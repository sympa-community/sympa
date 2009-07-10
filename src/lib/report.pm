# report.pm - This module provides various tools for command and message 
# diffusion report
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

package report;

use strict;

use Language;
use Log;
use List;

######################## MESSAGE DIFFUSION REPORT #############################################


############################################################
#  reject_report_msg
############################################################
#  Send a notification to the user about an error rejecting
#  its message diffusion, using mail_tt2/message_report.tt2
#  
# IN : -$type (+): 'intern'||'intern_quiet'||'user'||auth' - the error type 
#      -$error : scalar - the entry in message_report.tt2 if $type = 'user'
#                       - string error for listmaster if $type = 'intern'
#                       - the entry in authorization reject (called by message_report.tt2)
#                               if $type = 'auth'
#      -$user (+): scalar - the user to notify
#      -$param : ref(HASH) - var used in message_report.tt2
#         $param->msg_id (+) if $type='intern'
#      -$robot (+): robot
#      -$msg_string : string - rejected msg 
#      -$list : ref(List)
#
# OUT : 1
#
############################################################## 
sub reject_report_msg {
    my ($type,$error,$user,$param,$robot,$msg_string,$list) = @_;
    &do_log('debug2', "reject::reject_report_msg(%s,%s,%s)", $type,$error,$user);

    unless ($type eq 'intern' || $type eq 'intern_quiet' || $type eq 'user'|| $type eq 'auth') {
	&do_log('err',"report::reject_report_msg(): error to prepare parsing 'message_report' template to $user : not a valid error type");
	return undef
    }

    unless ($user){
	&do_log('err',"report::reject_report_msg(): unable to send template command_report.tt2 : no user to notify");
	return undef;
    }
 
    unless ($robot){
	&do_log('err',"report::reject_report_msg(): unable to send template command_report.tt2 : no robot");
	return undef;
    }

    chomp($user);
    $param->{'to'} = $user;
    $param->{'msg'} = $msg_string;
    $param->{'auto_submitted'} = 'auto-replied';

    if ($type eq 'user') {
	$param->{'entry'} = $error;
	$param->{'type'} = 'user_error';

    } elsif ($type eq 'auth') {
	$param->{'entry'} = $error;
	$param->{'type'} = 'authorization_reject';

    } else {
	$param->{'type'} = 'intern_error';
    }

    ## Prepare the original message if provided
    if (defined $param->{'message'}) {
	$param->{'original_msg'} = &_get_msg_as_hash($param->{'message'});
     }

    if (ref($list) eq "List") {
	unless ($list->send_file('message_report',$user,$robot,$param)) {
	    &do_log('notice',"report::reject_report_msg(): Unable to send template 'message_report' to '$user'");
	}
    } else {
	unless (&List::send_global_file('message_report',$user,$robot,$param)) {
	    &do_log('notice',"report::reject_report_msg(): Unable to send template 'message_report' to '$user'");
	}
    }
    if ($type eq 'intern') {
	chomp($param->{'msg_id'});

	$param ||= {}; 
	$param->{'error'} =  &gettext($error);
	$param->{'who'} = $user;
	$param->{'action'} = 'message diffusion';
	$param->{'msg_id'} = $param->{'msg_id'};
	$param->{'list'} = $list if (defined $list);
	unless (&List::send_notify_to_listmaster('mail_intern_error', $robot, $param)) {
	    &do_log('notice',"report::reject_report_msg(): Unable to notify_listmaster concerning '$user'");
	}
    }
    return 1;
}



############################################################
#  _get_msg_as_hash
############################################################
#  Internal subroutine
#  Provide useful parts of a message as a hash entries
#  
# IN : -$msg_object (+): ref(HASH) - the MIME::Entity or Message object
#
# OUT : $msg_hash : ref(HASH) - the hashref
#
############################################################## 

sub _get_msg_as_hash {
    my $msg_object = shift;

    my ($msg_entity, $msg_hash);

    if (ref($msg_object) =~ /^MIME::Entity/) { ## MIME-ttols object
	$msg_entity = $msg_object;
    }elsif (ref($msg_object) =~ /^Message/) { ## Sympa's own Message object
	$msg_entity = $msg_object->{'msg'};
    }else {
	&do_log('err', "reject_report_msg: wrong type for msg parameter");
    }
    
    my $head = $msg_entity->head;
    my $body_handle = $msg_entity->bodyhandle;
    my $body_as_string;
    
    if (defined $body_handle) {
	$body_as_string = $body_handle->as_lines();
    }

    ## TODO : we should also decode headers + remove trailing \n + use these variables in default mail templates

    $msg_hash = {'full' => $msg_entity->as_string, 
		 'body' => $body_as_string,
		 'from' => $head->get('From'),
		 'subject' => $head->get('Subject'),
		 'message_id' => $head->get('Message-Id')
		 };

    return $msg_hash;
}

############################################################
#  notice_report_msg
############################################################
#  Send a notification to the user about a success for its
#   message diffusion, using mail_tt2/message_report.tt2
#  
# IN : -$entry (+): scalar - the entry in message_report.tt2
#      -$user (+): scalar - the user to notify
#      -$param : ref(HASH) - var used in message_report.tt2
#      -$robot (+) : robot
#      -$list : ref(List)
#
# OUT : 1
#
############################################################## 
sub notice_report_msg {
    my ($entry,$user,$param,$robot,$list) = @_;

    $param->{'to'} = $user;
    $param->{'type'} = 'success';   
    $param->{'entry'} = $entry;
    $param->{'auto_submitted'} = 'auto-replied';

    unless ($user){
	&do_log('err',"report::notice_report_msg(): unable to send template message_report.tt2 : no user to notify");
	return undef;
    }
 
    unless ($robot){
	&do_log('err',"report::notice_report_msg(): unable to send template message_report.tt2 : no robot");
	return undef;
    }

    ## Prepare the original message if provided
    if (defined $param->{'message'}) {
	$param->{'original_msg'} = &_get_msg_as_hash($param->{'message'});
     }

    if (ref($list) eq "List") {
	unless ($list->send_file('message_report',$user,$robot,$param)) {
	    &do_log('notice',"report::notice_report_msg(): Unable to send template 'message_report' to '$user'");
	}
    } else {
	unless (&List->send_global_file('message_report',$user,$robot,$param)) {
	    &do_log('notice',"report::notice_report_msg(): Unable to send template 'message_report' to '$user'");
	}
    }

    return 1;
}




########################### MAIL COMMAND REPORT #############################################


# for rejected command because of internal error
my @intern_error_cmd;
# for rejected command because of user error
my @user_error_cmd;
# for errors no relative to a command
my @global_error_cmd;
# for rejected command because of no authorization
my @auth_reject_cmd;
# for command notice
my @notice_cmd;



#########################################################
# init_report_cmd
#########################################################
#  init arrays for mail command reports :
#
# 
# IN : -
#
# OUT : - 
#      
######################################################### 
sub init_report_cmd {

    undef @intern_error_cmd;
    undef @user_error_cmd;
    undef @global_error_cmd;
    undef @auth_reject_cmd;
    undef @notice_cmd;
}


#########################################################
# is_there_any_report_cmd
#########################################################
#  Look for some mail command report in one of arrays report
# 
# IN : -
#
# OUT : 1 if there are some reports to send
#      
######################################################### 
sub is_there_any_report_cmd {
    
    return (@intern_error_cmd ||
	    @user_error_cmd ||
	    @global_error_cmd ||
	    @auth_reject_cmd ||
	    @notice_cmd );
}


#########################################################
# send_report_cmd
#########################################################
#  Send the template command_report to $sender 
#   with global arrays :
#  @intern_error_cmd,@user_error_cmd,@global_error_cmd,
#   @auth_reject_cmd,@notice_cmd.
#
# 
# IN : -$sender (+): SCALAR
#      -$robot (+): SCALAR
#
# OUT : 1 if there are some reports to send
#      
######################################################### 
sub send_report_cmd {
    my ($sender,$robot) = @_;

    unless ($sender){
	&do_log('err',"report::send_report_cmd(): unable to send template command_report.tt2 : no user to notify");
	return undef;
    }
 
    unless ($robot){
	&do_log('err',"report::send_report_cmd() : unable to send template command_report.tt2 : no robot");
	return undef;
    }

   
    # for mail layout
    my $before_auth = 0;
    $before_auth = 1 if ($#notice_cmd +1);

    my $before_user_err;
    $before_user_err = 1 if ($before_auth || ($#auth_reject_cmd +1));

    my $before_intern_err;
    $before_intern_err = 1 if ($before_user_err || ($#user_error_cmd +1));

    chomp($sender);

    my $data = { 'to' => $sender,
	         'nb_notice' =>$#notice_cmd +1,
		 'nb_auth' => $#auth_reject_cmd +1,
		 'nb_user_err' => $#user_error_cmd +1,
		 'nb_intern_err' => $#intern_error_cmd +1,
		 'nb_global' => $#global_error_cmd +1,	
		 'before_auth' => $before_auth,
		 'before_user_err' => $before_user_err,
		 'before_intern_err' => $before_intern_err,
		 'notices' => \@notice_cmd,
		 'auths' => \@auth_reject_cmd,
		 'user_errors' => \@user_error_cmd,
		 'intern_errors' => \@intern_error_cmd,
		 'globals' => \@global_error_cmd,
	     };

		 

    unless (&List::send_global_file('command_report',$sender,$robot,$data)) {
	&do_log('notice',"report::send_report_cmd() : Unable to send template 'command_report' to $sender");
    }
    
    &init_report_cmd();
}


#########################################################
# global_report_cmd
#########################################################
#  puts global report of mail with commands in 
#  @global_report_cmd  used to send message with template 
#  mail_tt2/command_report.tt2
#  if $now , the template is sent now
#  if $type eq 'intern', the listmaster is notified
# 
# IN : -$type (+): 'intern'||'intern_quiet||'user'
#      -$error : scalar - $glob.entry in command_report.tt2 if $type = 'user'
#                          - string error for listmaster if $type = 'intern'
#      -$data : ref(HASH) - var used in command_report.tt2
#      -$sender :  required if $type eq 'intern' or if $now
#                  scalar - the user to notify 
#      -$robot :   required if $type eq 'intern' or if $now
#                  scalar - to notify useror listmaster
#      -$now : send now if true
#
# OUT : 1|| undef  
#      
######################################################### 
sub global_report_cmd {
    my ($type,$error,$data,$sender,$robot,$now) = @_;
    my $entry;

    unless ($type eq 'intern' || $type eq 'intern_quiet' || $type eq 'user') {
	&do_log('err',"report::global_report_msg(): error to prepare parsing 'command_report' template to $sender : not a valid error type");
	return undef;
    }
    
    if ($type eq 'intern') {

	if ($robot){
	    my $param = $data;
	    $param ||= {};
	    $param->{'error'} = &gettext($error);
	    $param->{'who'} = $sender;
	    $param->{'action'} = 'Command process';
	    
	    unless (&List::send_notify_to_listmaster('mail_intern_error', $robot,$param)) {
		&do_log('notice',"report::global_report_cmd(): Unable to notify listmaster concerning '$sender'");
	    }
	} else {
	    &do_log('notice',"report::global_report_cmd(): unable to send notify to listmaster : no robot");
	}	
    }

    if ($type eq 'user') {
	$entry = $error;

    } else {
	$entry = 'intern_error';
    }

    $data ||= {};
    $data->{'entry'} = $entry;
    push @global_error_cmd, $data;

    if ($now) {
	unless ($sender && $robot){
	    &do_log('err',"report::global_report_cmd(): unable to send template command_report now : no sender or robot");
	    return undef;
	}	
	&send_report_cmd($sender,$robot);
	
    }
}


#########################################################
# reject_report_cmd
#########################################################
#  puts errors reports of processed commands in 
#  @user/intern_error_cmd, @auth_reject_cmd  
#  used to send message with template 
#  mail_tt2/command_report.tt2
#  if $type eq 'intern', the listmaster is notified
# 
# IN : -$type (+): 'intern'||'intern_quiet||'user'||'auth'
#      -$error : scalar - $u_err.entry in command_report.tt2 if $type = 'user'
#                       - $auth.entry in command_report.tt2 if $type = 'auth' 
#                       - string error for listmaster if $type = 'intern'
#      -$data : ref(HASH) - var used in command_report.tt2
#      -$cmd : SCALAR - the rejected cmd : $xx.cmd in command_report.tt2
#      -$sender :  required if $type eq 'intern' 
#                  scalar - the user to notify 
#      -$robot :   required if $type eq 'intern'
#                  scalar - to notify listmaster
#
# OUT : 1|| undef  
#      
######################################################### 
sub reject_report_cmd {
    my ($type,$error,$data,$cmd,$sender,$robot) = @_;

    unless ($type eq 'intern' || $type eq 'intern_quiet' || $type eq 'user' || $type eq 'auth') {
	&do_log('err',"report::reject_report_cmd(): error to prepare parsing 'command_report' template to $sender : not a valid error type");
	return undef;
    }
    
    if ($type eq 'intern') {
	if ($robot){
	    
	    my $listname;
	    if (defined $data->{'listname'}) {
		$listname = $data->{'listname'};
	    }
	    
	    my $param = $data;
	    $param ||= {};
	    $param->{'error'} = &gettext($error);
	    $param->{'cmd'} = $cmd;
	    $param->{'listname'} = $listname;
	    $param->{'who'} = $sender;
	    $param->{'action'} = 'Command process';

	    unless (&List::send_notify_to_listmaster('mail_intern_error', $robot,$param)) {
		&do_log('notice',"report::reject_report_cmd(): Unable to notify listmaster concerning '$sender'");
	    }
	} else {
	    &do_log('notice',"report::reject_report_cmd(): unable to notify listmaster for error: '$error' : (no robot) ");
	}	
    }
	
    $data ||= {};
    $data->{'cmd'} = $cmd;

    if ($type eq 'auth') {
	$data->{'entry'} = $error;
	push @auth_reject_cmd,$data;

    } elsif ($type eq 'user') {
	$data->{'entry'} = $error;
	push @user_error_cmd,$data;

    } else {
	$data->{'entry'} = 'intern_error';
	push @intern_error_cmd, $data;

    }

}

#########################################################
# notice_report_cmd
#########################################################
#  puts notices reports of processed commands in 
#  @notice_cmd used to send message with template 
#  mail_tt2/command_report.tt2
# 
# IN : -$entry : $notice.entry to select string in
#               command_report.tt2
#      -$data : ref(HASH) - var used in command_report.tt2
#      -$cmd : SCALAR - the noticed cmd
#
# OUT : 1
#      
######################################################### 
sub notice_report_cmd {
    my ($entry,$data,$cmd) = @_;
   
    $data ||= {};
    $data->{'cmd'} = $cmd;
    $data->{'entry'} = $entry;
    push @notice_cmd, $data;
}



########################### WEB COMMAND REPORT #############################################


# for rejected web command because of internal error
my @intern_error_web;
# for rejected web command because of system error 
my @system_error_web;
# for rejected web command because of user error
my @user_error_web;
# for rejected web command because of no authorization
my @auth_reject_web;
# for web command notice
my @notice_web;


#########################################################
# init_report_web
#########################################################
#  init arrays for web reports :
#
# 
# IN : -
#
# OUT : - 
#      
######################################################### 
sub init_report_web {

    undef @intern_error_web;
    undef @system_error_web;
    undef @user_error_web;
    undef @auth_reject_web;
    undef @notice_web;
}


#########################################################
# is_there_any_reject_report_web
#########################################################
#  Look for some web reports in one of web 
#  arrays reject report 
# 
# IN : -
#
# OUT : 1 if there are some reports to send
#      
######################################################### 
sub is_there_any_reject_report_web {
    
    return (@intern_error_web ||
	    @system_error_web ||
	    @user_error_web ||
	    @auth_reject_web );
}



#########################################################
# get_intern_error_web
#########################################################
#  return array of web intern error
# 
# IN : -
#
# OUT : ref(ARRAY) - clone of \@intern_error_web
#      
######################################################### 
sub get_intern_error_web {
    my @intern_err;
    
    foreach my $i (@intern_error_web) {
	push @intern_err,$i;
    }
    return \@intern_err;
}


#########################################################
# get_system_error_web
#########################################################
#  return array of web system error
# 
# IN : -
#
# OUT : ref(ARRAY) - clone of \@system_error_web
#      
######################################################### 
sub get_system_error_web {
    my @system_err;
    
    foreach my $i (@system_error_web) {
	push @system_err,$i;
    }
    return \@system_err;
}


#########################################################
# get_user_error_web
#########################################################
#  return array of web user error
# 
# IN : -
#
# OUT : ref(ARRAY) - clone of \@user_error_web
#      
######################################################### 
sub get_user_error_web {
    my @user_err;
    
    foreach my $u (@user_error_web) {
	push @user_err,$u;
    }
    return \@user_err;
}


#########################################################
# get_auth_reject_web
#########################################################
#  return array of web authorisation reject
# 
# IN : -
#
# OUT : ref(ARRAY) - clone of \@auth_reject_web
#      
######################################################### 
sub get_auth_reject_web {
    my @auth_rej;
    
    foreach my $a (@auth_reject_web) {
	push @auth_rej,$a;
    }
    return \@auth_rej;
}


#########################################################
# get_notice_web
#########################################################
#  return array of web notice
# 
# IN : -
#
# OUT : ref(ARRAY) - clone of \@notice_web
#      
######################################################### 
sub get_notice_web {
    my @notice;
    
    if (@notice_web) {
	
	foreach my $n (@notice_web) {
	    push @notice,$n;
	}
	return \@notice;
    
    }else {
	return 0;
    }

}


#########################################################
# notice_report_web
#########################################################
#  puts notices reports of web commands in 
#  @notice_web used to notice user with template 
#  web_tt2/notice.tt2
# 
# IN : -$msg : $notice.msg to select string in
#               web/notice.tt2
#      -$data : ref(HASH) - var used in web_tt2/notices.tt2
#      -$action : SCALAR - the noticed action $notice.action in web_tt2/notices.tt2
#
# OUT : 1
#      
######################################################### 
sub notice_report_web {
    my ($msg,$data,$action) = @_;
   
    $data ||= {};
    $data->{'action'} = $action;
    $data->{'msg'} = $msg;
    push @notice_web,$data;

}

#########################################################
# reject_report_web
#########################################################
#  puts errors reports of web commands in 
#  @intern/user/system_error_web, @auth_reject_web
#   used to send message with template  web_tt2/error.tt2
#  if $type = 'intern'||'system', the listmaster is notified
#  (with 'web_intern_error' || 'web_system_error')
# 
# IN : -$type (+): 'intern'||'intern_quiet||'system'||'system_quiet'||user'||'auth'
#      -$error (+): scalar  - $u_err.msg in error.tt2 if $type = 'user'
#                           - $auth.msg in error.tt2 if $type = 'auth' 
#                           - $s_err.msg in error.tt2 if $type = 'system'||'system_quiet'
#                           - $i_err.msg in error.tt2 if $type = 'intern' || 'intern_quiet'
#                           - $error in listmaster_notification if $type = 'system'||'intern'
#      -$data : ref(HASH) - var used in web_tt2/error.tt2 
#      -$action(+) : SCALAR - the rejected action : 
#            $xx.action in web_tt2/error.tt2
#            $action in listmaster_notification.tt2 if needed
#      -$list : ref(List) || ''
#      -$user :  required if $type eq 'intern'||'system'
#                  scalar - the concerned user to notify listmaster
#      -$robot :   required if $type eq 'intern'||'system'
#                  scalar - the robot to notify listmaster
#
# OUT : 1|| undef  
#      
######################################################### 
sub reject_report_web {
    my ($type,$error,$data,$action,$list,$user,$robot) = @_;


    unless ($type eq 'intern' || $type eq 'intern_quiet' || $type eq 'system' || $type eq 'system_quiet' || $type eq 'user'|| $type eq 'auth') {
	&do_log('err',"report::reject_report_web(): error  to prepare parsing 'web_tt2/error.tt2' template to $user : not a valid error type");
	return undef
    }
    
    my $listname;
    if (ref($list) eq 'List'){
	$listname = $list->{'name'};
    }

    ## Notify listmaster for internal or system errors
    if ($type eq 'intern'|| $type eq 'system') {
	if ($robot){
	    my $param = $data;
	    $param ||= {};
	    $param->{'error'} = &gettext($error);
	    $param->{'list'} = $list if (defined $list);
	    $param->{'who'} = $user;
	    $param->{'action'} ||= 'Command process';

	    unless (&List::send_notify_to_listmaster('web_'.$type.'_error', $robot, $param)) {
		&do_log('notice',"report::reject_report_web(): Unable to notify listmaster concerning '$user'");
	    } 
	}else {
	    &do_log('notice',"report::reject_report_web(): unable to notify listmaster for error: '$error' : (no robot) ");
	} 
    }
    
    $data ||= {};

    $data->{'action'} = $action;
    $data->{'msg'} = $error;
    $data->{'listname'} = $listname;

    if ($type eq 'auth') {
	push @auth_reject_web,$data;
	
    }elsif ($type eq 'user') {
	push @user_error_web,$data;
	
    }elsif ($type eq 'system' || $type eq 'system_quiet') {
	push @system_error_web,$data;
	
    }elsif ($type eq 'intern' || $type eq 'intern_quiet') {
	push @intern_error_web,$data;
	
    }
}


#############################################





1;
