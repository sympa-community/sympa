# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

use strict;
use warnings;
use Encode qw();
use Test::More;

use Sympa::Tools::Text;

my $email = q{&'+-./09=_A@Z.a-z};
my $unicode_email =
    qq{\x{60c5}\x{5831}\@\x{30c9}\x{30e1}\x{30a4}\x{30f3}\x{540d}\x{4f8b}.jp};

is Sympa::Tools::Text::canonic_email($email),
    q{&'+-./09=_a@z.a-z}, 'canonic_email';
is Sympa::Tools::Text::canonic_email($unicode_email),
    $unicode_email, 'canonic_email, intl\'ed';
is Sympa::Tools::Text::canonic_email("\t\r\n "), undef,
    'canonic_email, whitespaces';
is Sympa::Tools::Text::canonic_email(undef), undef,
    'canonic_email, undefined value';

is Sympa::Tools::Text::encode_filesystem_safe($email),
    q{_26_27+-._2f09_3d_5fA@Z.a-z}, 'encode_filesystem_safe';
is Sympa::Tools::Text::encode_filesystem_safe(undef), '',
    'encode_filesystem_safe, undefined value';
my $enc = Sympa::Tools::Text::encode_filesystem_safe($unicode_email);
is $enc,
    q{_e6_83_85_e5_a0_b1@_e3_83_89_e3_83_a1_e3_82_a4_e3_83_b3_e5_90_8d_e4_be_8b.jp},
    'encode_filesystem_safe, Unicode';
ok !Encode::is_utf8($enc), 'encode_filesystem_safe, utf8 flag';

is Sympa::Tools::Text::decode_filesystem_safe(q{_26_27+-._2f09_3d_5fA@Z.a-z}),
    $email, 'decode_filesystem_safe';
is Sympa::Tools::Text::decode_filesystem_safe(q{_26_27+-._2F09_3D_5FA@Z.a-z}),
    $email, 'decode_filesystem_safe, uppercase';
is Sympa::Tools::Text::decode_filesystem_safe(undef), '',
    'decode_filesystem_safe, undefined value';
my $dec = Sympa::Tools::Text::decode_filesystem_safe(
    q{_e6_83_85_e5_a0_b1@_e3_83_89_e3_83_a1_e3_82_a4_e3_83_b3_e5_90_8d_e4_be_8b.jp}
);
ok !Encode::is_utf8($dec), 'decode_filesystem_safe, utf8 flag';
Encode::_utf8_on($dec);
is $dec, $unicode_email, 'decode_filesystem_safe, Unicode';

# ToDo: foldcase()
# ToDo: wrap_text()

# Noncharacters: U+D800, U+10FFE, U+110000, U+200000
is Sympa::Tools::Text::canonic_text(
    "\xED\xA0\x80\n\xF4\x8F\xBF\xBE\n\xF4\x90\x80\x80\n\xF8\x88\x80\x80\x80\n"
    ),
    Encode::encode_utf8(
    "\x{FFFD}\x{FFFD}\x{FFFD}\n\x{FFFD}\n\x{FFFD}\x{FFFD}\x{FFFD}\x{FFFD}\n\x{FFFD}\x{FFFD}\x{FFFD}\x{FFFD}\x{FFFD}\n"
    ),
    'canonic_text';

done_testing();
