# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# This file is part of Sympa, see top-level README.md file for details

package Sympa::DatabaseDriver::Informix;

use strict;
use warnings;

use base qw(Sympa::DatabaseDriver);

use constant required_modules => [qw(DBD::Informix)];

sub build_connect_string {
    my $self = shift;

    return 'DBI:Informix:' . $self->{'db_name'} . '@' . $self->{'db_host'};
}

1;
