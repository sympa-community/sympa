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

use Sympa::Log;

my $log = Sympa::Log->instance;

# Constructor for Class::Singleton.
sub _new_instance {
    my $class = shift;

    bless {children => {}} => $class;
}

sub fork {
    my $self = shift;

    my $pid = CORE::fork();
    unless (defined $pid) {
        ;
    } elsif ($pid) {
        $self->{children}->{$pid} = 1;
    } else {
        $self->{children} = {};
    }
    $pid;
}

# Old name: Sympa::Mailer::reaper().
sub reap_child {
    my $self    = shift;
    my %options = @_;

    my $blocking = $options{blocking};

    my $pid;
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
                'Child process %s for message <%s> was terminated by signal %d',
                $pid,
                $self->{children}->{$pid},
                $CHILD_ERROR & 127
            );
        } elsif ($CHILD_ERROR) {
            $log->syslog(
                'err',
                'Child process %s for message <%s> exited with status %s',
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

    return $pid;
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

=item fork ( )

I<Instance method>.
Forks process.
Note that this method should be used instead of fork() in Perl core.

=item reap_child ( [ blocking =E<gt> 1 ], [ children =E<gt> \%children ] )

I<Instance method>.
Non blocking function called by: main loop of sympa, task_manager, bounced
etc., just to clean the defuncts list by waiting to any processes and
decrementing the counter.

Parameter:

=over

=item blocking =E<gt> 1

Operation would block.

=item children =E<gt> \%children

Syncs local map of child PIDs.

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
