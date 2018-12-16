# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright 201X The Sympa Community. See the AUTHORS.md file at the
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

package Sympa::DataSource::VOOT;

use strict;
use warnings;

use Sympa::Log;

use base qw(Sympa::DataSource);

my $log = Sympa::Log->instance;

use constant required_modules => [qw(VOOTConsumer)];

sub _open {
    my $self = shift;

    my $consumer = VOOTConsumer->new(
        user     => $self->{user},
        provider => $self->{provider}
    );

    # Note: Here we need to check if we are in a web environment and set
    # consumer's webEnv accordingly.
    my $members = $consumer->getGroupMembers(group => $self->{'group'});
    unless ($members) {
        my $url = $consumer->getOAuthConsumer()->mustRedirect();
        # Report error with redirect url
        #return do_redirect($url) if(defined $url);
        return undef;
    }

    return $members;
}

sub _next {
    my $self = shift;

    my $members = $self->__dsh;

    while (my $member = shift @$members) {
        if (my $email = shift @{$member->{emails}}) {
            next unless defined $email and length $email;

            return [$email, $member->{displayName}];
        }
    }

    return;
}

sub _close { 1; }

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::DataSource::VOOT - Data source based on VOOT protocol

=head1 DESCRIPTION

Includes users from voot group

=head1 SEE ALSO

L<Sympa::DataSource>.

=head1 HISTORY

L<Sympa::DataSource::VOOT> appeared on Sympa 6.2.XX.

=cut
