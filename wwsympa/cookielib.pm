package cookielib;

use Exporter;
@ISA = ('Exporter');
@EXPORT = ();


use MD5;
use POSIX;
use CGI::Cookie;
use Log;

## Returns user information extracted from the cookie
sub check_cookie {
    my $http_cookie = shift;
    my $secret = shift;
    
    my %cookies = parse CGI::Cookie($http_cookie);
    
    ## Scan parameters
    ## With Sort, priority is given to newly 'sympauser'
    foreach (sort keys %cookies) {
	my $cookie = $cookies{$_};
	
	next unless ($cookie->name =~ /^sympauser|user$/);

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
	if ( /^I_Am_Not_An_Email_Sniffer/ ) {
	    return 1;
	}
    }    
    return undef;
}

## Set user $email cookie, ckecksum use $secret, expire=(now|session|#sec) domain=(localhost|<a domain>)
sub set_cookie {
    my ($email, $secret, $http_domain, $expires) = @_ ;

    unless ($email) {
	return undef;
    }
    my ($expiration,$domain);
    if ($expires =~ /now/i) {

	## 10 years ago
	$expiration = '-10y';
    }else{
	$expiration = '+'.$expires.'m';
    }

    if ($http_domain eq 'localhost') {
	$domain="";
    }else{
	$domain='domain='.$http_domain.'; ';
    }

    my $value = sprintf '%s:%s', $email, &get_mac($email,$secret);
    my $cookie;
    if ($expires =~ /session/i) {
	$cookie = new CGI::Cookie (-name    => 'sympauser',
				   -value   => $value,
				   -domain  => $domain,
				   -path    => '/'
				   );
    }else {
	$cookie = new CGI::Cookie (-name    => 'sympauser',
				   -value   => $value,
				   -expires => $expiration,
				   -domain  => $domain,
				   -path    => '/'
				   );
    }

    ## Send cookie to the client
    printf "Set-Cookie: %s\n", $cookie->as_string;
   
    return 1;
}
    
## Set cookie for accessing web archives
sub set_arc_cookie {
    my ($date,$expiration,$domain);

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



	my $md5 = new MD5;

	$md5->reset;
	$md5->add($email.$secret);

	return substr( unpack("H*", $md5->digest) , -8 );

}

1;
