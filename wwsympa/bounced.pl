#!--PERL--

# bounced.pl - This script runs as a daemon ; it does the incoming 
# non-delivery reports analysis and storage
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


## Worl Wide Sympa is a front-end to Sympa Mailing Lists Manager
## Copyright Comite Reseau des Universites

## Patch 2001.07.24 by nablaphi <nablaphi@bigfoot.com>
## Change the Getopt::Std to Getopt::Long

## Options :  F         -> do not detach TTY
##         :  d		-> debug -d is equiv to -dF
## Now, it is impossible to use -dF but you have to write it -d -F

## Change this to point to your Sympa bin directory
use lib '--LIBDIR--';
use strict;

use FileHandle;

use List;
use Conf;
use Log;
use smtp;
#use Getopt::Std;
use Getopt::Long;
use POSIX;

require 'tools.pl';

## Equivalents relative to RFC 1893
my %equiv = ( "user unknown" => '5.1.1',
	      "receiver not found" => '5.1.1',
	      "the recipient name is not recognized" => '5.1.1',
	      "sorry, no mailbox here by that name" => '5.1.1',
	      "utilisateur non recensé dans le carnet d'adresses public" => '5.1.1',
	      "unknown address" => '5.1.1',
	      "unknown user" => '5.1.1',
	      "550" => '5.1.1',
	      "le nom du destinataire n'est pas reconnu" => '5.1.1',
	      "user not listed in public name & address book" => '5.1.1',
	      "no such address" => '5.1.1',
	      "not known at this site." => '5.1.1',
	      "user not known" => '5.1.1',
	      
	      "user is over the quota. you can try again later." => '4.2.2',
	      "quota exceeded" => '4.2.2',
	      "write error to mailbox, disk quota exceeded" => '4.2.2',
	      "user mailbox exceeds allowed size" => '4.2.2',
	      "insufficient system storage" => '4.2.2',
	      "User's Disk Quota Exceeded:" => '4.2.2');


require "--LIBDIR--/bounce-lib.pl";
use wwslib;

#getopts('dF');
## Check options
my %options;
&GetOptions(\%main::options, 'debug|d','log_level=s','foreground|F');
# $main::options{'debug2'} = 1 if ($main::options{'debug'});

if ($main::options{'debug'}) {
    $main::options{'log_level'} = 2 unless ($main::options{'log_level'});
}

my $wwsympa_conf = "--WWSCONFIG--";
my $sympa_conf_file = '--CONFIG--';

my $wwsconf = {};

# Load WWSympa configuration
unless ($wwsconf = &wwslib::load_config($wwsympa_conf)) {
    print STDERR 'unable to load config file';
    exit;
}

# Load sympa.conf
unless (Conf::load($sympa_conf_file)) {
    &fatal_err("Unable to load sympa configuration, file $sympa_conf_file has errors.");
}


unshift @INC, $wwsconf->{'wws_path'};

## Check databse connectivity
unless ($List::use_db = &List::probe_db()) {
    print STDERR "Sympa not setup to use DBI, unable to manage bounces\n";
    exit (-1);
}

## Put ourselves in background if not in debug mode. 
unless ($main::options{'debug'} || $main::options{'foreground'}) {

    open(STDERR, ">> /dev/null");
    open(STDOUT, ">> /dev/null");
    if (open(TTY, "/dev/tty")) {
       ioctl(TTY, 0x20007471, 0);         # XXX s/b &TIOCNOTTY
#	ioctl(TTY, &TIOCNOTTY, 0);
	close(TTY);
    }
    setpgrp(0, 0);
    if ((my $child_pid = fork) != 0) {
	print STDOUT "Starting bounce daemon, pid $_\n";

	exit(0);
    }
}

## Create and write the pidfile
&tools::write_pid($wwsconf->{'bounced_pidfile'}, $$);

$log_level = $main::options{'log_level'} || $Conf{'log_level'};

$wwsconf->{'log_facility'}||= $Conf{'syslog'};
do_openlog($wwsconf->{'log_facility'}, $Conf{'log_socket_type'}, 'bounced');

## Set the UserID & GroupID for the process
$( = $) = (getpwnam('--GROUP--'))[2];
$< = $> = (getpwnam('--USER--'))[2];


## Sets the UMASK
umask($Conf{'umask'});

## Change to list root
unless (chdir($Conf{'home'})) {
    &message('chdir_error');
    &do_log('info','Unable to change directory');
    exit (-1);
}

my $pinfo = &List::_apply_defaults();

do_log('notice', "bounced Started");


## Catch SIGTERM, in order to exit cleanly, whenever possible.
$SIG{'TERM'} = 'sigterm';
my $end = 0;


my $queue = $Conf{'queuebounce'};

## infinite loop scanning the queue (unless a sig TERM is received
while (!$end) {
    ## this sleep is important to be raisonably sure that sympa is not currently
    ## writting the file this deamon is openning. 
    
    sleep $Conf{'sleep'};
    
    &List::init_list_cache();

    unless (opendir(DIR, $queue)) {
	fatal_err("Can't open dir %s: %m", $queue); ## No return.
    }

    my @files =  (sort grep(!/^(\.{1,2}|T\..*)$/, readdir DIR ));
    closedir DIR;
    foreach my $file (@files) {

	last if $end;
	
	unless ($file =~ /^(\S+)\.\d+\.\d+$/) {
	    my @s = stat("$queue/$file");
	    if (POSIX::S_ISREG($s[2])) {
		do_log ('notice',"Ignoring file $queue/$file because unknown format");
	        unlink("$queue/$file");
	    }
	    next;
	}
	
	if (-z "$queue/$file") {
	    do_log ('notice',"Ignoring file $queue/$file because empty file");
	    unlink("$queue/$file");
	}
	my ($listname, $robot) = split(/\@/,$1);
	$robot ||= $Conf{'domain'};

	if ($listname eq 'sympa') {
	    ## In this case return-path should has been set by sympa
            ## in order to recognize a welcome message bounce
	    unless (open BOUNCE, "$queue/$file") {
		&do_log('notice', 'Could not open %s/%s: %s', $queue, $file, $!);
		rename "$queue/$file", "$queue/BAD-$file";
		next;
		}

	    my $parser = new MIME::Parser;
	    $parser->output_to_core(1);
	    my $entity = $parser->read(\*BOUNCE);
	    my $head = $entity->head;
	    my $to = $head->get('to', 0);
	    close BOUNCE ;
	    if ($to =~ /^bounce\+(.*)\=\=a\=\=(.*)\=\=(.*)\@/) {
		my $who = "$1\@$2";
		my $listname = $3 ;
		my $list = new List ($listname);
		my $action =&List::request_action ('del','smtp',$robot,
					{'listname' =>$listname,
					 'sender' => $Conf{'listmasters'}[0],
					 'email' => $who});

#                    &List::get_action ('del', $listname, $Conf{'listmasters'}[0], 'smtp');

		if ($action =~ /do_it/i) {
		    if ($list->is_user($who)) {
			my $u = $list->delete_user($who);
			$list->save();
			do_log ('notice',"$who has been removed from $listname because welcome message bounced");
			
			$list->send_notify_to_owner({'who' => $who, 
						     'gecos' => "", 
						     'type' => 'automatic_del', 
						     'by' => 'listmaster'});
		    }
		}else {
		    do_log ('notice',"Unable to remove $who from $listname (welcome message bounced but del is closed)");
		}
		
	    }
	    unlink("$queue/$file");
	    next;
	}

	## ELSE
	my $list = new List ($listname);
	if ($list) {

	    do_log('debug',"Processing bouncefile $file for list $listname");      

	    unless (open BOUNCE, "$queue/$file") {
		&do_log('notice', 'Could not open %s/%s: %s', $queue, $file, $!);
		rename "$queue/$file", "$queue/BAD-$file";
		next;
	    }

	    my (%hash, $from);
	    my $bounce_dir = "$wwsconf->{'bounce_path'}/$list->{'name'}";

	    ## RFC1891 compliance check
	    my $bounce_count = &rfc1891(\*BOUNCE, \%hash, \$from);

	    unless ($bounce_count) {
		close BOUNCE;

		unless (open BOUNCE, "$queue/$file") {
		    &do_log('notice', 'Could not open %s/%s: %s', $queue, $file, $!);
		    rename "$queue/$file", "$queue/BAD-$file";
		    next;
		    }
		
		## Analysis of bounced message
		&anabounce(\*BOUNCE, \%hash, \$from);
	    }

	    close BOUNCE;
	    
	    ## Bounce directory
	    if (! -d $bounce_dir) {
		unless (mkdir $bounce_dir, 0777) {
		    &do_log('notice', 'Could not create %s: %s bounced die, check bounce-path in wwsympa.conf', $bounce_dir, $!);
		    exit;
		} 
	    }
 
	    my $adr_count;
	    ## Bouncing addresses
	    while (my ($rcpt, $status) = each %hash) {
		$adr_count++;

		## Set error message to a status RFC1893 compliant
		if ($status !~ /^\d+\.\d+\.\d+$/) {
		    if ($equiv{$status}) {
			$status = $equiv{$status};
		    }else {
			undef $status;
		    }
		}
		    
		my $escaped_rcpt = $rcpt;
		$escaped_rcpt = &tools::escape_chars($rcpt);
		
		&do_log('debug', 'bouncing address %s in list %s, %s', $rcpt
			, $list->{'name'}, $status);

		## Original message
		unless (open BOUNCE, "$queue/$file") {
		    &do_log('notice', 'Could not open %s/%s: %s', $queue, $file, $!);
		    rename "$queue/$file", "$queue/BAD-$file";
		    next;
		}
		
		unless (open ARC, ">$bounce_dir/$escaped_rcpt") {
		    &do_log('notice', "Unable to write $bounce_dir/$escaped_rcpt");
		    next;
		}
		print ARC <BOUNCE>;
		close BOUNCE;
		close ARC;

		## History
		my $first = my $last = time;
		my $count = 0;
		
		my $user = $list->get_subscriber($rcpt);
		
		unless ($user) {
		    &do_log ('notice', 'Subscriber not found in list %s : %s', $list->{'name'}, $rcpt); 
		    next;
		}

		if ($user->{'bounce'} =~ /^(\d+)\s\d+\s+(\d+)/) {
		    ($first, $count) = ($1, $2);
		}
		$count++;
		
		$list->update_user($rcpt,{'bounce' => "$first $last $count $status"});
	    }
    
	    ## No address found
	    unless ($adr_count) {
		
		my $escaped_from = &tools::escape_chars($from);
		&do_log('info', 'error: no address found in message from %s for list %s',$from, $list->{'name'});
		
		## We keep bounce msg
		if (! -d "$bounce_dir/OTHER") {
		    unless (mkdir  "$bounce_dir/OTHER",0777) {
			&do_log('notice', 'Could not create %s: %s', "$bounce_dir/OTHER", $!);
			next;
		    }
		}
		
		## Original msg
		if (-w "$bounce_dir/OTHER") {
		    unless (open BOUNCE, "$queue/$file") {
			&do_log('notice', 'Could not open %s/%s: %s', $queue, $file, $!);
			rename "$queue/$file", "$queue/BAD-$file";
			next;
			}
		    
		    unless (open ARC, ">$bounce_dir/OTHER/$escaped_from") {
			&do_log('notice', "Cannot create $bounce_dir/OTHER/$escaped_from");
			next;
		    }
		    print ARC <BOUNCE>;
		    close BOUNCE;
		    close ARC;
		}else {
		    &do_log('notice', "Failed to write $bounce_dir/OTHER/$escaped_from");
		}
	    }
	    
	}else {
	    do_log('debug',"Skipping bouncefile $file for unknown list $listname");
	}
	
	unless (unlink("$queue/$file")) {
	    do_log ('notice',"Could not remove $queue/$file ; $0 might NOT be running with the right UID\nRenaming file to $queue/BAD-$file.");
	    rename "$queue/$file", "$queue/BAD-$file";
	    last;
	}
    }

    ## Free zombie sendmail processes
    &smtp::reaper;

}
do_log('notice', 'bounced exited normally due to signal');
unlink("$wwsconf->{'bounced_pidfile'}");

exit(0);


## When we catch SIGTERM, just change the value of the loop
## variable.
sub sigterm {
    $end = 1;
}






















