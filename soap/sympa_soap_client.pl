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
use HTTP::Cookies;
use URI;

use lib '--LIBDIR--';
use Conf;
require 'tools.pl';

use strict;

my ($service, $reponse, @ret, $val, %fault);

## Cookies management
my $uri = new URI('http://www.cru.fr/wwsoap');

my $cookies = HTTP::Cookies->new(ignore_discard => 1,
				 file => '/tmp/my_cookies' );
$cookies->load();
printf "%s\n", $cookies->as_string();

#$cookies->set_cookie(0, 'Y_Y_Y_Y' => 'X_X_X_X', '/', 'www.cru.fr');

# Change to the path of Sympa.wsdl
#$service = SOAP::Lite->service('http://www.cru.fr/wws/wsdl');
#$reponse = $service->login($ARGV[0],$ARGV[1]);

my $soap = new SOAP::Lite();
$soap->uri('urn:sympasoap');
$soap->proxy('http://www.cru.fr/wwsoap',
	     cookie_jar =>$cookies);

#    ->outputxml(1);
#    ->readable(1);

#$reponse = $service->which($ARGV[0],$ARGV[1]);

print "LOGIN....\n";
$reponse = $soap->login($ARGV[0],$ARGV[1]);
$cookies->save;
&print_result($reponse);

#printf "%s\n", $cookies->as_string();

print "\n\nWHICH....\n";
$reponse = $soap->which();
&print_result($reponse);


print "\n\nSUB....\n";
$reponse = $soap->subscribe('aliba', 'ALI');
&print_result($reponse);

print "\n\nREVIEW....\n";
$reponse = $soap->review('aliba');
&print_result($reponse);


print "\n\nSIG....\n";
$reponse = $soap->signoff('aliba');
&print_result($reponse);

print "\n\nLIST....\n";
$reponse = $soap->lists('actualite');
&print_result($reponse);

print "\n\nCheck_cookie....\n";
$reponse = $soap->check_cookie();
&print_result($reponse);

sub print_result {
    my $r = shift;

# If we get a fault
    if ($r->fault) {
	print "Soap error :\n";
	%fault = %{$r->fault};
	foreach $val (keys %fault) {
	    print "$val = $fault{$val}\n";
	}
    }else {
	if (ref( $r->result)) {
	    @ret = @{$r->result};
	}else {
	    @ret = $r->result;
	}
	&tools::dump_var(\@ret, 0, \*STDOUT);
    }

    return 1;
}
