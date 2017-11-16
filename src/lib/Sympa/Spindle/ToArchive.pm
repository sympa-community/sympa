# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# This file is part of Sympa, see top-level README.md file for details

package Sympa::Spindle::ToArchive;

use strict;
use warnings;

use Sympa::Log;
use Sympa::Spool::Archive;
use Sympa::Tools::Data;

use base qw(Sympa::Spindle);

my $log = Sympa::Log->instance;

# Old name: (part of) Sympa::List::distribute_msg().
sub _twist {
    my $self    = shift;
    my $message = shift;

    my $list = $message->{context};

    # Archives
    unless ($list->is_archiving_enabled) {
        # Archiving is disabled.
    } elsif (
        !Sympa::Tools::Data::smart_eq(
            $Conf::Conf{'ignore_x_no_archive_header_feature'}, 'on')
        and (
            grep {
                /yes/i
            } $message->get_header('X-no-archive')
            or grep {
                /no\-external\-archive/i
            } $message->get_header('Restrict')
        )
        ) {
        # Ignoring message with a no-archive flag.
        $log->syslog('info',
            "Do not archive message with no-archive flag for list %s", $list);
    } else {
        my $spool = Sympa::Spool::Archive->new;
        $spool->store(
            $message,
            original => Sympa::Tools::Data::smart_eq(
                $list->{admin}{archive_crypted_msg}, 'original'
            )
        );
    }

    1;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Spindle::ToArchive - Process to store messages into archiving spool

=head1 DESCRIPTION

TBD.

=head1 SEE ALSO

L<Sympa::Message>,
L<Sympa::Spindle>, L<Sympa::Spindle::DistributeMessage>,
L<Sympa::Spool::Archive>.

=head1 HISTORY

L<Sympa::Spindle::ToArchive> appeared on Sympa 6.2.13.

=cut
