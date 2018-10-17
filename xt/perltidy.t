use strict;
use warnings;

use English qw(-no_match_vars);
use File::Finder;
use FindBin qw($Bin);
use Test::More;
use Test::PerlTidy;

chdir "$Bin/.." or die $ERRNO;
my $finder =
    File::Finder->type('f')->name(qr{[.](?:pl[.]in|fcgi[.]in|pm|t)$});
my @files = (
    'src/lib/Sympa/Constants.pm.in',
    grep { $_ ne 'src/lib/Sympa/Constants.pm' } $finder->in(qw(src t xt))
);

foreach my $file (@files) {
    ok Test::PerlTidy::is_file_tidy($file, 'doc/dot.perltidyrc'), $file;
}
done_testing;

