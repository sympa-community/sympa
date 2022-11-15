# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
# Copyright 2017, 2019 The Sympa Community. See the AUTHORS.md file at
# the top-level directory of this distribution and at
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

package Sympa::Spindle::ProcessIncoming;

use strict;
use warnings;
use File::Copy qw();

use Sympa;
use Conf;
use Sympa::Language;
use Sympa::List;
use Sympa::Log;
use Sympa::Mailer;
use Sympa::Process;
use Sympa::Spool::Listmaster;
use Sympa::Tools::Data;

use base qw(Sympa::Spindle);

my $language = Sympa::Language->instance;
my $log      = Sympa::Log->instance;
my $mailer   = Sympa::Mailer->instance;

use constant _distaff => 'Sympa::Spool::Incoming';

sub _init {
    my $self  = shift;
    my $state = shift;

    if ($state == 0) {
        $self->{_loop_info}     = {};
        $self->{_msgid}         = {};
        $self->{_msgid_cleanup} = time;
    } elsif ($state == 1) {
        # Process grouped notifications.
        Sympa::Spool::Listmaster->instance->flush;

        # Cleanup in-memory msgid table, only in a while.
        if (time > $self->{_msgid_cleanup} +
            $Conf::Conf{'msgid_table_cleanup_frequency'}) {
            $self->_clean_msgid_table();
            $self->{_msgid_cleanup} = time;
        }

        # Clear "quiet" flag set by AuthorizeMessage spindle.
        delete $self->{quiet};
    }

    1;
}

sub _on_success {
    my $self    = shift;
    my $message = shift;
    my $handle  = shift;

    if ($self->{keepcopy}) {
        unless (
            File::Copy::copy(
                $self->{distaff}->{directory} . '/' . $handle->basename,
                $self->{keepcopy} . '/' . $handle->basename
            )
        ) {
            $log->syslog(
                'notice',
                'Could not rename %s/%s to %s/%s: %m',
                $self->{distaff}->{directory},
                $handle->basename,
                $self->{keepcopy},
                $handle->basename
            );
        }
    }

    $self->SUPER::_on_success($message, $handle);
}

# Old name: process_message() in sympa_msg.pl.
sub _twist {
    my $self    = shift;
    my $message = shift;

    unless (defined $message->{'message_id'}
        and length $message->{'message_id'}) {
        $log->syslog('err', 'Message %s has no message ID', $message);
        $log->db_log(
            #'robot'        => $robot,
            #'list'         => $listname,
            'action'       => 'process_message',
            'parameters'   => $message->get_id,
            'target_email' => "",
            'msg_id'       => "",
            'status'       => 'error',
            'error_type'   => 'no_message_id',
            'user_email'   => $message->{'sender'}
        );
        return undef;
    }

    my $msg_id = $message->{message_id};

    $language->set_lang($self->{lang}, $Conf::Conf{'lang'}, 'en');

    # Compatibility: Message with checksum by Sympa <=6.2a.40
    # They should be migrated.
    if ($message and $message->{checksum}) {
        $log->syslog('err',
            '%s: Message with old format.  Run upgrade_send_spool.pl',
            $message);
        return 0;    # Skip
    }

    $log->syslog(
        'notice',
        'Processing %s; envelope_sender=%s; message_id=%s; sender=%s',
        $message,
        $message->{envelope_sender},
        $message->{message_id},
        $message->{sender}
    );

    my $robot;
    my $listname;

    if (ref $message->{context} eq 'Sympa::List') {
        $robot = $message->{context}->{'domain'};
    } elsif ($message->{context} and $message->{context} ne '*') {
        $robot = $message->{context};
    } else {
        # Older "sympa" alias may not have "@domain" in argument of queue
        # program.
        $robot = $Conf::Conf{'domain'};
    }
    $listname = $message->{'listname'};

    ## Ignoring messages with no sender
    my $sender = $message->{'sender'};
    unless ($message->{'md5_check'} or $sender) {
        $log->syslog('err', 'No sender found in message %s', $message);
        $log->db_log(
            'robot'        => $robot,
            'list'         => $listname,
            'action'       => 'process_message',
            'parameters'   => "",
            'target_email' => "",
            'msg_id'       => $msg_id,
            'status'       => 'error',
            'error_type'   => 'no_sender',
            'user_email'   => $sender
        );
        return undef;
    }

    # Unknown robot.
    unless ($message->{'md5_check'} or Conf::valid_robot($robot)) {
        $log->syslog('err', 'Robot %s does not exist', $robot);
        Sympa::send_dsn('*', $message, {}, '5.1.2');
        $log->db_log(
            'robot'        => $robot,
            'list'         => $listname,
            'action'       => 'process_message',
            'parameters'   => "",
            'target_email' => "",
            'msg_id'       => $msg_id,
            'status'       => 'error',
            'error_type'   => 'unknown_robot',
            'user_email'   => $sender
        );
        return undef;
    }

    $language->set_lang(Conf::get_robot_conf($robot, 'lang'));

    # Load spam status.
    $message->check_spam_status;
    # Check Authentication-Results fields, DKIM signatures and/or ARC seals.
    $message->aggregate_authentication_results;
    # Check S/MIME signature.
    $message->check_smime_signature;
    # Decrypt message.  On success, check nested S/MIME signature.
    if ($message->smime_decrypt and not $message->{'smime_signed'}) {
        $message->check_smime_signature;
    }

    # *** Now message content may be altered. ***

    # Enable SMTP logging if required.
    $mailer->{log_smtp} = $self->{log_smtp}
        || Sympa::Tools::Data::smart_eq(
        Conf::get_robot_conf($robot, 'log_smtp'), 'on');
    # Setting log_level using conf unless it is set by calling option.
    $log->{level} =
        (defined $self->{log_level})
        ? $self->{log_level}
        : Conf::get_robot_conf($robot, 'log_level');

    ## Strip of the initial X-Sympa-To and X-Sympa-Checksum internal headers
    delete $message->{'rcpt'};
    delete $message->{'checksum'};

    my $list =
        (ref $message->{context} eq 'Sympa::List')
        ? $message->{context}
        : undef;

    my $list_address;
    if ($message->{'listtype'} and $message->{'listtype'} eq 'sympaowner') {
        # Discard messages for sympa-request address to avoid loop caused by
        # misconfiguration.
        $log->syslog('err',
            'Don\'t forward sympa-request to Sympa. Check configuration of MTA'
        );
        return undef;
    } elsif ($message->{'listtype'}
        and $message->{'listtype'} eq 'listmaster') {
        $list_address = Sympa::get_address($robot, 'listmaster');
    } elsif ($message->{'listtype'} and $message->{'listtype'} eq 'sympa') {
        $list_address = Sympa::get_address($robot);
    } else {
        unless (ref $list eq 'Sympa::List') {
            $log->syslog('err', 'List %s does not exist', $listname);
            Sympa::send_dsn($message->{context} || '*', $message, {},
                '5.1.1');
            $log->db_log(
                'robot'        => $robot,
                'list'         => $listname,
                'action'       => 'process_message',
                'parameters'   => "",
                'target_email' => "",
                'msg_id'       => $msg_id,
                'status'       => 'error',
                'error_type'   => 'unknown_list',
                'user_email'   => $sender
            );
            return undef;
        }
        $list_address = Sympa::get_address($list, $message->{listtype})
            || Sympa::get_address($list);
    }

    ## Loop prevention
    if (ref $list eq 'Sympa::List'
        and Sympa::Tools::Data::smart_eq(
            $list->{'admin'}{'reject_mail_from_automates_feature'}, 'on'
        )
    ) {
        my $conf_loop_prevention_regex;
        $conf_loop_prevention_regex =
            $list->{'admin'}{'loop_prevention_regex'};
        $conf_loop_prevention_regex ||=
            Conf::get_robot_conf($robot, 'loop_prevention_regex');
        if ($sender =~ /^($conf_loop_prevention_regex)(\@|$)/mi) {
            $log->syslog(
                'err',
                'Ignoring message which would cause a loop, sent by %s; matches loop_prevention_regex',
                $sender
            );
            return undef;
        }

        ## Ignore messages that would cause a loop
        ## Content-Identifier: Auto-replied is generated by some non standard
        ## X400 mailer
        if (grep {/Auto-replied/i} $message->get_header('Content-Identifier')
            or grep {/Auto Reply to/i}
            $message->get_header('X400-Content-Identifier')
            or grep { !/^no$/i } $message->get_header('Auto-Submitted')) {
            $log->syslog('err',
                "Ignoring message which would cause a loop; message appears to be an auto-reply"
            );
            return undef;
        }
    }

    # Loop prevention.
    foreach my $loop ($message->get_header('X-Loop')) {
        $log->syslog('debug3', 'X-Loop: %s', $loop);
        if ($loop and $loop eq $list_address) {
            $log->syslog('err',
                'Ignoring message which would cause a loop (X-Loop: %s)',
                $loop);
            return undef;
        }
    }

    # Anti-virus
    my $rc =
        $message->check_virus_infection(debug => $self->{debug_virus_check});
    if ($rc) {
        my $antivirus_notify =
            Conf::get_robot_conf($robot, 'antivirus_notify') || 'none';
        if ($antivirus_notify eq 'sender') {
            Sympa::send_file(
                $robot,
                'your_infected_msg',
                $sender,
                {   'virus_name'     => $rc,
                    'recipient'      => $list_address,
                    'sender'         => $message->{sender},
                    'lang'           => Conf::get_robot_conf($robot, 'lang'),
                    'auto_submitted' => 'auto-replied'
                }
            );
        } elsif ($antivirus_notify eq 'delivery_status') {
            Sympa::send_dsn(
                $message->{context},
                $message,
                {   'virus_name' => $rc,
                    'recipient'  => $list_address,
                    'sender'     => $message->{sender}
                },
                '5.7.0'
            );
        }
        $log->syslog('notice',
            "Message for %s from %s ignored, virus %s found",
            $list_address, $sender, $rc);
        $log->db_log(
            'robot'        => $robot,
            'list'         => $listname,
            'action'       => 'process_message',
            'parameters'   => "",
            'target_email' => "",
            'msg_id'       => $msg_id,
            'status'       => 'error',
            'error_type'   => 'virus',
            'user_email'   => $sender
        );
        return undef;
    } elsif (!defined($rc)) {
        Sympa::send_notify_to_listmaster(
            $robot,
            'antivirus_failed',
            [   sprintf
                    "Could not scan message %s; The message has been saved as BAD.",
                $message->get_id
            ]
        );

        return undef;
    }

    # Route messages to appropriate handlers.
    if (    $message->{listtype}
        and $message->{listtype} eq 'owner'
        and $message->{'decoded_subject'}
        and $message->{'decoded_subject'} =~
        /\A\s*(subscribe|unsubscribe)(\s*$listname)?\s*\z/i) {
        # Simulate Smartlist behaviour with command in subject.
        $message->{listtype} = lc $1;
    }
    return [$self->_splicing_to($message)];
}

# Private subroutines.

# Cleanup the msgid_table every 'msgid_table_cleanup_frequency' seconds.
# Removes all entries older than 'msgid_table_cleanup_ttl' seconds.
# Old name: clean_msgid_table() in sympa_msg.pl.
sub _clean_msgid_table {
    my $self = shift;

    foreach my $rcpt (keys %{$self->{_msgid}}) {
        foreach my $msgid (keys %{$self->{_msgid}{$rcpt}}) {
            if (time > $self->{_msgid}{$rcpt}{$msgid} +
                $Conf::Conf{'msgid_table_cleanup_ttl'}) {
                delete $self->{_msgid}{$rcpt}{$msgid};
            }
        }
    }

    return 1;
}

sub _splicing_to {
    my $self    = shift;
    my $message = shift;

    return {
        editor      => 'Sympa::Spindle::DoForward',
        listmaster  => 'Sympa::Spindle::DoForward',
        owner       => 'Sympa::Spindle::DoForward',    # -request
        return_path => 'Sympa::Spindle::DoForward',    # -owner
        subscribe   => 'Sympa::Spindle::DoCommand',
        sympa       => 'Sympa::Spindle::DoCommand',
        unsubscribe => 'Sympa::Spindle::DoCommand',
    }->{$message->{listtype} || ''}
        || 'Sympa::Spindle::DoMessage';
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Spindle::ProcessIncoming - Workflow of processing incoming messages

=head1 SYNOPSIS

  use Sympa::Spindle::ProcessIncoming;

  my $spindle = Sympa::Spindle::ProcessIncoming->new;
  $spindle->spin;

=head1 DESCRIPTION

L<Sympa::Spindle::ProcessIncoming> defines workflow to process incoming
messages.

When spin() method is invoked, it reads the messages in incoming spool and
rejects, quarantines or modifies them.
Processing are done in the following order:

=over

=item *

Checks if message has message ID and sender, and if not, quarantines it.
Because such messages will be source of various troubles.

=item *

Checks if robot which message is bound for exists, and if not, rejects it.

=item *

Checks spam status, DKIM signature and S/MIME signature,
and decrypts message if possible.
Result of these checks are stored in message object and used in succeeding
process.

=item *

If message is bound for the list, checks if the list exists, and if not,
rejects it.

=item *

Loop prevention.  If loop is detected, ignores message.

=item *

Virus checking, if enabled by configuration.
And if malware is detected, rejects or discards message.

=item *

Splices message to appropriate class according to the type of message:
L<Sympa::Spindle::DoCommand> for command message;
L<Sympa::Spindle::DoForward> for message bound for administrator;
L<Sympa::Spindle::DoMessage> for ordinal post.

=back

Order to process messages in source spool are controlled by modification time
of files and delivery date.
Some messages are skipped according to these priorities
(See L<Sympa::Spool::Incoming>):

=over

=item *

Messages with lowest priority (C<z> or C<Z>) are skipped.

=item *

Messages with possibly higher priority are chosen.
This is done by skipping messages with lower priority than those already
found.

=back

=head2 Public methods

See also L<Sympa::Spindle/"Public methods">.

=over

=item new ( [ keepcopy =E<gt> $directory ], [ lang =E<gt> $lang ],
[ log_level =E<gt> $level ],
[ log_smtp =E<gt> 0|1 ] )

=item spin ( )

new() may take following options:

=over

=item keepcopy =E<gt> $directory

spin() keeps copy of successfully processed messages in $directory.

=item lang =E<gt> $lang

Overwrites lang parameter in configuration.

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

Instance of L<Sympa::Spool::Incoming> class.

=back

=head1 SEE ALSO

L<Sympa::Message>,
L<Sympa::Spindle>, L<Sympa::Spindle::DoCommand>, L<Sympa::Spindle::DoForward>,
L<Sympa::Spindle::DoMessage>,
L<Sympa::Spool::Incoming>.

=head1 HISTORY

L<Sympa::Spindle::ProcessIncoming> appeared on Sympa 6.2.13.

=cut
