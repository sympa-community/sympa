# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
# Copyright 2018 The Sympa Community. See the AUTHORS.md file at the
# top-level directory of this distribution and at
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

package Sympa::Spindle::ToDigest;

use strict;
use warnings;

use Sympa::Spool::Digest;
use Sympa::Tools::Data;

use base qw(Sympa::Spindle);

# Old name: (part of) Sympa::List::distribute_msg().
sub _twist {
    my $self    = shift;
    my $message = shift;

    my $list = $message->{context};

    # Store message into digest spool if list accept digest mode.
    # Note that encrypted message can't be included in digest.
    if ($list->is_digest()
        and not Sympa::Tools::Data::smart_eq(
            $message->{'smime_crypted'},
            'smime_crypted'
        )
    ) {
        my $spool_digest = Sympa::Spool::Digest->new(context => $list);
        $spool_digest->store($message) if $spool_digest;
    }

    1;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Spindle::ToDigest - Process to store messages into digest spool

=head1 DESCRIPTION

If the list is configured to perform digest delivery, this class stores it
into digest spool (F<SPOOLDIR/digest/list@domain>).

However, ecrypted messages will be ignored.

=head1 SEE ALSO

L<Sympa::Internals::Workflow>.

L<Sympa::Message>,
L<Sympa::Spindle>, L<Sympa::Spindle::DistributeMessage>,
L<Sympa::Spool::Digest>.

=head1 HISTORY

L<Sympa::Spindle::ToDigest> appeared on Sympa 6.2.13.

=cut
