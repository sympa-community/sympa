# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# This file is part of Sympa, see top-level README.md file for details

package Sympa::Spindle::ProcessRequest;

use strict;
use warnings;

use Sympa::Log;

use base qw(Sympa::Spindle);

my $log = Sympa::Log->instance;

use constant _distaff => 'Sympa::Request::Collection';
use constant _on_skip => 1;

sub _twist {
    my $self    = shift;
    my $request = shift;

    $log->syslog('notice', 'Processing %s', $request);

    return ['Sympa::Spindle::AuthorizeRequest'];
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Spindle::ProcessRequest - Workflow of request processing

=head1 SYNOPSIS

  use Sympa::Spindle::ProcessRequest;

  my $spindle = Sympa::Spindle::ProcessRequest->new(
      context => $robot, [options...],
      scenario_context => {sender => $sender});
  $spindle->spin;

=head1 DESCRIPTION

L<Sympa::Spindle::ProcessRequest> defines workflow to process requests.

When spin() method is invoked, it genarates requests and processes them.

TBD.

=over

=item *

=back

=head2 Public methods

See also L<Sympa::Spindle/"Public methods">.

=over

=item new ( options, ..., scenario_context =E<gt> {context...} )

=item spin ( )

new() may take following options:

=over

=item options, ...

Context (List or Robot) and other options to generate the requests.
See L<Sympa::Request> for more details.

If one of their value is arrayref, repeatedly generates instances over each
array item.

=item scenario_context =E<gt> {context...}

Authorization context given to scenario.

=back

=back

=head2 Properties

See also L<Sympa::Spindle/"Properties">.

=over

=item {distaff}

Instance of L<Sympa::Request::Collection> class.

=back

=head1 SEE ALSO

L<Sympa::Request>,
L<Sympa::Request::Collection>,
L<Sympa::Spindle>, L<Sympa::Spindle::AuthorizeRequest>,

=head1 HISTORY

L<Sympa::Spindle::ProcessRequest> appeared on Sympa 6.2.15.

=cut
