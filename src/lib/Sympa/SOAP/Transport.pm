# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# This file is part of Sympa, see top-level README.md file for details

package Sympa::SOAP::Transport;

use strict;
use warnings;
use English qw(-no_match_vars);
use SOAP::Transport::HTTP;

use Sympa::Log;
use Sympa::Session;
use Sympa::Tools::WWW;

# 'base' pragma doesn't work here
our @ISA = qw(SOAP::Transport::HTTP::FCGI);

my $log = Sympa::Log->instance;

sub new {
    my $class = shift;
    return $class if ref $class;
    my %options = @_;

    my $self = $class->SUPER::new();
    $self->{_ss_birthday} = [stat $PROGRAM_NAME]->[9] if $PROGRAM_NAME;
    $self->{_ss_cookie_expire} = $options{cookie_expire} || 0;

    $self;
}

sub request {
    my $self = shift;

    if (my $request = $_[0]) {
        # Select appropriate robot.
        $ENV{'SYMPA_ROBOT'} =
            Sympa::Tools::WWW::get_robot('soap_url_local', 'soap_url');

        ## Empty cache of the List.pm module
        Sympa::List::init_list_cache();

        my $session;
        ## Existing session or new one
        if (Sympa::Session::get_session_cookie($ENV{'HTTP_COOKIE'})) {
            $session = Sympa::Session->new(
                $ENV{'SYMPA_ROBOT'},
                {   'cookie' => Sympa::Session::get_session_cookie(
                        $ENV{'HTTP_COOKIE'}
                    )
                }
            );
        } else {
            $session = Sympa::Session->new($ENV{'SYMPA_ROBOT'}, {});
            $session->store() if (defined $session);
            ## Note that id_session changes each time it is saved in the DB
            $session->renew()
                if (defined $session);
        }

        delete $ENV{'USER_EMAIL'};
        if (defined $session) {
            $ENV{'SESSION_ID'} = $session->{'id_session'};
            if ($session->{'email'} ne 'nobody') {
                $ENV{'USER_EMAIL'} = $session->{'email'};
            }
        }
    }

    $self->SUPER::request(@_);
}

sub response {
    my $self = shift;

    if (my $response = $_[0]) {
        if (defined $ENV{'SESSION_ID'}) {
            my $cookie =
                Sympa::Session::soap_cookie2($ENV{'SESSION_ID'},
                $ENV{'SERVER_NAME'}, $self->{_ss_cookie_expire});
            $response->headers->push_header('Set-Cookie2' => $cookie);
        }
    }

    $self->SUPER::request(@_);
}

## Redefine FCGI's handle subroutine
sub handle {
    my $self = shift->new;

    my ($r1, $r2);
    my $fcgirq = $self->{_fcgirq};

    while (($r1 = $fcgirq->Accept()) >= 0) {

        $r2 = $self->SOAP::Transport::HTTP::CGI::handle;

        # Exit if script itself has changed.
        my $birthday = $self->{_ss_birthday};
        if (defined $birthday and $PROGRAM_NAME) {
            my $age = [stat $PROGRAM_NAME]->[9];
            if (defined $age and $birthday != $age) {
                $log->syslog(
                    'notice',
                    'Exiting because %s has changed since FastCGI server started',
                    $PROGRAM_NAME
                );
                exit(0);
            }
        }
    }
    return undef;
}

1;
