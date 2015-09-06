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

=encoding utf-8

=head1 NAME

Sympa::Tools::File - File-related functions

=head1 DESCRIPTION

This package provides some file-related functions.

=cut

package Sympa::Tools::File;

use strict;
use warnings;
use Encode::Guess;
use File::Copy::Recursive;
use File::Find qw();
use POSIX qw();

use Sympa::Log;

my $log = Sympa::Log->instance;

=head2 Functions

=over

=item set_file_rights(%parameters)

Sets owner and/or access rights on a file.

=back

=cut

sub set_file_rights {
    my %param = @_;
    my ($uid, $gid);

    if ($param{'user'}) {
        unless ($uid = (getpwnam($param{'user'}))[2]) {
            $log->syslog('err', "User %s can't be found in passwd file",
                $param{'user'});
            return undef;
        }
    } else {
        # "A value of -1 is interpreted by most systems to leave that value
        # unchanged".
        $uid = -1;
    }
    if ($param{'group'}) {
        unless ($gid = (getgrnam($param{'group'}))[2]) {
            $log->syslog('err', "Group %s can't be found", $param{'group'});
            return undef;
        }
    } else {
        #
        # "A value of -1 is interpreted by most systems to leave that value unchanged".
        $gid = -1;
    }
    unless (chown($uid, $gid, $param{'file'})) {
        $log->syslog('err', "Can't give ownership of file %s to %s.%s: %m",
            $param{'file'}, $param{'user'}, $param{'group'});
        return undef;
    }
    if ($param{'mode'}) {
        unless (chmod($param{'mode'}, $param{'file'})) {
            $log->syslog('err', "Can't change rights of file %s: %m",
                $Conf::Conf{'db_name'});
            return undef;
        }
    }
    return 1;
}

=over

=item copy_dir($dir1, $dir2)

Copy a directory and its content

=back

=cut

sub copy_dir {
    my $dir1 = shift;
    my $dir2 = shift;
    $log->syslog('debug', 'Copy directory %s to %s', $dir1, $dir2);

    unless (-d $dir1) {
        $log->syslog('err',
            'Directory source "%s" doesn\'t exist. Copy impossible', $dir1);
        return undef;
    }
    return (File::Copy::Recursive::dircopy($dir1, $dir2));
}

=over

=item del_dir($dir)

Delete a directory and its content

=back

=cut

sub del_dir {
    $log->syslog('debug3', '(%s)', @_);
    my $dir = shift;

    if (opendir DIR, $dir) {
        for (readdir DIR) {
            next if /^\.{1,2}$/;
            my $path = "$dir/$_";
            unlink $path   if -f $path;
            del_dir($path) if -d $path;
        }
        closedir DIR;
        unless (rmdir $dir) {
            $log->syslog('err', 'Unable to delete directory %s: %m', $dir);
        }
    } else {
        $log->syslog(
            'err',
            'Unable to open directory %s to delete the files it contains: %m',
            $dir
        );
    }
}

=over

=item mk_parent_dir($file)

To be used before creating a file in a directory that may not exist already.

=back

=cut

sub mk_parent_dir {
    my $file = shift;
    $file =~ /^(.*)\/([^\/])*$/;
    my $dir = $1;

    return 1 if (-d $dir);
    mkdir_all($dir, 0755);
}

=over

=item mkdir_all($path, $mode)

Recursively create directory and all parent directories

=back

=cut

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

=over

=item shift_file($file, $count)

Shift file renaming it with date. If count is defined, keep $count file and
unlink others

=back

=cut

# Note: This is used only once.
sub shift_file {
    my $file  = shift;
    my $count = shift;
    $log->syslog('debug', '(%s, %s)', $file, $count);

    unless (-f $file) {
        $log->syslog('info', 'Unknown file %s', $file);
        return undef;
    }

    my @date = localtime(time);
    my $file_extention = POSIX::strftime("%Y:%m:%d:%H:%M:%S", @date);

    unless (rename($file, $file . '.' . $file_extention)) {
        $log->syslog('err', 'Cannot rename file %s to %s.%s',
            $file, $file, $file_extention);
        return undef;
    }
    if ($count) {
        $file =~ /^(.*)\/([^\/])*$/;
        my $dir = $1;

        unless (opendir(DIR, $dir)) {
            $log->syslog('err', 'Cannot read dir %s', $dir);
            return ($file . '.' . $file_extention);
        }
        my $i = 0;
        foreach my $oldfile (reverse(sort (grep (/^$file\./, readdir(DIR)))))
        {
            $i++;
            if ($count lt $i) {
                if (unlink($oldfile)) {
                    $log->syslog('info', 'Unlink %s', $oldfile);
                } else {
                    $log->syslog('info', 'Unable to unlink %s', $oldfile);
                }
            }
        }
    }
    return ($file . '.' . $file_extention);
}

=over

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

=back

=cut

sub get_mtime {
    my $file = shift;
    die 'Missing parameter $file' unless $file;

    my @stat = stat $file;
    return (-e $file and -r $file) ? $stat[9] : POSIX::INT_MIN();
}

## Find a file in an ordered list of directories
#DEPRECATED: No longer used.
#sub find_file($filename, @directories);

=over

=item list_dir($dir, $all, $original_encoding)

Recursively list the content of a directory
Return an array of hash, each entry with directory + filename + encoding

=back

=cut

sub list_dir {
    my $dir               = shift;
    my $all               = shift;
    my $original_encoding = shift;  # Suspected original encoding of filenames

    if (opendir my $dh, $dir) {
        foreach my $file (sort grep !/^\.\.?$/, readdir $dh) {
            # Guess filename encoding
            my ($encoding, $guess);
            my $decoder =
                Encode::Guess::guess_encoding($file, $original_encoding,
                'utf-8');
            if (ref $decoder) {
                $encoding = $decoder->name;
            } else {
                $guess = $decoder;
            }

            push @$all,
                {
                'directory' => $dir,
                'filename'  => $file,
                'encoding'  => $encoding,
                'guess'     => $guess
                };
            if (-d "$dir/$file") {
                list_dir($dir . '/' . $file, $all, $original_encoding);
            }
        }
        closedir $dh;
    }

    return 1;
}

=over

=item get_dir_size($dir)

TBD.

=back

=cut

sub get_dir_size {
    my $dir = shift;

    my $size = 0;

    if (opendir(DIR, $dir)) {
        foreach my $file (sort grep (!/^\./, readdir(DIR))) {
            if (-d "$dir/$file") {
                $size += get_dir_size("$dir/$file");
            } else {
                my @info = stat "$dir/$file";
                $size += $info[7];
            }
        }
        closedir DIR;
    }

    return $size;
}

=over

=item remove_dir(@directories)

Function for Removing a non-empty directory.
It takes a variale number of arguments:
It can be a list of directory or few direcoty paths.

=back

=cut

sub remove_dir {

    $log->syslog('debug2', '');

    foreach my $current_dir (@_) {
        File::Find::finddepth({wanted => \&del, no_chdir => 1}, $current_dir);
    }

    sub del {
        my $name = $File::Find::name;

        if (!-l && -d _) {
            unless (rmdir($name)) {
                $log->syslog('err', 'Error while removing dir %s', $name);
            }
        } else {
            unless (unlink($name)) {
                $log->syslog('err', 'Error while removing file %s', $name);
            }
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
