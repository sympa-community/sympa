# DBManipulatorDefault.pm - This module contains default manipulation functions.
# they are used if not defined in the DBManipulator<*> subclasses.
#<!-- RCS Identication ; $Revision: 7016 $ --> 
#
# Sympa - SYsteme de Multi-Postage Automatique
# Copyright (c) 1997, 1998, 1999, 2000, 2001 Comite Reseau des Universites
# Copyright (c) 1997,1998, 1999 Institut Pasteur & Christophe Wolfhugel
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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

package DBManipulatorDefault;

use strict;

use Carp;
use Log;

use Datasource;

our @ISA = qw(Datasource);

sub build_connect_string {
    my $self = shift;
    $self->{'connect_string'} = "DBI:$self->{'db_type'}:$self->{'db_name'}:$self->{'db_host'}";
}

## Returns an SQL clause to be inserted in a query.
## This clause will compute a substring of max length
## $param->{'substring_length'} starting from the first character equal
## to $param->{'separator'} found in the value of field $param->{'source_field'}.
sub get_substring_clause {
    my $self = shift;
    my $param = shift;
    return "REVERSE(SUBSTRING(".$param->{'source_field'}." FROM position('".$param->{'separator'}."' IN ".$param->{'source_field'}.") FOR ".$param->{'substring_length'}."))";
}

## Returns an SQL clause to be inserted in a query.
## This clause will limit the number of records returned by the query to
## $param->{'rows_count'}. If $param->{'offset'} is provided, an offset of
## $param->{'offset'} rows is done from the first record before selecting
## the rows to return.
sub get_limit_clause {
    my $self = shift;
    my $param = shift;
    if ($param->{'offset'}) {
	return "LIMIT ".$param->{'offset'}.",".$param->{'rows_count'};
    }else{
	return "LIMIT ".$param->{'rows_count'};
    }
}

## Returns a character string corresponding to the expression to use in a query
## involving a date.
## Takes a hash as argument which can contain the following keys:
## * 'mode'
##   authorized values:
##	- 'write': the sub returns the expression to use in 'INSERT' or 'UPDATE' queries
##	- 'read': the sub returns the expression to use in 'SELECT' queries
## * 'target': the name of the field or the value to be used in the query
##
sub get_formatted_date {
    my $self = shift;
    my $param = shift;
    if (lc($param->{'mode'}) eq 'read') {
	return sprintf 'UNIX_TIMESTAMP(%s)',$param->{'target'};
    }elsif(lc($param->{'mode'}) eq 'write') {
	return sprintf 'FROM_UNIXTIME(%d)',$param->{'target'};
    }else {
	&Log::do_log('err',"Unknown date format mode %s", $param->{'mode'});
	return undef;
    }
}
return 1;
