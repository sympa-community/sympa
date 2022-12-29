#!/usr/bin/perl
# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id: tools_data.t 8606 2013-02-06 08:44:02Z rousse $

use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../src/lib";

use Test::More;

BEGIN {
    use_ok('Conf');
}

ok(Conf::load('t/data/sympa.conf'), 'Configuration file loading');

is(Conf::get_robot_conf('*', 'listmaster'),
    'dude@example.com', 'Check correct loading of Sympa gecos parameter');

done_testing();
