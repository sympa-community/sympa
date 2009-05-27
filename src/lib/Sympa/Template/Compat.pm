# $Id$
#
# Sympa - SYsteme de Multi-Postage Automatique
# Copyright (c) 1997, 1998, 1999, 2000, 2001 Comite Reseau des Universites
# Copyright (c) 1997,1998, 1999 Institut Pasteur & Christophe Wolfhugel
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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

# TT2 adapter for sympa's template system - Chia-liang Kao <clkao@clkao.org>
# usage: replace require 'parser.pl' in wwwsympa and other .pl

package Sympa::Template::Compat;

use strict;
use base 'Template::Provider';
use Encode;

my @other_include_path;
my $allow_absolute;

sub _load {
	my ($self, $name, $alias) = @_;
	my ($data, $error) = $self->SUPER::_load($name, $alias);
	$data->{text} = _translate($data->{text});

	return ($data, $error);
}

sub _translate {
    local $_ = join('', @_);

    # if / endif
    s/\[\s*(ELSIF|IF)\s+(.*?)\s*=\s*(.*?)\s*\]/[% \U$1\E $2 == '$3' %]/ig;
    s/\[\s*(ELSIF|IF)\s+(.*?)\s*<>\s*(.*?)\s*\]/[% \U$1\E $2 != '$3' %]/ig;
    s/\[\s*(ELSIF|IF)\s+(.*?)\s*\]/[% \U$1\E $2 %]/ig;
    s/\[\s*ELSE\s*\]/[% ELSE %]/ig;
    s/\[\s*ENDIF\s*\]/[% END %]/ig;

    # parse -> process
    s/\[\s*PARSE\s*('.*?')\s*\]/[% PROCESS $1 %]/ig;
    s/\[\s*PARSE\s*(.*?)\]/[% PROCESS \$$1 IF $1 %]/ig;

    # variable access
    while(s/\[(.*?)([^\]-]+?)->(\d+)(.*)\]/[$1$2.item('$3')$4]/g){};
    while(s/\[(.*?)([^\]-]+?)->(\w+)(.*)\]/[$1$2.$3$4]/g){};
    s/\[\s*SET\s+(\w+)=(.*?)\s*\]/[% SET $1 = $2 %]/ig;

    # foreach
    s/\[\s*FOREACH\s*(\w+)\s*IN\s*([\w.()\'\/]+)\s*\]/[% FOREACH $1 = $2 %]
    [% SET tmp = $1.key $1 = $1.value $1.NAME = tmp IF $1.key.defined %]/ig;
    s/\[\s*END\s*\]/[% END %]/ig;

    # sanity check before including file
    s/\[\s*INCLUDE\s*('.*?')\s*\]/[% INSERT $1 %]/ig;
    s/\[\s*INCLUDE\s*(\w+?)\s*\]/[% INSERT \$$1 IF $1 %]/ig;

    ## Be careful to absolute path
    if (/\[%\s*(PROCESS|INSERT)\s*\'(\S+)\'\s*%\]/) {
	my $file = $2;
	my $new_file = $file;
	$new_file =~ s/\.tpl$/\.tt2/;
	my @path = split /\//, $new_file;
	$new_file = $path[$#path];
	s/\'$file\'/\'$new_file\'/;
    }

    # setoption
    s/\[\s*SETOPTION\s(escape_)?html.*?\]/[% FILTER html_entity %]/ig;
    s/\[\s*SETOPTION\signore_undef.*?\]/[% IF 1 %]/ig;
    s/\[\s*UNSETOPTION.*?\]/[% END %]/ig;

    s/\[\s*([\w.()\'\/]+)\s*\]/[% $1 %]/g;

    s/\[\s*(STOP|START)PARSE\s*\]//ig;

    $_;
}

1;
