# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Test stub for Sympa::Constants;

package Sympa::Constants;

use constant VERSION => '6.2.52';
use constant USER    => [getpwuid $<]->[0];
use constant GROUP   => [getgrgid $(]->[0];

use constant CONFIG           => 't/tmp/etc/sympa.conf';
use constant WWSCONFIG        => 't/tmp/etc/wwsympa.conf';
use constant SENDMAIL_ALIASES => 't/tmp/etc/mail/sympa_aliases';

use constant PIDDIR      => 't/tmp';
use constant EXPLDIR     => 't/tmp/list_data';
use constant SPOOLDIR    => 't/tmp/spool';
use constant SYSCONFDIR  => 't/tmp/etc';
use constant LOCALEDIR   => 't/locale';
use constant LIBEXECDIR  => 't/tmp/bin';
use constant SBINDIR     => 't/tmp/bin';
use constant SCRIPTDIR   => 't/tmp/bin';
use constant MODULEDIR   => 't/tmp/bin';
use constant DEFAULTDIR  => 'default';
use constant ARCDIR      => 't/tmp/arc';
use constant BOUNCEDIR   => 't/tmp/bounce';
use constant EXECCGIDIR  => 't/tmp/bin';
use constant STATICDIR   => 't/tmp/static_content';
use constant CSSDIR      => 't/tmp/static_content/css';
use constant PICTURESDIR => 't/tmp/static_content/pictures';

use constant EMAIL_LEN  => 100;
use constant FAMILY_LEN => 50;
use constant LIST_LEN   => 50;
use constant ROBOT_LEN  => 80;

1;

