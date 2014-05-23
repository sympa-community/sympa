# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014 GIP RENATER
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

## This package handles Sympa virtual robots
## It should :
##   * provide access to global conf parameters,
##   * deliver the list of lists
##   * determine the current robot, given a host
package Robot;

use Conf;

## Constructor of a Robot instance
sub new {
    my ($pkg, $name) = @_;

    my $robot = {'name' => $name};
    Log::do_log('debug2', '');

    unless (defined $name && $Conf::Conf{'robots'}{$name}) {
        Log::do_log('err', "Unknown robot '$name'");
        return undef;
    }

    ## The default robot
    if ($name eq $Conf::Conf{'domain'}) {
        $robot->{'home'} = $Conf::Conf{'home'};
    } else {
        $robot->{'home'} = $Conf::Conf{'home'} . '/' . $name;
        unless (-d $robot->{'home'}) {
            Log::do_log('err',
                "Missing directory '$robot->{'home'}' for robot '$name'");
            return undef;
        }
    }

    ## Initialize internal list cache
    undef %list_cache;

    # create a new Robot object
    bless $robot, $pkg;

    return $robot;
}

## load all lists belonging to this robot
sub get_lists {
    my $self = shift;

    return List::get_lists($self->{'name'});
}

1;
