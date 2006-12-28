# Lock.pm - This module includes Sympa locking functions
#<!-- RCS Identication ; $Revision$ ; $Date$ --> 

#
# Sympa - SYsteme de Multi-Postage Automatique
# Copyright (c) 1997, 1998, 1999, 2000, 2001 Comite Reseau des Universites
# Copyright (c) 1997,1998, 1999 Institut Pasteur & Christophe Wolfhugel
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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

package Lock;

use strict;
require Exporter;
#require 'tools.pl';
my @ISA = qw(Exporter);
my @EXPORT = qw();

use Carp;
use Log;
use Conf;

use Fcntl qw(LOCK_SH LOCK_EX LOCK_NB);
use FileHandle;

sub LOCK_SH {1};
sub LOCK_EX {2};
sub LOCK_NB {4};
sub LOCK_UN {8};

my %list_of_locks;
my $default_timeout = 60 * 20; ## After this period a lock can be stolen


#sub do_log {
#    my $level = shift; my $s = shift;
#    printf STDERR "$s\n", @_;
#}

## Creates a new object
sub new {
    my($pkg, $filepath) = @_;
    &do_log('debug', 'Lock::new(%s,%s)',$filepath);
    
    my $lock_filename = $filepath.'.lock';
    my $lock = {'lock_filename' => $lock_filename};

    ## Create include.lock if needed
    unless (-f $lock_filename) {
	unless (open FH, ">>$lock_filename") {
	    &do_log('err', 'Cannot open %s: %s', $lock_filename, $!);
	    return undef;
	}
	close FH;
   }
    
    ## Bless Message object
    bless $lock, $pkg;
    
    return $lock;
}

sub set_timeout {
    my $self = shift;
    my $delay = shift;

    return undef unless (defined $delay);

    $list_of_locks{$self->{'lock_filename'}}{'timeout'} = $delay;

    return 1;
}

sub get_lock_count {
    my $self = shift;

    return $list_of_locks{$self->{'lock_filename'}}{'count'};
}

sub get_file_handle {
    my $self = shift;

    return $list_of_locks{$self->{'lock_filename'}}{'fh'};
}

sub lock {
    my $self = shift;
    my $mode = shift; ## read | write
    &do_log('debug', 'Lock::lock(%s,%s)',$self->{'lock_filename'}, $mode);

    ## Check if file was already locked by this process
    if ($list_of_locks{$self->{'lock_filename'}}{'fh'}) {

	## Check if the mode for this lock if the same as the previous one
	## if mode is 'write' and was previously 'read' then we unlock and redo a lock
	if ($mode eq 'write' && $list_of_locks{$self->{'lock_filename'}} eq 'read') {
	    my $count = $list_of_locks{$self->{'lock_filename'}}{'count'}; ## Save lock count

	    &do_log('debug', "Need to unlock and redo locking on %s", $self->{'lock_filename'});
	    $self->unlock(); ## unlock first	    
	    $self->lock($mode);
	    
	    $list_of_locks{$self->{'lock_filename'}}{'count'} = $count; ## Restore count
	}

	$list_of_locks{$self->{'lock_filename'}}{'count'}++;
	&do_log('debug', "Lock again %s ; total %d", $self->{'lock_filename'}, $list_of_locks{$self->{'lock_filename'}}{'count'});
	
	return $list_of_locks{$self->{'lock_filename'}}{'fh'};
    }else {
	my ($fh, $nfs_lock);
	if ($Conf::Conf{'lock_method'} eq 'nfs') {
	    ($fh, $nfs_lock) = _lock_nfs($self->{'lock_filename'}, $mode, $list_of_locks{$self->{'lock_filename'}}{'timeout'} || $default_timeout);
	    return undef unless (defined $fh && defined $nfs_lock);
	    
	    $list_of_locks{$self->{'lock_filename'}} = {'fh' => $fh, 'count' => 1, 'mode' => $mode, 'nfs_lock' => $nfs_lock};

	}else {
	    $fh = _lock_file($self->{'lock_filename'}, $mode, $list_of_locks{$self->{'lock_filename'}}{'timeout'} || $default_timeout);
	    return undef unless (defined $fh);
	    
	    $list_of_locks{$self->{'lock_filename'}} = {'fh' => $fh, 'count' => 1, 'mode' => $mode};
	}

	return $fh;
    }
}

sub unlock {
    my $self = shift;
    &do_log('debug', 'Lock::unlock(%s)',$self->{'lock_filename'});

    unless (defined $list_of_locks{$self->{'lock_filename'}}) {
	&do_log('err', "Failed to unlock file %s ; file is not locked", $self->{'lock_filename'});
	return undef;
    }

    if ($list_of_locks{$self->{'lock_filename'}}{'count'} > 1) {
	$list_of_locks{$self->{'lock_filename'}}{'count'}--;

    }else {
	my $fh = $list_of_locks{$self->{'lock_filename'}}{'fh'};

	if ($Conf::Conf{'lock_method'} eq 'nfs') {
	    my $nfs_lock = $list_of_locks{$self->{'lock_filename'}}{'nfs_lock'};

	    unless (defined $fh && defined $nfs_lock && &_unlock_nfs($self->{'lock_filename'}, $fh, $nfs_lock)) {
		&do_log('err', 'Failed to unlock %s', $self->{'lock_filename'});
		
		$list_of_locks{$self->{'lock_filename'}} = undef; ## Clean the list of locks anyway
		
		return undef;
	    }

	}else {
	    unless (defined $fh && &_unlock_file($self->{'lock_filename'}, $fh)) {
		&do_log('err', 'Failed to unlock %s', $self->{'lock_filename'});
		
		$list_of_locks{$self->{'lock_filename'}} = undef; ## Clean the list of locks anyway
		
		return undef;
	    }
	}
	
	$list_of_locks{$self->{'lock_filename'}} = undef;
    }

    return 1;
}

## lock a file 
sub _lock_file {
    my $lock_file = shift;
    my $mode = shift; ## read or write
    my $timeout = shift;
    &do_log('debug', 'Lock::_lock_file(%s,%s,%d)',$lock_file, $mode,$timeout);

    my $operation;
    my $open_mode;

    if ($mode eq 'read') {
	$operation = LOCK_SH;
    }else {
	$operation = LOCK_EX;
	$open_mode = '>>';
    }
    
    ## Read access to prevent "Bad file number" error on Solaris
    unless (open FH, $open_mode.$lock_file) {
	&do_log('err', 'Cannot open %s: %s', $lock_file, $!);
	return undef;
    }
    
    my $got_lock = 1;
    unless (flock (FH, $operation | LOCK_NB)) {
	&do_log('notice','Waiting for %s lock on %s', $mode, $lock_file);

	## If lock was obtained more than 20 minutes ago, then force the lock
	if ( (time - (stat($lock_file))[9] ) >= $timeout) {
	    &do_log('notice','Removing lock file %s', $lock_file);
	    unless (unlink $lock_file) {
		&do_log('err', 'Cannot remove %s: %s', $lock_file, $!);
		return undef;	    		
	    }
	    
	    unless (open FH, ">$lock_file") {
		&do_log('err', 'Cannot open %s: %s', $lock_file, $!);
		return undef;	    
	    }
	}

	$got_lock = undef;
	my $max = 10;
	$max = 2 if ($ENV{'HTTP_HOST'}); ## Web context
	for (my $i = 1; $i < $max; $i++) {
	    sleep (10 * $i);
	    if (flock (FH, $operation | LOCK_NB)) {
		$got_lock = 1;
		last;
	    }
	    &do_log('notice','Waiting for %s lock on %s', $mode, $lock_file);
	}
    }
 
    if ($got_lock) {
	&do_log('debug', 'Got lock for %s on %s', $mode, $lock_file);

	## Keep track of the locking PID
	if ($mode eq 'write') {
	    print FH "$$\n";
	}
    }else {
	&do_log('err', 'Failed locking %s: %s', $lock_file, $!);
	return undef;
    }

    return \*FH;
}

## unlock a file 
sub _unlock_file {
    my $lock_file = shift;
    my $fh = shift;
    &do_log('debug', 'Lock::_unlock_file(%s, %s)',$lock_file, $fh);
   
    unless (flock($fh,LOCK_UN)) {
	&do_log('err', 'Failed UNlocking %s: %s', $lock_file, $!);
	return undef;
    }
    close $fh;
    &do_log('debug', 'Release lock on %s', $lock_file);
    
    return 1;
}

# lock on NFS
sub _lock_nfs {
    my $lock_file = shift;
    my $mode = shift; ## read or write
    my $timeout = shift;
    &do_log('debug', "Lock::_lock_nfs($lock_file, $mode, $timeout)");
    
    ## TODO should become a configuration parameter, used with or without NFS
    my $hold = 30; 
    my ($open_mode, $operation);
    
    if ($mode eq 'read') {
	$operation = LOCK_SH;
    }else {
	$operation = LOCK_EX;
	$open_mode = '>>';
    }
    
    my $nfs_lock = undef;
    my $FH = undef;
    
    if ($nfs_lock = new File::NFSLock {
	file      => $lock_file,
	lock_type => $operation|LOCK_NB,
	blocking_timeout   => $hold,
	stale_lock_timeout => $timeout,
    }) {
	## Read access to prevent "Bad file number" error on Solaris
	$FH = new FileHandle;
	unless (open $FH, $open_mode.$lock_file) {
	    &do_log('err', 'Cannot open %s: %s', $lock_file, $!);
	    return undef;
	}
	
	&do_log('debug', 'Got lock for %s on %s', $mode, $lock_file);
	return ($FH, $nfs_lock);
    } else {
	&do_log('err', 'Failed locking %s: %s', $lock_file, $!);
	close($FH);
	return undef;
	}
        
    return undef;
}

# unlock on NFS
sub _unlock_nfs {
    my $lock_file = shift;
    my $fh = shift;
    my $nfs_lock = shift;
    do_log('debug', "Lock::_unlock_nfs($lock_file, $fh)");
    
    unless (defined $nfs_lock and $nfs_lock->unlock()) {
	&do_log('err', 'Failed UNlocking %s: %s', $lock_file, $!);
	return undef;
    }
    close $fh;
    
    &do_log('debug', 'Release lock on %s', $lock_file);
    
    return 1;
}

## Packages must return true.
1;
