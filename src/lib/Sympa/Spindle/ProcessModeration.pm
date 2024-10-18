# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id: Commands.pm 12548 2015-11-28 08:33:32Z sikeda $

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
# Copyright 2017, 2024 The Sympa Community. See the
# AUTHORS.md file at the top-level directory of this distribution and at
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

package Sympa::Spindle::ProcessModeration;

use strict;
use warnings;

use Sympa;
use Conf;
use Sympa::Language;
use Sympa::Log;

use base qw(Sympa::Spindle);

my $log = Sympa::Log->instance;

use constant _distaff => 'Sympa::Spool::Moderation';

sub _init {
    my $self  = shift;
    my $state = shift;

    if ($state == 0) {
        die 'bug in logic. Ask developer'
            unless ($self->{distributed_by} or $self->{rejected_by})
            and $self->{context}
            and $self->{authkey};
    }

    1;
}

sub _on_garbage {
    my $self   = shift;
    my $handle = shift;

    # Keep broken message and skip it.
    $handle->close;
}

sub _on_failure {
    my $self    = shift;
    my $message = shift;
    my $handle  = shift;

    # Keep failed message and exit.
    $handle->close;
    $self->{finish} = 'failure';
}

sub _on_success {
    my $self    = shift;
    my $message = shift;
    my $handle  = shift;

    # Remove succeeded message and exit.
    $self->SUPER::_on_success($message, $handle)
        and $self->{distaff}->html_remove($message);

    $self->{finish} = 'success';
}

sub _twist {
    my $self    = shift;
    my $message = shift;

    if ($self->{rejected_by}) {
        return _reject($self, $message);
    } else {
        return _distribute($self, $message);
    }
}

# Private subroutines.

sub _reject {
    my $self    = shift;
    my $message = shift;

    # Messages marked validated should not be rejected.
    return 0 if $message->{validated};

    # Assign distributing user as envelope sender to whom DSN will be sent.
    $message->{envelope_sender} = $self->{rejected_by};

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

    if ($message->{sender}) {
        my $param = {
            subject     => $message->{decoded_subject},
            rejected_by => $self->{rejected_by},
            #editor_msg_body =>
            #    ($editor_msg ? $editor_msg->body_as_string : undef),
        };
        $log->syslog('debug2', 'Message %s by %s rejected sender %s',
            $param->{subject}, $param->{rejected_by}, $message->{sender});

        # Notify author of message.
        unless ($self->{quiet}) {
            Sympa::send_file($list, 'reject', $message->{sender}, $param)
                or Sympa::send_dsn($list, $message, {}, '5.3.0');    #FIXME
        }

        # Notify list moderator.
        # Ensure 1 second elapsed since last message.
        Sympa::send_file(
            $list,
            'message_report',
            $self->{rejected_by},
            {   type           => 'success',            # Compat. <=6.2.12.
                entry          => 'message_rejected',
                auto_submitted => 'auto-replied',
                key            => $message->{authkey}
            },
            date => time + 1
        );
        $log->db_log(
            'robot'        => $list->{'domain'},
            'list'         => $list->{'name'},
            'action'       => 'reject',
            'parameters'   => $message->{authkey},
            'target_email' => $message->{sender},
            'status'       => 'success',
            'user_email'   => $param->{rejected_by}
        );
    }

    1;
}

sub _distribute {
    my $self    = shift;
    my $message = shift;

    # Decrpyt message.
    # If encrypted, it will be re-encrypted by succeeding processes.
    $message->smime_decrypt;

    # Assign distributing user to envelope sender.
    $message->{envelope_sender} = $self->{distributed_by};

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

    $message->add_header('X-Validation-by', $self->{distributed_by});

    my @apply_on = @{$list->{'admin'}{'dkim_signature_apply_on'} || []};
    $message->{shelved}{dkim_sign} = 1
        if grep { 'any' eq $_ } @apply_on
        or (grep { 'smime_authenticated_messages' eq $_ } @apply_on
        and $message->{'smime_signed'})
        or (grep { 'dkim_authenticated_messages' eq $_ } @apply_on
        and $message->{'dkim_pass'})
        or grep { 'editor_validated_messages' eq $_ } @apply_on;

    # Notify author of message.
    $message->{envelope_sender} = $message->{sender};
    unless ($self->{quiet}) {
        Sympa::send_dsn($message->{context}, $message, {}, '2.1.5');
    }

    $log->db_log(
        'robot'        => $list->{'domain'},
        'list'         => $list->{'name'},
        'action'       => 'distribute',
        'parameters'   => $message->{authkey},
        'target_email' => $message->{sender},
        'status'       => 'success',
        'user_email'   => $self->{distributed_by}
    );

    $message->{envelope_sender} = $self->{distributed_by};
    return ['Sympa::Spindle::DistributeMessage'];
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Spindle::ProcessModeration - Workflow of message moderation

=head1 SYNOPSIS

  use Sympa::Spindle::ProcessModeration;

  my $spindle = Sympa::Spindle::ProcessModeration->new(
      distributed_by => $email, context => $robot, authkey => $key);
  $spindle->spin;

=head1 DESCRIPTION

L<Sympa::Spindle::ProcessModeration> defines workflow for moderation of
messages.

When spin() method is invoked, it reads a message in moderation spool and
distribute or reject it.
Either distribution or rejection failed or not, spin() will terminate
processing.
Failed message will be kept in spool and wait for moderation again.

=head2 Public methods

See also L<Sympa::Spindle/"Public methods">.

=over

=item new ( distributed_by =E<gt> $email | rejected_by =E<gt> $email,
context =E<gt> $context, authkey =E<gt> $key,
[ quiet =E<gt> 1 ] )

=item spin ( )

new() must take following options:

=over

=item distributed_by =E<gt> $email | rejected_by =E<gt> $email

E-mail address of the user who distributed or rejected the message.
It is given by DISTRIBUTE or REJECT command.

=item context =E<gt> $context

=item authkey =E<gt> $key

Context (List or Robot) and authorization key to specify the message in
spool.

=item quiet =E<gt> 1

If this option is set, automatic replies reporting result of processing
to the user (see L</"distributed_by"> and L</"rejected_by">) will not be sent.

=back

=back

=head2 Properties

See also L<Sympa::Spindle/"Properties">.

=over

=item {distaff}

Instance of L<Sympa::Spool::Moderation> class.

=item {finish}

C<'success'> is set if processing succeeded.
C<'failure'> is set if processing failed.

=back

=head1 SEE ALSO

L<Sympa::Message>,
L<Sympa::Spindle>, L<Sympa::Spindle::DistributeMessage>,
L<Sympa::Spool::Moderation>.

=head1 HISTORY

L<Sympa::Spindle::ProcessModeration> appeared on Sympa 6.2.13.

=cut
