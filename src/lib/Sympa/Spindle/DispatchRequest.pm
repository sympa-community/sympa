# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
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

package Sympa::Spindle::DispatchRequest;

use strict;
use warnings;

use Sympa;
use Sympa::Log;

use base qw(Sympa::Spindle);

my $log = Sympa::Log->instance;

# Use {start_time} attribute of spindle.
#my $time_command;

# Moved to: Sympa::Request::Message::_parse().
#sub parse;

# Old name: (part of) Sympa::Commands::parse().
sub _twist {
    my $self    = shift;
    my $request = shift;

    # Check if required context (known list or robot) is given.
    if (defined $request->handler->context_class
        and $request->handler->context_class ne ref $request->{context}) {
        $request->{error} = 'unknown_list';
    }

    return _error($self, $request)
        if $request->{error};
    return [$request->handler];
}

# Pseudo-request to report error.
sub _error {
    my $self    = shift;
    my $request = shift;

    my $entry = $request->{error};

    if ($entry eq 'syntax_errors') {
        $self->add_stash($request, 'user', 'syntax_errors');
        $log->syslog('notice', 'Command syntax error');
    } elsif ($entry eq 'unknown_list') {
        $self->add_stash($request, 'user', 'unknown_list');
        $log->syslog(
            'info',
            '%s from %s refused, unknown list for robot %s',
            uc $request->{action},
            $request->{sender}, $request->{context}
        );
    } else {
        Sympa::send_notify_to_listmaster(
            $request->{context},
            'mail_intern_error',
            {   error  => $entry,
                who    => $request->{sender},
                action => 'Command process',
            }
        );
        $self->add_stash($request, 'intern');
        $log->syslog('err', 'Unknown error: %s', $entry);
        return undef;
    }
    return undef;
}

# Old name: Sympa::Commands::get_auth_method().
# Moved to: Sympa::Spindle::AuthorizeRequest::_get_auth_method().
#sub get_auth_method;

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Spindle::DispatchRequest -
Workflow to dispatch requests

=head1 DESCRIPTION

L<Sympa::Spindle::DispatchRequest> dispatches requests, in most cases
included in command messages.

Requests are dispatched to routines to perform abstract processing.

=head2 Public methods

See also L<Sympa::Spindle/"Public methods">.

=over

=item new ( key =E<gt> value, ... )

In most cases, L<Sympa::Spindle::ProcessMessage>
splices requests to this class.  This method is not used in ordinal case.

=item spin ( )

Not implemented.

=back

=head1 SEE ALSO

L<Sympa::Spindle>, L<Sympa::Spindle::ProcessMessage>,
L<Sympa::Spindle::ProcessRequest>.

=head1 HISTORY

L<Sympa::Spindle::DispatchRequest> appeared on Sympa 6.2.13.

=cut
