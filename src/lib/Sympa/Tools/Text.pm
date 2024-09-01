# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
# Copyright 2018, 2020, 2021, 2022 The Sympa Community. See the
# AUTHORS.md file at the top-level directory of this distribution and at
# <https://github.com/sympa-community/sympa.git>.
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
use feature qw(fc);
use Digest::MD5;
use Encode qw();
use English qw(-no_match_vars);
use Encode::MIME::Header;    # 'MIME-Q' encoding.
use HTML::Entities qw();
use MIME::Base64 qw();       # encode_base64url() needs 3.11 or later.
use MIME::EncWords;
use Text::LineFold;
use Unicode::GCString;
use URI::Escape qw();
BEGIN { eval 'use Unicode::Normalize qw()'; }
BEGIN { eval 'use Unicode::UTF8 qw()'; }

use Sympa::Language;
use Sympa::Regexps;

my $email_re = Sympa::Regexps::email();
my $email_like_re = sprintf '(?:<%s>|%s)', Sympa::Regexps::email(),
    Sympa::Regexps::email();

# Old name: tools::addrencode().
sub addrencode {
    my $addr    = shift;
    my $phrase  = (shift || '');
    my $charset = (shift || 'utf8');
    my $comment = (shift || '');

    return undef unless $addr =~ /\S/;

    # Eliminate hostile characters.
    $phrase =~ s/(\r\n|\r|\n)(?=[ \t])//g;
    $phrase =~ s/[\0\r\n]+//g;

    if ($phrase =~ /[^\s\x21-\x7E]/) {
        # String containing Non-ASCII should be encoded.
        $phrase = MIME::EncWords::encode_mimewords(
            Encode::decode('utf8', $phrase),
            'Encoding'    => 'A',
            'Charset'     => $charset,
            'Replacement' => 'FALLBACK',
            'Field'       => 'Resent-Sender', # almost longest
            'Minimal'     => 'DISPNAME',      # needs MIME::EncWords >= 1.012.
        );
    } elsif ($phrase =~ /[()<>\[\]:;\@\\,\"]/) {
        # Otherwise, the string has to be quoted when it is not a
        # dot-atom-text (RFC 5322 3.2.3).
        $phrase =~ s/([\\\"])/\\$1/g;
        $phrase = '"' . $phrase . '"';
    }

    if ($comment =~ /[^\s\x21-\x27\x2A-\x5B\x5D-\x7E]/) {
        $comment = MIME::EncWords::encode_mimewords(
            Encode::decode('utf8', $comment),
            'Encoding'    => 'A',
            'Charset'     => $charset,
            'Replacement' => 'FALLBACK',
            'Minimal'     => 'DISPNAME',
        );
    } elsif ($comment =~ /\S/) {
        $comment =~ s/([\\\"])/\\$1/g;
    }

    return
          ($phrase =~ /\S/  ? "$phrase "    : '')
        . ($comment =~ /\S/ ? "($comment) " : '')
        . "<$addr>";
}

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

# Old name: tools::clean_msg_id().
sub canonic_message_id {
    my $msg_id = shift;

    return $msg_id unless defined $msg_id;

    chomp $msg_id;

    if ($msg_id =~ /\<(.+)\>/) {
        $msg_id = $1;
    }

    return $msg_id;
}

sub canonic_text {
    my $text = shift;

    return undef unless defined $text;

    # Normalize text. See also discussion on
    # https://lists.sympa.community/msg/devel/2018-03/4QnaLDHkIC-7ZXa2e4npdQ
    #
    # N.B.: Corresponding modules are optional by now, and should be
    # mandatory in the future.
    my $utext;
    if (Encode::is_utf8($text)) {
        $utext = $text;
    } elsif ($Unicode::UTF8::VERSION) {
        no warnings 'utf8';
        $utext = Unicode::UTF8::decode_utf8($text);
    } else {
        $utext = Encode::decode_utf8($text);
    }
    if ($Unicode::Normalize::VERSION) {
        $utext = Unicode::Normalize::normalize('NFC', $utext);
    }

    # Remove DOS linefeeds (^M) that cause problems with Outlook 98, AOL,
    # and EIMS:
    $utext =~ s/\r\n|\r/\n/g;

    if (Encode::is_utf8($text)) {
        return $utext;
    } else {
        return Encode::encode_utf8($utext);
    }
}

sub slurp {
    my $path = shift;

    my $ifh;
    return undef unless open $ifh, '<', $path;
    my $text = do { local $RS; <$ifh> };
    close $ifh;

    return canonic_text($text);
}

sub wrap_text {
    my $text = shift;
    my $init = shift;
    my $subs = shift;
    my $cols = shift;

    $init //= '';
    $subs //= '';
    $cols //= 78;
    return $text unless $cols;

    my $linefold = Text::LineFold->new(
        Language   => Sympa::Language->instance->get_lang,
        Prep       => 'NONBREAKURI',
        prep       => [$email_like_re, sub { shift; @_ }],
        ColumnsMax => $cols,
        Format     => sub {
            shift;
            my $event = shift;
            my $str   = shift;
            if ($event =~ /^eo/)     { return "\n"; }
            if ($event =~ /^so[tp]/) { return $init . $str; }
            if ($event eq 'sol')     { return $subs . $str; }
            undef;
        },
    );

    my $t = Encode::is_utf8($text) ? $text : Encode::decode_utf8($text);

    my $ret = '';
    while (1000 < length $t) {
        my $s = substr $t, 0, 1000;
        $ret .= $linefold->break_partial($s);
        $t = substr $t, 1000;
    }
    $ret .= $linefold->break_partial($t) if length $t;
    $ret .= $linefold->break_partial(undef);

    return Encode::is_utf8($text) ? $ret : Encode::encode_utf8($ret);
}

sub decode_filesystem_safe {
    my $str = shift;
    return '' unless defined $str and length $str;

    $str = Encode::encode_utf8($str) if Encode::is_utf8($str);
    # On case-insensitive filesystem "_XX" along with "_xx" should be decoded.
    $str =~ s/_([0-9A-Fa-f]{2})/chr hex "0x$1"/eg;
    return $str;
}

sub decode_html {
    my $str = shift;

    Encode::encode_utf8(
        HTML::Entities::decode_entities(Encode::decode_utf8($str)));
}

sub encode_filesystem_safe {
    my $str = shift;
    return '' unless defined $str and length $str;

    $str = Encode::encode_utf8($str) if Encode::is_utf8($str);
    $str =~ s/([^-+.0-9\@A-Za-z])/sprintf '_%02x', ord $1/eg;
    return $str;
}

sub encode_html {
    my $str = shift;
    my $additional_unsafe = shift || '';

    HTML::Entities::encode_entities($str, '<>&"' . $additional_unsafe);
}

sub encode_uri {
    my $str     = shift;
    my %options = @_;

    # Note: URI-1.35 (URI::Escape 3.28) or later is required.
    return Encode::encode_utf8(
        URI::Escape::uri_escape_utf8(
            Encode::decode_utf8($str),
            '^-A-Za-z0-9._~' . (exists $options{omit} ? $options{omit} : '')
        )
    );
}

# Old name: tools::escape_chars().
# Moved to: Sympa::Upgrade::_escape_chars()
#sub escape_chars;

# Old name: tt2::escape_url().
# DEPRECATED.  Use Sympa::Tools::Text::escape_uri() or
# Sympa::Tools::Text::mailtourl().
#sub escape_url;

sub foldcase {
    my $str = shift;

    return '' unless defined $str and length $str;
    return Encode::encode_utf8(fc(Encode::decode_utf8($str)));
}

my %legacy_charsets = (
    'ar'    => [qw(iso-8859-6)],
    'bs'    => [qw(iso-8859-2)],
    'cs'    => [qw(iso-8859-2)],
    'eo'    => [qw(iso-8859-3)],
    'et'    => [qw(iso-8859-4)],
    'he'    => [qw(iso-8859-8)],
    'hr'    => [qw(iso-8859-2)],
    'hu'    => [qw(iso-8859-2)],
    'ja'    => [qw(euc-jp cp932 MacJapanese)],
    'kl'    => [qw(iso-8859-4)],
    'ko'    => [qw(cp949)],
    'lt'    => [qw(iso-8859-4)],
    'lv'    => [qw(iso-8859-4)],
    'mt'    => [qw(iso-8859-3)],
    'pl'    => [qw(iso-8859-2)],
    'ro'    => [qw(iso-8859-2)],
    'ru'    => [qw(koi8-r cp1251)],               # cp866? MacCyrillic?
    'sk'    => [qw(iso-8859-2)],
    'sl'    => [qw(iso-8859-2)],
    'th'    => [qw(iso-8859-11 cp874 MacThai)],
    'tr'    => [qw(iso-8859-9)],
    'uk'    => [qw(koi8-u)],                      # MacUkrainian?
    'zh-CN' => [qw(euc-cn)],
    'zh-TW' => [qw(big5-eten)],
);

sub guessed_to_utf8 {
    my $text  = shift;
    my @langs = @_;

    return Encode::encode_utf8($text) if Encode::is_utf8($text);
    return $text
        unless defined $text
        and length $text
        and $text =~ /[^\x00-\x7F]/;

    my $utf8;
    if ($Unicode::UTF8::VERSION) {
        $utf8 = Unicode::UTF8::decode_utf8($text)
            if Unicode::UTF8::valid_utf8($text);
    } else {
        $utf8 = eval { Encode::decode_utf8($text, Encode::FB_CROAK()) };
    }
    unless (defined $utf8) {
        foreach my $charset (map { $_ ? @$_ : () } @legacy_charsets{@langs}) {
            $utf8 =
                eval { Encode::decode($charset, $text, Encode::FB_CROAK()) };
            last if defined $utf8;
        }
    }
    unless (defined $utf8) {
        $utf8 = Encode::decode('iso-8859-1', $text);
    }

    # Apply NFC: e.g. for modified-NFD by Mac OS X.
    $utf8 = Unicode::Normalize::normalize('NFC', $utf8)
        if $Unicode::Normalize::VERSION;

    return Encode::encode_utf8($utf8);
}

sub mailtourl {
    my $text    = shift;
    my %options = @_;

    my $dtext =
          (not defined $text)   ? ''
        : $options{decode_html} ? Sympa::Tools::Text::decode_html($text)
        :                         $text;
    $dtext =~ s/\A\s+//;
    $dtext =~ s/\s+\z//;
    $dtext =~ s/(?:\r\n|\r|\n)(?=[ \t])//g;
    $dtext =~ s/\r\n|\r|\n/ /g;

    # The ``@'' in email address should not be encoded because some MUAs
    # aren't able to decode ``%40'' in e-mail address of mailto: URL.
    # Contrary, ``@'' in query component should be encoded because some
    # MUAs take it for a delimiter to separate URL from the rest.
    my ($format, $utext, $qsep);
    if ($dtext =~ /[()<>\[\]:;,\"\s]/) {
        # Use "to" header if source text includes any of RFC 5322
        # "specials", minus ``@'' and ``\'', plus whitespaces.
        $format = 'mailto:?to=%s%s';
        $utext  = Sympa::Tools::Text::encode_uri($dtext);
        $qsep   = '&';
    } else {
        $format = 'mailto:%s%s';
        $utext  = Sympa::Tools::Text::encode_uri($dtext, omit => '@');
        $qsep   = '?';
    }
    my $qstring = _url_query_string(
        $options{query},
        decode_html => $options{decode_html},
        leadchar    => $qsep,
        sepchar     => '&',
        trim_values => 1,
    );

    return sprintf $format, $utext, $qstring;
}

sub _url_query_string {
    my $query   = shift;
    my %options = @_;

    unless (ref $query eq 'HASH' and %$query) {
        return '';
    } else {
        my $decode_html = $options{decode_html};
        my $trim_values = $options{trim_values};
        return ($options{leadchar} || '?') . join(
            ($options{sepchar} || ';'),
            map {
                my ($dkey, $dval) = map {
                          (not defined $_) ? ''
                        : $decode_html ? Sympa::Tools::Text::decode_html($_)
                        :                $_;
                } ($_, $query->{$_});
                if ($trim_values and lc $dkey ne 'body') {
                    $dval =~ s/\A\s+//;
                    $dval =~ s/\s+\z//;
                    $dval =~ s/(?:\r\n|\r|\n)(?=[ \t])//g;
                    $dval =~ s/\r\n|\r|\n/ /g;
                }

                sprintf '%s=%s',
                    Sympa::Tools::Text::encode_uri($dkey),
                    Sympa::Tools::Text::encode_uri($dval);
            } sort keys %$query
        );
    }
}

sub permalink_id {
    my $message_id = shift;

    $message_id =~ s/[\s<>]//g;
    return MIME::Base64::encode_base64url(Digest::MD5::md5($message_id));
}

sub pad {
    my $str   = shift;
    my $width = shift;

    return $str unless $width and defined $str;

    my $ustr = Encode::is_utf8($str) ? $str : Encode::decode_utf8($str);
    my $cols = Unicode::GCString->new($ustr)->columns;

    unless ($cols < abs $width) {
        return $str;
    } elsif ($width < 0) {
        return $str . (' ' x (-$width - $cols));
    } else {
        return (' ' x ($width - $cols)) . $str;
    }
}

# Old name: tools::qdecode_filename().
sub qdecode_filename {
    my $filename = shift;

    ## We don't use MIME::Words here because it does not encode properly
    ## Unicode
    ## Check if string is already Q-encoded first
    #if ($filename =~ /\=\?UTF-8\?/) {
    $filename = Encode::encode_utf8(Encode::decode('MIME-Q', $filename));
    #}

    return $filename;
}

# Old name: tools::qencode_filename().
sub qencode_filename {
    my $filename = shift;

    ## We don't use MIME::Words here because it does not encode properly
    ## Unicode
    ## Check if string is already Q-encoded first
    ## Also check if the string contains 8bit chars
    unless ($filename =~ /\=\?UTF-8\?/
        || $filename =~ /^[\x00-\x7f]*$/) {

        ## Don't encode elements such as .desc. or .url or .moderate
        ## or .extension
        my $part = $filename;
        my ($leading, $trailing);
        $leading  = $1 if ($part =~ s/^(\.desc\.)//);    ## leading .desc
        $trailing = $1 if ($part =~ s/((\.\w+)+)$//);    ## trailing .xx

        my $encoded_part = MIME::EncWords::encode_mimewords(
            $part,
            Charset    => 'utf8',
            Encoding   => 'q',
            MaxLineLen => 1000,
            Minimal    => 'NO'
        );

        $filename = $leading . $encoded_part . $trailing;
    }

    return $filename;
}

sub clip {
    my $string = shift;
    return undef unless @_;
    my $length = shift;

    my ($gcstr, $blen);
    if (ref $string eq 'Unicode::GCString') {
        $gcstr = $string;
        $blen  = length Encode::encode_utf8($string->as_string);
    } elsif (Encode::is_utf8($string)) {
        $gcstr = Unicode::GCString->new($string);
        $blen  = length Encode::encode_utf8($string);
    } else {
        $gcstr = Unicode::GCString->new(Encode::decode_utf8($string));
        $blen  = length $string;
    }

    $length += $blen if $length < 0;
    return '' if $length < 0;             # out of range
    return $string if $blen <= $length;

    my $result = $gcstr->substr(0, _gc_length($gcstr, $length));

    if (ref $string eq 'Unicode::GCString') {
        return $result;
    } elsif (Encode::is_utf8($string)) {
        return $result->as_string;
    } else {
        return Encode::encode_utf8($result->as_string);
    }
}

sub _gc_length {
    my $gcstr  = shift;
    my $length = shift;

    return 0 unless $gcstr->length;
    return 0 unless $length;

    my ($shorter, $longer) = (0, $gcstr->length);
    while ($shorter < $longer) {
        my $cur = ($shorter + $longer + 1) >> 1;
        my $elen =
            length Encode::encode_utf8($gcstr->substr(0, $cur)->as_string);
        if ($elen <= $length) {
            $shorter = $cur;
        } else {
            $longer = $cur - 1;
        }
    }

    return $shorter;
}

# Old name: tools::unescape_chars().
# Moved to: Sympa::Upgrade::_unescape_chars().
#sub unescape_chars;

# Old name: tools::valid_email().
sub valid_email {
    my $email = shift;

    return undef
        unless defined $email and $email =~ /\A$email_re\z/;

    return 1;
}

sub weburl {
    my $base    = shift;
    my $paths   = shift;
    my %options = @_;

    my @paths = map {
        Sympa::Tools::Text::encode_uri(
              (not defined $_)      ? ''
            : $options{decode_html} ? Sympa::Tools::Text::decode_html($_)
            :                         $_
        );
    } @{$paths || []};

    my $qstring = _url_query_string(
        $options{query},
        decode_html => $options{decode_html},
        sepchar     => '&',
    );

    my $fstring;
    my $fragment = $options{fragment};
    if (defined $fragment) {
        $fstring = '#'
            . Sympa::Tools::Text::encode_uri(
            $options{decode_html}
            ? Sympa::Tools::Text::decode_html($fragment)
            : $fragment
            );
    } else {
        $fstring = '';
    }

    return sprintf '%s%s%s', join('/', grep { defined $_ } ($base, @paths)),
        $qstring, $fstring;
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

=item addrencode ( $addr, [ $phrase, [ $charset, [ $comment ] ] ] )

Returns formatted (and encoded) name-addr as RFC5322 3.4.

=item canonic_email ( $email )

I<Function>.
Returns canonical form of e-mail address.

Leading and trailing white spaces are removed.
Latin letters without accents are lower-cased.

For malformed inputs returns C<undef>.

=item canonic_message_id ( $message_id )

Returns canonical form of message ID without trailing or leading whitespaces
or C<E<lt>>, C<E<gt>>.

=item canonic_text ( $text )

Canonicalizes text.
C<$text> should be a binary string encoded by UTF-8 character set or
a Unicode string.
Forbidden sequences in binary string will be replaced by
U+FFFD REPLACEMENT CHARACTERs, and Normalization Form C (NFC) will be applied.

=item clip ( $string, $length )

I<Function>.
Clips $string according to $length by bytes,
considering boundary of grapheme clusters.
UTF-8 is assumed for $string as bytestring.

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

=item decode_html ( $str )

I<Function>.
Decodes HTML entities in a string encoded by UTF-8 or a Unicode string.

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

=item encode_html ( $str, [ $additional_unsafe ] )

I<Function>.
Encodes characters in a string $str to HTML entities.
By default
C<'E<lt>'>, C<'E<gt>'>, C<'E<amp>'> and C<'E<quot>'> are encoded.

Parameter:

=over

=item $str

String to be encoded.

=item $additional_unsafe

Character or range of characters additionally encoded as entity references.

This optional parameter was introduced on Sympa 6.2.37b.3.

=back

Returns:

Encoded string, I<not> stripping utf8 flag if any.

=item encode_uri ( $str, [ omit => $chars ] )

I<Function>.
Encodes potentially unsafe characters in the string using "percent" encoding
suitable for URIs.

Parameters:

=over

=item $str

String to be encoded.

=item omit =E<gt> $chars

By default, all characters except those defined as "unreserved" in RFC 3986
are encoded, that is, C<[^-A-Za-z0-9._~]>.
If this parameter is given, it will prevent encoding additional characters.

=back

Returns:

Encoded string, stripped C<utf8> flag if any.

=item escape_chars ( $str )

B<Deprecated>.
Use L</encode_filesystem_safe>.

Escape weird characters.

=item escape_url ( $str )

DEPRECATED.
Would be better to use L</"encode_uri"> or L</"mailtourl">.

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

=item guessed_to_utf8( $text, [ lang, ... ] )

I<Function>.
Guesses text charset considering language context
and returns the text reencoded by UTF-8.

Parameters:

=over

=item $text

Text to be reencoded.

=item lang, ...

Language tag(s) which may be given by L<Sympa::Language/"implicated_langs">.

=back

Returns:

Reencoded text.
If any charsets could not be guessed, C<iso-8859-1> will be used
as the last resort, just because it covers full range of 8-bit.

=item mailtourl ( $email, [ decode_html =E<gt> 1 ],
[ query =E<gt> {key =E<gt> val, ...} ] )

I<Function>.
Constructs a C<mailto:> URL for given e-mail.

Parameters:

=over

=item $email

E-mail address.

=item decode_html =E<gt> 1

If set, arguments are assumed to include HTML entities.

=item query =E<gt> {key =E<gt> val, ...}

Optional query.

=back

Returns:

Constructed URL.

=item pad ( $str, $width )

Pads space a string so that result will not be narrower than given width.

Parameters:

=over

=item $str

A string.

=item $width

If $width is false value or width of $str is not less than $width,
does nothing.
If $width is less than C<0>, pads right.
Otherwise, pads left.

=back

Returns:

Padded string.

=item permalink_id ( $message_id )

Calculates permalink ID from mesage ID.

=item qdecode_filename ( $filename )

Q-Decodes web file name.

ToDo:
This should be obsoleted in the future release: Would be better to use
L</decode_filesystem_safe>.

=item qencode_filename ( $filename )

Q-Encodes web file name.

ToDo:
This should be obsoleted in the future release: Would be better to use
L</encode_filesystem_safe>.

=item slurp ( $file )

Get entire content of the file.
Normalization by canonic_text() is applied.
C<$file> is the path to text file.

=item unescape_chars ( $str )

B<Deprecated>.
Use L</decode_filesystem_safe>.

Unescape weird characters.

=item valid_email ( $string )

Basic check of an email address.

=item weburl ( $base, \@paths, [ decode_html =E<gt> 1 ],
[ fragment =E<gt> $fragment ], [ query =E<gt> \%query ] )

Constructs a C<http:> or C<https:> URL under given base URI.

Parameters:

=over

=item $base

Base URI.

=item \@paths

Additional path components.

=item decode_html =E<gt> 1

If set, arguments are assumed to include HTML entities.
Exception is $base:
It is assumed not to include entities.

=item fragment =E<gt> $fragment

Optional fragment.

=item query =E<gt> \%query

Optional query.

=back

Returns:

A URI.

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

=back

=head1 HISTORY

L<Sympa::Tools::Text> appeared on Sympa 6.2a.41.

decode_filesystem_safe() and encode_filesystem_safe() were added
on Sympa 6.2.10.

decode_html(), encode_html(), encode_uri() and mailtourl()
were added on Sympa 6.2.14, and escape_url() was deprecated.

guessed_to_utf8() and pad() were added on Sympa 6.2.17.

canonic_text() and slurp() were added on Sympa 6.2.53b.

clip() was added on Sympa 6.2.61b.

=cut
