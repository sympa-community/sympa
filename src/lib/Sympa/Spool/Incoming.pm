# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015 GIP RENATER
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
use English qw(-no_match_vars);

use Conf;
use Sympa::Constants;
use Sympa::LockedFile;
use Sympa::Log;
use Sympa::Message;
use Sympa::Spool;
use Sympa::Tools::File;

my $log = Sympa::Log->instance;

sub new {
    my $class = shift;

    my $self = bless {
        directory         => $Conf::Conf{'queue'},
        bad_directory     => $Conf::Conf{'queue'} . '/bad',
        _metadatas        => undef,
        _highest_priority => 'z',
    } => $class;

    $self->_create_spool;

    return $self;
}

sub _create_spool {
    my $self = shift;

    my $umask = umask oct $Conf::Conf{'umask'};
    foreach my $directory ($self->{directory}, $self->{bad_directory}) {
        unless (-d $directory) {
            $log->syslog('info', 'Creating spool %s', $directory);
            unless (
                mkdir($directory, 0775)
                and Sympa::Tools::File::set_file_rights(
                    file  => $directory,
                    user  => Sympa::Constants::USER(),
                    group => Sympa::Constants::GROUP()
                )
                ) {
                die sprintf 'Cannot create %s: %s', $directory, $ERRNO;
            }
        }
    }
    umask $umask;
}

sub next {
    my $self = shift;

    return unless $self->{directory};

    unless ($self->{_metadatas}) {
        my $dh;
        unless (opendir $dh, $self->{directory}) {
            die sprintf 'Cannot open dir %s: %s', $self->{directory}, $ERRNO;
        }
        $self->{_metadatas} = [
            sort grep {
                        !/,lock/
                    and !m{(?:\A|/)(?:\.|T\.|BAD-)}
                    and -f ($self->{directory} . '/' . $_)
                } readdir $dh
        ];
        closedir $dh;

        # Sort specific to this spool.
        my %mtime =
            map {
            (   $_ => Sympa::Tools::File::get_mtime(
                    $self->{directory} . '/' . $_
                )
                )
            } @{$self->{_metadatas}};
        $self->{_metadatas} =
            [sort { $mtime{$a} <=> $mtime{$b} } @{$self->{_metadatas}}];
    }
    unless (@{$self->{_metadatas}}) {
        undef $self->{_metadatas};
        # Specific to this spool.
        $self->{_highest_priority} = 'z';
        return;
    }

    while (my $marshalled = shift @{$self->{_metadatas}}) {
        my ($lock_fh, $metadata, $message);

        # Try locking message.  Those locked or removed by other process will
        # be skipped.
        $lock_fh =
            Sympa::LockedFile->new($self->{directory} . '/' . $marshalled,
            -1, '+<');
        next unless $lock_fh;

        $metadata = Sympa::Spool::unmarshal_metadata(
            $self->{directory},
            $marshalled,
            qr{\A([^\s\@]+)(?:\@([\w\.\-]+))?\.(\d+)\.(\w+)(?:,.*)?\z},
            [qw(localpart domainpart date pid rand)]
        );

        # Filter specific to this spool.
        # - z and Z are a null priority, so file stay in queue and are
        #   processed only if renamed by administrator
        next if $metadata and lc($metadata->{priority} || '') eq 'z';
        # - Lazily seek highest priority: Messages with lower priority than
        #   those already found are skipped.
        if (length($metadata->{priority} || '')) {
            next if $self->{_highest_priority} lt $metadata->{priority};
            $self->{_highest_priority} = $metadata->{priority};
        }

        if ($metadata) {
            my $msg_string = do { local $RS; <$lock_fh> };
            $message = Sympa::Message->new($msg_string, %$metadata);
        }

        # Though message might not be deserialized, anyway return the result.
        return ($message, $lock_fh);
    }
    return;
}

sub quarantine {
    my $self    = shift;
    my $lock_fh = shift;

    my $bad_file;

    $bad_file = $self->{'bad_directory'} . '/' . $lock_fh->basename;
    unless (-d $self->{bad_directory} and $lock_fh->rename($bad_file)) {
        $bad_file = $self->{directory} . '/BAD-' . $lock_fh->basename;
        return undef unless $lock_fh->rename($bad_file);
    }

    return 1;
}

sub remove {
    my $self    = shift;
    my $lock_fh = shift;

    return $lock_fh->unlink;
}

sub store {
    my $self    = shift;
    my $message = shift->dup;
    my %options = @_;

    $message->{date} = time unless defined $message->{date};

    my $marshalled =
        Sympa::Spool::store_spool($self->{directory}, $message,
        '%s@%s.%ld.%ld,%d', [qw(localpart domainpart date PID RAND)],
        %options);
    return unless $marshalled;

    $log->syslog('notice', 'Message %s is stored into archive spool as <%s>',
        $message, $marshalled);
    return $marshalled;
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

Note:
In most cases, queue(8) program stores messages to incoming spool.

=head2 Methods

=over

=item new ( )

I<Constructor>.
Creates new instance of L<Sympa::Spool::Incoming>.

=item next ( )

I<Instance method>.
Gets next message to process, order is controled by delivery date, then
messages with possiblly higher priority are chosen.
Message will be locked to prevent multiple proccessing of a single message.

Parameters:

None.

Returns:

Two-elements list of L<Sympa::Message> instance and filehandle locking
a message.

=item quarantine ( $handle )

I<Instance method>.
Quarantines a message.
Message will be moved into bad/ subdirectory of the spool.

Parameter:

=over

=item $handle

Filehandle, L<Sympa::LockedFile> instance, locking message.

=back

Returns:

True value if message could be quarantined.
Otherwise false value.

=item remove ( $handle )

I<Instance method>.
Removes a message.

Parameter:

=over

=item $handle

Filehandle, L<Sympa::LockedFile> instance, locking message.

=back

Returns:

True value if message could be removed.
Otherwise false value.

=item store ( $message, [ original =E<gt> $original ] )

I<Instance method>.
Stores the message into spool.

Parameters:

=over

=item $message

Message to be stored.  Following attributes and metadata are referred:

=over

=item {date}

Unix time when the message would be delivered.

=back

=item original =E<gt> $original

If the message was decrypted, stores original encrypted form.

=back

Returns:

If storing succeeded, marshalled metadata (file name) of the message.
Otherwise C<undef>.

=back

=head1 SEE ALSO

L<sympa_msg(8)>, L<Sympa::Message>.

=head1 HISTORY

L<Sympa::Spool::Incoming> appeared on Sympa 6.2.5.

=cut
