#!/usr/bin/perl
# -*- indent-tabs-mode: t; -*-
# vim:ft=perl:et:sw=4
# $Id: critic.c 8606 2013-02-06 08:44:02Z rousse $

use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../src/lib";

use English qw(-no_match_vars);
use Test::More;

plan(skip_all => 'Author test, set $ENV{TEST_AUTHOR} to a true value to run')
    if !$ENV{TEST_AUTHOR};

eval {
    require Test::Perl::Critic;
    Test::Perl::Critic->import();
};
plan(skip_all => 'Test::Perl::Critic required') if $EVAL_ERROR;

Test::Perl::Critic->import(-profile => 't/perlcriticrc');

all_critic_ok('src/lib');
