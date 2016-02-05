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

package Sympa::Request::Handler::remind;

use strict;
use warnings;
use Time::HiRes qw();

use Sympa;
use Sympa::Language;
use Sympa::Log;

use base qw(Sympa::Spindle);

my $language = Sympa::Language->instance;
my $log      = Sympa::Log->instance;

# Sends a personal reminder to each subscriber of one list
# using template 'remind'.
# Old name: (part of) Sympa::Commands::remind().
sub _twist {
    my $self    = shift;
    my $request = shift;

    my $sender = $request->{sender};

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

    $language->set_lang($list->{'admin'}{'lang'});

    # For each subscriber send a reminder.
    my $total = 0;
    my $user;

    unless ($user = $list->get_first_list_member()) {
        my $error = "Unable to get subscribers for list $listname";
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

    do {
        unless ($list->send_probe_to_user('remind', $user->{'email'})) {
            $log->syslog('notice', 'Unable to send "remind" probe to %s',
                $user->{'email'});
            $self->add_stash($request, 'intern');
        }
        $total += 1;
    } while ($user = $list->get_next_list_member());

    $self->add_stash($request, 'notice', 'remind', {total => $total});
    $log->syslog(
        'info',
        'REMIND %s from %s accepted, sent to %d subscribers (%.2f seconds)',
        $listname,
        $sender,
        $total,
        Time::HiRes::time() - $self->{start_time}
    );

    return 1;
}

1;
__END__
