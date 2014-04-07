# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$
#
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

package Sympa::Language;

use strict;
use warnings;
use Locale::Messages '1.22';    # virtually same as 1.23.
use POSIX qw();

use Sympa::Constants;

BEGIN {
    ## Using the Pure Perl implementation of gettext
    ## This is required on Solaris : native implementation of gettext does not
    ## map ll_RR with ll.
    ## libintl-perl 1.23 or later is required to use 'gettext_dumb' package
    ## which is independent from POSIX locale.
    Locale::Messages->select_package('gettext_dumb');
    ## Workaround: Prevent from searching catalogs in /usr/share/locale.
    undef $Locale::gettext_pp::__gettext_pp_default_dir;
}

INIT {
    ## Initialize lang/locale.
    SetLang('en');
}

## The locale is the gettext catalog name; lang is the IETF language tag.
## Ex: locale = pt_BR ; lang = pt-BR
my ($current_lang, $current_locale, $current_charset, @previous_lang);

## The map to get language tag from older non-POSIX locale naming.
my %language_equiv = (
    'cn' => 'zh-CN',
    'tw' => 'zh-TW',
    'cz' => 'cs',
    'us' => 'en-US',
);

## The map to get appropriate POSIX locale name from language code.
## Why this is required is that on many systems locales often have canonic
## "ll_RR.ENCODING" names only.  n.b. This format can not express all
## languages in proper way, e.g. Common Arabic ("ar"), Esperanto ("eo").
##
## This map is also used to convert old-style Sympa "locales" to language
## tags ('en' is special case. cf. SetLang()).
my %lang2locale = (
    'af' => 'af_ZA',
    'ar' => 'ar_SY',
    'br' => 'br_FR',
    'bg' => 'bg_BG',
    'ca' => 'ca_ES',
    'cs' => 'cs_CZ',
    'de' => 'de_DE',
    'el' => 'el_GR',
    'es' => 'es_ES',
    'et' => 'et_EE',
    'eu' => 'eu_ES',
    'fi' => 'fi_FI',
    'fr' => 'fr_FR',
    'gl' => 'gl_ES',
    'hu' => 'hu_HU',
    'id' => 'id_ID',
    'it' => 'it_IT',
    'ja' => 'ja_JP',
    'ko' => 'ko_KR',
    'la' => 'la_VA',    # from OpenOffice.org
    'ml' => 'ml_IN',
    'nb' => 'nb_NO',
    'nn' => 'nn_NO',
    'nl' => 'nl_NL',
    'oc' => 'oc_FR',
    'pl' => 'pl_PL',
    'pt' => 'pt_PT',
    'rm' => 'rm_CH',    # CLDR
    'ro' => 'ro_RO',
    'ru' => 'ru_RU',
    'sv' => 'sv_SE',
    'tr' => 'tr_TR',
    'vi' => 'vi_VN',
);

## We use different catalog/textdomains depending on the template that
## requests translations
my %template2textdomain = (
    'help_admin.tt2'         => 'web_help',
    'help_arc.tt2'           => 'web_help',
    'help_editfile.tt2'      => 'web_help',
    'help_editlist.tt2'      => 'web_help',
    'help_faqadmin.tt2'      => 'web_help',
    'help_faquser.tt2'       => 'web_help',
    'help_introduction.tt2'  => 'web_help',
    'help_listconfig.tt2'    => 'web_help',
    'help_mail_commands.tt2' => 'web_help',
    'help_sendmsg.tt2'       => 'web_help',
    'help_shared.tt2'        => 'web_help',
    'help.tt2'               => 'web_help',
    'help_user_options.tt2'  => 'web_help',
    'help_user.tt2'          => 'web_help',
);

## Regexp for old style canonical locale used by Sympa-6.2b.1 or earlier.
my $old_lang_re = qr/^([a-z]{2})_([A-Z]{2})(?![A-Z])/i;

## Regexp for IETF language tag described in RFC 5646 (BCP 47), modified.
my $language_tag_re = qr/^
    ([a-z]{2}(?:-[a-z]{3}){,3} | [a-z]{2,3})        # language (and ext.)
    (?:-([a-z]{4}))?                                # script
    (?:-([a-z]{2}))?                                # region (no UN M.49)
    (?:-(                                           # variant
	(?:[a-z0-9]{5,} | [0-9][a-z0-9]{3,})
	(?:-[a-z0-9]{5,} | -[0-9][a-z0-9]{3,})*
    ))?
$/ix;

## A tiny subset of script codes and gettext modifier names.
## Keys are ISO 15924 script codes (Titlecased).
## Values are property value aliases standardised by Unicode Consortium
## (lowercased).  cf. <http://www.unicode.org/iso15924/iso15924-codes.html>.
my %script2modifier = (
    'Arab' => 'arabic',
    'Cyrl' => 'cyrillic',
    'Deva' => 'devanagari',
    'Dsrt' => 'deseret',
    'Glag' => 'glagolitic',
    'Guru' => 'gurmukhi',
    'Latn' => 'latin',
    'Mong' => 'mongolian',
    'Shaw' => 'shaw',         # found in Debian "en@shaw" locale.
    'Tfng' => 'tifinagh',
);

sub CanonicLang {
    my $lang = shift;
    return unless $lang;

    ## Compatibility: older non-POSIX locale names.
    if ($language_equiv{$lang}) {
        $lang = $language_equiv{$lang};
    }
    ## Compatibility: names used as "lang" or "locale" by Sympa <= 6.2b.1.
    elsif ($lang =~ $old_lang_re) {
        $lang = _oldlocale2lang(lc($1) . '_' . uc($2));
    }

    my @subtags;

    # unknown format.
    return unless @subtags = ($lang =~ $language_tag_re);

    ## Canonicalize cases of subtags: ll-ext-Scri-RR-variant-...
    $subtags[0] = lc $subtags[0];
    $subtags[1] =~ s/^(\w)(\w+)/uc($1) . lc($2)/e if $subtags[1];
    $subtags[2] = uc $subtags[2] if $subtags[2];
    $subtags[3] = lc $subtags[3] if $subtags[3];

    ##XXX Maybe more canonicalizations here.

    ## Check subtags,
    # won't support language extension subtags.
    return unless $subtags[0] =~ /^[a-z]{2,3}$/;

    # won't allow multiple variant subtags.
    $subtags[3] =~ s/-.+// if $subtags[3];

    ##XXX Maybe more checks here.

    return @subtags if wantarray;
    return join '-', grep {$_} @subtags;
}

sub ImplicatedLangs {
    my @langs = @_;
    @langs = (GetLang()) unless @langs;

    my @implicated_langs = ();
    my %implicated_langs = ();

    foreach my $lang (@langs) {
        my @subtags = CanonicLang($lang);
        while (@subtags) {
            my $l = join '-', grep {$_} @subtags;
            unless ($implicated_langs{$l}) {
                push @implicated_langs, $l;
                $implicated_langs{$l} = 1;
            }

            ## Workaround:
            ## - "zh-Hans-CN", "zh-Hant-TW", ... may occasionally be
            ##   identified with "zh-CN", "zh-TW" etc.  Add them to
            ##   implication list.
            if ($l =~ /^zh-(Hans|Hant)-[A-Z]{2}\b/) {
                $l = join '-', grep {$_} @subtags[0, 2 .. $#subtags];
                unless ($implicated_langs{$l}) {
                    push @implicated_langs, $l;
                    $implicated_langs{$l} = 1;
                }
            }

            1 until pop @subtags;
        }
    }

    return @implicated_langs;
}

## Parses content of HTTP 1.1 Accept-Charset, Accept-Encoding or
## Accept-Language request header field.
## Returns an array of arrayrefs [ITEM, WEIGHT].
##
## NOTE: This might be moved to utility package such as tools.pm.
sub parse_http_accept_string {
    my $accept_string = shift || '';

    $accept_string =~ s/^\s+//;
    $accept_string =~ s/\s+$//;
    $accept_string ||= '*';
    my @pairs = split /\s*,\s*/, $accept_string;

    my @ret = ();
    foreach my $pair (@pairs) {
        my ($item, $weight) = split /\s*;\s*/, $pair, 2;
        if (    defined $weight
            and $weight =~ s/^q\s*=\s*//i
            and $weight =~ /^(\d+(\.\d*)?|\.\d+)$/) {
            $weight += 0.0;
        } else {
            $weight = 1.0;
        }
        push @ret, [$item => $weight];
    }
    return @ret;
}

sub NegotiateLang {
    my $accept_string = shift || '*';
    my @supported_languages = grep {$_} map { split /\s*,\s*/, $_ } @_;

    ## parse Accept-Language: header field.
    ## unknown languages are ignored.
    my @accept_languages =
        grep { $_->[0] eq '*' or $_->[0] = CanonicLang($_->[0]) }
        parse_http_accept_string($accept_string);
    return unless @accept_languages;

    ## try to find the best language.
    my $best_lang   = undef;
    my $best_weight = 0.0;
    foreach my $supported_lang (@supported_languages) {
        my @supported_pfxs = ImplicatedLangs($supported_lang);
        foreach my $pair (@accept_languages) {
            my ($accept_lang, $weight) = @$pair;
            if ($accept_lang eq '*'
                or grep { $accept_lang eq $_ } @supported_pfxs) {
                unless ($best_lang and $weight <= $best_weight) {
                    $best_lang   = $supported_pfxs[0];    # canonic form
                    $best_weight = $weight;
                }
            }
        }
    }

    return $best_lang;
}

##sub GetSupportedLanguages {
##DEPRECATED: use tools::get_supported_languages().
## Supported languages are defined by 'supported_lang' sympa.conf parameter.

sub PushLang {
    my $lang = shift;

    push @previous_lang, GetLang();
    SetLang($lang);

    return 1;
}

sub PopLang {
    my $lang = pop @previous_lang;
    SetLang($lang);

    return 1;
}

sub SetLang {
    my $lang = shift;
    my $locale;

    return unless $lang;

    # Canonicalize lang.
    # Note: 'en' is always allowed.  Use 'en-US' and so on to provide NLS for
    # English.
    return unless $lang = CanonicLang($lang);

    # Try to set POSIX locale and gettext locale, and get lang actually set.
    # Note: Macrolanguage 'zh', 'zh-Hans' or 'zh-Hant' may fallback to lang
    # with available region.
    if ($locale = _set_locale(Lang2Locale($lang))) {
        ($lang) = grep { Lang2Locale($_) eq $locale } ImplicatedLangs($lang);
    } elsif ($lang =~ /^zh\b/) {
        my @rr;
        if ($lang =~ /^zh-Hans\b/) {
            @rr = qw(CN SG  HK MO TW);    # try simp. first
        } elsif ($lang =~ /^zh-Hant\b/) {
            @rr = qw(HK MO TW  CN SG);    # try trad. first
        } else {
            @rr = qw(CN HK MO SG TW);
        }
        foreach my $rr (@rr) {
            $lang = "zh-$rr";
            last if $locale = _set_locale(Lang2Locale($lang));
        }
    }
    unless ($locale and $lang) {
        _set_locale($current_locale || 'en');    # failed.  restore locale
        return;
    }

    $current_lang   = $lang;
    $current_locale = $locale;
    undef $current_charset;    # set on demand: See GetCharset().

    return $lang;
}

## Internal function.
## Sets POSIX locale and gettext locale.
## Mandatory parameter is gettext locale name.
## Note: Use SetLang() instead of using this directly.
sub _set_locale {
    my $locale = shift or die 'missing locale parameter';

    # Try to set POSIX locale which affects to strftime, sprintf etc.
    # Special case: 'en' is an alias of 'C' locale.  Use 'en_US' and so on for
    # real English.
    # As of 6.2b.2, POSIX locale became optional: if setting it failed, 'C'
    # locale will be set.
    if ($locale eq 'en') {
        POSIX::setlocale(POSIX::LC_ALL(),  'C');
        POSIX::setlocale(POSIX::LC_TIME(), 'C');
    } else {
        ## From "ll@modifier", gets "ll", "ll_RR" and "@modifier".
        my ($loc, $mod) = split /(?=\@)/, $locale, 2;
        my $machloc = $loc;
        $machloc =~ s/^([a-z]{2,3})(?!_)/$lang2locale{$1} || $1/e;
        $mod ||= '';

        ## Set POSIX locale
        foreach my $type (POSIX::LC_ALL(), POSIX::LC_TIME()) {
            my $success = 0;
            my @try;

            ## Add codeset.
            ## UpperCase required for FreeBSD; dashless required on HP-UX;
            ## null codeset is last resort.
            foreach my $cs ('.utf-8', '.UTF-8', '.utf8', '') {
                ## Truncate locale similarly in gettext: full locale, and omit
                ## region then modifier.
                push @try,
                    map { sprintf $_, $cs }
                    ("$machloc%s$mod", "$loc%s$mod", "$loc%s");
            }
            foreach my $try (@try) {
                if (POSIX::setlocale($type, $try)) {
                    $success = 1;
                    last;
                }
            }
            unless ($success) {
                POSIX::setlocale($type, 'C');
            }
        }
    }

    # Set gettext locale (Locale::Messages context).

    # Workaround:
    # - "nb" and "nn" are recommended not to have "_NO" region suffix:
    #   Both of them are official languages in Norway.  However, current Sympa
    #   provides "nb_NO" NLS catalog.
    $locale =~ s/^(nb|nn)\b/${1}_NO/;

    # Set gettext locale
    ## Define what catalogs are used
    Locale::Messages::bindtextdomain(sympa    => Sympa::Constants::LOCALEDIR);
    Locale::Messages::bindtextdomain(web_help => Sympa::Constants::LOCALEDIR);
    Locale::Messages::textdomain('sympa');
    ## Get translations by internal encoding.
    Locale::Messages::bind_textdomain_codeset(sympa    => 'utf-8');
    Locale::Messages::bind_textdomain_codeset(web_help => 'utf-8');

    ## Check if catalog is loaded.
    if ($locale ne 'en') {
        local %ENV;
        $ENV{'LANGUAGE'} = $locale;
        my $metadata = Locale::Messages::gettext('');    # get header

        unless ($metadata) {
            ## If a sublanguage of 'en' failed, fallback to 'en'.
            ## Otherwise fails.
            if ($locale =~ /^en(?![a-z])/) {
                $locale = 'en';
            } else {
                return;
            }
        } elsif ($metadata =~ /(?:\A|\n)Language:\s*([\@\w]+)/) {
            ## Get precise name of gettext locale if possible.
            $locale = $1;
        }
    }

    ## Workaround for "nb" and "nn": See above.
    $locale =~ s/^(nb|nn)_NO\b/$1/;

    return $locale;
}

sub GetLangName {
    my $lang = shift || GetLang();
    my $name;

    PushLang($lang);

    unless ($current_lang and $current_lang ne 'en') {
        $name = 'English';
    } else {
        local %ENV;
        $ENV{'LANGUAGE'} = $current_locale;
        my $metadata = Locale::Messages::gettext('');    # get header

        if ($metadata =~ /(?:\A|\n)Language-Team:\s*(.+)/) {
            $name = $1;
            $name =~ s/\s*\<\S+\>//;
        }
    }

    PopLang();

    return (defined $name and $name =~ /\S/) ? $name : '';
}

sub GetLang {
    return $current_lang || 'en';    # the last resort
}

sub GetCharset {
    return $current_charset if $current_charset;

    if (%Conf::Conf) {               # configuration loaded
        if ($current_lang) {
            my $locale2charset = $Conf::Conf{'locale2charset'} || {};

            ## get charset of lang with fallback.
            $current_charset = 'utf-8';    # the default
            foreach my $lang (ImplicatedLangs($current_lang)) {
                if (exists $locale2charset->{$lang}) {
                    $current_charset = $locale2charset->{$lang};
                    last;
                }
            }
        }
    }
    return $current_charset || 'utf-8';    # the last resort
}

## DEPRECATED: Use CanonicLang().
## sub Locale2Lang;

# Internal function.
# Convert language tag to gettext locale name.
# Note: This function in earlier releases returned POSIX locale name.
sub Lang2Locale {
    my $lang = shift;
    my $locale;
    my @subtags;

    ## unknown format.
    return unless @subtags = CanonicLang($lang);

    ## convert from "ll-Scri-RR" to "ll_RR@scriptname", or
    ## from "ll-RR-variant" to "ll_RR@variant".
    $locale = $subtags[0];
    if ($subtags[2]) {
        $locale .= '_' . $subtags[2];
    }
    if ($subtags[1]) {
        $locale .= '@' . ($script2modifier{$subtags[1]} || $subtags[1]);
    } elsif ($subtags[3]) {
        $locale .= '@' . $subtags[3];
    }

    return $locale;
}

# Internal function.
# Get language tag from old-style "locale".
# Note: Old name is Locale2Lang_old().
# Note: Use CanonicLang().
sub _oldlocale2lang {
    my $old_lang = shift;
    my @parts = split /[\W_]/, $old_lang;
    my $lang;

    if ($lang = {reverse %lang2locale}->{$old_lang}) {
        return $lang;
    } elsif (scalar @parts > 1 and length $parts[1]) {
        return join '-', lc $parts[0], uc $parts[1];
    } else {
        return lc $parts[0];
    }
}

sub Lang2Locale_old {
    my $lang = shift;
    my $old_lang;
    my @subtags;

    ## unknown format.
    return unless @subtags = CanonicLang($lang);

    ## 'zh-Hans' and 'zh-Hant' cannot map to useful POSIX locale.  Map them to
    ## 'zh_CN' and 'zh_TW'.
    ## 'zh' cannot map.
    if ($subtags[0] eq 'zh' and $subtags[1] and not $subtags[2]) {
        if ($subtags[1] eq 'Hans') {
            $subtags[2] = 'CN';
        } elsif ($subtags[1] eq 'Hant') {
            $subtags[2] = 'TW';
        }
    }

    unless ($subtags[2]) {
        if ($lang2locale{$subtags[0]}) {
            return $lang2locale{$subtags[0]};
        }
    } else {
        return join '_', $subtags[0], $subtags[2];
    }
    ## unconvertible locale name
    return;
}

## NOTE: This might be moved to tt2 package.
sub maketext {
    my $template_file = shift;
    my $msg           = shift;

    my $translation;
    my $textdomain = $template2textdomain{$template_file};

    if ($textdomain) {
        $translation = dgettext($textdomain, $msg);
    } else {
        $translation = &gettext($msg);
    }

    ## replace parameters in string
    $translation =~ s/\%\%/'_ESCAPED_'.'%_'/eg;    ## First escape '%%'
    $translation =~ s/\%(\d+)/$_[$1-1]/eg;
    $translation =~ s/_ESCAPED_%\_/'%'/eg;         ## Unescape '%%'

    return $translation;
}

# Note: older name is sympa_dgettext().
sub dgettext {
    my $textdomain = shift;
    my @param      = @_;

    ## This prevents meta information to be returned if the string to
    ## translate is empty
    unless (defined $param[0]) {
        return;
    } elsif ($param[0] eq '') {
        return '';
    } elsif ($param[0] =~ '^_(\w+)_$') {
        ## return meta information on the catalog (language, charset,
        ## encoding, ...).
        ## Note: currently, charset is always 'utf-8'; encoding won't be used.
        my $var = $1;
        my $metadata;
        ## Special case: 'en' is null locale
        if (not $current_lang or $current_lang eq 'en') {
            $metadata = 'Language-Team: English';
        } else {
            local %ENV;
            $ENV{'LANGUAGE'} = $current_locale;
            $metadata = Locale::Messages::gettext('');    # get header
        }
        foreach (split /\n/, $metadata) {
            if ($var eq 'language') {
                if (/^Language-Team:\s*(.+)$/i) {
                    my $language = $1;
                    $language =~ s/\s*\<\S+\>//;

                    return $language;
                }
            } elsif ($var eq 'charset') {
                if (/^Content-Type:\s*.*charset=(\S+)$/i) {
                    return $1;
                }
            } elsif ($var eq 'encoding') {
                if (/^Content-Transfer-Encoding:\s*(.+)$/i) {
                    return $1;
                }
            }
        }
        return '';
    }

    my $ret;
    do {
        local %ENV;
        $ENV{'LANGUAGE'} = $current_locale;
        $ret = Locale::Messages::dgettext($textdomain, $param[0]);
    };
    return $ret;
}

sub gettext {
    my @param = @_;

    ## This prevents meta information to be returned if the string to
    ## translate is empty
    unless (defined $param[0]) {
        return;
    } elsif ($param[0] eq '') {
        return '';
    } elsif ($param[0] =~ '^_(\w+)_$') {
        ## return meta information on the catalog (language, charset,
        ## encoding,...)
        ## Note: currently charset is always 'utf-8'; encoding won't be used.
        my $var = $1;
        my $metadata;
        ## Special case: 'en' is null locale
        if ($current_lang and $current_lang eq 'en') {    #FIXME
            $metadata = 'Language-Team: English';
        } else {
            local %ENV;
            $ENV{'LANGUAGE'} = $current_locale;
            $metadata = Locale::Messages::gettext('');    # get header
        }
        foreach (split /\n/, $metadata) {
            if ($var eq 'language') {
                if (/^Language-Team:\s*(.+)$/i) {
                    my $language = $1;
                    $language =~ s/\<\S+\>//;

                    return $language;
                }
            } elsif ($var eq 'charset') {
                if (/^Content-Type:\s*.*charset=(\S+)$/i) {
                    return $1;
                }
            } elsif ($var eq 'encoding') {
                if (/^Content-Transfer-Encoding:\s*(.+)$/i) {
                    return $1;
                }
            }
        }
        return '';
    }

    my $ret;
    do {
        local %ENV;
        $ENV{'LANGUAGE'} = $current_locale;
        $ret = Locale::Messages::gettext($param[0]);
    };
    return $ret;
}

my %date_part_names = (
    '%a' => {
        'index'      => 6,
        'gettext_id' => 'Sun:Mon:Tue:Wed:Thu:Fri:Sat'
    },
    '%A' => {
        'index' => 6,
        'gettext_id' =>
            'Sunday:Monday:Tuesday:Wednesday:Thursday:Friday:Saturday'
    },
    '%b' => {
        'index'      => 4,
        'gettext_id' => 'Jan:Feb:Mar:Apr:May:Jun:Jul:Aug:Sep:Oct:Nov:Dec'
    },
    '%B' => {
        'index' => 4,
        'gettext_id' =>
            'January:February:March:April:May:June:July:August:September:October:November:December'
    },
    '%p' => {
        'index'      => 2,
        'gettext_id' => 'AM:PM'
    },
);

sub gettext_strftime {
    my $format = shift;
    my @args   = @_;

    my $posix_locale = POSIX::setlocale(POSIX::LC_TIME());

    ## if lang has not been set or 'en' is set, fallback to native strftime().
    unless ($current_lang and $current_lang ne 'en') {
        POSIX::setlocale(POSIX::LC_TIME(), 'C');
        my $datestr = POSIX::strftime($format, @args);
        POSIX::setlocale(POSIX::LC_TIME(), $posix_locale);
        return $datestr;
    }

    $format = gettext($format);

    ## If POSIX locale was not set, emulate format strings.
    unless ($posix_locale
        and $posix_locale ne 'C'
        and $posix_locale ne 'POSIX') {
        my %names;
        foreach my $k (keys %date_part_names) {
            $names{$k} =
                [split /:/, gettext($date_part_names{$k}->{'gettext_id'})];
        }
        $format =~ s{(\%[EO]?.)}{
	    my $index;
	    if ($names{$1} and
		defined($index = $args[$date_part_names{$1}->{'index'}])) {
		$index = ($index < 12) ? 0 : 1
		    if $1 eq '%p';
		$names{$1}->[$index];
	    } else {
		$1;
	    }
	}eg;
    }

    return POSIX::strftime($format, @args);
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Language - Handling languages and locales

=head1 DESCRIPTION

This package provides interfaces for i18n (internationalization) of Sympa.

The language tags are used to determine each language.
A language tag consists of one or more subtags: language, script, region and
variant.  Below are some examples.

=over 4

=item *

C<ar> - Arabic language

=item *

C<ain> - Ainu language

=item *

C<pt-BR> - Portuguese language in Brazil

=item *

C<be-Latn> - Belarusian language in Latin script

=item *

C<ca-ES-valencia> - Valencian variant of Catalan

=back

Other two sorts of identifiers are derived from language tags:
gettext locales and POSIX locales.

The gettext locales determine each translation catalog.
It consists of one to three parts: language, territory and modifier.
For example, their equivalents of language tags above are C<ar>, C<ain>,
C<pt_BR>, C<be@latin> and C<ca_ES@valencia>, respectively.

The POSIX locales determine each I<locale>.  They have similar forms to
gettext locales and are used by this package internally.

=head2 Functions

=head3 Manipulating language tags

=over 4

=item CanonicLang ( $lang )

I<Function>.
Canonicalizes language tag according to RFC 5646 (BCP 47) and returns it.

Parameter:

=over

=item $lang

Language tag or similar thing.
Old style "locale" by Sympa (see also L</Compatibility>) will also be
accepted.

=back

Returns:

Canonicalized language tag.
In array context, returns an array
C<(I<language>, I<script>, I<region>, I<variant>)>.
For malformed inputs, returns C<undef> or empty array.

See L</CAVEATS> about details on format.

=item ImplicatedLangs ( [ $lang, ... ] )

I<Function>.
Gets a list of each language $lang itself and its "super" languages.
For example:
If C<'tyv-Latn-MN'> is given, this function returns
C<('tyv-Latn-MN', 'tyv-Latn', 'tyv')>.

Parameters:

=over

=item $lang, ...

Language tags or similar things.
They will be canonicalized by L</CanonicLang>()
and malformed inputs will be ignored.
If none are given, result of L</GetLang>() is used.

=back

Returns:

A list of implicated languages, if any.

=item NegotiateLang ( $string, $lang, ... )

I<Function>.
Get the best language according to the content of C<Accept-Language:> HTTP
request header field.

Parameters:

=over

=item $string

Content of the header.  If it is false value, C<'*'> is assumed.

=item $lang, ...

Acceptable languages.

=back

Returns:

The best language or, if negotiation failed, C<undef>.

=back

=head3 Getting/setting language context

=over 4

=item PushLang ( $lang )

I<Function>.
Set current language by L</SetLang>() keeping the previous one;
it can be restored with L</PopLang>().

Parameter:

=over

=item $lang

Language tag or similar thing.

=back

Returns:

Always C<1>.

=item PopLang

I<Function>.
Restores previous language.

Parameters:

None.

Returns:

Always C<1>.

=item SetLang ( $lang )

I<Function>.
Sets current language along with translation catalog,
and POSIX locale if possible.

Parameter:

=over

=item $lang

Language tag or similer thing.
Old style "locale" by Sympa (see also L</Compatibility>) will also be
accepted.

=back

Returns:

Canonic language tag actually set or, if no usable catalog was found,
C<undef>.

Note that the language actually set may not be identical to the parameter
$lang, even when latter has been canonicalized.

The language tag C<'en'> is special:
it is used to set C<'C'> locale and will succeed always.

Note:
This function of Sympa 6.2b.1 or earlier returned old style "locale" names.

=item GetLangName ( [ $lang ] )

I<Function>.
Get the name of the language, ie the one defined in the catalog.

Parameter:

=over

=item $lang

Language tag or similar thing.
If omitted, value of L</GetLang>() is used.

=back

Returns:

Name of the language in native notation.
If it was not found, returns an empty string C<''>.

Note:
The name is the content of C<Language-Team:> field in the header of catalog.

=item GetLang ()

I<Function>.
Get current language.

Parameters:

None.

Returns:

Current language.
If it is not known, returns default language tag.

=item GetCharset ()

I<Function>.
Gets current charset for e-mail messages sent by Sympa.

Parameters:

None.

Returns:

Current charset.
If it is not known, returns default charset.

=back

=head3 Compatibility

As of Sympa 6.2b.2, language tags are used to specify languages along with
locales.  Earlier releases used POSIX locale names.

These functions are used to migrate data structures and configurations of
earlier versions.

=over 4

=item Lang2Locale_old ( $lang )

I<Function>.
Convert language tag to old-style "locale".

Parameter:

=over

=item $lang

Language tag or similar thing.

=back

Returns:

Old-style "locale".
If corresponding locale could not be determined, returns C<undef>.

=back

=head3 Native language support (NLS)

=over 4

=item maketext ( $template, $msgid )

XXX @todo doc

=item dgettext ( $domain, $msgid )

XXX @todo doc

=item gettext ( $msgid )

I<Function>.
Returns the translation of given string.
Note that L</SetLang>() must be called in advance.

Parameter:

=over

=item $msgid

gettext message ID.

=back

Returns:

Translated string or, if it wasn't found, original string.

If special argument C<'_language_'> is given,
returns the name of language in native form (See L<GetLangName>()).
For argument C<''> returns empty string.

=item gettext_strftime ( $format, $args, ... )

I<Function>.
Internationalized L<strftime|POSIX/strftime>().
At first, translates FORMAT argument using current catalog.
Then returns formatted date/time by remainder of arguments.

If appropriate POSIX locale is not available, parts of result (names of days,
months etc.) will be taken from the catalog.

Parameters:

=over

=item $format

Format string.
See also L<strftime(3)>.

=item $args, ...

Arguments fed to strftime().

=back

Returns:

Translated and formatted string.

=back


B<Note>:

Calls of L</gettext>() and L</gettext_strftime>() are 
extracted during build process and are added to translation catalog.

=head1 CAVEATS

=over

=item *

We impose some restrictions and modifications to the format described in
BCP 47:
language extension subtags won't be supported;
if script and variant subtags co-exist, latter will be ignored;
the first one of multiple variant subtags will be used;
each variant subtag may be longer than eight characters;
extension subtags are not supported.

=item *

L</SetLang>() and its companions set POSIX categories
C<LC_ALL> and C<LC_TIME> using setlocale().
This may affect behavior of strftime() in L<POSIX> module,
and built-in functions printf(), sprintf() and write().

=item *

Since catalogs for C<zh>, C<zh-Hans> and C<zh-Hant> may not be provided,
L</SetLang>() will choose approximate C<zh_I<??>> catalogs for these tags.

=back

=head1 SEE ALSO

RFC 5646 I<Tags for Identifying Languages>.
L<http://tools.ietf.org/html/rfc5646>.

I<Translating Sympa>.
L<http://www.sympa.org/translating_sympa>.

=head1 HISTORY

L<Language> module appeared on Sympa 3.0.1 to handle NLS catalog in msgcat
format.

Sympa 4.1 adopted gettext portable object (PO) catalog and POSIX locale.

On Sympa 6.2, rewritten module L<Sympa::Language> adopted BCP 47 language tag
to determine language context, and installing POSIX locale became optional.

