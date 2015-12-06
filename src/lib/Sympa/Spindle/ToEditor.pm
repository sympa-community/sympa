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

package Sympa::Spindle::ToEditor;

use strict;
use warnings;

use Sympa;
use Sympa::Bulk;
use Sympa::Log;
use Sympa::Message;
use Sympa::Report;

use base qw(Sympa::Spindle);

my $log = Sympa::Log->instance;

sub _twist {
    my $self    = shift;
    my $message = shift;

    my $list = $message->{context};
    my $messageid = $message->{message_id};
    my $sender = $self->{confirmed_by} || $self->{distributed_by} || $message->{sender};

        unless (_send_confirm_to_editor($message, 'smtp')) {
            $log->syslog(
                'err',
                'Failed to send moderation request of %s from %s for list %s to editor(s)',
                $message,
                $sender,
                $list
            );
        Sympa::send_notify_to_listmaster(
            $list,
            'mail_intern_error',
            {   error => 'The request moderation sending to moderator failed.',
                who    => $sender,
                msg_id => $messageid,
            }
        );
        Sympa::send_dsn($list, $message, {}, '5.3.0');
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
        unless ($self->{quiet} or $message->{'spam_status'} eq 'spam') {
            Sympa::Report::notice_report_msg('moderating_message', $sender,
                {'message' => $message},
                $list->{'domain'}, $list);
        }
        return 1;
}

# Old name: List::send_to_editor(), Sympa::List::send_confirm_to_editor().
sub _send_confirm_to_editor {
    $log->syslog('debug2', '(%s, %s)', @_);
    my $message = shift;
    #my $method  = shift;

    my ($i, @rcpt);
    my $list = $message->{context};

    @rcpt = $list->get_admins_email('receptive_editor');
    @rcpt = $list->get_admins_email('actual_editor') unless @rcpt;
    $log->syslog('notice',
        'Warning: No owner and editor defined at all in list %s', $list)
        unless @rcpt;

    # Did we find a recipient?
    unless (@rcpt) {
        $log->syslog(
            'err',
            'Impossible to send the moderation request for message %s to editors of list %s. Neither editor nor owner defined!',
            $message,
            $list
        );
        return undef;
    }

    my $param = {
        'msg_from'       => $message->{'sender'},
        'subject'        => $message->{'decoded_subject'},
        'spam_status'    => $message->{'spam_status'},
        'method'         => 'smtp',
        'request_topic'  => $list->is_there_msg_topic,
        'auto_submitted' => 'auto-generated',
    };

    my $bulk = Sympa::Bulk->new;
    foreach my $recipient (@rcpt) {
        my $new_message = $message->dup;
        if ($new_message->{'smime_crypted'}) {
            unless ($new_message->smime_encrypt($recipient)) {
                # If encryption failed, attach a generic error message:
                # X509 cert missing.
                $new_message = Sympa::Message->new_from_template(
                    $list,
                    'x509-user-cert-missing',
                    $recipient,
                    {   'mail' => {
                            'sender'  => $message->{sender},
                            'subject' => $message->{decoded_subject},
                        },
                    }
                );
            }
        }
        $param->{'msg'} = $new_message;

        my $confirm_message =
            Sympa::Message->new_from_template($list, 'moderate', $recipient,
            $param);
        if ($confirm_message) {
            # Ensure 1 second elapsed since last message
            $confirm_message->{'date'} = time + 1;
        }
        unless ($confirm_message
            and defined $bulk->store($confirm_message, $recipient)) {
            $log->syslog('notice', 'Unable to send template "moderate" to %s',
                $recipient);
            return undef;
        }
    }

    return 1;
}

1;

