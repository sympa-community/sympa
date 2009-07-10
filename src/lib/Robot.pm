## This package handles Sympa virtual robots
## It should :
##   * provide access to global conf parameters,
##   * deliver the list of lists
##   * determine the current robot, given a host
package Robot;

use Conf;

## Constructor of a Robot instance
sub new {
    my($pkg, $name) = @_;

    my $robot = {'name' => $name};
    &Log::do_log('debug2', '');
    
    unless (defined $name && $Conf::Conf{'robots'}{$name}) {
	&Log::do_log('err',"Unknown robot '$name'");
	return undef;
    }

    ## The default robot
    if ($name eq $Conf::Conf{'host'}) {
	$robot->{'home'} = $Conf::Conf{'home'};
    }else {
	$robot->{'home'} = $Conf::Conf{'home'}.'/'.$name;
	unless (-d $robot->{'home'}) {
	    &Log::do_log('err', "Missing directory '$robot->{'home'}' for robot '$name'");
	    return undef;
	}
    }

    ## Initialize internal list cache
    undef %list_cache;

    # create a new Robot object
    bless $robot, $pkg;

    return $robot;
}

## load all lists belonging to this robot
sub get_lists {
    my $self = shift;

    return &List::get_lists($self->{'name'});
}


###### END of the Robot package ######

## Packages must return true.
1;
