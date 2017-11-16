# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# This file is part of Sympa, see top-level README.md file for details

package Sympa::DatabaseDriver::ODBC;

use strict;
use warnings;

use base qw(Sympa::DatabaseDriver);

use constant required_modules    => [qw(DBD::ODBC)];
use constant required_parameters => [qw(db_name db_user db_passwd)];
use constant optional_parameters => [];

sub build_connect_string {
    my $self = shift;
    return 'DBI:ODBC:' . $self->{'db_name'};
}

sub get_formatted_date {
    my $self  = shift;
    my $param = shift;

    die 'Not yet implemented: This is required by Sympa';
}

sub translate_type {
    my $self = shift;
    my $type = shift;

    return undef unless $type;

    # ODBC
    $type =~ s/^double/real/g;
    $type =~ s/^enum.*/varchar(20)/g;
    $type =~ s/^text.*/varchar(500)/g;
    $type =~ s/^longtext.*/text/g;
    $type =~ s/^datetime/timestamp/g;
    $type =~ s/^mediumblob/longvarbinary/g;
    return $type;
}

sub AS_DOUBLE {
    return ({'TYPE' => DBI::SQL_DOUBLE()} => $_[1])
        if scalar @_ > 1;
    return ();
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::DatabaseDriver::ODBC - Database driver for ODBC

=head1 DESCRIPTION

I<This module is under development>.

=head1 SEE ALSO

L<Sympa::DatabaseDriver>.

=cut
