# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id: TransformOutgoing.pm 12579 2015-12-10 08:21:40Z sikeda $

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

package Sympa::Spindle::TransformDigestFinal;

use strict;
use warnings;

use Sympa::Robot;

use base qw(Sympa::Spindle);

sub _twist {
    my $self    = shift;
    my $message = shift;

    my $list = $message->{context};

    $list->add_list_header($message, 'id');
    # Add RFC 2369 header fields
    foreach my $field (
        @{  Sympa::Robot::list_params($list->{'domain'})
                ->{'rfc2369_header_fields'}->{'format'}
        }
    ) {
        if (scalar grep { $_ eq $field }
            @{$list->{'admin'}{'rfc2369_header_fields'}}) {
            $list->add_list_header($message, $field);
        }
    }

    1;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Spindle::TransformDigestFinal -
Process to transform digest messages - final stage

=head1 DESCRIPTION

L<Sympa::Spindle::TransformDigestFinal> decorates messages bound for list
members with C<digest>, C<digestplain> or C<summary> reception mode.

This class represents the series of following processes:

=over

=item *

Adding RFC 2919 C<List-Id:> header field.

=item *

Adding RFC 2369 mailing list header fields.

=back

=head1 SEE ALSO

L<Sympa::Message>,
L<Sympa::Spindle>,
L<Sympa::Spindle::ProcessDigest>.

=head1 HISTORY

L<Sympa::Spindle::TransformDigestFinal> appeared on Sympa 6.2.13.

=cut
