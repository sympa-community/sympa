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

package Sympa::Request::Handler::invite;

use strict;
use warnings;
use Time::HiRes qw();

use Sympa;
use Sympa::Language;
use Sympa::Log;
use Sympa::Scenario;

use base qw(Sympa::Spindle);

my $language = Sympa::Language->instance;
my $log      = Sympa::Log->instance;

# Invite someone to subscribe a list by sending him
# template 'invite'.
# Old name: Sympa::Commands::invite().
sub _twist {
    my $self    = shift;
    my $request = shift;

    unless (ref $request->{context} eq 'Sympa::List') {
        $self->add_stash($request, 'user', 'unknown_list');
        $log->syslog(
            'info',
            '%s from %s refused, unknown list for robot %s',
            uc $request->{action},
            $request->{sender}, $request->{context}
        );
        return 1;
    }
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
            {'email' => $email});
        $log->syslog(
            'err',
            'INVITE command rejected; user "%s" already member of list "%s"',
            $email,
            $which
        );
        return undef;
    }

    # Is the guest user allowed to subscribe in this list?

    my %context;
    $context{'user'}{'email'} = $email;
    $context{'user'}{'gecos'} = $comment;
    $context{'requested_by'}  = $sender;

    # Emulating subscription privilege of target user.
    my $result =
        Sympa::Scenario::request_action($list, 'subscribe', 'md5',
        {sender => $email});
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
        my $keyauth = Sympa::compute_auth(
            context => $list,
            email   => $email,
            action  => 'subscribe'
        );
        $context{'subject'} = sprintf 'auth %s sub %s %s', $keyauth,
            $list->{'name'}, $comment;
        unless (Sympa::send_file($list, 'invite', $email, \%context)) {
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
