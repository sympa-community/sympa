# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
# Copyright 2017, 2018, 2019 The Sympa Community. See the AUTHORS.md file
# at the top-level directory of this distribution and at
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

=encoding utf-8

#=head1 NAME 
#
#I<Family.pm> - Handles list families

=head1 DESCRIPTION 

Sympa allows lists creation and management by sets. These are the families, sets of lists sharing common properties. This module gathers all the family-specific operations.

=cut 

package Sympa::Family;

use strict;
use warnings;
use English qw(-no_match_vars);
use Term::ProgressBar;
use XML::LibXML;

use Sympa;
use Conf;
use Sympa::DatabaseManager;
use Sympa::List;
use Sympa::Log;
use Sympa::Regexps;
use Sympa::Spindle::ProcessRequest;
use Sympa::Tools::File;

my $log = Sympa::Log->instance;

my %list_of_families;
my @uncompellable_param = (
    'msg_topic.keywords',
    'owner_include.source_parameters',
    'editor_include.source_parameters'
);

=pod 

=head1 SUBFUNCTIONS 

This is the description of the subfunctions contained by Family.pm

=cut 

=pod 

=head1 Class methods 

=cut 

## Class methods
################

=head2 sub get_families(Robot $robot)

Returns the list of existing families in the Sympa installation.

=head3 Arguments 

=over 

=item * I<$robot>, the robot the family list of which we want to get.

=back 

=head3 Returns

=over 

=item * An arrayref containing all the robot's family names.

=back 

=cut

sub get_families {
    my $robot_id = shift;

    my @families;

    foreach my $dir (
        reverse @{Sympa::get_search_path($robot_id, subdir => 'families')}) {
        next unless -d $dir;

        unless (opendir FAMILIES, $dir) {
            $log->syslog('err', 'Can\'t open dir %s: %m', $dir);
            next;
        }

        # If we can create a Sympa::Family object with what we find in the
        # family directory, then it is worth being added to the list.
        foreach my $subdir (grep !/^\.\.?$/, readdir FAMILIES) {
            next unless -d ("$dir/$subdir");
            if (my $family = Sympa::Family->new($subdir, $robot_id)) {
                push @families, $family;
            }
        }
    }

    return \@families;
}

sub get_available_families {
    my $robot_id = shift;
    my $families;
    my %hash;
    if ($families = get_families($robot_id)) {
        foreach my $family (@$families) {
            if (ref $family eq 'Sympa::Family') {
                $hash{$family->{'name'}} = $family;
            }
        }
        return %hash;
    } else {
        return undef;
    }
}

=head1 Instance methods 

=cut 

## Instance methods
###################

=pod 

=head2 sub new(STRING $name, STRING $robot)

Creates a new Sympa::Family object of name $name, belonging to the robot $robot.

=head3 Arguments 

=over 

=item * I<$class>, the class in which we're supposed to create the object (namely "Sympa::Family"),

=item * I<$name>, a character string containing the family name,

=item * I<$robot>, a character string containing the name of the robot which the family is/will be installed in.

=back 

=head3 Return 

=over 

=item * I<$self>, the Sympa::Family object 

=back 

=cut

#########################################
# new
#########################################
# constructor of the class Sympa::Family :
#   check family existence (required files
#   and directory)
#
# IN : -$class
#      -$name : family name
#      -robot : family robot
# OUT : -$self
#########################################
sub new {
    my $class = shift;
    my $name  = shift;
    my $robot = shift;
    $log->syslog('debug2', '(%s, %s)', $name, $robot);

    my $self = {};

    if ($list_of_families{$robot}{$name}) {
        # use the current family in memory and update it
        $self = $list_of_families{$robot}{$name};
###########
        # the robot can be different from latest new ...
        if ($robot eq $self->{'robot'}) {
            return $self;
        } else {
            $self = {};
        }
    }
    # create a new object family
    bless $self, $class;
    $list_of_families{$robot}{$name} = $self;

    my $family_name_regexp = Sympa::Regexps::family_name();

    ## family name
    unless ($name && ($name =~ /^$family_name_regexp$/io)) {
        $log->syslog('err', 'Incorrect family name "%s"', $name);
        return undef;
    }

    ## Lowercase the family name.
    $name =~ tr/A-Z/a-z/;
    $self->{'name'} = $name;

    $self->{'robot'} = $robot;

    ## Adding configuration related to automatic lists.
    my $all_families_config =
        Conf::get_robot_conf($robot, 'automatic_list_families');
    my $family_config = $all_families_config->{$name};
    foreach my $key (keys %{$family_config}) {
        $self->{$key} = $family_config->{$key};
    }

    ## family directory
    $self->{'dir'} = $self->_get_directory();
    unless (defined $self->{'dir'}) {
        $log->syslog('err', '(%s, %s) The family directory does not exist',
            $name, $robot);
        return undef;
    }

    ## family files
    if (my $file_names = $self->_check_mandatory_files()) {
        $log->syslog('err',
            '(%s, %s) Definition family files are missing: %s',
            $name, $robot, $file_names);
        return undef;
    }

    ## file mtime
    $self->{'mtime'}{'param_constraint_conf'} = undef;

    ## hash of parameters constraint
    $self->{'param_constraint_conf'} = undef;

    ## state of the family for the use of check_param_constraint : 'no_check'
    ## or 'normal'
    ## check_param_constraint  only works in state "normal"
    $self->{'state'} = 'normal';
    return $self;
}

# Merged to: Sympa::Request::Handler::create_automatic_list::_twist().
#sub add_list;

# Deprecated.  Use sympa.pl --modify_list.
#sub modify_list;

# Old name: Sympa::Admin::update_list().
# Moved: Use Sympa::Request::Handler::update_automatic_list handler.
#sub _update_list;

# Deprecated.  Use sympa.pl --close_family.
#sub close_family;

=pod 

=head2 sub instantiate(FILEHANDLE $fh, [ close_unknown =E<gt> 1 ] )

Creates family lists or updates them if they exist already.

=head3 Arguments 

=over 

=item * I<$self>, the Sympa::Family object corresponding to the family to create / update

=back 

=head3 Return 

=over 

=item * I<$string>, a character string containing a message to display describing the results of the sub,

=item * I<$fh>, a file handle on the B<family> XML file,

=item * I<$close_unknown>: if true, the function will close old lists undefined in the new instantiation.

=back 

=cut

#########################################
# instantiate
#########################################
# instantiate family action :
#  - create family lists if they are not
#  - update family lists if they already exist
#
# IN : -$self
#      -$xml_fh : file handle on the xml file
#      -%options
#        - close_unknown : true if must close old lists undefined in new
#                          instantiation
# OUT : -1 or undef
#########################################
sub instantiate {
    $log->syslog('debug2', '(%s, %s, ...)', @_);
    my $self     = shift;
    my $xml_file = shift;
    my %options  = @_;

    ## all the description variables are emptied.
    $self->_initialize_instantiation();

    ## set impossible checking (used by list->load)
    $self->{'state'} = 'no_check';

    ## get the currently existing lists in the family
    my $previous_family_lists =
        {(map { $_->{name} => $_ } @{Sympa::List::get_lists($self) || []})};

    ## Splits the family description XML file into a set of list description
    ## xml files
    ## and collects lists to be created in $list_to_generate.
    my $list_to_generate = $self->_split_xml_file($xml_file);
    unless ($list_to_generate) {
        $log->syslog('err', 'Errors during the parsing of family xml file');
        return undef;
    }

    my $created = 0;
    my $total;
    my $progress;
    unless (@$list_to_generate) {
        $log->syslog('err', 'No list found in XML file %s.', $xml_file);
        $total = 0;
    } else {
        $total    = scalar @$list_to_generate;
        $progress = Term::ProgressBar->new(
            {   name  => 'Creating lists',
                count => $total,
                ETA   => 'linear'
            }
        );
        $progress->max_update_rate(1);
    }
    my $next_update = 0;

    # EACH FAMILY LIST
    foreach my $listname (@$list_to_generate) {
        my $path = $self->{'dir'} . '/' . $listname . '.xml';
        my $list = Sympa::List->new($listname, $self->{'robot'});

        if ($list) {
            ## LIST ALREADY EXISTING
            delete $previous_family_lists->{$list->{'name'}};

            # Update list config.
            my $spindle = Sympa::Spindle::ProcessRequest->new(
                context          => $self,
                action           => 'update_automatic_list',
                parameters       => {file => $path},
                sender           => Sympa::get_address($self, 'listmaster'),
                scenario_context => {skip => 1},
            );
            unless ($spindle and $spindle->spin and $spindle->success) {
                push(@{$self->{'errors'}{'update_list'}}, $list->{'name'});
                $list->set_status_error_config('instantiation_family',
                    $self->{'name'});
                next;
            }
        } else {
            # FIRST LIST CREATION

            ## Create the list
            my $spindle = Sympa::Spindle::ProcessRequest->new(
                context          => $self,
                action           => 'create_automatic_list',
                listname         => $listname,
                parameters       => {file => $path},
                sender           => Sympa::get_address($self, 'listmaster'),
                scenario_context => {skip => 1},
            );
            unless ($spindle and $spindle->spin and $spindle->success) {
                push @{$self->{'errors'}{'create_list'}}, $listname;
                next;
            }

            $list = Sympa::List->new($listname, $self->{'robot'});

            ## aliases
            if (grep { $_->[1] eq 'notice' and $_->[2] eq 'auto_aliases' }
                @{$spindle->{stash} || []}) {
                push(
                    @{$self->{'created_lists'}{'with_aliases'}},
                    $list->{'name'}
                );
            } else {
                $self->{'created_lists'}{'without_aliases'}{$list->{'name'}}
                    = $list->{'name'};
            }
        }

        $created++;
        $progress->message(
            sprintf(
                "List \"%s\" (%i/%i) created/updated",
                $list->{'name'}, $created, $total
            )
        );
        $next_update = $progress->update($created)
            if ($created > $next_update);
    }

    $progress->update($total) if $progress;

    ## PREVIOUS LIST LEFT
    foreach my $l (keys %{$previous_family_lists}) {
        my $list;
        unless ($list = Sympa::List->new($l, $self->{'robot'})) {
            push(@{$self->{'errors'}{'previous_list'}}, $l);
            next;
        }

        my $answer;
        unless ($options{close_unknown}) {
            #while ($answer ne 'y' and $answer ne 'n') {
            print STDOUT
                "The list $l isn't defined in the new instantiation family, do you want to close it ? (y or n)";
            $answer = <STDIN>;
            chomp($answer);
            #######################
            $answer ||= 'y';
            #}
        }
        if ($options{close_unknown} or $answer eq 'y') {
            my $spindle = Sympa::Spindle::ProcessRequest->new(
                context          => $self->{'robot'},
                action           => 'close_list',
                current_list     => $list,
                sender           => Sympa::get_address($self, 'listmaster'),
                scenario_context => {skip => 1},
            );
            unless ($spindle and $spindle->spin and $spindle->success) {
                push @{$self->{'family_closed'}{'impossible'}},
                    $list->{'name'};
            }
            push(@{$self->{'family_closed'}{'ok'}}, $list->{'name'});

        } elsif (lc($answer) eq 'n') {
            next;
        } else {
            my $spindle = Sympa::Spindle::ProcessRequest->new(
                context      => $self,
                action       => 'update_automatic_list',
                current_list => $list,
                parameters   => {file => $list->{'dir'} . '/instance.xml'},
                sender       => Sympa::get_address($self, 'listmaster'),
                scenario_context => {skip => 1},
            );
            unless ($spindle and $spindle->spin and $spindle->success) {
                push(@{$self->{'errors'}{'update_list'}}, $list->{'name'});
                $list->set_status_error_config('instantiation_family',
                    $self->{'name'});
                next;
            }
        }
    }
    $self->{'state'} = 'normal';
    return 1;
}

=pod 

=head2 sub get_instantiation_results()

Returns a string with information summarizing the instantiation results.

=head3 Arguments 

=over 

=item * I<$self>, the Sympa::Family object.

=back 

=head3 Return 

=over 

=item * I<$string>, a character string containing a message to display.

=back 

=cut

#########################################
# get_instantiation_results
#########################################
# return a string of instantiation results
#
# IN : -$self
#
# OUT : -$string
#########################################
sub get_instantiation_results {
    my ($self, $result) = @_;
    $log->syslog('debug3', '(%s)', $self->{'name'});

    $result->{'errors'} = ();
    $result->{'warn'}   = ();
    $result->{'info'}   = ();
    my $string;

    unless ($#{$self->{'errors'}{'create_hash'}} < 0) {
        push(
            @{$result->{'errors'}},
            "\nImpossible list generation because errors in xml file for : \n  "
                . join(", ", @{$self->{'errors'}{'create_hash'}}) . "\n"
        );
    }

    unless ($#{$self->{'errors'}{'create_list'}} < 0) {
        push(
            @{$result->{'errors'}},
            "\nImpossible list creation for : \n  "
                . join(", ", @{$self->{'errors'}{'create_list'}}) . "\n"
        );
    }

    unless ($#{$self->{'errors'}{'listname_already_used'}} < 0) {
        push(
            @{$result->{'errors'}},
            "\nImpossible list creation because listname is already used (orphelan list or in another family) for : \n  "
                . join(", ", @{$self->{'errors'}{'listname_already_used'}})
                . "\n"
        );
    }

    unless ($#{$self->{'errors'}{'update_list'}} < 0) {
        push(
            @{$result->{'errors'}},
            "\nImpossible list updating for : \n  "
                . join(", ", @{$self->{'errors'}{'update_list'}}) . "\n"
        );
    }

    unless ($#{$self->{'errors'}{'previous_list'}} < 0) {
        push(
            @{$result->{'errors'}},
            "\nExisted lists from the lastest instantiation impossible to get and not anymore defined in the new instantiation : \n  "
                . join(", ", @{$self->{'errors'}{'previous_list'}}) . "\n"
        );
    }

    # $string .= "\n****************************************\n";

    unless ($#{$self->{'created_lists'}{'with_aliases'}} < 0) {
        push(
            @{$result->{'info'}},
            "\nThese lists have been created and aliases are ok :\n  "
                . join(", ", @{$self->{'created_lists'}{'with_aliases'}})
                . "\n"
        );
    }

    my $without_aliases = $self->{'created_lists'}{'without_aliases'};
    if (ref $without_aliases) {
        if (scalar %{$without_aliases}) {
            $string =
                "\nThese lists have been created but aliases need to be installed : \n";
            foreach my $l (keys %{$without_aliases}) {
                $string .= " $without_aliases->{$l}";
            }
            push(@{$result->{'warn'}}, $string . "\n");
        }
    }

    unless ($#{$self->{'updated_lists'}{'aliases_ok'}} < 0) {
        push(
            @{$result->{'info'}},
            "\nThese lists have been updated and aliases are ok :\n  "
                . join(", ", @{$self->{'updated_lists'}{'aliases_ok'}}) . "\n"
        );
    }

    my $aliases_to_install = $self->{'updated_lists'}{'aliases_to_install'};
    if (ref $aliases_to_install) {
        if (scalar %{$aliases_to_install}) {
            $string =
                "\nThese lists have been updated but aliases need to be installed : \n";
            foreach my $l (keys %{$aliases_to_install}) {
                $string .= " $aliases_to_install->{$l}";
            }
            push(@{$result->{'warn'}}, $string . "\n");
        }
    }

    my $aliases_to_remove = $self->{'updated_lists'}{'aliases_to_remove'};
    if (ref $aliases_to_remove) {
        if (scalar %{$aliases_to_remove}) {
            $string =
                "\nThese lists have been updated but aliases need to be removed : \n";
            foreach my $l (keys %{$aliases_to_remove}) {
                $string .= " $aliases_to_remove->{$l}";
            }
            push(@{$result->{'warn'}}, $string . "\n");
        }
    }

    # $string .= "\n****************************************\n";

    unless ($#{$self->{'generated_lists'}{'file_error'}} < 0) {
        push(
            @{$result->{'errors'}},
            "\nThese lists have been generated but they are in status error_config because of errors while creating list config files :\n  "
                . join(", ", @{$self->{'generated_lists'}{'file_error'}})
                . "\n"
        );
    }

    my $constraint_error = $self->{'generated_lists'}{'constraint_error'};
    if (ref $constraint_error) {
        if (scalar %{$constraint_error}) {
            $string =
                "\nThese lists have been generated but there are in status error_config because of errors on parameter constraint :\n";
            foreach my $l (keys %{$constraint_error}) {
                $string .= " $l : " . $constraint_error->{$l} . "\n";
            }
            push(@{$result->{'errors'}}, $string);
        }
    }

    # $string .= "\n****************************************\n";

    unless ($#{$self->{'family_closed'}{'ok'}} < 0) {
        push(
            @{$result->{'info'}},
            "\nThese lists don't belong anymore to the family, they are in status family_closed :\n  "
                . join(", ", @{$self->{'family_closed'}{'ok'}}) . "\n"
        );
    }

    unless ($#{$self->{'family_closed'}{'impossible'}} < 0) {
        push(
            @{$result->{'warn'}},
            "\nThese lists don't belong anymore to the family, but they can't be set in status family_closed :\n  "
                . join(", ", @{$self->{'family_closed'}{'impossible'}}) . "\n"
        );
    }

    unshift @{$result->{'errors'}},
        "\n********** ERRORS IN INSTANTIATION of $self->{'name'} FAMILY ********************\n"
        if ($#{$result->{'errors'}} > 0);
    unshift @{$result->{'warn'}},
        "\n********** WARNINGS IN INSTANTIATION of $self->{'name'} FAMILY ********************\n"
        if ($#{$result->{'warn'}} > 0);
    unshift @{$result->{'info'}},
        "\n\n******************************************************************************\n"
        . "\n******************** INSTANTIATION of $self->{'name'} FAMILY ********************\n"
        . "\n******************************************************************************\n\n";

    return $#{$result->{'errors'}};

}

=pod 

=head2 sub check_param_constraint(LIST $list)

Checks the parameter constraints taken from param_constraint.conf file for the List object $list.

=head3 Arguments 

=over 

=item * I<$self>, the Sympa::Family object

=item * I<$list>, a List object corresponding to the list to chek.

=back 

=head3 Return 

=over 

=item * I<1> if everything goes well,

=item * I<undef> if something goes wrong,

=item * I<\@error>, a ref on an array containing parameters conflicting with constraints.

=back 

=cut

#########################################
# check_param_constraint
#########################################
# check the parameter constraint from
# param_constraint.conf file, of the given
# list (constraint on param digest is only on days)
# (take care of $self->{'state'})
#
# IN  : -$self
#       -$list : ref on the list
# OUT : -1 (if ok) or
#        \@error (ref on array of parameters
#          in conflict with constraints) or
#        undef
#########################################
sub check_param_constraint {
    my $self = shift;
    my $list = shift;
    $log->syslog('debug2', '(%s, %s)', $self->{'name'}, $list->{'name'});

    if ($self->{'state'} and $self->{'state'} eq 'no_check') {
        # because called by load(called by new that is called by instantiate)
        # it is not yet the time to check param constraint,
        # it will be called later by instantiate
        return 1;
    }

    my @error;

    ## checking
    my $constraint = $self->get_constraints();
    unless (defined $constraint) {
        $log->syslog('err', '(%s, %s) Unable to get family constraints',
            $self->{'name'}, $list->{'name'});
        return undef;
    }
    foreach my $param (keys %{$constraint}) {
        my $constraint_value = $constraint->{$param};
        my $param_value;
        my $value_error;

        unless (defined $constraint_value) {
            $log->syslog(
                'err',
                'No value constraint on parameter %s in param_constraint.conf',
                $param
            );
            next;
        }

        $param_value = $list->get_param_value($param);

        # exception for uncompellable parameter
        foreach my $forbidden (@uncompellable_param) {
            if ($param eq $forbidden) {
                next;
            }
        }

        $value_error = $self->check_values($param_value, $constraint_value);

        if (ref($value_error)) {
            foreach my $v (@{$value_error}) {
                push(@error, $param);
                $log->syslog('err',
                    'Error constraint on parameter %s, value: %s',
                    $param, $v);
            }
        }
    }

    if (scalar @error) {
        return \@error;
    } else {
        return 1;
    }
}

=pod 

=head2 sub get_constraints()

Returns a hash containing the values found in the param_constraint.conf file.

=head3 Arguments 

=over 

=item * I<$self>, the Sympa::Family object

=back 

=head3 Return 

=over 

=item * I<$self->{'param_constraint_conf'}>, a hash containing the values found in the param_constraint.conf file.

=back 

=cut

#########################################
# get_constraints
#########################################
# return the hash constraint from
# param_constraint.conf file
#
# IN  : -$self
# OUT : -$self->{'param_constraint_conf'}
#########################################
sub get_constraints {
    my $self = shift;
    $log->syslog('debug3', '(%s)', $self->{'name'});

    ## load param_constraint.conf
    my $time_file =
        Sympa::Tools::File::get_mtime("$self->{'dir'}/param_constraint.conf");
    unless (defined($self->{'param_constraint_conf'})
        and $self->{'mtime'}{'param_constraint_conf'} >= $time_file) {
        $self->{'param_constraint_conf'} =
            $self->_load_param_constraint_conf();
        unless (defined $self->{'param_constraint_conf'}) {
            $log->syslog('err', 'Cannot load file param_constraint.conf');
            return undef;
        }
        $self->{'mtime'}{'param_constraint_conf'} = $time_file;
    }

    return $self->{'param_constraint_conf'};
}

=pod 

=head2 sub check_values(SCALAR $param_value, SCALAR $constraint_value)

Returns 0 if all the value(s) found in $param_value appear also in $constraint_value. Otherwise the function returns an array containing the unmatching values.

=head3 Arguments 

=over 

=item * I<$self>, the family

=item * I<$param_value>, a scalar or a ref to a list (which is also a scalar after all)

=item * I<$constraint_value>, a scalar or a ref to a list

=back 

=head3 Return 

=over 

=item * I<\@error>, a ref to an array containing the values in $param_value which don't match those in $constraint_value.

=back 

=cut

#########################################
# check_values
#########################################
# check the parameter value(s) with
# param_constraint value(s).
#
# IN  : -$self
#       -$param_value
#       -$constraint_value
# OUT : -\@error (ref on array of forbidden values)
#        or '0' for free parameters
#########################################
sub check_values {
    my ($self, $param_value, $constraint_value) = @_;
    $log->syslog('debug3', '');

    my @param_values;
    my @error;

    # just in case
    if ($constraint_value eq '0') {
        return [];
    }

    if (ref($param_value) eq 'ARRAY') {
        @param_values = @{$param_value};    # for multiple parameters
    } else {
        push @param_values, $param_value;    # for single parameters
    }

    foreach my $p_val (@param_values) {
        # multiple values
        if (ref($p_val) eq 'ARRAY') {

            foreach my $p (@{$p_val}) {
                ## controlled parameter
                if (ref($constraint_value) eq 'HASH') {
                    unless ($constraint_value->{$p}) {
                        push(@error, $p);
                    }
                    ## fixed parameter
                } else {
                    unless ($constraint_value eq $p) {
                        push(@error, $p);
                    }
                }
            }
            ## single value
        } else {
            ## controlled parameter
            if (ref($constraint_value) eq 'HASH') {
                unless ($constraint_value->{$p_val}) {
                    push(@error, $p_val);
                }
                ## fixed parameter
            } else {
                unless ($constraint_value eq $p_val) {
                    push(@error, $p_val);
                }
            }
        }
    }

    return \@error;
}

=pod 

=head2 sub get_param_constraint(STRING $param)

Gets the constraints on parameter $param from the 'param_constraint.conf' file.

=head3 Arguments 

=over 

=item * I<$self>, the Sympa::Family object

=item * I<$param>, a character string corresponding to the name of the parameter for which we want to gather constraints.

=back 

=head3 Return 

=over 

=item * I<0> if there are no constraints on the parameter,

=item * I<a scalar> containing the allowed value if the parameter has a fixed value,

=item * I<a ref to a hash> containing the allowed values if the parameter is controlled,

=item * I<undef> if something went wrong.

=back 

=cut

#########################################
# get_param_constraint
#########################################
# get the parameter constraint from
# param_constraint.conf file
#  (constraint on param digest is only on days)
#
# IN  : -$self
#       -$param : parameter requested
# OUT : -'0' if the parameter is free or
#        the parameter value if the
#          parameter is fixed or
#        a ref on a hash of possible parameter
#          values or
#        undef
#########################################
sub get_param_constraint {
    my $self  = shift;
    my $param = shift;
    $log->syslog('debug3', '(%s, %s)', $self->{'name'}, $param);

    unless (defined $self->get_constraints()) {
        return undef;
    }

    if (defined $self->{'param_constraint_conf'}{$param}) {
        ## fixed or controlled parameter
        return $self->{'param_constraint_conf'}{$param};

    } else {    ## free parameter
        return '0';
    }
}

# DEPRECATED: Use Sympa::List::get_lists($family).
#sub get_family_lists;

# DEPRECATED: Use Sympa::List::get_lists($family).
#sub get_hash_family_lists;

=head2 sub get_uncompellable_param()

Returns a reference to hash whose keys are the uncompellable parameters.

=head3 Arguments 

=over 

=item * I<none>

=back 

=head3 Return 

=over 

=item * I<\%list_of_param> a ref to a hash the keys of which are the uncompellable parameters names.

=back 

=cut

#########################################
# get_uncompellable_param
#########################################
# return the uncompellable parameters
#  into a hash
#
# IN  : -
# OUT : -\%list_of_param
#
#########################################
sub get_uncompellable_param {
    my %list_of_param;
    $log->syslog('debug3', '');

    foreach my $param (@uncompellable_param) {
        if ($param =~ /^([\w-]+)\.([\w-]+)$/) {
            $list_of_param{$1} = $2;

        } else {
            $list_of_param{$param} = '';
        }
    }

    return \%list_of_param;
}

=pod

=head1 Private methods

=cut

############################# PRIVATE METHODS ##############################

=pod 

=head2 sub _get_directory()

Gets the family directory, look for it in the robot, then in the site and finally in the distrib.

=head3 Arguments 

=over 

=item * I<$self>, the Sympa::Family object

=back 

=head3 Return 

=over 

=item * I<a string> containing the family directory name

=item * I<undef> if no directory is found.

=back 

=cut

#####################################################
# _get_directory
#####################################################
# get the family directory, look for it in the robot,
# then in the site and finally in the distrib
# IN :  -$self
# OUT : -directory name or
#        undef if the directory does not exist
#####################################################
sub _get_directory {
    my $self  = shift;
    my $robot = $self->{'robot'};
    my $name  = $self->{'name'};
    $log->syslog('debug3', '(%s)', $name);

    my @try = @{Sympa::get_search_path($robot, subdir => 'families')};

    foreach my $d (@try) {
        if (-d "$d/$name") {
            return "$d/$name";
        }
    }
    return undef;
}

=pod 

=head2 sub _check_mandatory_files()

Checks the existence of the mandatory files (param_constraint.conf and config.tt2) in the family directory.

=head3 Arguments 

=over 

=item * I<$self>, the family

=back 

=head3 Return 

=over 

=item * I<$string>, a character string containing the missing file(s)' name(s), separated by white spaces.

=item * I<0> if all the files are found.

=back 

=cut

#####################################################
# _check_mandatory_files
#####################################################
# check existence of mandatory files in the family
# directory:
#  - param_constraint.conf
#  - config.tt2
#
# IN  : -$self
# OUT : -0 (if OK) or
#        $string containing missing file names
#####################################################
sub _check_mandatory_files {
    my $self   = shift;
    my $dir    = $self->{'dir'};
    my $string = "";
    $log->syslog('debug3', '(%s)', $self->{'name'});

    foreach my $f ('config.tt2') {
        unless (-f "$dir/$f") {
            $string .= $f . " ";
        }
    }

    if ($string eq "") {
        return 0;
    } else {
        return $string;
    }
}

=pod 

=head2 sub _initialize_instantiation()

Initializes all the values used for instantiation and results description to empty values.

=head3 Arguments 

=over 

=item * I<$self>, the Sympa::Family object

=back 

=head3 Return 

=over 

=item * I<1>

=back 

=cut

#####################################################
# _initialize_instantiation
#####################################################
# initialize vars for instantiation and result
# then to make a string result
#
# IN  : -$self
# OUT : -1
#####################################################
sub _initialize_instantiation {
    my $self = shift;
    $log->syslog('debug3', '(%s)', $self->{'name'});

    ### info vars for instantiate  ###
    ### returned by                ###
    ### get_instantiation_results  ###

    ## lists in error during creation or updating : LIST FATAL ERROR
    # array of xml file name  : error during xml data extraction
    $self->{'errors'}{'create_hash'} = ();
    ## array of list name : error during list creation
    $self->{'errors'}{'create_list'} = ();
    ## array of list name : error during list updating
    $self->{'errors'}{'update_list'} = ();
    ## array of list name : listname already used (in another family)
    $self->{'errors'}{'listname_already_used'} = ();
    ## array of list name : previous list impossible to get
    $self->{'errors'}{'previous_list'} = ();

    ## created or updated lists
    ## array of list name : aliases are OK (installed or not, according to
    ## status)
    $self->{'created_lists'}{'with_aliases'} = ();
    ## hash of (list name -> aliases) : aliases needed to be installed
    $self->{'created_lists'}{'without_aliases'} = {};
    ## array of list name : aliases are OK (installed or not, according to
    ## status)
    $self->{'updated_lists'}{'aliases_ok'} = ();
    ## hash of (list name -> aliases) : aliases needed to be installed
    $self->{'updated_lists'}{'aliases_to_install'} = {};
    ## hash of (list name -> aliases) : aliases needed to be removed
    $self->{'updated_lists'}{'aliases_to_remove'} = {};

    ## generated (created or updated) lists in error : no fatal error for the
    ## list
    ## array of list name : error during copying files
    $self->{'generated_lists'}{'file_error'} = ();
    ## hash of (list name -> array of param) : family constraint error
    $self->{'generated_lists'}{'constraint_error'} = {};

    ## lists isn't anymore in the family
    ## array of list name : lists in status family_closed
    $self->{'family_closed'}{'ok'} = ();
    ## array of list name : lists that must be in status family_closed but
    ## they aren't
    $self->{'family_closed'}{'impossible'} = ();

    return 1;
}

=pod 

=head2 sub _split_xml_file(FILE_HANDLE $xml_fh)

Splits the XML family file into XML list files. New list names are put in the array reference and new files are put in the family directory.

=head3 Arguments 

=over 

=item * I<$self>, the Sympa::Family object

=item * I<$xml_fh>, a handle to the XML B<family> description file.

=back 

=head3 Return 

=over 

=item * I<1> if everything goes well

=item * I<0> if something goes wrong

=back 

=cut

#####################################################
# _split_xml_file
#####################################################
# split the xml family file into xml list files. New
# list names are put in the array reference
# and new files are put in
# the family directory
#
# IN : -$self
#      -$xml_fh : file handle on xml file containing description
#               of the family lists
# OUT : -1 (if OK) or undef
#####################################################
sub _split_xml_file {
    my $self     = shift;
    my $xml_file = shift;
    my $root;
    $log->syslog('debug2', '(%s)', $self->{'name'});

    ## parse file
    my $parser = XML::LibXML->new();
    $parser->line_numbers(1);
    my $doc;

    unless ($doc = $parser->parse_file($xml_file)) {
        $log->syslog('err', 'Failed to parse XML file');
        return undef;
    }

    ## the family document
    $root = $doc->documentElement();
    unless ($root->nodeName eq 'family') {
        $log->syslog('err',
            "Sympa::Family::_split_xml_file() : the root element must be called \"family\" "
        );
        return undef;
    }

    # Lists: Family's elements.
    my @list_to_generate;
    foreach my $list_elt ($root->childNodes()) {

        if ($list_elt->nodeType == 1) {    # ELEMENT_NODE
            unless ($list_elt->nodeName eq 'list') {
                $log->syslog(
                    'err',
                    'Elements contained in the root element must be called "list", line %s',
                    $list_elt->line_number()
                );
                return undef;
            }
        } else {
            next;
        }

        ## listname
        my @children = $list_elt->getChildrenByTagName('listname');

        if ($#children < 0) {
            $log->syslog(
                'err',
                '"listname" element is required in "list" element, line: %s',
                $list_elt->line_number()
            );
            return undef;
        }
        if ($#children > 0) {
            my @error;
            foreach my $i (@children) {
                push(@error, $i->line_number());
            }
            $log->syslog(
                'err',
                'Only one "listname" element is allowed for "list" element, lines: %s',
                join(", ", @error)
            );
            return undef;
        }
        my $listname_elt = shift @children;
        my $listname     = $listname_elt->textContent();
        $listname =~ s/^\s*//;
        $listname =~ s/\s*$//;
        $listname = lc $listname;
        my $filename = $listname . ".xml";

        ## creating list XML document
        my $list_doc =
            XML::LibXML::Document->createDocument($doc->version(),
            $doc->encoding());
        $list_doc->setDocumentElement($list_elt);

        ## creating the list xml file
        unless ($list_doc->toFile("$self->{'dir'}/$filename", 0)) {
            $log->syslog(
                'err',
                'Cannot create list file %s',
                $self->{'dir'} . '/' . $filename,
                $list_elt->line_number()
            );
            return undef;
        }

        push @list_to_generate, $listname;
    }
    return [@list_to_generate];
}

# Deprecated. No longer used.
#sub _update_existing_list;

# Moved:
# Use Sympa::Request::Handler::update_automatic_list::_get_customizing().
#sub _get_customizing;

# No longer used.
#sub _set_status_changes;

# Moved to part of: Sympa::Request::Handler::update_automatic_list::_twist().
#sub _end_update_list;

# No longer used.
#sub _copy_files;

=pod 

=head2 sub _load_param_constraint_conf()

Loads the param_constraint.conf file into a hash

=head3 Arguments 

=over 

=item * I<$self>, the Sympa::Family object

=back 

=head3 Return 

=over 

=item * I<$constraint>, a ref to a hash containing the data found in param_constraint.conf

=item * I<undef> if something went wrong

=back 

=cut

#########################################
# _load_param_constraint_conf()
#########################################
# load the param_constraint.conf file in
# a hash
#
# IN :  -$self
# OUT : -$constraint : ref on a hash or undef
#########################################
sub _load_param_constraint_conf {
    my $self = shift;
    $log->syslog('debug2', '(%s)', $self->{'name'});

    my $file = "$self->{'dir'}/param_constraint.conf";

    my $constraint = {};

    unless (-e $file) {
        $log->syslog('err', 'No file %s. Assuming no constraints to apply',
            $file);
        return $constraint;
    }

    unless (open(FILE, $file)) {
        $log->syslog('err', 'File %s exists, but unable to open it: %m',
            $file);
        return undef;
    }

    my $error = 0;

    ## Just in case...
    local $RS = "\n";

    while (<FILE>) {
        next if /^\s*(\#.*|\s*)$/;

        if (/^\s*([\w\-\.]+)\s+(.+)\s*$/) {
            my $param  = $1;
            my $value  = $2;
            my @values = split /,/, $value;

            unless (($param =~ /^([\w-]+)\.([\w-]+)$/)
                || ($param =~ /^([\w-]+)$/)) {
                $log->syslog('err', '(%s) Unknown parameter "%s" in %s',
                    $self->{'name'}, $_, $file);
                $error = 1;
                next;
            }

            if (scalar(@values) == 1) {
                $constraint->{$param} = shift @values;
            } else {
                foreach my $v (@values) {
                    $constraint->{$param}{$v} = 1;
                }
            }
        } else {
            $log->syslog('err', '(%s) Bad line: %s in %s',
                $self->{'name'}, $_, $file);
            $error = 1;
            next;
        }
    }
    if ($error) {
        Sympa::send_notify_to_listmaster($self->{'robot'},
            'param_constraint_conf_error', [$file]);
    }
    close FILE;

    # Parameters not allowed in param_constraint.conf file :
    foreach my $forbidden (@uncompellable_param) {
        if (defined $constraint->{$forbidden}) {
            delete $constraint->{$forbidden};
        }
    }

    return $constraint;
}

#Deprecated. Use Sympa::Request::Handler::create_automatic_list request handler.
#sub create_automatic_list;

# Returns 1 if the user is allowed to create lists based on the family.
#Deprecated. Use Sympa::Request::Handler::create_automatic_list request handler.
#sub is_allowed_to_create_automatic_lists;

## Handle exclusion table for family
sub insert_delete_exclusion {
    $log->syslog('debug2', '(%s, %s, %s)', @_);
    my $self   = shift;
    my $email  = shift;
    my $action = shift;

    my $name     = $self->{'name'};
    my $robot_id = $self->{'robot'};

    if ($action eq 'insert') {
        ##FXIME: Check if user belong to any list of family
        my $date = time;

        ## Insert: family, user and date
        ## Add dummy list_exclusion column to satisfy constraint.
        my $sdm;
        unless (
            $sdm = Sympa::DatabaseManager->instance
            and $sdm->do_prepared_query(
                q{INSERT INTO exclusion_table
                  (list_exclusion, family_exclusion, robot_exclusion,
                   user_exclusion, date_exclusion)
                  VALUES (?, ?, ?, ?, ?)},
                sprintf('family:%s', $name), $name, $robot_id, $email, $date
            )
        ) {
            $log->syslog('err', 'Unable to exclude user %s from family %s',
                $email, $self);
            return undef;
        }
        return 1;
    } elsif ($action eq 'delete') {
        ##FIXME: Not implemented yet.
        return undef;
    } else {
        $log->syslog('err', 'Unknown action %s', $action);
        return undef;
    }

    return 1;
}

sub get_id {
    my $self = shift;

    return '' unless $self->{'name'} and $self->{'robot'};
    return $self->{'name'} . '@' . $self->{'robot'};
}

1;
__END__

=encoding utf-8

=head1 AUTHORS 

=over 

=item * Serge Aumont <sa AT cru.fr> 

=item * Olivier Salaun <os AT cru.fr> 

=back 

=cut
