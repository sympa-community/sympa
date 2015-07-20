# -*- indent-tabs-mode: t; -*-
# vim:ft=perl:et:sw=4
# $Id$

use strict;
use warnings;
use Test::Fixme;

run_tests(
    where          => 'src',
    filename_match => qr/\.(?:pm|pl\.in|fcgi\.in)$/,
    match          => qr/#\s*TODO\b/i,
);
