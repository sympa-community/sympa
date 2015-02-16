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

=encoding utf-8

=head1 NAME

Sympa::Tools::Daemon - Daemon-related functions

=head1 DESCRIPTION

This package provides some daemon-related functions.

=head2 Functions

=cut

package Sympa::Tools::Daemon;

use strict;
use warnings;
use English qw(no_match_vars);
use Proc::ProcessTable;
use Sys::Hostname qw();

use Sympa::Constants;
use Sympa::Language;
use Sympa::LockedFile;
use Log;
use tools;
use Sympa::Tools::File;

=over

=item get_daemon_name($path)

Returns a name for current process, suitable for logging.

=back

=cut

# Old name: Log::set_daemon().
sub get_daemon_name {
    my $daemon_tmp = shift;
    my @path       = split(/\//, $daemon_tmp);
    my $daemon     = $path[$#path];
    $daemon =~ s/(\.[^\.]+)$//;
    return $daemon;
}

=over

=item remove_pid($name, $pid, $options)

Remove PID file and STDERR output.

=back

=cut

sub remove_pid {
    my ($name, $pid, $options) = @_;

    my $piddir  = Sympa::Constants::PIDDIR;
    my $pidfile = $piddir . '/' . $name . '.pid';

    my @pids;

    # Lock pid file
    my $lock_fh = Sympa::LockedFile->new($pidfile, 5, '+<');
    unless ($lock_fh) {
        Log::do_log('err', 'Could not open %s to remove PID %s',
            $pidfile, $pid);
        return undef;
    }

    ## If in multi_process mode (bulk.pl for instance can have child
    ## processes) then the PID file contains a list of space-separated PIDs
    ## on a single line
    if ($options->{'multiple_process'}) {
        # Read pid file
        seek $lock_fh, 0, 0;
        my $l = <$lock_fh>;
        @pids = grep { /^[0-9]+$/ and $_ != $pid } split(/\s+/, $l);

        ## If no PID left, then remove the file
        unless (@pids) {
            ## Release the lock
            unless (unlink $pidfile) {
                Log::do_log('err', "Failed to remove %s: %m", $pidfile);
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
            Log::do_log('err', "Failed to remove %s: %m", $pidfile);
            $lock_fh->close;
            return undef;
        }
        my $err_file = $Conf::Conf{'tmpdir'} . '/' . $pid . '.stderr';
        if (-f $err_file) {
            unless (unlink $err_file) {
                Log::do_log('err', "Failed to remove %s: %m", $err_file);
                $lock_fh->close;
                return undef;
            }
        }
    }

    $lock_fh->close;
    return 1;
}

=over

=item write_pid($name, $pid, $options)

TBD.

=back

=cut

sub write_pid {
    my ($name, $pid, $options) = @_;

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

    ## If we can have multiple instances for the process.
    ## Print other pids + this one
    if ($options->{'multiple_process'}) {
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
            Log::do_log('notice',
                'Previous process %s died suddenly; notifying listmaster',
                $other_pid);
            my $pname = $0;
            $pname =~ s/.*\/(\w+)/$1/;
            send_crash_report(('pid' => $other_pid, 'pname' => $pname));
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

=over

=item direct_stderr_to_file(%parameters)

TBD.

=back

=cut

sub direct_stderr_to_file {
    my %data = @_;
    ## Error output is stored in a file with PID-based name
    ## Usefull if process crashes
    open(STDERR, '>>',
        $Conf::Conf{'tmpdir'} . '/' . $data{'pid'} . '.stderr');
    unless (
        Sympa::Tools::File::set_file_rights(
            file  => $Conf::Conf{'tmpdir'} . '/' . $data{'pid'} . '.stderr',
            user  => Sympa::Constants::USER,
            group => Sympa::Constants::GROUP,
        )
        ) {
        Log::do_log(
            'err',
            'Unable to set rights on %s',
            $Conf::Conf{'tmpdir'} . '/' . $data{'pid'} . '.stderr'
        );
        return undef;
    }
    return 1;
}

=over

=item send_crash_report(%parameters)

Send content of $pid.stderr to listmaster for process whose pid is $pid.

=back

=cut

sub send_crash_report {
    my %data = @_;
    Log::do_log('debug', 'Sending crash report for process %s', $data{'pid'}),
        my $err_file = $Conf::Conf{'tmpdir'} . '/' . $data{'pid'} . '.stderr';

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
    tools::send_notify_to_listmaster(
        '*', 'crash',
        {   'crashed_process' => $data{'pname'},
            'crash_err'       => \@err_output,
            'crash_date'      => $err_date,
            'pid'             => $data{'pid'}
        }
    );
}

# return a lockname that is a uniq id of a processus (hostname + pid) ;
# hostname(20) and pid(10) are truncated in order to store lockname in
# database varchar(30)
# DEPRECATED: No longer used.
#sub get_lockname();

=over

=item get_pids_in_pid_file($name)

Returns the list of pid identifiers in the pid file.

=back

=cut

sub get_pids_in_pid_file {
    my $name = shift;

    my $piddir  = Sympa::Constants::PIDDIR;
    my $pidfile = $piddir . '/' . $name . '.pid';

    my $lock_fh = Sympa::LockedFile->new($pidfile, 5, '<');
    unless ($lock_fh) {
        Log::do_log('err', 'Unable to open PID file %s: %m', $pidfile);
        return undef;
    }
    my $l = <$lock_fh>;
    my @pids = grep {/^[0-9]+$/} split(/\s+/, $l);
    $lock_fh->close;
    return \@pids;
}

=over

=item get_children_processes_list()

TBD.

=back

=cut

sub get_children_processes_list {
    Log::do_log('debug3', '');
    my @children;
    for my $p (@{Proc::ProcessTable->new->table}) {
        if ($p->ppid == $PID) {
            push @children, $p->pid;
        }
    }
    return @children;
}

1;
