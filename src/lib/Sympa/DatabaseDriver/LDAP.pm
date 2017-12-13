# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
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

package Sympa::DatabaseDriver::LDAP;

use strict;
use warnings;
use English qw(-no_match_vars);

use Sympa::Log;

use base qw(Sympa::DatabaseDriver);

my $log = Sympa::Log->instance;

use constant required_parameters => [qw(host)];
use constant optional_parameters => [
    qw(port bind_dn bind_password
        use_tls ssl_version ssl_ciphers
        ssl_cert ssl_key ca_verify ca_path ca_file)
];
use constant required_modules => [qw(Net::LDAP)];
use constant optional_modules => [qw(IO::Socket::SSL)];

sub _new {
    my $class   = shift;
    my $db_type = shift;
    my %params  = @_;

    $params{use_tls} ||= 'none';

    # Canonicalize host parameter to be "scheme://host:port".
    # Note: Net::LDAP >= 0.40 is required to use ldaps: scheme.
    my @hosts =
          (ref $params{host}) ? @{$params{host}}
        : (defined $params{host} and length $params{host})
        ? (split /\s*,\s*/, $params{host})
        : ();
    foreach my $host (@hosts) {
        $host .= ':' . $params{port}
            if $params{port} and $host !~ m{:[-\w]+\z};
        $host = 'ldaps://' . $host
            if $params{use_tls} eq 'ldaps' and $host !~ m{\A[-\w]+://};
        $host = 'ldap://' . $host
            if $host !~ m{\A[-\w]+://};
    }
    $params{_hosts} = [@hosts];
    $params{host} = join ',', @hosts;
    delete $params{port};

    return bless {%params} => $class;
}

# Note: uri() method need perl-ldap >= 0.34.
sub _connect {
    my $self = shift;

    if ($self->{host} =~ m{\bldaps://} or $self->{use_tls} eq 'starttls') {
        # LDAPS and STARTTLS require IO::Socket::SSL.
        unless ($IO::Socket::SSL::VERSION) {
            $log->syslog('err', 'Can\'t load IO::Socket::SSL');
            return undef;
        }
    }

    # new() with multiple alternate hosts needs perl-ldap >= 0.27.
    my $connection = Net::LDAP->new(
        $self->{_hosts},
        timeout => ($self->{'timeout'} || 3),
        verify => (
              (not $self->{ca_verify})           ? 'optional'
            : ($self->{ca_verify} eq 'required') ? 'require'
            :                                      $self->{ca_verify}
        ),
        ($self->{'ca_path'} ? (capath => $self->{'ca_path'}) : ()),
        ($self->{'ca_file'} ? (cafile => $self->{'ca_file'}) : ()),
        sslversion => $self->{'ssl_version'},
        ciphers    => $self->{'ssl_ciphers'},
        clientcert => $self->{'ssl_cert'},
        clientkey  => $self->{'ssl_key'},
    );
    $self->{_error_code}   = 0;
    $self->{_error_string} = $EVAL_ERROR;

    unless ($connection) {
        $log->syslog('err', 'Unable to connect to the LDAP server %s',
            $self->{host});
        return undef;
    }

    # START_TLS if requested.
    if ($self->{use_tls} eq 'starttls') {
        my $mesg = $connection->start_tls(
            verify => (
                  (not $self->{ca_verify})           ? 'optional'
                : ($self->{ca_verify} eq 'required') ? 'require'
                :                                      $self->{ca_verify}
            ),
            ($self->{'ca_path'} ? (capath => $self->{'ca_path'}) : ()),
            ($self->{'ca_file'} ? (cafile => $self->{'ca_file'}) : ()),
            sslversion => $self->{'ssl_version'},
            ciphers    => $self->{'ssl_ciphers'},
            clientcert => $self->{'ssl_cert'},
            clientkey  => $self->{'ssl_key'},
        );

        unless ($mesg and $mesg->code() == 0) {
            if ($mesg) {
                $self->{_error_code}   = $mesg->code;
                $self->{_error_string} = $mesg->error;
            } else {
                $self->{_error_code}   = 0;
                $self->{_error_string} = 'Unknown';
            }
            $log->syslog('err', 'Failed to start TLS with LDAP server %s: %s',
                $connection->uri, $self->error);
            $connection->unbind;
            return undef;
        }
    }

    my $mesg;
    ## Not always anonymous...
    if (    defined $self->{'bind_dn'}
        and defined $self->{'bind_password'}) {
        $mesg =
            $connection->bind($self->{'bind_dn'},
            password => $self->{'bind_password'});
    } else {
        $mesg = $connection->bind;
    }

    unless ($mesg and $mesg->code() == 0) {
        if ($mesg) {
            $self->{_error_code}   = $mesg->code;
            $self->{_error_string} = $mesg->error;
        } else {
            $self->{_error_code}   = 0;
            $self->{_error_string} = 'Unknown';
        }
        $log->syslog('err', 'Failed to bind to LDAP server %s: %s',
            $connection->uri, $self->error);
        $connection->unbind;
        return undef;
    }
    $log->syslog('debug3', 'Bound to LDAP host "%s"', $connection->uri);

    delete $self->{_error_code};
    delete $self->{_error_string};
    return $connection;
}

sub disconnect {
    my $self = shift;

    $self->__dbh->unbind if $self->__dbh;
    $self->SUPER::disconnect();
}

sub do_operation {
    my $self      = shift;
    my $operation = shift;
    my %params    = @_;

    my $mesg;

    $log->syslog('debug3', 'Will perform operation "%s"', $operation);

    $mesg = $self->__dbh->search(%params);
    if ($mesg->code) {
        # Check connection to database in case it would be the cause of the
        # problem.  As LDAP doesn't support ping(), once disconnect and then
        # try connecting again.
        $self->disconnect;
        unless ($self->connect()) {
            $log->syslog('err', 'Unable to get a handle to %s', $self);
            return undef;
        } else {
            $mesg = $self->__dbh->search(%params);
            if ($mesg->code) {
                $self->{_error_code}   = $mesg->code;
                $self->{_error_string} = $mesg->error;
                $log->syslog('err', 'Unable to perform LDAP operation: %s',
                    $mesg->error);
                return undef;
            }
        }
    }

    delete $self->{_error_code};
    delete $self->{_error_string};
    return $mesg;
}

sub error {
    my $self = shift;

    return sprintf '(%s) %s', $self->{_error_code}, $self->{_error_string}
        if defined $self->{_error_code};
    return undef;
}

1;

=encoding utf-8

=head1 NAME

Sympa::DatabaseDriver::LDAP - Database driver for LDAP search operation

=head1 DESCRIPTION

TBD.

=head1 SEE ALSO

L<Sympa::DatabaseDriver>, L<Sympa::Database>.

=head1 HISTORY

L<Sympa::DatabaseDriver::LDAP> appeared on Sympa 6.2.

On Sympa 6.2.15, C<use_ssl> and C<use_start_tls> options were deprecated and
replaced by C<use_tls>.

=cut
