# -*- indent-tabs-mode: t; -*-
# vim:ft=perl:noet:sw=8:textwidth=78
# $Id: compile_modules.t 8606 2013-02-06 08:44:02Z rousse $

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

my @files = all_pm_files(qw{src/lib wwsympa soap});

all_pm_files_ok(@files);
