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

package Sympa::Request::Handler::review;

use strict;
use warnings;
use Time::HiRes qw();

use Sympa;
use Sympa::Language;
use Sympa::Log;

use base qw(Sympa::Spindle);

my $language = Sympa::Language->instance;
my $log      = Sympa::Log->instance;

# Sends the list of subscribers to the requester.
# Old name: Sympa::Commands::review().
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
    my $list     = $request->{context};
    my $listname = $list->{'name'};
    my $robot    = $list->{'domain'};
    my $sender   = $request->{sender};

    my $user;

    $language->set_lang($list->{'admin'}{'lang'});

    unless (defined $list->on_the_fly_sync_include(use_ttl => 1)) {
        $log->syslog('notice', 'Unable to synchronize list %s', $list);
        #FIXME: Abort if synchronization failed.
    }

    my @users;

    my $is_owner = $list->is_admin('owner', $sender)
        || Sympa::is_listmaster($list, $sender);
    unless ($user = $list->get_first_list_member({'sortby' => 'email'})) {
        $self->add_stash($request, 'user', 'no_subscriber');
        $log->syslog('err', 'No subscribers in list "%s"', $list->{'name'});
        return 'no_subscribers';
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
    }

    $log->syslog('info', 'REVIEW %s from %s accepted (%.2f seconds)',
        $listname, $sender, Time::HiRes::time() - $self->{start_time});
    return 1;
}

1;
__END__
