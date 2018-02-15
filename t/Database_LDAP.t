#!/usr/bin/perl
# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../src/lib";

use English qw(-no_match_vars);
use Test::More;

use Sympa::Database;

plan tests => 8;

my $source;

#$source = Sympa::Database->new('LDAP');
#ok(!defined $source, 'source is not defined');

$source = Sympa::Database->new('LDAP', host => 'localhost');
ok(defined $source, 'source is defined');
isa_ok($source, 'Sympa::DatabaseDriver::LDAP');

SKIP: {
    skip 'live LDAP tests disabled', 6 unless $ENV{TEST_LDAP_HOST};
    my $ldap;

    $source = Sympa::Database->new('LDAP', host => $ENV{TEST_LDAP_HOST});
    ok($source->connect(), 'connection succeed');
    isa_ok($source->__dbh, 'Net::LDAP');

    skip 'LDAPS tests disabled', 2 unless $ENV{TEST_LDAP_SSL};
    $source = Sympa::Database->new(
        'LDAP',
        host    => $ENV{TEST_LDAP_HOST},
        use_ssl => 1,
    );
    ok($source->connect(), 'LDAPS connection succeed');
    isa_ok($source->__dbh, 'Net::LDAP');

    skip 'StartTLS tests disabled', 2 unless $ENV{TEST_LDAP_START_TLS};
    $source = Sympa::Database->new(
        'LDAP',
        host          => $ENV{TEST_LDAP_HOST},
        use_start_tls => 1,
    );
    ok($source->connect(), 'LDAP connection + start_tls succeed');
    isa_ok($source->__dbh, 'Net::LDAP');
}
