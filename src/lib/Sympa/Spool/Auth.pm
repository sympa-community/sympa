# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# This file is part of Sympa, see top-level README.md file for details

package Sympa::Spool::Auth;

use strict;
use warnings;

use Conf;
use Sympa::Tools::Text;

use base qw(Sympa::Spool);

sub _directories {
    return {directory => $Conf::Conf{'queuesubscribe'},};
}

sub _filter {
    my $self     = shift;
    my $metadata = shift;

    # Decode e-mail.
    $metadata->{email} =
        Sympa::Tools::Text::decode_filesystem_safe($metadata->{email})
        if $metadata and $metadata->{email};

    1;
}

sub _filter_pre {
    my $self     = shift;
    my $metadata = shift;

    # Encode e-mail.
    $metadata->{email} =
        Sympa::Tools::Text::encode_filesystem_safe($metadata->{email})
        if $metadata and $metadata->{email};

    1;
}

use constant _generator => 'Sympa::Request';

sub _glob_pattern { shift->{_pattern} }

use constant _marshal_format => '%ld,%s@%s_%s,%s,%s';
use constant _marshal_keys =>
    [qw(date localpart domainpart KEYAUTH email action)];
use constant _marshal_regexp =>
    qr{\A(\d+),([^\s\@]+)\@([-.\w]+)_([\da-f]+),([^\s,]*),(\w+)\z};
use constant _store_key => 'keyauth';

sub new {
    my $class   = shift;
    my %options = @_;

    my $self = $class->SUPER::new(%options);

    # Build glob pattern using encoded e-mail.
    if ($self) {
        my $opts = {%options};
        $self->_filter_pre($opts);
        $self->{_pattern} =
            Sympa::Spool::build_glob_pattern($self->_marshal_format,
            $self->_marshal_keys, %$opts);
    }

    $self;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Spool::Auth - Spool for held requests waiting for moderation

=head1 SYNOPSIS

  use Sympa::Spool::Auth;

  my $spool = Sympa::Spool::Auth->new;
  my $request = Sympa::Request->new(...);
  $spool->store($request);

  my $spool = Sympa::Spool::Auth->new(
      context => $list, action => 'add');
  my $size = $spool->size;

  my $spool = Sympa::Spool::Auth->new(
      context => $list, keyauth => $id, action => 'add');
  my ($request, $handle) = $spool->next;

  $spool->remove($handle);

=head1 DESCRIPTION

L<Sympa::Spool::Auth> implements the spool for held requests waiting
for moderation.

=head2 Methods

See also L<Sympa::Spool/"Public methods">.

=over

=item new ( [ context =E<gt> $list ], [ action =E<gt> $action ],
[ keyauth =E<gt> $id ], [ email =E<gt> $email ])

=item next ( [ no_lock =E<gt> 1 ] )

If the pairs describing metadatas are specified,
contents returned by next() are filtered by them.

Order of items returned by next() is controlled by time of submission.

=item quarantine ( )

Does nothing.

=back

=head2 Context and metadata

See also L<Sympa::Spool/"Marshaling and unmarshaling metadata">.

This class particularly gives following metadata:

=over

=item {action}

Action requested.
C<'add'> etc.

=item {date}

Unix time when the request was submitted.

=item {email}

E-mail of user who submitted the request, or target e-mail of the request.

=item {keyauth}

Authentication key generated automatically
when the request is stored to spool.

=back

=head1 CONFIGURATION PARAMETERS

Following site configuration parameters in sympa.conf will be referred.

=over

=item queuesubscribe

Directory path of held request spool.

Note:
Named such by historical reason.

=back

=head1 SEE ALSO

L<sympa_msg(8)>, L<wwsympa(8)>,
L<Sympa::Request>, L<Sympa::Spool>.

=head1 HISTORY

L<Sympa::Spool::Request> appeared on Sympa 6.2.10.
It was renamed to L<Sympa::Spool::Auth> on Sympa 6.2.13.

=cut
