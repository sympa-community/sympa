# BounceMessage.pm - This module includes specialized sub to handle bounce messages.

package BounceMessage;

use strict;
use Message;
use Log;
use tracking;

our @ISA = qw(Message);

## Creates a new object
sub new {
    
    my $pkg =shift;
    my $datas = shift;
    my $self;
    Log::do_log('debug2', "Creating new BounceMessage object");
    return undef unless ($self = new Message($datas));
    unless ($self->get_message_as_string) {
		Log::do_log ('notice',"Ignoring bounce where %s  because it is empty",$self->{'messagekey'});
		return undef;
    }
    bless $self,$pkg;
    $self->{'to'} = $self->get_mime_message->head->get('to', 0);
    chomp $self->{'to'};	
    $self->{'listname'} = $self->{'list'}{'name'};
    $self->{'robotname'} = $self->{'robot'}->get_id;

    return $self;
}

sub analyze_verp_header {
    my $self = shift;

    Log::do_log('debug2', "analysing VERP headers for bounce %s",$self->get_msg_id);
    if($self->is_verp_in_use) {
	if ($self->{'local_part'} =~ /^(.*)(\=\=([wr]))$/) {
	    $self->{'local_part'} = $1;
	    $self->{'unique'} = $2;
	}elsif ($self->{'local_part'} =~  /^(.*)\=\=a\=\=(.*)\=\=(.*)\=\=(.*)$/ ) {# tracking in use
	    
	    $self->{'distribution_id'} = $4;
	    $self->{'local_part'} =~ /^(.*)\=\=(.*)$/ ;
	    $self->{'local_part'} = $1;
	}else{
	    undef $self->{'distribution_id'} ;
	    Log::do_log('err', 'NO ID PART in the bounce for :%s', $self->{'to'});
	}

	$self->{'local_part'} =~ s/\=\=a\=\=/\@/ ;
	$self->{'local_part'} =~ /^(.*)\=\=(.*)$/ ; 	    
	$self->{'who'} = $1;
	$self->update_list($2,$self->{'robotname'});

	Log::do_log('notice', 'VERP in use : bounce related to %s for list %s@%s',$self->{'who'},$self->{'listname'},$self->{'robotname'});
	return 1;
    }
    return 0;
}

sub is_verp_in_use {
    my $self = shift;

    Log::do_log('debug', "Checking if VERP is used for bounce %s. to is %s, prefix: %s",$self->get_msg_id,$self->{'to'},Site->bounce_email_prefix);
    my $bounce_email_prefix = Site->bounce_email_prefix;
    if ($self->{'to'} =~ /^$bounce_email_prefix\+(.*)\@(.*)$/) {
	$self->{'local_part'} = $1;
	$self->{'robotname'} = $2;
	return 1;
    }
    return 0;
}

sub failed_on_first_try {
    my $self = shift;

    Log::do_log('debug2', "Checking if bounce for message service for bounce %s",$self->get_msg_id);
    if ($self->{'unique'} =~ /[wr]/) {
	return 1;
    }
    return 0;
}

sub change_listname {
    my $self = shift;
    my $new_listname = shift;

    Log::do_log('debug3', "Changing listname from %s to %s for bounce %s",$self->{'listname'},$new_listname,$self->get_msg_id);
    $self->{'old_listname'} = $self->{'listname'};
    $self->{'listname'} = $new_listname;
}

sub change_robotname {
    my $self = shift;
    my $new_robotname = shift;

    Log::do_log('debug3', "Changing robotname from %s to %s for bounce %s",$self->{'robotname'},$new_robotname,$self->get_msg_id);
    $self->{'old_robotname'} = $self->{'robotname'};
    $self->{'robotname'} = $new_robotname;
}

sub update_list {
    my $self = shift;
    my $new_listname = shift;
    my $new_robotname = shift;

    Log::do_log('debug3', "Updating list for bounce %s",$self->get_msg_id);
    $self->update_robot($new_robotname);
    $self->change_listname($new_listname);

    if ($self->{'old_listname'} ne $self->{'listname'} || $self->{'old_robotname'} ne $self->{'robotname'}) {
	my $list = new List ($self->{'listname'}, $self->{'robot'});
	unless($list) {
	    Log::do_log('notice','Unable to set list object for unknown list %s@%s (bounce %s)',$self->{'listname'},$self->{'robotname'},$self->{'messagekey'});
	    return undef;
	}
	$self->{'list'} = $list;
    }
    
    return 1;
}

sub update_robot {
    my $self = shift;
    my $new_robotname = shift;
    
    Log::do_log('debug3', "Updating robot for bounce %s",$self->get_msg_id);
    $self->change_robotname($new_robotname);

    if ($self->{'old_robotname'} ne $self->{'robotname'}) {
	my $robot = new Robot($self->{'robot'});
	unless($robot) {
	    Log::do_log('notice','Unable to set robot object for unknown robot %s (bounce %s)',$self->{'robotname'},$self->{'messagekey'});
	    return undef;
	}
	$self->{'robot'} = $robot;
    }

    return 1;
}

sub delete_bouncer {
    my $self = shift;

    Log::do_log('debug','Deleting bouncing user %s',$self->{'who'});
    my $result = $self->{'list'}->check_list_authz('del','smtp',
					{'sender' => [Site->listmasters]->[0],
					 'email' => $self->{'who'}});
    my $action;
    $action = $result->{'action'} if (ref($result) eq 'HASH');

    if ($action =~ /do_it/i) {
	if ($self->{'list'}->is_list_member($self->{'who'})) {
	    my $u = $self->{'list'}->delete_list_member('users' => [$self->{'who'}], 'exclude' =>' 1');
	    Log::do_log ('notice',"$self->{'who'} has been removed from $self->{'listname'} because welcome message bounced");
	    Log::db_log({'robot' => $self->{'list'}->domain, 'list' => $self->{'list'}->name, 'action' => 'del',
			  'target_email' => $self->{'who'},'status' => 'error','error_type' => 'welcome_bounced',
			  'daemon' => 'bounced'});
	    
	    Log::db_stat_log({'robot' => $self->{'list'}->domain, 'list' => $self->{'list'}->name, 'operation' => 'auto_del', 'parameter' => "",
			       'mail' => $self->{'who'}, 'client' => "", 'daemon' => 'bounced.pl'});
	    
	    if ($action =~ /notify/) {
		unless ($self->{'list'}->send_notify_to_owner('automatic_del',
						    {'who' => $self->{'who'},
						     'by' => 'bounce manager',
						     'reason' => 'welcome'})) {
		    &wwslog('err', 'Unable to send notify "automatic_del" to %s list owner', $self->{'list'});
		} 
	    }
	}
    }else{
	Log::do_log('err','Authorization do delete user %s from liste %s denied',$self->{'who'},$self->{'list'}->get_id);
	return undef;
    }
    return 1;
}

sub tracking_is_used {
    my $self = shift ;

    return 1 if ($self->{'list'}->tracking->{'delivery_status_notification'} eq "on");
    return 1 if ($self->{'list'}->tracking->{'message_delivery_notification'} eq "on");
    return 1 if ($self->{'list'}->tracking->{'message_delivery_notification'} eq "on_demand");
    return 0;
}

sub is_dsn {
    my $self = shift;

    return 1 if (($self->get_mime_message->head->get('Content-type') =~ /multipart\/report/) && ($self->get_mime_message->head->get('Content-type') =~ /report\-type\=delivery-status/i) && ($self->tracking_is_used));
    return 0;
}

sub process_dsn {
    my $self = shift;

    my @parts = $self->get_mime_message->parts();
    my $original_rcpt; my $final_rcpt; my $user_agent; my $version; my $msg_id; my $orig_msg_id;
    my $arrival_date;
    
    my $msg_id = $self->get_mime_message->head->get('Message-Id');
    chomp $msg_id;
    
    my $date = $self->get_mime_message->head->get('Date');
    
    foreach my $p (@parts) {
	my $h = $p->head();
	my $content = $h->get('Content-type');
	
	if ($content =~ /message\/delivery-status/) {
	    my @report = split(/\n/, $p->bodyhandle->as_string());
	    foreach my $line (@report) {
		$line = lc($line);
		# Action Field MUST be present in a DSN report, possible values : failed, delayed, delivered, relayed, expanded(rfc3464)
		if ($line =~ /action\:\s*(.+)/i) {
		    $self->{'dsn_status'} = $1;
		    chomp $self->{'dsn_status'};
		}			
		
		if ( ($line =~ /final\-recipient\:\s*(.+)\s*$/i) && (not $final_rcpt) ) {
		    $final_rcpt = $1;
		    chomp $final_rcpt;
		    my @rcpt;
		    if($final_rcpt =~ /.*;.*/){
			@rcpt = split /;\s*/,$final_rcpt;
			foreach my $rcpt (@rcpt){
			    if($rcpt =~ /(\S+\@\S+)/){
				($rcpt)= $rcpt=~ /(\S+\@\S+)/;			
				$final_rcpt = $rcpt;
			    }
			}
		    }
		    else{
			($final_rcpt)= $final_rcpt =~ /(\S+\@\S+)/;
		    }	
		}
		#  $self->{'distribution_id'} is set using VERP nothing else.
		#if ( ($line =~ /original\-envelope\-id\:\s*(.+)/i) && (!$self->{'distribution_id'}) ) {
		#    $self->{'distribution_id'} = $1;
		#    chomp $self->{'distribution_id'};
		#   Log::do_log ('debug2',"1 - Original Envelope-id Detected, value : %s", $self->{'distribution_id'});
		#}
		if ($line =~ /arrival\-date\:\s*(.+)/i) {
		    $arrival_date = $1;
		    chomp $arrival_date;
		}
	    }
	}
    }
    
    $original_rcpt = $self->{'who'};
    
    if($final_rcpt =~ /<(\S+\@\S+)>/){
	($final_rcpt)= $final_rcpt =~ /<(\S+\@\S+)>/;
    }
    if($msg_id =~ /<(\S+\@\S+)>/){
	($msg_id)= $msg_id =~ /<(\S+\@\S+)>/;
    }
    
    Log::do_log ('debug2',"FINAL DSN Action Detected, value : %s", $self->{'dsn_status'});
    Log::do_log ('debug2',"FINAL DSN Recipient Detected, value : %s", $original_rcpt);
    Log::do_log ('debug2',"FINAL DSN final Recipient Detected, value : %s", $final_rcpt);
    Log::do_log ('debug2',"FINAL DSN Message-Id Detected, value : %s", $msg_id);
    Log::do_log ('debug2',"FINAL DSN Arrival Date Detected, value : %s", $arrival_date);
    
    unless  ($self->{'dsn_status'} =~ /failed/) { # DSN with status "failed" should not be removed because they must be processed for classical bounce managment (not only for tracking feature)
	Log::do_log('err', "Non failed dsn status $self->{'dsn_status'}");
	unless ($self->{'distribution_id'}) {
	    Log::do_log('err', "error: Id not found in to address %s, will ignore",$self->{'to'});
	    return undef;
	}
	unless ($original_rcpt) {
	    Log::do_log('err', "error: original recipient not found in dsn: %s, will ignore",$msg_id);
	    return undef;
	}
	unless ($msg_id) {
	    Log::do_log('err', "error: message_id not found in dsn will ignore");
	    return undef;
	}
    }
    
    if (tracking::db_insert_notification($self->{'distribution_id'}, 'DSN', $self->{'dsn_status'}, $arrival_date,$self->get_mime_message )) {
	Log::do_log('notice', "DSN Correctly treated...");
    }else{
	Log::do_log('err','Not able to fill database with notification data');
    }
    return 1;
}

sub is_mdn {
    my $self = shift;

    return 1 if (($self->get_mime_message->head->get('Content-type') =~ /multipart\/report/) && ($self->get_mime_message->head->get('Content-type') =~ /report\-type\=disposition-notification/i) && (($self->get_mime_message->tracking->{'message_delivery_notification'} eq "on")||($self->get_mime_message->tracking->{'message_delivery_notification'} eq "on_demand")));
    return 0;
}

sub process_mdn {
    my $self = shift;
    my @parts = $self->get_mime_message->parts();
    
    $self->{'mdn'}{'msg_id'} = $self->get_mime_message->head->get('Message-Id');
    chomp $self->{'mdn'}{'msg_id'};
    
    $self->{'mdn'}{'date'} = $self->get_mime_message->head->get('Date');
    
    foreach my $p (@parts) {
	my $h = $p->head();
	my $content = $h->get('Content-type');
	
	if ($content =~ /message\/disposition-notification/) {
	    my @report = split(/\n/, $p->bodyhandle->as_string());
	    foreach my $line (@report) {
		$line = lc($line);
		# Disposition Field MUST be present in a MDN report, possible values : displayed, deleted(rfc3798)
		if ($line =~ /disposition\:\s*(.+)\s*\;\s*(.+)/i) {
		    $self->{'mdn'}{'status'} = $2;
		    if($self->{'mdn'}{'status'}  =~ /.*\/.*/){
			my @results = split /\/\s*/,$self->{'mdn'}{'status'};
			$self->{'mdn'}{'status'} = $results[$0];
			chomp $self->{'mdn'}{'status'};
		    }
		}
		if ( ($line =~ /final\-recipient\:\s*(.+)\s*$/i) && (not $self->{'mdn'}{'final_rcpt'}) ) {
		    $self->{'mdn'}{'final_rcpt'} = $1;
		    chomp $self->{'mdn'}{'final_rcpt'};
		    my @rcpt;
		    if($self->{'mdn'}{'final_rcpt'} =~ /.*;.*/){
			@rcpt = split /;\s*/,$self->{'mdn'}{'final_rcpt'};
			foreach my $rcpt (@rcpt){
			    if($rcpt =~ /(\S+\@\S+)/){
				($rcpt)= $rcpt=~ /(\S+\@\S+)/;			
				$self->{'mdn'}{'final_rcpt'} = $rcpt;
			    }
			}
		    }
		    else{
			($self->{'mdn'}{'final_rcpt'})= $self->{'mdn'}{'final_rcpt'} =~ /(\S+\@\S+)/;
		    }	
		}
	    }
	}
    }
    
    if($self->{'mdn'}{'original_rcpt'} =~ /<(\S+\@\S+)>/){
	($self->{'mdn'}{'original_rcpt'})= $self->{'mdn'}{'original_rcpt'} =~ /<(\S+\@\S+)>/;
    }
    if($self->{'mdn'}{'final_rcpt'} =~ /<(\S+\@\S+)>/){
	($self->{'mdn'}{'final_rcpt'})= $self->{'mdn'}{'final_rcpt'} =~ /<(\S+\@\S+)>/;
    }
    if($self->{'mdn'}{'msg_id'} =~ /<(\S+\@\S+)>/){
	($self->{'mdn'}{'msg_id'})= $self->{'mdn'}{'msg_id'} =~ /<(\S+\@\S+)>/;
    }
    # let's use VERP 
    $self->{'mdn'}{'original_rcpt'} = $self->{'who'};
    
    &Log::do_log ('debug2',"FINAL MDN Disposition Detected, value : %s", $self->{'mdn'}{'status'});
    &Log::do_log ('debug2',"FINAL MDN Recipient Detected, value : %s", $self->{'mdn'}{'original_rcpt'});
    &Log::do_log ('debug2',"FINAL MDN Message-Id Detected, value : %s", $self->{'mdn'}{'msg_id'});
    &Log::do_log ('debug2',"FINAL MDN Date Detected, value : %s", $self->{'mdn'}{'date'});
    
    unless ($self->{'distribution_id'}) {
	&Log::do_log('err', "error: Id not found in to address %s, will ignore",$self->{'to'});
	return undef;
    }
    unless ($self->{'mdn'}{'original_rcpt'}) {
	&Log::do_log('err', "error: original recipient not found in dsn: %s, will ignore",$self->{'mdn'}{'msg_id'});
	return undef;
    }
    unless ($self->{'mdn'}{'msg_id'}) {
	&Log::do_log('err', "error: message_id not found in dsn will ignore");
	return undef;
    }
    unless ($self->{'mdn'}{'status'}) {
	&Log::do_log('err', "error: dsn status not found in dsn: %s, will ignore",$self->{'mdn'}{'msg_id'});
	return undef;
    }
    
    &Log::do_log('debug2', "Save in database...");
    unless (&tracking::db_insert_notification($self->{'distribution_id'}, 'MDN',$self->{'mdn'}{'status'}, $self->{'mdn'}{'date'},$self->get_mime_message )) {
	&Log::do_log('err','Not able to fill database with notification data');
	return undef;
    }
    return 1
}

sub is_email_feedback_report {
    my $self = shift;
    return 1 if (($self->get_mime_message->head->get('Content-type') =~ /multipart\/report/) && ($self->get_mime_message->head->get('Content-type') =~ /report\-type\=feedback-report/));
    return 0;
}

sub process_email_feedback_report {
    my $self = shift;
    
    Log::do_log ('notice',"processing  Email Feedback Report");
    my @parts = $self->get_mime_message->parts();
    $self->{'efr'}{'feedback_type'} = '';
    foreach my $p (@parts) {
	my $h = $p->head();
	my $content = $h->get('Content-type');
	next if ($content =~ /text\/plain/i);		 
	if ($content =~ /message\/feedback-report/) {
	    my @report = split(/\n/, $p->bodyhandle->as_string());
	    foreach my $line (@report) {
		$self->{'efr'}{'feedback_type'} = 'abuse' if ($line =~ /Feedback\-Type\:\s*abuse/i);
		if ($line =~ /Feedback\-Type\:\s*(.*)/i) {
		    $self->{'efr'}{'feedback_type'} = $1;
		}
		
		if ($line =~ /User\-Agent\:\s*(.*)/i) {
		    $self->{'efr'}{'user_agent'} = $1;
		}
		if ($line =~ /Version\:\s*(.*)/i) {
		    $self->{'efr'}{'version'} = $1;
		}
	    my $email_regexp = &tools::get_regexp('email');
		if ($line =~ /Original\-Rcpt\-To\:\s*($email_regexp)\s*$/i) {
		    $self->{'efr'}{'original_rcpt'} = $1;
		    chomp $self->{'efr'}{'original_rcpt'};
		}
	    }
	}elsif ($content =~ /message\/rfc822/) {
	    my @subparts = $p->parts();
	    foreach my $subp (@subparts) {
		my $subph =  $subp->head;
		$self->{'listname'} = $subph->get('X-Loop');
	    }
	}
    }
    my $forward ;
    ## RFC compliance remark: We do something if there is an abuse or an unsubscribe request.
    ## We don't throw an error if we find another kind of feedback (fraud, miscategorized, not-spam, virus or other)
    ## but we don't take action if we meet them yet. This is to be done, if relevant.
    if (($self->{'efr'}{'feedback_type'} =~ /(abuse|opt-out|opt-out-list|fraud|miscategorized|not-spam|virus|other)/i) && (defined $self->{'efr'}{'version'}) && (defined $self->{'efr'}{'user_agent'})) {
	
	Log::do_log ('debug','Email Feedback Report: %s feedback-type: %s',$self->{'listname'},$self->{'efr'}{'feedback_type'});
	if (defined $self->{'efr'}{'original_rcpt'}) {
	    Log::do_log ('debug','Recognized user : %s list',$self->{'efr'}{'original_rcpt'});		
	    my @lists;
	    
	    if (( $self->{'efr'}{'feedback_type'} =~ /(opt-out-list|abuse)/i ) && (defined $self->{'listname'})) {
		$self->{'listname'} = lc($self->{'listname'});
		chomp $self->{'listname'} ;
		$self->{'listname'} =~ /(.*)\@(.*)/;
		$self->{'listname'} = $1;
		$self->{'robotname'} = $2;
		my $list = new List ($self->{'listname'}, $self->{'robotname'});
		unless($list) {
		    Log::do_log('err',
			'Skipping Feedback Report (spool bounce, messagekey =%s) for unknown list %s@%s',
			$self->{'messagekey'}, $self->{'listname'}, $self->{'robotname'});
		    return undef;
		}
		push @lists, $list;
	    }elsif( $self->{'efr'}{'feedback_type'} =~ /opt-out/ && (defined $self->{'efr'}{'original_rcpt'})){
		@lists = List::get_which($self->{'efr'}{'original_rcpt'}, $self->{'robotname'}, 'member');
	    }else {
		Log::do_log('notice','Ignoring Feedback Report (bounce where messagekey=%s) : Nothing to do for this feedback type.(feedback_type:%s, original_rcpt:%s, listname:%s)',$self->{'messagekey'}, $self->{'efr'}{'feedback_type'}, $self->{'efr'}{'original_rcpt'}, $self->{'listname'} );		
		return 0;
	    }
	    foreach my $list (@lists){
		my $result =$list->check_list_authz('unsubscribe','smtp',{'sender' => $self->{'efr'}{'original_rcpt'}});
		my $action;
		$action = $result->{'action'} if (ref($result) eq 'HASH');		    
		if ($action =~ /do_it/i) {
		    if ($list->is_list_member($self->{'efr'}{'original_rcpt'})) {
			my $u = $list->delete_list_member('users' => [$self->{'efr'}{'original_rcpt'}], 'exclude' =>' 1');
		    
			Log::do_log ('notice','%s has been removed from %s because abuse feedback report',$self->{'efr'}{'original_rcpt'},$list->name);	
			unless ($list->send_notify_to_owner('automatic_del',{'who' => $self->{'efr'}{'original_rcpt'}, 'by' => 'listmaster'})) {
			    Log::do_log('notice', 'Unable to send notify "automatic_del" to %s list owner', $list->name);
			}
		    }else{
			&Log::do_log('err','Ignore Feedback Report (bounce where messagekey =%s) for list %s@%s : user %s not subscribed',$self->{'messagekey'},$list->name,$self->{'robotname'},$self->{'efr'}{'original_rcpt'});
			unless ($list->send_notify_to_owner('warn-signoff',{'who' => $self->{'efr'}{'original_rcpt'}})) {
			    &Log::do_log('notice', 'Unable to send notify "warn-signoff" to %s list owner', $list);
			}
		    }
		}else{
		    $forward = 'request';
		    Log::do_log('err',
			'Ignore Feedback Report (bounce where messagekey=%s) for list %s : user %s is not allowed to unsubscribe',
			$self->{'messagekey'}, $list, $self->{'efr'}{'original_rcpt'});
		}
	    }
	}else{
	    &Log::do_log ('err','Ignoring Feedback Report (bounce where messagekey=%s) : Unknown Original-Rcpt-To field. Can\'t do anything. (feedback_type:%s, listname:%s)',$self->{'messagekey'}, $self->{'efr'}{'feedback_type'}, $self->{'listname'} );		
	    return undef;;
	}
    }else {
	return undef;
    }
    return 1;
}

1;
