# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

use strict;
use warnings;
use Data::Dumper;
use English qw(-no_match_vars);
use File::Temp qw();
use Test::More;

use Sympa::DatabaseManager;
use Sympa::List;
use Sympa::Log;
use Sympa::Spindle::ProcessRequest;

BEGIN {
    eval 'use DBD::SQLite';
}
unless ($DBD::SQLite::VERSION) {
    plan skip_all => 'DBD::SQLite required';
}

my $listname = 'test';

my $tempdir = File::Temp->newdir(CLEANUP => ($ENV{TEST_DEBUG} ? 0 : 1));
%Conf::Conf = (
    domain                => 'mail.example.org',
    listmaster            => 'dude@example.com',
    lang                  => 'en-US',
    db_type               => 'SQLite',
    db_name               => ':memory:',
    update_db_field_types => 'auto',

    queuesubscribe => $tempdir . '/auth',
    bounce_path    => $tempdir . '/bounce',
    etc            => $tempdir . '/etc',
);
mkdir $Conf::Conf{queuesubscribe};
mkdir $Conf::Conf{bounce_path};
mkdir $Conf::Conf{bounce_path} . '/' . $listname . '@' . $Conf::Conf{domain};
mkdir $Conf::Conf{etc};
mkdir $Conf::Conf{etc} . '/data_sources';

my $fake_list = bless {
    name   => $listname,
    domain => $Conf::Conf{'domain'},
    dir    => $tempdir . '/list',
    admin  => {
        max_list_members => 2,

        available_user_options => {reception => [qw(mail digest)],},
        default_user_options   => {
            reception  => 'digest',
            visibility => 'conceal',
        },
        default_owner_options => {
            profile    => 'privileged',
            reception  => 'nomail',
            visibility => 'conceal',
        },
        default_editor_options => {
            reception  => 'nomail',
            visibility => 'conceal',
        },

        member_include => [
            {   source    => 'include_file',
                reception => 'mail',
            }
        ],
        owner_include => [
            {   source  => 'include_file',
                profile => 'normal',
            }
        ],
        editor_include => [
            {   source     => 'include_file',
                visibility => 'noconceal',
            }
        ],
    },
} => 'Sympa::List';
mkdir $tempdir . '/list';
open my $fh, '>', $Conf::Conf{etc} . '/data_sources/include_file.incl'
    or die $ERRNO;
print $fh "include_file $tempdir/source\n";
close $fh;

Sympa::Log->instance->{level} = -1;
do {
    no warnings 'redefine';
    local (*Sympa::send_notify_to_listmaster) = sub {1};
    Sympa::DatabaseManager::probe_db();
};
$SIG{__WARN__} = sub {
    print STDERR @_ unless 0 == index $_[0], 'Use of uninitialized value';
};

my $sdm = Sympa::DatabaseManager->instance or die;

# Now do testing

my $member_none = 'member0@example.name';
my $member1     = [qw(member1@example.name Member1 digest conceal)];
my $member2     = [qw(member2@example.name Member2 digest conceal)];
my $member3     = [qw(member3@example.name Member3 digest conceal)];
my $owner_none  = 'owner0@example.name';
my $owner1 = [qw(owner owner1@example.name Owner1 privileged nomail conceal)];
my $editor_none = 'editor0@example.name';
my $editor1 =
    [qw(editor editor1@example.name Editor1), undef, qw(nomail conceal)];
my $editor2 =
    [qw(editor editor2@example.name Editor2), undef, qw(nomail conceal)];
my $editor3 =
    [qw(editor editor3@example.name Editor3), undef, qw(nomail conceal)];

do_test(
    request => {
        action => 'add',
        email  => [$member1->[0], $member2->[0],],
        gecos  => [$member1->[1], $member2->[1],],
    },
    result => [[qw(user list_not_open)]],
    data   => [],
    name   => 'add subscriber: List not open'
);
$fake_list->{'admin'}{'status'} = 'open';
do_test(
    request => {
        action => 'add',
        email  => $member1->[0],
        gecos  => $member1->[1],
        quiet  => 1,
    },
    data => [$member1],
    name => 'add subscriber'
);
do_test(
    request => {
        action => 'add',
        email  => $member1->[0],
        gecos  => $member1->[1],
    },
    result => [[qw(user already_subscriber)]],
    data   => [$member1],
    name   => 'add subscriber: Already subscriber'
);

do_test(
    request => {
        action => 'add',
        email  => $member2->[0],
        gecos  => $member2->[1],
        quiet  => 1,
    },
    data => [$member1, $member2],
    name => 'add subscriber: Not exceeding max_list_members'
);
do_test(
    request => {
        action => 'add',
        email  => $member3->[0],
        gecos  => $member3->[1],
    },
    data   => [$member1, $member2],
    result => [[qw(user max_list_members_exceeded)]],
    name   => 'add subscriber: Exceeding max_list_members'
);

do_test(
    request => {
        action => 'add',
        role   => 'owner',
        email  => $owner1->[1],
        gecos  => $owner1->[2],
        quiet  => 1,
    },
    data => [$owner1],
    name => 'add owner'
);
do_test(
    request => {
        action => 'add',
        role   => 'editor',
        email  => $editor1->[1],
        gecos  => $editor1->[2],
        quiet  => 1,
    },
    data => [$editor1, $owner1],
    name => 'add moderator'
);
do_test(
    request => {
        action => 'add',
        role   => 'owner',
        email  => $owner1->[1],
    },
    result => [[qw(user already_user)]],
    data   => [$editor1, $owner1],
    name   => 'add owner: Already owner'
);
do_test(
    request => {
        action => 'add',
        role   => 'editor',
        email  => [map { $_->[1] } ($editor1, $editor2, $editor3)],
        gecos  => [map { $_->[2] } ($editor1, $editor2, $editor3)],
        quiet  => 1,
    },
    result => [[qw(user already_user)], [qw(notice add_performed)]],
    data   => [$editor1, $editor2, $editor3, $owner1],
    name   => 'add moderators'
);

do_test(
    request => {
        action => 'del',
        email  => $member_none,
    },
    result => [[qw(user user_not_subscriber)]],
    data   => [$member1, $member2],
    name   => 'del subscriber: Not a subscriber'
);
do_test(
    request => {
        action => 'del',
        email  => $member1->[0],
        quiet  => 1,
    },
    data => [$member2],
    name => 'del subscriber'
);
do_test(
    request => {
        action => 'del',
        email  => [$member1->[0], $member2->[0]],
        quiet  => 1,
    },
    data   => [],
    result => [[qw(user user_not_subscriber)], [qw(notice removed)]],
    name   => 'del subscribers'
);

do_test(
    request => {
        action => 'del',
        role   => 'owner',
        email  => $owner_none,
    },
    result => [[qw(user user_not_admin)]],
    data   => [$editor1, $editor2, $editor3, $owner1],
    name   => 'del owner: Not a owner'
);
do_test(
    request => {
        action => 'del',
        role   => 'owner',
        email  => $owner1->[1],
    },
    data => [$editor1, $editor2, $editor3],
    name => 'del owner'
);
do_test(
    request => {
        action => 'del',
        role   => 'editor',
        email =>
            [$editor_none, map { $_->[1] } ($editor1, $editor2, $editor3)],
    },
    result => [[qw(user user_not_admin)], [qw(notice removed)]],
    data   => [],
    name   => 'del moderators'
);

do_test_include(
    role   => 'member',
    source => [$member1],
    data   => [[@{$member1}[0, 1], qw(mail conceal)]],
    name   => 'include subscriber',
);
sleep 2;
do_test_include(
    role   => 'member',
    source => [],
    data   => [],
    name   => 'include subscriber: emptied',
);
do_test_include(
    role   => 'member',
    source => [$member1],
    data   => [[@{$member1}[0, 1], qw(mail conceal)]],
    name   => 'include subscriber',
);
do_test_include(
    role   => 'owner',
    source => [[@{$owner1}[1, 2]]],
    data   => [[@{$owner1}[0 .. 2], qw(normal nomail conceal)]],
    name   => 'include owner',
);
do_test_include(
    role   => 'editor',
    source => [[@{$editor1}[1, 2]]],
    data   => [
        [@{$editor1}[0 .. 3], qw(nomail noconceal)],
        [@{$owner1}[0 .. 2],  qw(normal nomail conceal)],
    ],
    name => 'include moderator',
);
sleep 2;
do_test_include(
    role   => 'owner',
    source => [],
    data   => [[@{$editor1}[0 .. 3], qw(nomail noconceal)]],
    name   => 'include owner: emptied',
);
do_test_include(
    role   => 'editor',
    source => [],
    data   => [],
    name   => 'include moderator: emptied',
);

done_testing();

sub do_test {
    my %options = @_;

    my $role = $options{request}->{role} // 'member';

    my @stash;
    my $spindle = Sympa::Spindle::ProcessRequest->new(
        context => $fake_list,
        %{$options{request}},
        sender           => $Conf::Conf{listmaster},
        stash            => \@stash,
        scenario_context => {skip => 1},
    );
    die unless $spindle and $spindle->spin;

    if ($options{result}) {
        unless (
            grep {
                my $s = $_;
                grep { $_->[0] eq $s->[1] and $_->[1] eq $s->[2] }
                    @{$options{result}}
            } @stash
        ) {
            fail $options{name};
            diag 'No result ' . join "\n",
                map { sprintf '"%s" "%s"', @$_ } @{$options{result}};
            diag join "\n", map { join ',', @$_ } @stash;
        }
    } elsif (
        grep {
            $_->[1] ne 'notice'
        } @stash
    ) {
        fail $options{name};
        diag join "\n", map { join ',', @$_ } @stash;
    }

    return unless $options{data};

    if ('member' eq $role) {
        is_deeply $sdm->do_prepared_query(
            q{SELECT user_subscriber, comment_subscriber,
                     reception_subscriber, visibility_subscriber
              FROM subscriber_table
              ORDER BY user_subscriber}
        )->fetchall_arrayref, $options{data}, $options{name};
    } else {
        is_deeply $sdm->do_prepared_query(
            q{SELECT role_admin, user_admin, comment_admin,
                     profile_admin, reception_admin, visibility_admin
              FROM admin_table
              ORDER BY user_admin}
        )->fetchall_arrayref, $options{data}, $options{name};
    }
}

sub do_test_include {
    my %options = @_;

    my $role = $options{role} or die 'no role specified';

    open my $fh, '>', $tempdir . '/source' or die $ERRNO;
    foreach my $u (@{$options{source} // []}) {
        printf $fh "%s %s\n", $u->[0], $u->[1];
    }
    close $fh;

    my @stash;
    my $spindle = Sympa::Spindle::ProcessRequest->new(
        context          => $fake_list,
        action           => 'include',
        role             => $role,
        sender           => $Conf::Conf{listmaster},
        stash            => \@stash,
        scenario_context => {skip => 1},
    );
    die unless $spindle and $spindle->spin;

    if ($options{result}) {
        unless (
            grep {
                my $s = $_;
                grep { $_->[0] eq $s->[1] and $_->[1] eq $s->[2] }
                    @{$options{result}}
            } @stash
        ) {
            fail $options{name};
            diag 'No result ' . join "\n",
                map { sprintf '"%s" "%s"', @$_ } @{$options{result}};
            diag join "\n", map { join ',', @$_ } @stash;
        }
    } elsif (
        grep {
            $_->[1] ne 'notice'
        } @stash
    ) {
        fail $options{name};
        diag join "\n", map { join ',', @$_ } @stash;
    }

    return unless $options{data};

    if ('member' eq $role) {
        is_deeply $sdm->do_prepared_query(
            q{SELECT user_subscriber, comment_subscriber,
                     reception_subscriber, visibility_subscriber
              FROM subscriber_table
              ORDER BY user_subscriber}
        )->fetchall_arrayref, $options{data}, $options{name};
    } else {
        is_deeply $sdm->do_prepared_query(
            q{SELECT role_admin, user_admin, comment_admin,
                     profile_admin, reception_admin, visibility_admin
              FROM admin_table
              ORDER BY user_admin}
        )->fetchall_arrayref, $options{data}, $options{name};
    }
}

