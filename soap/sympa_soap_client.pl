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
my $uri = new URI($ARGV[0]);

my $cookies = HTTP::Cookies->new(ignore_discard => 1,
				 file => '/tmp/my_cookies' );
$cookies->load();
printf "%s\n", $cookies->as_string();


# Change to the path of Sympa.wsdl
#$service = SOAP::Lite->service($ARGV[0]);
#$reponse = $service->login($ARGV[1],$ARGV[2]);

#my $soap = SOAP::Lite->service($ARGV[0]);

my $soap = new SOAP::Lite();
#$soap->on_debug(sub{print@_});
$soap->uri('urn:sympasoap');
$soap->proxy($ARGV[0],
	     cookie_jar =>$cookies);


print "LOGIN....\n";

#$reponse = $soap->casLogin($ARGV[0]);
$reponse = $soap->login($ARGV[1],$ARGV[2]);
$cookies->save;
&print_result($reponse);
my $md5 = $reponse->result;

print "\n\nAuthenticateAndRun simple which....\n";
$reponse = $soap->authenticateAndRun($ARGV[1],$md5,'which');
&print_result($reponse);

#printf "%s\n", $cookies->as_string();

print "\n\nWHICH....\n";
$reponse = $soap->complexWhich();
&print_result($reponse);

#print "\n\nINFO....\n";
#$reponse = $soap->info('aliba');
#&print_result($reponse);

#print "\n\nSUB....\n";
#$reponse = $soap->subscribe('aliba', 'ALI');
#&print_result($reponse);

#print "\n\nREVIEW....\n";
#$reponse = $soap->review('aliba');
#&print_result($reponse);


#print "\n\nSIG....\n";
#$reponse = $soap->signoff('aliba');
#&print_result($reponse);

print "\n\nLIST....\n";
$reponse = $soap->lists('Kulturelles');
&print_result($reponse);

print "\n\nComplex LIST....\n";
$reponse = $soap->complexLists('Kulturelles');
&print_result($reponse);

print "\n\nAM I....\n";
$reponse = $soap->amI('aliba','owner','olivier.salaun@cru.fr');
&print_result($reponse);

print "\n\nCheckCookie....\n";
$reponse = $soap->checkCookie();
&print_result($reponse);

sub print_result {
    my $r = shift;

# If we get a fault
    if (defined $r && $r->fault) {
	print "Soap error :\n";
	%fault = %{$r->fault};
	foreach $val (keys %fault) {
	    print "$val = $fault{$val}\n";
	}
    }else {
	if (ref( $r->result) =~ /^ARRAY/) {
	    #printf "R: $r->result\n";
	    @ret = @{$r->result};
	}elsif (ref $r->result) {
	    printf "Pb $r->result\n";
	    return undef;
	}else {
	    @ret = $r->result;
	}
	&tools::dump_var(\@ret, 0, \*STDOUT);
    }

    return 1;
}
