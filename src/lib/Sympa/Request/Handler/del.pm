# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
# Copyright 2017, 2021 The Sympa Community. See the
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

package Sympa::Request::Handler::del;

use strict;
use warnings;
use Time::HiRes qw();

use Sympa;
use Conf;
use Sympa::Language;
use Sympa::Log;
use Sympa::Tracking;

use base qw(Sympa::Request::Handler);

my $language = Sympa::Language->instance;
my $log      = Sympa::Log->instance;

use constant _action_scenario => 'del';
use constant _action_regexp   => qr'reject|request_auth|do_it'i;
use constant _context_class   => 'Sympa::List';

# Old name: Sympa::Commands::del().
sub _twist {
    my $self    = shift;
    my $request = shift;

    my $list   = $request->{context};
    my $which  = $list->{'name'};
    my $robot  = $list->{'domain'};
    my $sender = $request->{sender};
    my $who    = $request->{email};

    $language->set_lang($list->{'admin'}{'lang'});

    unless ($request->{force} or $list->is_subscription_allowed) {
        $log->syslog('info', 'List %s not open', $list);
        $self->add_stash($request, 'user', 'list_not_open',
            {'status' => $list->{'admin'}{'status'}});
        return undef;
    }

    my @stash;
    $list->delete_list_member(
        [$who],
        exclude   => 1,
        operation => 'del',
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

    # Only when deletion was done by request, bounce information will be
    # cleared.  Note that tracking information will be kept.
    my $tracking = Sympa::Tracking->new(context => $list);
    if ($tracking) {
        $tracking->remove_message_by_email($who);
    }

    ## Send a notice to the removed user, unless the owner indicated
    ## quiet del.
    unless ($request->{quiet}) {
        unless (Sympa::send_file($list, 'removed', $who, {})) {
            $log->syslog('notice', 'Unable to send template "removed" to %s',
                $who);
        }
    }
    $self->add_stash($request, 'notice', 'removed', {'email' => $who});
    $log->syslog(
        'info',
        'DEL %s %s from %s accepted (%.2f seconds, %d subscribers)',
        $which,
        $who,
        $sender,
        Time::HiRes::time() - $self->{start_time},
        $list->get_total()
    );
    if ($request->{notify}) {
        $list->send_notify_to_owner(
            'notice',
            {   'who'     => $who,
                'gecos'   => "",
                'command' => 'del',
                'by'      => $sender
            }
        );
    }
    return 1;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Request::Handler::del - del request handler

=head1 DESCRIPTION

Removes a user from a list (requested by another user).
Verifies the authorization and sends acknowledgements
unless quiet is specified.

=head2 Attributes

See also L<Sympa::Request::Handler/"Attributes">.

=over

=item {email}

I<Mandatory>.
E-mail of the user to be deleted.

=item {force}

I<Optional>.
If true value is specified,
users will be deleted even if the list is closed.

=item {quiet}

I<Optional>.
Don't notify addition to the user.

=back

=head1 SEE ALSO

L<Sympa::Request::Handler>.

=head1 HISTORY

=cut
