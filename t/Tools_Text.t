# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

use strict;
use warnings;

use Test::More;

use Sympa::Tools::Text;

plan tests => 3;

my $email = q{&'+-./09=A@Z.a-z};
is Sympa::Tools::Text::canonic_email($email),
    q{&'+-./09=a@z.a-z}, 'canonic_email';
is Sympa::Tools::Text::canonic_email("\t\r\n "), undef,
    'canonic_email, whitespaces';
is Sympa::Tools::Text::canonic_email(undef), undef,
    'canonic_email, undefined value';

# ToDo: foldcase()
# ToDo: wrap_text()
