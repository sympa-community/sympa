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
    return undef unless ($self = new Message($datas));
    unless ($self->get_message_as_string) {
		Log::do_log ('notice',"Ignoring bounce where %s  because it is empty",$self->{'messagekey'});
		return undef;
    }
    bless $self,$pkg;
    $self->{'to'} = $self->get_mime_message->head->get('to', 0);
    chomp $self->{'to'};	

    return $self;
}

sub analyze_verp_header {
    my $self = shift;

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
	$self->{'listname'} = $2;

	&Log::do_log('notice', 'VERP in use : bounce related to %s for list %s@%s',$self->{'who'},$self->{'listname'},$self->{'domain_part'});
	return 1;
    }
    return 0;
}

sub is_verp_in_use {
    my $self = shift;

    my $bounce_email_prefix = Site->bounce_email_prefix;
    if ($self->{'to'} =~ /^$bounce_email_prefix\+(.*)\@(.*)$/) {
	$self->{'local_part'} = $1;
	$self->{'domain_part'} = $2;
	return 1;
    }
    return 0;
}

sub failed_on_first_try {
    my $self = shift;

    if ($self->{'unique'} =~ /[wr]/) {
	return 1;
    }
    return 0;
}

1;
