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

package Sympa::Spindle::DoMessage;

use strict;
use warnings;
use POSIX qw();

use Sympa;
use Conf;
use Sympa::Language;
use Sympa::List;
use Sympa::Log;
use Sympa::Regexps;
use Sympa::Report;
use Sympa::Scenario;
use Sympa::Tools::Data;
use Sympa::Topic;

use base qw(Sympa::Spindle::ProcessIncoming);

my $log = Sympa::Log->instance;

# Old name: DoMessage() in sympa_msg.pl.
sub _twist {
    my $self    = shift;
    my $message = shift;

    # Fail-safe: Skip messages with unwanted types.
    return 0 unless $self->_splicing_to($message) eq __PACKAGE__;

    my $start_time = time;

    # List unknown.
    unless (ref $message->{context} eq 'Sympa::List') {
        $log->syslog('notice', 'Unknown list %s', $message->{localpart});

        unless (
            Sympa::send_file(
                $message->{context},
                'list_unknown',
                $message->{sender},
                {   'list' => $message->{localpart},
                    'date' =>
                        POSIX::strftime("%d %b %Y  %H:%M", localtime(time)),
                    'header'         => $message->header_as_string,
                    'auto_submitted' => 'auto-replied'
                }
            )
            ) {
            $log->syslog('notice',
                'Unable to send template "list_unknown" to %s',
                $message->{sender});
        }
        return undef;
    }
    my $list = $message->{context};

    Sympa::Language->instance->set_lang(
        $list->{'admin'}{'lang'},
        Conf::get_robot_conf($list->{'domain'}, 'lang'),
        $Conf::Conf{'lang'}, 'en'
    );

    my $messageid  = $message->{message_id};
    my $msg_string = $message->as_string;
    my $sender     = $message->{'sender'};

    ## Now check if the sender is an authorized address.

    $log->syslog('info',
        "Processing message %s for %s with priority %s, <%s>",
        $message, $list, $list->{'admin'}{'priority'}, $messageid);

    if ($self->{_msgid}{$list->get_id}{$messageid}) {
        $log->syslog(
            'err',
            'Found known Message-ID <%s>, ignoring message %s which would cause a loop',
            $messageid,
            $message
        );
        $log->db_log(
            'robot'        => $list->{'domain'},
            'list'         => $list->{'name'},
            'action'       => 'DoMessage',
            'parameters'   => $message->get_id,
            'target_email' => '',
            'msg_id'       => $messageid,
            'status'       => 'error',
            'error_type'   => 'known_message',
            'user_email'   => $sender
        );
        return undef;
    }

    # Reject messages with commands
    if ($Conf::Conf{'misaddressed_commands'} =~ /reject/i) {
        # Check the message for commands and catch them.
        my $cmd = _check_command($message);
        if (defined $cmd) {
            $log->syslog('err',
                'Found command "%s" in message, ignoring message', $cmd);
            Sympa::Report::reject_report_msg('user', 'routing_error', $sender,
                {'message' => $message},
                $list->{'domain'}, $msg_string, $list);
            $log->db_log(
                'robot'        => $list->{'domain'},
                'list'         => $list->{'name'},
                'action'       => 'DoMessage',
                'parameters'   => $message->get_id,
                'target_email' => '',
                'msg_id'       => $messageid,
                'status'       => 'error',
                'error_type'   => 'routing_error',
                'user_email'   => $sender
            );
            return undef;
        }
    }

    # Check if the message is too large
    my $max_size = $list->{'admin'}{'max_size'};

    if ($max_size and $max_size < $message->{size}) {
        $log->syslog('info',
            'Message for %s from %s rejected because too large (%d > %d)',
            $list, $sender, $message->{size}, $max_size);
        Sympa::Report::reject_report_msg(
            'user',
            'message_too_large',
            $sender,
            {   'msg_size' => int($message->{'size'} / 1024),
                'max_size' => int($max_size / 1024)
            },
            $list->{'domain'},
            '', $list
        );
        $log->db_log(
            'robot'        => $list->{'domain'},
            'list'         => $list->{'name'},
            'action'       => 'DoMessage',
            'parameters'   => $message->get_id,
            'target_email' => '',
            'msg_id'       => $messageid,
            'status'       => 'error',
            'error_type'   => 'message_too_large',
            'user_email'   => $sender
        );
        return undef;
    }

    my $context = {
        'sender'  => $sender,
        'message' => $message
    };

    # List msg topic.
    if ($list->is_there_msg_topic) {
        my $topic;
        if ($topic = Sympa::Topic->load($message)) {
            # Is message already tagged?
            ;
        } elsif ($topic = Sympa::Topic->load($message, in_reply_to => 1)) {
            # Is message in-reply-to already tagged?
            $topic =
                Sympa::Topic->new(topic => $topic->{topic}, method => 'auto');
            $topic->store($message);
        } elsif (my $topic_list = $message->compute_topic) {
            # Not already tagged.
            $topic =
                Sympa::Topic->new(topic => $topic_list, method => 'auto');
            $topic->store($message);
        }

        if ($topic) {
            $context->{'topic'} = $context->{'topic_' . $topic->{method}} =
                $topic->{topic};
        }
        $context->{'topic_needed'} =
            (!$context->{'topic'} && $list->is_msg_topic_tagging_required);
    }

    # Call scenario: auth_method MD5 do not have any sense in "send"
    # scenario because auth is performed by distribute or reject command.

    my $action;
    my $result;

    # The order of the following 3 lines is important! SMIME > DKIM > SMTP.
    my $auth_method =
          $message->{'smime_signed'} ? 'smime'
        : $message->{'md5_check'}    ? 'md5'
        : $message->{'dkim_pass'}    ? 'dkim'
        :                              'smtp';

    $result = Sympa::Scenario::request_action($list, 'send', $auth_method,
        $context);
    $action = $result->{'action'} if (ref($result) eq 'HASH');

    unless (defined $action) {
        $log->syslog(
            'err',
            'Message %s ignored because unable to evaluate scenario "send" for list %s',
            $message,
            $list
        );
        Sympa::Report::reject_report_msg(
            'intern',
            'Message ignored because scenario "send" cannot be evaluated',
            $sender,
            {'msg_id' => $messageid, 'message' => $message},
            $list->{'domain'},
            $msg_string,
            $list
        );
        $log->db_log(
            'robot'        => $list->{'domain'},
            'list'         => $list->{'name'},
            'action'       => 'DoMessage',
            'parameters'   => $message->get_id,
            'target_email' => '',
            'msg_id'       => $messageid,
            'status'       => 'error',
            'error_type'   => 'internal',
            'user_email'   => $sender
        );
        return undef;
    }

    # Message topic context.
    if ($action =~ /^do_it\b/ and $context->{'topic_needed'}) {
        if ($list->{'admin'}{'msg_topic_tagging'} eq 'required_sender') {
            $action = 'request_auth';
        } elsif (
            $list->{'admin'}{'msg_topic_tagging'} eq 'required_moderator') {
            $action = 'editorkey';
        }
    }

    if ($action =~ /^do_it\b/) {
        $message->{shelved}{dkim_sign} = 1
            if Sympa::Tools::Data::is_in_array(
            $list->{'admin'}{'dkim_signature_apply_on'}, 'any')
            or (
            Sympa::Tools::Data::is_in_array(
                $list->{'admin'}{'dkim_signature_apply_on'},
                'smime_authenticated_messages')
            and $message->{'smime_signed'}
            )
            or (
            Sympa::Tools::Data::is_in_array(
                $list->{'admin'}{'dkim_signature_apply_on'},
                'dkim_authenticated_messages')
            and $message->{'dkim_pass'}
            );

        # Check TT2 syntax for merge_feature.
        unless ($message->test_personalize($list)) {
            $log->syslog(
                'err',
                'Failed to personalize. Message %s for list %s was rejected',
                $message,
                $list
            );
            Sympa::send_dsn($list, $message, {}, '5.6.5');
            return undef;
        }

        my $numsmtp = Sympa::List::distribute_msg($message);

        # Keep track of known message IDs...if any.
        $self->{_msgid}{$list->get_id}{$messageid} = time
            if $messageid;

        unless (defined $numsmtp) {
            $log->syslog('err', 'Unable to send message %s to list %s',
                $message, $list);
            Sympa::Report::reject_report_msg('intern', '', $sender,
                {'msg_id' => $messageid, 'message' => $message},
                $list->{'domain'}, $msg_string, $list);
            $log->db_log(
                'robot'        => $list->{'domain'},
                'list'         => $list->{'name'},
                'action'       => 'DoMessage',
                'parameters'   => $message->get_id,
                'target_email' => '',
                'msg_id'       => $messageid,
                'status'       => 'error',
                'error_type'   => 'internal',
                'user_email'   => $sender
            );
            return undef;
        }
        $log->syslog(
            'info',
            'Message %s for %s from %s accepted (%d seconds, %d sessions, %d subscribers), message ID=%s, size=%d',
            $message,
            $list,
            $sender,
            time - $start_time,
            $numsmtp,
            $list->get_total,
            $messageid,
            $message->{'size'}
        );

        return 1;
    } elsif ($action =~ /^request_auth\b/) {
        ## Check syntax for merge_feature.
        unless ($message->test_personalize($list)) {
            $log->syslog(
                'err',
                'Failed to personalize. Message %s for list %s was rejected',
                $message,
                $list
            );
            Sympa::send_dsn($list, $message, {}, '5.6.5');
            return undef;
        }

        my $key = Sympa::List::send_confirm_to_sender($message);

        unless (defined $key) {
            $log->syslog('err',
                'Failed to send confirmation of %s for %s to sender %s',
                $message, $list, $sender);
            Sympa::Report::reject_report_msg(
                'intern',
                'The request authentication sending failed',
                $sender,
                {'msg_id' => $messageid, 'message' => $message},
                $list->{'domain'},
                $msg_string,
                $list
            );
            $log->db_log(
                'robot'        => $list->{'domain'},
                'list'         => $list->{'name'},
                'action'       => 'DoMessage',
                'parameters'   => $message->get_id,
                'target_email' => '',
                'msg_id'       => $messageid,
                'status'       => 'error',
                'error_type'   => 'internal',
                'user_email'   => $sender
            );
            return undef;
        }
        $log->syslog('notice',
            'Message %s for %s from %s kept for authentication with key %s',
            $message, $list, $sender, $key);
        $log->db_log(
            'robot'        => $list->{'domain'},
            'list'         => $list->{'name'},
            'action'       => 'DoMessage',
            'parameters'   => $message->get_id,
            'target_email' => '',
            'msg_id'       => $messageid,
            'status'       => 'success',
            'error_type'   => 'kept_for_auth',
            'user_email'   => $sender
        );

        return 1;
    } elsif ($action =~ /^editorkey\b(?:\s*,\s*(quiet))?/) {
        my $quiet = $1;

        # Check syntax for merge_feature.
        unless ($message->test_personalize($list)) {
            $log->syslog(
                'err',
                'Failed to personalize. Message %s for list %s was rejected',
                $message,
                $list
            );
            Sympa::send_dsn($list, $message, {}, '5.6.5');
            return undef;
        }

        my $key = Sympa::List::send_confirm_to_editor($message, 'md5');

        unless (defined $key) {
            $log->syslog(
                'err',
                'Failed to send moderation request of %s from %s for list %s to editor(s)',
                $message,
                $sender,
                $list
            );
            Sympa::Report::reject_report_msg(
                'intern',
                'The request moderation sending to moderator failed.',
                $sender,
                {'msg_id' => $messageid, 'message' => $message},
                $list->{'domain'},
                $msg_string,
                $list
            );
            $log->db_log(
                'robot'        => $list->{'domain'},
                'list'         => $list->{'name'},
                'action'       => 'DoMessage',
                'parameters'   => $message->get_id,
                'target_email' => '',
                'msg_id'       => $messageid,
                'status'       => 'error',
                'error_type'   => 'internal',
                'user_email'   => $sender
            );
            return undef;
        }

        $log->syslog('info',
            'Key %s of message %s for list %s from %s sent to editors',
            $key, $message, $list, $sender);

        # Do not report to the sender if the message was tagged as a spam.
        unless ($quiet or $message->{'spam_status'} eq 'spam') {
            Sympa::Report::notice_report_msg('moderating_message', $sender,
                {'message' => $message},
                $list->{'domain'}, $list);
        }
        return 1;

    } elsif ($action =~ /^editor\b(?:\s*,\s*(quiet))?/) {
        my $quiet = $1;

        # Check syntax for merge_feature.
        unless ($message->test_personalize($list)) {
            $log->syslog(
                'err',
                'Failed to personalize. Message %s for list %s was rejected',
                $message,
                $list
            );
            Sympa::send_dsn($list, $message, {}, '5.6.5');
            return undef;
        }

        my $key = Sympa::List::send_confirm_to_editor($message, 'smtp');

        unless (defined $key) {
            $log->syslog(
                'err',
                'Failed to send moderation request of %s from %s for list %s to editor(s)',
                $message,
                $sender,
                $list
            );
            Sympa::Report::reject_report_msg(
                'intern',
                'The request moderation sending to moderator failed.',
                $sender,
                {'msg_id' => $messageid, 'message' => $message},
                $list->{'domain'},
                $msg_string,
                $list
            );
            $log->db_log(
                'robot'        => $list->{'domain'},
                'list'         => $list->{'name'},
                'action'       => 'DoMessage',
                'parameters'   => $message->get_id,
                'target_email' => '',
                'msg_id'       => $messageid,
                'status'       => 'error',
                'error_type'   => 'internal',
                'user_email'   => $sender
            );
            return undef;
        }

        $log->syslog('info', 'Message %s for list %s from %s sent to editors',
            $message, $list, $sender);

        # Do not report to the sender if the message was tagged as a spam.
        unless ($quiet or $message->{'spam_status'} eq 'spam') {
            Sympa::Report::notice_report_msg('moderating_message', $sender,
                {'message' => $message},
                $list->{'domain'}, $list);
        }
        return 1;
    } elsif ($action =~ /^reject\b(?:\s*,\s*(quiet))?/) {
        my $quiet = $1;

        $log->syslog(
            'notice',
            'Message %s for %s from %s rejected(%s) because sender not allowed',
            $message,
            $list,
            $sender,
            $result->{'tt2'}
        );

        # Do not report to the sender if the message was tagged as a spam.
        unless ($quiet or $message->{'spam_status'} eq 'spam') {
            if (defined $result->{'tt2'}) {
                unless (
                    Sympa::send_file(
                        $list, $result->{'tt2'},
                        $sender, {auto_submitted => 'auto-replied'}
                    )
                    ) {
                    $log->syslog('notice',
                        'Unable to send template "%s" to %s',
                        $result->{'tt2'}, $sender);
                    Sympa::Report::reject_report_msg('auth',
                        $result->{'reason'}, $sender, {'message' => $message},
                        $list->{'domain'}, $msg_string, $list);
                }
            } else {
                Sympa::Report::reject_report_msg('auth', $result->{'reason'},
                    $sender, {'message' => $message},
                    $list->{'domain'}, $msg_string, $list);
            }
        }
        $log->db_log(
            'robot'        => $list->{'domain'},
            'list'         => $list->{'name'},
            'action'       => 'DoMessage',
            'parameters'   => $message->get_id,
            'target_email' => '',
            'msg_id'       => $messageid,
            'status'       => 'error',
            'error_type'   => 'rejected_authorization',
            'user_email'   => $sender
        );
        return undef;
    } else {
        $log->syslog('err',
            'Unknown action %s returned by the scenario "send"', $action);
        Sympa::Report::reject_report_msg(
            'intern',
            'Unknown action returned by the scenario "send"',
            $sender,
            {'msg_id' => $messageid, 'message' => $message},
            $list->{'domain'},
            $msg_string,
            $list
        );
        $log->db_log(
            'robot'        => $list->{'domain'},
            'list'         => $list->{'name'},
            'action'       => 'DoMessage',
            'parameters'   => $message->get_id,
            'target_email' => '',
            'msg_id'       => $messageid,
            'status'       => 'error',
            'error_type'   => 'internal',
            'user_email'   => $sender
        );
        return undef;
    }
}

# Checks command in subject or body of the message.
# If there are any commands in it, returns string.  Otherwise returns undef.
#
# Old name: tools::checkcommand(), _check_command() in sympa_msg.pl.
sub _check_command {
    my $message = shift;

    my $commands_re = $Conf::Conf{'misaddressed_commands_regexp'};
    return undef unless defined $commands_re and length $commands_re;

    # Check for commands in the subject.
    my $subject_field = $message->{'decoded_subject'};
    $subject_field = '' unless defined $subject_field;
    $subject_field =~ s/\n//mg;    # multiline subjects
    my $re_regexp = Sympa::Regexps::re();
    $subject_field =~ s/^\s*(?:$re_regexp)?\s*(.*)\s*$/$1/i;

    if ($subject_field =~ /^($commands_re)$/im) {
        return $1;
    }

    my @body = map { s/\r\n|\n//; $_ } split /(?<=\n)/,
        ($message->get_plain_body || '');

    # More than 5 lines in the text.
    return undef if scalar @body > 5;

    foreach my $line (@body) {
        if ($line =~ /^($commands_re)\b/im) {
            return $1;
        }

        # Control is only applied to first non-blank line.
        last unless $line =~ /\A\s*\z/;
    }
    return undef;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Spindle::DoMessage - Workflow to handle messages bound for lists

=head1 DESCRIPTION

L<Sympa::Spindle::DoMessage> handles a message sent to a list.

If a message has no special types (command or administrator),
message will be processed.  Otherwise messages will be skipped.

TBD

=head2 Public methods

See also L<Sympa::Spindle::Incoming/"Public methods">.

=over

=item new ( key =E<gt> value, ... )

=item spin ( )

In most cases, L<Sympa::Spindle::ProcessIncoming> splices meessages
to this class.  These methods are not used in ordinal case.

=back

=head1 SEE ALSO

L<Sympa::Message>, L<Sympa::Scenario>, L<Sympa::Spindle::ProcessIncoming>,
L<Sympa::Topic>.

=head1 HISTORY

L<Sympa::Spindle::DoMessage> appeared on Sympa 6.2.13.

=cut
