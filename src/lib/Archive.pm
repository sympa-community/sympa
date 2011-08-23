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

use Log;

my $serial_number = 0; # incremented on each archived mail

## RCS identification.

## copie a message in $dir using a unique file name based on liSTNAME

sub outgoing {
    my($dir,$list_id,$msg) = @_;
    
    &Log::do_log ('debug2',"outgoing for list $list_id to directory $dir");
    
    return 1 if ($dir eq '/dev/null');

    ## ignoring message with a no-archive flag
    if (ref($msg) && 
	($Conf::Conf{'ignore_x_no_archive_header_feature'} ne 'on') && 
	(($msg->head->get('X-no-archive') =~ /yes/i) || ($msg->head->get('Restrict') =~ /no\-external\-archive/i))) {
	&Log::do_log('info',"Do not archive message with no-archive flag for list $list_id");
	return 1;
    }

    
    ## Create the archive directory if needed
    
    unless (-d $dir) {
	mkdir ($dir, 0775);
	chmod 0774, $dir;
	&Log::do_log('info',"creating $dir");
    }
    
    my @now  = localtime(time);
#    my $prefix= sprintf("%04d-%02d-%02d-%02d-%02d-%02d",1900+$now[5],$now[4]+1,$now[3],$now[2],$now[1],$now[0]);
#    my $filename = "$dir"."/"."$prefix-$list_id";
    my $filename = sprintf '%s/%s.%d.%d.%d', $dir, $list_id, time, $$, $serial_number;
    $serial_number = ($serial_number+1)%100000;
    unless ( open(OUT, "> $filename")) {
	&Log::do_log('info',"error unable open outgoing dir $dir for list $list_id");
	return undef;
    }
    &Log::do_log('debug',"put message in $filename");
    if (ref ($msg)) {
  	$msg->print(\*OUT);
    }else {
 	print OUT $msg;
    }
    close (OUT);
}

## Does the real job : stores the message given as an argument into
## the indicated directory.

sub store_last {
    my($list, $msg) = @_;
    
    &Log::do_log ('debug2','archive::store ()');
    
    my($filename, $newfile);
    
    return unless $list->is_archived();
    my $dir = $list->{'dir'}.'/archives';
    
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

	$msg->{'subject'} = &MIME::EncWords::decode_mimewords($mail->{'msg'}->head->get('Subject'), Charset=>'utf8');
	chomp $msg->{'subject'};

	$msg->{'from'} = &MIME::EncWords::decode_mimewords($mail->{'msg'}->head->get('From'), Charset=>'utf8');
	chomp $msg->{'from'};    	        	
        
	$msg->{'date'} = &MIME::EncWords::decode_mimewords($mail->{'msg'}->head->get('Date'), Charset=>'utf8');
	chomp $msg->{'date'};
	
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
	&Log::do_log ('info',"archive::search_msgid : dir $dir look unproper");
	return undef;
    }
    unless (opendir (ARC, "$dir")){
	&Log::do_log ('info',"archive::scan_dir_archive($dir, $msgid): unable to open dir $dir");
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

    &Log::do_log('debug', 'Archived::last_path(%s)', $list->{'name'});

    return undef unless ($list->is_archived());
    my $file = $list->{'dir'}.'/archives/last_message';

    return ($list->{'dir'}.'/archives/last_message') if (-f $list->{'dir'}.'/archives/last_message'); 
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

1;


