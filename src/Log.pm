#! --PERL--
##
## This module is part of "Sympa" software

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








