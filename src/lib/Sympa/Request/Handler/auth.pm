# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# This file is part of Sympa, see top-level README.md file for details

package Sympa::Request::Handler::auth;

use strict;
use warnings;
use Time::HiRes qw();

use Sympa;
use Sympa::Log;
use Sympa::Spindle::ProcessAuth;

use base qw(Sympa::Request::Handler);

my $log = Sympa::Log->instance;

use constant _action_scenario => undef;

sub _twist {
    my $self    = shift;
    my $request = shift;

    my $key    = $request->{keyauth};
    my $sender = $request->{sender};

    # Optional $request->{request} is given by Sympa::Request::Message to
    # check if "cmd" argument of e-mail command matches with held request.
    my $req     = $request->{request};
    my $spindle = Sympa::Spindle::ProcessAuth->new(
        (   $req
            ? ( context => $req->{context},
                action  => $req->{action},
                email   => $req->{email}
                )
            : ()
        ),
        keyauth      => $key,
        confirmed_by => $sender,

        scenario_context => $self->{scenario_context},
        stash            => $self->{stash},
    );

    unless ($spindle and $spindle->spin) {
        $log->syslog('info', 'AUTH %s from %s refused, auth failed',
            $key, $sender);
        $self->add_stash($request, 'user', 'wrong_email_confirm',
            {key => $key, command => $req->{action}});
        return undef;
    } elsif ($spindle->{finish} and $spindle->{finish} eq 'success') {
        return 1;
    } else {
        return undef;
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Request::Handler::auth - auth request handler

=head1 DESCRIPTION

Fetchs the request matching with {authkey} and optional {request} attributes
from held request spool,
and if succeeded, processes it with C<md5> authentication level.

=head1 CAVEAT

Auth request handler itself never check privileges:
It trust in senders if valid authorization key is specified.
Access to this handler should be restricted sufficiently by applications.

=head1 SEE ALSO

L<Sympa::Request::Handler>, L<Sympa::Spindle::ProcessAuth>.

=head1 HISTORY

L<Sympa::Request::Handler::auth> appeared on Sympa 6.2.15.

=cut
