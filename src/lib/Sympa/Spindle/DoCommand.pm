# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016 GIP RENATER
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

package Sympa::Spindle::DoCommand;

use strict;
use warnings;
use English qw(-no_match_vars);

use Sympa;
use Conf;
use Sympa::Log;
use Sympa::Report;
use Sympa::Spindle::ProcessMessage;

use base qw(Sympa::Spindle::ProcessIncoming);    # Derives _splicing_to().

my $log = Sympa::Log->instance;

# Old name: (part of) DoCommand() in sympa_msg.pl.
# Partially moved to Sympa::Request::Message::_load().
sub _twist {
    my $self    = shift;
    my $message = shift;

    # Fail-safe: Skip messages with unwanted types.
    return 0 unless $self->_splicing_to($message) eq __PACKAGE__;

    my ($list, $robot);
    if (ref $message->{context} eq 'Sympa::List') {
        $list  = $message->{context};
        $robot = $list->{'domain'};
    } elsif ($message->{context} and $message->{context} ne '*') {
        $robot = $message->{context};
    } else {
        $robot = '*';
    }

    my $messageid = $message->{'message_id'};

    $log->syslog(
        'debug',
        "Processing command with priority %s, %s",
        $Conf::Conf{'sympa_priority'}, $messageid
    );

    my $sender = $message->{'sender'};

    if ($message->{'spam_status'} eq 'spam') {
        $log->syslog(
            'notice',
            'Message for %s ignored, because tagged as spam (message ID: %s)',
            $message->{context},
            $messageid
        );
        return undef;
    }

    ## Detect loops
    if ($self->{_msgid}{'sympa@' . $robot}{$messageid}) {
        $log->syslog('err',
            'Found known Message-ID, ignoring command which would cause a loop'
        );
        $log->db_log(
            'robot' => $robot,
            #'list'         => 'sympa',
            'action'       => 'DoCommand',
            'parameters'   => $message->get_id,
            'target_email' => '',
            'msg_id'       => $messageid,
            'status'       => 'error',
            'error_type'   => 'known_message',
            'user_email'   => $sender
        );
        # Clean old files from spool.
        return undef;
    }
    # Keep track of known message IDs...if any.
    $self->{_msgid}{'sympa@' . $robot}{$messageid} = time;

    # Initialize command report.
    Sympa::Report::init_report_cmd();

    my $spindle_message =
        Sympa::Spindle::ProcessMessage->new(message => $message);
    unless ($spindle_message and $spindle_message->spin) {
        # No command found.
        $log->syslog('info', "No command found in message");
        Sympa::Report::global_report_cmd('user', 'no_cmd_found', {});
        $log->db_log(
            'robot' => $robot,
            #'list'         => 'sympa',
            'action'       => 'DoCommand',
            'parameters'   => $message->get_id,
            'target_email' => '',
            'msg_id'       => $messageid,
            'status'       => 'error',
            'error_type'   => 'no_cmd_found',
            'user_email'   => $sender
        );
    }
    my $status = $spindle_message->{success} if $spindle_message;

    # Mail back the result.
    if (Sympa::Report::is_there_any_report_cmd()) {
        ## Loop prevention

        ## Count reports sent to $sender
        $self->{_loop_info}{$sender}{'count'}++;

        ## Sampling delay
        if ((time - ($self->{_loop_info}{$sender}{'date_init'} || 0)) <
            $Conf::Conf{'loop_command_sampling_delay'}) {

            # Notify listmaster of first rejection.
            if ($self->{_loop_info}{$sender}{'count'} ==
                $Conf::Conf{'loop_command_max'}) {
                ## Notify listmaster
                Sympa::send_notify_to_listmaster($robot, 'loop_command',
                    {'msg' => $message});
            }

            # Too many reports sent => message skipped !!
            if ($self->{_loop_info}{$sender}{'count'} >=
                $Conf::Conf{'loop_command_max'}) {
                $log->syslog(
                    'err',
                    'Ignoring message which would cause a loop, %d messages sent to %s; loop_command_max exceeded',
                    $self->{_loop_info}{$sender}{'count'},
                    $sender
                );

                return undef;
            }
        } else {
            # Sampling delay is over, reinit.
            $self->{_loop_info}{$sender}{'date_init'} = time;

            # We apply Decrease factor if a loop occurred.
            $self->{_loop_info}{$sender}{'count'} *=
                $Conf::Conf{'loop_command_decrease_factor'};
        }

        ## Send the reply message
        Sympa::Report::send_report_cmd($sender, $robot);
        $log->db_log(
            'robot' => $robot,
            #'list'         => 'sympa',
            'action'       => 'DoCommand',
            'parameters'   => $message->get_id,
            'target_email' => "",
            'msg_id'       => $message->{message_id},
            'status'       => 'success',
            'error_type'   => '',
            'user_email'   => $sender
        );

    }

    return $status;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Spindle::DoCommand - Workflow to handle command messages

=head1 DESCRIPTION

L<Sympa::Spindle::DoCommand> handles command messages bound for sympa,
[list]-subscribe or [list]-unsubscribe address.

If a message has one of types above, commands in the message will be parsed
and executed.  Otherwise messages will be skipped.

=head2 Public methods

See also L<Sympa::Spindle::Incoming/"Public methods">.

=over

=item new ( key =E<gt> value, ... )

=item spin ( )

In most cases, L<Sympa::Spindle::ProcessIncoming> splices meessages
to this class.  These methods are not used in ordinal case.

=back

=head1 SEE ALSO

L<Sympa::Message>, L<Sympa::Spindle::ProcessIncoming>,
L<Sympa::Spindle::ProcessMessage>.

=head1 HISTORY

L<Sympa::Spindle::DoCommand> appeared on Sympa 6.2.13.

=cut
