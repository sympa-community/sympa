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
    use_ok('Sympa::Request::Handler::update_list_admin');
}

## Definition of test variables, files and directories
my $test_list_name = 'testlist';
my $test_robot_name = 'lists.example.com';
my $test_user = 'owner@example.com';
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
foreach my $delta ('','2','3') {
    mkdir $pseudo_list_directory.$delta;
    open($fh,">$pseudo_list_directory$delta/config");
    print $fh "name $test_list_name$delta";
    close $fh;
}

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
$Conf::Conf{home} = $test_directory;
$Conf::Conf{log_socket_type} = 'stream';
$Conf::Conf{db_list_cache} = 'off';

Sympa::DatabaseManager::probe_db() or die "Unable to contact test database $test_database_file";

## Error checking

my $stash = [];
my $spindle = Sympa::Spindle::ProcessRequest->new(
    context          => undef,
    action           => 'update_list_admin',
    current_email            => $test_user,
    role             => 'owner',
    sender     =>   $test_listmaster,
    stash            => $stash,
);

$spindle->spin();

ok (scalar @$stash, 'List owner update fails when no list or robot object given.');

is ($stash->[0][2], 'syntax_errors', 'Correct error in stash when missing email.');

$stash = [];
$spindle = Sympa::Spindle::ProcessRequest->new(
    context          => $list,
    action           => 'update_list_admin',
    role             => 'owner',
    sender     =>   $test_listmaster,
    stash            => $stash,
);

$spindle->spin();

ok (scalar @$stash, 'List owner update fails when no email given.');

is ($stash->[0][2], 'missing_parameters', 'Correct error in stash when missing email.');

$stash = [];
$spindle = Sympa::Spindle::ProcessRequest->new(
    context          => $list,
    action           => 'update_list_admin',
    current_email            => $test_user,
    new_email        => 'new'.$test_user,
    role             => 'globuz',
    sender     =>   $test_listmaster,
    stash            => $stash,
);

$spindle->spin();

ok (scalar @$stash, 'List owner update fails when the given role does not exist.');

is ($stash->[0][2], 'syntax_errors', 'Correct error in stash when role does not exist.');

is ($stash->[0][3]{p_name}, 'role', 'The error parameter is the role.');

$stash = [];
$spindle = Sympa::Spindle::ProcessRequest->new(
    context          => $list,
    action           => 'update_list_admin',
    current_email            => 'globuz',
    new_email        => 'new'.$test_user,
    role             => 'owner',
    sender     =>   $test_listmaster,
    stash            => $stash,
);

$spindle->spin();

ok (scalar @$stash, 'List owner update fails when the given current_email is invalid.');

is ($stash->[0][2], 'syntax_errors', 'Correct error in stash when the given current_email is invalid.');

is ($stash->[0][3]{p_name}, 'current_email', 'The error parameter is the current_email.');

$stash = [];
$spindle = Sympa::Spindle::ProcessRequest->new(
    context          => $list,
    action           => 'update_list_admin',
    current_email            => $test_user,
    new_email        => 'new',
    role             => 'owner',
    sender     =>   $test_listmaster,
    stash            => $stash,
);

$spindle->spin();

ok (scalar @$stash, 'List owner update fails when the given new email is invalid.');

is ($stash->[0][2], 'syntax_errors', 'Correct error in stash when the given new email is invalid.');

is ($stash->[0][3]{p_name}, 'new_email', 'The error parameter is the new_email.');

$stash = [];
$spindle = Sympa::Spindle::ProcessRequest->new(
    context          => $list,
    action           => 'update_list_admin',
    current_email            => $test_user,
    sender     =>   $test_listmaster,
    stash            => $stash,
);

$spindle->spin();

ok (scalar @$stash, 'List owner update fails when the given current email is not admin.');

is ($stash->[0][2], 'not_list_admin', 'Correct error in stash when the given current email is not admin.');

## List owner: replacement by a new owner;

my $sdm = Sympa::DatabaseManager->instance;
my $sth;

$sdm->do_query('DELETE FROM `admin_table` WHERE 1');
my $role = 'owner';
my $user = {
    email => $test_user,
};
$list->add_list_admin($role, $user) or die 'Unable to add owner';

## Second owner that should not be updated.
$sth = $sdm->do_query('SELECT * from `admin_table` WHERE `list_admin` LIKE %s and `robot_admin` LIKE %s and role_admin LIKE %s and user_admin like %s',
    $sdm->quote($test_list_name),
    $sdm->quote($test_robot_name),
    $sdm->quote('owner'),
    $sdm->quote($test_user),
);

my @stored_admins;
while (my $row = $sth->fetchrow_hashref()) {
    push @stored_admins, $row;
}

is(scalar @stored_admins, 1, 'Test owner is correctly stored in database.');

ok ($spindle = Sympa::Spindle::ProcessRequest->new(
    context          => $list,
    action           => 'update_list_admin',
    current_email            => $test_user,
    new_email        => 'new'.$test_user,
    role             => 'owner',
    sender     =>   $test_listmaster,
    stash            => $stash,
), 'Request handler object created');

ok ($spindle->spin(), 'List owner replacement succeeds.');

$sth = $sdm->do_query('SELECT * from `admin_table` WHERE `list_admin` LIKE %s and `robot_admin` LIKE %s and role_admin LIKE %s and user_admin like %s',
    $sdm->quote($test_list_name),
    $sdm->quote($test_robot_name),
    $sdm->quote('owner'),
    $sdm->quote('new'.$test_user),
);

@stored_admins = ();

while (my $row = $sth->fetchrow_hashref()) {
    push @stored_admins, $row;
}

is(scalar @stored_admins, 1, 'new list test owner has been added to the database.');

my $owner = $list->get_admins('owner', filter => [email => 'new'.$test_user]);

is($owner->[0]->{email}, 'new'.$test_user, 'The Sympa primitives now return the new user as list owner.');

$sth = $sdm->do_query('SELECT * from `admin_table` WHERE `list_admin` LIKE %s and `robot_admin` LIKE %s and role_admin LIKE %s and user_admin like %s',
    $sdm->quote($test_list_name),
    $sdm->quote($test_robot_name),
    $sdm->quote('owner'),
    $sdm->quote($test_user),
);

@stored_admins = ();

while (my $row = $sth->fetchrow_hashref()) {
    push @stored_admins, $row;
}

is(scalar @stored_admins, 0, 'former test owner has been removed from database.');

$owner = $list->get_admins('owner', filter => [email => $test_user]);

is(scalar @$owner, 0, 'The Sympa primitives do not return the old owner when queried.');

## Error when trying to update a list owner which does not exist.

$stash = [];
$spindle = Sympa::Spindle::ProcessRequest->new(
    context          => $list,
    action           => 'update_list_admin',
    current_email            => $test_user,
    new_email        => 'new'.$test_user,
    role             => 'owner',
    sender     =>   $test_listmaster,
    stash            => $stash,
);

$spindle->spin();

ok (scalar @$stash, 'List owner update fails when the given email does not have the role to be removed.');

is ($stash->[0][2], 'not_list_admin', 'Correct error in stash when the given email does not have the role to be removed.');

## Parameters handling: parameters are used to create the new admin

$sdm->do_query('DELETE FROM `admin_table` WHERE 1');

my %parameters = (
    visibility => {old_value => 'noconceal', new_value => 'conceal', field => 'visibility_admin'},
    profile => {old_value => 'normal', new_value => 'privileged', field => 'profile_admin'},
    reception => {old_value => 'mail', new_value => 'nomail', field => 'reception_admin'},
    gecos => {old_value => 'Dude', new_value => 'New Dude', field => 'comment_admin'},
    info => {old_value => 'an info', new_value => 'another info', field => 'info_admin'},
);

$list->add_list_admin('owner', {
    email       => $test_user,
    visibility  => $parameters{visibility}{old_value},
    profile     => $parameters{profile}{old_value},
    reception   => $parameters{reception}{old_value},
    gecos       => $parameters{gecos}{old_value},
    info        => $parameters{info}{old_value},
}) or die 'Unable to add editor';

$stash = [];
$spindle = Sympa::Spindle::ProcessRequest->new(
    context         => $list,
    action          => 'update_list_admin',
    current_email           => $test_user,
    new_email       => 'new'.$test_user,
    role            => 'owner',
    sender          => $test_listmaster,
    visibility      => $parameters{visibility}{new_value},
    profile         => $parameters{profile}{new_value},
    reception       => $parameters{reception}{new_value},
    gecos           => $parameters{gecos}{new_value},
    info            => $parameters{info}{new_value},
    stash           => $stash,
);

$spindle->spin();

$sth = $sdm->do_query('SELECT * from `admin_table` WHERE `list_admin` LIKE %s and `robot_admin` LIKE %s and role_admin LIKE %s and user_admin like %s',
    $sdm->quote($test_list_name),
    $sdm->quote($test_robot_name),
    $sdm->quote('owner'),
    $sdm->quote('new'.$test_user),
);

my $new_admin = $sth->fetchrow_hashref();

foreach my $param (keys %parameters) {
    is ($new_admin->{$parameters{$param}{field}}, $parameters{$param}{new_value}, "Parameter $param has been updated in database.");
}
## Correct handling of privileges for owners.

## When replacing a user by another one which has already the same role, the old one is removed and the other one kept the same

$sdm->do_query('DELETE FROM `admin_table` WHERE 1');

%parameters = (
    visibility => {old_value => 'noconceal', new_value => 'conceal', field => 'visibility_admin'},
    profile => {old_value => 'normal', new_value => 'privileged', field => 'profile_admin'},
    reception => {old_value => 'mail', new_value => 'nomail', field => 'reception_admin'},
    gecos => {old_value => 'Dude', new_value => 'New Dude', field => 'comment_admin'},
    info => {old_value => 'an info', new_value => 'another info', field => 'info_admin'},
);

$list->add_list_admin('owner', {
    email       => $test_user,
    visibility  => $parameters{visibility}{old_value},
    profile     => $parameters{profile}{old_value},
    reception   => $parameters{reception}{old_value},
    gecos       => $parameters{gecos}{old_value},
    info        => $parameters{info}{old_value},
}) or die 'Unable to add editor';

$list->add_list_admin('owner', {
    email       => 'new'.$test_user,
    visibility  => $parameters{visibility}{new_value},
    profile     => $parameters{profile}{new_value},
    reception   => $parameters{reception}{new_value},
    gecos       => $parameters{gecos}{new_value},
    info        => $parameters{info}{new_value},
}) or die 'Unable to add editor';

$stash = [];
$spindle = Sympa::Spindle::ProcessRequest->new(
    context         => $list,
    action          => 'update_list_admin',
    current_email           => $test_user,
    new_email       => 'new'.$test_user,
    role            => 'owner',
    sender          => $test_listmaster,
    visibility      => $parameters{visibility}{old_value},
    profile         => $parameters{profile}{old_value},
    reception       => $parameters{reception}{old_value},
    gecos           => $parameters{gecos}{old_value},
    info            => $parameters{info}{old_value},
    stash           => $stash,
);

$spindle->spin();

$sth = $sdm->do_query('SELECT * from `admin_table` WHERE `list_admin` LIKE %s and `robot_admin` LIKE %s and role_admin LIKE %s and user_admin like %s',
    $sdm->quote($test_list_name),
    $sdm->quote($test_robot_name),
    $sdm->quote('owner'),
    $sdm->quote('new'.$test_user),
);

$new_admin = $sth->fetchrow_hashref();

## When replacing a user by another one which has already the same role, the old one keeps all its parameters (safe privileges, see below).

foreach my $param (keys %parameters) {
    is ($new_admin->{$parameters{$param}{field}}, $parameters{$param}{new_value}, "Parameter $param for pre-existing admin has been kept the same in database.");
}

my $old_admin = $sth->fetchrow_hashref();

is($old_admin, undef, 'Old admin has been deleted when replaced by an user that existed already with the same role in the same list.');

## When replacing a user by another one which has already the same role, if "profile" is given with value "privileged", it is applied if the pre-existing owner was "normal".

$sdm->do_query('DELETE FROM `admin_table` WHERE 1');

%parameters = (
    profile => {old_value => 'normal', new_value => 'privileged', field => 'profile_admin'},
);

$list->add_list_admin('owner', {
    email       => $test_user,
    profile     => $parameters{profile}{old_value},
}) or die 'Unable to add editor';

$list->add_list_admin('owner', {
    email       => 'new'.$test_user,
    profile     => $parameters{profile}{old_value},
}) or die 'Unable to add editor';

$stash = [];
$spindle = Sympa::Spindle::ProcessRequest->new(
    context         => $list,
    action          => 'update_list_admin',
    current_email           => $test_user,
    new_email       => 'new'.$test_user,
    role            => 'owner',
    sender          => $test_listmaster,
    profile         => $parameters{profile}{new_value},
    stash           => $stash,
);

$spindle->spin();

$sth = $sdm->do_query('SELECT * from `admin_table` WHERE `list_admin` LIKE %s and `robot_admin` LIKE %s and role_admin LIKE %s and user_admin like %s',
    $sdm->quote($test_list_name),
    $sdm->quote($test_robot_name),
    $sdm->quote('owner'),
    $sdm->quote('new'.$test_user),
);

$new_admin = $sth->fetchrow_hashref();

is ($new_admin->{$parameters{profile}{field}}, $parameters{profile}{new_value}, 'Parameter profile for pre-existing admin has been upgraded to higher privilege in database.');

## List editor replacement by a new editor

$sdm->do_query('DELETE FROM `admin_table` WHERE 1');
$list->add_list_admin('editor', $user) or die 'Unable to add editor';

$sth = $sdm->do_query('SELECT * from `admin_table` WHERE `list_admin` LIKE %s and `robot_admin` LIKE %s and role_admin LIKE %s and user_admin like %s',
    $sdm->quote($test_list_name),
    $sdm->quote($test_robot_name),
    $sdm->quote('editor'),
    $sdm->quote($test_user),
);

@stored_admins = ();

while (my $row = $sth->fetchrow_hashref()) {
    push @stored_admins, $row;
}

is(scalar @stored_admins, 1, 'Test editor is correctly stored in database.');

$stash = [];
$spindle = Sympa::Spindle::ProcessRequest->new(
    context          => $list,
    action           => 'update_list_admin',
    current_email            => $test_user,
    new_email        => 'new'.$test_user,
    role             => 'editor',
    stash            => $stash,
);

ok ($spindle->spin(), 'List editor replacement succeeds.');

$sth = $sdm->do_query('SELECT * from `admin_table` WHERE `list_admin` LIKE %s and `robot_admin` LIKE %s and role_admin LIKE %s and user_admin like %s',
    $sdm->quote($test_list_name),
    $sdm->quote($test_robot_name),
    $sdm->quote('editor'),
    $sdm->quote('new'.$test_user),
);

@stored_admins = ();

while (my $row = $sth->fetchrow_hashref()) {
    push @stored_admins, $row;
}

is(scalar @stored_admins, 1, 'new list test editor has been added to the database.');

$sth = $sdm->do_query('SELECT * from `admin_table` WHERE `list_admin` LIKE %s and `robot_admin` LIKE %s and role_admin LIKE %s and user_admin like %s',
    $sdm->quote($test_list_name),
    $sdm->quote($test_robot_name),
    $sdm->quote('editor'),
    $sdm->quote($test_user),
);

@stored_admins = ();

while (my $row = $sth->fetchrow_hashref()) {
    push @stored_admins, $row;
}

is(scalar @stored_admins, 0, 'former test editor has been removed from database.');

## Replacement of all roles in a single list

$sdm->do_query('DELETE FROM `admin_table` WHERE 1');
$list->add_list_admin('owner', $user) or die 'Unable to add owner';
$list->add_list_admin('editor', $user) or die 'Unable to add owner';

$stash = [];
$spindle = Sympa::Spindle::ProcessRequest->new(
    context          => $list,
    action           => 'update_list_admin',
    current_email            => $test_user,
    new_email        => 'new'.$test_user,
    stash            => $stash,
);

ok ($spindle->spin(), 'List admin replacement succeeds.');

$sth = $sdm->do_query('SELECT * from `admin_table` WHERE `list_admin` LIKE %s and `robot_admin` LIKE %s and user_admin like %s',
    $sdm->quote($test_list_name),
    $sdm->quote($test_robot_name),
    $sdm->quote($test_user),
);

@stored_admins = ();

while (my $row = $sth->fetchrow_hashref()) {
    push @stored_admins, $row;
}

is(scalar @stored_admins, 0, 'test user got all his roles in test list removed from database.');

$sth = $sdm->do_query('SELECT * from `admin_table` WHERE `list_admin` LIKE %s and `robot_admin` LIKE %s',
    $sdm->quote($test_list_name),
    $sdm->quote($test_robot_name),
);

@stored_admins = ();

my ($found_editor, $found_owner, $too_much_data);

while (my $row = $sth->fetchrow_hashref()) {
    if ($row->{user_admin} eq 'new'.$test_user and $row->{role_admin} eq 'editor') {
        $found_editor = 1;
    } elsif ($row->{user_admin} eq 'new'.$test_user and $row->{role_admin} eq 'owner') {
        $found_owner = 1;
    }else {
        $too_much_data = 1;
    }
}

ok(($found_owner and $found_editor), 'The new user has gathered all roles from previous user.');
ok(!$too_much_data, 'The database contains the wanted data and them only.');

## Replacement of one role for a whole domain.

$sdm->do_query('DELETE FROM `admin_table` WHERE 1');

my $list2 = {name => $test_list_name.'2', domain => $test_robot_name, dir => $pseudo_list_directory.'2'};
bless $list2,'Sympa::List';

my $list3 = {name => $test_list_name.'3', domain => $test_robot_name, dir => $pseudo_list_directory.'3'};
bless $list3,'Sympa::List';

$list->add_list_admin('owner', $user) or die 'Unable to add owner';
$list2->add_list_admin('owner', $user) or die 'Unable to add owner';

$stash = [];
$spindle = Sympa::Spindle::ProcessRequest->new(
    context          => $test_robot_name,
    action           => 'update_list_admin',
    role             => 'owner',
    current_email            => $test_user,
    new_email        => 'new'.$test_user,
    stash            => $stash,
);

ok ($spindle->spin(), 'List owner replacement succeeds for a whole domain.');

$sth = $sdm->do_query('SELECT * from `admin_table` WHERE `robot_admin` LIKE %s and role_admin LIKE %s and user_admin like %s',
    $sdm->quote($test_robot_name),
    $sdm->quote('owner'),
    $sdm->quote($test_user),
);

@stored_admins = ();

while (my $row = $sth->fetchrow_hashref()) {
    push @stored_admins, $row;
}

is(scalar @stored_admins, 0, 'test user got removed ownership for all lists in the domain.');

## Replacement of all roles for a whole domain.

$sdm->do_query('DELETE FROM `admin_table` WHERE 1');

$list->add_list_admin('owner', $user) or die 'Unable to add owner';
$list2->add_list_admin('owner', $user) or die 'Unable to add owner';
$list->add_list_admin('editor', $user) or die 'Unable to add editor';
$list2->add_list_admin('editor', $user) or die 'Unable to add editor';

$stash = [];
$spindle = Sympa::Spindle::ProcessRequest->new(
    context          => $test_robot_name,
    action           => 'update_list_admin',
    current_email            => $test_user,
    new_email        => 'new'.$test_user,
    stash            => $stash,
);

ok ($spindle->spin(), 'List admin replacement succeeds for a whole domain.');

$sth = $sdm->do_query('SELECT * from `admin_table` WHERE `robot_admin` LIKE %s and user_admin like %s',
    $sdm->quote($test_robot_name),
    $sdm->quote($test_user),
);

@stored_admins = ();

while (my $row = $sth->fetchrow_hashref()) {
    push @stored_admins, $row;
}

is(scalar @stored_admins, 0, 'test user got removed all adminships for all lists in the domain.');

## When the email and new_email parameters are the same, it leads to an update of the old admin in the list only for the given role.

$sdm->do_query('DELETE FROM `admin_table` WHERE 1');

%parameters = (
    visibility => {old_value => 'noconceal', new_value => 'conceal', field => 'visibility_admin'},
    profile => {old_value => 'normal', new_value => 'privileged', field => 'profile_admin'},
    reception => {old_value => 'mail', new_value => 'nomail', field => 'reception_admin'},
    gecos => {old_value => 'Dude', new_value => 'New Dude', field => 'comment_admin'},
    info => {old_value => 'an info', new_value => 'another info', field => 'info_admin'},
);

$list->add_list_admin('owner', {
    email       => $test_user,
    visibility  => $parameters{visibility}{old_value},
    profile     => $parameters{profile}{old_value},
    reception   => $parameters{reception}{old_value},
    gecos       => $parameters{gecos}{old_value},
    info        => $parameters{info}{old_value},
}) or die 'Unable to add editor';

$stash = [];
$spindle = Sympa::Spindle::ProcessRequest->new(
    context         => $list,
    action          => 'update_list_admin',
    current_email           => $test_user,
    new_email       => $test_user,
    role            => 'owner',
    sender          => $test_listmaster,
    visibility      => $parameters{visibility}{new_value},
    profile         => $parameters{profile}{new_value},
    reception       => $parameters{reception}{new_value},
    gecos           => $parameters{gecos}{new_value},
    info            => $parameters{info}{new_value},
    stash           => $stash,
);

$spindle->spin();

$sth = $sdm->do_query('SELECT * from `admin_table` WHERE `list_admin` LIKE %s and `robot_admin` LIKE %s and role_admin LIKE %s and user_admin like %s',
    $sdm->quote($test_list_name),
    $sdm->quote($test_robot_name),
    $sdm->quote('owner'),
    $sdm->quote($test_user),
);

$new_admin = $sth->fetchrow_hashref();

foreach my $param (keys %parameters) {
    is ($new_admin->{$parameters{$param}{field}}, $parameters{$param}{new_value}, "Parameter $param for updated admin has been kept the same in database.");
}

## When no new_email parameter is given, it leads to an update of the old admin.

$sdm->do_query('DELETE FROM `admin_table` WHERE 1');

%parameters = (
    visibility => {old_value => 'noconceal', new_value => 'conceal', field => 'visibility_admin'},
    profile => {old_value => 'normal', new_value => 'privileged', field => 'profile_admin'},
    reception => {old_value => 'mail', new_value => 'nomail', field => 'reception_admin'},
    gecos => {old_value => 'Dude', new_value => 'New Dude', field => 'comment_admin'},
    info => {old_value => 'an info', new_value => 'another info', field => 'info_admin'},
);

$list->add_list_admin('owner', {
    email       => $test_user,
    visibility  => $parameters{visibility}{old_value},
    profile     => $parameters{profile}{old_value},
    reception   => $parameters{reception}{old_value},
    gecos       => $parameters{gecos}{old_value},
    info        => $parameters{info}{old_value},
}) or die 'Unable to add editor';

$stash = [];
$spindle = Sympa::Spindle::ProcessRequest->new(
    context         => $list,
    action          => 'update_list_admin',
    current_email           => $test_user,
    role            => 'owner',
    sender          => $test_listmaster,
    visibility      => $parameters{visibility}{new_value},
    profile         => $parameters{profile}{new_value},
    reception       => $parameters{reception}{new_value},
    gecos           => $parameters{gecos}{new_value},
    info            => $parameters{info}{new_value},
    stash           => $stash,
);

$spindle->spin();

$sth = $sdm->do_query('SELECT * from `admin_table` WHERE `list_admin` LIKE %s and `robot_admin` LIKE %s and role_admin LIKE %s and user_admin like %s',
    $sdm->quote($test_list_name),
    $sdm->quote($test_robot_name),
    $sdm->quote('owner'),
    $sdm->quote($test_user),
);

$new_admin = $sth->fetchrow_hashref();

foreach my $param (keys %parameters) {
    is ($new_admin->{$parameters{$param}{field}}, $parameters{$param}{new_value}, "Parameter $param for updated admin has been kept the same in database.");
}

## When no new_email and no role parameters are given, parameters are used to update the old admin for all roles in the list.

$sdm->do_query('DELETE FROM `admin_table` WHERE 1');

%parameters = (
    visibility => {old_value => 'noconceal', new_value => 'conceal', field => 'visibility_admin'},
    profile => {old_value => 'normal', new_value => 'privileged', field => 'profile_admin'},
    reception => {old_value => 'mail', new_value => 'nomail', field => 'reception_admin'},
    gecos => {old_value => 'Dude', new_value => 'New Dude', field => 'comment_admin'},
    info => {old_value => 'an info', new_value => 'another info', field => 'info_admin'},
);

$list->add_list_admin('owner', {
    email       => $test_user,
    visibility  => $parameters{visibility}{old_value},
    profile     => $parameters{profile}{old_value},
    reception   => $parameters{reception}{old_value},
    gecos       => $parameters{gecos}{old_value},
    info        => $parameters{info}{old_value},
}) or die 'Unable to add editor';

$list->add_list_admin('editor', {
    email       => $test_user,
    visibility  => $parameters{visibility}{old_value},
    profile     => $parameters{profile}{old_value},
    reception   => $parameters{reception}{old_value},
    gecos       => $parameters{gecos}{old_value},
    info        => $parameters{info}{old_value},
}) or die 'Unable to add editor';

$stash = [];
$spindle = Sympa::Spindle::ProcessRequest->new(
    context         => $list,
    action          => 'update_list_admin',
    current_email           => $test_user,
    sender          => $test_listmaster,
    visibility      => $parameters{visibility}{new_value},
    profile         => $parameters{profile}{new_value},
    reception       => $parameters{reception}{new_value},
    gecos           => $parameters{gecos}{new_value},
    info            => $parameters{info}{new_value},
    stash           => $stash,
);

$spindle->spin();

foreach my $role ('owner', 'editor') {
    $sth = $sdm->do_query('SELECT * from `admin_table` WHERE `list_admin` LIKE %s and `robot_admin` LIKE %s and role_admin LIKE %s and user_admin like %s',
        $sdm->quote($test_list_name),
        $sdm->quote($test_robot_name),
        $sdm->quote($role),
        $sdm->quote($test_user),
    );

    my $new_admin = $sth->fetchrow_hashref();

    foreach my $param (keys %parameters) {
        if ($param eq 'profile' && $role eq 'editor') {
            is ($new_admin->{$parameters{$param}{field}}, 'normal', "Parameter $param for old admin has been ignored while updating database for role $role.");
        }else{
            is ($new_admin->{$parameters{$param}{field}}, $parameters{$param}{new_value}, "Parameter $param for old admin has been updated in database for role $role.");
        }
    }
}

## When no new_email and no list parameters are given, parameters are used to update the old admin for the given role on the whole robot.

$sdm->do_query('DELETE FROM `admin_table` WHERE 1');

%parameters = (
    visibility => {old_value => 'noconceal', new_value => 'conceal', field => 'visibility_admin'},
    profile => {old_value => 'normal', new_value => 'privileged', field => 'profile_admin'},
    reception => {old_value => 'mail', new_value => 'nomail', field => 'reception_admin'},
    gecos => {old_value => 'Dude', new_value => 'New Dude', field => 'comment_admin'},
    info => {old_value => 'an info', new_value => 'another info', field => 'info_admin'},
);

$list->add_list_admin('owner', {
    email       => $test_user,
    visibility  => $parameters{visibility}{old_value},
    profile     => $parameters{profile}{old_value},
    reception   => $parameters{reception}{old_value},
    gecos       => $parameters{gecos}{old_value},
    info        => $parameters{info}{old_value},
}) or die 'Unable to add editor';

$list2->add_list_admin('owner', {
    email       => $test_user,
    visibility  => $parameters{visibility}{old_value},
    profile     => $parameters{profile}{old_value},
    reception   => $parameters{reception}{old_value},
    gecos       => $parameters{gecos}{old_value},
    info        => $parameters{info}{old_value},
}) or die 'Unable to add editor';

$stash = [];
$spindle = Sympa::Spindle::ProcessRequest->new(
    context         => $test_robot_name,
    action          => 'update_list_admin',
    current_email           => $test_user,
    role            => 'owner',
    sender          => $test_listmaster,
    visibility      => $parameters{visibility}{new_value},
    profile         => $parameters{profile}{new_value},
    reception       => $parameters{reception}{new_value},
    gecos           => $parameters{gecos}{new_value},
    info            => $parameters{info}{new_value},
    stash           => $stash,
);

$spindle->spin();

foreach my $list ('testlist', 'testlist2') {
    $sth = $sdm->do_query('SELECT * from `admin_table` WHERE `list_admin` LIKE %s and `robot_admin` LIKE %s and role_admin LIKE %s and user_admin like %s',
        $sdm->quote($list),
        $sdm->quote($test_robot_name),
        $sdm->quote('owner'),
        $sdm->quote($test_user),
    );

    my $new_admin = $sth->fetchrow_hashref();

    foreach my $param (keys %parameters) {
        is ($new_admin->{$parameters{$param}{field}}, $parameters{$param}{new_value}, "Parameter $param for old admin has been updated in database for list $list.");
    }
}


## When no new_email, no list and no role parameters are given, parameters are used to update the old admin for all roles in the whole robot.

$sdm->do_query('DELETE FROM `admin_table` WHERE 1');

%parameters = (
    visibility => {old_value => 'noconceal', new_value => 'conceal', field => 'visibility_admin'},
    profile => {old_value => 'normal', new_value => 'privileged', field => 'profile_admin'},
    reception => {old_value => 'mail', new_value => 'nomail', field => 'reception_admin'},
    gecos => {old_value => 'Dude', new_value => 'New Dude', field => 'comment_admin'},
    info => {old_value => 'an info', new_value => 'another info', field => 'info_admin'},
);

$list->add_list_admin('owner', {
    email       => $test_user,
    visibility  => $parameters{visibility}{old_value},
    profile     => $parameters{profile}{old_value},
    reception   => $parameters{reception}{old_value},
    gecos       => $parameters{gecos}{old_value},
    info        => $parameters{info}{old_value},
}) or die 'Unable to add owner';

$list2->add_list_admin('owner', {
    email       => $test_user,
    visibility  => $parameters{visibility}{old_value},
    profile     => $parameters{profile}{old_value},
    reception   => $parameters{reception}{old_value},
    gecos       => $parameters{gecos}{old_value},
    info        => $parameters{info}{old_value},
}) or die 'Unable to add owner';

$list->add_list_admin('editor', {
    email       => $test_user,
    visibility  => $parameters{visibility}{old_value},
    profile     => $parameters{profile}{old_value},
    reception   => $parameters{reception}{old_value},
    gecos       => $parameters{gecos}{old_value},
    info        => $parameters{info}{old_value},
}) or die 'Unable to add editor';

$list2->add_list_admin('editor', {
    email       => $test_user,
    visibility  => $parameters{visibility}{old_value},
    profile     => $parameters{profile}{old_value},
    reception   => $parameters{reception}{old_value},
    gecos       => $parameters{gecos}{old_value},
    info        => $parameters{info}{old_value},
}) or die 'Unable to add editor';

$stash = [];
$spindle = Sympa::Spindle::ProcessRequest->new(
    context         => $test_robot_name,
    action          => 'update_list_admin',
    current_email           => $test_user,
    sender          => $test_listmaster,
    visibility      => $parameters{visibility}{new_value},
    profile         => $parameters{profile}{new_value},
    reception       => $parameters{reception}{new_value},
    gecos           => $parameters{gecos}{new_value},
    info            => $parameters{info}{new_value},
    stash           => $stash,
);

$spindle->spin();

foreach my $role ('owner', 'editor') {
    foreach my $list ('testlist', 'testlist2') {
        $sth = $sdm->do_query('SELECT * from `admin_table` WHERE `list_admin` LIKE %s and `robot_admin` LIKE %s and role_admin LIKE %s and user_admin like %s',
            $sdm->quote($list),
            $sdm->quote($test_robot_name),
            $sdm->quote($role),
            $sdm->quote($test_user),
        );

        my $new_admin = $sth->fetchrow_hashref();

        foreach my $param (keys %parameters) {
            if ($param eq 'profile' && $role eq 'editor') {
                is ($new_admin->{$parameters{$param}{field}}, 'normal', "Parameter $param for old admin has been ignored while updating database for list $list and role $role.");
            }else{
                is ($new_admin->{$parameters{$param}{field}}, $parameters{$param}{new_value}, "Parameter $param for old admin has been updated in database for list $list and role $role.");
            }
        }
    }
}

rmtree $test_directory;

done_testing();
