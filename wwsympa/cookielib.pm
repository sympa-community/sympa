package cookielib;

use Exporter;
@ISA = ('Exporter');
@EXPORT = ();


use MD5;
use POSIX;

## Returns user information extracted from the cookie
sub check_cookie {

    my $http_cookie = shift;
    my $secret = shift;

    ## Scan parameters
    foreach (split /;/, $http_cookie ) {
	if ( /^\s*(sympauser|user)\=(.*):(\S+)\s*$/ ) {
	    my ($email, $mac) = ($2, $3);

	    ## Check the MAC
	    if (&get_mac($email,$secret) eq $mac) {
		return $email;
	    }else{
		return undef 
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
    my ($date,$expiration,$domain);
    if ($expires =~ /now/i) {
	$expiration = 'expires=Tue,1-Jan-1970 10:10:10 GMT; ';
    }elsif ($expires =~ /session/i) {
	$expiration = "";
    }else{
	## Keep locale and set it to 
	my $locale = $ENV{'LC_ALL'};
	&POSIX::setlocale(&POSIX::LC_ALL, 'C');
	
	my $date = &POSIX::strftime("%A, %d-%b-%Y %H:%M:%S GMT", gmtime(time + (60 * $expires) ));
	
	## Restore locale
	&POSIX::setlocale(&POSIX::LC_ALL, $locale);
	
	$expiration = 'expires='.$date.'; ';
    }
    if ($http_domain eq 'localhost') {
	$domain="";
    }else{
	$domain='domain='.$http_domain.'; ';
    }
    ## Send cookie to the client
    printf "Set-Cookie: sympauser=%s:%s; %s %s path=/\n", $email, &get_mac($email,$secret), $expiration,$domain;
   
    return 1;
}
    
## Set cookie for accessing web archives
sub set_arc_cookie {
    my ($date,$expiration,$domain);

    ## Keep locale and set it to 
    my $locale = $ENV{'LC_ALL'};
    &POSIX::setlocale(&POSIX::LC_ALL, 'C');
    
    my $date = &POSIX::strftime("%A, %d-%b-%Y %H:%M:%S GMT", gmtime(time + (60 * 60 * 24 * 30) ));
    
    ## Restore locale
    &POSIX::setlocale(&POSIX::LC_ALL, $locale);
    
    ## Send cookie to the client
    printf "Set-Cookie: I_Am_Not_An_Email_Sniffer=Let_Me_In; expires=%s path=/\n", $date;
   
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
