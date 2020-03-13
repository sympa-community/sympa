# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright 2019, 2020 The Sympa Community. See the AUTHORS.md
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

package Sympa::Spool::Outgoing;

use strict;
use warnings;
use Cwd qw();
use English qw(-no_match_vars);
use File::Copy qw();
use Time::HiRes qw();

use Conf;
use Sympa::Constants;
use Sympa::LockedFile;
use Sympa::Log;
use Sympa::Message;
use Sympa::Spool;
use Sympa::Tools::File;

my $log = Sympa::Log->instance;

sub new {
    my $class   = shift;
    my %options = @_;

    my $self = bless {
        msg_directory     => $Conf::Conf{'queuebulk'} . '/msg',
        pct_directory     => $Conf::Conf{'queuebulk'} . '/pct',
        bad_directory     => $Conf::Conf{'queuebulk'} . '/bad',
        bad_msg_directory => $Conf::Conf{'queuebulk'} . '/bad/msg',
        bad_pct_directory => $Conf::Conf{'queuebulk'} . '/bad/pct',
        _metadatas        => undef,
    } => $class;

    $self->_create_spool;

    # Build glob pattern (for pct entries).
    $self->{_glob_pattern} = Sympa::Spool::build_glob_pattern(
        '%s.%s.%d.%f.%s@%s_%s,%ld,%d/%s',
        [   qw(priority packet_priority date time localpart domainpart tag pid rand serial)
        ],
        %options
    ) || '*/*';

    return $self;
}

sub _create_spool {
    my $self = shift;

    my $umask = umask oct $Conf::Conf{'umask'};
    foreach my $directory (
        $Conf::Conf{queuebulk},     $self->{msg_directory},
        $self->{pct_directory},     $self->{bad_directory},
        $self->{bad_msg_directory}, $self->{bad_pct_directory}
    ) {
        unless (-d $directory) {
            $log->syslog('info', 'Creating spool %s', $directory);
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
    my $self    = shift;
    my %options = @_;

    unless ($self->{_metadatas}) {
        my $cwd = Cwd::getcwd();
        unless (chdir $self->{pct_directory}) {
            die sprintf 'Cannot chdir to %s: %s', $self->{pct_directory},
                $ERRNO;
        }
        $self->{_metadatas} = [
            sort grep {
                        !/,lock/
                    and !m{(?:\A|/)(?:\.|T\.|BAD-)}
                    and -f ($self->{pct_directory} . '/' . $_)
            } glob $self->{_glob_pattern}
        ];
        chdir $cwd;
    }
    unless (@{$self->{_metadatas}}) {
        undef $self->{_metadatas};
        return;
    }

    while (my $marshalled = shift @{$self->{_metadatas}}) {
        my ($lock_fh, $metadata, $message);

        # Try locking packet.  Those locked or removed by other process will
        # be skipped.
        $lock_fh =
            Sympa::LockedFile->new($self->{pct_directory} . '/' . $marshalled,
            -1, '+<');
        next unless $lock_fh;

        # FIXME: The list or the robot that injected packet can no longer be
        # available.
        $metadata = Sympa::Spool::unmarshal_metadata(
            $self->{pct_directory},
            $marshalled,
            qr{\A(\w+)\.(\w+)\.(\d+)\.(\d+\.\d+)\.(\@?[^\s\@]*)\@([\w\.\-*]*)_(\w+),(\d+),(\d+)/(\w+)\z},
            [   qw(priority packet_priority date time localpart domainpart tag pid rand serial)
            ]
        );

        if ($metadata) {
            unless ($options{no_filter}) {
                # Skip messages not yet to be delivered.
                next unless $metadata->{date} <= time;
            }

            my $msg_file = Sympa::Spool::marshal_metadata(
                $metadata,
                '%s.%s.%d.%f.%s@%s_%s,%ld,%d',
                [   qw(priority packet_priority date time localpart domainpart tag pid rand)
                ]
            );
            $message = Sympa::Message->new_from_file(
                $self->{msg_directory} . '/' . $msg_file, %$metadata);

            if ($message) {
                my $rcpt_string = do { local $RS; <$lock_fh> };
                $message->{rcpt} = [split /\n+/, $rcpt_string];
            }
        }

        # Though message might not be deserialized, anyway return the result.
        return ($message, $lock_fh);
    }
    return;
}

sub quarantine {
    my $self    = shift;
    my $lock_fh = shift;

    my $marshalled        = $lock_fh->basename(1);
    my $bad_pct_directory = $self->{bad_pct_directory} . '/' . $marshalled;
    my $bad_msg_file      = $self->{bad_msg_directory} . '/' . $marshalled;
    my $bad_pct_file;

    File::Copy::cp($self->{msg_directory} . '/' . $marshalled, $bad_msg_file)
        unless -e $bad_msg_file;

    $bad_pct_file = $bad_pct_directory . '/' . $lock_fh->basename;
    mkdir $bad_pct_directory unless -d $bad_pct_directory;
    unless (-d $bad_pct_directory and $lock_fh->rename($bad_pct_file)) {
        $bad_pct_file =
              $self->{pct_directory} . '/BAD-'
            . $lock_fh->basename(1) . '-'
            . $lock_fh->basename;
        return undef unless $lock_fh->rename($bad_pct_file);
    }

    if (rmdir($self->{pct_directory} . '/' . $marshalled)) {
        # No more packet.
        unlink($self->{msg_directory} . '/' . $marshalled);
    }
    return 1;
}

sub remove {
    my $self    = shift;
    my $lock_fh = shift;

    my $marshalled = $lock_fh->basename(1);

    if ($lock_fh->unlink) {
        if (rmdir($self->{pct_directory} . '/' . $marshalled)) {
            # No more packet.
            unlink($self->{msg_directory} . '/' . $marshalled);
        }
        return 1;
    }
    return undef;
}

# DEPRECATED: No longer used.
#sub messageasstring($messagekey);

# fetch message from bulkspool_table by key
# Old name: Sympa::Bulk::message_from_spool()
# DEPRECATED: Not used.
#sub fetch_content($messagekey);

# DEPRECATED: Use Sympa::Message::personalize().
# sub merge_msg;

# DEPRECATED: Use Sympa::Message::personalize_text().
# sub merge_data ($rcpt, $listname, $robot_id, $data, $body, \$message_output)

sub store {
    my $self    = shift;
    my $message = shift->dup;
    my $rcpt    = shift;
    my %options = @_;

    delete $message->{rcpt};    #FIXME

    my ($list, $robot_id);
    if (ref($message->{context}) eq 'Sympa::List') {
        $list     = $message->{context};
        $robot_id = $message->{context}->{'domain'};
    } elsif ($message->{context} and $message->{context} ne '*') {
        $robot_id = $message->{context};
    } else {
        $robot_id = '*';
    }

    my $tag = $options{tag};
    $tag = 's' unless defined $tag;
    $message->{tag} = $tag;

    $message->{priority} =
          $list
        ? $list->{admin}{priority}
        : Conf::get_robot_conf($robot_id, 'sympa_priority')
        unless defined $message->{priority} and length $message->{priority};
    $message->{packet_priority} =
        Conf::get_robot_conf($robot_id, 'sympa_packet_priority');
    $message->{date} = time unless defined $message->{date};
    $message->{time} = Time::HiRes::time();

    # First, store the message in bulk/msg spool, because as soon as packets
    # are created bulk.pl may distribute them.

    my $marshalled = Sympa::Spool::store_spool(
        $self->{msg_directory},
        $message,
        '%s.%s.%d.%f.%s@%s_%s,%ld,%d',
        [   qw(priority packet_priority date time localpart domainpart tag PID RAND)
        ],
        %options
    );
    return unless $marshalled;

    unless (mkdir($self->{pct_directory} . '/' . $marshalled)) {
        $log->syslog(
            'err',
            'Cannot mkdir %s/%s: %m',
            $self->{pct_directory}, $marshalled
        );
        unlink($self->{msg_directory} . '/' . $marshalled);
        return;
    }

    # Second, create each recipient packet in bulk/pct spool.

    my @rcpts;
    unless (ref $rcpt) {
        @rcpts = ([$rcpt]);
    } else {
        @rcpts = _get_recipient_tabs_by_domain($robot_id, @{$rcpt || []});
    }
    my $total_sent = $#rcpts + 1;

    # Create a temporary lock file in the packet directory to prevent bulk.pl
    # from removing packet directory and the message during addition of
    # packets.
    my $lock_fh_tmp = Sympa::LockedFile->new(
        $self->{pct_directory} . '/' . $marshalled . '/dont_rmdir',
        -1, '+');

    my $serial = $message->{tag};
    while (my $rcpt = shift @rcpts) {
        my $lock_fh = Sympa::LockedFile->new(
            $self->{pct_directory} . '/' . $marshalled . '/' . $serial,
            5, '>>');
        return unless $lock_fh;

        $lock_fh_tmp->close unless @rcpts;   # Now the last packet is written.

        print $lock_fh join("\n", @{$rcpt}) . "\n";
        $lock_fh->close;

        if (length $serial == 1) {           # '0', 's' or 'z'.
            $serial = '0001';
        } else {
            $serial++;
        }
    }

    $log->syslog('notice', 'Message %s is stored into bulk spool as <%s>',
        $message, $marshalled);
    return unless $marshalled;
    return {marshalled => $marshalled, total_packets => $total_sent};
}

# Old name: (part of) Sympa::Mail::mail_message().
sub _get_recipient_tabs_by_domain {
    my $robot_id = shift;
    my @rcpt     = @_;

    return unless @rcpt;

    # Sort by domain.
    @rcpt = map {
        join '@', grep { defined $_ } @$_;
    } sort {
        (($a->[1] // '') cmp($b->[1] // '')) || ($a->[0] cmp $b->[0])
    } map {
        [split /\@/, $_, 2]
    } @rcpt;

    my ($i, $j, $nrcpt);
    my $size = 0;

    my %rcpt_by_dom;

    my @sendto;
    my @sendtobypacket;

    while (defined($i = shift @rcpt)) {
        my @k = reverse split /[\.@]/, $i;
        my @l = reverse split /[\.@]/, (defined $j ? $j : '@');

        my $dom;
        if ($i =~ /\@(.*)$/) {
            $dom = $1;
            chomp $dom;
        }
        $rcpt_by_dom{$dom} += 1;
        $log->syslog(
            'debug2',
            'Domain: %s; rcpt by dom: %s; limit for this domain: %s',
            $dom,
            $rcpt_by_dom{$dom},
            $Conf::Conf{'nrcpt_by_domain'}{$dom}
        );

        if (
            # number of recipients by each domain
            (   defined $Conf::Conf{'nrcpt_by_domain'}{$dom}
                and $rcpt_by_dom{$dom} >= $Conf::Conf{'nrcpt_by_domain'}{$dom}
            )
            or
            # number of different domains
            (       $j
                and scalar(@sendto) > Conf::get_robot_conf($robot_id, 'avg')
                and lc "$k[0] $k[1]" ne lc "$l[0] $l[1]"
            )
            or
            # number of recipients in general
            (@sendto and $nrcpt >= Conf::get_robot_conf($robot_id, 'nrcpt'))
        ) {
            undef %rcpt_by_dom;
            # do not replace this line by "push @sendtobypacket, \@sendto" !!!
            my @tab = @sendto;
            push @sendtobypacket, \@tab;
            $nrcpt = $size = 0;
            @sendto = ();
        }

        $nrcpt++;
        $size += length($i) + 5;
        push(@sendto, $i);
        $j = $i;
    }

    if (@sendto) {
        my @tab = @sendto;
        # do not replace this line by push @sendtobypacket, \@sendto !!!
        push @sendtobypacket, \@tab;
    }

    return @sendtobypacket;
}

## remove file that are not referenced by any packet
# DEPRECATED: No longer used.
#sub purge_bulkspool();

# Old name: Bulk::there_is_too_much_remaining_packets().
sub too_much_remaining_packets {
    my $self = shift;

    my $remaining_packets = scalar @{$self->{_metadatas} || []};
    if ($remaining_packets > Conf::get_robot_conf('*', 'bulk_fork_threshold'))
    {
        return $remaining_packets;
    } else {
        return 0;
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Spool::Outgoing - Spool for outgoing messages

=head1 SYNOPSIS

  use Sympa::Spool::Outgoing;
  my $bulk = Sympa::Spool::Outgoing->new;

  $bulk->store($message, ['user@dom.ain', 'user@other.dom.ain']);

  my ($message, $handle) = $bulk->next;

=head1 DESCRIPTION

L<Sympa::Spool::Outgoing> implements the spool for outgoing messages.

=head2 Methods

=over

=item new ( )

I<Constructor>.
Creates new instance of L<Sympa::Spool::Outgoing>.

=item next ( [ no_filter =E<gt> 1 ] )

I<Instance method>.
Gets next packet to process, order is controlled by message priority, then by
packet priority, then by delivery date, then by reception date.
Packets with future delivery date are ignored
(if C<no_filter> option is I<not> set).
Packet will be locked to prevent multiple processing of a single packet.

Parameters:

None.

Returns:

Two-elements list of L<Sympa::Message> instance and filehandle locking
a packet.

=item quarantine ( $handle )

I<Instance method>.
Quarantines a packet.
Packet will be moved into bad/ subdirectory of the spool.

Parameter:

=over

=item $handle

Filehandle, L<Sympa::LockedFile> instance, locking packet.

=back

Returns:

True value if packet could be quarantined.
Otherwise false value.

=item remove ( $handle )

I<Instance method>.
Removes a packet.
If the packet is the last one of bulk sending,
corresponding message will also be removed from spool.

Parameter:

=over

=item $handle

Filehandle, L<Sympa::LockedFile> instance, locking packet.

=back

Returns:

True value if packet could be removed.
Otherwise false value.

=item store ( $message, $rcpt, [ original =E<gt> $original ],
[ tag =E<gt> $tag ] )

I<Instance method>.
Stores the message into message spool.
Recipients will be split into multiple packets and
stored into packet spool.

Parameters:

=over

=item $message

Message to be stored.  Following attributes and metadata are referred:

=over

=item {envelope_sender}

SMTP "MAIL FROM:" field.

=item {priority}

Message priority.

=item {packet_priority}

Packet priority, assigned as C<sympa_packet_priority> parameter by each robot.

=item {date}

Unix time when the message would be delivered.

=item {time}

Unix time in floating point number when the message was stored.

=back

=item $rcpt

Scalar, scalarref or arrayref, for SMTP "RCPT TO:" field(s).

=item original =E<gt> $original

If the message was decrypted, stores original encrypted form.

=item tag =E<gt> $tag

TBD.

=back

Returns:

If storing succeeded, marshalled metadata (file name) of the message.
Otherwise C<undef>.

=item too_much_remaining_packets ( )

I<Instance method>.
Returns true value if the number of remaining packets exceeds
the value of the C<bulk_fork_threshold> config parameter.

=back

=head1 CONFIGURATION PARAMETERS

Following site configuration parameters in sympa.conf will be referred.

=over

=item queuebulk

Directory path of outgoing spool.

Note:
Named such by historical reason.
Don't confuse with C<queueoutgoing> for archive spool
(see L<Sympa::Spool::Archive>).

=item umask

The umask to make directory.

=back

=head1 CAVEAT

L<Sympa::Spool::Outgoing> is not a real subsclass of L<Sympa::Spool>.

=head1 SEE ALSO

L<bulk(8)>, L<Sympa::Mailer>, L<Sympa::Message>.

=head1 HISTORY

L<Bulk> module initially written by Serge Aumont appeared on Sympa 6.0.
It used database tables to store and fetch packets and messages.

Support for DKIM signing was added on Sympa 6.1.

Rewritten L<Sympa::Bulk> appeared on Sympa 6.2, using spools based on
filesystem.
It was renamed to L<Sympa::Spool::Outgoing> on Sympa 6.2.45b.3.

=cut
