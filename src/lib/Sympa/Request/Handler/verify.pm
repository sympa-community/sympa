# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# This file is part of Sympa, see top-level README.md file for details

package Sympa::Request::Handler::verify;

use strict;
use warnings;
use Time::HiRes qw();

use Sympa::Language;
use Sympa::Log;

use base qw(Sympa::Request::Handler);

my $language = Sympa::Language->instance;
my $log      = Sympa::Log->instance;

use constant _action_scenario => undef;
use constant _context_class   => 'Sympa::List';

# Old name: Sympa::Commands::verify().
sub _twist {
    my $self    = shift;
    my $request = shift;

    my $list     = $request->{context};
    my $listname = $list->{'name'};
    my $robot    = $list->{'domain'};
    my $sender   = $request->{sender};

    $language->set_lang($list->{'admin'}{'lang'});

    if ($request->{smime_signed} or $request->{dkim_pass}) {
        $log->syslog(
            'info',  'VERIFY successful from %s (%.2f seconds)',
            $sender, Time::HiRes::time() - $self->{start_time}
        );
        if ($request->{smime_signed}) {
            $self->add_stash($request, 'notice', 'smime');
        } elsif ($request->{dkim_pass}) {
            $self->add_stash($request, 'notice', 'dkim');
        }
    } else {
        $log->syslog(
            'info',
            'VERIFY from %s: could not find correct S/MIME signature (%.2f seconds)',
            $sender,
            Time::HiRes::time() - $self->{start_time}
        );
        $self->add_stash($request, 'user', 'no_verify_sign');
    }
    return 1;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Request::Handler::verify - verify request handler

=head1 DESCRIPTION

Verifys S/MIME signature in the message.

=head1 SEE ALSO

L<Sympa::Request::Handler>.

=head1 HISTORY

=cut
