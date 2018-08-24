# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
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

package Sympa::List::Config;

use strict;
use warnings;

use Conf;
use Sympa::Log;
use Sympa::Robot;

use base qw(Sympa::Config);

my $log = Sympa::Log->instance;

sub new {
    my $class   = shift;
    my $context = shift;
    my %options = @_;

    die 'bug in logic. Ask developer' unless ref $context eq 'Sympa::List';
    $class->SUPER::new($context, %options);
}

sub _schema {
    my $self = shift;

    my $list = $self->{context};
    return Sympa::Robot::list_params($list->{'domain'});
}

sub _init_schema_item {
    my $self    = shift;
    my $pitem   = shift;
    my $pnames  = shift;
    my $subres  = shift;
    my %options = @_;

    if (ref $pitem->{format} ne 'HASH' and exists $pitem->{default}) {
        my $list    = $self->{context};
        my $default = $pitem->{default};

        if (ref $default eq 'HASH' and exists $default->{conf}) {
            $pitem->{default} =
                Conf::get_robot_conf($list->{'domain'}, $default->{conf});
        }
    }

    $self->SUPER::_init_schema_item($pitem, $pnames, $subres, %options);

    return undef if $options{no_family};
    my $family = $self->{context}->get_family;
    return undef unless ref $family eq 'Sympa::Family';

    if (ref $pitem->{format} eq 'HASH') {
        if ($subres and grep {$_} values %$subres) {
            return 'constrained';
        }
    } else {
        my $constraint = $family->get_param_constraint(join '.', @$pnames);
        my @constr;
        unless (defined $constraint) {    # Error
            return undef;
        } elsif (ref $constraint eq 'ARRAY') {    # Multiple choices
            @constr = @$constraint;
        } elsif ($constraint ne '0') {            # Fixed value
            @constr = ($constraint);
        } else {                                  # No control
            return undef;
        }

        if (ref $pitem->{format} eq 'ARRAY') {
            @constr = grep {
                my $k = $_;
                grep { $k eq $_ } @constr
            } @{$pitem->{format}};
        } else {
            my $re = $pitem->{format};
            @constr = grep {/^($re)$/} @constr;
        }

        if (@constr) {
            if (ref $pitem->{format} eq 'ARRAY') {
                $pitem->{format} = [@constr];
            } else {
                $pitem->{format} = join '|', map { quotemeta $_ } @constr;
            }

            if ($pitem->{occurrence} eq '0-n') {
                $pitem->{occurrence} = '1-n';
            } elsif ($pitem->{occurrence} eq '0-1') {
                $pitem->{occurrence} = '1';
            }

            if (1 == scalar @constr) {
                if ($pitem->{occurrence} =~ /n$/) {
                    $pitem->{default} = [@constr];
                } elsif ($pitem->{scenario} or $pitem->{task}) {
                    $pitem->{default} = {name => $constr[0]};
                } else {
                    $pitem->{default} = $constr[0];
                }
                # Choose more restrictive privilege.
                # See also _get_schema_apply_privilege().
                $pitem->{privilege} = 'read'
                    if not $pitem->{privilege}
                    or 'read' lt $pitem->{privilege};
            } elsif (exists $pitem->{default} and defined $pitem->{default}) {
                delete $pitem->{default}
                    unless grep { $pitem->{default} eq $_ } @constr;
            }
            return 'constrained';
        }
    }

    return undef;
}

sub get_schema {
    my $self = shift;
    my $user = shift;

    my $pinfo = $self->SUPER::get_schema;
    if ($user) {
        foreach my $pname (CORE::keys %{$pinfo || {}}) {
            $self->_get_schema_apply_privilege($pinfo->{$pname}, [$pname],
                $user, undef);
        }
    }
    $pinfo;
}

# Apply privilege on each parameter.
sub _get_schema_apply_privilege {
    my $self   = shift;
    my $pitem  = shift;
    my $pnames = shift;
    my $user   = shift;
    my $priv_p = shift;

    my $list = $self->{context};

    # Choose most restrictive privilege.
    # - Trick: "hidden", "read" and "write" precede others in reverse
    #   dictionary order.
    # - Internal parameters are not editable anyway.
    my $priv = $list->may_edit(join('.', @{$pnames || []}), $user);
    $priv = 'read'
        if $pitem->{internal}
        and (not $priv or 'read' lt $priv);
    $priv = $priv_p
        if not $priv
        or ($priv_p and $priv_p lt $priv);
    $pitem->{privilege} = $priv
        if not $pitem->{privilege}
        or ($priv and $priv lt $pitem->{privilege});
    $pitem->{privilege} ||= 'hidden';    # Implicit default

    if (ref $pitem->{format} eq 'HASH') {
        foreach my $key (CORE::keys %{$pitem->{format} || {}}) {
            $self->_get_schema_apply_privilege(
                $pitem->{format}->{$key},
                [@$pnames, $key],
                $user, $pitem->{privilege}
            );
        }
    }
}

use constant _local_validations => {
    # Checking no topic named "other".
    reserved_msg_topic_name => sub {
        my $self = shift;
        my $new  = shift;

        return 'topic_other'
            if lc $new eq 'other';
    },
};

sub commit {
    my $self = shift;
    my $errors = shift || [];

    my $list    = $self->{context};
    my $changes = $self->{_changes};
    my $pinfo   = $self->{_pinfo};

    # Updating config_changes for changed parameters.
    # FIXME:Check subitems also.
    if (ref($list->get_family) eq 'Sympa::Family') {
        unless (
            $list->update_config_changes(
                'param', [CORE::keys %{$changes || {}}]
            )
        ) {
            push @$errors, ['intern', 'update_config_changes'];
            return undef;
        }
    }

    $self->SUPER::commit($errors);
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::List::Config - List configuration

=head1 SYNOPSIS

  use Sympa::List::Config;
  my $config = Sympa::List::Config->new($list, {...});
 
  my $errors = []; 
  my $validity = $config->submit({...}, $user, $errors);
  $config->commit($errors);
  
  my ($value) = $config->get('owner.0.gecos');
  my @keys  = $config->keys('owner');

=head1 DESCRIPTION

=head2 Methods

=over

=item new ( $list, [ config =E<gt> $initial_config ], [ copy =E<gt> 1 ],
[ no_family =E<gt> 1 ] )

I<Constructor>.
Creates new instance of L<Sympa::List::Config> object.

Parameters:

See also L<Sympa::Config/new>.

=over

=item $list

Context.  An instance of L<Sympa::List> class.

=item no_family =E<gt> 1

Won't apply family constraint.
By default, the constraint will be applied if the list is belonging to
family.
See also L</"Family constraint">.

=back

=item get_schema ( [ $user ] )

I<Instance method>.
Get configuration schema as hashref.
See L<Sympa::ListDef> about structure of schema.

Parameter:

=over

=item $user

Email address of a user.
If specified, adds C<'privilege'> attribute taken from L<edit_list.conf(5)>
for the user.

=back

=back

=head2 Attribute

See L<Sympa::Config/Attribute>.

=head2 Family constraint

The family (see L<Sympa::Family>) adds additional constraint to schema.

=over

=item *

restricts options for particular scalar parameters to the set of values
or single value,

=item *

makes occurrence of them be required (C<'1'> or C<'1-n'>), and

=item *

if the occurrence became C<'1'>,
makes their privilege be unwritable (C<'read'> if it was not C<'hidden'>).

=back

=head2 Filters

TBD.

=head2 Validations

TBD.

=head1 SEE ALSO

L<Sympa::Config>,
L<Sympa::List>,
L<Sympa::ListDef>.

=head1 HISTORY

L<Sympa::List::Config> appeared on Sympa 6.2.17.

=cut

