# BounceMessage.pm - This module includes specialized sub to handle bounce messages.

package BounceMessage;

use strict;
use Message;
use Log;

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

	&Log::do_log('notice', 'VERP in use : bounce related to %s for list %s@%s',$self->{'who'},$self->{'listname'},$self->{'robotname'});
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
	    &Log::do_log ('notice',"$self->{'who'} has been removed from $self->{'listname'} because welcome message bounced");
	    &Log::db_log({'robot' => $self->{'list'}->domain, 'list' => $self->{'list'}->name, 'action' => 'del',
			  'target_email' => $self->{'who'},'status' => 'error','error_type' => 'welcome_bounced',
			  'daemon' => 'bounced'});
	    
	    &Log::db_stat_log({'robot' => $self->{'list'}->domain, 'list' => $self->{'list'}->name, 'operation' => 'auto_del', 'parameter' => "",
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

1;
