#!/usr/bin/perl
# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id: tools_data.t 8606 2013-02-06 08:44:02Z rousse $

use strict;
use warnings;
use Data::Dumper;

use FindBin qw($Bin);
use lib "$Bin/stub";
use lib "$Bin/../src/lib";

use Test::More;
use File::Path;
use File::Slurp;
use Sympa::List;
use Sympa::DatabaseManager;
use Sympa::ConfDef;

BEGIN {
    use_ok('Sympa::Request::Handler::delete_list_admin');
}

## Definitin of test variables, files and directories
my $test_list_name = 'testlist';
my $test_robot_name = 'lists.example.com';
my $test_user = 'new_owner@example.com';
my $test_listmaster = 'dude@example.com';

my $test_directory = 't/tmp';
rmtree $test_directory if -e $test_directory;
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
$Conf::Conf{queuebulk} = $test_directory.'/bulk';
$Conf::Conf{log_socket_type} = 'stream';

Sympa::DatabaseManager::probe_db() or die "Unable to contact test database $test_database_file";
my $role = 'owner';
my $user = {
    email => $test_user,
};
$list->add_list_admin($role, $user) or die 'Unable to add owner';

my $sdm = Sympa::DatabaseManager->instance;

my $sth = $sdm->do_query('SELECT * from `admin_table` WHERE `list_admin` LIKE %s and `robot_admin` LIKE %s and role_admin LIKE %s',
    $sdm->quote($test_list_name),
    $sdm->quote($test_robot_name),
    $sdm->quote('owner'),
);

my @stored_admins;
while (my $row = $sth->fetchrow_hashref()) {
    push @stored_admins, $row;
}

is(scalar keys @stored_admins, 1, 'Test owner is correctly stored in database.');

$role = 'editor';
$list->add_list_admin($role, $user) or die 'Unable to add editor';

$sth = $sdm->do_query('SELECT * from `admin_table` WHERE `list_admin` LIKE %s and `robot_admin` LIKE %s and role_admin LIKE %s',
    $sdm->quote($test_list_name),
    $sdm->quote($test_robot_name),
    $sdm->quote('editor'),
);

@stored_admins = ();

while (my $row = $sth->fetchrow_hashref()) {
    push @stored_admins, $row;
}

is(scalar keys @stored_admins, 1, 'Test editor is correctly stored in database.');

## Error checking

my $stash = [];
my $spindle = Sympa::Spindle::ProcessRequest->new(
    context          => undef,
    action           => 'delete_list_admin',
    email            => $test_user,
    role             => 'owner',
    sender     =>   $test_listmaster,
    stash            => $stash,
);

$spindle->spin();

ok (scalar @$stash, 'List owner deletion fails when no list or robot object given.');

is ($stash->[0][2], 'unknown_list', 'Correct error in stash when mising email.');

$stash = [];
$spindle = Sympa::Spindle::ProcessRequest->new(
    context          => $list,
    action           => 'delete_list_admin',
    role             => 'owner',
    sender     =>   $test_listmaster,
    stash            => $stash,
);

$spindle->spin();

ok (scalar @$stash, 'List owner deletion fails when no email given.');

is ($stash->[0][2], 'missing_parameters', 'Correct error in stash when missing email.');

$stash = [];
$spindle = Sympa::Spindle::ProcessRequest->new(
    context          => $list,
    action           => 'delete_list_admin',
    email            => $test_user,
    role             => 'globuz',
    sender     =>   $test_listmaster,
    stash            => $stash,
);

$spindle->spin();

ok (scalar @$stash, 'List owner deletion fails when the given role does not exist.');

is ($stash->[0][2], 'syntax_errors', 'Correct error in stash when role does not exist.');

is ($stash->[0][3]{p_name}, 'role', 'The error parameter is the role.');

$stash = [];
$spindle = Sympa::Spindle::ProcessRequest->new(
    context          => $list,
    action           => 'delete_list_admin',
    email            => 'globuz',
    role             => 'owner',
    sender     =>   $test_listmaster,
    stash            => $stash,
);

$spindle->spin();

ok (scalar @$stash, 'List owner deletion fails when the given email is invalid.');

is ($stash->[0][2], 'syntax_errors', 'Correct error in stash when the given email is invalid.');

is ($stash->[0][3]{p_name}, 'email', 'The error parameter is the email.');

ok ($spindle = Sympa::Spindle::ProcessRequest->new(
    context          => $list,
    action           => 'delete_list_admin',
    email            => $test_user,
    role             => 'owner',
    sender     =>   $test_listmaster,
    stash            => $stash,
), 'Request handler object created');

ok ($spindle->spin(), 'List owner deletion succeeds.');

$sth = $sdm->do_query('SELECT * from `admin_table` WHERE `list_admin` LIKE %s and `robot_admin` LIKE %s and role_admin LIKE %s',
    $sdm->quote($test_list_name),
    $sdm->quote($test_robot_name),
    $sdm->quote('owner'),
);

@stored_admins = ();

while (my $row = $sth->fetchrow_hashref()) {
    push @stored_admins, $row;
}

is(scalar keys @stored_admins, 0, 'test owner has been deleted from database.');

$stash = [];
$spindle = Sympa::Spindle::ProcessRequest->new(
    context          => $list,
    action           => 'delete_list_admin',
    email            => $test_user,
    role             => 'owner',
    sender     =>   $test_listmaster,
    stash            => $stash,
);

$spindle->spin();

ok (scalar @$stash, 'List owner deletion fails when the given email does not have the role to be removed.');

is ($stash->[0][2], 'not_list_admin', 'Correct error in stash when the given email does not have the role to be removed.');

$stash = [];
$spindle = Sympa::Spindle::ProcessRequest->new(
    context          => $list,
    action           => 'delete_list_admin',
    email            => $test_user,
    role             => 'editor',
    stash            => $stash,
);

ok ($spindle->spin(), 'List editor deletion succeeds.');

$sth = $sdm->do_query('SELECT * from `admin_table` WHERE `list_admin` LIKE %s and `robot_admin` LIKE %s and role_admin LIKE %s',
    $sdm->quote($test_list_name),
    $sdm->quote($test_robot_name),
    $sdm->quote('editor'),
);

@stored_admins = ();

while (my $row = $sth->fetchrow_hashref()) {
    push @stored_admins, $row;
}

is(scalar keys @stored_admins, 0, 'test editor has been removed from database.');

$stash = [];
rmtree $test_directory;

done_testing();
