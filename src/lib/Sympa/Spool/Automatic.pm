# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# This file is part of Sympa, see top-level README.md file for details

package Sympa::Spool::Automatic;

use strict;
use warnings;

use Conf;

use base qw(Sympa::Spool::Incoming);

sub _directories {
    return {
        directory     => $Conf::Conf{'queueautomatic'},
        bad_directory => $Conf::Conf{'queueautomatic'} . '/bad',
    };
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Spool::Automatic - Spool for incoming messages in automatic spool

=head1 SYNOPSIS

  use Sympa::Spool::Automatic;
  my $spool = Sympa::Spool::Automatic->new;

  my ($message, $handle) = $spool->next;

=head1 DESCRIPTION

L<Sympa::Spool::Automatic> implements the spool for incoming messages in
automatic spool.

=head2 Methods

See also L<Sympa::Spool/"Public methods">.

=over

=item next ( [ no_filter =E<gt> 1 ], [ no_lock =E<gt> 1 ] )

I<Instance method>.
Order is controlled by modification time of files and delivery date, then,
if C<no_filter> is I<not> set,
messages with possiblly higher priority are chosen and
messages with lowest priority (C<z> or C<Z>) are skipped.

=item store ( $message, [ original =E<gt> $original ] )

In most cases, familyqueue(8) program stores messages to automatic spool.
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

=item queueautomatic

Directory path of list creation spool.

=back

=head1 SEE ALSO

L<sympa_automatic(8)>, L<Sympa::Message>, L<Sympa::Spool>.

=head1 HISTORY

L<Sympa::Spool::Automatic> appeared on Sympa 6.2.6.

=cut
