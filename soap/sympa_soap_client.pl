#! --PERL-- -w

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

#use SOAP::Lite +trace;
use SOAP::Lite;

use lib '--LIBDIR--';
use Conf;
#use Log;

use strict;

my $sympa_conf_file = '--CONFIG--';

## Load sympa config
#unless (&Conf::load($sympa_conf_file)) {
#    printf STDERR 'Unable to load sympa config file %s', $sympa_conf_file;
#}

my ($service, $reponse, @ret, $val, %fault);

print "Debut\n";
# Change to the path of Sympa.wsdl
$service = SOAP::Lite->service('http://www.cru.fr/wws/wsdl');
#    ->outputxml(1);
#    ->readable(1);

# Select your function
#$reponse = $service->amI($ARGV[0],$ARGV[1],$ARGV[2]);
#$reponse = $service->isSubscriber($ARGV[0],$ARGV[1]);
#$reponse = $service->review($ARGV[0],$ARGV[1],$ARGV[2],$ARGV[3],$ARGV[4]);
#$reponse = $service->subscribe($ARGV[0],$ARGV[1],$ARGV[2],$ARGV[3],$ARGV[4]);
#$reponse = $service->sign_off($ARGV[0],$ARGV[1],$ARGV[2],$ARGV[3],$ARGV[4]);
#$reponse = $service->do_login($ARGV[0],$ARGV[1],$ARGV[2]);
#$reponse =  $service->do_lists($ARGV[0],$ARGV[1],$ARGV[2],$ARGV[3],$ARGV[4]);

print "Avant\n";
$reponse = $service->do_which($ARGV[0],$ARGV[1]);
print "Après\n";

# If we get a fault
if ($service->call->fault)
{
    print "Soap error :\n";
    %fault = %{$service->call->fault};
    foreach $val (keys %fault)
    {
	print "$val = $fault{$val}\n";
    }
}
else
{
    if (ref( $service->call->result)) {
	@ret = @{$service->call->result};
    }else{
	@ret = $service->call->result;
    }
    
    &tools::dump_vars(\@res, 0);

}





