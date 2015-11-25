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

package Sympa::Spindle;

use strict;
use warnings;
use English qw(-no_match_vars);

sub new {
    my $class   = shift;
    my %options = @_;

    die $EVAL_ERROR unless eval sprintf 'require %s', $class->_distaff;
    my $distaff = $class->_distaff->new(%options);
    return undef unless $distaff;

    my %spools;
    my $spools = $class->_spools if $class->can('_spools');
    foreach my $key (sort keys %{$spools || {}}) {
        die $EVAL_ERROR unless eval sprintf 'require %s', $spools->{$key};
        my $spool = $spools->{$key}->new;
        return undef unless $spool;

        $spools{$key} = $spool;
    }

    my $self = bless {%options, %spools, distaff => $distaff} => $class;
    $self->_init(0) or return undef;
    $self;
}

sub spin {
    my $self = shift;

    my $processed = 0;

    while (1) {
        $self->_init(1);
        my ($message, $handle) = $self->{distaff}->next;

        if ($message and $handle) {
            my $status = $self->spin_once($message, $handle);
            unless (defined $status) {
                $self->_on_failure($message, $handle);
            } elsif ($status) {
                $self->_on_success($message, $handle);
            } else {
                $self->_on_skip($message, $handle);
            }

            $processed++;
            $self->_init(2);
        } elsif ($handle) {
            $self->_on_garbage($message, $handle);
        } else {
            last;
        }

        last if $self->{finish};
    }

    return $processed;
}

sub spin_once {
    my $self    = shift;
    my $message = shift;
    my $handle  = shift || 1;

    my $status = $self->_twist($message, $handle);
    while (ref $status eq 'ARRAY' and @$status) {
        foreach my $class (@$status) {
            die sprintf 'Illegal package name "%s"', $class
                unless $class =~ /\A(?:\w+::)*\w+\z/;
            die $EVAL_ERROR unless eval sprintf 'require %s', $class;
            my $twist = $class->can('_twist')
                or die sprintf
                'Can\'t locate object method "_twist" via package "%s"',
                $class;

            $status = $self->$twist($message, $handle);
            last unless $status;
        }
    }

    return $status;
}

sub _init {1}

sub _on_failure {
    my $self    = shift;
    my $message = shift;
    my $handle  = shift;

    $self->{distaff}->quarantine($handle);
}

sub _on_success {
    my $self    = shift;
    my $message = shift;
    my $handle  = shift;

    $self->{distaff}->remove($handle);
}

sub _on_skip {
    my $self    = shift;
    my $message = shift;
    my $handle  = shift;

    $handle->close if ref $handle;
}

sub _on_garbage {
    my $self    = shift;
    my $message = shift;
    my $handle  = shift;

    $self->{distaff}->quarantine($handle);
}

sub _twist {0}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Spindle - Base class of subclasses to define Sympa workflows

=head1 SYNOPSIS

  package Sympa::Spindle::FOO;
  use base qw(Sympa::Spindle);

  use constant _distaff => 'Sympa::Spool::BAR';
  
  sub _twist {
      my $self = shift;
      my $object = shift;
      my $handle = shift; 
  
      # Process object...
 
      return 1;                        # If succeeded.
      return 0;                        # If skipped.
      return undef;                    # If failed.
      return ['Sympa::Spindle::BAZ'];  # Splicing to another class.
  }

  1;

=head1 DESCRIPTION

L<Sympa::Spindle> is the base class of subclasses to define particular
workflows of Sympa.

A spindle class is a set of features to process objects.
If spin() method is called, it retrieves each object from source spool,
processes it, at last passes altered object to appropriate destination
(another spool or mailer), and removes it as necessity.
Processing repeats until source spool is empty.

=head2 Public methods

=over

=item new ( [ key =E<gt> value, ... ] )

I<Constructor>.
Creates new instance of L<Sympa::Spindle>.

=item spin ( )

I<instance method>.
Fetches an object and handle locking it from source spool, processes them
calling _twist() and repeats.
If source spool no longer gives content, returns the number of processed
objects.

=back

=head2 Properties

Instance of L<Sympa::Spindle> may have following properties.

=over

=item {distaff}

Instance of source spool class _distaff() method returns.

=item {finish}

I<Read/write>.
At first this property is false.
Once it is set, spin() finishes processing safely.

=item Spools

Instances of spool classes _spools() method returns.

=back

=head2 Methods subclass should implement

=over

=item _distaff ( )

I<Class method>, I<mandatory>.
Returns the name of source spool class.
source spool class must implement new() and next().

=item _init ( $state )

I<Instance method>.
Additional processing
when the spindle class is instantiated ($state is 0), before spin() processes
next object in source spool ($state is 1) or after it processed object
($state is 2).

If it returns false value, new() will return C<undef> (when $state is 0)
or spin() will terminate processing (when $state is 1).
By default it always returns C<1>.

=item _on_garbage ( $handle )

I<Instance method>, I<overridable>.
Executes process when object could not be deserialized (new() method of object
failed).
By default, quarantines object calling quearantine() method of source spool.

=item _on_failure ( $message, $handle )

I<Instance method>, I<overridable>.
Executes process when processing of $message failed (_twist() returned
C<undef>).
By default, quarantines object calling quearantine() method of source spool.

=item _on_skip ( $message, $handle )

I<Instance method>, I<overridable>.
Executes process when $message was skipped (_twist() returned C<0>).
By default, simply unlocks object calling close() method of $handle.

=item _on_success ( $message, $handle )

I<Instance method>, I<overridable>.
Executes process when processing of $message succeeded (_twist() returned true
value).
By default, removes object calling remove() method of source spool.

=item _spools ( )

I<Class method>.
If implemented, returns hashref with names of spool classes related to the
spindle as values.

=item _twist ( $message, $handle )

I<Instance method>, I<mandatory>.
Processes an object: Typically, modifys object or creates another object and
stores it into appropriate spool.

Parameters:

=over

=item $message

An object fetched from source spool.

=item $handle

A handle locking the object.
On filesystem spool it is filehandle;
on collection it is true scalar value (see also L<Sympa::Spool>).

=back

Returns:

Status of processing:
True value on success; C<0> if processing skipped; C<undef> on failure.

As of Sympa 6.2.13, _twist() may also return the reference to array including
name(s) of other classes:
In this case spin() will call _twist() method of given classes in order
(not coercing spindle object into them) and uses finally returned value.

=back

=head1 SEE ALSO

L<Sympa::Spool>.

=head1 HISTORY

L<Sympa::Spindle> appeared on Sympa 6.2.10.

=cut
