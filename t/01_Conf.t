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

ok(Conf::load('t/dummy_data/sympa.conf'), 'Configuration file loading');

done_testing();
