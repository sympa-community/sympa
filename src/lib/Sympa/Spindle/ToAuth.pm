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

package Sympa::Spindle::ToAuth;

use strict;
use warnings;
use Time::HiRes qw();

use Sympa;
use Sympa::Log;
use Sympa::Spool::Auth;

use base qw(Sympa::Spindle);

my $log = Sympa::Log->instance;

sub _twist {
    my $self    = shift;
    my $request = shift;

    my $that   = $request->{context} || '*';
    my $sender = $request->{sender};
    my $to     = $request->{sender_to_confirm} || $sender;

    $log->syslog('debug2', 'Auth requested from %s', $sender);

    my $spool_req = Sympa::Spool::Auth->new;
    my $keyauth;
    unless ($keyauth = $spool_req->store($request)) {
        $self->add_stash($request, 'intern');
        return undef;
    }

    # Send notice to the user.
    my $cmd_line = $request->cmd_line(canonic => 1);
    unless (
        Sympa::send_file(
            $that,
            'request_auth',
            $to,
            {   cmd => $cmd_line,
                # Compat. <= 6.2.14.
                command        => sprintf('AUTH %s %s', $keyauth, $cmd_line),
                keyauth        => $keyauth,
                type           => $request->{action},
                to             => $to,
                auto_submitted => 'auto-replied',
            }
        )
    ) {
        my $error = sprintf
            'Unable to request authentication for command "%s"',
            $request->{action};
        Sympa::send_notify_to_listmaster(
            $that,
            'mail_intern_error',
            {   error  => $error,
                who    => $sender,
                action => 'Command process',
            }
        );
        $self->add_stash($request, 'intern');
        return undef;
    }

    $self->add_stash($request, 'notice', 'sent_to_user', {email => $to})
        unless $request->{quiet};

    $log->syslog(
        'info',
        '%s for %s from %s, auth requested (%.2f seconds)',
        uc $request->{action},
        $request->{context},
        $sender,
        Time::HiRes::time() - $self->{start_time}
    );
    return 1;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Spindle::ToAuth -
Process to store requests into request spool to wait for moderation

=head1 DESCRIPTION

TBD.

=head1 SEE ALSO

L<Sympa::Request>,
L<Sympa::Spindle>, L<Sympa::Spindle::AuthorizeRequest>,
L<Sympa::Spool::Auth>.

=head1 HISTORY

L<Sympa::Spindle::ToAuth> appeared on Sympa 6.2.13.

=cut
