# Language.pm - This module does just the initial setup for the international messages
# RCS Identication ; $Revision$ ; $Date$ 
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

package Language;

require Exporter;
use Carp;
@ISA = qw(Exporter);
@EXPORT = qw(Msg);

use strict;
use Locale::Msgcat;
use Log;
use Version;

my %Message;

my $dir;
my $current_lang;
my $default_lang;

sub LoadLang {
    my $catdir = pop;

    unless (-d $catdir && -r $catdir) {
	do_log('info','Cannot read Locale directory %s', $catdir);
	return undef;
    }

    $dir = $catdir;

    unless (opendir CATDIR, $catdir) {
	do_log('info','Unable to open directory %s', $catdir);
	return undef;
    }

    foreach my $file (grep /\.cat$/, readdir(CATDIR)) {    

	$file =~ /^([\w-]+)\.cat$/;
	
	my $catname = $1;

	my $catfile = $catdir.'/'.$catname.'.cat';
	unless (-r $catfile) {
	    do_log('info','Locale file %s not found', $catfile);
	    return undef;
	}

	$Message{$catname} = new Locale::Msgcat;

	unless ($Message{$catname}->catopen($catfile, 1)) {
	    do_log('info','Locale file %s.cat not used, using builtin messages', $catname);
	    return undef;
	}
	
	$current_lang = $catname;
	do_log('info', 'Loading locale file %s.cat version %s', $catname, Msg(1, 102, $Version));	
    }
    closedir CATDIR;

    return 1;
}

sub SetLang {
    my $catname = shift;
    do_log('debug3', 'Language::SetLang(%s)', $catname);
   
    unless (defined ($Message{$catname})) {
	do_log('info','unknown Locale %s', $catname);
	return undef;
    }
	    
    $current_lang = $catname;
    return 1;
}

sub Msg {
    
    if (defined ($Message{$current_lang})) {
	$Message{$current_lang}->catgets(@_);
    }else {
	$_[2];
    }
}

sub GetLang {
    return $current_lang;
}

1;

