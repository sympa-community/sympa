# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014 GIP RENATER
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
no warnings 'ambiguous';

## Regexps for list params
## Caution : if this regexp changes (more/less parenthesis), then regexp using
## it should also be changed
use constant email => '([\w\-\_\.\/\+\=\'\&]+|\".*\")\@[\w\-]+(\.[\w\-]+)+';
use constant family_name   => '[a-z0-9][a-z0-9\-\.\+_]*';
use constant template_name => '[a-zA-Z0-9][a-zA-Z0-9\-\.\+_\s]*';  ## Allow \s
use constant host          => '[\w\.\-]+';
use constant multiple_host_with_port =>
    '[\w\.\-]+(:\d+)?(,[\w\.\-]+(:\d+)?)*';
use constant listname    => '[a-z0-9][a-z0-9\-\.\+_]{0,49}';
use constant sql_query   => '(SELECT|select).*';
use constant scenario    => '[\w,\.\-]+';
use constant task        => '\w+';
use constant datasource  => '[\w-]+';
use constant uid         => '[\w\-\.\+]+';
use constant time        => '[012]?[0-9](?:\:[0-5][0-9])?';
use constant time_range  => __PACKAGE__->time . '-' . __PACKAGE__->time;
use constant time_ranges => time_range() . '(?:\s+' . time_range() . ')*';

use constant re =>
    '(?i)(?:AW|(?:\xD0\x9D|\xD0\xBD)(?:\xD0\x90|\xD0\xB0)|Re(?:\^\d+|\*\d+|\*\*\d+|\[\d+\])?|Rif|SV|VS|Antw|\xCE\x91(?:\xCE\xA0|\xCF\x80)|\xCE\xA3(?:\xCE\xA7\xCE\x95\xCE\xA4|\xCF\x87\xCE\xB5\xCF\x84)|Odp|YNT)\s*:';
# (de | ru etc. | en, la etc. | it | da, sv | fi | nl | el | el | pl | tr).

1;
