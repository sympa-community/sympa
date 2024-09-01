# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
# Copyright 2017, 2021, 2022, 2023 The Sympa Community. See the
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

package Sympa::Regexps;

use strict;
use warnings;

# domain name.
use constant domain => qr'[-\w]+(?:[.][-\w]+)+';

# These are relaxed variants of the syntax for mailbox described in RFC 5322.
# See also RFC 5322, 3.2.3 & 3.4.1 for details on format.
use constant email =>
    qr{(?:[A-Za-z0-9!\#\$%\&'*+\-/=?^_`{|}~.]+|"(?:\\.|[^\\"])*")\@[-\w]+(?:[.][-\w]+)+};

# This is older definition used by 6.2.65b and earlier.
#use constant addrspec => qr{(?:[-&+'./\w=]+|".*")\@[-\w]+(?:[.][-\w]+)+};

# This is the same as above except that it gave some groups, then regexp
# using it should also be changed.  By this reason it has been deprecated.
#use constant email => qr'([\w\-\_\.\/\+\=\'\&]+|\".*\")\@[\w\-]+(\.[\w\-]+)+';

use constant family_name => qr'[a-z0-9][a-z0-9\-\.\+_]*';
## Allow \s for template names
use constant template_name => qr'[a-zA-Z0-9][a-zA-Z0-9\-\.\+_\s]*';
#FIXME: Not matching with IPv6 address.
use constant host     => qr'[\w\.\-]+';
use constant hostport => qr{(?:
        [-.\w]+ (?::\d+)?
      | [:0-9a-f]*:[:0-9a-f]*:[:0-9a-f]*
      | \[ [:0-9a-f]*:[:0-9a-f]*:[:0-9a-f]* \] (?::\d+)?
    )}ix;
use constant html_date =>
    qr'[0-9]{4}[0-9]*-(?:0[1-9]|1[0-2])-(?:0[1-9]|[12][0-9]|3[01])';
use constant ipv6 => qr'[:0-9a-f]*:[:0-9a-f]*:[:0-9a-f]*'i;
#FIXME: Cannot contain IPv6 address.
use constant multiple_host_with_port =>
    '[\w\.\-]+(:\d+)?(,[\w\.\-]+(:\d+)?)*';
#FIXME: Cannot contain IPv6 address.
use constant multiple_host_or_url =>
    qr'([-\w]+://.+|[-.\w]+(:\d+)?)(,([-\w]+://.+|[-.\w]+(:\d+)?))*';
use constant listname => qr'[a-z0-9][a-z0-9\-\.\+_]*';

use constant ldap_attrdesc => qr'\w[-\w]*(?:;[-\w]+)*';    # RFC2251, 4.1.5

# "value" defined in RFC 2045, 5.1.
use constant rfc2045_parameter_value =>
    qr'[^\s\x00-\x1F\x7F-\xFF()<>\@,;:\\/\[\]?=\"]+';

use constant sql_query => qr'(SELECT|select).*';

# "scenario" was deprecated. Use "scenario_name".
# "scenario_config" is used for compatibility to earlier list config files.
use constant scenario_config => qr'[-.,\w]+';
use constant scenario_name   => qr'[-.\w]+';

use constant task        => qr'\w+';
use constant datasource  => qr'[\w-]+';
use constant uid         => qr'[\w\-\.\+]+';
use constant time        => qr'[012]?[0-9](?:\:[0-5][0-9])?';
use constant time_range  => __PACKAGE__->time . '-' . __PACKAGE__->time;
use constant time_ranges => time_range() . '(?:\s+' . time_range() . ')*';

use constant re => qr{
      (?:
        Antw                                    # Dutch
      | ATB                                     # Welsh
      | ATB \.                                  # Latvian
      | AW                                      # German
      | Odp                                     # Polish
      | R                                       # Italian
      | Re (?: \s* \( \d+ \) | \s* \[ \d+ \] | \*{1,2} \d+ | \^ \d+ )?
      | REF                                     # French
      | RES                                     # Portuguese
      | Rif                                     # Italian
      | SV                                      # Scandinavian
      | V\x{00E1}                               # Magyar, "VA"
      | VS                                      # Finnish
      | YNT                                     # Turkish
      | \x{05D4}\x{05E9}\x{05D1}                # Hebrew, "hashev"
      | \x{0391}\x{03A0}                        # Greek, "AP"
      | \x{03A3}\x{03A7}\x{0395}\x{03A4}        # Greek, "SChET"
      | \x{041D}\x{0410}                        # some Slavic in Cyrillic, "na"
      | \x{56DE}\x{590D}                        # Simp. Chinese, "huifu"
      | \x{56DE}\x{8986}                        # Trad. Chinese, "huifu"
      )
      \s* [:\x{FF1A}]
    }ix;

1;

__END__

=encoding utf-8

=head1 NAME

Sympa::Regexps - Definition of regular expressions

=head1 DESCRIPTION

This module keeps definition of regular expressions used by Sympa software.

=cut
