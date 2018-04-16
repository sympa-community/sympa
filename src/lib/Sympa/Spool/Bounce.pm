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

package Sympa::Spool::Bounce;

use strict;
use warnings;

use Conf;

use base qw(Sympa::Spool::Incoming);

sub _directories {
    return {
        directory     => $Conf::Conf{'queuebounce'},
        bad_directory => $Conf::Conf{'queuebounce'} . '/bad',
    };
}

use constant _filter => 1;
use constant _init   => 1;

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Spool::Bounce - Spool for incoming bounce messages

=head1 SYNOPSIS

  use Sympa::Spool::Bounce;
  my $spool = Sympa::Spool::Bounce->new;
  
  my ($message, $handle) = $spool->next;

=head1 DESCRIPTION

L<Sympa::Spool::Bounce> implements the spool for incoming bounce messages.

=head2 Methods

See also L<Sympa::Spool/"Public methods">.

=over

=item next ( )

Order is controlled by modification time of files and delivery date.

=item store ( $message, [ original =E<gt> $original ] )

In most cases, bouncequeue(8) program stores messages to bounce spool.
This method is not used in ordinal case.

=back

=head2 Context and metadata

See also L<Sympa::Spool/"Marshaling and unmarshaling metadata">.

This class particularly gives following metadata:

=over

=item {date}

Unix time when the message would be delivered.

=back

=head1 CONFIGURATION PARAMETERS

Following site configuration parameters in sympa.conf will be referred.

=over

=item queuebounce

Directory path of bounce spool.

=back

=head1 SEE ALSO

L<bounced(8)>, L<Sympa::Message>, L<Sympa::Spool>, L<Sympa::Tracking>.

=head1 HISTORY

L<Sympa::Spool::Bounce> appeared on Sympa 6.2.6.

=cut
