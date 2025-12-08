# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

use strict;
use warnings;

use File::Temp qw();
use Test::More;

use Sympa::List;
use Sympa::DatabaseManager;
use Sympa::ConfDef;

BEGIN {
    eval 'use DBD::SQLite';
}
unless ($DBD::SQLite::VERSION) {
    plan skip_all => 'DBD::SQLite required';
}

## Definition of test variables, files and directories
my $listname        = 'testlist';
my $test_user       = 'user@example.com';
my $test_listmaster = 'dude@example.com';

my $tempdir = File::Temp->newdir(CLEANUP => ($ENV{TEST_DEBUG} ? 0 : 1));

my $list = bless {
    name   => $listname,
    domain => 'mail.example.org',
    dir    => "$tempdir/$listname",
    admin  => {available_user_options => {reception => [qw(mail nomail)],},},
} => 'Sympa::List';

%Conf::Conf = (
    domain         => 'mail.example.org',    # mandatory
    listmaster     => $test_listmaster,      # mandatory
    db_type        => 'SQLite',
    db_name        => ':memory:',
    queuebulk      => $tempdir . '/bulk',
    queuesubscribe => $tempdir . '/auth',
    home           => $tempdir,
    db_list_cache  => 'off',
);
# Apply defaults.
foreach my $pinfo (grep { $_->{name} and exists $_->{default} }
    @Sympa::ConfDef::params) {
    $Conf::Conf{$pinfo->{name}} = $pinfo->{default}
        unless exists $Conf::Conf{$pinfo->{name}};
}

mkdir $Conf::Conf{queuesubscribe};

Sympa::Log->instance->{level} = -1;
do {
    no warnings 'redefine';
    local (*Sympa::send_notify_to_listmaster) = sub {1};
    Sympa::DatabaseManager::probe_db();
};
$SIG{__WARN__} = sub {
    print STDERR @_ unless 0 == index $_[0], 'Use of uninitialized value';
};

# Now do testing

## Error checking

my $stash = [];
Sympa::Spindle::ProcessRequest->new(
    context => undef,
    action  => 'set',
    email   => $test_user,
    role    => 'owner',
    sender  => $test_listmaster,
    stash   => $stash,
)->spin;
my ($result) = grep { $_->[1] ne 'notice' } @$stash;
ok($result, 'List owner update fails when no list object given.');
is($result->[2], 'unknown_list',
    'Correct error in stash when missing email.');

# List owner update fails when no email given.
do_test(
    role  => 'owner',
    error => [qw(user not_list_user)],
);

is eval { do_test(role => 'globuz', email => $test_user,) }, undef,
    'Fails when the given role does not exist';

do_test(
    role  => 'owner',
    email => 'globuz',
    error => [qw(user not_list_user)],
);

do_test(
    role  => 'owner',
    email => $test_user,
    error => [qw(user not_list_user)],
);

my $testOwner = {
    email      => $test_user,
    visibility => 'noconceal',
    profile    => 'normal',
    reception  => 'mail',
    gecos      => 'Dude',
    info       => 'an info',
};
my $testMember = {
    email      => $test_user,
    visibility => 'noconceal',
    reception  => 'mail',
    gecos      => 'Dude',
};

# Update of the admin in the list only for the given role.
do_test(
    role   => 'owner',
    add    => $testOwner,
    update => {
        visibility => 'conceal',
        profile    => 'privileged',
        reception  => 'nomail',
        gecos      => 'New Dude',
        info       => 'another info',
    },
);

# When no role parameters are given, parameters are used to update the member
# in the list.
do_test(
    add    => $testMember,
    update => {
        visibility => 'conceal',
        reception  => 'nomail',
        gecos      => 'New Dude',
    },
);

# Empty values are allowed for gecos and info.
do_test(
    role   => 'owner',
    add    => $testOwner,
    update => {
        gecos => '',
        info  => '',
    },
);
do_test(
    role   => 'member',
    add    => $testMember,
    update => {gecos => '',},
);

# Illegal parameter values.
do_test(
    role   => 'owner',
    add    => $testOwner,
    update => {reception => 'not_me',},
    error  => [qw(user not_available_reception_mode)],
);
do_test(
    role   => 'member',
    add    => $testMember,
    update => {reception => 'not_me',}, # cf. available_user_options.reception
    error => [qw(user not_available_reception_mode)],
);
do_test(
    role   => 'member',
    add    => $testMember,
    update => {reception => 'digest',}, # cf. available_user_options.reception
    error  => [qw(user no_digest)],
);
do_test(
    role   => 'owner',
    add    => $testOwner,
    update => {visibility => 'unknown',},
    error  => [qw(user not_available_visibility)],
);
do_test(
    role   => 'member',
    add    => $testMember,
    update => {visibility => 'unknown',},
    error  => [qw(user not_available_visibility)],
);
do_test(
    role   => 'owner',
    add    => $testOwner,
    update => {profile => 'omnipotent',},
    error  => [qw(user not_available_profile)],
);

# No changes
do_test(
    role   => 'owner',
    add    => $testOwner,
    update => {},
    error  => [qw(user no_changed_properties)],
);
do_test(
    role   => 'editor',
    add    => $testOwner,
    update => {},
    error  => [qw(user no_changed_properties)],
);
do_test(
    role   => 'member',
    add    => $testMember,
    update => {},
    error  => [qw(user no_changed_properties)],
);

done_testing();

sub do_test {
    my %options = @_;

    my $role   = $options{role} // 'member';
    my $add    = $options{add};
    my $update = $options{update};
    my $email  = $add ? $add->{email} : $options{email};
    my $error  = $options{error};

    my $sdm = Sympa::DatabaseManager->instance;
    if ($role eq 'member') {
        $sdm->do_query('DELETE FROM subscriber_table');
    } else {
        $sdm->do_query('DELETE FROM admin_table');
    }

    if ($role eq 'member') {
        $list->add_list_member($add) if $add;
    } else {
        $list->add_list_admin($role, $add) if $add;
    }

    my $stash = [];
    Sympa::Spindle::ProcessRequest->new(
        context => $list,
        action  => 'set',
        ($email ? (email => $email) : ()),
        sender => $test_listmaster,
        ($update ? %$update : ()),
        ($options{role} ? (role => $role) : ()),
        stash => $stash,
    )->spin;

    if ($error) {
        my ($result) = grep { $_->[1] ne 'notice' } @$stash;
        is join(', ', @{$result}[1, 2]), join(', ', @$error),
            "Error ($error->[0], $error->[1]) for user ($role)";
    } else {
        my $new_user;
        if ($role eq 'member') {
            $new_user = $list->get_list_member($email);
        } else {
            $new_user =
                [$list->get_admins($role, filter => [email => $email])]->[0];
        }

        foreach my $param (sort keys %$add) {
            if (exists $update->{$param}) {
                is($new_user->{$param}, $update->{$param},
                    "Parameter $param for user ($role) has been updated.");
            } else {
                is($new_user->{$param}, $add->{$param},
                    "Parameter $param for user ($role) has _not_ been updated."
                );
            }
        }
    }
}

