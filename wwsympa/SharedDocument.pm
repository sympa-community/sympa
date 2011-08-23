# SharedDocument.pm - module to manipulate shared web documents
# <!-- RCS Identication ; $Revision$ ; $Date$ -->

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

package SharedDocument;

use strict;

use Carp;
use POSIX;

use tools;
use List;
use Log;

## Creates a new object
sub new {
    my($pkg, $list, $path, $param) = @_;

    my $email = $param->{'user'}{'email'};
    #$email ||= 'nobody';
    my $document = {};
    &Log::do_log('debug2', 'SharedDocument::new(%s, %s)', $list->{'name'}, $path);
    
    unless (ref($list) =~ /List/i) {
	&Log::do_log('err', 'SharedDocument::new : incorrect list parameter');
	return undef;
    }

    $document->{'root_path'} = $list->{'dir'}.'/shared';

    $document->{'path'} = &main::no_slash_end($path);
    $document->{'escaped_path'} = &tools::escape_chars($document->{'path'}, '/');

    ### Document isn't a description file
    if ($document->{'path'} =~ /\.desc/) {
	&Log::do_log('err',"SharedDocument::new : %s : description file", $document->{'path'});
	return undef;
    }

    ## absolute path
    # my $doc;
    $document->{'absolute_path'} = $document->{'root_path'};
    if ($document->{'path'}) {
	$document->{'absolute_path'} .= '/'.$document->{'path'};
    }

    ## Check access control
    &check_access_control($document, $param);

    ###############################
    ## The path has been checked ##
    ###############################

    ### Document exist ? 
    unless (-r $document->{'absolute_path'}) {
	&Log::do_log('err',"SharedDocument::new : unable to read %s : no such file or directory", $document->{'absolute_path'});
	return undef;
    }
    
    ### Document has non-size zero?
    unless (-s $document->{'absolute_path'}) {
	&Log::do_log('err',"SharedDocument::new : unable to read %s : empty document", $document->{'absolute_path'});
	return undef;
    }
    
    $document->{'visible_path'} = &main::make_visible_path($document->{'path'});
    
    ## Date
    my @info = stat $document->{'absolute_path'};
    $document->{'date'} =  &POSIX::strftime("%d %b %Y", localtime($info[9]));
    $document->{'date_epoch'} =  $info[9];
    
    # Size of the doc
    $document->{'size'} = (-s $document->{'absolute_path'}) / 1000;

    ## Filename
    my @tokens = split /\//, $document->{'path'};
    $document->{'filename'} = $document->{'visible_filename'} = $tokens[$#tokens];

    ## Moderated document
    if ($document->{'filename'} =~ /^\.(.*)(\.moderate)$/) {
	$document->{'moderate'} = 1;
	$document->{'visible_filename'} = $1;
    }

    $document->{'escaped_filename'} =  &tools::escape_chars($document->{'filename'});

    ## Father dir
    if ($document->{'path'} =~ /^(([^\/]*\/)*)([^\/]+)$/) {
	$document->{'father_path'} = $1;
    }else {
	$document->{'father_path'} = '';
    }
    $document->{'escaped_father_path'} = &tools::escape_chars($document->{'father_path'}, '/');
    

    ### File, directory or URL ?
    if (! (-d $document->{'absolute_path'})) {

	if ($document->{'filename'} =~ /^\..*\.(\w+)\.moderate$/) {
	    $document->{'file_extension'} = $1;
	}elsif ($document->{'filename'} =~ /^.*\.(\w+)$/) {
	    $document->{'file_extension'} = $1;
	 }
	
	if ($document->{'file_extension'} eq 'url') {
	    $document->{'type'} = 'url';
	}else {
	    $document->{'type'} = 'file';
	}
    }else {
	$document->{'type'} = 'directory';
    }

    ## Load .desc file unless root directory
    my $desc_file;
    if ($document->{'type'} eq 'directory') {
	$desc_file = $document->{'absolute_path'}.'/.desc';
    }else {
	if ($document->{'absolute_path'} =~ /^(([^\/]*\/)*)([^\/]+)$/) {
	    $desc_file = $1.'.desc.'.$3;
	}else {
	    &Log::do_log('err',"SharedDocument::new() : cannot determine desc file for %s", $document->{'absolute_path'});
	    return undef;
	}
    }

    if ($document->{'path'} && (-e $desc_file)) {
	my @info = stat $desc_file;
	$document->{'serial_desc'} = $info[9];
	
	my %desc_hash = &main::get_desc_file($desc_file);
	$document->{'owner'} = $desc_hash{'email'};
	    $document->{'title'} = $desc_hash{'title'};
	$document->{'escaped_title'} = &tools::escape_html($document->{'title'});
	
	# Author
	if ($desc_hash{'email'}) {
	    $document->{'author'} = $desc_hash{'email'};
	    $document->{'author_mailto'} = &main::mailto($list,$desc_hash{'email'});
	    $document->{'author_known'} = 1;
	}
    }


   ### File, directory or URL ?
    if ($document->{'type'} eq 'url') {
	
	$document->{'icon'} = &main::get_icon('url');
	
	open DOC, $document->{'absolute_path'};
	my $url = <DOC>;
	close DOC;
	chomp $url;
	$document->{'url'} = $url;
	
	if ($document->{'filename'} =~ /^(.+)\.url/) {
	    $document->{'anchor'} = $1;
	}
    }elsif ($document->{'type'} eq 'file') {

	if (my $type = &main::get_mime_type($document->{'file_extension'})) {
	    # type of the file and apache icon
	    if ($type =~ /^([\w\-]+)\/([\w\-]+)$/) {
		my ($mimet, $subt) = ($1, $2);
		    if ($subt) {
			if ($subt =~  /^octet-stream$/) {
			    $mimet = 'octet-stream';
			    $subt = 'binary';
			}
			$type = "$subt file";
		    }
		$document->{'icon'} = &main::get_icon($mimet) || &main::get_icon('unknown');
	    }
	} else {
	    # unknown file type
	    $document->{'icon'} = &main::get_icon('unknown');
	}
	
	## HTML file
	if ($document->{'file_extension'} =~ /^html?$/i) { 
	    $document->{'html'} = 1;
	    $document->{'icon'} = &main::get_icon('text');
	}

	## Directory
    }else {
	
	$document->{'icon'} = &main::get_icon('folder');
	
	# listing of all the shared documents of the directory
	unless (opendir DIR, $document->{'absolute_path'}) {
	    &Log::do_log('err',"SharedDocument::new() : cannot open %s : %s", $document->{'absolute_path'}, $!);
	    return undef;
	}
	
	# array of entry of the directory DIR 
	my @tmpdir = readdir DIR; closedir DIR;
	
	my $dir = &main::get_directory_content(\@tmpdir, $email, $list, $document->{'absolute_path'});

	foreach my $d (@{$dir}) {

	    my $sub_document = new SharedDocument ($list, $document->{'path'}.'/'.$d, $param);	    
	    push @{$document->{'subdir'}}, $sub_document;
	}
    }

    $document->{'list'} = $list;
	
    ## Bless Message object
    bless $document, $pkg;
    
    return $document;
}

sub dump {
    my $self = shift;
    my $fd = shift;

    &tools::dump_var($self, 0, $fd);

}

sub dup {
    my $self = shift;

    my $copy = {};

    foreach my $k (keys %$self ) {
	$copy->{$k} = $self->{$k};
    }

    return $copy;
}

 ## Regulars
 #  read(/) = default (config list)
 #  edit(/) = default (config list)
 #  control(/) = not defined
#  read(A/B)= (read(A) && read(B)) ||
 #             (author(A) || author(B))
 #  edit = idem read
 #  control (A/B) : author(A) || author(B)
 #  + (set owner A/B) if (empty directory &&   
 #                        control A)


sub check_access_control {
    # Arguments:
    # (\%mode,$path)
    # if mode->{'read'} control access only for read
    # if mode->{'edit'} control access only for edit
    # if mode->{'control'} control access only for control
    
    # return the hash (
    # $result{'may'}{'read'} == $result{'may'}{'edit'} == $result{'may'}{'control'}  if is_author else :
    # $result{'may'}{'read'} = 0 or 1 (right or not)
    # $result{'may'}{'edit'} = 0(not may edit) or 0.5(may edit with moderation) or 1(may edit ) : it is not a boolean anymore
    # $result{'may'}{'control'} = 0 or 1 (right or not)
    # $result{'reason'}{'read'} = string for authorization_reject.tt2 when may_read == 0
    # $result{'reason'}{'edit'} = string for authorization_reject.tt2 when may_edit == 0
    # $result{'scenario'}{'read'} = scenario name for the document
    # $result{'scenario'}{'edit'} = scenario name for the document
    
    
    # Result
    my %result;
    $result{'reason'} = {};
    
    # Control 
    
    # Arguments
    my $self = shift;
    my $param = shift;

    my $list = $self->{'list'};

    &Log::do_log('debug', "check_access_control(%s)", $self->{'path'});

    # Control for editing
    my $may_read = 1;
    my $why_not_read = ''; 
    my $may_edit = 1;
    my $why_not_edit = ''; 
    
    ## First check privileges on the root shared directory
    $result{'scenario'}{'read'} = $list->{'admin'}{'shared_doc'}{'d_read'}{'name'};
    $result{'scenario'}{'edit'} = $list->{'admin'}{'shared_doc'}{'d_edit'}{'name'};
    
    ## Privileged owner has all privileges
    if ($param->{'is_privileged_owner'}) {
	$result{'may'}{'read'} = 1;
	$result{'may'}{'edit'} = 1;
	$result{'may'}{'control'} = 1; 

	$self->{'access'} = \%result;
	return 1;
    }
    
    # if not privileged owner
    if (1) {
	my $result = $list->check_list_authz('shared_doc.d_read',$param->{'auth_method'},
					     {'sender' => $param->{'user'}{'email'},
					      'remote_host' => $param->{'remote_host'},
					      'remote_addr' => $param->{'remote_addr'}});    
	my $action;
	if (ref($result) eq 'HASH') {
	    $action = $result->{'action'};   
	    $why_not_read = $result->{'reason'}; 
	}	     
	
	$may_read = ($action =~ /do_it/i);
    }
    
    if (1) {
	my $result = $list->check_list_authz('shared_doc.d_edit',$param->{'auth_method'},
					     {'sender' => $param->{'user'}{'email'},
					      'remote_host' => $param->{'remote_host'},
					      'remote_addr' => $param->{'remote_addr'}});
	my $action;
	if (ref($result) eq 'HASH') {
	    $action = $result->{'action'};   
	    $why_not_edit = $result->{'reason'}; 
	}	 
	
	#edit = 0, 0.5 or 1
	$may_edit = &main::find_edit_mode($action);	 
	$why_not_edit = '' if ($may_edit);
    }
    
    ## Only authenticated users can edit files
    unless ($param->{'user'}{'email'}) {
	$may_edit = 0;
	$why_not_edit = 'not_authenticated';
    }
    
    my $current_path = $self->{'path'};
    my $current_document;
    my %desc_hash;
    my $user = $param->{'user'}{'email'} || 'nobody';
    
    while ($current_path ne "") {
	# no description file found yet
	my $def_desc_file = 0;
	my $desc_file;
	
	$current_path =~ /^(([^\/]*\/)*)([^\/]+)(\/?)$/; 
	$current_document = $3;
	my $next_path = $1;
	
	# opening of the description file appropriated
	if (-d $self->{'root_path'}.'/'.$current_path) {
	    # case directory
	    
	    #		unless ($slash) {
	    $current_path = $current_path.'/';
	    #		}
	    
	    if (-e "$self->{'root_path'}/$current_path.desc"){
		$desc_file = $self->{'root_path'}.'/'.$current_path.".desc";
		$def_desc_file = 1;
	    }
	    
	}else {
	    # case file
	    if (-e "$self->{'root_path'}/$next_path.desc.$3"){
		$desc_file = $self->{'root_path'}.'/'.$next_path.".desc.".$3;
		$def_desc_file = 1;
	    } 
	}
	
	if ($def_desc_file) {
	    # a description file was found
	    # loading of acces information
	    
	    %desc_hash = &main::get_desc_file($desc_file);
	    
	    ## Author has all privileges
	    if ($user eq $desc_hash{'email'}) {
		$result{'may'}{'read'} = 1;
		$result{'may'}{'edit'} = 1;
		$result{'may'}{'control'} = 1;

		$self->{'access'} = \%result;
		return 1;
	    } 
	    
	    if (1) {
		
		my $result = $list->check_list_authz('shared_doc.d_read',$param->{'auth_method'},
						     {'sender' => $param->{'user'}{'email'},
						      'remote_host' => $param->{'remote_host'},
						      'remote_addr' => $param->{'remote_addr'},
						      'scenario'=> $desc_hash{'read'}});
		my $action;
		if (ref($result) eq 'HASH') {
		    $action = $result->{'action'};   
		    $why_not_read = $result->{'reason'}; 
		}	     
		
		$may_read = $may_read && ( $action=~ /do_it/i);
		$why_not_read = '' if ($may_read);
	    }
	    
	    if (1) {
		my $result = $list->check_list_authz('shared_doc.d_edit',$param->{'auth_method'},
						     {'sender' => $param->{'user'}{'email'},
						      'remote_host' => $param->{'remote_host'},
						      'remote_addr' => $param->{'remote_addr'},
						      'scenario'=> $desc_hash{'edit'}});
		my $action_edit;
		if (ref($result) eq 'HASH') {
		    $action_edit = $result->{'action'};   
		    $why_not_edit = $result->{'reason'}; 
		}
		
		
		# $may_edit = 0, 0.5 or 1
		my $may_action_edit = &main::find_edit_mode($action_edit);
		$may_edit = &main::merge_edit($may_edit,$may_action_edit); 
		$why_not_edit = '' if ($may_edit);
		
		
	    }
	    
	    ## Only authenticated users can edit files
	    unless ($param->{'user'}{'email'}) {
		$may_edit = 0;
		$why_not_edit = 'not_authenticated';
	    }
	    
	    unless (defined $result{'scenario'}{'read'}) {
		$result{'scenario'}{'read'} = $desc_hash{'read'};
		$result{'scenario'}{'edit'} = $desc_hash{'edit'};
	    }
	    
	}
	
	# truncate the path for the while   
	$current_path = $next_path; 
    }
    
    if (1) {
	$result{'may'}{'read'} = $may_read;
	$result{'reason'}{'read'} = $why_not_read;
    }
    
    if (1) {
	  $result{'may'}{'edit'} = $may_edit;
	  $result{'reason'}{'edit'} = $why_not_edit;
      }
    
    $self->{'access'} = \%result;
    return 1;
}

1;
