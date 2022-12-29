#-*- perl -*-

use strict;
use warnings;
use English qw(-no_match_vars);
use Test::More;

use Sympa::Scenario;

my @files = <default/scenari/*.*>;

foreach my $file (@files) {
    open my $fh, '<', $file or die $ERRNO;
    my $data = do { local $RS; <$fh> };
    close $fh;

    my $parsed = Sympa::Scenario::compile('*', $data);
    my $eval_error = $EVAL_ERROR;
    ok(($parsed and ref $parsed->{sub} eq 'CODE'), $file);
    diag($eval_error) if $eval_error;
}

done_testing();

