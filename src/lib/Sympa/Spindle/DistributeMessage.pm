# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# This file is part of Sympa, see top-level README.md file for details

package Sympa::Spindle::DistributeMessage;

use strict;
use warnings;

use base qw(Sympa::Spindle);

# prepares and distributes a message to a list, do
# some of these :
# stats, hidding sender, adding custom subject,
# archive, changing the replyto, removing headers,
# adding headers, storing message in digest
sub _twist {
    return [
        'Sympa::Spindle::TransformIncoming', 'Sympa::Spindle::ToArchive',
        'Sympa::Spindle::TransformOutgoing', 'Sympa::Spindle::ToDigest',
        'Sympa::Spindle::ToList'
    ];
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Spindle::DistributeMessage -
Workflow to distribute messages to list members

=head1 DESCRIPTION

L<Sympa::Spindle::DistributeMessage> distributes incoming messages to list
members.

This class represents the series of following processes:

=over

=item L<Sympa::Spindle::TransformIncoming>

Process to transform messages - first stage

=item L<Sympa::Spindle::ToArchive>

Process to store messages into archiving spool

=item L<Sympa::Spindle::TransformOutgoing>

Process to transform messages - second stage

=item L<Sympa::Spindle::ToDigest>

Process to store messages into digest spool

=item L<Sympa::Spindle::ToList>

Process to distribute messages to list members

=back

=head2 Public methods

See also L<Sympa::Spindle/"Public methods">.

=over

=item new ( key =E<gt> value, ... )

In most cases, L<Sympa::Spindle::DoMessage>
splices meessages to this class.  This method is not used in ordinal case.

=item spin ( )

Not implemented.

=back

=head1 SEE ALSO

L<Sympa::Spindle>, L<Sympa::Spindle::DoMessage>,
L<Sympa::Spindle::ProcessModeration>.

=head1 HISTORY

L<Sympa::Spindle::DistributeMessage> appeared on Sympa 6.2.13.

=cut
