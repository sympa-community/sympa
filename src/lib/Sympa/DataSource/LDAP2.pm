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

package Sympa::DataSource::LDAP2;

use strict;
use warnings;

use Sympa::Log;

use base qw(Sympa::DataSource::LDAP);    # Derived class

my $log = Sympa::Log->instance;

use constant required_modules => [qw(Net::LDAP::Util)];

sub _open {
    my $self = shift;

    my $mesg = $self->SUPER::_open(
        timeout => $self->{timeout1},
        suffix  => $self->{suffix1},
        filter  => $self->{filter1},
        attrs   => $self->{attrs1},
        scope   => $self->{scope1},
    );
    return undef unless $mesg;
    $self->{_ds} = $mesg;    # hack __dsh()

    my @values;
    while (
        my $entry = $self->SUPER::_next(
            attrs  => $self->{attrs1},
            select => $self->{select1},
            regex  => $self->{regex1},
            turn   => 'first'
        )
    ) {
        push @values, $entry->[0] if defined $entry->[0];
    }
    $self->{_attr1values} = [@values];

    return 1;
}

# Old name: (part of) Sympa::List::_include_users_ldap_2level().
sub _load_next {
    my $self    = shift;
    my %options = @_;

    if ($options{turn} eq 'first') {
        return $self->SUPER::_load_next(%options);
    }

    my @retrieved;
    while (my $value = shift @{$self->{_attr1values} || []}) {
        my ($escaped, $suffix, $filter);

        # Escape LDAP characters occurring in attribute for search base.
        if ($options{suffix} =~ /[[]attrs1[]]\z/) {
            # [attrs1] should be a DN, because it is search base or its root.
            # Note: Don't canonicalize DN, because some LDAP servers e.g. AD
            #   don't conform to standard on matching rule and canonicalization
            #   might hurt integrity (cf. GH #474).
            unless (defined Net::LDAP::Util::canonical_dn($value)) {
                $log->syslog('err', 'Attribute value is not a DN: %s',
                    $value);
                next;
            }
            $escaped = $value;
        } else {
            # [attrs1] may be an attributevalue in DN.
            $escaped = Net::LDAP::Util::escape_dn_value($value);
        }
        ($suffix = $options{suffix}) =~ s/[[]attrs1[]]/$escaped/g;

        # Escape LDAP characters occurring in attribute for search filter.
        $escaped = Net::LDAP::Util::escape_filter_value($value);
        ($filter = $options{filter}) =~ s/[[]attrs1[]]/$escaped/g;

        my $mesg = $self->SUPER::_open_operation(
            suffix => $suffix,
            filter => $filter,
            attrs  => $options{attrs},
            scope  => $options{scope}
        );
        next unless $mesg;
        $self->{_ds} = $mesg;    # hack __dsh()

        my @tmp_array = $self->SUPER::_load_next(%options);
        @tmp_array = map {@$_} @tmp_array;
        push @retrieved, @tmp_array;
    }

    $self->{_retrieved} = [@retrieved];
    return $self->{_retrieved};
}

sub _next {
    my $self = shift;

    return $self->SUPER::_next(
        suffix => $self->{suffix2},
        filter => $self->{filter2},
        attrs  => $self->{attrs2},
        scope  => $self->{scope2},
        select => $self->{select2},
        regex  => $self->{regex2},
        turn   => 'last'
    );
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::DataSource::LDAP2 -
Data source based on LDAP with two-level search operations

=head1 DESCRIPTION

Returns a list of subscribers extracted indirectly from a remote LDAP
Directory using a two-level query

=head1 SEE ALSO

L<Sympa::DataSource>.

=head1 HISTORY

L<Sympa::DataSource::LDAP2> appeared on Sympa 6.2.45b.

=cut
