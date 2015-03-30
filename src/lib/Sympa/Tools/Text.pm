# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015 GIP RENATER
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
use Text::LineFold;
use if (5.008 < $] && $] < 5.016), qw(Unicode::CaseFold fc);
use if (5.016 <= $]), qw(feature fc);

#*******************************************
# Function : wrap_text
# Description : return line-wrapped text.
## IN : text, init, subs, cols
#*******************************************
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

#*******************************************
## Function : foldcase
## Description : returns "fold-case" string suitable for case-insensitive
## match.
### IN : str
##*******************************************
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
