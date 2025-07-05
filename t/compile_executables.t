# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

use strict;
use warnings;

use English qw(-no_match_vars);
use Test::More;

BEGIN { eval 'use Test::Compile::Internal'; }
unless ($Test::Compile::Internal::VERSION) {
    my $msg = 'Test::Compile required';
    plan(skip_all => $msg);
} else {
    my $test  = Test::Compile::Internal->new;
    my @files = (
        <src/sbin/*.pl>,        <src/libexec/*.pl>,
        'src/cgi/wwsympa.fcgi', 'src/cgi/sympa_soap_server.fcgi',
    );
    $test->plan(tests => scalar @files);
    foreach my $file (@files) {
        my $ok = $test->pl_file_compiles($file);
        $test->ok($ok, $file);
        $test->diag("$file does not compile") unless $ok;
    }
}

