#!/usr/bin/env perl

use warnings;
use strict;

use Test::More;
use lib 'lib';

BEGIN {
   eval "require Net::OAuth2::Profile::WebServer";
   $@ and plan skip_all =>
      'install Net::OAuth2 if you want to connect to SURFnet';

   my $v = Net::OAuth2::Profile::WebServer->VERSION;
   !defined $v || $v > 0.50 or plan skip_all =>
      'upgrade Net::0Auth2 to at least 0.50';

   plan tests => 2;
}
 
use_ok('Net::VOOT::SURFnet');


#XXX MO: next to be removed
use_ok('Sympa::ListSource::VOOT');
