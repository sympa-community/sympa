# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

use strict;
use warnings;
use Test::More;

use Sympa::HTML::URIFind;

my $finder = Sympa::HTML::URIFind->new;
isa_ok $finder, 'Sympa::HTML::URIFind';

my $text;

$text = '$@example.org,<%@example.org>, &@example.org.';
is $finder->find(\$text), 3, 'email addresses';
is $text,
      '<a href="mailto:$@example.org">$@example.org</a>,'
    . '&lt;<a href="mailto:%@example.org">%@example.org</a>&gt;, '
    . '<a href="mailto:&amp;@example.org">&amp;@example.org</a>.';

$text = '""ma il"@example.org"';
is $finder->find(\$text), 1, 'email addresses';
is $text,
      '&quot;'
    . '<a href="mailto:%22ma%20il%22@example.org">'
    . '&quot;ma il&quot;@example.org' . '</a>'
    . '&quot;';

$text =
    'Mailto:$@example.org,<mailTo:%@example.org>, mailto:&@example.org. mailto:&#example.org';
is $finder->find(\$text), 3, 'mailto: URIs';
is $text,
      '<a href="Mailto:$@example.org">Mailto:$@example.org</a>,'
    . '&lt;<a href="mailTo:%@example.org">mailTo:%@example.org</a>&gt;, '
    . '<a href="mailto:&amp;@example.org">mailto:&amp;@example.org</a>. '
    . 'mailto:&amp;#example.org';

$text = 'example.org,<example.org>, ftp.example.org. example.qq';
is $finder->find(\$text), 3, 'schemeless URIs';
is $text,
      '<a href="http://example.org">example.org</a>,'
    . '&lt;<a href="http://example.org">example.org</a>&gt;, '
    . '<a href="ftp://ftp.example.org">ftp.example.org</a>. '
    . 'example.qq';

done_testing;
