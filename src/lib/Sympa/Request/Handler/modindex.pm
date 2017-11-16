# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# This file is part of Sympa, see top-level README.md file for details

package Sympa::Request::Handler::modindex;

use strict;
use warnings;
use Time::HiRes qw();

use Sympa;
use Sympa::Language;
use Sympa::Log;
use Sympa::Spool::Moderation;

use base qw(Sympa::Request::Handler);

my $language = Sympa::Language->instance;
my $log      = Sympa::Log->instance;

use constant _action_scenario => undef;         # Only actual editors allowed.
use constant _context_class   => 'Sympa::List';

# Old name: Sympa::Commands::modindex().
sub _twist {
    my $self    = shift;
    my $request = shift;

    my $list   = $request->{context};
    my $name   = $list->{'name'};
    my $robot  = $list->{'domain'};
    my $sender = $request->{sender};

    $language->set_lang($list->{'admin'}{'lang'});

    unless ($list->is_admin('actual_editor', $sender)) {
        $self->add_stash($request, 'auth', 'restricted_modindex');
        $log->syslog('info', 'MODINDEX %s from %s refused, not allowed',
            $name, $sender);
        return undef;
    }

    my $spool_mod = Sympa::Spool::Moderation->new(context => $list);
    my @now = localtime(time);

    # List of messages
    my @spool;

    while (1) {
        my ($message, $handle) = $spool_mod->next(no_lock => 1);
        last unless $handle;
        next unless $message and not $message->{validated};
        # Skip message already marked to be distributed using WWSympa.

        # Push message for building MODINDEX
        push @spool, $message->as_string;
    }

    unless (scalar @spool) {
        $self->add_stash($request, 'notice', 'no_message_to_moderate');
        $log->syslog('info',
            'MODINDEX %s from %s refused, no message to moderate',
            $name, $sender);
        return undef;
    }

    unless (
        Sympa::send_file(
            $list,
            'modindex',
            $sender,
            {   'spool' => \@spool,          #FIXME: Use msg_list.
                'total' => scalar(@spool),
                'boundary1' => "==main $now[6].$now[5].$now[4].$now[3]==",
                'boundary2' => "==digest $now[6].$now[5].$now[4].$now[3]=="
            }
        )
        ) {
        $log->syslog('notice', 'Unable to send template "modindex" to %s',
            $sender);
        $self->add_stash($request, 'intern');
        return undef;
    }

    $log->syslog('info', 'MODINDEX %s from %s accepted (%.2f seconds)',
        $name, $sender, Time::HiRes::time() - $self->{start_time});

    return 1;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Request::Handler::modindex - modindex request handler

=head1 DESCRIPTION

Sends a list of current messages to moderate of a list,
using 'modindex' template
(look into moderation spool).

=head1 SEE ALSO

L<Sympa::Request::Handler>, L<Sympa::Spool::Moderation>.

=head1 HISTORY

=cut
