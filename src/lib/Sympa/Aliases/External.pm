# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright 2017, 2018 The Sympa Community. See the AUTHORS.md file at the
# top-level directory of this distribution and at
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

package Sympa::Aliases::External;

use strict;
use warnings;
use English qw(-no_match_vars);

use Conf;
use Sympa::Log;

use base qw(Sympa::Aliases::CheckSMTP);

my $log = Sympa::Log->instance;

# Old name: Sympa::Admin::install_aliases().
sub add {
    $log->syslog('debug', '(%s, %s)', @_);
    my $self = shift;
    my $list = shift;

    my $program = $self->{program};
    system($program, 'add', $list->{'name'}, $list->{'domain'},
        ($self->{file} ? ($self->{file}) : ()));
    if ($CHILD_ERROR & 127) {
        $log->syslog('err', '%s was terminated by signal %d',
            $program, $CHILD_ERROR & 127);
        return undef;
    } elsif ($CHILD_ERROR) {
        return _error($CHILD_ERROR >> 8, $ERRNO);
    } else {
        $log->syslog('info', 'Aliases for list %s installed successfully',
            $list);
        return 1;
    }
}

# Old names: Sympa::Admin::remove_aliases() & Sympa::List::remove_aliases().
sub del {
    $log->syslog('info', '(%s, %s)', @_);
    my $self = shift;
    my $list = shift;

    my $program = $self->{program};
    system($program, 'del', $list->{'name'}, $list->{'domain'},
        ($self->{file} ? ($self->{file}) : ()));
    if ($CHILD_ERROR & 127) {
        $log->syslog('err', '%s was terminated by signal %d',
            $program, $CHILD_ERROR & 127);
        return undef;
    } elsif ($CHILD_ERROR) {
        return _error($CHILD_ERROR >> 8, $ERRNO);
    } else {
        $log->syslog('info', 'Aliases for list %s removed successfully',
            $list);
        return 1;
    }
}

use constant ERR_CONFIG        => 1;
use constant ERR_PARAMETER     => 2;
use constant ERR_WRITE_ALIAS   => 5;
use constant ERR_NEWALIASES    => 6;
use constant ERR_READ_ALIAS    => 7;
use constant ERR_CREATE_TEMP   => 8;
use constant ERR_ALIAS_EXISTS  => 13;
use constant ERR_LOCK          => 14;
use constant ERR_ALIASES_EMPTY => 15;
use constant ERR_OTHER         => 127;

sub _error {
    my $status = shift;
    my $errno  = shift;

    unless ($status) {
        $log->syslog('info', 'Aliases installed successfully');
        return 1;
    } elsif ($status == ERR_CONFIG()) {
        $log->syslog('err', '(%d) Configuration file has errors', $status);
    } elsif ($status == ERR_PARAMETER()) {
        $log->syslog('err', '(%d) Incorrect call to program', $status);
    } elsif ($status == ERR_WRITE_ALIAS()) {
        $log->syslog('err', '(%d) Unable to append to alias', $status);
    } elsif ($status == ERR_NEWALIASES()) {
        $log->syslog('err', '(%d) Unable to run newaliases program', $status);
    } elsif ($status == ERR_READ_ALIAS()) {
        $log->syslog('err', '(%d) Unable to read existing aliases', $status);
    } elsif ($status == ERR_CREATE_TEMP()) {
        $log->syslog('err', '(%d) Could not create temporary file', $status);
    } elsif ($status == ERR_ALIAS_EXISTS()) {
        $log->syslog('info', '(%d) Some of list aliases already exist',
            $status);
    } elsif ($status == ERR_LOCK()) {
        $log->syslog('err', '(%d) Can not lock resource', $status);
    } elsif ($status == ERR_ALIASES_EMPTY()) {
        $log->syslog('err', '(%d) The parser returned empty aliases',
            $status);
    } elsif ($status == ERR_OTHER()) {
        $log->syslog('err', '(%d) Error', $status);
    } elsif ($errno) {
        $log->syslog('err',
            '(%d) Unknown error %s while running alias manager: %s',
            $status, $errno);
    } else {
        $log->syslog('err',
            '(%d) Unknown error %s while running alias manager', $status);
    }

    return undef;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Aliases::External -
Alias management: Updating aliases by external program

=head1 SYNOPSIS

  use Sympa::Aliases;
  
  my $aliases = Sympa::Aliases->new('/path/to/program',
      [ file => 'file' ] );
  # or,
  my $aliases = Sympa::Aliases->new('External',
      program => '/path/to/program', [ file => 'file' ] );
  
  $aliases->check('listname', 'domain');
  $aliases->add($list);
  $aliases->del($list);

=head1 DESCRIPTION 

L<Sympa::Aliases::External> manages list aliases using external program.

=head2 Methods

=over

=item check ( $listname, $domain )

See L<Sympa::Aliases::CheckSMTP>.

=item add ( $list )

=item del ( $list )

Invokes program with command line arguments:

  /path/to/program add | del listname domain [ file ]

If processing succeed, program should exit with status 0.
Otherwise it may exit with non-zero status (see also L</"Constants">).

=back

=head2 Constants

=head3 Exit status

=over

=item ERR_CONFIG

Configuration file has errors.

=item ERR_PARAMETER

Incorrect call to program.

=item ERR_WRITE_ALIAS

Unable to append to alias.

=item ERR_NEWALIASES

Unable to run newaliases command.

=item ERR_READ_ALIAS

Unable to read existing aliases.

=item ERR_CREATE_TEMP

Could not create temporary file.

=item ERR_ALIAS_EXISTS

Some of list aliases already exist.

=item ERR_LOCK

Can not lock resource.

=item ERR_ALIASES_EMPTY

The parser returned empty aliases.

=back

=head1 SEE ALSO

L<Sympa::Aliases>,
L<Sympa::Aliases::CheckSMTP>.

=head1 HISTORY

L<Sympa::Aliases::External> module appeared on Sympa 6.2.23b.

=cut 
