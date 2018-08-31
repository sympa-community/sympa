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

package Sympa::Spindle::DoMessage;

use strict;
use warnings;

use Sympa;
use Conf;
use Sympa::Language;
use Sympa::Log;
use Sympa::Regexps;

use base qw(Sympa::Spindle::ProcessIncoming);    # Deriving _splicing_to().

my $log = Sympa::Log->instance;

# Old name: (part of) DoMessage() in sympa_msg.pl.
sub _twist {
    my $self    = shift;
    my $message = shift;

    # Fail-safe: Skip messages with unwanted types.
    return 0 unless $self->_splicing_to($message) eq __PACKAGE__;

    # List unknown.
    unless (ref $message->{context} eq 'Sympa::List') {
        $log->syslog('notice', 'Unknown list %s', $message->{localpart});
        Sympa::send_dsn($message->{context} || '*', $message, {}, '5.1.1');
        return undef;
    }
    my $list = $message->{context};

    Sympa::Language->instance->set_lang(
        $list->{'admin'}{'lang'},
        Conf::get_robot_conf($list->{'domain'}, 'lang'),
        $Conf::Conf{'lang'}, 'en'
    );

    my $messageid = $message->{message_id};
    my $sender    = $message->{sender};

    $log->syslog('info',
        'Processing message %s for %s with priority %s, <%s>',
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
            Sympa::send_dsn($list, $message, {cmd => $cmd}, '5.6.0');
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
        Sympa::send_dsn($list, $message, {}, '5.2.3');
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

    return ['Sympa::Spindle::AuthorizeMessage'];
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

See also L<Sympa::Spindle::ProcessIncoming/"Public methods">.

=over

=item new ( key =E<gt> value, ... )

=item spin ( )

In most cases, L<Sympa::Spindle::ProcessIncoming> splices messages
to this class.  These methods are not used in ordinal case.

=back

=head1 SEE ALSO

L<Sympa::Message>, L<Sympa::Spindle::AuthorizeMessage>,
L<Sympa::Spindle::ProcessIncoming>.

=head1 HISTORY

L<Sympa::Spindle::DoMessage> appeared on Sympa 6.2.13.

=cut
