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

package Sympa::Tools::File;

use strict;
use warnings;
use Encode::Guess;
use File::Copy::Recursive;
use File::Find qw();
use POSIX qw();

use Log;

## Sets owner and/or access rights on a file.
sub set_file_rights {
    my %param = @_;
    my ($uid, $gid);

    if ($param{'user'}) {
        unless ($uid = (getpwnam($param{'user'}))[2]) {
            Log::do_log('err', "User %s can't be found in passwd file",
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
            Log::do_log('err', "Group %s can't be found", $param{'group'});
            return undef;
        }
    } else {
        #
        # "A value of -1 is interpreted by most systems to leave that value unchanged".
        $gid = -1;
    }
    unless (chown($uid, $gid, $param{'file'})) {
        Log::do_log('err', "Can't give ownership of file %s to %s.%s: %m",
            $param{'file'}, $param{'user'}, $param{'group'});
        return undef;
    }
    if ($param{'mode'}) {
        unless (chmod($param{'mode'}, $param{'file'})) {
            Log::do_log('err', "Can't change rights of file %s: %m",
                $Conf::Conf{'db_name'});
            return undef;
        }
    }
    return 1;
}

#copy a directory and its content
sub copy_dir {
    my $dir1 = shift;
    my $dir2 = shift;
    Log::do_log('debug', 'Copy directory %s to %s', $dir1, $dir2);

    unless (-d $dir1) {
        Log::do_log('err',
            'Directory source "%s" doesn\'t exist. Copy impossible', $dir1);
        return undef;
    }
    return (File::Copy::Recursive::dircopy($dir1, $dir2));
}

#delete a directory and its content
sub del_dir {
    Log::do_log('debug3', '(%s)', @_);
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
            Log::do_log('err', 'Unable to delete directory %s: %m', $dir);
        }
    } else {
        Log::do_log(
            'err',
            'Unable to open directory %s to delete the files it contains: %m',
            $dir
        );
    }
}

#to be used before creating a file in a directory that may not exist already.
sub mk_parent_dir {
    my $file = shift;
    $file =~ /^(.*)\/([^\/])*$/;
    my $dir = $1;

    return 1 if (-d $dir);
    mkdir_all($dir, 0755);
}

## Recursively create directory and all parent directories
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

# shift file renaming it with date. If count is defined, keep $count file and
# unlink others
# Note: This is used only once.
sub shift_file {
    my $file  = shift;
    my $count = shift;
    Log::do_log('debug', '(%s, %s)', $file, $count);

    unless (-f $file) {
        Log::do_log('info', 'Unknown file %s', $file);
        return undef;
    }

    my @date = localtime(time);
    my $file_extention = POSIX::strftime("%Y:%m:%d:%H:%M:%S", @date);

    unless (rename($file, $file . '.' . $file_extention)) {
        Log::do_log('err', 'Cannot rename file %s to %s.%s',
            $file, $file, $file_extention);
        return undef;
    }
    if ($count) {
        $file =~ /^(.*)\/([^\/])*$/;
        my $dir = $1;

        unless (opendir(DIR, $dir)) {
            Log::do_log('err', 'Cannot read dir %s', $dir);
            return ($file . '.' . $file_extention);
        }
        my $i = 0;
        foreach my $oldfile (reverse(sort (grep (/^$file\./, readdir(DIR)))))
        {
            $i++;
            if ($count lt $i) {
                if (unlink($oldfile)) {
                    Log::do_log('info', 'Unlink %s', $oldfile);
                } else {
                    Log::do_log('info', 'Unable to unlink %s', $oldfile);
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
If the file is not found or is not readable, returns C<POSIX::INT_MIN>.
In case of other error, returns C<undef>.

=back

=cut

sub get_mtime {
    my $file = shift;
    die 'Missing parameter $file' unless $file;

    return POSIX::INT_MIN() unless -e $file and -r $file;

    my @stat = stat $file;
    return $stat[9];
}

## Find a file in an ordered list of directories
#DEPRECATED: No longer used.
#sub find_file($filename, @directories);

## Recursively list the content of a directory
## Return an array of hash, each entry with directory + filename + encoding
sub list_dir {
    my $dir               = shift;
    my $all               = shift;
    my $original_encoding = shift; ## Suspected original encoding of filenames

    my $size = 0;

    if (opendir(DIR, $dir)) {
        foreach my $file (sort grep (!/^\.\.?$/, readdir(DIR))) {

            ## Guess filename encoding
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
        closedir DIR;
    }

    return 1;
}

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

## Function for Removing a non-empty directory
## It takes a variale number of arguments :
## it can be a list of directory
## or few direcoty paths
sub remove_dir {

    Log::do_log('debug2', '');

    foreach my $current_dir (@_) {
        File::Find::finddepth({wanted => \&del, no_chdir => 1}, $current_dir);
    }

    sub del {
        my $name = $File::Find::name;

        if (!-l && -d _) {
            unless (rmdir($name)) {
                Log::do_log('err', 'Error while removing dir %s', $name);
            }
        } else {
            unless (unlink($name)) {
                Log::do_log('err', 'Error while removing file %s', $name);
            }
        }
    }
    return 1;
}

#DEPRECATED: No longer used.
#sub a_is_older_than_b({a_file => file, b_file => file);

=over

=item CleanDir (STRING $spool_dir, INT $clean_delay)

Clean all messages in spool $spool_dir older than $clean_delay.

Arguments:

=over 

=item * I<spool_dir> : a string corresponding to the path to the spool to clean;

=item * I<clean_delay> : the delay between the moment we try to clean spool and the last modification date of a file.

=back

Returns:

=over

=item * 1 if the spool was cleaned withou troubles.

=item * undef if something went wrong.

=back 

Calls::

=over 

=item * Sympa::Tools::File::remove_dir

=back 

=back

=cut 

############################################################
#  CleanDir
############################################################
#  Cleans files older than $clean_delay from spool $spool_dir
#
# IN : -$spool_dir (+): the spool directory
#      -$clean_delay (+): delay in days
#
# OUT : 1
#
##############################################################
# Old name: tools::CleanSpool().
sub CleanDir {
    my ($spool_dir, $clean_delay) = @_;
    Log::do_log('debug', '(%s, %s)', $spool_dir, $clean_delay);

    unless (opendir(DIR, $spool_dir)) {
        Log::do_log('err', 'Unable to open "%s" spool: %m', $spool_dir);
        return undef;
    }

    my @qfile = sort grep (!/^\.+$/, readdir(DIR));
    closedir DIR;

    my ($curlist, $moddelay);
    foreach my $f (@qfile) {
        if (Sympa::Tools::File::get_mtime("$spool_dir/$f") <
            time - $clean_delay * 60 * 60 * 24) {
            if (-f "$spool_dir/$f") {
                unlink("$spool_dir/$f");
                Log::do_log('notice', 'Deleting old file %s',
                    "$spool_dir/$f");
            } elsif (-d "$spool_dir/$f") {
                unless (Sympa::Tools::File::remove_dir("$spool_dir/$f")) {
                    Log::do_log('err', 'Cannot remove old directory %s: %m',
                        "$spool_dir/$f");
                    next;
                }
                Log::do_log('notice', 'Deleting old directory %s',
                    "$spool_dir/$f");
            }
        }
    }

    return 1;
}

1;
