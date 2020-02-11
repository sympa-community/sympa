# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright 2020 The Sympa Community. See the AUTHORS.md
# file at the top-level directory of this distribution and at
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

package Sympa::Request::Handler::family_signoff;

use strict;
use warnings;

use Sympa::Language;
use Sympa::Log;

use base qw(Sympa::Request::Handler);

my $language = Sympa::Language->instance;
my $log      = Sympa::Log->instance;

use constant _action_regexp   => qr'reject|request_auth|do_it'i;
use constant _action_scenario => 'family_signoff';
use constant _context_class   => 'Sympa::Family';

sub _twist {
    my $self    = shift;
    my $request = shift;

    my $family = $request->{context};
    my $sender = $request->{sender};
    my $email  = $request->{email};

    unless ($email eq $sender) {
        $self->add_stash($request, 'user', 'user_not_subscriber');
        $log->syslog('err',
            'User %s tried to unsubscribe address %s from family %s',
            $sender, $email, $family);
        return undef;
    }

    unless ($family->insert_delete_exclusion($email, 'insert')) {
        $self->add_stash($request, 'user', 'cannot_do_signoff');
        $log->syslog('err',
            'Unsubscription of address %s from family %s failed',
            $email, $family);
        return undef;
    }
    return 1;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Request::Handler::family_signoff - family 'signoff' request handler

=head1 DESCRIPTION

Unsubscribes from all the lists belonging to specified family.

=head1 SEE ALSO

L<Sympa::Request::Handler>.

=head1 HISTORY

L<Sympa::Request::Handler::family_signoff> appeared on Sympa 6.2.53b.

=cut
