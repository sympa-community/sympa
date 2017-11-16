# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# This file is part of Sympa, see top-level README.md file for details

package Sympa::Spindle::ProcessMessage;

use strict;
use warnings;

use Sympa::Log;

use base qw(Sympa::Spindle);

my $log = Sympa::Log->instance;

use constant _distaff    => 'Sympa::Request::Message';
use constant _on_failure => 1;
use constant _on_garbage => 1;

sub _on_skip {
    shift->{success} = 1;
}

sub _on_success {
    shift->{success} = 1;
}

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

Sympa::Spindle::ProcessMessage - Workflow of command processing

=head1 SYNOPSIS

  use Sympa::Spindle::ProcessMessage;

  my $spindle = Sympa::Spindle::ProcessMessage->new(
      message => $message, scenario_context => {sender => $sender});
  $spindle->spin;

=head1 DESCRIPTION

L<Sympa::Spindle::ProcessMessage> defines workflow to process commands in
message.

When spin() method is invoked, it parses message and fetch requests and
processes them.

TBD.

=over

=item *

=back

=head2 Public methods

See also L<Sympa::Spindle/"Public methods">.

=over

=item new ( scenario_context =E<gt> {context...}, [ message =E<gt> $message ] )

=item spin ( )

new() may take following options:

=over

=item scenario_context =E<gt> {context...}

Authorization context given to scenario.

=item message =E<gt> $message

See L<Sympa::Request::Message>.

=back

=back

=head2 Properties

See also L<Sympa::Spindle/"Properties">.

=over

=item {distaff}

Instance of L<Sympa::Request::Message> class.

=back

=head1 SEE ALSO

L<Sympa::Request>,
L<Sympa::Request::Message>,
L<Sympa::Spindle>.

=head1 HISTORY

L<Sympa::Spindle::ProcessMessage> appeared on Sympa 6.2.13.

=cut
