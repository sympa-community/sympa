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

use Conf;

require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(%Ldap);

my @valid_options = qw(host port suffix filter scope);

my %valid_options = ();
map { $valid_options{$_}++; } @valid_options;

my %Default_Conf =
    ( 	'host'=> undef,
    	'port' => undef,
    	'suffix' => undef,
    	'filter' => undef,
    	'scope' => undef
   );

%Ldap = ();

## Loads and parses the configuration file. Reports errors if any.
sub load {
    my $config = shift;

   &Log::do_log('debug2','Ldap::load(%s)', $config);

    my $line_num = 0;
    my $config_err = 0;
    my($i, %o);

    ## Open the configuration file or return and read the lines.
    unless (open(IN, $config)) {
	&Log::do_log('err','Unable to open %s: %s', $config, $!);
	return undef;
    }
    while (<IN>) {
	$line_num++;
	next if (/^\s*$/o || /^[\#\;]/o);

	if (/^(\S+)\s+(.+)$/io) {
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
	next if ($valid_options{$i});
	&Log::do_log('err',"Line %d, unknown field: %s \n", $o{$i}[1], $i);
	$config_err++;
    }
    ## Do we have all required values ?
    foreach $i (keys %valid_options) {
	unless (defined $o{$i} or defined $Default_Conf{$i}) {
	    &Log::do_log('err',"Required field not found : %s\n", $i);
	    $config_err++;
	    next;
	}
	$Ldap{$i} = $o{$i}[0] || $Default_Conf{$i};
	
    }
 return %Ldap;
}

sub export_list{
    my ($directory,$list) = @_;

    &Log::do_log('debug',' Ldap::export_list(%s,%s)', $directory,$list->{'name'});

    my (@owner_emails,@editor_emails,@editor_names,@owner_names);

    ##To record owner's and editor's email and gecos
    ## !! STRUCTURE LDAP A REVOIR
    foreach my $element (@{$list->{'admin'}{'owner'}}){
	push(@owner_emails,$element->{'email'}) if(defined $element->{'email'}) ;
	push(@owner_names,$element->{'gecos'}) if(defined $element->{'gecos'});
    }

    foreach my $element (@{$list->{'admin'}{'editor'}}){
	push(@editor_emails,$element->{'email'}) if(defined $element->{'email'}) ;
	push(@editor_names,$element->{'gecos'}) if(defined $element->{'gecos'});
    }

    unless (require Net::LDAP) {
       &Log::do_log ('err',"Unable to use LDAP library, Net::LDAP required, install perl-ldap (CPAN) first");
       return undef;
    }
    
    ##Connexion
    my $ldap = Net::LDAP->new($Conf{'ldap_export'}{$directory}{'host'});

    unless ($ldap) {
	&Log::do_log('err',"Ldap::export_list:Unable to bind to the directory %s", $dir);
	return undef;
    }
  
    ##Bind:To verify the password
    my $cnx = $ldap->bind(dn => "$Conf{'ldap_export'}{$directory}{'DnManager'}" , password => "$Conf{'ldap_export'}{$directory}{'password'}");

    unless($cnx->code == 0){
	&Log::do_log('notice', 'Ldap::export_list:Incorrect password for binding with dn: %s',$Conf{'ldap_export'}{$directory}{'DnManager'});
	$ldap->unbind;
	return undef;
    }
    
    ##If the entry already exists delete it
    
    return undef
	unless &delete_list($directory, $list, $ldap);
	
    my $list_email = "$list->{'name'}".'@'."$list->{'admin'}{'host'}"; 
    my $dn = "cn=$list_email,$Conf{'ldap_export'}{$directory}{'suffix'}";

    my $total =  $list->get_total() || 0;
    my $result_add = $ldap->add( 
				 dn => "$dn",
				 attrs => [
					   'cn' => "$list_email",
					   'listName' => "$list->{'name'}",
					   'listEmailAddress' => "$list_email",
					   'listSubject' => "$list->{'admin'}{'subject'}" || 'unknown',
					   'listLang' => $list->{'admin'}{'lang'},
					   'listCreateDate' => $list->{'admin'}{'creation'}{'date'} || 'unknown',
					   'listCreateDateepoch' => $list->{'admin'}{'creation'}{'date_epoch'} || 0,
					   'listDescription' =>$list->get_info() || 'unknown',
					   'listSubscribersNumber' => "$total",
					   'robotEmail' =>  "$list->{'admin'}{'host'}",
					   'robotType' => 'sympa',
	         			   'listUrlHomePage' =>'http://'."$list->{'admin'}{'host'}".'/'.'wws',
					   'listUrlArc' => 'http://'."$list->{'admin'}{'host'}".'/wws/arc/'."$list->{'name'}",
					   'listUrlInfo' =>'http://'."$list->{'admin'}{'host'}".'/wws/info/'."$list->{'name'}",
				           'listTheme' => [@{$list->{'admin'}{'topics'}}],
				           #'listOwnerName' => [@owner_names]|| 'none' ,
					   #'listOwnerEmail' => [@owner_emails], 
					   #'listEditorName' => [@editor_names],
					   #'listEditorEmail' => [@editor_emails], 
					   'objectclass' => ['top','MailingList']
					   ]

                                );
    #&Log::do_log('notice',"xxxadd ok") if($result_add->code == 0);

    if($result_add->code != 0){
        #my $error = $result_add->error;
	&Log::do_log('err'," Ldap::export_list: Adding Error ");
#	my $server_error = $result_add->server_error;
#	&Log::do_log('err'," Ldap::export_list: Server error=$server_error ");
#	&Log::do_log('err','Ldap::export_list:Unable to add the entry %s, in the directory %s ',$dn,$Conf{'ldap_export'}{$directory}{'host'});
        $ldap->unbind();
        return undef;
   }

   $ldap->unbind();
   return 1;
}


sub delete_list{
    my($directory,$list,$ldap) = @_;
    &Log::do_log('debug2', 'Ldap::delete_list(%s,%s)', $directory,$list->{'name'});

    my $already_binded = 1;

    unless (require Net::LDAP) {
        &Log::do_log ('err',"Unable to use LDAP library, Net::LDAP required, install perl-ldap (CPAN) first");
        return undef;
    }
    
    ## We may used delete_list independently OR from export_list()
    unless (defined $ldap) {
      $already_binded = 0;

      $ldap = Net::LDAP->new($Conf{'ldap_export'}{$directory}{'host'});
    
      unless ($ldap) {
  	  &Log::do_log('err',"Ldap::delete_list:unable to bind to the directory %s", $dir);
	  return undef;
      }
    
      ##To verify the password
      my $cnx = $ldap->bind(dn => "$Conf{'ldap_export'}{$directory}{'DnManager'}" , password => "$Conf{'ldap_export'}{$directory}{'password'}");
    
      unless($cnx->code == 0){
	  &Log::do_log('notice', 'Ldap::delete_list:Incorrect dn %s for binding',$Conf{'ldap_export'}{$directory}{'DnManager'});
	  $ldap->unbind;
	  return undef;
      }
    }
    
    ##To create the dn and delete this entry
    my $list_email = "$list->{'name'}".'@'."$list->{'admin'}{'host'}"; 
    my $dn = "cn=$list_email,$Conf{'ldap_export'}{$directory}{'suffix'}";
    my $filter = "(listEmailAddress = $list_email)";
    
    my $result_search = $ldap->search (
				       base => "$Conf{'ldap_export'}{$directory}{'suffix'}",
				       filter => "$filter",
				       scope => 'sub',
				       );
    
    if($result_search->count > 0){
        my $result_delete = $ldap->delete("$dn");
	
	unless($result_delete->code == 0){
	    my $error = $result_delete->error;
	    &Log::do_log('err',"Ldap::export_list: Delete Error=$error");
	    return undef;
	}
    }
    
    &Log::do_log('info',"Ldap::delete_list: Deleting the entry $dn");
       
    $ldap->unbind 
        unless $already_binded;
}

sub get_exported_lists{
    my $filter = shift;
    my $directory = shift;

    &Log::do_log('debug2','Ldap::get_exported_lists(%s)',$directory);

    my %lists;
    
    unless (require Net::LDAP) {
	&Log::do_log ('err',"Unable to use LDAP library, Net::LDAP required, install perl-ldap (CPAN) first");
        return undef;
    }
    
    my $ldap = Net::LDAP->new($Conf{'ldap_export'}{$directory}{'host'}, timeout => $Conf{'ldap_export'}{$directory}{'connection_timeout'});
    unless ($ldap) {
	&Log::do_log('err',"unable to bind to '%s' directory", $directory);
	return undef;
    }
   
    $ldap->bind();
	
    my $search_filter = "(|(listEmailAddress=*$filter*)(listSubject=*$filter*))";
    my $result_search = $ldap->search (
				       base => "$Conf{'ldap_export'}{$directory}{'suffix'}",
				       filter => "$search_filter",
				       scope => 'sub',
				       );

    if($result_search->code != 0){
	&Log::do_log('notice',"No result for directory '%s' : %s",$directory, $result_search->error );
    }else{
	foreach my $entry ($result_search->all_entries){
	    $list_name = $entry->get_value('listName');
	    $list_address = $entry->get_value('listEmailAddress');
	    $subject = $entry->get_value('listSubject');
	    $urlinfo = $entry->get_value('listUrlInfo');
	    $host = $entry->get_value('robotEmail');
	    
	    %lists = ("$list_name" => {'list_address' => "$list_address",
				       'subject' => "$subject",
				       'urlinfo' => "$urlinfo",
				       'host' => "$host",                          	    
				   },
		      );
	}
    }
    $ldap->unbind;
    return %lists;
}


##Subroutine not used yet but may be useful later
sub get_dn_anonymous{

    my $datas = shift;
    $datas->{'timeout'} = 20 unless($datas->{'timeout'});
    $datas->{'scope'} = 'sub' unless($datas->{'scope'});
    
    unless (require Net::LDAP) {
        &Log::do_log ('err',"Unable to use LDAP library, Net::LDAP required, install perl-ldap (CPAN) first");
        return undef;
    }

    ##New
    my $ldap = Net::LDAP->new($datas->{'host'},timeout => $datas->{'timeout'});
    unless ($ldap) {
	&Log::do_log('err','Ldap::get_dn_anonymous :Unable to bind to the directory %s',$datas->{'host'});
	return undef;
    }

    ##Bind
    $ldap->bind();

    ##Search
    my $result_search = $ldap->search (
				       base => $datas->{'base'},
				       filter => $datas->{'filter'},
				       scope => $datas->{'scope'},
				       timeout => $datas->{'timeout'},
				       );
    if($result_search->code != 0){
	&Log::do_log('notice',"Ldap::get_dn_anonymous :No result for directory %s",$directory );
    }
    
    if ($result_search->count() == 0) {
	do_log('notice','Ldap::get_dn_anonymous : No entry in the Ldap Directory of %s',$datas->{'host'});
	$ldap->unbind;
    }
    
    my $refhash = $result_search->as_struct();
    my (@DN) = keys(%$refhash);
    $ldap->unbind;
    
    return $DN[0];
}



## Packages must return true.
1;






