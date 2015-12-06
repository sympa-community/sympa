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

package Sympa::Spindle::ToHeld;

use strict;
use warnings;
use Time::HiRes qw();

use Sympa;
use Sympa::Bulk;
use Sympa::Log;
use Sympa::Message;
use Sympa::Spool::Held;

use base qw(Sympa::Spindle);

my $log = Sympa::Log->instance;

sub _twist {
    my $self    = shift;
    my $message = shift;

    my $list      = $message->{context};
    my $messageid = $message->{message_id};
    my $sender =
           $self->{confirmed_by}
        || $self->{distributed_by}
        || $message->{sender};

    my $key = _send_confirm_to_sender($message);

    unless (defined $key) {
        $log->syslog('err',
            'Failed to send confirmation of %s for %s to sender %s',
            $message, $list, $sender);
        Sympa::send_notify_to_listmaster(
            $list,
            'mail_intern_error',
            {   error  => 'The request authentication sending failed',
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
    $log->syslog(
        'notice',
        'Message %s for %s from %s kept for authentication with key %s (%.2f seconds)',
        $message,
        $list,
        $sender,
        $key,
        Time::HiRes::time() - $self->{start_time}
    );
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
}

# Old name: List::send_auth(), Sympa::List::send_confirm_to_sender().
sub _send_confirm_to_sender {
    $log->syslog('debug3', '(%s)', @_);
    my $message = shift;

    my $list   = $message->{context};
    my $sender = $message->{'sender'};

    my ($i, @rcpt);
    my $spool_held = Sympa::Spool::Held->new;
    # If crypted, store the crypted form of the message.
    my $authkey = $spool_held->store($message, original => 1);
    unless ($authkey) {
        $log->syslog('err', 'Cannot create authkey of message %s for %s',
            $message, $list);
        return undef;
    }

    my $param = {
        'authkey'        => $authkey,
        'msg'            => $message->as_string(original => 1),    # encrypted
        'request_topic'  => $list->is_there_msg_topic,
        'auto_submitted' => 'auto-replied',
        #'file' => $message->{'filename'},    # obsoleted (<=6.1)
    };

    my $confirm_message =
        Sympa::Message->new_from_template($list, 'send_auth', $sender,
        $param);
    if ($confirm_message) {
        # Ensure 1 second elapsed since last message
        $confirm_message->{'date'} = time + 1;
    }
    unless ($confirm_message
        and defined Sympa::Bulk->new->store($confirm_message, $sender)) {
        $log->syslog('notice', 'Unable to send template "send_auth" to %s',
            $sender);
        return undef;
    }

    return $authkey;
}

1;
