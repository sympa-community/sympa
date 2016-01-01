# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016 GIP RENATER
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

package Sympa::Tools::Text;

use strict;
use warnings;
use Encode qw();
use Text::LineFold;
use if (5.008 < $] && $] < 5.016), qw(Unicode::CaseFold fc);
use if (5.016 <= $]), qw(feature fc);

# Old names: tools::clean_email(), tools::get_canonical_email().
sub canonic_email {
    my $email = shift;

    return undef unless defined $email;

    # Remove leading and trailing white spaces.
    $email =~ s/\A\s+//;
    $email =~ s/\s+\z//;

    # Lower-case.
    $email =~ tr/A-Z/a-z/;

    return (length $email) ? $email : undef;
}

sub wrap_text {
    my $text = shift;
    my $init = shift;
    my $subs = shift;
    my $cols = shift;
    $cols = 78 unless defined $cols;
    return $text unless $cols;

    $text = Text::LineFold->new(
        Language      => Sympa::Language->instance->get_lang,
        OutputCharset => (Encode::is_utf8($text) ? '_UNICODE_' : 'utf8'),
        Prep          => 'NONBREAKURI',
        ColumnsMax    => $cols
    )->fold($init, $subs, $text);

    return $text;
}

sub decode_filesystem_safe {
    my $str = shift;
    return '' unless defined $str and length $str;

    $str = Encode::encode_utf8($str) if Encode::is_utf8($str);
    # On case-insensitive filesystem "_XX" along with "_xx" should be decoded.
    $str =~ s/_([0-9A-Fa-f]{2})/chr hex "0x$1"/eg;
    return $str;
}

sub encode_filesystem_safe {
    my $str = shift;
    return '' unless defined $str and length $str;

    $str = Encode::encode_utf8($str) if Encode::is_utf8($str);
    $str =~ s/([^-+.0-9\@A-Za-z])/sprintf '_%02x', ord $1/eg;
    return $str;
}

sub foldcase {
    my $str = shift;
    return '' unless defined $str and length $str;

    if ($] <= 5.008) {
        # Perl 5.8.0 does not support Unicode::CaseFold. Use lc() instead.
        return Encode::encode_utf8(lc(Encode::decode_utf8($str)));
    } else {
        # later supports it. Perl 5.16.0 and later have built-in fc().
        return Encode::encode_utf8(fc(Encode::decode_utf8($str)));
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Tools::Text - Text-related functions

=head1 DESCRIPTION

This package provides some text-related functions.

=head2 Functions

=over

=item canonic_email ( $email )

I<Function>.
Returns canonical form of e-mail address.

Leading and trailing whilte spaces are removed.
Latin letters without accents are lower-cased.

For malformed inputs returns C<undef>.

=item wrap_text ( $text, [ $init_tab, [ $subsequent_tab, [ $cols ] ] ] )

I<Function>.
Returns line-wrapped text.

Parameters:

=over

=item $text

The text to be folded.

=item $init_tab

Indentation prepended to the first line of paragraph.
Default is C<''>, no indentation.

=item $subsequent_tab

Indentation prepended to each subsequent line of folded paragraph.
Default is C<''>, no indentation.

=item $cols

Max number of columns of folded text.
Default is C<78>.

=back

=item decode_filesystem_safe ( $str )

I<Function>.
Decodes a string encoded by encode_filesystem_safe().

Parameter:

=over

=item $str

String to be decoded.

=back

Returns:

Decoded string, stripped C<utf8> flag if any.

=item encode_filesystem_safe ( $str )

I<Function>.
Encodes a string $str to be suitable for filesystem.

Parameter:

=over

=item $str

String to be encoded.

=back

Returns:

Encoded string, stripped C<utf8> flag if any.
All bytes except C<'-'>, C<'+'>, C<'.'>, C<'@'>
and alphanumeric characters are encoded to sequences C<'_'> followed by
two hexdigits.

Note that C<'/'> will also be encoded.

=item foldcase ( $str )

I<Function>.
Returns "fold-case" string suitable for case-insensitive match.
For example, a code below looks for a needle in haystack not regarding case,
even if they are non-ASCII UTF-8 strings.

  $haystack = Sympa::Tools::Text::foldcase($HayStack);
  $needle   = Sympa::Tools::Text::foldcase($NeedLe);
  if (index $haystack, $needle >= 0) {
      ...
  }

Parameter:

=over

=item $str

A string.

=back

=back

=head1 HISTORY

L<Sympa::Tools::Text> appeared on Sympa 6.2a.41.

decode_filesystem_safe() and encode_filesystem_safe() were added
on Sympa 6.2.10.

=cut
