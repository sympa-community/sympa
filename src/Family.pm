# Family.pm - This module manages list families
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

package Family;

use strict;
use XML::LibXML;

## Sympa API
use List;
use Conf;
use Log;
use admin;
use Config_XML;

my %list_of_families;

## Class methods
################

sub get_available_families {
    my $robot = shift;

    my %families;

    foreach my $dir ('--ETCBINDIR--/families',
		     $Conf{'etc'}.'/families',
		     $Conf{'etc'}.'/'.$robot.'/families') {
	next unless (-d $dir);

	unless (opendir FAMILIES, $dir) {
	    &do_log ('err', "error : can't open dir %s: %s", $dir, $!);
	    next;
	}

	foreach my $subdir (grep !/^\.\.?$/, readdir FAMILIES) {
	    if (my $family = new Family($subdir, $robot)) { 
		$families{$subdir} = 1;
	    }
	}
    }
    
    return keys %families;
}

## Instance methods
###################

#########################################
# new                                   
#########################################
# constructor of the class Family :
#   check family existence (required files
#   and directory)
#
# IN : -$class 
#      -$name : family name
#      -robot : family robot
# OUT : -$self
#########################################
sub new {
    my $class = shift;
    my $name = shift;
    my $robot = shift;
    &do_log('debug2','Family::new(%s,%s)',$name,$robot);
    
    my $self = {};

    if ($list_of_families{$name}) {
        # use the current family in memory and update it
	$self = $list_of_families{$name};
###########
	# the robot can be different from lastest new ...
	if ($robot eq $self->{'robot'}) {
	return $self;
	}else {
	    $self = {};
	}
    }
        # create a new object family
	bless $self, $class;
	$list_of_families{$name} = $self;

    ## family name
    unless ($name && ($name =~ /^$tools::regexp{'family_name'}$/io) ) {
	&do_log('err', 'Incorrect family name "%s"',  $name);
	return undef;
    }

    ## Lowercase the family name.
    $name =~ tr/A-Z/a-z/;
    $self->{'name'} = $name;

    $self->{'robot'} = $robot;

    ## family directory
    $self->{'dir'} = $self->_get_directory();
    unless (defined $self->{'dir'}) {
	&do_log('err','Family::new(%s,%s) : the family directory does not exist',$name,$robot);
	return undef;
    }

    ## family files
    if (my $file_names = $self->_check_obligatory_files()) {
	&do_log('err','Family::new(%s,%s) : Definition family files are missing : %s',$name,$robot,$file_names);
	return undef;
    }

    ## file mtime
    $self->{'mtime'}{'param_constraint_conf'};
    
    ## hash of parameters constraint
    $self->{'param_constraint_conf'} = undef;

    ## state of the family for the use of check_param_constraint : 'no_check' or 'normal'
    ## check_param_constraint  only works in state "normal"
    $self->{'state'} = 'normal';

    return $self;
}
     
#########################################
# add_list                                
#########################################
# add a list to the family under to current robot:
# (list described by the xml file)
#  
# IN : -$self
#      -$fh : file handle on the xml file
# OUT : -$return->{'ok'} = 1(pas d'erreur fatale) or undef(erreur fatale)
#       -$return->{'string'} : string of results 
#########################################
sub add_list {
    my $self = shift;
    my $fh = shift;
    &do_log('info','Family::add_list(%s)',$self->{'name'});

    $self->{'state'} = 'no_check';
    my $return;
    $return->{'ok'} = undef;
    $return->{'string_info'} = ""; ## info and simple errors
    $return->{'string_error'} = ""; ## fatal errors

    #copy the xml file in another file
    unless (open (FIC,">$self->{'dir'}/_new_list.xml")) {
	&do_log('err','Family::add_list(%s) : impossible to create the temp file %s/_new_list.xml : %s',$self->{'name'},$self->{'dir'},$!);
    }
    while (<$fh>) {
	print FIC ($_);
    }
    close FIC;

    # get list data
    open (FIC,"$self->{'dir'}/_new_list.xml");
    my $config = new Config_XML(\*FIC);
    close FIC;
    unless (defined $config->createHash()) {
	$return->{'string_error'} = "\nError in representation data with these xml data\n";
	return $return;
    } 

    my $hash_list = $config->getHash();

    #list creation
    my $result = &admin::create_list($hash_list->{'config'},$self,,$self->{'robot'});
    unless (defined $result) {
	$return->{'string_error'} = "\nError during list creation, see logs for more informations\n";
	return $return;
    }
    unless (defined $result->{'list'}) {
	$return->{'string_error'} = "\nErrors : no created list, see logs for more informations\n";
	return $return;
    }
    my $list = $result->{'list'};
	    
    ## aliases
    if ($result->{'aliases'} == 1) {
	$return->{'string_info'} .= "\nList $list->{'name'} has been created in $self->{'name'} family\n";
    }else {
	$return->{'string_info'} .= "\nList $list->{'name'} has been created in $self->{'name'} family, required aliases :\n $result->{'aliases'} \n";
    }
	    
    # config_changes
    unless (open FILE, ">$list->{'dir'}/config_changes") {
	$list->set_status_error_config('error_copy_file',$list->{'name'},$self->{'name'});
	$return->{'string_info'} .="\n Impossible to create file $list->{'dir'}/config_changes : $!, the list is set in status error_config";
    }
    close FILE;
 
    my $host = &Conf::get_robot_conf($self->{'robot'}, 'host');

    # info parameters
    $list->{'admin'}{'latest_instantiation'}{'email'} = "listmaster\@$host";
    $list->{'admin'}{'latest_instantiation'}{'date'} = &POSIX::strftime("%d %b %Y at %H:%M:%S", localtime(time));
    $list->{'admin'}{'latest_instantiation'}{'date_epoch'} = time;
    $list->save_config("listmaster\@$host");
    $list->{'family'} = $self;
    
    ## check param_constraint.conf 
    $self->{'state'} = 'normal';
    my $error = $self->check_param_constraint($list);
    $self->{'state'} = 'no_check';
    
    unless (defined $error) {
	$list->set_status_error_config('no_check_rules_family',$list->{'name'},$self->{'name'});
	$return->{'string_error'} = "\nImpossible to check parameters constraint, see logs for more informations. The list is set in status error_config\n";
	return $return;
    }
    
    if (ref($error) eq 'ARRAY') {
	$list->set_status_error_config('no_respect_rules_family',$list->{'name'},$self->{'name'});
	$return->{'string_info'} .= "\The list does not respect the family rules : ".join(", ",@{$error})."\n";
    }
    
    ## copy files in the list directory : xml file

    unless ($self->_copy_files($list->{'dir'},"_new_list.xml")) {
	$list->set_status_error_config('error_copy_file',$list->{'name'},$self->{'name'});
	$return->{'string_info'} .= "\n Impossible to copy the xml file in the list directory, the list is set in status error_config.\n";
    }

    ## END
    $self->{'state'} = 'normal';
    $return->{'ok'} = 1;

    return $return;
}

#########################################
# modify_list                                
#########################################
# modify a list that belongs to the family
#  under to current robot:
# (the list is new described by the xml file)
#  
# IN : -$self
#      -$fh : file handle on the xml file
# OUT : -$return->{'ok'} = 1(pas d'erreur fatale) or undef(erreur fatale)
#       -$return->{'string'} : string of results 
#########################################
sub modify_list {
    my $self = shift;
    my $fh = shift;
    &do_log('info','Family::modify_list(%s)',$self->{'name'});

    $self->{'state'} = 'no_check';
    my $return;
    $return->{'ok'} = undef;
    $return->{'string_info'} = ""; ## info and simple errors
    $return->{'string_error'} = ""; ## fatal errors

    #copy the xml file in another file
    unless (open (FIC,">$self->{'dir'}/_mod_list.xml")) {
	&do_log('err','Family::modify_list(%s) : impossible to create the temp file %s/_mod_list.xml : %s',$self->{'name'},$self->{'dir'},$!);
    }
    while (<$fh>) {
	print FIC ($_);
    }
    close FIC;

    # get list data
    open (FIC,"$self->{'dir'}/_mod_list.xml");
    my $config = new Config_XML(\*FIC);
    close FIC;
    unless (defined $config->createHash()) {
	$return->{'string_error'} = "\nError in representation data with these xml data\n";
	return $return;
    } 

    my $hash_list = $config->getHash();

    #getting list
    my $list;
    unless ($list = new List($hash_list->{'config'}{'listname'},$self->{'robot'})) {
	$return->{'string_error'} = "\nThe list $hash_list->{'config'}{'listname'} does not exist.\n";
	return $return;
    }
    
    ## check family name
    if (defined $list->{'admin'}{'family_name'}) {
	unless ($list->{'admin'}{'family_name'} eq $self->{'name'}) {
	  $return->{'string_error'} = "\nThe list $list->{'name'} already belongs to family $list->{'admin'}{'family_name'}.\n";
	  return $return;
	} 
    } else {
	$return->{'string_error'} = "\nThe orphelan list $list->{'name'} already exists.\n";
	return $return;
    }

    ## get allowed and forbidden list customizing
    my $custom = $self->_get_customizing($list);
    unless (defined $custom) {
	&do_log('err','impossible to get list %s customizing',$list->{'name'});
	$return->{'string_error'} = "\nError during updating list $list->{'name'}, the list is set in status error_config.\n"; 
	$list->set_status_error_config('modify_list_family',$list->{'name'},$self->{'name'});
	return $return;
    }
    my $config_changes = $custom->{'config_changes'}; 
    my $old_status = $list->{'admin'}{'status'};

    ## list config family updating
    my $result = &admin::update_list($list,$hash_list->{'config'},$self,$self->{'robot'});
    unless (defined $result) {
	&do_log('err','No object list resulting from updating list %s',$list->{'name'});
	$return->{'string_error'} = "\nError during updating list $list->{'name'}, the list is set in status error_config.\n"; 
	$list->set_status_error_config('modify_list_family',$list->{'name'},$self->{'name'});
	return $return;
    }
    $list = $result;
 
    ## set list customizing
    foreach my $p (keys %{$custom->{'allowed'}}) {
	$list->{'admin'}{$p} = $custom->{'allowed'}{$p};
	delete $list->{'admin'}{'defaults'}{$p};
	&do_log('info',"Customizing : keeping values for parameter $p");
    }

    ## info file
    unless ($config_changes->{'file'}{'info'}) {
	$hash_list->{'config'}{'description'} =~ s/\015//g;
	
	unless (open INFO, ">$list->{'dir'}/info") {
	    $return->{'string_info'} .= "Impossible to create new $list->{'dir'}/info file : $!";
	}
	print INFO $hash_list->{'config'}{'description'};
	close INFO; 
    }

    foreach my $f (keys %{$config_changes->{'file'}}) {
	&do_log('info',"Customizing : this file has been changed : $f");
    }
    
    ## rename forbidden files
#    foreach my $f (@{$custom->{'forbidden'}{'file'}}) {
#	unless (rename ("$list->{'dir'}"."/"."info","$list->{'dir'}"."/"."info.orig")) {
	    ################
#	}
#	if ($f eq 'info') {
#	    $hash_list->{'config'}{'description'} =~ s/\015//g;
#	    unless (open INFO, ">$list_dir/info") {
		################
#	    }
#	    print INFO $hash_list->{'config'}{'description'};
#	    close INFO; 
#	}
#    }

    ## notify owner for forbidden customizing
    if (#(scalar $custom->{'forbidden'}{'file'}) ||
	(scalar @{$custom->{'forbidden'}{'param'}})) {
#	my $forbidden_files = join(',',@{$custom->{'forbidden'}{'file'}});
	my $forbidden_param = join(',',@{$custom->{'forbidden'}{'param'}});
	&do_log('notice',"These parameters aren't allowed in the new family definition, they are erased by a new instantiation family : \n $forbidden_param");

	unless ($list->new_send_notify_to_owner('erase_customizing',($self->{'name'},$forbidden_param))) {
	    &do_log('notice','the owner isn\'t informed from erased customizing of the list %s',$list->{'name'});
	}
    }

    ## status
    my $result = $self->_set_status_changes($list,$old_status);

    if ($result->{'aliases'} == 1) {
	$return->{'string_info'} .= "\nThe $list->{'name'} list has been modified.\n";
    
    }elsif ($result->{'install_remove'} eq 'install') {
	$return->{'string_info'} .= "\nList $list->{'name'} has been modified, required aliases :\n $result->{'aliases'} \n";
	
    }else {
	$return->{'string_info'} .= "\nList $list->{'name'} has been modified, aliases need to be removed : \n $result->{'aliases'} \n";
	
    }

    ## config_changes
    foreach my $p (@{$custom->{'forbidden'}{'param'}}) {

	if (defined $config_changes->{'param'}{$p}  ) {
	    delete $config_changes->{'param'}{$p};
	}

    }

    unless (open FILE, ">$list->{'dir'}/config_changes") {
	$list->set_status_error_config('error_copy_file',$list->{'name'},$self->{'name'});
	$return->{'string_info'} .="\n Impossible to create file $list->{'dir'}/config_changes : $!, the list is set in status error_config.\n";
    }
    close FILE;

    my @kept_param = keys %{$config_changes->{'param'}};
    $list->update_config_changes('param',\@kept_param);
    my @kept_files = keys %{$config_changes->{'file'}};
    $list->update_config_changes('file',\@kept_files);


    my $host = &Conf::get_robot_conf($self->{'robot'}, 'host');

    $list->{'admin'}{'latest_instantiation'}{'email'} = "listmaster\@$host";
    $list->{'admin'}{'latest_instantiation'}{'date'} = &POSIX::strftime("%d %b %Y at %H:%M:%S", localtime(time));
    $list->{'admin'}{'latest_instantiation'}{'date_epoch'} = time;
    $list->save_config("listmaster\@$host");
    $list->{'family'} = $self;
    
    ## check param_constraint.conf 
    $self->{'state'} = 'normal';
    my $error = $self->check_param_constraint($list);
    $self->{'state'} = 'no_check';
    
    unless (defined $error) {
	$list->set_status_error_config('no_check_rules_family',$list->{'name'},$self->{'name'});
	$return->{'string_error'} .= "\nImpossible to check parameters constraint, see logs for more informations. \nThe list is set in status error_config\n";
	return $return;
    }
    
    if (ref($error) eq 'ARRAY') {
	$list->set_status_error_config('no_respect_rules_family',$list->{'name'},$self->{'name'});
	$return->{'string_info'} .= "\nThe list does not respect the family rules : ".join(", ",@{$error})."\n";
    }
    
    ## copy files in the list directory : xml file

    unless ($self->_copy_files($list->{'dir'},"_mod_list.xml")) {
	$list->set_status_error_config('error_copy_file',$list->{'name'},$self->{'name'});
	$return->{'string_info'} .= "\nImpossible to copy the xml file in the list directory, the list is set in status error_config.\n";
    }

    ## END
    $self->{'state'} = 'normal';
    $return->{'ok'} = 1;

    return $return;
}

#########################################
# close                                 
#########################################
# closure family action :
#  - close every list family
#  
# IN : -$self
# OUT : -$string
#########################################
sub close {
    my $self = shift;
    &do_log('info','Family::close(%s)',$self->{'name'});

    my $family_lists = $self->get_family_lists();
    my @impossible_close;
    my @close_ok;

    foreach my $listname (@{$family_lists}) {
	my $list = new List($listname, $self->{'robot'});
	
	unless (defined $list){
	    &do_log('err','The %s list belongs to %s family but the list does not exist',$listname,$self->{'name'});
	    next;
	}
	
	unless ($list->set_status_family_closed('close_list',$self->{'name'})) {
	    push (@impossible_close,$list->{'name'});
	    next
	}
	push (@close_ok,$list->{'name'});
    }
    my $string = "\n\n******************************************************************************\n"; 
    $string .= "\n******************** CLOSURE of $self->{'name'} FAMILY ********************\n";
    $string .= "\n******************************************************************************\n\n"; 

    unless ($#impossible_close <0) {
	$string .= "\nImpossible list closure for : \n  ".join(", ",@impossible_close)."\n"; 
    }
    
    $string .= "\n****************************************\n";    

    unless ($#close_ok <0) {
	$string .= "\nThese lists are closed : \n  ".join(", ",@close_ok)."\n"; 
    }

    $string .= "\n******************************************************************************\n";
    
    return $string;
}



#########################################
# instantiate                                   
#########################################
# instantiate family action :
#  - create family lists if they are not
#  - update family lists if they already exist
#  
# IN : -$self
#      -$xml_fh : file handle on the xml file
# OUT : -1 or undef
#########################################
sub instantiate {
    my $self = shift;
    my $xml_fh = shift;
    &do_log('debug2','Family::instantiate(%s)',$self->{'name'});

    # initialize vars
    $self->_initialize_instantiation();
    
    # set impossible checking (used by list->load)
    $self->{'state'} = 'no_check';
	
    my $previous_family_lists = $self->get_hash_family_lists();

    ## xml instantiation data
    unless ($self->_split_xml_file($xml_fh)) {
	&do_log('err','Errors during the parsing of family xml file');
	return undef;
    }

    ## EACH FAMILY LIST
    foreach my $listname (@{$self->{'list_to_generate'}}) {

	my $list = new List($listname, $self->{'robot'});
	
        ## get data from list xml file
	my $xml_fh;
	open $xml_fh,"$self->{'dir'}"."/".$listname.".xml";
	my $config = new Config_XML($xml_fh);
	close $xml_fh;
	unless (defined $config->createHash()) {
	    push (@{$self->{'errors'}{'create_hash'}},"$self->{'dir'}/$listname.xml");
	    if ($list) {
 		$list->set_status_error_config('instantiation_family',$list->{'name'},$self->{'name'});
 	    }
	    next;
	} 
	my $hash_list = $config->getHash();

	## LIST ALREADY EXISTING
	if ($list) {

	    delete $previous_family_lists->{$list->{'name'}};

	    ## check family name
	    if (defined $list->{'admin'}{'family_name'}) {
		unless ($list->{'admin'}{'family_name'} eq $self->{'name'}) {
		    push (@{$self->{'errors'}{'listname_already_used'}},$list->{'name'});
		    &do_log('err','The list %s already belongs to family %s',$list->{'name'},$list->{'admin'}{'family_name'});
		    next;
		} 
	    } else {
		push (@{$self->{'errors'}{'listname_already_used'}},$list->{'name'});
		&do_log('err','The orphelan list %s already exists',$list->{'name'});
		next;
	    }

	    my $result = $self->_update_existing_list($list,$hash_list);
	    unless (defined $result) {
		push (@{$self->{'errors'}{'update_list'}},$list->{'name'});
		$list->set_status_error_config('instantiation_family',$list->{'name'},$self->{'name'});
		next;
	    }
	    $list = $result;
	    
	## FIRST LIST CREATION    
	} else{

	    my $result = &admin::create_list($hash_list->{'config'},$self,$self->{'robot'});
	    unless (defined $result) {
		push (@{$self->{'errors'}{'create_list'}},$hash_list->{'config'}{'listname'});
		next;
	    }
	    unless (defined $result->{'list'}) {
		push (@{$self->{'errors'}{'create_list'}},$hash_list->{'config'}{'listname'});
		next;
	    }
	    $list = $result->{'list'};
	    
	    ## aliases
	    if ($result->{'aliases'} == 1) {
		push (@{$self->{'created_lists'}{'with_aliases'}},$list->{'name'});
		
	    }else {
		$self->{'created_lists'}{'without_aliases'}{$list->{'name'}} = $result->{'aliases'};
	    }
	    
	    # config_changes
	    unless (open FILE, ">$list->{'dir'}/config_changes") {
		&do_log('err','Family::instantiate : impossible to create file %s/config_changes : %s',$list->{'dir'},$!);
		push (@{$self->{'generated_lists'}{'file_error'}},$list->{'name'});
		$list->set_status_error_config('error_copy_file',$list->{'name'},$self->{'name'});
	    }
	    close FILE;
	}
	
	## ENDING : existing and new lists
	unless ($self->_end_update_list($list,1)) {
	    &do_log('err','Instantiation stopped on list %s',$list->{'name'});
	    return undef;
	}

    }

    ## PREVIOUS LIST LEFT
    foreach my $l (keys %{$previous_family_lists}) {
	my $list;
	unless ($list = new List ($l,$self->{'robot'})) {
	    push (@{$self->{'errors'}{'previous_list'}},$l);
	    next;
	}
	
	my $answer;
#	while (($answer ne 'y') && ($answer ne 'n')) {
	    print STDOUT "The list $l isn't defined in the new instantiation family, do you want to close it ? (y or n)";
	    $answer = <STDIN>;
	    chomp($answer);
#######################
	    $answer ||= 'y';
	#}
	if ($answer eq 'y'){

	    unless ($list->set_status_family_closed('close_list',$self->{'name'})) {
		push (@{$self->{'family_closed'}{'impossible'}},$list->{'name'});
	    }
	    push (@{$self->{'family_closed'}{'ok'}},$list->{'name'});
	
	} else {
	    ## get data from list xml file
	    my $xml_fh;
	    open $xml_fh,"$list->{'dir'}/instance.xml";
	    my $config = new Config_XML($xml_fh);
	    close $xml_fh;
	    unless (defined $config->createHash()) {
		push (@{$self->{'errors'}{'create_hash'}},"$list->{'dir'}/instance.xml");
		$list->set_status_error_config('instantiation_family',$list->{'name'},$self->{'name'});
		next;
	    } 
	    my $hash_list = $config->getHash();
	    
	    my $result = $self->_update_existing_list($list,$hash_list);
	    unless (defined $result) {
		push (@{$self->{'errors'}{'update_list'}},$list->{'name'});
		$list->set_status_error_config('instantiation_family',$list->{'name'},$self->{'name'});
		next;
	    }
	    $list = $result;

	    unless ($self->_end_update_list($list,0)) {
		&do_log('err','Instantiation stopped on list %s',$list->{'name'});
		return undef;
	    }
	}
    }
    $self->{'state'} = 'normal';
    return 1;
}

#########################################
# get_instantiation_results
#########################################
# return a string of instantiation results
#  
# IN : -$self
#
# OUT : -$string
#########################################
sub get_instantiation_results {
    my $self = shift;
    &do_log('debug4','Family::get_instantiation_results(%s)',$self->{'name'});
    my $string = "\n\n******************************************************************************\n"; 
    $string .= "\n******************** INSTANTIATION of $self->{'name'} FAMILY ********************\n";
    $string .= "\n******************************************************************************\n\n"; 

    unless ($#{$self->{'errors'}{'create_hash'}} <0) {
	$string .= "\nImpossible list generation because errors in xml file for : \n  ".join(", ",@{$self->{'errors'}{'create_hash'}})."\n";    }
        
    unless ($#{$self->{'errors'}{'create_list'}} <0) {
	$string .= "\nImpossible list creation for : \n  ".join(", ",@{$self->{'errors'}{'create_list'}})."\n";
    }
    
    unless ($#{$self->{'errors'}{'listname_already_used'}} <0) {
	$string .= "\nImpossible list creation because listname is already used (orphelan list or in another family) for : \n  ".join(", ",@{$self->{'errors'}{'listname_already_used'}})."\n";
    }
    
    unless ($#{$self->{'errors'}{'update_list'}} <0) {
	$string .= "\nImpossible list updating for : \n  ".join(", ",@{$self->{'errors'}{'update_list'}})."\n";
    }
    
    unless ($#{$self->{'errors'}{'previous_list'}} <0) {
	$string .= "\nExisted lists from the lastest instantiation impossible to get and not anymore defined in the new instantiation : \n  ".join(", ",@{$self->{'errors'}{'previous_list'}})."\n";
    }
    
    $string .= "\n****************************************\n";    
    
    unless ($#{$self->{'created_lists'}{'with_aliases'}} <0) {
	$string .= "\nThese lists have been created and aliases are ok :\n  ".join(", ",@{$self->{'created_lists'}{'with_aliases'}})."\n";
    }
    
    my $without_aliases =  $self->{'created_lists'}{'without_aliases'};
    if (ref $without_aliases) {
	if (scalar %{$without_aliases}) {
	    $string .= "\nThese lists have been created but aliases need to be installed : \n";
	    foreach my $l (keys %{$without_aliases}) {
		$string .= " $without_aliases->{$l}";
	    }
	}
    }
    
    unless ($#{$self->{'updated_lists'}{'aliases_ok'}} <0) {
	$string .= "\nThese lists have been updated and aliases are ok :\n  ".join(", ",@{$self->{'updated_lists'}{'aliases_ok'}})."\n";
    }
    
    my $aliases_to_install =  $self->{'updated_lists'}{'aliases_to_install'};
    if (ref $aliases_to_install) {
	if (scalar %{$aliases_to_install}) {
	    $string .= "\nThese lists have been updated but aliases need to be installed : \n";
	    foreach my $l (keys %{$aliases_to_install}) {
		$string .= " $aliases_to_install->{$l}";
	    }
	}
    }
    
    my $aliases_to_remove =  $self->{'updated_lists'}{'aliases_to_remove'};
    if (ref $aliases_to_remove) {
	if (scalar %{$aliases_to_remove}) {
	    $string .= "\nThese lists have been updated but aliases need to be removed : \n";
	    foreach my $l (keys %{$aliases_to_remove}) {
		$string .= " $aliases_to_remove->{$l}";
	    }
	}
    }
	    
    $string .= "\n****************************************\n";    
    
    unless ($#{$self->{'generated_lists'}{'file_error'}} <0) {
	$string.= "\nThese lists have been generated but they are in status error_config because of errors while creating list config files :\n  ".join(", ",@{$self->{'generated_lists'}{'file_error'}})."\n";
    }

    my $constraint_error = $self->{'generated_lists'}{'constraint_error'};
    if (ref $constraint_error) {
	if (scalar %{$constraint_error}) {
	    $string .="\nThese lists have been generated but there are in status error_config because of errors on parameter constraint :\n";
	    foreach my $l (keys %{$constraint_error}) {
		$string .= " $l : ".$constraint_error->{$l}."\n";
	    }
	}
    }

    $string .= "\n****************************************\n";    	
    
    unless ($#{$self->{'family_closed'}{'ok'}} <0) {
	$string.= "\nThese lists don't belong anymore to the family, they are in status family_closed :\n  ".join(", ",@{$self->{'family_closed'}{'ok'}})."\n";
    }

    unless ($#{$self->{'family_closed'}{'impossible'}} <0){
	$string.= "\nThese lists don't belong anymore to the family, but they can't be set in status family_closed :\n  ".join(", ",@{$self->{'family_closed'}{'impossible'}})."\n";
    }

    return $string
}



#########################################
# check_param_constraint                                   
#########################################
# check the parameter constraint from 
# param_constraint.conf file, of the given 
# list (constraint on param digest is only on days)
# (take care of $self->{'state'}) 
#  
# IN  : -$self
#       -$list : ref on the list  
# OUT : -1 (if ok) or 
#        \@error (ref on array of parameters 
#          in conflict with constraints) or 
#        undef 
#########################################
sub check_param_constraint {
    my $self = shift;
    my $list = shift;
    my $config = $list->{'admin'};
    &do_log('debug2','Family::check_param_constraint(%s,%s)',$self->{'name'},$list->{'name'});

    if ($self->{'state'} eq 'no_check') {
	return 1;
	# because called by load(called by new that is called by instantiate) 
	# it is not yet the time to check param constraint, 
	# it will be called later by instantiate
    }

    my @error;

    ## checking
    my $constraint = $self->get_constraints();
    unless (defined $constraint) {
	&do_log('err','Family::check_param_constraint(%s,%s) : unable to get family constraints',$self->{'name'},$list->{'name'});
	return undef;
    }
    foreach my $param (keys %{$constraint}) {
	my $constraint_value = $constraint->{$param};
	my $param_value;
	my $value_error;

	unless (defined $constraint_value) {
	    &do_log('err','No value constraint on parameter %s in param_constraint.conf',$param);
	    next;
	}

	$param_value = $list->get_param_value($param);
	$value_error = $self->check_values($param_value,$constraint_value);
	
	if (ref($value_error)) {
	    foreach my $v (@{$value_error}) {
		push (@error,$param);
		&do_log('err','Error constraint on parameter %s, value : %s',$param,$v);
	    }
	}
    }
    
    if (scalar @error) {
	return \@error;
    }else {
	return 1;
    }
}

#########################################
# get_constraints
#########################################
# return the hash constraint from 
# param_constraint.conf file
#  
# IN  : -$self
# OUT : -$self->{'param_constraint_conf'}
#########################################
sub get_constraints {
    my $self = shift;
    &do_log('debug3','Family::get_constraints(%s)',$self->{'name'});

    ## load param_constraint.conf
    my $time_file = (stat("$self->{'dir'}/param_constraint.conf"))[9];
    unless ((defined $self->{'param_constraint_conf'}) && ($self->{'mtime'}{'param_constraint_conf'} >= $time_file)) {
	$self->{'param_constraint_conf'} = $self->_load_param_constraint_conf();
	unless (defined $self->{'param_constraint_conf'}) {
	    &do_log('err','Cannot load file param_constraint.conf ');
	    return undef;
	}
	$self->{'mtime'}{'param_constraint_conf'} = $time_file;
    }
        
    return $self->{'param_constraint_conf'};
}

#########################################
# check_values                                  
#########################################
# check the parameter value(s) with 
# param_constraint value(s).
#  
# IN  : -$self
#       -$param_value 
#       -constraint_value
# OUT : -\@error (ref on array of forbidden values) 
#        or '0' for free parameters
#########################################
sub check_values {
    my ($self,$param_value,$constraint_value) = @_;
    &do_log('debug3','Family::check_values()');
    
    my @param_values;
    my @error;
    
    # just in case
    if ($constraint_value eq '0') {
	return [];
    }
    
    if (ref($param_value) eq 'ARRAY') {
	@param_values = @{$param_value}; # for multiple parameters
    }
    else {
	push @param_values,$param_value; # for single parameters
    }
    
 
    foreach my $p_val (@param_values) { 
	
	my $found = 0;

	## multiple values
	if(ref($p_val) eq 'ARRAY') { 
	    
	    foreach my $p (@{$p_val}) {
		## controlled parameter
		if (ref($constraint_value) eq 'HASH') {
		    unless ($constraint_value->{$p}) {
			push (@error,$p);
		    }
		## fixed parameter    
		} else {
		    unless ($constraint_value eq $p) {
			push (@error,$p);
		    }
		}
	    }
	## single value
	} else {  
	    ## controlled parameter    
	    if (ref($constraint_value) eq 'HASH') {
		unless ($constraint_value->{$p_val}) {
		    push (@error,$p_val);
		}
	    ## fixed parameter    
	    } else {
		unless ($constraint_value eq $p_val) {
		    push (@error,$p_val);
		}
	    }
	}
    }

 
    return \@error;
}


#########################################
# get_param_constraint                                   
#########################################
# get the parameter constraint from 
# param_constraint.conf file
#  (constraint on param digest is only on days)
#  
# IN  : -$self
#       -$param : parameter requested  
# OUT : -'0' if the parameter is free or 
#        the parameter value if the 
#          parameter is fixed or
#        a ref on a hash of possible parameter 
#          values or 
#        undef 
#########################################
sub get_param_constraint {
    my $self = shift;
    my $param  = shift;
    &do_log('debug3','Family::get_param_constraint(%s,%s)',$self->{'name'},$param);
 
    unless(defined $self->get_constraints()) {
	return undef;
    }
 
    if (defined $self->{'param_constraint_conf'}{$param}) { ## fixed or controlled parameter
	return $self->{'param_constraint_conf'}{$param};
  
    } else { ## free parameter
	return '0';
    }
}
	
#########################################
# get_family_lists                                 
#########################################
# return the family's lists into an array
#  
# IN  : -$self
# OUT : -\@list_of_list 
#########################################    
sub get_family_lists {
    my $self = shift;
    my @list_of_lists;
    &do_log('debug2','Family::get_family_lists(%s)',$self->{'name'});

    foreach my $l ( &List::get_lists($self->{'robot'}) ) {
	my $list = new List ($l,$self->{'robot'}); 
	if ((defined $list->{'admin'}{'family_name'}) && ($list->{'admin'}{'family_name'} eq $self->{'name'})) {
	    push (@list_of_lists,$l);
	}
    }
    return \@list_of_lists;
}

#########################################
# get_hash_family_lists                                 
#########################################
# return the family's lists into a hash
#  
# IN  : -$self
# OUT : -\%list_of_list 
#########################################    
sub get_hash_family_lists {
    my $self = shift;
    my %list_of_lists;
    &do_log('debug2','Family::get_hash_family_lists(%s)',$self->{'name'});

    foreach my $l ( &List::get_lists($self->{'robot'}) ) {
	my $list = new List ($l,$self->{'robot'}); 
	if ((defined $list->{'admin'}{'family_name'}) && ($list->{'admin'}{'family_name'} eq $self->{'name'})) {
	    $list_of_lists{$l} = 1;
	}
    }
    return \%list_of_lists;
}

############################# PRIVATE METHODS ##############################

#####################################################
# _get_directory                                   
#####################################################
# get the family directory, look for it in the robot,
# then in the site and finally in the distrib
# IN :  -$self
# OUT : -directory name or 
#        undef if the directory does not exist  
#####################################################
sub _get_directory {
    my $self = shift;
    my $robot = $self->{'robot'};
    my $name = $self->{'name'};
    &do_log('debug3','Family::_get_directory(%s)',$name);

    my @try = ("$Conf{'etc'}/$robot".'/families',
	       $Conf{'etc'}.'/families',
	       '--ETCBINDIR--'.'/families');

    foreach my $d (@try) {
	if (-d "$d/$name") {
	    return "$d/$name";
	}
    }
    return undef;
}


#####################################################
# _check_obligatory_files                                   
#####################################################
# check existence of obligatory files in the family
# directory:
#  - param_constraint.conf
#  - config.tpl
#
# IN  : -$self
# OUT : -0 (if OK) or 
#        $string containing missing file names
#####################################################
sub _check_obligatory_files {
    my $self = shift;
    my $dir = $self->{'dir'};
    my $string = "";
    &do_log('debug3','Family::_check_obligatory_files(%s)',$self->{'name'});

    foreach my $f ('param_constraint.conf','config.tt2') {
	unless (-f "$dir/$f") {
	    $string .= $f." ";
	}
    }

    if ($string eq "") {
	return 0;
    } else {
	return $string;
    }
}



#####################################################
# _initialize_instantiation                                   
#####################################################
# initialize vars for instantiation and result
# then to make a string result
#
# IN  : -$self
# OUT : -1 
#####################################################
sub _initialize_instantiation() {
    my $self = shift;
    &do_log('debug4','Family::_initialize_instantiation(%s)',$self->{'name'});

    ### info vars for instantiate  ###
    ### returned by                ###
    ### get_instantiation_results  ### 
    
    ## array of list to generate
    $self->{'list_to_generate'}=(); 
    
    ## lists in error during creation or updating : LIST FATAL ERROR
    # array of xml file name  : error during xml data extraction
    $self->{'errors'}{'create_hash'} = ();
    ## array of list name : error during list creation
    $self->{'errors'}{'create_list'} = ();
    ## array of list name : error during list updating
    $self->{'errors'}{'update_list'} = ();
    ## array of list name : listname already used (in another family)
    $self->{'errors'}{'listname_already_used'} = ();
    ## array of list name : previous list impossible to get
    $self->{'errors'}{'previous_list'} = ();
    
    ## created or updated lists
    ## array of list name : aliases are OK (installed or not, according to status)
    $self->{'created_lists'}{'with_aliases'} = ();
    ## hash of (list name -> aliases) : aliases needed to be installed
    $self->{'created_lists'}{'without_aliases'} = {};
    ## array of list name : aliases are OK (installed or not, according to status)
    $self->{'updated_lists'}{'aliases_ok'} = ();
    ## hash of (list name -> aliases) : aliases needed to be installed
    $self->{'updated_lists'}{'aliases_to_install'} = {};
    ## hash of (list name -> aliases) : aliases needed to be removed
    $self->{'updated_lists'}{'aliases_to_remove'} = {};
    
    ## generated (created or updated) lists in error : no fatal error for the list
    ## array of list name : error during copying files
    $self->{'generated_lists'}{'file_error'} = ();
    ## hash of (list name -> array of param) : family constraint error
    $self->{'generated_lists'}{'constraint_error'} = {};
    
    ## lists isn't anymore in the family
    ## array of list name : lists in status family_closed
    $self->{'family_closed'}{'ok'} = ();
    ## array of list name : lists that must be in status family_closed but they aren't
    $self->{'family_closed'}{'impossible'} = ();
    
    return 1;
}


#####################################################
# _split_xml_file                                   
#####################################################
# split the xml family file into xml list files. New
# list names are put in the array reference
# $self->{'list_to_generate'} and new files are put in
# the family directory
#
# IN : -$self
#      -$xml_fh : file handle on xml file containing description
#               of the family lists 
# OUT : -1 (if OK) or undef 
#####################################################
sub _split_xml_file {
    my $self = shift;
    my $xml_fh = shift;
    my $root;
    &do_log('debug2','Family::_split_xml_file(%s)',$self->{'name'});

    ## parse file
    my $parser = XML::LibXML->new();
    $parser->line_numbers(1);
    my $doc;

    unless ($doc = $parser->parse_fh($xml_fh)) {
	&do_log('err',"Family::_split_xml_file() : failed to parse XML file");
	return undef;
    }
    
    ## the family document
    $root = $doc->documentElement();
    unless ($root->nodeName eq 'family') {
	&do_log('err',"Family::_split_xml_file() : the root element must be called \"family\" ");
	return undef;
    }

    ## lists : family's elements
    foreach my $list_elt ($root->childNodes()) {

	if ($list_elt->nodeType == 1) {# ELEMENT_NODE
	    unless ($list_elt->nodeName eq 'list') {
		&do_log('err','Family::_split_xml_file() : elements contained in the root element must be called "list", line %s',$list_elt->line_number());
		return undef;
	    }
	}else {
	    next;
	}
	
	## listname 
	my @children = $list_elt->getChildrenByTagName('listname');

	if ($#children <0) {
	    &do_log('err','Family::_split_xml_file() : "listname" element is required in "list" element, line : %s',$list_elt->line_number());
	    return undef;
	}
	if ($#children > 0) {
	    my @error;
	    foreach my $i (@children) {
		push (@error,$i->line_number());    
	    }
	    &do_log('err','Family::_split_xml_file() : Only one "listname" element is allowed for "list" element, lines : %s',join(", ",@error));
	    return undef;
	    my $minor_param = $2;
	}
	my $listname_elt = shift @children;
	my $listname = $listname_elt->textContent();
	$listname =~ s/^\s*//;
	$listname =~ s/\s*$//;
	$listname = lc $listname;
	my $filename = $listname.".xml";
	
        ## creating list XML document 
	my $list_doc = XML::LibXML::Document->createDocument($doc->version(),$doc->encoding());
	$list_doc->setDocumentElement($list_elt);

	## creating the list xml file
	unless ($list_doc->toFile("$self->{'dir'}/$filename",0)) {
	    &do_log('err','Family::_split_xml_file() : cannot create list file %s',
		    $self->{'dir'}.'/'.$filename,$list_elt->line_number());
	    return undef;
	}

	push (@{$self->{'list_to_generate'}},$listname);
    }
    return 1;
}

#####################################################
# _update_existing_list
#####################################################
# update an already existing list in the new family context
#
# IN : -$self
#      -$list : the list to update
#      -hash_list : data to create the list config
#
# OUT : -$list : the new list (or undef)
#####################################################
sub _update_existing_list {
    my ($self,$list,$hash_list) = @_;
    &do_log('debug3','Family::_update_existing_list(%s,%s)',$self->{'name'},$list->{'name'});

    ## get allowed and forbidden list customizing
    my $custom = $self->_get_customizing($list);
    unless (defined $custom) {
	&do_log('err','impossible to get list %s customizing',$list->{'name'});
	return undef;
    }
    my $config_changes = $custom->{'config_changes'}; 
    my $old_status = $list->{'admin'}{'status'};
	    


    ## list config family updating
    my $result = &admin::update_list($list,$hash_list->{'config'},$self,$self->{'robot'});
    unless (defined $result) {
	&do_log('err','No object list resulting from updating list %s',$list->{'name'});
	return undef;
    }
    $list = $result;

    
    ## set list customizing
    foreach my $p (keys %{$custom->{'allowed'}}) {
	$list->{'admin'}{$p} = $custom->{'allowed'}{$p};
	delete $list->{'admin'}{'defaults'}{$p};
	&do_log('info','Customizing : keeping values for parameter %s',$p);
    }

    ## info file
    unless ($config_changes->{'file'}{'info'}) {
	$hash_list->{'config'}{'description'} =~ s/\015//g;
	
	unless (open INFO, ">$list->{'dir'}/info") {
	    &do_log('err','Impossible to open %s/info : %s',$list->{'dir'},$!);
	}
	print INFO $hash_list->{'config'}{'description'};
	close INFO; 
    }
    
    foreach my $f (keys %{$config_changes->{'file'}}) {
	&do_log('info','Customizing : this file has been changed : %s',$f);
    }
    
    ## rename forbidden files
#    foreach my $f (@{$custom->{'forbidden'}{'file'}}) {
#	unless (rename ("$list->{'dir'}"."/"."info","$list->{'dir'}"."/"."info.orig")) {
	    ################
#	}
#	if ($f eq 'info') {
#	    $hash_list->{'config'}{'description'} =~ s/\015//g;
#	    unless (open INFO, ">$list_dir/info") {
		################
#	    }
#	    print INFO $hash_list->{'config'}{'description'};
#	    close INFO; 
#	}
#    }


    ## notify owner for forbidden customizing
    if (#(scalar $custom->{'forbidden'}{'file'}) ||
	(scalar @{$custom->{'forbidden'}{'param'}})) {
#	my $forbidden_files = join(',',@{$custom->{'forbidden'}{'file'}});
	my $forbidden_param = join(',',@{$custom->{'forbidden'}{'param'}});
	&do_log('notice',"These parameters aren't allowed in the new family definition, they are erased by a new instantiation family : \n $forbidden_param");

	unless ($list->new_send_notify_to_owner('erase_customizing',($self->{'name'},$forbidden_param))) {
	    &do_log('notice','the owner isn\'t informed from erased customizing of the list %s',$list->{'name'});
	}
    }

    ## status
    my $result = $self->_set_status_changes($list,$old_status);

    if ($result->{'aliases'} == 1) {
	push (@{$self->{'updated_lists'}{'aliases_ok'}},$list->{'name'});
    
    }elsif ($result->{'install_remove'} eq 'install') {
	$self->{'updated_lists'}{'aliases_to_install'}{$list->{'name'}} = $result->{'aliases'};
	
    }else {
	$self->{'updated_lists'}{'aliases_to_remove'}{$list->{'name'}} = $result->{'aliases'};
	
    }

    ## config_changes
    foreach my $p (@{$custom->{'forbidden'}{'param'}}) {

	if (defined $config_changes->{'param'}{$p}  ) {
	    delete $config_changes->{'param'}{$p};
	}

    }

    unless (open FILE, ">$list->{'dir'}/config_changes") {
	&do_log('err','impossible to open file %s/config_changes : %s',$list->{'dir'},$!);
	push (@{$self->{'generated_lists'}{'file_error'}},$list->{'name'});
	$list->set_status_error_config('error_copy_file',$list->{'name'},$self->{'name'});
    }
    close FILE;

    my @kept_param = keys %{$config_changes->{'param'}};
    $list->update_config_changes('param',\@kept_param);
    my @kept_files = keys %{$config_changes->{'file'}};
    $list->update_config_changes('file',\@kept_files);
    
    
    return $list;
}

#####################################################
# _get_customizing                                   
#####################################################
# gets list customizing from config_changes file and
# keep on changes that are allowed by param_constraint.conf 
#
# IN : -$self
#      -$list
# OUT :- $result->{'config_changes'} : the list config_changes
#      - $result->{'allowed'}
#           hash of allowed param : ($param,$values)
#      - $result->{'forbidden'}{'param'} = \@ 
#                              {'file'} = \@ (no working)
#####################################################
sub _get_customizing {
    my ($self,$list) = @_;
    &do_log('debug3','Family::_get_customizing(%s,%s)',$self->{'name'},$list->{'name'});

    my $result;
    my $config_changes = $list->get_config_changes;
    
    unless (defined $config_changes) {
	&do_log('err','impossible to get config_changes');
	return undef;
    }

    ## FILES
#    foreach my $f (keys %{$config_changes->{'file'}}) {

#	my $privilege; # =may_edit($f)
	    
#	unless ($privilege eq 'write') {
#	    push @{$result->{'forbidden'}{'file'}},$f;
#	}
#    }

    ## PARAMETERS

    # get customizing values
    my $changed_values;
    foreach my $p (keys %{$config_changes->{'param'}}) {

	$changed_values->{$p} = $list->{'admin'}{$p}
    }

    # check these values
    my $constraint = $self->get_constraints();
    unless (defined $constraint) {
	&do_log('err','unable to get family constraints',$self->{'name'},$list->{'name'});
	return undef;
    }

    foreach my $param (keys %{$constraint}) {
	my $constraint_value = $constraint->{$param};
	my $param_value;
	my $value_error;

	unless (defined $constraint_value) {
	    &do_log('err','No value constraint on parameter %s in param_constraint.conf',$param);
	    next;
	}

	$param_value = &List::_get_param_value_anywhere($changed_values,$param);
 
	$value_error = $self->check_values($param_value,$constraint_value);

	foreach my $v (@{$value_error}) {
	    push @{$result->{'forbidden'}{'param'}},$param;
	    &do_log('err','Error constraint on parameter %s, value : %s',$param,$v);
	}
	
    }
    
    # keep allowed values
    foreach my $param (@{$result->{'forbidden'}{'param'}}) {
	my $minor_p;
	if ($param =~ /^([\w-]+)\.([\w-]+)$/) {
	    $param = $1;
	}

	if (defined $changed_values->{$param}) {
	    delete $changed_values->{$param};
	}
    }
    $result->{'allowed'} = $changed_values;

    $result->{'config_changes'} = $config_changes;
    return $result;
}

#####################################################
# _set_status_changes
#####################################################
# set changes (load the users, install or removes the
# aliases) dealing with the new and old_status (for 
# already existing lists)
# IN : -$self
#      -$list : the new list
#      -$robot
#      -$old_status : the list status before instantiation
#                     family
#
# OUT :-$result->{'install_remove'} ='install' or 'remove'
#      -$result->{'aliases'} = 1 (if install or remove is done) or
#        a string of aliases needed to be installed or removed 
#####################################################
sub _set_status_changes {
    my ($self,$list,$old_status) = @_;
    &do_log('debug3','Family::_set_status_changes(%s,%s,%s)',$self->{'name'},$list);

    my $result;

    $result->{'aliases'} = 1;

    unless (defined $list->{'admin'}{'status'}) {
	$list->{'admin'}{'status'} = 'open';
    }

    ## aliases
    if ($list->{'admin'}{'status'} eq 'open') {
	unless ($old_status eq 'open') {
	    $result->{'install_remove'} = 'install'; 
	    $result->{'aliases'} = &admin::install_aliases($list,$self->{'robot'});
	}
    }

    if (($list->{'admin'}{'status'} eq 'pending') && 
	(($old_status eq 'open') || ($old_status eq 'error_config'))) {
	$result->{'install_remove'} = 'remove'; 
	$result->{'aliases'} = &admin::remove_aliases($list,$self->{'robot'});
    }
    
    ## subscribers
    if (($old_status ne 'pending') && ($old_status ne 'open')) {
	
	if ($list->{'admin'}{'user_data_source'} eq 'file') {
	    $list->{'users'} = &List::_load_users_file("$list->{'dir'}/subscribers.closed.dump");
	    $list->save();
	}elsif ($list->{'admin'}{'user_data_source'} eq 'database') {
	    unless (-f "$list->{'dir'}/subscribers.closed.dump") {
		&do_log('notice', 'No subscribers to restore');
	    }
	    my @users = &List::_load_users_file("$list->{'dir'}/subscribers.closed.dump");
	    
	    ## Insert users in database
	    foreach my $user (@users) {
		$list->add_user($user);
	    }
	}
    }
	
    return $result;
}



#####################################################
# _end_update_list
#####################################################
# finish to generate a list in a family context 
# (for a new or an already existing list)
# if there are error, list are set in status error_config
#
# IN : -$self
#      -$list 
#      -$xml_file : 0 (no copy xml file)or 1 (copy xml file)
#
# OUT : -1 or undef
#####################################################
sub _end_update_list {
    my ($self,$list,$xml_file) = @_;
    &do_log('debug3','Family::_end_update_list(%s,%s)',$self->{'name'},$list->{'name'});
    
    my $host = &Conf::get_robot_conf($self->{'robot'}, 'host');
    $list->{'admin'}{'latest_instantiation'}{'email'} = "listmaster\@$host";
    $list->{'admin'}{'latest_instantiation'}{'date'} = &POSIX::strftime("%d %b %Y at %H:%M:%S", localtime(time));
    $list->{'admin'}{'latest_instantiation'}{'date_epoch'} = time;
    $list->save_config("listmaster\@$host");
    $list->{'family'} = $self;
    
    ## check param_constraint.conf 
    $self->{'state'} = 'normal';
    my $error = $self->check_param_constraint($list);
    $self->{'state'} = 'no_check';

    unless (defined $error) {
	&do_log('err', 'Impossible to check parameters constraint, it happens on list %s. It is set in status error_config',$list->{'name'});
	$list->set_status_error_config('no_check_rules_family',$list->{'name'},$self->{'name'});
	return undef;
    }
    if (ref($error) eq 'ARRAY') {
	$self->{'generated_lists'}{'constraint_error'}{$list->{'name'}} = join(", ",@{$error});
	$list->set_status_error_config('no_respect_rules_family',$list->{'name'},$self->{'name'});
    }
    
    ## copy files in the list directory
    if ($xml_file) { # copying the xml file
	unless ($self->_copy_files($list->{'dir'},"$list->{'name'}.xml")) {
	    push (@{$self->{'generated_lists'}{'file_error'}},$list->{'name'});
	    $list->set_status_error_config('error_copy_file',$list->{'name'},$self->{'name'});
	}
    }

    return 1;
}

#####################################################
# _copy_files                                   
#####################################################
# copy files in the list directory :
#   - instance.xml (xml data defining list)
#
# IN : -$self
#      -$list_dir list directory
#      -$file : xml file : optionnal
# OUT : -1 or undef 
#####################################################
sub _copy_files {
    my $self = shift;
    my $list_dir = shift;
    my $file = shift;
    my $dir = $self->{'dir'};
    &do_log('debug3','Family::_copy_files(%s,%s)',$self->{'name'},$list_dir);

    # instance.xml
    if (defined $file) {
	unless (rename "$dir/$file", "$list_dir/instance.xml") {
	    &do_log('err','Family::_copy_files(%s) : impossible to move %s/%s into %s/instance.xml : %s',$self->{'name'},$dir,$file,$list_dir,$!);
	    return undef;
	}
    }



    return 1;
}

#########################################
# _load_param_constraint_conf()                                   
#########################################
# load the param_constraint.conf file in 
# a hash
#  
# IN :  -$self
# OUT : -$constraint : ref on a hash or undef
#########################################
sub _load_param_constraint_conf {
    my $self = shift;
    &do_log('debug2','Family::_load_param_constraint_conf(%s)',$self->{'name'});

    my $file = "$self->{'dir'}/param_constraint.conf";
    
    unless (open (FILE, $file)) {
	&do_log('err','Unable to open file %s : %s', $file,$_);
	return undef;
    }

    my $constraint = {};
    my $error = 0;

    ## Just in case...
    $/ = "\n";

    while (<FILE>) {
	next if /^\s*(\#.*|\s*)$/;

	if (/^\s*([\w-\.]+)\s+(.+)\s*$/) {
	    my $param = $1;
	    my $value = $2;
	    my @values = split /,/, $value;
	    
	    unless(($param =~ /^([\w-]+)\.([\w-]+)$/) || ($param =~ /^([\w-]+)$/)) {
		&do_log ('err', 'Family::_load_param_constraint_conf(%s) : unknown parameter "%s" in %s',$self->{'name'},$_,$file);
		$error = 1;
		next;
	    }
	    
	    if (scalar(@values) == 1) {
		$constraint->{$param} = shift @values;
	    } else {
		foreach my $v (@values) {
		    $constraint->{$param}{$v} = 1;
		}
	    }
	} else {
	    &do_log ('err', 'Family::_load_param_constraint_conf(%s) : bad line : %s in %s',$self->{'name'},$_,$file);
	    $error = 1;
	    next;
	}
    }
    if ($error) {
	&List::send_notify_to_listmaster('param_constraint_conf_error', $self->{'robot'}, $file);
    }
    close FILE;
###########################"
 #   open TMP, ">/tmp/dump1";
 #   &tools::dump_var ($constraint, 0, \*TMP);
 #    close TMP;

    return $constraint;
}



###################################
return 1;
