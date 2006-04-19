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

use Getopt::Long;

my %opt;
unless (&GetOptions(\%opt, 'host=s', 'suffix=s', 'filter=s','attrs=s', 'ssl=s', 'scope=s')) {
    die "Unknown options.";
}

unless (defined $opt{'host'} &&
	defined $opt{'suffix'} &&
	defined $opt{'filter'}) {
    die "Usage $ARGV[-1] --host=<host> --ssl=on|off --suffix=<suffix> --scope=base|one|sub --filter=<filter> --attrs=<attrs>";
}

printf "host : $opt{'host'}\nsuffix : $opt{'suffix'}\nfilter: $opt{'filter'}\n";

my %arg;
$arg{'scope'} = $opt{'scope'};


if ($opt{'ssl'} eq 'on') {
    eval "require Net::LDAPS";

    $arg{'sslversion'} = 'sslv3';
    $arg{'sslciphers'} = 'ALL';

    $ldap=Net::LDAPS->new($opt{'host'},%arg) or print "connect impossible\n";
}else {
    use Net::LDAP;
    $ldap=Net::LDAP->new($opt{'host'},%arg) or print "connect impossible\n";
}

$ldap->bind or print "bind impossible \n";

#$mesg = $ldap->search ( base => "$opt{'suffix'}", filter => "(cn=$nom)" )
$mesg = $ldap->search ( base => $opt{'suffix'}, 
			filter => $opt{'filter'}, 
			attrs => [$opt{'attrs'}] )
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






