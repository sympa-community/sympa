# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

use strict;
use warnings;
use Test::More;

plan tests => 1;

use_ok('Conf');

Conf::load('t/config_samples/sympa.conf', 0, 0);
