#! --PERL--

# Log.pm - This module includes all Logging-related functions
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

package Log;

require Exporter;
use Sys::Syslog;
use Carp;

@ISA = qw(Exporter);
@EXPORT = qw(fatal_err do_log do_openlog);

my ($log_facility, $log_socket_type, $log_service);

sub fatal_err {
    my $m  = shift;
    my $errno  = $!;
    
    syslog('err', $m, @_);
    syslog('err', "Exiting.");
#   if ($main::options{'debug'} || $main::options{'foreground'}) {
    $m =~ s/%m/$errno/g;
    printf STDERR "$m\n", @_;
#   }
    exit(1);   
}

sub do_log {
    my $fac = shift;
    my $m = shift;
    my $errno = $!;
    my $debug = 0;

    if ($fac eq 'debug2') {
	$fac = 'debug';
	$debug = 1;
	
    }else {
	unless (syslog($fac, $m, @_)) {
	    &do_connect();
	    syslog($fac, $m, @_);
	}
    }

    $m =~ s/%m/$errno/g;

    if ($main::options{'debug2'}) {
	printf STDERR "%s\t$m\n", time, @_;
    }elsif($debug){
	return ;
    }elsif ($main::options{'debug'} || $main::options{'foreground'})   {
#    }elsif ($main::options{'debug'} || $main::options{'foreground'} || $ENV{'HTTP_HOST'})   {
	printf STDERR "$m\n", @_;
	
    }
    
}


sub do_list_log {
   my $list = shift;
   my $message = shift;

   syslog($fac, $m, @_);
   if ($main::options{'debug'} || $main::options{'foreground'}) {
      $m =~ s/%m/$errno/g;
      printf STDERR "$m\n", @_;
   }
}

sub do_openlog {
   my ($fac, $socket_type, $service) = @_;
   $service ||= 'sympa';

   ($log_facility, $log_socket_type, $log_service) = ($fac, $socket_type, $service);

#   foreach my $k (keys %options) {
#       printf "%s = %s\n", $k, $options{$k};
#   }

   &do_connect();
}

sub do_connect {
    if ($log_socket_type =~ /^(unix|inet)$/i) {
      Sys::Syslog::setlogsock(lc($log_socket_type));
    }
    openlog("$log_service\[$$\]", 'ndelay', $log_facility);
}

1;








