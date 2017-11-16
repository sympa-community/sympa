# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# This file is part of Sympa, see top-level README.md file for details

package Sympa::Request::Handler::reject;

use strict;
use warnings;
use Time::HiRes qw();

use Sympa::Log;
use Sympa::Spindle::ProcessModeration;

use base qw(Sympa::Request::Handler);

my $log = Sympa::Log->instance;

use constant _action_scenario => undef;
use constant _context_class   => 'Sympa::List';

# Old name: Sympa::Commands::reject().
sub _twist {
    my $self    = shift;
    my $request = shift;

    my $list   = $request->{context};
    my $which  = $list->{'name'};
    my $robot  = $list->{'domain'};
    my $sender = $request->{sender};

    my $key = $request->{authkey};

    my $spindle = Sympa::Spindle::ProcessModeration->new(
        rejected_by => $sender,
        context     => $list,
        authkey     => $key,
        quiet       => $request->{quiet}
    );

    unless ($spindle and $spindle->spin) {    # No message
        $log->syslog('info', 'REJECT %s %s from %s refused, auth failed',
            $list->{'name'}, $key, $sender);
        $self->add_stash($request, 'user', 'already_moderated',
            {key => $key});
        return undef;
    } elsif ($spindle->{finish} and $spindle->{finish} eq 'success') {
        $log->syslog(
            'info',          'REJECT %s %s from %s accepted (%.2f seconds)',
            $list->{'name'}, $key,
            $sender,         Time::HiRes::time() - $self->{start_time}
        );
        return 1;
    } else {
        return undef;
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Request::Handler::reject - reject request handler

=head1 DESCRIPTION

Refuse and delete a moderated message and notify sender
by sending template 'reject'.

=head1 SEE ALSO

L<Sympa::Request::Handler>, L<Sympa::Spindle::ProcessModeration>.

=head1 HISTORY

=cut
