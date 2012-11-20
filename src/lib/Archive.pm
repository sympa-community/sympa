# Archive.pm - This module does the archiving job for a mailing lists.
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

package Archive;

use strict;
use Carp qw(carp);
use Cwd;
use Encode qw(decode_utf8 encode_utf8);
use HTML::Entities qw(decode_entities);

use Log;

my $serial_number = 0; # incremented on each archived mail

## RCS identification.

## Does the real job : stores the message given as an argument into
## the indicated directory.

sub store_last {
    my($list, $msg) = @_;
    
    &Log::do_log ('debug2','archive::store ()');
    
    my($filename, $newfile);
    
    return unless $list->is_archived();
    my $dir = $list->dir.'/archives';
    
    ## Create the archive directory if needed
    mkdir ($dir, "0775") if !(-d $dir);
    chmod 0774, $dir;
    
    
    ## erase the last  message and replace it by the current one
    open(OUT, "> $dir/last_message");
    if (ref ($msg)) {
  	$msg->print(\*OUT);
    }else {
 	print OUT $msg;
    }
    close(OUT);
    
}

## Lists the files included in the archive, preformatted for printing
## Returns an array.
sub list {
    my $name = shift;

    &Log::do_log ('debug',"archive::list($name)");

    my($filename, $newfile);
    my(@l, $i);
    
    unless (-d "$name") {
	&Log::do_log ('warning',"archive::list($name) failed, no directory $name");
#      @l = ($msg::no_archives_available);
      return @l;
  }
    unless (opendir(DIR, "$name")) {
	&Log::do_log ('warning',"archive::list($name) failed, cannot open directory $name");
#	@l = ($msg::no_archives_available);
	return @l;
    }
   foreach $i (sort readdir(DIR)) {
       next if ($i =~ /^\./o);
       next unless  ($i =~ /^\d\d\d\d\-\d\d$/);
       my(@s) = stat("$name/$i");
       my $a = localtime($s[9]);
       push(@l, sprintf("%-40s %7d   %s\n", $i, $s[7], $a));
   }
    return @l;
}

sub scan_dir_archive {
    
    my($dir, $month) = @_;
    
    &Log::do_log ('info',"archive::scan_dir_archive($dir, $month)");

    unless (opendir (DIR, "$dir/$month/arctxt")){
	&Log::do_log ('info',"archive::scan_dir_archive($dir, $month): unable to open dir $dir/$month/arctxt");
	return undef;
    }
    
    my $all_msg = [];
    my $i = 0 ;
    foreach my $file (sort readdir(DIR)) {
	next unless ($file =~ /^\d+$/);
	&Log::do_log ('debug',"archive::scan_dir_archive($dir, $month): start parsing message $dir/$month/arctxt/$file");

	my $mail = new Message({'file'=>"$dir/$month/arctxt/$file",'noxsympato'=>'noxsympato'});
	unless (defined $mail) {
	    &Log::do_log('err', 'Unable to create Message object %s', $file);
	    return undef;
	}
	
	&Log::do_log('debug',"MAIL object : $mail");

	$i++;
	my $msg = {};
	$msg->{'id'} = $i;

	$msg->{'subject'} = &tools::decode_header($mail, 'Subject');
	$msg->{'from'} = &tools::decode_header($mail, 'From');
	$msg->{'date'} = &tools::decode_header($mail, 'Date');

	$msg->{'full_msg'} = $mail->{'msg'}->as_string;

	&Log::do_log('debug','Archive::scan_dir_archive adding message %s in archive to send', $msg->{'subject'});

	push @{$all_msg}, $msg ;
    }
    closedir DIR ;

    return $all_msg;
}

#####################################################
#  search_msgid                  
####################################################
#  
# find a message in archive specified by arcpath and msgid
# 
# IN : arcpath and msgid
#
# OUT : undef | #message in arctxt
#
#################################################### 

sub search_msgid {
    
    my($dir, $msgid) = @_;
    
    &Log::do_log ('info',"archive::search_msgid($dir, $msgid)");

    
    if ($msgid =~ /NO-ID-FOUND\.mhonarc\.org/) {
	&Log::do_log('err','remove_arc: no message id found');return undef;
    } 
    unless ($dir =~ /\d\d\d\d\-\d\d\/arctxt/) {
	&Log::do_log ('err',"archive::search_msgid : dir $dir look unproper");
	return undef;
    }
    unless (opendir (ARC, "$dir")){
	&Log::do_log ('err',"archive::scan_dir_archive($dir, $msgid): unable to open dir $dir");
	return undef;
    }
    chomp $msgid ;

    foreach my $file (grep (!/\./,readdir ARC)) {
	next unless (open MAIL,"$dir/$file") ;
	while (<MAIL>) {
	    last if /^$/ ; #stop parse after end of headers
	    if (/^Message-id:\s?<?([^>\s]+)>?\s?/i ) {
		my $id = $1;
		if ($id eq $msgid) {
		    close MAIL; closedir ARC;
		    return $file;
		}
	    }
	}
	close MAIL;
    }
    closedir ARC;
    return undef;
}


sub exist {
    my($name, $file) = @_;
    my $fn = "$name/$file";
    
    return $fn if (-r $fn && -f $fn);
    return undef;
}


# return path for latest message distributed in the list
sub last_path {
    
    my $list = shift;

    &Log::do_log('debug', 'Archived::last_path(%s)', $list->name);

    return undef unless ($list->is_archived());
    my $file = $list->dir.'/archives/last_message';

    return ($list->dir.'/archives/last_message') if (-f $list->dir.'/archives/last_message'); 
    return undef;

}

## Load an archived message, returns the mhonarc metadata
## IN : file_path
sub load_html_message {
    my %parameters = @_;

    &Log::do_log ('debug2',$parameters{'file_path'});
    my %metadata;

    unless (open ARC, $parameters{'file_path'}) {
	&Log::do_log('err', "Failed to load message '%s' : $!", $parameters{'file_path'});
	return undef;
    }

    while (<ARC>) {
	last if /^\s*$/; ## Metadata end with an emtpy line

	if (/^<!--(\S+): (.*) -->$/) {
	    my ($key, $value) = ($1, $2);
	    $value = encode_utf8(decode_entities(decode_utf8($value)));
	    if ($key eq 'X-From-R13') {
		$metadata{'X-From'} = $value;
		$metadata{'X-From'} =~ tr/N-Z[@A-Mn-za-m/@A-Z[a-z/; ## Mhonarc protection of email addresses
		$metadata{'X-From'} =~ s/^.*<(.*)>/$1/g; ## Remove the gecos
	    }
	    $metadata{$key} = $value;
	}
    }

    close ARC;
    
    return \%metadata;
}


sub clean_archive_directory{
    my $params = shift;
    &Log::do_log('debug',"Cleaning archives for directory '%s'.",$params->{'arc_root'}.'/'.$params->{'dir_to_rebuild'});
    my $answer;
    $answer->{'dir_to_rebuild'} = $params->{'arc_root'}.'/'.$params->{'dir_to_rebuild'};
    $answer->{'cleaned_dir'} = Site->tmpdir.'/'.$params->{'dir_to_rebuild'};
    unless(my $number_of_copies = &tools::copy_dir($answer->{'dir_to_rebuild'},$answer->{'cleaned_dir'})){
	&Log::do_log('err',"Unable to create a temporary directory where to store files for HTML escaping (%s). Cancelling.",$number_of_copies);
	return undef;
    }
    if(opendir ARCDIR,$answer->{'cleaned_dir'}){
	my $files_left_uncleaned = 0;
	foreach my $file (readdir(ARCDIR)){
	    next if($file =~ /^\./);	    
	    $file = $answer->{'cleaned_dir'}.'/'.$file;
	    $files_left_uncleaned++ unless(&clean_archived_message({'input'=>$file ,'output'=>$file})); 
	}
	closedir DIR;
	if ($files_left_uncleaned) {
	    &Log::do_log('err',"HTML cleaning failed for %s files in the directory %s.",$files_left_uncleaned,$answer->{'dir_to_rebuild'});
	}
	$answer->{'dir_to_rebuild'} = $answer->{'cleaned_dir'};
    }else{
	&Log::do_log('err','Unable to open directory %s: %s',$answer->{'dir_to_rebuild'},$!);
	&tools::del_dir($answer->{'cleaned_dir'});
	return undef;
    }
    return $answer;
}

sub clean_archived_message{
    my $params = shift;
    &Log::do_log('debug',"Cleaning HTML parts of a message input %s , output  %s ",$params->{'input'},$params->{'output'});

    my $input = $params->{'input'};
    my $output = $params->{'output'};


    if (my $msg = new Message({'file'=>$input, 'noxsympato' => 1})){
	if($msg->clean_html()){
	    if(open TMP, ">$output") {
		print TMP $msg->{'msg'}->as_string;
		close TMP;
	    }else{
		&Log::do_log('err','Unable to create a tmp file to write clean HTML to file %s',$output);
		return undef;
	    }
	}else{
	    &Log::do_log('err','HTML cleaning in file %s failed.',$output);
	    return undef;
	}
    }else{
	&Log::do_log('err','Unable to create a Message object with file %s',$input);
	exit;
	return undef;
    }
}

#############################
# convert a messsage to html. 
#    result is stored in $destination_dir
#    attachement_url is used to link attachement
#    
# NOTE: This might be moved to Site package as a mutative method.
sub convert_single_msg_2_html {
    
    my $data =shift;
    my $msg_as_string = $data->{'msg_as_string'};
    my $destination_dir = $data->{'destination_dir'};
    my $attachement_url = $data->{'attachement_url'};
    my $list = $data->{'list'};
    my $robot = Robot::clean_robot($data->{'robot'});
    my $messagekey = $data->{'messagekey'};

    my $listname ='';
    my $msg_file;
    #XXXmy $host = $robot;
    my $host;
    if ($list) {
	$host = $list->host;
	$robot = $list->robot;
	$listname = $list->name;
	$msg_file = $robot->tmpdir . '/' . $list->get_id() . '_' . $$;
    } else {
	$host = $robot->host;
	$listname = '';
	$msg_file = $robot->tmpdir . '/' . $messagekey . '_' . $$;
    }

    my $pwd = getcwd;  #  mhonarc require du change workdir so this proc must retore it    
    unless (open(OUT, ">$msg_file")) {
&Log::do_log('notice', 'Could Not open %s', $msg_file);
	return undef;
    }
    printf OUT $msg_as_string ;
    close(OUT);

    unless (-d $destination_dir) {
	unless (&tools::mkdir_all($destination_dir, 0777)) {
	    &Log::do_log('err','Unable to create %s', $destination_dir);
	    return undef;
	}
    }
    my $mhonarc_ressources = ($list || $robot)->get_etc_filename(
	'mhonarc-ressources.tt2');
    
    unless ($mhonarc_ressources) {
&Log::do_log('notice',"Cannot find any MhOnArc ressource file");
	return undef;
    }
    ## generate HTML
    unless (chdir $destination_dir) {
&Log::do_log('err',"Could not change working directory to %s",$destination_dir);
    }
    my $tracepwd = getcwd ;


    my $mhonarc = $robot->mhonarc;
    my $base_url = $robot->wwsympa_url;
    #open ARCMOD, "$mhonarc  -single --outdir .. -rcfile $mhonarc_ressources -definevars listname=$listname -definevars hostname=$host -attachmenturl=$attachement_url $msg_file |";
    #open MSG, ">msg00000.html";
    #&Log::do_log('debug', "$mhonarc  --outdir .. -single -rcfile $mhonarc_ressources -definevars listname=$listname -definevars hostname=$host $msg_file");
    #print MSG <ARCMOD>;
    #close MSG;
    #close ARCMOD;
    `$mhonarc  -single --outdir .. -rcfile $mhonarc_ressources -definevars listname=$listname -definevars hostname=$host -attachmenturl=$attachement_url $msg_file > msg00000.html`;

    # restore current wd 
    chdir $pwd;		

    return 1;
}

1;
