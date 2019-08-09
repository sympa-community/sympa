# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright 2019 The Sympa Community. See the AUTHORS.md file at
# the top-level directory of this distribution and at
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

package Sympa::Spindle::ToListmaster;

use strict;
use warnings;

use Sympa::Spool::Listmaster;

use base qw(Sympa::Spindle);

sub _twist {
    my $self    = shift;
    my $message = shift;

    return Sympa::Spool::Listmaster->instance->store($message,
        $message->{rcpt}, operation => $self->{data}{type}) ? 1 : undef;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Spindle::ToListmaster -
Process to store messages into spool on memory for listmaster notification

=head1 DESCRIPTION

TBD.

=head1 SEE ALSO

L<Sympa::Message>,
L<Sympa::Spindle>, L<Sympa::Spindle::ProcessTemplate>,
L<Sympa::Spool::Listmaster>.

=head1 HISTORY

L<Sympa::Spindle::ToAlarm> appeared on Sympa 6.2.13.
It was renamed to L<Sympa::Spindle::ToListmaster> on Sympa 6.2.45b.3.

=cut
