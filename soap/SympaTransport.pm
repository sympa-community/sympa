package SOAP::Transport::HTTP::FCGI::Sympa;

use strict;
use vars qw(@ISA);

use SOAP::Transport::HTTP;
@ISA = qw(SOAP::Transport::HTTP::FCGI);

1;

sub request {
    my $self = shift;
    
    
    if (my $request = $_[0]) {	
	
	my %sympa_cookies;

	## Accept cookies V1 and V2
	my @cookies1 = $request->headers->header('cookie');
	my @cookies2 = $request->headers->header('cookie2');
	my @cookies = (@cookies1,@cookies2);

	foreach my $cookie ( @cookies) {
	    foreach my $token (split /;/,$cookie) {
		$token =~ s/^\s+//;
		$token =~ s/\s+$//;
		my ($key, $value) = split(/=/,$token);
		$value =~ s/^\"(.+)\"$/$1/;
		if ($key =~ /^sympa/) {
		    $sympa_cookies{$key} = $value;
		}
	    }
	}
	
	## Empty cache of the List.pm module
	&List::init_list_cache();

	delete $ENV{'USER_EMAIL'};
	if (defined $sympa_cookies{'sympauser'}) {
	    my ($email, $md5) = split /:/,$sympa_cookies{'sympauser'};
	    if (&cookielib::get_mac($email, $Conf::Conf{'cookie'}) eq $md5) {
		$ENV{'USER_EMAIL'} = $email;
	    }
	}
    }

    ## Select appropriate robot
    if (defined $Conf::Conf{'robot_by_soap_url'}{$ENV{'SERVER_NAME'}.$ENV{'SCRIPT_NAME'}}) {
	$ENV{'SYMPA_ROBOT'} = $Conf::Conf{'robot_by_soap_url'}{$ENV{'SERVER_NAME'}.$ENV{'SCRIPT_NAME'}};
	&Log::do_log('debug2', 'Robot : %s', $ENV{'SYMPA_ROBOT'});
    }else {
	&Log::do_log('debug2', 'URL : %s', $ENV{'SERVER_NAME'}.$ENV{'SCRIPT_NAME'});
	$ENV{'SYMPA_ROBOT'} =  $Conf::Conf{'host'} ;
    }

    $self->SUPER::request(@_);
}

sub response {
    my $self = shift;
    
    if (my $response = $_[0]) {
	if (defined $ENV{'USER_EMAIL'}) {
	    my $expire = $main::param->{'user'}{'cookie_delay'} || $main::wwsconf->{'cookie_expire'};
	    &cookielib::set_cookie_soap($ENV{'USER_EMAIL'}, $Conf::Conf{'cookie'}, $ENV{'SERVER_NAME'}, $expire);
	}
	
	if (defined $ENV{'SOAP_COOKIE_sympauser'}) {
	    $response->headers->push_header('Set-Cookie2' => $ENV{'SOAP_COOKIE_sympauser'});
	    delete $ENV{'SOAP_COOKIE_sympauser'};
	}
    }
    
    $self->SUPER::request(@_);
}

## Redefine FCGI's handle subroutine
sub handle ($$) {
    my $self = shift->new;
    my $birthday = shift;
    
    my ($r1, $r2);
    my $fcgirq = $self->{_fcgirq};
    
    ## If fastcgi changed on disk, die
    ## Apache will restart the process
    while (($r1 = $fcgirq->Accept()) >= 0) {	

	$r2 = $self->SOAP::Transport::HTTP::CGI::handle;

	if ((stat($ENV{'SCRIPT_FILENAME'}))[9] > $birthday ) {
	    exit(0);
	}
	#print "Set-Cookie: sympa_altemails=olivier.salaun%40cru.fr; path=/; expires=Tue , 19-Oct-2004 14 :08:19 GMT\n";
    }
    return undef;
}
