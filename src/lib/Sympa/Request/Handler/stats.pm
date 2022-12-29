# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
# Copyright 2017 The Sympa Community. See the AUTHORS.md file at the top-level
# directory of this distribution and at
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

package Sympa::Request::Handler::stats;

use strict;
use warnings;
use Time::HiRes qw();

use Sympa;
use Sympa::Log;

use base qw(Sympa::Request::Handler);

my $log = Sympa::Log->instance;

use constant _action_scenario => 'review';
use constant _action_regexp   => qr'reject|do_it'i;    #FIXME: request_auth?
use constant _context_class   => 'Sympa::List';

# Old name: Sympa::Commands::stats().
sub _twist {
    my $self    = shift;
    my $request = shift;

    my $list     = $request->{context};
    my $listname = $list->{'name'};
    my $robot    = $list->{'domain'};
    my $sender   = $request->{sender};

    my @stats = $list->get_stats;
    my %stats = (
        'msg_rcv'   => $stats[0],
        'msg_sent'  => $stats[1],
        'byte_rcv'  => sprintf('%9.2f', ($stats[2] / 1024 / 1024)),
        'byte_sent' => sprintf('%9.2f', ($stats[3] / 1024 / 1024))
    );

    unless (
        Sympa::send_file(
            $list,
            'stats_report',
            $sender,
            {   'stats'   => \%stats,
                'subject' => "STATS $list->{'name'}",    # compat <= 6.1.17.
                'auto_submitted' => 'auto-replied'
            }
        )
    ) {
        $log->syslog('notice',
            'Unable to send template "stats_reports" to %s', $sender);
        $self->add_stash($request, 'intern');
        return undef;
    }

    $log->syslog('info', 'STATS %s from %s accepted (%.2f seconds)',
        $listname, $sender, Time::HiRes::time() - $self->{start_time});
    return 1;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Request::Handler::stats - stats request handler

=head1 DESCRIPTION

Sends the statistics about a list using template
'stats_report'.

=head1 SEE ALSO

L<Sympa::Request::Handler>.

=head1 HISTORY

=cut
