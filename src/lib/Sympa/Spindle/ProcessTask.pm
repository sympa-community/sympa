# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright 2018, 2019, 2020, 2021 The Sympa Community. See the
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

package Sympa::Spindle::ProcessTask;

use strict;
use warnings;
use English qw(-no_match_vars);

use Sympa;
use Conf;
use Sympa::DatabaseManager;
use Sympa::List;
use Sympa::Log;
use Sympa::Scenario;
use Sympa::Spool;
use Sympa::Spool::Listmaster;
use Sympa::Task;
use Sympa::Ticket;
use Sympa::Tools::File;
use Sympa::Tools::Time;
use Sympa::Tools::Text;
use Sympa::Tracking;
use Sympa::User;

use base qw(Sympa::Spindle);

my $log = Sympa::Log->instance;

use constant _distaff => 'Sympa::Spool::Task';

sub _init {
    my $self  = shift;
    my $state = shift;

    if ($state == 1) {
        # Process grouped notifications.
        Sympa::Spool::Listmaster->instance->flush;
    }

    1;
}

sub _twist {
    my $self = shift;
    my $task = shift;

    my $that = $task->{context};
    if (ref $that eq 'Sympa::List' and $that->{'admin'}{'status'} ne 'open') {
        # Skip closed lists: Remove task.
        return 1;
    }

    return _execute($self, $task);
}

### TASK EXECUTION SUBROUTINES ###

my %comm = (
    stop                        => 'do_stop',
    next                        => 'do_next',
    create                      => 'do_create',
    exec                        => 'do_exec',
    expire_bounce               => 'do_expire_bounce',
    purge_user_table            => 'do_purge_user_table',
    purge_logs_table            => 'do_purge_logs_table',
    purge_session_table         => 'do_purge_session_table',
    purge_spools                => 'do_purge_spools',
    purge_tables                => 'do_purge_tables',
    purge_one_time_ticket_table => 'do_purge_one_time_ticket_table',
    sync_include                => 'do_sync_include',
    purge_orphan_bounces        => 'do_purge_orphan_bounces',
    eval_bouncers               => 'do_eval_bouncers',
    process_bouncers            => 'do_process_bouncers',

    # commands which use a variable
    send_msg => 'do_send_msg',
    rm_file  => 'do_rm_file',

    # commands which return a variable
    select_subs => 'do_select_subs',

    # commands which return and use a variable
    delete_subs => 'do_delete_subs',
);

# Old name: execute() in task_manager.pl.
sub _execute {
    my $self = shift;
    my $task = shift;

    $log->syslog('notice', 'Running task %s', $task);

    die 'bug in logic. Ask developer' unless $task->{_parsed};

    my %vars;    # list of task vars
    my @lines = $task->lines;

    my $label = $task->{label};
    return undef if $label eq 'ERROR';

    if (defined $label and length $label) {
        my $line;
        while ($line = shift @lines) {
            next unless defined $line->{label};
            last if $line->{label} eq $label;
        }
    }

    # Execution.
    my $status;
    foreach my $line (@lines) {
        if ($line->{nature} eq 'assignment') {
            # Processing of the assignments.
            $status = $vars{$line->{var}} =
                _cmd_process($self, $task, $line, \%vars);
            last if not defined $status;
        } elsif ($line->{nature} eq 'command') {
            # Processing of the commands.
            $status = _cmd_process($self, $task, $line, \%vars);
            last if not defined $status or $status < 0;
        }
    }

    if (not defined $status) {
        $log->syslog('err', 'Error while processing task %s', $task);
        # Remove task.
        return undef;
    } elsif ($status < 0) {
        $log->syslog('notice', 'The task %s is now useless. Removing it',
            $task);
        # Remove task.
        return 1;
    } else {
        # Keep task.
        return 0;
    }
}

# Old name: cmd_process() in task_manager.pl.
sub _cmd_process {
    $log->syslog('debug2', '(%s, %s, %s, %s, %s, %s)', @_);
    my $self  = shift;
    my $task  = shift;
    my $line  = shift;
    my $Rvars = shift;    # variable list of the task

    my $command = $line->{command};    # command name

    unless (defined $comm{$command}) {
        return undef;
    } else {
        no strict 'refs';
        return $comm{$command}->($self, $task, $line, $Rvars);
    }
}

### command subroutines ###

# remove files whose name is given in the key 'file' of the hash
# Old name: rm_file() in task_manager.pl.
sub do_rm_file {
    my $self  = shift;
    my $task  = shift;
    my $line  = shift;
    my $Rvars = shift;

    my @tab = @{$line->{Rarguments} || []};
    my $var = $tab[0];

    foreach my $key (keys %{$Rvars->{$var}}) {
        my $file = $Rvars->{$var}{$key}{'file'};
        next unless $file;
        unless (unlink $file) {
            _error($task,
                "error in rm_file command : unable to remove $file");
            return undef;
        }
    }

    return 1;
}

# Old name: stop() in task_manager.pl.
sub do_stop {
    my $self = shift;
    my $task = shift;
    my $line = shift;

    $log->syslog('notice', '%s: stop %s', $line->{line}, $task);
    return -1;    # Remove task.
}

# Old name: send_msg() in task_manager.pl.
sub do_send_msg {
    my $self  = shift;
    my $task  = shift;
    my $line  = shift;
    my $Rvars = shift;

    my @tab      = @{$line->{Rarguments} || []};
    my $template = $tab[1];
    my $var      = $tab[0];

    $log->syslog('notice', 'Line %s: send_msg (%s)',
        $line->{line}, join(',', @tab));

    foreach my $email (keys %{$Rvars->{$var}}) {
        $log->syslog('notice', '--> message sent to %s', $email);
        unless (
            Sympa::send_file(
                $task->{context}, $template,
                $email,           $Rvars->{$var}{$email}
            )
        ) {
            $log->syslog('notice', 'Unable to send template %s to %s',
                $template, $email);
        }
    }

    return 1;
}

# Old name: next_cmd() in task_manager.pl.
sub do_next {
    my $self = shift;
    my $task = shift;
    my $line = shift;

    my @tab = @{$line->{Rarguments} || []};
    # conversion of the date argument into epoch format
    my $date  = Sympa::Tools::Time::epoch_conv($tab[0]);
    my $label = $tab[1];

    $log->syslog('notice', 'line %s of %s: next(%s, %s)',
        $line->{line}, $task->{model}, $date, $label);

    my $new_task = Sympa::Task->new(
        context => $task->{context},
        date    => $date,
        label   => $label,
        model   => $task->{model},
    );
    unless ($new_task and $self->{distaff}->store($new_task)) {
        _error($task,
            "error in create command : creation subroutine failure");
        return undef;
    }

    $log->syslog('notice', '--> new task %s', $new_task);

    return -1;    # Remove older task.
}

# Old name: select_subs() in task_manager.pl.
sub do_select_subs {
    my $self = shift;
    my $task = shift;
    my $line = shift;

    my @tab = @{$line->{Rarguments} || []};
    my $condition = $tab[0];
    $log->syslog('debug2', 'Line %s: select_subs (%s)',
        $line->{line}, $condition);

    my ($func, $date);
    if ($condition =~ /(older|newer)[(]([^\)]*)[)]/) {
        ($func, $date) = ($1, $2);
        # Conversion of the date argument into epoch format.
        $date = Sympa::Tools::Time::epoch_conv($date);
    } else {
        $log->syslog('err', 'Illegal condition %s', $condition);
        return {};
    }

    my %selection;
    my $list = $task->{context};
    unless (ref $list eq 'Sympa::List') {
        $log->syslog('err', 'No list');
        return {};
    }

    for (
        my $user = $list->get_first_list_member();
        $user;
        $user = $list->get_next_list_member()
    ) {
        if (   $func eq 'newer' and $date < $user->{update_date}
            or $func eq 'older' and $user->{update_date} < $date) {
            $selection{$user->{'email'}} = undef;
            $log->syslog('info', '--> user %s has been selected',
                $user->{'email'});
        }
    }

    return \%selection;
}

# Old name: delete_subs_cmd() in task_manager.pl.
# Not yet used.
sub do_delete_subs {
    my $self  = shift;
    my $task  = shift;
    my $line  = shift;
    my $Rvars = shift;

    my @tab = @{$line->{Rarguments} || []};
    my $var = $tab[0];

    $log->syslog('notice', 'Line %s: delete_subs (%s)', $line->{line}, $var);

    my $list = $task->{context};
    unless (ref $list eq 'Sympa::List') {
        $log->syslog('err', 'No list');
        return {};
    }

    my %selection;    # hash of subscriber emails who are successfully deleted

    foreach my $email (keys %{$Rvars->{$var}}) {
        $log->syslog('notice', '%s', $email);
        my $result = Sympa::Scenario->new($list, 'del')->authz(
            'smime',
            {   'sender' => $Conf::Conf{'listmaster'},    #FIXME
                'email'  => $email,
            }
        );
        my $action;
        $action = $result->{'action'} if (ref($result) eq 'HASH');
        if ($action =~ /reject/i) {
            #FIXME
            _error($task,
                "error in delete_subs command : deletion of $email not allowed"
            );
        } else {
            $log->syslog('notice', '--> %s deleted', $email);
            $list->delete_list_member([$email], operation => 'auto_del');
            $selection{$email} = {};
        }
    }

    return \%selection;
}

my $subarg_regexp = '(\w+)(|\((.*)\))';

# Old name: create_cmd() in task_manager.pl.
sub do_create {
    my $self = shift;
    my $task = shift;
    my $line = shift;

    my @tab          = @{$line->{Rarguments} || []};
    my $arg          = $tab[0];
    my $model        = $tab[1];
    my $model_choice = $tab[2];

    $log->syslog('notice', 'line %s: create(%s, %s, %s)',
        $line->{line}, $arg, $model, $model_choice);

    # recovery of the object type and object
    my $that;
    if ($arg =~ /$subarg_regexp/) {
        my $type   = $1;
        my $object = $3;

        if ($type eq 'list') {
            my ($name, $robot) = split /\@/, $object, 2;
            $that = Sympa::List->new($name, $robot, {just_try => 1});
        } else {
            $that = '*';
        }
    }
    unless ($that) {
        _error($task,
            "error in create command : don't know how to create $arg");
        return undef;
    }

    my $new_task = Sympa::Task->new(
        context => $that,
        date    => $task->{date},
        model   => $model
    );
    unless ($new_task and $self->{distaff}->store($new_task)) {
        _error($task,
            "error in create command : creation subroutine failure");
        return undef;
    }

    return 1;
}

# Old name: exec_cmd() in task_manager.pl.
sub do_exec {
    my $self = shift;
    my $task = shift;
    my $line = shift;

    my @tab = @{$line->{Rarguments} || []};
    my $file = $tab[0];

    $log->syslog('notice', 'Line %s: exec (%s)', $line->{line}, $file);
    system($file);

    return 1;
}

# Old name: purge_logs_table() in task_manager.pl.
sub do_purge_logs_table {
    my $self = shift;
    my $task = shift;
    my $line = shift;

    unless (_db_log_del()) {
        $log->syslog('err', 'Failed to delete logs');
        return undef;
    }

    $log->syslog('notice', 'Logs purged');

    if ($log->aggregate_stat) {
        $log->syslog('notice', 'Stats aggregated');
    }

    return 1;
}

# Deletes logs in RDBMS.
# If a log is older than $list->get_latest_distribution_date() - $delay
# expire the log.
# Old name: _db_log_del() in task_manager.pl.
sub _db_log_del {
    my ($exp, $date);

    my $sdm = Sympa::DatabaseManager->instance;

    $exp = Conf::get_robot_conf('*', 'logs_expiration_period');
    $date = time - ($exp * 31 * 24 * 60 * 60);
    unless (
        $sdm
        and $sdm->do_prepared_query(
            q{DELETE FROM logs_table
              WHERE date_logs <= ?},
            $date
        )
    ) {
        $log->syslog('err',
            'Unable to delete db_log entry from the database');
        return undef;
    }

    $exp = Conf::get_robot_conf('*', 'stats_expiration_period');
    $date = time - ($exp * 31 * 24 * 60 * 60);
    unless (
        $sdm->do_prepared_query(
            q{DELETE FROM stat_table
              WHERE date_stat <= ?},
            $date
        )
    ) {
        $log->syslog('err',
            'Unable to delete db_log entry from the database');
        return undef;
    }
    unless (
        $sdm->do_prepared_query(
            q{DELETE FROM stat_counter_table
              WHERE end_date_counter <= ?},
            $date
        )
    ) {
        $log->syslog('err',
            'Unable to delete db_log entry from the database');
        return undef;
    }

    return 1;
}

# Remove sessions from session_table if older than session_table_ttl or
# anonymous_session_table_ttl.
# Old name: Sympa::Session::purge_old_sessions(),
# purge_session_table() in task_manager.pl.
sub do_purge_session_table {
    my $self = shift;
    my $task = shift;
    my $line = shift;

    my $delay =
        Sympa::Tools::Time::duration_conv($Conf::Conf{'session_table_ttl'});
    my $anonymous_delay = Sympa::Tools::Time::duration_conv(
        $Conf::Conf{'anonymous_session_table_ttl'});

    unless ($delay) {
        $log->syslog('info', 'Exit with delay null');
        return undef;
    }
    unless ($anonymous_delay) {
        $log->syslog('info', 'Exit with anonymous delay null');
        return undef;
    }

    my @sessions;
    my $sth;
    my $sdm = Sympa::DatabaseManager->instance;
    unless ($sdm) {
        $log->syslog('err', 'Unavailable database connection');
        return undef;
    }

    my (@conditions, @anonymous_conditions);
    push @conditions, sprintf('%d > date_session', time - $delay) if $delay;
    push @anonymous_conditions,
        sprintf('%d > date_session', time - $anonymous_delay)
        if $anonymous_delay;

    my $condition           = join ' AND ', @conditions;
    my $anonymous_condition = join ' AND ', @anonymous_conditions,
        "email_session = 'nobody'", 'hit_session = 1';

    my $count_statement =
        sprintf q{SELECT COUNT(*) FROM session_table WHERE %s}, $condition;
    my $anonymous_count_statement =
        sprintf q{SELECT COUNT(*) FROM session_table WHERE %s},
        $anonymous_condition;

    my $statement = sprintf q{DELETE FROM session_table WHERE %s}, $condition;
    my $anonymous_statement = sprintf q{DELETE FROM session_table WHERE %s},
        $anonymous_condition;

    unless ($sth = $sdm->do_query($count_statement)) {
        $log->syslog('err', 'Unable to count old session');
        return undef;
    }

    my $total = $sth->fetchrow;
    if ($total == 0) {
        $log->syslog('debug', 'No sessions to expire');
    } else {
        unless ($sth = $sdm->do_query($statement)) {
            $log->syslog('err', 'Unable to purge old sessions');
            return undef;
        }
    }
    unless ($sth = $sdm->do_query($anonymous_count_statement)) {
        $log->syslog('err', 'Unable to count anonymous sessions');
        return undef;
    }
    my $anonymous_total = $sth->fetchrow;
    if ($anonymous_total == 0) {
        $log->syslog('debug', 'No anonymous sessions to expire');
    } else {
        unless ($sth = $sdm->do_query($anonymous_statement)) {
            $log->syslog('err', 'Unable to purge anonymous sessions');
            return undef;
        }
    }

    $log->syslog(
        'notice',
        '%s row removed in session_table',
        $total + $anonymous_total
    );
    return 1;
}

# Remove messages from spools if older than duration given by configuration.
# Old name: purge_spools() in task_manager.pl.
sub do_purge_spools {
    my $self = shift;
    my $task = shift;
    my $line = shift;

    # Expiring bad messages in incoming spools and archive spool.
    foreach my $queue (qw(queue queueautomatic queuebounce queueoutgoing)) {
        my $directory   = $Conf::Conf{$queue} . '/bad';
        my $clean_delay = $Conf::Conf{'clean_delay_' . $queue};
        if (-e $directory) {
            _clean_spool($directory, $clean_delay);
        }
    }

    # Expiring bad messages in digest spool.
    if (opendir my $dh, $Conf::Conf{'queuedigest'}) {
        my $base_dir = $Conf::Conf{'queuedigest'};
        my @dirs = grep { !/\A\./ and -d $base_dir . '/' . $_ } readdir $dh;
        closedir $dh;
        foreach my $subdir (@dirs) {
            my $directory   = $base_dir . '/' . $subdir . '/bad';
            my $clean_delay = $Conf::Conf{'clean_delay_queuedigest'};
            if (-e $directory) {
                _clean_spool($directory, $clean_delay);
            }
        }
    }

    # Expiring bad packets and messages in bulk spool.
    foreach my $subdir (qw(pct msg)) {
        my $directory   = $Conf::Conf{'queuebulk'} . '/bad/' . $subdir;
        my $clean_delay = $Conf::Conf{'clean_delay_queuebulk'};
        if (-e $directory) {
            _clean_spool($directory, $clean_delay);
        }
    }

    # Expiring moderation spools except mod, topic spool and temporary files.
    foreach my $queue (
        qw(queueauth queueautomatic queuesubscribe queuetopic tmpdir)) {
        my $directory   = $Conf::Conf{$queue};
        my $clean_delay = $Conf::Conf{'clean_delay_' . $queue};
        if (-e $directory) {
            _clean_spool($directory, $clean_delay);
        }
    }

    # Expiring mod spool.
    my $modqueue = $Conf::Conf{'queuemod'};
    if (opendir my $dh, $modqueue) {
        my @qfiles = sort readdir $dh;
        closedir $dh;
        foreach my $i (@qfiles) {
            next if $i =~ /\A[.]/;
            next unless -f $modqueue . '/' . $i;

            $i =~ /\A(.+)_[.\w]+\z/;
            my $list = Sympa::List->new($1, '*', {just_try => 1}) if $1;
            my $moddelay;
            if (ref $list eq 'Sympa::List') {
                $moddelay = $list->{'admin'}{'clean_delay_queuemod'};
            } else {
                $moddelay = $Conf::Conf{'clean_delay_queuemod'};
            }
            if ($moddelay) {
                my $mtime =
                    Sympa::Tools::File::get_mtime($modqueue . '/' . $i);
                if ($mtime < time - $moddelay * 86400) {
                    unlink($modqueue . '/' . $i);
                    $log->syslog('notice',
                        'Deleting unmoderated message %s, too old', $i);
                }
            }
        }
    }

    # Expiring formatted held messages.
    if (opendir my $dh, $Conf::Conf{'viewmail_dir'} . '/mod') {
        my $base_dir = $Conf::Conf{'viewmail_dir'} . '/mod';
        my @dirs = grep { !/\A\./ and -d $base_dir . '/' . $_ } readdir $dh;
        closedir $dh;
        foreach my $list_id (@dirs) {
            my $clean_delay;
            my $list = Sympa::List->new($list_id, '*', {just_try => 1});
            if (ref $list eq 'Sympa::List') {
                $clean_delay = $list->{'admin'}{'clean_delay_queuemod'};
            } else {
                $clean_delay = $Conf::Conf{'clean_delay_queuemod'};
            }
            my $directory = $base_dir . '/' . $list_id;
            if ($clean_delay and -e $directory) {
                _clean_spool($directory, $clean_delay);
            }
        }
    }

    # Removing messages in bulk spool with no more packet.
    my $pct_directory = $Conf::Conf{'queuebulk'} . '/pct';
    my $msg_directory = $Conf::Conf{'queuebulk'} . '/msg';
    if (opendir my $dh, $pct_directory) {
        my $msgpath;
        while ($msgpath = readdir $dh) {
            next if $msgpath =~ /\A\./;
            next unless -d $pct_directory . '/' . $msgpath;
            next
                if time - 3600 < Sympa::Tools::File::get_mtime(
                $pct_directory . '/' . $msgpath);

            # If packet directory is empty, remove message also.
            unlink($msg_directory . '/' . $msgpath)
                if rmdir($pct_directory . '/' . $msgpath);
        }
        closedir $dh;
    }

    return 1;
}

# Old name: tools::CleanSpool(), Sympa::Tools::File::CleanDir(),
# _clean_spool() in task_manager.pl.
sub _clean_spool {
    $log->syslog('debug2', '(%s, %s)', @_);
    my ($directory, $clean_delay) = @_;

    return 1 unless $clean_delay;

    my $dh;
    unless (opendir $dh, $directory) {
        $log->syslog('err', 'Unable to open "%s" spool: %m', $directory);
        return undef;
    }
    my @qfile = sort grep { !/\A\.+\z/ and !/\Abad\z/ } readdir $dh;
    closedir $dh;

    my ($curlist, $moddelay);
    foreach my $f (@qfile) {
        if (Sympa::Tools::File::get_mtime("$directory/$f") <
            time - $clean_delay * 60 * 60 * 24) {
            if (-f "$directory/$f") {
                unlink("$directory/$f");
                $log->syslog('notice', 'Deleting old file %s',
                    "$directory/$f");
            } elsif (-d "$directory/$f") {
                unless (Sympa::Tools::File::remove_dir("$directory/$f")) {
                    $log->syslog('err', 'Cannot remove old directory %s: %m',
                        "$directory/$f");
                    next;
                }
                $log->syslog('notice', 'Deleting old directory %s',
                    "$directory/$f");
            }
        }
    }

    return 1;
}

## remove messages from bulkspool table when no more packet have any pointer
## to this message
# Old name: purge_tables() in task_manager.pl.
sub do_purge_tables {
    my $self = shift;
    my $task = shift;
    my $line = shift;

    my $removed;

    $removed = 0;
    foreach my $robot (Sympa::List::get_robots()) {
        my $all_lists = Sympa::List::get_lists($robot);

        foreach my $list (@{$all_lists || []}) {
            my $tracking = Sympa::Tracking->new(context => $list);
            next unless $tracking;

            $removed +=
                $tracking->remove_message_by_period(
                $list->{'admin'}{'tracking'}{'retention_period'});
        }
    }
    $log->syslog('notice', "%s rows removed in tracking table", $removed);

    return 1;
}

## remove one time ticket table if older than
## $Conf::Conf{'one_time_ticket_table_ttl'}
# Old name: purge_one_time_ticket_table() in task_manager.pl.
sub do_purge_one_time_ticket_table {
    my $self = shift;
    my $task = shift;
    my $line = shift;

    $log->syslog('info', '');
    my $removed = Sympa::Ticket::purge_old_tickets('*');
    unless (defined $removed) {
        $log->syslog('err', 'Failed to remove old tickets');
        return undef;
    }
    $log->syslog('notice', '%s row removed in one_time_ticket_table',
        $removed);
    return 1;
}

# Old name: purge_user_table() in task_manager.pl.
sub do_purge_user_table {
    my $self = shift;
    my $task = shift;
    my $line = shift;

    my $sdm = Sympa::DatabaseManager->instance;

    my $time = time;

    # Marking super listmasters
    foreach my $l (Sympa::get_listmasters_email('*')) {
        unless (
            $sdm
            and $sdm->do_prepared_query(
                q{UPDATE user_table
                  SET last_active_date_user = ?
                  WHERE email_user = ?},
                $time, lc $l
            )
        ) {
            $log->syslog('err', 'Failed to check activity of users');
            return undef;
        }
    }
    # Marking per-robot listmasters.
    foreach my $robot_id (Sympa::List::get_robots()) {
        foreach my $l (Sympa::get_listmasters_email($robot_id)) {
            unless (
                $sdm->do_prepared_query(
                    q{UPDATE user_table
                      SET last_active_date_user = ?
                      WHERE email_user = ?},
                    $time, lc $l
                )
            ) {
                $log->syslog('err', 'Failed to check activity of users');
                return undef;
            }
        }
    }
    # Marking new users, owners/editors and subscribers.
    unless (
        $sdm->do_prepared_query(
            q{UPDATE user_table
              SET last_active_date_user = ?
              WHERE last_active_date_user IS NULL
              OR EXISTS (
                SELECT 1
                FROM admin_table
                WHERE admin_table.user_admin = user_table.email_user
              )
              OR EXISTS (
                SELECT 1
                FROM subscriber_table
                WHERE subscriber_table.user_subscriber = user_table.email_user
              )},
            $time
        )
    ) {
        $log->syslog('err', 'Failed to check activity of users');
        return undef;
    }

    # Look for unused entries.
    my @purged_users;
    my $sth;
    unless (
        $sth = $sdm->do_prepared_query(
            q{SELECT email_user
              FROM user_table
              WHERE last_active_date_user IS NOT NULL AND
                    last_active_date_user < ?},
            $time
        )
    ) {
        $log->syslog('err', 'Failed to get inactive users');
        return undef;
    }
    @purged_users =
        grep {$_} map { $_->[0] } @{$sth->fetchall_arrayref || []};
    $sth->finish;

    # Purge unused entries.
    foreach my $email (@purged_users) {
        my $user = Sympa::User->new($email);
        next unless $user;

        unless ($user->expire) {
            $log->syslog('err', 'Failed to purge inactive user %s', $user);
            return undef;
        } else {
            $log->syslog('info', 'User %s was expired', $user);
        }
    }

    return scalar @purged_users;
}

## Subroutine which remove bounced message of no-more known users
# Old name: purge_orphan_bounces() in task_manager.pl.
sub do_purge_orphan_bounces {
    my $self = shift;
    my $task = shift;
    my $line = shift;

    my $all_lists = Sympa::List::get_lists('*');
    foreach my $list (@{$all_lists || []}) {
        # First time: loading DB entries into %bounced_users,
        # hash {'bounced address' => 1}
        my %bounced_users;

        for (
            my $user_ref = $list->get_first_bouncing_list_member();
            $user_ref;
            $user_ref = $list->get_next_bouncing_list_member()
        ) {
            $bounced_users{
                Sympa::Tools::Text::encode_filesystem_safe(
                    $user_ref->{email}
                )
            } = 1;
        }

        my $bounce_dir = $list->get_bounce_dir();
        unless (-d $bounce_dir) {
            $log->syslog('notice', 'No bouncing subscribers in list %s',
                $list);
            next;
        }

        # Then reading Bounce directory & compare with %bounced_users
        my $dh;
        unless (opendir $dh, $bounce_dir) {
            $log->syslog('err', 'Error while opening bounce directory %s',
                $bounce_dir);
            return undef;
        }

        # Finally removing orphan files
        my $marshalled;
        while ($marshalled = readdir $dh) {
            my $metadata =
                Sympa::Spool::unmarshal_metadata($bounce_dir, $marshalled,
                qr/\A([^\s\@]+\@[\w\.\-*]+?)(?:__(\w+))?\z/,
                [qw(recipient envid)]);
            next unless $metadata;
            # Skip <email>__<envid> which is used by tracking feature.
            next if defined $metadata->{envid};

            unless ($bounced_users{$marshalled}) {
                $log->syslog('info',
                    'Removing orphan Bounce for user %s in list %s',
                    $marshalled, $list);
                unless (unlink($bounce_dir . '/' . $marshalled)) {
                    $log->syslog('err', 'Error while removing file %s/%s',
                        $bounce_dir, $marshalled);
                }
            }
        }

        closedir $dh;
    }
    return 1;
}

# If a bounce is older than $list->get_latest_distribution_date() - $delay
# expire the bounce.
# Old name: expire_bounce() in task_manager.pl.
sub do_expire_bounce {
    my $self = shift;
    my $task = shift;
    my $line = shift;

    my @tab = @{$line->{Rarguments} || []};
    my $delay = $tab[0];

    my $all_lists = Sympa::List::get_lists('*');
    foreach my $list (@{$all_lists || []}) {
        my $listname = $list->{'name'};

        # the reference date is the date until which we expire bounces in
        # second
        # the latest_distribution_date is the date of last distribution #days
        # from 01 01 1970

        unless ($list->get_latest_distribution_date()) {
            $log->syslog(
                'debug2',
                'Bounce expiration: skipping list %s because could not get latest distribution date',
                $listname
            );
            next;
        }
        my $refdate =
            (($list->get_latest_distribution_date() - $delay) * 3600 * 24);

        for (
            my $u = $list->get_first_bouncing_list_member();
            $u;
            $u = $list->get_next_bouncing_list_member()
        ) {
            $u->{'bounce'} =~ /^(\d+)\s+(\d+)\s+(\d+)(\s+(.*))?$/;
            $u->{'last_bounce'} = $2;
            if ($u->{'last_bounce'} < $refdate) {
                my $email = $u->{'email'};

                unless ($list->is_list_member($email)) {
                    $log->syslog('info', '%s not subscribed', $email);
                    next;
                }

                unless (
                    $list->update_list_member(
                        $email,
                        bounce         => undef,
                        bounce_address => undef
                    )
                ) {
                    $log->syslog('info', 'Failed update database for %s',
                        $email);
                    next;
                }
                my $escaped_email =
                    Sympa::Tools::Text::encode_filesystem_safe($email);

                my $bounce_dir = $list->get_bounce_dir();

                unless (unlink $bounce_dir . '/' . $escaped_email) {
                    $log->syslog(
                        'info',
                        'Failed deleting %s',
                        $bounce_dir . '/' . $escaped_email
                    );
                    next;
                }
                $log->syslog(
                    'info',
                    'Expire bounces for subscriber %s of list %s (last distribution %s, last bounce %s)',
                    $email,
                    $listname,
                    POSIX::strftime(
                        "%Y-%m-%d",
                        localtime(
                            $list->get_latest_distribution_date() * 3600 * 24
                        )
                    ),
                    POSIX::strftime(
                        "%Y-%m-%d", localtime($u->{'last_bounce'})
                    )
                );
            }
        }
    }

    # Expiring formatted bounce messages.
    if (opendir my $dh, $Conf::Conf{'viewmail_dir'} . '/bounce') {
        my $base_dir = $Conf::Conf{'viewmail_dir'} . '/bounce';
        my @dirs = grep { !/\A\./ and -d $base_dir . '/' . $_ } readdir $dh;
        closedir $dh;
        foreach my $list_id (@dirs) {
            my $directory = $base_dir . '/' . $list_id;
            if (-e $directory) {
                _clean_spool($directory, $delay);
            }
        }
    }

    return 1;
}

# Removed because not yet fully implemented.  See r11771.
#sub chk_cert_expiration;

# Removed becuase not yet fully implemented.  See r11771.
#sub update_crl;

## Subroutine for bouncers evaluation:
# give a score for each bouncing user
# Old name: eval_bouncers() in task_manager.pl.
sub do_eval_bouncers {
    my $self = shift;
    my $task = shift;
    my $line = shift;

    my $all_lists = Sympa::List::get_lists('*');
    foreach my $list (@{$all_lists || []}) {
        my $listname     = $list->{'name'};
        my $list_traffic = {};

        $log->syslog('info', '(%s)', $listname);

        ## Analizing file Msg-count and fill %$list_traffic
        my $ifh;
        unless (open $ifh, '<', $list->{'dir'} . '/msg_count') {
            $log->syslog('debug',
                '** Could not open msg_count FILE for list %s', $listname);
            next;
        }
        while (<$ifh>) {
            if (/^(\w+)\s+(\d+)/) {
                my ($a, $b) = ($1, $2);
                $list_traffic->{$a} = $b;
            }
        }
        close $ifh;

        #for each bouncing user
        for (
            my $user_ref = $list->get_first_bouncing_list_member();
            $user_ref;
            $user_ref = $list->get_next_bouncing_list_member()
        ) {
            my $score = _get_score($user_ref, $list_traffic) || 0;

            # Copying score into database.
            unless (
                $list->update_list_member(
                    $user_ref->{'email'}, bounce_score => $score
                )
            ) {
                $log->syslog('err', 'Error while updating DB for user %s',
                    $user_ref->{'email'});
                next;
            }
        }
    }
    return 1;
}

# Routine for automatic bouncing users management
#
# This sub apply a treatment foreach category of bouncing-users
#
# The relation between possible actions and correponding subroutines
# is indicated by the following hash (%actions).
# It's possible to add actions by completing this hash and the one in list
# config (file List.pm, in sections "bouncers_levelX"). Then you must write
# the code for your action:
# The action subroutines have two parameters:
# - current list
# - a reference on users email list
# Look at the _remove_bouncers() for an example.
# Old name: process_bouncers() in task_manager.pl.
sub do_process_bouncers {
    my $self = shift;
    my $task = shift;
    my $line = shift;

    ## possible actions
    my %actions = (
        'remove_bouncers' => \&_remove_bouncers,
        'notify_bouncers' => \&_notify_bouncers,
        'none'            => sub {1},
    );

    my $all_lists = Sympa::List::get_lists('*');
    foreach my $list (@{$all_lists || []}) {
        my @bouncers;
        # @bouncers = (
        #     ['email1', 'email2', 'email3',....,],    There is one line
        #     ['email1', 'email2', 'email3',....,],    foreach bounce
        #     ['email1', 'email2', 'email3',....,],    level.
        # );

        my $max_level;
        for (
            my $level = 1;
            defined($list->{'admin'}{'bouncers_level' . $level});
            $level++
        ) {
            $max_level = $level;
        }

        ##  first, bouncing email are sorted in @bouncer
        for (
            my $user_ref = $list->get_first_bouncing_list_member();
            $user_ref;
            $user_ref = $list->get_next_bouncing_list_member()
        ) {
            # Skip included users (cannot be removed)
            next if defined $user_ref->{'inclusion'};

            for (my $level = $max_level; ($level >= 1); $level--) {
                if ($user_ref->{'bounce_score'} >=
                    $list->{'admin'}{'bouncers_level' . $level}{'rate'}) {
                    push(@{$bouncers[$level]}, $user_ref->{'email'});
                    $level = ($level - $max_level);
                }
            }
        }

        ## then, calling action foreach level
        for (my $level = $max_level; ($level >= 1); $level--) {
            my $action =
                $list->{'admin'}{'bouncers_level' . $level}{'action'};
            my $notification =
                $list->{'admin'}{'bouncers_level' . $level}{'notification'};
            my $robot_id = $list->{'domain'};

            if (@{$bouncers[$level] || []}) {
                ## calling action subroutine with (list,email list) in
                ## parameter
                unless ($actions{$action}->($list, $bouncers[$level])) {
                    $log->syslog(
                        'err',
                        'Error while calling action sub for bouncing users in list %s',
                        $list
                    );
                    return undef;
                }

                # Notify owner or listmaster with list, action, email list.
                my $param = {
                    #'listname'  => $listname, # No longer used (<=6.1)
                    'action'    => $action,
                    'user_list' => \@{$bouncers[$level]},
                    'total'     => scalar(@{$bouncers[$level]}),
                };
                if ($notification eq 'owner') {
                    $list->send_notify_to_owner('automatic_bounce_management',
                        $param);
                } elsif ($notification eq 'listmaster') {
                    Sympa::send_notify_to_listmaster($list,
                        'automatic_bounce_management', $param);
                }
            }
        }
    }
    return 1;
}

# Old name: get_score() in task_manager.pl.
sub _get_score {

    my $user_ref     = shift;
    my $list_traffic = shift;

    $log->syslog('debug', '(%s)', $user_ref->{'email'});

    my $min_period    = $Conf::Conf{'minimum_bouncing_period'};
    my $min_msg_count = $Conf::Conf{'minimum_bouncing_count'};

    # Analizing bounce_subscriber_field and keep useful infos for notation
    $user_ref->{'bounce'} =~ /^(\d+)\s+(\d+)\s+(\d+)(\s+(.*))?$/;

    my $BO_period    = int($1 / 86400) - $Conf::Conf{'bounce_delay'};
    my $EO_period    = int($2 / 86400) - $Conf::Conf{'bounce_delay'};
    my $bounce_count = $3;
    my $bounce_type  = $4;

    my $msg_count = 0;
    my $min_day   = $EO_period;

    unless ($bounce_count >= $min_msg_count) {
        #not enough messages distributed to keep score
        $log->syslog('debug', 'Not enough messages for evaluation of user %s',
            $user_ref->{'email'});
        return undef;
    }

    unless (($EO_period - $BO_period) >= $min_period) {
        #too short bounce period to keep score
        $log->syslog('debug', 'Too short period for evaluate %s',
            $user_ref->{'email'});
        return undef;
    }

    # calculate number of messages distributed in list while user was bouncing
    foreach my $date (sort { $b <=> $a } keys(%$list_traffic)) {
        if (($date >= $BO_period) && ($date <= $EO_period)) {
            $min_day = $date;
            $msg_count += $list_traffic->{$date};
        }
    }

    # Adjust bounce_count when msg_count file is too recent, compared to the
    # bouncing period
    my $tmp_bounce_count = $bounce_count;
    unless ($EO_period == $BO_period) {
        my $ratio = (($EO_period - $min_day) / ($EO_period - $BO_period));
        $tmp_bounce_count *= $ratio;
    }

    ## Regularity rate tells how much user has bounced compared to list
    ## traffic
    $msg_count ||= 1;    ## Prevents "Illegal division by zero" error
    my $regularity_rate = $tmp_bounce_count / $msg_count;

    ## type rate depends on bounce type (5 = permanent ; 4 =tewmporary)
    my $type_rate = 1;
    $bounce_type =~ /(\d)\.(\d)\.(\d)/;
    if ($1 == 4) {       # if its a temporary Error: score = score/2
        $type_rate = .5;
    }

    my $note = $bounce_count * $regularity_rate * $type_rate;

    ## Note should be an integer
    $note = int($note + 0.5);

#    $note = 100 if ($note > 100); # shift between message ditrib & bounces =>
#    note > 100

    return $note;
}

# Sub for removing user
# Old name: Sympa::List::remove_bouncers().
sub _remove_bouncers {
    $log->syslog('debug2', '(%s, %s)', @_);
    my $list  = shift;
    my $users = shift;

    foreach my $u (@{$users || []}) {
        $log->syslog('notice', 'Removing bouncing subsrciber of list %s: %s',
            $list, $u);
    }
    $list->delete_list_member($users, exclude => 1, operation => 'auto_del');
    return 1;
}

# Sub for notifying users: "Be careful, you're bouncing".
# Old name: Sympa::List::notify_bouncers().
sub _notify_bouncers {
    $log->syslog('debug2', '(%s, %s)', @_);
    my $list  = shift;
    my $users = shift;

    foreach my $u (@{$users || []}) {
        $log->syslog('notice', 'Notifying bouncing subsrciber of list %s: %s',
            $list, $u);
        Sympa::send_notify_to_user($list, 'auto_notify_bouncers', $u);
    }
    return 1;
}

# Old name: none() in task_manager.pl.
# No longer used.
#sub _none;

# Old name: sync_include() in task_manager.pl.
sub do_sync_include {
    my $self = shift;
    my $task = shift;
    my $line = shift;

    my $list = $task->{context};
    unless (ref $list eq 'Sympa::List') {
        $log->syslog('err', 'No list');
        return -1;
    }

    $list->sync_include('member');
    $list->sync_include('owner');
    $list->sync_include('editor');

    unless ($list->has_data_sources or $list->has_included_users) {
        $log->syslog('debug', 'List %s no more require sync_include task',
            $list);
        return -1;
    }
}

### MISCELLANEOUS SUBROUTINES ###

## change the label of a task file
# Old name: change_label() in task_manager.pl.
# No onger used.
#sub _change_label;

## send a error message to list-master, log it, and change the label task into
## 'ERROR'
sub _error {
    my $task    = shift;
    my $message = shift;

    my @param = (
        sprintf
            'An error has occurred during the execution of the task %s: %s',
        $task->get_id, $message
    );
    $log->syslog('err', '%s', $message);
    #FIXME: Coresponding mail template would be added.
    Sympa::send_notify_to_listmaster('*', 'error_in_task', \@param);
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Spindle::ProcessTask - Workflow of task processing

=head1 SYNOPSIS

  use Sympa::Spindle::ProcessTask;
  
  my $spindle = Sympa::Spindle::ProcessTask->new;
  $spindle->spin;

=head1 DESCRIPTION

L<Sympa::Spindle::ProcessTask> defines workflow to process tasks in
task spool.

When spin() method is invoked, tasks kept in task spool are processed.
Then, all global and list tasks are created as necessity.

=head1 SEE ALSO

L<task_manager(8)>, L<Sympa::Spindle>, L<Sympa::Spool::Task>, L<Sympa::Task>.

=head1 HISTORY

L<Sympa::Spindle::ProcessTask> appeared on Sympa 6.2.37b.2.

=cut

