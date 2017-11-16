# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# This file is part of Sympa, see top-level README.md file for details

package Sympa::DatabaseDriver::CSV;

use strict;
use warnings;

use base qw(Sympa::DatabaseDriver);

use constant required_modules    => [qw(DBD::CSV)];
use constant required_parameters => [qw(f_dir)];
use constant optional_parameters => [qw(db_options)];

sub build_connect_string {
    my $self = shift;

    my $connect_string = 'DBI:CSV:f_dir=' . $self->{'f_dir'};
    $connect_string .= ';' . $self->{'db_options'}
        if defined $self->{'db_options'};
    return $connect_string;
}

1;

=encoding utf-8

=head1 NAME

Sympa::DatabaseDriver::CSV - Database driver for CSV

=head1 SEE ALSO

L<Sympa::DatabaseDriver>.

=cut
