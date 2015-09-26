# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015 GIP RENATER
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

package Sympa::Spool::Held;

use strict;
use warnings;

use Conf;

use base qw(Sympa::Spool);

sub _directories {
    return {directory => $Conf::Conf{'queueauth'},};
}

sub _filter {
    my $self     = shift;
    my $metadata = shift;

    $metadata && ref $metadata->{context} eq 'Sympa::List';
}

use constant _generator => 'Sympa::Message';

sub _glob_pattern { shift->{_pattern} }

use constant _marshal_format => '%s@%s_%s';
use constant _marshal_keys   => [qw(localpart domainpart AUTHKEY)];
use constant _marshal_regexp => qr{\A([^\s\@]+)\@([-.\w]+)_([\da-f]+)\z};
use constant _store_key      => 'authkey';

sub new {
    my $class   = shift;
    my %options = @_;

    my $self = $class->SUPER::new(%options);

    if ($self) {
        # Construct glob pattern.
        if (exists $options{context}) {
            my $context = $options{context};
            if (ref $context eq 'Sympa::List') {
                @options{qw(localpart domainpart)} =
                    split /\@/, $context->get_list_address;
            } else {
                $options{domainpart} = $context;
            }
        }

        my $format = $self->_marshal_format;
        $format =~ s/%[\W\d]*\w/%s/g;
        my @args =
            map {
            if (exists $options{$_} and defined $options{$_}) {
                my $val = $options{$_};
                $val =~ s/([^\w\x80-\xFF])/\\$1/g;
                $val;
            } else {
                '*';
            }
            } map {
            lc $_
            } @{$self->_marshal_keys || []};

        my $pattern = sprintf $format, @args;
        $pattern =~ s/[*][*]+/*/g;
        if ($pattern =~ /[0-9A-Za-z\x80-\xFF]/) {
            $self->{_pattern} = $pattern;
        }
    }

    $self;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Spool::Held - Spool for held messages waiting for confirmation

=head1 SYNOPSIS

  use Sympa::Spool::Held;

  my $spool = Sympa::Spool::Held->new;
  my $authkey = $spool->store($message);

  my $spool =
      Sympa::Spool::Held->new(context => $list, authkey => $authkey);
  my ($message, $handle) = $spool->next;

=head1 DESCRIPTION

L<Sympa::Spool::Held> implements the spool for held messages waiting for
confirmation.

=head2 Methods

See also L<Sympa::Spool/"Public methods">.

=over

=item new ( [ context =E<gt> $list ], [ authkey =E<gt> $authkey ] )

=item next ( )

If the pairs describing metadatas are specified,
contents returned by next() are filtered by them.

=item quarantine ( )

Does nothing.

=item store ( $message, [ original =E<gt> $original ] )

If storing succeeded, returns authentication key.

=back

=head1 CONFIGURATION PARAMETERS

Following site configuration parameters in sympa.conf will be referred.

=over

=item queueauth

Directory path of held message spool.

Note:
Named such by historical reason.

=back

=head1 SEE ALSO

L<sympa_msg(8)>, L<wwsympa(8)>,
L<Sympa::Message>, L<Sympa::Spool>, L<Sympa::Spool::Moderation>.

=head1 HISTORY

L<Sympa::Spool::Held> appeared on Sympa 6.2.8.

=cut
