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

package Sympa::Spindle::ToArchive;

use strict;
use warnings;

use Conf;
use Sympa::Log;
use Sympa::Spool::Archive;
use Sympa::Tools::Data;

use base qw(Sympa::Spindle);

my $log = Sympa::Log->instance;

# Old name: (part of) Sympa::List::distribute_msg().
sub _twist {
    my $self    = shift;
    my $message = shift;

    my $list = $message->{context};

    # Archives
    unless ($list->is_archiving_enabled) {
        # Archiving is disabled.
    } elsif (
        !Sympa::Tools::Data::smart_eq(
            $Conf::Conf{'ignore_x_no_archive_header_feature'}, 'on')
        and (
            grep {
                /yes/i
            } $message->get_header('X-no-archive')
            or grep {
                /no\-external\-archive/i
            } $message->get_header('Restrict')
        )
    ) {
        # Ignoring message with a no-archive flag.
        $log->syslog('info',
            "Do not archive message with no-archive flag for list %s", $list);
    } else {
        my $spool = Sympa::Spool::Archive->new;
        $spool->store(
            $message,
            original => Sympa::Tools::Data::smart_eq(
                $list->{admin}{archive_crypted_msg}, 'original'
            )
        );
    }

    1;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Spindle::ToArchive - Process to store messages into archiving spool

=head1 DESCRIPTION

This class stores message into archive spool (SPOOLDIR/outgoing).
However, in any of following cases, message won't be stored:

=over

=item *

C<process_archive> list parameter is I<not> C<on>, i.e. archiving is disabled.

=item *

C<ignore_x_no_archive_header_feature> list parameter is I<not> C<on>,
and the message has any of these fields:

  X-no-archive: yes
  Restrict: no-external-archive

=back

When message was originally encrypted,
then if C<archive_crypted_msg> list parameter is I<not> C<original>, decrypted
message will be stored.  Otherwise original message will be stored.

=head1 SEE ALSO

L<Sympa::Internals::Workflow>.

L<Sympa::Message>,
L<Sympa::Spindle>, L<Sympa::Spindle::DistributeMessage>,
L<Sympa::Spool::Archive>.

=head1 HISTORY

L<Sympa::Spindle::ToArchive> appeared on Sympa 6.2.13.

=cut
