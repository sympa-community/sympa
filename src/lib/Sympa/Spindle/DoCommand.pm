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
use Sympa::Commands;
use Conf;
use Sympa::Log;
use Sympa::Regexps;
use Sympa::Report;

use base qw(Sympa::Spindle::ProcessIncoming);

my $log = Sympa::Log->instance;

# Old name: DoCommand() in sympa_msg.pl.
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

    my $status = _do_command($message);

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

# Private subroutines.

# Old name: (part of) DoCommand() in sympa_msg.pl.
sub _do_command {
    my $message = shift;

    my ($list, $robot);
    if (ref $message->{context} eq 'Sympa::List') {
        $list  = $message->{context};
        $robot = $list->{'domain'};
    } elsif ($message->{context} and $message->{context} ne '*') {
        $robot = $message->{context};
    } else {
        $robot = '*';
    }

    my $success;
    my $cmd_found = 0;
    my $messageid = $message->{message_id};
    my $sender    = $message->{sender};

    # If type is subscribe or unsubscribe, parse as a single command.
    if (   $message->{listtype} eq 'subscribe'
        or $message->{listtype} eq 'unsubscribe') {
        $log->syslog('debug', 'Processing message for %s type %s',
            $message->{context}, $message->{listtype});
        # FIXME: at this point $message->{'dkim_pass'} does not verify that
        # Subject: is part of the signature. It SHOULD !
        my $auth_level = $message->{'dkim_pass'} ? 'dkim' : undef;

        Sympa::Commands::parse($robot,
            sprintf('%s %s', $message->{listtype}, $list->{'name'}),
            $auth_level, $message);
        $log->db_log(
            'robot'        => $robot,
            'list'         => $list->{'name'},
            'action'       => 'DoCommand',
            'parameters'   => $message->get_id,
            'target_email' => '',
            'msg_id'       => $messageid,
            'status'       => 'success',
            'error_type'   => '',
            'user_email'   => $sender
        );
        return 1;
    }

    ## Process the Subject of the message
    ## Search and process a command in the Subject field
    my $subject_field = $message->{'decoded_subject'};
    $subject_field = '' unless defined $subject_field;
    $subject_field =~ s/\n//mg;    ## multiline subjects
    my $re_regexp = Sympa::Regexps::re();
    $subject_field =~ s/^\s*(?:$re_regexp)?\s*(.*)\s*$/$1/i;

    #FIXME
    my $auth_level =
          $message->{'smime_signed'} ? 'smime'
        : $message->{'dkim_pass'}    ? 'dkim'
        :                              undef;

    if (defined $subject_field and $subject_field =~ /\S/) {
        $success ||=
            Sympa::Commands::parse($robot, $subject_field, $auth_level,
            $message);
        unless ($success and $success eq 'unknown_cmd') {
            $cmd_found = 1;
        }
    }

    my $line;
    my $size;

    ## Process the body of the message
    ## unless subject contained commands or message has no body
    unless ($cmd_found) {
        my $body = $message->get_plain_body;
        unless (defined $body) {
            $log->syslog('err', 'Could not change multipart to singlepart');
            Sympa::Report::global_report_cmd('user', 'error_content_type',
                {});
            $log->db_log(
                'robot' => $robot,
                #'list'         => 'sympa',
                'action'       => 'DoCommand',
                'parameters'   => $message->get_id,
                'target_email' => '',
                'msg_id'       => $messageid,
                'status'       => 'error',
                'error_type'   => 'error_content_type',
                'user_email'   => $sender
            );
            return $success ? 1 : undef;
        }

        foreach $line (split /\r\n|\r|\n/, $body) {
            last if $line =~ /^-- $/;    # Ignore signature.
            $line =~ s/^\s*>?\s*(.*)\s*$/$1/g;
            next unless length $line;    # Skip empty lines.
            next if $line =~ /^\s*\#/;

            #FIXME
            $auth_level =
                  $message->{'smime_signed'} ? 'smime'
                : $message->{'dkim_pass'}    ? 'dkim'
                :                              $auth_level;
            my $status =
                Sympa::Commands::parse($robot, $line, $auth_level, $message);

            $cmd_found = 1;    # if problem no_cmd_understood is sent here
            if ($status eq 'unknown_cmd') {
                $log->syslog('notice', 'Unknown command found: %s', $line);
                Sympa::Report::reject_report_cmd(
                    {cmd_line => $line, context => $robot},
                    'user', 'not_understood');
                $log->db_log(
                    'robot' => $robot,
                    #'list'         => 'sympa',
                    'action'       => 'DoCommand',
                    'parameters'   => $message->get_id,
                    'target_email' => '',
                    'msg_id'       => $messageid,
                    'status'       => 'error',
                    'error_type'   => 'not_understood',
                    'user_email'   => $sender
                );
                last;
            }
            if ($line =~ /^(quit|end|stop|-)\s*$/io) {
                last;
            }

            $success ||= $status;
        }
    }

    ## No command found
    unless ($cmd_found) {
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
        return undef;
    }

    return $success ? 1 : undef;
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

L<Sympa::Commands>, L<Sympa::Message>, L<Sympa::Spindle::ProcessIncoming>.

=head1 HISTORY

L<Sympa::Spindle::DoCommand> appeared on Sympa 6.2.13.

=cut
