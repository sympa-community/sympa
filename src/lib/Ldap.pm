# Ldap.pm - This module includes most LDAP-related functions
# RCS Identication ; $Revision$ ; $Date$ 
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

package Ldap;

use strict "vars";

use Conf;

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(%Ldap);

my @valid_options = qw(host suffix filter scope bind_dn bind_password);
my  @required_options = qw(host suffix filter);

my %valid_options = ();
map { $valid_options{$_}++; } @valid_options;

my %required_options = ();
map { $required_options{$_}++; } @required_options;

my %Default_Conf =
    ( 	'host'=> undef,
    	'suffix' => undef,
    	'filter' => undef,
    	'scope' => 'sub',
	'bind_dn' => undef,
	'bind_password' => undef
   );

my %Ldap = ();

## Loads and parses the configuration file. Reports errors if any.
sub load {
    my $config = shift;

   &Log::do_log('debug3','Ldap::load(%s)', $config);

    my $line_num = 0;
    my $config_err = 0;
    my($i, %o);

    ## Open the configuration file or return and read the lines.
    unless (open(IN, $config)) {
	&Log::do_log('err','Unable to open %s: %s', $config, $!);
	return undef;
    }

    my $folded_line;
    while (my $current_line = <IN>) {
	$line_num++;
	next if ($current_line =~ /^\s*$/o || $current_line =~ /^[\#\;]/o);

	## Cope with folded line (ending with '\')
	if ($current_line =~ /\\\s*$/) {
	    $current_line =~ s/\\\s*$//; ## remove trailing \
	    chomp $current_line;
	    $folded_line .= $current_line;
	    next;
	}elsif (defined $folded_line) {
	    $current_line = $folded_line.$current_line;
	    $folded_line = undef;
	}

	if ($current_line =~ /^(\S+)\s+(.+)$/io) {
	    my($keyword, $value) = ($1, $2);
	    $value =~ s/\s*$//;
	
	    $o{$keyword} = [ $value, $line_num ];
	}else {
#	    printf STDERR Msg(1, 3, "Malformed line %d: %s"), $config, $_;
	    $config_err++;
	}
    }
    close(IN);


    ## Check if we have unknown values.
    foreach $i (sort keys %o) {
	$Ldap{$i} = $o{$i}[0] || $Default_Conf{$i};
	
	unless ($valid_options{$i}) {
	    &Log::do_log('err',"Line %d, unknown field: %s \n", $o{$i}[1], $i);
	    $config_err++;
	}
    }
    ## Do we have all required values ?
    foreach $i (keys %required_options) {
	unless (defined $o{$i} or defined $Default_Conf{$i}) {
	    &Log::do_log('err',"Required field not found : %s\n", $i);
	    $config_err++;
	    next;
	}
    }
 return %Ldap;
}

## Packages must return true.
1;






