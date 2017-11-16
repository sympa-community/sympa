# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# This file is part of Sympa, see top-level README.md file for details

package Sympa::Request::Handler::import;

use strict;
use warnings;
use Time::HiRes qw();

use Sympa::Log;
use Sympa::Spindle::ProcessRequest;

use base qw(Sympa::Request::Handler);

my $log = Sympa::Log->instance;

use constant _action_scenario => undef;
use constant _context_class   => 'Sympa::List';

sub _twist {
    my $self    = shift;
    my $request = shift;

    my $list   = $request->{context};
    my $sender = $request->{sender};

    unless ($request->{force}) {
        # If a list is not 'open' and allow_subscribe_if_pending has been set
        # to 'off' returns undef.
        unless (
            $list->{'admin'}{'status'} eq 'open'
            or Conf::get_robot_conf($list->{'domain'},
                'allow_subscribe_if_pending') eq 'on'
            ) {
            $self->add_stash($request, 'user', 'list_not_open',
                {'status' => $list->{'admin'}{'status'}});
            $log->syslog('info', 'List %s not open', $list);
            return undef;
        }
    }

    my @users = map {
        my ($email, $gecos) = m{\A\s*(\S+)(?:\s+(.*))?\s*\z};

        (defined $gecos and $gecos =~ /\S/)
            ? {email => $email, gecos => $gecos}
            : {email => $email}
        } grep {
        /\S/ and !/\A\s*#/
        }
        split /\r\n|\r|\n/, ($request->{dump} || '');

    my $processed = 0;
    foreach my $user (@users) {
        my $spindle = Sympa::Spindle::ProcessRequest->new(
            context          => $list,
            action           => 'add',
            email            => $user->{email},
            gecos            => $user->{gecos},
            quiet            => $request->{quiet},
            force            => $request->{force},
            sender           => $sender,
            md5_check        => $request->{md5_check},
            scenario_context => {
                %{$self->{scenario_context} || {}},
                sender => $sender,
                email  => $user->{email},
            },
            stash => $self->{stash},
        );
        $spindle and $processed += $spindle->spin;
    }
    unless ($processed) {    # No message
        $log->syslog('info', 'Import %s from %s failed, no e-mails to add',
            $list, $sender);
        $self->add_stash($request, 'user', 'no_email');
        return undef;
    }

    $log->syslog(
        'info', 'Import %s from %s finished (%.2f seconds)',
        $list, $sender, Time::HiRes::time() - $self->{start_time},
    );
    return 1;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Request::Handler::import - import request handler

=head1 DESCRIPTION

Add subscribers to the list.
E-mails and display names of subscribers are taken from {dump} parameter,
the text including lines describing users to be added.

=head2 Attributes

=over

=item {dump}

I<Mandatory>.
Text including information of users to be added.

=item {force}

I<Optional>.
If true value is specified,
users will be added even if the list is closed.

=back

=head1 SEE ALSO

L<Sympa::Request::Handler>, L<Sympa::Request::Handler::add>.

=head1 HISTORY

L<Sympa::Request::Handler::import> appeared on Sympa 6.2.19b.

=cut
