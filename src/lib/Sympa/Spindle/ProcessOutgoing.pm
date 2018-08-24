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

package Sympa::Spindle::ProcessOutgoing;

use strict;
use warnings;
use English qw(-no_match_vars);

use Sympa;
use Sympa::Alarm;
use Conf;
use Sympa::DatabaseManager;
use Sympa::List;
use Sympa::Log;
use Sympa::Mailer;
use Sympa::Message::Template;
use Sympa::Process;
use Sympa::Tools::Data;
use Sympa::Tools::DKIM;
use Sympa::Tracking;

use base qw(Sympa::Spindle);

my $log     = Sympa::Log->instance;
my $mailer  = Sympa::Mailer->instance;
my $process = Sympa::Process->instance;

use constant _distaff => 'Sympa::Bulk';

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
        Sympa::Alarm->instance->flush;

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
                        $log->openlog($Conf::Conf{'syslog'},
                            $Conf::Conf{'log_socket_type'});
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

sub _twist {
    my $self    = shift;
    my $message = shift;

    # Get list/robot context.
    my ($list, $robot, $listname);
    if (ref($message->{context}) eq 'Sympa::List') {
        $list     = $message->{context};
        $robot    = $message->{context}->{'domain'};
        $listname = $list->{'name'};
    } elsif ($message->{context} and $message->{context} ne '*') {
        $robot = $message->{context};
    } else {
        $robot = '*';
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
        # trace_smime($message, 'init');
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
    #  -1 headers modifications (done in sympa.pl)
    #  -2 DMARC protection
    #  -3 personalize (a.k.a. "merge")
    #  -4 S/MIME signing
    #  -5 S/MIME encryption
    #  -6 remove existing signature if altered
    #  -7 DKIM signing

    if ($message->{shelved}{dmarc_protect}) {
        $message->dmarc_protect;
    }

    my $dkim;
    if ($message->{shelved}{dkim_sign}) {
        $dkim = Sympa::Tools::DKIM::get_dkim_parameters($message->{context});
    }

    if (   $message->{shelved}{merge}
        or $message->{shelved}{smime_encrypt}
        or $message->{shelved}{tracking}) {
        # message needs personalization
        my $key;

        foreach my $rcpt (@rcpts) {
            my $new_message = $message->dup;

            my $envid;
            my $return_path;

            if (Sympa::Tools::Data::smart_eq(
                    $new_message->{shelved}{tracking}, qr/dsn|mdn/
                )
            ) {
                # tracking by MDN required tracking by DSN to
                my $msgid = $new_message->{'message_id'};
                $envid =
                    Sympa::Tracking::find_notification_id_by_message($rcpt,
                    $msgid, $listname, $robot);
                $return_path = $list->get_bounce_address($rcpt, $envid);
                $new_message->replace_header('Disposition-Notification-To',
                    $return_path)
                    if $new_message->{shelved}{tracking} =~ /mdn/;
                # trace_smime($new_message, 'tracking');
            } elsif (
                Sympa::Tools::Data::smart_eq(
                    $new_message->{shelved}{tracking}, 'w'
                )
            ) {
                $return_path = $list->get_bounce_address($rcpt, 'w');
            } elsif (
                Sympa::Tools::Data::smart_eq(
                    $new_message->{shelved}{tracking}, 'r'
                )
            ) {
                $return_path = $list->get_bounce_address($rcpt, 'r');
            } elsif ($new_message->{shelved}{tracking}) {    # simple VERP
                $return_path = $list->get_bounce_address($rcpt);
            } elsif ($new_message->{envelope_sender}) {
                $return_path = $new_message->{envelope_sender};
            } elsif ($list) {
                $return_path = Sympa::get_address($list, 'return_path');
            } else {
                $return_path = Sympa::get_address($robot, 'owner');
            }

            if ($new_message->{shelved}{merge}) {
                unless ($new_message->personalize($list, $rcpt)) {
                    $log->syslog('err', 'Erreur d appel personalize()');
                    Sympa::send_notify_to_listmaster($list, 'bulk_failed',
                        {'message_id' => $message->get_id});
                    # Quarantine packet into bad spool.
                    return undef;
                }
                delete $new_message->{shelved}{merge};
            }

            if ($new_message->{shelved}{smime_sign}) {
                $new_message->smime_sign;
                delete $new_message->{shelved}{smime_sign};
            }

            if ($new_message->{shelved}{smime_encrypt}) {
                unless ($new_message->smime_encrypt($rcpt)) {
                    $log->syslog(
                        'err',
                        'Unable to encrypt message %s from %s for recipient %s',
                        $new_message,
                        $list,
                        $rcpt
                    );
                    # If encryption failed, send a generic error message:
                    # X509 cert missing.
                    my $entity = Sympa::Message::Template->new(
                        context  => $list,
                        template => 'x509-user-cert-missing',
                        rcpt     => $rcpt,
                        data     => {
                            'mail' => {
                                'sender'  => $new_message->{sender},
                                'subject' => $new_message->{decoded_subject},
                            },
                        }
                    )->as_entity;
                    $new_message->set_entity($entity);
                }
                delete $new_message->{shelved}{smime_encrypt};
            }

            if (Conf::get_robot_conf($robot, 'dkim_feature') eq 'on') {
                $new_message->remove_invalid_dkim_signature;
            }
            if ($new_message->{shelved}{dkim_sign} and $dkim) {
                # apply DKIM signature AFTER any other message
                # transformation.
                $new_message->dkim_sign(
                    'dkim_d'          => $dkim->{'d'},
                    'dkim_i'          => $dkim->{'i'},
                    'dkim_selector'   => $dkim->{'selector'},
                    'dkim_privatekey' => $dkim->{'private_key'},
                );
                delete $new_message->{shelved}{dkim_sign};
            }

            # trace_smime($new_message, 'dkim');

            $new_message->{envelope_sender} = $return_path;
            unless (
                defined $mailer->store(
                    $new_message, $rcpt,
                    envid => $envid,
                    tag   => $new_message->{serial}
                )
            ) {
                $log->syslog('err', 'Failed to store message %s into mailer',
                    $new_message);
                # Quarantine packet into bad spool.
                return undef;
            }
        }
    } else {
        # message doesn't need personalization, so can be sent by packet.
        my $new_message = $message->dup;

        my $return_path;

        if ($new_message->{envelope_sender}) {
            $return_path = $new_message->{envelope_sender};
        } elsif ($list) {
            $return_path = Sympa::get_address($list, 'return_path');
        } else {
            $return_path = Sympa::get_address($robot, 'owner');
        }

        if ($new_message->{shelved}{smime_sign}) {
            $new_message->smime_sign;
            delete $new_message->{shelved}{smime_sign};
        }

        if (Conf::get_robot_conf($robot, 'dkim_feature') eq 'on') {
            $new_message->remove_invalid_dkim_signature;
        }
        # Initial message
        if ($new_message->{shelved}{dkim_sign} and $dkim) {
            $new_message->dkim_sign(
                'dkim_d'          => $dkim->{'d'},
                'dkim_i'          => $dkim->{'i'},
                'dkim_selector'   => $dkim->{'selector'},
                'dkim_privatekey' => $dkim->{'private_key'},
            );
            delete $new_message->{shelved}{dkim_sign};
        }

        # trace_smime($new_message,'dkim 2');

        $new_message->{envelope_sender} = $return_path;
        unless (
            defined $mailer->store(
                $new_message, [@rcpts], tag => $new_message->{serial}
            )
        ) {
            $log->syslog('err', 'Failed to store message %s into mailer',
                $new_message);
            # Quarantine packet into bad spool.
            return undef;
        }
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

=item *

S/MIME signing

=item *

S/MIME encryption

=item *

Removal of existing DKIM signature(s) which are invalidated by
preceding transformations.

=item *

DKIM signing

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

Instance of L<Sympa::Bulk> class.

=back

=head1 SEE ALSO

L<Sympa::Bulk>, L<Sympa::Mailer>, L<Sympa::Message>, L<Sympa::Spindle>.

=head1 HISTORY

L<Sympa::Spindle::ProcessOutgoing> appeared on Sympa 6.2.13.

=cut
