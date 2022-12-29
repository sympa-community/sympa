# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
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

package Sympa::Request::Handler::distribute;

use strict;
use warnings;
use Time::HiRes qw();

use Sympa::Log;
use Sympa::Spindle::ProcessModeration;

use base qw(Sympa::Request::Handler);

my $log = Sympa::Log->instance;

use constant _action_scenario => undef;
use constant _context_class   => 'Sympa::List';

# Old name: Sympa::Commands::distribute().
sub _twist {
    my $self    = shift;
    my $request = shift;

    my $list   = $request->{context};
    my $which  = $list->{'name'};
    my $robot  = $list->{'domain'};
    my $sender = $request->{sender};

    my $key = $request->{authkey};

    my $spindle = Sympa::Spindle::ProcessModeration->new(
        distributed_by => $sender,
        context        => $robot,
        authkey        => $key,
        quiet          => $request->{quiet}
    );

    unless ($spindle and $spindle->spin) {    # No message.
        $log->syslog('err',
            'Unable to find message with key <%s> for list %s',
            $key, $list);
        $self->add_stash($request, 'user', 'already_moderated',
            {key => $key});
        return undef;
    } elsif ($spindle->{finish} and $spindle->{finish} eq 'success') {
        $log->syslog(
            'info',
            'DISTRIBUTE %s %s from %s accepted (%.2f seconds)',
            $list->{'name'},
            $key,
            $sender,
            Time::HiRes::time() - $self->{start_time}
        );
        return 1;
    } else {
        return undef;
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Request::Handler::distribute - distribute request handler

=head1 DESCRIPTION

Distributes the broadcast of a validated moderated message.

=head1 SEE ALSO

L<Sympa::Request::Handler>, L<Sympa::Spindle::ProcessModeration>.

=head1 HISTORY

=cut
