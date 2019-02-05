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

my $new_config_file_content = read_file("$pseudo_list_directory/config");

my $config_update_succeeded = 0;
my $update_date = 0;
my $update_author = '';

foreach my $line (split '\n', $new_config_file_content) {
    if($line =~ m{\Aupdate}) {
        $config_update_succeeded = 1;
    }
    if($line =~ m{date_epoch\s+(\d+)}) {
        $update_date = $1;
    }
    if($line =~ m{email\s+(\S+)}) {
        $update_author = $1;
    }
}

ok($config_update_succeeded, 'List config file has been updated');
cmp_ok($update_date, '>=', $test_start_date, 'Update time is consistant with the time of test.');
is($update_author, $test_listmaster, 'The update author name is correct.');

$spindle = Sympa::Spindle::ProcessRequest->new(
    context          => $list,
    action           => 'add_list_admin',
    email            => $test_user,
    role             => 'editor',
);

ok ($spindle->spin(), 'List editor addition succeeds.');

$sth = $sdm->do_query('SELECT * from `admin_table` WHERE `list_admin` LIKE %s and `robot_admin` LIKE %s', $sdm->quote($test_list_name), $sdm->quote($test_robot_name));

@stored_admins = ();

while (my $row = $sth->fetchrow_hashref()) {
    push @stored_admins, $row;
}

is(scalar keys @stored_admins, 2, 'Now two admins are stored in database.');

is($stored_admins[0]->{user_admin}, $test_user, 'The editor stored in database is the one we requested.');

rmtree $test_directory;

done_testing();
