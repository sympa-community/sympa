# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
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

package Sympa::Request::Handler::open_list;

use strict;
use warnings;
use English qw(-no_match_vars);
use File::Path qw();

use Sympa;
use Sympa::Aliases;
use Conf;
use Sympa::DatabaseManager;
use Sympa::Log;
use Sympa::Task;
use Sympa::Tools::File;

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

    # Dump initial permanent owners/editors in config file.
    if ($mode eq 'install') {
        my ($fh, $fh_config);
        foreach my $role (qw(owner editor)) {
            my $file   = $list->{'dir'} . '/' . $role . '.dump';
            my $config = $list->{'dir'} . '/config';

            if (    !-e $file
                and open($fh,        '>', $file)
                and open($fh_config, '<', $config)) {
                local $RS = '';    # read paragraph by each
                my $admins = join '', grep {/\A\s*$role\b/} <$fh_config>;
                print $fh $admins;
                close $fh;
                close $fh_config;
            }
        }
    }
    # Load permanent users.
    $list->suck_user('member');
    $list->suck_user('owner');
    $list->suck_user('editor');
    # Load initial transitional owners/editors from external data sources.
    if ($mode eq 'install') {
        $list->sync_include_admin;
    }

    # Install new aliases.
    my $aliases = Sympa::Aliases->new(
        Conf::get_robot_conf($list->{'domain'}, 'alias_manager'));
    if ($aliases and $aliases->add($list)) {
        $self->add_stash($request, 'notice', 'auto_aliases');
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
