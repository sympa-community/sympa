# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
# Copyright 2018 The Sympa Community. See the AUTHORS.md file at the
# top-level directory of this distribution and at
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

package Sympa::Constants;
use English;

use constant VERSION => '7.0' ;
use constant USER    => (getpwuid $UID)[0];
use constant GROUP   => (getgrgid $GID)[0];
use constant CONFIG           => 't/data/sympa.conf' ;
use constant WWSCONFIG        => 't/data/wwsympa.conf' ;
use constant SENDMAIL_ALIASES => 't/tmp/sympa_aliases' ;

use constant PIDDIR      => 't/tmp/piddir' ;
use constant EXPLDIR     => 't/tmp/expldir' ;
use constant SPOOLDIR    => 't/tmp/spooldir' ;
use constant SYSCONFDIR  => 't/tmp/sysconfdir' ;
use constant LOCALEDIR   => 't/tmp/localedir' ;
use constant LIBEXECDIR  => 't/tmp/libexecdir' ;
use constant SBINDIR     => 't/tmp/sbindir' ;
use constant SCRIPTDIR   => 't/tmp/scriptdir' ;
use constant MODULEDIR   => 't/tmp/moduledir' ;
use constant DEFAULTDIR  => 't/tmp/defaultdir' ;
use constant ARCDIR      => 't/tmp/arcdir' ;
use constant BOUNCEDIR   => 't/tmp/bouncedir' ;
use constant EXECCGIDIR  => 't/tmp/execcgidir' ;
use constant STATICDIR   => 't/tmp/staticdir' ;
use constant CSSDIR      => 't/tmp/cssdir' ;
use constant PICTURESDIR => 't/tmp/picturesdir' ;

use constant EMAIL_LEN  => 100;
use constant FAMILY_LEN => 50;
use constant LIST_LEN   => 50;
use constant ROBOT_LEN  => 80;
 
1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Constants - Definition of constants

=head1 DESCRIPTION

This module keeps definition of constants used by Sympa software.

=cut
