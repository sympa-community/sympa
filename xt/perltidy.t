use strict;
use warnings;

use Test::PerlTidy;
use FindBin qw($Bin);

run_tests(
    path       => "$Bin/../",
    perltidyrc => "$Bin/../doc/dot.perltidyrc",
    exclude    => [
        "$Bin/../autom4te.cache/", "$Bin/../ext/",
        "$Bin/../default/",        "$Bin/../doc/",
        "$Bin/../ext/",            "$Bin/../po/",
        "$Bin/../www/"
    ]
);
