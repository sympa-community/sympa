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

package Bounce;

use strict;
use warnings;
use English qw(no_match_vars);

use Mail::Address;
use MIME::Parser;

# RFC1891 compliance check
# Moved: Use _parse_dsn() in bounced.pl.
#sub rfc1891;

## Corrige une adresse SMTP
# Moved: Use _corrige() in bounced.pl.
#sub corrige;

## Analyse d'un rapport de non-remise
## Param 1 : descripteur du fichier contenant le bounce
## //    2 : reference d'un hash pour retourner @ en erreur
## //    3 : reference d'un tableau pour retourner des stats
## //    4 : reference d'un tableau pour renvoyer le bounce
# Moved: Use _anabounce() in bouncde.pl.
#sub anabounce;

1;
