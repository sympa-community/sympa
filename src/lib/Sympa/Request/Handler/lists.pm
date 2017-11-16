# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# This file is part of Sympa, see top-level README.md file for details

package Sympa::Request::Handler::lists;

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

# Old name: Sympa::Commands::lists().
sub _twist {
    my $self    = shift;
    my $request = shift;

    my $robot  = $request->{context};
    my $sender = $request->{sender};

    my $data  = {};
    my $lists = {};

    my $auth_method =
          $request->{smime_signed} ? 'smime'
        : $request->{md5_check}    ? 'md5'
        : $request->{dkim_pass}    ? 'dkim'
        :                            'smtp';

    foreach my $list (@{Sympa::List::get_lists($robot) || []}) {
        my $result =
            Sympa::Scenario::request_action($list, 'visibility', $auth_method,
            $self->{scenario_context});
        my $action;
        $action = $result->{'action'} if ref $result eq 'HASH';

        unless (defined $action) {
            my $error =
                sprintf
                'Unable to evaluate scenario "visibility" for list %s',
                $list->get_id;
            Sympa::send_notify_to_listmaster(
                $list,
                'intern_error',
                {   'error'          => $error,
                    'who'            => $sender,
                    'cmd'            => $request->{cmd_line},
                    'action'         => 'Command process',
                    'auto_submitted' => 'auto-replied'
                }
            );
            next;
        }

        if ($action eq 'do_it') {
            $lists->{$list->{'name'}}{'subject'} =
                $list->{'admin'}{'subject'};
            $lists->{$list->{'name'}}{'host'} = $list->{'admin'}{'host'};
        }
    }

    $data->{'lists'}          = $lists;
    $data->{'auto_submitted'} = 'auto-replied';

    unless (Sympa::send_file($robot, 'lists', $sender, $data)) {
        $log->syslog('notice', 'Unable to send template "lists" to %s',
            $sender);
        $self->add_stash($request, 'intern');
        return undef;
    }

    $log->syslog(
        'info',  'LISTS from %s accepted (%.2f seconds)',
        $sender, Time::HiRes::time() - $self->{start_time}
    );

    return 1;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Request::Handler::lists - lists request handler

=head1 DESCRIPTION

Sends back the list of public lists on this node using 'lists' template.

=head1 SEE ALSO

L<Sympa::Request::Handler>.

=head1 HISTORY

=cut
