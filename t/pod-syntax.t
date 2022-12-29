# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

use strict;
use warnings;
use English qw(-no_match_vars);
use Test::More;

my $test_pod_ok;

BEGIN {
    # Test::Pod 1.40 mistakenly complains about the construct L<text|url>.
    eval 'use Test::Pod 1.41';
    $test_pod_ok = 1 unless $EVAL_ERROR;
}
unless ($test_pod_ok) {
    plan(skip_all => 'Test::Pod 1.41 or later required');
} else {
    my @files = (
        all_pod_files('src'), glob('doc/*.pod'),
        glob('doc/*.podin'),  glob('doc/*.podpl')
    );
    all_pod_files_ok(@files);
}

