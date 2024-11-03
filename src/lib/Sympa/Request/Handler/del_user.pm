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

    my $robot_id   = $request->{context};
    my $email      = $request->{email};
    my $last_robot = $request->{last_robot};
    my @stash;

    unless ($email and $robot_id and $last_robot) {
        die 'Missing incoming parameters';
    }

    # Unsubscribe
    for my $list (Sympa::List::get_which($email, $robot_id, 'member')) {
        $log->syslog('info', 'List %s', $list->{name});
        $list->delete_list_member([$email], exclude => 1);
        $self->add_stash($request, 'notice', 'now_unsubscribed',
            {email => $email, listname => $list->{'name'}});
    }

    # Remove from the editors/owners
    for my $role (qw/editor owner/) {
        for my $list (Sympa::List::get_which($email, $robot_id, $role)) {
            $list->delete_list_admin($role, [$email]);
            $self->add_stash($request, 'notice', 'removed',
                {'email' => $email, 'listname' => $list->get_id});
        }
    }

    # Update netidmap_table.
    unless (Sympa::Robot::update_email_netidmap_db($robot_id, $email, $email))
    {
        $self->add_stash($request, 'intern');
        $log->syslog('err', 'Update failed');
        return undef;
    }

    # Remove the user on the final run
    if ($robot_id eq $last_robot) {
        if (Sympa::User::is_global_user($email)) {
            my $user_object = Sympa::User->new($email);

            $user_object->expire;
            $self->add_stash($request, 'notice', 'user_removed',
                {'email' => $email,});
        }
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
