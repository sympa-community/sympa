# KeySpool: this module contains methods to handle filesystem spools containing moderated messages.
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

package KeySpool;

use SympaspoolClassic;
use Log;

our @ISA = qw(SympaspoolClassic);

our $filename_regexp = '^(\S+)_(\w+)(\.distribute)?$';

sub new {
    Log::do_log('debug2', '(%s)', @_);
    my $pkg = shift;
    my $spool = SympaspoolClassic->new('mod');
    bless $spool, $pkg;
    return $spool;
}

sub get_storage_name {
    my $self = shift;
    my $filename;
    my $param = shift;
    if ($param->{'list'} && $param->{'robot'}) {
	$filename = $param->{'list'}.'@'.$param->{'robot'}.'_'.$param->{'authkey'};
    }
    return $filename;
}

sub analyze_current_file_name {
    my $self = shift;
    Log::do_log('debug3','%s',$self->get_id);
    unless($self->{'current_file'}{'name'} =~ /$filename_regexp/){
	Log::do_log('err','File %s name does not have the proper format. Stopping here.',$self->{'current_file'}{'name'});
	return undef;
    }
    ($self->{'current_file'}{'list'}, $self->{'current_file'}{'robot'}) = split(/\@/,$1);
    $self->{'current_file'}{'authkey'} = $2;
    $self->{'current_file'}{'validated'} = $3;
    
    $self->{'current_file'}{'list'} = lc($self->{'current_file'}{'list'});
    $self->{'current_file'}{'robot'}=lc($self->{'current_file'}{'robot'});
    return undef unless ($self->{'current_file'}{'robot_object'} = Robot->new($self->{'current_file'}{'robot'}));

    my $list_check_regexp = $self->{'current_file'}{'robot_object'}->list_check_regexp;

    if ($self->{'current_file'}{'list'} =~ /^(\S+)-($list_check_regexp)$/) {
	($self->{'current_file'}{'list'}, $self->{'current_file'}{'type'}) = ($1, $2);
    }
    return undef unless ($self->{'current_file'}{'list_object'} = List->new($self->{'current_file'}{'list'},$self->{'current_file'}{'robot_object'}));
    return 1;
}

## Return messages not validated yet.
sub get_awaiting_messages {
    my $self = shift;
    my $param = shift;
    $param->{'selector'}{'validated'} = ['.distribute','ne'];
    $self->get_content($param);
    return @{$self->{'current_files_in_spool'}};
}

sub validate_message {
    my $self = shift;
    my $file = shift;
    $file ||= $self->{'current_file'}{'name'};
    unless(File::Copy::copy($self->{'dir'}.'/'.$file , $self->{'dir'}.'/'.$file.'.distribute')) {
	Log::do_log('err','Could not rename file %s: %s',$self->{'dir'}.'/'.$file,$!);
	return undef;
    }
    unless (unlink ($self->{'dir'}.'/'.$file )) {
	&Log::do_log('err',"Could not unlink message %s/%s . Exiting",$self->{'dir'}, $file );
    }
    return 1;
}

1;
