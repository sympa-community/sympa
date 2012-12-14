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

1;
