# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright 2022 The Sympa Community. See the
# AUTHORS.md file at the top-level directory of this distribution and at
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

package Sympa::CLI::upgrade::outgoing;

use strict;
use warnings;
use English qw(-no_match_vars);
use MIME::Base64 qw();
use POSIX qw();

use Conf;
use Sympa::Constants;
use Sympa::DatabaseManager;
use Sympa::List;
use Sympa::Log;
use Sympa::Message;
use Sympa::Spool;
use Sympa::Spool::Outgoing;

use parent qw(Sympa::CLI::upgrade);

use constant _options   => qw(dry_run);
use constant _args      => qw();
use constant _need_priv => 1;

my $log = Sympa::Log->instance;

# Old name: process() in uipgrade_bulk_spool.pl.
sub _run {
    my $class   = shift;
    my $options = shift;

    my $bulk = Sympa::Spool::Outgoing->new;

    my $sdm = Sympa::DatabaseManager->instance
        or die 'Can\'t connect to database';

    # Checking if bulkmailer_table exits
    my @tables;
    my $list_of_tables;
    if ($list_of_tables = $sdm->get_tables()) {
        @tables = @{$list_of_tables};
    } else {
        @tables = ();
    }
    my $found = 0;
    foreach my $t (@tables) {
        if ($t eq "bulkmailer_table") {
            $found = 1;
            last;
        }
    }
    if ($found == 0) {
        $log->syslog('notice',
            'bulkmailer table not found in database, bulk spool of your Sympa is probably up-to-date'
        );
        exit 0;
    }

    my $sth = $sdm->do_prepared_query(
        q{SELECT *
          FROM bulkmailer_table
          WHERE returnpath_bulkmailer IS NOT NULL}
    );
    unless ($sth) {
        die
            'Cannot execute SQL query.  Database is inaccessible or bulk spool of your Sympa is up-to-date';
    }
    my ($row_mailer, $row_spool);
    while ($row_mailer = $sth->fetchrow_hashref('NAME_lc')) {
        if ($row_mailer->{lock_bulkmailer}) {
            $log->syslog(
                'info',
                'Packet %s is locked.  Skipping',
                $row_mailer->{packetid_bulkmailer}
            );
            next;
        }
        my $packetid = $row_mailer->{packetid_bulkmailer};

        my ($list, $robot_id);
        $list = Sympa::List->new(
            $row_mailer->{listname_bulkmailer},
            $row_mailer->{robot_bulkmailer},
            {just_try => 1}
        );
        if ($list) {
            $robot_id = $list->{'domain'};
        } else {
            $robot_id = $row_mailer->{robot_bulkmailer} || '*';
        }
        my $packet_priority =
            Conf::get_robot_conf($robot_id, 'sympa_packet_priority');

        # Fetch message
        my $messagekey = $row_mailer->{messagekey_bulkmailer};
        my $sth2       = $sdm->do_prepared_query(
            q{SELECT *
              FROM bulkspool_table
              WHERE messagekey_bulkspool = ?},
            $messagekey
        );
        unless ($sth2) {
            die 'Fatal: Cannot execute SQL query';
        }
        $row_spool = $sth2->fetchrow_hashref('NAME_lc');
        $sth2->finish;
        unless ($row_spool) {
            $log->syslog('err', '%s: No messages found.  Skipping',
                $messagekey);
            $sth2->finish;
            next;
        }

        my $msg_string =
            MIME::Base64::decode($row_spool->{message_bulkspool});
        my $message = Sympa::Message->new(
            $msg_string,
            context => ($list || $robot_id),
            messagekey => $messagekey
        );

        printf
            "---\nMessage:       %s\nPacket:        %s\nDelivery Date: %s\nRecipients:    %s\nContext:       %s\@%s\n\nMessage-ID:    %s\nFrom:          %s\nSubject:       %s\n",
            $messagekey, $packetid,
            POSIX::strftime('%Y-%m-%d %H:%M:%S',
            localtime $row_mailer->{delivery_date_bulkmailer}),
            ($row_mailer->{receipients_bulkmailer} || 'NONE'),
            ($row_mailer->{listname_bulkmailer}    || ''),
            $row_mailer->{robot_bulkmailer},
            ($row_spool->{messageid_bulkspool} || ''),
            ($message->get_header('From', ', ') || ''),
            ($message->{decoded_subject} || '');

        print "Migrate this message? [yN] ";
        my $answer = <STDIN>;
        chomp $answer;
        next unless lc $answer eq 'y';

        # Update message and messagekey.

        $message->{date} = $row_mailer->{delivery_date_bulkmailer}  || time;
        $message->{time} = $row_mailer->{reception_date_bulkmailer} || time;

        $message->{priority} = $row_mailer->{priority_message_bulkmailer};
        $message->{packet_priority} = $packet_priority;
        if ($packet_priority lt $row_mailer->{priority_packet_bulkmailer}) {
            $message->{tag} = 'z';
        } else {
            $message->{tag} = '0';
        }

        $message->{shelved}{dkim_sign} = 1
            if $row_spool->{dkim_privatekey_bulkspool};
        $message->{message_id} = $row_spool->{messageid_bulkspool}
            if $row_spool->{messageid_bulkspool};
        $message->{envelope_sender} = $row_mailer->{returnpath_bulkmailer};
        $message->{shelved}{tracking} = 'verp'
            if $row_mailer->{verp_bulkmailer};
        $message->{shelved}{tracking} = $row_mailer->{tracking_bulkmailer}
            if $row_mailer->{tracking_bulkmailer};
        # Compatibility: On earlier version only 'all' mode was available.
        $message->{shelved}{merge} = 'all' if $row_mailer->{merge_bulkmailer};

        # Not a typo: column name was recEipients_bulkmailer.
        my $rcpt_string = $row_mailer->{receipients_bulkmailer};
        my $rcpt = [split /,/, $rcpt_string];

        my $marshalled;
        unless ($options->{dry_run}) {
            $marshalled =
                $bulk->store($message, $rcpt, tag => $message->{tag});
        } else {
            $marshalled = Sympa::Spool::marshal_metadata(
                $message,
                '%s.%s.%d.%f.%s@%s_%s,?????,????',
                [   qw(priority packet_priority date time localpart domainpart tag)
                ]
            );
        }
        unless ($marshalled) {
            $log->syslog(
                'err',
                'Packet %s of message %s could not be migrated into new spool',
                $row_mailer->{packetid_bulkmailer},
                $message
            );
            next;
        } else {
            $log->syslog(
                'notice',
                'Packet %s of message %s was migrated into new spool as <%s>',
                $row_mailer->{packetid_bulkmailer},
                $message,
                $marshalled
            );
        }
    }

    return 1;
}

1;
__END__

=encoding utf-8

=head1 NAME

sympa-upgrade-outgoing - Migrating messages in bulk tables

=head1 SYNOPSIS

  sympa upgrade outgoing [ --dry_run ]

=head1 DESCRIPTION

On Sympa earlier than 6.2, messages for bulk sending were stored into
bulk spool based on database tables.
Recent release of Sympa stores outbound messages into the spool based on
filesystem or sends them by Mailer directly.
This program migrates messages with old format in appropriate spool.

=head1 OPTIONS

=over

=item --dry_run

Shows what will be done but won't really perform upgrade process.

=back

=head1 RETURN VALUE

This program exits with status 0 if processing succeeded.
Otherwise exits with non-zero status.

=head1 CONFIGURATION OPTIONS

Following site configuration parameters in F<--CONFIG--> or
robot configuration parameters in C<robot.conf> are referred.

=over

=item db_type, db_name etc.

=item queuebulk

=item sympa_packet_priority

=item umask

=back

=head1 SEE ALSO

L<sympa.conf(5)>,
L<Sympa::Message>,
L<Sympa::Spool::Outgoing>.

=head1 HISTORY

F<upgrade_bulk_spool.pl> appeared on Sympa 6.2.

Its function was moved to C<sympa upgrade outgoing> command line
on Sympa 6.2.70.

Its function was moved to C<sympa upgrade outgoing> command line
on Sympa 6.2.70.

=cut
