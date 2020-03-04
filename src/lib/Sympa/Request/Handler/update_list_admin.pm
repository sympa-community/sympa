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

package Sympa::Request::Handler::update_list_admin;

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
use constant _context_class   => undef;

sub _twist {
    my $self    = shift;
    my $request = shift;
    my $context    = $request->{context};
    my $listname;
    my $robot;
    my $list;
    if (defined $context and ref $context and $context->isa('Sympa::List')) {
        $list   = $context;
        $listname   = $list->{'name'};
        $robot   = $list->{'domain'};
    }elsif(defined $context and Sympa::List::get_lists($context)) {
        $robot   = $context;
    }else{
        $log->syslog('err', 'Wrong context type: %s.', $context);
        $self->add_stash(
            $request, 'user', 'syntax_errors',
            {p_name => 'context'}
        );
        return undef;
    }
    my $role = $request->{role};
    my $sender = $request->{sender};
    my $notify = $request->{notify};
    my $updater_user = $sender || Sympa::get_address($list, 'listmaster');
    my $new_values;
    $new_values->{email} = Sympa::Tools::Text::canonic_email($request->{new_email}) if $request->{new_email};
    $new_values->{visibility} = $request->{visibility} if $request->{visibility};
    $new_values->{profile} = $request->{profile} if $request->{profile};
    $new_values->{reception} = $request->{reception} if $request->{reception};
    $new_values->{gecos} = $request->{gecos} if $request->{gecos};
    $new_values->{info} = $request->{info} if $request->{info};

    my $previous_email = Sympa::Tools::Text::canonic_email($request->{current_email});

    unless( $previous_email ) {
        $log->syslog('err', 'Trying to update list admin without giving its email');
        $self->add_stash(
            $request, 'user', 'missing_parameters',
            'email'
        );
        return undef;
    }

    my $schema = $Sympa::ListDef::user_info{owner};
    unless($previous_email =~ m{$schema->{format}{email}{file_format}}) {
        $self->add_stash(
            $request, 'user', 'syntax_errors',
            {p_name => 'current_email'}
        );
        $log->syslog('err', 'Error : provided email %s is not a valid email.', $previous_email);
        return undef;
    }

    my @param_in_error;
    foreach my $param (keys %{$schema->{format}}) {
        if ($new_values->{$param}) {
            unless($new_values->{$param} =~ /$schema->{format}{$param}{file_format}/) {
                if ($param eq 'email') {
                    $param = 'new_email';
                }
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
            $new_values->{email}, $role, $listname, $robot, join ', ', @param_in_error);
        return undef;
     }

    if ( $role && !($role eq 'owner' or $role eq 'editor')) {
        $self->add_stash(
            $request, 'user', 'syntax_errors',
            {p_name => 'role'}
        );
        $log->syslog('err', 'Error: %s is not a defined role type',
            $role);
        return undef;
    }

    ## if role given: use it only
    my @roles;
    if ($role) {
        @roles = ($role);
    ## else: use all roles
    }else{
        @roles = ('owner', 'editor');
    }

    ## Actual update.
    my $error_found = 0;
    my %error_found;
    foreach my $role (@roles) {
        my @lists;
        ## if list given: use it only
        if ($list) {
            @lists = ($list);
        ## else: use all lists in robot.
        }else{
            @lists = Sympa::List::get_which($previous_email, $robot, $role);
        }
        
        foreach my $list (@lists) {

            my %new_values_copy = %$new_values;
            if ($role eq 'editor') {
                $new_values_copy{profile} = 'normal';
            }
            unless ($list->is_admin($role, $previous_email)) {
                 $error_found{$list->{name}}{$role} = 1;
            } else {
                ## Verifying if we will replace an amin by another one or just update an existing one.
                my $is_replacement = 0;
                my $former_couple = 0;
                my $mail_to_update = $previous_email;
                if ($new_values_copy{email} && $new_values_copy{email} ne $previous_email) {
                    ## If new email already admin, it will be an update.
                    if ($list->is_admin($role, $new_values_copy{email})) {
                        $is_replacement = 0;
                        $mail_to_update = $new_values_copy{email};
                        $former_couple = 1;
                    } else {
                        $is_replacement = 1;
                    }
                }
                ## Replacing an existing admin by a new one
                if ($is_replacement) {
                    my $previous_user = $list->get_admins($role, filter => [email => $mail_to_update]);
                    ## Privilege exception. If no privilege was explicitely given as argument, the new owner
                    ## will get the same profile as the old one (default to 'normal').
                    if ($role eq 'owner' and !$new_values_copy{profile}) {
                        $new_values_copy{profile} = $previous_user->[0]->{profile} || 'normal';
                    }
                    ## Add new admin
                    unless ($list->add_list_admin($role, \%new_values_copy)) {
                        $self->add_stash(
                            $request, 'user',
                            'list_admin_addition_failed',
                            {email => $new_values_copy{email}, listname => $list->{'name'}}
                        );
                        $log->syslog('err', 'Could not add %s as list %s@%s admin (role: %s)',
                            $new_values_copy{email}, $listname, $robot, $role);
                        ## Don't go further in the current operation if addition of new user was unsuccessful.
                        next;
                    } else {
                        if ($notify) {
                            Sympa::send_notify_to_user(
                                $list,
                                'added_as_listadmin',
                                $new_values_copy{email},
                                {   admin_type => $role,
                                    delegator  => $updater_user
                                }
                            );
                        }
                    }
                    ## Delete old admin
                    unless ($list->delete_list_admin($role, $previous_email)) {
                        $self->add_stash(
                            $request, 'intern',
                            'list_admin_deletion_failed',
                            {email => $previous_email, role => $role, listname => $list->{'name'}}
                        );
                        $log->syslog('err', 'Could not remove the role %s to user %s from list %s@%s.',
                            $role, $previous_email, $listname, $robot);
                        $error_found = 1;
                    } else {
                        if ($notify) {
                            Sympa::send_notify_to_user(
                                $list,
                                'removed_from_listadmin',
                                $previous_email,
                                {   admin_type => $role,
                                    delegator  => $updater_user
                                }
                            );
                        }
                    }
                ## Updating an existing admin with new values
                } else {
                    # Merging data for new user. Don't do anything if data unchanged.
                    my $previous_user = $list->get_admins($role, filter => [email => $mail_to_update]);
                    delete $previous_user->[0]->{included};
                    ## Privilege exception. If user to update was owner already and was privileged, don't decrease this privilege.
                    ## If the new privilege is 'privileged' it is always applied.
                    if ($former_couple and $role eq 'owner' and ($previous_user->[0]->{profile} eq 'privileged' or ($new_values_copy{profile} and $new_values_copy{profile} eq 'privileged'))) {
                        $previous_user->[0]->{profile} = 'privileged';
                    }
                    unless ($former_couple) {
                        my $changed = 0;
                        foreach my $key (keys %new_values_copy) {
                            if ($previous_user->[0]->{$key} ne $new_values_copy{$key}) {
                                $previous_user->[0]->{$key} = $new_values_copy{$key};
                                $changed = 1;
                            }
                        }
                        next unless $changed;
                    }
                    unless ($list->update_list_admin($mail_to_update, $role, $previous_user->[0])) {
                        $self->add_stash(
                            $request, 'intern',
                            'list_admin_update_failed',
                            {current_email => $mail_to_update, new_email => $mail_to_update, role => $role, listname => $list->{'name'}}
                        );
                        $log->syslog('err', 'Could not update data for the user %s with role %s in list %s@%s.',
                            $mail_to_update, $role, $listname, $robot);
                        $error_found = 1;
                    }
                    if ($former_couple) {
                        ## Delete old admin
                        unless ($list->delete_list_admin($role, $previous_email)) {
                            $self->add_stash(
                                $request, 'intern',
                                'list_admin_deletion_failed',
                                {email => $previous_email, role => $role, listname => $list->{'name'}}
                            );
                            $log->syslog('err', 'Could not remove the role %s to user %s from list %s@%s.',
                                $role, $previous_email, $listname, $robot);
                            $error_found = 1;
                        } else {
                            if ($notify) {
                                Sympa::send_notify_to_user(
                                    $list,
                                    'removed_from_listadmin',
                                    $previous_email,
                                    {   admin_type => $role,
                                        delegator  => $updater_user
                                    }
                                );
                            }
                        }
                    }
                }
            }
        }
    }

    my $email = $previous_email;
    foreach my $list (keys %error_found) {
        my @errors;
        foreach my $role (@roles) {
            if ($error_found{$list}{$role}) {
                if (scalar @roles == 1) {
                    $self->add_stash(
                        $request, 'user',
                        'not_list_admin',
                        {email => $email, role => $role, listname => $list}
                    );
                    $log->syslog('err', 'User "%s" has not the role "%s" in list "%s@%s"',
                        $email, $role, $list, $robot);
                    $error_found = 1;
                } else {
                    push @errors, $role;
                }
            }
        }
        if (scalar @roles == 2 && scalar @errors == 2) {
            $self->add_stash(
                $request, 'user',
                'not_list_admin',
                {email => $email, role => 'any roles', listname => $list}
            );
            $log->syslog('err', 'User "%s" has no admin role in list "%s@%s"',
                $email, $list, $robot);
            $error_found = 1;
        }
    }

    return undef if $error_found;
    return 1;
}

1;

__END__

=encoding utf-8

=head1 NAME

Sympa::Request::Handler::update_list_admin - update list admin from a list.

=head1 DESCRIPTION

update an admin, either owner or editor, from a list.

=head2 Attributes

See also L<Sympa::Request/"Attributes">.

=over

=item {email}

I<Mandatory>.
List admin email address.

=item {list}

I<Mandatory>.
list email address.

=item {rle}

I<Mandatory>.
The role from which the user should be removed.

=back

=head1 SEE ALSO

L<Sympa::Request::Handler>.

=head1 HISTORY

L<Sympa::Request::Handler::update_list_admin> appeared on Sympa 6.2.xxx.

=cut
