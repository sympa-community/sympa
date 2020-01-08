# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
# Copyright 2017, 2018, 2019 The Sympa Community. See the AUTHORS.md file at
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

package Sympa::Spindle::ToOutgoing;

use strict;
use warnings;

use Sympa::Spool::Outgoing;

use base qw(Sympa::Spindle);

sub _twist {
    my $self    = shift;
    my $message = shift;

    my $status =
        Sympa::Spool::Outgoing->new->store($message, $message->{rcpt},
        tag => $message->{tag});

    if (    $status
        and ref $message->{context} eq 'Sympa::List'
        and $self->{add_list_statistics}) {
        my $list = $message->{context};

        # Add number and size of digests sent to total in stats file.
        my $numsent = scalar @{$message->{rcpt} || []};
        my $bytes = length $message->as_string;
        $list->update_stats(0, $numsent, $bytes, $bytes * $numsent);
    }

    $status ? 1 : undef;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Spindle::ToOutgoing - Process to store messages into outgoing spool

=head1 DESCRIPTION

This class stores message into outgoing spool (SPOOLDIR/bulk).

If the message has list context and C<add_list_statistics> attribute
(the case it was spliced from L<Sympa::Spindle::ProcessDigest>),
updates statistics information of the list (with regular delivery,
L<Sympa::Spindle::ToList> will update it).

=head1 SEE ALSO

L<Sympa::Message>,
L<Sympa::Spindle>,
L<Sympa::Spool::Outgoing>.

=head1 HISTORY

L<Sympa::Spindle::ToOutgoing> appeared on Sympa 6.2.13.

=cut
