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

package Sympa::DataSource::RemoteDump;

use strict;
use warnings;

use Sympa;
use Conf;
use Sympa::Log;

use base qw(Sympa::DataSource);

my $log = Sympa::Log->instance;

use constant required_modules => [qw(IO::Socket::SSL)];

# Old name: (part of) Sympa::Fetch::get_https(), Sympa::List::_get_https().
sub _open {
    my $self = shift;

    my $list = $self->{context};
    my $dir  = $list->{'dir'};

    my $host = $self->{host};
    my $port = $self->{port} || '443';
    my $path = $self->{path};
    my $cert = $self->{cert} || 'list';

    my $cert_file = $list->{'dir'} . '/cert.pem';
    my $key_file  = $list->{'dir'} . '/private_key';
    if ($cert eq 'list') {
        $cert_file = $dir . '/cert.pem';
        $key_file  = $dir . '/private_key';
    } elsif ($cert eq 'robot') {
        $cert_file = Sympa::search_fullpath($list, 'cert.pem');
        $key_file  = Sympa::search_fullpath($list, 'private_key');
    }
    unless (-r $cert_file and -r $key_file) {
        $log->syslog(
            'err',
            'Include remote list https://%s:%s/%s using cert %s, unable to open %s or %s',
            $host,
            $port,
            $path,
            $cert,
            $cert_file,
            $key_file
        );
        return undef;
    }

    my $key_passwd      = $Conf::Conf{'key_passwd'};    #FIXME
    my $trusted_ca_file = $Conf::Conf{'cafile'};
    my $trusted_ca_path = $Conf::Conf{'capath'};

    my $ssl_socket = IO::Socket::SSL->new(
        SSL_use_cert    => 1,
        SSL_verify_mode => 0x01,
        SSL_cert_file   => $cert_file,
        SSL_key_file    => $key_file,
        SSL_passwd_cb   => sub { return ($key_passwd) },
        ($trusted_ca_file ? (SSL_ca_file => $trusted_ca_file) : ()),
        ($trusted_ca_path ? (SSL_ca_path => $trusted_ca_path) : ()),
        PeerAddr => $host,
        PeerPort => $port,
        Proto    => 'tcp',
        Timeout  => '5'
    );

    unless ($ssl_socket) {
        $log->syslog('err', 'Error %s unable to connect https://%s:%s/',
            IO::Socket::SSL::errstr(), $host, $port);
        return undef;
    }
    $log->syslog('debug', 'Connected to https://%s:%s/',
        IO::Socket::SSL::errstr(), $host, $port);

    if (ref($ssl_socket) eq "IO::Socket::SSL") {
        my $subject_name = $ssl_socket->peer_certificate("subject");
        my $issuer_name  = $ssl_socket->peer_certificate("issuer");
        my $cipher       = $ssl_socket->get_cipher();
        $log->syslog('debug',
            'SSL peer certificate %s issued by %s. Cipher used %s',
            $subject_name, $issuer_name, $cipher);
    }

    print $ssl_socket "GET $path HTTP/1.0\nHost: $host\n\n";
    $log->syslog('debug3', 'https://%s:%s/%s', $host, $port, $path);

    return $ssl_socket;
}

sub _next {
    my $self = shift;

    my $list = $self->{context};

    my $ssl_socket = $self->__dsh;

    my ($email, $gecos);
    my $getting_headers = 1;
    while (my $line = $ssl_socket->getline) {
        $line =~ s/\r?\n\z//;

        if ($getting_headers) {    # ignore http headers
            next
                unless $line =~
                /^(date|update_date|email|reception|visibility)/;
        }
        undef $getting_headers;

        if ($line =~ /^\s*email\s+(.+)\s*$/o) {
            $email = $1;
        } elsif ($line =~ /^\s*gecos\s+(.+)\s*$/o) {
            $gecos = $1;
        } elsif ($line ne '') {
            next;
        }
        next unless defined $email and length $email;

        return [$email, $gecos];
    }

    return;
}

sub _close {
    my $self = shift;

    my $socket = $self->__dsh;
    return unless ref $socket;
    return $socket->close(SSL_no_shutdown => 1);
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

L<Sympa::DataSource::RemoteDump> appeared on Sympa 6.2.XX.

=cut
