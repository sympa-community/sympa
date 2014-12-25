#!/usr/bin/perl
# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

use strict;
use warnings;

use lib 'src/lib';

use English qw(-no_match_vars);
use Test::More;

use Sympa::Datasource::LDAP;

plan tests => 8;

my $source;

#$source = Sympa::Datasource::LDAP->new();
#ok(!defined $source, 'source is not defined');

$source = Sympa::Datasource::LDAP->new({host => 'localhost'});
ok(defined $source, 'source is defined');
isa_ok($source, 'Sympa::Datasource::LDAP');

SKIP: {
    skip 'live LDAP tests disabled', 6 unless $ENV{TEST_LDAP_HOST};
    my $ldap;

    $source = Sympa::Datasource::LDAP->new({host => $ENV{TEST_LDAP_HOST}});
    $ldap = $source->connect();
    ok(defined $ldap, 'connection succeed');
    isa_ok($ldap, 'Net::LDAP');

    skip 'LDAPS tests disabled', 2 unless $ENV{TEST_LDAP_SSL};
    $source = Sympa::Datasource::LDAP->new(
        {   host    => $ENV{TEST_LDAP_HOST},
            use_ssl => 1,
        }
    );
    $ldap = $source->connect();
    ok(defined $ldap, 'LDAPS connection succeed');
    isa_ok($ldap, 'Net::LDAP');

    skip 'StartTLS tests disabled', 2 unless $ENV{TEST_LDAP_START_TLS};
    $source = Sympa::Datasource::LDAP->new(
        {   host          => $ENV{TEST_LDAP_HOST},
            use_start_tls => 1,
        }
    );
    $ldap = $source->connect();
    ok(defined $ldap, 'LDAP connection + start_tls succeed');
    isa_ok($ldap, 'Net::LDAP');
}
