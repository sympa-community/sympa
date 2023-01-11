# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

use strict;
use warnings;
use English qw(-no_match_vars);
use Test::More;

use Sympa::HTMLSanitizer;

%Conf::Conf = (wwsympa_url => 'https://web.example.org/sympa');

my $sanitizer = Sympa::HTMLSanitizer->new('*');
my $sanitized;

my $html = sprintf <<'EOF', ('YmxhaGJsYWhibGFo' x 8192);
<html>
<head></head>
<body>
<div style="width:100%%; color: white; background-image:url(data:image/jpeg;base64,%s); background-color: black">
</div>
</body>
</html>
EOF

ok eval {
    local $SIG{__DIE__};
    $sanitized = $sanitizer->sanitize_html($html);
}, 'Avoid ReDoS with style attribute';
if ($EVAL_ERROR) {
    diag $EVAL_ERROR;
} else {
    $sanitized =~ s/\n//g;
    is $sanitized,
        '<html><head></head><body><div style="color:white; background-color:black"></div></body></html>',
        'Scrub style attribute';
}

is $sanitizer->sanitize_html(
    sprintf
        '<html><body><a href="https://web.example.org/%s"></a></body></html>',
    'x' x 9977
    ),
    '<html><body><a></a></body></html>',
    'filter long URI';
is $sanitizer->sanitize_html(
    '<html><body><a href="CiD:foobar"></a></body></html>'),
    '<html><body><a href="cid:foobar"></a></body></html>',
    'not filter cid URI';
is $sanitizer->sanitize_html(
    '<html><body><a href="data:image/jpeg,base64;Lg=="></a></body></html>'),
    '<html><body><a></a></body></html>', 'filter data URI';
is $sanitizer->sanitize_html(
    '<html><body><a href="../&hearts;"></a></body></html>'),
    '<html><body><a href="../%E2%99%A5"></a></body></html>',
    'not filter relative URI reference';
is $sanitizer->sanitize_html(
    '<html><body><a href="https://"></a></body></html>'),
    '<html><body><a></a></body></html>',
    'filter URI with empty host';
is $sanitizer->sanitize_html(
    '<html><body><a href="https://web.example.org"></a></body></html>'),
    '<html><body><a href="https://web.example.org/"></a></body></html>',
    'not filter https URI with the same origin';
is $sanitizer->sanitize_html(
    '<html><body><a href="https://web.example.com"></a></body></html>'),
    '<html><body><a></a></body></html>',
    'filter https URI with the other origin';

done_testing();

__END__

