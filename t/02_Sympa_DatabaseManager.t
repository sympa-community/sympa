#!/usr/bin/perl
# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id: tools_data.t 8606 2013-02-06 08:44:02Z rousse $

use strict;
use warnings;
use Data::Dumper;

use FindBin qw($Bin);
use lib "$Bin/../src/lib";

use Test::More;

BEGIN {
    use_ok('Sympa::DatabaseManager');
}

Conf::load('t/dummy_data/sympa.conf');

ok(my $sdm = Sympa::DatabaseManager->instance, 'Connection to dummy database.');

is($sdm->get_id(),'db_name=t/dummy_data/sympa', 'Check database id value');

ok(Sympa::DatabaseManager->disconnect, 'Disconnection from database');

done_testing();
