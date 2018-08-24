# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

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

package Sympa::Request::Handler::auth;

use strict;
use warnings;
use Time::HiRes qw();

use Sympa;
use Sympa::Log;
use Sympa::Spindle::ProcessAuth;

use base qw(Sympa::Request::Handler);

my $log = Sympa::Log->instance;

use constant _action_scenario => undef;

sub _twist {
    my $self    = shift;
    my $request = shift;

    my $key    = $request->{keyauth};
    my $sender = $request->{sender};

    # Optional $request->{request} is given by Sympa::Request::Message to
    # check if "cmd" argument of e-mail command matches with held request.
    my $req     = $request->{request};
    my $spindle = Sympa::Spindle::ProcessAuth->new(
        (   map { ($req and $req->{$_}) ? ($_ => $req->{$_}) : () }
                qw(context action email)
        ),
        keyauth      => $key,
        confirmed_by => $sender,

        scenario_context => $self->{scenario_context},
        stash            => $self->{stash},
    );

    unless ($spindle and $spindle->spin) {
        $log->syslog('info', 'AUTH %s from %s refused, auth failed',
            $key, $sender);
        $self->add_stash($request, 'user', 'wrong_email_confirm',
            {key => $key, command => ($req || {})->{action}});
        return undef;
    } elsif ($spindle->{finish} and $spindle->{finish} eq 'success') {
        return 1;
    } else {
        return undef;
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Request::Handler::auth - auth request handler

=head1 DESCRIPTION

Fetches the request matching with {authkey} and optional {request} attributes
from held request spool,
and if succeeded, processes it with C<md5> authentication level.

=head1 CAVEAT

Auth request handler itself never check privileges:
It trust in senders if valid authorization key is specified.
Access to this handler should be restricted sufficiently by applications.

=head1 SEE ALSO

L<Sympa::Request::Handler>,
L<Sympa::Request::Handler::decl>,
L<Sympa::Spindle::ProcessAuth>.

=head1 HISTORY

L<Sympa::Request::Handler::auth> appeared on Sympa 6.2.15.

=cut
