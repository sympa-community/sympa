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
my $test_list_name  = 'testlist';
my $test_robot_name = 'lists.example.com';
my $test_user       = 'owner@example.com';
my $test_listmaster = 'dude@example.com';

my $tempdir = File::Temp->newdir(CLEANUP => ($ENV{TEST_DEBUG} ? 0 : 1));

my $list = bless {
    name   => $test_list_name,
    domain => $test_robot_name,
    dir    => "$tempdir/$test_list_name",
    admin  => {available_user_options => {reception => [qw(mail nomail)],},},
} => 'Sympa::List';

%Conf::Conf = (
    domain          => $test_robot_name,     # mandatory
    listmaster      => $test_listmaster,     # mandatory
    db_type         => 'SQLite',
    db_name         => ':memory:',
    queuebulk       => $tempdir . '/bulk',
    queuesubscribe  => $tempdir . '/auth',
    home            => $tempdir,
    log_socket_type => 'stream',
    db_list_cache   => 'off',
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

my $stash   = [];
my $spindle = Sympa::Spindle::ProcessRequest->new(
    context => undef,
    action  => 'set',
    email   => $test_user,
    role    => 'owner',
    sender  => $test_listmaster,
    stash   => $stash,
);

$spindle->spin();

ok(scalar @$stash, 'List owner update fails when no list object given.');

is($stash->[0][2], 'unknown_list',
    'Correct error in stash when missing email.');

$stash   = [];
$spindle = Sympa::Spindle::ProcessRequest->new(
    context => $list,
    action  => 'set',
    role    => 'owner',
    sender  => $test_listmaster,
    stash   => $stash,
);

$spindle->spin();

ok(scalar @$stash, 'List owner update fails when no email given.');

is($stash->[0][2], 'not_list_user',
    'Correct error in stash when missing email.');

$stash   = [];
$spindle = Sympa::Spindle::ProcessRequest->new(
    context => $list,
    action  => 'set',
    email   => $test_user,
    role    => 'globuz',
    sender  => $test_listmaster,
    stash   => $stash,
);

is eval { $spindle->spin() }, undef,
    'Fails when the given role does not exist.';

$stash   = [];
$spindle = Sympa::Spindle::ProcessRequest->new(
    context => $list,
    action  => 'set',
    email   => 'globuz',
    role    => 'owner',
    sender  => $test_listmaster,
    stash   => $stash,
);

$spindle->spin();

ok(scalar @$stash,
    'List owner update fails when the given email is invalid.');

is($stash->[0][2], 'not_list_user',
    'Correct error in stash when the given email is invalid.');

$stash   = [];
$spindle = Sympa::Spindle::ProcessRequest->new(
    context => $list,
    action  => 'set',
    email   => $test_user,
    role    => 'owner',
    sender  => $test_listmaster,
    stash   => $stash,
);

$spindle->spin();

ok(scalar @$stash,
    'List owner update fails when the given email is not admin.');

is($stash->[0][2], 'not_list_user',
    'Correct error in stash when the given email is not admin.');

my $sdm = Sympa::DatabaseManager->instance;
my $sth;

# Update of the admin in the list only for the given role.
do_test(
    role => 'owner',
    user => {
        email      => $test_user,
        visibility => 'noconceal',
        profile    => 'normal',
        reception  => 'mail',
        gecos      => 'Dude',
        info       => 'an info',
    },
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
    user => {
        email      => $test_user,
        visibility => 'noconceal',
        reception  => 'mail',
        gecos      => 'Dude',
    },
    update => {
        visibility => 'conceal',
        reception  => 'nomail',
        gecos      => 'New Dude',
    },
);

# Empty values are allowed for gecos and info.
do_test(
    role => 'owner',
    user => {
        email      => $test_user,
        visibility => 'noconceal',
        profile    => 'normal',
        reception  => 'mail',
        gecos      => 'Dude',
        info       => 'an info',
    },
    update => {
        gecos => '',
        info  => '',
    },
);
do_test(
    role => 'member',
    user => {
        email      => $test_user,
        visibility => 'noconceal',
        reception  => 'mail',
        gecos      => 'Dude',
    },
    update => {gecos => '',},
);

done_testing();

sub do_test {
    my %options = @_;

    my $role   = $options{role} // 'member';
    my $user   = $options{user} or die;
    my $update = $options{update} or die;
    my $email  = $user->{email};

    if ($role eq 'member') {
        $sdm->do_query('DELETE FROM subscriber_table');
    } else {
        $sdm->do_query('DELETE FROM admin_table');
    }

    if ($role eq 'member') {
        $list->add_list_member($user);
    } else {
        $list->add_list_admin($role, $user);
    }

    $stash   = [];
    $spindle = Sympa::Spindle::ProcessRequest->new(
        context => $list,
        action  => 'set',
        email   => $email,
        sender  => $test_listmaster,
        %$update,
        ($options{role} ? (role => $role) : ()),
        stash => $stash,
    );

    $spindle->spin();

    my $new_user;
    if ($role eq 'member') {
        $new_user = $list->get_list_member($email);
    } else {
        $new_user =
            [$list->get_admins($role, filter => [email => $email])]->[0];
    }

    foreach my $param (sort keys %$user) {
        if (exists $update->{$param}) {
            is($new_user->{$param}, $update->{$param},
                "Parameter $param for user ($role) has been updated.");
        } else {
            is($new_user->{$param}, $user->{$param},
                "Parameter $param for user ($role) has _not_ been updated.");
        }
    }

}

