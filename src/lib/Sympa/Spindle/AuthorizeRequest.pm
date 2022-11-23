# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
# Copyright 2017, 2018, 2021 The Sympa Community. See the
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

package Sympa::Spindle::AuthorizeRequest;

use strict;
use warnings;
use Time::HiRes qw();

use Sympa;
use Sympa::Log;
use Sympa::Request;
use Sympa::Scenario;

use base qw(Sympa::Spindle);

my $log = Sympa::Log->instance;

sub _twist {
    my $self    = shift;
    my $request = shift;

    # Skip authorization unless specific scenario is defined.
    if (   $request->{error}
        or not $request->handler->action_scenario
        or ($self->{scenario_context} and $self->{scenario_context}{skip})) {
        return ['Sympa::Spindle::DispatchRequest'];
    }

    my $scenario      = $request->handler->action_scenario;
    my $action_regexp = $request->handler->action_regexp;

    my $sender = $request->{sender};

    # Check if required context (known list or robot) is given.
    if (defined $request->handler->context_class
        and $request->handler->context_class ne ref $request->{context}) {
        $request->{error} = 'unknown_list';
        return ['Sympa::Spindle::DispatchRequest'];
    }
    my $that = $request->{context};

    my $context = $self->{scenario_context}
        or die 'bug in logic. Ask developer';
    # Add target email kept only in request to context.
    # FIXME: $request and $context would be merged in some future
    $context = {email => $request->{email}, %$context}
        if exists $request->{email};

    # Call scenario: auth_method MD5 do not have any sense in
    # scenario because auth is performed by AUTH command.

    my $action;
    my $result;

    # The order of the following 3 lines is important! SMIME > DKIM > SMTP.
    my $auth_method =
          $request->{smime_signed} ? 'smime'
        : $request->{md5_check}    ? 'md5'
        :                            'smtp';

    $result =
        Sympa::Scenario->new($that, $scenario)->authz($auth_method, $context);
    $action = $result->{'action'} if ref $result eq 'HASH';

    unless (defined $action and $action =~ /\A(?:$action_regexp)\b/) {
        $log->syslog(
            'info',
            '%s for %s from %s aborted, unknown requested action "%s" in scenario "%s"',
            uc $request->{action},
            $that,
            $sender,
            $action,
            $scenario
        );
        my $error = sprintf 'Unknown requested action in scenario: %s',
            ($action || '');
        Sympa::send_notify_to_listmaster(
            $request->{context},
            'mail_intern_error',
            {   error  => $error,
                who    => $sender,
                action => 'Command process',
            }
        );
        $self->add_stash($request, 'intern');
        return undef;
    }

    # Special cases for "subscribe" and "signoff" actions.
    if ($action =~ /\Areject\b/i) {
        ;
    } elsif (
        $sender ne ($request->{email} // '')
        and
        ($request->{action} eq 'subscribe' or $request->{action} eq 'signoff')
    ) {
        # Request by an other/anonymous user:
        # If membership is unsatisfactory, fake successful response to prevent
        # sniffing users.
        my $is_list_member = $that->get_list_member($request->{email});
        if (   $request->{action} eq 'subscribe' and $is_list_member
            or $request->{action} eq 'signoff' and not $is_list_member) {
            $log->syslog(
                'info',
                '%s %s for %s from %s is in vain (omitted)',
                uc $request->{action},
                $request->{email}, $that, $sender
            );
            # Notify target address.
            Sympa::send_notify_to_user($that, 'vain_request_by_other',
                $request->{email}, {request => $request});
            # Fake succsssful result.
            if ($action =~ /\Arequest_auth\b/i) {
                $self->add_stash($request, 'notice', 'sent_to_user',
                    {email => $request->{email}});
            } elsif ($action =~ /\Aowner\b/i) {
                $self->add_stash($request, 'notice', 'sent_to_owner');
            }
            # Abort processing request.
            return 1;
        }

        # Otherwise, confirmation should be sent to target email instead of
        # sender.  This fixup is necessary for subscribe.* scenarios bundled
        # in 6.2.34 or earlier.
        $action =~
            s/\Arequest_auth(?![(][[]email[]][)])/request_auth([email])/;
    }

    if ($action =~ /\Ado_it\b/i) {
        $request->{quiet} ||= ($action =~ /,\s*quiet\b/i);    # Overwrite.
        $request->{notify} = ($action =~ /,\s*notify\b/i);
        return ['Sympa::Spindle::DispatchRequest'];
    } elsif ($action =~ /\Alistmaster\b/i) {
        # Special case for move_list and create_list.
        $request->{pending} = 'pending';
        $request->{notify}  = ($action =~ /,\s*notify\b/i);
        return ['Sympa::Spindle::DispatchRequest'];
    } elsif (
        $action =~ /\Arequest_auth\b(?:\s*[(]\s*[[]\s*(\S+)\s*[]]\s*[)])?/i) {
        my $to = $1;
        if ($to and $to eq 'email') {
            $request->{sender_to_confirm} = $request->{email};
        }
        return ['Sympa::Spindle::ToAuth'];
    } elsif ($action =~ /\Aowner\b/i and ref $that eq 'Sympa::List') {
        # Special case for subscribe and signoff.
        $request->{quiet} ||= ($action =~ /,\s*quiet\b/i);
        return ['Sympa::Spindle::ToAuthOwner'];
    } elsif ($action =~ /\Areject\b/i) {
        $self->add_stash($request, 'auth', $result->{'reason'},
            {template => $result->{'tt2'}});
        $log->syslog(
            'info',
            '%s for %s from %s refused (not allowed)',
            uc $request->{action},
            $that, $sender
        );
        return undef;
    }

    $log->syslog(
        'info',
        '%s for %s from %s aborted, unknown requested action "%s" in scenario "%s"',
        uc $request->{action},
        $that,
        $sender,
        $action,
        $scenario
    );
    my $error = sprintf 'Unknown requested action in scenario: %s',
        $request->{action};
    Sympa::send_notify_to_listmaster(
        $request->{context},
        'mail_intern_error',
        {   error  => $error,
            who    => $sender,
            action => 'Command process',
        }
    );
    $self->add_stash($request, 'intern');
    return undef;
}

# Checks the authentication and return method
# used if authentication not failed.
# Returns 'smime', 'md5', 'dkim' or 'smtp' if authentication OK, undef else.
# Old name: Sympa::Commands::get_auth_method().
# DEPRECATED.  Use Sympa::Request::Handler::auth module to authorize requests.
#sub _get_auth_method;

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Spindle::AuthorizeRequest -
Workflow to authorize requests in command messages

=head1 DESCRIPTION

L<Sympa::Spindle::AuthorizeRequest> authorizes requests and stores them
into request spool or dispatch them.

TBD

=head2 Public methods

See also L<Sympa::Spindle/"Public methods">.

=over

=item new ( key =E<gt> value, ... )

In most cases, L<Sympa::Spindle::ProcessMessage>
splices messages to this class.  This method is not used in ordinal case.

=item spin ( )

Not implemented.

=back

=head1 SEE ALSO

L<Sympa::Request>, L<Sympa::Scenario>, L<Sympa::Spindle::DispatchRequest>,
L<Sympa::Spindle::ProcessMessage>, L<Sympa::Spindle::ProcessRequest>,
L<Sympa::Spindle::ToAuth>, L<Sympa::Spindle::ToAuthOwner>.

=head1 HISTORY

L<Sympa::Spindle::AuthorizeRequest> appeared on Sympa 6.2.13.

=cut
