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

package Sympa::Request::Handler::modindex;

use strict;
use warnings;
use Time::HiRes qw();

use Sympa;
use Sympa::Language;
use Sympa::Log;
use Sympa::Spool::Moderation;

use base qw(Sympa::Request::Handler);

my $language = Sympa::Language->instance;
my $log      = Sympa::Log->instance;

use constant _action_scenario => undef;         # Only actual editors allowed.
use constant _context_class   => 'Sympa::List';

# Old name: Sympa::Commands::modindex().
sub _twist {
    my $self    = shift;
    my $request = shift;

    my $list   = $request->{context};
    my $name   = $list->{'name'};
    my $robot  = $list->{'domain'};
    my $sender = $request->{sender};

    $language->set_lang($list->{'admin'}{'lang'});

    unless ($list->is_admin('actual_editor', $sender)) {
        $self->add_stash($request, 'auth', 'restricted_modindex');
        $log->syslog('info', 'MODINDEX %s from %s refused, not allowed',
            $name, $sender);
        return undef;
    }

    my $spool_mod = Sympa::Spool::Moderation->new(context => $list);
    my @now = localtime(time);

    # List of messages
    my @spool;

    while (1) {
        my ($message, $handle) = $spool_mod->next(no_lock => 1);
        last unless $handle;
        next unless $message and not $message->{validated};
        # Skip message already marked to be distributed using WWSympa.

        # Push message for building MODINDEX
        push @spool, $message->as_string;
    }

    unless (scalar @spool) {
        $self->add_stash($request, 'notice', 'no_message_to_moderate');
        $log->syslog('info',
            'MODINDEX %s from %s refused, no message to moderate',
            $name, $sender);
        return undef;
    }

    unless (
        Sympa::send_file(
            $list,
            'modindex',
            $sender,
            {   'spool' => \@spool,          #FIXME: Use msg_list.
                'total' => scalar(@spool),
            }
        )
    ) {
        $log->syslog('notice', 'Unable to send template "modindex" to %s',
            $sender);
        $self->add_stash($request, 'intern');
        return undef;
    }

    $log->syslog('info', 'MODINDEX %s from %s accepted (%.2f seconds)',
        $name, $sender, Time::HiRes::time() - $self->{start_time});

    return 1;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Request::Handler::modindex - modindex request handler

=head1 DESCRIPTION

Sends a list of current messages to moderate of a list,
using 'modindex' template
(look into moderation spool).

=head1 SEE ALSO

L<Sympa::Request::Handler>, L<Sympa::Spool::Moderation>.

=head1 HISTORY

=cut
