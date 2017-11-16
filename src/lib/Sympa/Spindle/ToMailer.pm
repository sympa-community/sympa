# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# This file is part of Sympa, see top-level README.md file for details

package Sympa::Spindle::ToMailer;

use strict;
use warnings;

use Sympa::Mailer;

use base qw(Sympa::Spindle);

sub _twist {
    my $self    = shift;
    my $message = shift;

    # ToDo: Consider envid and tag.
    return Sympa::Mailer->instance->store($message, $message->{rcpt})
        ? 1
        : undef;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Spindle::ToMailer - Process to store messages into sendmail component

=head1 DESCRIPTION

TBD.

=head1 SEE ALSO

L<Sympa::Message>,
L<Sympa::Spindle>,
L<Sympa::Mailer>.

=head1 HISTORY

L<Sympa::Spindle::ToMailer> appeared on Sympa 6.2.13.

=cut
