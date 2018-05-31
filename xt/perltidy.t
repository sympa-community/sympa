use strict;
use warnings;

use Test::PerlTidy;
use FindBin qw($Bin);

run_tests(
    path       => "$Bin/../src/",
    perltidyrc => "$Bin/../doc/dot.perltidyrc"
);
