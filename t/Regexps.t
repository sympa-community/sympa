# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

use strict;
use warnings;
use Test::More;

use Sympa::Regexps;

my %tests = (
    email         => '([\w\-\_\.\/\+\=\'\&]+|\".*\")\@[\w\-]+(\.[\w\-]+)+',
    family_name   => '[a-z0-9][a-z0-9\-\.\+_]*',
    template_name => '[a-zA-Z0-9][a-zA-Z0-9\-\.\+_\s]*',
    host          => '[\w\.\-]+',
    multiple_host_with_port => '[\w\.\-]+(:\d+)?(,[\w\.\-]+(:\d+)?)*',
    listname                => '[a-z0-9][a-z0-9\-\.\+_]{0,49}',
    sql_query               => '(SELECT|select).*',
    scenario_config         => '[-.,\w]+',
    scenario_name           => '[-.\w]+',
    task                    => '\w+',
    datasource              => '[\w-]+',
    uid                     => '[\w\-\.\+]+',
    time                    => '[012]?[0-9](?:\:[0-5][0-9])?',
    time_range => '[012]?[0-9](?:\:[0-5][0-9])?-[012]?[0-9](?:\:[0-5][0-9])?',
    time_ranges =>
        '[012]?[0-9](?:\:[0-5][0-9])?-[012]?[0-9](?:\:[0-5][0-9])?(?:\s+[012]?[0-9](?:\:[0-5][0-9])?-[012]?[0-9](?:\:[0-5][0-9])?)*',
);

plan tests => scalar keys %tests;

foreach my $type (keys %tests) {
    ok(eval("Sympa::Regexps::$type"), $tests{$type});
}

1;
