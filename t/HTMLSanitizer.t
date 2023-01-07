# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

use strict;
use warnings;
use English qw(-no_match_vars);
use Test::More;

use Sympa::HTMLSanitizer;

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
},
    'Avoid ReDoS with style attribute';
if ($EVAL_ERROR) {
    diag $EVAL_ERROR;
} else {
    $sanitized =~ s/\n//g;
    is $sanitized,
        '<html><head></head><body><div style="color:white; background-color:black"></div></body></html>',
        'Scrub style attribute';
}

done_testing();

__END__

