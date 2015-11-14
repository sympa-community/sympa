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
use base qw(Class::Singleton);

use English qw(-no_match_vars);
use POSIX qw();

use Sympa::Constants;
use Sympa::LockedFile;
use Sympa::Log;

my $log = Sympa::Log->instance;

# Constructor for Class::Singleton.
sub _new_instance {
    my $class = shift;

    bless {children => {}} => $class;
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

    if ($options{pidname}) {
        my $pidname = $options{pidname};
        foreach my $child_pid (_get_pids_in_pid_file($pidname)) {
            next if $child_pid == $PID;

            unless (exists $self->{children}->{$child_pid}) {
                $log->syslog(
                    'err',
                    'The %s child exists in the PID file but is no longer running. Removing it and notifying listmaster',
                    $child_pid
                );
                Sympa::Tools::Daemon::remove_pid($pidname, $child_pid,
                    {multiple_process => 1});
                Sympa::Tools::Daemon::send_crash_report(
                    pid   => $child_pid,
                    pname => [split /\//, $PROGRAM_NAME]->[-1]
                );
            }
        }
    }

    return $pid;
}

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

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Process - Process of Sympa

=head1 SYNOPSIS

  use Sympa::Process;
  my $process = Sympa::Process->instance;

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
pidname =E<gt> $name ] )

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

=item pidname =E<gt> $name

Syncs child PIDs in PID file named $name.pid.
If dead PID is found, notification will be send to listmaster.

=back

Returns:

PID of reaped child porocess.
C<-1> on error.

=back

=head2 Attributes

L<Sympa::Process> instance may have following attributes:

=over

=item {children}

TBD.

=back

=head1 HISTORY

L<Sympa::Process> appeared on Sympa 6.2.12.

=cut
