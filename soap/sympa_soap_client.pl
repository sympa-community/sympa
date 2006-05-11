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
use Getopt::Long;

use lib '--LIBDIR--';
# use Conf;
require 'tools.pl';

use strict;


my ($reponse, @ret, $val, %fault);


my $usage = "$0 is a perl soap client for Sympa for TEST ONLY. Use it to illustrate how to code access to features of Sympa soap server. Authentication can be done via user/password or user cookie or as a trusted remote application\n";
   $usage = "Usage: $0 --soap_url=<soap sympa server url> --service=<a sympa service> --trusted_application=<app name> __trusted_application_password=<password> --proxy_vars=<id=value,id2=value2> --service_parameters=<value1,value2,value3>";
   $usage .="       $0 --soap_url=<soap sympa server url> --user_email=<email> --user_password=<password> \n";

my %options;
unless (&GetOptions(\%main::options, 'soap_url=s', 'service=s', 'trusted_application=s', 'trusted_application_password=s','user_email=s', 'user_password=s','proxy_vars=s','service_parameters=s')) {
    printf "";
}


my $soap_url = $main::options{'soap_url'};
unless (defined $soap_url){
    printf "error : missing soap_url parameter\n";
    printf $usage;
    exit;
}

my $user_email = $main::options{'user_email'};
my $user_password =$main::options{'user_password'};
my $trusted_application =$main::options{'trusted_application'};
my $trusted_application_password =$main::options{'trusted_application_password'};
my $proxy_vars=$main::options{'proxy_vars'};
my $service=$main::options{'service'};
my $service_parameters=$main::options{'service_parameters'};

if (defined $trusted_application) {
    unless (defined $trusted_application_password) {
	printf "error : missing trsuted_application_password parameter\n";
	printf $usage;
	exit;
    }
    unless (defined $service) {
	printf "error : missing service parameter\n";
	printf $usage;
	exit;
    }
    unless (defined $proxy_vars) {
	printf "error : missing proxy_vars parameter\n";
	printf $usage;
	exit;
    }

    &play_soap_as_trusted($soap_url, $trusted_application,  $trusted_application_password, $service, $proxy_vars, $service_parameters);
}else{

    unless (defined $user_email){
	printf "error : missing user_email parameter\n";
	printf $usage;
	exit;
    }
    unless (defined  $user_password) {
	printf "error : missing user_password parameter\n";
	printf $usage;
	exit;
    }

    &play_soap($soap_url, $user_email, $user_password);


}

sub play_soap_as_trusted{
    my $soap_url=shift;
    my $trusted_application=shift;
    my $trusted_application_password=shift;
    my $service=shift;
    my $proxy_vars=shift;
    my $service_parameters=shift;

    my $soap = new SOAP::Lite();    
    $soap->uri('urn:sympasoap');
    $soap->proxy($soap_url);

    my @parameters; 
    @parameters= split(/,/,$service_parameters) if (defined $service_parameters);
    my $p= join(',',@parameters);
    printf "calling authenticateRemoteAppAndRun( $trusted_application, $trusted_application_password, $proxy_vars,$service,$p)\n";

    my $reponse = $soap->authenticateRemoteAppAndRun( $trusted_application, $trusted_application_password, $proxy_vars,$service,\@parameters);
    &print_result($reponse);
}



sub play_soap{
    my $soap_url=shift;
    my $user_email=shift;
    my $user_password=shift;

    my ($service, $reponse, @ret, $val, %fault);

    ## Cookies management
    # my $uri = new URI($soap_url);
    
    my $cookies = HTTP::Cookies->new(ignore_discard => 1,
				     file => '/tmp/my_cookies' );
    $cookies->load();
    printf "cookie : %s\n", $cookies->as_string();


    # Change to the path of Sympa.wsdl
    #$service = SOAP::Lite->service($soap_url);
    #$reponse = $service->login($user_email,$user_password);
    #my $soap = SOAP::Lite->service($soap_url);
     
    my $soap = new SOAP::Lite();
    #$soap->on_debug(sub{print@_});
    $soap->uri('urn:sympasoap');
    $soap->proxy($soap_url,
		 cookie_jar =>$cookies);

    print "LOGIN....\n";

    #$reponse = $soap->casLogin($soap_url);
    $reponse = $soap->login($user_email,$user_password);
    $cookies->save;
    &print_result($reponse);
    my $md5 = $reponse->result;
    
    print "\n\nAuthenticateAndRun simple which....\n";
    $reponse = $soap->authenticateAndRun($user_email,$md5,'which');
    &print_result($reponse);
    
    #printf "%s\n", $cookies->as_string();
       
    print "\n\nWHICH....\n";
    $reponse = $soap->complexWhich();
    &print_result($reponse);
exit;    
    #print "\n\nINFO....\n";
    #$reponse = $soap->info('aliba');
    #&print_result($reponse);
    
    # print "\n\nSUB....\n";
    # $reponse = $soap->subscribe('aliba', 'ALI'); 
    # &print_result($reponse);
    
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
}

sub print_result {
    my $r = shift;

# If we get a fault
    if (defined $r && $r->fault) {
	print "Soap error :\n";
	my %fault = %{$r->fault};
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
