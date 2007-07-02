#!--PERL-- -w

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


my $usage = "\n$0 is a perl soap client for Sympa for TEST ONLY. Use it to illustrate how to code access to features of Sympa soap server. Authentication can be done via user/password or user cookie or as a trusted remote application\n\n";
$usage .= "Usage: $0 <with the following options:>\n\n";
$usage .= "--soap_url=<soap sympa server url>\n";
$usage .= "--service=<a sympa service>\n";
$usage .= "--trusted_application=<app name>\n";
$usage .= "--trusted_application_password=<password>\n";
$usage .= "--proxy_vars=<id=value,id2=value2>\n";
$usage .= "--service_parameters=<value1,value2,value3>\n\n\n";
$usage .= "OR usage: $0 <with the following options:>\n\n";
$usage .= "--soap_url=<soap sympa server url>\n";
$usage .= "--user_email=<email>\n";
$usage .= "--user_password=<password>\n";
$usage .= "--service=<a sympa service>\n";
$usage .= "--service_parameters=<value1,value2,value3>\n\n\n";
$usage .= "OR usage: $0 <with the following options:>\n\n";
$usage .= "--soap_url=<soap sympa server url>\n";
$usage .= "--cookie=<sympauser cookie string>\n\n\n";
$usage .= "Example: \n\n$0 --soap_url=<soap sympa server url> --cookie=sympauser=someone\@cru.fr%3A8be58b86\n\n";

my %options;
unless (&GetOptions(\%main::options, 'soap_url=s', 'service=s', 'trusted_application=s', 'trusted_application_password=s','user_email=s', 'user_password=s','cookie=s','proxy_vars=s','service_parameters=s')) {
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
my $cookie=$main::options{'cookie'};

if (defined $trusted_application) {
    unless (defined $trusted_application_password) {
	printf "error : missing trusted_application_password parameter\n";
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
}elsif(defined $cookie){
    printf "error : get_email_cookie\n";
     &get_email($soap_url, $cookie);
     exit;
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
    &play_soap($soap_url, $user_email, $user_password, $service, $service_parameters);
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

sub get_email {
     my $soap_url=shift;
     my $cookie=shift;

    my ($service, $reponse, @ret, $val, %fault);

    ## Cookies management
    # my $uri = new URI($soap_url);
    
#    my $cookies = HTTP::Cookies->new(ignore_discard => 1,
#				     file => '/tmp/my_cookies' );
#    $cookies->load();
    printf "cookie : %s\n", $cookie;

     
    my $soap = new SOAP::Lite();
    #$soap->on_debug(sub{print@_});
    $soap->uri('urn:sympasoap');
     $soap->proxy($soap_url);
#,		 cookie_jar =>$cookies);

    print "\n\ngetEmailUserByCookie....\n";
    $reponse = $soap->getUserEmailByCookie($cookie);
    &print_result($reponse);
exit;
  
 }

sub play_soap{
    my $soap_url=shift;
    my $user_email=shift;
    my $user_password=shift;
    my $service=shift;
    my $service_parameters=shift;

    my ($reponse, @ret, $val, %fault);

    ## Cookies management
    # my $uri = new URI($soap_url);
    
    my $cookies = HTTP::Cookies->new(ignore_discard => 1,
				     file => '/tmp/my_cookies' );
    $cookies->load();
    printf "cookie : %s\n", $cookies->as_string();

    my @parameters; 
    @parameters= split(/,/,$service_parameters) if (defined $service_parameters);
    my $p= join(',',@parameters);
    foreach my $tmpParam (@parameters) {
	printf "param: %s\n", $tmpParam;
    }

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
    
    printf "\n\nAuthenticateAndRun %s....\n",$service;
    $reponse = $soap->authenticateAndRun($user_email,$md5,$service,\@parameters);
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
