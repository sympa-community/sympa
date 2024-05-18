# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
# Copyright 2017, 2021 The Sympa Community. See the
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

package Sympa::Log;

use strict;
use warnings;
use English qw(-no_match_vars);
use POSIX qw();
use Scalar::Util;
use Sys::Syslog qw();
use Time::Local qw();

use Sympa::Tools::Time;

use base qw(Class::Singleton);

# Constructor for Class::Singleton.
sub _new_instance {
    my $class = shift;

    bless {} => $class;
}

# Old name: Log::do_openlog().
sub openlog {
    my $self    = shift;
    my %options = @_;

    $self->{_service} = $options{service} || _daemon_name() || 'sympa';
    $self->{_database_backend} =
        (exists $options{database_backend})
        ? $options{database_backend}
        : 'Sympa::DatabaseManager';

    return $self->_connect();
}

# When logs are not available, period of time to wait before sending another
# warning to listmaster.
my $warning_timeout = 600;
# Date of the last time a message was sent to warn the listmaster that the
# logs are unavailable.
my $warning_date = 0;

my %levels = (
    err    => 0,
    info   => 0,
    notice => 0,
    trace  => 0,
    debug  => 1,
    debug2 => 2,
    debug3 => 3,
);

# Deprecated: No longer used.
#sub fatal_err;

# Old name: Log::do_log().
sub syslog {
    my $self    = shift;
    my $level   = shift;
    my $message = shift;
    my $errno   = $ERRNO;

    unless (exists $levels{$level}) {
        $self->syslog('err', 'Invalid $level: "%s"', $level);
        $level = 'info';
    }

    # do not log if log level is too high regarding the log requested by user
    return if defined $self->{level}  and $levels{$level} > $self->{level};
    return if !defined $self->{level} and $levels{$level} > 0;

    # Skip stack frame when warnings are issued.
    local $SIG{__WARN__} = \&_warn_handler;

    ## Do not display variables which are references.
    my @param = ();
    foreach my $fstring (($message =~ /(%.)/g)) {
        next if $fstring eq '%%' or $fstring eq '%m';

        my $p = shift @_;
        unless (defined $p) {
            # prevent 'Use of uninitialized value' warning
            push @param, '';
        } elsif (ref $p eq 'Template::Exception') {
            push @param, $p->as_string;
        } elsif (Scalar::Util::blessed($p) and $p->can('get_id')) {
            push @param, sprintf('%s <%s>', ref $p, $p->get_id);
        } elsif (ref $p eq 'Regexp') {
            push @param, "qr<$p>";
        } elsif (ref $p) {
            push @param, ref $p;
        } else {
            push @param, $p;
        }
    }
    $message =~ s/(%.)/($1 eq '%m') ? '%%%%errno%%%%' : $1/eg;
    $message = sprintf $message, @param;
    $message =~ s/%%errno%%/$errno/g;

    ## If in 'err' level, build a stack trace,
    ## except if syslog has not been setup yet.
    if (defined $self->{level} and $level eq 'err') {
        my $go_back = 0;
        my @calls;

        my @f = caller($go_back);
        #if ($f[3] and $f[3] =~ /wwslog$/) {
        #    ## If called via wwslog, go one step ahead
        #    @f = caller(++$go_back);
        #}
        @calls = '#' . $f[2];
        while (@f = caller(++$go_back)) {
            if ($f[3] and $f[3] =~ /\ASympa::Crash::/) {
                # Discard trace inside crash handler.
                @calls = '#' . $f[2];
            } else {
                $calls[0] = ($f[3] || '') . $calls[0];
                unshift @calls, '#' . $f[2];
            }
        }
        $calls[0] = 'main::' . $calls[0];

        my $caller_string = join ' > ', @calls;
        $message = "$caller_string $message";
    } else {
        my @call = caller(1);
        ## If called via wwslog, go one step ahead
        #if ($call[3] and $call[3] =~ /wwslog$/) {
        #    @call = caller(2);
        #}

        my $caller_string = $call[3];
        if (defined $caller_string and length $caller_string) {
            if ($message =~ /\A[(].*[)]/) {
                $message = "$caller_string$message";
            } else {
                $message = "$caller_string() $message";
            }
        } else {
            $message = "main:: $message";
        }
    }

    ## Add facility to log entry
    $message = "$level $message";

    # map to standard syslog facility if needed
    if ($level eq 'trace') {
        $message = "###### TRACE MESSAGE ######:  " . $message;
        $level   = 'notice';
    } elsif ($level eq 'debug2' or $level eq 'debug3') {
        $level = 'debug';
    }

    ## Output to STDERR if needed
    if (not defined $self->{level}
        or ($self->{log_to_stderr}
            and ($self->{log_to_stderr} eq 'all'
                or 0 <= index($self->{log_to_stderr}, $level))
        )
    ) {
        print STDERR "$message\n";
    }
    return unless defined $self->{level};

    # Output to syslog
    # Note: Sys::Syslog <= 0.07 which are bundled in Perl <= 5.8.7 pass
    # $message to sprintf() even when no arguments are given.  As a
    # workaround, always pass format string '%s' along with $message.
    eval {
        unless (Sys::Syslog::syslog($level, '%s', $message)) {
            $self->_connect();
            Sys::Syslog::syslog($level, '%s', $message);
        }
    };
    if ($EVAL_ERROR and $warning_date < time - $warning_timeout) {
        warn sprintf 'No logs available: %s', $EVAL_ERROR;
        $warning_date = time + $warning_timeout;
    }
}

# Old names: Log::set_daemon(), Sympa::Tools::Daemon::get_daemon_name().
sub _daemon_name {
    my @path = split /\//, $PROGRAM_NAME;
    my $service = $path[$#path];
    $service =~ s/(\.[^\.]+)$//;
    return $service;
}

# Old name: Log::do_connect().
sub _connect {
    my $self = shift;

    if (@{$Conf::Conf{'syslog_socket.type'} || []}) {
        Sys::Syslog::setlogsock(
            {   (type => $Conf::Conf{'syslog_socket.type'}),
                map {
                    length($Conf::Conf{"syslog_socket.$_"} // '')
                        ? ($_ => $Conf::Conf{"syslog_socket.$_"})
                        : ()
                } qw(path timeout host port)
            }
        );
    }

    my $facility =
        (grep { $self->{_service} eq $_ }
            qw(wwsympa sympasoap archived bounced task_manager)
            and $Conf::Conf{'log_facility'})
        || $Conf::Conf{'syslog'};

    # Close log may be useful: If parent processus did open log child
    # process inherit the openlog with parameters from parent process.
    Sys::Syslog::closelog;
    eval {
        Sys::Syslog::openlog(sprintf('%s[%s]', $self->{_service}, $PID),
            'ndelay,nofatal', $facility);
    };
    if ($EVAL_ERROR && ($warning_date < time - $warning_timeout)) {
        warn sprintf 'No logs available: %s', $EVAL_ERROR;
        $warning_date = time + $warning_timeout;
        return undef;
    }

    return $self;
}

sub _warn_handler {
    my $message = shift;

    my $go_back = 0;
    my @f;
    do { @f = caller(++$go_back) } while @f and $f[0] eq __PACKAGE__;
    $message =~ s/ at \S+ line \S+\n*\z/ at $f[1] line $f[2]\n/ if @f;
    print STDERR $message;
}

sub get_log_date {
    my $self = shift;

    my $sdm;
    unless ($self->{_database_backend}
        and $sdm = $self->{_database_backend}->instance) {
        $self->syslog('err', 'Database backend is not available');
        return;
    }

    my $sth;
    my @dates;
    foreach my $query ('MIN', 'MAX') {
        unless ($sth =
            $sdm->do_query("SELECT $query(date_logs) FROM logs_table")) {
            $self->syslog('err', 'Unable to get %s date from logs_table',
                $query);
            return;
        }
        while (my $d = ($sth->fetchrow_array)[0]) {
            push @dates, $d;
        }
    }

    return @dates;
}

# add log in RDBMS
sub db_log {
    my $self    = shift;
    my %options = @_;

    my $sdm;
    unless ($self->{_database_backend}
        and $sdm = $self->{_database_backend}->instance) {
        $self->syslog('err', 'Database backend is not available');
        return undef;
    }

    my $list         = $options{'list'};
    my $robot        = $options{'robot'};
    my $action       = $options{'action'};
    my $parameters   = $options{'parameters'};
    my $target_email = $options{'target_email'};
    my $msg_id       = $options{'msg_id'};
    my $status       = $options{'status'};
    my $error_type   = $options{'error_type'};
    my $user_email   = $options{'user_email'};
    my $client       = $options{'client'};
    my $daemon       = $self->{_service} || 'sympa';
    my ($date, $usec) = Sympa::Tools::Time::gettimeofday();

    unless ($user_email) {
        $user_email = 'anonymous';
    }
    unless (defined $list and length $list) {
        $list = '';
    } elsif ($list =~ /(.+)\@(.+)/) {
        #remove the robot name of the list name
        $list = $1;
        unless ($robot) {
            $robot = $2;
        }
    }

    # Insert in log_table
    unless (
        $sdm->do_prepared_query(
            q{INSERT INTO logs_table
              (date_logs, usec_logs, robot_logs, list_logs, action_logs,
               parameters_logs,
               target_email_logs, msg_id_logs, status_logs, error_type_logs,
               user_email_logs, client_logs, daemon_logs)
              VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)},
            $date, $usec, $robot, $list, $action,
            substr($parameters || '', 0, 100),
            $target_email, $msg_id, $status, $error_type,
            $user_email,   $client, $daemon
        )
    ) {
        $self->syslog('err',
            'Unable to insert new db_log entry in the database');
        return undef;
    }

    return 1;
}

#insert data in stats table
# Old name: Log::db_stat_log().
sub add_stat {
    my $self    = shift;
    my %options = @_;

    my $sdm;
    unless ($self->{_database_backend}
        and $sdm = $self->{_database_backend}->instance) {
        $self->syslog('err', 'Database backend is not available');
        return undef;
    }

    my $list      = $options{'list'};
    my $operation = $options{'operation'};
    my $date      = time;
    my $mail      = $options{'mail'};
    my $daemon    = $self->{_service} || 'sympa';
    my $ip        = $options{'client'};
    my $robot     = $options{'robot'};
    my $parameter = $options{'parameter'};
    my $read      = 0;

    if (ref $list eq 'Sympa::List') {
        $list = $list->{'name'};
    } elsif ($list and $list =~ /(.+)\@(.+)/) {
        #remove the robot name of the list name
        $list = $1;
        unless ($robot) {
            $robot = $2;
        }
    }

    ##insert in stat table
    unless (
        $sdm->do_prepared_query(
            q{INSERT INTO stat_table
              (date_stat, email_stat, operation_stat, list_stat,
               daemon_stat, user_ip_stat, robot_stat, parameter_stat,
               read_stat)
              VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)},
            $date,   $mail, $operation, $list,
            $daemon, $ip,   $robot,     $parameter,
            $read
        )
    ) {
        $self->syslog('err',
            'Unable to insert new stat entry in the database');
        return undef;
    }
    return 1;
}

# delete logs in RDBMS
# MOVED to _db_log_del() in task_manager.pl.
#sub db_log_del;

# Scan log_table with appropriate select
sub get_first_db_log {
    my $self   = shift;
    my $select = shift;

    my $sdm;
    unless ($self->{_database_backend}
        and $sdm = $self->{_database_backend}->instance) {
        $self->syslog('err', 'Database backend is not available');
        return undef;
    }

    # Clear state.
    if ($self->{_sth}) {
        eval { $self->{_sth}->finish; };
        delete $self->{_sth};
    }

    my %action_type = (
        'message' => [
            'reject',       'distribute',  'arc_delete',   'arc_download',
            'sendMessage',  'remove',      'record_email', 'send_me',
            'd_remove_arc', 'rebuildarc',  'remind',       'send_mail',
            'DoFile',       'sendMessage', 'DoForward',    'DoMessage',
            'DoCommand',    'SendDigest'
        ],
        'authentication' => [
            'login',        'logout',
            'loginrequest', 'requestpasswd',
            'ssologin',     'ssologin_succeses',
            'remindpasswd', 'choosepasswd'
        ],
        'subscription' =>
            ['subscribe', 'signoff', 'add', 'del', 'ignoresub', 'subindex'],
        'list_management' => [
            'create_list',          'rename_list',
            'close_list',           'edit_list',
            'admin',                'blocklist',
            'install_pending_list', 'purge_list',
            'edit_template',        'copy_template',
            'remove_template'
        ],
        'bounced'     => ['resetbounce', 'get_bounce'],
        'preferences' => [
            'set',       'setpref', 'pref', 'change_email',
            'setpasswd', 'editsubscriber'
        ],
        'shared' => [
            'd_unzip',                'd_upload',
            'd_read',                 'd_delete',
            'd_savefile',             'd_overwrite',
            'd_create_dir',           'd_set_owner',
            'd_change_access',        'd_describe',
            'd_rename',               'd_editfile',
            'd_admin',                'd_install_shared',
            'd_reject_shared',        'd_properties',
            'creation_shared_file',   'd_unzip_shared_file',
            'install_file_hierarchy', 'd_copy_rec_dir',
            'd_copy_file',            'change_email',
            'set_lang',               'new_d_read',
            'd_control'
        ],
    );

    my $statement = sprintf q{SELECT date_logs, usec_logs AS usec,
                         robot_logs AS robot, list_logs AS list,
                         action_logs AS action,
                         parameters_logs AS parameters,
                         target_email_logs AS target_email,
                         msg_id_logs AS msg_id, status_logs AS status,
                         error_type_logs AS error_type,
                         user_email_logs AS user_email,
                         client_logs AS client, daemon_logs AS daemon
                  FROM logs_table
                  WHERE robot_logs = %s }, $sdm->quote($select->{'robot'});

    if (    $select->{target_type}
        and $select->{target_type} ne 'none'
        and $select->{target_type} =~ /\A\w+\z/
        and $select->{target}) {
        # If a type of target and a target are specified:
        $statement .= sprintf 'AND %s_logs = %s ',
            lc $select->{target_type}, $sdm->quote(lc $select->{target});
    } elsif ($select->{type}
        and $select->{type} ne 'none'
        and $select->{type} ne 'all_actions'
        and $action_type{$select->{type}}) {
        # If the search is on a precise type:
        $statement .= sprintf 'AND (%s) ',
            join ' OR ',
            map { sprintf "logs_table.action_logs = '%s'", $_ }
            @{$action_type{$select->{'type'}}};
    }

    #if the search is between two date
    if ($select->{'date_from'}) {
        my ($yyyy, $mm, $dd) = split /[^\da-z]/i, $select->{'date_from'};
        ($dd, $mm, $yyyy) = ($yyyy, $mm, $dd) if 31 < $dd;
        $yyyy += ($yyyy < 50 ? 2000 : $yyyy < 100 ? 1900 : 0);

        my $date_from = POSIX::mktime(0, 0, -1, $dd, $mm - 1, $yyyy - 1900);
        unless ($select->{'date_to'}) {
            my $date_from2 =
                POSIX::mktime(0, 0, 25, $dd, $mm - 1, $yyyy - 1900);
            $statement .= sprintf "AND date_logs >= %s AND date_logs <= %s ",
                $date_from, $date_from2;
        } else {
            my ($yyyy, $mm, $dd) = split /[^\da-z]/i, $select->{'date_to'};
            ($dd, $mm, $yyyy) = ($yyyy, $mm, $dd) if 31 < $dd;
            $yyyy += ($yyyy < 50 ? 2000 : $yyyy < 100 ? 1900 : 0);

            my $date_to = POSIX::mktime(0, 0, 25, $dd, $mm - 1, $yyyy - 1900);
            $statement .= sprintf "AND date_logs >= %s AND date_logs <= %s ",
                $date_from, $date_to;
        }
    }

    # if the listmaster want to make a search by an IP address.
    if ($select->{'ip'}) {
        $statement .= sprintf ' AND client_logs = %s ',
            $sdm->quote($select->{'ip'});
    }

    ## Currently not used
    #if the search is on the actor of the action
    if ($select->{'user_email'}) {
        $select->{'user_email'} = lc($select->{'user_email'});
        $statement .= sprintf "AND user_email_logs = '%s' ",
            $select->{'user_email'};
    }

    #if a list is specified -just for owner or above-
    if ($select->{'list'}) {
        $select->{'list'} = lc($select->{'list'});
        $statement .= sprintf "AND list_logs = '%s' ", $select->{'list'};
    }

    # Unknown sort key as 'date'.
    my $sortby = $select->{'sortby'};
    unless (
        $sortby
        and grep { $sortby eq $_ }
        qw(date robot list action parameters target_email msg_id
        status error_type user_email client daemon)
    ) {
        $sortby = 'date';
    }
    $statement .= sprintf 'ORDER BY %s ',
        ($sortby eq 'date' ? 'date_logs, usec_logs' : $sortby . '_logs');

    my $sth;
    unless ($sth = $sdm->do_query($statement)) {
        $self->syslog('err',
            'Unable to retrieve logs entry from the database');
        return undef;
    }
    $self->{_sth} = $sth;

    my $row = $sth->fetchrow_hashref('NAME_lc');

    ## If no rows returned, return an empty hash
    ## Required to differenciate errors and empty results
    unless ($row) {
        return {};
    }

    ## We can't use the "AS date" directive in the SELECT statement because
    ## "date" is a reserved keywork with Oracle
    $row->{date} = $row->{date_logs} if defined $row->{date_logs};
    return $row;

}

sub get_next_db_log {
    my $self = shift;

    my $sth = $self->{_sth};
    die 'Bug in logic.  Ask developer' unless $sth;

    my $row = $sth->fetchrow_hashref('NAME_lc');

    unless (defined $row) {
        $sth->finish;
        delete $self->{_sth};
    }

    ## We can't use the "AS date" directive in the SELECT statement because
    ## "date" is a reserved keywork with Oracle
    $row->{date} = $row->{date_logs} if defined $row->{date_logs};

    return $row;
}

# Data aggregation, to make statistics.
sub aggregate_stat {
    my $self = shift;

    my $sdm;
    unless ($self->{_database_backend}
        and $sdm = $self->{_database_backend}->instance) {
        $self->syslog('err', 'Database backend is not available');
        return undef;
    }

    my (@time, $sth);

    @time = localtime time;
    $time[0] = $time[1] = 0;
    my $date_end = Time::Local::timelocal(@time);

    unless (
        $sth = $sdm->do_prepared_query(
            q{SELECT date_stat
              FROM stat_table
              WHERE read_stat = 0
              ORDER BY date_stat ASC}
        )
    ) {
        $self->syslog('err', 'Unable to retrieve oldest non processed stat');
        return undef;
    }
    my @res = $sth->fetchrow_array;
    $sth->finish;    # Fetch only the oldest row.

    # If the array is emty, then we don't have anything to aggregate.
    # Simply return and carry on.
    unless (@res) {
        return 0;
    }
    my $date_deb = $res[0] - ($res[0] % 3600);

    # Hour to hour
    my @slots;
    for (my $i = $date_deb; $i <= $date_end; $i = $i + 3600) {
        push @slots, $i;
    }

    for (my $j = 1; $j <= scalar(@slots); $j++) {
        $self->_aggregate_data($slots[$j - 1] || $date_deb,
            $slots[$j] || $date_end);
    }

    return 1;
}

# Aggregate data from stat_table to stat_counter_table.
# Dates must be in epoch format.
my @robot_operations = qw{close_list copy_list create_list list_rejected
    login logout purge_list restore_list};

# Old name: Log::aggregate_data().
sub _aggregate_data {
    my $self = shift;
    my ($begin_date, $end_date) = @_;

    my $sdm;
    unless ($self->{_database_backend}
        and $sdm = $self->{_database_backend}->instance) {
        $self->syslog('err', 'Database backend is not available');
        return;
    }

    # Store reslults in stat_counter_table.
    my $cond;

    # Store data by each list.
    $cond = join ' AND ', map {"operation_stat <> '$_'"} @robot_operations;
    $sdm->do_prepared_query(
        sprintf(
            q{INSERT INTO stat_counter_table
              (beginning_date_counter, end_date_counter, data_counter,
               robot_counter, list_counter, count_counter)
              SELECT ?, ?, operation_stat, robot_stat, list_stat, COUNT(*)
              FROM stat_table
              WHERE ? <= date_stat AND date_stat < ?
                    AND list_stat IS NOT NULL AND list_stat <> ''
                    AND read_stat = 0 AND %s
              GROUP BY robot_stat, list_stat, operation_stat},
            $cond
        ),
        $begin_date,
        $end_date,
        $begin_date,
        $end_date
    );

    # Store data by each robot.
    $cond = join ' OR ', map {"operation_stat = '$_'"} @robot_operations;
    $sdm->do_prepared_query(
        sprintf(
            q{INSERT INTO stat_counter_table
              (beginning_date_counter, end_date_counter, data_counter,
               robot_counter, list_counter, count_counter)
              SELECT ?, ?, operation_stat, robot_stat, '', COUNT(*)
              FROM stat_table
              WHERE ? <= date_stat AND date_stat < ?
                    AND read_stat = 0 AND (%s)
              GROUP BY robot_stat, operation_stat},
            $cond
        ),
        $begin_date,
        $end_date,
        $begin_date,
        $end_date
    );

    # Update subscriber_table about messages sent, upgrade field
    # number_messages_subscriber.
    my $sth;
    my $row;
    if ($sth = $sdm->do_prepared_query(
            q{SELECT COUNT(*) AS "count",
                     robot_stat AS robot, list_stat AS list,
                     email_stat AS email
              FROM stat_table
              WHERE ? <= date_stat AND date_stat < ?
                    AND read_stat = 0 AND operation_stat = 'send_mail'
              GROUP BY robot_stat, list_stat, email_stat},
            $begin_date, $end_date
        )
    ) {
        while ($row = $sth->fetchrow_hashref('NAME_lc')) {
            $sdm->do_prepared_query(
                q{UPDATE subscriber_table
                      SET number_messages_subscriber =
                          number_messages_subscriber + ?
                      WHERE robot_subscriber = ? AND list_subscriber = ? AND
                            user_subscriber = ?},
                $row->{'count'},
                $row->{'robot'}, $row->{'list'},
                $row->{'email'}
            );
        }
        $sth->finish;
    }

    # The rows were read, so update the read_stat from 0 to 1.
    unless (
        $sth = $sdm->do_prepared_query(
            q{UPDATE stat_table
              SET read_stat = 1
              WHERE ? <= date_stat AND date_stat < ?},
            $begin_date, $end_date
        )
    ) {
        $self->syslog('err',
            'Unable to set stat entries between date % and date %s as read',
            $begin_date, $end_date);
        return undef;
    }

    my $d_deb = localtime($begin_date);
    my $d_fin = localtime($end_date) if defined $end_date;
    $self->syslog('debug2', 'data aggregated from %s to %s', $d_deb, $d_fin);
}

#get date of the last time we have aggregated data
# Never used.
#sub get_last_date_aggregation;

sub aggregate_daily_data {
    my $self = shift;
    $self->syslog('debug2', '(%s, %s)', @_);
    my $list      = shift;
    my $operation = shift;

    my $sdm;
    unless ($self->{_database_backend}
        and $sdm = $self->{_database_backend}->instance) {
        $self->syslog('err', 'Database backend is not available');
        return;
    }

    my $result;

    my $sth;
    my $row;
    unless (
        $sth = $sdm->do_prepared_query(
            q{SELECT beginning_date_counter AS "date",
                     count_counter AS "count"
              FROM stat_counter_table
              WHERE data_counter = ? AND
                    robot_counter = ? AND list_counter = ?},
            $operation,
            $list->{'domain'}, $list->{'name'}
        )
    ) {
        $self->syslog('err', 'Unable to get stat data %s for list %s',
            $operation, $list);
        return;
    }
    while ($row = $sth->fetchrow_hashref('NAME_lc')) {
        my $midnight = Sympa::Tools::Time::get_midnight_time($row->{'date'});
        $result->{$midnight} = 0 unless defined $result->{$midnight};
        $result->{$midnight} += $row->{'count'};
    }
    $sth->finish;

    my @dates = sort { $a <=> $b } keys %$result;
    return {} unless @dates;

    for (my $date = $dates[0]; $date < $dates[-1]; $date += 86400) {
        my $midnight = Sympa::Tools::Time::get_midnight_time($date);
        $result->{$midnight} = 0 unless defined $result->{$midnight};
    }
    return $result;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Log - Logging facility of Sympa

=head1 SYNOPSIS

  use Sympa::Log;

  my $log = Sympa::Log->instance;
  $log->openlog(facility => $facility);
  $log->{level} = 0;
  $log->syslog('info', '%s: Stat logging', $$);

=head1 DESCRIPTION

TBD.

=head2 Methods

=over

=item instance ( )

I<Constructor>.
Creates new singleton instance of L<Sympa::Log>.

=item openlog ( [ options ... ] )

TBD.

=item syslog ( $level, $format, [ parameters ... ] )

TBD.

=item get_log_date

TBD,

=item db_log

TBD.

=item add_stat

TBD.

=item get_first_db_log

TBD.

=item get_next_db_log

TBD.

=item aggregate_stat

TBD.

=item aggregate_daily_data

TBD.

=back

=head2 Properties

Instance of L<Sympa::Log> has following properties.

=over

=item {level}

Logging level.  Integer or C<undef>.

=item {log_to_stderr}

If set, print logs by syslog() to standard error.
Property value may be log level(s) to print or C<'all'>.

=back

=head1 SEE ALSO

L<Sys::Syslog>, L<Sympa::DatabaseManager>.

=head1 HISTORY

Database logging feature contributed by Adrien Brard appeared on Sympa 5.3.

Statistics feature appeared on Sympa 6.2.

L<Log> module was renamed to L<Sympa::Log> on Sympa 6.2.

=cut
