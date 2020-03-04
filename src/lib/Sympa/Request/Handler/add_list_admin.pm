# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright 2019 The Sympa Community. See the AUTHORS.md file at the top-level
# directory of this distribution and at
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

package Sympa::Request::Handler::add_list_admin;

use strict;
use warnings;
use Data::Dumper;

use Sympa;
use Sympa::List;
use Sympa::Log;
use Sympa::Robot;
use Sympa::Tools::Text;

use base qw(Sympa::Request::Handler);

my $log = Sympa::Log->instance;

use constant _action_scenario => undef; # Only privileged owners and listmasters allowed.
use constant _context_class   => 'Sympa::List';

sub _twist {
    my $self    = shift;
    my $request = shift;

    my $list    = $request->{context};
    my $listname   = $list->{'name'};
    my $robot   = $list->{'domain'};
    my $role = $request->{role};
    my $sender = $request->{sender};
    my $updater_user = $sender || Sympa::get_address($list, 'listmaster');
    my $user;
    $user->{email} = Sympa::Tools::Text::canonic_email($request->{email});
    $user->{visibility} = $request->{visibility};
    $user->{profile} = $request->{profile};
    $user->{reception} = $request->{reception};
    $user->{gecos} = $request->{gecos};
    $user->{info} = $request->{info};

    my %mandatory_parameters = (
        email => $user->{email},
        role  => $role,
    );
    
    my @missing_parameters;
    foreach my $mandatory_param (keys %mandatory_parameters) {
        unless ($mandatory_parameters{$mandatory_param}) {
            push @missing_parameters, $mandatory_param;
        }
    }
    
    if( scalar @missing_parameters) {
        $log->syslog('err', 'Trying to add list admin without giving %s.', join (', ', @missing_parameters));
        $self->add_stash(
            $request, 'user', 'missing_parameters',
            {p_name => join ', ', @missing_parameters}
        );
        return undef;
    }
    
    unless ($role eq 'owner' or $role eq 'editor') {
        $self->add_stash(
            $request, 'user', 'syntax_errors',
            {p_name => 'role'}
        );
        $log->syslog('err', 'Error while adding %s as %s to list %s@%s. Bad parameter(s): %s',
            $user->{email}, $role, $listname, $robot, 'role');
        return undef;
    }
    
    if ($role eq 'editor') {
        delete $user->{profile} if $user->{profile};
    }
    my $schema = $Sympa::ListDef::user_info{$role};
    my @param_in_error;
    foreach my $param (keys %{$schema->{format}}) {
        if ($user->{$param}) {
            unless($user->{$param} =~ /$schema->{format}{$param}{file_format}/) {
                push @param_in_error, $param;
            }
        }
    }
     if (scalar @param_in_error) {
        $self->add_stash(
            $request, 'user', 'syntax_errors',
            {p_name => join ', ', @param_in_error}
        );
        $log->syslog('err', 'Error while adding %s as %s to list %s@%s. Bad parameter(s): %s',
            $user->{email}, $role, $listname, $robot, join ', ', @param_in_error);
        return undef;
     }
    # Check if user is already admin of the list.
    if ($list->is_admin($role, $user->{email})) {
        $self->add_stash(
            $request, 'user',
            'already_list_admin',
            {email => $user->{email}, role => $role, listname => $list->{'name'}}
        );
        $log->syslog('err', 'User "%s" has the role "%s" in list "%s@%s" already',
            $user->{email}, $role, $listname, $robot);
        return undef;
    } else {
        unless ($list->add_list_admin($role, $user)) {
            $self->add_stash(
                $request, 'user',
                'list_admin_addition_failed',
                {email => $user->{email}, listname => $list->{'name'}}
            );
            $log->syslog('err', 'Could not add %s as list %s@%s admin (role: %s)',
                $user->{email}, $listname, $robot, $role);
        } else {
            
            eval {Sympa::send_notify_to_user(
                $list,
                'added_as_listadmin',
                $user->{email},
                {   admin_type => $role,
                    delegator  => $updater_user
                }
            )};
            $@ and die $@;
        }

    }

    return 1;
}

1;

__END__

=encoding utf-8

=head1 NAME

Sympa::Request::Handler::add_list_admin - add list admin to a list.

=head1 DESCRIPTION

Add an admin, either owner or editor, to a list.

=head2 Attributes

See also L<Sympa::Request/"Attributes">.

=over

=item {email}

I<Mandatory>.
New list admin email address.

=item {list}

I<Mandatory>.
New list admin email address.

=item {email}

I<Mandatory>.
New list admin email address.

=back

=head1 SEE ALSO

L<Sympa::Request::Handler>.

=head1 HISTORY

L<Sympa::Request::Handler::add_list_admin> appeared on Sympa 6.2.xxx.

=cut
