# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
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

package Sympa::Request::Handler::decl;

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
        keyauth     => $key,
        canceled_by => $sender,

        scenario_context => $self->{scenario_context},
        stash            => $self->{stash},
    );

    unless ($spindle and $spindle->spin) {
        $log->syslog('info', 'Declining %s from %s refused, decl failed',
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

Sympa::Request::Handler::decl - decl request handler

=head1 DESCRIPTION

Fetches the request matching with {authkey} and optional {request} attributes
from held request spool,
and if succeeded, remove it from the spool.

=head1 CAVEAT

Decl request handler itself never check privileges:
It trust in senders if valid authorization key is specified.
Access to this handler should be restricted sufficiently by applications.

=head1 SEE ALSO

L<Sympa::Request::Handler>,
L<Sympa::Request::Handler::auth>,
L<Sympa::Spindle::ProcessAuth>.

=head1 HISTORY

L<Sympa::Request::Handler::decl> appeared on Sympa 6.2.19b.

=cut
