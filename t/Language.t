# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Unit test for Sympa::Language.
#
# This will run in following environment:
# - Available catalogs: cs, zh_TW.

use strict;
use warnings;
use Test::More;

use lib qw(t/stub);
use Sympa::Language;

my %tests = (
    ## Lang 2 gettext locale
    lang2locale => [
        ## not a language tag or available locale.
        [undef() => undef],
        ['C'     => undef],
        ['POSIX' => undef],

        ['ca'    => 'ca'],
        ['cs'    => 'cs'],
        ['en'    => 'en'],
        ['en-US' => 'en_US'],
        ['ja-JP' => 'ja_JP'],
        ['nb'    => 'nb'],
        ['nb-NO' => 'nb_NO', 'not recommended but possible'],
        ['pt'    => 'pt'],
        ['pt-BR' => 'pt_BR'],
        ['zh'    => 'zh'],
        ['zh-CN' => 'zh_CN'],
        ## non-POSIX locales
        ['cz' => 'cs'],
        ['us' => 'en_US'],
        ['cn' => 'zh_CN'],
        ## OLd style locales
        ['en_US' => 'en_US'],
        ['ja_JP' => 'ja'],
        ['nb_NO' => 'nb'],
        ['pt_BR' => 'pt_BR'],
        ['zh_CN' => 'zh_CN'],
        ## Complex tags
        ['ca-ES-valencia' => 'ca_ES@valencia'],
        ['be-Latn'        => 'be@latin'],
        ['tyv-Latn-MN'    => 'tyv_MN@latin'],
    ],

    ## Lang to old style locale
    lang2oldlocale => [
        ['ca'    => 'ca_ES'],
        ['cs'    => 'cs_CZ'],
        ['en'    => undef, 'special'],
        ['en-US' => 'en_US'],
        ['ja-JP' => 'ja_JP'],
        ['nb'    => 'nb_NO'],
        ['nb-NO' => 'nb_NO'],
        ['pt'    => 'pt_PT'],
        ['pt-BR' => 'pt_BR'],
        ['zh'    => undef, 'region not determined'],
        ['zh-CN' => 'zh_CN'],
        ## zh
        ['zh-Hant'    => 'zh_TW'],
        ['zh-Hans-HK' => 'zh_HK'],
        ## non-POSIX locales
        ['cz' => 'cs_CZ'],
        ['us' => 'en_US'],
        ['cn' => 'zh_CN'],
        ## Old style locales
        ['en_US' => 'en_US'],
        ['ja_JP' => 'ja_JP'],
        ['nb_NO' => 'nb_NO'],
        ['pt_BR' => 'pt_BR'],
        ['zh_CN' => 'zh_CN'],
    ],

    ## Canonical names
    canonic_lang => [
        ## not a language tag
        [undef() => undef],
        ['C'     => undef],
        ['POSIX' => undef],
        ['en_Dsrt_US' => undef, 'illegal format'],
        ['zh-min-nan' => undef, 'unsupported tag'],

        ['ca'    => 'ca'],
        ['cs'    => 'cs'],
        ['en'    => 'en'],
        ['en-US' => 'en-US'],
        ['ja-JP' => 'ja-JP'],
        ['nb'    => 'nb'],
        ['nb-NO' => 'nb-NO', 'not recommended but possible'],
        ['pt'    => 'pt'],
        ['pt-BR' => 'pt-BR'],
        ['zh'    => 'zh'],
        ['zh-CN' => 'zh-CN'],
        ## non-POSIX locales
        ['cz' => 'cs'],
        ['us' => 'en-US'],
        ['cn' => 'zh-CN'],
        ## Old-style locales
        ['en_US' => 'en-US'],
        ['ja_JP' => 'ja'],
        ['nb_NO' => 'nb'],
        ['pt_BR' => 'pt-BR'],
        ['zh_CN' => 'zh-CN'],
    ],

    ## Implicated langs
    implicated_langs => [
        #[[]                 => ['cs']],
        [['ca']             => ['ca']],
        [['en-US']          => [qw(en-US en)]],
        [['ca-ES-valencia'] => [qw(ca-ES-valencia ca-ES ca)]],
        [['be-Latn']        => [qw(be-Latn be)]],
        [['tyv-Latn-MN']    => [qw(tyv-Latn-MN tyv-Latn tyv)]],
        ## zh-Hans-*/zh-Hant-* workaround
        [['zh-Hans-CN'] => [qw(zh-Hans-CN zh-CN zh-Hans zh)]],
        [   ['zh-Hant-HK-xxxxx'] => [
                qw(zh-Hant-HK-xxxxx zh-HK-xxxxx zh-Hant-HK zh-HK zh-Hant zh)]
        ],
        ## non-POSIX locales
        [['cn'] => [qw(zh-CN zh)]],
        ## Old style locales
        [['en_US'] => [qw(en-US en)]],
        [['nb_NO'] => ['nb']],
        ## Multiple arguments
        [   [qw(tyv-MN tyv-Latn-MN kim tyv-Mong)] =>
                [qw(tyv-MN tyv-Latn-MN tyv-Latn kim tyv-Mong tyv)]
        ],
        [[qw(zh zh-TW zh-Hant-TW)] => [qw(zh-Hant-TW zh-TW zh-Hant zh)]],
    ],

    ## Content negotiation
    negotiate_lang => [
        [['de',                      'en']             => undef],
        [['DE,en,fr;Q=0.5,es;q=0.1', 'es,fr,de,en']    => 'de'],
        [['en',                      'EN-CA,en']       => 'en-CA'],
        [['en-US',                   'en,en-CA,en-US'] => 'en-US'],
    ],

    set_lang => [
        ## Unknown language
        [undef() => undef],
        ['C',    => undef],
        ['POSIX' => undef],
        ['ja' => undef, 'no catalog - error'],
        ## Fallback
        ['cs-CZ-lasstina' => 'cs'],
        ['cs-lasstina'    => 'cs', 'locale-independent case'],
        ['cs-CZ'          => 'cs'],
        ['cs'             => 'cs'],
        ['en-CA'          => 'en', 'no catalog (en_CA) - fallback to en'],
        ['en-Shaw'        => 'en', 'no catalog (en@shaw) - fallback to en'],
        ['en'             => 'en', 'no catalog (en) - fallback to en'],
        ['zh'             => 'zh-TW', 'macrolanguage zh'],
        ['zh-guoyu'       => 'zh-TW', 'macrolanguage zh'],
        ['zh-TW'          => 'zh-TW'],
        ['zh-Hant'        => 'zh-TW', 'semi-macrolanguage zh-Hant'],
        ['zh-Hant-TW'     => 'zh-TW'],
        ['zh-Hant-HK'     => 'zh-TW', 'semi-macrolanguage zh-Hant'],
        ['zh-Hant-guoyu'  => 'zh-TW', 'semi-macrolanguage zh-Hant'],
        ['zh-Hans-CN'     => 'zh-TW', 'macrolanguage zh'],
    ],

    native_name => [
        ['cs'    => "\xC4\x8Cesky"],
        ['cs-CZ' => "\xC4\x8Cesky"],
        ['en'    => 'English'],
        ['en-CA' => 'English', 'fallback to en'],
        ['zh-TW' => "\xE7\xB9\x81\xE9\xAB\x94\xE4\xB8\xAD\xE6\x96\x87"],
    ],

    ## Translation
    gettext => [
        [undef()       => undef,         'undefined msgid'],
        [''            => '',            'empty msgid'],
        ['lorem ipsum' => 'lorem ipsum', 'unknown msgid'],
        ['_language_'  => "\xC4\x8Cesky"],
        [   'Sun:Mon:Tue:Wed:Thu:Fri:Sat' =>
                "Ne:Po:\xC3\x9At:St:\xC4\x8Ct:P\xC3\xA1:So"
        ],
    ],

    dgettext => [
        [['web_help', undef]         => undef,         'undefined msgid'],
        [['web_help', '']            => '',            'empty msgid'],
        [['web_help', 'lorem ipsum'] => 'lorem ipsum', 'unknown msgid'],
        [['web_help', '_language_']  => "\xC4\x8Cesky"],
        [['web_help', 'What is a mailing list?'] => "Co je mail list?"],
    ],

    ## POSIX::strftime()
    strftime => [['%a, %d %b %Y' => 'Thu, 01 Jan 1970', 'POSIX strftime'],],

    ## Emulated strftime()
    gettext_strftime =>
        [['%a, %d %b %Y' => "\xC4\x8Ct 01. Led 1970", 'emulated strftime'],],

    ## Failed if utf8 flag set
    gettext_strftime_noutf8 => [['%a, %d %b %Y'],],
);

plan tests => scalar map {@$_} values %tests;

foreach my $test (@{$tests{lang2locale}}) {
    is( Sympa::Language::lang2locale($test->[0]),
        $test->[1],
        (   defined $test->[0]
            ? "lang2locale($test->[0])"
            : 'lang2locale(undef)'
            )
            . ($test->[2] ? ": $test->[2]" : '')
    );
}

foreach my $test (@{$tests{lang2oldlocale}}) {
    is(Sympa::Language::lang2oldlocale($test->[0]),
        $test->[1],
        "lang2oldlocale($test->[0])" . ($test->[2] ? ": $test->[2]" : ''));
}

foreach my $test (@{$tests{canonic_lang}}) {
    is( Sympa::Language::canonic_lang($test->[0]),
        $test->[1],
        (   defined $test->[0]
            ? "canonic_lang($test->[0])"
            : 'canonic_lang(undef)'
            )
            . ($test->[2] ? ": $test->[2]" : '')
    );
}

foreach my $test (@{$tests{implicated_langs}}) {
    is_deeply([Sympa::Language::implicated_langs(@{$test->[0]})], $test->[1],
              'implicated_langs('
            . join(' ', @{$test->[0]}) . ')'
            . ($test->[2] ? ": $test->[2]" : ''));
}

foreach my $test (@{$tests{negotiate_lang}}) {
    is(Sympa::Language::negotiate_lang(@{$test->[0]}), $test->[1],
              "negotiate_lang("
            . join(' ', @{$test->[0]}) . ')'
            . ($test->[2] ? ": $test->[2]" : ''));
}

my $language = Sympa::Language->instance;

foreach my $test (@{$tests{set_lang}}) {
    is($language->set_lang($test->[0]), $test->[1],
        (defined $test->[0] ? "set_lang($test->[0])" : 'set_lang(undef)')
            . ($test->[2]   ? ": $test->[2]"         : ''));
}

foreach my $test (@{$tests{native_name}}) {
    $language->set_lang($test->[0]);
    is( $language->native_name,
        $test->[1],
        (   defined $test->[0]
            ? "native_name($test->[0])"
            : 'native_name(undef)'
            )
            . ($test->[2] ? ": $test->[2]" : '')
    );
}

$language->set_lang('cs');
foreach my $test (@{$tests{gettext}}) {
    is($language->gettext($test->[0]), $test->[1],
              (defined $test->[0] ? "gettext($test->[0])" : 'gettext(undef)')
            . ($test->[2]         ? ": $test->[2]"        : ''));
}

$language->set_lang('cs');
foreach my $test (@{$tests{dgettext}}) {
    is( $language->dgettext(@{$test->[0]}),
        $test->[1],
        (   defined $test->[0]->[1]
            ? "dgettext(" . join(' ', @{$test->[0]}) . ")"
            : 'dgettext(' . $test->[0]->[0] . ' undef)'
            )
            . ($test->[2] ? ": $test->[2]" : '')
    );
}

$language->set_lang('en');
foreach my $test (@{$tests{strftime}}) {
    is($language->gettext_strftime($test->[0], gmtime 0),
        $test->[1],
        "gettext_strftime($test->[0])" . ($test->[2] ? ": $test->[2]" : ''));
}

$language->set_lang('cs');
$language->{locale_time} = 'C';    # hack to cancel POSIX locale.
foreach my $test (@{$tests{gettext_strftime}}) {
    is($language->gettext_strftime($test->[0], gmtime 0),
        $test->[1],
        "gettext_strftime($test->[0])" . ($test->[2] ? ": $test->[2]" : ''));
}

# PR #134
$language->set_lang('zh-TW');
foreach my $test (@{$tests{gettext_strftime_noutf8}}) {
    ok(!Encode::is_utf8($language->gettext_strftime($test->[0], gmtime 0)),
        "!is_utf8 gettext_strftime($test->[0])");
}

