# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# This file is part of Sympa, see top-level README.md file for details

package Sympa::Spool::Digest;

use strict;
use warnings;

use Conf;

use base qw(Sympa::Spool);

sub _directories {
    my $self    = shift;
    my %options = @_;

    my $list = ref($self) ? $self->{context} : $options{context};
    die 'bug in logic.  Ask developer' unless ref $list eq 'Sympa::List';

    return {
        parent_directory => $Conf::Conf{'queuedigest'},
        directory        => $list->get_digest_spool_dir,
        bad_directory    => $list->get_digest_spool_dir . '/bad',
    };
}

use constant _generator => 'Sympa::Message';

sub _init {
    my $self   = shift;
    my $status = shift;

    unless ($status) {
        # Get earliest time of messages in the spool.
        my $metadatas = $self->_load || [];
        my $metadata;
        while (my $marshalled = shift @$metadatas) {
            $metadata = $self->unmarshal($marshalled);
            last if $metadata;
        }
        $self->{time} = $metadata ? $metadata->{time} : undef;
        $self->{_metadatas} = undef;    # Rewind cache.
    }
    return 1;
}

use constant _marshal_format => '%ld.%f,%ld,%d';
use constant _marshal_keys   => [qw(date TIME PID RAND)];
use constant _marshal_regexp => qr{\A(\d+)\.(\d+\.\d+)(?:,.*)?\z};

sub next {
    my $self = shift;

    my ($message, $handle) = $self->SUPER::next();
    if ($message) {
        # Assign context which is not given by metadata.
        $message->{context} = $self->{context};
    }
    return ($message, $handle);
}

# Old name: Sympa::List::store_digest().
sub store {
    my $self    = shift;
    my $message = shift->dup;

    # Delete original message ID because it can be anonymized.
    delete $message->{message_id};

    return $self->SUPER::store($message);
}

sub get_id {
    my $self = shift;

    if ($self->{context}) {
        if (ref $self->{context} eq 'Sympa::List') {
            return $self->{context}->get_id;
        } else {
            return $self->{context};
        }
    } else {
        return '';
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Spool::Digest - Spool for messages waiting for digest sending

=head1 SYNOPSIS

  use Sympa::Spool::Digest;
  my $spool = Sympa::Spool::Digest->new(context => $list);
  
  $spool->store($message);
  
  my ($message, $handle) = $spool->next;

=head1 DESCRIPTION

L<Sympa::Spool::Digest> implements the spool for messages waiting for
digest sending.

=head2 Methods

See also L<Sympa::Spool/"Public methods">.

=over

=item new ( context =E<gt> $list )

Creates new instance of L<Sympa::Spool::Digest> related to the list $list.

=item next ( )

Order is controlled by delivery date, then by reception date.

=back

=head2 Properties

See also L<Sympa::Spool/"Properties">.

=over

=item {time}

Earliest time of messages in the spool, or C<undef>.

=back

=head2 Context and metadata

See also L<Sympa::Spool/"Marshaling and unmarshaling metadata">.

This class particularly gives following metadata:

=over

=item {date}

Unix time when the message was delivered.

=item {time}

Unix time in floating point number when the message was stored.

=back

=head1 CONFIGURATION PARAMETERS

Following site configuration parameters in sympa.conf will be referred.

=over

=item queuedigest

Parent directory path of digest spools.

=back

=head1 SEE ALSO

L<sympa_msg(8)>,
L<Sympa::Message>, L<Sympa::Spool>, L<Sympa::Spool::Digest::Collection>.

=head1 HISTORY

L<Sympa::Spool::Digest> appeared on Sympa 6.2.6.

=cut
