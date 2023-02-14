# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$
#
# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
# Copyright 2017 The Sympa Community. See the AUTHORS.md file at the top-level
# directory of this distribution and at
# <https://github.com/sympa-community/sympa.git>.
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
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

package Sympa::WWW::SOAP::FastCGI;

use strict;
use warnings;
use English qw(-no_match_vars);
use SOAP::Transport::HTTP;

use Sympa::Log;
use Sympa::WWW::Session;
use Sympa::WWW::Tools;

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
        $ENV{SYMPA_DOMAIN} =
            Sympa::WWW::Tools::get_robot('soap_url_local', 'soap_url');

        my $session;
        ## Existing session or new one
        if (Sympa::WWW::Session::get_session_cookie($ENV{'HTTP_COOKIE'})) {
            $session = Sympa::WWW::Session->new(
                $ENV{SYMPA_DOMAIN},
                {   'cookie' => Sympa::WWW::Session::get_session_cookie(
                        $ENV{'HTTP_COOKIE'}
                    )
                }
            );
        } else {
            $session = Sympa::WWW::Session->new($ENV{SYMPA_DOMAIN}, {});
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
                Sympa::WWW::Session::soap_cookie2($ENV{'SESSION_ID'},
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

package Sympa::WWW::SOAP::Data;

use Encode qw();
use SOAP::Lite;

# 'base' pragma doesn't work here
our @ISA = qw(SOAP::Data);

sub type {
    my $self = shift;
    if (@_) {
        my ($type, @value) = @_;

        if ($type eq 'string') {
            return $self->SUPER::type($type,
                map { Encode::is_utf8($_) ? $_ : Encode::decode_utf8($_) }
                    @value);
        }
    }

    return $self->SUPER::type(@_);
}

sub value {
    my $self = shift;

    if (($self->type // '') eq 'string') {
        return $self->SUPER::value(
            map { Encode::is_utf8($_) ? $_ : Encode::decode_utf8($_) } @_);
    }

    return $self->SUPER::value(@_);
}

1;
__END__

