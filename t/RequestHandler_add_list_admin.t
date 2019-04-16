#!/usr/bin/perl
# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id: tools_data.t 8606 2013-02-06 08:44:02Z rousse $

use strict;
use warnings;
use Data::Dumper;

use FindBin qw($Bin);
use lib ("$Bin/stub", "$Bin/../src/lib");

use Test::More;
use File::Path;
use File::Slurp;
use Sympa::List;
use Sympa::DatabaseManager;
use Sympa::ConfDef;

BEGIN {
    use_ok('Sympa::Request::Handler::add_list_admin');
}
print "Initializing variables\n";
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

print "Initializing test directory\n";
my $test_directory = 't/tmp';
rmtree $test_directory if -e $test_directory;
mkdir $test_directory;

print "Initializing test db $test_directory/sympa-test.sqlite\n";
my $test_database_file = "$test_directory/sympa-test.sqlite";
unlink $test_database_file;
open(my $fh,">$test_database_file");
print $fh "";
close $fh;

print "Initializing test list  $test_directory/$test_list_name\n";
my $pseudo_list_directory = "$test_directory/$test_list_name";
mkdir $pseudo_list_directory;
open($fh,">$pseudo_list_directory/config");
print $fh "name $test_list_name";
close $fh;

print "Redirecting standard error to tmp file to prevent having logs all over the output.\n";
## Redirecting standard error to tmp file to prevent having logs all over the output.
open $fh, '>', "$test_directory/error_log" or die "Can't open file $test_directory/error_log in write mode";
close(STDERR);
my $out;
open(STDERR, ">>", \$out) or do { print $fh, "failed to open STDERR ($!)\n"; die };

print "Setting pseudo list.\n";
## Setting pseudo list
my $list = {name => $test_list_name, domain => $test_robot_name, dir => $pseudo_list_directory};
bless $list,'Sympa::List';

print "Setting pseudo configuration.\n";
## Setting pseudo configuration
%Conf::Conf = map { $_->{'name'} => $_->{'default'} }
    @Sympa::ConfDef::params;

$Conf::Conf{domain} = $test_robot_name; # mandatory
$Conf::Conf{listmaster} = $test_listmaster;  # mandatory
$Conf::Conf{db_type} = 'SQLite';
$Conf::Conf{db_name} = $test_database_file;
$Conf::Conf{queuebulk} = $test_directory.'/bulk';
$Conf::Conf{log_socket_type} = 'stream';

print "Creating Sympa database.\n";
Sympa::DatabaseManager::probe_db() or die "Unable to contact test database $test_database_file";
my $stash = [];

print "Creating Request handler.\n";
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

#~ print 'user: '.Sympa::Constants::USER."\n";
#~ print 'group: '.Sympa::Constants::GROUP."\n";

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
    if ($report->[2] eq 'already_list_admin') {
        $reported_error++;
    }
}
ok($reported_error, 'User error returned when trying to add the same address in the same role.');

my %parameters = (
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
);

my @parameters_to_delete = (
    'email',
    'role',
);

foreach my $param (@parameters_to_delete) {
    my %current_parameters = %parameters;
    delete $current_parameters{$param};
    $stash = [];
    $current_parameters{stash} = $stash;
    $spindle = Sympa::Spindle::ProcessRequest->new(%current_parameters);
    $spindle->spin();
    #~ print Dumper $stash;
    ok(scalar @$stash && $stash->[0][3]{p_name} =~ /$param/, "When trying to run addition with a missing mandatory $param, an error is stashed.");
}

my %parameter_errors = (
    email            => 'wrong email address',
    role             => 'a role that does not exist',
    profile          => 'a profile that does not exist',
    reception        => 'a reception that does not exist',
    visibility       => 'a visibility that does not exist',
);

foreach my $param (sort keys %parameter_errors) {
    my %current_parameters = %parameters;
    $current_parameters{$param} = $parameter_errors{$param};
    $stash = [];
    $current_parameters{stash} = $stash;
    $spindle = Sympa::Spindle::ProcessRequest->new(%current_parameters);
    $spindle->spin();
    #~ print Dumper $stash;
    ok(scalar @$stash && $stash->[0][3]{p_name} =~ /$param/, "When trying to run addition with a faulty $param, an error is stashed.");
}

rmtree $test_directory;

done_testing();