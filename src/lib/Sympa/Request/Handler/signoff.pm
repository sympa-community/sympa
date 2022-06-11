# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
# Copyright 2021 The Sympa Community. See the
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

package Sympa::Request::Handler::signoff;

use strict;
use warnings;
use Time::HiRes qw();

use Sympa;
use Conf;
use Sympa::Language;
use Sympa::Log;

use base qw(Sympa::Request::Handler);

my $language = Sympa::Language->instance;
my $log      = Sympa::Log->instance;

use constant _action_scenario => 'unsubscribe';
use constant _action_regexp   => qr'reject|request_auth|owner|do_it'i;
use constant _context_class   => 'Sympa::List';
use constant _owner_action    => 'del';

# Old name: (part of) Sympa::Commands::signoff().
sub _twist {
    my $self    = shift;
    my $request = shift;

    my $list   = $request->{context};
    my $which  = $list->{'name'};
    my $sender = $request->{sender};
    my $email  = $request->{email};

    $language->set_lang($list->{'admin'}{'lang'});

    # If a list is not 'open' and allow_subscribe_if_pending has been set to
    # 'off' returns undef.
    unless ($list->is_subscription_allowed) {
        $log->syslog('info', 'List %s not open', $list);
        $self->add_stash($request, 'user', 'list_not_open',
            {status => $list->{'admin'}{'status'}});
        return undef;
    }

    my @stash;
    $list->delete_list_member(
        [$email],
        exclude   => 1,
        operation => 'signoff',
        stash     => \@stash
    );
    foreach my $report (@stash) {
        $self->add_stash($request, @$report);
        if ($report->[0] eq 'intern') {
            Sympa::send_notify_to_listmaster(
                $list,
                'mail_intern_error',
                {   error  => $report->[1],      #FIXME: Update listmaster tt2
                    who    => $sender,
                    action => 'Command process',
                }
            );
        }
    }
    return undef if grep { $_->[0] eq 'user' or $_->[0] eq 'intern' } @stash;

    # Notify the owner.
    if ($request->{notify}) {
        $list->send_notify_to_owner(
            'notice',
            {   'who'     => $email,
                'gecos'   => "",
                'command' => 'signoff'
            }
        );
    }

    unless ($request->{quiet}) {
        # Send bye file to subscriber.
        unless (Sympa::send_file($list, 'bye', $email, {})) {
            $log->syslog('notice', 'Unable to send template "bye" to %s',
                $email);
        }
    }

    $log->syslog(
        'info',
        'SIG %s from %s accepted (%.2f seconds, %d subscribers)',
        $which,
        $sender,
        Time::HiRes::time() - $self->{start_time},
        $list->get_total()
    );

    return 1;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Request::Handler::signoff - signoff request handler

=head1 DESCRIPTION

Unsubscribes a user from a list.
The user can be informed by template 'bye'.

=head1 SEE ALSO

L<Sympa::Request::Handler>.

=head1 HISTORY

=cut
