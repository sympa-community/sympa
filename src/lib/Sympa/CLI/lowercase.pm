# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright 2021 The Sympa Community. See the
# AUTHORS.md file at the top-level directory of this distribution and at
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

package Sympa::CLI::lowercase;

use strict;
use warnings;

use Sympa::DatabaseManager;
use Sympa::List;
use Sympa::Log;

use parent qw(Sympa::CLI);

use constant _options => qw();
use constant _args    => qw();

my $log = Sympa::Log->instance;

sub _run {
    my $class   = shift;
    my $options = shift;

    print STDERR "Working on user_table...\n";
    my $total = _lowercase_field('user_table', 'email_user');

    if (defined $total) {
        print STDERR "Working on subscriber_table...\n";
        my $total_sub =
            _lowercase_field('subscriber_table', 'user_subscriber');
        if (defined $total_sub) {
            $total += $total_sub;
        }
    }

    unless (defined $total) {
        print STDERR "Could not work on dabatase.\n";
        exit 1;
    }

    printf STDERR "Total lowercased rows: %d\n", $total;

    exit 0;
}

# Lowercase field from database.
# Old names: List::lowercase_field(), Sympa::List::lowercase_field().
sub _lowercase_field {
    my ($table, $field) = @_;

    my $sth;
    my $sdm   = Sympa::DatabaseManager->instance;
    my $total = 0;

    unless ($sdm
        and $sth = $sdm->do_query(q{SELECT %s FROM %s}, $field, $table)) {
        $log->syslog('err', 'Unable to get values of field %s for table %s',
            $field, $table);
        return undef;
    }

    while (my $user = $sth->fetchrow_hashref('NAME_lc')) {
        my $lower_cased = lc($user->{$field});
        next if $lower_cased eq $user->{$field};

        $total++;

        ## Updating database.
        unless (
            $sth = $sdm->do_prepared_query(
                sprintf(
                    q{UPDATE %s SET %s = ? WHERE %s = ?},
                    $table, $field, $field
                ),
                $lower_cased,
                $user->{$field}
            )
        ) {
            $log->syslog('err',
                'Unable to set field % from table %s to value %s',
                $field, $lower_cased, $table);
            next;
        }
    }
    $sth->finish();

    return $total;
}

1;
__END__

=encoding utf-8

=head1 NAME

sympa-lowercase - Lowercase email addresses in database

=head1 SYNOPSIS

C<sympa lowercase>

=head1 DESCRIPTION

Lowercase email addresses in database.

=cut
