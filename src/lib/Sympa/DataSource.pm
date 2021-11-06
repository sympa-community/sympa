# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright 2019, 2021 The Sympa Community. See the
# AUTHORS.md file at the top-level directory of this distribution and at
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

package Sympa::DataSource;

use strict;
use warnings;
use Digest::MD5 qw();
use English qw(-no_match_vars);

use Sympa;
use Sympa::Log;
use Sympa::Regexps;
use Sympa::Tools::Text;

my $log = Sympa::Log->instance;

sub required_modules { [] }

sub new {
    $log->syslog('debug2', '%s,%s,%s,...');
    my $class   = shift;
    my $type    = shift;
    my $role    = shift;
    my %options = @_;

    return undef unless $type;
    return undef if $type =~ /[^\w:]/;

    # Load appropriate subclasses.
    $type = sprintf 'Sympa::DataSource::%s', $type unless $type =~ /::/;
    unless (eval sprintf('require %s', $type)
        and $type->isa('Sympa::DataSource')) {
        $log->syslog('err', 'Unable to use %s module: %s',
            $type, $EVAL_ERROR || 'Not a Sympa::DataSource class');
        return undef;
    }

    my $list = $options{context};
    if (grep { $role eq $_ } qw(member owner editor)) {
        die 'bug in logic. Ask developer' unless ref $list eq 'Sympa::List';
    }

    # Get default user options.
    my ($defopts, @required);
    if ($options{default_user_options}) {
        $defopts  = $options{default_user_options};
        @required = qw(reception visibility);
    } elsif ($role eq 'owner') {
        my @keys = qw(visibility reception profile info);
        @{$defopts}{@keys} = @options{@keys};
        @required = qw(reception visibility profile);
    } elsif ($role eq 'editor') {
        my @keys = qw(visibility reception info);
        @{$defopts}{@keys} = @options{@keys};
        @required = qw(reception visibility);
    }
    # Complement required attributes.
    #FIXME: check not only existence but also validity of values
    if (@required) {
        my $defdefs = {
            reception  => 'mail',
            visibility => 'noconceal',
            profile    => 'normal',
        };
        my @missing =
            grep { not(defined $defopts->{$_} and length $defopts->{$_}) }
            @required;
        @{$defopts}{@missing} = @{$defdefs}{@missing} if @missing;
    }
    my @defkeys = sort keys %{$defopts || {}};
    my @defvals = @{$defopts || {}}{@defkeys} if @defkeys;

    #FIXME: consider boundaries of Unicode characters (or grapheme clusters)
    $options{name} = substr $options{name}, 0, 50
        if $options{name} and 50 < length $options{name};

    my $self = $type->_new(
        %options,
        _role    => $role,
        _defkeys => [@defkeys],
        _defvals => [@defvals],
    );
    $self->{_external} = not($self->isa('Sympa::DataSource::List')
        and [split /\@/, $self->{listname}, 2]->[1] eq $list->{'domain'})
        if ref $list eq 'Sympa::List';

    $self;
}

sub _new {
    my $class   = shift;
    my %options = @_;

    return bless {%options} => $class;
}

sub open {
    my $self = shift;

    # Check if required module such as DBD is installed.
    foreach my $module (@{$self->required_modules}) {
        unless (eval "require $module") {
            $log->syslog(
                'err',
                'A module for %s is not installed. You should download and install %s',
                ref($self),
                $module
            );
            Sympa::send_notify_to_listmaster('*', 'missing_dbd',
                {db_type => ref($self), db_module => $module});
            return undef;
        }
    }

    my $dsh = $self->_open;
    return undef unless $dsh;
    $self->{_ds} = $dsh if ref $dsh;

    return $dsh;
}

sub _open {1}

sub __dsh { shift->{_ds}; }

sub next {
    my $self = shift;

    while (1) {
        my $entry =
            ($self->role eq 'custom_attribute')
            ? $self->_next_ca
            : $self->_next;
        last unless $entry;

        my ($email, $other_value) = @$entry;
        next unless defined $email and length $email;
        unless (Sympa::Tools::Text::valid_email($email)) {
            $log->syslog('err', 'Skip badly formed email address: "%s"',
                $email);
            next;
        }
        $email = Sympa::Tools::Text::canonic_email($email);

        if ($self->role eq 'custom_attribute') {
            next unless ref $other_value eq 'HASH' and %$other_value;
        }

        return [$email, $other_value];
    }

    return;
}

# _next() and _next_ca() should be implemented explicitly by subclasses.

sub close {
    my $self = shift;

    $self->_close if ref $self->{_ds};
    delete $self->{_ds};

    return 1;
}

sub _close {0}

sub name {
    my $self = shift;

    return $self->{name} || $self->get_short_id;
}

sub role {
    shift->{_role};
}

# Returns a real unique ID for an include datasource.
sub get_id {
    my $self = shift;

    my $context = $self->{context} || '';
    $context = $context->get_id if ref $context eq 'Sympa::List';

    sprintf 'context=%s;id=%s;role=%s;name=%s', $context,
        $self->get_short_id, $self->role, ($self->{name} || '');
}

# Returns a unique ID for an include datasource.
# Old name: Sympa::Datasource::_get_datasource_id().
sub get_short_id {
    my $self = shift;

    my @items = map { ($_, $self->{$_}) } sort grep {
                defined $_
            and length $_
            and !/\A_/
            and !ref $self->{$_}    # Omit context
            and defined $self->{$_}
            and length $self->{$_}
            and !/passw(or)?d/
            and !/\Aname\z/
    } keys %$self;

    return substr Digest::MD5::md5_hex(join ',', @items), -8;
}

sub is_allowed_to_sync {
    my $self = shift;

    my $ranges = $self->{nosync_time_ranges};
    return 1 unless defined $ranges and length $ranges;

    $ranges =~ s/^\s+//;
    $ranges =~ s/\s+$//;
    my $rsre = Sympa::Regexps::time_ranges();
    return 1 unless ($ranges =~ /^$rsre$/);

    $log->syslog('debug', "Checking whether sync is allowed at current time");

    my ($sec, $min, $hour) = localtime(time);
    my $now = 60 * int($hour) + int($min);

    foreach my $range (split(/\s+/, $ranges)) {
        next
            unless ($range =~
            /^([012]?[0-9])(?:\:([0-5][0-9]))?-([012]?[0-9])(?:\:([0-5][0-9]))?$/
            );
        my $start = 60 * int($1) + int($2 // 0);
        my $end   = 60 * int($3) + int($4 // 0);
        $end += 24 * 60 if ($end < $start);

        $log->syslog('debug',
                  "Checking for range from "
                . sprintf('%02d', $start / 60) . "h"
                . sprintf('%02d', $start % 60) . " to "
                . sprintf('%02d', ($end / 60) % 24) . "h"
                . sprintf('%02d', $end % 60));

        next if ($start == $end);

        if ($now >= $start && $now <= $end) {
            $log->syslog('debug', 'Failed, sync not allowed');
            return 0;
        }

        $log->syslog('debug', "Pass ...");
    }

    $log->syslog('debug', "Sync allowed");
    return 1;
}

sub is_external {
    shift->{_external};
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::DataSource - Base class of Sympa data source subclasses

=head1 SYNOPSIS

  # To implemnt Sympa::DataSource::Foo:

  package Sympa::DataSource::Foo;

  use base qw(Sympa::DataSource);
  
  sub _open {
      my $self = shift;
      ...
      return $handle;
  }
  
  sub _next {
      my $self = shift;
      ...
      return [$email, $gecos];
  }
  
  1;
  
  # To use Sympa::DataSource::Foo:
  
  usr Sympa::DataSource;
  
  $ds = Sympa::DataSource->new('Foo', 'member', context => $list,
      key => val, ...);
  if ($ds and $ds->open) {
      while (my $member = $ds->next) {
          ...
      }
      $ds->close;
  }

=head1 DESCRIPTION

TBD.

=head2 Methods

=over

=item new ( $type, $role, context =E<gt> $that, [ I<key> =E<gt> I<val>, ... ] )

I<Constructor>.
Creates a new instance of L<Sympa::DataSource>.

Parameters:

=over

=item $type

Type of data source.
This corresponds to impemented subclasses.

=item $role

Role of data source.
C<'member'>, C<'owner'>, C<'editor'> or C<'custom_attribute'>.

=item context =E<gt> $that

Context. L<Sympa::List> instance and so on.

=item I<key> =E<gt> I<val>, ...

Optional or mandatory parameters.

=back

Returns:

A new instance, or C<undef> on failure.

=item close ( )

I<Instance method>.
Closes backend and does cleanup.

=item is_external ( )

I<Instance method>.
Returns true value if the data source is external data source.
"External" means that it is not C<include_sympa_list> (the instance of
L<Sympa::DataSource::List>) or not including any lists on local domain.

Known bug:

=over

=item *

If a data source is a list included from the other external data source(s),
this method will treat it as non-external so that some requests not allowed
for external data sources, such as C<move_user> request, on corresponding
users may be allowed.

=back

=item next ( )

I<Instance method>.
Returns the next entry in data source.
Data source should have been opened.

=item open ( )

I<Instance method>.
Opens backend and returns handle.

=item get_id ( )

I<Instance method>.
Gets unique ID of the instance.

=item get_short_id ( )

I<Instance method>.
Gets data source ID, a hexadecimal string with 8 columns.

=item name ( )

I<Instance method>.
Gets human-readable name of data source.
Typically it is value of {name} attribute or result of get_short_id().

=item role ( )

I<Instance method>.
Returns $role set by new().

=item __dsh ( )

I<Instance method>, I<protected>.
Returns native query handle which L<_open>() returned.
This may be used only at inside of each subclass.

=back

=head2 Methods subclass should implement

=over

=item required_modules

I<Class or instance method>.
TBD.

=item _open ( [ options... ] )

I<Instance mthod>.
TBD.

=item _next ( [ options... ] )

I<Instance method>, I<mandatory>.
TBD.

=item _next_ca ( [ options... ] )

I<Instance method>, I<mandatory> if the data source supports custom attribute.
TBD.

=item _close (  )

I<Instance method>.
TBD.

=back

=head2 Attributes

=over

=item {context}

Context of the data source set by new().

=item Others

The other options set by new() may be accessed as attributes.

=back

=head1 HISTORY

L<Sympa::DataSource> appeared on Sympa 6.2.45b.
See also L<Sympa::Request::Handler::include/"HISTORY">.

=cut

