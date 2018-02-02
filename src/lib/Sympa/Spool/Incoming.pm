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

package Sympa::Spool::Incoming;

use strict;
use warnings;

use Conf;
use Sympa::Tools::File;

use base qw(Sympa::Spool);

sub _directories {
    return {
        directory     => $Conf::Conf{'queue'},
        bad_directory => $Conf::Conf{'queue'} . '/bad',
    };
}
use constant _generator      => 'Sympa::Message';
use constant _marshal_format => '%s@%s.%ld.%ld,%d';
use constant _marshal_keys   => [qw(localpart domainpart date PID RAND)];
use constant _marshal_regexp =>
    qr{\A([^\s\@]+)(?:\@([\w\.\-]+))?\.(\d+)\.(\w+)(?:,.*)?\z};

sub _filter {
    my $self     = shift;
    my $metadata = shift;

    return undef unless $metadata;

    # - z and Z are a null priority, so file stay in queue and are
    #   processed only if renamed by administrator
    return 0 if lc($metadata->{priority} || '') eq 'z';

    # - Lazily seek highest priority: Messages with lower priority than
    #   those already found are skipped.
    if (length($metadata->{priority} || '')) {
        return 0 if $self->{_highest_priority} lt $metadata->{priority};
        $self->{_highest_priority} = $metadata->{priority};
    }

    return 1;
}

sub _init {
    my $self = shift;

    $self->{_highest_priority} = 'z';
}

sub _load {
    my $self = shift;

    my $metadatas = $self->SUPER::_load();
    my %mtime     = map {
        ($_ => Sympa::Tools::File::get_mtime($self->{directory} . '/' . $_))
    } @$metadatas;
    return [sort { $mtime{$a} <=> $mtime{$b} } @$metadatas];
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Spool::Incoming - Spool for incoming messages

=head1 SYNOPSIS

  use Sympa::Spool::Incoming;
  my $spool = Sympa::Spool::Incoming->new;

  $spool->store($message);

  my ($message, $handle) = $spool->next;

=head1 DESCRIPTION

L<Sympa::Spool::Incoming> implements the spool for incoming messages.

=head2 Methods

See also L<Sympa::Spool/"Public methods">.

=over

=item next ( [ no_filter =E<gt> 1 ], [ no_lock =E<gt> 1 ] )

Order is controlled by modification time of file and delivery date, then,
if C<no_filter> is I<not> set,
messages with possibly higher priority are chosen and
messages with lowest priority (C<z> or C<Z>) are skipped.

=item store ( $message, [ original =E<gt> $original ] )

In most cases, queue(8) program stores messages to incoming spool.
Daemon such as sympa_automatic(8) uses this method to store messages.

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

=item queue

Directory path of incoming spool.

=back

=head1 SEE ALSO

L<sympa_automatic(8)>, L<sympa_msg(8)>, L<Sympa::Message>, L<Sympa::Spool>.

=head1 HISTORY

L<Sympa::Spool::Incoming> appeared on Sympa 6.2.5.

=cut
