# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Test stub for Sympa::Constants;

package Sympa::Constants;

use constant LOCALEDIR => 't/locale';
use constant USER    => $ENV{LOGNAME} || $ENV{USER} || getpwuid($<);
use constant GROUP   => $ENV{LOGNAME} || $ENV{USER} || getgrgid($<);

1;

