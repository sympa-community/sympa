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

my @other_include_path;
my $allow_absolute;

sub _load {
	my ($self, $name, $alias) = @_;
	my ($data, $error) = $self->SUPER::_load($name, $alias);
	$data->{text} = _translate($data->{text});

=comment

	my $newname = $name;
	$newname =~ s|(.*)/([^/]+)$|$2|;

	open my $fh, ">/tmp/tt2/$newname";
	print $fh $data->{text};
	close $fh;

=cut

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
    s/\[\s*FOREACH\s*(\w+)\s*IN\s*([\w.()'\/]+)\s*\]/[% FOREACH $1 = $2 %]
    [% SET tmp = $1.key $1 = $1.value $1.NAME = tmp IF $1.key.defined %]/ig;
    s/\[\s*END\s*\]/[% END %]/ig;

    # sanity check before including file
    s/\[\s*INCLUDE\s*(\w+?)\s*\]/[% INSERT \$$1 IF $1 %]/ig;

    # setoption
    s/\[\s*SETOPTION\s(escape_)?html.*?\]/[% FILTER html_entity %]/ig;
    s/\[\s*SETOPTION\signore_undef.*?\]/[% IF 1 %]/ig;
    s/\[\s*UNSETOPTION.*?\]/[% END %]/ig;

    s/\[\s*([\w.()'\/]+)\s*\]/[% $1 %]/g;

    s/\[\s*(STOP|START)PARSE\s*\]//ig;

    $_;
}

1;

package tt2;

use strict;
use Template;
use CGI::Util;
use Log;
use Language;

my $current_lang;

sub qencode {
    my $string = shift;

    return MIME::Words::encode_mimewords($string, 'Q', gettext("_charset_"));
}

sub maketext {
    my ($context, @arg) = @_;

    return sub {
	&Language::maketext($_[0], @arg);
    }
}

## To add a directory to the TT2 include_path
sub add_include_path {
    my $path = shift;

    push @other_include_path, $path;
}

## Allow inclusion/insertion of file with absolute path
sub allow_absolute_path {
    $allow_absolute = 1;
}

## The main parsing sub
## Parameters are   
## data: a HASH ref containing the data   
## template : a filename or a ARRAY ref that contains the template   
## output : a Filedescriptor or a SCALAR ref for the output

sub parse_tt2 {
    my ($data, $template, $output, $include_path) = @_;
    $include_path ||= ['--ETCBINDIR--'];

    ## Add directories that may have been added
    push @{$include_path}, @other_include_path;
    @other_include_path = []; ## Reset it

    my $wantarray;

    ## An array can be used as a template (instead of a filename)
    if (ref($template) eq 'ARRAY') {
	$template = \join('', @$template);
    }

    # quick hack! wrong layer!
    s|^/home/sympa/bin/etc/wws_templates/(.*?)(\...)?(\.tpl)|$1.tt2|
	for values %$data;

#    &do_log('notice', 'TPL: %s ; LANG: %s', $template, $data->{lang});

    &Language::SetLang($data->{lang});

    my $config = {
	# ABSOLUTE => 1,
	INCLUDE_PATH => $include_path,
	
	FILTERS => {
	    unescape => \&CGI::Util::unescape,
	    l => [\&maketext, 1],
	    loc => [\&maketext, 1],
	    qencode => [\&qencode, 0]
	    },
       #PRE_CHOMP   => 1,
       #POST_CHOMP   => 1,
	    };

    if ($allow_absolute) {
	$config->{'ABSOLUTE'} = 1;
	$allow_absolute = 0;
    }

    my $tt2 = Template->new($config) or die $!;

    unless ($tt2->process($template, $data, $output)) {
	&do_log('err', 'Failed to parse %s : %s', $template, $tt2->error());
	return undef;
    } 
}


1;
