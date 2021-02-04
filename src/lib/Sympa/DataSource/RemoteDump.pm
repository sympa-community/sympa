# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright 2019 The Sympa Community. See the AUTHORS.md file at
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

package Sympa::DataSource::RemoteDump;

use strict;
use warnings;

use Sympa::Log;
use Sympa::Regexps;

use base qw(Sympa::DataSource::RemoteFile);    # Derived class

my $log = Sympa::Log->instance;

use constant required_modules => [qw(LWP::Protocol::https)];

# Old name: (part of) Sympa::Fetch::get_https(), Sympa::List::_get_https().
sub _open {
    my $self = shift;

    unless ($self->{url}) {
        my $host_re = Sympa::Regexps::host();
        my $host    = $self->{host};
        return undef unless $host and $host =~ /\A$host_re\z/;

        my $port = $self->{port} || '443';
        my $path = $self->{path};
        $path = '' unless defined $path;
        $path = "/$path" unless 0 == index $path, '/';

        $self->{url} = sprintf 'https://%s:%s%s', $host, $port, $path;
    }

    my $fh = $self->SUPER::_open(use_cert => 1);
    return $fh;
}

sub _next {
    my $self = shift;

    my $fh = $self->__dsh;

    my %entry;
    while (my $line = <$fh>) {
        $line =~ s/\s+\z//;

        if ($line eq '') {
            last if defined $entry{email} and length $entry{email};
            %entry = ();
        } elsif ($line =~ /\A\s*(\w+)(?:\s+(.*))?\z/) {
            $entry{$1} = $2;
        } else {
            $log->syslog(
                'err',
                '%s: Illegal line %.128s. Source file probably corrupted. Aborting',
                $self,
                $line
            );
            return;
        }
    }

    return [@entry{qw(email gecos)}]
        if defined $entry{email} and length $entry{email};
    return;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::DataSource::RemoteDump -
Data source based on a user dump at remote host

=head1 DESCRIPTION

Include a remote sympa list as subscribers.

=head1 SEE ALSO

L<Sympa::DataSource>.

=head1 HISTORY

L<Sympa::DataSource::RemoteDump> appeared on Sympa 6.2.45b.

=cut
