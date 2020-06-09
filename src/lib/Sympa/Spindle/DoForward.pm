# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
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

package Sympa::Spindle::DoForward;

use strict;
use warnings;

use Sympa;
use Conf;
use Sympa::Log;
use Sympa::Mailer;

use base qw(Sympa::Spindle::ProcessIncoming);

my $log = Sympa::Log->instance;

# Old name: DoForward() in sympa_msg.pl.
sub _twist {
    my $self    = shift;
    my $message = shift;

    # Fail-safe: Skip messages with unwanted types.
    return 0 unless $self->_splicing_to($message) eq __PACKAGE__;

    my ($name, $robot);
    if (ref $message->{context} eq 'Sympa::List') {
        $name  = $message->{context}->{'name'};
        $robot = $message->{context}->{'domain'};
    } elsif ($message->{context} and $message->{context} ne '*') {
        $name  = 'sympa';
        $robot = $message->{context};
    } else {
        $name  = 'sympa';
        $robot = $Conf::Conf{'domain'};
    }
    my $function = $message->{listtype};

    my $messageid = $message->{message_id};
    my $sender    = $message->{sender};

    if ($message->{'spam_status'} eq 'spam') {
        $log->syslog(
            'notice',
            'Message for %s-%s ignored, because tagued as spam (message ID: %s)',
            $name,
            $function,
            $messageid
        );
        return undef;
    }

    # Search for the list.
    my ($list, $recipient, $priority);

    if ($function eq 'listmaster') {
        $recipient = Sympa::get_address($robot, 'listmaster');
        $priority = 0;
    } else {
        $list = $message->{context};
        unless (ref $list eq 'Sympa::List') {
            $log->syslog(
                'notice',
                'Message for %s function %s ignored, unknown list %s (message ID: %s)',
                $name,
                $function,
                $name,
                $messageid
            );
            Sympa::send_dsn($message->{context} || '*', $message, {},
                '5.1.1');
            return undef;
        }

        $recipient = Sympa::get_address($list, $function);
        $priority = $list->{'admin'}{'priority'};
    }

    my @rcpt;

    $log->syslog('info',
        'Processing %s; message_id=%s; priority=%s; recipient=%s',
        $message, $messageid, $priority, $recipient);

    delete $message->{'rcpt'};
    delete $message->{'family'};

    if ($function eq 'listmaster') {
        @rcpt = Sympa::get_listmasters_email($robot);
        $log->syslog('notice',
            'No listmaster defined; incoming message is rejected')
            unless @rcpt;
    } elsif ($function eq 'owner') {    # -request
        @rcpt = $list->get_admins_email('receptive_owner');
        @rcpt = $list->get_admins_email('owner') unless @rcpt;
        $log->syslog(
            'notice',
            'No owner defined at all in list %s; incoming message is rejected',
            $name
        ) unless @rcpt;
    } elsif ($function eq 'editor') {
        @rcpt = $list->get_admins_email('receptive_editor');
        @rcpt = $list->get_admins_email('actual_editor') unless @rcpt;
        $log->syslog(
            'notice',
            'No owner and editor defined at all in list %s; incoming message is rejected',
            $name
        ) unless @rcpt;
    }

    # Did we find a recipient?
    # If not, send back DSN to original sender to notify failure.
    unless (@rcpt) {
        Sympa::send_notify_to_listmaster(
            $message->{context} || '*',
            'mail_intern_error',
            {   error => sprintf(
                    'Impossible to forward a message to %s function %s : undefined in this list',
                    $name, $function
                ),
                who      => $sender,
                msg_id   => $messageid,
                entry    => 'forward',
                function => $function,
            }
        );
        Sympa::send_dsn(
            $message->{context} || '*', $message,
            {function => $function}, '5.2.4'
        );
        $log->db_log(
            'robot'        => $robot,
            'list'         => $list->{'name'},
            'action'       => 'DoForward',
            'parameters'   => "$name,$function",
            'target_email' => '',
            'msg_id'       => $messageid,
            'status'       => 'error',
            'error_type'   => 'internal',
            'user_email'   => $sender
        );
        return undef;
    }

    # Add or remove several headers to forward message safely.
    # - Add X-Loop: field to mitigate mail looping.
    # - The Sender: field should be added (overwritten) at least for Sender ID
    #   (a.k.a. SPF 2.0) compatibility.  Note that Resent-Sender: field will
    #   be removed.
    # - Apply DMARC protection if needed.
    #FIXME: Existing DKIM signature depends on these headers will be broken.
    #FIXME: Currently messages via -request and -editor addresses will be
    #       protected against DMARC if neccessary.  The listmaster address
    #       would be protected, too.
    $message->add_header('X-Loop', $recipient);
    $message->replace_header('Sender', Sympa::get_address($robot, 'owner'));
    $message->delete_header('Resent-Sender');
    if ($function eq 'owner' or $function eq 'editor') {
        $message->dmarc_protect if $list;
    }

    # Overwrite envelope sender.  It is REQUIRED for delivery.
    $message->{envelope_sender} = Sympa::get_address($robot, 'owner');

    unless (defined Sympa::Mailer->instance->store($message, \@rcpt)) {
        $log->syslog('err', 'Impossible to forward mail for %s function %s',
            $name, $function);
        Sympa::send_notify_to_listmaster(
            $message->{context} || '*',
            'mail_intern_error',
            {   error => sprintf(
                    'Impossible to forward a message for %s function %s',
                    $name, $function
                ),
                who      => $sender,
                msg_id   => $messageid,
                entry    => 'forward',
                function => $function,
            }
        );
        Sympa::send_dsn($message->{context} || '*', $message, {}, '5.3.0');
        $log->db_log(
            'robot'        => $robot,
            'list'         => $list->{'name'},
            'action'       => 'DoForward',
            'parameters'   => "$name,$function",
            'target_email' => '',
            'msg_id'       => $messageid,
            'status'       => 'error',
            'error_type'   => 'internal',
            'user_email'   => $sender
        );
        return undef;
    }
    $log->db_log(
        'robot'        => $robot,
        'list'         => $list->{'name'},
        'action'       => 'DoForward',
        'parameters'   => "$name,$function",
        'target_email' => '',
        'msg_id'       => $messageid,
        'status'       => 'success',
        'error_type'   => '',
        'user_email'   => $sender
    );

    return 1;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Spindle::DoForward - Workflow to forward messages to administrators

=head1 DESCRIPTION

L<Sympa::Spindle::DoForward> handles a message sent to [list]-editor (the list
editor), [list]-request (the list owner) or the listmaster.

If a message has one of types above, message will be forwarded to the users
according to types using mailer directly (See L<Sympa::Mailer>).
Otherwise messages will be skipped.

=head2 Public methods

See also L<Sympa::Spindle::ProcessIncoming/"Public methods">.

=over

=item new ( key =E<gt> value, ... )

=item spin ( )

In most cases, L<Sympa::Spindle::ProcessIncoming> splices messages
to this class.  These methods are not used in ordinal case.

=back

=head1 SEE ALSO

L<Sympa::Mailer>, L<Sympa::Message>, L<Sympa::Spindle::ProcessIncoming>.

=head1 HISTORY

L<Sympa::Spindle::DoForward> appeared on Sympa 6.2.13.

=cut
