#!--PERL--

# archived.pl - This script does the web archives building for Sympa
# RCS Identication ; $Revision: 4985 $ ; $Date: 2008-05-02 12:06:27 +0200 (Fri, 02 May 2008) $ 
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

## Options :  F         -> do not detach TTY
##         :  d		-> debug -d is equiv to -dF
## Now, it is impossible to use -dF but you have to write it -d -F

=pod 

=head1 NAME 

I<bulk.pl> - Daemon for submitting to smtp engine bulkmailer_table content.

=head1 DESCRIPTION 

This script must be run along with sympa. It regularly checks the bulkmailer_table content and submit the messages it finds in it to the sendmail engine. Several deamon should be used on deferent server for hugue traffic.

=cut 

## Change this to point to your Sympa bin directory
use lib '--LIBDIR--';

use Conf;
use Log;
use Commands;
use Getopt::Long;

use mail;
use Version;
use Bulk;
use List;

require 'tools.pl';

my $daemon_name = &Log::set_daemon($0);
my $creation_date = time();
local $main::daemon_usage = 'DAEMON_MASTER'; ## Default is to launch bulk as master daemon.

## Check options
##  --debug : sets the debug mode
##  --foreground : prevents the script from beeing daemonized
##  --mail : logs every sendmail calls
my %options;
unless (&GetOptions(\%main::options, 'debug|d', 'foreground|F','mail|m')) {
    &fatal_err("Unknown options.");
}

if ($main::options{'debug'}) {
    $main::options{'log_level'} = 2 unless ($main::options{'log_level'});
}

$main::options{'foreground'} = 1 if ($main::options{'debug'});
$main::options{'log_to_stderr'} = 1 if ($main::options{'debug'} || $main::options{'foreground'});

$sympa_conf_file = '--CONFIG--';

# Load sympa.conf
unless (Conf::load($sympa_conf_file)) {
    &fatal_err("Unable to load sympa configuration, file $sympa_conf_file has errors.");
}

## Check database connectivity
unless (&List::check_db_connect()) {
    &fatal_err('Database %s defined in sympa.conf has not the right structure or is unreachable.', $Conf::Conf{'db_name'});
}

do_openlog($Conf::Conf{'syslog'}, $Conf::Conf{'log_socket_type'}, 'bulk');

# setting log_level using conf unless it is set by calling option
if ($main::options{'log_level'}) {
    &Log::set_log_level($main::options{'log_level'});
    do_log('info', "Configuration file read, log level set using options : $main::options{'log_level'}"); 
}else{
    &Log::set_log_level($Conf::Conf{'log_level'});
    do_log('info', "Configuration file read, default log level $Conf::Conf{'log_level'}"); 
}

## Set the process as main bulk daemon by default.
my $is_main_bulk = 0;

if (-f $Conf::Conf{'pidfile_bulk'}){
    my $p_count = &tools::get_number_of_pids($Conf::Conf{'pidfile_bulk'});
    if ($p_count > 0) {
	fatal_err('Some process identifiers remain in %s. Please make sure another bulk is not already running.', $pidfile);	    
    }
}

## Put ourselves in background if not in debug mode. 
unless ($main::options{'debug'} || $main::options{'foreground'}) {
   open(STDERR, ">> /dev/null");
   open(STDOUT, ">> /dev/null");
   if (open(TTY, "/dev/tty")) {
      ioctl(TTY, $TIOCNOTTY, 0);
      close(TTY);
   }
   setpgrp(0, 0);
   if ((my $child_pid = fork) != 0) {
       do_log('info',"Starting bulk master daemon, pid %s",$child_pid);
       exit(0);
   }
}
do_openlog($Conf::Conf{'syslog'}, $Conf::Conf{'log_socket_type'}, 'bulk');
## If process is running in foreground, don't write STDERR to a dedicated file
my $options;
$options->{'stderr_to_tty'} = 1 if ($main::options{'foreground'});
$options->{'multiple_process'} = 1;

# Saves the pid number
&tools::write_pid($Conf::Conf{'pidfile_bulk'}, $$, $options);

## Set the UserID & GroupID for the process
$( = $) = (getgrnam('--GROUP--'))[2];
$< = $> = (getpwnam('--USER--'))[2];

## Required on FreeBSD to change ALL IDs(effective UID + real UID + saved UID)
&POSIX::setuid((getpwnam('--USER--'))[2]);
&POSIX::setgid((getgrnam('--GROUP--'))[2]);

## Check if the UID has correctly been set (usefull on OS X)
unless (($( == (getgrnam('--GROUP--'))[2]) && ($< == (getpwnam('--USER--'))[2])) {
    &fatal_err("Failed to change process userID and groupID. Note that on some OS Perl scripts can't change their real UID. In such circumstances Sympa should be run via SUDO.");
}

## Sets the UMASK
umask(oct($Conf::Conf{'umask'}));

## Change to list root
unless (chdir($Conf::Conf{'home'})) {
    &do_log('err','unable to change directory');
    exit (-1);
}

my $pinfo = &List::_apply_defaults();

do_log('notice', "bulkd $Version::Version Started");


## Catch SIGTERM, in order to exit cleanly, whenever possible.
$SIG{'TERM'} = 'sigterm';
$end = 0;

my $opensmtp = 0 ;
my $fh = 'fh0000000000';	## File handle for the stream.

my $messagekey;       # the key of the current message in the message_table   
my $messageasstring;  # the current message as a string

my $timeout = $Conf::Conf{'bulk_wait_to_fork'};
my $last_check_date = time();

while (!$end) {
    my $bulk;
    ## Create slave bulks if too much packets are waiting to be sent in the bulk_mailer table.
    if (($main::daemon_usage eq 'DAEMON_MASTER') && (time() - $last_check_date > $timeout)){
	if((my $r_packets = &Bulk::there_is_too_much_remaining_packets()) && !(&tools::get_number_of_pids($Conf::Conf{'pidfile_bulk'}) > 1)){
	    if($Conf::Conf{'bulk_max_count'} > 1) {
		&do_log('info','Too much packets in spool (%s). Creating %s slave bulks to increase sending rate.', $r_packets, $Conf::Conf{'bulk_max_count'}-1);
		for my $process_count(1..$Conf::Conf{'bulk_max_count'}-1){
		    if ((my $child_pid = fork) != 0) {
			do_openlog($Conf::Conf{'syslog'}, $Conf::Conf{'log_socket_type'}, 'bulk');
			do_log('info', "Starting bulk slave daemon, pid %s", $child_pid);
			$creation_date = time();
                        # Saves the pid number
			&tools::write_pid($Conf::Conf{'pidfile_bulk'}, $$, $options);
		    }else{
			## We're in a slave bulk process
			$main::daemon_usage = 'DAEMON_SLAVE'; # automatic lists creation
			last;
		    }
		}
	    }
	}
	$last_check_date = time();
    }
    ## If a slave bulk process is running for long enough, stop it (if the number of remaining packets to send is reasonnable).
    if (($main::daemon_usage eq 'DAEMON_SLAVE') && (time() - $creation_date > $Conf::Conf{'bulk_ttl'}) && !(my $r_packets = &Bulk::there_is_too_much_remaining_packets())){
	&do_log('info', "Process %s too old, exiting.", $$);
	last;
    }
    if ($bulk = Bulk::next()) {
	if ($bulk->{'messagekey'} ne $messagekey) {
	    # current packet is no related to the same message as the previous packet
            # so it is needed to fetch the new message from message_table 
	    $messageasstring = &Bulk::messageasstring($bulk->{'messagekey'});
	    unless ( $messageasstring ) {
		&do_log('err',"internal error : current packet 'messagekey= %s contain a ref to a null message",$bulk->{'messagekey'});
	    }
	}
	my @rcpts = split /,/,$bulk->{'receipients'};
	if ($bulk->{'verp'}){   
	    foreach my $rcpt (@rcpts) {
		$return_path = $rcpt;
		$return_path =~ s/\@/\=\=a\=\=/; 
		$return_path = "$Conf::Conf{'bounce_email_prefix'}+$return_path\=\=$bulk->{'listname'}\@$bulk->{'robot'}"; # xxxxxxxxxxxxx verp cassé si pas de listename (message de sympa
		*SMTP = &mail::smtpto($return_path, \$rcpt, $bulk->{'robot'});
		print SMTP $messageasstring;
		close SMTP;
	    }

	}else{
	    *SMTP = &mail::smtpto($bulk->{'returnpath'}, \@rcpts, $bulk->{'robot'});
	    print SMTP $messageasstring;
	    close SMTP;
	}
	&Bulk::remove($bulk->{'messagekey'},$bulk->{'packetid'});
    }else{
	sleep 1; # scan bulk_mailer table every 1 second waiting for some new packets
    }
    &mail::reaper;
}
do_log('notice', 'bulkd exited normally due to signal');
&tools::remove_pid($Conf::Conf{'pidfile_bulk'}, $$, $options);

exit(0);


## When we catch SIGTERM, just change the value of the loop
## variable.
sub sigterm {
    $end = 1;
}

