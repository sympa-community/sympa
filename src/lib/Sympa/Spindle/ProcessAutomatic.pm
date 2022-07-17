# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
# Copyright 2017, 2019, 2020 The Sympa Community. See the AUTHORS.md
# file at the top-level directory of this distribution and at
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

package Sympa::Spindle::ProcessAutomatic;

use strict;
use warnings;
use English qw(-no_match_vars);
use File::Copy qw();

use Sympa;
use Conf;
use Sympa::Family;
use Sympa::List;
use Sympa::Log;
use Sympa::Mailer;
use Sympa::Spindle::ProcessRequest;
use Sympa::Spool::Incoming;
use Sympa::Spool::Listmaster;
use Sympa::Tools::Data;

use base qw(Sympa::Spindle);

my $log = Sympa::Log->instance;

use constant _distaff => 'Sympa::Spool::Automatic';

sub _init {
    my $self  = shift;
    my $state = shift;

    if ($state == 1) {
        # Process grouped notifications.
        Sympa::Spool::Listmaster->instance->flush;
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

# Old name: process_message() in sympa_automatic.pl.
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

    $robot =
        (ref $message->{context} eq 'Sympa::List')
        ? $message->{context}->{'domain'}
        : $message->{context};
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

    # Load spam status.
    $message->check_spam_status;
    # Check DKIM signatures.
    $message->check_dkim_signature;
    # Check S/MIME signature.
    $message->check_smime_signature;
    # Decrypt message.  On success, check nested S/MIME signature.
    if ($message->smime_decrypt and not $message->{'smime_signed'}) {
        $message->check_smime_signature;
    }

    # *** Now message content may be altered. ***

    # Enable SMTP logging if required.
    Sympa::Mailer->instance->{log_smtp} = $self->{log_smtp}
        || Sympa::Tools::Data::smart_eq(
        Conf::get_robot_conf($robot, 'log_smtp'), 'on');
    # setting log_level using conf unless it is set by calling option
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

    # Maybe we are an automatic list
    #_amr ici on ne doit prendre que la première ligne !
    my ($dyn_list_family, $dyn_just_created);
    # we care of fake headers. If we put it, it's the 1st one.
    $dyn_list_family = $message->{'family'};

    unless (defined $dyn_list_family and length $dyn_list_family) {
        $log->syslog(
            'err',
            'Internal server error: Automatic lists creation daemon should never proceed message %s without X-Sympa-Family header',
            $message
        );
        Sympa::send_notify_to_listmaster(
            '*',
            'intern_error',
            {   'error' =>
                    sprintf(
                    'Internal server error: Automatic lists creation daemon should never proceed message %s without X-Sympa-Family header',
                    $message)
            }
        );
        return undef;
    }
    delete $message->{'family'};

    unless (ref $list eq 'Sympa::List') {
        ## Automatic creation of a mailing list, based on a family
        my $dyn_family;
        unless ($dyn_family = Sympa::Family->new($dyn_list_family, $robot)) {
            $log->syslog(
                'err',
                'Failed to process message %s: family %s does not exist, impossible to create the dynamic list',
                $message,
                $dyn_list_family
            );
            Sympa::send_notify_to_listmaster(
                $robot,
                'automatic_list_creation_failed',
                {   'family' => $dyn_list_family,
                    'robot'  => $robot,
                    'msg_id' => $msg_id,
                }
            );
            Sympa::send_dsn($robot, $message, {}, '5.3.5');
            return undef;
        }

        my $spindle_req = Sympa::Spindle::ProcessRequest->new(
            context          => $dyn_family,
            action           => 'create_automatic_list',
            parameters       => {listname => $listname},
            sender           => $sender,
            smime_signed     => $message->{'smime_signed'},
            md5_check        => $message->{'md5_check'},
            scenario_context => {
                sender             => $sender,
                message            => $message,
                family             => $dyn_family,
                automatic_listname => $listname,
            },
        );
        unless ($spindle_req and $spindle_req->spin) {
            $log->syslog('err', 'Cannot create dynamic list %s', $listname);
            return undef;
        } elsif (
            not($spindle_req->success
                and $list = Sympa::List->new(
                    $listname,
                    $dyn_family->{'domain'},
                    {just_try => 1}
                )
            )
        ) {
            $log->syslog('err',
                'Unable to create list %s. Message %s ignored',
                $listname, $message);
            Sympa::send_notify_to_listmaster(
                $dyn_family->{'domain'},
                'automatic_list_creation_failed',
                {   'listname' => $listname,
                    'family'   => $dyn_list_family,
                    'robot'    => $robot,
                    'msg_id'   => $msg_id,
                }
            );
            Sympa::send_dsn($robot, $message, {}, '5.3.5');
            $log->db_log(
                'robot'        => $dyn_family->{'domain'},
                'list'         => $listname,
                'action'       => 'process_message',
                'parameters'   => $msg_id . "," . $dyn_family->{'domain'},
                'target_email' => '',
                'msg_id'       => $msg_id,
                'status'       => 'error',
                'error_type'   => 'internal',
                'user_email'   => $sender
            );
            return undef;
        } else {
            # Overwrite context of the message.
            $message->{context} = $list;
            $dyn_just_created = 1;
        }
    }

    if ($dyn_just_created) {
        unless (defined $list->sync_include('member')) {
            $log->syslog(
                'err',
                'Failed to synchronize list members of dynamic list %s from %s family',
                $list,
                $dyn_list_family
            );
            # As list may be purged, use robot context.
            Sympa::send_dsn($robot, $message, {}, '4.2.1');
            $log->db_log(
                'robot'        => $robot,
                'list'         => $list->{'name'},
                'action'       => 'process_message',
                'parameters'   => "",
                'target_email' => "",
                'msg_id'       => $msg_id,
                'status'       => 'error',
                'error_type'   => 'dyn_cant_sync',
                'user_email'   => $sender
            );
            # purge the unwanted empty automatic list
            if ($Conf::Conf{'automatic_list_removal'} =~ /if_empty/i) {
                Sympa::Spindle::ProcessRequest->new(
                    context          => $robot,
                    action           => 'close_list',
                    current_list     => $list,
                    mode             => 'purge',
                    scenario_context => {skip => 1},
                )->spin;
            }
            return undef;
        }
        unless ($list->get_total) {
            $log->syslog('err',
                'Dynamic list %s from %s family has ZERO subscribers',
                $list, $dyn_list_family);
            # As list may be purged, use robot context.
            Sympa::send_dsn($robot, $message, {}, '4.2.4');
            $log->db_log(
                'robot'        => $robot,
                'list'         => $list->{'name'},
                'action'       => 'process_message',
                'parameters'   => "",
                'target_email' => "",
                'msg_id'       => $msg_id,
                'status'       => 'error',
                'error_type'   => 'list_unknown',
                'user_email'   => $sender
            );
            # purge the unwanted empty automatic list
            if ($Conf::Conf{'automatic_list_removal'} =~ /if_empty/i) {
                Sympa::Spindle::ProcessRequest->new(
                    context          => $robot,
                    action           => 'close_list',
                    current_list     => $list,
                    mode             => 'purge',
                    scenario_context => {skip => 1},
                )->spin;
            }
            return undef;
        }
        $log->syslog('info',
            'Successfully create list %s with %s subscribers',
            $list, $list->get_total());
    }

    # Do not process messages in list creation.  Move them to main spool.
    my $marshalled =
        Sympa::Spool::Incoming->new->store($message, original => 1);
    if ($marshalled) {
        $log->syslog('notice',
            'Message %s is stored into incoming spool as <%s>',
            $message, $marshalled);
    } else {
        $log->syslog(
            'err',
            'Unable to move in spool for processing message %s to list %s (daemon_usage = creation)',
            $message,
            $list
        );
        Sympa::send_notify_to_listmaster($list, 'mail_intern_error',
            {error => '', who => $sender, msg_id => $msg_id,});
        Sympa::send_dsn($list, $message, {}, '5.3.0');
        return undef;
    }

    return 1;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Spindle::ProcessAutomatic - Workflow of automatic list creation

=head1 SYNOPSIS

  use Sympa::Spindle::ProcessAutomatic;

  my $spindle = Sympa::Spindle::ProcessAutomatic->new;
  $spindle->spin;

=head1 DESCRIPTION

L<Sympa::Spindle::ProcessAutomatic> defines workflow to process messages
for automatic list creation.

When spin() method is invoked, it reads the messages in automatic spool.
If the list a message is bound for has not been there and list creation is
authorized, it will be created.  Then the message is stored into incoming
message spool again and waits for processing by
L<Sympa::Spindle::ProcessIncoming>.

Order to process messages in source spool are controlled by modification time
of files and delivery date.
Some messages are skipped according to these priorities
(See L<Sympa::Spool::Automatic>):

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

=item new ( [ keepcopy =E<gt> $directory ],
[ log_level =E<gt> $level ],
[ log_smtp =E<gt> 0|1 ] )

=item spin ( )

new() may take following options:

=over

=item keepcopy =E<gt> $directory

spin() keeps copy of successfully processed messages in $directory.

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

Instance of L<Sympa::Spool::Automatic> class.

=back

=head1 SEE ALSO

L<Sympa::Message>,
L<Sympa::Spindle>, L<Sympa::Spool::Automatic>, L<Sympa::Spool::Incoming>.

=head1 HISTORY

L<Sympa::Spindle::ProcessAutomatic> appeared on Sympa 6.2.10.

=cut
