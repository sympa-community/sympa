# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# This file is part of Sympa, see top-level README.md file for details

package Sympa::Request::Handler::finished;

use strict;
use warnings;

use base qw(Sympa::Request::Handler);

use constant _action_scenario => undef;

# Old name: Sympa::Commands::finished().
sub _twist {
    my $self    = shift;
    my $request = shift;

    $self->add_stash($request, 'notice', 'finished');
    return 1;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Request::Handler::finished - finished request handler

=head1 DESCRIPTION

Notices the last command line.
Any requests in the message after this request will not be processed.

=head1 SEE ALSO

L<Sympa::Request::Handler>, L<Sympa::Spindle::ProcessMessage>.

=head1 HISTORY

=cut
