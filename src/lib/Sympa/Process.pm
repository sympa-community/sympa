# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015 GIP RENATER
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

package Sympa::Process;

use strict;
use warnings;
use English qw(-no_match_vars);
use POSIX qw();

use Conf;
use Sympa;
use Sympa::Constants;
use Sympa::Language;
use Sympa::LockedFile;
use Sympa::Log;
use Sympa::Tools::File;

use base qw(Class::Singleton);

my $log = Sympa::Log->instance;

# Constructor for Class::Singleton.
sub _new_instance {
    my $class = shift;

    bless {
        children   => {},
        detached   => 0,
        generation => 0,
    } => $class;
}

sub init {
    my $self    = shift;
    my %options = @_;

    foreach my $key (sort keys %options) {
        $self->{$key} = $options{$key};
    }
    $self->{name} ||= $self->{pidname} || [split /\//, $PROGRAM_NAME]->[-1];
    $self;
}

# Put ourselves in background.  That method works on many systems, although,
# it seems that Unix conceptors have decided that there won't be a single and
# easy way to detach a process from its controlling TTY.
sub daemonize {
    my $self = shift;

    if (open my $tty, '/dev/tty') {
        ioctl $tty, 0x20007471, 0;    # XXX s/b TIOCNOTTY()
        close $tty;
    }
    open STDIN,  '<',  '/dev/null';
    open STDOUT, '>>', '/dev/null';
    open STDERR, '>>', '/dev/null';

    setpgrp 0, 0;

    my $child_pid = CORE::fork();
    if ($child_pid) {
        $log->syslog('notice', 'Starting %s daemon, PID %d',
            $self->{name}, $child_pid);
        exit 0;
    } elsif (not defined $child_pid) {
        die sprintf 'Cannot fork %s daemon: %s', $self->{name}, $ERRNO;
    } else {
        $self->{detached} = 1;
    }
}

sub fork {
    my $self = shift;
    my $tag = shift || [split /\//, $PROGRAM_NAME]->[-1];

    my $pid = CORE::fork();
    unless (defined $pid) {
        ;
    } elsif ($pid) {
        $self->{children}->{$pid} = $tag;
    } else {
        $self->{children} = {};
        $self->{generation}++;
    }
    $pid;
}

# Old name: Sympa::Mailer::reaper().
sub reap_child {
    my $self    = shift;
    my %options = @_;

    my $pid;

    my $blocking = $options{blocking};
    while (0 < ($pid = waitpid(-1, $blocking ? 0 : POSIX::WNOHANG()))) {
        $blocking = 0;
        unless (exists $self->{children}->{$pid}) {
            $log->syslog('debug2', 'Reaper waited %s, unknown process to me',
                $pid);
            next;
        }
        if ($CHILD_ERROR & 127) {
            $log->syslog(
                'err',
                'Child process %s for <%s> was terminated by signal %d',
                $pid,
                $self->{children}->{$pid},
                $CHILD_ERROR & 127
            );
        } elsif ($CHILD_ERROR) {
            $log->syslog(
                'err', 'Child process %s for <%s> exited with status %s',
                $pid,
                $self->{children}->{$pid},
                $CHILD_ERROR >> 8
            );
        }
        delete $self->{children}->{$pid};
    }
    $log->syslog(
        'debug3',
        'Reaper unwaited PIDs: %s Open = %s',
        join(' ', sort { $a <=> $b } keys %{$self->{children}}),
        scalar keys %{$self->{children}}
    );

    if ($options{children}) {
        my $children = $options{children};
        foreach my $child_pid (keys %$children) {
            delete $children->{$child_pid}
                unless exists $self->{children}->{$child_pid};
        }
    }

    if ($self->{pidname} and $options{file}) {
        foreach my $child_pid (_get_pids_in_pid_file($self->{pidname})) {
            next if $child_pid == $PID;

            unless (exists $self->{children}->{$child_pid}) {
                $log->syslog(
                    'err',
                    'The %s child exists in the PID file but is no longer running. Removing it and notifying listmaster',
                    $child_pid
                );
                $self->remove_pid(pid => $child_pid);
                _send_crash_report($child_pid);
            }
        }
    }

    return $pid;
}

# Moved to Log::_daemon_name().
#sub get_daemon_name;

# Old name: Sympa::Tools::Daemon::remove_pid().
sub remove_pid {
    my $self    = shift;
    my %options = @_;

    my $name = $self->{pidname}
        or die 'bug in logic.  Ask developer';
    my $pid = $options{pid} || $PID;

    my $piddir  = Sympa::Constants::PIDDIR;
    my $pidfile = $piddir . '/' . $name . '.pid';

    my @pids;

    # Lock pid file
    my $lock_fh = Sympa::LockedFile->new($pidfile, 5, '+<');
    unless ($lock_fh) {
        $log->syslog('err', 'Could not open %s to remove PID %s',
            $pidfile, $pid);
        return undef;
    }

    ## If in multi_process mode (bulk.pl for instance can have child
    ## processes) then the PID file contains a list of space-separated PIDs
    ## on a single line
    unless ($options{final}) {
        # Read pid file
        seek $lock_fh, 0, 0;
        my $l = <$lock_fh>;
        @pids = grep { /^[0-9]+$/ and $_ != $pid } split(/\s+/, $l);

        ## If no PID left, then remove the file
        unless (@pids) {
            ## Release the lock
            unless (unlink $pidfile) {
                $log->syslog('err', "Failed to remove %s: %m", $pidfile);
                $lock_fh->close;
                return undef;
            }
        } else {
            seek $lock_fh, 0, 0;
            truncate $lock_fh, 0;
            print $lock_fh join(' ', @pids) . "\n";
        }
    } else {
        unless (unlink $pidfile) {
            $log->syslog('err', "Failed to remove %s: %m", $pidfile);
            $lock_fh->close;
            return undef;
        }
        my $err_file = $Conf::Conf{'tmpdir'} . '/' . $pid . '.stderr';
        if (-f $err_file) {
            unless (unlink $err_file) {
                $log->syslog('err', "Failed to remove %s: %m", $err_file);
                $lock_fh->close;
                return undef;
            }
        }
    }

    $lock_fh->close;
    return 1;
}

# Old name: Sympa::Tools::Daemon::write_pid().
sub write_pid {
    my $self    = shift;
    my %options = @_;

    my $name = $self->{pidname}
        or die 'bug in logic.  Ask developer';
    my $pid = $options{pid} || $PID;

    my $piddir  = Sympa::Constants::PIDDIR;
    my $pidfile = $piddir . '/' . $name . '.pid';

    ## Create piddir
    mkdir($piddir, 0755) unless (-d $piddir);

    unless (
        Sympa::Tools::File::set_file_rights(
            file  => $piddir,
            user  => Sympa::Constants::USER,
            group => Sympa::Constants::GROUP,
        )
        ) {
        die sprintf 'Unable to set rights on %s. Exiting.', $piddir;
        ## No return
    }

    my @pids;

    # Lock pid file
    my $lock_fh = Sympa::LockedFile->new($pidfile, 5, '+>>');
    unless ($lock_fh) {
        die sprintf 'Unable to lock %s file in write mode. Exiting.',
            $pidfile;
    }
    ## If pidfile exists, read the PIDs
    if (-s $pidfile) {
        # Read pid file
        seek $lock_fh, 0, 0;
        my $l = <$lock_fh>;
        @pids = grep {/^[0-9]+$/} split(/\s+/, $l);
    }

    # If we can have multiple instances for the process.
    # Print other pids + this one.
    unless ($options{initial}) {
        ## Print other pids + this one
        push(@pids, $pid);

        seek $lock_fh, 0, 0;
        truncate $lock_fh, 0;
        print $lock_fh join(' ', @pids) . "\n";
    } else {
        ## The previous process died suddenly, without pidfile cleanup
        ## Send a notice to listmaster with STDERR of the previous process
        if (@pids) {
            my $other_pid = $pids[0];
            $log->syslog('notice',
                'Previous process %s died suddenly; notifying listmaster',
                $other_pid);
            _send_crash_report($other_pid);
        }

        seek $lock_fh, 0, 0;
        unless (truncate $lock_fh, 0) {
            ## Unlock pid file
            $lock_fh->close();
            die sprintf 'Could not truncate %s, exiting.', $pidfile;
        }

        print $lock_fh $pid . "\n";
    }

    unless (
        Sympa::Tools::File::set_file_rights(
            file  => $pidfile,
            user  => Sympa::Constants::USER,
            group => Sympa::Constants::GROUP,
        )
        ) {
        ## Unlock pid file
        $lock_fh->close();
        die sprintf 'Unable to set rights on %s', $pidfile;
    }
    ## Unlock pid file
    $lock_fh->close();

    return 1;
}

# Old name: Sympa::Tools::Daemon::direct_stderr_to_file().
sub direct_stderr_to_file {
    my $self = shift;

    # Error output is stored in a file with PID-based name.
    # Useful if process crashes.
    open(STDERR, '>>', $Conf::Conf{'tmpdir'} . '/' . $PID . '.stderr');
    unless (
        Sympa::Tools::File::set_file_rights(
            file  => $Conf::Conf{'tmpdir'} . '/' . $PID . '.stderr',
            user  => Sympa::Constants::USER,
            group => Sympa::Constants::GROUP,
        )
        ) {
        $log->syslog(
            'err',
            'Unable to set rights on %s: %m',
            $Conf::Conf{'tmpdir'} . '/' . $PID . '.stderr'
        );
        return undef;
    }
    return 1;
}

# Old name: Sympa::Tools::Daemon::send_crash_report().
sub _send_crash_report {
    my $pid = shift;

    my $err_file = $Conf::Conf{'tmpdir'} . '/' . $pid . '.stderr';

    my $language = Sympa::Language->instance;
    my (@err_output, $err_date);
    if (-f $err_file) {
        open(ERR, $err_file);
        @err_output = map { chomp $_; $_; } <ERR>;
        close ERR;

        my $err_date_epoch = (stat $err_file)[9];
        if (defined $err_date_epoch) {
            $err_date = $language->gettext_strftime("%d %b %Y  %H:%M",
                localtime $err_date_epoch);
        } else {
            $err_date = $language->gettext('(unknown date)');
        }
    } else {
        $err_date = $language->gettext('(unknown date)');
    }
    Sympa::send_notify_to_listmaster(
        '*', 'crash',
        {   'crashed_process' => [split /\//, $PROGRAM_NAME]->[-1],
            'crash_err'       => \@err_output,
            'crash_date'      => $err_date,
            'pid'             => $pid,
        }
    );
}

# return a lockname that is a uniq id of a processus (hostname + pid) ;
# hostname(20) and pid(10) are truncated in order to store lockname in
# database varchar(30)
# DEPRECATED: No longer used.
#sub get_lockname();

# Old name: Sympa::Tools::Daemon::get_pids_in_pid_file().
sub _get_pids_in_pid_file {
    my $name = shift;

    my $piddir  = Sympa::Constants::PIDDIR;
    my $pidfile = $piddir . '/' . $name . '.pid';

    my $lock_fh = Sympa::LockedFile->new($pidfile, 5, '<');
    unless ($lock_fh) {
        $log->syslog('err', 'Unable to open PID file %s: %m', $pidfile);
        return;
    }
    my $l = <$lock_fh>;
    my @pids = grep {/^[0-9]+$/} split(/\s+/, $l);
    $lock_fh->close;

    return @pids;
}

# Old name: Sympa::Tools::Daemon::get_children_processes_list().
# OBSOLETED.  No longer used.
sub get_children_processes_list {
    $log->syslog('debug3', '');
    my @children;
    for my $p (@{Proc::ProcessTable->new->table}) {
        if ($p->ppid == $PID) {
            push @children, $p->pid;
        }
    }
    return @children;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Process - Process of Sympa

=head1 SYNOPSIS

  use Sympa::Process;
  my $process = Sympa::Process->instance;
  $process->init(pidname => 'sympa');

  $process->daemonize;

  $process->fork;
  $process->reap_child;

=head1 DESCRIPTION

L<Sympa::Process> implements the class to handle process itself of Sympa
software.

=head2 Methods

=over

=item instance ( )

I<Constructor>.
Creates a singleton instance of L<Sympa::Process> object.

Returns:

A new L<Sympa::Process> instance, or I<undef> for failure.

=item init ( key =E<gt> value, ... )

I<Instance method>.
TBD.

=item daemonize ( )

I<Instance method>.
Daemonizes process itself.
Process is given new process group, detached from TTY
and given new process ID.

Parameters:

None.

Returns:

None.

=item fork ( [ $tag ] )

I<Instance method>.
Forks process.
Note that this method should be used instead of fork() in Perl core.

Parameter:

=over

=item $tag

A string to determine new child process.
By default the name of calling process.

=back

Returns:

See L<perlfunc/"fork">.

=item reap_child ( [ blocking =E<gt> 1 ], [ children =E<gt> \%children ],
file =E<gt> 1 ] )

I<Instance method>.
Non blocking function called by: main loop of sympa, task_manager, bounced
etc., just to clean the defuncts list by waiting to any processes and
decrementing the counter.

Parameter:

=over

=item blocking =E<gt> 1

Operation would block.

=item children =E<gt> \%children

Syncs PIDs in local map %children.

=item file =E<gt> 1

Syncs child PIDs in PID file.
If dead PID is found, notification will be sent to super-listmaster.

=back

Returns:

PID of reaped child porocess or C<0>.
If blocking option is set, returns C<0>.
In both cases returns C<-1> on failure.

=item remove_pid ([ pid =E<gt> $pid ], [ final =E<gt> 1 ] )

I<Instance method>.
Removes process ID from PID file.
Then if the file is empty, it will be removed.

=item write_pid ( [ initial =E<gt> 1 ], [ pid =E<gt> $pid ] )

I<Instance method>.
Writes or adds process ID to PID file.

Parameters:

=over

=item initial =E<gt> 1

Initializes PID file.
If the file remains, notification will be sent to super-listmaster.

=item pid =E<gt> $pid

Process ID to be written.
By default PID of current process.

=back

=item direct_stderr_to_file ( )

I<Instance method>.
TBD.

=back

=head2 Attributes

L<Sympa::Process> instance may have following attributes:

=over

=item {children}

Hashref with child PIDs forked by fork() method as keys.

=item {detached}

True value is set if daemonize() method was called and the process has been
detached from TTY.

=item {generation}

Generation of process.
If fork() method succeeds, it will be increased by child process.

=back

=head1 HISTORY

L<Sympa::Tools::Daemon> appeared on Sympa 6.2a.41.

Renamed L<Sympa::Process> appeared on Sympa 6.2.12
and began to provide OO interface.

Sympa 6.2.13 introduced daemonize() method and {detached} attribute.

=cut
