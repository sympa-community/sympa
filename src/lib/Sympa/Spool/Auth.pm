# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
# Copyright 2017, 2020 The Sympa Community. See the AUTHORS.md
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

package Sympa::Spool::Auth;

use strict;
use warnings;

use Conf;
use Sympa::Tools::Text;

use base qw(Sympa::Spool);

sub _directories {
    return {directory => $Conf::Conf{'queuesubscribe'},};
}

sub _filter {
    my $self     = shift;
    my $metadata = shift;

    # Decode e-mail.
    $metadata->{email} =
        Sympa::Tools::Text::decode_filesystem_safe($metadata->{email})
        if $metadata and $metadata->{email};

    1;
}

sub _filter_pre {
    my $self     = shift;
    my $metadata = shift;

    # Encode e-mail.
    $metadata->{email} =
        Sympa::Tools::Text::encode_filesystem_safe($metadata->{email})
        if $metadata and $metadata->{email};

    1;
}

use constant _generator => 'Sympa::Request';

use constant _marshal_format => '%ld,%s@%s_%s,%s,%s';
use constant _marshal_keys =>
    [qw(date localpart domainpart KEYAUTH email action)];
use constant _marshal_regexp =>
    qr{\A(\d+),(\@?[^\s\@]+)\@([-.\w]+)_([\da-f]+),([^\s,]*),(\w+)\z};
use constant _store_key => 'keyauth';

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Spool::Auth - Spool for held requests waiting for moderation

=head1 SYNOPSIS

  use Sympa::Spool::Auth;

  my $spool = Sympa::Spool::Auth->new;
  my $request = Sympa::Request->new(...);
  $spool->store($request);

  my $spool = Sympa::Spool::Auth->new(
      context => $list, action => 'add');
  my $size = $spool->size;

  my $spool = Sympa::Spool::Auth->new(
      context => $list, keyauth => $id, action => 'add');
  my ($request, $handle) = $spool->next;

  $spool->remove($handle);

=head1 DESCRIPTION

L<Sympa::Spool::Auth> implements the spool for held requests waiting
for moderation.

=head2 Methods

See also L<Sympa::Spool/"Public methods">.

=over

=item new ( [ context =E<gt> $that ], [ action =E<gt> $action ],
[ keyauth =E<gt> $id ], [ email =E<gt> $email ])

Context may be either instance of L<Sympa::List> or L<Sympa::Family>,
or robot.

=item next ( [ no_lock =E<gt> 1 ] )

If the pairs describing metadatas are specified,
contents returned by next() are filtered by them.

Order of items returned by next() is controlled by time of submission.

=item quarantine ( )

Does nothing.

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

=item {keyauth}

Authentication key generated automatically
when the request is stored to spool.

=back

=head1 CONFIGURATION PARAMETERS

Following site configuration parameters in sympa.conf will be referred.

=over

=item queuesubscribe

Directory path of held request spool.

Note:
Named such by historical reason.

=back

=head1 SEE ALSO

L<sympa_msg(8)>, L<wwsympa(8)>,
L<Sympa::Request>, L<Sympa::Spool>.

=head1 HISTORY

L<Sympa::Spool::Request> appeared on Sympa 6.2.10.
It was renamed to L<Sympa::Spool::Auth> on Sympa 6.2.13.

=cut
