# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015 GIP RENATER
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
        use_ssl use_start_tls ssl_version ssl_ciphers
        ssl_cert ssl_key ca_verify ca_path ca_file)
];
use constant required_modules => [qw(Net::LDAP)];

sub _new {
    my $class   = shift;
    my $db_type = shift;
    my %params  = @_;

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
        # Value of obsoleted use_ssl parameter may be '1' or 'yes' depending
        # on the context.
        $host = 'ldaps://' . $host
            if $params{use_ssl}
                and ($params{use_ssl} eq '1' or $params{use_ssl} eq 'yes')
                and $host !~ m{\A[-\w]+://};
        $host = 'ldap://' . $host
            if $host !~ m{\A[-\w]+://};
    }
    $params{_hosts} = [@hosts];
    $params{host} = join ',', @hosts;
    delete $params{port};
    delete $params{use_ssl};

    return bless {%params} => $class;
}

sub _connect {
    my $self = shift;

    # Earlier releases of IO::Socket::SSL would fallback SSL_verify_mode to
    # SSL_VERIFY_NONE when there are no usable CAfile nor CApath.  However,
    # recent releases won't: They simply deny connection.
    # As a workaround, make ca_file or ca_path parameter mandatory unless
    # "none" is explicitly assigned to ca_verify parameter.
    if ($self->{host} =~ m{\bldaps://} or $self->{use_start_tls}) {
        unless ($self->{ca_verify} and $self->{ca_verify} eq 'none') {
            unless ($self->{ca_file} or $self->{ca_path}) {
                $log->syslog('err',
                    'Neither ca_file nor ca_path parameter is specified');
                return undef;
            }
        }
    }

    # new() with multiple alternate hosts needs perl-ldap >= 0.27.
    # It may die if depending module is missing (e.g. for SSL).
    my $connection = eval {
        Net::LDAP->new(
            $self->{_hosts},
            timeout => ($self->{'timeout'}   || 3),
            verify  => ($self->{'ca_verify'} || 'optional'),
            capath  => $self->{'ca_path'},
            cafile  => $self->{'ca_file'},
            sslversion => $self->{'ssl_version'},
            ciphers    => $self->{'ssl_ciphers'},
            clientcert => $self->{'ssl_cert'},
            clientkey  => $self->{'ssl_key'},
        );
    };
    $self->{_error_code}   = 0;
    $self->{_error_string} = $EVAL_ERROR;

    unless ($connection) {
        $log->syslog('err', 'Unable to connect to the LDAP server %s',
            $self->{host});
        return undef;
    }

    # scheme() and uri() need perl-ldap >= 0.34.
    my $host_entry = sprintf '%s://%s', $connection->scheme, $connection->uri;

    # Using start_tls() will convert the existing connection to using
    # Transport Layer Security (TLS), which provides an encrypted connection.
    # FIXME: This is only possible if the connection uses LDAPv3, and requires
    # that the server advertises support for LDAP_EXTENSION_START_TLS. Use
    # "supported_extension" in Net::LDAP::RootDSE to check this.
    if ($self->{'use_start_tls'}) {
        # new() may die if depending module for SSL/TLS is missing.
        # FIXME: Result should be checked.
        eval {
            $connection->start_tls(
                verify => ($self->{'ca_verify'} || 'optional'),
                capath => $self->{'ca_path'},
                cafile => $self->{'ca_file'},
                sslversion => $self->{'ssl_version'},
                ciphers    => $self->{'ssl_ciphers'},
                clientcert => $self->{'ssl_cert'},
                clientkey  => $self->{'ssl_key'},
            );
        };
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
            $host_entry, $self->error);
        $connection->unbind;
        return undef;
    }
    $log->syslog('debug3', 'Bound to LDAP host "%s"', $host_entry);

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

=head1 SEE ALSO

L<Sympa::DatabaseDriver>, L<Sympa::Database>.

=cut
