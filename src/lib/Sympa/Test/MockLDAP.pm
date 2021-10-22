# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

package Sympa::Test::MockLDAP;

use strict;
use warnings;
BEGIN { eval 'use Test::Net::LDAP::Util qw(ldap_mockify)'; }

use Sympa::DatabaseDriver::LDAP;

sub build {
    my @entries = @_;

    no warnings qw(redefine);
    *Sympa::DatabaseDriver::LDAP::_connect = sub {
        my $ldap;
        ldap_mockify {
            $ldap = Net::LDAP->new;

            foreach my $entry (@entries) {
                $ldap->add(@$entry);
            }
        };
        $ldap;
    };
}

1;
__END__

=encoding UTF-8

=head1 NAME

Sympa::Test::MockLDAP - Mocking LDAP directory

=head1 DESCRIPTION

L<Sympa::Test::MockLDAP> mocks LDAP directory on memory so that it will be
used in unit tests.

=head2 Functions

=over

=item build ( entries... )

Builds mocked directory on memory.

I<entries...> is a list of arrayref to arguments fed to add().

=back

=head1 SEE ALSO

L<Sympa::DatabaseDriver::LDAP>,
L<Sympa::DataSource::LDAP>,
L<Sympa::DataSource::LDAP2>.

=head1 HISTORY

L<Sympa::Test::MockLDAP> appeared on Sympa 6.2.55b.

=cut


