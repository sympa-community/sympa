# -*- indent-tabs-mode: t; -*-
# vim:ft=perl:et:sw=4
# $Id$

use strict;
use warnings;
use English qw(-no_match_vars);
use Test::More;

BEGIN {
    eval { use Test::Perl::Critic -profile => 'xt/perlcriticrc'; };
}
plan(skip_all => 'Test::Perl::Critic required')
    unless $Test::Perl::Critic::VERSION;

all_critic_ok('src/lib');
