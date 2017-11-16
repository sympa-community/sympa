# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# This file is part of Sympa, see top-level README.md file for details

package Sympa::Request::Handler::review;

use strict;
use warnings;
use Time::HiRes qw();

use Sympa;
use Sympa::Language;
use Sympa::Log;

use base qw(Sympa::Request::Handler);

my $language = Sympa::Language->instance;
my $log      = Sympa::Log->instance;

use constant _action_scenario => 'review';
use constant _action_regexp   => qr'reject|request_auth|do_it'i;
use constant _context_class   => 'Sympa::List';

# Old name: Sympa::Commands::review().
sub _twist {
    my $self    = shift;
    my $request = shift;

    my $list     = $request->{context};
    my $listname = $list->{'name'};
    my $robot    = $list->{'domain'};
    my $sender   = $request->{sender};

    my $user;

    $language->set_lang($list->{'admin'}{'lang'});

    # Members list synchronization if include is in use.
    if ($list->has_include_data_sources) {
        unless (defined $list->on_the_fly_sync_include(use_ttl => 1)) {
            $log->syslog('notice', 'Unable to synchronize list %s', $list);
            #FIXME: Abort if synchronization failed.
        }
    }

    my @users;

    my $is_owner = $list->is_admin('owner', $sender)
        || Sympa::is_listmaster($list, $sender);
    unless ($user = $list->get_first_list_member({'sortby' => 'email'})) {
        $self->add_stash($request, 'user', 'no_subscriber');
        $log->syslog('err', 'No subscribers in list "%s"', $list->{'name'});
        return undef;
    }
    do {
        ## Owners bypass the visibility option
        unless (($user->{'visibility'} eq 'conceal')
            and (!$is_owner)) {

            ## Lower case email address
            $user->{'email'} =~ y/A-Z/a-z/;
            push @users, $user;
        }
    } while ($user = $list->get_next_list_member());
    unless (
        Sympa::send_file(
            $list, 'review', $sender,
            {   'users'          => \@users,
                'total'          => $list->get_total(),
                'subject'        => "REVIEW $listname",    # Compat <= 6.1.17.
                'auto_submitted' => 'auto-replied'
            }
        )
        ) {
        $log->syslog('notice', 'Unable to send template "review" to %s',
            $sender);
        $self->add_stash($request, 'intern');
        return undef;
    }

    $log->syslog('info', 'REVIEW %s from %s accepted (%.2f seconds)',
        $listname, $sender, Time::HiRes::time() - $self->{start_time});
    return 1;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Request::Handler::review - review request handler

=head1 DESCRIPTION

Sends the list of subscribers to the requester
using 'review' template.

=head1 SEE ALSO

L<Sympa::Request::Handler>.

=head1 HISTORY

=cut
