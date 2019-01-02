# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright 2017, 2019 The Sympa Community. See the AUTHORS.md file at
# the top-level directory of this distribution and at
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
use Sympa::Tools::Text;
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
        $log->syslog('info', 'No change on email');
        $self->add_stash($request, 'user', 'no_email_changed',
            {email => $email});
        return 1;
    }

    # Change email as list MEMBER.
    foreach
        my $list (Sympa::List::get_which($current_email, $robot_id, 'member'))
    {
        my $user_entry = $list->get_list_member($current_email);

        # Check the type of data sources.
        # If only include_sympa_list of local mailing lists, then no
        # problem.  Otherwise, notify list owner.
        #FIXME: Consider the case source list is included from external
        #       data source.
        if ($user_entry and defined $user_entry->{'inclusion_ext'}) {
            $list->send_notify_to_owner(
                'failed_to_change_included_member',
                {   'current_email' => $current_email,
                    'new_email'     => $email,
                    'datasource'    => '',
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

        # Check if user is already member of the list with their new address
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
            my ($admin_user) =
                grep { $_->{role} eq $role and $_->{email} eq $current_email }
                @{$list->get_current_admins || []};

            # Check the type of data sources.
            # If only include_sympa_list of local mailing lists, then no
            # problem.  Otherwise, notify listmaster.
            #FIXME: Consider the case source list is included from external
            #       data source.
            if ($admin_user and defined $admin_user->{'inclusion_ext'}) {
                Sympa::send_notify_to_listmaster(
                    $list,
                    'failed_to_change_included_admin',
                    {   current_email => $current_email,
                        new_email     => $email,
                        role          => $role,
                        datasource    => '',
                    }
                );
                $self->add_stash(
                    $request, 'user',
                    'change_admin_email_failed_included',
                    {   email    => $current_email,
                        listname => $list->{'name'},
                        role     => $role
                    }
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

            # Check if user is already user of the list with their new address
            # then we just need to remove the old address.
            if (grep { $_->{role} eq $role and $_->{email} eq $email }
                @{$list->get_current_admins || []}) {
                unless ($list->delete_list_admin($role, $current_email)) {
                    $self->add_stash(
                        $request, 'user',
                        'change_admin_email_failed_deleting',
                        {   email    => $current_email,
                            listname => $list->{'name'},
                            role     => $role
                        }
                    );
                    $log->syslog('info',
                        'Could not remove email %s from list %s',
                        $current_email, $list);
                    next;
                }
            } else {
                unless (
                    $list->update_list_admin(
                        $current_email, $role,
                        {email => $email, update_date => time}
                    )
                ) {
                    $self->add_stash(
                        $request, 'user',
                        'change_admin_email_failed',
                        {   email    => $current_email,
                            listname => $list->{'name'},
                            role     => $role
                        }
                    );
                    $log->syslog('err',
                        'Could not change email %s for list %s to %s',
                        $current_email, $list, $email);
                    next;
                }
            }
            $updated_lists{$list->{'name'}} = 1;
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

Changes a user email address for both their memberships and ownerships
on particular robot.

=head2 Attributes

See also L<Sympa::Request/"Attributes">.

=over

=item {current_email}

I<Mandatory>.
Current user email address.

=item {email}

I<Mandatory>.
New user email address.

=back

=head1 SEE ALSO

L<Sympa::Request::Handler>.

=head1 HISTORY

L<Sympa::Request::Handler::move_user> appeared on Sympa 6.2.19b.

=cut
