# subst.pl - This script replaces --VAR-- occurences at installation time
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

foreach $src (@ARGV) {

   unless (open(IN, $src)) {
      print STDERR "Can't read $src: $!\n";
      next;
   }

   unless (defined ($ENV{'INSTALLDIR'})) {
       die "Missing INSTALLDIR variable";
   }

   my $dest;
   if (defined $ENV{'INSTALLNAME'}) {
       $dest = "$ENV{'DESTDIR'}$ENV{'INSTALLDIR'}/$ENV{'INSTALLNAME'}";
   }else {
       $dest = "$ENV{'DESTDIR'}$ENV{'INSTALLDIR'}/$src";
   }

   ## If destination file is a symbolic link, remove it first
   if (-l $dest) {
       print STDERR "Removing symbolic link $dest\n";
       unlink $dest;
   }

   if (-f $dest) {
      print STDERR "Overwriting $dest\n";
   } else {
      print STDERR "Creating $dest\n";
   }
   unless (open(OUT, "> $dest")) {
      print STDERR "Can't write $dest: $!\n";
      close(IN);
      next;
   }
   
#   foreach my $v (keys %ENV) {
#       printf "ENV %s=%s\n", $v, $ENV{$v};
#   }

   while (<IN>) {
       ## Instantiate variables --VAR--
       s/--(\w+)--/$ENV{$1}/g;

       ## Conditional logging, for performances concerns
       if (/^\s*(\&?(Log::)?(do_log|wwslog)\s*\(\'(\w+)\').*$/) {
	   my $facility = $4;
	   my $level = 0;
	   if ($facility =~ /^debug(\d+)?$/) {
	       $level = $1 || 1;
	   }
	   
	   my $condition = '($Log::log_level >= '.$level.') && ';

	   s/^(\s*)/$1$condition/;
       }

       print OUT $_;
   }
   close(OUT);
   close(IN);
#   chown ((getpwnam($ENV{'USER'}))[2,3], $dest);
   chmod oct($ENV{'UMASK'}), $dest;
}
exit(0);
