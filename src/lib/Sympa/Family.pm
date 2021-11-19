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

package Sympa::Family;

use strict;
use warnings;
use English qw(-no_match_vars);

use Sympa;
use Conf;
use Sympa::DatabaseManager;
use Sympa::Log;
use Sympa::Regexps;
use Sympa::Tools::File;

my $log = Sympa::Log->instance;

my %list_of_families;
my @uncompellable_param = (
    'msg_topic.keywords',
    'owner_include.source_parameters',
    'editor_include.source_parameters'
);

sub get_families {
    my $robot_id = shift;

    my @families;

    foreach my $dir (
        reverse @{Sympa::get_search_path($robot_id, subdir => 'families')}) {
        next unless -d $dir;

        my $dh;
        unless (opendir $dh, $dir) {
            $log->syslog('err', 'Can\'t open dir %s: %m', $dir);
            next;
        }

        # If we can create a Sympa::Family object with what we find in the
        # family directory, then it is worth being added to the list.
        foreach my $subdir (grep { !/^\.\.?$/ } readdir $dh) {
            next unless -d ("$dir/$subdir");
            if (my $family = Sympa::Family->new($subdir, $robot_id)) {
                push @families, $family;
            }
        }

        closedir $dh;
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
        if ($robot eq $self->{'domain'}) {
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
    $self->{'name'}   = $name;
    $self->{'domain'} = $robot;

    $self->{'robot'} = $self->{'domain'};    # Compat.<=6.2.52

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

# Moved to: instantiate() in sympa.pl.
#sub instantiate;

# moved to: get_instantiation_results() in sympa.pl.
#sub get_instantiation_results;

sub check_param_constraint {
    $log->syslog('debug2', '(%s, %s)', @_);
    my $self = shift;
    my $list = shift;

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

# Gets the family directory, look for it in the robot, then in the site and
# finally in the distrib.
# OUT : -directory name or undef if the directory does not exist
sub _get_directory {
    $log->syslog('debug3', '(%s)', @_);
    my $self = shift;

    my $name  = $self->{'name'};
    my $robot = $self->{'domain'};

    my @try = @{Sympa::get_search_path($robot, subdir => 'families')};

    foreach my $d (@try) {
        if (-d "$d/$name") {
            return "$d/$name";
        }
    }
    return undef;
}

# Checks the existence of the mandatory files (param_constraint.conf and
# config.tt2) in the family directory.
# OUT : -0 (if OK) or $string containing missing file names
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

# Moved to: _initialize_instantiation() in sympa.pl.
#sub _initialize_instantiation;

# Moved to: _split_xml_file() in sympa.pl.
#sub _split_xml_file;

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

# Loads the param_constraint.conf file in a hash.
# OUT : -$constraint : ref on a hash or undef
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

    my $ifh;
    unless (open $ifh, '<', $file) {
        $log->syslog('err', 'File %s exists, but unable to open it: %m',
            $file);
        return undef;
    }

    my $error = 0;

    ## Just in case...
    local $RS = "\n";

    while (<$ifh>) {
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
        Sympa::send_notify_to_listmaster($self->{'domain'},
            'param_constraint_conf_error', [$file]);
    }
    close $ifh;

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
    my $robot_id = $self->{'domain'};

    if ($action eq 'insert') {
        ##FXIME: Check if user belong to any list of family
        my $date = time;

        ## Insert: family, user and date
        ## Add dummy list_exclusion column to satisfy constraint.
        my $sdm = Sympa::DatabaseManager->instance;
        unless (
            $sdm
            and $sdm->do_prepared_query(
                q{INSERT INTO exclusion_table
                  (list_exclusion, family_exclusion, robot_exclusion,
                   user_exclusion, date_exclusion)
                  SELECT ?, ?, ?, ?, ?
                  FROM dual
                  WHERE NOT EXISTS (
                    SELECT 1
                    FROM exclusion_table
                    WHERE family_exclusion = ? AND robot_exclusion = ? AND
                          user_exclusion = ?
                  )},
                sprintf('family:%s', $name), $name, $robot_id, $email, $date,
                $name, $robot_id, $email
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

    return '' unless $self->{'name'} and $self->{'domain'};
    return sprintf '%s@%s', $self->{'name'}, $self->{'domain'};
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Family - List families

=head1 DESCRIPTION

Sympa allows lists creation and management by sets. These are the families,
sets of lists sharing common properties.
This module gathers all the family-specific operations.

=head2 Functions

=over

=item get_families ( $robot )

I<Function>.
Returns the list of existing families in the Sympa installation.

Arguments

=over

=item $robot

The robot the family list of which we want to get.

=back

Returns

An arrayref containing all the robot's family names.

=item get_available_families ( $robot )

I<Function>.
B<Obsoleted>.
Use C<get_families()>.

=back

=head2 Methods

=over

=item new (STRING $name, STRING $robot)

I<Constructor>.
Creates a new Sympa::Family object of name $name, belonging to the robot $robot.

Arguments

=over

=item $name

A character string containing the family name,

=item $robot

A character string containing the name of the robot which the family is/will
be installed in.

=back

Returns

The L<Sympa::Family> object.

=item check_param_constraint (LIST $list)

I<Instance method>.
Checks the parameter constraints taken from param_constraint.conf file for
the L<Sympa::List> object $list.

Arguments

=over

=item $list

A List object corresponding to the list to chek.

=back

Returns

=over

=item *

I<1> if everything goes well,

=item *

I<undef> if something goes wrong,

=item *

I<\@error>, a ref on an array containing parameters conflicting with constraints.

=back

=item get_constraints ()

I<Instance method>.
Returns a hash containing the values found in the param_constraint.conf file.

Arguments

None.

Returns

C<$self-E<gt>{'param_constraint_conf'}>,
a hash containing the values found in the param_constraint.conf file.

=item check_values (SCALAR $param_value, SCALAR $constraint_value)

I<Instance method>.
Returns 0 if all the value(s) found in $param_value appear also in
$constraint_value.
Otherwise the function returns an array containing the unmatching values.

Arguments

=over

=item $param_value

A scalar or a ref to a list (which is also a scalar after all)

=item $constraint_value

A scalar or a ref to a list

=back

Returns

I<\@error>, a ref to an array containing the values in $param_value
which don't match those in $constraint_value.

=item get_param_constraint (STRING $param)

I<Instance method>.
Gets the constraints on parameter $param from the 'param_constraint.conf' file.

Arguments

=over

=item $param

A character string corresponding to the name of the parameter
for which we want to gather constraints.

=back

Returns

=over

=item * I<0> if there are no constraints on the parameter,

=item * I<a scalar> containing the allowed value if the parameter has a fixed value,

=item * I<a ref to a hash> containing the allowed values if the parameter is controlled,

=item * I<undef> if something went wrong.

=back

=item get_uncompellable_param ()

I<Instance method>.
Returns a reference to hash whose keys are the uncompellable parameters.

Arguments

None.

Returns

C<\%list_of_param>, a ref to a hash the keys of which are the
uncompellable parameters names.


=item insert_delete_exclusion ( $email, $action )

I<Instance method>.
Handle exclusion table for family.
TBD.

=item get_id ( )

I<Instance method>.
Gets unique identifier of instance.

=back

=head2 Attributes

=over

=item {name}

The name of family.

=item {domain}

The mail domain (a.k.a. "robot") the family belongs to.

B<Note>:
On Sympa 6.2.52 or earlier, C<{robot}> was used.

=item {dir}

Base dire4ctory of the family.

=item {state}

Obsoleted.
TBD.

=back

=head1 SEE ALSO

L<Sympa::List>,
L<Sympa::Request::Handler::close_list>,
L<Sympa::Request::Handler::create_automatic_list>,
L<Sympa::Request::Handler::update_automatic_list>.

L<sympa_automatic(8)>.

L<List families|https://sympa-community.github.io/manual/customize/basics-families.html>, I<Sympa Administration Manual>.

=head1 HISTORY

L<Family> module was initially written by:

=over

=item * Serge Aumont <sa AT cru.fr>

=item * Olivier Salaun <os AT cru.fr>

=back

Renamed L<Sympa::Family> appeared on Sympa 6.2a.39.
Afterward, it has been gradually rewritten,
therefore L<Sympa::Request::Handler::close_list>,
L<Sympa::Request::Handler::create_automatic_list> and
L<Sympa::Request::Handler::update_automatic_list> were separated
up till Sympa 6.2.49b.

=cut
