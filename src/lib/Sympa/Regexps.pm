# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
# Copyright 2017 The Sympa Community. See the AUTHORS.md file at the top-level
# directory of this distribution and at
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

# This is the same as email below except that it does never give any groups.
use constant addrspec => qr{(?:[-&+'./\w=]+|".*")\@[-\w]+(?:[.][-\w]+)+};
# Caution: If this regexp changes (more/less parenthesis), then regexp using
# it should also be changed.  By this reason it would be obsoleted.
use constant email => qr'([\w\-\_\.\/\+\=\'\&]+|\".*\")\@[\w\-]+(\.[\w\-]+)+';
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
use constant ipv6 => qr'[:0-9a-f]*:[:0-9a-f]*:[:0-9a-f]*'i;
#FIXME: Cannot contain IPv6 address.
use constant multiple_host_with_port =>
    '[\w\.\-]+(:\d+)?(,[\w\.\-]+(:\d+)?)*';
#FIXME: Cannot contain IPv6 address.
use constant multiple_host_or_url =>
    qr'([-\w]+://.+|[-.\w]+(:\d+)?)(,([-\w]+://.+|[-.\w]+(:\d+)?))*';
use constant listname => qr'[a-z0-9][a-z0-9\-\.\+_]*';

use constant ldap_attrdesc => qr'\w[-\w]*(?:;[-\w]+)*';    # RFC2251, 4.1.5
use constant sql_query     => qr'(SELECT|select).*';

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

use constant re =>
    qr'(?i)(?:AW|(?:\xD0\x9D|\xD0\xBD)(?:\xD0\x90|\xD0\xB0)|Re(?:\^\d+|\*\d+|\*\*\d+|\[\d+\])?|Rif|SV|VS|Antw|\xCE\x91(?:\xCE\xA0|\xCF\x80)|\xCE\xA3(?:\xCE\xA7\xCE\x95\xCE\xA4|\xCF\x87\xCE\xB5\xCF\x84)|Odp|YNT)\s*:';
# (de | ru etc. | en, la etc. | it | da, sv | fi | nl | el | el | pl | tr).

1;

__END__

=encoding utf-8

=head1 NAME

Sympa::Regexps - Definition of regular expressions

=head1 DESCRIPTION

This module keeps definition of regular expressions used by Sympa software.

=cut
