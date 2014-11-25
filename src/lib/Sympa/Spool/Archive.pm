# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id: Bulk.pm 11592 2014-10-26 01:38:30Z sikeda $

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014 GIP RENATER
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

package Sympa::Spool::Archive;

use strict;
use warnings;
use English qw(-no_match_vars);

use Conf;
use Sympa::Constants;
use Sympa::LockedFile;
use Log;
use Sympa::Message;
use tools;
use Sympa::Tools::File;

sub new {
    my $class = shift;

    my $self = bless {
        directory     => $Conf::Conf{'queueoutgoing'},
        bad_directory => $Conf::Conf{'queueoutgoing'} . '/bad',
        _metadatas    => undef,
    } => $class;

    $self->_create_spool;

    return $self;
}

sub _create_spool {
    my $self = shift;

    my $umask = umask oct $Conf::Conf{'umask'};
    foreach my $directory ($self->{directory}, $self->{bad_directory}) {
        unless (-d $directory) {
            Log::do_log('info', 'Creating spool %s', $directory);
            unless (
                mkdir($directory, 0755)
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

    unless ($self->{_metadatas}) {
        my $dh;
        unless (opendir $dh, $self->{directory}) {
            die sprintf 'Cannot open dir %s: %s', $self->{directory},
                $ERRNO;
        }
        $self->{_metadatas} = [
            sort grep {
                        !/,lock/
                    and !m{(?:\A|/)(?:\.|T\.|BAD-)}
                    and -f ($self->{directory} . '/' . $_)
                } readdir $dh
        ];
        closedir $dh;
    }
    unless (@{$self->{_metadatas}}) {
        undef $self->{_metadatas};
        return;
    }

    my ($lock_fh, $metadata, $message);
    while (my $marshalled = shift @{$self->{_metadatas}}) {
        # Try locking message.  Those locked or removed by other process will
        # be skipped.
        $lock_fh =
            Sympa::LockedFile->new($self->{directory} . '/' . $marshalled,
            -1, '+<');
        next unless $lock_fh;

        $metadata = tools::unmarshal_metadata(
            $self->{directory},
            $marshalled,
            qr{\A(\d+)\.(\d+\.\d+)\.([^\s\@]*)\@([\w\.\-*]*),(\d+),(\d+)},
            [qw(date time localpart domainpart pid rand)]
        );

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

    my $marshalled = tools::store_spool(
        $self->{directory},
        $message,
        '%d.%f.%s@%s,%ld,%d',
        [qw(date TIME localpart domainpart PID RAND) ],
        %options
    );
    return unless $marshalled;

    Log::do_log('notice', 'Message %s is stored into archive spool as <%s>',
        $message, $marshalled);
    return $marshalled;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Spool::Archive - Spool for messages waiting for archiving.

=head1 SYNOPSIS

TBD

=head1 DESCRIPTION

L<Sympa::Spool::Archive> implements the spool for messages waiting for
archiving.

=head2 Methods

=over

=item new ( )

I<Constructor>.
Creates new instance of L<Sympa::Spool::Archive>.

=item next ( )

I<Instance method>.
Gets next message to process, order is controled by delivery date, then by
reception date.
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

=item {sender}

Sender of the message.

=item {date}

Unix time when the message would be delivered.

=item {time}

Unix time in floating point number when the message was stored.

=back

=item original =E<gt> $original

TBD

=back

Returns:

If storing succeeded, marshalled metadata (file name) of the message.
Otherwise C<undef>.

=back

=head1 SEE ALSO

L<archived(8)>, L<Sympa::Message>.

=head1 HISTORY

L<Sympa::Spool::Archive> appeared on Sympa 6.2.0.

=cut
