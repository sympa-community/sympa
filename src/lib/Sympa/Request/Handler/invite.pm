# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
# Copyright 2018 The Sympa Community. See the AUTHORS.md file at the
# top-level directory of this distribution and at
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

package Sympa::Request::Handler::invite;

use strict;
use warnings;
use Time::HiRes qw();

use Sympa;
use Sympa::Language;
use Sympa::Log;
use Sympa::Request;
use Sympa::Scenario;
use Sympa::Spool::Auth;

use base qw(Sympa::Request::Handler);

my $language = Sympa::Language->instance;
my $log      = Sympa::Log->instance;

use constant _action_scenario => 'invite';
use constant _action_regexp   => qr'reject|request_auth|do_it'i;
use constant _context_class   => 'Sympa::List';

# Old name: Sympa::Commands::invite().
sub _twist {
    my $self    = shift;
    my $request = shift;

    my $list    = $request->{context};
    my $which   = $list->{'name'};
    my $robot   = $list->{'domain'};
    my $sender  = $request->{sender};
    my $email   = $request->{email};
    my $comment = $request->{gecos};

    my $sympa = Sympa::get_address($robot, 'sympa');

    $language->set_lang($list->{'admin'}{'lang'});

    if ($list->is_list_member($email)) {
        $self->add_stash($request, 'user', 'already_subscriber',
            {'email' => $email, 'listname' => $list->{'name'}});
        $log->syslog(
            'err',
            'INVITE command rejected; user "%s" already member of list "%s"',
            $email,
            $which
        );
        return undef;
    }

    # Is the guest user allowed to subscribe in this list?
    # Emulating subscription privilege of target user.
    my $result =
        Sympa::Scenario->new($list, 'subscribe')
        ->authz('md5', {sender => $email});
    my $action;
    $action = $result->{'action'} if ref $result eq 'HASH';

    unless (defined $action) {
        my $error = "Unable to evaluate scenario 'subscribe' for list $which";
        Sympa::send_notify_to_listmaster(
            $list,
            'mail_intern_error',
            {   error  => $error,
                who    => $sender,
                action => 'Command process',
            }
        );
        $self->add_stash($request, 'intern');
        return undef;
    }

    if ($action =~ /\Areject\b/i) {
        $log->syslog(
            'info',
            'INVITE %s %s from %s refused, not allowed (%.2f seconds, %d subscribers)',
            $which,
            $email,
            $sender,
            Time::HiRes::time() - $self->{start_time},
            $list->get_total()
        );
        $self->add_stash($request, 'auth', $result->{'reason'},
            {'email' => $email, template => $result->{'tt2'}});
        return undef;
    } else {
        my $spool_req     = Sympa::Spool::Auth->new;
        my $req_subscribe = Sympa::Request->new(
            context => $list,
            action  => 'subscribe',
            email   => $email,
            sender  => $sender,
        );
        my $keyauth = $spool_req->store($req_subscribe);

        my $cmd_line = $req_subscribe->cmd_line(canonic => 1);
        unless (
            Sympa::send_file(
                $list, 'invite', $email,
                {   user         => {email => $email, gecos => $comment},
                    requested_by => $sender,
                    keyauth      => $keyauth,
                    cmd          => $cmd_line,
                    # Compat. <= 6.2.14.
                    subject => sprintf('AUTH %s %s', $keyauth, $cmd_line),
                }
            )
        ) {
            $log->syslog('notice', 'Unable to send template "invite" to %s',
                $email);
            my $error = sprintf 'Unable to send template "invite" to %s',
                $email;
            Sympa::send_notify_to_listmaster(
                $list,
                'mail_intern_error',
                {   error  => $error,
                    who    => $sender,
                    action => 'Command process',
                }
            );
            $self->add_stash($request, 'intern');
            return undef;
        }
        $log->syslog(
            'info',
            'INVITE %s %s from %s accepted, auth requested (%.2f seconds, %d subscribers)',
            $which,
            $email,
            $sender,
            Time::HiRes::time() - $self->{start_time},
            $list->get_total()
        );
        $self->add_stash($request, 'notice', 'invite', {'email' => $email});
    }

    return 1;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Request::Handler::invite - invite request handler

=head1 DESCRIPTION

Invites someone to subscribe a list by sending him
template 'invite'.

Subscription request of target user is stored into held request spool.

=head1 SEE ALSO

L<Sympa::Request::Handler>, L<Sympa::Spool::Auth>.

=head1 HISTORY

=cut
