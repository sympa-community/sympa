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

package Sympa::Request::Handler::unknown;

use strict;
use warnings;

use Sympa::Log;

use base qw(Sympa::Request::Handler);

my $log = Sympa::Log->instance;

use constant _action_scenario => undef;
use constant _context_class   => undef;    # Don't care.

# Old name: Sympa::Commands::unknown().
sub _twist {
    my $self    = shift;
    my $request = shift;

    $log->syslog('notice', 'Unknown command found: %s', $request->{cmd_line});
    $self->add_stash($request, 'user', 'unknown_command');
    return undef;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Request::Handler::unknown - unknown request handler

=head1 DESCRIPTION

Internally-used request to inform unknown commands.

=head1 SEE ALSO

L<Sympa::Request::Handler>.

=head1 HISTORY

=cut
