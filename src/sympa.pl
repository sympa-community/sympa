#! --PERL--

# sympa.pl - This script is the main one ; it runs as a daemon and does
# the messages/commands processing
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

use strict;

use lib '--LIBDIR--';
#use Getopt::Std;
use Getopt::Long;

use Mail::Address;
use File::Path;

use Commands;
use Conf;
use Language;
use Log;
use Version;
use smtp;
use MIME::QuotedPrint;
use List;
use Ldap;
use Message;

require 'tools.pl';
require 'msg.pl';
require 'parser.pl';


# durty global variables
my $is_signed = {}; 
my $is_crypted ;
# log_level is a global var, can be set by sympa.conf, robot.conf, list/config, --log_level or $PATHINFO  


## Internal tuning
# delay between each read of the expirequeue
my $expiresleep = 50 ; 

# delay between each read of the digestqueue
my $digestsleep = 5; 

## Init random engine
srand (time());

my $version_string = "Sympa version is $Version

Try $0 --help for further information about Sympa
";

my $usage_string = "Usage:
   $0 [OPTIONS]

Options:
   -d, --debug         : sets Sympa in debug mode 
   -f, --config=FILE   : uses an alternative configuration file
   --import=list       : import subscribers (read from STDIN)
   -k, --keepcopy=dir  : keep a copy of incoming message
   -l, --lang=LANG     : use a language catalog for Sympa
   -m, --mail          : log calls to sendmail
   --dump=list|ALL     : dumps subscribers 
   --lowercase         : lowercase email addresses in database
   --log_level=LEVEL   : sets Sympa log level

   -h, --help          : print this help
   -v, --version       : print version number

Sympa is a mailinglists manager and comes with a complete (user and admin)
web interface. Sympa  can be linked to an LDAP directory or an RDBMS to 
create dynamic mailing lists. Sympa provides S/MIME and HTTPS based authentication and
encryption.
";

## Check --dump option
my %options;
&GetOptions(\%main::options, 'dump=s', 'debug|d', ,'log_level=s','foreground', 'config|f=s', 
	    'lang|l=s', 'mail|m', 'keepcopy|k=s', 'help', 'version', 'import=s','make_alias_file','lowercase');


if ($main::options{'debug'}) {
    $main::options{'log_level'} = 2 unless ($main::options{'log_level'});
}
# Some option force foreground mode
$main::options{'foreground'} = 1 if ($main::options{'debug'} ||
                                     $main::options{'version'} || 
				     $main::options{'import'} ||
				     $main::options{'help'} || 
				     $main::options{'make_alias_file'} || 
				     $main::options{'lowercase'} || 
				     $main::options{'dump'});

$log_level = $main::options{'log_level'} if ($main::options{'log_level'}); 

my @parser_param = ($*, $/);
my %loop_info;
my %msgid_table;

# this loop is run foreach HUP signal received
my $signal = 0;

while ($signal ne 'term') { #as long as a SIGTERM is not received }

my $config_file = $main::options{'config'} || '--CONFIG--';
## Load configuration file
unless (Conf::load($config_file)) {
   print Msg(1, 1, "Configuration file $config_file has errors.\n");
   exit(1);
}

## Open the syslog and say we're read out stuff.
do_openlog($Conf{'syslog'}, $Conf{'log_socket_type'}, 'sympa');

# setting log_level using conf unless it is set by calling option
if ($main::options{'log_level'}) {
    do_log('info', "Configuration file read, log level set using options : $log_level"); 
}else{
    $log_level = $Conf{'log_level'};
    do_log('info', "Configuration file read, default log level  $log_level"); 
}


## Probe Db if defined
if ($Conf{'db_name'} and $Conf{'db_type'}) {
    unless ($List::use_db = &List::probe_db()) {
	&fatal_err('Database %s defined in sympa.conf has not the right structure or is unreachable. If you don\'t use any database, comment db_xxx parameters in sympa.conf', $Conf{'db_name'});
    }
}

## Apply defaults to %List::pinfo
&List::_apply_defaults();

&tools::ciphersaber_installed();

if (&tools::cookie_changed($Conf{'cookie'})) {
     &fatal_err("sympa.conf/cookie parameter has changed. You may have severe inconsitencies into password storage. Restore previous cookie or write some tool to re-encrypt password in database and check spools contents (look at $Conf{'etc'}/cookies.history file)");
    exit;
}

## Set locale configuration
$main::options{'lang'} =~ s/\.cat$//; ## Compatibility with version < 2.3.3
$Language::default_lang = $main::options{'lang'} || $Conf{'lang'};
&Language::LoadLang($Conf{'msgcat'});

## Check locale version
#if (Msg(1, 102, $Version) ne $Version){
#    &do_log('info', 'NLS message file version %s different from src version %s', Msg(1, 102,""), $Version);
#} 

## Main program
if (!chdir($Conf{'home'})) {
   fatal_err("Can't chdir to %s: %m", $Conf{'home'});
   ## Function never returns.
}

if ($signal ne 'hup' ) {
    ## Put ourselves in background if we're not in debug mode. That method
    ## works on many systems, although, it seems that Unix conceptors have
    ## decided that there won't be a single and easy way to detach a process
    ## from its controlling tty.
    unless ($main::options{'foreground'}) {
	if (open(TTY, "/dev/tty")) {
	    ioctl(TTY, 0x20007471, 0);         # XXX s/b &TIOCNOTTY
	    #       ioctl(TTY, &TIOCNOTTY, 0);
	    close(TTY);
	}
	open(STDIN, ">> /dev/null");
	open(STDERR, ">> /dev/null");
	open(STDOUT, ">> /dev/null");
	setpgrp(0, 0);
	if ((my $child_pid = fork) != 0) {
	    do_log('debug', "Starting server, pid $_");

	    exit(0);
	}
    }
    
    unless ($main::options{'dump'} || $main::options{'help'} ||
	    $main::options{'version'} || $main::options{'import'} || $main::options{'make_alias_file'} ||
	    $main::options{'lowercase'} ) {
	## Create and write the pidfile
	&tools::write_pid($Conf{'pidfile'}, $$);
    }	

    do_openlog($Conf{'syslog'}, $Conf{'log_socket_type'}, 'sympa');

    # Set the UserID & GroupID for the process
    $( = $) = (getgrnam('--GROUP--'))[2];
    $< = $> = (getpwnam('--USER--'))[2];

    # Sets the UMASK
    umask(oct($Conf{'umask'}));

 ## Most initializations have now been done.
    do_log('notice', "Sympa $Version started");
    printf "Sympa $Version started\n";
}else{
    do_log('notice', "Sympa $Version reload config");
    printf "Sympa $Version reload config\n";
    $signal = '0';
}

## Check for several files.
unless (&Conf::checkfiles()) {
   fatal_err("Missing files. Aborting.");
   ## No return.
}

## Daemon called for dumping subscribers list
if ($main::options{'dump'}) {
    
    my @listnames;
    if ($main::options{'dump'} eq 'ALL') {
	@listnames = &List::get_lists('*');
    }else {
	@listnames = ($main::options{'dump'});
    }

    &List::dump(@listnames);

    exit 0;
}elsif ($main::options{'help'}) {
    print $usage_string;
    exit 0;
}elsif ($main::options{'make_alias_file'}) {
    my @listnames = &List::get_lists('*');
    unless (open TMP, ">/tmp/sympa_aliases.$$") {
	printf STDERR "Unable to create tmp/sympa_aliases.$$, exiting\n";
	exit;
    }
    printf TMP "#\n#\tAliases for all Sympa lists (but not for robots)\n#\n";
    close TMP;
    foreach my $listname (@listnames) {
	if (my $list = new List ($listname)) {

	    system ("--SBINDIR--/alias_manager.pl add $list->{'name'} $list->{'domain'} /tmp/sympa_aliases.$$") ;
	}	
    }
    printf ("Sympa aliases file is /tmp/sympa_aliases.$$ file made, you probably need to installed it in your SMTP engine\n");
    
    exit 0;
}elsif ($main::options{'version'}) {
    print $version_string;
    
    exit 0;
}elsif ($main::options{'import'}) {
    my ($list, $total);
    unless ($list = new List ($main::options{'import'})) {
	fatal_err('Unknown list name %s', $main::options{'import'});
    }

    ## Read imported data from STDIN
    while (<STDIN>) {
	next if /^\s*$/;
	next if /^\s*\#/;

	unless (/^\s*((\S+|\".*\")@\S+)(\s*(\S.*))?\s*$/) {
	    printf STDERR "Not an email address: %s\n", $_;
	}

	my $email = lc($1);
	my $gecos = $4;
	my $u;
	my $defaults = $list->get_default_user_options();
	%{$u} = %{$defaults};
	$u->{'email'} = $email;
	$u->{'gecos'} = $gecos;

	unless ($list->add_user($u)) {
	    printf STDERR "\nCould not add %s\n", $email;
	    next;
	}
	print STDERR '+';
	
	$total++;	
    }
    
    printf STDERR "Total imported subscribers: %d\n", $total;

    exit 0;
}elsif ($main::options{'lowercase'}) {
    
    unless ($List::use_db) {
	&fatal_err("You don't have a database setup, can't lowercase email addresses");
    }

    print STDERR "Working on user_table...\n";
    my $total = &List::lowercase_field('user_table', 'email_user');

    print STDERR "Working on subscriber_table...\n";
    $total += &List::lowercase_field('subscriber_table', 'user_subscriber');

    unless (defined $total) {
	&fatal_err("Could not work on dabatase");
    }

    printf STDERR "Total lowercased rows: %d\n", $total;

    exit 0;
}

## Do we have right access in the directory
if ($main::options{'keepcopy'}) {
    if (! -d $main::options{'keepcopy'}) {
	&do_log('notice', 'Cannot keep a copy of incoming messages : %s is not a directory', $main::options{'keepcopy'});
	delete $main::options{'keepcopy'};
    }elsif (! -w $main::options{'keepcopy'}) {
	&do_log('notice','Cannot keep a copy of incoming messages : no write access to %s', $main::options{'keepcopy'});
	delete $main::options{'keepcopy'};
    }
}

## Catch SIGTERM, in order to exit cleanly, whenever possible.
$SIG{'TERM'} = 'sigterm';
$SIG{'HUP'} = 'sighup';

my $index_queuedigest = 0; # verify the digest queue
my $index_queueexpire = 0; # verify the expire queue
my $index_cleanqueue = 0; 
my @qfile;

## This is the main loop : look after files in the directory, handles
## them, sleeps a while and continues the good job.
while (!$signal) {

    # setting log_level using conf unless it is set by calling option
    unless ($main::options{'log_level'}) {
	$log_level = $Conf{'log_level'};
	# do_log('notice', "Reset default log level  $log_level"); 
    }
    

    &Language::SetLang($Language::default_lang);

    &List::init_list_cache();

    if (!opendir(DIR, $Conf{'queue'})) {
	fatal_err("Can't open dir %s: %m", $Conf{'queue'}); ## No return.
    }
    @qfile = sort grep (!/^\./,readdir(DIR));
    closedir(DIR);
    
    ## Scan queuedigest
    if ($index_queuedigest++ >=$digestsleep){
	$index_queuedigest=0;
	&SendDigest();
    }
    ## Scan the queueexpire
    if ($index_queueexpire++ >=$expiresleep){
	$index_queueexpire=0;
	&ProcessExpire();
    }

    ## Clean queue (bad)
    if ($index_cleanqueue++ >= 100){
	$index_cleanqueue=0;
	&CleanSpool("$Conf{'queue'}/bad", $Conf{'clean_delay_queue'});
	&CleanSpool($Conf{'queuemod'}, $Conf{'clean_delay_queuemod'});
	&CleanSpool($Conf{'queueauth'}, $Conf{'clean_delay_queueauth'});
    }

    my $filename;
    my $listname;
    my $robot;

    my $highest_priority = 'z'; ## lowest priority
    
    ## Scans files in queue
    ## Search file with highest priority
    foreach my $t_filename (sort @qfile) {
	my $priority;
	my $type;
	my $list;
	my ($t_listname, $t_robot);

	# trying to fix a bug (perl bug ??) of solaris version
	($*, $/) = @parser_param;

	## test ever if it is an old bad file
	if ($t_filename =~ /^BAD\-/i){
	    if ((stat "$Conf{'queue'}/$t_filename")[9] < (time - $Conf{'clean_delay_queue'}*86400) ){
		unlink ("$Conf{'queue'}/$t_filename") ;
		do_log('notice',"Deleting bad message %s because too old", $t_filename);
	    };
	    next;
	}

	## z and Z are a null priority, so file stay in queue and are processed
	## only if renamed by administrator
	next unless ($t_filename =~ /^(\S+)\.\d+\.\d+$/);

	## Don't process temporary files created by queue (T.xxx)
	next if ($t_filename =~ /^T\./);

	($t_listname, $t_robot) = split(/\@/,$1);
	
	$t_listname = lc($t_listname);
	if ($t_robot) {
	    $t_robot=lc($t_robot);
	}else{
	    $t_robot = lc($Conf{'host'});
	}

	my $list_check_regexp = &Conf::get_robot_conf($robot,'list_check_regexp');

	if ($t_listname =~ /^(\S+)-($list_check_regexp)$/) {
	    ($t_listname, $type) = ($1, $2);
	}

	# (sa) le terme "(\@$Conf{'host'})?" est inutile
	unless ($t_listname =~ /^(sympa|listmaster|$Conf{'email'})(\@$Conf{'host'})?$/i) {
	    $list = new List ($t_listname);
	}
	
	if ($t_listname eq 'listmaster') {
	    ## highest priority
	    $priority = 0;
	}elsif ($type eq 'request') {
	    $priority = $Conf{'request_priority'};
	}elsif ($type eq 'owner') {
	    $priority = $Conf{'owner_priority'};
	}elsif ($t_listname =~ /^(sympa|$Conf{'email'})(\@$Conf{'host'})?$/i) {	
	    $priority = $Conf{'sympa_priority'};
	}else {
	    if ($list) {
		$priority = $list->{'admin'}{'priority'};
	    }else {
		$priority = $Conf{'default_list_priority'};
	    }
	}
	
	if (ord($priority) < ord($highest_priority)) {
	    $highest_priority = $priority;
	    $filename = $t_filename;
	}
    } ## END of spool lookup

    &smtp::reaper;

    unless ($filename) {
	sleep($Conf{'sleep'});
	next;
    }

    do_log('debug', "Processing %s with priority %s", "$Conf{'queue'}/$filename", $highest_priority) ;
    
    if ($main::options{'mail'} != 1) {
	$main::options{'mail'} = $robot if ($Conf{'robots'}{$robot}{'log_smtp'});
	$main::options{'mail'} = $robot if ($Conf{'log_smtp'});
    }

    ## Set NLS default lang for current message
    $Language::default_lang = $main::options{'lang'} || &Conf::get_robot_conf($robot, 'lang');

    my $status = &DoFile("$Conf{'queue'}/$filename");
    
    if (defined($status)) {
	do_log('debug', "Finished %s", "$Conf{'queue'}/$filename") ;

	if ($main::options{'keepcopy'}) {
	    unless (rename "$Conf{'queue'}/$filename", $main::options{'keepcopy'}."/$filename") {
		do_log('notice', 'Could not rename %s to %s: %s', "$Conf{'queue'}/$filename", $main::options{'keepcopy'}."/$filename", $!);
		unlink("$Conf{'queue'}/$filename");
	    }
	}else {
	    unlink("$Conf{'queue'}/$filename");
	}
    }else {
	my $bad_dir = "$Conf{'queue'}/bad";

	if (-d $bad_dir) {
	    unless (rename("$Conf{'queue'}/$filename", "$bad_dir/$filename")){
		do_log('err', "Exiting, unable to rename bad file %s to %s (check directory permission)", $filename, "$bad_dir/$filename");
		exit;
	    }
	    do_log('notice', "Moving bad file %s to bad/", $filename);
	}else{
	    do_log('notice', "Missing directory '%s'", $bad_dir);
	    unless (rename("$Conf{'queue'}/$filename", "$Conf{'queue'}/BAD-$filename")) {
		do_log('err', "Exiting, unable to rename bad file %s to BAD-%s", $filename, $filename);
		exit;		
	    }
	    do_log('notice', "Renaming bad file %s to BAD-%s", $filename, $filename);
	}
	
    }

} ## END of infinite loop

## Dump of User files in DB
#List::dump();

## Disconnect from Database
List::db_disconnect if ($List::dbh);

} #end of block while ($signal ne 'term'){

do_log('notice', 'Sympa exited normally due to signal');
unless (unlink $Conf{'pidfile'}) {
    fatal_err("Could not delete %s, exiting", $Conf{'pidfile'});
    ## No return.
}
exit(0);

## When we catch SIGTERM, just change the value of the loop
## variable.
sub sigterm {
    do_log('notice', 'signal TERM received, still processing current task');
    $signal = 'term';
}

## When we catch SIGHUP, just change the value of the loop
## variable.
sub sighup {
    if ($main::options{'mail'}) {
	do_log('notice', 'signal HUP received, switch of the "-mail" logging option and continue current task');
	undef $main::options{'mail'};
    }else{
	do_log('notice', 'signal HUP received, switch on the "-mail" logging option and continue current task');
	$main::options{'mail'} = 1;
    }
    $signal = 'hup';
}

## Handles a file received and files in the queue directory. This will
## read the file, separate the header and the body of the message and
## call the adequate function wether we have received a command or a
## message to be redistributed to a list.
sub DoFile {
    my ($file) = @_;
    &do_log('debug', 'DoFile(%s)', $file);
    
    my ($listname, $robot);
    my $status;

    my $message = new Message($file);
    unless (defined $message) {
	do_log('err', 'Unable to create Message object %s', $file);
	return undef;
    }
    
    open TMP, ">/tmp/dump";
    $message->dump(\*TMP);
    close TMP;

    my $msg = $message->{'msg'};
    my $hdr = $msg->head;
    my $rcpt = $message->{'rcpt'};
    
    # message prepared by wwsympa and distributed by sympa
    if ( $hdr->get('X-Sympa-Checksum')) {
	return (&DoSendMessage ($msg)) ;
    }

    ## get listname & robot
    ($listname, $robot) = split(/\@/,$rcpt);

    $robot = lc($robot);
    $listname = lc($listname);
    $robot ||= $Conf{'host'};
    
    # setting log_level using conf unless it is set by calling option
    unless ($main::options{'log_level'}) {
	$log_level = $Conf{'robots'}{$robot}{'log_level'};
	do_log('debug', "Setting log level with $robot configuration (or sympa.conf) : $log_level"); 
    }

    ## Ignoring messages with no sender
    my $sender = $message->{'sender'};
    unless ($sender) {
	do_log('err', 'No From found in message, skipping.');
	return undef;
    }

    ## Strip of the initial X-Sympa-To field
    $hdr->delete('X-Sympa-To');
    
    ## Loop prevention
    my $conf_email = &Conf::get_robot_conf($robot, 'email');
    my $conf_host = &Conf::get_robot_conf($robot, 'host');
    if ($sender =~ /^(mailer-daemon|sympa|listserv|mailman|majordomo|smartlist|$conf_email)(\@|$)/mio) {
	do_log('notice','Ignoring message which would cause a loop, sent by %s', $sender);
	return undef;
    }
	
    ## Initialize command report
    undef @msg::report;  
    
    ## Q- and B-decode subject
    my $subject_field = &MIME::Words::decode_mimewords($hdr->get('Subject'));
    chomp $subject_field;
#    $hdr->replace('Subject', $subject_field);
        
    my ($list, $host, $name);   
    if ($listname =~ /^(sympa|listmaster|$conf_email)(\@$conf_host)?$/i) {
	$host = $conf_host;
	$name = $listname;
    }else {
	$list = new List ($listname);
	$host = $list->{'admin'}{'host'};
	$name = $list->{'name'};
	# setting log_level using list config unless it is set by calling option
	unless ($main::options{'log_level'}) {
	    $log_level = $list->{'log_level'};
	    do_log('debug', "Setting log level with list configuration : $log_level"); 
	}
    }
    
    ## Loop prevention
    my $loop;
    foreach $loop ($hdr->get('X-Loop')) {
	chomp $loop;
	&do_log('debug2','X-Loop: %s', $loop);
	#foreach my $l (split(/[\s,]+/, lc($loop))) {
	    if ($loop eq lc("$name\@$host")) {
		do_log('notice', "Ignoring message which would cause a loop (X-Loop: $loop)");
		return undef;
	    }
	#}
    }
    
    ## Content-Identifier: Auto-replied is generated by some non standard 
    ## X400 mailer
    if ($hdr->get('Content-Identifier') =~ /Auto-replied/i) {
	do_log('notice', "Ignoring message which would cause a loop (Content-Identifier: Auto-replied)");
	return undef;
    }elsif ($hdr->get('X400-Content-Identifier') =~ /Auto Reply to/i) {
	do_log('notice', "Ignoring message which would cause a loop (X400-Content-Identifier: Auto Reply to)");
	return undef;
    }

    ## encrypted message
    if ($message->{'smime_crypted'}) {
	$is_crypted = 'smime_crypted';
	$file = '_ALTERED_';
	($msg, $file) = ($message->{'decrypted_msg'}, $message->{'decrypted_msg_as_string'});
	unless (defined($msg)) {
	    do_log('debug','unable to decrypt message');
	    ## xxxxx traitement d'erreur ?
	    return undef;
	};
	$hdr = $msg->head;
	do_log('debug2', "message successfully decrypted");
    }else {
	$is_crypted = 'not_crypted';
    }

    ## S/MIME signed messages
    if ($message->{'smime_signed'}) {
	$is_signed = {'subject' => $message->{'smime_subject'},
		      'body' => 'smime'};
    }else {
	undef $is_signed;
    }


    if ($rcpt =~ /^listmaster(\@(\S+))?$/) {
	$status = &DoForward('sympa', 'listmaster', $robot, $msg, $file, $sender);

	## Mail adressed to the robot and mail 
	## to <list>-subscribe or <list>-unsubscribe are commands
    }elsif (($rcpt =~ /^(sympa|$conf_email)(\@\S+)?$/i) || ($rcpt =~ /^(\S+)-(subscribe|unsubscribe)(\@(\S+))?$/o)) {
	$status = &DoCommand($rcpt, $robot, $msg, $file);
	
	## forward mails to <list>-request <list>-owner etc
    }elsif ($rcpt =~ /^(\S+)-(request|owner|editor)(\@(\S+))?$/o) {
	my ($name, $function) = ($1, $2);
	
	## Simulate Smartlist behaviour with command in subject
        ## xxxxxxxxxxx  ÅÈtendre le jeu de command reconnue sous cette forme ?
        ## 
	if (($function eq 'request') and ($subject_field =~ /^\s*(subscribe|unsubscribe)(\s*$name)?\s*$/i) ) {
	    my $command = $1;
	    
	    $status = &DoCommand("$name-$command", $robot, $msg, $file);
	}else {
	    $status = &DoForward($name, $function, $robot, $msg, $file, $sender);
	}       
    }else {
	$status =  &DoMessage($rcpt, $message, $robot);
    }
    

    ## Mail back the result.
    if (@msg::report) {

	## Loop prevention

	## Count reports sent to $sender
	$loop_info{$sender}{'count'}++;
	
	## Sampling delay 
	if ((time - $loop_info{$sender}{'date_init'}) < $Conf{'loop_command_sampling_delay'}) {

	    ## Notify listmaster of first rejection
	    if ($loop_info{$sender}{'count'} == $Conf{'loop_command_max'}) {
		## Notify listmaster
		&List::send_notify_to_listmaster('loop_command', $robot, $file);
	    }
	    
	    ## Too many reports sent => message skipped !!
	    if ($loop_info{$sender}{'count'} >= $Conf{'loop_command_max'}) {
		&do_log('notice', 'Ignoring message which would cause a loop, %d messages sent to %s', $loop_info{$sender}{'count'}, $sender);
		
		return undef;
	    }
	}else {
	    ## Sampling delay is over, reinit
	    $loop_info{$sender}{'date_init'} = time;

	    ## We apply Decrease factor if a loop occured
	    $loop_info{$sender}{'count'} *= $Conf{'loop_command_decrease_factor'};
	}

	## Prepare the reply message
	my $reply_hdr = new Mail::Header;
#	$reply_hdr->add('From', sprintf Msg(12, 4, 'SYMPA <%s>'), $Conf{'sympa'});
	$reply_hdr->add('From', sprintf Msg(12, 4, 'SYMPA <%s>'), &Conf::get_robot_conf($robot, 'sympa'));
	$reply_hdr->add('To', $sender);
	$reply_hdr->add('Subject', Msg(4, 17, 'Output of your commands'));
	$reply_hdr->add('X-Loop', &Conf::get_robot_conf($robot, 'sympa'));
	$reply_hdr->add('MIME-Version', Msg(12, 1, '1.0'));
	$reply_hdr->add('Content-type', sprintf 'text/plain; charset=%s', 
			Msg(12, 2, 'us-ascii'));
	$reply_hdr->add('Content-Transfer-Encoding', Msg(12, 3, '7bit'));
	
	## Open the SMTP process for the response to the command.
	*FH = &smtp::smtpto(&Conf::get_robot_conf($robot, 'request'), \$sender);
	$reply_hdr->print(\*FH);
	
	foreach (@msg::report) {
	    print FH;
	}
	
	print FH "\n";

	close(FH);
    }
    
    return $status;
}

## send a message as prepared by wwsympa
sub DoSendMessage {
    my $msg = shift;
    &do_log('debug', 'DoSendMessage()');

    my $hdr = $msg->head;
    
    my ($chksum, $rcpt, $from) = ($hdr->get('X-Sympa-Checksum'), $hdr->get('X-Sympa-To'), $hdr->get('X-Sympa-From'));
    chomp $rcpt; chomp $chksum; chomp $from;

    do_log('info', "Processing web message for %s", $rcpt);

    unless ($chksum eq &tools::sympa_checksum($rcpt)) {
	&do_log('notice', 'Message ignored because incorrect checksum');
	return undef ;
    }

    $hdr->delete('X-Sympa-Checksum');
    $hdr->delete('X-Sympa-To');
    
    ## Multiple recepients
    my @rcpts = split /,/,$rcpt;
    
    *MSG = &smtp::smtpto($from,\@rcpts); 
    $msg->print(\*MSG);
    close (MSG);

    do_log('info', "Message for %s sent", $rcpt);

    return 1;
}

## Handles a message sent to [list]-editor, [list]-owner or [list]-request
sub DoForward {
    my($name, $function, $robot, $msg, $file, $sender) = @_;
    &do_log('debug', 'DoForward(%s, %s, %s, %s)', $name, $function, $file, $sender);

    my $hdr = $msg->head;
    my $messageid = $hdr->get('Message-Id');

    ##  Search for the list
    my ($list, $admin, $host, $recepient, $priority);

    if ($function eq 'listmaster') {
	$recepient="$function";
	$host = &Conf::get_robot_conf($robot, 'host');
	$priority = 0;
    }else {
	unless ($list = new List ($name)) {
	    do_log('notice', "Message for %s-%s ignored, unknown list %s",$name, $function, $name );
	    return undef;
	}
	
	$admin = $list->{'admin'};
	$host = $admin->{'host'};
        $recepient="$name-$function";
	$priority = $admin->{'priority'};
    }

    my @rcpt;
    
    do_log('info', "Processing message for %s with priority %s, %s", $recepient, $priority, $messageid );
    
    $hdr->add('X-Loop', "$name-$function\@$host");
    $hdr->delete('X-Sympa-To:');

    if ($function eq "listmaster") {
	my $listmasters = &Conf::get_robot_conf($robot, 'listmasters');
	@rcpt = @{$listmasters};
	do_log('notice', 'Warning : no listmaster defined in sympa.conf') 
	    unless (@rcpt);
	
    }elsif ($function eq "request") {
	@rcpt = $list->get_owners_email();

	do_log('notice', 'Warning : no owner defined or all of them use nomail option in list %s', $name ) 
	    unless (@rcpt);

    }elsif ($function eq "editor") {
	foreach my $i (@{$admin->{'editor'}}) {
	    next if ($i->{'reception'} eq 'nomail');
	    push(@rcpt, $i->{'email'}) if ($i->{'email'});
	}
	unless (@rcpt) {
	    do_log('notice', 'No editor defined in list %s (unless they use NOMAIL), use owners', $name ) ;
	    @rcpt = $list->get_owners_email();
	}
    }
    
    if ($#rcpt < 0) {
	do_log('notice', "Message for %s-%s ignored, %s undefined in list %s", $name, $function, $function, $name);
	return undef;
    }
   
    my $rc;
    my $msg_copy = $msg->dup;

    if ($rc = &tools::virus_infected($msg_copy, $file)) {
	if ($Conf{'antivirus_notify'} eq 'sender') {
	    if ($list) {
		$list->send_file('your_infected_msg', $sender, $robot, 
				 {'virus_name' => $rc,
				  'recipient' => $recepient.'@'.$host,
				  'lang' => $list->{'admin'}{'lang'}});
	    }
	    else {
		my %context;
		$context{'virus_name'} = $rc ;
		$context{'recipient'} = $recepient.'@'.$host;
		$context{'lang'} = &Conf::get_robot_conf($robot, 'lang');
		&List::send_global_file('your_infected_msg', $sender, $robot, \%context );
	    }    
	}
	&do_log('notice', "Message for %s\@%s from %s ignored, virus %s found", $recepient, $host, $sender, $rc);

	return undef;
    }else{
 
	*SIZ = smtp::smtpto(&Conf::get_robot_conf($robot, 'request'), \@rcpt);
	$msg->print(\*SIZ);
	close(SIZ);
	
	do_log('info',"Message for %s forwarded", $recepient);
    }
    return 1;
}


## Handles a message sent to a list.
sub DoMessage{
    my($which, $message, $robot) = @_;
    my ($msg, $file, $bytes) = ($message->{'msg'}, $message->{'filename'}, $message->{'size'});
    my $encrypt;
    $encrypt = 'smime_crypted' if ($message->{'smime_crypted'});
    &do_log('debug', 'DoMessage(%s, %s, %s, msg from %s, %s, %s,%s)', $which, $msg, $robot, $msg->head->get('From'), $bytes, $file, $encrypt);
    
    ## List and host.
    my($listname, $host) = split(/[@\s]+/, $which);

    my $hdr = $msg->head;
    
    my $from_field = $hdr->get('From');
    my $messageid = $hdr->get('Message-Id');

    my @sender_hdr = Mail::Address->parse($from_field);

    my $sender = $sender_hdr[0]->address || '';

    ## Search for the list
    my $list = new List ($listname);
 
    ## List unknown
    unless ($list) {
	&do_log('notice', 'Unknown list %s', $listname);
	&List::send_global_file('list_unknown', $sender, $robot,
				{'list' => $which,
				 'date' => &POSIX::strftime("%d %b %Y  %H:%M", localtime(time)),
				 'boundary' => &Conf::get_robot_conf($robot, 'sympa').time,
				 'header' => $hdr->as_string()
				});
	return undef;
    }
    
    my ($name, $host) = ($list->{'name'}, $list->{'admin'}{'host'});

    my $start_time = time;
    
    &Language::SetLang($list->{'admin'}{'lang'});

    ## Now check if the sender is an authorized address.

    do_log('info', "Processing message for %s with priority %s, %s", $name,$list->{'admin'}{'priority'}, $messageid );
    
    my $conf_email = &Conf::get_robot_conf($robot, 'sympa');
    if ($sender =~ /^(mailer-daemon|sympa|listserv|majordomo|smartlist|mailman|$conf_email)(\@|$)/mio) {
	do_log('notice', 'Ignoring message which would cause a loop');
	return undef;
    }

    if ($msgid_table{$listname}{$messageid}) {
	do_log('notice', 'Found known Message-ID, ignoring message which would cause a loop');
	return undef;
    }
    
    # Reject messages with commands
    if ($Conf{'misaddressed_commands'} =~ /reject/i) {
	## Check the message for commands and catch them.
	if (tools::checkcommand($msg, $sender, $robot)) {
	    &do_log('notice', 'Found command in message, ignoring message');
	    
	    return undef;
	}
    }

    my $admin = $list->{'admin'};
    return undef unless $admin;
    
    my $customheader = $admin->{'custom_header'};
#    $host = $admin->{'host'} if ($admin->{'host'});

    ## Check if the message is a return receipt
    if ($hdr->get('multipart/report')) {
	do_log('notice', 'Message for %s from %s ignored because it is a report', $name, $sender);
	return undef;
    }
    
    ## Check if the message is too large
    my $max_size = $list->get_max_size() || $Conf{'max_size'};
    if ($max_size && $bytes > $max_size) {
	do_log('notice', 'Message for %s from %s too large (%d > %d)', $name, $sender, $bytes, $max_size);
	*SIZ  = smtp::smtpto(&Conf::get_robot_conf($robot, 'request'), \$sender);
	print SIZ "From: " . sprintf (Msg(12, 4, 'SYMPA <%s>'), &Conf::get_robot_conf($robot, 'request')) . "\n";
	printf SIZ "To: %s\n", $sender;
	printf SIZ "Subject: " . Msg(4, 11, "Your message for list %s has been rejected") . "\n", $name;
	printf SIZ "MIME-Version: %s\n", Msg(12, 1, '1.0');
	printf SIZ "Content-Type: text/plain; charset=%s\n", Msg(12, 2, 'us-ascii');
	printf SIZ "Content-Transfer-Encoding: %s\n\n", Msg(12, 3, '7bit');
	print SIZ Msg(4, 12, $msg::msg_too_large);
	$msg->print(\*SIZ);
	close(SIZ);
	return undef;
    }
    
    my $rc;
   
    if ($rc= &tools::virus_infected($msg, $file)) {
	printf "do message, virus= $rc \n";
	$list->send_file('your_infected_msg', $sender, $robot, {'virus_name' => $rc,
							'recipient' => $name.'@'.$host,
							'lang' => $list->{'admin'}{'lang'}});
	&do_log('notice', "Message for %s\@%s from %s ignored, virus %s found", $name, $host, $sender, $rc);
	return undef;
    }
    
    ## Call scenarii : auth_method MD5 do not have any sense in send
    ## scenarii because auth is perfom by distribute or reject command.
    
    my $action ;
    if ($is_signed->{'body'}) {
	$action = &List::request_action ('send', 'smime',$robot,
					 {'listname' => $name,
					  'sender' => $sender,
					  'msg' => $msg });
    }else{
	$action = &List::request_action ('send', 'smtp',$robot,
					 {'listname' => $name,
					  'sender' => $sender,
					  'msg' => $msg });
    }

    return undef
	unless (defined $action);

    if ($action =~ /^do_it/) {
	
	my $numsmtp = $list->distribute_msg($msg, $bytes, $file, $encrypt);

	$msgid_table{$listname}{$messageid}++;
	
	unless (defined($numsmtp)) {
	    do_log('info','Unable to send message to list %s', $name);
	    return undef;
	}

	do_log('info', 'Message for %s from %s accepted (%d seconds, %d sessions), size=%d', $name, $sender, time - $start_time, $numsmtp, $bytes);
	
	## Everything went fine, return TRUE in order to remove the file from
	## the queue.
	return 1;
    }elsif($action =~ /^request_auth/){
    	my $key = $list->send_auth($message);
	do_log('notice', 'Message for %s from %s kept for authentication with key %s', $name, $sender, $key);
	return 1;
    }elsif($action =~ /^editorkey(\s?,\s?(quiet))?/){
	my $key = $list->send_to_editor('md5',$message);
	do_log('info', 'Key %s for list %s from %s sent to editors, %s', $key, $name, $sender, $file, $encrypt);
	$list->notify_sender($sender) unless ($2 eq 'quiet');
	return 1;
    }elsif($action =~ /^editor(\s?,\s?(quiet))?/){
	my $key = $list->send_to_editor('smtp', $message);
	do_log('info', 'Message for %s from %s sent to editors', $name, $sender);
	$list->notify_sender($sender) unless ($2 eq 'quiet');
	return 1;
    }elsif($action =~ /^reject(\(\'?(\w+)\'?\))?(\s?,\s?(quiet))?/) {
	my $tpl = $2;
	do_log('notice', 'Message for %s from %s rejected(%s) because sender not allowed', $name, $sender, $tpl);
	unless ($4 eq 'quiet') {
	    if ($tpl) {
		$list->send_file($tpl, $sender, $robot, {});
	    }else {
		*SIZ  = smtp::smtpto(&Conf::get_robot_conf($robot, 'request'), \$sender);
		print SIZ "From: " . sprintf (Msg(12, 4, 'SYMPA <%s>'), &Conf::get_robot_conf($robot, 'request')) . "\n";
		printf SIZ "To: %s\n", $sender;
		printf SIZ "Subject: " . Msg(4, 11, "Your message for list %s has been rejected")."\n", $name ;
		printf SIZ "MIME-Version: %s\n", Msg(12, 1, '1.0');
		printf SIZ "Content-Type: text/plain; charset=%s\n", Msg(12, 2, 'us-ascii');
		printf SIZ "Content-Transfer-Encoding: %s\n\n", Msg(12, 3, '7bit');
		printf SIZ Msg(4, 15, $msg::list_is_private), $name;
		$msg->print(\*SIZ);
		close(SIZ);
	    }
	}
	return undef;
    }
}

## Handles a message sent to a list.

## Handles a command sent to the list manager.
sub DoCommand {
    my($rcpt, $robot, $msg, $file) = @_;
    &do_log('debug', 'DoCommand(%s %s %s %s) ', $rcpt, $robot, $msg, $file);

    ## Now check if the sender is an authorized address.
    my $hdr = $msg->head;
    
    ## Decode headers
    $hdr->decode();
    
    my $from_field = $hdr->get('From');
    my $messageid = $hdr->get('Message-Id');
    my ($success, $status);
    
    do_log('debug', "Processing command with priority %s, %s", $Conf{'sympa_priority'}, $messageid );
    
    my @sender_hdr = Mail::Address->parse($from_field);
    my $sender = $sender_hdr[0]->address;

    ## Detect loops
    if ($msgid_table{$robot}{$messageid}) {
	do_log('notice', 'Found known Message-ID, ignoring command which would cause a loop');
	return undef;
    }
    $msgid_table{$robot}{$messageid}++;

    ## If X-Sympa-To = <listname>-<subscribe|unsubscribe> parse as a unique command
    if ($rcpt =~ /^(\S+)-(subscribe|unsubscribe)(\@(\S+))?$/o) {
	do_log('debug',"processing message for $1-$2");
	&Commands::parse($sender,$robot,"$2 $1");
	return 1; 
    }
    
    ## Process the Subject of the message
    ## Search and process a command in the Subject field
    my $subject_field = $hdr->get('Subject');
    chomp $subject_field;
    $subject_field =~ s/\n//mg; ## multiline subjects
    $subject_field =~ s/^\s*(Re:)?\s*(.*)\s*$/$2/i;

    $success ||= &Commands::parse($sender, $robot, $subject_field, $is_signed->{'subject'}) ;

    ## Make multipart singlepart
    my $loops;
    while ($msg->is_multipart()) {
	$loops++;
	if (&tools::as_singlepart($msg, 'text/plain')) {
	    do_log('notice', 'Multipart message changed to singlepart');
	}
	if ($loops > 2) {
	    do_log('notice', 'Could not change multipart to singlepart');
	    return undef;
	}
    }

    ## check Content-type
    my $mime = $hdr->get('Mime-Version') ;
    my $content_type = $hdr->get('Content-type');
    my $transfert_encoding = $hdr->get('Content-transfer-encoding');
    
    unless (($content_type =~ /text/i and !$mime)
	    or !($content_type) 
	    or ($content_type =~ /text\/plain/i)) {
	do_log('notice', "Ignoring message body not in text/plain, Content-type: %s", $content_type);
	print Msg(4, 37, "Ignoring message body not in text/plain, please use text/plain only \n(or put your command in the subject).\n");
	
	return $success;
    }
        
    my @msgexpire;
    my ($expire, $i);
    my $size;

    ## Process the body of the message
    ## unless subject contained commands or message has no body
    unless (($success == 1) || (! defined $msg->bodyhandle)) { 
#	foreach $i (@{$msg->body}) {
	my @body = $msg->bodyhandle->as_lines();
	foreach $i (@body) {
	    if ($transfert_encoding =~ /quoted-printable/i) {
		$i = MIME::QuotedPrint::decode($i);
	    }
	    if ($expire){
		if ($i =~ /^(quit|end|stop)/io){
		    last;
		}
		# store the expire message in @msgexpire
		push(@msgexpire, $i);
		next;
	    }
	    $i =~ s/^\s*>?\s*(.*)\s*$/$1/g;
	    next if ($i =~ /^$/); ## skip empty lines
	    
	    # exception in the case of command expire
	    if ($i =~ /^exp(ire)?\s/i){
		$expire = $i;
		print "> $i\n\n";
		next;
	    }
	    
	    push @msg::report, "> $i\n\n";
	    $size = $#msg::report;
	    

	    if ($i =~ /^(quit|end|stop|--)/io) {
		last;
	    }
	    &do_log('debug2',"is_signed->body $is_signed->{'body'}");

	    unless ($status = Commands::parse($sender, $robot, $i, $is_signed->{'body'})) {
		push @msg::report, sprintf Msg(4, 19, "Command not understood: ignoring end of message.\n");
		last;
	    }

	    if ($#msg::report > $size) {
		## There is a command report
		push @msg::report, "\n";
	    }else {
		## No command report
		pop @msg::report;
	    }
	    
	    $success ||= $status;
	}
	pop @msg::report unless ($#msg::report > $size);
    }

    ## No command found
    unless ($success == 1) {
	## No status => no command
	unless (defined $success) {
	    do_log('info', "No command found in message");
	    push @msg::report, sprintf Msg(4, 39, "No command found in message");
	}
	return undef;
    }
    
    # processing the expire function
    if ($expire){
	print STDERR "expire\n";
	unless (&Commands::parse($sender, $robot, $expire, @msgexpire)) {
	    print Msg(4, 19, "Command not understood: ignoring end of message.\n");
	}
    }

    return $success;
}

## Read the queue and send old digests to the subscribers with the digest option.
sub SendDigest{
    &do_log('debug', 'SendDigest()');

    if (!opendir(DIR, $Conf{'queuedigest'})) {
	fatal_err(Msg(3, 1, "Can't open dir %s: %m"), $Conf{'queuedigest'}); ## No return.
    }
    my @dfile =( sort grep (!/^\./,readdir(DIR)));
    closedir(DIR);


    foreach my $listname (@dfile){

	my $filename = $Conf{'queuedigest'}.'/'.$listname;

	my $list = new List ($listname);
	unless ($list) {
	    &do_log('info', 'Unknown list, deleting digest file %s', $filename);
	    unlink $filename;
	    return undef;
	}

	&Language::SetLang($list->{'admin'}{'lang'});

	if ($list->get_nextdigest()){
	    ## Blindly send the message to all users.
	    do_log('info', "Sending digest to list %s", $listname);
	    my $start_time = time;
	    $list->send_msg_digest();

	    unlink($filename);
	    do_log('info', 'Digest of the list %s sent (%d seconds)', $listname,time - $start_time);
	}
    }
}


## Read the EXPIRE queue and check if a process has ended
sub ProcessExpire{
    &do_log('debug', 'ProcessExpire()');

    my $edir = $Conf{'queueexpire'};
    if (!opendir(DIR, $edir)) {
	fatal_err("Can't open dir %s: %m", $edir); ## No return.
    }
    my @dfile =( sort grep (!/^\./,readdir(DIR)));
    closedir(DIR);
    my ($d1, $d2, $proprio, $user);

    foreach my $expire (@dfile) {
#   while ($expire=<@dfile>){	
	## Parse the expire configuration file
	if (!open(IN, "$edir/$expire")) {
	    next;
	}
	if (<IN> =~ /^(\d+)\s+(\d+)$/) {
	    $d1=$1;
	    $d2=$2;
	}	

	if (<IN>=~/^(.*)$/){
	    $proprio=$1; 
	}
	close(IN);

	## Is the EXPIRE process finished ?
	if ($d2 <= time){
	    my $list = new List ($expire);
	    my $listname = $list->{'name'};
	    unless ($list){
		unlink("$edir/$expire");
		next;
	    };
	
	    ## Prepare the reply message
	    my $reply_hdr = new Mail::Header;
	    $reply_hdr->add('From', sprintf Msg(12, 4, 'SYMPA <%s>'), $Conf{'sympa'});
	    $reply_hdr->add('To', $proprio);
 	    $reply_hdr->add('Subject',sprintf( Msg(4, 24, 'End of your command EXPIRE on list %s'),$expire));

	    $reply_hdr->add('MIME-Version', Msg(12, 1, '1.0'));
	    my $content_type = 'text/plain; charset='.Msg(12, 2, 'us-ascii');
	    $reply_hdr->add('Content-type', $content_type);
	    $reply_hdr->add('Content-Transfer-Encoding', Msg(12, 3, '7bit'));

	    ## Open the SMTP process for the response to the command.
	    *FH = &smtp::smtpto($Conf{'request'}, \$proprio);
	    $reply_hdr->print(\*FH);
	    my $fh = select(FH);
	    my $limitday=$d1;
	    #converting dates.....
	    $d1= int((time-$d1)/86400);
	    #$d2= int(($d2-time)/86400);
	
	    my $cpt_badboys;
	    ## Amount of unconfirmed subscription

	    unless ($user = $list->get_first_user()) {
		return undef;
}

	    while ($user = $list->get_next_user()) {
		$cpt_badboys++ if ($user->{'date'} < $limitday);
	    }

	    ## Message to the owner who launched the expire command
	    printf Msg(4, 28, "Among the subscribers of list %s for %d days, %d did not confirm their subscription.\n"), $listname, $d1, $cpt_badboys;
	    print "\n";
	    printf Msg(4, 26, "Subscribers who do not have confirm their subscription:\n");	
	    print "\n";
	
	    my $temp=0;

	    unless ($user = $list->get_first_user()) {
		return undef;
	    }

	    while ($user = $list->get_next_user()) {
		next unless ($user->{'date'} < $limitday);
		print "," if ($temp == 1);
		print " $user->{'email'} ";
		$temp=1 if ($temp == 0);
	    }
	    print "\n\n";
	    printf Msg(4, 27, "You must delete these subscribers from this list with the following commands :\n");
	    print "\n";

	    unless ($user = $list->get_first_user()) {
		return undef;
	    }
	    while ($user = $list->get_next_user()) {
		next unless ($user->{'date'} < $limitday);
		print "DEL   $listname   $user->{'email'}\n";
	    }
	    ## Mail back the result.
	    select($fh);
	    close(FH);
	    unlink("$edir/$expire");
	    next;
	}
    }
}

## Clean old files from spool
sub CleanSpool {
    my ($spool_dir, $clean_delay) = @_;
    &do_log('debug', 'CleanSpool(%s,%s)', $spool_dir, $clean_delay);

    unless (opendir(DIR, $spool_dir)) {
	do_log('err', "Unable to open '%s' spool : %s", $spool_dir, $!);
	return undef;
    }

    my @qfile = sort grep (!/^\.+$/,readdir(DIR));
    closedir DIR;
    
    my ($curlist,$moddelay);
    foreach my $f (sort @qfile) {

	if ((stat "$spool_dir/$f")[9] < (time - $clean_delay * 60 * 60 * 24)) {
	    if (-f "$spool_dir/$f") {
		unlink ("$spool_dir/$f") ;
		do_log('notice', 'Deleting old file %s', "$spool_dir/$f");
	    }elsif (-d "$spool_dir/$f") {
		unless (opendir(DIR, "$spool_dir/$f")) {
		    &do_log('err', 'Cannot open directory %s : %s', "$spool_dir/$f", $!);
		    next;
		}
		my @files = sort grep (!/^\./,readdir(DIR));
		foreach my $file (@files) {
		    unlink ("$spool_dir/$f/$file");
		}	
		closedir DIR;
		
		rmdir ("$spool_dir/$f") ;
		do_log('notice', 'Deleting old directory %s', "$spool_dir/$f");
	    }
	}
    }

    return 1;
}

1;


