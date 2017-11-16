# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# This file is part of Sympa, see top-level README.md file for details

package Sympa::Request::Handler::unknown;

use strict;
use warnings;

use Sympa::Log;

use base qw(Sympa::Request::Handler);

my $log = Sympa::Log->instance;

use constant _action_scenario => undef;
use constant _context_class   => undef;    # Don't care.

# Old name: Sympa::Commands::unknown().
sub _twist {
    my $self    = shift;
    my $request = shift;

    $log->syslog('notice', 'Unknown command found: %s', $request->{cmd_line});
    $self->add_stash($request, 'user', 'unknown_command');
    return undef;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Request::Handler::unknown - unknown request handler

=head1 DESCRIPTION

Internally-used request to inform unknown commands.

=head1 SEE ALSO

L<Sympa::Request::Handler>.

=head1 HISTORY

=cut
