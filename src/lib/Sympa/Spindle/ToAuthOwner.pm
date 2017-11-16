# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# This file is part of Sympa, see top-level README.md file for details

package Sympa::Spindle::ToAuthOwner;

use strict;
use warnings;
use Time::HiRes qw();

use Sympa;
use Sympa::Log;
use Sympa::Request;
use Sympa::Spool::Auth;

use base qw(Sympa::Spindle);

my $log = Sympa::Log->instance;

sub _twist {
    my $self    = shift;
    my $request = shift;

    my $list   = $request->{context};
    my $sender = $request->{sender};

    my $tpl =
        {subscribe => 'subrequest', signoff => 'sigrequest'}
        ->{$request->{action}};
    my $owner_action = $request->handler->owner_action || $request->{action};

    my $spool_req   = Sympa::Spool::Auth->new;
    my $add_request = Sympa::Request->new(
        action => $owner_action,
        # Keep date of message.
        (   map { ($_ => $request->{$_}) }
                qw(date context custom_attribute email gecos sender)
        ),
    );
    my $keyauth;
    unless ($keyauth = $spool_req->store($add_request)) {
        $self->add_stash($request, 'intern');
        return undef;
    }

    # Send a notice to the owners.
    unless (
        $list->send_notify_to_owner(
            $tpl,
            {   'who'     => $sender,
                'keyauth' => $keyauth,
                'replyto' => Sympa::get_address($list, 'sympa'),
                'gecos'   => $request->{gecos},
            }
        )
        ) {
        #FIXME: Why is error reported only in this case?
        $log->syslog('info', 'Unable to send notify "%s" to %s list owner',
            $tpl, $list);
        my $error = sprintf 'Unable to send subrequest to %s list owner',
            $list->get_id;
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

    $self->add_stash($request, 'notice', 'sent_to_owner')
        unless $request->{quiet};

    $log->syslog(
        'info',
        '%s for %s from %s forwarded to the owners of the list (%.2f seconds)',
        uc $request->{action},
        $list,
        $sender,
        Time::HiRes::time() - $self->{start_time}
    );
    return 1;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Spindle::ToAuthOwner -
Process to store requests into request spool to wait for moderation

=head1 DESCRIPTION

TBD.

=head1 SEE ALSO

L<Sympa::Request>,
L<Sympa::Spindle>, L<Sympa::Spindle::AuthorizeRequest>,
L<Sympa::Spool::Auth>.

=head1 HISTORY

L<Sympa::Spindle::ToAuthOwner> appeared on Sympa 6.2.13.

=cut
