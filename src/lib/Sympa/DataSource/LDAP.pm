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

package Sympa::DataSource::LDAP;

use strict;
use warnings;

use Sympa::Database;
use Sympa::Log;

use base qw(Sympa::DataSource);

my $log = Sympa::Log->instance;

sub _open {
    my $self    = shift;
    my %options = @_;

    my $timeout = $options{timeout} || $self->{timeout};

    #FIXME: Timeout specific to connection
    my $db = Sympa::Database->new('LDAP', %$self, timeout => $timeout);
    return undef unless $db and $db->connect;
    $self->{_db} = $db;

    my $mesg = $self->_open_operation(%options);
    return undef unless $mesg;

    $self->{_retrieved} = [];

    return $mesg;
}

# Method specific to this class.
sub _open_operation {
    my $self    = shift;
    my %options = @_;

    my $ldap_suffix = $options{suffix} || $self->{suffix};
    my $ldap_filter = $options{filter} || $self->{filter};
    my $ldap_attrs  = $options{attrs}  || $self->{attrs};
    my $ldap_scope  = $options{scope}  || $self->{scope};

    my $mesg = $self->{_db}->do_operation(
        'search',
        base   => $ldap_suffix,
        filter => $ldap_filter,
        attrs  => [split /\s*,\s*/, $ldap_attrs],
        scope  => $ldap_scope
    );
    unless ($mesg) {
        $log->syslog(
            'err',
            'LDAP search (single level) failed: %s with data source %s',
            $self->{_db}->error, $self
        );
        return undef;
    }

    return $mesg;
}

# Method specific to this class.
# Old name: (part of) these functions:
# Sympa::List::_include_users_ldap() and Sympa::List::_include_ldap_ca().
sub _load_next {
    my $self    = shift;
    my %options = @_;

    my $ldap_attrs  = $options{attrs}  || $self->{attrs};
    my $ldap_select = $options{select} || $self->{select};
    my $ldap_regex  = $options{regex}  || $self->{regex};
    # If value of this option is _not_ 'last', this function will process
    # an intermediate turn of multiple level data source.
    my $turn = $options{turn} || 'last';

    my ($key_attr, $other_attr, @other_attrs);
    if ($turn eq 'last') {
        if ($self->role eq 'custom_attribute') {
            $key_attr = $self->{email_entry};
            @other_attrs = grep { $key_attr ne $_ } split /\s*,\s*/,
                $ldap_attrs;
        } else {
            ($key_attr, $other_attr) = split /\s*,\s*/, $ldap_attrs;
        }
    } else {
        $key_attr = [split /\s*,\s*/, $ldap_attrs]->[0];
    }

    my @retrieved;
    my $mesg = $self->__dsh;
    while (my $entry = $mesg->shift_entry) {
        my $key_values = $entry->get_value($key_attr, asref => 1);
        next unless $key_values and @$key_values;

        my $other_value;
        if ($turn eq 'last') {
            if ($self->role eq 'custom_attribute') {
                $other_value = {};
                foreach my $attr (@other_attrs) {
                    my $values = $entry->get_value($attr, asref => 1);
                    next unless $values and @$values;

                    $other_value->{$attr} = $values->[0];
                }
            } else {
                $other_value =
                    ($entry->get_value($other_attr, asref => 1) || [])->[0]
                    if $other_attr;
            }
        }

        foreach my $key_value (@$key_values) {
            next unless defined $key_value;

            if (    $ldap_select eq 'regex'
                and defined $ldap_regex
                and length $ldap_regex) {
                next unless $key_value =~ /$ldap_regex/;
            }

            if ($turn eq 'last') {
                next unless length $key_value;
                push @retrieved, [$key_value, $other_value];
            } else {
                # Intermediate result can be empty string "".
                push @retrieved, [$key_value];
            }

            last if $ldap_select eq 'first';
        }
    }

    return [@retrieved];
}

sub _next {
    my $self    = shift;
    my %options = @_;

    unless ($self->{_retrieved} and @{$self->{_retrieved}}) {
        $self->{_retrieved} = $self->_load_next(%options);
    }
    if ($self->{_retrieved} and @{$self->{_retrieved}}) {
        return shift @{$self->{_retrieved}};
    }
    return;
}

sub _next_ca {
    goto &_next;    # '&' is required.
}

sub _close {
    my $self = shift;

    my $db = $self->{_db};
    return unless ref $db;

    unless ($db->disconnect) {
        $log->syslog('info', 'Can\'t close data source %s: %s',
            $self, $db->error);
        return undef;
    }

    return 1;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::DataSource::LDAP - Data source based on LDAP search operation

=head1 DESCRIPTION

Returns a list of subscribers extracted from a remote LDAP Directory

=head1 SEE ALSO

L<Sympa::DataSource>.

=head1 HISTORY

L<Sympa::DataSource::LDAP> appeared on Sympa 6.2.45b.

=cut
