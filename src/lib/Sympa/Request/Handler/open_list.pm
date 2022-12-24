# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright 2017, 2018, 2020, 2022 The Sympa Community. See the
# AUTHORS.md file at the top-level directory of this distribution and at
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

package Sympa::Request::Handler::open_list;

use strict;
use warnings;
use English qw(-no_match_vars);

use Sympa;
use Sympa::Aliases;
use Conf;
use Sympa::Log;

use base qw(Sympa::Request::Handler);

my $log = Sympa::Log->instance;

use constant _action_scenario => undef;    # Only listmasters allowed.

# Old name: do_restore_list() in wwsympa.fcgi.
sub _twist {
    my $self    = shift;
    my $request = shift;

    my $list   = $request->{current_list};
    my $mode   = $request->{mode} || 'open';
    my $sender = $request->{sender};
    my $notify = $request->{notify};

    if ($mode eq 'open') {
        unless (grep { $list->{'admin'}{'status'} eq $_ }
            qw(closed family_closed)) {
            $self->add_stash($request, 'user', 'not_closed',
                {listname => $list->{'name'}});
            $log->syslog('info', 'List not closed');
            return undef;
        }
    } elsif ($mode eq 'install') {
        unless ($list->{'admin'}{'status'} eq 'pending') {
            $self->add_stash($request, 'user', 'didnt_change_anything',
                {listname => $list->{'name'}});
            $log->syslog('info',
                'Didn\'t change really the status, nothing to do');
            return undef;
        }
    } else {
        die 'bug in logic. Ask developer';
    }

    # Change status & save config.
    $list->{'admin'}{'status'} = 'open';
    unless ($list->save_config($sender)) {
        $self->add_stash($request, 'intern', 'cannot_save_config',
            {'listname' => $list->{'name'}});
        $log->syslog('info', 'Cannot save config file');
        return undef;
    }

    if ($mode eq 'open') {
        # Restore permanent/transitional list users dumped by close_list.
        $list->restore_users('member');
        $list->restore_users('owner');
        $list->restore_users('editor');
    } elsif ($mode eq 'install') {
        # Since initial permanent list users have been stored by create_list
        # or create_automatic_list, add transitional owners/editors from
        # external data sources.
        $list->sync_include('owner');
        $list->sync_include('editor');
    }

    # Install new aliases.
    my $aliases = Sympa::Aliases->new(
        Conf::get_robot_conf($list->{'domain'}, 'alias_manager'));
    if ($aliases and $aliases->add($list)) {
        $self->add_stash($request, 'notice', 'auto_aliases',
            {listname => $list->{'name'} . '@' . $list->{'domain'}});
    } else {
        ;
    }

    if ($mode eq 'open') {
        $self->add_stash($request, 'notice', 'list_restored',
            {listname => $list->{'name'}});

        $log->add_stat(
            robot     => $list->{'domain'},
            list      => $list->{'name'},
            operation => 'restore_list',
            mail      => $sender,
            client    => $self->{scenario_context}->{remote_addr},
        );
    } elsif ($mode eq 'install') {
        Sympa::send_notify_to_listmaster($list, 'list_created',
            [$list->{'name'}]);
        $list->send_notify_to_owner('list_created', [$list->{'name'}])
            if $notify;
    }

    return 1;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Request::Handler::open_list - open_list request handler

=head1 DESCRIPTION

TBD.

=head1 HISTORY

L<Sympa::Request::Handler::open_list> appeared on Sympa 6.2.23b.

=cut
