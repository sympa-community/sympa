# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014 GIP RENATER
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

package Sympa::LockedFile;

use strict;
use warnings;
use base qw(IO::File);

use Fcntl qw();
use File::NFSLock;

BEGIN {
    no warnings 'redefine';

    # Separate extensions with "," to avoid confusion with domain parts,
    # and to ensure that file names related to lock contains ",lock".
    $File::NFSLock::LOCK_EXTENSION = ',lock';
    *File::NFSLock::rand_file = sub($) {
        my $file = shift;
        "$file,lock.". time()%10000 .'.'. $$ .'.'. int(rand()*10000);
    };
}

our %lock_of;
my $default_timeout    = 30;
my $stale_lock_timeout = 20 * 60;    # TODO should become a config parameter

sub open {
    my $self             = shift;
    my $file             = shift;
    my $blocking_timeout = shift || $default_timeout;
    my $mode             = shift || '<';

    my $lock_type;
    if ($mode =~ /[+>aw]/) {
        $lock_type = Fcntl::LOCK_EX;
    } else {
        $lock_type = Fcntl::LOCK_SH;
    }
    if ($blocking_timeout < 0) {
        $lock_type |= Fcntl::LOCK_NB;
    }

    my $lock = File::NFSLock->new(
        {   file               => $file,
            lock_type          => $lock_type,
            blocking_timeout   => $blocking_timeout,
            stale_lock_timeout => $stale_lock_timeout,
        }
    );
    unless ($lock) {
        return undef;
    }

    if ($mode ne '+') {
        unless ($self->SUPER::open($file, $mode)) {
            $lock->unlock;    # make sure unlock to occur immediately.
            return undef;
        }
    }

    $lock_of{$self + 0} = $lock;    # register lock object, i.e. keep locking.
    return 1;
}

sub close {
    my $self = shift;

    my $ret;
    if (defined $self->fileno) {
        $ret = $self->SUPER::close;
    } else {
        $ret = 1;
    }

    die 'Lock not found' unless exists $lock_of{$self + 0};

    $lock_of{$self + 0}->unlock;    # make sure unlock to occur immediately.
    delete $lock_of{$self + 0};     # lock object will be destructed.
    return $ret;
}

# Destruct inside reference to lock object so that it will be released.
# Corresponding filehandle will be closed automatically.
sub DESTROY {
    my $self = shift;
    delete $lock_of{$self + 0};     # lock object will be destructed.
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::LockedFile - Filehandle with locking

=head1 SYNOPSIS

  use Sympa::LockedFile;
  
  # Create filehandle acquiring lock.
  my $fh = Sympa::LockedFile->new('/path/to/file', 20, '+<') or die;
  # or,
  my $fh = Sympa::LockedFile->new();
  $fh->open('/path/to/file', 20, '+<') or die;
  
  # Operations...
  while (<$fh>) { ... }
  seek $fh, 0, 0;
  truncate $fh, 0;
  print $fh "blah blah\n";
  # et cetera.
 
  # Close filehandle releasing lock.
  $fh->close;

=head1 DESCRIPTION

This class implements a filehadle with locking.

=head2 Class Method

=over

=item Sympa::LockedFile->new ( [ $file, [ $blocking_timeout, [ $mode ] ] ] )

Creates new object.
If any of optional parameters are specified, opens a file acquiring lock.

Parameters:

See open().

Returns:

New object or, if something went wrong, false value.

=back

=head2 Instance Methods

Instances of L<Sympa::LockedFile> support the methods provided by L<IO::File>.

=over

=item $fh->open ( $file, [ $blocking_timeout, [ $mode ] ] )

Opens a file specified by $file acquiring lock.

Parameters:

=over

=item $file

Path of file to be locked and opened.

=item $blocking_timeout

Programs will block up to the number of seconds specified by this option
before returning undef (could not get a lock).
If negative value was given, programs will not block but fail immediately.

Default is C<30>.

However, if existing lock is older than 1200 seconds i.e. 20 minutes,
lock will be stolen.

=item $mode

Mode to open file.
If it implys any writing operations (C<'E<gt>'>, C<'E<gt>E<gt>'>,
C<'+E<lt>'>, ...), trys to acquire exclusive lock (C<Fcntl::LOCK_EX>),
otherwise shared lock (C<Fcntl::LOCK_SH>).

Default is C<'E<lt>'>.

Additionally, a special mode C<'+'> will acquire exclusive lock
without opening file.  In this case the file does not have to exist.

=back

Returns:

New filehandle.
If acquiring lock failed, won't open file.
If opening file failed, releases acquired lock.
In both cases returns false value.

=back

=over

=item $fh->close ( )

Closes filehandle and releases lock on it.

Parameters:

None.

Returns:

If close succeeded, returns true value, otherwise false value.

If filehandle had not been locked by current process,
this method will safely close it and die.

=back

=head1 SEE ALSO

L<perlfunc/"Functions for filehandles, files or directories">,
L<perlop/"I/O Operators">,
L<IO::File>, L<File::NFSLock>.

=head1 HISTORY

Lock module written by Olivier SalaE<252>n appeared on Sympa 5.3.

Support for NFS was added by Kazuo Moriwaka.

L<Sympa::LockedFile> module was initially written by IKEDA Soji.

=cut
