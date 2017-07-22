# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright 2017 The Sympa Community. See the AUTHORS.md file at the top-level
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

package Sympa::Request::Handler::move_user;

use strict;
use warnings;

use Sympa;
use Sympa::List;
use Sympa::Log;
use Sympa::Robot;
use Sympa::User;

use base qw(Sympa::Request::Handler);

my $log = Sympa::Log->instance;

use constant _action_scenario => 'move_user';
use constant _action_regexp   => qr'reject|request_auth|do_it'i;
use constant _context_class   => '';                               # Robot

# Old name: Sympa::Admin::change_user_email().
sub _twist {
    my $self    = shift;
    my $request = shift;

    my $robot_id = $request->{context};
    my $current_email =
        Sympa::Tools::Text::canonic_email($request->{current_email});
    my $email = Sympa::Tools::Text::canonic_email($request->{email});

    unless ($current_email and $email and $robot_id) {
        die 'Missing incoming parameter';
    }

    if ($current_email eq $email) {
        $self->add_stash($request, 'notice', 'no_email_changed',
            {email => $email});
        $log->syslog('info', 'No change on email');
        return 1;
    }

    # Change email as list MEMBER.
    foreach
        my $list (Sympa::List::get_which($current_email, $robot_id, 'member'))
    {

        my $user_entry = $list->get_list_member($current_email);

        if ($user_entry->{'included'} == 1) {
            # Check the type of data sources.
            # If only include_sympa_list of local mailing lists, then no
            # problem.  Otherwise, notify list owner.
            # We could also force a sync_include for local lists.
            my $use_external_data_sources;
            foreach my $datasource_id (split(/,/, $user_entry->{'id'})) {
                my $datasource = $list->search_datasource($datasource_id);
                if (   !defined $datasource
                    or $datasource->{'type'} ne 'include_sympa_list'
                    or (    $datasource->{'def'} =~ /\@(.+)$/
                        and $1 ne $robot_id)
                    ) {
                    $use_external_data_sources = 1;
                    last;
                }
            }
            if ($use_external_data_sources) {
                # Notify list owner.
                $list->send_notify_to_owner(
                    'failed_to_change_included_member',
                    {   'current_email' => $current_email,
                        'new_email'     => $email,
                        'datasource' =>
                            $list->get_datasource_name($user_entry->{'id'})
                    }
                );
                $self->add_stash(
                    $request, 'user',
                    'change_member_email_failed_included',
                    {email => $current_email, listname => $list->{'name'}}
                );
                $log->syslog(
                    'err',
                    'Could not change member email %s for list %s to %s because member is included',
                    $current_email,
                    $list,
                    $email
                );
                next;
            }
        }

        # Check if user is already member of the list with his new address
        # then we just need to remove the old address.
        if ($list->is_list_member($email)) {
            unless ($list->delete_list_member('users' => [$current_email])) {
                $self->add_stash(
                    $request, 'user',
                    'change_member_email_failed_deleting',
                    {email => $current_email, listname => $list->{'name'}}
                );
                $log->syslog('info', 'Could not remove email %s from list %s',
                    $current_email, $list);
            }

        } else {
            unless (
                $list->update_list_member(
                    $current_email,
                    email       => $email,
                    update_date => time
                )
                ) {
                $self->add_stash($request, 'user',
                    'change_member_email_failed',
                    {email => $current_email, listname => $list->{'name'}});
                $log->syslog('err',
                    'Could not change email %s for list %s to %s',
                    $current_email, $list, $email);
            }
        }
    }

    # Change email as list OWNER/MODERATOR.
    my %updated_lists;
    foreach my $role ('owner', 'editor') {
        foreach my $list (
            Sympa::List::get_which($current_email, $robot_id, $role)) {
            # Check if admin is included via an external datasource.
            my ($admin_user) =
                @{$list->get_admins($role,
                    filter => [email => $current_email])};
            if ($admin_user and $admin_user->{'included'}) {
                # Notify listmaster.
                Sympa::send_notify_to_listmaster(
                    $list,
                    'failed_to_change_included_admin',
                    {   'current_email' => $current_email,
                        'new_email'     => $email,
                        'datasource' =>
                            $list->get_datasource_name($admin_user->{'id'})
                    }
                );
                $self->add_stash(
                    $request, 'user',
                    'change_admin_email_failed_included',
                    {email => $current_email, listname => $list->{'name'}}
                );
                $log->syslog(
                    'err',
                    'Could not change %s email %s for list %s to %s because admin is included',
                    $role,
                    $current_email,
                    $list,
                    $email
                );
                next;
            }

            # Go through owners/editors of the list.
            foreach my $admin (@{$list->{'admin'}{$role}}) {
                next
                    unless lc $admin->{'email'} eq lc $current_email;

                # Update entry with new email address.
                $admin->{'email'} = $email;
                $updated_lists{$list->{'name'}}++;
            }

            # Update database cache for the list.
            $list->sync_include_admin();
            $list->save_config();
        }
    }
    # Notify listmasters that list owners/moderators email have changed.
    if (keys %updated_lists) {
        Sympa::send_notify_to_listmaster(
            $robot_id,
            'listowner_email_changed',
            {   'previous_email' => $current_email,
                'new_email'      => $email,
                'updated_lists'  => [sort keys %updated_lists]
            }
        );
    }

    # Update user_table and remove existing entry first (to avoid duplicate
    # entries).
    my $oldu = Sympa::User->new($email);
    $oldu->expire if $oldu;
    my $u = Sympa::User->new($current_email);
    unless ($u and $u->moveto($email)) {
        $self->add_stash($request, 'intern');
        $log->syslog('err', 'Update failed');
        return undef;
    }

    # Update netidmap_table.
    unless (
        Sympa::Robot::update_email_netidmap_db(
            $robot_id, $current_email, $email
        )
        ) {
        $self->add_stash($request, 'intern');
        $log->syslog('err', 'Update failed');
        return undef;
    }

    return 1;
}

1;

__END__

=encoding utf-8

=head1 NAME

Sympa::Request::Handler::move_user - change user's email

=head1 DESCRIPTION

Changes a user email address for both their memberships and ownerships.

# IN  : - current_email : current user email address
#       - email     : new user email address
#
# OUT : - status(scalar)          : status of the subroutine
#       - failed_for(arrayref)    : list of lists for which the change could
#       not be done (because user was
#                                   included or for authorization reasons)

=head1 SEE ALSO

L<Sympa::Request::Handler>.

=head1 HISTORY

L<Sympa::Request::Handler::move_user> appeared on Sympa 6.2.19b.

=cut
