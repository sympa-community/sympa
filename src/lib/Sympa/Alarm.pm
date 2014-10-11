# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014 GIP RENATER
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

package Sympa::Alarm;

use strict;
use warnings;

use Sympa::Bulk;
use Conf;
use Log;
use Sympa::Mailer;
use Sympa::Message;
use tools;

our $use_bulk;    #FIXME: Instantiate Sympa::Alarm instead.
our %listmaster_messages_stack;

my $mailer = Sympa::Mailer->instance;

sub store {
    my $message   = shift;
    my $operation = shift;

    my $email = $message->{rcpt};

    my $robot_id;
    if (ref $message->{context} eq 'Sympa::List') {
        $robot_id = $message->{context}->{'domain'};
    } elsif ($message->{context} and $message->{context} ne '*') {
        $robot_id = $message->{context};
    } else {
        $robot_id = '*';
    }

    $listmaster_messages_stack{$robot_id}{$operation}{'first'} = time
        unless $listmaster_messages_stack{$robot_id}{$operation}{'first'};
    $listmaster_messages_stack{$robot_id}{$operation}{'counter'}++;
    $listmaster_messages_stack{$robot_id}{$operation}{'last'} = time;

    if ($listmaster_messages_stack{$robot_id}{$operation}{'counter'} > 3) {
        # stack if too much messages w/ same code
        Log::do_log('info', 'Stacking message about "%s" for %s (%s)',
            $operation, $email, $robot_id)
            unless $operation eq 'logs_failed';
        push @{$listmaster_messages_stack{$robot_id}{$operation}{'messages'}
                {$email}}, $message->as_string;
        return 1;
    } else {
        # Overwrite envelope sender
        $message->{envelope_sender} =
            Conf::get_robot_conf($robot_id, 'request');
        #FIXME: Priority would better to be '0', isn't it?
        $message->{priority} =
            Conf::get_robot_conf($robot_id, 'sympa_priority');

        if ($use_bulk) {
            return Sympa::Bulk::store($message, $email);
        } else {
            return $mailer->store($message, $email);
        }
    }
}

sub flush {
    my $purge = shift;

    foreach my $robot_id (keys %listmaster_messages_stack) {
        foreach my $operation (keys %{$listmaster_messages_stack{$robot_id}})
        {
            my $first_age = time -
                $listmaster_messages_stack{$robot_id}{$operation}{'first'};
            my $last_age = time -
                $listmaster_messages_stack{$robot_id}{$operation}{'last'};
            # not old enough to send and first not too old
            next
                unless $purge
                    or $last_age > 30
                    or $first_age > 60;
            next
                unless $listmaster_messages_stack{$robot_id}{$operation}
                {'messages'};

            my %messages =
                %{$listmaster_messages_stack{$robot_id}{$operation}
                    {'messages'}};
            Log::do_log(
                'info', 'Got messages about "%s" (%s)',
                $operation, join(', ', keys %messages)
            );

            ##### bulk send
            foreach my $email (keys %messages) {
                my $param = {
                    to                    => $email,
                    auto_submitted        => 'auto-generated',
                    operation             => $operation,
                    notification_messages => $messages{$email},
                    boundary              => '----------=_'
                        . tools::get_message_id($robot_id)
                };

                Log::do_log('info', 'Send messages to %s', $email);

                # Skip DB access because DB is not accessible
                $email = [$email]
                    if not ref $email
                        and (  $operation eq 'no_db'
                            or $operation eq 'db_restored');

                my $message =
                    Sympa::Message->new_from_template($robot_id,
                    'listmaster_groupednotifications',
                    $email, $param);
                unless ($message) {
                    Log::do_log(
                        'notice',
                        'Unable to send template "listmaster_groupnotification" to %s listmaster %s',
                        $robot_id,
                        $email
                    ) unless $operation eq 'logs_failed';
                    return undef;
                }
                my $status;
                if ($use_bulk) {
                    $status = Sympa::Bulk::store($message, $email);
                } else {
                    $status = $mailer->store($message, $email);
                }
                unless (defined $status) {
                    Log::do_log(
                        'notice',
                        'Unable to send template "listmaster_groupnotification" to %s listmaster %s',
                        $robot_id,
                        $email
                    ) unless $operation eq 'logs_failed';
                    return undef;
                }
            }

            Log::do_log('info', 'Cleaning stacked notifications');
            delete $listmaster_messages_stack{$robot_id}{$operation};
        }
    }
    return 1;
}

1;

__END__

=encoding utf-8

=head1 NAME

Sympa::Alarm - Spool on memory for listmaster notification

=head1 SYNOPSIS

    use Sympa::Alarm;
    
    Sympa::Alarm::store($message, $operation);
    
    Sympa::Alarm::flush();
    Sympa::Alarm::flush(1);

=head1 DESCRIPTION

L<Sympa::Alarm> implements on-memory spool for listmaster notification.

=head2 Functions

=over

=item store ( $message, $operation )

Stores a message of a operation to spool.

Parameters:

=over

=item $message

L<Sympa::Message> object to be stored.

=item $operation

A string specifys tag of the message.

=back

Returns:

True value if succeed, otherwise C<undef>.

=item flush ( [ purge ] )

Sends compiled messages in spool.

If true value is given as optional argument, all messages in spool will be
sent.

=back

=head1 HISTORY

L<Sympa::Alarm> appeared on Sympa 6.2.

=cut
