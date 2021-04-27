# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

use strict;
use warnings;
use English qw(-no_match_vars);
use File::Path qw(make_path rmtree);
use Test::More;

BEGIN {
    use_ok 'Sympa::WWW::Tools';
}

# get_robot()

%Conf::Conf = (
    domain      => 'mail.example.org',
    listmaster  => 'listmaster@example.org',
    wwsympa_url => 'http://web.example.org/sym/pa',
    etc         => 't/tmp/etc',
);
make_path $Conf::Conf{'etc'} or die $ERRNO;

$ENV{SERVER_NAME} = 'web.example.org';
$ENV{SCRIPT_NAME} = '/sym/pa';
$ENV{PATH_INFO}   = undef;
is_deeply [Sympa::WWW::Tools::get_robot('wwsympa_url')],
    ['mail.example.org', '/sym/pa', ''],
    'SCRIPT_NAME & empty PATH_INFO';

$ENV{SERVER_NAME} = 'web.example.org';
$ENV{SCRIPT_NAME} = '/sym/pa';
$ENV{PATH_INFO}   = '/help';
is_deeply [Sympa::WWW::Tools::get_robot('wwsympa_url')],
    ['mail.example.org', '/sym/pa', '/help'],
    'SCRIPT_NAME & non-empty PATH_INFO';

$ENV{SERVER_NAME} = 'web.example.org';
$ENV{SCRIPT_NAME} = '/sym';
$ENV{PATH_INFO}   = '/pa/help';
is_deeply [Sympa::WWW::Tools::get_robot('wwsympa_url')],
    ['mail.example.org', '/sym/pa', '/help'],
    'split script-path (e.g. mod_proxy_fcgi on httpd)';

$ENV{SERVER_NAME} = 'web.example.org';
$ENV{SCRIPT_NAME} = '/sym/pa/help';
$ENV{PATH_INFO}   = undef;
is_deeply [Sympa::WWW::Tools::get_robot('wwsympa_url')],
    ['mail.example.org', '/sym/pa', '/help'],
    'no PATH_INFO (e.g. nginx without fastcgi_split_path_info)';

$ENV{SERVER_NAME} = 'other.example.org';
$ENV{SCRIPT_NAME} = '/sym/pa';
$ENV{PATH_INFO}   = '/help';
is_deeply [Sympa::WWW::Tools::get_robot('wwsympa_url')], [],
    'mismatch SERVER_NAME';

$ENV{SERVER_NAME} = 'web.example.org';
$ENV{SCRIPT_NAME} = '/sympa';
$ENV{PATH_INFO}   = '/help';
is_deeply [Sympa::WWW::Tools::get_robot('wwsympa_url')], [],
    'mismatch SCRIPT_NAME';

$ENV{SERVER_NAME} = 'web.example.org';
$ENV{SCRIPT_NAME} = 'sym/pa';
$ENV{PATH_INFO}   = '/help';
is_deeply [Sympa::WWW::Tools::get_robot('wwsympa_url')], [],
    'dubious SCRIPT_NAME';

$ENV{SERVER_NAME} = 'web.example.org';
$ENV{SCRIPT_NAME} = '/sym/pa/';
$ENV{PATH_INFO}   = 'help';
is_deeply [Sympa::WWW::Tools::get_robot('wwsympa_url')], [],
    'dubious PATH_INFO';

$Conf::Conf{wwsympa_url} = 'http://web.example.org';

$ENV{SERVER_NAME} = 'web.example.org';
$ENV{SCRIPT_NAME} = '';
$ENV{PATH_INFO}   = '/help';
is_deeply [Sympa::WWW::Tools::get_robot('wwsympa_url')],
    ['mail.example.org', '', '/help'],
    'URL prefix on the top: (empty) SCRIPT_NAME & non-empty PATH_INFO';

$ENV{SERVER_NAME} = 'web.example.org';
$ENV{SCRIPT_NAME} = '/help';
$ENV{PATH_INFO}   = undef;
is_deeply [Sympa::WWW::Tools::get_robot('wwsympa_url')],
    ['mail.example.org', '', '/help'],
    'URL prefix on the top: no PATH_INFO';

done_testing();
rmtree 't/tmp';
