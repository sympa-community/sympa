# cookielib.pm - This module includes functions managing HTTP cookies in Sympa
# RCS Identication ; $Revision$ ; $Date$ 
#
# Sympa - SYsteme de Multi-Postage Automatique
# Copyright (c) 1997, 1998, 1999, 2000, 2001 Comite Reseau des Universites
# Copyright (c) 1997,1998, 1999 Institut Pasteur & Christophe Wolfhugel
#
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


package cookielib;

use strict vars;

use Digest::MD5;
use POSIX;
use CGI::Cookie;

use Log;

## Generic subroutine to set a cookie
sub generic_set_cookie {
    my %param = @_;

    my %cookie_param;
    foreach my $p ('name','value','expires','domain','path') {
	$cookie_param{'-'.$p} = $param{$p}; ## CGI::Cookie expects -param => value
    }

    if ($cookie_param{'-domain'} eq 'localhost') {
	$cookie_param{'-domain'} = '';
    }

    my $cookie = new CGI::Cookie(%cookie_param);

    ## Send cookie to the client
    printf "Set-Cookie:  %s\n", $cookie->as_string;
   
    return 1;
}
    

    
# Sets an HTTP cookie to be sent to a SOAP client
sub set_cookie_soap {
    my ($session_id,$http_domain,$expire) = @_ ;
    my $cookie;
    my $value;

    # WARNING : to check the cookie the SOAP services does not gives
    # all the cookie, only it's value so we need ':'
    $value = $session_id;
  
    ## With set-cookie2 max-age of 0 means removing the cookie
    ## Maximum cookie lifetime is the session
    $expire ||= 600; ## 10 minutes

    if ($http_domain eq 'localhost') {
	$cookie = sprintf "%s=%s; Path=/; Max-Age=%s", 'sympa_session', $value, $expire;
    }else {
	$cookie = sprintf "%s=%s; Domain=%s; Path=/; Max-Age=%s", 'sympa_session', $value, $http_domain, $expire;;
    }

    ## Return the cookie value
    return $cookie;
}

## returns Message Authentication Check code
sub get_mac {
        my $email = shift ;
	my $secret = shift ;	
	&do_log('debug3', "get_mac($email, $secret)");

	unless ($secret) {
	    &do_log('err', 'get_mac : failure missing server secret for cookie MD5 digest');
	    return undef;
	}
	unless ($email) {
	    &do_log('err', 'get_mac : failure missing email adresse or cookie MD5 digest');
	    return undef;
	}



	my $md5 = new Digest::MD5;

	$md5->reset;
	$md5->add($email.$secret);

	return substr( unpack("H*", $md5->digest) , -8 );

}

sub set_cookie_extern {
    my ($secret,$http_domain,%alt_emails) = @_ ;
    my $expiration;
    my $cookie;
    my $value;

    my @mails ;
    foreach my $mail (keys %alt_emails) {
	my $string = $mail.':'.$alt_emails{$mail};
	push(@mails,$string);
    }
    my $emails = join(',',@mails);

    $value = sprintf '%s&%s',$emails,&get_mac($emails,$secret);
 
    if ($http_domain eq 'localhost') {
	$http_domain="";
    }

	$cookie = new CGI::Cookie (-name    => 'sympa_altemails',
	                           -value   => $value,
				   -expires => '+1y',
				   -domain  => $http_domain,
				   -path    => '/'
				   );
    ## Send cookie to the client
    printf "Set-Cookie: %s\n", $cookie->as_string;
    #do_log('notice',"set_cookie_extern : %s",$cookie->as_string);
    return 1;
}




###############################
# Subroutines to read cookies #
###############################

## Generic subroutine to get a cookie value
sub generic_get_cookie {
    my $http_cookie = shift;
    my $cookie_name = shift;

    if ($http_cookie =~/\S+/g) {
	my %cookies = parse CGI::Cookie($http_cookie);
	foreach (keys %cookies) {
	    my $cookie = $cookies{$_};
	    next unless ($cookie->name eq $cookie_name);
	    return ($cookie->value);
	}
    }
    return (undef);
}

## Returns user information extracted from the cookie
sub check_cookie {
    my $http_cookie = shift;
    my $secret = shift;
    
    my $user = &generic_get_cookie($http_cookie, 'sympauser');

    my @values = split /:/, $user; 
    if ($#values >= 1) {
	my ($email, $mac, $auth) = @values;
	$auth ||= 'classic';
	
	## Check the MAC
	if (&get_mac($email,$secret) eq $mac) {
	    return ($email, $auth);
	}
    }	

    return undef;
}

sub check_cookie_extern {
    my ($http_cookie,$secret,$user_email) = @_;

    my $extern_value = &generic_get_cookie($http_cookie, 'sympa_altemails');
 
    if ($extern_value =~ /^(\S+)&(\w+)$/) {
	return undef unless (&get_mac($1,$secret) eq $2) ;
		
	my %alt_emails ;
	foreach my $element (split(/,/,$1)){
	    my @array = split(/:/,$element);
	    $alt_emails{$array[0]} = $array[1];
	}
	      
	my $e = lc($user_email);
	unless ($alt_emails{$e}) {
	    return undef;
	}
	return (\%alt_emails);
    }
    return undef
}

1;



