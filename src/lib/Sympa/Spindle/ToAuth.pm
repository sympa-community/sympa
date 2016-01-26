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

package Sympa::Spindle::ToAuth;

use strict;
use warnings;
use Time::HiRes qw();

use Sympa;
use Sympa::Log;

use base qw(Sympa::Spindle);

my $log      = Sympa::Log->instance;

sub _twist {
    my $self    = shift;
    my $request = shift;

    my $sender = $request->{sender};
    my $to     = $request->{sender_to_confirm} || $sender;

        $log->syslog('debug2', 'Auth requested from %s', $sender);
        unless (Sympa::request_auth(%$request, sender => $to)) {
            my $error = sprintf
                'Unable to request authentication for command "%s"',
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
        $log->syslog(
            'info',
            '%s for %s from %s, auth requested (%.2f seconds)',
            uc $request->{action},
            $request->{context},
            $sender,
            Time::HiRes::time() - $self->{start_time}
        );
        return 1;
}

1;
