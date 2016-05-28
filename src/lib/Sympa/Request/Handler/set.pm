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

package Sympa::Request::Handler::set;

use strict;
use warnings;
use Time::HiRes qw();

use Sympa;
use Sympa::Language;
use Sympa::Log;

use base qw(Sympa::Request::Handler);

my $language = Sympa::Language->instance;
my $log      = Sympa::Log->instance;

use constant _action_scenario => undef;           # Only list members allowed.
use constant _context_class   => 'Sympa::List';

# Old name: (part of) Sympa::Commands::set().
sub _twist {
    my $self    = shift;
    my $request = shift;

    my $sender     = $request->{sender};
    my $email      = $request->{email};
    my $reception  = $request->{reception};
    my $visibility = $request->{visibility};

    my $list  = $request->{context};
    my $which = $list->{'name'};

    $language->set_lang($list->{'admin'}{'lang'});

    # Check if we know this email on the list and remove it. Otherwise
    # just reject the message.
    unless ($list->is_list_member($email)) {
        unless ($email eq $sender) {    # Request from owner?
            $self->add_stash($request, 'user', 'user_not_subscriber');
        } else {
            $self->add_stash($request, 'user', 'not_subscriber');
        }
        $log->syslog('info', 'SET %s %s%s from %s refused, %s not on list',
            $which, $reception, $visibility, $sender, $email);
        return undef;
    }

    # May set to DIGEST.
    if (    $reception
        and grep { $reception eq $_ } qw(digest digestplain summary)
        and not $list->is_digest) {
        $self->add_stash($request, 'user', 'no_digest');
        $log->syslog('info', 'SET %s %s from %s refused, no digest mode',
            $which, $reception, $sender);
        return undef;
    }

    # Verify that the mode is allowed.
    if ($reception and not $list->is_available_reception_mode($reception)) {
        $self->add_stash(
            $request, 'user',
            'not_available_reception_mode',
            {   modes => join(' ', $list->available_reception_mode),
                reception_modes => [$list->available_reception_mode],
                reception_mode  => $reception,
            }
        );
        $log->syslog('info', 'SET %s %s from %s refused, mode not available',
            $which, $reception, $sender);
        return undef;
    }

    if ($reception or $visibility) {
        unless (
            $list->update_list_member(
                $email,
                ($reception  ? (reception  => $reception)  : ()),
                ($visibility ? (visibility => $visibility) : ()),
                update_date => time
            )
            ) {
            my $error =
                sprintf
                'Failed to change subscriber "%s" options for list %s',
                $email, $list->get_id;
            Sympa::send_notify_to_listmaster(
                $list,
                'mail_intern_error',
                {   error  => $error,
                    who    => $sender,
                    action => 'Command process',
                }
            );
            $self->add_stash($request, 'intern');
            $log->syslog('info', 'SET %s %s%s from %s refused, update failed',
                $which, $reception, $visibility, $sender);
            return undef;
        }
    }

    $self->add_stash($request, 'notice', 'config_updated');
    $log->syslog('info', 'SET %s from %s accepted (%.2f seconds)',
        $which, $sender, Time::HiRes::time() - $self->{start_time});
    return 1;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Request::Handler::set - set request handler

=head1 DESCRIPTION

Change subscription options (reception or visibility).

=head1 SEE ALSO

L<Sympa::Request::Handler>.

=head1 HISTORY

=cut
