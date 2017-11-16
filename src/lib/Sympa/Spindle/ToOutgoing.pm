# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# This file is part of Sympa, see top-level README.md file for details

package Sympa::Spindle::ToOutgoing;

use strict;
use warnings;

use Sympa::Bulk;

use base qw(Sympa::Spindle);

sub _twist {
    my $self    = shift;
    my $message = shift;

    my $status =
        Sympa::Bulk->new->store($message, $message->{rcpt},
        tag => $message->{tag});

    if (    $status
        and ref $message->{context} eq 'Sympa::List'
        and $self->{add_list_statistics}) {
        my $list = $message->{context};

        # Add number and size of digests sent to total in stats file.
        my $numsent = scalar @{$message->{rcpt} || []};
        my $bytes = length $message->as_string;
        $list->{'stats'}[1] += $numsent;
        $list->{'stats'}[2] += $bytes;
        $list->{'stats'}[3] += $bytes * $numsent;
    }

    $status ? 1 : undef;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Spindle::ToOutgoing - Process to store messages into outgoing spool

=head1 DESCRIPTION

TBD.

=head1 SEE ALSO

L<Sympa::Message>,
L<Sympa::Spindle>,
L<Sympa::Bulk>.

=head1 HISTORY

L<Sympa::Spindle::ToOutgoing> appeared on Sympa 6.2.13.

=cut
