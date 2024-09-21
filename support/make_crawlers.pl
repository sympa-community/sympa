#!/usr/bin/env perl
# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

use strict;
use warnings;
use English qw(-no_match_vars);
use Getopt::Long;
use JSON qw();
use LWP::Simple qw();

use constant crawlers_url =>
    'https://raw.githubusercontent.com/monperrus/crawler-user-agents/master/crawler-user-agents.json';

my %opts;
GetOptions(\%opts, 'output|o=s') or exit 1;

my $crawlers = JSON->new->decode(LWP::Simple::get(crawlers_url()));
die "No content.\n" unless ref $crawlers eq 'ARRAY';

my @patterns = map {
    if (ref $_ eq 'HASH' and defined $_->{pattern}) {
        ($_->{pattern} =~ s/([ #{}])/[$1]/gr =~ s/\@/\\\@/gr =~
                s/(?<![[\\])[.](?![]])/\\./gr);
    } else {
        ();
    }
} @$crawlers;
die "No patterns.\n" unless @patterns;

my $output = sprintf do { local $RS; <DATA> }, join "\n  | ", @patterns;
eval $output;
$EVAL_ERROR and die "$EVAL_ERROR\n";

my $fh;
if ($opts{output}) {
    if ($opts{output} eq '-') {
        $fh = *STDOUT;
    } else {
        open $fh, '>', $opts{output} or die "$ERRNO\n";
    }
} else {
    my $dir = `dirname $0`;
    chomp $dir;
    open $fh, '>', "$dir/../src/lib/Sympa/WWW/Crawlers.pm"
        or die "$ERRNO\n";
}
print $fh $output;

__END__
# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# Sympa - SYsteme de Multi-Postage Automatique

# NOTE: This file is auto-generated.  Don't edit it manually.
# Instead, modifications should be made on support/make_crawlers.pl file.

package Sympa::WWW::Crawlers;

use strict;
use warnings;

use constant crawler => qr{
  (
    %s
  )
}x;

1;

__END__
=encoding utf-8

=head1 NAME

Sympa::WWW::Crawlers - Regular expression for User-Agent of web crawlers

=head1 DESCRIPTION

This module keeps definition of regular expressions used by Sympa software.

The regular expression is generated from the data provided by the
project below.

=head1 SEE ALSO

=over

=item *

Syntactic patterns of HTTP user-agents used by bots / robots / crawlers /
scrapers / spiders

L<https://github.com/monperrus/crawler-user-agents>

=back


=head1 HISTORY

Crawler detection feature of WWSympa was introduced on Sympa 5.4a.4
which derives information provided by L<http://www.useragentstring.com>.

On Sympa 6.2.74, it was replaced with regular expression matching
using information provided by crawler-user-agents project above.

=cut
