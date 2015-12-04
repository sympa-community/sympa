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

package Sympa::Spindle::AuthorizeMessage;

use strict;
use warnings;

use Sympa;
use Sympa::List;
use Sympa::Log;
use Sympa::Report;
use Sympa::Scenario;
use Sympa::Tools::Data;
use Sympa::Topic;

use base qw(Sympa::Spindle);

my $log = Sympa::Log->instance;

# Old name: (part of) DoMessage() in sympa_msg.pl.
sub _twist {
    my $self    = shift;
    my $message = shift;

    my $list       = $message->{context};
    my $messageid  = $message->{message_id};
    my $msg_string = $message->as_string;

    # Now check if the sender is an authorized address.
    my $sender = $message->{sender};

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
            time - $self->{start_time},
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

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Spindle::AuthorizeMessage - Workflow to authorize messages

=head1 DESCRIPTION

L<Sympa::Spindle::AuthorizeMessage> authorizes messages and stores them
into confirmation spool, moderation spool or the lists.

TBD

=head2 Public methods

See also L<Sympa::Spindle/"Public methods">.

=over

=item new ( key =E<gt> value, ... )

In most cases, L<Sympa::Spindle::DoMessage>
splices meessages to this class.  This method is not used in ordinal case.

=item spin ( )

Not implemented.

=back

=head1 SEE ALSO

L<Sympa::Message>, L<Sympa::Scenario>, L<Sympa::Spindle::DoMessage>,
L<Sympa::Topic>.

=head1 HISTORY

L<Sympa::Spindle::AuthorizeMessage> appeared on Sympa 6.2.13.

=cut
