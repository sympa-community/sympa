# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

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

package Sympa::Bulk;

use strict;
use warnings;
use English qw(no_match_vars);
use Time::HiRes qw();

use Conf;
use Sympa::LockedFile;
use Log;
use Sympa::Message;
use tools;

# Cache of spool.
our $metadatas;

# Get next packet to process, order is controled by priority, then by
# packet_priority, then by delivery date, then by reception date.
# Next lock the packet to prevent multiple proccessing of a single packet

sub next {
    my $spool_dir = $Conf::Conf{'queuebulk'};

    unless ($metadatas) {
        my $dh;
        die $ERRNO unless opendir $dh, $spool_dir;
        $metadatas = [
            sort grep {
                        !/,lock/
                    and !/^(?:\.|T\.|BAD-)/
                    and -f ($spool_dir . '/' . $_)
                } readdir $dh
        ];
        closedir $dh;
    }
    unless (@{$metadatas}) {
        undef $metadatas;
        return;
    }

    my ($lock_fh, $metadata, $message);
    while (my $marshalled = shift @{$metadatas}) {
        # Try locking message.  Those locked or removed by other process will
        # be skipped.
        $lock_fh =
            Sympa::LockedFile->new($spool_dir . '/' . $marshalled, -1, '+<');
        next unless $lock_fh;

        # FIXME: The list or the robot that injected packet can no longer be
        # available.
        $metadata = tools::unmarshal_metadata(
            $spool_dir,
            $marshalled,
            qr{\A(\w+)\.(\w+)\.(\d+)\.(\d+\.\d+)\.([^\s\@]*)\@([\w\.\-*]*)_(\w+)(?:,.*)?\z},
            [qw(priority packet_priority date time localpart domainpart tag)]
        );

        if ($metadata) {
            # Skip messages not yet to be delivered.
            next unless $metadata->{date} <= time;

            my $msg_string = do { local $RS; <$lock_fh> };
            $message = Sympa::Message->new($msg_string, %$metadata);
        }

        # Though message might not be deserialized, anyway return the result.
        return ($message, $lock_fh);
    }
    return;
}

# remove a packet by packet ID. return false if packet could not be removed.
sub remove {
    my $lock_fh = shift;

    return $lock_fh->unlink;
}

# quarantine a packet.
sub quarantine {
    my $lock_fh = shift;

    my $spool_dir = $Conf::Conf{'queuebulk'};
    my $bad_dir   = $spool_dir . '/bad';
    my $bad_file;

    $bad_file = $bad_dir . '/' . $lock_fh->basename;
    return 1 if -d $bad_dir and $lock_fh->rename($bad_file);

    $bad_file = $spool_dir . '/BAD-' . $lock_fh->basename;
    return $lock_fh->rename($bad_file);
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
    Log::do_log('debug2', '(%s, ...)', @_);
    my $message = shift->dup;
    my $rcpt    = shift;
    my %options = @_;

    my $spool_dir = $Conf::Conf{'queuebulk'};
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

    # second : create each recipient packet in bulkmailer_table
    my @rcpts;
    unless (ref $rcpt) {
        @rcpts = ([$rcpt]);
    } else {
        @rcpts = _get_recipient_tabs_by_domain($robot_id, @{$rcpt || []});
    }

    my $marshalled;
    my $serial = ($message->{tag} eq '0') ? 1 : 0;
    foreach my $packet (@rcpts) {
        $message->{rcpt} = $packet;

        $marshalled = tools::store_spool(
            $spool_dir,
            $message,
            '%s.%s.%d.%f.%s@%s_%s,%ld,%d',
            [   qw(priority packet_priority date time localpart domainpart tag PID RAND)
            ],
            %options
        );
        return unless $marshalled;
        $message->{tag} = $serial++;
    }

    Log::do_log('notice', 'Message %s is stored into bulk spool as <%s>',
        $message, $marshalled);
    return $marshalled;
}

# Old name: (part of) Sympa::Mail::mail_message().
sub _get_recipient_tabs_by_domain {
    my $robot_id = shift;
    my @rcpt     = @_;

    return unless @rcpt;

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
        Log::do_log(
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

## Returns 1 if the number of remaining packets in the bulkmailer table
## exceeds
## the value of the 'bulk_fork_threshold' config parameter.
sub there_is_too_much_remaining_packets {
    Log::do_log('debug3', '');
    my $remaining_packets = scalar @{$metadatas || []};
    if ($remaining_packets > Conf::get_robot_conf('*', 'bulk_fork_threshold'))
    {
        return $remaining_packets;
    } else {
        return 0;
    }
}

1;
