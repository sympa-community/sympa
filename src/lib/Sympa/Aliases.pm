# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright 2017 The Sympa Community. See the AUTHORS.md file at the top-level
# directory of this distribution and at
# <https://github.com/sympa-community/sympa.git>.
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

package Sympa::Aliases;

use Sympatic -oo;

use Sympa::Constants;
use Sympa::Log;
use MooX::TypeTiny;
use Types::Standard qw(Str HashRef);

has 'class' => (
  is  => 'ro',
  isa => Str,
);

has 'type' => (
  is        => 'ro',
  isa       => Str,
  required  => 1,
);

has 'options' => (
  is  => 'ro',
  isa => HashRef,
);

has 'log' => (
  is      => 'ro',
  default => sub {return Sympa::Log->instance},
);

# Sympa::Aliases is the proxy class of subclasses.
# The constructor may be overridden by _new() method.
sub BUILD {
  my ($self) = @_;

    # Special cases:
    # - To disable aliases management, specify "none" as $self->type().
    # - "External" module is used for full path to program.
    # - However, "Template" module is used instead of obsoleted program
    #   alias_manager.pl.
    #return $self->class()->_new() if $self->class() eq 'none';

    if ($self->type() eq Sympa::Constants::SBINDIR() . '/alias_manager.pl') {
        $self->type('Sympa::Aliases::Template');
    } elsif (0 == index $self->type(), '/' and -x $self->type()) {
        $self->options()->set('program', $self->type());
        $self->type('Sympa::Aliases::External');
    }
}

sub check {0}

sub add {0}

sub del {0}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Aliases - Base class for alias management

=head1 SYNOPSIS

  package Sympa::Aliases::FOO;

  use base qw(Sympa::Aliases);

  sub check { ... }
  sub add { ... }
  sub del { ... }

  1;

=head1 DESCRIPTION

This module is the base class for subclasses to manage list aliases of Sympa.

=head2 Methods

=over

=item new ( $self->type(), [ key =E<gt> value, ... ] )

I<Constructor>.
Creates new instance of L<Sympa::Aliases>.

Returns one of appropriate subclasses according to $self->type():

=over

=item C<'none'>

No aliases management.

=item Full path to executable

Use external program to manage aliases.
See L<Sympa::Aliases::External>.

=item Name of subclass

Use a subclass C<Sympa::Aliases::I<name>> to manage aliases.

=back

For invalid types returns C<undef>.

Optional C<I<key> =E<gt> I<value>> pairs are included in the instance as
hash entries.

=item check ($listname, $robot_id)

I<Instance method>, I<overridable>.
Checks if the addresses of requested list exist already.

Parameters:

=over

=item $listname

Name of the list.

=item $robot_id

List's robot.

=back

Returns:

True value if one of addresses exists.
C<0> if none found.
C<undef> if something wrong happened.

By default, this method always returns C<0>.

=item add ($list)

I<Instance method>, I<overridable>.
Installs aliases for the list $list.

Parameters:

=over

=item $list

An instance of L<Sympa::List>.

=back

Returns:

C<1> if installation succeeded.
C<0> if there were no aliases to be installed.
C<undef> if not applicable.

By default, this method always returns C<0>.

=item del ($list)

I<Instance method>, I<overridable>.
Removes aliases for the list $list.

Parameters:

=over

=item $list

An instance of L<Sympa::List>.

=back

Returns:

C<1> if removal succeeded.
C<0> if there were no aliases to be removed.
C<undef> if not applicable.

By default, this method always returns C<0>.

=back

=head1 SEE ALSO

L<Sympa::Aliases::CheckSMTP>,
L<Sympa::Aliases::External>,
L<Sympa::Aliases::Template>.

=head1 HISTORY

F<alias_manager.pl> as a program to automate alias management appeared on
Sympa 3.1b.13.

L<Sympa::Aliases> module as an OO-based class appeared on Sympa 6.2.23b,
and it obsoleted F<alias_manager.pl>.

=cut
