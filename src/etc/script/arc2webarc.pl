#! --PERL--

# arc2webarc.pl - This script will concert existing Sympa mail archives
# to Sympa web archives
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

use lib '--BINDIR--';
use wwslib;
$wwsympa_conf_file = '--WWSCONFIG--';
$sympa_conf_file = '--CONFIG--';

use List;
use Log;

my %month_idx = qw(jan 1 
		   fev 2
		   feb 2
		   fv  2
		   mar 3
		   avr 4
		   apr 4
		   mai 5
		   may 5
		   jun 6
		   jul 7
		   aug 8
		   aou 8
		   sep 9
		   oct 10
		   nov 11
		   dec 12
		   dc  12);

my @msgs;
my %nummsg;

my %options;
# load options ?
#$main::options{'debug'} = 1;
#$main::options{'debug2'} = 1 if ($main::options{'debug'});

# this line is necessary - without it the new List fails.
my $pinfo = &List::_apply_defaults();

$| = 1;

die "Usage : $ARGV[-1] <listname>" unless ($#ARGV >= 0);
my $listname = $ARGV[0];

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

$List::use_db = &List::probe_db();

chdir $Conf::Conf{'home'};

my $list = new List($listname) 
    or die 'Cannot create List object';

my $home_sympa = $Conf::Conf{'home'};
my $dest_dir = "$wwsconf->{'arc_path'}/$listname\@$list->{'admin'}{'host'}";

## Burst archives
unless (-d "$home_sympa/$listname") {
    die "No directory for list $listname";
}

unless (-d "$home_sympa/$listname/archives") {
    die "No archives for list $listname";
}

print STDERR "Bursting archives\n";
foreach my $arc_file (<$home_sympa/$listname/archives/log*>) {
    my ($first, $new);
    my $msg = [];

    print '.';
    open ARCFILE, $arc_file;
    while (<ARCFILE>) {
	if (/^------- THIS IS A RFC934 (COMPILANT|COMPLIANT) DIGEST/) {
	    $first = 1;
	    $new = 1;
	    next;
	}elsif (! $first) {
	    next;
	}elsif (/^$/ && $new) {
	    next;
	}elsif (/^------- CUT --- CUT/) {
	    push @msgs, $msg;
	    $msg = [];
	    $new = 1;
	}else {
	    push @{$msg}, $_;
	    undef $new;
	}
    }
    close ARCFILE;
}

print STDERR "\nFound $#msgs messages\n";

##Dump
#foreach my $i (0..$#msgs) {
#    printf "******** Message %d *******\n", $i;
#    print @{$msgs[$i]};
#}


if (-d $dest_dir) {
    print "Web archives already exist for list $listname\nGo on (<CR>|n) ?";
    my $s = <STDIN>;
    die if ($s eq 'n');
}else {
    mkdir $dest_dir, 0755 or die;
}

## Analyzing Date header fields

print STDERR "Analysing Date: header fields\n";
foreach my $msg (@msgs) {
    my $incorrect = 0;
    my ($date, $year, $month);
    
    print '.';
    foreach (@{$msg}) {
	if (/^Date:\s+(.*)$/) {
	    #print STDERR "#$_#\n";
	    $date = $1;

	    # Date type : Mon, 8 Dec 97 13:33:47 +0100
	    if ($date =~ /^\w{2,3},\s+\d{1,2}\s+([\wéû]{2,3})\s+(\d{2,4})/) {
                $month = $1;
		$year =$2;
		#print STDERR "$month/$year\n";

	    # Date type : 8 Dec 97 13:33:47+0100
	    }elsif ($date =~ /^\d{1,2}\s+(\w{3}) (\d{2,4})/) {
		$month = $1;
		$year =$2;

	    # Date type : 8-DEC-1997 13:33:47 +0100
	    }elsif ($date =~ /^\d{1,2}-(\w{3})-(\d{4})/) {
		$month = $1;
		$year =$2;

	    # Date type : Mon Dec 8 13:33:47 1997
	    }elsif ($date =~ /^\w+\s+(\w+)\s+\d{1,2} \d+:\d+:\d+ (GMT )?(\d{4})/) {
		$month = $1;
		$year =$3;

	    # unknown date format
	    }else {
		$incorrect = 1;
		last;
	    }
               
	    # Month format
	    if ($month !~ /^\d+$/) {
		$month =~ y/éûA-Z/eua-z/;
		if (!$month_idx{$month}) {
		    $incorrect = 1;
		}else {
		    $month = $month_idx{$month};
		}
	    }elsif (($month < 1) or ($month > 12)) {
		$incorrect = 1;
	    }
	    $month = "0".$month if $month =~ /^\d$/;
	    
	    # Checking Year format
	    if ($year =~ /^[89]\d$/) {
		$year = "19".$year;
	    }elsif ($year !~ /^19[89]\d|200[0-9]$/) {
		$incorrect = 1;
	    }
	    
	    last;
	}
	
	# empty line => end of header
	if (/^\s*$/) {
	    last;
	}
    }
    close MSG;
    # Unknown date format/No date
    if ($incorrect || ! $month || ! $year) {
	$year = 'UN';
	$month = 'KNOWN';
    }
    
    # New month
    if (!-d "$dest_dir/$year-$month") {
	print "\nNew directory $year-$month\n";
	`mkdir $dest_dir/$year-$month`;
    }

    if (!-d "$dest_dir/$year-$month/arctxt") {
	`mkdir $dest_dir/$year-$month/arctxt`;
    }

    $nummsg{$year}{$month}++ while (-e "$dest_dir/$year-$month/arctxt/$nummsg{$year}{$month}");

    # Save message
    open DESTFILE, ">$dest_dir/$year-$month/arctxt/$nummsg{$year}{$month}";
    print DESTFILE @{$msg};
    close DESTFILE;
#    `mv $m $dest_dir/$year-$month/arctxt/$nummsg{$year}{$month}`;
     $nummsg{$year}{$month}++;
}
  
## Rebuild web archives
print STDERR "Rebuilding HTML\n";
`touch $Conf::Conf{'queueoutgoing'}/.rebuild.$listname\@$list->{'admin'}{'host'}`;

print STDERR "\nHave a look in $dest_dir/-/ directory for messages dateless
Now, you should add a web_archive parameter in the config file to make it accessible from the web\n";





