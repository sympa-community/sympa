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

package Sympa::Spindle::AuthorizeRequest;

use strict;
use warnings;
use Time::HiRes qw();

use Sympa;
use Sympa::CommandDef;
use Sympa::Log;
use Sympa::Report;
use Sympa::Request;
use Sympa::Scenario;
use Sympa::Spool::Request;

use base qw(Sympa::Spindle);

my $log      = Sympa::Log->instance;

sub _twist {
    my $self    = shift;
    my $request = shift;

    # Skip authorization unless specific scenario is defined.
    if (   $request->{error}
        or not $Sympa::CommandDef::comms{$request->{action}}
        or not $Sympa::CommandDef::comms{$request->{action}}->{scenario}) {
        return ['Sympa::Spindle::DispatchRequest'];
    }

    my $scenario = $Sympa::CommandDef::comms{$request->{action}}->{scenario};
    my $action_regexp =
        $Sympa::CommandDef::comms{$request->{action}}->{action_regexp}
        or die 'bug in logic. Ask developer';

    my $message = $request->{message};
    my $sender  = $request->{sender};

    # Check if required list argument is known.
    if ($request->{localpart} and ref $request->{context} ne 'Sympa::List') {
        $request->{error} = 'unknown_list';
        return ['Sympa::Spindle::DispatchRequest'];
    }
    my $that = $request->{context};

    my $context = {
        sender  => $sender,
        message => $message,
    };

    # Authorize requests.

    my $action;
    my $result;

    my $auth_method = _get_auth_method($request);
    return 'wrong_auth'
        unless defined $auth_method;

    $result = Sympa::Scenario::request_action($that, $scenario, $auth_method,
        $context);
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
        Sympa::Report::reject_report_cmd($request, 'intern', $error);
        return undef;
    }

    # Special cases for subscribe & signoff: If membership is unsatisfactory,
    # force execute request and let it be rejected.
    unless ($action =~ /\Areject\b/i) {
        if ($request->{action} eq 'subscribe'
            and defined $that->get_list_member($request->{email})) {
            $action =~ s/\A\w+/do_it/;
        } elsif ($request->{action} eq 'signoff'
            and not defined $that->get_list_member($request->{email})) {
            $action =~ s/\A\w+/do_it/;
        }
    }

    if ($action =~ /\Ado_it\b/i) {
        $request->{quiet} ||= ($action =~ /,\s*quiet\b/i);    # Overwrite.
        $request->{notify} = ($action =~ /,\s*notify\b/i);
        return ['Sympa::Spindle::DispatchRequest'];
    } elsif ($action =~ /\Arequest_auth\b(?:\s*[[]\s*(\S+)\s*[]])?/i) {
        my $to = $1;
        if ($to and $to eq 'email') {
            $to = $request->{email} || $sender;
        } else {
            $to = $sender;
        }

        $log->syslog('debug2', 'Auth requested from %s', $sender);
        unless (Sympa::request_auth(%$request, sender => $to)) {
            my $error = sprintf
                'Unable to request authentication for command "%s"',
                $request->{action};
            Sympa::Report::reject_report_cmd($request, 'intern', $error);
            return undef;
        }
        $log->syslog(
            'info',
            '%s for %s from %s, auth requested (%.2f seconds)',
            uc $request->{action},
            $that,
            $sender,
            Time::HiRes::time() - $self->{start_time}
        );
        return 1;
    } elsif ($action =~ /\Aowner\b/i and ref $that eq 'Sympa::List') {
        Sympa::Report::notice_report_cmd($request, 'req_forward')
            unless $action =~ /,\s*quiet\b/i;

        my $tpl =
            {subscribe => 'subrequest', signoff => 'sigrequest'}
            ->{$request->{action}};
        my $owner_action =
            {subscribe => 'add', signoff => 'del'}->{$request->{action}};

        # Send a notice to the owners.
        unless (
            $that->send_notify_to_owner(
                $tpl,
                {   'who'     => $sender,
                    'keyauth' => Sympa::compute_auth(
                        context => $that,
                        email   => $request->{email},
                        action  => $owner_action,
                    ),
                    'replyto' => Sympa::get_address($that, 'sympa'),
                    'gecos'   => $request->{gecos},
                }
            )
            ) {
            #FIXME: Why is error reported only in this case?
            $log->syslog('info',
                'Unable to send notify "%s" to %s list owner',
                $tpl, $that);
            Sympa::Report::reject_report_cmd(
                $request, 'intern',
                sprintf('Unable to send subrequest to %s list owner',
                    $that->get_id)
            );
        }

        my $spool_req   = Sympa::Spool::Request->new;
        my $add_request = Sympa::Request->new_from_tuples(
            %$request,
            action => $owner_action,
            date   => $message->{date},    # Keep date of message.
        );
        if ($spool_req->store($add_request)) {
            $log->syslog(
                'info',
                '%s for %s from %s forwarded to the owners of the list (%.2f seconds)',
                uc $request->{action},
                $that,
                $sender,
                Time::HiRes::time() - $self->{start_time}
            );
        }
        return 1;
    } elsif ($action =~ /\Areject\b/i) {
        if (defined $result->{'tt2'}) {
            unless (
                Sympa::send_file(
                    $that, $result->{'tt2'},
                    $sender, {'auto_submitted' => 'auto-replied'}
                )
                ) {
                $log->syslog('notice', 'Unable to send template "%s" to %s',
                    $result->{'tt2'}, $sender);
                Sympa::Report::reject_report_cmd($request, 'auth',
                    $result->{'reason'});
            }
        } else {
            Sympa::Report::reject_report_cmd($request, 'auth',
                $result->{'reason'});
        }
        $log->syslog(
            'info',
            '%s for %s from %s refused (not allowed)',
            uc $request->{action},
            $that, $sender
        );
        return 'not_allowed';
    } else {
        #NOTREACHED
        die 'bug in logic. Ask developer';
    }
}

# Checks the authentication and return method
# used if authentication not failed.
# Returns 'smime', 'md5', 'dkim' or 'smtp' if authentication OK, undef else.
# Old name: Sympa::Commands::get_auth_method().
sub _get_auth_method {
    $log->syslog('debug3', '(%s)', @_);
    my $request = shift;

    my $list     = $request->{context};
    my $sign_mod = $request->{sign_mod};
    my $sender   = $request->{sender};

    my $cmd   = $request->{action};
    my $email = $request->{email};

    my $auth = $request->{auth};

    my $that;
    my $auth_method;

    if ($sign_mod and $sign_mod eq 'smime') {
        $auth_method = 'smime';
    } elsif ($auth) {
        $log->syslog('debug', 'Auth received from %s: %s', $sender, $auth);

        my $compute;
        if (ref $list eq 'Sympa::List') {
            $compute = Sympa::compute_auth(
                context => $list,
                email   => $email,
                action  => $cmd
            );
            $that = $list->{'domain'};    # Robot
        } else {
            $compute = Sympa::compute_auth(
                context => '*',
                email   => $email,
                action  => $cmd
            );
            $that = '*';                  # Site
        }
        if ($auth eq $compute) {
            $auth_method = 'md5';
        } else {
            $log->syslog('debug2', 'Auth should be %s', $compute);
            if (grep { $cmd eq $_ } qw(add del invite signoff subscribe)) {
                Sympa::Report::reject_report_cmd($request, 'user',
                    'wrong_email_confirm', {command => $cmd});
            } else {
                Sympa::Report::reject_report_cmd($request, 'intern',
                    'The authentication process failed');
            }
            $log->syslog('info', 'Command "%s" from %s refused, auth failed',
                $request->{cmd_line}, $sender);
            return undef;
        }
    } else {
        $auth_method = 'smtp';
        $auth_method = 'dkim' if $sign_mod and $sign_mod eq 'dkim';
    }

    return $auth_method;
}

1;
