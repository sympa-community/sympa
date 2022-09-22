# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
# Copyright 2017, 2018, 2019, 2020, 2021 The Sympa Community. See the
# AUTHORS.md file at the top-level directory of this distribution and at
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
use Sympa::Regexps;
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
    family_signoff          => 'family_signoff',
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

    my $scenario_name_re = Sympa::Regexps::scenario_name();

    # Compatibility for obsoleted use of parameter names.
    $function = $compat_function_maps{$function} || $function;
    die 'bug in logic. Ask developer'
        unless defined $function and $function =~ /\A$scenario_name_re\z/;

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

    unless (
        defined $name
        and (  $function eq 'include' and $name =~ m{\A[^/]+\z}
            or $name =~ /\A$scenario_name_re\z/)
    ) {
        $log->syslog(
            'err',
            'Unknown or undefined scenario function "%s", scenario name "%s"',
            $function,
            $name
        );
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

    my $parsed = Sympa::Scenario::compile(
        $that, $data,
        function  => $function,
        file_path => $file_path
    );
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

sub compile {
    my $that    = shift;
    my $data    = shift;
    my %options = @_;

    my $function  = $options{function};
    my $file_path = $options{file_path};

    my $parsed = _parse_scenario($data, $file_path);
    if ($parsed and not($function and $function eq 'include')) {
        $parsed->{compiled} = _compile_scenario($that, $function, $parsed);
        if ($parsed->{compiled}) {
            $parsed->{sub} = eval $parsed->{compiled};
            # Bad syntax in compiled Perl code.
            $log->syslog('err', '%s: %s\n', ($file_path || '(data)'),
                $EVAL_ERROR)
                unless ref $parsed->{sub} eq 'CODE';
        }
    }

    return $parsed;
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

            # 'dkim' became a synonym of 'smtp' on Sympa 6.2.71b.
            my @auth_methods = sort keys %{
                {   map { ($_ eq 'dkim') ? (smtp => 1) : $_ ? ($_ => 1) : () }
                        split(/[\s,]+/, $auth_methods)
                }
            };

            push @rules,
                {
                condition   => $condition,
                auth_method => [@auth_methods],
                action      => $action,
                lineno      => $lineno,
                };
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
    unless ($auth_method =~ /^(smtp|md5|pgp|smime|dkim)/) {  #FIXME: regex '$'
        $log->syslog('info', 'Unknown auth method %s', $auth_method);
        return {
            action      => 'reject',
            reason      => 'unknown-auth-method',
            auth_method => $auth_method,
            condition   => '',
        };
    }

    # 'dkim' auth method was deprecated on Sympa 6.2.71b.
    # Now it is a synonym of 'smtp'.
    $auth_method = 'smtp' if $auth_method eq 'dkim';

    # Defining default values for parameters.
    $context->{'sender'}      ||= 'nobody';
    $context->{'email'}       ||= $context->{'sender'};
    $context->{'remote_host'} ||= 'unknown_host';
    $context->{'execution_date'} //= time;

    if (ref $that eq 'Sympa::List') {
        foreach my $var (@{$that->{'admin'}{'custom_vars'} || []}) {
            $context->{'custom_vars'}{$var->{'name'}} = $var->{'value'};
        }

        $context->{listname} = $that->{'name'};
        $context->{domain}   = $that->{'domain'};
        # Compat.<6.2.32
        $context->{host} = $that->{'domain'};
    } else {
        $context->{domain} = Conf::get_robot_conf($that || '*', 'domain');
    }

    my $sub = ($self->{_scenario} || {})->{sub};
    my $result = eval { $sub->($that, $context, $auth_method) }
        if ref $sub eq 'CODE';
    # Cope with errors.
    unless ($result) {
        unless ($sub) {
            $result = {reason => 'not-compiled'};
        } elsif (ref $EVAL_ERROR eq 'HASH') {
            $result = $EVAL_ERROR;
        } else {
            # Fatal error will be logged but not be exposed.
            $log->syslog('err', 'Error in scenario %s, context %s: (%s)',
                $self, $that, $EVAL_ERROR || 'unknown');
            $result = {};
        }
        $result->{action}      ||= 'reject';
        $result->{reason}      ||= 'error-performing-condition';
        $result->{auth_method} ||= $auth_method;
        $result->{condition}   ||= 'default';

        if ($result->{reason} eq 'not-compiled') {
            $log->syslog('info', '%s: Not compiled, reject', $self);
        } elsif ($result->{reason} eq 'no-rule-match') {
            $log->syslog('info', '%s: No rule match, reject', $self);
        } else {
            $log->syslog('info', 'Error in scenario %s, context %s: (%s)',
                $self, $that, $result->{reason});
            Sympa::send_notify_to_listmaster($that,
                'error_performing_condition', {error => $result->{reason}})
                unless $options{debug};
        }
        return $result;
    }

    my %action = %$result;
    # Check syntax of returned action
    if (   $options{debug}
        or $action{action} =~
        /^(do_it|reject|request_auth|owner|editor|editorkey|listmaster|ham|spam|unsure)/
    ) {
        return {%action, auth_method => $auth_method,};
    } else {
        $log->syslog('err', 'Matched unknown action "%s" in scenario',
            $action{action});
        return {
            action      => 'reject',
            reason      => 'unknown-action',
            auth_method => $auth_method,
        };
    }
}

# Old name: Sympa::Scenario::_parse_action().
sub _compile_action {
    my $action    = shift;
    my $condition = shift;

    my %action;
    $action{condition} = $condition if $condition;

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
            if ($p =~ /^\'?([^'=]+)\'?/) {
                $action{tt2} = $1;
                # keeping existing only, not merging with reject
                # parameters in scenarios
                last;
            }
        }
    }
    $action{action} = $action;

    return _compile_hashref({%action});
}

## check if email respect some condition
# Old name: Sympa::Scenario::verify().
# Deprecated: No longer used.
#sub _verify;

# Old names: (part of) Sympa::Scenario::authz().
sub _compile_scenario {
    $log->syslog('debug2', '(%s, %s, ...)', @_);
    my $that     = shift;
    my $function = shift;
    my $parsed   = shift;

    my @rules = @{$parsed->{rules} || []};

    # Include include.<function>.header if found.
    my $include_scenario =
        Sympa::Scenario->new($that, 'include', name => $function . '.header')
        if $function;
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

    ## Include a Blocklist rules if configured for this action
    if ($function and $Conf::Conf{'blocklist'}{$function}) {
        ## Add rules at the beginning of the array
        unshift @rules,
            {
            'condition'   => "search('blocklist.txt',[sender])",
            'action'      => 'reject,quiet',
            'auth_method' => ['smtp', 'dkim', 'md5', 'pgp', 'smime'],
            };
    }

    my @codes;
    my %required;
    foreach my $rule (@rules) {
        $log->syslog(
            'debug3',
            'Verify rule %s, auth %s, action %s',
            $rule->{'condition'},
            join(',', @{$rule->{'auth_method'} || []}),
            $rule->{'action'}
        );

        my ($code, @required) = _compile_rule($rule);
        return undef unless defined $code;    # Bad syntax.
        push @codes, $code;

        %required = (%required, map { ($_ => 1) } @required);
    }

    my $required = join "\n", map {
        my $req;
        if ($_ eq 'list_object') {
            $req =
                'die "No list context" unless ref $that eq \'Sympa::List\';';
        } elsif ($_ eq 'message') {
            $req = '$context->{message} ||= Sympa::Message->new("\n");';
        } else {
            $req = sprintf '$context->{\'%s\'} //= \'\';', $_;
        }
        "    $req";
    } sort keys %required;

    return sprintf(<<'EOF', $required, join '', @codes);
sub {
    my $that        = shift;
    my $context     = shift;
    my $auth_method = shift;

%s

%s
    die {reason => 'no-rule-match'};
}
EOF

}

sub _compile_rule {
    my $rule = shift;

    my ($cond, @required) = _compile_condition($rule);
    return unless defined $cond and length $cond;

    my $auth_methods = join ' ', sort @{$rule->{'auth_method'} || []};
    my $result = _compile_action($rule->{action}, $rule->{condition});

    if (1 == scalar @{$rule->{'auth_method'} || []}) {
        return (sprintf(<<'EOF', $auth_methods, $result, $cond), @required);
    if ($auth_method eq '%s') {
        return %s if %s;
    }
EOF
    } elsif ($auth_methods eq join(' ', sort qw(smtp md5 smime))) {
        return (sprintf(<<'EOF', $result, $cond), @required);
    return %s if %s;
EOF
    } else {
        return (sprintf(<<'EOF', $auth_methods, $result, $cond), @required);
    if (grep {$auth_method eq $_} qw(%s)) {
        return %s if %s;
    }
EOF
    }
}

sub _compile_condition {
    my $rule = shift;

    my $condition = $rule->{condition};

    unless ($condition =~
        /(\!)?\s*(true|is_listmaster|verify_netmask|is_editor|is_owner|is_subscriber|less_than|match|equal|message|older|newer|all|search|customcondition\:\:\w+)\s*\(\s*(.*)\s*\)\s*/i
    ) {
        $log->syslog('err', 'Error rule syntaxe: unknown condition %s',
            $condition);
        return undef;
    }
    my $negation      = ($1 and $1 eq '!') ? '!' : '';
    my $condition_key = lc $2;
    my $arguments     = $3;

    ## The expression for regexp is tricky because we don't allow the '/'
    ## character (that indicates the end of the regexp
    ## but we allow any number of \/ escape sequence)
    my @args;
    my %required_keys;
    pos $arguments = 0;
    while (
        $arguments =~ m{
        \G\s*(
            (\[\w+(\-\>[\w\-]+)?\](\[[-+]?\d+\])?)
            |
            ([\w\-\.]+)
            |
            '[^,)]*'
            |
            "[^,)]*"
            |
            /([^/]*((\\/)*[^/]+))*/
            |
            (\w+)\.ldap
            |
            (\w+)\.sql
        )\s*,?
        }cgx
    ) {
        my $value = $1;

        if ($value =~ m{\A/(.+)/\z}) {
            my $re = $1;
            # Fix orphan "'" and "\".
            $re =~ s{(\\.|.)}{($1 eq "'" or $1 eq "\\")? "\\$1" : $1}eg;
            # regexp w/o interpolates
            unless (
                defined
                do { local $SIG{__DIE__}; eval sprintf "qr'%s'i", $re }
            ) {
                $log->syslog('err', 'Bad regexp /%s/: %s', $re, $EVAL_ERROR);
                return undef;
            }
            $value = sprintf 'Sympa::Scenario::safe_qr(\'%s\', $context)',
                $re;
        } elsif ($value =~ /\[custom_vars\-\>([\w\-]+)\]/i) {
            # Custom vars
            $value = sprintf '$context->{custom_vars}{\'%s\'}', $1;
        } elsif ($value =~ /\[family\-\>([\w\-]+)\]/i) {
            # Family vars
            $value = sprintf '$context->{family}{\'%s\'}', $1;
        } elsif ($value =~ /\[conf\-\>([\w\-]+)\]/i) {
            # Config param
            my $conf_key = $1;
            # Compat. < 6.2.32
            $conf_key = 'domain' if $conf_key and $conf_key eq 'host';

            if (grep { $_->{'name'} and $_->{'name'} eq $conf_key }
                @Sympa::ConfDef::params) {
                #FIXME: Old or obsoleted names of parameters
                $value =
                    sprintf
                    'Conf::get_robot_conf(((ref $that eq \'Sympa::List\') ? $that->{domain} : $that), \'%s\')',
                    $conf_key;
            } else {
                # a condition related to a undefined context variable is
                # always false
                $log->syslog('err', '%s: Unknown key for [conf->%s]',
                    $conf_key);
                $value = 'undef()';
            }
        } elsif ($value =~ /\[list\-\>([\w\-]+)\]/i) {
            # List param
            my $param = $1;
            $required_keys{list_object} = 1;

            if ($param eq 'name') {
                $value = '$that->{name}';
            } elsif ($param eq 'total') {
                $value = '$that->get_total';
            } elsif ($param eq 'address') {
                $value = 'Sympa::get_address($that)';
            } else {
                my $pinfo = {%Sympa::ListDef::pinfo};    #FIXME

                my $canon_param = $param;
                if (exists $pinfo->{$param}) {
                    my $alias = $pinfo->{$param}{'obsolete'};
                    if ($alias and exists $pinfo->{$alias}) {
                        $canon_param = $alias;
                    }
                }
                if (    exists $pinfo->{$canon_param}
                    and ref $pinfo->{$canon_param}{format} ne 'HASH'
                    and $pinfo->{$canon_param}{occurrence} !~ /n$/) {
                    $value = sprintf '$that->{admin}{\'%s\'}', $canon_param;
                } else {
                    $log->syslog('err',
                        'Unknown list parameter %s in rule %s',
                        $value, $condition);
                    return undef;
                }
            }
        } elsif ($value =~ /\[env\-\>([\w\-]+)\]/i) {
            my $env = $1;
            $value = sprintf '$ENV{\'%s\'}', $env;
        } elsif ($value =~ /\[user\-\>([\w\-]+)\]/i) {
            # Sender's user/subscriber attributes (if subscriber)
            my $key = $1;
            $value =
                sprintf
                '($context->{user} || Sympa::User->new($context->{sender}))->{\'%s\'}',
                $key;
        } elsif ($value =~ /\[user_attributes\-\>([\w\-]+)\]/i) {
            my $key = $1;
            $value =
                sprintf
                '($context->{user} || Sympa::User->new($context->{sender}))->{attributes}{\'%s\'}',
                $key;
        } elsif ($value =~ /\[subscriber\-\>([\w\-]+)\]/i) {
            my $key = $1;
            $value =
                sprintf
                '($context->{subscriber} || $that->get_list_memner($context->{sender}) || {})->{\'%s\'}',
                $key;
        } elsif ($value =~
            /\[(msg_header|header)\-\>([\w\-]+)\](?:\[([-+]?\d+)\])?/i) {
            ## SMTP header field.
            ## "[msg_header->field]" returns arrayref of field values,
            ## preserving order. "[msg_header->field][index]" returns one
            ## field value.
            my $field_name = $2;
            my $index = (defined $3) ? $3 + 0 : undef;
            ## Defaulting empty or missing fields to '', so that we can
            ## test their value in Scenario, considering that, for an
            ## incoming message, a missing field is equivalent to an empty
            ## field : the information it is supposed to contain isn't
            ## available.
            if (defined $index) {
                $value =
                    sprintf
                    'do { my @h = $context->{message}->get_header(\'%s\'); $h[%s] // \'\' }',
                    $field_name, $index;
            } else {
                $value =
                    sprintf
                    'do { my @h = $context->{message}->get_header(\'%s\'); @h ? [@h] : [\'\'] }',
                    $field_name;
            }
            $required_keys{message} = 1;
        } elsif ($value =~ /\[msg_body\]/i) {
            $value = '$context->{message}->body_as_string';
            $value =
                sprintf
                '((0 == index lc($context->{message}->as_entity->effective_type || "text"), "text") ? %s : undef)',
                $value;
            $required_keys{message} = 1;
        } elsif ($value =~ /\[msg_part\-\>body\]/i) {
            #FIXME:Should be recurcive...
            $value =
                '[map {$_->bodyhandle->as_string} grep { defined $_->bodyhandle and 0 == index ($_->effective_type || "text"), "text" } $context->{message}->as_entity->parts]';
            $required_keys{message} = 1;
        } elsif ($value =~ /\[msg_part\-\>type\]/i) {
            $value =
                '[map {$_->effective_type} $context->{message}->as_entity->parts]';
            $required_keys{message} = 1;
        } elsif ($value =~ /\[msg\-\>(\w+)\]/i) {
            my $key = $1;
            $value =
                sprintf
                '(exists $context->{message}{%s} ? $context->{message}{%s} : undef)',
                $key, $key;
            $required_keys{message} = 1;
        } elsif ($value =~ /\[is_bcc\]/i) {
            $value =
                'Sympa::Scenario::message_is_bcc($that, $context->{message})';
            $required_keys{list_object} = 1;
            $required_keys{message}     = 1;
        } elsif ($value =~ /\[msg_encrypted\]/i) {
            $value =
                'Sympa::Scenario::message_encrypted($context->{message})';
            $required_keys{message} = 1;
        } elsif ($value =~ /\[(topic(?:_\w+)?)\]/i) {
            # Useful only with send scenario.
            my $key = $1;
            $value = sprintf '$context->{%s}', $key;
            $required_keys{$key} = 1;
            $required_keys{message} = 1;
        } elsif ($value =~ /\[current_date\]/i) {
            $value = 'time()';
        } elsif ($value =~ /\[listname\]/i) {
            # Context should be a List from which value will be taken.
            $value = '$that->{name}';
            $required_keys{list_object} = 1;
        } elsif ($value =~ /\[(\w+)\]/i) {
            my $key = $1;
            $value = sprintf '$context->{%s}', $key;
            $required_keys{$key} = 1;
        } elsif ($value =~ /^'(.*)'$/ || $value =~ /^"(.*)"$/) {
            # Quoted string
            my $str = $1;
            $str =~ s{(\\.|.)}{($1 eq "'" or $1 eq "\\")? "\\\'" : $1}eg;
            $value = sprintf "'%s'", $str;
        } else {
            # Texts with unknown format may be treated as the string constants
            # for compatibility to loose parsing with earlier ver (<=6.2.48).
            my $str = $value;
            $str =~ s/([\\\'])/\\$1/g;
            $value = sprintf "'%s'", $str;
        }
        push(@args, $value);
    }

    my $term = _compile_condition_term($rule, $condition_key, @args);
    return unless $term;

    return ("$negation$term", sort keys %required_keys);
}

sub _compile_condition_term {
    my $rule          = shift;
    my $condition_key = shift;
    my @args          = @_;

    # Getting rid of spaces.
    $condition_key =~ s/^\s*//g;
    $condition_key =~ s/\s*$//g;

    if ($condition_key =~ /^(true|all)$/i) {
        # condition that require 0 argument
        if (@args) {
            $log->syslog(
                'err',
                'Syntax error: Incorrect number of argument or incorrect argument syntax in %s',
                $condition_key
            );
            return undef;
        }
        return '1';
    } elsif ($condition_key =~ /^(is_listmaster|verify_netmask)$/) {
        # condition that require 1 argument
        unless (scalar @args == 1) {
            $log->syslog('err',
                'Syntax error: Incorrect argument number for condition %s',
                $condition_key);
            return undef;
        }
    } elsif ($condition_key =~ /^search$/o) {
        # condition that require 1 or 2 args (search : historical reasons)
        unless (scalar @args == 1 or scalar @args == 2) {
            $log->syslog('err',
                'Syntax error: Incorrect argument number for condition %s',
                $condition_key);
            return undef;
        }
        # We could search in the family if we got ref on Sympa::Family object.
        return sprintf 'Sympa::Scenario::do_search($that, $context, %s)',
            join ', ', @args;
    } elsif (
        $condition_key =~
        # condition that require 2 args
        /^(is_owner|is_editor|is_subscriber|less_than|match|equal|message|newer|older)$/o
    ) {
        unless (scalar @args == 2) {
            $log->syslog(
                'err',
                'Syntax error: Incorrect argument number (%d instead of %d) for condition %s',
                scalar(@args),
                2,
                $condition_key
            );
            return undef;
        }
        if ($condition_key =~ /\A(is_owner|is_editor|is_subscriber)\z/) {
            # Interpret '[listname]' as $that.
            $args[0] = '$that' if $args[0] eq '$that->{name}';
        }
    } elsif ($condition_key =~ /^customcondition::(\w+)$/) {
        my $mod = $1;
        return sprintf 'do_verify_custom($that, %s, \'%s\', %s)',
            _compile_hashref($rule), $mod, join ', ', @args;
    } else {
        $log->syslog('err', 'Syntax error: Unknown condition %s',
            $condition_key);
        return undef;
    }

    return sprintf 'Sympa::Scenario::do_%s($that, \'%s\', %s)',
        $condition_key, $condition_key, join ', ', @args;
}

sub _compile_hashref {
    my $hashref = shift;

    return '{' . join(
        ', ',
        map {
            my ($k, $v) = ($_, $hashref->{$_});
            if (ref $v eq 'ARRAY') {
                $v = join(
                    ', ',
                    map {
                        my $i = $_;
                        $i =~ s/([\\\'])/\\$1/g;
                        "'$i'";
                    } @$v
                );
                sprintf '%s => [%s]', $k, $v;
            } else {
                $v =~ s/([\\\'])/\\$1/g;
                sprintf "%s => '%s'", $k, $v;
            }
        } sort keys %$hashref
    ) . '}';
}

sub message_is_bcc {
    my $that    = shift;
    my $message = shift;

    return '' unless $message;
    #FIXME: need more accurate test.
    return (
        0 <= index(
            lc join(', ',
                $message->get_header('To'),
                $message->get_header('Cc')),
            lc $that->{'name'}
        )
    ) ? 0 : 1;
}

sub message_encrypted {
    my $message = shift;

    return ($message and $message->{smime_crypted}) ? 'smime' : '';
}

sub safe_qr {
    my $re      = shift;
    my $context = shift;

    my $domain = $context->{domain};
    $domain =~ s/[.]/[.]/g;
    $re =~ s/[[](domain|host)[]]/$domain/g;
    return do { local $SIG{__DIE__}; eval sprintf "qr'%s'i", $re };
}

##### condition : true

##### condition is_listmaster
sub do_is_listmaster {
    my $that          = shift;
    my $condition_key = shift;
    my @args          = @_;

    return 0 if not ref $args[0] and $args[0] eq 'nobody';

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
        if (Sympa::is_listmaster($that, $arg)) {
            $ok = $arg;
            last;
        }
    }

    return $ok ? 1 : 0;
}

##### condition verify_netmask
sub do_verify_netmask {
    my $that          = shift;
    my $condition_key = shift;
    my @args          = @_;
    ## Check that the IP address of the client is available
    ## Means we are in a web context
    # always skip this rule because we can't evaluate it.
    return 0 unless defined $ENV{'REMOTE_ADDR'};

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
        $log->syslog('err', 'Error rule syntax: failed to parse netmask "%s"',
            $args[0]);
        die {};
    }

    $log->syslog('debug3', 'REMOTE_ADDR %s against %s',
        $ENV{'REMOTE_ADDR'}, $args[0]);
    return Net::CIDR::cidrlookup($ENV{'REMOTE_ADDR'}, @cidr) ? 1 : 0;
}

##### condition older
sub do_older {
    $log->syslog('debug3', '(%s,%s,%s,%s)', @_);
    my $that          = shift;
    my $condition_key = shift;
    my @args          = @_;

    my $arg0 = Sympa::Tools::Time::epoch_conv($args[0]);
    my $arg1 = Sympa::Tools::Time::epoch_conv($args[1]);

    if ($condition_key eq 'older') {
        return ($arg0 <= $arg1) ? 1 : 0;
    } else {
        return ($arg0 > $arg1) ? 1 : 0;
    }
}

sub do_newer {
    goto &do_older;
}

##### condition is_owner, is_subscriber and is_editor
sub do_is_owner {
    my $that          = shift;
    my $condition_key = shift;
    my @args          = @_;

    return 0 if $args[1] eq 'nobody';

    # The list is local or in another local robot
    my $list;
    if (ref $args[0] eq 'Sympa::List') {
        $list = $args[0];
    } elsif ($args[0] =~ /\@/) {
        $list = Sympa::List->new($args[0]);
    } else {
        my $robot = (ref $that eq 'Sympa::List') ? $that->{'domain'} : $that;
        $list = Sympa::List->new($args[0], $robot);
    }

    unless ($list) {
        $log->syslog('err', 'Unable to create list object "%s"', $args[0]);
        return 0;
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
            if ($list->is_list_member($arg)) {
                $ok = $arg;
                last;
            }
        }
        return $ok ? 1 : 0;
    } elsif ($condition_key eq 'is_owner') {
        foreach my $arg (@arg) {
            if ($list->is_admin('owner', $arg)
                or Sympa::is_listmaster($list, $arg)) {
                $ok = $arg;
                last;
            }
        }
        return $ok ? 1 : 0;
    } elsif ($condition_key eq 'is_editor') {
        foreach my $arg (@arg) {
            if ($list->is_admin('actual_editor', $arg)) {
                $ok = $arg;
                last;
            }
        }
        return $ok ? 1 : 0;
    }
}

sub do_is_subscriber {
    goto &do_is_owner;
}

sub do_is_editor {
    goto &do_is_owner;
}

##### match
sub do_match {
    $log->syslog('debug3', '(%s,%s,%s,%s)', @_);
    my $that          = shift;
    my $condition_key = shift;
    my @args          = @_;

    # Nothing can match an empty regexp.
    return 0 unless length $args[1];

    # wrap matches with eval{} to avoid crash by malformed regexp.
    my $r = 0;
    if (ref $args[0] eq 'ARRAY') {
        eval {
            foreach my $arg (@{$args[0]}) {
                if ($arg =~ /$args[1]/i) {
                    $r = 1;
                    last;
                }
            }
        };
    } else {
        eval {
            if ($args[0] =~ /$args[1]/i) {
                $r = 1;
            }
        };
    }
    if ($EVAL_ERROR) {
        $log->syslog('err', 'Cannot evaluate match: %s', $EVAL_ERROR);
        return undef;
    }
    return $r ? 1 : 0;
}

## search rule

## equal
sub do_equal {
    $log->syslog('debug3', '(%s,%s,...)', @_);
    my $that          = shift;
    my $condition_key = shift;
    my @args          = @_;
    if (ref $args[0]) {
        foreach my $arg (@{$args[0]}) {
            return 1 if lc $arg eq lc $args[1];
        }
    } elsif (lc $args[0] eq lc $args[1]) {
        return 1;
    }
    return 0;
}

## custom perl module

## less_than
sub do_less_than {
    $log->syslog('debug3', '(%s,%s,,,,)', @_);
    my $that          = shift;
    my $condition_key = shift;
    my @args          = @_;
    if (ref $args[0]) {
        foreach my $arg (@{$args[0]}) {
            return 1 if Sympa::Tools::Data::smart_lessthan($arg, $args[1]);
        }
    } else {
        return 1 if Sympa::Tools::Data::smart_lessthan($args[0], $args[1]);
    }

    return 0;
}

# Verify if a given user is part of an LDAP, SQL or TXT search filter
# We could search in the family if we got ref on Sympa::Family object.
# Old name: Sympa::Scenario::search(), Sympa::Scenario::_search().
sub do_search {
    $log->syslog('debug2', '(%s, %s, %s)', @_);
    my $that        = shift;    # List, Family or Robot
    my $context     = shift;
    my $filter_file = shift;

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
            die {};
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
                die {};
            }

            if (defined $key) {    ## Should be a hash
                unless (defined $context->{$var}{$key}) {
                    $log->syslog('err',
                        'Failed to parse variable "%s.%s" in filter "%s"',
                        $var, $key, $file);
                    die {};
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
            die {};
        }

        my $sth;
        unless ($sth = $db->do_prepared_query($statement, @statement_args)) {
            $log->syslog('debug', '%s named filter cancelled', $file);
            die {};
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
            die {};
        }
        my $timeout   = 3600;
        my %ldap_conf = _load_ldap_configuration($file);

        die {} unless %ldap_conf;

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
                die {};
            }

            if (defined $key) {    ## Should be a hash
                unless (defined $context->{$var}{$key}) {
                    $log->syslog('err',
                        'Failed to parse variable "%s.%s" in filter "%s"',
                        $var, $key, $file);
                    die {};
                }

                $filter =~ s/\[$full_var\]/$context->{$var}{$key}/;
            } else {               ## Scalar
                $filter =~ s/\[$full_var\]/$context->{$var}/;

            }
        }

        # $filter =~ s/\[sender\]/$sender/g;

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
            die {};
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
            die {};
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

        ## Raise an error except for blocklist.txt
        unless (@files) {
            if ($filter_file eq 'blocklist.txt') {
                return 0;
            } else {
                $log->syslog('err', 'Could not find search filter %s',
                    $filter_file);
                die {};
            }
        }

        my $sender = lc($sender);
        foreach my $file (@files) {
            $log->syslog('debug3', 'Found file %s', $file);
            my $ifh;
            unless (open $ifh, '<', $file) {
                $log->syslog('err', 'Could not open file %s', $file);
                die {};
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
        return 0;
    } else {
        $log->syslog('err', "Unknown filter file type %s", $filter_file);
        die {};
    }
}

# eval a custom perl module to verify a scenario condition
# Old name: Sympa::Scenario::_verify_custom().
sub do_verify_custom {
    $log->syslog('debug3', '(%s, %s, %s, ...)', @_);
    my $that      = shift;
    my $rule      = shift;
    my $condition = shift;
    my @args      = @_;

    my $timeout = 3600;

    my $filter = join('*', @args);
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
    #my $file = Sympa::search_fullpath($that, $condition . '.pm',
    #    subdir => 'custom_conditions');
    my $robot = (ref $that eq 'Sympa::List') ? $that->{'domain'} : $that;
    my $file = Sympa::search_fullpath(
        $robot,
        $condition . '.pm',
        subdir => 'custom_conditions'
    );
    unless ($file) {
        $log->syslog('err', 'No module found for %s custom condition',
            $condition);
        die {};
    }
    $log->syslog('notice', 'Use module %s for custom condition', $file);
    eval { require "$file"; };
    if ($EVAL_ERROR) {
        $log->syslog('err', 'Error requiring %s: %s (%s)',
            $condition, "$EVAL_ERROR", ref $EVAL_ERROR);
        die {};
    }
    my $res = do {
        local $_ = $rule;
        eval sprintf 'CustomCondition::%s::verify(@args)', $condition;
    };
    if ($EVAL_ERROR) {
        $log->syslog('err', 'Error evaluating %s: %s (%s)',
            $condition, "$EVAL_ERROR", ref $EVAL_ERROR);
        die {};
    }

    die {} unless defined $res;

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

    my $scenario_re = Sympa::Regexps::scenario_name();
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
            next unless (defined $scenario);

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

Note:
C<pgp> has not been implemented.

Note:
C<dkim> was deprecated on Sympa 6.2.71b.
Now it is the synonym of C<smtp>.

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

=item compile ( $that, $data,
[ function =E<gt> $function ], [ file_path =E<gt> $path ] )

I<Function>.
Compiles scenario source and returns results.

Parameters:

=over

=item $that

Context.  L<Sympa::List> instance or Robot.

=item $data

Source text of scenario.

=item function =E<gt> $function

Name of function.  Optional.

=item file_path =E<gt> $path

Path of scenario file.  Optional.

=back

Returns:

Hashref with following items, or C<undef> on failure.

=over

=item {compiled}

Compiled scenario represented by Perl code.

=item {sub}

Compiled coderef.

=item {data}

Source text of the scenario.

=item {title}

Hashref representing titles of the scenario.

=item {rules}

Arrayref to texts of rules.

=item {purely_closed}

True if the scenario is purely closed.

=item {date}

Keep track of the current time if C<file_path> is given.
This is used later to reload scenario files when they changed on disk.

=back

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

authz() method obsoleting request_action() function was introduced on
Sympa 6.2.41b.
compile() function was added on Sympa 6.2.49b.

=cut

