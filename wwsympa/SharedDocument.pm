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
require Exporter;
require 'tools.pl';
my @ISA = qw(Exporter);
my @EXPORT = qw();

use Carp;
use List;
use Log;
use POSIX;

## Creates a new object
sub new {
    my($pkg, $list, $path, $email) = @_;

    #$email ||= 'nobody';
    my $document = {};
    &do_log('debug2', 'SharedDocument::new(%s, %s)', $list->{'name'}, $path);
    
    unless (ref($list) =~ /List/i) {
	&do_log('err', 'SharedDocument::new : incorrect list parameter');
	return undef;
    }

    my $shared_dir = $list->{'dir'}.'/shared';

    $document->{'path'} = &main::no_slash_end($path);
    $document->{'escaped_path'} = &tools::escape_chars($document->{'path'}, '/');

    ### Document isn't a description file
    if ($document->{'path'} =~ /\.desc/) {
	&do_log('err',"SharedDocument::new : %s : description file", $document->{'path'});
	return undef;
    }

    ## Check privileges
    my %mode = ('read' => 1,
		'edit' => 1,
		'control' => 1
	    );

    my %access = &main::d_access_control(\%mode, $document->{'path'});
    unless (defined %access) {
	&do_log('err',"SharedDocument::new : failed to determine access privileges for %s", $document->{'absolute_path'});
	return undef;
    }
    $document->{'access'} = \%access;   

    ###############################
    ## The path has been checked ##
    ###############################

    ## absolute path
    # my $doc;
    $document->{'absolute_path'} = $shared_dir;
    if ($document->{'path'}) {
	$document->{'absolute_path'} .= '/'.$document->{'path'};
    }

    ### Document exist ? 
    unless (-r $document->{'absolute_path'}) {
	&do_log('err',"SharedDocument::new : unable to read %s : no such file or directory", $document->{'absolute_path'});
	return undef;
    }
    
    ### Document has non-size zero?
    unless (-s $document->{'absolute_path'}) {
	&do_log('err',"SharedDocument::new : unable to read %s : empty document", $document->{'absolute_path'});
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
	    &do_log('err',"SharedDocument::new() : cannot determine desc file for %s", $document->{'absolute_path'});
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
	    &do_log('err',"SharedDocument::new() : cannot open %s : %s", $document->{'absolute_path'}, $!);
	    return undef;
	}
	
	# array of entry of the directory DIR 
	my @tmpdir = readdir DIR; closedir DIR;
	
	my $dir = &main::get_directory_content(\@tmpdir, $email, $list, $document->{'absolute_path'});

	foreach my $d (@{$dir}) {

	    my $sub_document = new SharedDocument ($list, $path.'/'.$d, $email);	    
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

## Packages must return true.
1;
