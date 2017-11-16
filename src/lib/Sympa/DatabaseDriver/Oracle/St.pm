# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# This file is part of Sympa, see top-level README.md file for details

package Sympa::DatabaseDriver::Oracle::St;

use strict;
use warnings;
use DBI qw();
use Encode qw();

# 'base' pragma doesn't work here
our @ISA = qw(DBI::st);

sub fetchrow {
    goto &fetchrow_array;    # '&' is required.
}

sub fetchrow_array {
    my $self   = shift;
    my @values = $self->SUPER::fetchrow_array(@_);
    return unless @values;

    foreach my $value (@values) {
        Encode::_utf8_off($value)
            if defined $value and Encode::is_utf8($value);
    }
    wantarray ? @values : $values[0];
}

sub fetchrow_hashref {
    my $self   = shift;
    my $values = $self->SUPER::fetchrow_hashref(@_);
    return undef unless $values;

    foreach my $value (values %$values) {
        Encode::_utf8_off($value)
            if defined $value and Encode::is_utf8($value);
    }
    $values;
}

sub fetchall_arrayref {
    my $self      = shift;
    my $allvalues = $self->SUPER::fetchall_arrayref(@_);
    return undef unless $allvalues;

    if (ref $_[0] eq 'HASH') {
        foreach my $values (@$allvalues) {
            foreach my $value (values %$values) {
                Encode::_utf8_off($value)
                    if defined $value and Encode::is_utf8($value);
            }
        }
    } else {
        foreach my $values (@$allvalues) {
            foreach my $value (@$values) {
                Encode::_utf8_off($value)
                    if defined $value and Encode::is_utf8($value);
            }
        }
    }
    $allvalues;
}

sub fetchall_hashref {
    my $self      = shift;
    my $allvalues = $self->SUPER::fetchall_hashref(@_);
    return undef unless $allvalues;

    foreach my $values (values %$allvalues) {
        foreach my $value (values %$values) {
            Encode::_utf8_off($value)
                if defined $value and Encode::is_utf8($value);
        }
    }
    $allvalues;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::DatabaseDriver::Oracle::St - Correcting behavior of DBD::Oracle

=head1 DESCRIPTION

If C<NLS_LANG> environment variable is properly set with charset
C<AL32UTF8> (or C<UTF8>), L<DBD::Oracle> handles character values as
Unicode, i.e. "utf8 flags" are set.  This behavior is not desirable for Sympa.

Sympa::DatabaseDriver::Oracle::St overrides functions of DBI statement handle
object to reset utf8 flags.

=head1 HISTORY

L<Sympa::DatabaseDriver::Oracle::St> appears on Sympa 6.2.

=cut
