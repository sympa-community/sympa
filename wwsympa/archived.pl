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

use wwslib;
use smtp;

require 'tt2native.pl';
require 'tools.pl';

#getopts('dF');

## Check options
my %options;
&GetOptions(\%main::options, 'debug|d', 'foreground|F');

if ($main::options{'debug'}) {
    $main::options{'log_level'} = 2 unless ($main::options{'log_level'});
}

$Version = '0.1';

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
$List::use_db = &List::probe_db();

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

## Sets the UMASK
umask(oct($Conf{'umask'}));

## Check access to arc_path 
unless ((-r $wwsconf->{'arc_path'}) && (-w $wwsconf->{'arc_path'})) {
    do_log('err', 'Unsufficient access to %s directory', $wwsconf->{'arc_path'});
}

&Language::LoadLang($Conf{'msgcat'});

## Change to list root
unless (chdir($Conf{'home'})) {
    &message('chdir_error');
    &do_log('err','unable to change directory');
    exit (-1);
}

my $pinfo = &List::_apply_defaults();

$Language::default_lang = $Conf{'lang'};

do_log('notice', "archived $Version Started");


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

       if ($file  =~ /^\.remove\.(.*)\.\d+$/ ) {
	   do_log('debug',"remove found : $file for list $1");

	   unless (open REMOVE, "$queue/$file") {
	        do_log ('err',"Ignoring file $queue/$file because couldn't read it, archived.pl must use the same uid as sympa");
		   next;
	       }
	   my $msgid = <REMOVE> ;
	   close REMOVE;
	   &remove($1,$msgid);
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
	       do_log ('err',"Ignoring file $queue/$file because not to be rebuild or liste archive");
               unlink("$queue/$file");
	       next;
	   }
	   
	   $adrlist =~ /^(.*)\@(.*)$/;
	   my $listname = $1;
	   my $hostname = $2;

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
unlink("$wwsconf->{'archived_pidfile'}");

exit(0);


## When we catch SIGTERM, just change the value of the loop
## variable.
sub sigterm {
    $end = 1;
}

sub remove {
    my $adrlist = shift;
    my $msgid = shift;

    do_log ('debug2',"remove ($adrlist $msgid)");
    my $arc ;

    if ($adrlist =~ /^(.*)\.(\d{4}-\d{2})$/) {
	$adrlist = $1;
        $arc = $2;
    }

    do_log('notice',"Removing $msgid in list $adrlist section $2");
  
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

    $adrlist =~ /^(.*)\@(.*)$/;
    my $listname = $1;
    my $hostname = $2;

    my $list = new List($listname);

    do_log('debug',"Rebuilding $adrlist archive ($2)");

    my $mhonarc_ressources = &tools::get_filename('etc','mhonarc-ressources',$list->{'domain'}, $list);

    if (($list->{'admin'}{'web_archive_spam_protection'} ne 'none') && ($list->{'admin'}{'web_archive_spam_protection'} ne 'cookie')) {
	&set_hidden_mode();
    }else {
	&unset_hidden_mode();
    }

    do_log('notice','Rebuilding  $arc with M2H_ADDRESSMODIFYCODE : %s',$ENV{'M2H_ADDRESSMODIFYCODE'});


    if ($arc) {
        do_log('notice',"Rebuilding  $arc of $adrlist archive");
	$arc =~ /^(\d{4})-(\d{2})$/ ;
	my $yyyy = $1 ;
	my $mm = $2 ;

	my $cmd = "$wwsconf->{'mhonarc'} -rcfile $mhonarc_ressources -outdir $wwsconf->{'arc_path'}/$adrlist/$yyyy-$mm  -definevars \"listname='$listname' hostname=$hostname yyyy=$yyyy mois=$mm yyyymm=$yyyy-$mm wdir=$wwsconf->{'arc_path'} base=$Conf{'wwsympa_url'}/arc \" -umask $Conf{'umask'} $wwsconf->{'arc_path'}/$adrlist/$arc/arctxt";

	do_log('debug',"System call : $cmd");
	my $exitcode = system($cmd);
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

	    my $cmd = "$wwsconf->{'mhonarc'}  -rcfile $mhonarc_ressources -outdir $wwsconf->{'arc_path'}/$adrlist/$yyyy-$mm  -definevars \"listname=$listname hostname=$hostname yyyy=$yyyy mois=$mm yyyymm=$yyyy-$mm wdir=$wwsconf->{'arc_path'} base=$Conf{'wwsympa_url'}/arc \" -umask $Conf{'umask'} $wwsconf->{'arc_path'}/$adrlist/$arc/arctxt";
	    my $exitcode = system($cmd);
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
    

    my $list = new List($listname);

    if (($list->{'admin'}{'web_archive_spam_protection'} ne 'none') && ($list->{'admin'}{'web_archive_spam_protection'} ne 'cookie')) {
	&set_hidden_mode();
    }else {
	&unset_hidden_mode();
    }    

    do_log('debug',"mail2arc $file for $listname\@$hostname yyyy:$yyyy, mm:$mm dd:$dd hh:$hh min$min ss:$ss");
    #    chdir($wwsconf->{'arc_path'});
    
    if (! -d "$arcpath/$listname\@$hostname") {
	unless (mkdir ("$arcpath/$listname\@$hostname", 0775)) {
	    &do_log('err', 'Cannot create directory %s', "$arcpath/$listname\@$hostname");
	    return undef;
	}
	do_log('debug',"mkdir $arcpath/$listname\@$hostname");
    }

    ## Check quota
    if ($list->{'admin'}{'web_archive'}{'quota'}) {
	my $used = $list->get_arc_size("$arcpath") ;
	
	if ($used >= $list->{'admin'}{'web_archive'}{'quota'} * 1024){
	    &do_log('err',"archived::mail2arc : web_arc Quota exceeded for list $list->{'name'}");
	    $list->send_notify_to_owner({ 'type' => 'arc_quota_exceeded',
					  'robot'=>$hostname,
					  'size' => $used,
					  'email' => $param[1]});
	    
	    return undef;
	}
	if ($used >= ($list->{'admin'}{'web_archive'}{'quota'} * 1024 * 0.95)){
	    &do_log('err',"archived::mail2arc : web_arc Quota exceeded for list $list->{'name'}");
	    $list->send_notify_to_owner({ 'type' => 'arc_quota_95',
					  'robot'=>$hostname,
					  'size' => $used,
					  'rate' => int($used * 100 / ($list->{'admin'}{'web_archive'}{'quota'} * 1024 )) ,
					  'email' => $param[1]});
	}
    }
	

    if (! -d "$arcpath/$listname\@$hostname/$yyyy-$mm") {
	unless (mkdir ("$arcpath/$listname\@$hostname/$yyyy-$mm", 0775)) {
	    &do_log('err', 'Cannot create directory %s', "$arcpath/$listname\@$hostname/$yyyy-$mm");
	    return undef;
	}
	do_log('debug',"mkdir $arcpath/$listname\@$hostname/$yyyy-$mm");
    }
    if (! -d "$arcpath/$listname\@$hostname/$yyyy-$mm/arctxt") {
	unless (mkdir ("$arcpath/$listname\@$hostname/$yyyy-$mm/arctxt", 0775)) {
	    &do_log('err', 'Cannot create directory %s', "$arcpath/$listname\@$hostname/$yyyy-$mm/arctxt");
	    return undef;
	}
	do_log('debug',"mkdir $arcpath/$listname\@$hostname/$yyyy-$mm/arctxt");
    }
    
    ## copy the file in the arctxt and in "mhonarc -add"
     if( -f "$arcpath/$listname\@$hostname/$yyyy-$mm/index" )
     {
	open(IDX,"<$arcpath/$listname\@$hostname/$yyyy-$mm/index") || fatal_err("couldn't read index for $listname");
	$newfile = <IDX>;
	chomp($newfile);
	$newfile++;
	close IDX;
     }
     else
     {
	do_log('debug',"indexing $listname archive");
	opendir (DIR, "$arcpath/$listname\@$hostname/$yyyy-$mm/arctxt");
	my @files = (sort { $a <=> $b;}  readdir(DIR)) ;
	$files[$#files]+=1;
	$newfile = $files[$#files];
     }
    
    my $mhonarc_ressources = &tools::get_filename('etc','mhonarc-ressources',$list->{'domain'}, $list);
    
    do_log ('debug',"calling $wwsconf->{'mhonarc'} for list $listname\@$hostname" ) ;
    my $cmd = "$wwsconf->{'mhonarc'} -add -rcfile $mhonarc_ressources -outdir $arcpath/$listname\@$hostname/$yyyy-$mm  -definevars \"listname='$listname' hostname=$hostname yyyy=$yyyy mois=$mm yyyymm=$yyyy-$mm wdir=$wwsconf->{'arc_path'} base=$Conf{'wwsympa_url'}/arc \" -umask $Conf{'umask'} < $queue/$file";
    
    my $exitcode = system($cmd);
    if ($exitcode) {
           do_log('err',"Command $cmd failed with exit code $exitcode");
    }

    
    open (ORIG, "$queue/$file") || fatal_err("couldn't open file $queue/$file");
    open (DEST, ">$arcpath/$listname\@$hostname/$yyyy-$mm/arctxt/$newfile") || fatal_err("couldn't open file $newfile");
    while (<ORIG>) {
        print DEST $_ ;
    }
    
    close ORIG;  
    close DEST;
    &save_idx("$arcpath/$listname\@$hostname/$yyyy-$mm/index",$newfile);
}

sub set_hidden_mode {
    ## $ENV{'M2H_MODIFYBODYADDRESSES'} à positionner si le corps du message est parse
    $ENV{'M2H_ADDRESSMODIFYCODE'} = 's|^([^@]+)@([^@]+)$|\[hidden_head\]$1\[hidden_at\]$2\[hidden_end\]|g';	
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

