package SOAP::Transport::HTTP::FCGI::Sympa;

use strict;
use vars qw(@ISA);

use SOAP::Transport::HTTP;
@ISA = qw(SOAP::Transport::HTTP::FCGI);

1;

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

    }
    return undef;
}
