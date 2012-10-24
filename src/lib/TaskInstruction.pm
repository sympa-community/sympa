# TaskInstruction.pm - This module includes the TaskInstruction object.
# This object is used to handle a single line contained by a task.
#<!-- RCS Identication ; $Revision: 7792 $ ; $Date: 2012-10-23 15:36:05 +0200 (mar 23 oct 2012) $ --> 

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

package TaskInstruction;

use strict;

use Carp;
use Data::Dumper;
use Digest::MD5;
use Exporter;
use Time::Local;

use tools;

###### DEFINITION OF AVAILABLE COMMANDS FOR TASKS ######

our $date_arg_regexp1 = '\d+|execution_date';
our $date_arg_regexp2 = '(\d\d\d\dy)(\d+m)?(\d+d)?(\d+h)?(\d+min)?(\d+sec)?'; 
our $date_arg_regexp3 = '(\d+|execution_date)(\+|\-)(\d+y)?(\d+m)?(\d+w)?(\d+d)?(\d+h)?(\d+min)?(\d+sec)?';
our $delay_regexp = '(\d+y)?(\d+m)?(\d+w)?(\d+d)?(\d+h)?(\d+min)?(\d+sec)?';
our $var_regexp ='@\w+'; 
our $subarg_regexp = '(\w+)(|\((.*)\))'; # for argument with sub argument (ie arg(sub_arg))
                 
# regular commands
our %commands = ('next'                  => ['date', '\w*'],
		                           # date   label
                'stop'                  => [],
		'create'                => ['subarg', '\w+', '\w+'],
		                           #object    model  model choice
		'exec'                  => ['.+'],
		                           #script
		'update_crl'            => ['\w+', 'date'], 
		                           #file    #delay
		'expire_bounce'         => ['\d+'],
		                           #Number of days (delay)
		'chk_cert_expiration'   => ['\w+', 'date'],
		                           #template  date
		'sync_include'          => [],
		'purge_user_table'      => [],
		'purge_logs_table'      => [],
		'purge_session_table'   => [],
		'purge_tables'   => [],
		'purge_one_time_ticket_table'   => [],
		'purge_orphan_bounces'  => [],
		'eval_bouncers'         => [],
		'process_bouncers'      => []
		);

# commands which use a variable. If you add such a command, the first parameter must be the variable
our %var_commands = ('delete_subs'      => ['var'],
		                          # variable 
		    'send_msg'         => ['var',  '\w+' ],
		                          #variable template
		    'rm_file'          => ['var'],
		                          # variable
		    );

foreach (keys %var_commands) {
    $commands{$_} = $var_commands{$_};
}                                     
 
# commands which are used for assignments
our %asgn_commands = ('select_subs'      => ['subarg'],
		                            # condition
		     'delete_subs'      => ['var'],
		                            # variable
		     );

foreach (keys %asgn_commands) {
    $commands{$_} = $asgn_commands{$_};
}                                    

sub new {
	my $pkg = shift;
	my $data = shift; #Instructions are built by parsing a single line of a task string.
	my $self = &tools::dup_var($data);

	bless $self, $pkg;
	$self->parse;
	return $self;
}

## Parses the line of a task and returns a hash that can be executed.
sub parse {
	my $self = shift;
	
    &Log::do_log('debug2', 'Parsing "%s"', $self->{'line_as_string'});

    $self->{'nature'} = undef;
    # empty line
    if (! $self->{'line_as_string'}) {
	$self->{'nature'} = 'empty line';
    # comment
    }elsif ($self->{'line_as_string'} =~ /^\s*\#.*/) {
	$self->{'nature'} = 'comment';
    # title
    }elsif ($self->{'line_as_string'} =~ /^\s*title\...\s*(.*)\s*/i) {
	$self->{'nature'} = 'title';
	$self->{'title'} = $1;
    # label
    }elsif ($self->{'line_as_string'} =~ /^\s*\/\s*(.*)/) {
	$self->{'nature'} = 'label';
	$self->{'label'} = $1;
    # command
     }elsif ($self->{'line_as_string'} =~ /^\s*(\w+)\s*\((.*)\)\s*/i ) { 
	my $command = lc ($1);
	my @args = split (/,/, $2);
	foreach (@args) { s/\s//g;}

	unless ($commands{$command}) { 
	    $self->{'nature'} = 'error';
	    $self->{'error'} = "unknown command $command";
	}else {
	    $self->{'nature'} = 'command';
	    $self->{'command'} = $command;

	    # arguments recovery. no checking of their syntax !!!
	    $self->{'Rarguments'} = \@args;
	    $self->chk_cmd;
	}
    # assignment
    }elsif ($self->{'line_as_string'} =~ /^\s*(@\w+)\s*=\s*(.+)/) {

		my $subinstruction = new TaskInstruction ({'line_as_string' => $2, 'line_number' => $self->{'line_number'}});
		
		unless ( $asgn_commands{$subinstruction->{'command'}} ) { 
			$self->{'nature'} = 'error';
			$self->{'error'} = "non valid assignment $2";
		}else {
			$self->{'nature'} = 'assignment';
			$self->{'var'} = $1;
			$self->{'command'} = $subinstruction->{'command'};
			$self->{'Rarguments'} = $subinstruction->{'Rarguments'};
		}
    }else {
		$self->{'nature'} = 'error'; 
		$self->{'error'} = 'syntax error';
    }
}

## Checks the arguments of a command 
sub chk_cmd {

    my $self = shift;

    &Log::do_log('debug2', 'chk_cmd(%s, %d, %s)', $self->{'command'}, $self->{'line_number'}, join(',',@{$self->{'Rarguments'}}));
    
    if (defined $commands{$self->{'command'}}) {
	
	my @expected_args = @{$commands{$self->{'command'}}};
	my @args = @{$self->{'Rarguments'}};
	
	unless ($#expected_args == $#args) {
	    &Log::do_log ('err', "error at line $self->{'line_number'} : wrong number of arguments for $self->{'command'}");
	    &Log::do_log ('err', "args = @args ; expected_args = @expected_args");
	    return undef;
	}
	
	foreach (@args) {
	    
	    undef my $error;
	    my $regexp = $expected_args[0];
	    shift (@expected_args);
	    
	    if ($regexp eq 'date') {
		$error = 1 unless ( (/^$date_arg_regexp1$/i) or (/^$date_arg_regexp2$/i) or (/^$date_arg_regexp3$/i) );
	    }
	    elsif ($regexp eq 'delay') {
		$error = 1 unless (/^$delay_regexp$/i);
	    }
	    elsif ($regexp eq 'var') {
		$error = 1 unless (/^$var_regexp$/i);
	    }
	    elsif ($regexp eq 'subarg') {
		$error = 1 unless (/^$subarg_regexp$/i);
	    }
	    else {
		$error = 1 unless (/^$regexp$/i);
	    }
	    
	    if ($error) {
		&Log::do_log ('err', "error at line $self->{'line_number'} : argument $_ is not valid");
		return undef;
	    }
	    
	    $self->{'used_labels'}{$args[1]} = 1 if ($self->{'command'} eq 'next' && ($args[1]));   
	    $self->{'used_vars'}{$args[0]} = 1 if ($var_commands{$self->{'command'}});
	}
    }
    return 1;
}

# Packages must return true;
return 1;
