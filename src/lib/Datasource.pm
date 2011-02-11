# Datasource.pm - This module includes external datasources related functions
#<!-- RCS Identication ; $Revision$ --> 

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

package Datasource;

use strict;

use Carp;
use Log;

############################################################
#  constructor
############################################################
#  Create a new datasource object. Handle SQL source only
#  at this moment. 
#  
# IN : -$type (+): the type of datasource to create
#         'SQL' or 'MAIN' for main sympa database
#      -$param_ref (+): ref to a Hash of config data
#
# OUT : instance of Datasource
#     | undef
#
##############################################################
sub new {
    my($pkg, $param_ref) = @_;
    my $datasrc= $param_ref;
    &do_log('debug2', 'Datasource::new($pkg)');

    ## Bless Message object
    bless $datasrc, $pkg;
    return $datasrc;
}

# Returns a unique ID for an include datasource
sub _get_datasource_id {
    my ($source) = shift;
    if (ref($source) eq 'Datasource') {
    	$source = shift;
    }

    if (ref ($source)) {
	## Ordering values so that order of keys in a hash don't mess the value comparison
	## Warning: Only the first level of the hash is ordered. Should a datasource 
	## be described with a hash containing more than one level (a hash of hash) we should transform
	## the following algorithm into something that would be recursive. Unlikely it happens.
	my @orderedValues;
	foreach my $key (sort (keys %{$source})) {
	    @orderedValues = (@orderedValues,$key,$source->{$key});
	}
	return substr(Digest::MD5::md5_hex(join('/', @orderedValues)), -8);
    }else {
	return substr(Digest::MD5::md5_hex($source), -8);
    }
	
}

## Packages must return true.
1;
