# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# This file is part of Sympa, see top-level README.md file for details

package Sympa::Spool::Archive;

use strict;
use warnings;
use English qw(-no_match_vars);

use Conf;

use base qw(Sympa::Spool);

sub _directories {
    return {
        directory     => $Conf::Conf{'queueoutgoing'},
        bad_directory => $Conf::Conf{'queueoutgoing'} . '/bad',
    };
}
use constant _generator      => 'Sympa::Message';
use constant _marshal_format => '%d.%f.%s@%s,%ld,%d';
use constant _marshal_keys   => [qw(date TIME localpart domainpart PID RAND)];
use constant _marshal_regexp =>
    qr{\A(\d+)\.(\d+\.\d+)\.([^\s\@]*)\@([\w\.\-*]*),(\d+),(\d+)};

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Spool::Archive - Spool for messages waiting for archiving

=head1 SYNOPSIS

  use Sympa::Spool::Archive;
  my $spool = Sympa::Spool::Archive->new;

  $spool->store($message);

  my ($message, $handle) = $spool->next;

=head1 DESCRIPTION

L<Sympa::Spool::Archive> implements the spool for messages waiting for
archiving.

=head2 Methods

See also L<Sympa::Spool/"Public methods">.

=over

=item next ( )

Order is controlled by delivery date, then by reception date.

=back

=head2 Context and metadata

See also L<Sympa::Spool/"Marshaling and unmarshaling metadata">.

This class particularly gives following metadata:

=over

=item {date}

Unix time when the message would be delivered.

=item {time}

Unix time in floating point number when the message was stored.

=back

=head1 CONFIGURATION PARAMETERS

Following site configuration parameters in sympa.conf will be referred.

=over

=item queueoutgoing

Directory path of archive spool.

Note:
Named such by historical reason.

=back

=head1 SEE ALSO

L<Sympa::Archive>, L<Sympa::Message>, L<Sympa::Spindle::ProcessArchive>,
L<Sympa::Spool>.

=head1 HISTORY

L<Sympa::Spool::Archive> appeared on Sympa 6.2.

=cut
