# SympaspoolClassic: this module contains methods to handle filesystem spools.
# RCS Identication ; $Revision: 6646 $ ; $Date: 2010-08-19 10:32:08 +0200 (jeu 19 aoû 2010) $ 
#
# Sympa - SYsteme de Multi-Postage Automatique
# Copyrigh (c) 1997, 1998, 1999, 2000, 2001 Comite Reseau des Universites
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
# along with this program.  If not, see <http://www.gnu.org/licenses>.

package SympaspoolClassic;

use strict;
use warnings;
use Carp qw(croak);
use Exporter;
use File::Path qw(make_path remove_tree);
# tentative
use Data::Dumper;

use List;

our $filename_regexp = '^(\S+)\.(\d+)\.\w+$';

our %classes = (
		'msg' => 'Messagespool',
		'task' => 'TaskSpool',
		'mod' => 'KeySpool',
		);

## Creates an object.
sub new {
    Log::do_log('debug2', '(%s, %s, %s)', @_);
    my($pkg, $spoolname, $selection_status) = @_;
    my $spool = {};

    unless ($spoolname =~ /^(auth)|(bounce)|(digest)|(mod)|(msg)|(outgoing)|(automatic)|(subscribe)|(signoff)|(topic)|(task)$/){
	Log::do_log('err','internal error unknown spool %s',$spoolname);
	return undef;
    }
    $spool->{'spoolname'} = $spoolname;
    $spool->{'selection_status'} = $selection_status;
    my $queue = 'queue'.$spoolname;
    $queue = 'queue' if ($spoolname eq 'msg');
    $spool->{'dir'} = Site->$queue;
    if ($spool->{'selection_status'} and $spool->{'selection_status'} eq 'bad') {
	$spool->{'dir'} .= '/bad';
    }
    Log::do_log('debug','Spool to scan "%s"',$spool->{'dir'});
    bless $spool, $pkg;
    $spool->create_spool_dir;

    return $spool;
}

# total spool_table count : not object oriented, just a subroutine 
sub global_count {
    
    my $message_status = shift;
    my @files = <Sympa::Constants::SPOOLDIR/*>;
##    foreach my $file (@files) {
##	Log::do_log('trace', '%s', $file);
##    }
    my $count = @files;

    return $count;
}

sub count {
    my $self = shift;
    return ($self->get_content({'selection'=>'count'}));
}

#######################
#
#  get_content return the content an array of hash describing the spool content
# 
sub get_content {
    Log::do_log('debug2', '(%s, %s)', @_);
    my $self = shift;
    my $param = shift || {};

    my $perlselector = _perlselector($param->{'selector'}) || '1';

    my @messages;
    foreach my $key ($self->get_files_in_spool) {
	my $item = $self->parse($key);
	next unless $item;
	next unless eval $perlselector;
	if ($@) {
	    Log::do_log('err', 'Failed to evaluate selector: %s', $@);
	    next;
	}
	next unless $self->is_relevant($key);
	push @messages, $item;
    }

    return @messages;
}

sub get_count {
    my $self = shift;
    my $param = shift;
    my @messages = $self->get_content($param);
    return $#messages+1;
}

#######################
#
#  next : return next spool entry ordered by priority next lock the message_in_spool that is returned
#  returns 0 if no file found
#  returns undef if problem scanning spool
sub next {
    Log::do_log('debug2', '(%s)', @_);
    my $self = shift;

    my $key;
    my $message;

    unless($self->refresh_spool_files_list) {
	Log::do_log('err', 'Unable to refresh spool %s files list', $self);
	return undef;
    }
    return 0 unless($#{$self->{'spool_files_list'}} > -1);
    return 0 unless $key = $self->get_next_file_to_process;
    unless($message = $self->parse($key)) {
	$self->move_to_bad($key);
	return undef;
    }
##    Log::do_log('trace', 'Will return file %s', $key);
    return $message;
}

sub parse {
    my $self = shift;
    my $key  = shift;

    unless($key) {
	Log::do_log('err',
	    'Unable to find out which file to process');
	return undef;
    }

    my $data = {};
    unless($self->analyze_file_name($key, $data)) {
	$self->move_to_bad($key);
	return undef;
    }
    $data->{'messagekey'} = $key;

    $self->get_priority($key, $data);
    $self->get_file_date($key, $data);
    $data->{'messageasstring'} = $self->get_file_content($key);
    unless (defined $data->{'messageasstring'}) {
	Log::do_log('err', 'Unable to gather content from file %s', $key);
	return undef;
    }
    return $data;
}

sub get_next_file_to_process {
    Log::do_log('debug2', '(%s)', @_);
    my $self = shift;

    foreach my $key (@{$self->{'spool_files_list'}}) {
	return $key if $self->is_readable($key);
    }
    return undef;
}

sub is_readable {
    my $self = shift;
    my $key  = shift;

    if (-f "$self->{'dir'}/$key" && -r _) {
	return 1;
    } else {
	return 0;
    }
}

sub is_relevant {
    return 1;
}

sub analyze_file_name {
    Log::do_log('debug3', '(%s, %s, %s)', @_);
    my $self = shift;
    my $key  = shift;
    my $data = shift;

    unless($key =~ /$filename_regexp/){
	Log::do_log('err',
	    'File %s name does not have the proper format', $key);
	return undef;
    }
    ($data->{'list'}, $data->{'robot'}) = split /\@/, $1;
    
    $data->{'list'} = lc($data->{'list'});
    $data->{'robot'} = lc($data->{'robot'});
    return undef
	unless $data->{'robot_object'} = Robot->new($data->{'robot'});

    ($data->{'list'}, $data->{'type'}) =
	$data->{'robot_object'}->split_listname($data->{'list'});
    return 1;
}

sub get_priority {
    Log::do_log('debug3', '(%s, %s, %s)', @_);
    my $self = shift;
    my $key  = shift;
    my $data = shift;

    my $email = $data->{'robot_object'}->email;
    
    if ($data->{'list'} eq Site->listmaster_email) {
	## highest priority
	$data->{'priority'} = 0;
    } elsif ($data->{'type'} and $data->{'type'} eq 'request') {
	$data->{'priority'} = $data->{'robot_object'}->request_priority;
    } elsif ($data->{'type'} and $data->{'type'} eq 'owner') {
	$data->{'priority'} = $data->{'robot_object'}->owner_priority;
    } elsif ($data->{'list'} =~ /^(sympa|$email)(\@Site->host)?$/i) {	
	$data->{'priority'} = $data->{'robot_object'}->sympa_priority;
    } else {
	$data->{'list_object'} =
	    List->new($data->{'list'}, $data->{'robot_object'},
		{'just_try' => 1});
	if ($data->{'list_object'} && $data->{'list_object'}->isa('List')) {
	    $data->{'priority'} = $data->{'list_object'}->priority;
	}else {
	    $data->{'priority'} =
		$data->{'robot_object'}->default_list_priority;
	}
    }
    Log::do_log('debug3',
	'current file %s, priority %s', $key, $data->{'priority'});
}

sub get_file_date {
    Log::do_log('debug3', '(%s, %s, %s)', @_);
    my $self = shift;
    my $key  = shift;
    my $data = shift;

    unless ($key =~ /$filename_regexp/) {
	$data->{'date'} = (stat "$self->{'dir'}/$key")[9];
    } else {
	$data->{'date'} = $2;
    }
    return $data->{'date'};
}

sub get_file_content {
    Log::do_log('debug3', '(%s, %s)', @_);
    my $self = shift;
    my $key  = shift;

    my $fh;
    unless (open $fh, $self->{'dir'}.'/'.$key) {
	Log::do_log('err', 'Unable to open file %s: %s',
	    $self->{'dir'}.'/'.$key, $!);
	return undef;
    }
    local $/;
    my $messageasstring = <$fh>;
    close $fh;
    return $messageasstring;
}

sub lock_message {
    Log::do_log('debug2', '(%s, %s)', @_);
    my $self = shift;
    my $key  = shift;

    $self->{'lock'} = new Lock($key);
    $self->{'lock'}->set_timeout(-1);
    unless ($self->{'lock'}->lock('write')) {
	Log::do_log('err', 'Unable to put a lock on file %s', $key);
	delete $self->{'lock'};
	return undef;
    }
    return 1;
}

sub unlock_message {
    Log::do_log('debug2', '(%s, %s)', @_);
    my $self = shift;
    my $key  = shift;

    unless(ref($self->{'lock'}) and $self->{'lock'}->isa('Lock')) {
	delete $self->{'lock'};
	return undef;
    }
    unless ($self->{'lock'}->unlock()) {
	Log::do_log('err','Unable to remove lock from file %s', $key);
	delete $self->{'lock'};
	return undef;
    }
    return 1;
}

sub get_files_in_spool {
    my $self = shift;
    return undef unless($self->refresh_spool_files_list);
    return @{$self->{'spool_files_list'}};
}

sub get_dirs_in_spool {
    my $self = shift;
    return undef unless($self->refresh_spool_dirs_list);
    return @{$self->{'spool_dirs_list'}};
}

sub refresh_spool_files_list {
    my $self = shift;
    Log::do_log('debug2','%s',$self->get_id);
    unless (-d $self->{'dir'}) {
	$self->create_spool_dir;
    }
    unless (opendir SPOOLDIR, $self->{'dir'}) {
	Log::do_log('err','Unable to access %s spool. Please check proper rights are set;',$self->{'dir'});
	return undef;
    }
    my @qfile = sort tools::by_date grep {!/^\./ && -f "$self->{'dir'}/$_"} readdir(SPOOLDIR);
    closedir(SPOOLDIR);
    $self->{'spool_files_list'} = \@qfile;
    return 1;
}

sub refresh_spool_dirs_list {
    my $self = shift;
    Log::do_log('debug2','%s',$self->get_id);
    unless (-d $self->{'dir'}) {
	$self->create_spool_dir;
    }
    unless (opendir SPOOLDIR, $self->{'dir'}) {
	Log::do_log('err','Unable to access %s spool. Please check proper rights are set;',$self->{'dir'});
	return undef;
    }
    my @qdir = sort tools::by_date grep {!/^(\.\.|\.)$/ && -d "$self->{'dir'}/$_"} readdir(SPOOLDIR);
    closedir(SPOOLDIR);
    $self->{'spool_dirs_list'} = \@qdir;
    return 1;
}

sub create_spool_dir {
    my $self = shift;
    Log::do_log('debug','%s',$self->get_id);
    unless (-d $self->{'dir'}) {
	make_path($self->{'dir'});
    }
}

sub move_to_bad {
    Log::do_log('debug3', '(%s, %s)', @_);
    my $self = shift;
    my $key = shift;

    unless (-d $self->{'dir'}.'/bad') {
	make_path($self->{'dir'}.'/bad');
    }
    unless(File::Copy::copy($self->{'dir'}.'/'.$key, $self->{'dir'}.'/bad/'.$key)) {
	Log::do_log('err','Could not move file %s to spool bad %s: %s',$self->{'dir'}.'/'.$key,$self->{'dir'}.'/bad',$!);
	return undef;
    }
    unless (unlink ($self->{'dir'}.'/'.$key)) {
	&Log::do_log('err',"Could not unlink message %s/%s . Exiting",$self->{'dir'}, $key);
    }
    $self->unlock_message($key);
    return 1;
}

#################"
# return one message from related spool using a specified selector
# returns undef if message was not found.
#  
sub get_message {
    my $self = shift;
    my $selector = shift;
    Log::do_log('debug2', '(%s, list=%s, robot=%s)',
	$self->get_id, $selector->{'list'}, $selector->{'robot'});
    my @messages = $self->get_content({'selector' => $selector});
    return $messages[0];
}

#################"
# lock one message from related spool using a specified selector
#  
#sub unlock_message {
#
#    my $self = shift;
#    my $messagekey = shift;
#
#    &Log::do_log('debug', 'Spool::unlock_message(%s,%s)',$self->{'spoolname'}, $messagekey);
#    return ( $self->update({'messagekey' => $messagekey},
#			   {'messagelock' => 'NULL'}));
#}

sub move_to {
    my $self = shift;
    my $param = shift;
    my $target = shift;
    my $file_to_move = $self->get_message($param);
    my $new_spool = new SympaspoolClassic($target);
    if ($classes{$target}) {
	bless $new_spool, $target;
    }
    $new_spool->store($file_to_move);
    $self->remove_message("$file_to_move->{'messagekey'}");
    return 1;
}

sub update {
    croak 'Not implemented yet';
}

################"
# store a message in spool 
#
sub store {  
    my $self = shift;
    my $messageasstring = shift;
    my $param = shift;
    my $target_file = $param->{'filename'};
    $target_file ||= $self->get_storage_name($param);
##    Log::do_log('trace','Storing in file %s',"$self->{'dir'}/$target_file");
    my $fh;
    unless(open $fh, ">", "$self->{'dir'}/$target_file") {
	Log::do_log('err','Unable to write file to spool %s',$self->{'dir'});
	return undef;
    }
    print $fh $messageasstring;
    close $fh;
    return 1;
}

sub get_storage_name {
    my $self = shift;
    my $filename;
    my $param = shift;
##    foreach my $line (split '\n',&Dumper($param)) {
##	Log::do_log('trace', '%s', $line);
##    }
    if ($param->{'list'} && $param->{'robot'}) {
	$filename = $param->{'list'}.'@'.$param->{'robot'}.'.'.time.'.'.int(rand(10000));
    }else{
	Log::do_log('err','Unsufficient parameters provided to create file name');
	return undef;
    }
    return $filename;
}

################"
# remove a message in database spool using (messagekey,list,robot) which are a unique id in the spool
#
sub remove_message {  
    my $self = shift;
    my $key  = shift;

    unless (unlink $self->{'dir'}.'/'.$key) {
	Log::do_log('err',
	    'Unable to remove file %s: %s', $self->{'dir'}.'/'.$key, $!);
	return undef;
    }
    return 1;
}

################"
# Clean a spool by removing old messages
#

sub clean {
    my $self = shift;
    my $filter = shift;
    &Log::do_log('debug','Cleaning spool %s (%s), delay: %s',$self->{'spoolname'},$self->{'selection_status'},$filter->{'delay'});

    return undef unless $self->{'spoolname'};
    return undef unless $filter->{'delay'};
    
    my $freshness_date = time - ($filter->{'delay'} * 60 * 60 * 24);
    my $deleted = 0;

    my @to_kill = $self->get_files_in_spool;
    foreach my $f (@to_kill) {
	if ((stat "$self->{'dir'}/$f")[9] < $freshness_date) {
	    if (unlink ("$self->{'dir'}/$f") ) {
		$deleted++;
		Log::do_log('notice', 'Deleting old file %s', "$self->{'dir'}/$f");
	    }else{
		Log::do_log('notice', 'unable to delete old file %s: %s', "$self->{'dir'}/$f",$!);
	    }
	}else{
	    last;
	}
    }
    @to_kill = $self->get_dirs_in_spool;
    foreach my $d (@to_kill) {
	if ((stat "$self->{'dir'}/$d")[9] < $freshness_date) {
	    if (tools::remove_dir("$self->{'dir'}/$d") ) {
		$deleted++;
		Log::do_log('notice', 'Deleting old file %s', "$self->{'dir'}/$d");
	    }else{
		Log::do_log('notice', 'unable to delete old file %s: %s', "$self->{'dir'}/$d",$!);
	    }
	}else{
	    last;
	}
    }

    Log::do_log('debug',"%s entries older than %s days removed from spool %s" ,$deleted,$filter->{'delay'},$self->{'spoolname'});
    return 1;
}


sub _perlselector {
    my $selector = shift || {};

    my ($comparator, $value, $perl_key);

    my @perl_clause = ();
    foreach my $criterium (keys %{$selector}) {
	if (ref($selector->{$criterium}) eq 'ARRAY') {
	    ($value, $comparator) = @{$selector->{$criterium}};
	    $comparator = 'eq' unless $comparator and $comparator eq 'ne';
	} else {
	    ($value, $comparator) = ($selector->{$criterium}, 'eq');
	}

	$perl_key = sprintf '$item->{"%s"}', $criterium;

	push @perl_clause,
	sprintf '%s %s "%s"', $perl_key, $comparator, quotemeta $value;
    }

    return join ' and ', @perl_clause;
}


## Get unique ID
sub get_id {
    my $self = shift;
    return sprintf '%s/%s',
	$self->{'spoolname'}, ($self->{'selection_status'} || 'ok');
}

###### END of the Sympapool package ######

## Packages must return true.
1;
