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

use Exporter;
@ISA = ('Exporter');
@EXPORT = ();


use Digest::MD5;
use POSIX;
use CGI::Cookie;
use Log;

use strict vars;


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
    

    
## Set user $email cookie, ckecksum use $secret, expire=(now|session|#sec) domain=(localhost|<a domain>)
sub set_cookie {
    my ($email, $secret, $http_domain, $expires, $auth) = @_ ;

    unless ($email) {
	return undef;
    }
    my $expiration;
    if ($expires =~ /now/i) {

	## 10 years ago
	$expiration = '-10y';
    }else{
	$expiration = '+'.$expires.'m';
    }

    if ($http_domain eq 'localhost') {
	$http_domain="";
    }

    my $value = sprintf '%s:%s', $email, &get_mac($email,$secret);
    if ($auth ne 'classic') {
	$value .= ':'.$auth;
    }
    my $cookie;
    if ($expires =~ /session/i) {
	$cookie = new CGI::Cookie (-name    => 'sympauser',
				   -value   => $value,
				   -domain  => $http_domain,
				   -path    => '/'
				   );
    }else {
	$cookie = new CGI::Cookie (-name    => 'sympauser',
				   -value   => $value,
				   -expires => $expiration,
				   -domain  => $http_domain,
				   -path    => '/'
				   );
    }

    ## Send cookie to the client
    printf "Set-Cookie: %s\n", $cookie->as_string;
   
    return 1;
}
    

### Set cookie with lang pref
#sub set_lang_cookie {
#    my ($lang,$domain) = @_;
#
#    if ($domain eq 'localhost') {
#	$domain="";
#    }
#
#    my $cookie = new CGI::Cookie (-name    => 'sympalang',
#				  -value   => $lang,
#				  -expires => '+1M',
#				  -domain  => $domain,
#				  -path    => '/'
#				  );
#    
#    ## Send cookie to the client
#    printf "Set-Cookie:  %s\n", $cookie->as_string;
#   
#    return 1;
#}
    
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
	&do_log('debug4', "get_mac($email, $secret)");

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


## Set cookie for expert_page mode in the shared
# sub set_expertpage_cookie {
#    my ($put,$domain) = @_;
#    
#    if ($domain eq 'localhost') {
#	$domain="";
#    }
#    
#    my $expire;
#    if ($put == 1) {
#	$expire = '+1y';
#    } else {
#	$expire = '-10y';
#    }
#    
#    my $cookie = new CGI::Cookie (-name    => 'sympaexpertpage',
#				  -value   => '1',
#				  -expires => $expire,
#				  -domain  => $domain,
#				  -path    => '/'
#				  );
#    
#    ## Send cookie to the client
#    printf "Set-Cookie:  %s\n", $cookie->as_string;
#    
#    return 1;
#}

## Set cookie for accessing web archives
sub set_which_cookie {
    my $domain = shift ;
    my @which = @_;

    my @listnames;
    foreach my $list (@which) {
	push @listnames, $list->{'name'};
    }

    my $commawhich = join ',', @which;
    
    if ($domain eq 'localhost') {
	$domain="";
    }
    &do_log('debug2',"set_which_cookie ($domain,$commawhich)");

    my $cookie = new CGI::Cookie (-name    => 'your_subscriptions',
				  -value   => $commawhich ,
				  -domain  => $domain,
				  -path    => '/'
				  );
    
    ## Send cookie to the client
    printf "Set-Cookie:  %s\n", $cookie->as_string;
    return 1;
}

###############################
# Subroutines to read cookies #
###############################

## Generic subroutine to get a cookie value
sub generic_get_cookie {
    my $http_cookie = shift;
    my $cookie_name = shift;

    my %cookies = parse CGI::Cookie($http_cookie);
        
    foreach (keys %cookies) {
	my $cookie = $cookies{$_};
	
	next unless ($cookie->name eq $cookie_name);

	return ($cookie->value);
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

## Check cookie for accessing web archives
# sub check_arc_cookie {
#    my $http_cookie = shift;
#    
#    return &generic_get_cookie($http_cookie, 'I_Am_Not_An_Email_Sniffer');
#}

## get cookie for list of subscribtion
sub get_which_cookie {    
    my $http_cookie = shift;
    &do_log('debug2',"get_which_cookie ($http_cookie)");    

    my $subscriptions = &generic_get_cookie($http_cookie, 'your_subscriptions');

    if (defined $subscriptions) {
	my @which;
	foreach my $list (split /,/, $subscriptions) {
	    push @which,$list;
	}
	return @which;
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

## get unappropriate_cas_server
sub get_do_not_use_cas {    
    my $http_cookie = shift;

    return &generic_get_cookie($http_cookie, 'do_not_use_cas');
}

## get unappropriate_cas_server
sub get_cas_server {
    my $http_cookie = shift;

    return &generic_get_cookie($http_cookie, 'cas_server');
}

## Check cookie for expert_page mode in the shared
sub check_expertpage_cookie {
    my $http_cookie = shift;
    
    return &generic_get_cookie($http_cookie, 'sympaexpertpage');
}

## Check cookie for lang pref
#sub check_lang_cookie {
#    my $http_cookie = shift;
#    
#    return &generic_get_cookie($http_cookie, 'sympalang');
#}

## Set cookie for accessing web archives
sub set_do_not_use_cas {
    my $domain = shift;
    my $value = shift ;    
    my $expires=shift;
    
    my $expiration;

    if ($expires =~ /now/i) {
	$expiration = "-10y";
    }else{
	$expiration = '+'.$expires.'m';
    }

    if ($domain eq 'localhost') {
	$domain="";
    }

    do_log('debug',"cookielib::set_do_not_use_cas($domain,$value,$expiration) ");

    unless (($value == 0) || ($value == 1)) {
	do_log('err',"cookielib::set_do_not_use_cas($value) incorrect parameter");
	return undef;
    }
    
    my $cookie = new CGI::Cookie (-name    => 'do_not_use_cas',
				  -value   => $value ,
				  -domain  => $domain,
				  -expires => $expiration,
				  -path    => '/'
				  );
    
    ## Send cookie to the client
    printf "Set-Cookie:  %s\n", $cookie->as_string;
    return 1;
}


## Set cookie for accessing web archives
sub set_cas_server {
    my $domain = shift;
    my $value = shift ;    
    my $expires=shift;

    if ($expires =~ /now/i) {
	$expires = "-10y";
    }

    if ($domain eq 'localhost') {
	$domain="";
    }

    do_log('debug',"cookielib::set_cas_server($domain,$value) ");
    
    my $cookie = new CGI::Cookie (-name    => 'cas_server',
				  -value   => $value ,
				  -domain  => $domain,
				  -expires => $expires,
				  -path    => '/'
				  );
    
    ## Send cookie to the client
    printf "Set-Cookie:  %s\n", $cookie->as_string;
    return 1;
}



1;



