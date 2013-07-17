#!/usr/bin/env perl

use warnings;
use strict;

use Test::More;
use lib 'lib';

BEGIN {
   eval "require OAuth::Lite::Consumer";
   $@ and plan skip_all =>
      'install OAuth::Lite::Consumer if you want to connect to Renater';

   plan tests => 1;
}
 
use_ok('Net::VOOT::Renater');
