# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright 2022 The Sympa Community. See the
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

package Sympa::Request::Handler::del_user;

use strict;
use warnings;

use Sympa;
use Sympa::List;
use Sympa::Log;
use Sympa::Robot;
use Sympa::Tools::Text;
use Sympa::User;
use Data::Dumper;

use base qw(Sympa::Request::Handler);

my $log = Sympa::Log->instance;

use constant _action_scenario => 'del_user';
use constant _action_regexp   => qr'reject|request_auth|do_it'i;
use constant _context_class   => '';                               # Robot

sub _twist {
    my $self    = shift;
    my $request = shift;

    my $robot_id = $request->{context};
    my $email = $request->{email};
    my $last_robot = $request->{last_robot};

    unless ($email and $robot_id and $last_robot) {
        die 'Missing incoming parameters';
    }

    # Determine if user exists
    my $user_hash = Sympa::User::get_global_user($email);

    unless ($user_hash) {
        $self->add_stash($request, 'user', 'no_entry',
                         {email => $email});
        $self->{finish} = 1;
        return 1;
    }

    # Unsubscribe
    for my $list (Sympa::List::get_which($email, $robot_id, 'member')) {
        $log->syslog('info', 'List %s', $list->{name});
        $list->delete_list_member([$email]);
        $self->add_stash($request, 'notice', 'now_unsubscribed',
                         {email => $email, listname => $list->{'name'}});
    }

    # Remove from the editors
    for my $role (qw/editor owner/) {
        for my $list (Sympa::List::get_which($email, $robot_id, $role)) {
            $list->delete_list_admin($role, [$email]);
            $self->add_stash($request, 'notice', 'removed',
                             {'email' => $email, 'listname' => $list->get_id});
        }
    }

    # Remove the user on the final run
    if ($robot_id eq $last_robot) {
        my $user_object = Sympa::User->new($email);
        $user_object->expire;
        $self->add_stash($request, 'notice', 'user_removed',
                         {'email' => $email, });
    }

    return 1;

    # Change email as list OWNER/MODERATOR.
    my %updated_lists;
    foreach my $role ('owner', 'editor') {
        foreach my $list (
            Sympa::List::get_which($email, $robot_id, $role)) {
            my ($admin_user) =
                grep { $_->{role} eq $role and $_->{email} eq $email }
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
                    {   email => $email,
                        new_email     => $email,
                        role          => $role,
                        datasource    => '',
                    }
                );
                $self->add_stash(
                    $request, 'user',
                    'change_admin_email_failed_included',
                    {   email    => $email,
                        listname => $list->{'name'},
                        role     => $role
                    }
                );
                $log->syslog(
                    'err',
                    'Could not change %s email %s for list %s to %s because admin is included',
                    $role,
                    $email,
                    $list,
                    $email
                );
                next;
            }

            # Check if user is already user of the list with their new address
            # then we just need to remove the old address.
            if (grep { $_->{role} eq $role and $_->{email} eq $email }
                @{$list->get_current_admins || []}) {
                my @stash;
                $list->delete_list_admin($role, [$email],
                    stash => \@stash);
                foreach my $report (@stash) {
                    next
                        unless
                        grep { $_->[0] eq 'user' or $_->[0] eq 'intern' }
                        @stash;
                    $log->syslog('info',
                        'Could not remove email %s from list %s',
                        $email, $list);
                    $self->add_stash(
                        $request, 'user',
                        'change_member_email_failed_deleting',
                        {   email    => $email,
                            listname => $list->{'name'},
                            role     => $role
                        }
                    );
                }
                next
                    if grep { $_->[0] eq 'user' or $_->[0] eq 'intern' }
                    @stash;
            } else {
                unless (
                    $list->update_list_admin(
                        $email, $role,
                        {email => $email, update_date => time}
                    )
                ) {
                    $self->add_stash(
                        $request, 'user',
                        'change_admin_email_failed',
                        {   email    => $email,
                            listname => $list->{'name'},
                            role     => $role
                        }
                    );
                    $log->syslog('err',
                        'Could not change email %s for list %s to %s',
                        $email, $list, $email);
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
            {   'previous_email' => $email,
                'new_email'      => $email,
                'updated_lists'  => [sort keys %updated_lists]
            }
        );
    }

  
    # Update netidmap_table.
    unless (
        Sympa::Robot::update_email_netidmap_db(
            $robot_id, $email, $email
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

Sympa::Request::Handler::del_user - delete user

=head1 DESCRIPTION

Deletes an user including subscriptions.

=head2 Attributes

See also L<Sympa::Request/"Attributes">.

=over

=item {email}

I<Mandatory>.
User email address.

=back

=head1 SEE ALSO

L<Sympa::Request::Handler>.

=cut
