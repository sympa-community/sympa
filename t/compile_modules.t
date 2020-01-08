# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

use strict;
use warnings;

use English qw(-no_match_vars);
use Test::More;

BEGIN { eval 'use Test::Compile qw(all_pm_files all_pm_files_ok)'; }
unless ($Test::Compile::VERSION) {
    my $msg = 'Test::Compile required';
    plan(skip_all => $msg);
}

# Workaround: Suppress warnings on INIT block.
$SIG{__WARN__} = sub {
    my $msg = shift;
    print STDERR $msg unless $msg =~ /\AToo late to run INIT block at /;
};

my @files = all_pm_files(qw{src/lib});

all_pm_files_ok(@files);
