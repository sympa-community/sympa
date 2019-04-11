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

package Sympa::Request::Handler::delete_list_admin;

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
    my $user;
    $user->{email} = Sympa::Tools::Text::canonic_email($request->{email});

    unless( $user->{email} ) {
        $log->syslog('err', 'Trying to delete list admin without giving its email');
        $self->add_stash(
            $request, 'user', 'missing_parameters',
            'email'
        );
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
    my $schema = $Sympa::ListDef::user_info{owner};
    unless($user->{email} =~ /$schema->{format}{email}{file_format}/) {
        $self->add_stash(
            $request, 'user', 'syntax_errors',
            {p_name => 'email'}
        );
        $log->syslog('err', 'Error while deleting %s as %s to list %s@%s. Bad email parameter.');
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
    my $error_found = 0;
    foreach my $role (@roles) {
        my @lists;
        ## if list given: use it only
        if ($list) {
            @lists = ($list);
        ## else: use all lists in robot.
        }else{
            @lists = Sympa::List::get_which($user->{email}, $robot, $role);
        }

        foreach my $list (@lists) {
            # Check if the user is admin of the list with the given role.
            unless ($list->is_admin($role, $user->{email})) {
                $self->add_stash(
                    $request, 'user',
                    'not_list_admin',
                    {email => $user->{email}, role => $role, listname => $list->{'name'}}
                );
                $log->syslog('err', 'User "%s" has not the role "%s" in list "%s@%s"',
                    $user->{email}, $role, $listname, $robot);
                $error_found = 1;
            } else {
                if ($role eq 'owner') {
                    ## Don't remove the last list owner.
                    ## Note: it might be refined.
                    ## We could switch the last user with listmaster.
                    ## We could also add a "force" option that would ignore this protection.
                    ## It could also be a mitigation of both solutions:
                    ## for example, force the deletion but replace the email with the sender's email.
                    ## To be discussed, I guess.
                    my @current_owners = $list->get_admins('owner');
                    if ($#current_owners == 0) {
                        $self->add_stash(
                            $request, 'user',
                            'last_owner_deletion_attempt',
                            {email => $user->{email}, listname => $list->{'name'}}
                        );
                        $log->syslog('err', 'The user %s is the last owner of list %s@%s. Deletion forbidden.',
                            $user->{email}, $listname, $robot);
                        $error_found = 1;
                        next;
                    }
                }
                unless ($list->delete_list_admin($role, $user->{email})) {
                    $self->add_stash(
                        $request, 'intern',
                        'list_admin_deletion_failed',
                        {email => $user->{email}, role => $role, listname => $list->{'name'}}
                    );
                    $log->syslog('err', 'Could not remove the role %s to user %s from list %s@%s.',
                        $role, $user->{email}, $listname, $robot);
                    $error_found = 1;
                } else {
                    if ($notify) {
                        Sympa::send_notify_to_user(
                            $list,
                            'removed_from_listadmin',
                            $user->{email},
                            {   admin_type => $role,
                                delegator  => $updater_user
                            }
                        );
                    }
                }
            }
        }
    }

    return undef if $error_found;
    return 1;
}

1;

__END__

=encoding utf-8

=head1 NAME

Sympa::Request::Handler::delete_list_admin - delete list admin from a list.

=head1 DESCRIPTION

Delete an admin, either owner or editor, from a list.

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

L<Sympa::Request::Handler::delete_list_admin> appeared on Sympa 6.2.xxx.

=cut
