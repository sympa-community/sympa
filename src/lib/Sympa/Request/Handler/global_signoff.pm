# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# This file is part of Sympa, see top-level README.md file for details

package Sympa::Request::Handler::global_signoff;

use strict;
use warnings;

use Sympa;
use Sympa::List;
use Sympa::Log;
use Sympa::Scenario;
use Sympa::Spindle::ProcessRequest;

use base qw(Sympa::Request::Handler);

my $log = Sympa::Log->instance;

use constant _action_scenario => undef;

# Old name: (part of) Sympa::Commands::signoff().
sub _twist {
    my $self    = shift;
    my $request = shift;

    my $sender = $request->{sender};
    my $email  = $request->{email};

    my $auth_method =
          $request->{smime_signed} ? 'smime'
        : $request->{md5_check}    ? 'md5'
        : $request->{dkim_pass}    ? 'dkim'
        :                            'smtp';

    my @target_lists;
    foreach my $list (
        Sympa::List::get_which($email, $request->{context}, 'member')) {
        # Skip hidden lists.
        my $result =
            Sympa::Scenario::request_action($list, 'visibility', $auth_method,
            $self->{scenario_context});
        my $action = $result->{'action'} if ref $result eq 'HASH';

        unless ($action) {
            my $error =
                sprintf 'Unable to evaluate scenario "visibility" for list ',
                $list->get_id;
            Sympa::send_notify_to_listmaster(
                $list,
                'intern_error',
                {   'error'  => $error,
                    'who'    => $sender,
                    'cmd'    => $request->{cmd_line},
                    'action' => 'Command process'
                }
            );
            next;
        }

        if ($action =~ /\Areject\b/i) {
            next;
        }

        push @target_lists, $list;
    }
    unless (@target_lists) {
        $self->add_stash($request, 'user', 'no_lists');
        $log->syslog('info', 'SIG * %s from %s refused, no lists to process',
            $email, $sender);
        return undef;
    }

    my $spindle = Sympa::Spindle::ProcessRequest->new(
        context => [@target_lists],
        action  => 'signoff',
        (   map { ($_ => $request->{$_}) }
                qw(email sender smime_signed md5_check dkim_pass cmd_line)
        ),

        scenario_context => $self->{scenario_context},
        stash            => $self->{stash},
    );
    $spindle and $spindle->spin;

    return 1;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Request::Handler::global_signoff - global 'signoff' request handler

=head1 DESCRIPTION

Unsubscribes a user from list(s).
The user can be informed by template 'bye'.

=head1 SEE ALSO

L<Sympa::Request::Handler>.

=head1 HISTORY

=cut
