#! --PERL--

# tpl2tt2.pl - This script will concert existing templates (mail and web) from the old native
# Sympa template format to the TT2 format
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

use lib '--LIBDIR--';
use wwslib;
require "tt2.pl";

$wwsympa_conf_file = '--WWSCONFIG--';
$sympa_conf_file = '--CONFIG--';

use List;
use Log;

my %options;

my $pinfo = &List::_apply_defaults();

$| = 1;

## Check UID
unless (getlogin() eq '--USER--') {
    print "You should run this script as user \"sympa\", ignore ? (y/CR)";
    my $s = <STDIN>;
    die unless ($s =~ /^y$/i);
}

my $wwsconf = {};

## Load config 
unless ($wwsconf = &wwslib::load_config($wwsympa_conf_file)) {
    die 'unable to load config file';
}

## Load sympa config
unless (&Conf::load($sympa_conf_file)) {
    die 'config_error';
}

@directories;

## Search in main robot
if (-d "$Conf::Conf{'etc'}/templates") {
    push @directories, "$Conf::Conf{'etc'}/templates";
}
if (-d "$Conf::Conf{'etc'}/wws_templates") {
    push @directories, "$Conf::Conf{'etc'}/wws_templates";
}

## Go through Virtual Robots
foreach my $vr (keys %{$Conf::Conf{'robots'}}) {
    ## Search in etc/
    if (-d "$Conf::Conf{'etc'}/$vr/templates") {
	push @directories, "$Conf::Conf{'etc'}/$vr/templates";
    }
    if (-d "$Conf::Conf{'etc'}/$vr/wws_templates") {
	push @directories, "$Conf::Conf{'etc'}/$vr/wws_templates";
    }

    ## Search in V. Robot Lists
    foreach my $l ( &List::get_lists($vr) ) {
	my $list = new List ($l);
	next unless $list;
	
	push @directories, $list->{'dir'};
	
	if (-d "$list->{'dir'}/templates") {
	    push @directories, "$list->{'dir'}/templates";
	}
	if (-d "$list->{'dir'}/wws_templates") {
	    push @directories, "$list->{'dir'}/wws_templates";
	}
    }
}

my @templates;

## List .tpl files
foreach my $d (@directories) {
    unless (opendir DIR, $d) {
	print STDERR "Error: Cannot read %s directory : %s", $d, $!;
	next;
    }
    
    foreach my $tpl (sort grep(/\.tpl$/,readdir DIR)) {
	push @templates, "$d/$tpl";
    }
    
    closedir DIR;
}

my $total;
foreach my $tpl (@templates) {
    
    unless (-r $tpl) {
	print STDERR "Error : Unable to read file %s\n", $tpl;
	next;
    }

    unless ($tpl =~ /^(.+)\/([^\/]+)$/) {
	print STDERR "Error : Incorrect Path %s\n", $tpl;
	next;
    }
    
    my ($path, $file) = ($1, $2);
    my ($dest_path, $dest_file);

    ## Destinatination Path
    $dest_path = $path;
    if ($path =~ /\/wws_templates$/) {
	$dest_path =~ s/wws_templates/web_tt2/;
    }else {
	if ($path =~ /\/templates$/) {
	    $dest_path =~ s/templates/tt2/;
	}else {
	    $dest_path .= '/tt2';
	}
    }

    ## Destination filename
    $dest_file = $file;
    $dest_file =~ s/\.tpl$/\.tt2/;

    ## Create directory if required
    unless (-d $dest_path) {
	printf "Creating $dest_path directory\n";
	unless (mkdir ($dest_path, 0777)) {
	    printf STDERR "Error : Cannot create $dest_path directory : $!\n";
	    next;
	}
	chown '--USER--', '--GROUP--', $dest_path;
    }

    my $tt2 = "$dest_path/$dest_file";

    ## Convert tpl file
    unless (open TPL, $tpl) {
	print STDERR "Cannot open $tpl : $!\n";
	next;
    }
    unless (open TT2, ">$tt2") {
	print STDERR "Cannot create $tt2 : $!\n";
	next;
    }
    while (<TPL>) {
	print TT2 Sympa::Template::Compat::_translate($_);
    }
    close TT2;
    close TPL;
    
    chown '--USER--', '--GROUP--', $tt2;
    $total++;
    
    printf "Template file $tpl has been converted to $tt2\n";

    ## Rename old files to .converted
    unless (rename $tpl, "$tpl.converted") {
	print STDERR "Error : failed to rename $tpl to $tpl.converted : $!\n";
	next;
    }
}

print "\n$total template files have been converted\n";
