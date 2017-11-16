# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# This file is part of Sympa, see top-level README.md file for details

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

sub _connect {
    my $self = shift;

    if ($self->{host} =~ m{\bldaps://} or $self->{use_tls} eq 'starttls') {
        # LDAPS and STARTTLS require IO::Socket::SSL.
        unless ($IO::Socket::SSL::VERSION) {
            $log->syslog('err', 'Can\'t load IO::Socket::SSL');
            return undef;
        }

        # Earlier releases of IO::Socket::SSL would fallback SSL_verify_mode
        # to SSL_VERIFY_NONE when there are no usable CAfile nor CApath.
        # However, recent releases won't: They simply deny connection.
        # As a workaround, make ca_file or ca_path parameter mandatory unless
        # "none" is explicitly assigned to ca_verify parameter.
        unless ($self->{ca_verify} and $self->{ca_verify} eq 'none') {
            unless ($self->{ca_file} or $self->{ca_path}) {
                $log->syslog('err',
                    'Neither ca_file nor ca_path parameter is specified');
                return undef;
            }
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
        capath     => $self->{'ca_path'},
        cafile     => $self->{'ca_file'},
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

    # scheme() and uri() need perl-ldap >= 0.34.
    my $host_entry = sprintf '%s://%s', $connection->scheme, $connection->uri;

    # START_TLS if requested.
    if ($self->{use_tls} eq 'starttls') {
        my $mesg = $connection->start_tls(
            verify => (
                  (not $self->{ca_verify})           ? 'optional'
                : ($self->{ca_verify} eq 'required') ? 'require'
                :                                      $self->{ca_verify}
            ),
            capath     => $self->{'ca_path'},
            cafile     => $self->{'ca_file'},
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
                $host_entry, $self->error);
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

=head1 DESCRIPTION

TBD.

=head1 SEE ALSO

L<Sympa::DatabaseDriver>, L<Sympa::Database>.

=head1 HISTORY

L<Sympa::DatabaseDriver::LDAP> appeared on Sympa 6.2.

On Sympa 6.2.15, C<use_ssl> and C<use_start_tls> options were deprecated and
replaced by C<use_tls>.

=cut
