# Language.pm - This module does just the initial setup for the international messages
# RCS Identication ; $Revision$ ; $Date$ 
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

package Language;

require Exporter;
use Carp;
@ISA = qw(Exporter);
@EXPORT = qw(Msg &gettext);

use strict;
use Log;
use Version;
use POSIX qw (setlocale);
use Locale::Messages qw (:locale_h :libintl_h !gettext);

my %msghash;     # Hash organization is like Messages file: File>>Sections>>Messages
my %set_comment; #sets-of-messages comment   

## The lang is the NLS catalogue name ; locale is the locale preference
## Ex: lang = fr ; locale = fr_FR
my ($current_lang, $current_locale);
my $default_lang;
## This was the old style locale naming, used for templates, nls, scenario
my %language_equiv = ( 'zh_CN' => 'cn',
		       'zh_TW' => 'tw',
		       'cs'    => 'cz',
		       'en_US' => 'us',
		       );

## Supported languages
my @supported_languages = ('cs_CZ','de_DE','en_US','es_ES','et_EE',
			   'fi_FI','fr_FR','hu_HU','it_IT','nl_NL',
			   'pl_PL','pt_PT','ro_RO','zh_CN','zh_TW');

my %lang2locale = ('cz' => 'cs_CZ',
		   'de' => 'de_DE',
		   'us' => 'en_US',
		   'es' => 'es_ES',
		   'et' => 'et_EE',
		   'fi' => 'fi_FI',
		   'fr' => 'fr_FR',
		   'hu' => 'hu_HU',
		   'it' => 'it_IT',
		   'nl' => 'nl_NL',
		   'pl' => 'pl_PL',
		   'pt' => 'pt_PT',
		   'ro' => 'ro_RO',
		   'cn' => 'zh_CN',
		   'tw' => 'zh_TW');

sub GetSupportedLanguages {
    my $robot = shift;
    my @lang_list;
    
    foreach my $l (split /,/,&Conf::get_robot_conf($robot, 'supported_lang')) {
	push @lang_list, $lang2locale{$l}||$l;
    }
    return @lang_list;
}

sub SetLang {
###########
    my $locale = shift;
    &do_log('debug', 'Language::SetLang(%s)', $locale);

    my $lang = $locale;

    unless ($lang) {
	&do_log('err','Language::SetLang(), missing locale parameter');
	return undef;
    }

   if (length($locale) == 2) {
	$locale = $lang2locale{$lang};
    }else {
	## Get the NLS equivalent for the lang
	if (defined $language_equiv{$lang}) {
	    $lang = $language_equiv{$lang};
	}else {
	    ## remove the country part 
	    $lang =~ s/_\w{2}$//;
	}
    }
   
    ## Set Locale::Messages context
    unless (setlocale(&POSIX::LC_ALL, $locale)) {
	&do_log('err','Failed to setlocale(%s)', $locale);
	return undef;
    }
    &Locale::Messages::textdomain("sympa");
    &Locale::Messages::bindtextdomain('sympa','--DIR--/locale');
    #bind_textdomain_codeset sympa => 'iso-8859-1';

    $current_lang = $lang;
    $current_locale = $locale;

    return $locale;
}#SetLang

sub GetLang {
############

    return $current_lang;
}

sub maketext {
    my $msg = shift;

#    &do_log('notice','Maketext: %s', $msg);

    ## xgettext.pl bug adds a \n to multi-lined strings
    if ($msg =~ /\n.+/m) {
	$msg .= "\n";
    }

    my $translation = &gettext ($msg);

    ## replace parameters in string
    $translation =~ s/\%(\d+)/$_[$1-1]/eg;

    return $translation;
}

sub gettext {

    ## This prevents meta information to be returned if the string to translate is empty
    if ($_[0] eq '') {
	return '';
	
	## return meta information on the catalogue (language, charset, encoding,...)
    }elsif ($_[0] =~ '^_(\w+)_$') {
	my $var = $1;
	foreach (split /\n/,&Locale::Messages::gettext('')) {
	    if ($var eq 'language') {
		if (/^Language-Team:\s*(.+)$/i) {
		    return $1;
		}
	    }elsif ($var eq 'charset') {
		if (/^Content-Type:\s*.*charset=(\S+)$/i) {
		    return $1;
		}
	    }elsif ($var eq 'encoding') {
		if (/^Content-Transfer-Encoding:\s*(.+)$/i) {
		    return $1;
		}
	    }
	}
	return '';
    }

    &Locale::Messages::gettext(@_);
}

1;

