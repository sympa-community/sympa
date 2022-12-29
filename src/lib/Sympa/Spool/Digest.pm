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

package Sympa::Spool::Digest;

use strict;
use warnings;

use Conf;

use base qw(Sympa::Spool);

sub new {
    my $class   = shift;
    my %options = @_;

    return undef unless ref $options{context} eq 'Sympa::List';
    $class->SUPER::new(%options);
}

sub _directories {
    my $self    = shift;
    my %options = @_;

    my $list = ref($self) ? $self->{context} : $options{context};
    die 'bug in logic.  Ask developer' unless ref $list eq 'Sympa::List';

    return {
        parent_directory => $Conf::Conf{'queuedigest'},
        directory        => $list->get_digest_spool_dir,
        bad_directory    => $list->get_digest_spool_dir . '/bad',
    };
}

use constant _generator => 'Sympa::Message';

sub _init {
    my $self   = shift;
    my $status = shift;

    unless ($status) {
        # Get earliest time of messages in the spool.
        my $metadatas = $self->_load || [];
        my $metadata;
        while (my $marshalled = shift @$metadatas) {
            $metadata = $self->unmarshal($marshalled);
            last if $metadata;
        }
        $self->{time} = $metadata ? $metadata->{time} : undef;
        $self->{_metadatas} = undef;    # Rewind cache.
    }
    return 1;
}

use constant _marshal_format => '%ld.%f,%ld,%d';
use constant _marshal_keys   => [qw(date TIME PID RAND)];
use constant _marshal_regexp => qr{\A(\d+)\.(\d+\.\d+)(?:,.*)?\z};

use constant _no_glob_pattern => 1;

sub next {
    my $self = shift;

    my ($message, $handle) = $self->SUPER::next();
    if ($message) {
        # Assign context which is not given by metadata.
        $message->{context} = $self->{context};
    }
    return ($message, $handle);
}

# Old name: Sympa::List::store_digest().
sub store {
    my $self    = shift;
    my $message = shift->dup;

    # Delete original message ID because it can be anonymized.
    delete $message->{message_id};

    return $self->SUPER::store($message);
}

sub get_id {
    my $self = shift;

    if ($self->{context}) {
        if (ref $self->{context} eq 'Sympa::List') {
            return $self->{context}->get_id;
        } else {
            return $self->{context};
        }
    } else {
        return '';
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Spool::Digest - Spool for messages waiting for digest sending

=head1 SYNOPSIS

  use Sympa::Spool::Digest;
  my $spool = Sympa::Spool::Digest->new(context => $list);
  
  $spool->store($message);
  
  my ($message, $handle) = $spool->next;

=head1 DESCRIPTION

L<Sympa::Spool::Digest> implements the spool for messages waiting for
digest sending.

=head2 Methods

See also L<Sympa::Spool/"Public methods">.

=over

=item new ( context =E<gt> $list )

Creates new instance of L<Sympa::Spool::Digest> related to the list $list.

=item next ( )

Order is controlled by delivery date, then by reception date.

=back

=head2 Properties

See also L<Sympa::Spool/"Properties">.

=over

=item {time}

Earliest time of messages in the spool, or C<undef>.

=back

=head2 Context and metadata

See also L<Sympa::Spool/"Marshaling and unmarshaling metadata">.

This class particularly gives following metadata:

=over

=item {date}

Unix time when the message was delivered.

=item {time}

Unix time in floating point number when the message was stored.

=back

=head1 CONFIGURATION PARAMETERS

Following site configuration parameters in sympa.conf will be referred.

=over

=item queuedigest

Parent directory path of digest spools.

=back

=head1 SEE ALSO

L<sympa_msg(8)>,
L<Sympa::Message>, L<Sympa::Spool>, L<Sympa::Spool::Digest::Collection>.

=head1 HISTORY

L<Sympa::Spool::Digest> appeared on Sympa 6.2.6.

=cut
