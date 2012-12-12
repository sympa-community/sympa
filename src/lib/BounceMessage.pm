# BounceMessage.pm - This module includes specialized sub to handle bounce messages.

package BounceMessage;

use strict;
use Message;

our @ISA = qw(Message);

## Creates a new object
sub new {
    
    my $pkg =shift;
    my $datas = shift;
	my $self;
    return undef unless ($self = new Message($datas));
    bless $self,$pkg;
    return $self;
}
