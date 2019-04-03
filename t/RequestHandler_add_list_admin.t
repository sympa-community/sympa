#!/usr/bin/perl
# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id: tools_data.t 8606 2013-02-06 08:44:02Z rousse $

use strict;
use warnings;
use Data::Dumper;

use FindBin qw($Bin);
use lib "$Bin/../src/lib";

use Test::More;
use File::Path;
use File::Slurp;
use Sympa::List;
use Sympa::DatabaseManager;
use Sympa::ConfDef;

BEGIN {
    use_ok('Sympa::Request::Handler::add_list_admin');
}

## Definitin of test variables, files and directories
my $test_list_name = 'testlist';
my $test_robot_name = 'lists.example.com';
my $test_user = 'new_owner@example.com';
my $test_gecos = 'Dude McDude';
my $test_listmaster = 'dude@example.com';
my %available_owner_options = (
    info           =>   'Wot?',
    profile        =>   'privileged',
    reception      =>   'nomail',
    visibility     =>   'conceal',
);

my $test_directory = 't/tmp/';
mkdir $test_directory;

my $test_database_file = "$test_directory/sympa-test.sqlite";
unlink $test_database_file;
open(my $fh,">$test_database_file");
print $fh "";
close $fh;

my $pseudo_list_directory = "$test_directory/$test_list_name";
mkdir $pseudo_list_directory;
open($fh,">$pseudo_list_directory/config");
print $fh "name $test_list_name";
close $fh;

## Redirecting standard error to tmp file to prevent having logs all over the output.
open $fh, '>', "$test_directory/error_log" or die "Can't open file $test_directory/error_log in write mode";
close(STDERR);
my $out;
open(STDERR, ">>", \$out) or do { print $fh, "failed to open STDERR ($!)\n"; die };

## Setting pseudo list
my $list = {name => $test_list_name, domain => $test_robot_name, dir => $pseudo_list_directory};
bless $list,'Sympa::List';

## Setting pseudo configuration
%Conf::Conf = map { $_->{'name'} => $_->{'default'} }
    @Sympa::ConfDef::params;

$Conf::Conf{domain} = $test_robot_name; # mandatory
$Conf::Conf{listmaster} = $test_listmaster;  # mandatory
$Conf::Conf{db_type} = 'SQLite';
$Conf::Conf{db_name} = $test_database_file;
$Conf::Conf{log_socket_type} = 'stream';

Sympa::DatabaseManager::probe_db() or die "Unable to contact test database $test_database_file";
my $stash = [];

my $test_start_date = time();
ok (my $spindle = Sympa::Spindle::ProcessRequest->new(
    context          => $list,
    action           => 'add_list_admin',
    email            => $test_user,
    role             => 'owner',
    gecos          =>   $test_gecos,
    info           =>   $available_owner_options{info},
    profile        =>   $available_owner_options{profile},
    reception      =>   $available_owner_options{reception},
    visibility     =>   $available_owner_options{visibility},
    sender     =>   $test_listmaster,
    stash            => $stash,
), 'Request handler object created');

ok ($spindle->spin(), 'List owner addition succeeds.');

my $sdm = Sympa::DatabaseManager->instance;

my $sth = $sdm->do_query('SELECT * from `admin_table` WHERE `list_admin` LIKE %s and `robot_admin` LIKE %s', $sdm->quote($test_list_name), $sdm->quote($test_robot_name));

my @stored_admins;

while (my $row = $sth->fetchrow_hashref()) {
    push @stored_admins, $row;
}

is(scalar keys @stored_admins, 1, 'One admin stored in database.');

is($stored_admins[0]->{user_admin}, $test_user, 'The user stored in database is the one we requested.');

is($stored_admins[0]->{comment_admin}, $test_gecos, 'The user stored in database has the right gecos.');

foreach my $option (keys %available_owner_options) {
    is($stored_admins[0]->{$option.'_admin'}, $available_owner_options{$option}, "Correct value set for option $option");
}

$stash = [];
$spindle = Sympa::Spindle::ProcessRequest->new(
    context          => $list,
    action           => 'add_list_admin',
    email            => $test_user,
    role             => 'editor',
    stash            => $stash,
);

ok ($spindle->spin(), 'List editor addition succeeds.');

$sth = $sdm->do_query('SELECT * from `admin_table` WHERE `list_admin` LIKE %s and `robot_admin` LIKE %s', $sdm->quote($test_list_name), $sdm->quote($test_robot_name));

@stored_admins = ();

while (my $row = $sth->fetchrow_hashref()) {
    push @stored_admins, $row;
}

is(scalar keys @stored_admins, 2, 'Now two admins are stored in database.');

is($stored_admins[0]->{user_admin}, $test_user, 'The editor stored in database is the one we requested.');

$stash = [];
$spindle = Sympa::Spindle::ProcessRequest->new(
    context          => $list,
    action           => 'add_list_admin',
    email            => $test_user,
    role             => 'editor',
    stash            => $stash,
);

$spindle->spin();
my $reported_error = 0;
foreach my $report (@$stash) {
    if ($report->[1] eq 'user') {
        $reported_error++;
    }
}
ok($reported_error, 'User error returned when trying to add the same address in the same role.');

rmtree $test_directory;

done_testing();
