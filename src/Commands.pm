# Command.pm - this module does the mail commands processing
# RCS Identication ; $Revision$ ; $Date$ 

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

package Commands;

use Conf;
use Language;
use Log;
use List;
use Version;
use Message;

use Digest::MD5;
use Fcntl;
use DB_File;
use Time::Local;
use MIME::Words;

require 'tools.pl';

use Exporter;
@ISA = ('Exporter');
@EXPORT_OK=('$sender');

my %comms =  ('add' =>			   	     'add',
	      'con|confirm' =>	                     'confirm',
	      'del|delete' =>			     'del',
	      'dis|distribute' =>      		     'distribute',
	      'exp|expire' =>			     'expire',
	      'expind|expireind|expireindex' =>      'expireindex',
	      'expdel|expiredel' =>		     'expiredel',
	      'get' =>				     'getfile',
	      'hel|help|sos' =>			     'help',
	      'inf|info' =>  			     'info',
	      'inv|invite' =>                        'invite',
	      'ind|index' =>			     'index',
	      'las|last' =>                          'last',
	      'lis|lists?' =>			     'lists',
	      'mod|modindex|modind' =>		     'modindex',
	      'qui|quit|end|stop|-' =>		     'finished',
	      'rej|reject' =>			     'reject',
	      'rem|remind' =>                        'remind',
	      'rev|review|who' =>		     'review',
	      'set' =>				     'set',
	      'sub|subscribe' =>             	     'subscribe',
	      'sig|signoff|uns|unsub|unsubscribe' => 'signoff',
	      'sta|stats' =>		       	     'stats',
	      'ver|verify' =>     	             'verify',
	      'whi|which|status' =>     	     'which'
	      );

my $sender = '';
my $time_command;
my $msg_file;

## Caution : if this regexp changes (more/less parenthesis), then regexp using it should 
## also be changed
my $email_regexp = '([\w\-\_\.\/\+\=]+|\".*\")\@[\w\-]+(\.[\w\-]+)+';

## Parse the command and call the adequate subroutine with
## the arguments to the command.
sub parse {
   $sender = lc(shift);
   my $robot = shift;
   my $i = shift;
   my $sign_mod = shift;

   do_log('debug2', 'Commands::parse(%s, %s, %s, %s)', $sender, $robot, $i,$sign_mod );

   my @msgsup = @_; ## For special commands (such as expire) needing
                    ## a message within a command
   my $j;

   do_log('notice', "Parsing: %s", $i);
   
   ## allow reply usage for auth process based on user mail replies
   if ($i =~ /auth\s+(\S+)\s+(.+)$/io) {
       $auth = $1;
       $i = $2;
   } else {
       $auth = '';
   }
   
   if ($i =~ /^quiet\s+(.+)$/i) {
       $i = $1;
       $quiet = 1;
   }else {
       $quiet = 0;
   }

   foreach $j (keys %comms) {
       if ($i =~ /^($j)(\s+(.+))?\s*$/i) {
	   $time_command = time;
	   my $args = $3;
	   $args =~ s/^\s*//;
	   $args =~ s/\s*$//;

	   my $status;

	   if (@msgsup) { ## The command expects a message
	       $status = & {$comms{$j}}($args, $robot, @msgsup);
	   }else {
	       $status = & {$comms{$j}}($args, $robot, $sign_mod);
	   }
	   return $status;
       }
   }
   
   ## Unknown command
   return undef;  
}

## Do not process what's after this line.
sub finished {
    do_log('debug2', 'Commands::finished');

    push @msg::report, sprintf Msg(4, 18, "Found `quit' command, exiting.\n");

    return 1;
}

## Send the help file for the software
sub help {

    shift;
    my $robot=shift;

    my $sympa = &Conf::get_robot_conf($robot, 'sympa');
    my $host = &Conf::get_robot_conf($robot, 'host');

    do_log('debug', 'Commands::help to robot %s',$robot);

    # sa ne prends pas en compte la structure des répertoires par lang.
    if ((-r "$Conf{'etc'}/templates/helpfile.tpl")||("$Conf{'etc'}/$robot/templates/helpfile.tpl")) {

	my $data = {};

	my @owner = &List::get_which ($sender, $robot,'owner');
	my @editor = &List::get_which ($sender, $robot, 'editor');
	
	$data->{'is_owner'} = 1 if ($#owner > -1);
	$data->{'is_editor'} = 1 if ($#editor > -1);
	$data->{'subject'} = MIME::Words::encode_mimewords(sprintf Msg(6, 81, "User guide"));

	&List::send_global_file("helpfile", $sender, $robot, $data);
    
    }elsif (open IN, 'helpfile'){
	## Old style
	while (<IN>){
	    s/\[sympa_email\]/$sympa/g;
	    s/\[sympa_host\]/$host/g;
	    push @msg::report, $_ ;
	}
	close IN;

	if ((List::get_which ($sender,$robot,'owner'))||(List::get_which ($sender,$robot,'editor'))){
	    if (open IN, 'helpfile.advanced'){
		while (<IN>){
		    s/\[sympa_email\]/$sympa/g;
		    s/\[sympa_host\]/$host/g;
		    push @msg::report, $_ ;
		}
		close IN;
	    }
	}
	push @msg::report, sprintf Msg(6, 70, "\nPowered by Sympa %s : http://www.sympa.org/\n")
	    , $Version ;

    }elsif (-r "--ETCBINDIR--/templates/helpfile.tpl") {

	my $data = {};

	my @owner = &List::get_which ($sender,$robot, 'owner');
	my @editor = &List::get_which ($sender,$robot, 'editor');
	
	$data->{'is_owner'} = 1 if ($#owner > -1);
	$data->{'is_editor'} = 1 if ($#editor > -1);

	$data->{'subject'} = sprintf Msg(6, 81, "User guide");

	&List::send_global_file("helpfile", $sender, $robot, $data);

    }else{
	push @msg::report, sprintf Msg(6, 2, "Could not read help file: %s\n"), $!;
	do_log('info', 'HELP from %s refused, file not found'
	       , $sender,);
	return undef;
    }

    do_log('info', 'HELP from %s accepted (%d seconds)', $sender
	   , time-$time_command);
    
    return 1;
}

## Sends back the list of public lists on this node.
sub lists {

    shift; 
    my $robot=shift;

    my $sympa = &Conf::get_robot_conf($robot, 'sympa');
    my $host = &Conf::get_robot_conf($robot, 'host');

    do_log('debug', 'Commands::lists for robot %s', $robot);

    my $data = {};
    my $lists = {};

    foreach my $l ( &List::get_lists($robot) ) {
	my $list = new List ($l);

	next unless ($list);
	my $action = &List::request_action('visibility','smtp',$robot,
                                            {'listname' => $l,
                                             'sender' => $sender });
	return undef
	    unless (defined $action);

	if ($action eq 'do_it') {
	    $lists->{$l}{'subject'} = $list->{'admin'}{'subject'};
	    $lists->{$l}{'host'} = $list->{'admin'}{'host'};
	}
    }

    my $data = {};
    $data->{'lists'} = $lists;
    $data->{'subject'} = MIME::Words::encode_mimewords(sprintf Msg(6, 82, "Public lists"));
    
    &List::send_global_file('lists', $sender, $robot, $data);

    do_log('info', 'LISTS from %s accepted (%d seconds)', $sender, time-$time_command);

    return 1;
}

## Sends the statistics about a list.
sub stats {
    my $listname = shift;
    my $robot=shift;

    do_log('debug', 'Commands::stats(%s)', $listname);

    my $list = new List ($listname, $robot);
    unless ($list) {
	push @msg::report, sprintf Msg(6, 5, "List %s not found.\n"), $listname;
	do_log('info', 'STATS %s from %s refused, unknown list for robot %s', $listname, $sender,$robot);
	return 'unknown_list';
    }

    my $auth_method;

    if ($sign_mod eq 'smime') {
	$auth_method='smime';
    }else { 
	$auth_method = 'smtp';
    }

    my $action = &List::request_action ('review',$auth_method,$robot,
					{'listname' => $listname,
					 'sender' => $sender});

    return undef
	unless (defined $action);

    if ($action =~ /reject(\(\'?(\w+)\'?\))?/i) {
	my $tpl = $2;

	if ($tpl) {
	    $list->send_file($tpl, $sender, $robot, {});
	}else {
	    push @msg::report, sprintf Msg(6, 80, "You are not allowed to perform %s in list %s.\n"),'STATS',$listname;
	}
	do_log('info', 'stats %s from %s refused (not allowed)', $listname,$sender);
	return 'not_allowed';
    }else {
	my %stats = ('msg_rcv' => $list->{'stats'}[0],
		     'msg_sent' => $list->{'stats'}[1],
		     'byte_rcv' => sprintf ('%9.2f', ($list->{'stats'}[2] / 1024 / 1024)),
		     'byte_sent' => sprintf ('%9.2f', ($list->{'stats'}[3] / 1024 / 1024))
		     );
	
	$list->send_file('stats_report', $sender, $robot, {'stats' => \%stats, 
							   'from' => "SYMPA <$sympa>",
							   'subject' => "STATS $list->{'name'}"});
	
	do_log('info', 'STATS %s from %s accepted (%d seconds)', $listname, sender, time-$time_command);
    }

    return 1;
}

## Sends back the requested archive file
sub getfile {
    my($which, $file) = split(/\s+/, shift);
    my $robot=shift;

    do_log('debug', 'Commands::getfile(%s, %s)', $which, $file);

    my $list = new List ($which, $robot);
    unless ($list) {
	push @msg::report, sprintf Msg(6, 5, "List %s not found.\n"), $which;
	do_log('info', 'GET %s %s from %s refused, list unknown for robot %s', $which, $file, $sender, $robot);
	return 'unknownlist';
    }

    &Language::SetLang($list->{'admin'}{'lang'});

    unless ($list->is_archived()) {
	push @msg::report, sprintf Msg(6, 7, "No files are available for this list.\n");
	do_log('info', 'GET %s %s from %s refused, archive not found', $which, $file, $sender);
	return 'no_archive';
    }
    ## Check file syntax
    if ($file =~ /(\.\.|\/)/) {
	push @msg::report, sprintf Msg(6, 8, "The requested file has not been found.\n");
	do_log('info', 'GET %s %s from %s, incorrect filename', $which, $file, $sender);
	return 'no_archive';
    }
    unless ($list->archive_exist($file)) {
	push @msg::report, sprintf Msg(6, 8, "The requested file has not been found.\n");
 	do_log('info', 'GET %s %s from %s refused, archive not found', $which, $file, $sender);
	return 'no_archive';
    }
    unless ($list->may_do('get', $sender)) {
	push @msg::report, sprintf Msg(6, 9, "This list is private, you may not get files from the archive.\n");
	do_log('info', 'GET %s %s from %s refused, review not allowed', $which, $file, $sender);
	return 'not_allowed';
    }
    $list->archive_send($sender, $file);
    do_log('info', 'GET %s %s from %s accepted (%d seconds)', $which, $file, $sender,time-$time_command);

    return 1;
}

## Sends back the requested archive file
sub last {
    my $which = shift;
    my $robot = shift;

    my $sympa = &Conf::get_robot_conf($robot, 'sympa');

    do_log('debug', 'Commands::last(%s, %s)', $which);

    my $list = new List ($which,$robot);
    unless ($list)  {
	push @msg::report, sprintf Msg(6, 5, "List %s not found.\n"), $which;
	do_log('info', 'LAST %s from %s refused, list unknown for robot %s', $which, $sender, $robot);
	return 'unknownlist';
    }

    &Language::SetLang($list->{'admin'}{'lang'});

    unless ($list->is_archived()) {
	push @msg::report, sprintf Msg(6, 7, "No files are available for this list.\n");
	do_log('info', 'LAST %s from %s refused, list not archived', $which,  $sender);
	return 'no_archive';
    }

    unless ($list->archive_exist('last_message')) {
	push @msg::report, sprintf Msg(6, 8, "The requested file has not been found.\n");
 	do_log('info', 'LAST %s from %s refused, archive not found', $which,  $sender);
	return 'no_archive';
    }
    unless ($list->may_do('get', $sender)) {
	push @msg::report, sprintf Msg(6, 9, "This list is private, you may not get files from the archive.\n");
	do_log('info', 'LAST %s from %s refused, archive access not allowed', $which, $sender);
	return 'not_allowed';
    }
    my ($fd) = &smtp::smtpto($sympa,\$sender); 
    unless (open(MSG, "$list->{'dir'}/archives/last_message")) { 
	print "unable to open last_message";
    }
    print $fd <MSG>;
    close MSG ;
    close ($fd);

    do_log('info', 'LAST %s from %s accepted (%d seconds)', $which,  $sender,time-$time_command);

    return 1;
}

## Lists the archived files
sub index {
    my $which = shift;
    my $robot = shift;


    do_log('debug', 'Commands::index(%s) robot (%s)',$which,$robot);

    my $list = new List ($which, $robot);
    unless ($list) {
	push @msg::report, sprintf Msg(6, 5, "List %s not found.\n"), $which;
	do_log('info', 'INDEX %s from %s refused, list unknown for robot %s', $which, $sender,$robot);
	return 'unknown_list';
    }

    &Language::SetLang($list->{'admin'}{'lang'});
    
    ## Now check if we may send the list of users to the requestor.
    ## Check all this depending on the values of the Review field in
    ## the control file.
    unless ($list->may_do('index', $sender)) {
	push @msg::report, sprintf Msg(6, 10, "This list is private, you may not retrieve the list of available files.\n");
	do_log('info', 'INDEX %s from %s refused, not allowed', $which, $sender);
	return 'not_allowed';
    }
    unless ($list->is_archived()) {
	push @msg::report, sprintf Msg(6, 7, "No files are available for this list.\n");
	do_log('info', 'INDEX %s from %s refused, list not archived', $which, $sender);
	return 'no_archive';
    }
    my @l = $list->archive_ls();
    push @msg::report, @l;
    do_log('info', 'INDEX %s from %s accepted (%d seconds)', $which, $sender,time-$time_command);

    return 1;
}

## Sends the list of subscribers to the requester.
sub review {
    my $listname  = shift;
    my $robot = shift;
    my $sign_mod = shift ;

    do_log('debug', 'Commands::review(%s,%s,%s)', $listname,$robot,$sign_mod );

    my $sympa = &Conf::get_robot_conf($robot, 'sympa');

    my $user;
    my $list = new List ($listname, $robot);

    unless ($list) {
	push @msg::report, sprintf Msg(6, 5, "List %s not found.\n"), $listname;
	do_log('info', 'REVIEW %s from %s refused, list unknown to robot %s', $listname,$sender,$robot);
	return 'unknown_list';
    }

    &Language::SetLang($list->{'admin'}{'lang'});

    if ($sign_mod eq 'smime') {
	$auth_method='smime';
    }elsif ($auth ne '') {
	do_log ('debug',"auth received from $sender : $auth");
	if ($auth eq $list->compute_auth ('','review')) {
	    $auth_method='md5';
	}else{
            do_log ('debug2', 'auth should be %s',$list->compute_auth ('','review'));
	    push @msg::report, sprintf Msg(6, 15, $msg::wrong_authenticator);
	    do_log('info', 'REVIEW %s from %s refused, auth failed', $listname,$sender);
	    return 'wrong_auth';
	}
	
    }else {
	$auth_method='smtp';
    }

    my $action = &List::request_action ('review',$auth_method,$robot,
                                     {'listname' => $listname,
                                      'sender' => $sender});

    return undef
	unless (defined $action);

    if ($action =~ /request_auth/i) {
	do_log ('debug2',"auth requested from $sender");
        $list->request_auth ($sender,'review',$robot);
	do_log('info', 'REVIEW %s from %s, auth requested (%d seconds)', $listname, $sender,time-$time_command);
	return 1;
    }
    if ($action =~ /reject(\(\'?(\w+)\'?\))?/i) {
	my $tpl = $2;
	if ($tpl) {
	    $list->send_file($tpl, $sender, $robot, {});
	}else {
	    push @msg::report, sprintf Msg(6, 80, "You are not allowed to perform %s in list %s.\n"),'review',$listname;
	}
	do_log('info', 'review %s from %s refused (not allowed)', $listname,$sender);
	return 'not_allowed';
    }

    my @users;

    if ($action =~ /do_it/i) {
	my $is_owner = $list->am_i('owner', $sender);
	unless ($user = $list->get_first_user({'sortby' => 'email'})) {
	    push @msg::report, sprintf Msg(6, 3, "List %s has no subscriber.\n"), $list->{'name'};
	    do_log('err', "No subscribers in list '%s'", $list->{'name'});
	    return 'no_subscribers';
	}
	do {
	    ## Owners bypass the visibility option
	    unless ( ($user->{'visibility'} eq 'conceal') 
		     and (! $is_owner) ) {

		## Lower case email address
		$user->{'email'} =~ y/A-Z/a-z/;
		push @users, $user;
	    }
	} while ($user = $list->get_next_user());
	$list->send_file('review', $sender, $robot, {'users' => \@users, 
					     'total' => $list->get_total(),
					     'from' => "SYMPA <$sympa>",
					     'subject' => "REVIEW $listname"});

	do_log('info', 'REVIEW %s from %s accepted (%d seconds)', $listname, $sender,time-$time_command);
	return 1;
    }
    do_log('info', 'REVIEW %s from %s aborted, unknown requested action in scenario',$listname,$sender);
    push @msg::report, sprintf("Internal configuration error, please report to listmaster\nreview %s aborted because unknown requested action in scenario\n",$listname);
    return undef;
}

## Verify an S/MIME signature
sub verify {
    my $listname = shift ;
    my $robot = shift;

    my $sign_mod = shift ;
    do_log('debug', 'Commands::verify(%s)', $sign_mod );
    
    my $user;
    
    &Language::SetLang($list->{'admin'}{'lang'});
    
    if ($sign_mod eq 'smime') {
	$auth_method='smime';
	do_log('info', 'VERIFY successfull from %s', $sender,time-$time_command);
	push @msg::report, sprintf Msg(6, 262, "Your message signature as been succesfully verified using smime.\n");
    }else{
	do_log('info', 'VERIFY from %s : could not find correct s/mime signature', $sender,time-$time_command);
	push @msg::report, sprintf Msg(6, 263, "Could not find signature or could not verify it using smime.\n");
	
    }
    return 1;
}

## Adds a user to a list. The user sent a subscribe
## command. Format is : sub list optionnal comment
sub subscribe {
    my $what = shift;
    my $robot = shift;

    my $sign_mod = shift ;

    do_log('debug', 'Commands::subscribe(%s,%s)', $what,$sign_mod);

    $what =~ /^(\S+)(\s+(.+))?\s*$/;
    my($which, $comment) = ($1, $3);
    my $auth_method ;
    
    ## Load the list if not already done, and reject the
    ## subscription if this list is unknown to us.
    my $list = new List ($which, $robot);
    unless ($list) {
	push @msg::report, sprintf Msg(6, 5, "List %s not found.\n"), $which;
	do_log('info', 'SUB %s from %s refused, unknown list for robot %s', $which,$sender,$robot);
	return 'unknown_list';
    }

    &Language::SetLang($list->{'admin'}{'lang'});

    ## This is a really minimalistic handling of the comments,
    ## it is far away from RFC-822 completeness.
    $comment =~ s/"/\\"/g;
    $comment = "\"$comment\"" if ($comment =~ /[<>\(\)]/);
    
    ## Now check if the user may subscribe to the list
    
    if ($sign_mod eq 'smime') {
	$auth_method='smime';
    }elsif ($auth ne '') {
	if ($auth eq $list->compute_auth ($sender,'subscribe')) {
	    $auth_method='md5';
	}else{
	    push @msg::report, sprintf Msg(6, 15, $msg::wrong_authenticator);
	    push @msg::report, sprintf Msg(6, 16, $msg::non_canonical);
	    do_log('info', 'SUB %s from %s refused, auth failed'
		   , $which,$sender);
	    return 'wrong_auth';
	}
    }else {
	$auth_method='smtp';
    }
    ## query what to do with this subscribtion request
    
    my $action = &List::request_action('subscribe',$auth_method,$robot,
				       {'listname' => $which, 
					'sender' => $sender });
    
    return undef
	unless (defined $action);

    &do_log('debug2', 'action : %s', $action);
    
    if ($action =~ /reject(\(\'?(\w+)\'?\))?/i) {
	my $tpl = $2;
	if ($tpl) {
	    $list->send_file($tpl, $sender, $robot, {});
	}else {
	    push @msg::report, sprintf Msg(6, 80, "You are not allowed to perform %s in list %s.\n"),'subscribe',$which;
	}
	do_log('info', 'SUB %s from %s refused (not allowed)', $which, $sender);
	return 'not_allowed';
    }
    if ($action =~ /owner/i) {
	push @msg::report, sprintf Msg(6, 25, $msg::subscription_forwarded);
	## Send a notice to the owners.
	$list->send_notify_to_owner({'who' => $sender,
				     'keyauth' => $list->compute_auth($sender,'add'),
				     'replyto' => &Conf::get_robot_conf($robot, 'sympa'),
				     'gecos' => $comment,
				     'type' => 'subrequest'});
	$list->store_subscription_request($sender, $comment);
	do_log('info', 'SUB %s from %s forwarded to the owners of the list (%d seconds)', $which, $sender,time-$time_command);   
	return 1;
    }
    if ($action =~ /request_auth/i) {
	my $cmd = 'subscribe';
	$cmd = "quiet $cmd" if $quiet;
	$list->request_auth ($sender, $cmd, $robot, $comment );
	do_log('info', 'SUB %s from %s, auth requested (%d seconds)', $which, $sender,time-$time_command);
	return 1;
    }
    if ($action =~ /do_it/i) {

	my $user_entry = $list->get_subscriber($sender);
	
	if (defined $user_entry) {
		
	    ## Only updates the date
	    ## Options remain the same
	    my $user = {};
	    $user->{'update_date'} = time;
		$user->{'gecos'} = $comment if $comment;
	    $user->{'subscribed'} = 1;
	    
	    return undef
		unless $list->update_user($sender, $user);
	}else {

	    my $u;
	    my $defaults = $list->get_default_user_options();
	    %{$u} = %{$defaults};
	    $u->{'email'} = $sender;
	    $u->{'gecos'} = $comment;
	    $u->{'date'} = $u->{'update_date'} = time;
	    $u->{'subscribed'} = 1 if ($list->{'admin'}{'user_data_source'} eq 'include2');

	    return undef  unless $list->add_user($u);
	}
	
	if ($List::use_db) {
	    my $u = &List::get_user_db($sender);
	    
	    &List::update_user_db($sender, {'lang' => $u->{'lang'} || $list->{'admin'}{'lang'},
					    'password' => $u->{'password'} || &tools::tmp_passwd($sender)
					    });
	}
	
	$list->save();
	
	## Now send the welcome file to the user
	unless ($quiet || ($action =~ /quiet/i )) {
	    my %context;
	    $context{'subject'} = sprintf(Msg(8, 6, "Welcome to list %s"), $list->{'name'});
	    $context{'body'} = sprintf(Msg(8, 6, "You are now subscriber of list %s"), $list->{'name'});
	    $list->send_file('welcome', $sender, $robot, \%context);
	}

	## If requested send notification to owners
	if ($action =~ /notify/i) {
	    $list->send_notify_to_owner({'who' => $sender, 
					 'gecos' =>$comment, 
					 'type' => 'subscribe'});
	}
	do_log('info', 'SUB %s from %s accepted (%d seconds, %d subscribers)', $which, $sender, time-$time_command, $list->get_total());
	
	return 1;
    }
    
    do_log('info', 'SUB %s  from %s aborted, unknown requested action in scenario',$which,$sender);
    push @msg::report, sprintf("Internal configuration error, please report to listmaster\nSUB %s aborted because unknown requested action in scenario",$listname);
    return undef;
}

## Sends the information file to the requester
sub info {
    my $listname = shift;
    my $robot = shift;
    my $sign_mod = shift ;

    do_log('debug', 'Commands::info(%s,%s)', $listname,$robot);

    my $sympa = &Conf::get_robot_conf($robot, 'sympa');

    my $list = new List ($listname, $robot);
    unless ($list) {
	push @msg::report, sprintf Msg(6, 5, "List %s not found.\n"), $listname;
	do_log('info', 'INFO %s from %s refused, unknown list for robot %s', $listname,$sender,$robot);
	return 'unknown_list';
    }

    &Language::SetLang($list->{'admin'}{'lang'});

    if ($sign_mod eq 'smime') {
	$auth_method='smime';
    }elsif ($auth ne '') {
	do_log ('debug2',"auth received from $sender : $auth");
	if ($auth eq $list->compute_auth ('','info')) {
	    $auth_method='md5';
	}else{
            do_log ('debug2', 'auth should be %s',$list->compute_auth ('','info'));
	    push @msg::report, sprintf Msg(6, 15, $msg::wrong_authenticator);
	    do_log('info', 'INFO %s from %s refused, auth failed', $listname,$sender);
	    return 'wrong_auth';
	}
	
    }else {
	$auth_method='smtp';
    }

    my $action = &List::request_action('info',$auth_method,$robot,
				       {'listname' => $listname, 
					'sender' => $sender });
    
    return undef
	unless (defined $action);

    if ($action =~ /reject(\(\'?(\w+)\'?\))?/i) {

	my $tpl = $2;
	if ($tpl) {
	    $list->send_file($tpl, $sender, $robot, {});
	}else {
	    push @msg::report, sprintf Msg(6, 80, "You are not allowed to perform %s in list %s.\n"),'review',$listname;
	}
	do_log('info', 'review %s from %s refused (not allowed)', $listname,$sender);
	return 'not_allowed';
    }
    if ($action =~ /do_it/i) {

	my %data = %{$list->{'admin'}};
	$data{'from'} = "SYMPA <$sympa>";
	$data{'subject'} = "INFO $listname";
	foreach my $p ('subscribe','unsubscribe','send','review') {
	    $data{$p} = $data{$p}->{'title'}{$list->{'admin'}{'lang'}};
	}

	## Digest
	my @days;
	foreach my $d (@{$list->{'admin'}{'digest'}{'days'}}) {
	    push @days, &POSIX::strftime("%A", localtime(0 + ($d +3) * (3600 * 24)))
	}
	$data{'digest'} = join (',', @days).' '.$list->{'admin'}{'digest'}{'hour'}.':'.$list->{'admin'}{'digest'}{'minute'};

	$data{'available_reception_mode'} = $list->available_reception_mode();

	my $wwsympa_url = &Conf::get_robot_conf($robot, 'wwsympa_url');
	$data{'url'} = $wwsympa_url.'/info/'.$list->{'name'};

	$list->send_file('info_report', $sender, $robot, \%data);

	do_log('info', 'INFO %s from %s accepted (%d seconds)', $listname, $sender,time-$time_command);
	return 1;
    }
    if ($action =~ /request_auth/) {
	do_log ('debug2',"auth requested from $sender");
        $list->request_auth ($sender,'info', $robot);
	do_log('info', 'REVIEW %s from %s, auth requested (%d seconds)', $listname, $sender,time-$time_command);
	return 1;
    }

    do_log('info', 'INFO %s  from %s aborted, unknown requested action in scenario',$listname,$sender);
    push @msg::report, sprintf("Internal configuration error, please report to listmaster\nreview %s aborted because unknown requested action in scenario\n",$listname);
    return undef;

}

## Removes a user from a list. The user sent a signoff
## command. Format is : sig list
sub signoff {
    my $which = shift;
    my $robot = shift;

    my $sign_mod = shift ;
    do_log('debug', 'Commands::signoff(%s,%s)', $which,$sign_mod);

    my ($l,$list,$auth_method);
    my $host = &Conf::get_robot_conf($robot, 'host');

    ## $email is defined if command is "unsubscribe <listname> <e-mail>"    
    unless ($which =~ /^(\*|[\w\.\-]+)(\@$host)?(\s+(.+))?$/) {
	push @msg::report, sprintf Msg(6, 13, "Command syntax error\n");
	do_log ('notice', "Command syntax error\n");
        return 'syntax_error';
    }

    ($which,$email) = ($1,$4||$sender);
    
    if ($which eq '*') {
	my $success ;
	foreach $l ( List::get_which ($email,$robot,'member') ){
            $success ||= &signoff($l,$email);
	}
	return ($success);
    }

    $list = new List ($which, $robot);
    
    ## Is this list defined
    unless ($list) {
	push @msg::report, sprintf Msg(6, 5, "List %s not found.\n"), $which;
	do_log('info', 'SIG %s %s from %s, unknown list for robot %s', $which,$email,$sender,$robot);
	return 'unknown_list';
    }

    &Language::SetLang($list->{'admin'}{'lang'});

    if ($sign_mod eq 'smime') {
	$auth_method='smime';
    }elsif ($auth ne '') {
	if ($auth eq $list->compute_auth ($email,'signoff')) {
	    $auth_method='md5';
	}else{
	    push @msg::report, sprintf Msg(6, 15, $msg::wrong_authenticator);
	    push @msg::report, sprintf Msg(6, 16, $msg::non_canonical);
	    do_log('info', 'SIG %s from %s refused, auth failed'
		   , $which,$sender);
	    return 'wrong_auth';
	}
    }else{
	$auth_method='smtp';
    }  
    
    my $action = &List::request_action('unsubscribe',$auth_method,$robot,
				       {'listname' => $which, 
					'email' => $email,
					'sender' => $sender });
    
    return undef
	unless (defined $action);

    if ($action =~ /reject(\(\'?(\w+)\'?\))?/i) {
	my $tpl = $2;
	if ($tpl) {
	    $list->send_file($tpl, $sender, $robot, {});
	}else {
	    push @msg::report, sprintf Msg(6, 80, "You are not allowed to perform %s %s in list %s.\n"),'sig',$which,$email;
	}
	do_log('info', 'DEL %s %s from %s refused (not allowed)', $which, $email, $sender);
	return 'not_allowed';
    }
    if ($action =~ /request_auth\s*\(\s*\[\s*(email|sender)\s*\]\s*\)/i) {
	my $cmd = 'signoff';
	$cmd = "quiet $cmd" if $quiet;
	$list->request_auth ($$1, $cmd, $robot);
	do_log('info', 'SIG %s from %s auth requested (%d seconds)', $which, $sender,time-$time_command);
	return 1;
    }

    if ($action =~ /owner/i) {
	push @msg::report, sprintf Msg(6, 25, $msg::subscription_forwarded)
	    unless ($action =~ /quiet/i);
	## Send a notice to the owners.
	$list->send_notify_to_owner({'who' => $sender,
				     'keyauth' => $list->compute_auth($sender,'del'),
				     'type' => 'sigrequest'});
	do_log('info', 'SIG %s from %s forwarded to the owners of the list (%d seconds)', $which, $sender,time-$time_command);   
	return 1;
    }
    if ($action =~ /do_it/i) {
	## Now check if we know this email on the list and
	## remove it if found, otherwise just reject the
	## command.
	my $user_entry = $list->get_subscriber($email);
	unless ((defined $user_entry) && ($user_entry->{'subscribed'} == 1)) {
	    push @msg::report, sprintf Msg(6, 30, "Email address %s has not been found on the list %s. You did perhaps\nsubscribe using a different address ?\n"), $email, $list->{'name'};
	    do_log('info', 'SIG %s from %s refused, not on list', $which, $email);
	    
	    ## Tell the owner somebody tried to unsubscribe
	    if ($action =~ /notify/i) {
		$list->send_notify_to_owner({'who' => $email, 
					     'gecos' => $comment, 
					     'type' => 'warn-signoff'});
	    }
	    return 'not_allowed';
	}
	
	if ($user_entry->{'included'} == 1) {
	    unless ($list->update_user($email, 
				       {'subscribed' => 0,
					'update_date' => time})) {
		do_log('info', 'SIG %s from %s failed, database update failed', $which, $email);
		return undef;
	    }

	}else {
	    ## Really delete and rewrite to disk.
	    $list->delete_user($email);
	}
	
	## Notify the owner
	if ($action =~ /notify/i) {
	    $list->send_notify_to_owner({'who' => $email, 
					 'gecos' => $comment, 
					 'type' => 'signoff'});
	}
	
	$list->save();

	unless ($quiet || ($action =~ /quiet/i)) {
	    ## Send bye file to subscriber
	    my %context;
	    $context{'subject'} = sprintf(Msg(6 , 71, 'Signoff from list %s'), $list->{'name'});
	    $context{'body'} = sprintf(Msg(6 , 31, "You have been removed from list %s.\n Thanks for being with us.\n"), $list->{'name'});
	    $list->send_file('bye', $email, $robot, \%context);
	}

	do_log('info', 'SIG %s from %s accepted (%d seconds, %d subscribers)', $which, $email, time-$time_command, $list->get_total() );
	
	return 1;	    
    }
    return undef;
}


## Owner adds a user to a list. Verifies the proper authorization
## and sends acknowledgements unless quiet add.
sub add {
    my $what = shift;
    my $robot = shift;

    my $sign_mod = shift ;

    do_log('debug', 'Commands::add(%s,%s)', $what,$sign_mod );

    $what =~ /^(\S+)\s+($email_regexp)(\s+(.+))?\s*$/;
    my($which, $email, $comment) = ($1, $2, $6);
    my $auth_method ;

    ## Load the list if not already done, and reject the
    ## subscription if this list is unknown to us.
    my $list = new List ($which, $robot);
    unless ($list) {
	push @msg::report, sprintf Msg(6, 5, "List %s not found.\n"), $which;
	do_log('info', 'ADD %s %s from %s refused, unknown list for robot %s', $which, $email,$sender,$robot);
	return 'unknown_list';
    }

    &Language::SetLang($list->{'admin'}{'lang'});
    
    if ($sign_mod eq 'smime') {
	$auth_method='smime';
    }elsif ($auth ne '') {
	if ($auth eq $list->compute_auth ($email, 'add')) {
	    $auth_method='md5';
	}else{
	    push @msg::report, sprintf Msg(6, 15, $msg::wrong_authenticator);
	    push @msg::report, sprintf Msg(6, 16, $msg::non_canonical);
	    do_log('info', 'ADD %s %s from %s refused, auth failed', $which,$email,$sender);
	    return 'wrong_auth';
	}
    }else{
	$auth_method='smtp';
    }
    
    my $action = &List::request_action('add',$auth_method,$robot,
				       {'listname' => $which, 
					'email' => $email,
					'sender' => $sender });
    
    return undef
	unless (defined $action);

    if ($action =~ /reject(\(\'?(\w+)\'?\))?/i) {
	my $tpl = $2;
	if ($tpl) {
	    $list->send_file($tpl, $sender, $robot, {});
	}else {
	    push @msg::report, sprintf Msg(6, 80, "You are not allowed to perform %s in list %s.\n"),'add',$which;
	}
	do_log('info', 'ADD %s %s from %s refused (not allowed)', $which, $email, $sender);
	return 'not_allowed';
    }
    
    if ($action =~ /request_auth/i) {
	my $cmd = 'add';
	$cmd = "quiet $cmd" if $quiet;
        $list->request_auth ($sender, $cmd, $robot, $email, $comment);
	do_log('info', 'ADD %s from %s, auth requested(%d seconds)', $which, $sender,time-$time_command);
	return 1;
    }
    if ($action =~ /do_it/i) {
	if ($list->is_user($email)) {
	    my $user = {};
	    $user->{'update_date'} = time;
	    $user->{'gecos'} = $comment if $comment;
	    $user->{'subscribed'} = 1;

	    return undef 
		unless $list->update_user($email, $user);
	    push @msg::report, sprintf Msg(6, 36, "User %s record has been updated for list %s.\n"),$email,$which;
	}else {
	    my $u;
	    my $defaults = $list->get_default_user_options();
	    %{$u} = %{$defaults};
	    $u->{'email'} = $email;
	    $u->{'gecos'} = $comment;
	    $u->{'date'} = $u->{'update_date'} = time;
	    $u->{'subscribed'} = 1 if ($list->{'admin'}{'user_data_source'} eq 'include2');
	    
	    return undef unless $list->add_user($u);
	    $list->delete_subscription_request($email);
	    push @msg::report, sprintf Msg(6, 37, "User %s has been added to the list %s.\n"), $email, $which;
	}
    
	if ($List::use_db) {
	    my $u = &List::get_user_db($email);
	    
	    &List::update_user_db($email, {'lang' => $u->{'lang'} || $list->{'admin'}{'lang'},
					   'password' => $u->{'password'} || &tools::tmp_passwd($email)
					    });
	}

	$list->save();
    
	## Now send the welcome file to the user if it exists.
	unless ($quiet || ($action =~ /quiet/i )) {
	    my %context;
	    $context{'subject'} = sprintf(Msg(8, 6, "Welcome to list %s"), $list->{'name'});
	    $context{'body'} = sprintf(Msg(8, 6, "You are now subscriber of list %s"), $list->{'name'});
	    $list->send_file('welcome', $email, $robot, \%context);
	}

	do_log('info', 'ADD %s %s from %s accepted (%d seconds, %d subscribers)', $which, $email, $sender, time-$time_command, $list->get_total() );
	if ($action =~ /notify/i) {
	    $list->send_notify_to_owner({'who' => $email, 
					 'gecos' => $comment,
					 'type' => 'add',
					 'by' => $sender});
	}
	return 1;
    }

}


## Invite someone to subscribe
sub invite {
    my $what = shift;
    my $robot=shift;
    my $sign_mod = shift ;
    do_log('debug', 'Commands::invite(%s,%s)', $what,$sign_mod);

    my $sympa = &Conf::get_robot_conf($robot, 'sympa');

    $what =~ /^(\S+)\s+(\S+)(\s+(.+))?\s*$/;
    my($which, $email, $comment) = ($1, $2, $4);
    my $auth_method ;

    ## Load the list if not already done, and reject the
    ## subscription if this list is unknown to us.
    my $list = new List ($which, $robot);
    unless ($list) {
	push @msg::report, sprintf Msg(6, 5, "List %s not found.\n"), $which;
	do_log('info', 'INVITE %s %s from %s refused, unknown list for robot', $which, $email,$sender,$robot);
	return 'unknown_list';
    }
    
    &Language::SetLang($list->{'admin'}{'lang'});

    if ($sign_mod eq 'smime') {
	$auth_method='smime';
    }elsif ($auth ne '') {
	if ($auth eq $list->compute_auth ($email, 'invite')) {
	    $auth_method='md5';
	}else{
	    push @msg::report, sprintf Msg(6, 15, $msg::wrong_authenticator);
	    push @msg::report, sprintf Msg(6, 16, $msg::non_canonical);
	    do_log('info', 'ADD %s %s from %s refused, auth failed', $which,$email,$sender);
	    return 'wrong_auth';
	}
    }else {
	$auth_method='smtp';
    }
    
    my $action = &List::request_action('invite',$auth_method,$robot,
				       {'listname' => $which, 
					'sender' => $sender });

    return undef
	unless (defined $action);

    if ($action =~ /reject(\(\'?(\w+)\'?\))?/i) {
	my $tpl = $2;
	if ($tpl) {
	    $list->send_file($tpl, $sender, $robot, {});
	}else {
	    push @msg::report, sprintf Msg(6, 80, "You are not allowed to perform %s in list %s.\n"),'invite',$which;
	}
	do_log('info', 'INVITE %s %s from %s refused (not allowed)', $which, $email, $sender);
	return 'not_allowed';
    }
    
    if ($action =~ /request_auth/i) {
        $list->request_auth ($sender, 'invite', $robot, $email, $comment);
	do_log('info', 'INVITE %s from %s, auth requested (%d seconds)', $which, $sender,time-$time_command);
	return 1;
    }
    if ($action =~ /do_it/i) {
	if ($list->is_user($email)) {
	    push @msg::report, sprintf Msg(6, 84, "User %s is already subscriber of list %s.\n"),$email,$which;
	}else{
            ## Is the guest user allowed to subscribe in this list ?

	    my %context;
	    $context{'subject'} = sprintf(Msg(8, 29, "Invitation to join list %s"), $list->{'name'});
	    $context{'body'} = sprintf(Msg(8, 30, "You are invited to join list %s"), $list->{'name'});
	    $context{'user'}{'email'} = $email;
	    $context{'user'}{'gecos'} = $comment;
	    $context{'requested_by'} = $sender;

	    my $action = &List::request_action('subscribe','smtp',$robot,
					       {'listname' => $which, 
						'sender' => $sender });

	    return undef
		unless (defined $action);

            if ($action =~ /request_auth/i) {
		my $keyauth = $list->compute_auth ($email, 'subscribe');
		my $command = "auth $keyauth sub $which $comment";
		$context{'subject'} = $command;
		$context{'url'}= "mailto:$sympa?subject=$command";
		$context{'url'} =~ s/\s/%20/g;
		$list->send_file('invite', $email, $robot, \%context);            
		do_log('info', 'INVITE %s %s from %s accepted, auth requested (%d seconds, %d subscribers)', $which, $email, $sender, time-$time_command, $list->get_total() );
		push @msg::report, sprintf Msg(6, 85, "User %s has been invited to subscribe in list %s.\n"),$email,$which;

	    }elsif ($action !~ /reject/i) {
                $context{'subject'} = "sub $which $comment";
		$context{'url'}= "mailto:$sympa?subject=$context{'subject'}";
		$context{'url'} =~ s/\s/%20/g;
		$list->send_file('invite', $email, $robot,\%context) ;      
		do_log('info', 'INVITE %s %s from %s accepted,  (%d seconds, %d subscribers)', $which, $email, $sender, time-$time_command, $list->get_total() );
		push @msg::report, sprintf Msg(6, 85, "User %s has been invited to subscribe in list %s.\n"),$email,$which;

	    }elsif ($action =~ /reject\(\'?(\w+)\'?\)/i) {
		$tpl = 41;
		do_log('info', 'INVITE %s %s from %s refused, not allowed (%d seconds, %d subscribers)', $which, $email, $sender, time-$time_command, $list->get_total() );
		if ($tpl) {
		    $list->send_file($tpl, $sender, $robot, {});
		}else {
		    push @msg::report, sprintf Msg(6, 86, "User %s is unwanteed in list %s.\n"),$email,$which;
		}
	    }

	}
    
	return 1;
    }
}


## send a personal reminder to each subscriber of a list
sub remind {
    my $which = shift;
    my $robot = shift;
    my $sign_mod = shift ;

    do_log('debug', 'Commands::remind(%s,%s)', $which,$sign_mod);

    my $host = &Conf::get_robot_conf($robot, 'host');
    
    my $auth_method ;
    my %context;
    
    unless ($which =~ /^(\*|[\w\.\-]+)(\@$host)?\s*$/) {
	push @msg::report, sprintf Msg(6, 13, "Command syntax error\n");
	do_log ('notice', "Command syntax error\n");
        return 'syntax_error';
    }

    my $listname = $1;
    my $list;

    unless ($listname eq '*') {
	$list = new List ($listname, $robot);
	unless ($list) {
	    push @msg::report, sprintf Msg(6, 5, "List %s not found.\n"), $listname;
	    do_log('info', 'REMIND %s from %s refused, unknown list for robot %s', $which, $sender,$robot);
	    return 'unknown_list';
	}
    }

    if ($sign_mod eq 'smime') {
	$auth_method='smime';
    }elsif ($auth ne '') {
	do_log ('debug2',"auth received from $sender : $auth");

	my $should_be;
	if ($listname eq '*') {
	    $should_be = &List::compute_auth ('','remind');
	}else {
	    $should_be = $list->compute_auth ('','remind');
	}

	if ($auth eq $should_be) {
	    $auth_method = 'md5';
	}else{
            do_log ('debug2', 'auth should be %s', $should_be);
	    push @msg::report, sprintf Msg(6, 15, $msg::wrong_authenticator);
	    do_log('info', 'REMIND %s from %s refused, auth failed', $listname,$sender);
	    return 'wrong_auth';
	}
	
    }else {
	$auth_method='smtp';
    }
    my $action;

    if ($listname eq '*') {
	$action = &List::request_action('global_remind',$auth_method,$robot,
					   {'sender' => $sender });
	
    }else{
	
	&Language::SetLang($list->{'admin'}{'lang'});

	$host = $list->{'admin'}{'host'};

	$action = &List::request_action('remind',$auth_method,$robot,
					   {'listname' => $listname, 
					    'sender' => $sender });
    }

    return undef
	unless (defined $action);

    if ($action =~ /reject(\(\'?(\w+)\'?\))?/i) {
	my $tpl = $2;
	do_log ('info',"Remind for list $listname from $sender refused");
	if ($tpl) {
	    $list->send_file($tpl, $sender, $robot, {});
	}else {
	    push @msg::report, sprintf Msg(6, 80, "You are not allowed to perform command %s in list %s\n"),'remind',$listname;
	}
	return 'not_allowed';
    }elsif ($action =~ /request_auth/i) {
	do_log ('debug2',"auth requested from $sender");
	if ($listname eq '*') {
	    &List::request_auth ($sender,'remind', $robot);
	}else {
	    $list->request_auth ($sender,'remind', $robot);
	}
	do_log('info', 'REMIND %s from %s, auth requested (%d seconds)', $listname, $sender,time-$time_command);
	return 1;
    }elsif ($action =~ /do_it/i) {

	if ($listname ne '*') {

	    unless ($list) {
		push @msg::report, sprintf Msg(6, 5, "List '%s' not found.\n"), $which;
		do_log('info', 'REMIND %s from %s refused, unknown list for robot %s', $listname,$sender,$robot);
		return 'unknown_list';
	    }
	    
	    ## for each subscriber send a reminder
	    my $total=0;
	    my $user;
	    
	    unless ($user = $list->get_first_user()) {
		return undef;
	    }
	    
	    do {
		my %context;
		$context{'subject'} = sprintf(Msg(6, 76, "Subscription reminder of list %s"), $list->{'name'});
		$context{'body'} = sprintf(Msg(6, 77, "You are subscriber of the list %s with email %s.\n"), $list->{'name'}, $user->{'email'});

		$list->send_file('remind', $user->{'email'},$robot, \%context);
		$total += 1 ;
	    } while ($user = $list->get_next_user());
	    
	    push @msg::report, sprintf(Msg(6, 78,  "Subscription reminder sent to each of %d %s subscribers\n"),$total,$listname);
	    do_log('info', 'REMIND %s  from %s accepted, sent to %d subscribers (%d seconds)',$listname,$sender,$total,time-$time_command);
	    

	    return 1;
	}else{
	    ## Global REMIND
	    my %global_subscription;
	    my %global_info;
	    my $count = 0 ;

	    $context{'subject'} = Msg(6, 83, "summary of your subscription");
	    # this remind is a global remind.
	    foreach my $listname (List::get_lists($robot)){

		my $list = new List ($listname, $robot);
		next unless $list;

		next unless ($user = $list->get_first_user()) ;

		do {
		    my $email = lc ($user->{'email'});
		    if (List::request_action('visibility','smtp',$robot,
					     {'listname' => $listname, 
					      'sender' => $email}) eq 'do_it') {
			push @{$global_subscription{$email}},$listname;
			
			$user->{'lang'} ||= $list->{'admin'}{'lang'};
			
			$global_info{$email} = $user;

			do_log('debug2','remind * : %s subscriber of %s', $email,$listname);
			$count++ ;
		    } 
		} while ($user = $list->get_next_user());
	    }
	    do_log('debug2','Sending REMIND * to %d users', $count);

	    foreach my $email (keys %global_subscription) {
		my $user = &List::get_user_db($email);
		foreach my $key (keys %{$user}) {
		    $global_info{$email}{$key} = $user->{$key}
		    if ($user->{$key});
		}
		
                $context{'user'}{'email'} = $email;
		$context{'user'}{'lang'} = $global_info{$email}{'lang'};
		$context{'user'}{'password'} = $global_info{$email}{'password'};
		$context{'user'}{'gecos'} = $global_info{$email}{'gecos'};
                @{$context{'lists'}} = @{$global_subscription{$email}};

		&List::send_global_file('global_remind', $email, $robot, \%context);
	    }
	    push @msg::report, sprintf ("The Reminder has been sent to %d users\n",$count);
	}
    }else{
	do_log('info', 'REMIND %s  from %s aborted, unknown requested action in scenario',$listname,$sender);
	push @msg::report, sprintf('Internal configuration error, please report to listmaster\nREMIND %s aborted because unknown requested action in scenario',$listname);
	return undef;
    }

}


## Owner removes a user from a list. Verifies the authorization and
## sends acknowledgements unless quiet is specifies.
sub del {
    my $what = shift;
    my $robot = shift;

    my $sign_mod = shift ;

    do_log('debug', 'Commands::del(%s,%s)', $what,$sign_mod);

    $what =~ /^(\S+)\s+($email_regexp)\s*/;
    my($which, $who) = ($1, $2);
    my $auth_method;
    
    ## Load the list if not already done, and reject the
    ## subscription if this list is unknown to us.
    my $list = new List ($which, $robot);
    unless ($list) {
	push @msg::report, sprintf Msg(6, 5, "List %s not found.\n"), $which;
	do_log('info', 'DEL %s %s from %s refused, unknown list for robot %s', $which, $who,$sender,$robot);
	return 'unknown_list';
    }

    &Language::SetLang($list->{'admin'}{'lang'});

    if ($sign_mod eq 'smime') {
	$auth_method='smime';
    }elsif ($auth ne '') {
	if ($auth eq $list->compute_auth ($who,'del')) {
	    $auth_method='md5';
	}else{
	    push @msg::report, sprintf Msg(6, 15, $msg::wrong_authenticator);
	    push @msg::report, sprintf Msg(6, 16, $msg::non_canonical);
	    do_log('info', 'DEL %s %s from %s refused, auth failed'
		   , $which,$who,$sender);
	    return 'wrong_auth';
	}
    }else{
	$auth_method='smtp';
    }  


    ## query what to do with this DEL request
    my $action = &List::request_action ('del',$auth_method,$robot,
					{'listname' =>$which,
					 'sender' => $sender,
					 'email' => $who,
					 });

    return undef
	unless (defined $action);

    if ($action =~ /reject(\(\'?(\w+)\'?\))?/i) {
	my $tpl = $2;
	if ($tpl) {
	    $list->send_file($tpl, $sender, $robot, {});
	}else {
	    push @msg::report, sprintf Msg(6, 80, "You are not allowed to perform %s in list %s.\n"),'del',$which;
	}
	do_log('info', 'DEL %s %s from %s refused (not allowed)', $which, $who, $sender);
	return 'not_allowed';
    }
    if ($action =~ /request_auth/i) {
	my $cmd = 'del';
	$cmd = "quiet $cmd" if $quiet;
        $list->request_auth ($sender, $cmd, $robot, $who );
	do_log('info', 'DEL %s %s from %s, auth requested (%d seconds)', $which, $who, $sender,time-$time_command);
	return 1;
    }

    if ($action =~ /do_it/i) {
	## Check if we know this email on the list and remove it. Otherwise
	## just reject the message.
	my $user_entry = $list->get_subscriber($who);

	unless ((defined $user_entry) && ($user_entry->{'subscribed'} == 1)) {
	    push @msg::report, sprintf Msg(6, 33, "Email address %s has not been found on the list.\n"), $who;
	    do_log('info', 'DEL %s %s from %s refused, not on list', $which, $who, $sender);
	    return 'not_allowed';
	}
	
	## Get gecos before deletion
	my $gecos = $user_entry->{'gecos'};
	
	if ($user_entry->{'included'} == 1) {
	    unless ($list->update_user($who, 
				       {'subscribed' => 0,
					'update_date' => time})) {
		do_log('info', 'DEL %s %s from %s failed, database update failed', $which, $who, $sender);
		return undef;
	    }

	}else {
	    ## Really delete and rewrite to disk.
	    my $u = $list->delete_user($who);
	}

	$list->save();
	
	## Send a notice to the removed user, unless the owner indicated
	## quiet del.
	unless ($quiet || ($action =~ /quiet/i )) {
	    my %context;
	    $context{'subject'} = sprintf(Msg(6, 18, "You have been removed from list %s\n"), $list->{'name'});
	    $context{'body'} = sprintf(Msg(6, 31, "You have been removed from list %s.\nThanks for being with us.\n"), $list->{'name'});
	    
	    $list->send_file('removed', $who, $robot, \%context);
	    
	}
	push @msg::report, sprintf Msg(6, 38, $msg::user_removed_from_list), $who, $which;
	do_log('info', 'DEL %s %s from %s accepted (%d seconds, %d subscribers)', $which, $who, $sender, time-$time_command, $list->get_total() );
	if ($action =~ /notify/i) {
	    $list->send_notify_to_owner({'who' => $who, 
					 'gecos' => "", 
					 'type' => 'del',
					 'by' => $sender});
	}
	return 1;
    }
    do_log('info', 'DEL %s %s from %s aborted, unknown requested action in scenario',$which,$who,$sender);
    push @msg::report, sprintf("Internal configuration error, please report to listmaster\nDEL %s aborted because unknown requested action in scenario",$listname);
    return undef;
}


## Change subscription options (reception or visibility)
sub set {
    my $what = shift;
    my $robot = shift;

    do_log('debug', 'Commands::set(%s)', $what);

    $what =~ /^\s*(\S+)\s+(\S+)\s*$/; 
    my ($which, $mode) = ($1, $2);

    ## Unknown command (should be checked....)
    unless ($mode =~ /^(digest|nomail|normal|each|mail|conceal|noconceal|summary|notice|txt|html|urlize)$/i) {
	push @msg::report, sprintf "Unknown command.\n";
	return 'syntax_error';
    }

    ## SET EACH is a synonim for SET MAIL
    $mode = 'mail' if ($mode =~ /^each|eachmail|nodigest|normal$/i);
    $mode =~ y/[A-Z]/[a-z]/;
    
    ## Recursive call to subroutine
    if ($which eq "*"){
        my ($l);
	my $status;
	foreach $l ( List::get_which ($sender,$robot,'member')){
	    my $current_status = &set ("$l $mode");
	    $status ||= $current_status;
	}
	return $status;
    }

    ## Load the list if not already done, and reject
    ## if this list is unknown to us.
    my $list = new List ($which, $robot);

    unless ($list) {
	push @msg::report, sprintf Msg(6, 5, "List %s not found.\n"), $which;
	do_log('info', 'SET %s %s from %s refused, unknown list for robot %s', $which, $mode, $sender,$robot);
	return 'unknown_list';
    }

    ## No subscriber pref if 'include'
    if ($list->{'admin'}{'user_data_source'} eq 'include') {
		push @msg::report, sprintf Msg(6, 91, '%s mailing list does not provide subscriber preferences.\n'), $list->{'name'};
	do_log('info', 'SET %s %s from %s refused, user_data_source include',  $which, $mode, $sender);
	return 'not allowed';
    }
    
    &Language::SetLang($list->{'admin'}{'lang'});

    ## Check if we know this email on the list and remove it. Otherwise
    ## just reject the message.
    unless ($list->is_user($sender) ) {
	push @msg::report, sprintf Msg(6, 33, "Email address %s was not found on the list.\n"), $sender;
	do_log('info', 'SET %s %s from %s refused, not on list',  $which, $mode, $sender);
	return 'not allowed';
    }
    
    ## May set to DIGEST
    if ($mode =~ /^(digest|summary)/ and !$list->is_digest()){
	push @msg::report, sprintf Msg(6, 45, "List %s has no digest mode. Your configuration hasn't been modified.\n"), $which;
	do_log('info', 'SET %s DIGEST from %s refused, no digest mode', $which, $sender);
	return 'not_allowed';
    }
    
    if ($mode =~ /^(mail|nomail|digest|summary|notice|txt|html|urlize|not_me)/){
        # Verify that the mode is allowed
        if (! $list->is_available_reception_mode($mode)) {
	  push @msg::report, sprintf Msg(6, 90, "List %s allows only these reception modes : %s\nYour configuration hasn't been modified.\n"), $which, $list->available_reception_mode;
	  do_log('info','SET %s %s from %s refused, mode not available', $which, $mode, $sender);
	  return 'not_allowed';
	}

	my $update_mode = $mode;
	$update_mode = '' if ($update_mode eq 'mail');
	unless ($list->update_user($sender,{'reception'=> $update_mode, 'update_date' => time})) {
	    push @msg::report, sprintf Msg(6, 92, 'Failed to change your subscriber options for list %s.\n'), $list->{'name'};
	    do_log('info', 'SET %s %s from %s refused, update failed',  $which, $mode, $sender);
	    return 'failed';
	}
	$list->save();
	
	push @msg::report, sprintf Msg(6,40, "Your config file has been updated for list %s.\n"), $which   unless ($quiet || ($action =~ /quiet/i ));

	do_log('info', 'SET %s %s from %s accepted (%d seconds)', $which, $mode, $sender, time-$time_command);
    }
    
    if ($mode =~ /^(conceal|noconceal)/){
	unless ($list->update_user($sender,{'visibility'=> $mode, 'update_date' => time})) {
	    push @msg::report, sprintf Msg(6, 92, 'Failed to change your subscriber options for list %s.\n'), $list->{'name'};
	    do_log('info', 'SET %s %s from %s refused, update failed',  $which, $mode, $sender);
	    return 'failed';
	}
	$list->save();
	
	push @msg::report, sprintf Msg(6,40, "Your config file have been updated on list %s.\n"), $which unless ($quiet || ($action =~ /quiet/i ));
	do_log('info', 'SET %s %s from %s accepted (%d seconds)', $which, $mode, $sender, time-$time_command);
    }

    return 1;
}

## distribute the broadcast of a moderated message
sub distribute {
    my $what =shift;
    my $robot = shift;

    $what =~ /^\s*(\S+)\s+(.+)\s*$/;
    my($which, $key) = ($1, $2);
    $which =~ y/A-Z/a-z/;

    do_log('debug', 'Commands::distribute(%s,%s,%s,%s)', $which,$robot,$key,$what);


    my $start_time=time; # get the time at the beginning
    ## Load the list if not already done, and reject the
    ## subscription if this list is unknown to us.
    my $list = new List ($which, $robot);
    unless ($list) {
	push @msg::report, sprintf Msg(6, 5, "List %s not found.\n"), $which;
	do_log('info', 'DISTRIBUTE %s %s from %s refused, unknown list for robot %s', $which, $key, $sender,$robot);
	return 'unknown_list';
    }

    &Language::SetLang($list->{'admin'}{'lang'});

    #read the moderation queue and purge it
    my $modqueue = $Conf{'queuemod'} ;
    
    my $name = $list->{'name'};
    my $host = $list->{'admin'}{'host'};
    my $file = "$modqueue\/$name\_$key";
    
    ## if the file as been accepted by WWSympa, it's name is different.
    unless (-r $file) {
        $file= "$modqueue\/$name\_$key.distribute";
    }

    ## Open and parse the file
    my $message = new Message($file);
    unless (defined $message) {
	do_log('err', 'Unable to create Message object %s', $file);
	return undef;
    }

    my $msg = $message->{'msg'};
    my $hdr= $msg->head;

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

    $hdr->add('X-Validation-by', $sender);

    ## Distribute the message
    my $numsmtp;
    unless ($numsmtp = $list->distribute_msg($msg, $bytes, $file, $is_crypted)) {
	return undef;
    }

    do_log('info', 'Message for %s from %s accepted (%d seconds, %d sessions), size=%d',
	   $which, $sender, time - $start_time, $numsmtp, $bytes);

    push @msg::report, sprintf Msg(6, 44, "Message %s for list %s has been distributed"), $key, $name   unless ($quiet || ($action =~ /quiet/i ));
    do_log('info', 'DISTRIBUTE %s %s from %s accepted (%d seconds)', $name, $key, $sender, time-$time_command);
    unlink($file);
    
    return 1;
}


# confirm the authentication of a message
sub confirm {
    my $what = shift;
    my $robot = shift;
    do_log('debug', 'Commands::confirm(%s)', $what);

    $what =~ /^\s*(\S+)\s*$/;
    my $key = $1;
    my $start_time = time; # get the time at the beginning

    my $file;

    unless (opendir DIR, $Conf{'queueauth'} ) {
        do_log('info', 'WARNING unable to read %s directory', $Conf{'queueauth'});
    }


    # delete old file from the auth directory
    foreach (grep (!/^\./,readdir(DIR))) {
        if (/\_$key$/i){
	    $file= "$Conf{'queueauth'}\/$_";
        }
    }
    closedir DIR ;
    
    unless ($file) {
        push @msg::report, sprintf Msg(6, 68, "Unable to find the message auth locked by the key %s."),$key;
        do_log('info', 'CONFIRM %s from %s refused, auth failed', $key,$sender);
        return 'wrong_auth';
    }

    my $message = new Message ($file);
    unless (defined $message) {
	do_log('err', 'Unable to create Message object %s', $file);
	return undef;
    }

    my $msg = $message->{'msg'};
    my $list = $message->{'list'};

    &Language::SetLang($list->{'admin'}{'lang'});

    my $name = $list->{'name'};
   
    my $bytes = -s $file;
    my $hdr= $msg->head;

    my $action = &List::request_action('send','md5',$robot,
				       {'listname' => $name, 
					'sender' => $sender ,
					'msg' => $msg});

    return undef
	unless (defined $action);

    if ($action =~ /^editorkey/) {
	my $key = $list->send_to_editor('md5', $message);
	do_log('info', 'Key %s for list %s from %s sent to editors', $key, $name, $sender);
	$list->notify_sender($sender);
	return 1;
    }elsif($action =~ /editor/){
	my $key = $list->send_to_editor('smtp', $message);
	do_log('info', 'Message for %s from %s sent to editors', $name, $sender);
	$list->notify_sender($sender);
	return 1;
    }elsif($action =~ /^reject(\(\'?(\w+)\'?\))?/) {
	my $tpl = $2;
   	do_log('notice', 'Message for %s from %s rejected, sender not allowed', $name, $sender);
	if ($tpl) {
	    $list->send_file($tpl, $sender, $robot, {});
	}else {
	    *SIZ  = smtp::smtpto(&Conf::get_robot_conf($robot, 'request'), \$sender);
	    print SIZ "From: " . sprintf (Msg(12, 4, 'SYMPA <%s>'), &Conf::get_robot_conf($robot, 'request')) . "\n";
	    printf SIZ "To: %s\n", $sender;
	    printf SIZ "Subject: " . Msg(4, 11, "Your message for list %s has been rejected") . "\n", $name;
	    printf SIZ "MIME-Version: %s\n", Msg(12, 1, '1.0');
	    printf SIZ "Content-Type: text/plain; charset=%s\n", Msg(12, 2, 'us-ascii');
	    printf SIZ "Content-Transfer-Encoding: %s\n\n", Msg(12, 3, '7bit');
	    printf SIZ Msg(4, 15, $msg::list_is_private), $name;
	    $msg->print(\*SIZ);
	    close(SIZ);
	    return 1;
	}
    }elsif($action =~ /^do_it/) {

	$hdr->add('X-Validation-by', $sender);
	
	## Distribute the message
	my $numsmtp;
	unless ($numsmtp = $list->distribute_msg($msg, $bytes, $file, $is_crypted)) {
	    return undef;
	}

	push @msg::report, sprintf Msg(6, 44, "Message %s for list %s has been distributed."), $key, $name   unless ($quiet || ($action =~ /quiet/i ));
	do_log('info', 'CONFIRM %s from %s for list %s accepted (%d seconds)', $key, $sender, $which, time-$time_command);
	unlink($file);
	
	return 1;
    }
}

## Refuse and delete  a moderated message
sub reject {
    my $what = shift;
    my $robot = shift;

    do_log('debug', 'Commands::reject(%s)', $what);

    $what =~ /^(\S+)\s+(.+)\s*$/;
    my($which, $key) = ($1, $2);
    $which =~ y/A-Z/a-z/;
    my $modqueue = $Conf{'queuemod'};
    ## Load the list if not already done, and reject the
    ## subscription if this list is unknown to us.
    my $list = new List ($which, $robot);
    unless ($list) {
	push @msg::report, sprintf Msg(6, 5, "List %s not found.\n"), $which;
	do_log('info', 'REJECT %s %s from %s refused, unknown list for robot %s', $which, $key, $sender,$robot);
	return 'unknown_list';
    }

    &Language::SetLang($list->{'admin'}{'lang'});

    my $name = "$list->{'name'}";
    my $file= "$modqueue\/$name\_$key";


    my $msg;
    my $parser = new MIME::Parser;
    $parser->output_to_core(1);
    unless ($msg = $parser->read(\*IN)) {
	do_log('notice', 'Unable to parse message');
	return undef;
    }

    close(IN);
    
    my $bytes = -s $file;
    my $hdr= $msg->head;
    my $customheader = $list->{'admin'}{'custom_header'};
    my $to_field = $hdr->get('To');


    
    ## Open the file
    if (!open(IN, $file)) {
	push @msg::report, sprintf Msg(6, 41, "Unable to find the message of the list %s locked by the key %s.\nWarning : this message could have ever been send by another editor"),$name,$key ;
	do_log('info', 'REJECT %s %s from %s refused, auth failed', $which, $key, $sender);
	return 'wrong_auth';
    }
    do_log('debug2', 'message to be rejected by %s',$sender);
    unless ($quiet || ($action =~ /quiet/i )) {
	push @msg::report, sprintf Msg(6, 43, "Message %s for list %s has been rejected"),$key, $name  ;

	my $message;
	my $parser = new MIME::Parser;
	$parser->output_to_core(1);
	unless ($message = $parser->read(\*IN)) {
	    do_log('notice', 'Unable to parse message');
	    return undef;
	}

	my @sender_hdr = Mail::Address->parse($message->head->get('From'));
        unless  ($#sender_hdr == -1) {
	    my $rejected_sender = $sender_hdr[0]->address;
	    my %context;
	    $context{'subject'} = &MIME::Words::decode_mimewords($message->head->get('subject'));
	    $context{'rejected_by'} = $sender;
	    do_log('debug2', 'message %s by %s rejected sender %s',$context{'subject'},$context{'rejected_by'},$rejected_sender);


	    $list->send_file('reject', $rejected_sender, $robot, \%context);
	}
    }
    close(IN);
    do_log('info', 'REJECT %s %s from %s accepted (%d seconds)', $name, $sender, $key, time-$time_command);
    unlink($file);

    return 1;
}

## EXPIRE <list> <from nb day> <nb day to confirm>
sub expire {
    my $what = shift;
    my $robot=shift;

    do_log('debug', 'Commands::expire(%s)', $what);

    my @msgexp = @_;
    my $name, $d1, $d2;
    if ($what =~ /^\s*(\S+)\s+(\d+)\s+(\d+)/) {
	($name, $d1, $d2) = ($1, $2, $3);
	$name =~ y/A-Z/a-z/;
    }else {
	push @msg::report, sprintf Msg(6, 13, "Syntax error.\n");
	do_log('info', 'EXPIRE %s from %s refused, syntax error', $name, $sender);
	return 'syntax_error';
    }
    my $nb_words_max=20;
    my $queueexpire =$Conf{'queueexpire'};
    my $key;
    ## Load the list if not already done, and reject the
    ## subscription if this list is unknown to us.
    my $list = new List ($name, $robot);
    unless ($list) {
	push @msg::report, sprintf Msg(6, 5, "List %s not found.\n"), $name;
	do_log('info', 'EXPIRE %s %d %d from %s refused, unknown list for robot %s', $name, $d1 , $d2, $sender,$robot);
	return 'unknown_list';
    }

    &Language::SetLang($list->{'admin'}{'lang'});

    $name = "$list->{'name'}";
    my $file= "$queueexpire\/$name";
    my ($limitday,$confirmday,$proprio);

    ## Check if the requestor is an authorized owner for this list.
    unless ($list->may_do('expire', $sender)) {
        push @msg::report, sprintf Msg(6, 47, $msg::not_owner_expire), $name;
        do_log('info', 'EXPIRE %s %d %d from %s refused, not allowed', $name,
	      $d1,$d2,$sender);
        return 'not_allowed';
    }

    ## Check if the message is long enough
    if (! $auth) {
        my $nbwords=0;
        my @words;
        foreach(@msgexp){
	    @words=split (/[\s\,\;\-\_]/,$_);
	    $nbwords+=$#words+1 if ($#words>=0); 
        }   
	unless ($nbwords>=$nb_words_max){
	    push @msg::report, sprintf Msg(6, 60,$msg::expire_end ), $nb_words_max;
	    push @msg::report, "\n\n";
	    push @msg::report, sprintf Msg(6, 61,"Your rejected message is :\n");
	    foreach(@msgexp){
		push @msg::report, $_;
	    }
	    do_log('info', 'EXPIRE %s %d %d from %s refused, error in message', $name,
		   $d1,$d2,$sender);
	    return 'syntax_error';
	}
    }

    ## Now check the auth stuff.
    if ($auth) {
	## An expire process in already running
	if (-e $file) {

	    if (! open IN, $file) {
		do_log('info', 'EXPIRE %s %d %d from %s refused, file %s unreadable', $name, $d1,$d2,$sender,$file);
		return 'no_file';
	    }
	    
	    ## Parse the expire config. file
	    if (<IN> =~ /^(\d+)\D+(\d+)$/){
		$limitday=$1;
		$confirmday=$2;
		#converting dates.....
		$d1 = int((time-$limitday)/86400);
		$d2 = int(($confirmday-time)/86400);
	    }
	    
	    if (<IN> =~ /^(.*)$/){
		$proprio=$1;
	    }
	    
	    undef @msgexp; 
	    while (<IN> =~ /^(end|quit|exit)/i ){
		# store the expire message in @msgexp
		push(@msgexp, $_);		
	    }
	    close(IN);
	    my @timefile= localtime( (stat "$file")[9]);
	    
	    push @msg::report, sprintf Msg(6, 49, $msg::expire_running), $name, $proprio, POSIX::strftime("%a %b %e %H:%M:%S %Y",@timefile), $d1, $d2, POSIX::strftime("%a %b %e %H:%M:%S %Y", localtime($confirmday));
	    push @msg::report, sprintf Msg(6, 57, $msg::expireindex_info), $name;       
	    push @msg::report, sprintf Msg(6, 53, $msg::expiredel_info), $name;
	    do_log('info', 'EXPIRE %s %d %d from %s refused, another expire is running', $name,
		   $limitday,$confirmday,$sender);
	    return 'not_allowed';
	    
	}else{ 
	    ## Check the auth response

            ## Read the temporary config file .<nomliste>_<mk5key>
	    ## Auth failed
	    if (! open(IN, "$queueexpire\/\.$name\_$auth")) {
		push @msg::report, sprintf Msg(6, 15, $msg::wrong_authenticator);
		do_log('info', 'EXPIRE %s %d %d from %s refused, auth failed', $name,
		       $limitday,$confirmday,$sender);
		return 'wrong_auth';
	    }
	    
	    ## Parse the expire config file
	    if (<IN>=~/^(\d+)\D+(\d+)$/){
		$limitday=$1;
		$confirmday=$2;
		#converting dates.....
		$d1 = int((time-$limitday)/86400);
		$d2 = int(($confirmday-time)/86400);
	    }

	    if (<IN>=~/^(.*)$/){
		$proprio=$1;
	    }

	    undef @msgexp;
	    while (<IN> ){
		last if (/^(end|quit|exit)/i);
		push(@msgexp, $_);
	    }
	    close(IN);
	    unlink "$queueexpire\/\.$name\_$auth";

	    push @msg::report, sprintf Msg(6, 56, $msg::expire_comment), $name, $d2;	   	    	    
	    push @msg::report, sprintf Msg(6, 69, "%s posted your expiration message to the following addresses :\n"), &Conf::get_robot_conf($robot, 'sympa');

	    ## Send the confirmation request to concerned subscribers
	    my $user;

	    unless ($user = $list->get_first_user()) {
		return undef;
}
	    do {
		next unless ($user->{'date'} < $limitday);
		push @msg::report, "   $user->{'email'}\n";      
		&mail::mailback(\@msgexp, 
				{'Subject' => sprintf(Msg(6, 21, "Renewal of your subscription to %s"), $name)},
				'sympa', $user->{'email'}, $user->{'email'}, $robot);
	    } while ($user = $list->get_next_user());

	    push @msg::report, "\n";
	    push @msg::report, sprintf Msg(6, 57, $msg::expireindex_info), $name;       
	    push @msg::report, sprintf Msg(6, 53, $msg::expiredel_info), $name;


	    ## Save the expire config in the expirequeue
	    ## (The expire itself will be triggered in sympa.pl)
	    if (!-e $file) {
		open(OUT,">$file");
		print OUT "$limitday $confirmday\n";
		print OUT "$sender\n";
		print OUT "\n";
		close (OUT);       
	    }
	    do_log('info', 'EXPIRE %s %d %d from %s accepted (%d seconds)', $name, $d1, $d2, $sender, time-$time_command);    
	}
    }else { 
        ## Ask the requestor for an authentication
	$key=substr(Digest::MD5::md5_hex(join('/', $list->get_cookie(), $name, $sender, $d1, $d2, 'expire', time)), -8);
	push @msg::report, sprintf Msg(6, 48, $msg::expire_need_auth), $name, $d1, &Conf::get_robot_conf($robot, 'sympa'),$key,$name, $d1, $d2;

	$limitday= time - 86400* $d1;
	$confirmday= time + 86400* $d2;
	
	## Save the config in a temporary file
	open(OUT,">$queueexpire\/\.$name\_$key");
	print OUT "$limitday $confirmday\n";
	print OUT "$sender\n";
	print OUT "\n";
	foreach(@msgexp){
	    print OUT $_;
	}
	print OUT "end";
	close (OUT);       
	do_log('info', 'EXPIRE %s %d %d from %s authentified (%d seconds)', $name, $d1, $d2,
	       $sender, time-$time_command);
	return 1;
    }

    return 1;
}

sub _expirecheck {
## list all expired adress in a list
    my ($name,$limitday) = @_;
    my $robot = shift;

    my $list,$user,$count;

    my $list = new List ($name, $robot);
    unless ($list) {
	do_log ('info',"unable to create list for expire $name");
	return 'unknown_list';
    }
    
    $count = 0 ;

    unless ($user = $list->get_first_user()) {
	return undef;
}

    do {
	next unless ($user->{'date'} < $limitday);
	push @msg::report, sprintf "DEL   $name   $user->{'email'}\n";
        $count++
    } while ($user = $list->get_next_user());
    push @msg::report, sprintf "\n\n%d",$count;

}
## Give the current configuration of the expiration
sub expireindex {
    my $name = shift;
    my $robot = shift;

    $name =~ y/A-Z/a-z/;
    do_log('debug', 'Commands::expireindex(%s)', $name);

    ## Load the list if not already done, and reject the
    ## subscription if this list is unknown to us.
    my $list = new List ($name, $robot);
    unless ($list) {
	push @msg::report, sprintf Msg(6, 5, "List %s not found.\n"), $name;
	do_log('info', 'EXPIREINDEX %s from %s refused, unknown list for list %s', $name, $sender,$robot);
	return 'unknown_list';
    } 

    &Language::SetLang($list->{'admin'}{'lang'});

    my $queueexpire =$Conf{'queueexpire'};
    $name = "$list->{'name'}";
    my $file= "$queueexpire\/$name";
    my ($limitday,$confirmday,$proprio);
    my ($d1,$d2);

    ## Check if the requestor is an authorized owner for this list.
    unless ($list->may_do('expire', $sender)) {
	push @msg::report, sprintf Msg(6, 47, $msg::not_owner_expire), $name;
	do_log('info', 'EXPIREINDEX %s from %s refused, not allowed', $name,$sender);
	return 'not_allowed';
    }

    ## Open and read the file
    if (-e $file) {
	if (!open(IN, $file)) {
	    do_log('info', 'EXPIREINDEX %s from %s refused, file %s unreadable', $name,
		   $sender,$file);
	    return 'no_file';
	}

	## Parse the config file 
	if (<IN>=~/^(\d+)\D+(\d+)$/){
	    $limitday=$1;
	    $confirmday=$2;
	    #converting dates.....
	    $d1= int((time-$limitday)/86400);
	    $d2= int(($confirmday-time)/86400);
	}

	if (<IN>=~/^(.*)$/){
	    $proprio=$1;
	}
	close(IN);
	my @timefile= localtime( (stat "$file")[9]);

	 push @msg::report, sprintf Msg(6, 49, $msg::expire_running), $name, $proprio, POSIX::strftime("%a %b %e %H:%M:%S %Y",@timefile), $d1, $d2, POSIX::strftime("%a %b %e %H:%M:%S %Y", localtime($confirmday));

	push @msg::report, sprintf Msg(6, 52, "%s did not receive confirmation for the following addresses :\n"), &Conf::get_robot_conf($robot, 'sympa');
	push @msg::report, "\n";
	my $temp = 0;
	my $user;

	unless ($user = $list->get_first_user()) {
	    return undef;
}

        do {
	    next unless ($user->{'date'} < $limitday);
	    push @msg::report, "," if ($temp==1);
	    push @msg::report, " $user->{'email'} ";
	    $temp = 1 if ($temp==0);
	} while ($user = $list->get_next_user());
	push @msg::report, "\n\n";
	push @msg::report, sprintf Msg(6, 58, "If you want to delete these subscribers, please use the following commands :\n");
	push @msg::report, "\n";

	unless ($user = $list->get_first_user()) {
	    return undef;
	}

	do {
	    next unless ($user->{'date'} < $limitday);
	    push @msg::report, sprintf "DEL   $name   $user->{'email'}\n";
	} while ($user = $list->get_next_user());

	do_log('info', 'EXPIREINDEX %s from %s accepted (%d seconds)', $name,
	       $sender,time-$time_command);
	return 1;
    }else{
	push @msg::report, sprintf Msg(6, 54, "There is no expire for the list %s \n"),$name;
	do_log('info', 'EXPIREINDEX %s from %s refused, no current expire', $name, $sender);
	return 'not_allowed';
   }

    return 1;
}

## Give the current configuration of the expiration
sub expiredel {
    my $name = shift;
    my $robot = shift;
    $name =~ y/A-Z/a-z/;
    do_log('debug', 'Commands::expiredel(%s)', $name);

    ## Load the list if not already done, and reject the
    ## subscription if this list is unknown to us.
    my $list = new List ($name, $robot);
    unless ($list) {
	push @msg::report, sprintf Msg(6, 5, "List %s not found.\n"), $name;
 	do_log('info', 'EXPIREDEL %s from %s refused, unknown list for robot', $name, $sender, $robot);
 	return 'unknown_list';
    }

    &Language::SetLang($list->{'admin'}{'lang'});

    my $queueexpire =$Conf{'queueexpire'};
    $name = "$list->{'name'}";
    my $file= "$queueexpire\/$name";
    my ($limitday,$confirmday,$proprio);
   ## Check if the requestor is an authorized owner for this list.
   unless ($list->may_do('expire', $sender)) {
       push @msg::report, sprintf Msg(6, 47, $msg::not_owner_expire), $name;
       do_log('info', 'EXPIREDEL %s from %s refused, not allowed', $name,$sender);
       return 'not_allowed';
   }
   ## Open and read the file
   if (-e $file) {
       unlink($file);
       push @msg::report, sprintf Msg(6, 55, "You have canceled the current expire process on list \"%s\"\n"),$name;  
       do_log('info', 'EXPIREDEL %s from %s accepted (%d seconds)', $name,
	  $sender,time-$time_command);
      return 1;
   }else{
       push @msg::report, sprintf Msg(6, 54, "There is no expire for the list %s \n"),$name;
       do_log('info', 'EXPIREDEL %s from %s refused, no current expire', $name, $sender);
   }

    return 1;
}


## Send a list of currents messages to moderate of a list
## usage :    modindex <liste> 
sub modindex {
    my $name = shift;
    my $robot = shift;
    do_log('debug', 'Commands::modindex(%s)', $name);
    
    $name =~ y/A-Z/a-z/;

    my $list = new List ($name, $robot);
    unless ($list) {
	push @msg::report, sprintf Msg(6, 5, "List %s not found.\n"), $name;
	do_log('info', 'MODINDEX %s from %s refused, unknown list for robot %s', $name, $sender, $robot);
	return 'unknown_list';
    }

    &Language::SetLang($list->{'admin'}{'lang'});

    my $modqueue = $Conf{'queuemod'};
    
    my $i;
    
    unless ($list->may_do('modindex', $sender)) {
	push @msg::report, sprintf Msg(6, 46, "Only editors can use the command modindex. You are not  an editor of the list %s.\n"),$name ;
	do_log('info', 'MODINDEX %s from %s refused, not allowed', $name,$sender);
	return 'not_allowed';
    }

    # purge the queuemod -> delete old files
    if (!opendir(DIR, $modqueue)) {
	do_log('info', 'WARNING unable to read %s directory', $modqueue);
    }
    my @qfile = sort grep (!/^\.+$/,readdir(DIR));
    closedir(DIR);
    my ($curlist,$moddelay);
    foreach $i (sort @qfile) {

	## Erase diretories used for web modindex
	if (-d "$modqueue/$i") {
	    unlink <$modqueue/$i/*>;
	    rmdir "$modqueue/$i";
	    next;
	}

	$i=~/\_(.+)$/;
	$curlist = new List ($`);
	if ($curlist) {
	    # list loaded    
	    if (exists $curlist->{'admin'}{'clean_delay_queuemod'}){
		$moddelay = $curlist->{'admin'}{'clean_delay_queuemod'}
	    }else{
		$moddelay =  $Conf{'clean_delay_queuemod'};
	    }
	    
	    if ((stat "$modqueue/$i")[9] < (time -  $moddelay*86400) ){
		unlink ("$modqueue/$i") ;
		do_log('notice', 'Deleting unmoderated message %s, too old', $i);
	    };
	}
    }

    opendir(DIR, $modqueue);

    my @files = ( sort grep (/^$name\_/,readdir(DIR)));
    closedir(DIR);
    my $n;
    my @now = localtime(time);

    ## List of messages
    my @spool;

    foreach $i (@files) {
	## skip message allready marked to be distributed using WWS
	next if ($i =~ /.distribute$/) ;

	## Push message for building MODINDEX
	my $raw_msg;
	open(IN, "$modqueue\/$i");
	while (<IN>) {
	    $raw_msg .= $_;
	}
	close IN;
	push @spool, $raw_msg;

	$n++;
    }
    
    unless ($n){
	do_log('info', 'MODINDEX %s from %s refused, no message to moderate', $name, $sender);
	return 'no_file';
    }  
    
    $list->send_file('modindex', $sender, $robot, {'spool' => \@spool,
					   'total' => $n,
					   'boundary1' => "==main $now[6].$now[5].$now[4].$now[3]==",
					   'boundary2' => "==digest $now[6].$now[5].$now[4].$now[3]=="});

    do_log('info', 'MODINDEX %s from %s accepted (%d seconds)', $name,
	   $sender,time-$time_command);
    
    return 1;
}

## WHICH
## return information about the sender 
sub which {
    my($listname, @which);
    shift;
    my $robot = shift;
    do_log('debug', 'Commands::which(%s)', $listname);
    
    ## Subscriptions
    push @msg::report, sprintf  Msg(6, 67, "List of your current subscriptions : \n\n");    
    foreach $listname (List::get_which ($sender,$robot,'member')){
	next unless (&List::request_action ('visibility', 'smtp',$robot,
					    {'listname' =>  $listname,
					     'sender' => $sender}) =~ /do_it/);
	push @msg::report, sprintf "\t%s\n",$listname;
    }

    ## Ownership
    if (@which = List::get_which ($sender,$robot,'owner')){
	push @msg::report, sprintf  Msg(6, 72, " Here are the lists where you are owner: \n\n");
	foreach $listname (@which){
	    push @msg::report, sprintf "\t%s\n",$listname;
	}
    }

    ## Editorship
    if (@which = List::get_which ($sender,$robot,'editor')){
	push @msg::report, sprintf  Msg(6, 73, " Here are the lists where you are editor: \n\n");
	foreach $listname (@which){
	    push @msg::report, sprintf "\t%s\n",$listname;
	}
    }

    do_log('info', 'WHICH from %s accepted (%d seconds)', $sender,time-$time_command);

    return 1;
}

# end of package
1;





