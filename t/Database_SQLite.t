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

# Definition of test variables, files and directories
my $test_listmaster = 'dude@example.com';

my $tempdir = File::Temp->newdir(CLEANUP => ($ENV{TEST_DEBUG} ? 0 : 1));

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
$SIG{__WARN__} = sub {
    print STDERR @_ unless 0 == index $_[0], 'Use of uninitialized value';
};

# Now do testing
my $sdm = Sympa::DatabaseManager->instance;
ok $sdm, 'instance';
diag sprintf 'SQLite version %d', $DBD::SQLite::sqlite_version_number;

do {
    no warnings 'redefine';
    local (*Sympa::send_notify_to_listmaster) = sub {1};
    ok Sympa::DatabaseManager::probe_db(), 'probe_db';
};

like $sdm->delete_field({table => 'subscriber_table', field => 'field1'}),
    qr/not exist/, 'delete_field(nonexisting)';
ok $sdm->add_field(
    {table => 'subscriber_table', field => 'field1', type => 'int'}),
    'add_field(nonexisting)';
ok not(
    $sdm->add_field(
        {table => 'subscriber_table', field => 'field1', type => 'int'}
    )
    ),
    'add_field(existing)';
if (3035005 <= $DBD::SQLite::sqlite_version_number) {
    ok $sdm->delete_field({table => 'subscriber_table', field => 'field1'}),
        'delete_field(existing)';
} else {
    like $sdm->delete_field({table => 'subscriber_table', field => 'field1'}),
        qr/not support/, 'delete_field(unsupported)';
}

done_testing();

