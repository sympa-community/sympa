#!/usr/bin/perl

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






