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

package Sympa::Spool::Digest::Collection;

use strict;
use warnings;

use Conf;
use Sympa::Tools::File;

use base qw(Sympa::Spool);

sub _directories {
    return {directory => $Conf::Conf{'queuedigest'},};
}

sub _filter {
    my $self     = shift;
    my $metadata = shift;

    $metadata && ref $metadata->{context} eq 'Sympa::List';
}

use constant _generator     => 'Sympa::Spool::Digest';
use constant _is_collection => 1;

sub _load {
    my $self = shift;

    my $metadatas = $self->SUPER::_load();
    my %mtime     = map {
        ($_ => Sympa::Tools::File::get_mtime($self->{directory} . '/' . $_))
    } @$metadatas;
    return [sort { $mtime{$a} <=> $mtime{$b} } @$metadatas];
}

use constant _marshal_format => '%s@%s';
use constant _marshal_keys   => [qw(localpart domainpart)];
use constant _marshal_regexp => qr{\A([^\s\@]+)(?:\@([\w\.\-]+))?\z};

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Spool::Digest::Collection - Collection of digest spools

=head1 SYNOPSIS

  use Sympa::Spool::Digest::Collection;
  
  my $collection = Sympa::Spool::Digest::Collection->new;
  my ($spool, $handle) = $collection->next;

=head1 DESCRIPTION

L<Sympa::Spool::Digest::Collection> implements the collection of
L<Sympa::Spool::Digest> instances.

=head2 Methods

See also L<Sympa::Spool/"Public methods">.

=over

=item next ( )

Returns next instance of L<Sympa::Spool::Digest>.
Order is controlled by modification times of spool directories.
Spool directory is locked to prevent processing by multiple processes.

=item quarantine ( )

Does nothing.

=item remove ( $handle )

Tries to remove directory of spool.
If succeeded, returns true value.
Otherwise returns false value.

=item store (  )

Does nothing.

=back

=head1 CONFIGURATION PARAMETERS

Following site configuration parameters in sympa.conf will be referred.

=over

=item queuedigest

Parent directory path of digest spools.

=back

=head1 SEE ALSO

L<sympa_msg(8)>, L<Sympa::Spool::Digest>.

=head1 HISTORY

L<Sympa::Spool::Digest::Collection> appeared on Sympa 6.2.6.

=cut
