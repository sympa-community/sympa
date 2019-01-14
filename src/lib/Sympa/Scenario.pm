# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
# Copyright 2017, 2018 The Sympa Community. See the AUTHORS.md file at the
# top-level directory of this distribution and at
# <https://github.com/sympa-community/sympa.git>.
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

package Sympa::Scenario;

use strict;
use warnings;
use English qw(-no_match_vars);
use Mail::Address;
use Net::CIDR;

use Sympa;
use Conf;
use Sympa::ConfDef;
use Sympa::Constants;
use Sympa::Database;
use Sympa::Language;
use Sympa::List;
use Sympa::Log;
use Sympa::Robot;
use Sympa::Tools::Data;
use Sympa::Tools::File;
use Sympa::Tools::Time;
use Sympa::User;

my $log = Sympa::Log->instance;

our %all_scenarios;
my %persistent_cache;

my $picache         = {};
my $picache_refresh = 10;

#FIXME: should be taken from Sympa::ListDef.
my %list_ppath_maps = (
    visibility          => 'visibility',
    send                => 'send',
    info                => 'info',
    subscribe           => 'subscribe',
    add                 => 'add',
    unsubscribe         => 'unsubscribe',
    del                 => 'del',
    invite              => 'invite',
    remind              => 'remind',
    review              => 'review',
    d_read              => 'shared_doc.d_read',
    d_edit              => 'shared_doc.d_edit',
    archive_web_access  => 'archive.web_access',
    archive_mail_access => 'archive.mail_access',
    tracking            => 'tracking.tracking',
);

#FIXME: should be taken from Sympa::ConfDef.
my %domain_ppath_maps = (
    create_list             => 'create_list',
    global_remind           => 'global_remind',
    move_user               => 'move_user',
    automatic_list_creation => 'automatic_list_creation',
    spam_status             => 'spam_status',
);

# For compatibility to obsoleted use of parameter name instead of function.
my %compat_function_maps = (
    'shared_doc.d_read'   => 'd_read',
    'shared_doc.d_edit'   => 'd_edit',
    'archive.access'      => 'archive_mail_access',    # obsoleted
    'web_archive.access'  => 'archive_web_access',     # obsoleted
    'mail_access'         => 'archive_mail_access',    # mislead
    'web_access'          => 'archive_web_access',     # mislead
    'archive.mail_access' => 'archive_mail_access',
    'archive.web_access'  => 'archive_web_access',
    'tracking.tracking'   => 'tracking',
);

## Creates a new object
## Supported parameters : function, robot, name, directory, file_path, options
## Output object has the following entries : name, file_path, rules, date,
## title, struct, data
sub new {
    $log->syslog('debug2', '(%s, %s, %s, ...)', @_);
    my $class    = shift;
    my $that     = shift || $Conf::Conf{'domain'};    # List or domain
    my $function = shift;
    my %options  = @_;

    # Compatibility for obsoleted use of parameter names.
    $function = $compat_function_maps{$function} || $function;
    die 'bug in logic. Ask developer'
        unless defined $function and $function =~ /\A[-.\w]+\z/;

    # Determine parameter to get the name of scenario.
    # 'include' and 'topics_visibility' functions are special: They don't
    # have corresponding list/domain parameters.
    my $ppath =
        (ref $that eq 'Sympa::List')
        ? $list_ppath_maps{$function}
        : $domain_ppath_maps{$function};
    unless ($function eq 'include'
        or (ref $that ne 'Sympa::List' and $function eq 'topics_visibility')
        or $ppath) {
        $log->syslog('err', 'Unknown scenario function "%s"', $function);
        return undef;
    }

    my $name;
    if ($options{name}) {
        $name = $options{name};
    } elsif ($function eq 'include') {
        # {name} option is mandatory.
        die 'bug in logic. Ask developer';
    } elsif (ref $that eq 'Sympa::List') {
        #FIXME: Use Sympa::List::Config.
        if ($ppath =~ /[.]/) {
            my ($pname, $key) = split /[.]/, $ppath, 2;
            $name = ($that->{'admin'}{$pname}{$key} || {})->{name}
                if $that->{'admin'}{$pname};
        } else {
            $name = ($that->{'admin'}{$ppath} || {})->{name};
        }
    } elsif ($function eq 'topics_visibility') {
        # {name} option is mandatory.
        die 'bug in logic. Ask developer';
    } else {
        $name = Conf::get_robot_conf($that, $ppath);
    }
    unless (defined $name and $name =~ /\A[-\w]+\z/) {
        $log->syslog('err', 'Unknown or undefined scenario function "%s"',
            $function);
        return undef;
    }

    my $data;
    my $file_path = Sympa::search_fullpath(
        $that,
        $function . '.' . $name,
        subdir => 'scenari'
    );
    if ($file_path) {
        # Load the scenario if previously loaded in memory.
        if ($all_scenarios{$file_path}
            and ($options{dont_reload_scenario}
                or Sympa::Tools::File::get_mtime($file_path) <=
                $all_scenarios{$file_path}->{date})
        ) {
            return bless {
                context   => $that,
                function  => $function,
                name      => $name,
                file_path => $file_path,
                _scenario => $all_scenarios{$file_path}
            } => $class;
        }

        # Get the data from file.
        if (open my $ifh, '<', $file_path) {
            $data = do { local $RS; <$ifh> };
            close $ifh;
        } else {
            $log->syslog('err', 'Failed to open scenario file "%s": %m',
                $file_path);
            return undef;
        }
    } elsif ($function eq 'include') {
        # include.xx not found will not raise an error message.
        return undef;
    } else {
        if ($all_scenarios{"ERROR/$function.$name"}) {
            return bless {
                context   => $that,
                function  => $function,
                name      => $name,
                file_path => 'ERROR',
                _scenario => $all_scenarios{"ERROR/$function.$name"}
            } => $class;
        }

        $log->syslog('err', 'Unable to find scenario file "%s.%s"',
            $function, $name);
        # Default rule is rejecting always.
        $data = 'true() smtp -> reject';
    }

    my $parsed = _parse_scenario($data, $file_path);

    # Keep the scenario in memory.
    $all_scenarios{$file_path || "ERROR/$function.$name"} = $parsed;

    return bless {
        context   => $that,
        function  => $function,
        name      => $name,
        file_path => ($file_path || 'ERROR'),
        _scenario => $parsed,
    } => $class;
}

# Parse scenario rules.  On failure, returns hash with empty rules.
sub _parse_scenario {
    $log->syslog('debug3', '(%s, %s)', @_);
    my $data      = shift;
    my $file_path = shift;

    my (%title, @rules);
    my @lines = split /\r\n|\r|\n/, $data;
    my $lineno = 0;
    foreach my $line (@lines) {
        $lineno++;

        next if $line =~ /^\s*\w+\s*$/;    # skip paragraph name
        $line =~ s/\#.*$//;                # remove comments
        next if $line =~ /^\s*$/;          # skip empty lines

        if ($line =~ /^\s*title\.gettext\s+(.*)\s*$/i) {
            $title{gettext} = $1;
            next;
        } elsif ($line =~ /^\s*title\.(\S+)\s+(.*)\s*$/i) {
            my ($lang, $title) = ($1, $2);
            # canonicalize lang if possible.
            $lang = Sympa::Language::canonic_lang($lang) || $lang;
            $title{$lang} = $title;
            next;
        } elsif ($line =~ /^\s*title\s+(.*)\s*$/i) {
            $title{default} = $1;
            next;
        }

        if ($line =~ /\s*(include\s*\(?\'?(.*)\'?\)?)\s*$/i) {
            push @rules, {condition => $1, lineno => $lineno};
        } elsif ($line =~
            /^\s*(.*?)\s+((\s*(md5|pgp|smtp|smime|dkim)\s*,?)*)\s*->\s*(.*)\s*$/gi
        ) {
            my ($condition, $auth_methods, $action) = ($1, $2 || 'smtp', $5);
            $auth_methods =~ s/\s//g;

            # Duplicate the rule for each mentionned authentication method
            foreach my $auth_method (split /,/, $auth_methods) {
                push @rules,
                    {
                    condition   => $condition,
                    auth_method => $auth_method,
                    action      => $action,
                    lineno      => $lineno,
                    };
            }
        } else {
            $log->syslog(
                'err',
                'Error parsing %s line %s: "%s"',
                $file_path || '(file)',
                $lineno, $line
            );
            @rules = ();
            last;
        }
    }

    my $purely_closed =
        not
        grep { not($_->{condition} eq 'true' and $_->{action} =~ /reject/) }
        @rules;

    return {
        data          => $data,
        title         => {%title},
        rules         => [@rules],
        purely_closed => $purely_closed,
        # Keep track of the current time ; used later to reload scenario files
        # when they changed on disk
        date => ($file_path ? time : 0),
    };
    #XXX$scenario->{'context'} = $robot_id;
    #XXX$scenario->{'struct'} = $scenario_struct;
}

sub to_string {
    shift->{_scenario}{data};
}

sub request_action {
    my $that        = shift;
    my $function    = shift;
    my $auth_method = shift;
    my $context     = shift;
    my %options     = @_;

    my $self = Sympa::Scenario->new($that, $function, %options);
    unless ($self) {
        $log->syslog('err', 'Failed to load scenario for "%s"', $function);
        return undef;
    }

    return $self->authz($auth_method, $context, %options);
}

# Old name: Sympa::Scenario::request_action().
sub authz {
    $log->syslog('debug2', '(%s, %s, %s, ...)', @_);
    my $self        = shift;
    my $auth_method = shift;
    my $context     = shift;
    my %options     = @_;

    my $that     = $self->{context};
    my $function = $self->{function};

    # Pending/closed lists => send/visibility are closed.
    if (    ref $that eq 'Sympa::List'
        and not($that->{'admin'}{'status'} eq 'open')
        and grep { $function eq $_ } qw(send visibility)) {
        $log->syslog('debug3', '%s rejected reason list not open', $function);
        return {
            action      => 'reject',
            reason      => 'list-no-open',
            auth_method => '',
            condition   => '',
        };
    }

    # Check that authorization method is one of those known by Sympa.
    unless ($auth_method =~ /^(smtp|md5|pgp|smime|dkim)/) {
        $log->syslog('info', 'Unknown auth method %s', $auth_method);
        return {
            action      => 'reject',
            reason      => 'unknown-auth-method',
            auth_method => $auth_method,
            condition   => '',
        };
    }

    # Defining default values for parameters.
    $context->{'sender'}      ||= 'nobody';
    $context->{'email'}       ||= $context->{'sender'};
    $context->{'remote_host'} ||= 'unknown_host';
    $context->{'msg_encrypted'} = 'smime'
        if defined $context->{'message'}
        and $context->{'message'}->{'smime_crypted'};

    if (ref $that eq 'Sympa::List') {
        foreach my $var (@{$that->{'admin'}{'custom_vars'} || []}) {
            $context->{'custom_vars'}{$var->{'name'}} = $var->{'value'};
        }
    }

    my @rules;
    push @rules, @{$self->{_scenario}{rules}};

    # Include include.<function>.header if found.
    my $include_scenario =
        Sympa::Scenario->new($that, 'include', name => $function . '.header');
    if ($include_scenario) {
        # Add rules at the beginning.
        unshift @rules, @{$include_scenario->{_scenario}{rules}};
    }
    # Look for 'include' directives amongst rules first.
    foreach my $index (0 .. $#rules) {
        if ($rules[$index]{'condition'} =~
            /^\s*include\s*\(?\'?([\w\.]+)\'?\)?\s*$/i) {
            my $include_file = $1;
            my $include_scenario =
                Sympa::Scenario->new($that, 'include', name => $include_file);
            if ($include_scenario) {
                # Replace the include directive with included rules.
                splice @rules, $index, 1,
                    @{$include_scenario->{_scenario}{rules}};
            }
        }
    }

    ## Include a Blacklist rules if configured for this action
    if ($Conf::Conf{'blacklist'}{$function}) {
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

    foreach my $rule (@rules) {
        $log->syslog(
            'debug3', 'Verify rule %s, auth %s, action %s',
            $rule->{'condition'}, $rule->{'auth_method'},
            $rule->{'action'}
        );
        next unless $auth_method eq $rule->{'auth_method'};

        my $result = _verify($that, $rule, $context);

        # Cope with errors.
        unless (defined $result) {
            unless ($options{debug}) {
                $log->syslog('info', 'Error in scenario %s, list %s',
                    $self, $that);
                # FIXME: Add entry to listmaster_notification.tt2
                Sympa::send_notify_to_listmaster($that,
                    'error_performing_condition',
                    [$context->{'listname'} . "  " . $rule->{'condition'}]);
            }
            return {
                action      => 'reject',
                reason      => 'error-performing-condition',
                auth_method => $rule->{'auth_method'},
                condition   => $rule->{'condition'}
            };
        }

        # Rule returned false.
        if ($result == -1) {
            $log->syslog(
                'debug3',
                '%s condition %s with authentication method %s not verified',
                $self,
                $rule->{'condition'},
                $rule->{'auth_method'}
            );
            next;
        }
        # Not happen
        next unless $result == 1;

        $log->syslog(
            'debug3', 'Rule "%s %s -> %s" accepted',
            $rule->{'condition'}, $rule->{'auth_method'},
            $rule->{'action'}
        );

        my %action = _parse_action($rule->{action});
        # Check syntax of returned action
        if (   $options{debug}
            or $action{action} =~
            /^(do_it|reject|request_auth|owner|editor|editorkey|listmaster|ham|spam|unsure)/
        ) {
            return {
                %action,
                auth_method => $rule->{auth_method},
                condition   => $rule->{condition},
            };
        } else {
            $log->syslog('err', 'Matched unknown action "%s" in scenario',
                $rule->{'action'});
            return {
                action      => 'reject',
                reason      => 'unknown-action',
                auth_method => $rule->{auth_method},
                condition   => $rule->{condition},
            };
        }
    }

    $log->syslog('info', '%s: No rule match, reject', $self);
    return {
        action      => 'reject',
        reason      => 'no-rule-match',
        auth_method => 'default',
        condition   => 'default'
    };
}

sub _parse_action {
    my $action = shift;

    my %action;

    ## reject : get parameters
    if ($action =~ /^(ham|spam|unsure)/) {
        $action = $1;
    }
    if ($action =~ /^reject(\((.+)\))?(\s?,\s?(quiet))?/) {
        if ($4) {
            $action = 'reject,quiet';
        } else {
            $action = 'reject';
        }
        my @param = split /,/, $2 if defined $2;

        foreach my $p (@param) {
            if ($p =~ /^reason=\'?(\w+)\'?/) {
                $action{reason} = $1;
                next;

            } elsif ($p =~ /^tt2=\'?(\w+)\'?/) {
                $action{tt2} = $1;
                next;

            }
            if ($p =~ /^\'?[^=]+\'?/) {
                $action{tt2} = $p;
                # keeping existing only, not merging with reject
                # parameters in scenarios
                last;
            }
        }
    }

    return (%action, action => $action);
}

## check if email respect some condition
# Old name: Sympa::Scenario::verify().
sub _verify {
    $log->syslog('debug2', '(%s, %s, %s)', @_);
    my $that    = shift;
    my $rule    = shift;
    my $context = shift;

    my $condition = $rule->{condition};

    my $robot;
    my $pinfo;
    if (ref $that eq 'Sympa::List') {
        $robot = $that->{'domain'};
        $pinfo = {};
    } else {
        $robot = $that;

        # Generating the lists index creates multiple calls to _verify()
        # per list, and each call triggers a copy of the pinfo hash.
        # Profiling shows that this scales poorly with thousands of lists.
        # Briefly cache the list params data to avoid this overhead.
        if (time > ($picache->{$robot}{'expires'} || 0)) {
            $log->syslog('debug', 'robot %s pinfo cache refresh', $robot);
            $picache->{$robot}{'pinfo'}   = Sympa::Robot::list_params($robot);
            $picache->{$robot}{'expires'} = (time + $picache_refresh);
        }
        $pinfo = $picache->{$robot}{'pinfo'};
    }

    unless (defined($context->{'sender'})) {
        $log->syslog('info',
            'Internal error, no sender find.  Report authors');
        return undef;
    }

    $context->{'execution_date'} = time
        unless (defined($context->{'execution_date'}));

    #FIXME: Is this block needed?
    if ($context->{listname} and not(ref $that eq 'Sympa::List')) {
        unless ($that = Sympa::List->new($context->{listname}, $that)) {
            $log->syslog('info', 'Unable to create List object for list %s',
                $context->{listname});
            return undef;
        }
    }

    if (ref $that eq 'Sympa::List') {
        my $list = $that;

        $context->{listname} = $list->{'name'};
        $context->{domain}   = $list->{'domain'};
        # Compat.<6.2.32
        $context->{host} = $list->{'domain'};

        if ($context->{message}) {
            #FIXME: need more accurate test.
            $context->{is_bcc} = (
                0 <= index(
                    lc join(', ',
                        $context->{message}->get_header('To'),
                        $context->{message}->get_header('Cc')),
                    lc $list->{'name'}
                )
            ) ? 0 : 1;
        }
    } else {
        $context->{domain} = Conf::get_robot_conf($that || '*', 'domain');
    }

    unless ($condition =~
        /(\!)?\s*(true|is_listmaster|verify_netmask|is_editor|is_owner|is_subscriber|less_than|match|equal|message|older|newer|all|search|customcondition\:\:\w+)\s*\(\s*(.*)\s*\)\s*/i
    ) {
        $log->syslog('err', 'Error rule syntaxe: unknown condition %s',
            $condition);
        return undef;
    }
    my $negation = 1;
    if ($1 and $1 eq '!') {
        $negation = -1;
    }

    my $condition_key = lc($2);
    my $arguments     = $3;
    my @args;

    ## The expression for regexp is tricky because we don't allow the '/'
    ## character (that indicates the end of the regexp
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

            # Compat. < 6.2.32
            $conf_key = 'domain' if $conf_key and $conf_key eq 'host';

            if (scalar(
                    grep { $_->{'name'} and $_->{'name'} eq $conf_key }
                        @Sympa::ConfDef::params
                )
                and $conf_value = Conf::get_robot_conf($robot, $conf_key)
            ) {
                $value =~ s/\[conf\-\>([\w\-]+)\]/$conf_value/;
            } else {
                # a condition related to a undefined context variable is
                # always false
                return -1 * $negation;
            }
        }
        ## List param
        elsif ($value =~ /\[list\-\>([\w\-]+)\]/i) {
            my $param = $1;
            my $list  = $that;

            unless (ref $that eq 'Sympa::List') {
                $log->syslog('err', 'Unknown list in rule %s', $condition);
                return undef;
            } elsif ($param eq 'name') {
                my $val = $list->{'name'};
                $value =~ s/\[list\-\>name\]/$val/;
            } elsif ($param eq 'total') {
                my $val = $list->get_total;
                $value =~ s/\[list\-\>total\]/$val/;
            } elsif ($param eq 'address') {
                my $val = Sympa::get_address($list);
                $value =~ s/\[list\-\>$param\]/$val/;
            } else {
                my $canon_param = $param;
                if (exists $pinfo->{$param}) {
                    my $alias = $pinfo->{$param}{'obsolete'};
                    if ($alias and exists $pinfo->{$alias}) {
                        $canon_param = $alias;
                    }
                }
                if (exists $pinfo->{$canon_param}
                    and !ref($list->{'admin'}{$canon_param})) {
                    my $val = $list->{'admin'}{$canon_param};
                    $val = '' unless defined $val;
                    $value =~ s/\[list\-\>$param\]/$val/;
                } else {
                    $log->syslog('err',
                        'Unknown list parameter %s in rule %s',
                        $value, $condition);
                    return undef;
                }
            }
        } elsif ($value =~ /\[env\-\>([\w\-]+)\]/i) {
            my $env = $ENV{$1};
            $env = '' unless defined $env;
            $value =~ s/\[env\-\>([\w\-]+)\]/$env/;
        } elsif ($value =~ /\[user\-\>([\w\-]+)\]/i) {
            # Sender's user/subscriber attributes (if subscriber)

            $context->{'user'} ||=
                Sympa::User::get_global_user($context->{'sender'});
            $value =~ s/\[user\-\>([\w\-]+)\]/$context->{'user'}{$1}/;

        } elsif ($value =~ /\[user_attributes\-\>([\w\-]+)\]/i) {

            $context->{'user'} ||=
                Sympa::User::get_global_user($context->{'sender'});
            $value =~
                s/\[user_attributes\-\>([\w\-]+)\]/$context->{'user'}{'attributes'}{$1}/;

        } elsif ($value =~ /\[subscriber\-\>([\w\-]+)\]/i
            and defined $context->{sender}
            and $context->{sender} ne 'nobody') {
            my $list = $that;

            $context->{'subscriber'} ||=
                $list->get_list_member($context->{'sender'});
            $value =~
                s/\[subscriber\-\>([\w\-]+)\]/$context->{'subscriber'}{$1}/;

        } elsif ($value =~
            /\[(msg_header|header)\-\>([\w\-]+)\](?:\[([-+]?\d+)\])?/i) {
            ## SMTP header field.
            ## "[msg_header->field]" returns arrayref of field values,
            ## preserving order. "[msg_header->field][index]" returns one
            ## field value.
            my $field_name = $2;
            my $index = (defined $3) ? $3 + 0 : undef;
            if ($context->{'message'}) {
                my @fields = $context->{'message'}->get_header($field_name);
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
                return -1 * $negation;
            }

        } elsif ($value =~ /\[msg_body\]/i) {
            unless (
                $context->{'message'}
                and Sympa::Tools::Data::smart_eq(
                    $context->{'message'}->as_entity->effective_type,
                    qr/^text/)
                and defined($context->{'message'}->as_entity->bodyhandle)
            ) {
                return -1 * $negation;
            }

            $value = $context->{'message'}->body_as_string;

        } elsif ($value =~ /\[msg_part\-\>body\]/i) {
            unless ($context->{'message'}) {
                return -1 * $negation;
            }

            my @bodies;
            ## FIXME:Should be recurcive...
            foreach my $part ($context->{'message'}->as_entity->parts) {
                next unless $part->effective_type =~ /^text/;
                next unless defined $part->bodyhandle;

                push @bodies, $part->bodyhandle->as_string();
            }
            $value = \@bodies;
        } elsif ($value =~ /\[msg_part\-\>type\]/i) {
            unless ($context->{'message'}) {
                return -1 * $negation;
            }

            my @types;
            foreach my $part ($context->{'message'}->as_entity->parts) {
                push @types, $part->effective_type();
            }
            $value = \@types;

        } elsif ($value =~ /\[msg\-\>(\w+)\]/i) {
            return -1 * $negation unless $context->{'message'};
            my $message_field = $1;
            return -1 * $negation
                unless (defined($context->{'message'}{$message_field}));
            $value = $context->{'message'}{$message_field};

        } elsif ($value =~ /\[current_date\]/i) {
            my $time = time;
            $value =~ s/\[current_date\]/$time/;

            ## Quoted string
        } elsif ($value =~ /\[(\w+)\]/i) {

            if (defined($context->{$1})) {
                $value =~ s/\[(\w+)\]/$context->{$1}/i;
            } else {
                # a condition related to a undefined context variable is
                # always false
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
            $log->syslog(
                'err',
                'error rule syntaxe : incorrect number of argument or incorrect argument syntaxe %s',
                $condition
            );
            return undef;
        }
        # condition that require 1 argument
    } elsif ($condition_key =~ /^(is_listmaster|verify_netmask)$/) {
        unless ($#args == 0) {
            $log->syslog(
                'err',
                'error rule syntaxe : incorrect argument number for condition %s',
                $condition_key
            );
            return undef;
        }
        # condition that require 1 or 2 args (search : historical reasons)
    } elsif ($condition_key =~ /^search$/o) {
        unless ($#args == 1 || $#args == 0) {
            $log->syslog(
                'err',
                'error rule syntaxe : Incorrect argument number for condition %s',
                $condition_key
            );
            return undef;
        }
        # condition that require 2 args
    } elsif ($condition_key =~
        /^(is_owner|is_editor|is_subscriber|less_than|match|equal|message|newer|older)$/o
    ) {
        unless ($#args == 1) {
            $log->syslog(
                'err',
                'Incorrect argument number (%d instead of %d) for condition %s',
                $#args + 1,
                2,
                $condition_key
            );
            return undef;
        }
    } elsif ($condition_key !~ /^customcondition::/o) {
        $log->syslog('err', 'Error rule syntaxe: unknown condition %s',
            $condition_key);
        return undef;
    }

    ## Now eval the condition
    ##### condition : true
    if ($condition_key =~ /^(true|any|all)$/i) {
        return $negation;
    }
    ##### condition is_listmaster
    if ($condition_key eq 'is_listmaster') {
        if (!ref $args[0] and $args[0] eq 'nobody') {
            return -1 * $negation;
        }

        my @arg;
        my $ok = undef;
        if (ref $args[0] eq 'ARRAY') {
            @arg = map { $_->address }
                grep {$_} map { (Mail::Address->parse($_)) } @{$args[0]};
        } else {
            @arg = map { $_->address }
                grep {$_} Mail::Address->parse($args[0]);
        }
        foreach my $arg (@arg) {
            if (Sympa::is_listmaster($robot, $arg)) {
                $ok = $arg;
                last;
            }
        }
        if ($ok) {
            return $negation;
        } else {
            return -1 * $negation;
        }
    }

    ##### condition verify_netmask
    if ($condition_key eq 'verify_netmask') {
        ## Check that the IP address of the client is available
        ## Means we are in a web context
        unless (defined $ENV{'REMOTE_ADDR'}) {
            # always skip this rule because we can't evaluate it.
            return -1;
        }

        my @cidr;
        if ($args[0] eq 'default' or $args[0] eq 'any') {
            # Compatibility with Net::Netmask, adding IPv6 feature.
            @cidr = ('0.0.0.0/0', '::/0');
        } else {
            if ($args[0] =~ /\A(\d+\.\d+\.\d+\.\d+):(\d+\.\d+\.\d+\.\d+)\z/) {
                # Compatibility with Net::Netmask.
                eval { @cidr = Net::CIDR::range2cidr("$1/$2"); };
            } else {
                eval { @cidr = Net::CIDR::range2cidr($args[0]); };
            }
            if ($@ or scalar(@cidr) != 1) {
                # Compatibility with Net::Netmask: Should be single range.
                @cidr = ();
            } else {
                @cidr = grep { Net::CIDR::cidrvalidate($_) } @cidr;
            }
        }
        unless (@cidr) {
            $log->syslog('err',
                'Error rule syntax: failed to parse netmask "%s"',
                $args[0]);
            return undef;
        }

        $log->syslog('debug3', 'REMOTE_ADDR %s against %s (rule %s)',
            $ENV{'REMOTE_ADDR'}, $args[0], $condition);
        if (Net::CIDR::cidrlookup($ENV{'REMOTE_ADDR'}, @cidr)) {
            return $negation;
        } else {
            return -1 * $negation;
        }
    }

    ##### condition older
    if ($condition_key =~ /^(older|newer)$/) {

        $negation *= -1 if ($condition_key eq 'newer');
        my $arg0 = Sympa::Tools::Time::epoch_conv($args[0]);
        my $arg1 = Sympa::Tools::Time::epoch_conv($args[1]);

        $log->syslog('debug3', '%s(%d, %d)', $condition_key, $arg0, $arg1);
        if ($arg0 <= $arg1) {
            return $negation;
        } else {
            return -1 * $negation;
        }
    }

    ##### condition is_owner, is_subscriber and is_editor
    if ($condition_key =~ /^(is_owner|is_subscriber|is_editor)$/i) {
        my $list2;

        if ($args[1] eq 'nobody') {
            return -1 * $negation;
        }

        ## The list is local or in another local robot
        if ($args[0] =~ /\@/) {
            $list2 = Sympa::List->new($args[0]);
        } else {
            $list2 = Sympa::List->new($args[0], $robot);
        }

        if (!$list2) {
            $log->syslog('err', 'Unable to create list object "%s"',
                $args[0]);
            return -1 * $negation;
        }

        my @arg;
        my $ok = undef;
        if (ref $args[1] eq 'ARRAY') {
            @arg = map { $_->address }
                grep {$_} map { (Mail::Address->parse($_)) } @{$args[1]};
        } else {
            @arg = map { $_->address }
                grep {$_} Mail::Address->parse($args[1]);
        }

        if ($condition_key eq 'is_subscriber') {
            foreach my $arg (@arg) {
                if ($list2->is_list_member($arg)) {
                    $ok = $arg;
                    last;
                }
            }
            if ($ok) {
                return $negation;
            } else {
                return -1 * $negation;
            }

        } elsif ($condition_key eq 'is_owner') {
            foreach my $arg (@arg) {
                if ($list2->is_admin('owner', $arg)
                    or Sympa::is_listmaster($list2, $arg)) {
                    $ok = $arg;
                    last;
                }
            }
            if ($ok) {
                return $negation;
            } else {
                return -1 * $negation;
            }

        } elsif ($condition_key eq 'is_editor') {
            foreach my $arg (@arg) {
                if ($list2->is_admin('actual_editor', $arg)) {
                    $ok = $arg;
                    last;
                }
            }
            if ($ok) {
                return $negation;
            } else {
                return -1 * $negation;
            }
        }
    }
    ##### match
    if ($condition_key eq 'match') {
        unless ($args[1] =~ /^\/(.*)\/$/) {
            $log->syslog('err', 'Match parameter %s is not a regexp',
                $args[1]);
            return undef;
        }
        my $regexp = $1;

        # Nothing can match an empty regexp.
        if ($regexp =~ /^$/) {
            return -1 * $negation;
        }

        my $reghost = Conf::get_robot_conf($robot, 'domain');
        $reghost =~ s/\./\\./g;
        # "[host]" as alias of "[domain]": Compat. < 6.2.32
        $regexp =~ s/[[](?:domain|host)[]]/$reghost/g;

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
        if ($EVAL_ERROR) {
            $log->syslog('err', 'Cannot evaluate match: %s', $EVAL_ERROR);
            return undef;
        }
        if ($r) {
            return $negation;
        } else {
            return -1 * $negation;
        }
    }

    ## search rule
    if ($condition_key eq 'search') {
        my $val_search;
        # we could search in the family if we got ref on Sympa::Family object
        $val_search = _search($that, $args[0], $context);
        return undef unless defined $val_search;
        if ($val_search == 1) {
            return $negation;
        } else {
            return -1 * $negation;
        }
    }

    ## equal
    if ($condition_key eq 'equal') {
        if (ref($args[0])) {
            foreach my $arg (@{$args[0]}) {
                $log->syslog('debug3', 'Arg: %s', $arg);
                if (lc($arg) eq lc($args[1])) {
                    return $negation;
                }
            }
        } else {
            if (lc($args[0]) eq lc($args[1])) {
                return $negation;
            }
        }
        return -1 * $negation;
    }

    ## custom perl module
    if ($condition_key =~ /^customcondition::(\w+)/i) {
        my $res = _verify_custom($robot, $rule, $1, \@args);
        unless (defined $res) {
            return undef;
        }
        return $res * $negation;
    }

    ## less_than
    if ($condition_key eq 'less_than') {
        if (ref($args[0])) {
            foreach my $arg (@{$args[0]}) {
                $log->syslog('debug3', 'Arg: %s', $arg);
                if (Sympa::Tools::Data::smart_lessthan($arg, $args[1])) {
                    return $negation;
                }
            }
        } else {
            if (Sympa::Tools::Data::smart_lessthan($args[0], $args[1])) {
                return $negation;
            }
        }

        return -1 * $negation;
    }
    return undef;
}

## Verify if a given user is part of an LDAP, SQL or TXT search filter
# Old name: Sympa::Scenario::search().
sub _search {
    $log->syslog('debug2', '(%s, %s, %s)', @_);
    my $that        = shift;    # List or Robot
    my $filter_file = shift;
    my $context     = shift;

    my $sender = $context->{'sender'};

    if ($filter_file =~ /\.sql$/) {

        my $file = Sympa::search_fullpath($that, $filter_file,
            subdir => 'search_filters');

        my $timeout = 3600;
        my $sql_conf;
        my $time = time;

        unless ($sql_conf = Conf::load_sql_filter($file)) {
            $that->send_notify_to_owner('bad_named_filter',
                {'filter' => $filter_file})
                if ref $that eq 'Sympa::List';
            return undef;
        }

        my $statement = $sql_conf->{'sql_named_filter_query'}->{'statement'};
        my $filter    = $statement;
        my @statement_args;    ## Useful to later quote parameters

        ## Minimalist variable parser ; only parse [x] or [x->y]
        ## should be extended with the code from _verify()
        while ($filter =~ /\[(\w+(\-\>[\w\-]+)?)\]/x) {
            my ($full_var) = ($1);
            my ($var, $key) = split /\-\>/, $full_var;

            unless (defined $context->{$var}) {
                $log->syslog('err',
                    'Failed to parse variable "%s" in filter "%s"',
                    $var, $file);
                return undef;
            }

            if (defined $key) {    ## Should be a hash
                unless (defined $context->{$var}{$key}) {
                    $log->syslog('err',
                        'Failed to parse variable "%s.%s" in filter "%s"',
                        $var, $key, $file);
                    return undef;
                }

                $filter =~ s/\[$full_var\]/$context->{$var}{$key}/;
                $statement =~ s/\[$full_var\]/?/;
                push @statement_args, $context->{$var}{$key};
            } else {               ## Scalar
                $filter =~ s/\[$full_var\]/$context->{$var}/;
                $statement =~ s/\[$full_var\]/?/;
                push @statement_args, $context->{$var};

            }
        }

        # $statement =~ s/\[sender\]/?/g;
        # $filter =~ s/\[sender\]/$sender/g;

        if (defined($persistent_cache{'named_filter'}{$filter_file}{$filter})
            && (time <=
                $persistent_cache{'named_filter'}{$filter_file}{$filter}
                {'update'} + $timeout)
            ) {    ## Cache has 1hour lifetime
            $log->syslog('notice', 'Using previous SQL named filter cache');
            return $persistent_cache{'named_filter'}{$filter_file}{$filter}
                {'value'};
        }

        my $db = Sympa::Database->new(
            $sql_conf->{'sql_named_filter_query'}->{db_type},
            %{$sql_conf->{'sql_named_filter_query'}}
        );
        unless ($db and $db->connect()) {
            $log->syslog('notice',
                'Unable to connect to the SQL server %s', $db);
            return undef;
        }

        my $sth;
        unless ($sth = $db->do_prepared_query($statement, @statement_args)) {
            $log->syslog('debug', '%s named filter cancelled', $file);
            return undef;
        }

        my $res = $sth->fetchall_arrayref;    #FIXME: Check timeout.
        $db->disconnect();
        my $first_row = ref($res->[0]) ? $res->[0]->[0] : $res->[0];
        $log->syslog('debug2', 'Result of SQL query: %d = %s',
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
        return $persistent_cache{'named_filter'}{$filter_file}{$filter}
            {'value'};

    } elsif ($filter_file =~ /\.ldap$/) {
        ## Determine full path of the filter file
        my $file = Sympa::search_fullpath($that, $filter_file,
            subdir => 'search_filters');

        unless ($file) {
            $log->syslog('err', 'Could not find search filter %s',
                $filter_file);
            return undef;
        }
        my $timeout   = 3600;
        my %ldap_conf = _load_ldap_configuration($file);

        return undef unless %ldap_conf;

        my $filter = $ldap_conf{'filter'};

        ## Minimalist variable parser ; only parse [x] or [x->y]
        ## should be extended with the code from _verify()
        while ($filter =~ /\[(\w+(\-\>[\w\-]+)?)\]/x) {
            my ($full_var) = ($1);
            my ($var, $key) = split /\-\>/, $full_var;

            unless (defined $context->{$var}) {
                $log->syslog('err',
                    'Failed to parse variable "%s" in filter "%s"',
                    $var, $file);
                return undef;
            }

            if (defined $key) {    ## Should be a hash
                unless (defined $context->{$var}{$key}) {
                    $log->syslog('err',
                        'Failed to parse variable "%s.%s" in filter "%s"',
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
            && (time <=
                $persistent_cache{'named_filter'}{$filter_file}{$filter}
                {'update'} + $timeout)
            ) {                    ## Cache has 1hour lifetime
            $log->syslog('notice', 'Using previous LDAP named filter cache');
            return $persistent_cache{'named_filter'}{$filter_file}{$filter}
                {'value'};
        }

        my $db = Sympa::Database->new('LDAP', %ldap_conf);
        unless ($db and $db->connect) {
            $log->syslog('err', 'Unable to connect to the LDAP server "%s"',
                $ldap_conf{'host'});
            return undef;
        }

        ## The 1.1 OID correponds to DNs ; it prevents the LDAP server from
        ## preparing/providing too much data
        my $mesg = $db->do_operation(
            'search',
            base   => "$ldap_conf{'suffix'}",
            filter => "$filter",
            scope  => "$ldap_conf{'scope'}",
            attrs  => ['1.1']
        );
        unless ($mesg) {
            $log->syslog('err', "Unable to perform LDAP search");
            return undef;
        }

        if ($mesg->count() == 0) {
            $persistent_cache{'named_filter'}{$filter_file}{$filter}{'value'}
                = 0;

        } else {
            $persistent_cache{'named_filter'}{$filter_file}{$filter}{'value'}
                = 1;
        }

        $db->disconnect()
            or $log->syslog('notice', 'Unbind impossible');
        $persistent_cache{'named_filter'}{$filter_file}{$filter}{'update'} =
            time;

        return $persistent_cache{'named_filter'}{$filter_file}{$filter}
            {'value'};

    } elsif ($filter_file =~ /\.txt$/) {
        # $log->syslog('info', 'Eval %s', $filter_file);
        my @files = Sympa::search_fullpath(
            $that, $filter_file,
            subdir  => 'search_filters',
            'order' => 'all'
        );

        ## Raise an error except for blacklist.txt
        unless (@files) {
            if ($filter_file eq 'blacklist.txt') {
                return -1;
            } else {
                $log->syslog('err', 'Could not find search filter %s',
                    $filter_file);
                return undef;
            }
        }

        my $sender = lc($sender);
        foreach my $file (@files) {
            $log->syslog('debug3', 'Found file %s', $file);
            my $ifh;
            unless (open $ifh, '<', $file) {
                $log->syslog('err', 'Could not open file %s', $file);
                return undef;
            }
            while (my $pattern = <$ifh>) {
                next if $pattern =~ /\A\s*\z/ or $pattern =~ /\A[#;]/;
                chomp $pattern;
                $pattern =~ s/([^\w\x80-\xFF])/\\$1/g;
                $pattern =~ s/\\\*/.*/;
                if ($sender =~ /^$pattern$/i) {
                    close $ifh;
                    return 1;
                }
            }
            close $ifh;
        }
        return -1;
    } else {
        $log->syslog('err', "Unknown filter file type %s", $filter_file);
        return undef;
    }
}

# eval a custom perl module to verify a scenario condition
sub _verify_custom {
    $log->syslog('debug3', '(%s, %s, %s, %s)', @_);
    my $robot     = shift;
    my $rule      = shift;
    my $condition = shift;
    my $args_ref  = shift;

    my $timeout = 3600;

    my $filter = join('*', @{$args_ref});
    if (defined($persistent_cache{'named_filter'}{$condition}{$filter})
        && (time <=
            $persistent_cache{'named_filter'}{$condition}{$filter}{'update'}
            + $timeout)
        ) {    ## Cache has 1hour lifetime
        $log->syslog('notice', 'Using previous custom condition cache %s',
            $filter);
        return $persistent_cache{'named_filter'}{$condition}{$filter}
            {'value'};
    }

    # use this if your want per list customization (be sure you know what you
    # are doing)
    #my $file = Sympa::search_fullpath(
    #    $that,
    #    $condition . '.pm',
    #    subdir => 'custom_conditions'
    #);
    my $file = Sympa::search_fullpath(
        $robot,
        $condition . '.pm',
        subdir => 'custom_conditions'
    );
    unless ($file) {
        $log->syslog('err', 'No module found for %s custom condition',
            $condition);
        return undef;
    }
    $log->syslog('notice', 'Use module %s for custom condition', $file);
    eval { require "$file"; };
    if ($EVAL_ERROR) {
        $log->syslog('err', 'Error requiring %s: %s (%s)',
            $condition, "$EVAL_ERROR", ref $EVAL_ERROR);
        return undef;
    }
    my $res = do {
        local $_ = $rule;
        eval "CustomCondition::${condition}::verify(\@{\$args_ref})";
    };
    if ($EVAL_ERROR) {
        $log->syslog('err', 'Error evaluating %s: %s (%s)',
            $condition, "$EVAL_ERROR", ref $EVAL_ERROR);
        return undef;
    }

    return undef unless defined $res;

    $persistent_cache{'named_filter'}{$condition}{$filter}{'value'} =
        ($res == 1 ? 1 : 0);
    $persistent_cache{'named_filter'}{$condition}{$filter}{'update'} = time;
    return $persistent_cache{'named_filter'}{$condition}{$filter}{'value'};
}

# NEVER USED.
sub dump_all_scenarios {
    open my $ofh, '>', '/tmp/all_scenarios';
    Sympa::Tools::Data::dump_var(\%all_scenarios, 0, $ofh);
    close $ofh;
}

sub get_current_title {
    my $self = shift;

    my $hash     = $self->{_scenario};
    my $language = Sympa::Language->instance;

    foreach my $lang (Sympa::Language::implicated_langs($language->get_lang))
    {
        if (exists $hash->{title}{$lang}) {
            return $hash->{title}{$lang};
        }
    }
    if (exists $hash->{title}{gettext}) {
        return $language->gettext($hash->{title}{gettext});
    } elsif (exists $hash->{title}{default}) {
        return $hash->{title}{default};
    } else {
        return $self->{name};
    }
}

sub is_purely_closed {
    shift->{_scenario}{purely_closed};
}

## Loads and parses the configuration file. Reports errors if any.
sub _load_ldap_configuration {
    $log->syslog('debug3', '(%s)', @_);
    my $config = shift;

    my $line_num   = 0;
    my $config_err = 0;
    my ($i, %o);

    ## Open the configuration file or return and read the lines.
    my $ifh;
    unless (open $ifh, '<', $config) {
        $log->syslog('err', 'Unable to open %s: %m', $config);
        return;
    }

    my @valid_options = qw(host suffix filter scope bind_dn bind_password
        use_tls ssl_version ssl_ciphers ssl_cert ssl_key
        ca_verify ca_path ca_file);
    my @required_options = qw(host suffix filter);

    my %valid_options    = map { $_ => 1 } @valid_options;
    my %required_options = map { $_ => 1 } @required_options;

    my %Default_Conf = (
        'host'          => undef,
        'suffix'        => undef,
        'filter'        => undef,
        'scope'         => 'sub',
        'bind_dn'       => undef,
        'bind_password' => undef
    );

    my %Ldap = ();

    my $folded_line;
    while (my $current_line = <$ifh>) {
        $line_num++;
        next if ($current_line =~ /^\s*$/o || $current_line =~ /^[\#\;]/o);

        ## Cope with folded line (ending with '\')
        if ($current_line =~ /\\\s*$/) {
            $current_line =~ s/\\\s*$//;    ## remove trailing \
            chomp $current_line;
            $folded_line .= $current_line;
            next;
        } elsif (defined $folded_line) {
            $current_line = $folded_line . $current_line;
            $folded_line  = undef;
        }

        if ($current_line =~ /^(\S+)\s+(.+)$/io) {
            my ($keyword, $value) = ($1, $2);
            $value =~ s/\s*$//;

            $o{$keyword} = [$value, $line_num];
        } else {
            #printf STDERR Msg(1, 3, "Malformed line %d: %s"), $config, $_;
            $config_err++;
        }
    }
    close $ifh;

    ## Check if we have unknown values.
    foreach $i (sort keys %o) {
        $Ldap{$i} = $o{$i}[0] || $Default_Conf{$i};

        unless ($valid_options{$i}) {
            $log->syslog('err', 'Line %d, unknown field: %s', $o{$i}[1], $i);
            $config_err++;
        }
    }
    ## Do we have all required values ?
    foreach $i (keys %required_options) {
        unless (defined $o{$i} or defined $Default_Conf{$i}) {
            $log->syslog('err', 'Required field not found: %s', $i);
            $config_err++;
            next;
        }
    }
    return %Ldap;
}

# Loads all scenari for an function
# Old name: Sympa::List::load_scenario_list() which returns hashref.
sub get_scenarios {
    $log->syslog('debug3', '(%s, %s)', @_);
    my $that     = shift;
    my $function = shift;

    my @scenarios;

    my %seen;
    my %skipped;
    my @paths = @{Sympa::get_search_path($that, subdir => 'scenari')};
    #XXXunshift @list_of_scenario_dir, $that->{'dir'} . '/scenari';

    my $scenario_re = Sympa::Regexps::scenario();
    foreach my $dir (@paths) {
        next unless -d $dir;

        while (<$dir/$function.*:ignore>) {
            if (/$function\.($scenario_re):ignore$/) {
                my $name = $1;
                $skipped{$name} = 1;
            }
        }

        while (<$dir/$function.*>) {
            next unless /$function\.($scenario_re)$/;
            my $name = $1;

            # Ignore default setting on <= 6.2.40, using symbolic link.
            next if $name eq 'default' and -l "$dir/$function.$name";

            next if $seen{$name};
            next if $skipped{$name};

            my $scenario =
                Sympa::Scenario->new($that, $function, name => $name);
            $seen{$name} = 1;
            push @scenarios, $scenario;
        }
    }

    return [@scenarios];
}

sub get_id {
    my $self = shift;
    sprintf '%s.%s;%s', @{$self}{qw(function name file_path)};
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Scenario - Authorization scenarios

=head1 SYNOPSIS

  use Sympa::Scenario;
  
  my $scenario = Sympa::Scenario->new($list, 'send', name => 'private');
  my $result = $scenario->authz('md5', {sender => $sender});

=head1 DESCRIPTION

L<Sympa::Scenario> provides feature of scenarios which perform authorization
on functions of Sympa software against users and clients.

=head2 Methods

=over

=item new ( $that, $function, [ name =E<gt> $name ],
[ dont_reload_scenario =E<gt> 1 ] )

I<Constructor>.
Creates a new L<Sympa::Scenario> instance.

Parameters:

=over

=item $that

Context of scenario, list or domain
(note that scenario does not have site context).

=item $function

Specifies scenario function.

=item name =E<gt> $name

Specifies scenario name.
If the name was not given, it is taken from list/domain configuration.
See L</"Scenarios"> for details.

=item dont_reload_scenario =E<gt> 1

If set, won't check if scenario files were updated.

=back

Returns:

A new L<Sympa::Scenario> instance.

=item authz ( $auth_method, \%context,  [ debug =E<gt> 1] )

I<Instance method>.
Return the action to perform for 1 sender
using 1 auth method to perform 1 function.

Parameters:

=over

=item $auth_method

'smtp', 'md5', 'pgp', 'smime' or 'dkim'.
Note that `pgp` has not been implemented.

=item \%context

A hashref containing information to evaluate scenario (scenario context).

=item debug =E<gt> 1

Adds keys in the returned hashref.

=back

Returns:

A hashref containing following items.

=over

=item {action}

'do_it', 'reject', 'request_auth',
'owner', 'editor', 'editorkey' or 'listmaster'.

=item {reason}

Defined if {action} is 'reject' and in case C<reject(reason='...')>:
Key for template authorization_reject.tt2.

=item {tt2}

Defined if {action} is 'reject' and in case C<reject(tt2='...')> or
C<reject('...tt2')>:
Mail template name to be sent back to request sender.

=item {condition}

The checked condition (defined if debug is set).

=item {auth_method}

The checked auth_method (defined if debug is set).

=back

=item get_current_title ( )

I<Instance method>.
Gets the title of the scenarioin the current language context.

=item is_purely_closed ( )

I<Instance method>.
Returns true value if the scenario obviously returns "reject" action.

=item to_string ( )

I<Instance method>.
Returns source text of the scenario.

=back

=head2 Functions

=over

=item get_scenarios ( $that, $function )

I<Function>.
Gets all scenarios beloging to context $that and function $function.

=item request_action ( $that, $function, $auth_method, \%context,
[ name =E<gt> $name ], [ dont_reload_scenario =E<gt> 1 ], [ debug =E<gt> 1] )

I<Function>. Obsoleted on Sympa 6.2.42. Use authz() method instead.

=back

=head2 Attributes

Instance of L<Sympa::Scenario> has these attributes:

=over

=item {context}

Context given by new().

=item {function}

Name of function.

=item {name}

Scenario name.

=item {file_path}

Full path of scenario file.

=back

=head2 Scenarios

A scenario file is named as I<C<function>>C<.>I<C<name>>,
where I<C<function>> is one of predefined function names, and
I<C<name>> distinguishes policy.

If new() is called without C<name> option, it is taken from configuration
parameter of context. Some functions don't have corresponding configuration
parameter and C<name> options for them are mandatory.

=head1 SEE ALSO

L<sympa_scenario(5)>.

=head1 HISTORY

authz() method obsoleting request_action() function introduced on
Sympa 6.2.41b.

=cut

