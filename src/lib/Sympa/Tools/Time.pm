# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
# Copyright 2018, 2023 The Sympa Community. See the
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

package Sympa::Tools::Time;

use strict;
use warnings;
use POSIX qw();
use Time::Local qw();
use Time::HiRes qw();

use constant has_gettimeofday => defined eval { Time::HiRes::gettimeofday() };

## convert an epoch date into a readable date scalar
# DEPRECATED: No longer used.
#sub adate($epoch);

# Note: This is used only once.
sub get_midnight_time {
    my $epoch = shift;
    my @date  = localtime $epoch;
    return Time::Local::timelocal(0, 0, 0, @date[3 .. 5]);
}

sub epoch_conv {
    my $arg = $_[0];    # argument date to convert

    my $result;

    # decomposition of the argument date
    my $date;
    my $duration;
    my $op;

    if ($arg =~ /^(.+)(\+|\-)(.+)$/) {
        $date     = $1;
        $duration = $3;
        $op       = $2;
    } else {
        $date     = $arg;
        $duration = '';
        $op       = '+';
    }

    #conversion
    $date = date_conv($date);
    $duration = duration_conv($duration, $date);

    if   ($op eq '+') { $result = $date + $duration; }
    else              { $result = $date - $duration; }

    return $result;
}

sub date_conv {
    my $arg = shift;

    if ($arg eq 'execution_date') {    # execution date
        return time;
    }

    if ($arg =~ /^\d+$/) {             # already an epoch date
        return $arg;
    }

    if ($arg =~ /^(\d\d\d\dy)(\d+m)?(\d+d)?(\d+h)?(\d+min)?(\d+sec)?$/) {
        # absolute date

        my @date = ($6, $5, $4, $3, $2, $1);
        foreach my $part (@date) {
            $part =~ s/[a-z]+$// if $part;
            $part ||= 0;
            $part += 0;
        }
        $date[3] = 1 if $date[3] == 0;
        $date[4]-- if $date[4] != 0;
        $date[5] -= 1900;

        return Time::Local::timelocal(@date);
    }

    return time;
}

sub duration_conv {

    my $arg        = $_[0];
    my $start_date = $_[1];

    return 0 unless $arg;

    my @date =
        ($arg =~ /(\d+y)?(\d+m)?(\d+w)?(\d+d)?(\d+h)?(\d+min)?(\d+sec)?$/i);
    foreach my $part (@date) {
        $part =~ s/[a-z]+$// if $part;    ## Remove trailing units
        $part ||= 0;
    }

    my $duration =
        $date[6] +
        60 * ($date[5] +
            60 * ($date[4] + 24 * ($date[3] + 7 * $date[2] + 365 * $date[0]))
        );

    # specific processing for the months because their duration varies
    my @months = (
        31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31,
        31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31
    );
    my $start = (defined $start_date) ? (localtime($start_date))[4] : 0;
    for (my $i = 0; $i < $date[1]; $i++) {
        $duration += $months[$start + $i] * 60 * 60 * 24;
    }

    return $duration;
}

sub gettimeofday {
    return (@_ = Time::HiRes::gettimeofday()) if has_gettimeofday();

    my $orig_locale = POSIX::setlocale(POSIX::LC_NUMERIC());
    POSIX::setlocale(POSIX::LC_NUMERIC(), 'C');

    my ($second, $subsecond) =
        split /[.]/, sprintf('%.6f', Time::HiRes::time());
    $subsecond ||= '0' x 6;
    $subsecond += 0;

    POSIX::setlocale(POSIX::LC_NUMERIC(), $orig_locale);
    return ($second, $subsecond);
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Tools::Time - Time-related functions

=head1 DESCRIPTION

This package provides some time-related functions.

=head2 Functions

=over

=item date_conv ( $arg )

I<Function>.
TBD.

=item duration_conv ( $arg, [ $startdate ] )

I<Function>.
TBD.

=item epoch_conv ( $arg )

I<Function>.
Converts a human format date into an Unix time.
TBD.

=item get_midnight_time ( $time )

I<Function>.
Returns the Unix time corresponding to the last midnight before date given
as argument.

=item gettimeofday ( )

I<Function>.
Returns an array C<(I<second>, I<microsecond>)> of current Unix time.

If the system does not have gettimeofday(2) system call, this function
emulates it.

=back

=head1 HISTORY

L<Sympa::Tools::Time> appeared on Sympa 6.2a.37.

gettimeofday() function was introduced on Sympa 6.2.10.

=cut
