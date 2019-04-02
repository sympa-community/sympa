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

package Sympa::Request::Handler::global_set;

use strict;
use warnings;

use Sympa;
use Sympa::List;
use Sympa::Log;
use Sympa::Scenario;
use Sympa::Spindle::ProcessRequest;

use base qw(Sympa::Request::Handler);

my $log = Sympa::Log->instance;

use constant _action_scenario => undef;

# Old name: (part of) Sympa::Commands::set().
sub _twist {
    my $self    = shift;
    my $request = shift;

    my $sender = $request->{sender};

    my $auth_method =
          $request->{smime_signed} ? 'smime'
        : $request->{md5_check}    ? 'md5'
        : $request->{dkim_pass}    ? 'dkim'
        :                            'smtp';

    # Recursive call to subroutine.
    my @target_lists;
    foreach my $list (
        Sympa::List::get_which($sender, $request->{context}, 'member')) {
        # Skip hidden lists.
        my $result =
            Sympa::Scenario->new($list, 'visibility')
            ->authz($auth_method, $self->{scenario_context});
        my $action = $result->{'action'} if ref $result eq 'HASH';

        unless ($action) {
            my $error =
                sprintf
                'Unable to evaluate scenario "visibility" for list %s',
                $list->get_id;
            Sympa::send_notify_to_listmaster(
                $list,
                'intern_error',
                {   'error'  => $error,
                    'who'    => $sender,
                    'cmd'    => $request->{cmd_line},
                    'action' => 'Command process'
                }
            );
            next;
        }

        if ($action =~ /\Areject\b/i) {
            next;
        }

        push @target_lists, $list;
    }
    unless (@target_lists) {
        $self->add_stash($request, 'user', 'no_lists');
        $log->syslog('info',
            'SET * %s%s from %s refused, no lists to process',
            $request->{reception}, $request->{visibility}, $sender);
        return undef;
    }

    my $spindle = Sympa::Spindle::ProcessRequest->new(
        context => [@target_lists],
        action  => 'set',
        (   map { ($_ => $request->{$_}) }
                qw(email reception visibility
                sender smime_signed md5_check dkim_pass
                cmd_line)
        ),

        scenario_context => $self->{scenario_context},
        stash            => $self->{stash},
    );
    $spindle and $spindle->spin;

    return 1;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Request::Handler::global_set - global 'set' request handler

=head1 DESCRIPTION

Change subscription options (reception or visibility).

=head1 SEE ALSO

L<Sympa::Request::Handler>.

=head1 HISTORY

=cut
