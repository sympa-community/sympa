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

use base qw(Class::Singleton);

my $mailer = Sympa::Mailer->instance;

# Constructor for Class::Singleton.
sub _new_instance {
    my $class = shift;

    bless {
        use_bulk => undef,
        stack    => {},
    };
}

sub store {
    my $self    = shift;
    my $message = shift;
    my $rcpt    = shift;
    my %options = @_;

    my $use_bulk  = $self->{use_bulk};
    my $operation = $options{operation};

    my $robot_id;
    if (ref $message->{context} eq 'Sympa::List') {
        $robot_id = $message->{context}->{'domain'};
    } elsif ($message->{context} and $message->{context} ne '*') {
        $robot_id = $message->{context};
    } else {
        $robot_id = '*';
    }

    $self->{stack}->{$robot_id}{$operation}{'first'} = time
        unless $self->{stack}->{$robot_id}{$operation}{'first'};
    $self->{stack}->{$robot_id}{$operation}{'counter'}++;
    $self->{stack}->{$robot_id}{$operation}{'last'} = time;

    if ($self->{stack}->{$robot_id}{$operation}{'counter'} > 3) {
        my @rcpts = ref $rcpt ? @$rcpt : ($rcpt);

        # stack if too much messages w/ same code
        Log::do_log('info', 'Stacking message about "%s" for %s (%s)',
            $operation, join(', ', @rcpts), $robot_id)
            unless $operation eq 'logs_failed';
        foreach my $rcpt (@rcpts) {
            push
                @{$self->{stack}->{$robot_id}{$operation}{'messages'}{$rcpt}},
                $message->as_string;
        }
        return 1;
    } else {
        # Overwrite envelope sender
        $message->{envelope_sender} =
            Conf::get_robot_conf($robot_id, 'request');
        #FIXME: Priority would better to be '0', isn't it?
        $message->{priority} =
            Conf::get_robot_conf($robot_id, 'sympa_priority');

        if ($use_bulk) {
            return Sympa::Bulk::store($message, $rcpt);
        } else {
            return $mailer->store($message, $rcpt);
        }
    }
}

sub flush {
    my $self    = shift;
    my %options = @_;

    my $use_bulk = $self->{use_bulk};
    my $purge    = $options{purge};

    foreach my $robot_id (keys %{$self->{stack}}) {
        foreach my $operation (keys %{$self->{stack}->{$robot_id}}) {
            my $first_age =
                time - $self->{stack}->{$robot_id}{$operation}{'first'};
            my $last_age =
                time - $self->{stack}->{$robot_id}{$operation}{'last'};
            # not old enough to send and first not too old
            next
                unless $purge
                    or $last_age > 30
                    or $first_age > 60;
            next
                unless $self->{stack}->{$robot_id}{$operation}{'messages'};

            my %messages =
                %{$self->{stack}->{$robot_id}{$operation}{'messages'}};
            Log::do_log(
                'info', 'Got messages about "%s" (%s)',
                $operation, join(', ', keys %messages)
            );

            ##### bulk send
            foreach my $rcpt (keys %messages) {
                my $param = {
                    to                    => $rcpt,
                    auto_submitted        => 'auto-generated',
                    operation             => $operation,
                    notification_messages => $messages{$rcpt},
                    boundary              => '----------=_'
                        . tools::get_message_id($robot_id)
                };

                Log::do_log('info', 'Send messages to %s', $rcpt);

                # Skip DB access because DB is not accessible
                $rcpt = [$rcpt]
                    if $operation eq 'no_db'
                        or $operation eq 'db_restored';

                my $message =
                    Sympa::Message->new_from_template($robot_id,
                    'listmaster_groupednotifications',
                    $rcpt, $param);
                unless ($message) {
                    Log::do_log(
                        'notice',
                        'Unable to send template "listmaster_groupnotification" to %s listmaster %s',
                        $robot_id,
                        $rcpt
                    ) unless $operation eq 'logs_failed';
                    return undef;
                }
                my $status;
                if ($use_bulk) {
                    $status = Sympa::Bulk::store($message, $rcpt);
                } else {
                    $status = $mailer->store($message, $rcpt);
                }
                unless (defined $status) {
                    Log::do_log(
                        'notice',
                        'Unable to send template "listmaster_groupnotification" to %s listmaster %s',
                        $robot_id,
                        $rcpt
                    ) unless $operation eq 'logs_failed';
                    return undef;
                }
            }

            Log::do_log('info', 'Cleaning stacked notifications');
            delete $self->{stack}->{$robot_id}{$operation};
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
    
    Sympa::Alarm->instance->store($message, $rcpt, $operation);
    
    Sympa::Alarm->instance->flush();
    Sympa::Alarm->instance->flush(purge => 1);

=head1 DESCRIPTION

L<Sympa::Alarm> implements on-memory spool for listmaster notification.

=head2 Methods

=over

=item instance ( )

I<Constructor>.
Creates a singleton instance of L<Sympa::Alarm> object.

Returns:

A new L<Sympa::Alarm> instance, or undef for failure.

=item store ( $message, $rcpt, operation => $operation )

I<Instance method>.
Stores a message of a operation to spool.

Parameters:

=over

=item $message

L<Sympa::Message> object to be stored.

=item $rcpt

Arrayref or scalar.  Recipient of notification.

=item operation => $operation

A string specifys tag of the message.

=back

Returns:

True value if succeed, otherwise C<undef>.

=item flush ( [ purge => $purge ] )

I<Instance method>.
Sends compiled messages in spool.

If true value is given as optional argument, all messages in spool will be
sent.

=back

=head2 Attributes

The instance of L<Sympa::Alarm> has followin attribute.

=over

=item {use_bulk}

If set to be true, messages to be sent will be stored into spool
instead of being stored to sendmail.

Default is false.

=back

=head1 HISTORY

L<Sympa::Alarm> appeared on Sympa 6.2.

=cut
