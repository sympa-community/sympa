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
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

package Messagespool;

use SympaspoolClassic;
use Log;

our @ISA = qw(SympaspoolClassic);

sub new {
    Sympa::Log::Syslog::do_log('debug2', '(%s, %s)', @_);
    my $pkg = shift;
    return $pkg->SUPER::new('msg', shift,
	'sortby' => 'priority',
	'selector' => {'priority' => ['z', 'ne']},
    );
}

sub is_relevant {
    Sympa::Log::Syslog::do_log('debug3', '(%s, %s)', @_);
    my $self = shift;
    my $key  = shift;

    ## z and Z are a null priority, so file stay in queue and are processed
    ## only if renamed by administrator
    return 0 unless $key =~ /$filename_regexp/;

    ## Don't process temporary files created by queue (T.xxx)
    return 0 if $key =~ /^T\./;

    return 1;
}

1;
