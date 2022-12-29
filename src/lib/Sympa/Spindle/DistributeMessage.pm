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

package Sympa::Spindle::DistributeMessage;

use strict;
use warnings;

use base qw(Sympa::Spindle);

# prepares and distributes a message to a list, do
# some of these :
# stats, hidding sender, adding custom subject,
# archive, changing the replyto, removing headers,
# adding headers, storing message in digest
sub _twist {
    return [
        'Sympa::Spindle::TransformIncoming', 'Sympa::Spindle::ToArchive',
        'Sympa::Spindle::TransformOutgoing', 'Sympa::Spindle::ToDigest',
        'Sympa::Spindle::ToList'
    ];
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Spindle::DistributeMessage -
Workflow to distribute messages to list members

=head1 DESCRIPTION

L<Sympa::Spindle::DistributeMessage> distributes incoming messages to list
members.

This class represents the series of following processes:

=over

=item L<Sympa::Spindle::TransformIncoming>

Process to transform messages - first stage

=item L<Sympa::Spindle::ToArchive>

Process to store messages into archiving spool

=item L<Sympa::Spindle::TransformOutgoing>

Process to transform messages - second stage

=item L<Sympa::Spindle::ToDigest>

Process to store messages into digest spool

=item L<Sympa::Spindle::ToList>

Process to distribute messages to list members

=back

=head2 Public methods

See also L<Sympa::Spindle/"Public methods">.

=over

=item new ( key =E<gt> value, ... )

In most cases, L<Sympa::Spindle::DoMessage>
splices messages to this class.  This method is not used in ordinal case.

=item spin ( )

Not implemented.

=back

=head1 SEE ALSO

L<Sympa::Spindle>, L<Sympa::Spindle::DoMessage>,
L<Sympa::Spindle::ProcessModeration>.

=head1 HISTORY

L<Sympa::Spindle::DistributeMessage> appeared on Sympa 6.2.13.

=cut
