#!--PERL--

# testldap.pl - This script aims at testing LDAP queries
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

unless ($#ARGV == 3) {
   die "Usage $ARGV[-1] <host> <suffix> <filter> <attrs>";
}

($directory, $suffix, $filter, $attrs) = @ARGV;

printf "host : $directory\nsuffix : $suffix\nfilter: $filter\n";
use Net::LDAP;
$ldap=Net::LDAP->new($directory) or print "connect impossible\n";
$ldap->bind or print "bind impossible \n";

#$mesg = $ldap->search ( base => "$suffix", filter => "(cn=$nom)" )
$mesg = $ldap->search ( base => "$suffix", 
			filter => "$filter", 
			attrs => [$attrs] )
or  print "Search  impossible \n";

# $mesg->code or  print "code chjie\n";

#foreach $entry ($mesg->all_entries) { 

#    $entry->dump;
#    printf "-- %s \n", $entry->get('mail');
#}

$res = $mesg->as_struct ;

#foreach my $k (keys %$res) {
#   printf "\t%s => %s\n", $k, $res->{$k};
#}

foreach $dn (keys %$res) {
        
   my $hash = $res->{$dn};
   print "#$dn\n";

   foreach my $k (keys %$hash) {
     my $array = $hash->{$k};
     if ((ref($array) eq 'ARRAY') and ($k ne 'jpegphoto')) {
        printf "\t%s => %s\n", $k, join(',', @$array);
     }else {
       printf "\t%s => %s\n", $k, $array;
     }
   }
  $cpt++;
}

print "Total : $cpt\n";

$ldap->unbind or print "unbind impo \n";






