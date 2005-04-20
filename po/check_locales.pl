# check_locales.pl - This script checks available locales on the system
# Sympa uses locales to build the user interface ; if none is available, 
# Sympa will speak English only

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

use POSIX qw (setlocale);

my @locales = split /\s+/,$ENV{'SYMPA_LOCALES'};

my (@supported, @not_supported);

foreach my $l (@locales) {
    if (setlocale(&POSIX::LC_ALL, $l)) {
	push @supported, $l;
    }else {
	push @not_supported, $l;
    }
}

if ($#supported == -1) {
    printf "#########################################################################################################\n";
    printf "## IMPORTANT : Sympa is not able to use locales because they are not properly configured on this server\n";
    printf "## You should activate some of the following locales :\n";
    printf "##     %s\n", join(' ', @locales);
    printf "## On Debian you should run the following command : dpkg-reconfigure locales\n";
    printf "## On others systems, check /etc/locale.gen or /etc/sysconfig/i18n files\n";
    printf "#########################################################################################################\n";
    
    my $s = $<;
}elsif ($#not_supported > -1){
    printf "#############################################################################################################\n";
    printf "## IMPORTANT : Sympa is not able to use all supported because they are not properly configured on this server\n";
    printf "## Herer is a list on NOT supported locales :\n";
    printf "##     %s\n", join(' ', @not_supported);
    printf "## On Debian you should run the following command : dpkg-reconfigure locales\n";
    printf "## On others systems, check /etc/locale.gen or /etc/sysconfig/i18n files\n";
    printf "#############################################################################################################\n";
    
    my $s = $<;
}

