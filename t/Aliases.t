# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

use strict;
use warnings;
use Test::More;

plan tests => 2;

use_ok('Sympa::Aliases');

ok(Sympa::Aliases->new(type => 'Sympa::Aliases::Template',));
