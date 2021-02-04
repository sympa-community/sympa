# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
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

package Sympa::Tools::File;

use strict;
use warnings;
use English qw(-no_match_vars);
use File::Copy::Recursive;
use File::Find qw();
use POSIX qw();

use Sympa::Tools::Text;

sub set_file_rights {
    my %param = @_;
    my ($uid, $gid);

    if ($param{'user'}) {
        $uid = [getpwnam $param{'user'}]->[2];
        unless (defined $uid) {
            $ERRNO = POSIX::ENOENT();
            return undef;
        } elsif ($uid == 0) {
            die 'You are trying to give root permission';
        }
    } else {
        # "A value of -1 is interpreted by most systems to leave that value
        # unchanged".
        $uid = -1;
    }
    if ($param{'group'}) {
        unless ($gid = [getgrnam $param{'group'}]->[2]) {
            $ERRNO = POSIX::ENOENT();
            return undef;
        }
    } else {
        # "A value of -1 is interpreted by most systems to leave that value
        # unchanged".
        $gid = -1;
    }
    unless (chown $uid, $gid, $param{'file'}) {
        return undef;
    }
    if ($param{'mode'}) {
        unless (chmod $param{'mode'}, $param{'file'}) {
            return undef;
        }
    }
    return 1;
}

sub copy_dir {
    my $dir1 = shift;
    my $dir2 = shift;

    unless (-d $dir1) {
        $ERRNO = POSIX::ENOENT();
        return undef;
    }
    return (File::Copy::Recursive::dircopy($dir1, $dir2));
}

sub del_dir {
    my $dir = shift;

    if (opendir my $dh, $dir) {
        my @dirs = readdir $dh;
        closedir $dh;
        foreach my $ent (@dirs) {
            next if $ent =~ /\A[.]{1,2}\z/;
            my $path = $dir . '/' . $ent;
            unlink $path   if -f $path;
            del_dir($path) if -d $path;
        }
        rmdir $dir;
    }
}

sub mk_parent_dir {
    my $file = shift;
    $file =~ /^(.*)\/([^\/])*$/;
    my $dir = $1;

    return 1 if (-d $dir);
    mkdir_all($dir, 0755);
}

sub mkdir_all {
    my ($path, $mode) = @_;
    my $status = 1;

    ## Change umask to fully apply modes of mkdir()
    my $saved_mask = umask;
    umask 0000;

    return undef if ($path eq '');
    return 1 if (-d $path);

    ## Compute parent path
    my @token = split /\//, $path;
    pop @token;
    my $parent_path = join '/', @token;

    unless (-d $parent_path) {
        unless (mkdir_all($parent_path, $mode)) {
            $status = undef;
        }
    }

    if (defined $status) {    ## Don't try if parent dir could not be created
        unless (mkdir($path, $mode)) {
            $status = undef;
        }
    }

    ## Restore umask
    umask $saved_mask;

    return $status;
}

# Old name: tools::qencode_hierarchy().
# Moved to: _qencode_hierarchy() in upgrade_shared_repository.pl.
#sub qencode_hierarchy;

# Note: This is used only once.
sub shift_file {
    my $file  = shift;
    my $count = shift;

    unless (-f $file) {
        $ERRNO = POSIX::ENOENT();
        return undef;
    }

    my @date = localtime time;
    my $file_extention = POSIX::strftime("%Y:%m:%d:%H:%M:%S", @date);

    unless (rename $file, $file . '.' . $file_extention) {
        return undef;
    }
    if ($count) {
        $file =~ /^(.*)\/([^\/])*$/;
        my $dir = $1;

        my $dh;
        unless (opendir $dh, $dir) {
            return $file . '.' . $file_extention;
        }
        my $i = 0;
        foreach my $oldfile (reverse sort grep { 0 == index $_, "$file." }
            readdir $dh) {
            $i++;
            if ($count lt $i) {
                unlink $oldfile;
            }
        }
        closedir $dh;
    }
    return $file . '.' . $file_extention;
}

sub get_mtime {
    my $file = shift;
    die 'Missing parameter $file' unless $file;

    my @stat = stat $file;
    return (-e $file and -r $file) ? $stat[9] : POSIX::INT_MIN();
}

## Find a file in an ordered list of directories
#DEPRECATED: No longer used.
#sub find_file($filename, @directories);

# Moved to: _list_dir() in upgrade_shared_repository.pl.
#sub list_dir;

sub get_dir_size {
    my $dir = shift;

    my $size = 0;
    File::Find::find(
        sub {
            $size += -s $File::Find::name if -f $File::Find::name;
        },
        $dir
    );

    return $size;
}

sub remove_dir {
    no warnings qw(File::Find);

    foreach my $current_dir (@_) {
        File::Find::finddepth({wanted => \&del, no_chdir => 1}, $current_dir);
    }

    sub del {
        my $name = $File::Find::name;

        if (!-l and -d _) {
            rmdir $name;
        } else {
            unlink $name;
        }
    }
    return 1;
}

#DEPRECATED: No longer used.
#sub a_is_older_than_b({a_file => file, b_file => file);

#MOVED to _clean_spool() in task_manager.pl.
# Old name: tools::CleanSpool().
#sub CleanDir;

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Tools::File - File-related functions

=head1 DESCRIPTION

This package provides some file-related functions.

=head2 Functions

=over

=item set_file_rights(%parameters)

Sets owner and/or access rights on a file.

Returns true value if setting rights succeeded.
Otherwise returns false value.

Note:
If superuser was specified as owner, this function will die.

=item copy_dir($dir1, $dir2)

Copy a directory and its content

=item del_dir($dir)

Delete a directory and its content

=item mk_parent_dir($file)

To be used before creating a file in a directory that may not exist already.

=item mkdir_all($path, $mode)

Recursively create directory and all parent directories

=item shift_file($file, $count)

Shift file renaming it with date. If count is defined, keep $count file and
unlink others

=item get_mtime ( $file )

Gets modification time of the file.

Parameter:

=over

=item $file

Full path of file.

=back

Returns:

Modification time as UNIX time.
If the file is not found (including the case that the file vanishes during
execution of this function) or is not readable, returns C<POSIX::INT_MIN>.
In case of other error, returns C<undef>.

=item list_dir($dir, $all, $original_encoding)

DEPRECATED.

Recursively list the content of a directory
Return an array of hash, each entry with directory + filename + encoding

=item get_dir_size($dir)

TBD.

=item qencode_hierarchy()

DEPRECATED.

Q-encodes a complete file hierarchy.
Useful to Q-encode subshared documents.

ToDo:
See a comment on L<Sympa::Tools::Text/qencode_filename>.

=item remove_dir(@directories)

Function for Removing a non-empty directory.
It takes a variable number of arguments:
It can be a list of directory or few directory paths.

=back

=head1 HISTORY

L<Sympa::Tools::File> appeared on Sympa 6.2a.41.

=cut
