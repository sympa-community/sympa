# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# This file is part of Sympa, see top-level README.md file for details

package Sympa::Request::Handler::stats;

use strict;
use warnings;
use Time::HiRes qw();

use Sympa;
use Sympa::Log;

use base qw(Sympa::Request::Handler);

my $log = Sympa::Log->instance;

use constant _action_scenario => 'review';
use constant _action_regexp   => qr'reject|do_it'i;    #FIXME: request_auth?
use constant _context_class   => 'Sympa::List';

# Old name: Sympa::Commands::stats().
sub _twist {
    my $self    = shift;
    my $request = shift;

    my $list     = $request->{context};
    my $listname = $list->{'name'};
    my $robot    = $list->{'domain'};
    my $sender   = $request->{sender};

    my %stats = (
        'msg_rcv'   => $list->{'stats'}[0],
        'msg_sent'  => $list->{'stats'}[1],
        'byte_rcv'  => sprintf('%9.2f', ($list->{'stats'}[2] / 1024 / 1024)),
        'byte_sent' => sprintf('%9.2f', ($list->{'stats'}[3] / 1024 / 1024))
    );

    unless (
        Sympa::send_file(
            $list,
            'stats_report',
            $sender,
            {   'stats'   => \%stats,
                'subject' => "STATS $list->{'name'}",    # compat <= 6.1.17.
                'auto_submitted' => 'auto-replied'
            }
        )
        ) {
        $log->syslog('notice',
            'Unable to send template "stats_reports" to %s', $sender);
        $self->add_stash($request, 'intern');
        return undef;
    }

    $log->syslog('info', 'STATS %s from %s accepted (%.2f seconds)',
        $listname, $sender, Time::HiRes::time() - $self->{start_time});
    return 1;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Request::Handler::stats - stats request handler

=head1 DESCRIPTION

Sends the statistics about a list using template
'stats_report'.

=head1 SEE ALSO

L<Sympa::Request::Handler>.

=head1 HISTORY

=cut
