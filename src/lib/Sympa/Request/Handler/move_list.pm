# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright 2017, 2018, 2019 The Sympa Community. See the AUTHORS.md file at
# the top-level directory of this distribution and at
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

package Sympa::Request::Handler::move_list;

use strict;
use warnings;
use File::Copy qw();

use Sympa;
use Sympa::Aliases;
use Conf;
use Sympa::DatabaseManager;
use Sympa::List;
use Sympa::Log;
use Sympa::Spool;
use Sympa::Spool::Archive;
use Sympa::Spool::Auth;
use Sympa::Spool::Automatic;
use Sympa::Spool::Bounce;
use Sympa::Spool::Digest::Collection;
use Sympa::Spool::Held;
use Sympa::Spool::Incoming;
use Sympa::Spool::Moderation;
use Sympa::Spool::Outgoing;
use Sympa::Spool::Task;
use Sympa::Tools::File;

use base qw(Sympa::Request::Handler);

my $log = Sympa::Log->instance;

use constant _action_regexp   => qr{reject|listmaster|do_it}i;
use constant _action_scenario => 'create_list';

# Old name: Sympa::Admin::rename_list().
sub _twist {
    my $self    = shift;
    my $request = shift;

    my $robot_id     = $request->{context};
    my $current_list = $request->{current_list};
    my $listname     = lc($request->{listname} || '');
    my $mode         = $request->{mode};
    my $pending      = $request->{pending};
    my $notify       = $request->{notify};
    my $sender       = $request->{sender};

    die 'bug in logic. Ask developer'
        unless ref $current_list eq 'Sympa::List';

    # No changes.
    if ($current_list->get_id eq $listname . '@' . $robot_id) {
        $log->syslog('err', 'Cannot rename list: List %s will not be changed',
            $current_list);
        $self->add_stash(
            $request, 'user',
            'unable_to_rename_list',
            {   listname     => $current_list->get_id,
                new_listname => $listname . '@' . $robot_id,
                reason       => 'no_change'
            }
        );
        return undef;
    }

    # If list is included by another list, then it cannot be renamed.
    unless ($mode and $mode eq 'copy') {
        if ($current_list->is_included) {
            $log->syslog('err',
                'List %s is included by other list: cannot rename it',
                $current_list);
            $self->add_stash(
                $request, 'user',
                'unable_to_rename_list',
                {   listname     => $current_list->get_id,
                    new_listname => $listname . '@' . $robot_id,
                    reason       => 'included'
                }
            );
            return undef;
        }
    }

    # Check new listname.
    my @stash = Sympa::Aliases::check_new_listname($listname, $robot_id);
    if (@stash) {
        $self->add_stash($request, @stash);
        return undef;
    }

    # Rename or create this list directory itself.
    my $new_dir;
    my $home = $Conf::Conf{'home'};
    my $base = $home . '/' . $robot_id;
    if (-d $base) {
        $new_dir = $base . '/' . $listname;
    } elsif ($robot_id eq $Conf::Conf{'domain'}) {
        # Default robot.
        $new_dir = $home . '/' . $listname;
    } else {
        $log->syslog('err', 'Unknown robot %s', $robot_id);
        $self->add_stash($request, 'user', 'unknown_robot',
            {new_robot => $robot_id});
        return undef;
    }

    if ($mode and $mode eq 'copy') {
        _copy($self, $request, $new_dir) or return undef;
    } else {
        _move($self, $request, $new_dir) or return undef;
    }

    my $list;
    unless ($list =
        Sympa::List->new($listname, $robot_id, {reload_config => 1})) {
        $log->syslog('err', 'Unable to load %s while renaming', $listname);
        $self->add_stash($request, 'intern');
        return undef;
    }

    if ($listname ne $request->{listname}) {
        $self->add_stash($request, 'notice', 'listname_lowercased');
    }

    if ($list->{'admin'}{'status'} eq 'open') {
        # Install new aliases.
        my $aliases = Sympa::Aliases->new(
            Conf::get_robot_conf($robot_id, 'alias_manager'));
        if ($aliases and $aliases->add($list)) {
            $self->add_stash($request, 'notice', 'auto_aliases');
        }
    } elsif ($list->{'admin'}{'status'} eq 'pending') {
        # Notify listmaster that creation list is moderated.
        Sympa::send_notify_to_listmaster(
            $list,
            'request_list_renaming',
            {   'new_listname' => $listname,
                'old_listname' => $current_list->{'name'},
                'email'        => $sender,
                'mode'         => $mode,
            }
        ) if $notify;

        $self->add_stash($request, 'notice', 'pending_list');
    }

    if ($mode and $mode eq 'copy') {
        $log->add_stat(
            robot     => $list->{'domain'},
            list      => $list->{'name'},
            operation => 'copy_list',
            mail      => $sender,
            client    => $self->{scenario_context}->{remote_addr},
        );
    }

    return 1;
}

sub _move {
    my $self    = shift;
    my $request = shift;
    my $new_dir = shift;

    my $robot_id     = $request->{context};
    my $listname     = lc($request->{listname} || '');
    my $current_list = $request->{current_list};
    my $sender       = $request->{sender};
    my $pending      = $request->{pending};

    # Remove aliases and dump subscribers.
    my $aliases = Sympa::Aliases->new(
        Conf::get_robot_conf($current_list->{'domain'}, 'alias_manager'));
    $aliases->del($current_list) if $aliases;
    $current_list->dump_users('member');
    $current_list->dump_users('owner');
    $current_list->dump_users('editor');

    # Set list status to pending if creation list is moderated.
    # Save config file for the new() later to reload it.
    $current_list->{'admin'}{'status'} = 'pending'
        if $pending;
    _modify_custom_subject($request, $current_list);
    $current_list->save_config($sender);

    # Start moving list.
    my $sdm       = Sympa::DatabaseManager->instance;
    my $fake_list = bless {
        name   => $listname,
        domain => $robot_id,
        dir    => $new_dir,
    } => 'Sympa::List';

    # If subscribtion are stored in database rewrite the database.
    unless (
        $sdm
        and $sdm->do_prepared_query(
            q{UPDATE subscriber_table
              SET list_subscriber = ?, robot_subscriber = ?
              WHERE list_subscriber = ? AND robot_subscriber = ?},
            $listname,               $robot_id,
            $current_list->{'name'}, $current_list->{'domain'}
        )
        and $sdm->do_prepared_query(
            q{UPDATE admin_table
              SET list_admin = ?, robot_admin = ?
              WHERE list_admin = ? AND robot_admin = ?},
            $listname,               $robot_id,
            $current_list->{'name'}, $current_list->{'domain'}
        )
        and $sdm->do_prepared_query(
            q{UPDATE list_table
              SET name_list = ?, robot_list = ?
              WHERE name_list = ? AND robot_list = ?},
            $listname,               $robot_id,
            $current_list->{'name'}, $current_list->{'domain'}
        )
        and $sdm->do_prepared_query(
            q{UPDATE exclusion_table
              SET list_exclusion = ?, robot_exclusion = ?
              WHERE list_exclusion = ? AND robot_exclusion = ?},
            $listname,               $robot_id,
            $current_list->{'name'}, $current_list->{'domain'}
        )
        and $sdm->do_prepared_query(
            q{UPDATE inclusion_table
              SET target_inclusion = ?
              WHERE target_inclusion = ?},
            sprintf('%s@%s', $listname, $robot_id),
            $current_list->get_id
        )
    ) {
        $log->syslog('err',
            'Unable to rename list %s to %s@%s in the database',
            $current_list, $listname, $robot_id);
        $self->add_stash($request, 'intern');
        return undef;
    }

    # Move stats.
    # Continue even if there are some troubles.
    unless (
        $sdm
        and $sdm->do_prepared_query(
            q{UPDATE stat_table
              SET list_stat = ?, robot_stat = ?
              WHERE list_stat = ? AND robot_stat = ?},
            $listname,               $robot_id,
            $current_list->{'name'}, $current_list->{'domain'}
        )
        and $sdm->do_prepared_query(
            q{UPDATE stat_counter_table
              SET list_counter = ?, robot_counter = ?
              WHERE list_counter = ? AND robot_counter = ?},
            $listname,               $robot_id,
            $current_list->{'name'}, $current_list->{'domain'}
        )
    ) {
        $log->syslog('err',
            'Unable to transfer stats from list %s to list %s@%s',
            $current_list, $listname, $robot_id);
    }

    # Rename files in spools.
    # Continue even if there are some troubles.
    foreach my $spool_class (
        qw(Sympa::Spool::Automatic Sympa::Spool::Bounce Sympa::Spool::Incoming
        Sympa::Spool::Auth Sympa::Spool::Held Sympa::Spool::Moderation
        Sympa::Spool::Archive Sympa::Spool::Digest::Collection
        Sympa::Spool::Task)
    ) {
        my $spool = $spool_class->new(context => $current_list);
        next unless $spool;

        while (1) {
            my ($message, $handle) = $spool->next(no_filter => 1);
            last unless $handle;
            next
                unless $message
                and ref $message->{context} eq 'Sympa::List'
                and $message->{context}->get_id eq $current_list->get_id;

            # Remove old HTML view if any (For moderation spool).
            $spool->html_remove($message) if $spool->can('html_remove');

            # Rename message in spool.
            $message->{context} = $fake_list;
            my $marshalled = $spool->marshal($message, keep_keys => 1);
            unless ($handle->rename($spool->{directory} . '/' . $marshalled))
            {
                $log->syslog('err',
                    'Cannot rename message in %s from %s to %s: %m',
                    $spool, $handle->basename, $marshalled);
            }
        }
    }

    my $queue;
    my $dh;

    # Rename files in topic spool.
    # Continue even if there are some troubles.
    #FIXME: Refactor to use Sympa::Spool subclass.
    $queue = $Conf::Conf{'queuetopic'};
    unless (opendir $dh, $queue) {
        $log->syslog('err', 'Unable to open topic spool %s: %m', $queue);
    } else {
        my $current_list_id = $current_list->get_id;
        my $new_list_id     = $fake_list->get_id;

        foreach my $file (sort readdir $dh) {
            next unless 0 == index $file, $current_list_id . '.';

            my $newfile = sprintf '%s.%s', $new_list_id,
                substr($file, length($current_list_id) + 1);
            unless (rename $queue . '/' . $file, $queue . '/' . $newfile) {
                $log->syslog('err',
                    'Unable to rename file in %s from %s to %s: %m',
                    $queue, $file, $newfile);
            }
        }

        closedir $dh;
    }

    # Rename files in outgoing spool.
    # Continue even if there are some troubles.
    my $spool = Sympa::Spool::Outgoing->new(context => $current_list);
    while (1) {
        my ($message, $handle) = $spool->next(no_filter => 1);
        last unless $handle;
        next
            unless $message
            and ref $message->{context} eq 'Sympa::List'
            and $message->{context}->get_id eq $current_list->get_id;

        my $pct_directory =
            $spool->{pct_directory} . '/' . $handle->basename(1);
        my $msg_file = $spool->{msg_directory} . '/' . $handle->basename(1);
        my $pct_file = $pct_directory . '/' . $handle->basename;

        # Rename message in spool.
        $message->{context} = $fake_list;
        my $marshalled = Sympa::Spool::marshal_metadata(
            $message,
            '%s.%s.%d.%f.%s@%s_%s,%ld,%d',
            [   qw(priority packet_priority date time localpart domainpart tag pid rand)
            ]
        );
        my $new_pct_directory = $spool->{pct_directory} . '/' . $marshalled;
        my $new_msg_file      = $spool->{msg_directory} . '/' . $marshalled;
        my $new_pct_file      = $new_pct_directory . '/' . $handle->basename;

        File::Copy::cp($msg_file, $new_msg_file)
            unless -e $new_msg_file;

        mkdir $new_pct_directory unless -d $new_pct_directory;
        unless (-d $new_pct_directory and $handle->rename($new_pct_file)) {
            $log->syslog('err',
                'Cannot rename message in %s from %s to %s: %m',
                $spool, $pct_file, $new_pct_file);
            next;
        }

        if (rmdir $pct_directory) {
            # No more packet.
            unlink $msg_file;
        }
    }

    # Try renaming archive.
    # Continue even if there are some troubles.
    my $arc_dir     = $current_list->get_archive_dir;
    my $new_arc_dir = $fake_list->get_archive_dir;
    if (-d $arc_dir and $arc_dir ne $new_arc_dir) {
        unless (File::Copy::move($arc_dir, $new_arc_dir)) {
            $log->syslog('err', 'Unable to rename archive %s to %s: %m',
                $arc_dir, $new_arc_dir);
        }
    }

    # Try renaming bounces and tracking information.
    # Continue even if there are some troubles.
    my $bounce_dir     = $current_list->get_bounce_dir;
    my $new_bounce_dir = $fake_list->get_bounce_dir;
    if (-d $bounce_dir and $bounce_dir ne $new_bounce_dir) {
        unless (File::Copy::move($bounce_dir, $new_bounce_dir)) {
            $log->syslog('err', 'Unable to rename bounces from %s to %s: %m',
                $bounce_dir, $new_bounce_dir);
        }
    }
    unless (
        $sdm
        and $sdm->do_prepared_query(
            q{UPDATE notification_table
              SET list_notification = ?, robot_notification = ?
              WHERE list_notification = ? AND robot_notification = ?},
            $listname,               $robot_id,
            $current_list->{'name'}, $current_list->{'domain'}
        )
    ) {
        $log->syslog(
            'err',
            'Unable to transfer tracking information from list %s to list %s@%s',
            $current_list,
            $listname,
            $robot_id
        );
    }
    # Clear old HTML view.
    Sympa::Tools::File::remove_dir(
        sprintf '%s/%s/%s',
        $Conf::Conf{'viewmail_dir'},
        'bounce', $current_list->get_id
    );

    # End moving list.
    unless (File::Copy::move($current_list->{'dir'}, $new_dir)) {
        $log->syslog(
            'err',
            'Unable to rename %s to %s: %m',
            $current_list->{'dir'}, $new_dir
        );
        $self->add_stash($request, 'intern');
        return undef;
    }

    return 1;
}

# Old name: Sympa::Admin::clone_list_as_empty() etc.
sub _copy {
    my $self    = shift;
    my $request = shift;
    my $new_dir = shift;

    my $robot_id     = $request->{context};
    my $listname     = lc($request->{listname} || '');
    my $current_list = $request->{current_list};
    my $sender       = $request->{sender};
    my $pending      = $request->{pending};

    unless (mkdir $new_dir, 0775) {
        $log->syslog('err', 'Failed to create directory %s: %m', $new_dir);
        $self->add_stash($request, 'intern');
        return undef;
    }

    # Dump permanent/transitional owners and moderators (Not subscribers).
    $current_list->dump_users('owner');
    $current_list->dump_users('editor');

    chmod 0775, $new_dir;
    foreach my $subdir ('etc', 'web_tt2', 'mail_tt2', 'data_sources') {
        if (-d $new_dir . '/' . $subdir) {
            unless (
                Sympa::Tools::File::copy_dir(
                    $current_list->{'dir'} . '/' . $subdir,
                    $new_dir . '/' . $subdir
                )
            ) {
                $log->syslog(
                    'err',
                    'Failed to copy_directory %s: %m',
                    $new_dir . '/' . $subdir
                );
                $self->add_stash($request, 'intern');
                return undef;
            }
        }
    }
    # copy mandatory files
    foreach my $file ('config', 'owner.dump', 'editor.dump') {
        unless (
            File::Copy::copy(
                $current_list->{'dir'} . '/' . $file,
                $new_dir . '/' . $file
            )
        ) {
            $log->syslog(
                'err',
                'Failed to copy %s: %m',
                $new_dir . '/' . $file
            );
            $self->add_stash($request, 'intern');
            return undef;
        }
    }
    # copy optional files
    foreach my $file ('message_header', 'message_footer', 'info', 'homepage')
    {
        if (-f $current_list->{'dir'} . '/' . $file) {
            unless (
                File::Copy::copy(
                    $current_list->{'dir'} . '/' . $file,
                    $new_dir . '/' . $file
                )
            ) {
                $log->syslog(
                    'err',
                    'Failed to copy %s: %m',
                    $new_dir . '/' . $file
                );
                $self->add_stash($request, 'intern');
                return undef;
            }
        }
    }

    my $new_list;
    # Now switch List object to new list, update some values.
    unless ($new_list = Sympa::List->new($listname, $robot_id)) {
        $log->syslog('info', 'Unable to load %s while renamming', $listname);
        $self->add_stash($request, 'intern');
        return undef;
    }
    $new_list->{'admin'}{'serial'} = 0;
    $new_list->{'admin'}{'creation'}{'email'} = $sender if ($sender);
    $new_list->{'admin'}{'creation'}{'date_epoch'} = time;

    # Set list status to pending if creation list is moderated.
    # Save config file for the new() later to reload it.
    $new_list->{'admin'}{'status'} = 'pending'
        if $pending;
    _modify_custom_subject($request, $new_list);
    $new_list->save_config($sender);

    # Store permanent/transitional owners and moderators (Not subscribers).
    $new_list->restore_users('owner');
    $new_list->restore_users('editor');

    return 1;
}

sub _modify_custom_subject {
    my $request  = shift;
    my $new_list = shift;

    return unless defined $new_list->{'admin'}{'custom_subject'};

    # Check custom_subject.
    my $custom_subject  = $new_list->{'admin'}{'custom_subject'};
    my $old_listname_re = $request->{current_list}->{'name'};
    $old_listname_re =~ s/([^\s\w\x80-\xFF])/\\$1/g;    # excape metachars
    my $listname = $request->{listname};

    $custom_subject =~ s/\b$old_listname_re\b/$listname/g;
    $new_list->{'admin'}{'custom_subject'} = $custom_subject;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Request::Handler::move_list - move_list request handler

=head1 DESCRIPTION

Renames a list or move a list to possibly beyond another virtual host.

On copy mode, Clone a list config including customization, templates,
scenario config but without archives, subscribers and shared.

=head2 Attributes

See also L<Sympa::Request/"Attributes">.

=over

=item {context}

Context of request.  The robot the new list will belong to.

=item {current_list}

Source of moving or copying.  An instance of L<Sympa::List>.

=item {listname}

The name of the new list.

=item {mode}

I<Optional>.
If it is set and its value is C<'copy'>,
won't erase source list.

=back

=head1 SEE ALSO

L<Sympa::Request::Collection>,
L<Sympa::Request::Handler>,
L<Sympa::Spindle::ProcessRequest>.

=head1 HISTORY

L<Sympa::Request::Handler::move_list> appeared on Sympa 6.2.23b.

=cut
