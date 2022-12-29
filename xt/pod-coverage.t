#!/usr/bin/perl
# -*- indent-tabs-mode: t; -*-
# vim:ft=perl:noet:sw=8:textwidth=78
# $Id$

use strict;
use warnings;
use English qw(-no_match_vars);
use Test::More;

eval {
    require Test::Pod::Coverage;
    Test::Pod::Coverage->import();
};
plan(skip_all => 'Test::Pod::Coverage required') if $EVAL_ERROR;

# Test::Pod::Coverage hardcodes 'lib' as prefix, whereas we use 'src/lib'
my @modules = map {
    s/^src::lib:://;
    $_
} all_modules('src/lib');

plan tests => scalar @modules;

foreach my $module (@modules) {
    pod_coverage_ok($module,
        {coverage_class => 'Pod::Coverage::CountParents',});
}
