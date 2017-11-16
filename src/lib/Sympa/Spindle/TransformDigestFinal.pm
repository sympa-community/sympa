# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# This file is part of Sympa, see top-level README.md file for details

package Sympa::Spindle::TransformDigestFinal;

use strict;
use warnings;

use Sympa::Robot;

use base qw(Sympa::Spindle);

sub _twist {
    my $self    = shift;
    my $message = shift;

    my $list = $message->{context};

    $list->add_list_header($message, 'id');
    # Add RFC 2369 header fields
    foreach my $field (
        @{  Sympa::Robot::list_params($list->{'domain'})
                ->{'rfc2369_header_fields'}->{'format'}
        }
        ) {
        if (scalar grep { $_ eq $field }
            @{$list->{'admin'}{'rfc2369_header_fields'}}) {
            $list->add_list_header($message, $field);
        }
    }

    1;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Spindle::TransformDigestFinal -
Process to transform digest messages - final stage

=head1 DESCRIPTION

L<Sympa::Spindle::TransformDigestFinal> decorates messages bound for list
members with C<digest>, C<digestplain> or C<summary> reception mode.

This class represents the series of following processes:

=over

=item *

Adding RFC 2919 C<List-Id:> header field.

=item *

Adding RFC 2369 mailing list header fields.

=back

=head1 SEE ALSO

L<Sympa::Message>,
L<Sympa::Spindle>,
L<Sympa::Spindle::ProcessDigest>.

=head1 HISTORY

L<Sympa::Spindle::TransformDigestFinal> appeared on Sympa 6.2.13.

=cut
