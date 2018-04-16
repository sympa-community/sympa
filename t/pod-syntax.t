# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

use strict;
use warnings;
use English qw(-no_match_vars);
use Test::More;

BEGIN {
    eval 'use Test::Pod';
}
plan(skip_all => 'Test::Pod required') unless $Test::Pod::VERSION;

my @files = (
    all_pod_files('src'), glob('doc/*.pod'),
    glob('doc/*.podin'),  glob('doc/*.podpl')
);

all_pod_files_ok(@files);
