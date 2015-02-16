#!/usr/bin/perl
# -*- indent-tabs-mode: t; -*-
# vim:ft=perl:noet:sw=8:textwidth=78
# $Id$

use strict;
use warnings;
use English qw(-no_match_vars);
use Test::More;

eval {
    require Test::Pod;
    Test::Pod->import();
};
plan(skip_all => 'Test::Pod required') if $EVAL_ERROR;

my @files = all_pod_files(
	'src/lib',
	'src/bin',
	'src/sbin',
	'src/cgi',
);

all_pod_files_ok(@files);
