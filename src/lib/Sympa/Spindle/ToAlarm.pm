# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# This file is part of Sympa, see top-level README.md file for details

package Sympa::Spindle::ToAlarm;

use strict;
use warnings;

use Sympa::Alarm;

use base qw(Sympa::Spindle);

sub _twist {
    my $self    = shift;
    my $message = shift;

    return Sympa::Alarm->instance->store($message, $message->{rcpt},
        operation => $self->{data}{type}) ? 1 : undef;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Spindle::ToAlarm -
Process to store messages into spool on memory for listmaster notification

=head1 DESCRIPTION

TBD.

=head1 SEE ALSO

L<Sympa::Message>,
L<Sympa::Spindle>, L<Sympa::Spindle::ProcessTemplate>,
L<Sympa::Alarm>.

=head1 HISTORY

L<Sympa::Spindle::ToAlarm> appeared on Sympa 6.2.13.

=cut
