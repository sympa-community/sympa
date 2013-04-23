# Messagespool: this module contains methods to handle filesystem spools containing messages.
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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

package Messagespool;

use SympaspoolClassic;
use Log;

our @ISA = qw(SympaspoolClassic);

sub get_next_file_to_process {
    my $self = shift;
    Log::do_log('debug3','%s',$self->get_id);
    
    my $highest_priority = 'z'; ## lowest priority
    my $file_to_process;

    ## Search file with highest priority
    foreach (@{$self->{'spool_files_list'}}) {

	$self->{'current_file'}{'name'} = $_;
	unless ($self->is_current_file_readable) {
	    undef $self->{'current_file'};
	    next;
	}
	
	unless ($self->is_current_file_relevant && $self->analyze_current_file_name) {
	    $self->move_current_file_to_bad;
	    undef $self->{'current_file'};
	    next;
	}

	$self->get_current_file_priority;
	
	if (ord($self->{'current_file'}{'priority'}) < ord($highest_priority)) {
	    $highest_priority = $self->{'current_file'}{'priority'};
	    $file_to_process = $self->{'current_file'};
	}
    } ## END of spool lookup
    $self->{'current_file'} = $file_to_process;
    return $self->{'current_file'};
}

sub is_current_file_relevant {
    my $self = shift;
    Log::do_log('debug3','%s',$self->get_id);
    ## z and Z are a null priority, so file stay in queue and are processed
    ## only if renamed by administrator
    return 0 unless ($self->{'current_file'}{'name'} =~ /$filename_regexp/);

    ## Don't process temporary files created by queue (T.xxx)
    return 0 if ($self->{'current_file'}{'name'} =~ /^T\./);

    return 1;
}
1;
