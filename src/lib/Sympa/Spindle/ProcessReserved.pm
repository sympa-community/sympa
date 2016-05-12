# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016 GIP RENATER
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

package Sympa::Spindle::ProcessReserved;

use strict;
use warnings;

use base qw(Sympa::Spindle);

use constant _distaff => 'Sympa::Spool::Reserved';

# NOTE: Sympa::Spool::Auth shares spool directory with Sympa::Spool::Reserved.
# So, unparsable items MUST NOT be removed / quarantined.
sub _on_garbage {
    my $self   = shift;
    my $handle = shift;

    # Keep broken request and skip it.
    $handle->close;
}

sub _twist {
    my $self    = shift;
    my $request = shift;

    # Assign privileges of request sender.
    $request->{md5_check} = 1;
    $self->{scenario_context} =
        {map { $request->{$_} ? ($_ => $request->{$_}) : () }
            qw(sender email remote_addr remote_host remote_application_name)};

    return ['Sympa::Spindle::AuthorizeRequest'];
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Spindle::ProcessReserved - Workflow of processing reserved request

=head1 SYNOPSIS

  use Sympa::Spindle::ProcessReserved;

  my $spindle = Sympa::Spindle::ProcessReserved->new;
  $spindle->spin;

=head1 DESCRIPTION

L<Sympa::Spindle::ProcessReserved> defines workflow for processing of reserved
requests.

When spin() method is invoked, it reads a request in held request spool,
authorizes it and dispatch it if possible.
Failed request will be quarantined.

=head2 Public methods

See also L<Sympa::Spindle/"Public methods">.

=over

=item new ( [ quiet =E<gt> 1 ] )

=item spin ( )

new() may take following options:

=over

=item quiet =E<gt> 1

If this option is set, automatic replys reporting result of processing
to the user will not be sent.

=back

=back

=head2 Properties

See also L<Sympa::Spindle/"Properties">.

=over

=item {distaff}

Instance of L<Sympa::Spool::Reserved> class.

=back

=head1 SEE ALSO

L<Sympa::Request>,
L<Sympa::Spindle>, L<Sympa::Spindle::AuthorizeRequest>,
L<Sympa::Spool::Reserved>.

=head1 HISTORY

L<Sympa::Spindle::ProcessReserved> appeared on Sympa 6.2.15.

=cut
