# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# This file is part of Sympa, see top-level README.md file for details

package Sympa::Request::Handler::confirm;

use strict;
use warnings;
use Time::HiRes qw();

use Sympa::Log;
use Sympa::Spindle::ProcessHeld;

use base qw(Sympa::Request::Handler);

my $log = Sympa::Log->instance;

use constant _action_scenario => undef;

# Old name: Sympa::Commands::confirm().
sub _twist {
    my $self    = shift;
    my $request = shift;

    my $robot  = $request->{context};
    my $sender = $request->{sender};

    my $key = $request->{authkey};

    my $spindle = Sympa::Spindle::ProcessHeld->new(
        confirmed_by => $sender,
        context      => $robot,
        authkey      => $key,
        quiet        => $request->{quiet}
    );

    unless ($spindle and $spindle->spin) {    # No message.
        $log->syslog('info', 'CONFIRM %s from %s refused, auth failed',
            $key, $sender);
        $self->add_stash($request, 'user', 'already_confirmed',
            {'key' => $key});
        return undef;
    } elsif ($spindle->{finish} and $spindle->{finish} eq 'success') {
        $log->syslog('info', 'CONFIRM %s from %s accepted (%.2f seconds)',
            $key, $sender, Time::HiRes::time() - $self->{start_time});
        return 1;
    } else {
        return undef;
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Request::Handler::confirm - confirm request handler

=head1 DESCRIPTION

Confirms the authentication of a message for its
distribution on a list.

=head1 SEE ALSO

L<Sympa::Request::Handler>, L<Sympa::Spindle::ProcessHeld>.

=head1 HISTORY

=cut
