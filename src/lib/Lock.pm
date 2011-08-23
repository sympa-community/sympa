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

use Fcntl qw(LOCK_SH LOCK_EX LOCK_NB LOCK_UN);
use FileHandle;

use Carp;
use Log;
use Conf;

my %list_of_locks;
my $default_timeout = 60 * 20; ## After this period a lock can be stolen


#sub &Log::do_log {
#    my $level = shift; my $s = shift;
#    printf STDERR "$s\n", @_;
#}

## Creates a new object
sub new {
    my($pkg, $filepath) = @_;
    &Log::do_log('debug', 'Lock::new(%s)',$filepath);
    
    my $lock_filename = $filepath.'.lock';
    my $lock = {'lock_filename' => $lock_filename};

    ## Create include.lock if needed
    my $fh;
    unless (-f $lock_filename) {
	unless (open $fh, ">>$lock_filename") {
	    &Log::do_log('err', 'Cannot open %s: %s', $lock_filename, $!);
	    return undef;
	}
	close $fh;
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

    return $#{$list_of_locks{$self->{'lock_filename'}}{'states_list'}} +1;
}

sub get_file_handle {
    my $self = shift;

    return $list_of_locks{$self->{'lock_filename'}}{'fh'};
}

sub lock {
    my $self = shift;
    my $mode = shift; ## read | write
    &Log::do_log('debug', 'Trying to put a lock on %s in mode %s',$self->{'lock_filename'}, $mode);

    ## If file was already locked by this process, we will add a new lock.
    ## We will need to create a new lock if the state must change.
    if ($list_of_locks{$self->{'lock_filename'}}{'fh'}) {
	
	## If the mode for the new lock is 'write' and was previously 'read'
	## then we unlock and redo a lock
	if ($mode eq 'write' && $list_of_locks{$self->{'lock_filename'}}{'mode'} eq 'read') {
	    &Log::do_log('debug', "Need to unlock and redo locking on %s", $self->{'lock_filename'});
	    ## First release previous lock
	    return undef unless ($self->remove_lock());
	    ## Next, lock in write mode
	    ## WARNING!!! This exact point of the code is a critical point, as any file lock this process could have
	    ## is currently released. However, we are supposed to have a 'read' lock! If any OTHER process has a read lock on the file, we won't
	    ## be able to add the new lock. While waiting, the other process can perfectly switch to 'write' mode and start writing
	    ## in the file THAT OTHER PARTS OF THIS PROCESS ARE CURRENTLY READING. Consequently, if add_lock can't create a lock at its
	    ## first attempt, it will first try to put a read lock instead. failing that, it will return undef for lock conflicts reasons.
	    if ($self->add_lock($mode,-1)) {
		push @{$list_of_locks{$self->{'lock_filename'}}{'states_list'}}, $mode;
	    }
	    else {
		return undef unless ($self->add_lock('read',-1));
	    }
	    return 1;
	}
	## Otherwise, the previous lock was probably a 'read' lock, so no worries, just increase the locks count.
	&Log::do_log('debug', "No need to change filesystem or NFS lock for %s. Just increasing count.", $self->{'lock_filename'});
	push @{$list_of_locks{$self->{'lock_filename'}}{'states_list'}}, 'read';
	&Log::do_log('debug', "Locked %s again; total locks: %d", $self->{'lock_filename'}, $#{$list_of_locks{$self->{'lock_filename'}}{'states_list'}} +1);
	return 1;
    }
    
    ## If file was not locked by this process, just *create* the lock.
    else {
	    if ($self->add_lock($mode)) {
		push @{$list_of_locks{$self->{'lock_filename'}}{'states_list'}}, $mode;
	    }
	    else {
		return undef;
	    }
    }
    return 1;
}

sub unlock {
    my $self = shift;
    &Log::do_log('debug', 'Removing lock on %s',$self->{'lock_filename'});

    unless (defined $list_of_locks{$self->{'lock_filename'}}) {
	&Log::do_log('err', "Failed to unlock file %s ; file is not locked", $self->{'lock_filename'});
	return undef;
    }
    my $previous_mode;
    my $current_mode;

    ## If it is not the last lock on the file, we revert the lock state to the previous lock.
    if ($#{$list_of_locks{$self->{'lock_filename'}}{'states_list'}} > 0) {
	$previous_mode = pop @{$list_of_locks{$self->{'lock_filename'}}{'states_list'}};
	$current_mode = @{$list_of_locks{$self->{'lock_filename'}}{'states_list'}}[$#{$list_of_locks{$self->{'lock_filename'}}{'states_list'}}];

	## If the new lock mode is different from the one we just removed, we need to create a new file lock.
	if ($previous_mode eq 'write' && $current_mode eq 'read') {
	    &Log::do_log('debug3', "Need to unlock and redo locking on %s", $self->{'lock_filename'});

	    ## First release previous lock
	    return undef unless($self->remove_lock());

	    ## Next, lock in write mode
	    ## WARNING!!! This exact point of the code is a critical point, as any file lock this process could have
	    ## is currently released. However, we are supposed to have a 'read' lock! If any OTHER process has a read lock on the file, we won't
	    ## be able to add the new lock. While waiting, the other process can perfectly switch to 'write' mode and start writing
	    ## in the file THAT OTHER PARTS OF THIS PROCESS ARE CURRENTLY READING. Consequently, if add_lock can't create a lock at its
	    ## first attempt, it will first try to put a read lock instead. failing that, it will return undef for lock conflicts reasons.
	    return undef unless ($self->add_lock($current_mode,-1));
	}
    }
    ## Otherwise, just delete the last lock.
    else {
	return undef unless($self->remove_lock());
	$previous_mode = pop @{$list_of_locks{$self->{'lock_filename'}}{'states_list'}};
    }
    return 1;
}

## Called by lock() or unlock() when these function need to add a lock (i.e. on the file system or NFS).
sub add_lock {
    my $self = shift;
    my $mode = shift;
    my $timeout = shift;

    ## If the $timeout value is -1, it means that we will try to put a lock only once. This is to be used when we are
    ## changing the lock mode (from write to read and reverse) and we then  release the file lock to create a new one AND
    ## we have previous locks pending in the same process on the same file.
    unless($timeout) {
	$timeout = $list_of_locks{$self->{'lock_filename'}}{'timeout'} || $default_timeout;
    }
    &Log::do_log('debug3', 'Adding lock to file %s in mode %s with a timeout of: %s',$self->{'lock_filename'}, $mode, $timeout);
    my ($fh, $nfs_lock);
    if ($Conf::Conf{'lock_method'} eq 'nfs') {
	($fh, $nfs_lock) = _lock_nfs($self->{'lock_filename'}, $mode, $timeout);
	return undef unless (defined $fh && defined $nfs_lock);
	$list_of_locks{$self->{'lock_filename'}}{'fh'} = $fh;
	$list_of_locks{$self->{'lock_filename'}}{'mode'} = $mode;
	$list_of_locks{$self->{'lock_filename'}}{'nfs_lock'} = $nfs_lock;
    }else {
	$fh = _lock_file($self->{'lock_filename'}, $mode, $timeout);
	return undef unless (defined $fh);
	$list_of_locks{$self->{'lock_filename'}}{'fh'} = $fh;
	$list_of_locks{$self->{'lock_filename'}}{'mode'} = $mode;
	$list_of_locks{$self->{'lock_filename'}}{'nfs_lock'} = $nfs_lock;
    }
    return 1;
}

## Called by lock() or unlock() when these function need to remove a lock (i.e. on the file system or NFS).
sub remove_lock {
    my $self = shift;
    &Log::do_log('debug3', 'Removing lock from file %s',$self->{'lock_filename'});

    my $fh = $list_of_locks{$self->{'lock_filename'}}{'fh'};
    my $previous_mode;
    
    if ($Conf::Conf{'lock_method'} eq 'nfs') {
	my $nfs_lock = $list_of_locks{$self->{'lock_filename'}}{'nfs_lock'};
	unless (defined $fh && defined $nfs_lock && &_unlock_nfs($self->{'lock_filename'}, $fh, $nfs_lock)) {
	    &Log::do_log('err', 'Failed to unlock %s', $self->{'lock_filename'});
	    $list_of_locks{$self->{'lock_filename'}} = undef; ## Clean the list of locks anyway
	    return undef;
	}
    }else {
	unless (defined $fh && &_unlock_file($self->{'lock_filename'}, $fh)) {
	    &Log::do_log('err', 'Failed to unlock %s', $self->{'lock_filename'});
	    $list_of_locks{$self->{'lock_filename'}} = undef; ## Clean the list of locks anyway
	    return undef;
	}
    }
    $list_of_locks{$self->{'lock_filename'}}{'fh'} = undef;
    return 1
}

## Locks a file - pure interface with the filesystem
sub _lock_file {
    my $lock_file = shift;
    my $mode = shift; ## read or write
    my $timeout = shift;
    &Log::do_log('debug3', 'Lock::_lock_file(%s,%s,%d)',$lock_file, $mode,$timeout);

    my $operation;
    my $open_mode;

    if ($mode eq 'read') {
	$operation = LOCK_SH;
    }else {
	$operation = LOCK_EX;
	$open_mode = '>';
    }
    
    ## Read access to prevent "Bad file number" error on Solaris
    my $fh;
    unless (open $fh, $open_mode.$lock_file) {
	&Log::do_log('err', 'Cannot open %s: %s', $lock_file, $!);
	return undef;
    }
    
    my $got_lock = 1;
    unless (flock ($fh, $operation | LOCK_NB)) {
	if ($timeout == -1) {
	    &Log::do_log('err','Unable to get a new lock and other locks pending in this process. Cancelling.');
	    return undef;
	}
	&Log::do_log('notice','Waiting for %s lock on %s', $mode, $lock_file);

	## If lock was obtained more than 20 minutes ago, then force the lock
	if ( (time - (stat($lock_file))[9] ) >= $timeout) {
	    &Log::do_log('debug3','Removing lock file %s', $lock_file);
	    unless (unlink $lock_file) {
		&Log::do_log('err', 'Cannot remove %s: %s', $lock_file, $!);
		return undef;	    		
	    }
	    
	    unless (open $fh, ">$lock_file") {
		&Log::do_log('err', 'Cannot open %s: %s', $lock_file, $!);
		return undef;	    
	    }
	}

	$got_lock = undef;
	my $max = 10;
	$max = 2 if ($ENV{'HTTP_HOST'}); ## Web context
	for (my $i = 1; $i < $max; $i++) {
	    sleep (10 * $i);
	    if (flock ($fh, $operation | LOCK_NB)) {
		$got_lock = 1;
		last;
	    }
	    &Log::do_log('debug3','Waiting for %s lock on %s', $mode, $lock_file);
	}
    }
 
    if ($got_lock) {
	&Log::do_log('debug3', 'Got lock for %s on %s', $mode, $lock_file);

	## Keep track of the locking PID
	if ($mode eq 'write') {
	    print $fh "$$\n";
	}
    }else {
	&Log::do_log('err', 'Failed locking %s: %s', $lock_file, $!);
	return undef;
    }

    return $fh;
}

## Unlocks a file - pure interface with the filesystem
sub _unlock_file {
    my $lock_file = shift;
    my $fh = shift;
    &Log::do_log('debug3', 'Lock::_unlock_file(%s)',$lock_file);
   
    unless (flock($fh,LOCK_UN)) {
	&Log::do_log('err', 'Failed UNlocking %s: %s', $lock_file, $!);
	return undef;
    }
    close $fh;
    &Log::do_log('debug3', 'Release lock on %s', $lock_file);
    
    return 1;
}

# Locks on NFS - pure interface with NFS
sub _lock_nfs {
    my $lock_file = shift;
    my $mode = shift; ## read or write
    my $timeout = shift;
    &Log::do_log('debug3', "Lock::_lock_nfs($lock_file, $mode, $timeout)");
    
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
    
    if ($nfs_lock = File::NFSLock->new( {
	file      => $lock_file,
	lock_type => $operation|LOCK_NB,
	blocking_timeout   => $hold,
	stale_lock_timeout => $timeout,
    })) {
	## Read access to prevent "Bad file number" error on Solaris
	$FH = new FileHandle;
	unless (open $FH, $open_mode.$lock_file) {
	    &Log::do_log('err', 'Cannot open %s: %s', $lock_file, $!);
	    return undef;
	}
	
	&Log::do_log('debug3', 'Got lock for %s on %s', $mode, $lock_file);
	return ($FH, $nfs_lock);
    } else {
	&Log::do_log('err', 'Failed locking %s: %s', $lock_file, $!);
	return undef;
	}
        
    return undef;
}

# Unlocks on NFS - pure interface with NFS
sub _unlock_nfs {
    my $lock_file = shift;
    my $fh = shift;
    my $nfs_lock = shift;
    &Log::do_log('debug3', "Lock::_unlock_nfs($lock_file, $fh)");
    
    unless (defined $nfs_lock and $nfs_lock->unlock()) {
	&Log::do_log('err', 'Failed UNlocking %s: %s', $lock_file, $!);
	return undef;
    }
    close $fh;
    
    &Log::do_log('debug3', 'Release lock on %s', $lock_file);
    
    return 1;
}

## Packages must return true.
1;
