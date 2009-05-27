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

package tt2;

use strict;

use Template;
use CGI::Util;
use MIME::EncWords; 
use Log;
use Language;
use Sympa::Constants;
use Sympa::Template::Compat;

my $current_lang;
my $last_error;

sub qencode {
    my $string = shift;
    # We are not able to determine the name of header field, so assume
    # longest (maybe) one.    
    return MIME::EncWords::encode_mimewords(Encode::decode('utf8', $string),
					    Encoding=>'A',
					    Charset=>&Language::GetCharset(),
					    Field=>"message-id");
}

sub escape_url {

    my $string = shift;
    
    $string =~ s/[\s+]/sprintf('%%%02x', ord($&))/eg;
    # Some MUAs aren't able to decode ``%40'' (escaped ``@'') in e-mail 
    # address of mailto: URL, or take ``@'' in query component for a 
    # delimiter to separate URL from the rest.
    my ($body, $query) = split(/\?/, $string, 2);
    if (defined $query) {
	$query =~ s/\@/sprintf('%%%02x', ord($&))/eg;
	$string = $body.'?'.$query;
    }
    
    return $string;
}

sub escape_xml {
    my $string = shift;
    
    $string =~ s/&/&amp;/g; 
    $string =~ s/</&lt;/g;
    $string =~ s/>/&gt;/g;
    $string =~ s/\'/&apos;/g;
    $string =~ s/\"/&quot;/g;
    
    return $string;
}

sub escape_quote {
    my $string = shift;

    $string =~ s/\'/\\\'/g; 
    $string =~ s/\"/\\\"/g;

    return $string;
}

sub encode_utf8 {
    my $string = shift;

    ## Skip if already internally tagged utf8
    if (&Encode::is_utf8($string)) {
	return &Encode::encode_utf8($string);
    }

    return $string;

}

sub decode_utf8 {
    my $string = shift;

    ## Skip if already internally tagged utf8
    unless (&Encode::is_utf8($string)) {
	## Wrapped with eval to prevent Sympa process from dying
	## FB_CROAK is used instead of FB_WARN to pass $string intact to succeeding processes it operation fails
	eval {
	    $string = &Encode::decode('utf8', $string, Encode::FB_CROAK);
	};
	$@ = '';
    }

    return $string;

}

sub maketext {
    my ($context, @arg) = @_;

    my $stash = $context->stash();
    my $component = $stash->get('component');
    my $template_name = $component->{'name'};
    my ($provider) = grep { $_->{HEAD}[2] eq $component } @{ $context->{LOAD_TEMPLATES} };
    my $path = $provider->{HEAD}[1] if $provider;

    ## Strangely the path is sometimes empty...
    ## TODO : investigate
#    &do_log('notice', "PATH: $path ; $template_name");

    ## Sample code to dump the STASH
    # my $s = $stash->_dump();    

    return sub {
	&Language::maketext($template_name, $_[0],  @arg);
    }	
}

# IN:
#    $fmt: strftime() style format string.
#    $arg: a string representing date/time:
#          "YYYY/MM", "YYYY/MM/DD", "YYYY/MM/DD/HH/MM", "YYYY/MM/DD/HH/MM/SS"
# OUT:
#    Subref to generate formatted (i18n'ized) date/time.
sub locdatetime {
    my ($fmt, $arg) = @_;
    if ($arg !~ /^(\d{4})\D(\d\d?)(?:\D(\d\d?)(?:\D(\d\d?)\D(\d\d?)(?:\D(\d\d?))?)?)?/) {
	return sub { gettext("(unknown date)"); };
    } else {
	my @arg = ($6+0, $5+0, $4+0, $3+0 || 1, $2-1, $1-1900, 0,0,0);
        return sub { gettext_strftime($_[0], @arg); };
    }
}

## To add a directory to the TT2 include_path
sub add_include_path {
    my $path = shift;

    push @other_include_path, $path;
}

## Get current INCLUDE_PATH
sub get_include_path {
    return @other_include_path;
}

## Allow inclusion/insertion of file with absolute path
sub allow_absolute_path {
    $allow_absolute = 1;
}

## Return the last error message
sub get_error {

    return $last_error;
}

## The main parsing sub
## Parameters are   
## data: a HASH ref containing the data   
## template : a filename or a ARRAY ref that contains the template   
## output : a Filedescriptor or a SCALAR ref for the output

sub parse_tt2 {
    my ($data, $template, $output, $include_path, $options) = @_;
    $include_path ||= [Sympa::Constants::DEFAULTDIR];

    ## Add directories that may have been added
    push @{$include_path}, @other_include_path;
    @other_include_path = (); ## Reset it

    my $wantarray;

    ## An array can be used as a template (instead of a filename)
    if (ref($template) eq 'ARRAY') {
	$template = \join('', @$template);
    }

    &Language::SetLang($data->{lang}) if ($data->{'lang'});

    my $config = {
	# ABSOLUTE => 1,
	INCLUDE_PATH => $include_path,
#	PRE_CHOMP  => 1,
	UNICODE => 0, # Prevent BOM auto-detection
	
	FILTERS => {
	    unescape => \&CGI::Util::unescape,
	    l => [\&tt2::maketext, 1],
	    loc => [\&tt2::maketext, 1],
	    helploc => [\&tt2::maketext, 1],
	    locdt => [\&tt2::locdatetime, 1],
	    qencode => [\&qencode, 0],
 	    escape_xml => [\&escape_xml, 0],
	    escape_url => [\&escape_url, 0],
	    escape_quote => [\&escape_quote, 0],
	    decode_utf8 => [\&decode_utf8, 0],
	    encode_utf8 => [\&encode_utf8, 0]
	    }
    };
    
    if ($allow_absolute) {
	$config->{'ABSOLUTE'} = 1;
	$allow_absolute = 0;
    }

    my $tt2 = Template->new($config) or die "Template error: ".Template->error();

    unless ($tt2->process($template, $data, $output)) {
	$last_error = $tt2->error();
	&do_log('err', 'Failed to parse %s : %s', $template, $tt2->error());
	&do_log('err', 'Looking for TT2 files in %s', join(',',@{$include_path}));


	return undef;
    } 

    return 1;
}


1;
