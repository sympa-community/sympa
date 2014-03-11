#!/usr/bin/perl
# -*- indent-tabs-mode: t; -*-
# vim:ft=perl:noet:sw=8:textwidth=78
# $Id: compile_executables.t 8606 2013-02-06 08:44:02Z rousse $

use strict;
use warnings;

use English qw(-no_match_vars);
use Test::More;

eval {
    require Test::Compile;
    Test::Compile->import();
};
if ($EVAL_ERROR) {
    my $msg = 'Test::Compile required';
    plan(skip_all => $msg);
}

#$ENV{PERL5LIB} = $ENV{PERL5LIB} ? "$ENV{PERL5LIB}:src/lib" : "src/lib";

all_pl_files_ok(
	<src/*.pl>,
	<src/etc/script/*.pl>,
	<soap/*.pl>,
	<wwsympa/wwsympa.fcgi>,
	<soap/sympa_soap_server.fcgi>,
);
