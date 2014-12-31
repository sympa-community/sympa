# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014 GIP RENATER
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

package Sympa::Datasource::LDAP;

use strict;
use warnings;

use Log;

use base qw(Sympa::Datasource);

use constant required_parameters => [qw(host)];
use constant optional_parameters => [
    qw(port bind_dn bind_password
        use_ssl use_start_tls ssl_version ssl_ciphers
        ssl_cert ssl_key ca_verify ca_path ca_file)
];
use constant required_modules => [qw(Net::LDAP)];

sub new {
    Log::do_log('debug2', '(%s, %s)', @_);
    my $class  = shift;
    my $params = shift;
    my %params = %$params;

    my $self = bless {
        map {
                  (exists $params{$_} and defined $params{$_})
                ? ($_ => $params{$_})
                : ()
            } (@{$class->required_parameters}, @{$class->optional_parameters})
    } => $class;
    $self->{timeout}   ||= 3;
    $self->{ca_verify} ||= 'optional';

    # Canonicalize host parameter to be "scheme://host:port".
    my @hosts =
        (ref $self->{host})
        ? @{$self->{host}}
        : (split /\s*,\s*/, $self->{host});
    foreach my $host (@hosts) {
        $host .= ':' . $self->{port}
            if $self->{port} and $host !~ m{:[-\w]+\z};
        # Value of obsoleted use_ssl parameter may be '1' or 'yes' depending
        # on the context.
        $host = 'ldaps://' . $host
            if $self->{use_ssl}
                and ($self->{use_ssl} eq '1' or $self->{use_ssl} eq 'yes')
                and $host !~ m{\A[-\w]+://};
        $host = 'ldap://' . $host
            if $host !~ m{\A[-\w]+://};
    }
    $self->{host} = [@hosts];

    foreach my $module (@{$class->required_modules}) {
        unless (eval "require $module") {
            Log::do_log(
                'err',
                'No module installed for LDAP. You should download and install %s',
                $module
            );
            return undef;
        }
    }

    return $self;
}

############################################################
#  connect
############################################################
#  Connect to an LDAP directory. This could be called as
#  a Sympa::Datasource::LDAP object member, or as a static sub.
#
# IN : -$options : ref to a hash. Options for the connection process.
#         currently accepts 'keep_trying' : wait and retry until
#         db connection is ok (boolean) ; 'warn' : warn
#         listmaster if connection fails (boolean)
# OUT : $self->{'ldap_handler'}
#     | undef
#
##############################################################
sub connect {
    my $self = shift;

    ## Do we have all required parameters
    foreach my $ldap_param (@{$self->required_parameters}) {
        unless ($self->{$ldap_param}) {
            Log::do_log('info', 'Missing parameter %s for LDAP connection',
                $ldap_param);
            return undef;
        }
    }

    my $host_entry;
    # There might be multiple alternate hosts defined
    foreach my $host (@{$self->{host}}) {
        # new() may die if depending module is missing (e.g. for SSL).
        $self->{'ldap_handler'} = eval {
            Net::LDAP->new(
                $host,
                timeout    => $self->{'timeout'},
                verify     => $self->{'ca_verify'},
                capath     => $self->{'ca_path'},
                cafile     => $self->{'ca_file'},
                sslversion => $self->{'ssl_version'},
                ciphers    => $self->{'ssl_ciphers'},
                clientcert => $self->{'ssl_cert'},
                clientkey  => $self->{'ssl_key'},
            );
        };

        # if $self->{'ldap_handler'} is defined, skip alternate hosts
        if ($self->{'ldap_handler'}) {
            $host_entry = $host;
            last;
        }
    }

    unless ($self->{'ldap_handler'}) {
        Log::do_log(
            'err',
            'Unable to connect to the LDAP server %s',
            join(',', @{$self->{'host'}})
        );
        return undef;
    }

    # Using start_tls() will convert the existing connection to using
    # Transport Layer Security (TLS), which provides an encrypted connection.
    # FIXME: This is only possible if the connection uses LDAPv3, and requires
    # that the server advertizes support for LDAP_EXTENSION_START_TLS. Use
    # "supported_extension" in Net::LDAP::RootDSE to check this.
    if ($self->{'use_start_tls'}) {
        # new() may die if depending module for SSL/TLS is missing.
        # FIXME: Result should be checked.
        eval {
            $self->{'ldap_handler'}->start_tls(
                verify     => $self->{'ca_verify'},
                capath     => $self->{'ca_path'},
                cafile     => $self->{'ca_file'},
                sslversion => $self->{'ssl_version'},
                ciphers    => $self->{'ssl_ciphers'},
                clientcert => $self->{'ssl_cert'},
                clientkey  => $self->{'ssl_key'},
            );
        };
    }

    my $cnx;
    ## Not always anonymous...
    if (    defined $self->{'bind_dn'}
        and defined $self->{'bind_password'}) {
        $cnx =
            $self->{'ldap_handler'}
            ->bind($self->{'bind_dn'}, password => $self->{'bind_password'});
    } else {
        $cnx = $self->{'ldap_handler'}->bind;
    }

    unless (defined $cnx and $cnx->code() == 0) {
        Log::do_log('err',
            'Failed to bind to LDAP server: "%s", LDAP server error: "%s"',
            $host_entry, $cnx->error, $cnx->server_error);
        $self->{'ldap_handler'}->unbind;
        return undef;
    }
    Log::do_log('debug3', 'Bound to LDAP host "%s"', $host_entry);

    return $self->{'ldap_handler'};
}

## Does not make sense in LDAP context
sub ping {
}

## Does not make sense in LDAP context
sub quote {
}

## Does not make sense in LDAP context
sub create_db {
}

sub disconnect {
    my $self = shift;
    $self->{'ldap_handler'}->unbind if $self->{'ldap_handler'};
}

1;
