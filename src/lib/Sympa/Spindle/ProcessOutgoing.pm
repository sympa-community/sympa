# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
# Copyright 2017, 2019, 2021, 2022, 2024 The Sympa Community. See the
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

package Sympa::Spindle::ProcessOutgoing;

use strict;
use warnings;
use English qw(-no_match_vars);

use Sympa;
use Conf;
use Sympa::DatabaseManager;
use Sympa::List;
use Sympa::Log;
use Sympa::Mailer;
use Sympa::Message::Template;
use Sympa::Process;
use Sympa::Spool::Listmaster;
use Sympa::Tools::Data;
use Sympa::Tools::DKIM;
use Sympa::Tracking;

use base qw(Sympa::Spindle);

my $log     = Sympa::Log->instance;
my $mailer  = Sympa::Mailer->instance;
my $process = Sympa::Process->instance;

use constant _distaff => 'Sympa::Spool::Outgoing';

sub _init {
    my $self  = shift;
    my $state = shift;

    if ($state == 0) {
        $self->{_last_activity} = time;
        $self->{_last_check}    = 0;
        $self->{_pids}          = {};
    } elsif ($state == 1) {
        # Enable SMTP logging if required.
        $mailer->{log_smtp} = $self->{log_smtp}
            || Sympa::Tools::Data::smart_eq($Conf::Conf{'log_smtp'}, 'on');
        # setting log_level using conf unless it is set by calling option
        $log->{level} =
            (defined $self->{log_level})
            ? $self->{log_level}
            : $Conf::Conf{'log_level'};

        # Process grouped notifications.
        Sympa::Spool::Listmaster->instance->flush;

        unless ($process->{detached}) {
            ;
        } elsif (0 == $process->{generation}) {
            # Create child bulks if too much packets are waiting to be sent in
            # the bulk_mailer table.
            # Only the main bulk process ({generation} is 0) can create child
            # processes.
            # Check if we need to run new child processes every
            # 'bulk_wait_to_fork' (sympa.conf parameter) seconds.
            $self->_fork_children;
        } elsif (0 < $process->{generation}) {
            # If a child bulk process is running for long enough, stop it (if
            # the number of remaining packets to send is modest).
            $self->_finish_child;
            return 0 if $self->{finish};
        }
    } elsif ($state == 2) {
        $self->{_last_activity} = time;
    }

    1;
}

# Private subroutine.
sub _fork_children {
    my $self = shift;

    if ($Conf::Conf{'bulk_wait_to_fork'} < time - $self->{_last_check}) {
        # Clean up PID file (in case some child bulks would have died)
        $process->sync_child(hash => $self->{_pids}, file => 1);

        # Start new processes if there remain at least
        # 'bulk_fork_threshold' packets to send in the bulk spool.
        my $spare_children =
            $Conf::Conf{'bulk_max_count'} - scalar keys %{$self->{_pids}};
        if (my $r_packets = $self->{distaff}->too_much_remaining_packets
            and 0 < $spare_children) {
            # Disconnect from database before fork to prevent DB handles
            # to be shared by different processes.  Sharing database
            # handles may crash bulk.pl.
            Sympa::DatabaseManager->disconnect;

            if ($Conf::Conf{'bulk_max_count'} > 1) {
                $log->syslog(
                    'info',
                    'Important workload: %s packets to process. Creating %s child bulks to increase sending rate',
                    $r_packets,
                    $spare_children
                );
                for my $process_count (1 .. $spare_children) {
                    $log->syslog('info', "Will fork: %s", $process_count);
                    my $child_pid = $process->fork;
                    if ($child_pid) {
                        $log->syslog('info',
                            'Starting bulk child daemon, PID %s', $child_pid);
                        # Save the PID number.
                        $process->write_pid(pid => $child_pid);
                        $self->{_pids}->{$child_pid} = 1;
                        sleep 1;
                    } elsif (not defined $child_pid) {
                        $log->syslog('err', 'Cannot fork: %m');
                        last;
                    } else {
                        # We're in a child bulk process.
                        close STDERR;
                        $process->direct_stderr_to_file;
                        $self->{_last_activity} = time;
                        $log->openlog;
                        $log->syslog('info',
                            'Bulk slave daemon started with PID %s', $PID);
                        last;
                    }
                }
            }

            # Restore persistent connection.
            Sympa::DatabaseManager->instance
                or die 'Reconnecting database failed';
        }
        $self->{_last_check} = time;
    }
}

# Private subroutine.
sub _finish_child {
    my $self = shift;

    if (time - $self->{_last_activity} > $Conf::Conf{'bulk_lazytime'}
        and !$self->{distaff}->too_much_remaining_packets) {
        $log->syslog('info',
            'Process %s didn\'t send any message since %s seconds, exiting',
            $PID, $Conf::Conf{'bulk_lazytime'});

        $self->{finish} = 'exit';
    }
}

sub __twist_one {
    my $message = shift->dup;
    my $rcpt    = shift;
    my %arc     = %{shift || {}};
    my %dkim    = %{shift || {}};
    my $rm_sig  = shift;

    my $that = $message->{context};

    my $personalize   = $message->{shelved}{merge};
    my $smime_encrypt = $message->{shelved}{smime_encrypt};
    my $tracking      = $message->{shelved}{tracking};
    die 'bug in logic. Ask developer'
        unless ($personalize or $smime_encrypt or $tracking)
        xor ref $rcpt eq 'ARRAY';
    my $decorate   = $message->{shelved}{decorate};
    my $smime_sign = $message->{shelved}{smime_sign};
    die 'bug in logic. Ask developer'
        if ($personalize
        or $smime_encrypt
        or $tracking
        or $decorate
        or $smime_sign)
        and not ref $that eq 'Sympa::List';

    # If message is personalized and DKIM signature is available,
    # Add One-Click Unsubscribe header field.
    if (    $personalize
        and (%arc or $message->{shelved}{dkim_sign} and %dkim)
        and grep { 'unsubscribe' eq $_ }
        @{$that->{'admin'}{'rfc2369_header_fields'}}) {
        $that->add_list_header($message, 'unsubscribe', oneclick => $rcpt);
    }
    if ($personalize and $personalize ne 'footer') {
        unless ($message->personalize($that, $rcpt)) {
            $log->syslog('err', 'Erreur d appel personalize()');
            Sympa::send_notify_to_listmaster($that, 'bulk_failed',
                {'message_id' => $message->get_id});
            # Quarantine packet into bad spool.
            return undef;
        }
        $personalize = 'footer';
    }
    if ($decorate) {
        $message->decorate(
            $that,
            (ref $rcpt ? undef : $rcpt),
            mode => $personalize
        );
    }

    if ($smime_sign) {
        $message->smime_sign;
    }
    if ($smime_encrypt) {
        unless ($message->smime_encrypt($rcpt)) {
            $log->syslog('err',
                'Unable to encrypt message %s from %s for recipient %s',
                $message, $that, $rcpt);
            # If encryption failed, send a generic error message:
            # X509 cert missing.
            my $entity = Sympa::Message::Template->new(
                context  => $that,
                template => 'x509-user-cert-missing',
                rcpt     => $rcpt,
                data     => {
                    'mail' => {
                        'sender'  => $message->{sender},
                        'subject' => $message->{decoded_subject},
                    },
                }
            )->as_entity;
            $message->set_entity($entity);
        }
    }

    if ($rm_sig) {
        # If it is set up, remove header fields related to DKIM signature
        # given by upstream MTAs.
        # AR should be removed after it is included into AAR: See below.
        $message->delete_header('DKIM-Signature');
        $message->delete_header('Domainkey-Signature');
    }

    if ($message->{shelved}{dkim_sign} or %arc) {
        # apply DKIM signature AFTER any other message transformation.
        # Note that when ARC seal was added, DKIM signature is forced.
        $message->dkim_sign(%dkim) if %dkim;
    }
    # DKIM signing must be done before ARC sealing. See RFC 8617, 5.1.
    $message->arc_seal(%arc) if %arc;

    if ($rm_sig) {
        $message->delete_header('Authentication-Results');
    }

    # Determine envelope sender and envelope ID.
    my $envid = undef;
    if ($tracking) {
        # If tracking (including VERP) is enabled, override envelope sender.
        if ($tracking =~ /dsn|mdn/) {
            # Note: Tracking by MDN requires tracking by DSN too.
            my $msgid = $message->{'message_id'};
            $envid =
                Sympa::Tracking::find_notification_id_by_message($rcpt,
                $msgid, $that);
            my $return_path = $that->get_bounce_address($rcpt, $envid);
            $message->replace_header('Disposition-Notification-To',
                $return_path)
                if $tracking =~ /mdn/;
            $message->{envelope_sender} = $return_path;
        } else {
            $message->{envelope_sender} =
                  $tracking eq 'w' ? $that->get_bounce_address($rcpt, 'w')
                : $tracking eq 'r' ? $that->get_bounce_address($rcpt, 'r')
                :                    $that->get_bounce_address($rcpt);
        }
    } else {
        # Otherwise, unless specified explicitly, the default is applied.
        $message->{envelope_sender} ||=
            ref $that eq 'Sympa::List'
            ? Sympa::get_address($that, 'return_path')
            : Sympa::get_address($that, 'owner');
    }

    unless (
        defined $mailer->store(
            $message, $rcpt,
            envid => $envid,
            tag   => $message->{serial}
        )
    ) {
        $log->syslog('err', 'Failed to store message %s into mailer',
            $message);
        # Quarantine packet into bad spool.
        return undef;
    }
}

sub _twist {
    my $self    = shift;
    my $message = shift;

    # Get list/robot context.
    my ($list, $robot, $arc_enabled, $dkim_enabled, $rm_sig);
    if (ref($message->{context}) eq 'Sympa::List') {
        $list  = $message->{context};
        $robot = $message->{context}->{'domain'};

        $arc_enabled = 'on' eq $list->{'admin'}{'arc_feature'};
        $dkim_enabled =
            'on' eq Conf::get_robot_conf($list->{'domain'}, 'dkim_feature');
        $rm_sig = 'on' eq $list->{'admin'}{'remove_dkim_headers'};
    } elsif ($message->{context} and $message->{context} ne '*') {
        $robot = $message->{context};

        $arc_enabled  = 'on' eq Conf::get_robot_conf($robot, 'arc_feature');
        $dkim_enabled = 'on' eq Conf::get_robot_conf($robot, 'dkim_feature');
        $rm_sig = 'on' eq Conf::get_robot_conf($robot, 'remove_dkim_headers');
    } else {
        $robot = '*';

        $arc_enabled  = 'on' eq $Conf::Conf{'arc_feature'};
        $dkim_enabled = 'on' eq $Conf::Conf{'dkim_feature'};
        $rm_sig       = 'on' eq $Conf::Conf{'remove_dkim_headers'};
    }

    if ($message->{serial} eq '0' or $message->{serial} eq 's') {
        $log->syslog(
            'notice',
            'Start sending message %s to %s (priority %s) (starting %s seconds after scheduled expedition date)',
            $message,
            $message->{context},
            $message->{'priority'},
            time() - $message->{'date'}
        );
    }

    # Enable SMTP logging if required.
    $mailer->{log_smtp} = $self->{log_smtp}
        || Sympa::Tools::Data::smart_eq(
        Conf::get_robot_conf($robot, 'log_smtp'), 'on');
    # setting log_level using conf unless it is set by calling option
    $log->{level} =
        (defined $self->{log_level})
        ? $self->{log_level}
        : Conf::get_robot_conf($robot, 'log_level');

    # Contain all the subscribers
    my @rcpts = @{$message->{rcpt}};

    # Message transformation should be done in the folowing order:
    #  -1 headers modifications (done in preceding Spindle modules)
    #  -2 DMARC protection
    #  -3 personalization ("merge") and decoration (adding footer/header)
    #  -4 S/MIME signing
    #  -5 S/MIME encryption
    #  -6 remove existing signature if altered (optional)
    #  -7 DKIM signing and ARC sealing

    if ($message->{shelved}{dmarc_protect}) {
        $message->dmarc_protect;
    }

    my %arc =
        Sympa::Tools::DKIM::get_arc_parameters($message->{context},
        $message->{shelved}{arc_cv})
        if $arc_enabled and $message->{shelved}{arc_cv};
    my %dkim = Sympa::Tools::DKIM::get_dkim_parameters($message->{context})
        if %arc
        or $message->{shelved}{dkim_sign};

    if (   $message->{shelved}{merge}
        or $message->{shelved}{smime_encrypt}
        or $message->{shelved}{tracking}) {
        # message needs personalization
        foreach my $rcpt (@rcpts) {
            __twist_one($message, $rcpt, {%arc}, {%dkim},
                $arc_enabled || $dkim_enabled);
        }
    } else {
        # message doesn't need personalization, so can be sent by packet.
        __twist_one($message, [@rcpts], {%arc}, {%dkim},
            $arc_enabled || $dkim_enabled);
    }

    1;
}

# Old name: trace_smime() in bulk.pl.
# No longer used.
#sub _trace_smime;

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Spindle::ProcessOutgoing - Workflow of message distribution

=head1 SYNOPSIS

  use Sympa::Spindle::ProcessOutgoing;

  my $spindle = Sympa::Spindle::ProcessOutgoing->new;
  $spindle->spin;

=head1 DESCRIPTION

L<Sympa::Spindle::ProcessOutgoing> defines workflow to distribute messages
in outgoing spool using mailer.

If messages are stored into incoming spool, sooner or later
L<Sympa::Spindle::ProcessIncoming> fetches them, modifies header and body of
them, shelves several transformations, and at last stores altered messages
into outgoing spool.

When spin() method of this class is invoked, it reads the messages in outgoing
spool and executes shelved transformations.
Message transformations are done in the following order:

=over

=item *

DMARC protection

=item *

Processing for tracking and VERP (see also <Sympa::Tracking>)

=item *

Personalization (a.k.a. "merge")
and decoration (adding footer/header)

=item *

S/MIME signing

=item *

S/MIME encryption

=item *

Removal of existing DKIM signature(s) which are invalidated by
preceding transformations.

=item *

DKIM signing
and ARC sealing

=back

Then spin() method stores transformed message into mailer
(See L<Sympa::Mailer>).

=head2 Public methods

See also L<Sympa::Spindle/"Public methods">.

=over

=item new ( [ log_level =E<gt> $level ], [ log_smtp =E<gt> 0|1 ] )

=item spin ( )

new() may take following options:

=over

=item log_level =E<gt> $level

Overwrites log_level parameter in configuration.

=item log_smtp =E<gt> 0|1

Overwrites log_smtp parameter in configuration.

=back

=back

=head2 Properties

See also L<Sympa::Spindle/"Properties">.

=over

=item {distaff}

Instance of L<Sympa::Spool::Outgoing> class.

=back

=head1 SEE ALSO

L<Sympa::Mailer>, L<Sympa::Message>, L<Sympa::Spindle>,
L<Sympa::Spool::Outgoing>.

=head1 HISTORY

L<Sympa::Spindle::ProcessOutgoing> appeared on Sympa 6.2.13.

Message decoration was moved from L<Sympa::Spindle::ToList>
to this module on Sympa 6.2.59b.

=cut
