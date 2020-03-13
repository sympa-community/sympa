# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright 2018, 2020 The Sympa Community. See the AUTHORS.md
# file at the top-level directory of this distribution and at
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

package Sympa::Spool::Task;

use strict;
use warnings;

use Conf;
use Sympa::List;

use base qw(Sympa::Spool);

sub _directories {
    return {directory => $Conf::Conf{'queuetask'},};
}

use constant _generator => 'Sympa::Task';

use constant _marshal_format => '%ld.%s.%s.%s@%s';
use constant _marshal_keys   => [qw(date label model localpart domainpart)];
use constant _marshal_regexp =>
    qr{\A(\d+)[.](\w*)[.](\w+)[.](?:([^\s\@]*)\@([\w\.\-*]*)|_global)\z};

sub _filter {
    my $self     = shift;
    my $metadata = shift;

    return undef unless $metadata and defined $metadata->{date};
    return 0 if time < $metadata->{date};
    return 1;
}

sub _load {
    my $self = shift;

    unless ($self->{_glob_pattern}) {
        $self->_create_all_tasks();
    }
    $self->SUPER::_load();
}

sub quarantine {
    my $self   = shift;
    my $handle = shift;

    $self->remove($handle);
}

# Private function to create all necessary tasks.
sub _create_all_tasks {
    my $self = shift;

    my $current_date = time;

    my $existing_tasks = $self->_existing_tasks;

    # Create global tasks.
    foreach my $model (keys %{Sympa::Task::site_models()}) {
        next if ${$existing_tasks->{'*'} || {}}{$model};

        my $task = $self->_generator->new(
            context => '*',
            date    => $current_date,
            model   => $model
        );
        next unless $task;
        $self->store($task);
    }

    # Create list tasks.
    foreach my $robot (Sympa::List::get_robots()) {
        my $all_lists = Sympa::List::get_lists($robot);

        foreach my $list (@{$all_lists || []}) {
            foreach my $model (keys %{Sympa::Task::list_models()}) {
                next if ${$existing_tasks->{$list->get_id} || {}}{$model};

                next unless $list->{'admin'}{'status'} eq 'open';
                if ($model eq 'sync_include') {
                    # Create tasks only when they are required.
                    next
                        unless $list->has_data_sources
                        or $list->has_included_users;
                }

                my $task = $self->_generator->new(
                    context => $list,
                    date    => $current_date,
                    model   => $model
                );
                next unless $task;
                $self->store($task);
            }
        }
    }
}

# Private function to list all existing tasks.
# Old name: Sympa::Task::list_tasks().
sub _existing_tasks {
    my $self = shift;

    my $existing_tasks = {};

    # Get all entries.
    $self->{_metadatas} = $self->SUPER::_load()
        or return {};
    while (1) {
        my ($task, $handle) = $self->next(no_filter => 1, no_lock => 1);

        if ($task and $handle) {
            my $id =
                (ref $task->{context} eq 'Sympa::List')
                ? $task->{context}->get_id
                : '*';
            my $model = $task->{model};

            $existing_tasks->{$id}{$model} = 1;
        } elsif ($handle) {
            next;
        } else {
            last;
        }
    }

    return $existing_tasks;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Spool::Task - Spool for tasks

=head1 SYNOPSIS

  use Sympa::Spool::Task;
  my $spool = Sympa::Spool::Task->new;

  $spool->store($task);

  my ($task, $handle) = $spool->next;

=head1 DESCRIPTION

L<Sympa::Spool::Task> implements the spool for tasks.

=head2 Methods

See also L<Sympa::Spool/"Public methods">.

=over

=item next ( [ no_filter =E<gt> 1 ], [ no_lock =E<gt> 1 ] )

Order is controlled by date element of file name.
if C<no_filter> is I<not> set,
messages with date newer than current time are skipped.

All necessary tasks are created and stored into spool in advance.

=item quarantine ( $handle )

Removes a task: The same as remove().
This spool does not have C<bad/> subdirectory.

=back

=head2 Context and metadata

See also L<Sympa::Spool/"Marshaling and unmarshaling metadata">.

This class particularly gives following metadata:

=over

=item {date}

Unix time when task will be executed at the next time.

=item {label}

=item {model}

TBD.

=back

=head1 CONFIGURATION PARAMETERS

Following site configuration parameters in sympa.conf will be referred.

=over

=item queuetask

Directory path of task spool.

=back

=head1 SEE ALSO

L<task_manager(8)>, L<Sympa::Spool>, L<Sympa::Task>.

=head1 HISTORY

L<Sympa::Spool::Task> appeared on Sympa 6.2.37b.2.

=cut
