#!--PERL--

# archived.pl - This script does the web archives building for Sympa
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

## Options :  F         -> do not detach TTY
##         :  d		-> debug -d is equiv to -dF
## Now, it is impossible to use -dF but you have to write it -d -F

## Change this to point to your Sympa bin directory
use lib '--LIBDIR--';

use List;
use Conf;
use Log;
use Commands;
#use Getopt::Std;
use Getopt::Long;
use Language;
use Digest::MD5;

use wwslib;
use mail;
use Version;

require 'tt2.pl';
require 'tools.pl';

my $daemon_name = &Log::set_daemon($0);
my $ip = $ENV{'REMOTE_HOST'};

#getopts('dF');

## Check options
my %options;
&GetOptions(\%main::options, 'debug|d', 'foreground|F');

if ($main::options{'debug'}) {
    $main::options{'log_level'} = 2 unless ($main::options{'log_level'});
}

$main::options{'foreground'} = 1 if ($main::options{'debug'});
$main::options{'log_to_stderr'} = 1 if ($main::options{'debug'} || $main::options{'foreground'});

$wwsympa_conf = "--WWSCONFIG--";
$sympa_conf_file = '--CONFIG--';

$wwsconf = {};
$adrlist = {};

# Load WWSympa configuration
unless ($wwsconf = &wwslib::load_config($wwsympa_conf)) {
    print STDERR 'unable to load config file';
    exit;
}

# Load sympa.conf
unless (Conf::load($sympa_conf_file)) {
    &fatal_err("Unable to load sympa configuration, file $sympa_conf_file has errors.");
}

## Create arc_path if required
if ($wwsconf->{'arc_path'}) {
    unless (-d $wwsconf->{'arc_path'}) {
	printf STDERR "Creating missing %s directory\n", $wwsconf->{'arc_path'};
	mkdir $wwsconf->{'arc_path'}, 0775;
	chown '--USER--', '--GROUP--', $wwsconf->{'arc_path'};
    }
}

## Check databse connectivity
unless ($List::use_db = &List::check_db_connect()) {
    &fatal_err('Database %s defined in sympa.conf has not the right structure or is unreachable. If you don\'t use any database, comment db_xxx parameters in sympa.conf', $Conf{'db_name'});
}

## Check databse connectivity
unless ($List::use_db = &List::check_db_connect()) {
    &fatal_err('Database %s defined in sympa.conf has not the right structure or is unreachable. If you don\'t use any database, comment db_xxx parameters in sympa.conf', $Conf{'db_name'});
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
      print STDOUT "Starting archive daemon, pid $_\n";

      exit(0);
   }
}

## Create and write the pidfile
&tools::write_pid($wwsconf->{'archived_pidfile'}, $$);

$log_level = $main::options{'log_level'} || $Conf{'log_level'};

$wwsconf->{'log_facility'}||= $Conf{'syslog'};
do_openlog($wwsconf->{'log_facility'}, $Conf{'log_socket_type'}, 'archived');

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
umask(oct($Conf{'umask'}));

## Check access to arc_path 
unless ((-r $wwsconf->{'arc_path'}) && (-w $wwsconf->{'arc_path'})) {
    do_log('err', 'Unsufficient access to %s directory', $wwsconf->{'arc_path'});
}

## Change to list root
unless (chdir($Conf{'home'})) {
    &do_log('err','unable to change directory');
    exit (-1);
}

my $pinfo = &List::_apply_defaults();

$Language::default_lang = $Conf{'lang'};

do_log('notice', "archived $Version::Version Started");


## Catch SIGTERM, in order to exit cleanly, whenever possible.
$SIG{'TERM'} = 'sigterm';
$end = 0;


$queue = $Conf{'queueoutgoing'};
print "queue : $queue\n";

#if (!chdir($queue)) {
#   fatal_err("Can't chdir to %s: %m", $queue);
#   ## Function never returns.
#}

## infinite loop scanning the queue (unless a sig TERM is received
while (!$end) {

    &List::init_list_cache();
    
   unless (opendir(DIR, $queue)) {
       fatal_err("Can't open dir %s: %m", $queue); ## No return.
   }

   my @files =  (grep(!/^\.{1,2}$/, readdir DIR ));
   closedir DIR;

   ## this sleep is important to be raisonably sure that sympa is not currently
   ## writting the file this deamon is openning. 
   sleep 6;

   foreach my $file (@files) {

       last if $end;

       if ($file  =~ /^\.remove\.((.*)\.(\d\d\d\d\-\d\d))\.\d+$/ ) {
	   my $arclistdir = $1;
	   my $listadress = $2;
	   my $yyyymm = $3;
	   my $arcpath = "$wwsconf->{'arc_path'}/$listadress/$yyyymm";

	   do_log('debug',"start remove process :listadress :'$listadress' arclistdir '$arclistdir' arcpath '$arcpath'  yyyymm '$yyyymm'");
	  
	   my $list;
	   unless ($list = new List ($listadress)) {
	       do_log('err',"remove : unknown list $listadress");
	       next;
	   }

	   do_log('debug',"remove found : $file for list $yyyymm");

	   unless (open REMOVE, "$queue/$file") {
	        do_log ('err',"Ignoring file $queue/$file because couldn't read it, archived.pl must use the same uid as sympa");
		   next;
	       }

	   my $email_regexp = &tools::get_regexp('email');

	   foreach my $removeorder (<REMOVE>) { 
	       unless($removeorder =~ /(.*)\|\|($email_regexp)/){
		   do_log ('err',"Ignoring remove_order $removeorder not recognized format");   
		   next;
	       }
	       my $msgid = $1;
	       my $sender = $2;

	       chomp 	$msgid ;
	       if ($msgid =~ /NO-ID-FOUND\.mhonarc\.org/) {
		   do_log('err','remove_arc: no message id found');
		   next;
	       } 

	       my $message ;
	       unless ($message = &Archive::search_msgid("$arcpath/arctxt",$msgid)){
		   do_log('err','No message with message-id %s found in %s',$msgid,$arcpath);
		   next;
	       }

	       unless ($list->am_i('privileged_owner',$sender)|| $list->am_i('owner',$sender)||$list->am_i('editor', $sender)||&List::is_listmaster($sender,$list->{'domain'} )){
		   # if not list owner or list editor or listmaster,n check if sender of remove order is sender of the message to remove

		   unless (my $new_message = new Message("$arcpath/arctxt/$message",'noxsympato')) {
		        do_log('err',"unable to load new message $arcpath/arctxt/$message");
			next;
		   }
		   my $messagesender = $new_message->{'sender'};
		   lc($messagesender);

		   unless ($sender == $messagesender) {
		       &do_log('err', 'remove command by unauthorized sender');
		       return undef;
		   }
	       }
	       # this point : requested command is from a authorized personn (message sender or list admin or listmaster

	       &remove($arclistdir,$msgid);

	       my $url_dir = $list->{'dir'}.'/urlized/'.$msgid;
	       &tools::remove_dir ($url_dir);

	       unless (-d "$arcpath/deleted"){
		   # do_log('info',"xxxxxxxxxxxxxxxxxxxxxxx  $arcpath/deleted");
		   unless (mkdir ("$arcpath/deleted",0777)) {
		       do_log('info',"remove_arc: unable to create $arcpath/deleted : $!");
		       last;
		   }
	       }

	       unless (rename ("$arcpath/arctxt/$message","$arcpath/deleted/$message")) {
		   do_log('info',"remove_arc: unable to rename message $arcpath/arctxt/$message");
		   next;
	       }
			       
	       # remove directory if empty arctxt
	       unless (opendir (DIR,"$arcpath/arctxt")) {
		   do_log('info',"remove_arc: unable to open dir $arcpath/arctxt");
		   next;
	       }
	       # do_log('info',"xxxxxxxxxxxxxxxxxxxxxxx  test emptydir");
	       my @files = grep(/^\d+$/, readdir( DIR ));
	       closedir (DIR);
	       if ($#files == -1) {
		   # do_log('info','remove_dir   xxxxxxxxxxxxxxxxxxx %s',$arcpath);
		   &tools::remove_dir ($arcpath); 
	       }else{			
		   # do_log('info', "xxxxxxxxxxxxxxxxxxx $arcpath/arctxt not empty");
	       }
	   }
	   close REMOVE;

	   unless (unlink("$queue/$file")) {
	       do_log ('err',"Ignoring file $queue/$file because couldn't remove it, archived.pl must use the same uid as sympa");
	       next;
	   }
	   
       }elsif ($file  =~ /^\.rebuild\.(.*)$/ ) {
	   do_log('debug',"rebuild found : $file for list $1");
	   &rebuild($1);	
	   unless (unlink("$queue/$file")) {
	       do_log ('err',"Ignoring file $queue/$file because couldn't remove it, archived.pl must use the same uid as sympa");
	       next;
	   }
       }else{
	   my ($yyyy, $mm, $dd, $min, $ss, $adrlist);
	   
	   if ($file =~ /^(\d{4})-(\d{2})-(\d{2})-(\d{2})-(\d{2})-(\d{2})-(.*)$/) {
	       ($yyyy, $mm, $dd, $hh, $min, $ss, $adrlist) = ($1, $2, $3, $4, $5, $6, $7);
	   }elsif (($file =~ /^(.*)\.(\d+)\.(\d+)\.(\d+)$/) || ($file =~ /^(.*)\.(\d+)\.(\d+)$/)) {
	       $adrlist = $1;
	       my $date = $2;

	       my @now = localtime($date);
	       $yyyy = sprintf '%04d', 1900+$now[5];
	       $mm = sprintf '%02d', $now[4]+1;
	       $dd = sprintf '%02d', $now[3];
	       $hh = sprintf '%02d', $now[2];
	       $min = sprintf '%02d', $now[1];
	       $ss = sprintf '%02d', $now[0];
	       
	   }else {
	       do_log ('err',"Ignoring file $queue/$file because not to be rebuid or liste archive");
               unlink("$queue/$file");
	       next;
	   }
	   
	   my ($listname, $hostname);
	   if ($adrlist =~ /^(.*)\@(.*)$/) {
	       $listname = $1;
	       $hostname = $2;
	   }else {
	       &do_log('err',"Match of list address '$adrlist' failed");
	       return undef;
	   }

	   do_log('notice',"Archiving $file for list $adrlist");      
	   mail2arc ($file, $listname, $hostname, $yyyy, $mm, $dd, $hh, $min, $ss) ;
	   unless (unlink("$queue/$file")) {
	       do_log ('err',"Ignoring file $queue/$file because couldn't remove it, archived.pl must use the same uid as sympa");
	       do_log ('err',"exiting because I don't want to loop until file system is full");
	       last;
	   }
       }
   }
}
do_log('notice', 'archived exited normally due to signal');
&tools::remove_pid($wwsconf->{'archived_pidfile'}, $$);

exit(0);


## When we catch SIGTERM, just change the value of the loop
## variable.
sub sigterm {
    $end = 1;
}

sub remove {
    my $adrlist = shift;
    my $msgid = shift;

    do_log ('debug2',"remove ($adrlist, $msgid)");
    my $arc ;

    if ($adrlist =~ /^(.*)\.(\d{4}-\d{2})$/) {
	$adrlist = $1;
        $arc = $2;
    }

    do_log('notice',"Removing $msgid in list $adrlist section $2");
    unless(&Log::db_log({'robot' => $robot,'list' => $adrlist,'action' => 'remove','parameters' => $msgid.','.$adrlist,'target_email' => '','msg_id' => $msgid,'status' => 'succes','error_type' => '','user_email' =>'','client' => $ip,'daemon' => $daemon_name})) {
	&do_log('error','archived::remove: unable to log event');
    }
  
    $arc =~ /^(\d{4})-(\d{2})$/ ;
    my $yyyy = $1 ;
    my $mm = $2 ;
    
    $msgid =~ s/\$/\\\$/g;
    system "$wwsconf->{'mhonarc'}  -outdir $wwsconf->{'arc_path'}/$adrlist/$yyyy-$mm -rmm $msgid";
}

sub rebuild {

    my $adrlist = shift;
    my $arc ;

    do_log ('debug2',"rebuild ($adrlist)");

    if ($adrlist =~ /^(.*)\.(\d{4}-\d{2})$/) {
	$adrlist = $1;
        $arc = $2;
    }

    my ($listname, $hostname);
    if ($adrlist =~ /^(.*)\@(.*)$/) {
	$listname = $1;
	$hostname = $2;
    }else {
	&do_log('err',"Match of list address '$adrlist' failed");
	       return undef;
    }

    my $tag = &get_tag($listname);

    my $list = new List($listname, $hostname);

    do_log('debug',"Rebuilding $adrlist archive ($2)");

    my $mhonarc_ressources = &tools::get_filename('etc',{},'mhonarc-ressources.tt2',$list->{'domain'}, $list);

    if (($list->{'admin'}{'web_archive_spam_protection'} ne 'none') && ($list->{'admin'}{'web_archive_spam_protection'} ne 'cookie')) {
	&set_hidden_mode($tag);
    }else {
	&unset_hidden_mode();
    }

    do_log('notice','Rebuilding  $arc with M2H_ADDRESSMODIFYCODE : %s',$ENV{'M2H_ADDRESSMODIFYCODE'});

    if ($arc) {
        do_log('notice',"Rebuilding  $arc of $adrlist archive");
	$arc =~ /^(\d{4})-(\d{2})$/ ;
	my $yyyy = $1 ;
	my $mm = $2 ;

	# remove empty directory
	my $arcdir = $wwsconf->{'arc_path'}.'/'.$adrlist.'/'.$yyyy.'-'.$mm ;
	my $arctxt = $arcdir.'/arctxt' ;
	if (opendir (DIR,$arctxt)) {
	    my @files = (grep /^\d+$/,(readdir DIR ));
	    close (DIR);
	    if ($#files == -1) { 
		do_log('notice', "Removing empty directory $arcdir");
		&tools::remove_dir ($arcdir);
		next ;	 
	    } 
	}

	## Remove .mhonarc.db
	unlink $wwsconf->{'arc_path'}.'/'.$adrlist.'/'.$yyyy.'-'.$mm.'/.mhonarc.db';
	
	## Remove existing HTML files
	opendir HTML, "$wwsconf->{'arc_path'}/$adrlist/$yyyy-$mm";
	
	## Skip arctxt/ . and ..
	foreach my $html_file (grep !/^arctxt$|^index$|\.+$/, readdir(HTML)) {
	    unlink $wwsconf->{'arc_path'}.'/'.$adrlist.'/'.$yyyy.'-'.$mm.'/'.$html_file;
	}	
	closedir HTML;

	my $cmd = "$wwsconf->{'mhonarc'} -modifybodyaddresses -addressmodifycode \'$ENV{'M2H_ADDRESSMODIFYCODE'}\' -rcfile $mhonarc_ressources -outdir $wwsconf->{'arc_path'}/$adrlist/$yyyy-$mm  -definevars \"listname='$listname' hostname=$hostname yyyy=$yyyy mois=$mm yyyymm=$yyyy-$mm wdir=$wwsconf->{'arc_path'} base=$Conf{'wwsympa_url'}/arc tag=$tag\" -umask $Conf{'umask'} $wwsconf->{'arc_path'}/$adrlist/$arc/arctxt";

	do_log('debug',"System call : $cmd");
	my $exitcode = system($cmd);
	$exitcode = $exitcode / 256;

	## Remove lock if required
	if ($exitcode == 75) {
	    &do_log('notice', 'Removing lock directory %s', $wwsconf->{'arc_path'}.'/'.$adrlist.'/'.$arc.'/.mhonarc.lck');
	    rmdir $wwsconf->{'arc_path'}.'/'.$adrlist.'/'.$arc.'/.mhonarc.lck';

	    $exitcode = system($cmd);
	    $exitcode = $exitcode / 256;	    
	}

	if ($exitcode) {
	    do_log('err',"Command $cmd failed with exit code $exitcode");
	}
    }else{
        do_log('notice',"Rebuilding $adrlist archive completely");

	if (!opendir(DIR, "$wwsconf->{'arc_path'}/$adrlist" )) {
	    do_log('err',"unable to open $wwsconf->{'arc_path'}/$adrlist to rebuild archive");
	    return ;
	}
	my @archives = (grep (/^\d{4}-\d{2}/, readdir(DIR)));
	close DIR ; 

	foreach my $arc (@archives) {
	    $arc =~ /^(\d{4})-(\d{2})$/ ;
	    my $yyyy = $1 ;
	    my $mm = $2 ;

	    ## Remove .mhonarc.db
	    unlink $wwsconf->{'arc_path'}.'/'.$adrlist.'/'.$yyyy.'-'.$mm.'/.mhonarc.db';
	    
	    ## Remove existing HTML files
	    opendir HTML, "$wwsconf->{'arc_path'}/$adrlist/$yyyy-$mm";
	    ## Skip arctxt/ . and ..
	    foreach my $html_file (grep !/^arctxt$|^index$|\.+$/, readdir(HTML)) {
		unlink $wwsconf->{'arc_path'}.'/'.$adrlist.'/'.$yyyy.'-'.$mm.'/'.$html_file;
	    }	
	    closedir HTML;	

	    my $cmd = "$wwsconf->{'mhonarc'} -modifybodyaddresses -addressmodifycode \'$ENV{'M2H_ADDRESSMODIFYCODE'}\'  -rcfile $mhonarc_ressources -outdir $wwsconf->{'arc_path'}/$adrlist/$yyyy-$mm  -definevars \"listname=$listname hostname=$hostname yyyy=$yyyy mois=$mm yyyymm=$yyyy-$mm wdir=$wwsconf->{'arc_path'} base=$Conf{'wwsympa_url'}/arc tag=$tag\" -umask $Conf{'umask'} $wwsconf->{'arc_path'}/$adrlist/$arc/arctxt";
	    my $exitcode = system($cmd);
	    $exitcode = $exitcode / 256;

	    ## Remove lock if required
	    if ($exitcode == 75) {
		&do_log('notice', 'Removing lock directory %s', $wwsconf->{'arc_path'}.'/'.$adrlist.'/'.$arc.'/.mhonarc.lck');
		rmdir $wwsconf->{'arc_path'}.'/'.$adrlist.'/'.$arc.'/.mhonarc.lck';
		
		$exitcode = system($cmd);
		$exitcode = $exitcode / 256;	    
	    }
	    if ($exitcode) {
		do_log('err',"Command $cmd failed with exit code $exitcode");
	    }
	    
	}
    }
}


sub mail2arc {

    my ($file, $listname, $hostname, $yyyy, $mm, $dd, $hh, $min, $ss) = @_;
    my $arcpath = $wwsconf->{'arc_path'};
    my $newfile;

    my $list = new List($listname, $hostname);

    unless (defined $list) {
	&do_log('err', 'Unknown list %s@%s', $listname, $hostname);
	return undef;
    }

    my $tag = &get_tag($listname);

    if (($list->{'admin'}{'web_archive_spam_protection'} ne 'none') && ($list->{'admin'}{'web_archive_spam_protection'} ne 'cookie')) {
	&set_hidden_mode($tag);
    }else {
	&unset_hidden_mode();
    }    

    do_log('debug',"mail2arc $file for %s yyyy:$yyyy, mm:$mm dd:$dd hh:$hh min$min ss:$ss", $list->get_list_id());
    #    chdir($wwsconf->{'arc_path'});

    my $basedir = $arcpath.'/'.$list->get_list_id();
    
    if (! -d $basedir) {
	unless (mkdir $basedir, 0775) {
	    &do_log('err', 'Cannot create directory %s', $basedir);
	    return undef;
	}
	do_log('debug',"mkdir $basedir");
    }

    ## Check quota
    if ($list->{'admin'}{'web_archive'}{'quota'}) {
	my $used = $list->get_arc_size("$arcpath") ;
	
	if ($used >= $list->{'admin'}{'web_archive'}{'quota'} * 1024){
	    &do_log('err',"archived::mail2arc : web_arc Quota exceeded for list $list->{'name'}");
	    unless ($list->send_notify_to_owner('arc_quota_exceeded',{'size' => $used})) {
		&do_log('notice',"Unable to send notify 'arc_quota_exceeded' to $list->{'name'} owner");	
	    }
	    return undef;
	}
	if ($used >= ($list->{'admin'}{'web_archive'}{'quota'} * 1024 * 0.95)){
	    &do_log('err',"archived::mail2arc : web_arc Quota exceeded for list $list->{'name'}");
	    unless ($list->send_notify_to_owner('arc_quota_95',{'size' => $used,
								'rate' => int($used * 100 / ($list->{'admin'}{'web_archive'}{'quota'} * 1024 ))})) {
		&do_log('notice',"Unable to send notify 'arc_quota_95' to $list->{'name'} owner");	
	    }
	}
    }
	
    my $monthdir = $basedir."/$yyyy-$mm";
    
    if (! -d $monthdir) {
	unless (mkdir ($monthdir, 0775)) {
	    &do_log('err', 'Cannot create directory %s', $monthdir);
	    return undef;
	}

	do_log('debug',"mkdir $arcpath/%s/$yyyy-$mm", $list->get_list_id());

	if ($list->{'admin'}{'web_archive'}{'max_month'}){ # maybe need to remove some old archive
	    if (opendir DIR,$arcpath.'/'.$list->get_list_id()) {
		my @archives = (sort {$a cmp $b} grep (/^\d{4}-\d{2}/, readdir(DIR)));	
		closedir DIR;
		my $nb_month = $#archives + 1 ;
		my $i = 0 ;
		while ( $nb_month >  $list->{'admin'}{'web_archive'}{'max_month'}) {
		    do_log('info',"removing  $arcpath/%s/$archives[$i]", $list->get_list_id());
		    &tools::remove_dir ($arcpath.'/'.$list->get_list_id().'/'.$archives[$i]);
		    $i ++; $nb_month --;		    
		}
	    }
	}
    }

    my $arctxtdir = $monthdir."/arctxt";

    if (! -d $arctxtdir) {
	unless (mkdir ($arctxtdir, 0775)) {
	    &do_log('err', 'Cannot create directory %s', $arctxtdir);
	    return undef;
	}
	do_log('debug',"mkdir $arctxtdir");
    }
    
    ## copy the file in the arctxt and in "mhonarc -add"
     if( -f $monthdir."/index" )
     {
	open(IDX,"<$monthdir/index") || fatal_err("couldn't read index for $listname");
	$newfile = <IDX>;
	chomp($newfile);
	$newfile++;
	close IDX;
     }
     else
     {
	do_log('debug',"indexing $listname archive");
	opendir (DIR, arctxtdir);
	my @files = (sort { $a <=> $b;}  readdir(DIR)) ;
	my $index = $files[$#files];
	$index +=1;
	$newfile = $index;
     }
    
    my $mhonarc_ressources = &tools::get_filename('etc',{},'mhonarc-ressources.tt2',$list->{'domain'}, $list);
    
    do_log ('debug',"calling $wwsconf->{'mhonarc'} for list %s", $list->get_list_id() ) ;
    my $cmd = "$wwsconf->{'mhonarc'} -add -modifybodyaddresses -addressmodifycode \'$ENV{'M2H_ADDRESSMODIFYCODE'}\'  -rcfile $mhonarc_ressources -outdir $monthdir  -definevars \"listname='$listname' hostname=$hostname yyyy=$yyyy mois=$mm yyyymm=$yyyy-$mm wdir=$wwsconf->{'arc_path'} base=$Conf{'wwsympa_url'}/arc tag=$tag\" -umask $Conf{'umask'} < $queue/$file";
    
    do_log('debug',"System call : $cmd");
    
    my $exitcode = system($cmd);
    $exitcode = $exitcode / 256;
    
    ## Remove lock if required
    if ($exitcode == 75) {
	&do_log('notice', 'Removing lock directory %s', $monthdir.'/.mhonarc.lck');
	rmdir $monthdir.'/.mhonarc.lck';
	
	$exitcode = system($cmd);
	$exitcode = $exitcode / 256;	    
    }
    if ($exitcode) {
	do_log('err',"Command $cmd failed with exit code $exitcode");
    }

    
    open (ORIG, "$queue/$file") || fatal_err("couldn't open file $queue/$file");
    open (DEST, ">$arctxtdir/$newfile") || fatal_err("couldn't open file $newfile");
    while (<ORIG>) {
        print DEST $_ ;
    }
    
    close ORIG;  
    close DEST;
    &save_idx("$monthdir/index",$newfile);
}

sub set_hidden_mode {
    my $tag = shift; ## tag is used as variable elements in tags to prevent message contents to be parsed

    ## $ENV{'M2H_MODIFYBODYADDRESSES'} à positionner si le corps du message est parse
    $ENV{'M2H_ADDRESSMODIFYCODE'} = "s|^([^\@]+)\@([^\@]+)\$|\($tag\%hidden_head\%$tag\)\$1\($tag\%hidden_at\%$tag\)\$2\($tag\%hidden_end\%$tag\)|g";
    $ENV{'M2H_MODIFYBODYADDRESSES'} = 1;
}

sub unset_hidden_mode {
    
    ## Be carefull, the .mhonarc.db file keeps track of previous M2H_ADDRESSMODIFYCODE setup
    $ENV{'M2H_ADDRESSMODIFYCODE'} = '';
}

sub save_idx {
    my ($index,$lst) = @_;
    
    open(INDEXF,">$index") || fatal_err("couldn't overwrite index $index");
    print INDEXF "$lst\n";
    close INDEXF;
    #   do_log('debug',"last arc entry for $index is $lst");
}

sub get_tag {
    my $listname = shift;
    
    return (substr(Digest::MD5::md5_hex(join('/', $Conf{'cookie'}, $listname)), -10)) ;
}
