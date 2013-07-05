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
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

package Scenario;

use strict;
use warnings;

use Carp qw(croak);
use Cwd;
use File::Spec;
use Mail::Address;
use Net::Netmask;
# tentative
use Data::Dumper;

#use Conf; # used in List - Site
#use Language; # used in List
#use List; # this package is used by List
#use Log; # used in Conf
#use Sympa::Constants; # used in Conf - confdef
#use tools; # used in Conf

my %all_scenarios;
my %persistent_cache;

=encoding utf-8

=head1 NAME

Scenario - Sympa scenarios

=head1 DESCRIPTION

=head2 Constructor

=over 4

=item new ( THAT, [ KEY => VAL, ... ] )

I<Constructor>.
Creates a new object

IN : -$pkg (+): class name
     -$that (+) : ref(List) | ref(Robot) | "Site"
     -%parameters : hash

OUT : Scenario object or undef

Supported parameters : function, name, file_path, options

Output object has the following entries : name, file_path, rules, date,
title, struct, data

=back

=cut

sub new {
    my $pkg        = shift;
    my $that       = shift;
    my %parameters = @_;
    Log::do_log(
	'debug2',
	'(%s, %s, function=%s, name=%s, file_path=%s, options=%s)',
	$pkg,
	$that,
	$parameters{'function'},
	$parameters{'name'},
	$parameters{'file_path'},
	$parameters{'options'}
    );

    unless (ref $that and
	ref $that eq 'List' or
	ref $that and
	ref $that eq 'Robot' or
	$that eq 'Site') {    # FIXME: really maybe a Site?
	croak 'bug in logic.  Ask developer';
    }

    my $scenario = {};

    ## Check parameters
    ## Need either file_path or function+name
    ## Note: parameter 'directory' was deprecated
    unless ($parameters{'file_path'} or
	$parameters{'function'} and
	$parameters{'name'}) {
	Log::do_log('err', 'Missing parameter');
	return undef;
    }

    my $file_path = $parameters{'file_path'};
    my $function  = $parameters{'function'};
    my $name      = $parameters{'name'};
    my $options   = $parameters{'options'} || {};
    my $scenario_struct;

    ## Determine the file path of the scenario

    if ($file_path and $file_path eq 'ERROR') {
	return $all_scenarios{$file_path};
    }

    unless ($file_path) {
	$file_path =
	    $that->get_etc_filename('scenari/' . $function . '.' . $name);
    }

    if ($file_path) {
	$scenario->{'file_path'} = $file_path;

	## Try to follow symlink.  If it succeed, try to get function and name
	## from real path name.
	my $filename;
	if (-l $file_path) {
	    my $realpath = Cwd::abs_path($file_path);
	    if ($realpath and
		-r $realpath and
		($filename = [File::Spec->splitpath($realpath)]->[2]) and
		$filename =~ /^([^\.]+)\.(.+)$/ and
		(!$function or $function eq $1)    # only for same function
		) {
		($function, $name) = ($1, $2);
	    }
	}
	## Otherwise, get function and name from original path name
	if (!($function and $name) and -r $file_path) {
	    $filename = [File::Spec->splitpath($file_path)]->[2];
	    unless ($filename and $filename =~ /^([^\.]+)\.(.+)$/) {
		Log::do_log('err',
		    'Failed to determine scenario type and name from "%s"',
		    $file_path);
		return undef;
	    }
	    ($function, $name) = ($1, $2);
	}

	## Load the scenario if previously loaded in memory
	if (defined $all_scenarios{$file_path}) {

	    ## Option 'dont_reload_scenario' prevents scenario reloading
	    ## Usefull for performances reasons
	    if ($options->{'dont_reload_scenario'}) {
		return $all_scenarios{$file_path};
	    }

	    ## Use cache unless file has changed on disk
	    if ($all_scenarios{$file_path}{'date'} >= (stat($file_path))[9]) {
		return $all_scenarios{$file_path};
	    }
	}

	## Load the scenario

	## Get the data from file
	unless (open SCENARIO, '<', $file_path) {
	    Log::do_log('err', 'Failed to open scenario "%s"', $file_path);
	    return undef;
	}
	my $data = join '', <SCENARIO>;
	close SCENARIO;

	## Keep rough scenario
	$scenario->{'data'} = $data;

	$scenario_struct = _parse_scenario($function, $name, $data);
    } elsif ($function eq 'include') {
	## include.xx not found will not raise an error message
	return undef;
    } else {
	## Default rule is 'true() smtp -> reject'
	Log::do_log(
	    'err',
	    'Unable to find scenario file "%s.%s", please report to listmaster',
	    $function,
	    $name
	);
	$scenario_struct =
	    _parse_scenario($function, $name, 'true() smtp -> reject');
	$scenario->{'file_path'} = 'ERROR';                   ## special value
	$scenario->{'data'}      = 'true() smtp -> reject';
    }

    ## Keep track of the current time ; used later to reload scenario files
    ## when they changed on disk
    $scenario->{'date'} = time;

    unless (ref($scenario_struct) eq 'HASH') {
	Log::do_log('err', 'Failed to load scenario "%s.%s"',
	    $function, $name);
	return undef;
    }

    $scenario->{'name'}   = $scenario_struct->{'name'};
    $scenario->{'rules'}  = $scenario_struct->{'rules'};
    $scenario->{'title'}  = $scenario_struct->{'title'};
    $scenario->{'struct'} = $scenario_struct;

    ## Bless Scenario object
    bless $scenario => $pkg;

    ## Keep the scenario in memory
    $all_scenarios{$scenario->{'file_path'}} = $scenario;

    return $scenario;
}

## Parse scenario rules
sub _parse_scenario {
    Log::do_log('debug3', '(%s, %s, %s)', @_);
    my ($function, $scenario_name, $paragraph) = @_;

    my $structure = {};
    $structure->{'name'} = $scenario_name;
    my @scenario;
    my @rules = split /\n/, $paragraph;

    foreach my $current_rule (@rules) {
	my @auth_methods_list;
	next if ($current_rule =~ /^\s*\w+\s*$/o);    # skip paragraph name
	my $rule = {};
	$current_rule =~ s/\#.*$//;                   # remove comments
	next if ($current_rule =~ /^\s*$/);           # skip empty lines
	if ($current_rule =~ /^\s*title\.gettext\s+(.*)\s*$/i) {
	    $structure->{'title'}{'gettext'} = $1;
	    next;
	} elsif ($current_rule =~ /^\s*title\.us\s+(.*)\s*$/i) {
	    $structure->{'title'}{'us'} = $1;
	    next;
	} elsif ($current_rule =~ /^\s*title\.([-.\w]+)\s+(.*)\s*$/i) {
	    my ($lang, $title) = ($1, $2);
	    $lang = Language::CanonicLang($lang) || $lang;
	    $structure->{'title'}{$lang} = $title;
	    next;
	} elsif ($current_rule =~ /^\s*title\s+(.*)\s*$/i) {
	    $structure->{'title'}{'us'} = $1;
	    next;
	}

	if ($current_rule =~ /\s*(include\s*\(?\'?(.*)\'?\)?)\s*$/i) {
	    $rule->{'condition'} = $1;
	    push(@scenario, $rule);
	} elsif ($current_rule =~
	    /^\s*(.*?)\s+((\s*(md5|pgp|smtp|smime|dkim)\s*,?)*)\s*->\s*(.*)\s*$/gi
	    ) {
	    $rule->{'condition'} = $1;
	    $rule->{'action'}    = $5;
	    my $auth_methods = $2 || 'smtp';
	    $auth_methods =~ s/\s//g;
	    @auth_methods_list = split ',', $auth_methods;
	} else {
	    Log::do_log(
		'err',
		'syntax error in scenario %s rule line %d expected : <condition> <auth_mod> -> <action>',
		$function,
		$.
	    );
	    Log::do_log('err', 'error parsing "%s"', $current_rule);
	    return undef;
	}

	## Duplicate the rule for each mentionned authentication method
	foreach my $auth_method (@auth_methods_list) {
	    push(
		@scenario,
		{   'condition'   => $rule->{condition},
		    'auth_method' => $auth_method,
		    'action'      => $rule->{action}
		}
	    );
	}
    }

    $structure->{'rules'} = \@scenario;

    return $structure;
}

=head2 Functions

=over 4

=item request_action ( THAT, OPERATION, AUTH_METHOD, CONTEXT, [ DEBUG ] )

I<Function>.
Return the action to perform for 1 sender
using 1 auth method to perform 1 operation

IN : -$that (+) : ref(List) | ref(Robot) | "Site"
     -$operation (+) : scalar
     -$auth_method (+) : 'smtp'|'md5'|'pgp'|'smime'|'dkim'
     -$context (+) : ref(HASH) containing information
       to evaluate scenario (scenario var)
     -$debug : adds keys in the returned HASH

OUT : undef | ref(HASH) containing keys :
       -action : 'do_it'|'reject'|'request_auth'
          |'owner'|'editor'|'editorkey'|'listmaster'
       -reason : defined if action == 'reject'
          and in scenario : reject(reason='...')
          key for template authorization_reject.tt2
       -tt2 : defined if action == 'reject'
          and in scenario : reject(tt2='...') or reject('...tt2')
          match a key in authorization_reject.tt2
       -condition : the checked condition
          (defined if $debug)
       -auth_method : the checked auth_method
          (defined if $debug)

=back

=cut

sub request_action {
    Log::do_log('debug2', '(%s, %s, %s, %s, %s)', @_);
    my $that        = shift;
    my $operation   = shift;
    my $auth_method = shift;
    my $context     = shift;
    my $debug       = shift;

    my $robot;
    my $list;
    if (ref $that and ref $that eq 'List') {
	$list  = $that;
	$robot = $that->robot;
    } else {
	$robot = Robot::clean_robot($that, 1);    #FIXME: really maybe Site?
    }

    my $trace_scenario;
    ## Defining default values for parameters.
    $context->{'sender'}      ||= 'nobody';
    $context->{'email'}       ||= $context->{'sender'};
    $context->{'remote_host'} ||= 'unknown_host';
    $context->{'robot_domain'} = $robot->domain;
    $context->{'robot_object'} = $robot;
    $context->{'msg'}          = $context->{'message'}->{'msg'}
	if (defined $context->{'message'});
    $context->{'msg_encrypted'} = 'smime'
	if (defined $context->{'message'} &&
	defined $context->{'message'}->{'smime_crypted'} &&
	$context->{'message'}->{'smime_crypted'} eq 'smime_crypted');
    ## Check that authorization method is one of those known by Sympa
    unless ($auth_method =~ /^(smtp|md5|pgp|smime|dkim)/) {
	&Log::do_log('info',
	    "fatal error : unknown auth method $auth_method in List::get_action"
	);
	return undef;
    }
    my (@rules, $name, $scenario);

    my $log_it
	; # this var is defined to control if log scenario is activated or not
    if (${$robot->loging_for_module || {}}{'scenario'}) {

	#activate log if no condition is defined
	unless (scalar keys %{$robot->loging_condition || {}}) {
	    $log_it = 1;
	} else {

	    #activate log if ip or email match
	    my $loging_conditions = $robot->loging_condition || {};
	    if ((   defined $loging_conditions->{'ip'} &&
		    $loging_conditions->{'ip'} =~ /$context->{'remote_addr'}/
		) ||
		(defined $loging_conditions->{'email'} &&
		    $loging_conditions->{'email'} =~ /$context->{'email'}/i)
		) {
		&Log::do_log(
		    'info',
		    'Will log scenario process for user with email: "%s", IP: "%s"',
		    $context->{'email'},
		    $context->{'remote_addr'}
		);
		$log_it = 1;
	    }
	}
    }
    if ($log_it) {
	if (ref $that and ref $that eq 'List') {
	    $trace_scenario =
		'scenario request ' . $operation . ' for list ' .
		($that->get_id) . ' :';
	    Log::do_log('info', 'Will evaluate scenario %s for list %s',
		$operation, $that);
	} elsif (ref $that and ref $that eq 'Robot') {
	    $trace_scenario =
		'scenario request ' . $operation . ' for robot ' .
		($that->get_id) . ' :';
	    Log::do_log('info', 'Will evaluate scenario %s for robot %s',
		$operation, $that);
	} else {
	    $trace_scenario =
		'scenario request ' . $operation . ' for site :';
	    Log::do_log('info', 'Will evaluate scenario %s for site',
		$operation);
	}
    }

    ## The current action relates to a list
    if ($list) {
	$context->{'list_object'} = $list;
	## The $operation refers to a list parameter of the same name
	## The list parameter might be structured ('.' is a separator)
	$scenario = $list->get_scenario($operation, $context->{'options'});

	## List parameter might not be defined (example : web_archive.access)
	unless ($scenario) {
	    my $return = {
		'action'      => 'reject',
		'reason'      => 'parameter-not-defined',
		'auth_method' => '',
		'condition'   => ''
	    };
	    if ($log_it) {
		&Log::do_log('info',
		    '%s rejected reason parameter not defined',
		    $trace_scenario);
	    }
	    return $return;
	}

	## Prepares custom_vars in $context
	if (scalar @{$list->custom_vars}) {
	    foreach my $var (@{$list->custom_vars}) {
		$context->{'custom_vars'}{$var->{'name'}} = $var->{'value'};
	    }
	}

	## pending/closed lists => send/visibility are closed
	unless ($list->status eq 'open') {
	    if ($operation =~ /^(send|visibility)$/) {
		my $return = {
		    'action'      => 'reject',
		    'reason'      => 'list-no-open',
		    'auth_method' => '',
		    'condition'   => ''
		};
		if ($log_it) {
		    &Log::do_log('info',
			"$trace_scenario rejected reason list not open");
		}
		return $return;
	    }
	}

	### the following lines are used by the document sharing action
	if (defined $context->{'scenario'}) {
	    my @operations = split /\./, $operation;

	    # loading of the structure
	    $scenario = Scenario->new(
		$list,
		'function' => $operations[$#operations],
		'name'     => $context->{'scenario'},
		'options'  => $context->{'options'}
	    );
	}

    } elsif ($context->{'topicname'}) {
	## Topics
	$scenario = Scenario->new(
	    $robot,
	    'function' => 'topics_visibility',
	    'name' => $robot->topics->{$context->{'topicname'}}{'visibility'},
	    'options' => $context->{'options'}
	);
    } else {
	## Global scenario (ie not related to a list) ; example : create_list
	my @p;
	if ((   @p =
		grep { $_->{'name'} and $_->{'name'} eq $operation }
		@confdef::params
	    ) and
	    $p[0]->{'scenario'}
	    ) {
	    $scenario = Scenario->new(
		$robot,
		'function' => $operation,
		'name'     => $robot->$operation,
		'options'  => $context->{'options'}
	    );
	}
    }

    unless (defined $scenario and defined $scenario->{'rules'}) {
	&Log::do_log('err', 'Failed to load scenario for "%s"', $operation);
	return undef;
    }

    push @rules, @{$scenario->{'rules'}};
    $name = $scenario->{'name'};

    unless ($name) {
	&Log::do_log('err',
	    "internal error : configuration for operation $operation is not yet performed by scenario"
	);
	return undef;
    }

    ## Include include.<action>.header if found
    my $include_scenario = Scenario->new(
	$that,
	'function' => 'include',
	'name'     => $operation . '.header',
	'options'  => $context->{'options'}
    );
    if (defined $include_scenario) {
	## Add rules at the beginning of the array
	unshift @rules, @{$include_scenario->{'rules'}};
    }
    ## Look for 'include' directives amongst rules first
    for (my $idx = 0; $idx < scalar @rules; $idx++) {
	if ($rules[$idx]->{'condition'} =~
	    /^\s*include\s*\(?\'?([\w\.]+)\'?\)?\s*$/i) {
	    my $include_file     = $1;
	    my $include_scenario = Scenario->new(
		$that,
		'function' => 'include',
		'name'     => $include_file,
		'options'  => $context->{'options'}
	    );
	    if (defined $include_scenario) {
		## Removes the include directive and replace it with
		## included rules
		##FIXME: possibie recursive include
		splice @rules, $idx, 1, @{$include_scenario->{'rules'}};
	    }
	}
    }

    ## Include a Blacklist rules if configured for this action
    if (Site->blacklist->{$operation}) {
	foreach my $auth ('smtp', 'dkim', 'md5', 'pgp', 'smime') {
	    my $blackrule = {
		'condition'   => "search('blacklist.txt',[sender])",
		'action'      => 'reject,quiet',
		'auth_method' => $auth
	    };
	    ## Add rules at the beginning of the array
	    unshift @rules, ($blackrule);
	}
    }

    my $return = {};
    foreach my $rule (@rules) {
	if ($log_it) {
	    &Log::do_log(
		'info', 'Verify rule %s, auth %s, action %s',
		$rule->{'condition'}, $rule->{'auth_method'},
		$rule->{'action'}
	    );
	}
	if ($auth_method eq $rule->{'auth_method'}) {
	    if ($log_it) {
		&Log::do_log(
		    'info',
		    'Context uses auth method %s',
		    $rule->{'auth_method'}
		);
	    }
	    my $result = &verify($context, $rule->{'condition'}, $log_it);

	    ## Cope with errors
	    if (!defined($result)) {
		&Log::do_log('info',
		    "error in $rule->{'condition'},$rule->{'auth_method'},$rule->{'action'}"
		);
		&Log::do_log(
		    'info',
		    'Error in %s scenario, in list %s',
		    $context->{'scenario'},
		    $context->{'listname'}
		);

		if ($debug) {
		    $return = {
			'action'      => 'reject',
			'reason'      => 'error-performing-condition',
			'auth_method' => $rule->{'auth_method'},
			'condition'   => $rule->{'condition'}
		    };
		    return $return;
		}
		$robot->send_notify_to_listmaster('error-performing-condition',
		    [$context->{'listname'} . "  " .  $rule->{'condition'}]
		);
		return undef;
	    }

	    ## Rule returned false
	    if ($result == -1) {
		if ($log_it) {
		    &Log::do_log('info',
			"$trace_scenario condition $rule->{'condition'} with authentication method $rule->{'auth_method'} not verified."
		    );
		}
		next;
	    }

	    my $action = $rule->{'action'};

	    ## reject : get parameters
	    if ($action =~ /^(ham|spam|unsure)/) {
		$action = $1;
	    }
	    if ($action =~ /^reject(\((.+)\))?(\s?,\s?(quiet))?/) {
		my ($p, $q) = ($2, $4);
		if ($q and $q eq 'quiet') {
		    $action = 'reject,quiet';
		} else {
		    $action = 'reject';
		}
		my @param = ();
		@param = split /,/, $p if $p;

		foreach my $p (@param) {
		    if ($p =~ /^reason=\'?(\w+)\'?/) {
			$return->{'reason'} = $1;
			next;

		    } elsif ($p =~ /^tt2=\'?(\w+)\'?/) {
			$return->{'tt2'} = $1;
			next;

		    }
		    if ($p =~ /^\'?[^=]+\'?/) {
			$return->{'tt2'} = $p;

			# keeping existing only, not merging with reject
			# parameters in scenarios
			last;
		    }
		}
	    }

	    $return->{'action'} = $action;

	    if ($log_it) {
		&Log::do_log('info',
		    "$trace_scenario condition $rule->{'condition'} with authentication method $rule->{'auth_method'} issued result : $action"
		);
	    }

	    if ($result == 1) {
		if ($log_it) {
		    &Log::do_log(
			'info', "rule '%s %s -> %s' accepted",
			$rule->{'condition'}, $rule->{'auth_method'},
			$rule->{'action'}
		    );
		}
		if ($debug) {
		    $return->{'auth_method'} = $rule->{'auth_method'};
		    $return->{'condition'}   = $rule->{'condition'};
		    return $return;
		}

		## Check syntax of returned action
		unless ($action =~
		    /^(do_it|reject|request_auth|owner|editor|editorkey|listmaster|ham|spam|unsure)/
		    ) {
		    &Log::do_log('err',
			"Matched unknown action '%s' in scenario",
			$rule->{'action'});
		    return undef;
		}
		return $return;
	    }
	} else {
	    if ($log_it) {
		&Log::do_log(
		    'info',
		    'Context does not use auth method %s',
		    $rule->{'auth_method'}
		);
	    }
	}
    }
    &Log::do_log('info', "no rule match, reject");

    if ($log_it) {
	&Log::do_log('info',
	    "$trace_scenario : no rule match request rejected");
    }

    $return = {
	'action'      => 'reject',
	'reason'      => 'no-rule-match',
	'auth_method' => 'default',
	'condition'   => 'default'
    };
    return $return;
}

=over 4

=item verify ( CONTEXT, CONDITION, LOG_IT )

I<Function>.
check if email respect some condition

=back

=cut

sub verify {
    Log::do_log('debug2', '(%s, %s, %s)', @_);
    my ($context, $condition, $log_it) = @_;

    my $robot;
    if ($context->{'list_object'}) {
	$robot = $context->{'list_object'}->robot;
    } elsif ($context->{'robot_object'}) {
	$robot = $context->{'robot_object'};
    } elsif ($context->{'robot_domain'}) {
	$robot = Robot::clean_robot($context->{'robot_domain'});
    }

    my $pinfo;
    if ($robot) {
	$pinfo = $robot->list_params;
    } else {
	$pinfo = {};
    }

    unless (defined($context->{'sender'})) {
	&Log::do_log('info',
	    "internal error, no sender find in List::verify, report authors");
	return undef;
    }

    $context->{'execution_date'} = time
	unless (defined($context->{'execution_date'}));

    my $list;
    if ($context->{'listname'} && !defined $context->{'list_object'}) {
	unless ($context->{'list_object'} =
	    new List($context->{'listname'}, $robot)) {
	    &Log::do_log(
		'err',
		'Unable to create List object for list %s',
		$context->{'listname'}
	    );
	    return undef;
	}
    }

    if (defined($context->{'list_object'})) {
	$list = $context->{'list_object'};
	$context->{'listname'} = $list->name;

	$context->{'host'} = $list->host;
    }

    if (defined($context->{'msg'})) {
	my $header = $context->{'msg'}->head;
	unless (
	    defined $context->{'listname'} &&
	    (   (   $header->get('to') &&
		    (   join(', ', $header->get('to')) =~
			/$context->{'listname'}/i)
		) ||
		(   $header->get('cc') &&
		    (   join(', ', $header->get('cc')) =~
			/$context->{'listname'}/i)
		)
	    )
	    ) {
	    $context->{'is_bcc'} = 1;
	} else {
	    $context->{'is_bcc'} = 0;
	}

    }
    unless ($condition =~
	/(\!)?\s*(true|is_listmaster|verify_netmask|is_editor|is_owner|is_subscriber|less_than|match|equal|message|older|newer|all|search|customcondition\:\:\w+)\s*\(\s*(.*)\s*\)\s*/i
	) {
	&Log::do_log('err',
	    "syntax error: unknown condition $condition");
	return undef;
    }
    my $negation = 1;
    if ($1 and $1 eq '!') {
	$negation = -1;
    }

    my $condition_key = lc($2);
    my $arguments     = $3;
    my @args;

    ## The expression for regexp is tricky because we don't allow the '/' character (that indicates the end of the regexp
    ## but we allow any number of \/ escape sequence)
    while (
	$arguments =~ s/^\s*(
				(\[\w+(\-\>[\w\-]+)?\](\[[-+]?\d+\])?)
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
				)\s*,?//x
	) {
	my $value = $1;

	## Custom vars
	if ($value =~ /\[custom_vars\-\>([\w\-]+)\]/i) {
	    $value =~
		s/\[custom_vars\-\>([\w\-]+)\]/$context->{'custom_vars'}{$1}/;
	}

	## Family vars
	if ($value =~ /\[family\-\>([\w\-]+)\]/i) {
	    $value =~ s/\[family\-\>([\w\-]+)\]/$context->{'family'}{$1}/;
	}

	## Config param
	elsif ($value =~ /\[conf\-\>([\w\-]+)\]/i) {
	    my $conf_key = $1;
	    my $conf_value;
	    if (scalar(
		    grep { $_->{'name'} and $_->{'name'} eq $conf_key }
			@confdef::params
		) and
		($conf_value = $robot->$conf_key)
		) {
		$value =~ s/\[conf\-\>([\w\-]+)\]/$conf_value/;
	    } else {
		&Log::do_log('debug',
		    'undefined variable context %s in rule %s',
		    $value, $condition);
		if ($log_it) {
		    &Log::do_log('info',
			'undefined variable context %s in rule %s',
			$value, $condition);
		}

	 # a condition related to a undefined context variable is always false
		return -1 * $negation;
	    }

	    ## List param
	} elsif ($value =~ /\[list\-\>([\w\-]+)\]/i) {
	    my $param = $1;

	    if ($param =~ /^(name|total)$/) {
		my $val = $list->$param;
		$value =~ s/\[list\-\>([\w\-]+)\]/$val/;
	    } elsif ($param eq 'address') {
		my $list_address = $list->get_list_address();
		$value =~ s/\[list\-\>([\w\-]+)\]/$list_address/;
	    } elsif (exists $pinfo->{$param} and !ref($list->$param)) {
		my $val = $list->$param;
		$value =~ s/\[list\-\>([\w\-]+)\]/$val/;
	    } else {
		&Log::do_log('err', 'Unknown list parameter %s in rule %s',
		    $value, $condition);
		if ($log_it) {
		    &Log::do_log('info',
			'Unknown list parameter %s in rule %s',
			$value, $condition);
		}
		return undef;
	    }

	} elsif ($value =~ /\[env\-\>([\w\-]+)\]/i) {

	    $value =~ s/\[env\-\>([\w\-]+)\]/$ENV{$1}/;

	    ## Sender's user/subscriber attributes (if subscriber)
	} elsif ($value =~ /\[user\-\>([\w\-]+)\]/i) {

	    $context->{'user'} ||=
		User::get_global_user($context->{'sender'});
	    $value =~ s/\[user\-\>([\w\-]+)\]/$context->{'user'}{$1}/;

	} elsif ($value =~ /\[user_attributes\-\>([\w\-]+)\]/i) {

	    $context->{'user'} ||=
		User::get_global_user($context->{'sender'});
	    $value =~
		s/\[user_attributes\-\>([\w\-]+)\]/$context->{'user'}{'attributes'}{$1}/;

	} elsif (($value =~ /\[subscriber\-\>([\w\-]+)\]/i) &&
	    defined($context->{'sender'} ne 'nobody')) {

	    $context->{'subscriber'} ||=
		$list->get_list_member($context->{'sender'});
	    $value =~
		s/\[subscriber\-\>([\w\-]+)\]/$context->{'subscriber'}{$1}/;

	} elsif ($value =~
	    /\[(msg_header|header)\-\>([\w\-]+)\](?:\[([-+]?\d+)\])?/i) {
	    ## SMTP header field.
	    ## "[msg_header->field] returns arrayref of field values,
	    ## preserving order. "[msg_header->field][index]" returns one
	    ## field value.
	    my $field_name = $2;
	    my $index = (defined $3) ? $3 + 0 : undef;
	    if (defined($context->{'msg'})) {
		my $headers = $context->{'msg'}->head->header();
		my @fields = grep { $_ } map {
		    my ($h, $v) = split /\s*:\s*/, $_, 2;
		    (lc $h eq lc $field_name) ? $v : undef;
		} @{$headers || []};
		## Defaulting empty or missing fields to '', so that we can
		## test their value in Scenario, considering that, for an
		## incoming message, a missing field is equivalent to an empty
		## field : the information it is supposed to contain isn't
		## available.
		if (defined $index) {
		    $value = $fields[$index];
		    unless (defined $value) {
			$value = '';
		    }
		} else {
		    unless (@fields) {
			@fields = ('');
		    }
		    $value = \@fields;
		}
	    } else {
		if ($log_it) {
		    &Log::do_log('info',
			'no message object found to evaluate rule %s',
			$condition);
		}
		return -1 * $negation;
	    }

	} elsif ($value =~ /\[msg_body\]/i) {
	    unless (defined($context->{'msg'}) &&
		defined($context->{'msg'}->effective_type() =~ /^text/) &&
		defined($context->{'msg'}->bodyhandle)) {
		if ($log_it) {
		    &Log::do_log(
			'info',
			'no proper textual message body to evaluate rule %s',
			$condition
		    );
		}
		return -1 * $negation;
	    }

	    $value = $context->{'msg'}->bodyhandle->as_string()();

	} elsif ($value =~ /\[msg_part\-\>body\]/i) {
	    unless (defined($context->{'msg'})) {
		if ($log_it) {
		    &Log::do_log('info', 'no message to evaluate rule %s',
			$condition);
		}
		return -1 * $negation;
	    }

	    my @bodies;
	    ## FIXME:Should be recurcive...
	    foreach my $part ($context->{'msg'}->parts) {
		next unless ($part->effective_type() =~ /^text/);
		next unless (defined $part->bodyhandle);

		push @bodies, $part->bodyhandle->as_string();
	    }
	    $value = \@bodies;

	} elsif ($value =~ /\[msg_part\-\>type\]/i) {
	    unless (defined($context->{'msg'})) {
		if ($log_it) {
		    &Log::do_log('info', 'no message to evaluate rule %s',
			$condition);
		}
		return -1 * $negation;
	    }

	    my @types;
	    foreach my $part ($context->{'msg'}->parts) {
		push @types, $part->effective_type();
	    }
	    $value = \@types;

	} elsif ($value =~ /\[current_date\]/i) {
	    my $time = time;
	    $value =~ s/\[current_date\]/$time/;

	    ## Quoted string
	} elsif ($value =~ /\[(\w+)\]/i) {

	    if (defined($context->{$1})) {
		$value =~ s/\[(\w+)\]/$context->{$1}/i;
	    } else {
		&Log::do_log('debug',
		    "undefined variable context $value in rule $condition");
		if ($log_it) {
		    &Log::do_log('info',
			"undefined variable context $value in rule $condition"
		    );
		}

	 # a condition related to a undefined context variable is always false
		return -1 * $negation;
	    }

	} elsif ($value =~ /^'(.*)'$/ || $value =~ /^"(.*)"$/) {
	    $value = $1;
	}
	push(@args, $value);

    }

    # Getting rid of spaces.
    $condition_key =~ s/^\s*//g;
    $condition_key =~ s/\s*$//g;

    # condition that require 0 argument
    if ($condition_key =~ /^(true|all)$/i) {
	unless ($#args == -1) {
	    &Log::do_log('err',
		"syntax error: incorrect number of argument or incorrect argument syntaxe $condition"
	    );
	    return undef;
	}

	# condition that require 1 argument
    } elsif ($condition_key =~ /^(is_listmaster|verify_netmask)$/) {
	unless ($#args == 0) {
	    &Log::do_log('err',
		"syntax error: incorrect argument number for condition $condition_key"
	    );
	    return undef;
	}

	# condition that require 1 or 2 args (search : historical reasons)
    } elsif ($condition_key =~ /^search$/o) {
	unless ($#args == 1 || $#args == 0) {
	    &Log::do_log('err',
		"syntax error: Incorrect argument number for condition $condition_key"
	    );
	    return undef;
	}

	# condition that require 2 args
    } elsif ($condition_key =~
	/^(is_owner|is_editor|is_subscriber|less_than|match|equal|message|newer|older)$/o
	) {
	unless ($#args == 1) {
	    &Log::do_log(
		'err',
		"syntax_error: incorrect argument number (%d instead of %d) for condition $condition_key",
		$#args + 1,
		2
	    );
	    return undef;
	}
    } elsif ($condition_key !~ /^customcondition::/o) {
	&Log::do_log('err',
	    "syntax error: unknown condition $condition_key");
	return undef;
    }

    ## Now eval the condition
    ##### condition : true
    if ($condition_key =~ /^(true|any|all)$/i) {
	if ($log_it) {
	    &Log::do_log('info', 'Condition %s is always true (rule %s)',
		$condition_key, $condition);
	}
	return $negation;
    }
    ##### condition is_listmaster
    if ($condition_key eq 'is_listmaster') {
	if (!ref $args[0] and $args[0] eq 'nobody') {
	    if ($log_it) {
		&Log::do_log('info',
		    '%s is not listmaster of robot %s (rule %s)',
		    $args[0], $robot, $condition);
	    }
	    return -1 * $negation;
	}

	my @arg;
	my $ok = undef;
	if (ref $args[0] eq 'ARRAY') {
	    @arg = map { $_->address }
	    grep { $_ } map { (Mail::Address->parse($_)) } @{$args[0]};
	} else {
	    @arg = map { $_->address }
	    grep { $_ } Mail::Address->parse($args[0]);
	}
	foreach my $arg (@arg) {
	    if ($robot->is_listmaster($arg)) {
		$ok = $arg;
		last;
	    }
	}
	if ($ok) {
	    if ($log_it) {
		&Log::do_log('info', '%s is listmaster of robot %s (rule %s)',
		    $ok, $robot, $condition);
	    }
	    return $negation;
	} else {
	    if ($log_it) {
		&Log::do_log('info',
		    '%s is not listmaster of robot %s (rule %s)',
		    $args[0], $robot, $condition);
	    }
	    return -1 * $negation;
	}
    }

    ##### condition verify_netmask
    if ($condition_key eq 'verify_netmask') {

	## Check that the IP address of the client is available
	## Means we are in a web context
	unless (defined $ENV{'REMOTE_ADDR'}) {
	    if ($log_it) {
		&Log::do_log('info',
		    'REMOTE_ADDR env variable not set (rule %s)', $condition);
	    }
	    return -1;   ## always skip this rule because we can't evaluate it
	}
	my $block;
	unless ($block = new2 Net::Netmask($args[0])) {
	    &Log::do_log('err',
		"syntax error: failed to parse netmask '$args[0]'");
	    return undef;
	}
	if ($block->match($ENV{'REMOTE_ADDR'})) {
	    if ($log_it) {
		&Log::do_log('info', 'REMOTE_ADDR %s matches %s (rule %s)',
		    $ENV{'REMOTE_ADDR'}, $args[0], $condition);
	    }
	    return $negation;
	} else {
	    if ($log_it) {
		&Log::do_log('info',
		    'REMOTE_ADDR %s does not match %s (rule %s)',
		    $ENV{'REMOTE_ADDR'}, $args[0], $condition);
	    }
	    return -1 * $negation;
	}
    }

    ##### condition older
    if ($condition_key =~ /^(older|newer)$/) {

	$negation *= -1 if ($condition_key eq 'newer');
	my $arg0 = &tools::epoch_conv($args[0]);
	my $arg1 = &tools::epoch_conv($args[1]);

	&Log::do_log('debug3', '%s(%d, %d)', $condition_key, $arg0, $arg1);
	if ($arg0 <= $arg1) {
	    if ($log_it) {
		&Log::do_log('info', '%s is smaller than %s (rule %s)',
		    $arg0, $arg1, $condition);
	    }
	    return $negation;
	} else {
	    if ($log_it) {
		&Log::do_log('info', '%s is NOT smaller than %s (rule %s)',
		    $arg0, $arg1, $condition);
	    }
	    return -1 * $negation;
	}
    }

    ##### condition is_owner, is_subscriber and is_editor
    if ($condition_key =~ /^(is_owner|is_subscriber|is_editor)$/i) {
	my ($list2);

	if ($args[1] eq 'nobody') {
	    if ($log_it) {
		&Log::do_log('info', "%s can't be used to evaluate (rule %s)",
		    $args[1], $condition);
	    }
	    return -1 * $negation;
	}

	## The list is local or in another local robot
	if ($args[0] =~ /\@/) {
	    $list2 = new List($args[0]);
	} else {
	    $list2 = new List($args[0], $robot);
	}

	if (!$list2) {
	    &Log::do_log('err', "unable to create list object \"$args[0]\"");
	    return -1 * $negation;
	}

	my @arg;
	my $ok = undef;
	if (ref $args[1] eq 'ARRAY') {
	    @arg = map { $_->address }
	    grep { $_ } map { (Mail::Address->parse($_)) } @{$args[1]};
	} else {
	    @arg = map { $_->address }
	    grep { $_ } Mail::Address->parse($args[1]);
	}

	if ($condition_key eq 'is_subscriber') {
	    foreach my $arg (@arg) {
		if ($list2->is_list_member($arg)) {
		    $ok = $arg;
		    last;
		}
	    }
	    if ($ok) {
		if ($log_it) {
		    &Log::do_log('info', "%s is member of list %s (rule %s)",
			$ok, $args[0], $condition);
		}
		return $negation;
	    } else {
		if ($log_it) {
		    &Log::do_log('info',
			"%s is NOT member of list %s (rule %s)",
			$args[1], $args[0], $condition);
		}
		return -1 * $negation;
	    }

	} elsif ($condition_key eq 'is_owner') {
	    foreach my $arg (@arg) {
		if ($list2->am_i('owner', $arg)) {
		    $ok = $arg;
		    last;
		}
	    }
	    if ($ok) {
		if ($log_it) {
		    &Log::do_log('info', "%s is owner of list %s (rule %s)",
			$ok, $args[0], $condition);
		}
		return $negation;
	    } else {
		if ($log_it) {
		    &Log::do_log('info',
			"%s is NOT owner of list %s (rule %s)",
			$args[1], $args[0], $condition);
		}
		return -1 * $negation;
	    }

	} elsif ($condition_key eq 'is_editor') {
	    foreach my $arg (@arg) {
		if ($list2->am_i('editor', $arg)) {
		    $ok = $arg;
		    last;
		}
	    }
	    if ($ok) {
		if ($log_it) {
		    &Log::do_log('info', "%s is editor of list %s (rule %s)",
			$ok, $args[0], $condition);
		}
		return $negation;
	    } else {
		if ($log_it) {
		    &Log::do_log('info',
			"%s is NOT editor of list %s (rule %s)",
			$args[1], $args[0], $condition);
		}
		return -1 * $negation;
	    }
	}
    }
    ##### match
    if ($condition_key eq 'match') {
	unless ($args[1] =~ /^\/(.*)\/$/) {
	    &Log::do_log('err', 'Match parameter %s is not a regexp',
		$args[1]);
	    return undef;
	}
	my $regexp = $1;

	# Nothing can match an empty regexp.
	if ($regexp =~ /^$/) {
	    if ($log_it) {
		&Log::do_log('info', "regexp '%s' is empty (rule %s)",
		    $regexp, $condition);
	    }
	    return -1 * $negation;
	}

	if ($regexp =~ /\[host\]/) {
	    my $reghost = $robot->host;
	    $reghost =~ s/\./\\./g;
	    $regexp  =~ s/\[host\]/$reghost/g;
	}

	# wrap matches with eval{} to avoid crash by malformed regexp.
	my $r = 0;
	if (ref($args[0])) {
	    eval {
		foreach my $arg (@{$args[0]}) {
		    if ($arg =~ /$regexp/i) {
			$r = 1;
			last;
		    }
		}
	    };
	} else {
	    eval {
		if ($args[0] =~ /$regexp/i) {
		    $r = 1;
		}
	    };
	}
	if ($@) {
	    &Log::do_log('err', 'cannot evaluate match: %s', $@);
	    return undef;
	}
	if ($r) {
	    if ($log_it) {
		my $args_as_string = '';
		if (ref($args[0])) {
		    foreach my $arg (@{$args[0]}) {
			$args_as_string .= "$arg, ";
		    }
		} else {
		    $args_as_string = $args[0];
		}
		&Log::do_log('info', "'%s' matches regexp '%s' (rule %s)",
		    $args_as_string, $regexp, $condition);
	    }
	    return $negation;
	} else {
	    if ($log_it) {
		my $args_as_string = '';
		if (ref($args[0])) {
		    foreach my $arg (@{$args[0]}) {
			$args_as_string .= "$arg, ";
		    }
		} else {
		    $args_as_string = $args[0];
		}
		&Log::do_log('info',
		    "'%s' does not match regexp '%s' (rule %s)",
		    $args_as_string, $regexp, $condition);
	    }
	    return -1 * $negation;
	}
    }

    ## search rule
    if ($condition_key eq 'search') {
	my $val_search;

	# we could search in the family if we got ref on Family object
	$val_search = search(($list || $robot), $args[0], $context);
	return undef unless defined $val_search;
	if ($val_search == 1) {
	    if ($log_it) {
		&Log::do_log('info', "'%s' found in '%s', robot %s (rule %s)",
		    $context->{'sender'}, $args[0], $robot, $condition);
	    }
	    return $negation;
	} else {
	    if ($log_it) {
		&Log::do_log('info',
		    "'%s' NOT found in '%s', robot %s (rule %s)",
		    $context->{'sender'}, $args[0], $robot, $condition);
	    }
	    return -1 * $negation;
	}
    }

    ## equal
    if ($condition_key eq 'equal') {
	if (ref($args[0])) {
	    foreach my $arg (@{$args[0]}) {
		&Log::do_log('debug3', 'ARG: %s', $arg);
		if (lc($arg) eq lc($args[1])) {
		    if ($log_it) {
			&Log::do_log('info', "'%s' equals '%s' (rule %s)",
			    lc($arg), lc($args[1]), $condition);
		    }
		    return $negation;
		}
	    }
	} else {
	    if (lc($args[0]) eq lc($args[1])) {
		if ($log_it) {
		    &Log::do_log('info', "'%s' equals '%s' (rule %s)",
			lc($args[0]), lc($args[1]), $condition);
		}
		return $negation;
	    }
	}
	if ($log_it) {
	    &Log::do_log('info', "'%s' does NOT equal '%s' (rule %s)",
		lc($args[0]), lc($args[1]), $condition);
	}
	return -1 * $negation;
    }

    ## custom perl module
    if ($condition_key =~ /^customcondition::(\w+)/o) {
	my $condition = $1;

	my $res = verify_custom(($list || $robot), $condition, \@args);
	unless (defined $res) {
	    if ($log_it) {
		my $args_as_string = '';
		foreach my $arg (@args) {
		    $args_as_string .= ", $arg";
		}
		&Log::do_log(
		    'info',
		    "custom condition '%s' returned an undef value with arguments '%s' (rule %s)",
		    $condition,
		    $args_as_string,
		    $condition
		);
	    }
	    return undef;
	}
	if ($log_it) {
	    my $args_as_string = '';
	    foreach my $arg (@args) {
		$args_as_string .= ", $arg";
	    }
	    if ($res == 1) {
		&Log::do_log('info',
		    "'%s' verifies custom condition '%s' (rule %s)",
		    $args_as_string, $condition, $condition);
	    } else {
		&Log::do_log('info',
		    "'%s' does not verify custom condition '%s' (rule %s)",
		    $args_as_string, $condition, $condition);
	    }
	}
	return $res * $negation;
    }

    ## less_than
    if ($condition_key eq 'less_than') {
	if (ref($args[0])) {
	    foreach my $arg (@{$args[0]}) {
		&Log::do_log('debug3', 'ARG: %s', $arg);
		if (&tools::smart_lessthan($arg, $args[1])) {
		    if ($log_it) {
			&Log::do_log('info',
			    "'%s' is less than '%s' (rule %s)",
			    $arg, $args[1], $condition);
		    }
		    return $negation;
		}
	    }
	} else {
	    if (&tools::smart_lessthan($args[0], $args[1])) {
		if ($log_it) {
		    &Log::do_log('info', "'%s' is less than '%s' (rule %s)",
			$args[0], $args[1], $condition);
		}
		return $negation;
	    }
	}

	if ($log_it) {
	    &Log::do_log('info', "'%s' is NOT less than '%s' (rule %s)",
		$args[0], $args[1], $condition);
	}
	return -1 * $negation;
    }
    return undef;
}

=over 4

=item search ( THAT, FILTER_FILE, CONTEXT )

I<Function>.
Verify if a given user is part of an LDAP, SQL or TXT search filter

=back

=cut

sub search {
    my $that        = shift || 'Site';
    my $filter_file = shift;
    my $context     = shift;

    unless (ref $that and ref $that eq 'List') {
	$that = Robot::clean_robot($that, 1);    #FIXME: really may be Site?
    }

    my $sender = $context->{'sender'};

    Log::do_log('debug2', '(%s, %s, sender=%s)', $that, $filter_file,
	$sender);

    if ($filter_file =~ /\.sql$/) {

	my $file = $that->get_etc_filename("search_filters/$filter_file");

	my $timeout = 3600;
	my ($sql_conf, $tsth);
	my $time = time;

	unless ($sql_conf = &Conf::load_sql_filter($file)) {
	    $that->send_notify_to_owner('named_filter',
		{'filter' => $filter_file})
		if ref $that eq 'List';
	    return undef;
	}

	my $statement = $sql_conf->{'sql_named_filter_query'}->{'statement'};
	my $filter    = $statement;
	my @statement_args;    ## Useful to later quote parameters

	## Minimalist variable parser ; only parse [x] or [x->y]
	## should be extended with the code from verify()
	while ($filter =~ /\[(\w+(\-\>[\w\-]+)?)\]/x) {
	    my ($full_var) = ($1);
	    my ($var, $key) = split /\-\>/, $full_var;

	    unless (defined $context->{$var}) {
		&Log::do_log('err',
		    "Failed to parse variable '%s' in filter '%s'",
		    $var, $file);
		return undef;
	    }

	    if (defined $key) {    ## Should be a hash
		unless (defined $context->{$var}{$key}) {
		    &Log::do_log('err',
			"Failed to parse variable '%s.%s' in filter '%s'",
			$var, $key, $file);
		    return undef;
		}

		$filter    =~ s/\[$full_var\]/$context->{$var}{$key}/;
		$statement =~ s/\[$full_var\]/\%s/;
		push @statement_args, $context->{$var}{$key};
	    } else {               ## Scalar
		$filter    =~ s/\[$full_var\]/$context->{$var}/;
		$statement =~ s/\[$full_var\]/\%s/;
		push @statement_args, $context->{$var};

	    }
	}

	#        $statement =~ s/\[sender\]/%s/g;
	#        $filter =~ s/\[sender\]/$sender/g;

	if (defined($persistent_cache{'named_filter'}{$filter_file}{$filter})
	    &&
	    (   time <=
		$persistent_cache{'named_filter'}{$filter_file}{$filter}
		{'update'} + $timeout)
	    ) {    ## Cache has 1hour lifetime
	    &Log::do_log('notice', 'Using previous SQL named filter cache');
	    return $persistent_cache{'named_filter'}{$filter_file}{$filter}
		{'value'};
	}

	my $ds = new SQLSource($sql_conf->{'sql_named_filter_query'});
	unless (defined $ds && $ds->connect() && $ds->ping) {
	    &Log::do_log(
		'notice',
		'Unable to connect to the SQL server %s:%d',
		$sql_conf->{'db_host'},
		$sql_conf->{'db_port'}
	    );
	    return undef;
	}

	## Quote parameters
	foreach (@statement_args) {
	    $_ = $ds->quote($_);
	}

	$statement = sprintf $statement, @statement_args;
	unless ($ds->query($statement)) {
	    &Log::do_log('debug', '%s named filter cancelled', $file);
	    return undef;
	}

	my $res = $ds->fetch;
	$ds->disconnect();
	my $first_row = ref($res->[0]) ? $res->[0]->[0] : $res->[0];
	Log::do_log('debug2', 'Result of SQL query : %d = %s',
	    $first_row, $statement);

	if ($first_row == 0) {
	    $persistent_cache{'named_filter'}{$filter_file}{$filter}{'value'}
		= 0;
	} else {
	    $persistent_cache{'named_filter'}{$filter_file}{$filter}{'value'}
		= 1;
	}
	$persistent_cache{'named_filter'}{$filter_file}{$filter}{'update'} =
	    time;
	return
	    $persistent_cache{'named_filter'}{$filter_file}{$filter}{'value'};
    } elsif ($filter_file =~ /\.ldap$/) {
	## Determine full path of the filter file
	my $file = $that->get_etc_filename("search_filters/$filter_file");

	unless ($file) {
	    &Log::do_log('err', 'Could not find search filter %s',
		$filter_file);
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
		&Log::do_log('err',
		    "Failed to parse variable '%s' in filter '%s'",
		    $var, $file);
		return undef;
	    }

	    if (defined $key) {    ## Should be a hash
		unless (defined $context->{$var}{$key}) {
		    &Log::do_log('err',
			"Failed to parse variable '%s.%s' in filter '%s'",
			$var, $key, $file);
		    return undef;
		}

		$filter =~ s/\[$full_var\]/$context->{$var}{$key}/;
	    } else {               ## Scalar
		$filter =~ s/\[$full_var\]/$context->{$var}/;

	    }
	}

	#	$filter =~ s/\[sender\]/$sender/g;

	if (defined($persistent_cache{'named_filter'}{$filter_file}{$filter})
	    &&
	    (   time <=
		$persistent_cache{'named_filter'}{$filter_file}{$filter}
		{'update'} + $timeout)
	    ) {    ## Cache has 1hour lifetime
	    &Log::do_log('notice', 'Using previous LDAP named filter cache');
	    return $persistent_cache{'named_filter'}{$filter_file}{$filter}
		{'value'};
	}

	my $ldap;
	my $param = &tools::dup_var(\%ldap_conf);
	my $ds    = new LDAPSource($param);

	unless (defined $ds && ($ldap = $ds->connect())) {
	    &Log::do_log('err', "Unable to connect to the LDAP server '%s'",
		$param->{'ldap_host'});
	    return undef;
	}

	## The 1.1 OID correponds to DNs ; it prevents the LDAP server from
	## preparing/providing too much data
	my $mesg = $ldap->search(
	    base   => "$ldap_conf{'suffix'}",
	    filter => "$filter",
	    scope  => "$ldap_conf{'scope'}",
	    attrs  => ['1.1']
	);
	unless ($mesg) {
	    &Log::do_log('err', "Unable to perform LDAP search");
	    return undef;
	}
	unless ($mesg->code == 0) {
	    &Log::do_log('err', 'Ldap search failed');
	    return undef;
	}

	if ($mesg->count() == 0) {
	    $persistent_cache{'named_filter'}{$filter_file}{$filter}
		{'value'} = 0;

	} else {
	    $persistent_cache{'named_filter'}{$filter_file}{$filter}
		{'value'} = 1;
	}

	$ds->disconnect() or
	    &Log::do_log('notice', 'List::search_ldap.Unbind impossible');
	$persistent_cache{'named_filter'}{$filter_file}{$filter}{'update'} =
	    time;

	return $persistent_cache{'named_filter'}{$filter_file}{$filter}
	    {'value'};

    } elsif ($filter_file =~ /\.txt$/) {

	# &Log::do_log('info', 'List::search: eval %s', $filter_file);
	my @files =
	    $that->get_etc_filename("search_filters/$filter_file",
	    {'order' => 'all'});

	## Raise an error except for blacklist.txt
	unless (@files) {
	    if ($filter_file eq 'blacklist.txt') {
		return -1;
	    } else {
		&Log::do_log('err', 'Could not find search filter %s',
		    $filter_file);
		return undef;
	    }
	}

	my $sender = lc($sender);
	foreach my $file (@files) {
	    &Log::do_log('debug3', 'List::search: found file  %s', $file);
	    unless (open FILE, $file) {
		&Log::do_log('err', 'Could not open file %s', $file);
		return undef;
	    }
	    while (<FILE>) {

		# &Log::do_log('debug3', 'List::search: eval rule %s', $_);
		next if (/^\s*$/o || /^[\#\;]/o);
		my $regexp = $_;
		chomp $regexp;
		$regexp =~ s/\*/.*/;
		$regexp = '^' . $regexp . '$';

 # &Log::do_log('debug3', 'List::search: eval  %s =~ /%s/i', $sender,$regexp);
		return 1 if ($sender =~ /$regexp/i);
	    }
	}
	return -1;
    } else {
	&Log::do_log('err', "Unknown filter file type %s", $filter_file);
	return undef;
    }
}

# eval a custom perl module to verify a scenario condition
sub verify_custom {
    my $that      = shift || 'Site';
    my $condition = shift;
    my $args_ref  = shift;

    my $robot;
    if (ref $that and ref $that eq 'List') {
	$robot = $that->robot;
    } else {
	$that = Robot::clean_robot($that, 1);    #FIXME: really may be Site?
	$robot = $that;
    }

    my $timeout = 3600;

    my $filter = join('*', @{$args_ref});
    Log::do_log('debug2', '(%s, %s, filter=%s)', $that, $condition, $filter);

    if (defined($persistent_cache{'named_filter'}{$condition}{$filter}) &&
	(   time <=
	    $persistent_cache{'named_filter'}{$condition}{$filter}{'update'} +
	    $timeout)
	) {    ## Cache has 1hour lifetime
	&Log::do_log('notice', 'Using previous custom condition cache %s',
	    $filter);
	return $persistent_cache{'named_filter'}{$condition}{$filter}
	    {'value'};
    }

    # use this if you want per list customization (be sure you know what
    # you are doing)
    #my $file = $that->get_etc_filename("custom_conditions/${condition}.pm");
    my $file = $robot->get_etc_filename("custom_conditions/${condition}.pm");
    unless ($file) {
	&Log::do_log('err', 'No module found for %s custom condition',
	    $condition);
	return undef;
    }
    &Log::do_log('notice', 'Use module %s for custom condition', $file);
    eval { require "$file"; };
    if ($@) {
	&Log::do_log('err', 'Error requiring %s : %s (%s)',
	    $condition, "$@", ref($@));
	return undef;
    }
    my $res;
    eval "\$res = CustomCondition::${condition}::verify(\@{\$args_ref});";
    if ($@) {
	&Log::do_log('err', 'Error evaluating %s : %s (%s)',
	    $condition, "$@", ref($@));
	return undef;
    }

    return undef unless defined $res;

    $persistent_cache{'named_filter'}{$condition}{$filter}{'value'} =
	($res == 1 ? 1 : 0);
    $persistent_cache{'named_filter'}{$condition}{$filter}{'update'} = time;
    return $persistent_cache{'named_filter'}{$condition}{$filter}{'value'};
}

=head2 Miscelaneous

=cut

sub dump_all_scenarios {
    open TMP, ">/tmp/all_scenarios";
    &tools::dump_var(\%all_scenarios, 0, \*TMP);
    close TMP;
}

=over 4

=item get_current_title ()

Get internationalized title of the scenario, under current language context.

=back

=cut

## Get the title in the current language
sub get_current_title {
    my $self = shift;

    foreach my $lang (Language::ImplicatedLangs()) {
	if (defined $self->{'title'}{$lang}) {
	    return $self->{'title'}{$lang};
	}
    }
    if (defined $self->{'title'}{'gettext'}) {
	return Language::gettext($self->{'title'}{'gettext'});
    } elsif (defined $self->{'title'}{'us'}) {
	return Language::gettext($self->{'title'}{'us'});
    } else {
	return $self->{'name'};
    }
}

=over 4

=item get_id ()

Get unique ID of object.

=back

=cut

## Get unique ID
sub get_id {
    return shift->{'file_path'} || '';
}

=over 4

=item is_purely_closed ()

Returns 1 if all conditions in scenario are "true()   [an_auth_method]    ->  reject"

=back

=cut

sub is_purely_closed {
    my $self = shift;
    foreach my $rule (@{$self->{'rules'}}) {
	if ($rule->{'condition'} ne 'true' &&
	    $rule->{'action'} !~ /reject/) {
	    Log::do_log('debug2', 'Scenario %s is not purely closed.',
		$self->{'title'});
	    return 0;
	}
    }
    Log::do_log('notice', 'Scenario %s is purely closed.',
	$self->{'file_path'});
    return 1;
}

1;
