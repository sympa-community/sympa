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
    my $user;
    $user->{email} = Sympa::Tools::Text::canonic_email($request->{email});
    $user->{visibility} = $request->{visibility};
    $user->{profile} = $request->{profile};
    $user->{reception} = $request->{reception};
    $user->{gecos} = $request->{gecos};
    $user->{info} = $request->{info};

    unless ($user->{email} and $robot and $role) {
        die "Missing incoming parameter. robot: $robot, role: $role, user: ".$user->{email};
    }
    # Check if user is already admin of the list.
    if ($list->is_admin($role, $user->{email})) {
        $self->add_stash(
            $request, 'user',
            'already_list_admin',
            {email => $user->{email}, role => $role, listname => $list->{'name'}}
        );
        $log->syslog('err', 'User "%s" has the role "%s" in list "%@%s" already',
            $user->{email}, $role, $listname, $robot);
        return undef;
    } else {
        unless ($list->add_list_admin($role, $user)) {
            $self->add_stash(
                $request, 'user',
                'list_admin_addition_failed',
                {email => $user->{email}, listname => $list->{'name'}}
            );
            $log->syslog('info', 'Could not add % as list %@%s admin (role: %s)',
                $user->{email}, $listname, $robot, $role);
        } else {
            # Notify listmasters that list owners/moderators email have changed.
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
