# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# This file is part of Sympa, see top-level README.md file for details

package Sympa::Spool::Bounce;

use strict;
use warnings;

use Conf;

use base qw(Sympa::Spool::Incoming);

sub _directories {
    return {
        directory     => $Conf::Conf{'queuebounce'},
        bad_directory => $Conf::Conf{'queuebounce'} . '/bad',
    };
}

use constant _filter => 1;
use constant _init   => 1;

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Spool::Bounce - Spool for incoming bounce messages

=head1 SYNOPSIS

  use Sympa::Spool::Bounce;
  my $spool = Sympa::Spool::Bounce->new;
  
  my ($message, $handle) = $spool->next;

=head1 DESCRIPTION

L<Sympa::Spool::Bounce> implements the spool for incoming bounce messages.

=head2 Methods

See also L<Sympa::Spool/"Public methods">.

=over

=item next ( )

Order is controlled by modification time of files and delivery date.

=item store ( $message, [ original =E<gt> $original ] )

In most cases, bouncequeue(8) program stores messages to bounce spool.
This method is not used in ordinal case.

=back

=head2 Context and metadata

See also L<Sympa::Spool/"Marshaling and unmarshaling metadata">.

This class particularly gives following metadata:

=over

=item {date}

Unix time when the message would be delivered.

=back

=head1 CONFIGURATION PARAMETERS

Following site configuration parameters in sympa.conf will be referred.

=over

=item queuebounce

Directory path of bounce spool.

=back

=head1 SEE ALSO

L<bounced(8)>, L<Sympa::Message>, L<Sympa::Spool>, L<Sympa::Tracking>.

=head1 HISTORY

L<Sympa::Spool::Bounce> appeared on Sympa 6.2.6.

=cut
