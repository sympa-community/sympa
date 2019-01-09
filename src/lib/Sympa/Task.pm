# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
# Copyright 2018 The Sympa Community. See the AUTHORS.md file at the
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

package Sympa::Task;

use strict;
use warnings;
use Scalar::Util;
use Template;

use Sympa;
use Conf;
use Sympa::Language;
use Sympa::Log;
use Sympa::Tools::Data;

my $language = Sympa::Language->instance;
my $log      = Sympa::Log->instance;

# List of list task models. FIXME:Refer Sympa::ListDef.
use constant list_models => {
    #expire       => 'expire_task',     # Not yet implemented.
    remind       => 'remind_task',
    sync_include => '',
};

# List of global task models. FIXME:Refer Sympa::ConfDef.
use constant site_models => {
    expire_bounce               => 'expire_bounce_task',
    purge_user_table            => 'purge_user_table_task',
    purge_logs_table            => 'purge_logs_table_task',
    purge_session_table         => 'purge_session_table_task',
    purge_spools                => 'purge_spools_task',
    purge_tables                => 'purge_tables_task',
    purge_one_time_ticket_table => 'purge_one_time_ticket_table_task',
    purge_orphan_bounces        => 'purge_orphan_bounces_task',
    eval_bouncers               => 'eval_bouncers_task',
    process_bouncers            => 'process_bouncers_task',
};

# Creates a new Sympa::Task object.
# Old name: create() in task_manager.pl, entirely rewritten.
sub new {
    my $class = shift;
    # Optional serialized content.
    my $serialized;
    if (@_ and ($_[0] eq '' or $_[0] =~ /\n/)) {
        $serialized = shift;
    }
    my %options = @_;

    die 'bug in logic. Ask developer'
        unless defined $options{model} and length $options{model};
    $options{context} = '*'
        unless ref $options{context} eq 'Sympa::List';    #FIXME
    $options{date} = time
        unless defined $options{date};
    $options{label} = ($options{model} eq 'sync_include') ? 'INIT' : ''
        unless defined $options{label};

    my $self = bless {%options} => $class;

    unless (defined $serialized) {
        my $that  = $self->{context};
        my $model = $self->{model};
        my $name;
        my $pname;

        if (defined $self->{name} and length $self->{name}) {
            die 'bug in logic. Ask developer'
                unless $self->{name} =~ /\A\w+\z/;
            $name = $self->{name};
        } elsif (ref $that eq 'Sympa::List' and $model eq 'sync_include') {
            $name = 'ttl';
        } elsif (ref $that eq 'Sympa::List'
            and $pname = ${list_models()}{$model}) {
            $name = $that->{'admin'}{$pname}->{'name'};
        } elsif ($that eq '*' and $pname = ${site_models()}{$model}) {
            $name = Conf::get_robot_conf($that, $pname);
        } else {
            $log->syslog('err', 'Unknown task %s for %s', $model, $that);
            return undef;
        }
        unless ($name) {
            $log->syslog('debug3', 'Inactive task %s for %s', $model, $that);
            return undef;
        }

        my $model_name = sprintf '%s.%s.task', $model, $name;
        my $model_file =
            Sympa::search_fullpath($that, $model_name, subdir => 'tasks');
        unless ($model_file) {
            $log->syslog('err', 'Unable to find task file %s for %s',
                $model_name, $that);
            return undef;
        }

        # creation
        my $data = {
            creation_date  => $self->{date},       # Compat., has never used
            execution_date => 'execution_date',    # Compat.
        };
        if (ref $that eq 'Sympa::List') {
            $data->{domain} = $that->{'domain'};    # New on 6.2.37b
            $data->{list}   = {
                name  => $that->{'name'},
                robot => $that->{'domain'},         # Compat., has never used
                ttl   => $that->{'admin'}{'ttl'},
            };
        }
        my $tt2 = Template->new(
            {   'START_TAG' => quotemeta('['),
                'END_TAG'   => quotemeta(']'),
                'ABSOLUTE'  => 1
            }
        );
        unless ($tt2 and $tt2->process($model_file, $data, \$serialized)) {
            $log->syslog('err', 'Failed to parse task template "%s": %s',
                $model_file, $tt2->error);
            return undef;
        }
    }

    unless ($self->_parse($serialized)) {
        $log->syslog('err', 'Syntax error in task file. You should check %s',
            $self);
        return undef;
    }
    $self;
}

### DEFINITION OF AVAILABLE COMMANDS FOR TASKS ###

my $date_arg_regexp1 = '\d+|execution_date';
my $date_arg_regexp2 = '(\d\d\d\dy)(\d+m)?(\d+d)?(\d+h)?(\d+min)?(\d+sec)?';
my $date_arg_regexp3 =
    '(\d+|execution_date)(\+|\-)(\d+y)?(\d+m)?(\d+w)?(\d+d)?(\d+h)?(\d+min)?(\d+sec)?';
my $delay_regexp  = '(\d+y)?(\d+m)?(\d+w)?(\d+d)?(\d+h)?(\d+min)?(\d+sec)?';
my $var_regexp    = '@\w+';
my $subarg_regexp = '(\w+)(|\((.*)\))';

# commands which use a variable. If you add such a command, the first
# parameter must be the variable
my %var_commands = (
    'delete_subs' => ['var'],
    # variable
    'send_msg' => ['var', '\w+'],
    #variable template
    'rm_file' => ['var'],
    # variable
);

# commands which are used for assignments
my %asgn_commands = (
    'select_subs' => ['subarg'],
    # condition
    'delete_subs' => ['var'],
    # variable
);

# regular commands
my %commands = (
    'next' => ['date', '\w*'],
    # date   label
    'stop'   => [],
    'create' => ['subarg', '\w+', '\w+'],
    #object    model  model choice
    'exec' => ['.+'],
    #file    #delay
    'expire_bounce' => ['\d+'],
    #template  date
    'sync_include'                => [],
    'purge_user_table'            => [],
    'purge_logs_table'            => [],
    'purge_session_table'         => [],
    'purge_spools'                => [],
    'purge_tables'                => [],
    'purge_one_time_ticket_table' => [],
    'purge_orphan_bounces'        => [],
    'eval_bouncers'               => [],
    'process_bouncers'            => [],
    %var_commands,
    %asgn_commands,
);

### SYNTAX CHECKING SUBROUTINES ###

# Check the syntax of a task.
# Old name: check() in task_manager.pl.
sub _parse {
    $log->syslog('debug2', '(%s, ...)', @_);
    my $self       = shift;
    my $serialized = shift;

    my $lnb = 0;        # line number
    my %used_labels;    # list of labels used as parameter in commands
    my %labels;         # list of declared labels
    my %used_vars;      # list of vars used as parameter in commands
    my %vars;           # list of declared vars

    return undef unless defined $serialized;
    $self->{_source} = $serialized;
    $self->{_title}  = {};
    $self->{_parsed} = [];

    foreach my $line (split /\r\n|\r|\n/, $serialized) {
        $lnb++;
        next if $line =~ /^\s*\#/;

        my %result;

        unless (_chk_line($line, \%result)) {
            $log->syslog('err', 'Error at line %s: %s', $lnb, $line);
            $log->syslog('err', '%s', $result{'error'});
            return undef;
        }

        if ($result{'nature'} eq 'assignment') {
            if (_chk_cmd(
                    $result{'command'},    $lnb,
                    $result{'Rarguments'}, \%used_labels,
                    \%used_vars
                )
            ) {
                $vars{$result{'var'}} = 1;
            } else {
                return undef;
            }
        } elsif ($result{'nature'} eq 'command') {
            return undef
                unless _chk_cmd($result{'command'}, $lnb,
                $result{'Rarguments'}, \%used_labels, \%used_vars);
        } elsif ($result{'nature'} eq 'label') {
            $labels{$result{'label'}} = 1;
        } elsif ($result{'nature'} eq 'title') {
            $self->{_title}->{$result{'lang'}} = $result{'title'};
            next;
        } else {
            next;
        }

        push @{$self->{_parsed}}, {%result, line => $lnb};
    }

    # are all labels used ?
    foreach my $label (keys %labels) {
        $log->syslog('debug3', 'Warning: Label %s exists but is not used',
            $label)
            unless $used_labels{$label};
    }

    # do all used labels exist ?
    foreach my $label (keys %used_labels) {
        unless ($labels{$label}) {
            $log->syslog('err', 'Label %s is used but does not exist',
                $label);
            return undef;
        }
    }

    # are all variables used ?
    foreach my $var (keys %vars) {
        $log->syslog('notice', 'Warning: Var %s exists but is not used', $var)
            unless $used_vars{$var};
    }

    # do all used variables exist ?
    foreach my $var (keys %used_vars) {
        unless ($vars{$var}) {
            $log->syslog('err', 'Var %s is used but does not exist', $var);
            return undef;
        }
    }

    # Set the title in the current language.
    my $titles = $self->{_title} || {};
    foreach my $lang (Sympa::Language::implicated_langs($language->get_lang))
    {
        if (exists $titles->{$lang}) {
            $self->{title} = $titles->{$lang};
            last;
        }
    }
    if ($self->{title}) {
        ;
    } elsif (exists $titles->{gettext}) {
        $self->{title} = $language->gettext($titles->{gettext});
    } elsif (exists $titles->{default}) {
        $self->{title} = $titles->{default};
    } else {
        $self->{title} = $self->{name} || $self->{model};
    }

    return 1;
}

# Check a task line.
# Old name: chk_line() in task_manager.pl.
sub _chk_line {
    my $line  = shift;
    my $Rhash = shift;

    ## just in case...
    chomp $line;

    $log->syslog('debug2', '(%s, %s)', $line, $Rhash->{'nature'});

    $Rhash->{'nature'} = undef;

    # empty line
    unless (length $line) {
        $Rhash->{'nature'} = 'empty line';
        return 1;
    }

    # comment
    if ($line =~ /^\s*\#.*/) {
        $Rhash->{'nature'} = 'comment';
        return 1;
    }

    # title
    #FIXME:Currently not used.
    if ($line =~ /^\s*title\.gettext\s+(.*)\s*$/i) {
        @{$Rhash}{qw(nature title lang)} = ('title', $1, 'gettext');
        return 1;
    } elsif ($line =~ /^\s*title\.(\S+)\s+(.*)\s*$/i) {
        my ($lang, $title) = ($1, $2);
        # canonicalize lang if possible.
        $lang = Sympa::Language::canonic_lang($lang) || $lang;
        @{$Rhash}{qw(nature title lang)} = ('title', $title, $lang);
        return 1;
    } elsif ($line =~ /^\s*title\s+(.*)\s*$/i) {
        @{$Rhash}{qw(nature title lang)} = ('title', $1, 'default');
        return 1;
    }

    # label
    if ($line =~ /^\s*\/\s*(.*)/) {
        $Rhash->{'nature'} = 'label';
        $Rhash->{'label'}  = $1;
        return 1;
    }

    # command
    if ($line =~ /^\s*(\w+)\s*\((.*)\)\s*/i) {

        my $command = lc($1);
        my @args = split(/,/, $2);
        foreach (@args) { s/\s//g; }

        unless ($commands{$command}) {
            $Rhash->{'nature'} = 'error';
            $Rhash->{'error'}  = "unknown command $command";
            return 0;
        }

        $Rhash->{'nature'}  = 'command';
        $Rhash->{'command'} = $command;

        # arguments recovery. no checking of their syntax !!!
        $Rhash->{'Rarguments'} = \@args;
        return 1;
    }

    # assignment
    if ($line =~ /^\s*(@\w+)\s*=\s*(.+)/) {
        my %hash2;
        _chk_line($2, \%hash2);
        unless ($asgn_commands{$hash2{'command'}}) {
            $Rhash->{'nature'} = 'error';
            $Rhash->{'error'}  = "non valid assignment $2";
            return 0;
        }
        $Rhash->{'nature'}     = 'assignment';
        $Rhash->{'var'}        = $1;
        $Rhash->{'command'}    = $hash2{'command'};
        $Rhash->{'Rarguments'} = $hash2{'Rarguments'};
        return 1;
    }

    $Rhash->{'nature'} = 'error';
    $Rhash->{'error'}  = 'syntax error';
    return 0;
}

# Check the arguments of a command.
# Old name: chk_cmd() in task_manager.pl.
sub _chk_cmd {
    $log->syslog('debug2', '(%s, %d, %s)', @_);
    my $cmd          = shift;    # command name
    my $lnb          = shift;    # line number
    my $Rargs        = shift;    # argument list
    my $Rused_labels = shift;
    my $Rused_vars   = shift;

    if (defined $commands{$cmd}) {
        my @expected_args = @{$commands{$cmd}};

        unless (scalar(@expected_args) == scalar(@$Rargs)) {
            $log->syslog('err',
                'Error at line %s: wrong number of arguments for %s',
                $lnb, $cmd);
            $log->syslog(
                'err',
                'Args = %s; expected_args = %s',
                join(',', @$Rargs),
                join(',', @expected_args)
            );
            return undef;
        }

        foreach my $arg (@$Rargs) {
            my $error;
            my $regexp = shift @expected_args;

            if ($regexp eq 'date') {
                $error = 1
                    unless $arg =~ /^$date_arg_regexp1$/i
                    or $arg =~ /^$date_arg_regexp2$/i
                    or $arg =~ /^$date_arg_regexp3$/i;
            } elsif ($regexp eq 'delay') {
                $error = 1 unless $arg =~ /^$delay_regexp$/i;
            } elsif ($regexp eq 'var') {
                $error = 1 unless $arg =~ /^$var_regexp$/i;
            } elsif ($regexp eq 'subarg') {
                $error = 1 unless $arg =~ /^$subarg_regexp$/i;
            } else {
                $error = 1 unless $arg =~ /^$regexp$/i;
            }

            if ($error) {
                $log->syslog('err',
                    'Error at line %s: argument %s is not valid',
                    $lnb, $arg);
                return undef;
            }

            $Rused_labels->{$Rargs->[1]} = 1
                if $cmd eq 'next' and $Rargs->[1];
            $Rused_vars->{$Rargs->[0]} = 1
                if $var_commands{$cmd};
        }
    }
    return 1;
}

sub dup {
    my $self = shift;

    my $clone = {};
    foreach my $key (sort keys %$self) {
        my $val = $self->{$key};
        next unless defined $val;

        unless (Scalar::Util::blessed($val)) {
            $clone->{$key} = Sympa::Tools::Data::dup_var($val);
        } elsif ($val->can('dup') and !$val->isa('Sympa::List')) {
            $clone->{$key} = $val->dup;
        } else {
            $clone->{$key} = $val;
        }
    }

    return bless $clone => ref($self);
}

sub to_string {
    shift->{_source};
}

sub lines {
    @{shift->{_parsed} || []};
}

# Old name: Sympa::List::load_task_list() which returned hashref.
sub get_tasks {
    $log->syslog('debug2', '(%s, %s)', @_);
    my $that  = shift;
    my $model = shift;

    my %tasks;

    foreach my $dir (@{Sympa::get_search_path($that, subdir => 'tasks')}) {
        my $dh;
        opendir $dh, $dir or next;
        foreach my $file (readdir $dh) {
            next unless $file =~ /\A$model[.](\w+)[.]task\z/;
            my $name = $1;
            next if $tasks{$name};

            my $task = Sympa::Task->new(
                context => $that,
                model   => $model,
                name    => $name
            );
            next unless $task;

            $tasks{$name} = $task;
        }
        closedir $dh;
    }

    return [map { $tasks{$_} } sort keys %tasks];
}

## Build all Sympa::Task objects
# No longer used. Use Sympa::Spool::Task::next().
#sub list_tasks;

## Return a list tasks for the given list
# No longer used. Use Sympa::Spool::Task::next().
#sub get_tasks_by_list;

# No longer used.
#sub get_used_models;

# No longer used. Use Sympa::Spool::Task::next().
#sub get_task_list;

## sort task name by their epoch date
# No longer used.
#sub epoch_sort;

sub get_id {
    my $self = shift;
    sprintf 'date=%s;label=%s;model=%s;context=%s',
        @{$self}{qw(date label model)},
        (ref $self->{context} ? $self->{context}->get_id : '*');
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Task - Tasks of Sympa

=head1 SYNOPSIS

  use Sympa::Task;
  
  $task = Sympa::Task->new($serialized, context => $list,
      model => 'remind', label => 'EXEC', date => 1234567890);
  
  $task = Sympa::Task->new(context => $list, model => 'remind');

=head1 DESCRIPTION

=head2 Methods

=over

=item new ( $serialized, context =E<gt> $that, model =E<gt> $model,
label =E<gt> $label, date =E<gt> $date )

=item new ( context =E<gt> $that, model =E<gt> $model, [ name =E<gt> $name ],
[ label =E<gt> $label ], [ date =E<gt> $date ] )

I<Constructor>.
Creates a new instance of L<Sympa::Task> class.

The first style is usually used by task spool class
(see also L<Sympa::Spool::Task>): C<context>, C<model>, C<label> and C<date>
are given by metadata (file name).

Parameters:

=over

=item $serialized

Serialized content of task file in spool.
If omitted (the second style above), appropriate task file is read,
parsed and used for serialized content.

=item context =E<gt> $that

Context of the task: List (instance of L<Sympa::List>) or Site (C<'*'>).

=item model =E<gt> $model

Task model.

=item name =E<gt> $name

Selector of task.
If omitted, value of parameter of context object that corresponds to
task model is used; if parameter value was not valid, constructor returns
C<undef>.

=item label =E<gt> $label

Label of task.
If omitted, default label (in many cases, empty string) is used.

=item date =E<gt> $date

Unix time. creation date of label.
If omitted, current time.

=back

Returns:

New instance of L<Sympa::Task> class.

=item dup ( )

I<Copy constructor>.
Creates deep copy of instance.

=item lines ( )

I<Instance method>.
Gets an array of parsed information by each line of serialized content.

=item to_string ( )

I<Instance method>.
Gets serialized content of the task. 

=item get_id ( )

I<Instasnce method>.
Gets unique identifier of instance.

=back

=head2 Function

=over

=item get_tasks ( $that, $model )

I<Function>.
Gets all possible tasks for particular context.

Parameters:

=over

=item $that

Context. Instance of L<Sympa::List> or C<'*'>.

=item $model

Task model.

=back

Returns:

An arrayref of possible tasks.

=back

=head2 Attributes

=over

=item {date}

=item {model}

=item {title}

TBD.

=back

=head1 SEE ALSO

L<task_manager(8)>.

L<Sympa::Spool::Task>.

=head1 HISTORY

L<Task> module appeared on Sympa 5.2b.1.
It was renamed to L<Sympa::Task> on Sympa 6.2a.41.

It was rewritten and split into Sympa::Task and L<Sympa::Spool::Task> on
Sympa 6.2.37b.2.

=cut
