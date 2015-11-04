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
            my $status = $self->_twist($message, $handle);

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
