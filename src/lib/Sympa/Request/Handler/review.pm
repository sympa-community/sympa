# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
# Copyright 2020 The Sympa Community. See the AUTHORS.md
# # file at the top-level directory of this distribution and at
# # <https://github.com/sympa-community/sympa.git>.
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

package Sympa::Request::Handler::review;

use strict;
use warnings;
use Time::HiRes qw();

use Sympa;
use Sympa::Language;
use Sympa::Log;

use base qw(Sympa::Request::Handler);

my $language = Sympa::Language->instance;
my $log      = Sympa::Log->instance;

use constant _action_scenario => 'review';
use constant _action_regexp   => qr'reject|request_auth|do_it'i;
use constant _context_class   => 'Sympa::List';

# Old name: Sympa::Commands::review().
sub _twist {
    my $self    = shift;
    my $request = shift;

    my $list     = $request->{context};
    my $listname = $list->{'name'};
    my $robot    = $list->{'domain'};
    my $sender   = $request->{sender};

    $language->set_lang($list->{'admin'}{'lang'});

    my (@users, $user);

    my $is_owner = $list->is_admin('owner', $sender)
        || Sympa::is_listmaster($list, $sender);
    unless ($user = $list->get_first_list_member({'sortby' => 'email'})) {
        $self->add_stash($request, 'user', 'no_subscriber');
        $log->syslog('err', 'No subscribers in list "%s"', $list->{'name'});
        return undef;
    }
    do {
        ## Owners bypass the visibility option
        unless (($user->{'visibility'} eq 'conceal')
            and (!$is_owner)) {

            ## Lower case email address
            $user->{'email'} =~ y/A-Z/a-z/;
            push @users, $user;
        }
    } while ($user = $list->get_next_list_member());
    unless (
        Sympa::send_file(
            $list, 'review', $sender,
            {   'users'          => \@users,
                'total'          => $list->get_total(),
                'subject'        => "REVIEW $listname",    # Compat <= 6.1.17.
                'auto_submitted' => 'auto-replied'
            }
        )
    ) {
        $log->syslog('notice', 'Unable to send template "review" to %s',
            $sender);
        $self->add_stash($request, 'intern');
        return undef;
    }

    $log->syslog('info', 'REVIEW %s from %s accepted (%.2f seconds)',
        $listname, $sender, Time::HiRes::time() - $self->{start_time});
    return 1;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Request::Handler::review - review request handler

=head1 DESCRIPTION

Sends the list of subscribers to the requester
using 'review' template.

=head1 SEE ALSO

L<Sympa::Request::Handler>.

=head1 HISTORY

=cut
