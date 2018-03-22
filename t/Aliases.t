# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

use strict;
use warnings;
use Test::More;
use Test::Exception;

use_ok('Sympa::Aliases');

ok(my $alias_manager = Sympa::Aliases->new(type => 'Sympa::Aliases::Template'), 'Alais manager object created');

is($alias_manager->check(), 0, 'check sub on the base class returns 0');

is($alias_manager->add(), 0, 'add sub on the base class returns 0');

is($alias_manager->del(), 0, 'del sub on the base class returns 0');

done_testing();
