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

## Returns user information extracted from the cookie
sub check_cookie {
    my $http_cookie = shift;
    my $secret = shift;
    
    my %cookies = parse CGI::Cookie($http_cookie);
    
    ## Scan parameters
    ## With Sort, priority is given to newly 'sympauser'
    foreach (sort keys %cookies) {
	my $cookie = $cookies{$_};
	
	next unless ($cookie->name =~ /^(sympauser|user)$/);

	if ($cookie->value =~ /^(.*):(\S+)\s*$/) {
	    my ($email, $mac) = ($1, $2);

	    ## Check the MAC
	    if (&get_mac($email,$secret) eq $mac) {
		return $email;
	    }
	}	
    }

    return undef;
}


## Check cookie for accessing web archives
sub check_arc_cookie {
    my $http_cookie = shift;

    ## Scan parameters
    foreach (split /;/, $http_cookie ) {
	if ( /I_Am_Not_An_Email_Sniffer/ ) {
	    return 1;
	}
    }    
    return undef;
}

## Check cookie for lang pref
sub check_lang_cookie {
    my $http_cookie = shift;
    
    my %cookies = parse CGI::Cookie($http_cookie);
    
    ## Scan parameters
    ## With Sort, priority is given to newly 'sympauser'
    foreach (sort keys %cookies) {
	my $cookie = $cookies{$_};
	
	next unless ($cookie->name eq 'sympalang');

	return $cookie->value;
    }

    return undef;
}

## Set user $email cookie, ckecksum use $secret, expire=(now|session|#sec) domain=(localhost|<a domain>)
sub set_cookie {
    my ($email, $secret, $http_domain, $expires) = @_ ;

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
    
## Set cookie for accessing web archives
sub set_arc_cookie {
    my ($domain);

    my $cookie = new CGI::Cookie (-name    => 'I_Am_Not_An_Email_Sniffer',
				  -value   => 'Let_Me_In',
				  -expires => '+1y',
				  -domain  => $domain,
				  -path    => '/'
				  );
    
    ## Send cookie to the client
    printf "Set-Cookie:  %s\n", $cookie->as_string;
   
    return 1;
}
    
## Set cookie with lang pref
sub set_lang_cookie {
    my ($lang,$domain) = @_;

    my $cookie = new CGI::Cookie (-name    => 'sympalang',
				  -value   => $lang,
				  -expires => '+1M',
				  -domain  => $domain,
				  -path    => '/'
				  );
    
    ## Send cookie to the client
    printf "Set-Cookie:  %s\n", $cookie->as_string;
   
    return 1;
}
    
## returns Message Authentication Check code
sub get_mac {
        my $email = shift ;
	my $secret = shift ;
	
	unless ($secret) {
	    printf STDERR 'get_mac : failure missing server secret for cookie MD5 digest';
	    return undef;
	}
	unless ($email) {
	    printf STDERR 'get_mac : failure missing email adresse or cookie MD5 digest';
	    return undef;
	}



	my $md5 = new Digest::MD5;

	$md5->reset;
	$md5->add($email.$secret);

	return substr( unpack("H*", $md5->digest) , -8 );

}

sub check_cookie_extern {
    my ($http_cookie,$secret,$user_email) = @_;
    my %cookies = parse CGI::Cookie($http_cookie);
 
    ## Scan parameters

    foreach (sort keys %cookies) {
	my $cookie = $cookies{$_};
	
	next unless ($cookie->name =~ /sympa_altemails/);
	
	if ($cookie->value =~ /^(\S+)&(\w+)$/) {
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
    }
    return undef
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

## get cookie for list of subscribtion
sub get_which_cookie {
    
    my $http_cookie = shift;

    do_log ('debug2',"get_which_cookie ($http_cookie)");    

    my %cookies = parse CGI::Cookie($http_cookie);
        
    foreach (sort keys %cookies) {
	my $cookie = $cookies{$_};
	
	next unless ($cookie->name eq 'your_subscriptions');
	my @which;
	foreach my $list (split /,/, $cookie->value) {
	    push @which,$list;
	}
	return (@which);
    }
    return undef;
}

## Set cookie for accessing web archives
sub set_which_cookie {
    my $domain = shift ;
    my @which = @_;

    my $commawhich = join ',', @which;
    
    if ($domain eq 'localhost') {
	$domain="";
    }
    do_log ('debug2',"set_which_cookie ($domain,$commawhich)");

    my $cookie = new CGI::Cookie (-name    => 'your_subscriptions',
				  -value   => $commawhich ,
				  -domain  => $domain,
				  -path    => '/'
				  );
    
    ## Send cookie to the client
    printf "Set-Cookie:  %s\n", $cookie->as_string;
    return 1;
}


1;



