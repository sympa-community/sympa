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
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

package Language;

use strict;
use warnings;
use Exporter;
use POSIX qw(setlocale strftime);
use Locale::Messages qw (:locale_h :libintl_h !gettext);

use Log;
use Sympa::Constants;

our @ISA    = qw(Exporter);
our @EXPORT = qw(&gettext gettext_strftime);

BEGIN {
    ## Using the Pure Perl implementation of gettext
    ## This is required on Solaris : native implementation of gettext does not
    ## map ll_RR with ll
    ## ToDo: Use 'gettext_dumb' by libintl-perl 1.23 or later.
    Locale::Messages->select_package('gettext_pp');
}

=pod

=encoding utf-8

=head1 NAME

Language - Handling languages and locales

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

Other two sorts of codes are derived from language tags: gettext locales and
POSIX locales.

The gettext locales determine each translation catalog.
It consists of one to three parts: language, region and modifier.
For example, their equivalents of language tags above are C<ar>, C<ain>,
C<pt_BR>, C<be@latin> and C<ca_ES@valencia>, respectively.

The POSIX locales determine each I<locale>.  They have similar forms to
gettext locales and are used by this package internally.

=cut

## The locale is the NLS catalog name ; lang is the IETF language tag.
## Ex: locale = pt_BR ; lang = pt-BR
my ($current_lang, $current_locale, $current_charset, @previous_lang);
my %warned_locale;

## The map to get from older non-POSIX locale naming to language tag.
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
## tags ('en' is special case. cf. SetLang() & SetLocale()).
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

## Regexp for old style canonical locale used by Sympa-6.2a.33 or earlier.
my $old_lang_re = qr/^([a-z]{2})_([A-Z]{2})(?![A-Z])/i;

## Regexp for IETF language tag described in RFC 5646.
## We made some modifications: variant subtags may be longer than eight chars;
## restricted features (see CanonicLang() function).
my $language_tag_re = qr/^
    ([a-z]{2}(?:-[a-z]{3}){,3} | [a-z]{2,3})        # language (and ext.)
    (?:-([a-z]{4}))?                                # script
    (?:-([a-z]{2}))?                                # region (no UN M. 49)
    (?:-(                                           # variant
	(?:[a-z0-9]{5,} | [0-9][a-z0-9]{3,})
	(?:-[a-z0-9]{5,} | -[0-9][a-z0-9]{3,})*
    ))?
$/ix;

## A tiny subset of script codes and gettext modifier names.
## Keys are ISO 15924 script codes (titlecased).
## Values are property value aliases by Unicode Consortium (lowercased).
## cf. <http://www.unicode.org/iso15924/iso15924-codes.html>.
my %script2modifier = (
    'Arab' => 'arabic',
    'Cyrl' => 'cyrillic',
    'Deva' => 'devanagari',
    'Glag' => 'glagolitic',
    'Guru' => 'gurmukhi',
    'Latn' => 'latin',
    'Shaw' => 'shaw',         # found in Debian "en@shaw" locale.
    'Tfng' => 'tifinagh',
);

=head2 Functions

=head3 Manipulating language tags

=over 4

=item CanonicLang ( LANG )

I<Function>.
Canonicalizes language tag according to RFC 5646 and returns it.
Old style "locale" by Sympa (see also L</Compatibility>) will also be
accepted.

Returns canonicalized language tag.
In array context, returns an array C<(language, script, region, variant)>.
For malformed input, returns C<undef> or empty array.

Note:
We impose some restrictions to the format described in the RFC:
language extension subtags won't be supported;
script and variant subtags must not co-exist;
variant subtags may appear only once.

=back

=cut

sub CanonicLang {
    my $lang = shift;
    return (wantarray ? () : undef) unless $lang;

    ## Compatibility: older non-POSIX locale names.
    if ($language_equiv{$lang}) {
	$lang = $language_equiv{$lang};
    }
    ## Compatibility: names used as "lang" or "locale" by Sympa <= 6.2a.33.
    elsif ($lang =~ $old_lang_re) {
	$lang = Locale2Lang_old(lc($1) . '_' . uc($2));
    }

    my @subtags;

    # unknown format.
    return (wantarray ? () : undef)
	unless @subtags = ($lang =~ $language_tag_re);

    ## Canonicalize cases of subtags: ll-ext-Scri-RR-variant-...
    $subtags[0] = lc $subtags[0];
    $subtags[1] =~ s/^(\w)(\w+)/uc($1) . lc($2)/e if $subtags[1];
    $subtags[2] = uc $subtags[2] if $subtags[2];
    $subtags[3] = lc $subtags[3] if $subtags[3];

    ##XXX Maybe more canonicalizations here.

    ## Check subtags,
    # won't support language extension subtags.
    return (wantarray ? () : undef) unless $subtags[0] =~ /^[a-z]{2,3}$/;

    # won't allow multiple variant subtags.
    $subtags[3] =~ s/-.+// if $subtags[3];

    ##XXX Maybe more checks here.

    return @subtags if wantarray;
    return join '-', grep {$_} @subtags;
}

=over 4

=item ImplicatedLangs ( [ LANG, ... ] )

I<Function>.
Gets a list of each language LANG itself and its "super" languages.
For example:
If C<'tyv-Latn-MN'> is given, this function returns
C<('tyv-Latn-MN', 'tyv-Latn', 'tyv')>.

If no LANG are given, result of L</GetLang>() is used.
Malformed inputs will be ignored.


=back

=cut

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
	    if ($l =~ /^(zh)-(Hans)-(CN|SG)\b/ or
		$l =~ /^(zh)-(Hant)-(HK|MO|TW)\b/) {
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
	if (defined $weight and
	    $weight =~ s/^q\s*=\s*//i and
	    $weight =~ /^(\d+(\.\d*)?|\.\d+)$/) {
	    $weight += 0.0;
	} else {
	    $weight = 1.0;
	}
	push @ret, [$item => $weight];
    }
    return @ret;
}

=over 4

=item NegotiateLang ( STRING, LANG, ... )

I<Function>.
Get the best language according to the content of C<Accept-Language:> HTTP
request header field.

STRING is content of the header, if it is false value, C<'*'> is assumed.
Remainder of arguments are acceptable languages.

Returns the best language or, if negotiation failed, C<undef>.

=back

=cut

sub NegotiateLang {
    my $accept_string = shift || '*';
    my @supported_languages = grep {$_} map { split /\s*,\s*/, $_ } @_;

    ## parse Accept-Language: header field.
    ## unknown languages are ignored.
    my @accept_languages =
	grep { $_->[0] eq '*' or $_->[0] = CanonicLang($_->[0]) }
	parse_http_accept_string($accept_string);
    return undef unless @accept_languages;

    ## try to find the best language.
    my $best_lang   = undef;
    my $best_weight = 0.0;
    foreach my $supported_lang (@supported_languages) {
	my @supported_pfxs = ImplicatedLangs($supported_lang);
	foreach my $pair (@accept_languages) {
	    my ($accept_lang, $weight) = @$pair;
	    if ($accept_lang eq '*' or
		grep { $accept_lang eq $_ } @supported_pfxs) {
		unless ($best_lang and $weight <= $best_weight) {
		    $best_lang   = $supported_pfxs[0];    # canonic form
		    $best_weight = $weight;
		}
	    }
	}
    }

    return $best_lang;
}

=head3 Getting/setting language context

=cut

##sub GetSupportedLanguages {
##DEPRECATED: use Site->supported_languages or $robot->supported_languages.
## Supported languages are defined by 'supported_lang' sympa.conf parameter.

=over 4

=item PushLang ( LANG )

I<Function>.
Sets current language keeping the previous one; it can be restored with
L</PopLang>().

=back

=cut

sub PushLang {
    Log::do_log('debug2', '(%s)', @_);
    my $lang = shift;

    push @previous_lang, GetLang();
    SetLang($lang);

    return 1;
}

=over 4

=item PopLang

I<Function>.
Restores previous language.

=back

=cut

sub PopLang {
    Log::do_log('debug2', '()');

    my $lang = pop @previous_lang;
    SetLang($lang);

    return 1;
}

=over 4

=item SetLang ( LANG, [ OPT =E<gt> VAL, ... ] )

I<Function>.
Sets current language along with translation catalog and locale.
Returns canonic language tag, or C<undef> if failed.

LANG is language tag.
Old style "locale" by Sympa (see also L</Compatibility>) will also be
accepted.
The language tag C<'en'> is special:
it is used to set L<'C'> locale and would success always.

Note:
This function of Sympa 3.2a.33 or earlier returned old style "locale" names.

=back

=cut

sub SetLang {
    Log::do_log('debug2', '(%s)', @_);
    my $lang = shift;
    my %opts = @_;
    my $locale;

    ## Use default lang if an empty parameter
    $lang ||= Site->lang if $Site::is_initialized;

    unless ($lang) {
	Log::do_log('err', 'missing lang parameter');
	return undef;
    }

    ## 'en' is always allowed.  Use 'en-US' to provide NLS on English.
    if ($lang eq 'en') {
	$locale = 'en';
    } else {
	unless ($lang = CanonicLang($lang) and $locale = Lang2Locale($lang)) {
	    Log::do_log('err', 'unknown language')
		unless $opts{'just_try'};
	    return undef;
	}
    }

    unless (SetLocale($locale, %opts)) {
	SetLocale($current_locale || 'en');    # restore POSIX locale
	return undef;
    }

    $current_lang   = $lang;
    $current_locale = $locale;
    undef $current_charset;    # set on demand: See GetCharset().

    return $lang;
}

## Internal function.
## Sets POSIX locale and gettext locale.  LOCALE is gettext locale name.
## Note: Use SetLang().
sub SetLocale {
    Log::do_log('debug3', '(%s)', @_);
    my $locale = shift;
    my %opts   = @_;

    ## Special case: 'en' is an alias of 'C' locale.  Use 'en_US' for real
    ## English.
    if ($locale eq 'en') {
	$locale = 'C';
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
		## Trancate locale similarly in gettext: full locale, and omit
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
		POSIX::setlocale($type, 'C');    # reset POSIX locale
		##FIXME: 'warn' is better.
		Log::do_log(
		    'notice',
		    'Failed to set locale "%s". You might want to extend available locales',
		    $locale
		) unless $warned_locale{$locale};
		$warned_locale{$locale} = 1;
	    }
	}
    }

    ## Workaround:
    ## - "nb" and "nn" are recommended not to have "_NO" region suffix:
    ##   Both of them are official languages in Norway.
    ##   However, current Sympa provides "nb_NO" NLS catalog.
    $locale =~ s/^(nb|nn)\b/${1}_NO/;

    ## Set gettext locale (Locale::Messages context).
    $ENV{'LANGUAGE'} = $locale;
    ## Define what catalogs are used
    Locale::Messages::textdomain("sympa");
    Locale::Messages::bindtextdomain('sympa',    Sympa::Constants::LOCALEDIR);
    Locale::Messages::bindtextdomain('web_help', Sympa::Constants::LOCALEDIR);

    # Get translations by internal encoding.
    bind_textdomain_codeset sympa    => 'utf-8';
    bind_textdomain_codeset web_help => 'utf-8';

    ## Check if catalog is loaded.
    if ($locale and $locale ne 'C') {
	unless (Locale::Messages::gettext('')) {
	    Log::do_log('err',
		'Failed to bind translation catalog for locale "%s"', $locale)
		unless $opts{'just_try'};
	    return undef;
	}
    }

    return 1;
}

=over 4

=item GetLangName ( LANG )

I<Function>.
Get the name of the language, ie the one defined in the catalog.

=back

=cut

sub GetLangName {
    my $lang = shift;

    PushLang($lang);
    my $name = gettext('_language_');
    PopLang();

    return $name;
}

=over 4

=item GetLang

I<Function>.
Get current language tag.
If it is not known, returns default language tag.

=back

=cut

sub GetLang {
    return $current_lang if $current_lang;

    if ($Site::is_initialized) {
	SetLang(Site->lang);
    }
    return $current_lang || 'en';    # the last resort
}

=over 4

=item GetCharset

I<Function>.
Gets current charset for e-mail messages sent by Sympa.
If it is not known, returns default charset.

=back

=cut

sub GetCharset {
    return $current_charset if $current_charset;

    if ($Site::is_initialized) {
	unless ($current_lang) {
	    SetLang(Site->lang);
	}
	if ($current_lang) {
	    my $locale2charset = Site->locale2charset;

	    ## get charset of lang with fallback.
	    $current_charset = 'utf-8';    # the default
	    foreach my $lang (ImplicatedLangs($current_lang)) {
		if ($locale2charset->{$lang}) {
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
    return undef unless @subtags = CanonicLang($lang);

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

=head3 Compatibility

As of Sympa 6.2a.34, language tags are used to specify languages and
locales.  Earlier releases used POSIX locale names.

These functions are used to migrate data structures and configurations of
earlier versions.

=cut

# Internal function.
# Get language tag from old-style "locale".
# Note: Use CanonicLang().
sub Locale2Lang_old {
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

=over 4

=item Lang2Locale_old ( LANG )

I<Function>.
Convert language tag to old-style "locale".

=back

=cut

sub Lang2Locale_old {
    my $lang = shift;
    my $old_lang;
    my @subtags;

    ## unknown format.
    return undef unless @subtags = CanonicLang($lang);

    unless ($subtags[2]) {
	if ($lang2locale{$subtags[0]}) {
	    return $lang2locale{$subtags[0]};
	}
    } else {
	return join '_', $subtags[0], $subtags[2];
    }
    ## unconvertible locale name
    return undef;
}

=head3 Native language support (NLS)

=cut

## NOTE: This might be moved to tt2 package.
sub maketext {
    my $template_file = shift;
    my $msg           = shift;

    my $translation;
    my $textdomain = $template2textdomain{$template_file};

    if ($textdomain) {
	$translation = &sympa_dgettext($textdomain, $msg);
    } else {
	$translation = &gettext($msg);
    }

    ## replace parameters in string
    $translation =~ s/\%\%/'_ESCAPED_'.'%_'/eg;    ## First escape '%%'
    $translation =~ s/\%(\d+)/$_[$1-1]/eg;
    $translation =~ s/_ESCAPED_%\_/'%'/eg;         ## Unescape '%%'

    return $translation;
}

=over 4

=item sympa_dgettext ( TEXTDOMAIN, MSGID )

XXX @todo doc

=back

=cut

sub sympa_dgettext {
    Log::do_log('debug3', '(%s, %s)', @_);
    my $textdomain = shift;
    my @param      = @_;

    ## This prevents meta information to be returned if the string to
    ## translate is empty
    unless (defined $param[0]) {
	return undef;
    } elsif ($param[0] eq '') {
	return '';
    } elsif ($param[0] =~ '^_(\w+)_$') {
	## return meta information on the catalog (language, charset,
	## encoding, ...).
	## Note: currently, charset is always 'utf-8'; encoding won't be used.
	my $var = $1;
	my $metadata;
	## Special case: 'en' is null locale
	if ($current_lang eq 'en') {
	    $metadata = 'Language-Team: English';
	} else {
	    $metadata = Locale::Messages::gettext('');
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

    return Locale::Messages::dgettext($textdomain, $param[0]);

}

=over 4

=item gettext ( MSGID )

I<Function>.
Returns the translation of MSGID.
Note that L</SetLang>() must be called in advance.

If special argument C<'_language_'> is given,
returns the name of language in native form:
it is the content of C<Language-Team:> field in the header of catalog.
For argument C<''> returns empty string.

=back

=cut

sub gettext {
    Log::do_log('debug3', '(%s)', @_);
    my @param = @_;

    ## This prevents meta information to be returned if the string to
    ## translate is empty
    unless (defined $param[0]) {
	return undef;
    } elsif ($param[0] eq '') {
	return '';
    } elsif ($param[0] =~ '^_(\w+)_$') {
	## return meta information on the catalog (language, charset,
	## encoding,...)
	## Note: currently charset is always 'utf-8'; encoding won't be used.
	my $var = $1;
	my $metadata;
	## Special case: 'en' is null locale
	if ($current_lang eq 'en') {
	    $metadata = 'Language-Team: English';
	} else {
	    $metadata = Locale::Messages::gettext('');
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

    return Locale::Messages::gettext($param[0]);
}

=over 4

=item gettext_strftime ( FORMAT, ARGS, ... )

I<Function>.
Internationalized L<strftime|POSIX/strftime>().
At first, translates FORMAT argument using current catalog.
Then returns formatted date/time by remainder of arguments.

If appropriate POSIX locale is not available, parts of result (names of days,
months etc.) will be taken from the catalog.

=back

=cut

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
    Log::do_log('debug3', '(%s, ...)', @_);
    my $format = shift;

    my $posix_locale = POSIX::setlocale(POSIX::LC_TIME());

    ## if lang has not been set, fallback to native strftime().
    unless ($current_lang and $current_lang ne 'en') {
	POSIX::setlocale(POSIX::LC_TIME(), 'C');
	my $datestr = POSIX::strftime($format, @_);
	POSIX::setlocale(POSIX::LC_TIME(), $posix_locale);
	return $datestr;
    }

    $format = Locale::Messages::gettext($format);

    ## If POSIX locale was not set, emulate format strings.
    unless ($posix_locale and
	$posix_locale ne 'C' and
	$posix_locale ne 'POSIX') {
	my %names;
	foreach my $k (keys %date_part_names) {
	    $names{$k} = [
		split /:/,
		Locale::Messages::gettext(
		    $date_part_names{$k}->{'gettext_id'}
		)
	    ];
	}
	$format =~ s{(\%[EO]?.)}{
	    my $index;
	    if ($names{$1} and
		defined($index = $_[$date_part_names{$1}->{'index'}])) {
		$index = ($index < 12) ? 0 : 1
		    if $1 eq '%p';
		$names{$1}->[$index];
	    } else {
		$1;
	    }
	}eg;
    }

    return POSIX::strftime($format, @_);
}

=pod

Note that calls of L</gettext>() and L</gettext_strftime>() are 
extracted during build process and are added to translation catalog.

=cut

# end of Language package
1;
__END__

=head1 SEE ALSO

RFC 5646 I<Tags for Identifying Languages>.
L<http://tools.ietf.org/html/rfc5646>.

I<Translating Sympa>.
L<http://www.sympa.org/translating_sympa>.

=head1 AUTHORS

Sympa developers and contributors.

