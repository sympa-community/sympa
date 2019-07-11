# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

use strict;
use warnings;

use English qw(-no_match_vars);
use Test::More;

BEGIN { eval 'use Test::Compile qw(all_pl_files_ok)'; }
unless ($Test::Compile::VERSION) {
    my $msg = 'Test::Compile required';
    plan(skip_all => $msg);
}

all_pl_files_ok(
    ##<po/*.pl>,
    <src/sbin/*.pl>,
    <src/bin/*.pl>,
    <src/libexec/*.pl>,
    'src/cgi/wwsympa.fcgi',
    'src/cgi/sympa_soap_server.fcgi',
);
