# Scenario.pm - This module includes functions for autorization scenarios processing

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

package Scenario;

use strict;
require Exporter;
require 'tools.pl';
my @ISA = qw(Exporter);
my @EXPORT = qw();

use List;
use Log;
use Conf;

my %all_scenarios;
my %persistent_cache;

## Creates a new object
## Supported parameters : function, robot, name, directory, file_path, options
## Output object has the following entries : name, file_path, rules, date, title, struct, data
sub new {
    my($pkg, @args) = @_;
    my %parameters = @args;
    &do_log('debug2', '');
 
    my $scenario = {};

    ## Check parameters
    ## Need either file_path or function+name
    ## Parameter 'directory' is optional, used in List context only
    unless ($parameters{'robot'} && 
	    ($parameters{'file_path'} || ($parameters{'function'} && $parameters{'name'}))) {
	&do_log('err', 'Missing parameter');
	return undef;
    }

    ## Determine the file path of the scenario
	
    if ($parameters{'file_path'} eq 'ERROR') {
	return $all_scenarios{$scenario->{'file_path'}};
    }

    if (defined $parameters{'file_path'}) {
	$scenario->{'file_path'} = $parameters{'file_path'};
	my @tokens = split /\//, $parameters{'file_path'};
	my $filename = $tokens[$#tokens];
	unless ($filename =~ /^([^\.]+)\.(.+)$/) {
	    &do_log('err',"Failed to determine scenario type and name from '$parameters{'file_path'}'");
	    return undef;
	}
	($parameters{'function'}, $parameters{'name'}) = ($1, $2);
	
    }else {
	## We can't use &tools::get_filename() because we don't have a List object yet ; it's being constructed
	my @dirs = ($Conf{'etc'}.'/'.$parameters{'robot'}, $Conf{'etc'}, '--ETCBINDIR--');
	unshift @dirs, $parameters{'directory'} if (defined $parameters{'directory'});
	foreach my $dir (@dirs) {
	    my $tmp_path = $dir.'/scenari/'.$parameters{'function'}.'.'.$parameters{'name'};
	    if (-r $tmp_path) {
		$scenario->{'file_path'} = $tmp_path;
		last;
	    }
	}
    }

    ## Load the scenario if previously loaded in memory
    if (defined $all_scenarios{$scenario->{'file_path'}}) {

	## Option 'dont_reload_scenario' prevents scenario reloading
	## Usefull for performances reasons
	if ($parameters{'options'}{'dont_reload_scenario'}) {
	    return $all_scenarios{$scenario->{'file_path'}};
	}
	
	## Use cache unless file has changed on disk
	if ($all_scenarios{$scenario->{'file_path'}}{'date'} >= (stat($scenario->{'file_path'}))[9]) {
	    return $all_scenarios{$scenario->{'file_path'}};
	}
    }

    ## Load the scenario
    my $scenario_struct;
    if (defined $scenario->{'file_path'}) {
	## Get the data from file
	unless (open SCENARIO, $scenario->{'file_path'}) {
	    &do_log('err',"Failed to open scenario '$scenario->{'file_path'}'");
	    return undef;
	}
	my $data = join '', <SCENARIO>;
	close SCENARIO;

	## Keep rough scenario
	$scenario->{'data'} = $data;

	$scenario_struct = &_parse_scenario($parameters{'function'}, $parameters{'robot'}, $parameters{'name'}, $data, $parameters{'directory'});
    }elsif ($parameters{'function'} eq 'include') {
	## include.xx not found will not raise an error message
	return undef;
	
    }else {
	## Default rule is 'true() smtp -> reject'
	&do_log('err',"Unable to find scenario file '$parameters{'function'}.$parameters{'name'}', please report to listmaster"); 
	$scenario_struct = &_parse_scenario($parameters{'function'}, $parameters{'robot'}, $parameters{'name'}, 'true() smtp -> reject', $parameters{'directory'});
	$scenario->{'file_path'} = 'ERROR'; ## special value
	$scenario->{'data'} = 'true() smtp -> reject';
    }

    ## Keep track of the current time ; used later to reload scenario files when they changed on disk
    $scenario->{'date'} = time;

    unless (ref($scenario_struct) eq 'HASH') {
	&do_log('err',"Failed to load scenario '$parameters{'function'}.$parameters{'name'}'");
	return undef;
    }

    $scenario->{'name'} = $scenario_struct->{'name'};
    $scenario->{'rules'} = $scenario_struct->{'rules'};
    $scenario->{'title'} = $scenario_struct->{'title'};
    $scenario->{'struct'} = $scenario_struct;

    ## Bless Message object
    bless $scenario, $pkg;

    ## Keep the scenario in memory
    $all_scenarios{$scenario->{'file_path'}} = $scenario;
    
    return $scenario;
}

## Parse scenario rules
sub _parse_scenario {
    my ($function, $robot, $scenario_name, $paragraph, $directory ) = @_;
    &do_log('debug2', "($function, $scenario_name, $robot)");
    
    my $structure = {};
    $structure->{'name'} = $scenario_name ;
    my @scenario;
    my @rules = split /\n/, $paragraph;

    foreach my $current_rule (@rules) {
	next if ($current_rule =~ /^\s*\w+\s*$/o); # skip paragraph name
	my $rule = {};
	$current_rule =~ s/\#.*$//;         # remove comments
        next if ($current_rule =~ /^\s*$/); # skip empty lines
	if ($current_rule =~ /^\s*title\.gettext\s+(.*)\s*$/i) {
	    $structure->{'title'}{'gettext'} = $1;
	    next;
	}elsif ($current_rule =~ /^\s*title\.(\w+)\s+(.*)\s*$/i) {
	    $structure->{'title'}{$1} = $2;
	    next;
	}
        
	if ($current_rule =~ /\s*(include\s*\(?\'?(.*)\'?\)?)\s*$/i) {
	    $rule->{'condition'} = $1;
	}elsif ($current_rule =~ /^\s*(.*)\s+(md5|pgp|smtp|smime)((\s*,\s*(md5|pgp|smtp|smime))*)\s*->\s*(.*)\s*$/i) {
	    $rule->{'condition'}=$1;
	    $rule->{'auth_method'}=$2 || 'smtp';
	    $rule->{'action'} = $6;
	}else {
	    do_log('err', "error rule syntaxe in scenario $function rule line $. expected : <condition> <auth_mod> -> <action>");
	    do_log('err',"error parsing $current_rule");
	    return undef;
	}

	
#	## Make action an ARRAY
#	my $action = $6;
#	my @actions;
#	while ($action =~ s/^\s*((\w+)(\s?\([^\)]*\))?)(\s|\,|$)//) {
#	    push @actions, $1;
#	}
#	$rule->{action} = \@actions;
	       
	push(@scenario,$rule);
#	do_log('debug3', "load rule 1: $rule->{'condition'} $rule->{'auth_method'} ->$rule->{'action'}");

	## Duplicate the rule for each mentionned authentication method
        my $auth_list = $3 ; 
        while ($auth_list =~ /\s*,\s*(md5|pgp|smtp|smime)((\s*,\s*(md5|pgp|smtp|smime))*)\s*/i) {
	    push(@scenario,{'condition' => $rule->{condition}, 
                            'auth_method' => $1,
                            'action' => $rule->{action}});
	    $auth_list = $2;
#	    do_log('debug3', "load rule ite: $rule->{'condition'} $1 -> $rule->{'action'}");
	}
	
    }
    
    $structure->{'rules'} = \@scenario;
   
    return $structure; 
}


####################################################
# request_action
####################################################
# Return the action to perform for 1 sender 
# using 1 auth method to perform 1 operation
#
# IN : -$operation (+) : scalar
#      -$auth_method (+) : 'smtp'|'md5'|'pgp'|'smime'
#      -$robot (+) : scalar
#      -$context (+) : ref(HASH) containing information
#        to evaluate scenario (scenario var)
#      -$debug : adds keys in the returned HASH 
#
# OUT : undef | ref(HASH) containing keys :
#        -action : 'do_it'|'reject'|'request_auth'
#           |'owner'|'editor'|'editorkey'|'listmaster'
#        -reason : defined if action == 'reject' 
#           and in scenario : reject(reason='...')
#           key for template authorization_reject.tt2
#        -tt2 : defined if action == 'reject'  
#           and in scenario : reject(tt2='...') or reject('...tt2')
#           match a key in authorization_reject.tt2
#        -condition : the checked condition 
#           (defined if $debug)
#        -auth_method : the checked auth_method 
#           (defined if $debug)
###################################################### 
sub request_action {
    my $operation = shift;
    my $auth_method = shift;
    my $robot=shift;
    my $context = shift;
    my $debug = shift;
    do_log('debug', 'List::request_action %s,%s,%s',$operation,$auth_method,$robot);

    ## Defining default values for parameters.
    $context->{'sender'} ||= 'nobody' ;
    $context->{'email'} ||= $context->{'sender'};
    $context->{'remote_host'} ||= 'unknown_host' ;
    $context->{'robot_domain'} = $robot ;
    $context->{'msg'} = $context->{'message'}->{'msg'} if (defined $context->{'message'});
    $context->{'msg_encrypted'} = 'smime' if (defined $context->{'message'} && 
					      $context->{'message'}->{'smime_crypted'} eq 'smime_crypted');
    ## Check that authorization method is one of those known by Sympa
    unless ( $auth_method =~ /^(smtp|md5|pgp|smime)/) {
	do_log('info',"fatal error : unknown auth method $auth_method in List::get_action");
	return undef;
    }
    my (@rules, $name, $scenario) ;

    ## Include a Blacklist rules if configured for this action
    if ($Conf{'blacklist'}{$operation}) {
	foreach my $auth ('smtp','md5','pgp','smime'){
	    my $blackrule = {'condition' => "search('blacklist.txt',[sender])",
			     'action' => 'reject,quiet',
			     'auth_method' => $auth};	
	    push(@rules, $blackrule);
	}
    }

    if ($context->{'listname'}) {
        unless ( $context->{'list_object'} = new List ($context->{'listname'}, $robot) ){
	    do_log('info',"request_action :  unable to create object $context->{'listname'}");
	    return undef ;
	}
    }    

    ## The current action relates to a list
    if (defined $context->{'list_object'}) {
	my $list = $context->{'list_object'};

	## The $operation refers to a list parameter of the same name
	## The list parameter might be structured ('.' is a separator)
	my @operations = split /\./, $operation;
	my $scenario_path;
	
	if ($#operations == 0) {
	    ## Simple parameter
	    $scenario_path = $list->{'admin'}{$operation}{'file_path'};
	}else{
	    ## Structured parameter
	    $scenario_path = $list->{'admin'}{$operations[0]}{$operations[1]}{'file_path'} if (defined $list->{'admin'}{$operations[0]});
	}
	
	## List parameter might not be defined (example : web_archive.access)
	unless (defined $scenario_path) {
	    my $return = {'action' => 'reject',
			  'reason' => 'parameter-not-defined',
			  'auth_method' => '',
			  'condition' => ''
			  };
	    return $return;
	}

	## Prepares custom_vars in $context
	if (defined $list->{'admin'}{'custom_vars'}) {
	    foreach my $var (@{$list->{'admin'}{'custom_vars'}}) {
		$context->{'custom_vars'}{$var->{'name'}} = $var->{'value'};
	    }
	}
	
	## Create Scenario object
	$scenario = new Scenario ('robot' => $robot, 
				  'directory' => $list->{'dir'},
				  'file_path' => $scenario_path,
				  'options' => $context->{'options'});

	## pending/closed lists => send/visibility are closed
	unless ($list->{'admin'}{'status'} eq 'open') {
	    if ($operation =~ /^send|visibility$/) {
		my $return = {'action' => 'reject',
			      'reason' => 'list-no-open',
			      'auth_method' => '',
			      'condition' => ''
			      };
		return $return;
	    }
	}
	
	### the following lines are used by the document sharing action 
	if (defined $context->{'scenario'}) { 
	    
	    # loading of the structure
	    $scenario = new Scenario ('robot' => $robot, 
				      'directory' => $list->{'dir'},
				      'function' => $operations[$#operations],
				      'name' => $context->{'scenario'},
				      'options' => $context->{'options'});
	}

    }elsif ($context->{'topicname'}) {
	## Topics

	$scenario = new Scenario ('robot' => $robot, 
				  'function' => 'topics_visibility',
				  'name' => $List::list_of_topics{$robot}{$context->{'topicname'}}{'visibility'},
				  'options' => $context->{'options'});

    }else{	
	## Global scenario (ie not related to a list) ; example : create_list
	
	my $p = &Conf::get_robot_conf($robot, $operation);
	$scenario = new Scenario ('robot' => $robot, 
				  'function' => $operation,
				  'name' => $p,
				  'options' => $context->{'options'});
    }

    unless ((defined $scenario) && (defined $scenario->{'rules'})) {
	do_log('err',"Failed to load scenario for '$operation'");
	return undef ;
    }

    push @rules, @{$scenario->{'rules'}};
    $name = $scenario->{'name'};

    unless ($name) {
	# do_log('err',"internal error : configuration for operation $operation is not yet performed by scenario");
	return undef;
    }

    ## Include include.<action>.header if found
    my %param = ('function' => 'include',
		 'robot' => $robot, 
		 'name' => $operation.'.header',
		 'options' => $context->{'options'});
    $param{'directory'} = $context->{'list_object'}{'dir'} if (defined $context->{'list_object'});
    my $include_scenario = new Scenario %param;
    if (defined $include_scenario) {
	## Add rules at the beginning of the array
	unshift @rules, @{$include_scenario->{'rules'}};
    }

    ## Look for 'include' directives amongst rules first
    foreach my $index (0..$#rules) {
	if ($rules[$index]{'condition'} =~ /^\s*include\s*\(?\'?([\w\.]+)\'?\)?\s*$/i) {
	    my $include_file = $1;
	    my %param = ('function' => 'include',
			 'robot' => $robot, 
			 'name' => $include_file,
			 'options' => $context->{'options'});
	    $param{'directory'} = $context->{'list_object'}{'dir'} if (defined $context->{'list_object'});
	    my $include_scenario = new Scenario %param;
	    if (defined $include_scenario) {
		## Removes the include directive and replace it with included rules
		splice @rules, $index, 1, @{$include_scenario->{'rules'}};
	    }	    
	}
    }    

    my $return = {};
    foreach my $rule (@rules) {
	# &do_log('info', 'List::request_action : verify rule %s',$rule->{'condition'});

	if ($auth_method eq $rule->{'auth_method'}) {
	    my $result =  &verify ($context,$rule->{'condition'});

	    ## Cope with errors
	    if (! defined ($result)) {
		do_log('info',"error in $rule->{'condition'},$rule->{'auth_method'},$rule->{'action'}" );
		
		&do_log('info', 'Error in %s scenario, in list %s', $context->{'scenario'}, $context->{'listname'});
		
		if ($debug) {
		    $return = {'action' => 'reject',
			       'reason' => 'error-performing-condition',
			       'auth_method' => $rule->{'auth_method'},
			       'condition' => $rule->{'condition'}
			   };
		    return $return;
		}
		unless (&List::send_notify_to_listmaster('error-performing-condition', $robot, [$context->{'listname'}."  ".$rule->{'condition'}] )) {
		    &do_log('notice',"Unable to send notify 'error-performing-condition' to listmaster");
		}
		return undef;
	    }

	    ## Rule returned false
	    if ($result == -1) {
		next;
	    }
	    
	    my $action = $rule->{'action'};

            ## reject : get parameters
	    if ($action =~/^reject(\((.+)\))?(\s?,\s?(quiet))?/) {

		if ($4 eq 'quiet') { 
		    $action = 'reject,quiet';
		} else{
		    $action = 'reject';	
		}
		my @param = split /,/,$2;
		
       		foreach my $p (@param){
		    if  ($p =~ /^reason=\'?(\w+)\'?/){
			$return->{'reason'} = $1;
			next;
			
		    }elsif ($p =~ /^tt2=\'?(\w+)\'?/){
			$return->{'tt2'} = $1;
			next;
			
		    }
		    if ($p =~ /^\'?[^=]+\'?/){
			$return->{'tt2'} = $p;
			# keeping existing only, not merging with reject parameters in scenarios
			last;
		    }
		}
	    }

	    $return->{'action'} = $action;
	    
	    if ($result == 1) {
		&do_log('debug3',"rule $rule->{'condition'},$rule->{'auth_method'},$rule->{'action'} accepted");
		if ($debug) {
		    $return->{'auth_method'} = $rule->{'auth_method'};
		    $return->{'condition'} = $rule->{'condition'};
		    return $return;
		}

		## Check syntax of returned action
		unless ($action =~ /^(do_it|reject|request_auth|owner|editor|editorkey|listmaster)/) {
		    &do_log('err', "Matched unknown action '%s' in scenario", $rule->{'action'});
		    return undef;
		}
		return $return;
	    }
	}
    }
    &do_log('debug3',"no rule match, reject");

    $return = {'action' => 'reject',
	       'reason' => 'no-rule-match',
			   'auth_method' => 'default',
			   'condition' => 'default'
			   };
    return $return;
}

## check if email respect some condition
sub verify {
    my ($context, $condition) = @_;
    &do_log('debug2', '(%s)', $condition);

    my $robot = $context->{'robot_domain'};

#    while (my($k,$v) = each %{$context}) {
#	do_log('debug3',"verify: context->{$k} = $v");
#    }

    unless (defined($context->{'sender'} )) {
	do_log('info',"internal error, no sender find in List::verify, report authors");
	return undef;
    }

    $context->{'execution_date'} = time unless ( defined ($context->{'execution_date'}) );

    if (defined ($context->{'msg'})) {
	my $header = $context->{'msg'}->head;
	unless (($header->get('to') && ($header->get('to') =~ /$context->{'listname'}/i)) || 
		($header->get('cc') && ($header->get('cc') =~ /$context->{'listname'}/i))) {
	    $context->{'is_bcc'} = 1;
	}else{
	    $context->{'is_bcc'} = 0;
	}
	
    }
    my $list;
    if ($context->{'listname'} && ! defined $context->{'list_object'}) {
        unless ( $context->{'list_object'} = new List ($context->{'listname'}, $robot) ){
	    &do_log('info',"Unable to create object $context->{'listname'}");
	    return undef ;
	}
    }    

    if (defined ($context->{'list_object'})) {
	$list = $context->{'list_object'};
	$context->{'listname'} = $list->{'name'};

	$context->{'host'} = $list->{'admin'}{'host'};
    }

    unless ($condition =~ /(\!)?\s*(true|is_listmaster|is_editor|is_owner|is_subscriber|match|equal|message|older|newer|all|search|customcondition\:\:\w+)\s*\(\s*(.*)\s*\)\s*/i) {
	&do_log('err', "error rule syntaxe: unknown condition $condition");
	return undef;
    }
    my $negation = 1 ;
    if ($1 eq '!') {
	$negation = -1 ;
    }

    my $condition_key = lc($2);
    my $arguments = $3;
    my @args;

    ## The expression for regexp is tricky because we don't allow the '/' character (that indicates the end of the regexp
    ## but we allow any number of \/ escape sequence
    while ($arguments =~ s/^\s*(
				\[\w+(\-\>[\w\-]+)?\]
				|
				([\w\-\.]+)
				|
				'[^,)]*'
				|
				"[^,)]*"
				|
				\/([^\/]*((\\\/)*[^\/]+))*\/
				|(\w+)\.ldap
				|(\w+)\.sql
				)\s*,?//x) {
	my $value=$1;

	## Custom vars
	if ($value =~ /\[custom_vars\-\>([\w\-]+)\]/i) {
	    $value =~ s/\[custom_vars\-\>([\w\-]+)\]/$context->{'custom_vars'}{$1}/;
	}
	
	## Config param
	elsif ($value =~ /\[conf\-\>([\w\-]+)\]/i) {
	    if (my $conf_value = &Conf::get_robot_conf($robot, $1)) {
		
		$value =~ s/\[conf\-\>([\w\-]+)\]/$conf_value/;
	    }else{
		do_log('debug',"undefine variable context $value in rule $condition");
		# a condition related to a undefined context variable is always false
		return -1 * $negation;
 #		return undef;
	    }

	    ## List param
	}elsif ($value =~ /\[list\-\>([\w\-]+)\]/i) {
	    if ($1 =~ /^name|total$/) {
		$value =~ s/\[list\-\>([\w\-]+)\]/$list->{$1}/;
	    }elsif ($list->{'admin'}{$1} and (!ref($list->{'admin'}{$1})) ) {
		$value =~ s/\[list\-\>([\w\-]+)\]/$list->{'admin'}{$1}/;
	    }else{
		do_log('err','Unknown list parameter %s in rule %s', $value, $condition);
		return undef;
	    }

	}elsif ($value =~ /\[env\-\>([\w\-]+)\]/i) {
	    
	    $value =~ s/\[env\-\>([\w\-]+)\]/$ENV{$1}/;

	    ## Sender's user/subscriber attributes (if subscriber)
	}elsif ($value =~ /\[user\-\>([\w\-]+)\]/i) {

	    $context->{'user'} ||= &List::get_user_db($context->{'sender'});	    
	    $value =~ s/\[user\-\>([\w\-]+)\]/$context->{'user'}{$1}/;

	}elsif ($value =~ /\[user_attributes\-\>([\w\-]+)\]/i) {
	    
	    $context->{'user'} ||= &List::get_user_db($context->{'sender'});
	    $value =~ s/\[user_attributes\-\>([\w\-]+)\]/$context->{'user'}{'attributes'}{$1}/;

	}elsif (($value =~ /\[subscriber\-\>([\w\-]+)\]/i) && defined ($context->{'sender'} ne 'nobody')) {
	    
	    $context->{'subscriber'} ||= $list->get_subscriber($context->{'sender'});
	    $value =~ s/\[subscriber\-\>([\w\-]+)\]/$context->{'subscriber'}{$1}/;

	    ## SMTP Header field
	}elsif ($value =~ /\[(msg_header|header)\-\>([\w\-]+)\]/i) {
	    my $field_name = $2;
	    if (defined ($context->{'msg'})) {
		my $header = $context->{'msg'}->head;
		my @fields = $header->get($field_name);
		## Defaulting empty or missing fields to '', so that we can test
		## their value in Scenario, considering that, for an incoming message,
		## a missing field is equivalent to an empty field : the information it
		## is supposed to contain isn't available.
		unless (@fields) {
		    @fields = ('');
		}
		
		$value = \@fields;
	    }else {
		return -1 * $negation;
	    }
	    
	}elsif ($value =~ /\[msg_body\]/i) {
	    return -1 * $negation unless (defined ($context->{'msg'}));
	    return -1 * $negation unless (defined ($context->{'msg'}->effective_type() =~ /^text/));
	    return -1 * $negation unless (defined $context->{'msg'}->bodyhandle);

	    $value = $context->{'msg'}->bodyhandle->as_string();

	}elsif ($value =~ /\[msg_part\-\>body\]/i) {
	    return -1 * $negation unless (defined ($context->{'msg'}));
	    
	    my @bodies;
	    my @parts = $context->{'msg'}->parts();
	    
	    ## Should be recurcive...
	    foreach my $i (0..$#parts) {
		next unless ($parts[$i]->effective_type() =~ /^text/);
		next unless (defined $parts[$i]->bodyhandle);

		push @bodies, $parts[$i]->bodyhandle->as_string();
	    }
	    $value = \@bodies;

	}elsif ($value =~ /\[msg_part\-\>type\]/i) {
	    return -1 * $negation unless (defined ($context->{'msg'}));
	    
	    my @types;
	    my @parts = $context->{'msg'}->parts();
	    foreach my $i (0..$#parts) {
		push @types, $parts[$i]->effective_type();
	    }
	    $value = \@types;

	}elsif ($value =~ /\[current_date\]/i) {
	    my $time = time;
	    $value =~ s/\[current_date\]/$time/;
	    
	    ## Quoted string
	}elsif ($value =~ /\[(\w+)\]/i) {

	    if (defined ($context->{$1})) {
		$value =~ s/\[(\w+)\]/$context->{$1}/i;
	    }else{
		&do_log('debug',"undefine variable context $value in rule $condition");
		# a condition related to a undefined context variable is always false
		return -1 * $negation;
 #		return undef;
	    }
	    
	}elsif ($value =~ /^'(.*)'$/ || $value =~ /^"(.*)"$/) {
	    $value = $1;
	}
	push (@args,$value);
	
    }
    # Getting rid of spaces.
    $condition_key =~ s/^\s*//g;
    $condition_key =~ s/\s*$//g;
    # condition that require 0 argument
    if ($condition_key =~ /^true|all$/i) {
	unless ($#args == -1){ 
	    do_log('err',"error rule syntaxe : incorrect number of argument or incorrect argument syntaxe $condition") ; 
	    return undef ;
	}
	# condition that require 1 argument
    }elsif ($condition_key eq 'is_listmaster') {
	unless ($#args == 0) { 
	     do_log('err',"error rule syntaxe : incorrect argument number for condition $condition_key") ; 
	    return undef ;
	}
	# condition that require 1 or 2 args (search : historical reasons)
    }elsif ($condition_key =~ /^search$/o) {
	unless ($#args == 1 || $#args == 0) {
	    do_log('err',"error rule syntaxe : Incorrect argument number for condition $condition_key") ; 
	    return undef ;
	}
	# condition that require 2 args
    }elsif ($condition_key =~ /^is_owner|is_editor|is_subscriber|match|equal|message|newer|older$/o) {
	unless ($#args == 1) {
	    do_log('err',"error rule syntaxe : incorrect argument number (%d instead of %d) for condition $condition_key", $#args+1, 2) ; 
	    return undef ;
	}
    }elsif ($condition_key !~ /^customcondition::/o) {
	do_log('err', "error rule syntaxe : unknown condition $condition_key");
	return undef;
    }

    ## Now eval the condition
    ##### condition : true
    if ($condition_key =~ /^true|any|all$/i) {
	return $negation;
    }
    ##### condition is_listmaster
    if ($condition_key eq 'is_listmaster') {
	
	if ($args[0] eq 'nobody') {
	    return -1 * $negation ;
	}

	if ( &List::is_listmaster($args[0],$robot)) {
	    return $negation;
	}else{
	    return -1 * $negation;
	}
    }

    ##### condition older
    if ($condition_key =~ /^older|newer$/) {
	 
	$negation *= -1 if ($condition_key eq 'newer');
 	my $arg0 = &tools::epoch_conv($args[0]);
 	my $arg1 = &tools::epoch_conv($args[1]);
 
	&do_log('debug4', '%s(%d, %d)', $condition_key, $arg0, $arg1);
 	if ($arg0 <= $arg1 ) {
 	    return $negation;
 	}else{
 	    return -1 * $negation;
 	}
     }


    ##### condition is_owner, is_subscriber and is_editor
    if ($condition_key =~ /^is_owner|is_subscriber|is_editor$/i) {
	my ($list2);

	if ($args[1] eq 'nobody') {
	    return -1 * $negation ;
	}

	## The list is local or in another local robot
	if ($args[0] =~ /\@/) {
	    $list2 = new List ($args[0]);
	}else {
	    $list2 = new List ($args[0], $robot);
	}
		
	if (! $list2) {
	    do_log('err',"unable to create list object \"$args[0]\"");
	    return -1 * $negation ;
	}

	if ($condition_key eq 'is_subscriber') {

	    if ($list2->is_user($args[1])) {
		return $negation ;
	    }else{
		return -1 * $negation ;
	    }

	}elsif ($condition_key eq 'is_owner') {
	    if ($list2->am_i('owner',$args[1])) {
		return $negation ;
	    }else{
		return -1 * $negation ;
	    }

	}elsif ($condition_key eq 'is_editor') {
	    if ($list2->am_i('editor',$args[1])) {
		return $negation ;
	    }else{
		return -1 * $negation ;
	    }
	}
    }
    ##### match
    if ($condition_key eq 'match') {
	unless ($args[1] =~ /^\/(.*)\/$/) {
	    &do_log('err', 'Match parameter %s is not a regexp', $args[1]);
	    return undef;
	}
	my $regexp = $1;
	
	if ($regexp =~ /\[host\]/) {
	    my $reghost = &Conf::get_robot_conf($robot, 'host');
            $reghost =~ s/\./\\./g ;
            $regexp =~ s/\[host\]/$reghost/g ;
	}

	if (ref($args[0])) {
	    foreach my $arg (@{$args[0]}) {
		return $negation 
		    if ($arg =~ /$regexp/i);
	    }
	}else {
	    if ($args[0] =~ /$regexp/i) {
		return $negation ;
	    }
	}
	
	return -1 * $negation ;

    }
    
    ## search rule
    if ($condition_key eq 'search') {
	my $val_search;
 	# we could search in the family if we got ref on Family object
 	if (defined $list){
 	    $val_search = &search($args[0],$context,$robot,$list);
 	}else {
 	    $val_search = &search($args[0],$context,$robot);
 	}
	return undef unless defined $val_search;
	if($val_search == 1) { 
	    return $negation;
	}else {
	    return -1 * $negation;
    	}
    }

    ## equal
    if ($condition_key eq 'equal') {
	if (ref($args[0])) {
	    foreach my $arg (@{$args[0]}) {
		&do_log('debug3', 'ARG: %s', $arg);
		return $negation 
		    if ($arg =~ /^$args[1]$/i);
	    }
	}else {
	    if ($args[0] =~ /^$args[1]$/i) {
		return $negation ;
	    }
	}
	return -1 * $negation ;
    }

    ## custom perl module
    if ($condition_key =~ /^customcondition::(\w+)/o ) {
    	my $condition = $1;
    	
    	my $res = &verify_custom($condition, \@args, $robot, $list);
	return undef unless defined $res;
	return $res * $negation ;
    }
    return undef;
}

## Verify if a given user is part of an LDAP, SQL or TXT search filter
sub search{
    my $filter_file = shift;
    my $context = shift;
    my $robot = shift;
    my $list = shift;

    my $sender = $context->{'sender'};

    &do_log('debug2', 'List::search(%s,%s,%s)', $filter_file, $sender, $robot);
    
    if ($filter_file =~ /\.sql$/) {
 
	my $file = &tools::get_filename('etc',{},"search_filters/$filter_file", $robot, $list);
	
        my $timeout = 3600;
        my ($sql_conf, $tsth);
        my $time = time;
	
        unless ($sql_conf = &Conf::load_sql_filter($file)) {
            $list->send_notify_to_owner('named_filter',{'filter' => $filter_file})
                if (defined $list && ref($list) eq 'List');
            return undef;
        }
	
        my $statement = $sql_conf->{'sql_named_filter_query'}->{'statement'};
        my $filter = $statement;
	my @statement_args; ## Useful to later quote parameters
	
	## Minimalist variable parser ; only parse [x] or [x->y]
	## should be extended with the code from verify()
	while ($filter =~ /\[(\w+(\-\>[\w\-]+)?)\]/x) {
	    my ($full_var) = ($1);
	    my ($var, $key) = split /\-\>/, $full_var;
	    
	    unless (defined $context->{$var}) {
		&do_log('err', "Failed to parse variable '%s' in filter '%s'", $var, $file);
		return undef;
	    }

	    if (defined $key) { ## Should be a hash
		unless (defined $context->{$var}{$key}) {
		    &do_log('err', "Failed to parse variable '%s.%s' in filter '%s'", $var, $key, $file);
		    return undef;
		}

		$filter =~ s/\[$full_var\]/$context->{$var}{$key}/;
		$statement =~ s/\[$full_var\]/\%s/;
		push @statement_args, $context->{$var}{$key};
	    }else { ## Scalar
		$filter =~ s/\[$full_var\]/$context->{$var}/;
		$statement =~ s/\[$full_var\]/\%s/;
		push @statement_args, $context->{$var};

	    }
	}

#        $statement =~ s/\[sender\]/%s/g;
#        $filter =~ s/\[sender\]/$sender/g;
 
        if (defined ($persistent_cache{'named_filter'}{$filter_file}{$filter}) &&
            (time <= $persistent_cache{'named_filter'}{$filter_file}{$filter}{'update'} + $timeout)){ ## Cache has 1hour lifetime
            &do_log('notice', 'Using previous SQL named filter cache');
            return $persistent_cache{'named_filter'}{$filter_file}{$filter}{'value'};
        }
	
	my $ds = new Datasource('SQL', $sql_conf->{'sql_named_filter_query'});
	unless ($ds->connect() && $ds->ping) {
            do_log('notice','Unable to connect to the SQL server %s:%d',$sql_conf->{'db_host'}, $sql_conf->{'db_port'});
            return undef;
        }
	
	## Quote parameters
	foreach (@statement_args) {
	    $_ = $ds->quote($_);
	}

        $statement = sprintf $statement, @statement_args;
        unless ($ds->query($statement)) {
            do_log('debug','%s named filter cancelled', $file);
            return undef;
        }
 
        my $res = $ds->fetch;
        $ds->disconnect();
        do_log('debug2','Result of SQL query : %d = %s', $res->[0], $statement);
 
        if ($res->[0] == 0){
            $persistent_cache{'named_filter'}{$filter_file}{$filter}{'value'} = 0;
        }else {
            $persistent_cache{'named_filter'}{$filter_file}{$filter}{'value'} = 1;
       }
        $persistent_cache{'named_filter'}{$filter_file}{$filter}{'update'} = time;
        return $persistent_cache{'named_filter'}{$filter_file}{$filter}{'value'};
 
     }elsif ($filter_file =~ /\.ldap$/) {	
	## Determine full path of the filter file
	my $file = &tools::get_filename('etc',{},"search_filters/$filter_file", $robot, $list);
	
	unless ($file) {
	    &do_log('err', 'Could not find search filter %s', $filter_file);
	    return undef;
	}   
	my $timeout = 3600;	
	my $var;
	my $time = time;
	my %ldap_conf;
    
	return undef unless (%ldap_conf = &Ldap::load($file));

	my $filter = $ldap_conf{'filter'};	

	## Minimalist variable parser ; only parse [x] or [x->y]
	## should be extended with the code from verify()
	while ($filter =~ /\[(\w+(\-\>[\w\-]+)?)\]/x) {
	    my ($full_var) = ($1);
	    my ($var, $key) = split /\-\>/, $full_var;
	    
	    unless (defined $context->{$var}) {
		&do_log('err', "Failed to parse variable '%s' in filter '%s'", $var, $file);
		return undef;
	    }

	    if (defined $key) { ## Should be a hash
		unless (defined $context->{$var}{$key}) {
		    &do_log('err', "Failed to parse variable '%s.%s' in filter '%s'", $var, $key, $file);
		    return undef;
		}

		$filter =~ s/\[$full_var\]/$context->{$var}{$key}/;
	    }else { ## Scalar
		$filter =~ s/\[$full_var\]/$context->{$var}/;

	    }
	}

#	$filter =~ s/\[sender\]/$sender/g;
	
	if (defined ($persistent_cache{'named_filter'}{$filter_file}{$filter}) &&
	    (time <= $persistent_cache{'named_filter'}{$filter_file}{$filter}{'update'} + $timeout)){ ## Cache has 1hour lifetime
	    &do_log('notice', 'Using previous LDAP named filter cache');
	    return $persistent_cache{'named_filter'}{$filter_file}{$filter}{'value'};
	}
	
	my $ldap;
	my $param = &tools::dup_var(\%ldap_conf);
	my $ds = new Datasource('LDAP', $param);
	    
	unless (defined $ds && ($ldap = $ds->connect())) {
	    &do_log('err',"Unable to connect to the LDAP server '%s'", $param->{'ldap_host'});
	    return undef;
	    }
	    
	## The 1.1 OID correponds to DNs ; it prevents the LDAP server from 
	## preparing/providing too much data
	    my $mesg = $ldap->search(base => "$ldap_conf{'suffix'}" ,
				     filter => "$filter",
				 scope => "$ldap_conf{'scope'}",
				 attrs => ['1.1']);
	    unless ($mesg) {
		do_log('err',"Unable to perform LDAP search");
		return undef;
	    }    
	    unless ($mesg->code == 0) {
		do_log('err','Ldap search failed');
		return undef;
	    }

	    if ($mesg->count() == 0){
		$persistent_cache{'named_filter'}{$filter_file}{$filter}{'value'} = 0;
		
	    }else {
		$persistent_cache{'named_filter'}{$filter_file}{$filter}{'value'} = 1;
	    }
	    
	$ds->disconnect() or do_log('notice','List::search_ldap.Unbind impossible');
	    $persistent_cache{'named_filter'}{$filter_file}{$filter}{'update'} = time;
	    
	    return $persistent_cache{'named_filter'}{$filter_file}{$filter}{'value'};

    }elsif($filter_file =~ /\.txt$/){ 
	# &do_log('info', 'List::search: eval %s', $filter_file);
	my @files = &tools::get_filename('etc',{'order'=>'all'},"search_filters/$filter_file", $robot, $list); 

	## Raise an error except for blacklist.txt
	unless (@files) {
	    if ($filter_file eq 'blacklist.txt') {
		return -1;
	    }else {
		&do_log('err', 'Could not find search filter %s', $filter_file);
		return undef;
	    }
	}

	my $sender = lc($sender);
	foreach my $file (@files) {
	    &do_log('debug3', 'List::search: found file  %s', $file);
	    unless (open FILE, $file) {
		&do_log('err', 'Could not open file %s', $file);
		return undef;
	    } 
	    while (<FILE>) {
		# &do_log('debug3', 'List::search: eval rule %s', $_);
		next if (/^\s*$/o || /^[\#\;]/o);
		my $regexp= $_ ;
		chomp $regexp;
		$regexp =~ s/\*/.*/ ; 
		$regexp = '^'.$regexp.'$';
		# &do_log('debug3', 'List::search: eval  %s =~ /%s/i', $sender,$regexp);
		return 1  if ($sender =~ /$regexp/i);
	    }
	}
	return -1;
    } else {
	do_log('err',"Unknown filter file type %s", $filter_file);
    	return undef;
    }
}

# eval a custom perl module to verify a scenario condition
sub verify_custom {
	my ($condition, $args_ref, $robot, $list) = @_;
        my $timeout = 3600;
	
	my $filter = join ('*', @{$args_ref});
	&do_log('debug2', 'List::verify_custom(%s,%s,%s,%s)', $condition, $filter, $robot, $list);
        if (defined ($persistent_cache{'named_filter'}{$condition}{$filter}) &&
            (time <= $persistent_cache{'named_filter'}{$condition}{$filter}{'update'} + $timeout)){ ## Cache has 1hour lifetime
            &do_log('notice', 'Using previous custom condition cache %s', $filter);
            return $persistent_cache{'named_filter'}{$condition}{$filter}{'value'};
        }

    	# use this if your want per list customization (be sure you know what you are doing)
	#my $file = &tools::get_filename('etc',{},"custom_conditions/${condition}.pm", $robot, $list);
	my $file = &tools::get_filename('etc',{},"custom_conditions/${condition}.pm", $robot);
	unless ($file) {
	    &do_log('err', 'No module found for %s custom condition', $condition);
	    return undef;
	}
	&do_log('notice', 'Use module %s for custom condition', $file);
	eval { require "$file"; };
	if ($@) {
	    &do_log('err', 'Error requiring %s : %s (%s)', $condition, "$@", ref($@));
	    return undef;
	}
	my $res;
	eval "\$res = CustomCondition::${condition}::verify(\@{\$args_ref});";
	if ($@) {
	    &do_log('err', 'Error evaluating %s : %s (%s)', $condition, "$@", ref($@));
	    return undef;
	}

	return undef unless defined $res;
	
        $persistent_cache{'named_filter'}{$condition}{$filter}{'value'} = ($res == 1 ? 1 : 0);
        $persistent_cache{'named_filter'}{$condition}{$filter}{'update'} = time;
        return $persistent_cache{'named_filter'}{$condition}{$filter}{'value'};
}

sub dump_all_scenarios {
    open TMP, ">/tmp/all_scenarios";
    &tools::dump_var(\%all_scenarios, 0, \*TMP);
    close TMP;
}


#### Module should return 1 #####
return 1;
