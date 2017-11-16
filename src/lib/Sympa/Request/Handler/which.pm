# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# This file is part of Sympa, see top-level README.md file for details

package Sympa::Request::Handler::which;

use strict;
use warnings;
use Time::HiRes qw();

use Sympa;
use Sympa::List;
use Sympa::Log;
use Sympa::Scenario;

use base qw(Sympa::Request::Handler);

my $log = Sympa::Log->instance;

use constant _action_scenario => undef;

# Old name: Sympa::Commands::which().
sub _twist {
    my $self    = shift;
    my $request = shift;

    my $robot  = $request->{context};
    my $sender = $request->{sender};

    my ($listname, @which);

    my $auth_method =
          $request->{smime_signed} ? 'smime'
        : $request->{md5_check}    ? 'md5'
        : $request->{dkim_pass}    ? 'dkim'
        :                            'smtp';

    # Subscriptions.
    my $data;
    foreach my $list (Sympa::List::get_which($sender, $robot, 'member')) {
        $listname = $list->{'name'};

        my $result =
            Sympa::Scenario::request_action($list, 'visibility', $auth_method,
            $self->{scenario_context});
        my $action;
        $action = $result->{'action'} if ref $result eq 'HASH';

        unless (defined $action) {
            my $error =
                "Unable to evaluate scenario 'visibility' for list $listname";
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

        next unless ($action =~ /do_it/);

        push @{$data->{'lists'}}, $listname;
    }

    ## Ownership
    if (@which = Sympa::List::get_which($sender, $robot, 'owner')) {
        foreach my $list (@which) {
            push @{$data->{'owner_lists'}}, $list->{'name'};
        }
        $data->{'is_owner'} = 1;
    }

    ## Editorship
    if (@which = Sympa::List::get_which($sender, $robot, 'editor')) {
        foreach my $list (@which) {
            push @{$data->{'editor_lists'}}, $list->{'name'};
        }
        $data->{'is_editor'} = 1;
    }

    unless (Sympa::send_file($robot, 'which', $sender, $data)) {
        $log->syslog('notice', 'Unable to send template "which" to %s',
            $sender);
        $self->add_stash($request, 'intern');
        return undef;
    }

    $log->syslog(
        'info',  'WHICH from %s accepted (%.2f seconds)',
        $sender, Time::HiRes::time() - $self->{start_time}
    );

    return 1;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Request::Handler::which - which request handler

=head1 DESCRIPTION

Returns list of lists that sender is subscribed. If he is
owner and/or editor, managed lists are also noticed.
The 'which' template is used.

=head1 SEE ALSO

L<Sympa::Request::Handler>.

=head1 HISTORY

=cut
