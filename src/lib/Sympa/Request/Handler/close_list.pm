# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright 2017, 2018 The Sympa Community. See the AUTHORS.md file at the
# top-level directory of this distribution and at
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

package Sympa::Request::Handler::close_list;

use strict;
use warnings;
use File::Path qw();

use Sympa;
use Sympa::Aliases;
use Conf;
use Sympa::DatabaseManager;
use Sympa::Log;
use Sympa::Spool::Task;
use Sympa::Tools::File;

use base qw(Sympa::Request::Handler);

my $log = Sympa::Log->instance;

use constant _action_scenario => undef;    # Only privileged owners allowed.

# Old names: Sympa::List::close_list(), Sympa::List::purge() and
# Sympa::List::set_status_family_closed().
sub _twist {
    my $self    = shift;
    my $request = shift;

    my $list   = $request->{current_list};
    my $sender = $request->{sender};
    my $mode   = $request->{mode} || 'close';
    my $notify = $request->{notify};

    # If list is included by another list, then it cannot be removed.
    if ($list->is_included) {
        $log->syslog('err',
            'List %s is included by other list: cannot close it', $list);
        $self->add_stash($request, 'user', 'cannot_close_list',
            {reason => 'included', listname => $list->{'name'}});
        return undef;
    }

    if ($mode eq 'close') {
        if (grep { $list->{'admin'}{'status'} eq $_ }
            qw(closed family_closed)) {
            $log->syslog('err',
                'List %s is already closed: cannot close it again', $list);
            $self->add_stash($request, 'user', 'already_closed',
                {listname => $list->{'name'}});
            return undef;
        }

        _close($self, $request);
        $log->syslog(
            'info', 'The list %s is set in status %s',
            $list,  $list->{'admin'}{'status'}
        );
        $self->add_stash($request, 'notice', 'list_closed',
            {listname => $list->{'name'}});
        #FIXME: No owners!
        $list->send_notify_to_owner('list_closed_family', {})
            if $list->{'admin'}{'family_name'};

        $log->add_stat(
            robot     => $list->{'domain'},
            list      => $list->{'name'},
            operation => 'close_list',
            parameter => '',
            mail      => $sender,
            client    => $self->{scenario_context}->{remote_addr},
        );
    } elsif ($mode eq 'install') {
        unless ($list->{'admin'}{'status'} eq 'pending') {
            $log->syslog('err',
                'Didn\'t change really the status, nothing to do');
            $self->add_stash($request, 'user', 'didnt_change_anything',
                {listname => $list->{'name'}});
            return undef;
        }

        Sympa::send_notify_to_listmaster($list, 'list_rejected',
            [$list->{'name'}]);
        $list->send_notify_to_owner('list_rejected', [$list->{'name'}])
            if $notify;

        _close($self, $request);
        $log->syslog(
            'info', 'The list %s is set in status %s',
            $list,  $list->{'admin'}{'status'}
        );

        $log->add_stat(
            robot     => $list->{'domain'},
            list      => $list->{'name'},
            operation => 'list_rejected',
            parameter => '',
            mail      => $sender,
            client    => $self->{scenario_context}->{remote_addr},
        );
    } elsif ($mode eq 'purge') {
        unless (grep { $list->{'admin'}{'status'} eq $_ }
            qw(closed family_closed)) {
            _close($self, $request);
        }
        _purge($self, $request);
        $log->syslog('info', 'The list %s is purged', $list);
        $self->add_stash($request, 'notice', 'list_purged',
            {listname => $list->{'name'}});

        $log->add_stat(
            robot     => $list->{'domain'},
            list      => $list->{'name'},
            operation => 'purge_list',
            parameter => '',
            mail      => $sender,
            client    => $self->{scenario_context}->{remote_addr},
        );
    } else {
        die 'bug in logic. Ask developer';
    }

    return 1;
}

sub _close {
    my $self    = shift;
    my $request = shift;

    my $list   = $request->{current_list};
    my $sender = $request->{sender};

    my $aliases = Sympa::Aliases->new(
        Conf::get_robot_conf($list->{'domain'}, 'alias_manager'));
    $aliases->del($list) if $aliases;

    # Dump users.
    $list->dump_users('member');
    $list->dump_users('owner');
    $list->dump_users('editor');

    ## Delete users
    my @users;
    for (
        my $user = $list->get_first_list_member();
        $user;
        $user = $list->get_next_list_member()
    ) {
        push @users, $user->{'email'};
    }
    $list->delete_list_member('users' => \@users);

    # Remove entries from admin_table.
    foreach my $role (qw(editor owner)) {
        $list->delete_list_admin($role, [$list->get_admins_email($role)]);
    }

    # Change status & save config.
    $list->{'admin'}{'status'} =
        $list->{'admin'}{'family_name'} ? 'family_closed' : 'closed';
    $list->{'admin'}{'defaults'}{'status'} = 0;    #FIXME
    unless (
        $list->save_config(
            $sender || Sympa::get_address($list, 'listmaster')
        )
    ) {
        $self->add_stash($request, 'intern', 'cannot_save_config',
            {'listname' => $list->{'name'}});
        $log->syslog('info', 'Cannot save config file');
    }

    return 1;
}

# Old name: (part of) Sympa::List::purge().
sub _purge {
    my $self    = shift;
    my $request = shift;

    my $list   = $request->{current_list};
    my $sender = $request->{sender};

    # Remove tasks for this list.
    my $spool = Sympa::Spool::Task->new(context => $list);
    while (1) {
        my ($task, $handle) = $spool->next(no_filter => 1);

        if ($task and $handle) {
            next
                unless ref $task->{context} eq 'Sympa::List'
                and $task->{context}->get_id eq $list->get_id;

            $spool->remove($handle);
        } elsif ($handle) {
            next;
        } else {
            last;
        }
    }

    #FIXME: Lock directories to remove them safely.
    my $error;
    File::Path::remove_tree($list->get_archive_dir,      {error => \$error});
    File::Path::remove_tree($list->get_digest_spool_dir, {error => \$error});
    File::Path::remove_tree($list->get_bounce_dir,       {error => \$error});

    # Clean list table if needed.
    my $sdm = Sympa::DatabaseManager->instance;
    unless (
        $sdm
        and $sdm->do_prepared_query(
            q{DELETE FROM list_table
                  WHERE name_list = ? AND robot_list = ?},
            $list->{'name'}, $list->{'domain'}
        )
    ) {
        $log->syslog('err', 'Cannot remove list %s from table', $list);
    }
    unless (
        $sdm
        and $sdm->do_prepared_query(
            q{DELETE FROM inclusion_table
              WHERE target_inclusion = ?},
            $list->get_id
        )
    ) {
        $log->syslog('err', 'Cannot remove list %s from table', $list);
    }

    Sympa::Tools::File::remove_dir($list->{'dir'});

    # Clean memory cache. FIXME
    $list->destroy_multiton;

    return 1;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Request::Handler::close_list - close_list request handler

=head1 DESCRIPTION

Closes the list (remove from DB, remove aliases, change status to 'closed'
or 'family_closed'), or purges the list.

TBD.

=head1 HISTORY

L<Sympa::Request::Handler::close_list> appeared on Sympa 6.2.23b.

=cut
