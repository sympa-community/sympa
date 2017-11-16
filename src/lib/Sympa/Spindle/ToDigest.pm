# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# This file is part of Sympa, see top-level README.md file for details

package Sympa::Spindle::ToDigest;

use strict;
use warnings;

use Sympa::Spool::Digest;
use Sympa::Tools::Data;

use base qw(Sympa::Spindle);

# Old name: (part of) Sympa::List::distribute_msg().
sub _twist {
    my $self    = shift;
    my $message = shift;

    my $list = $message->{context};

    # Store message into digest spool if list accept digest mode.
    # Note that encrypted message can't be included in digest.
    if ($list->is_digest()
        and not Sympa::Tools::Data::smart_eq(
            $message->{'smime_crypted'},
            'smime_crypted'
        )
        ) {
        my $spool_digest = Sympa::Spool::Digest->new(context => $list);
        $spool_digest->store($message) if $spool_digest;
    }

    1;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Spindle::ToDigest - Process to store messages into digest spool

=head1 DESCRIPTION

TBD.

=head1 SEE ALSO

L<Sympa::Message>,
L<Sympa::Spindle>, L<Sympa::Spindle::DistributeMessage>,
L<Sympa::Spool::Digest>.

=head1 HISTORY

L<Sympa::Spindle::ToDigest> appeared on Sympa 6.2.13.

=cut
