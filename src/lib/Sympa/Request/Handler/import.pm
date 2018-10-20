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

package Sympa::Request::Handler::import;

use strict;
use warnings;
use Time::HiRes qw();

use Conf;
use Sympa::Log;
use Sympa::Spindle::ProcessRequest;

use base qw(Sympa::Request::Handler);

my $log = Sympa::Log->instance;

use constant _action_scenario => undef;
use constant _context_class   => 'Sympa::List';

sub _twist {
    my $self    = shift;
    my $request = shift;

    my $list   = $request->{context};
    my $sender = $request->{sender};

    unless ($request->{force}) {
        # If a list is not 'open' and allow_subscribe_if_pending has been set
        # to 'off' returns undef.
        unless (
            $list->{'admin'}{'status'} eq 'open'
            or Conf::get_robot_conf($list->{'domain'},
                'allow_subscribe_if_pending') eq 'on'
        ) {
            $self->add_stash($request, 'user', 'list_not_open',
                {'status' => $list->{'admin'}{'status'}});
            $log->syslog('info', 'List %s not open', $list);
            return undef;
        }
    }

    my @users = map {
        my ($email, $gecos) = m{\A\s*(\S+)(?:\s+(.*))?\s*\z};

        (defined $gecos and $gecos =~ /\S/)
            ? {email => $email, gecos => $gecos}
            : {email => $email}
    } grep {
        /\S/ and !/\A\s*#/
    } split /\r\n|\r|\n/, ($request->{dump} || '');

    my $processed = 0;
    foreach my $user (@users) {
        my $spindle = Sympa::Spindle::ProcessRequest->new(
            context          => $list,
            action           => 'add',
            email            => $user->{email},
            gecos            => $user->{gecos},
            quiet            => $request->{quiet},
            force            => $request->{force},
            sender           => $sender,
            md5_check        => $request->{md5_check},
            scenario_context => {
                %{$self->{scenario_context} || {}},
                sender => $sender,
                email  => $user->{email},
            },
            stash => $self->{stash},
        );
        $spindle and $processed += $spindle->spin;

        last
            if grep {
            $_->[1] eq 'intern'
                or $_->[1] eq 'user' and ($_->[2] eq 'list_not_open'
                or $_->[2] eq 'max_list_members_exceeded')
            } @{$self->{stash} || []};
    }
    unless ($processed) {    # No message
        $log->syslog('info', 'Import %s from %s failed, no e-mails to add',
            $list, $sender);
        $self->add_stash($request, 'user', 'no_email');
        return undef;
    }

    $log->syslog(
        'info', 'Import %s from %s finished (%.2f seconds)',
        $list, $sender, Time::HiRes::time() - $self->{start_time},
    );
    return 1;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Request::Handler::import - import request handler

=head1 DESCRIPTION

Add subscribers to the list.
E-mails and display names of subscribers are taken from {dump} parameter,
the text including lines describing users to be added.

=head2 Attributes

=over

=item {dump}

I<Mandatory>.
Text including information of users to be added.

=item {force}

I<Optional>.
If true value is specified,
users will be added even if the list is closed.

=back

=head1 SEE ALSO

L<Sympa::Request::Handler>, L<Sympa::Request::Handler::add>.

=head1 HISTORY

L<Sympa::Request::Handler::import> appeared on Sympa 6.2.19b.

=cut
