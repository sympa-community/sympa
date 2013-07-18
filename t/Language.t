#-*- perl -*-
# -*- indent-tabs-mode: t; -*-
# vim:ft=perl:noet:sw=8:textwidth=78
# $Id$

use strict;
use warnings;
#use lib "...";

use Test::More;

use Language;

plan tests => 77;

Log::set_log_level(-1);

## Unknown language
is(Language::SetLang('C'),     undef);
is(Language::SetLang('POSIX'), undef);

## Lang 2 locale
is(Language::Lang2Locale('ca'),    'ca');
is(Language::Lang2Locale('cs'),    'cs');
is(Language::Lang2Locale('en'),    'en');
is(Language::Lang2Locale('en-US'), 'en_US');
is(Language::Lang2Locale('ja-JP'), 'ja_JP');
is(Language::Lang2Locale('nb'),    'nb');
is(Language::Lang2Locale('nb-NO'),
	'nb_NO', '"nb-NO": not recommended but possible');
is(Language::Lang2Locale('pt'),    'pt');
is(Language::Lang2Locale('pt-BR'), 'pt_BR');
is(Language::Lang2Locale('zh'),    'zh');
is(Language::Lang2Locale('zh-CN'), 'zh_CN');

is(Language::Lang2Locale('cz'), 'cs');
is(Language::Lang2Locale('us'), 'en_US');
is(Language::Lang2Locale('cn'), 'zh_CN');

is(Language::Lang2Locale('en_US'), 'en_US');
is(Language::Lang2Locale('ja_JP'), 'ja');
is(Language::Lang2Locale('nb_NO'), 'nb');
is(Language::Lang2Locale('pt_BR'), 'pt_BR');
is(Language::Lang2Locale('zh_CN'), 'zh_CN');

## Complex locales
is(Language::Lang2Locale('ca-ES-valencia'), 'ca_ES@valencia');
is(Language::Lang2Locale('be-Latn'),        'be@latin');
is(Language::Lang2Locale('tyv-Latn-MN'),    'tyv_MN@latin');

## Old style locale
is(Language::Lang2Locale_old('ca'),    'ca_ES');
is(Language::Lang2Locale_old('cs'),    'cs_CZ');
is(Language::Lang2Locale_old('en'),    undef);
is(Language::Lang2Locale_old('en-US'), 'en_US');
is(Language::Lang2Locale_old('ja-JP'), 'ja_JP');
is(Language::Lang2Locale_old('nb'),    'nb_NO');
is(Language::Lang2Locale_old('nb-NO'), 'nb_NO');
is(Language::Lang2Locale_old('pt'),    'pt_PT');
is(Language::Lang2Locale_old('pt-BR'), 'pt_BR');
is(Language::Lang2Locale_old('zh'),    undef);
is(Language::Lang2Locale_old('zh-CN'), 'zh_CN');

is(Language::Lang2Locale_old('cz'), 'cs_CZ');
is(Language::Lang2Locale_old('us'), 'en_US');
is(Language::Lang2Locale_old('cn'), 'zh_CN');

is(Language::Lang2Locale_old('en_US'), 'en_US');
is(Language::Lang2Locale_old('ja_JP'), 'ja_JP');
is(Language::Lang2Locale_old('nb_NO'), 'nb_NO');
is(Language::Lang2Locale_old('pt_BR'), 'pt_BR');
is(Language::Lang2Locale_old('zh_CN'), 'zh_CN');

## Canonical names
# not language tag
is(Language::CanonicLang('C'),     undef);
is(Language::CanonicLang('POSIX'), undef);

is(Language::CanonicLang('ca'),    'ca');
is(Language::CanonicLang('cs'),    'cs');
is(Language::CanonicLang('en'),    'en');
is(Language::CanonicLang('en-US'), 'en-US');
is(Language::CanonicLang('ja-JP'), 'ja-JP');
is(Language::CanonicLang('nb'),    'nb');
is(Language::CanonicLang('nb-NO'),
	'nb-NO', '"nb-NO": not recommended but possible');
is(Language::CanonicLang('pt'),    'pt');
is(Language::CanonicLang('pt-BR'), 'pt-BR');
is(Language::CanonicLang('zh'),    'zh');
is(Language::CanonicLang('zh-CN'), 'zh-CN');

is(Language::CanonicLang('cz'), 'cs');
is(Language::CanonicLang('us'), 'en-US');
is(Language::CanonicLang('cn'), 'zh-CN');

is(Language::CanonicLang('en_US'), 'en-US');
is(Language::CanonicLang('ja_JP'), 'ja');
is(Language::CanonicLang('nb_NO'), 'nb');
is(Language::CanonicLang('pt_BR'), 'pt-BR');
is(Language::CanonicLang('zh_CN'), 'zh-CN');

## Implicated langs
is_deeply([Language::ImplicatedLangs('ca')], ['ca']);
is_deeply([Language::ImplicatedLangs('en-US')], ['en-US', 'en']);
is_deeply([Language::ImplicatedLangs('ca-ES-valencia')],
	['ca-ES-valencia', 'ca-ES', 'ca']);
is_deeply([Language::ImplicatedLangs('be-Latn')], ['be-Latn', 'be']);
is_deeply(
	[Language::ImplicatedLangs('tyv-Latn-MN')],
	['tyv-Latn-MN', 'tyv-Latn', 'tyv']
);

# zh-Hans-*/zh-Hant-* workaround
is_deeply(
	[Language::ImplicatedLangs('zh-Hans-CN')],
	['zh-Hans-CN', 'zh-CN', 'zh-Hans', 'zh'],
	'workaround for "zh-Hans-CN"'
);
is_deeply(
	[Language::ImplicatedLangs('zh-Hant-HK-xxxxx')],
	[       'zh-Hant-HK-xxxxx', 'zh-HK-xxxxx',
		'zh-Hant-HK',       'zh-HK',
		'zh-Hant',          'zh'
	],
	'workaround for "zh-Hant-HK"'
);

is_deeply([Language::ImplicatedLangs('cn')], ['zh-CN', 'zh']);

is_deeply([Language::ImplicatedLangs('en_US')], ['en-US', 'en']);
is_deeply([Language::ImplicatedLangs('nb_NO')], ['nb']);

## Content negotiation
is(Language::NegotiateLang('DE,en,fr;Q=0.5,es;q=0.1', 'es,fr,de,en'), 'de');
is(Language::NegotiateLang('en',    'EN-CA,en'),       'en-CA');
is(Language::NegotiateLang('en-US', 'en,en-CA,en-US'), 'en-US');

