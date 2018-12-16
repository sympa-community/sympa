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

package Sympa::DataSource::RemoteFile;

use strict;
use warnings;
use HTTP::Request;
use IO::Scalar;
use LWP::UserAgent;

use Sympa::Constants;
use Sympa::Log;

use base qw(Sympa::DataSource::File);    # Derived class.

my $log = Sympa::Log->instance;

use constant required_modules => [qw(LWP::Protocol::https)];

# Old name: (part of) Sympa::List::_include_users_remote_file().
sub _open {
    my $self = shift;

    my $fetch =
        LWP::UserAgent->new(agent => 'Sympa/' . Sympa::Constants::VERSION);
    $fetch->protocols_allowed(['http', 'https', 'ftp']);
    my $req = HTTP::Request->new(GET => $self->{url});
    if (defined $self->{user} and defined $self->{passwd}) {
        $req->authorization_basic($self->{user}, $self->{passwd});
    }

    my $res = $fetch->request($req);
    unless ($res->is_success) {
        $log->syslog('err', 'Unable to fetch data source %s: %s',
            $self, $res->message);
        return undef;
        #FIXME: Reset http credentials???
    }

    my $content = $res->content;
    return IO::Scalar->new(\$content);
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::DataSource::RemoteFile - Data source based on a file at remote host

=head1 DESCRIPTION

TBD.

=head1 SEE ALSO

L<Sympa::DataSource>.

=head1 HISTORY

L<Sympa::DataSource::RemoteFile> appeared on Sympa 6.2.XX.

=cut
