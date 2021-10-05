# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright 2019, 2020 The Sympa Community. See the AUTHORS.md
# file at the top-level directory of this distribution and at
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
use English qw(-no_match_vars);
use HTTP::Request;
use LWP::UserAgent;

use Conf;
use Sympa::Constants;
use Sympa::Log;

use base qw(Sympa::DataSource::File);    # Derived class.

my $log = Sympa::Log->instance;

use constant required_modules => [qw(LWP::Protocol::https)];

# Old name: (part of) Sympa::List::_include_users_remote_file().
sub _open {
    my $self    = shift;
    my %options = @_;

    my $list = $self->{context};

    my $ua =
        LWP::UserAgent->new(agent => 'Sympa/' . Sympa::Constants::VERSION);
    $ua->protocols_allowed(['http', 'https', 'ftp']);
    if ($self->{url} =~ /\Ahttps:/i) {
        my $cert_file = Sympa::search_fullpath($list, 'cert.pem');
        my $key_file  = Sympa::search_fullpath($list, 'private_key');
        my $key_passwd = $Conf::Conf{'key_passwd'};
        my $ca_file    = $Conf::Conf{'cafile'};
        my $ca_path    = $Conf::Conf{'capath'};

        if ($options{use_cert}) {
            unless ($cert_file
                and -r $cert_file
                and $key_file
                and -r $key_file) {
                $log->syslog('err',
                    '%s: Unable to open client certificate or private key',
                    $self);
                return undef;
            } else {
                $ua->ssl_opts(SSL_use_cert => 1);
            }
        }

        $ua->ssl_opts(SSL_version => $self->{ssl_version})
            if $self->{ssl_version} and $self->{ssl_version} ne 'ssl_any';
        $ua->ssl_opts(SSL_cipher_list => $self->{ssl_ciphers})
            if $self->{ssl_ciphers};
        $ua->ssl_opts(SSL_cert_file => $cert_file) if $cert_file;
        $ua->ssl_opts(SSL_key_file  => $key_file)  if $key_file;
        $ua->ssl_opts(SSL_passwd_cb => sub { return ($key_passwd) })
            if $key_passwd;
        $ua->ssl_opts(
            SSL_verify_mode => (
                {none => 0, optional => 1, required => 3}
                ->{$self->{ca_verify}} || 0
            )
        ) if defined $self->{ca_verify};
        $ua->ssl_opts(SSL_ca_file => $ca_file) if $ca_file;
        $ua->ssl_opts(SSL_ca_path => $ca_path) if $ca_path;
    }
    $ua->timeout($self->{timeout}) if $self->{timeout};

    my $req = HTTP::Request->new(GET => $self->{url});
    if (defined $self->{user} and defined $self->{passwd}) {
        $req->authorization_basic($self->{user}, $self->{passwd});
    }

    $self->{_tmpfile} = sprintf '%s/%s_RemoteFile.%s.%s',
        $Conf::Conf{'tmpdir'},
        $list->get_id, $PID, (int rand 9999);
    my $res = $ua->request($req, $self->{_tmpfile});
    $log->syslog('debug', 'REQUEST: %s', $req->as_string);
    $log->syslog('debug', 'RESPONSE:%s', $res->as_string);
    unless ($res->is_success) {
        $log->syslog('err', 'Unable to fetch data source %s: %s',
            $self, $res->message);
        return undef;
    }

    if ($self->{url} =~ /\Ahttps:/i and $options{use_cert}) {
        # Log subject, issuer and cipher of peer.
        $log->syslog(
            'info',
            '%s: Peer %s. Certificate subject "%s" issuer "%s". Cipher used "%s"',
            $self,
            $res->header('Client-Peer'),
            $res->header('Client-SSL-Cert-Subject'),
            $res->header('Client-SSL-Cert-Issuer'),
            $res->header('Client-SSL-Cipher')
        );
    }

    my $fh;
    unless (open $fh, '<', $self->{_tmpfile}) {
        $log->syslog('err', 'Cannot open file %s: %m', $self->{_tmpfile});
        return undef;
    }
    return $fh;
}

sub _close {
    my $self = shift;

    return undef unless $self->SUPER::_close();
    unlink $self->{_tmpfile};
    return 1;
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

L<Sympa::DataSource::RemoteFile> appeared on Sympa 6.2.45b.

=cut
