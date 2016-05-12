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

package Sympa::Spool::Reserved;

use strict;
use warnings;

use Conf;

use base qw(Sympa::Spool::Auth);  # Sharing most of interface with Auth spool.

sub _directories {
    return {
        directory     => $Conf::Conf{'queuesubscribe'},
        bad_directory => $Conf::Conf{'queuesubscribe'} . '/bad',
    };
}

use constant _marshal_format => '%ld,%s@%s_reserved,%s,%s';
use constant _marshal_keys   => [qw(date localpart domainpart email action)];
use constant _marshal_regexp =>
    qr{\A(\d+),([^\s\@]+)\@([-.\w]+)_reserved,([^\s,]*),(\w+)\z};
use constant _store_key => undef;

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Spool::Reserved - Spool for reserved requests waiting for processing

=head1 SYNOPSIS

  use Sympa::Spool::Reserved;

  my $spool = Sympa::Spool::Reserved->new;
  my $request = Sympa::Request->new(...);
  $spool->store($request);

  my $spool = Sympa::Spool::Reserved->new(
      context => $list, action => 'close_list');
  my ($request, $handle) = $spool->next;

  $spool->remove($handle);

=head1 DESCRIPTION

L<Sympa::Spool::Reserved> implements the spool for reserved requests waiting
for processing.

=head2 Methods

See also L<Sympa::Spool/"Public methods">.

=over

=item new ( [ context =E<gt> $list ], [ action =E<gt> $action ],
[ email =E<gt> $email ])

=item next ( [ no_lock =E<gt> 1 ] )

If the pairs describing metadatas are specified,
contents returned by next() are filtered by them.

Order of items returned by next() is controled by time of submission.

=back

=head2 Context and metadata

See also L<Sympa::Spool/"Marshaling and unmarshaling metadata">.

This class particularly gives following metadata:

=over

=item {action}

Action requested.
C<'add'> etc.

=item {date}

Unix time when the request was submitted.

=item {email}

E-mail of user who submitted the request, or target e-mail of the request.

=back

=head1 CONFIGURATION PARAMETERS

Following site configuration parameters in sympa.conf will be referred.

=over

=item queuesubscribe

Directory path of held request spool.

Note:
Named such by historical reason.

Note:
Physical spool directory is shared with L<Sympa::Spool::Auth>.

=back

=head1 SEE ALSO

L<sympa_msg(8)>, L<wwsympa(8)>,
L<Sympa::Request>, L<Sympa::Spool>.

=head1 HISTORY

L<Sympa::Spool::Reserved> appeared on Sympa 6.2.15.

=cut
