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

## We have a parameter that should be a template to convert
## Output is sent to stdout
if ($#ARGV >=0) {
    my $f = $ARGV[0];
    unless (-f $f) {
	die "unable to find file $f";
    }
    
    &convert($f);

    exit 0;
}

## Default is to migrate every template to the new TT2 format

my @directories;
my @templates;

## Search in main robot
if (-d "$Conf::Conf{'etc'}/templates") {
    push @directories, "$Conf::Conf{'etc'}/templates";
}
if (-d "$Conf::Conf{'etc'}/wws_templates") {
    push @directories, "$Conf::Conf{'etc'}/wws_templates";
}
if (-f "$Conf::Conf{'etc'}/mhonarc-ressources") {
    push @templates, "$Conf::Conf{'etc'}/mhonarc-ressources";
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
    if (-f "$Conf::Conf{'etc'}/$vr/mhonarc-ressources") {
	push @templates, "$Conf::Conf{'etc'}/$vr/mhonarc-ressources";
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

    ## We don't migrate mhonarc-ressources files
    if ($tpl =~ /mhonarc\-ressources$/) {
	rename $tpl, "$tpl.uncompatible";
	print STDERR "File $tpl could not be translated to TT2 ; it has been renamed $tpl.uncompatible. You should customize a standard mhonarc-ressourses.tt2 file\n";
	next;
    }

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
    }elsif ($path =~ /\/templates$/) {
	$dest_path =~ s/templates/mail_tt2/;
    }elsif ($path =~ /\/expl\//) {
	$dest_path .= '/mail_tt2';
    }else {
	$dest_path = $path;
    }

    ## Destination filename
    $dest_file = $file;
    $dest_file =~ s/\.tpl$/\.tt2/;

    ## If file has no extension
    unless ($dest_file =~ /\./) {
	$dest_file = $file.'.tt2';
    }

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

    &convert($tpl, $tt2);
    $total++;
    
    ## Rename old files to .converted
    unless (rename $tpl, "$tpl.converted") {
	print STDERR "Error : failed to rename $tpl to $tpl.converted : $!\n";
	next;
    }
}

print "\n$total template files have been converted\n";

## Convert a template file to tt2
sub convert {
    my ($in_file, $out_file) = @_;

    ## Convert tpl file
    unless (open TPL, $in_file) {
	print STDERR "Cannot open $in_filel : $!\n";
	next;
    }
    if ($out_file) {
	unless (open TT2, ">$out_file") {
	    print STDERR "Cannot create $out_file : $!\n";
	    next;
	}
    }

    while (<TPL>) {
	if ($out_file) {
	    print TT2 Sympa::Template::Compat::_translate($_);
	}else {
	    print STDOUT Sympa::Template::Compat::_translate($_);
	}
    }
    close TT2 if ($out_file);
    close TPL;

    printf "Template file $in_file has been converted to $out_file\n";
    
    chown '--USER--', '--GROUP--', $out_file;    
}
