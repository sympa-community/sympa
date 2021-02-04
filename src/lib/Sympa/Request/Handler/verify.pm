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

package Sympa::Request::Handler::verify;

use strict;
use warnings;
use Time::HiRes qw();

use Sympa::Language;
use Sympa::Log;

use base qw(Sympa::Request::Handler);

my $language = Sympa::Language->instance;
my $log      = Sympa::Log->instance;

use constant _action_scenario => undef;
use constant _context_class   => 'Sympa::List';

# Old name: Sympa::Commands::verify().
sub _twist {
    my $self    = shift;
    my $request = shift;

    my $list     = $request->{context};
    my $listname = $list->{'name'};
    my $robot    = $list->{'domain'};
    my $sender   = $request->{sender};

    $language->set_lang($list->{'admin'}{'lang'});

    if ($request->{smime_signed} or $request->{dkim_pass}) {
        $log->syslog(
            'info',  'VERIFY successful from %s (%.2f seconds)',
            $sender, Time::HiRes::time() - $self->{start_time}
        );
        if ($request->{smime_signed}) {
            $self->add_stash($request, 'notice', 'smime');
        } elsif ($request->{dkim_pass}) {
            $self->add_stash($request, 'notice', 'dkim');
        }
    } else {
        $log->syslog(
            'info',
            'VERIFY from %s: could not find correct S/MIME signature (%.2f seconds)',
            $sender,
            Time::HiRes::time() - $self->{start_time}
        );
        $self->add_stash($request, 'user', 'no_verify_sign');
    }
    return 1;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Request::Handler::verify - verify request handler

=head1 DESCRIPTION

Verifies S/MIME signature in the message.

=head1 SEE ALSO

L<Sympa::Request::Handler>.

=head1 HISTORY

=cut
