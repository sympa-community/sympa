# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# This file is part of Sympa, see top-level README.md file for details

package Sympa::Request::Handler::remind;

use strict;
use warnings;
use Time::HiRes qw();

use Sympa;
use Sympa::Language;
use Sympa::Log;

use base qw(Sympa::Request::Handler);

my $language = Sympa::Language->instance;
my $log      = Sympa::Log->instance;

use constant _action_scenario => 'remind';
use constant _action_regexp   => qr'reject|request_auth|do_it'i;
use constant _context_class   => 'Sympa::List';

# Old name: (part of) Sympa::Commands::remind().
sub _twist {
    my $self    = shift;
    my $request = shift;

    my $list     = $request->{context};
    my $listname = $list->{'name'};
    my $robot    = $list->{'domain'};
    my $sender   = $request->{sender};

    $language->set_lang($list->{'admin'}{'lang'});

    # For each subscriber send a reminder.
    my $total = 0;
    my $user;

    unless ($user = $list->get_first_list_member()) {
        my $error = "Unable to get subscribers for list $listname";
        Sympa::send_notify_to_listmaster(
            $list,
            'mail_intern_error',
            {   error  => $error,
                who    => $sender,
                action => 'Command process',
            }
        );
        $self->add_stash($request, 'intern');
        return undef;
    }

    do {
        unless ($list->send_probe_to_user('remind', $user->{'email'})) {
            $log->syslog('notice', 'Unable to send "remind" probe to %s',
                $user->{'email'});
            $self->add_stash($request, 'intern');
        }
        $total += 1;
    } while ($user = $list->get_next_list_member());

    $self->add_stash($request, 'notice', 'remind', {total => $total});
    $log->syslog(
        'info',
        'REMIND %s from %s accepted, sent to %d subscribers (%.2f seconds)',
        $listname,
        $sender,
        $total,
        Time::HiRes::time() - $self->{start_time}
    );

    return 1;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Request::Handler::remind - remind request handler

=head1 DESCRIPTION

Sends a personal reminder to each subscriber of one list
using template 'remind'.

=head1 SEE ALSO

L<Sympa::Request::Handler>.

=head1 HISTORY

=cut
