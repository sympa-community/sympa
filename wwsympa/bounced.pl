#!--PERL--

## Worl Wide Sympa is a front-end to Sympa Mailing Lists Manager
## Copyright Comite Reseau des Universites


## Options :  F         -> do not detach TTY
##         :  d		-> debug -d is equiv to -dF

## Change this to point to your Sympa bin directory
use lib '--BINDIR--';
use FileHandle;

use List;
use Conf;
use Log;
use smtp;
use Getopt::Std;
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
	      "insufficient system storage" => '4.2.2');


require "--BINDIR--/bounce-lib.pl";
require "--BINDIR--/wws-lib.pl";

getopts('dF');

$wwsympa_conf = "--WWSCONFIG--";
$sympa_conf_file = '--CONFIG--';

$wwsconf = {};

# Load WWSympa configuration
unless ($wwsconf = &load_config($wwsympa_conf)) {
    print STDERR 'unable to load config file';
    exit;
}

# Load sympa.conf
unless (Conf::load($sympa_conf_file)) {
    do_log  ('notice',"Unable to load sympa configuration, file $sympa_conf_file has errors.");
    exit(1);
}

unshift @INC, $wwsconf->{'wws_path'};
$wwsconf->{'log_facility'}||= $Conf{'syslog'};
do_openlog($wwsconf->{'log_facility'}, $Conf{'log_socket_type'}, 'bounced');

## Check databse connectivity
unless ($List::use_db = &List::probe_db()) {
    print STDERR "Sympa not setup to use DBI, unable to manage bounces\n";
    exit (-1);
}

## Set the UserID & GroupID for the process
$< = $> = (getpwnam('--USER--'))[2];
$( = $) = (getpwnam('--GROUP--'))[2];

## Put ourselves in background if not in debug mode. 
unless ($opt_d || $opt_F) {
    open(STDERR, ">> /dev/null");
    open(STDOUT, ">> /dev/null");
    if (open(TTY, "/dev/tty")) {
	ioctl(TTY, $TIOCNOTTY, 0);
	close(TTY);
    }
    setpgrp(0, 0);
    if (($_ = fork) != 0) {
	do_log('debug', "Starting bounce daemon, pid $_");
	exit(0);
    }
}

## Sets the UMASK
umask($Conf{'umask'});

## Change to list root
unless (chdir($Conf{'home'})) {
    &message('chdir_error');
    &do_log('info','Unable to change directory');
    exit (-1);
}

my $pinfo = &List::_apply_defaults();

## Create and write the pidfile
unless (open(LOCK, "+>> $wwsconf->{'bounced_pidfile'}")) {
    fatal_err("Could not open %s, exiting", $wwsconf->{'bounced_pidfile'});
}
unless (flock(LOCK, 6)) {
    printf STDERR "Could not lock %s: bounced is probably already running",$wwsconf->{'bounced_pidfile'} ;
    fatal_err("Could not lock %s: bounced is probably already running.", $wwsconf->{'bounced_pidfile'});
}
unless (open(LCK, "> $wwsconf->{'bounced_pidfile'}")) {
    fatal_err("Could not open %s, exiting", $wwsconf->{'bounced_pidfile'});
}
unless (truncate(LCK, 0)) {
    fatal_err("Could not truncate %s, exiting.", $wwsconf->{'bounced_pidfile'});
}

print LCK "$$\n";
close(LCK);

do_log('notice', "bounced Started");


## Catch SIGTERM, in order to exit cleanly, whenever possible.
$SIG{'TERM'} = 'sigterm';
$end = 0;


$queue = $Conf{'queuebounce'};

## infinite loop scanning the queue (unless a sig TERM is received
while (!$end) {
    ## this sleep is important to be raisonably sure that sympa is not currently
    ## writting the file this deamon is openning. 
    
    sleep 2;
    
    &List::init_list_cache();

    unless (opendir(DIR, $queue)) {
	fatal_err("Can't open dir %s: %m", $queue); ## No return.
    }

    my @files =  (sort grep(!/^(\.{1,2}|T\..*)$/, readdir DIR ));
    closedir DIR;
    foreach my $file (@files) {
	
	unless ($file =~ /^(\S+)\.\d+\.\d+$/) {
	    my @s = stat("$queue/$file");
	    if (POSIX::S_ISREG($s[2])) {
		do_log ('notice',"Ignoring file $queue/$file because unknown format");
	        unlink("$queue/$file");
	    }
	    next;
	}
	
	my $listname = $1;

	if ($listname eq 'sympa') {
	    ## In this case return-path should has been set by sympa
            ## in order to recognize a welcome message bounce
	    open BOUNCE, "$queue/$file";
#            my $parser = new MIME::Parser output_dir     => '/tmp', output_to_core => 'ALL';
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
		my $action =&List::request_action ('del','smtp',
					{'listname' =>$listname,
					 'sender' => $Conf{'listmasters'}[0],
					 'email' => $who});

#                    &List::get_action ('del', $listname, $Conf{'listmasters'}[0], 'smtp');

		if ($action =~ /do_it/i) {
		    if ($list->is_user($who)) {
			my $u = $list->delete_user($who);
			$list->save();
			do_log ('notice',"$who has been removed from $listname because welcome message bounced");
			
			$list->send_notify_to_owner($who, "", 'automatic_del', 'listmaster');
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
	    open BOUNCE, "$queue/$file";

	    my %hash;
	    my $bounce_dir = "$wwsconf->{'bounce_path'}/$list->{'name'}";

	    ## RFC1891 compliance check
	    my $bounce_count = &rfc1891(\*BOUNCE, \%hash, \$from);

	    unless ($bounce_count) {
		close BOUNCE;
		open BOUNCE, "$queue/$file";
		
		## Analysis of bounced message
		&anabounce(BOUNCE, \%hash, \$from);
	    }

	    close BOUNCE;
	    
	    ## Bounce directory
	    if (! -d $bounce_dir) {
		mkdir $bounce_dir, 0777 or die "Cannot create $bounce_dir";
		chmod 0777, $bounce_dir;
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
		open BOUNCE, "$queue/$file";
		
		open ARC, ">$bounce_dir/$escaped_rcpt" or &leave("archiving bounce");
		print ARC <BOUNCE>;
		close BOUNCE;
		close ARC;
		chmod 0777, "$bounce_dir/$escaped_rcpt";

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
		
		&do_log('info', 'error: no address found in message from %s for list %s',$from, $list->{'name'});
		
		## We keep bounce msg
		if (! -d "$bounce_dir/OTHER") {
		    mkdir  "$bounce_dir/OTHER",0777 or &leave("creating $bounce_dir/OTHER");
		    chmod 0777,"$bounce_dir/OTHER";
		}
		
		## Original msg
		if (-w "$bounce_dir/OTHER") {
		    open BOUNCE, "$queue/$file";
		    open ARC, ">$bounce_dir/OTHER/$from" or &leave();
		    print ARC <BOUNCE>;
		    close BOUNCE;
		    close ARC;
		    chmod 0777, '$bounce_dir/OTHER/$from';
		}else {
		    &do_log('notice', "Failed to write $bounce_dir/OTHER/$from");
		}
	    }
	    
	}else {
	    do_log('debug',"Skipping bouncefile $file for unknown list $listname");
	}
	
	unless (unlink("$queue/$file")) {
	    do_log ('notice',"Ignoring file $queue/$file because couldn't remove it, bounced.pl must use the same uid as sympa");
	    do_log ('notice',"exiting because I don't want to loop until file system is full");
	    last;
	}
    }
}
do_log('notice', 'bounced exited normally due to signal');
unlink("$wwsconf->{'bounced_pidfile'}");

exit(0);


## When we catch SIGTERM, just change the value of the loop
## variable.
sub sigterm {
    $end = 1;
}

sub process_bounce {

}

sub leave() {
    my $msg = shift(@_);

    die "Errorr : $msg";
}





















