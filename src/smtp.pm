## This module does the SMTP job, it does send messages using predefined
## limits.

package smtp;

use POSIX;
use Mail::Internet;
use Conf;
use Language;
use Log;

require 'tools.pl';

use strict;

## RCS identification.
#my $id = '@(#)$Id$';

my $opensmtp = 0;
my $fh = 'fh0000000000';	## File handle for the stream.

my $max_arg = eval { &POSIX::_SC_ARG_MAX; };
if ($@) {
    $max_arg = 4096;
    print STDERR Msg(11, 1,'Your system is not POSIX P1003.1 compliant, or it does not define
the _SC_ARG_MAX constant in its POSIX library. You will need to manually edit
smtp.pm and configure $max_arg
');
} else {
    $max_arg = POSIX::sysconf($max_arg);
}

my %pid = ();

## Reaper - Non blocking function called by the main loop, just to
## clean the defuncts list by waiting to any processes and decrementing
## the counter.
sub reaper {
   my $block = shift;
   my $i;

   $block = 1 unless (defined($block));
   while (($i = waitpid(-1, $block ? &POSIX::WNOHANG : 0)) > 0) {
      $block = 1;
      if (!defined($pid{$i})) {
         print STDERR "Reaper waited $i, unknown process to me\n" if ($main::options{'debug'});
         next;
      }
      $opensmtp--;
      delete($pid{$i});
   }
   printf STDERR "Reaper unwaited pids : %s\nOpen = %s\n", join(' ', sort keys %pid), $opensmtp if ($main::options{'debug'});
   return $i;
}

## Makes a sendmail ready for the recipients given as
## argument, uses a file descriptor in the smtp table
## which can be imported by other parties.
sub smtpto {
   my($from, $rcpt, $sign_mode) = @_;
   
   if (ref($rcpt) eq 'SCALAR') {
       do_log('debug2', 'smtp::smtpto(%s, %s, %s )', $from, $$rcpt,$sign_mode);
   }else {
       do_log('debug2', 'smtp::smtpto(%s, %s, %s)', $from, join(',', @{$rcpt}), $sign_mode);
   }

   my($pid, $str);

   ## Escape "-" at beginning of recepient addresses
   ## prevent sendmail from taking it as argument

   if (ref($rcpt) eq 'SCALAR') {
       $$rcpt =~ s/^-/\\-/;
   }else {
       my @emails = @$rcpt;
       foreach my $i (0..$#emails) {
	   $rcpt->[$i] =~ s/^-/\\-/;
       }
   }
   
   ## Check how many open smtp's we have, if too many wait for a few
   ## to terminate and then do our job.
   print STDERR "Open = $opensmtp\n" if ($main::options{'debug'});
   while ($opensmtp > $Conf{'maxsmtp'}) {
       print STDERR "Smtpto: too many open SMTP ($opensmtp), calling reaper\n" if ($main::options{'debug'});
       last if (&reaper(0) == -1); ## Blocking call to the reaper.
   }

   *IN = ++$fh; *OUT = ++$fh;
   

   if (!pipe(IN, OUT)) {
       fatal_err(Msg(11, 2, "Can't create a pipe in smtpto: %m")); ## No return
   }
   $pid = &tools::safefork();
   $pid{$pid} = 0;
   if ($pid == 0) {
       close(OUT);
       open(STDIN, "<&IN");
#       my $filter = '' ;
#       if ($sign_mode eq 'smime') {
#	   # xxxx a remplacer par un pipe in/out ? Attention $filter est pas configurable
#           # xxxx et ne bénéficie pas de Conf.pm 
#
#	   $filter = "/home/sympa/bin/sign_filter.pl -c ./cert.pem -k ./private_key -d |"
#       }
       if (ref($rcpt) eq 'SCALAR') {
#	   exec "$filter $Conf{'sendmail'} -oi -odi -oem -f $from $$rcpt";
	   exec $Conf{'sendmail'}, '-oi', '-odi', '-oem', '-f', $from, $$rcpt;
       }else{
#	   exec "$filter $Conf{'sendmail'} -oi -odi -oem -f $from @$rcpt";
	   exec $Conf{'sendmail'}, '-oi', '-odi', '-oem', '-f', $from, @$rcpt;
       }
       exit 1; ## Should never get there.
   }
   if ($main::options{'messages'}) {
       $str = "safefork: $Conf{'sendmail'} -oi -odi -oem -f $from ";
       if (ref($rcpt) eq 'SCALAR') {
	   $str .= $$rcpt;
       } else {
	   $str .= join(' ', @$rcpt);
       }
       do_log('debug', $str);
   }
   close(IN);
   $opensmtp++;
   select(undef, undef,undef, 0.3) if ($opensmtp < $Conf{'maxsmtp'});
   return("smtp::$fh"); ## Symbol for the write descriptor.
}


## Makes a sendmail ready for the recipients given as
## argument, uses a file descriptor in the smtp table
## which can be imported by other parties.
sub smime_sign {
    my $from = shift;
    my $temporary_file  = shift;
    
    do_log('debug2', 'smtp::smime_sign (%s)', $from);

    exec "$Conf{'openssl'} smime -sign -signer cert.pem -inkey private_key -out $temporary_file";
    exit 1; ## Should never get there.
}


sub sendto {
    my($msg_header, $msg_body, $from, $rcpt, $encrypt) = @_;
    do_log('debug2', 'smtp::sendto(%s, %s, %s)', $from, $rcpt, $encrypt);

    my $msg;

    if ($encrypt eq 'smime_crypted') {
	my $email ;
	if (ref($rcpt) eq 'SCALAR') {
	    $email = lc ($$rcpt) ;
	}else{
	    my @rcpts = @$rcpt;
	    if ($#rcpts != 0) {
		do_log('err',"incorrect call for encrypt with $#rcpts recipient(s)"); 
		return undef;
	    }
	    $email = lc ($rcpt->[0]); 
	}
	$msg = &tools::smime_encrypt ($msg_header, $msg_body, ,$email);
    }else {
        $msg = $msg_header->as_string . "\n" . $msg_body;
    }
    
    if ($msg) {
	*SMTP = &smtpto($from, $rcpt);
        print SMTP $msg;
	close SMTP;
	return 1;
    }else{    
	my $param = {'from' => "$from",
		     'email' => "$rcpt"
		     };   

	my $filename;
	if (-r "x509-user-cert-missing.tpl") {
	    $filename = "x509-user-cert-missing.tpl";
	}elsif (-r "$Conf{'etc'}/templates/x509-user-cert-missing.tpl") {
	    $filename = "$Conf{'etc'}/templates/x509-user-cert-missing.tpl";
	}elsif (-r "--ETCBINDIR--/templates/x509-user-cert-missing.tpl") {
	    $filename = "--ETCBINDIR--/templates/x509-user-cert-missing.tpl";
	}else {
	    # $filename = '';
	    do_log ('err',"Unable to open file x509-user-cert-missing.tpl in list directory NOR $Conf{'etc'}/templates/x509-user-cert-missing.tpl NOR --ETCBINDIR--/templates/x509-user-cert-missing.tpl");
	    return undef;
	}
    
	&mail::mailfile ($filename, $rcpt, $param, 'none');

	return undef;
    }
}

sub mailto {
   my($msg, $from, $encrypt, $originalfile , @rcpt) = @_;
   do_log('debug2', 'smtp::mailto(from: %s, %s, %d rcpt)', $from, $encrypt, $#rcpt);

   my($i, $j, $nrcpt, $size, @sendto);
   my $numsmtp = 0;
   
   ## If message contain a footer or header added by Sympa  use the object message else
   ## Extract body from original file to preserve signature
   my ($msg_body, $msg_header);

   $msg_header = $msg->head;

   if ($originalfile eq '_ALTERED_') {
       $msg_body = $msg->body_as_string;
   }else {
   ## Get body from original file
       unless (open MSG, $originalfile) {
	   do_log ('notice',"unable to open %s:%s",$originalfile,$!);
	   last;
       }
       my $in_header = 1 ;
       while (<MSG>) {
	   if ( !$in_header)  { 
	       $msg_body .= $_;       
	   }else {
	       $in_header = 0 if (/^$/); 
	   }
       }
       close (MSG);
   }
   
   ## if the message must be crypted,  we need to send it using one smtp session for each rcpt
   if ($encrypt eq 'smime_crypted'){
       $numsmtp = 0;
       while ($i = shift(@rcpt)) {
	   &sendto($msg_header, $msg_body, $from, [$i], $encrypt);
	   $numsmtp++
	   }
       
       return ($numsmtp);
   }

   while ($i = shift(@rcpt)) {
       my @k = reverse(split(/[\.@]/, $i));
       my @l = reverse(split(/[\.@]/, $j));
       if ($j && $#sendto >= $Conf{'avg'} && lc("$k[0] $k[1]") ne lc("$l[0] $l[1]")) {
           &sendto($msg_header, $msg_body, $from, \@sendto);
           $numsmtp++;
           $nrcpt = $size = 0;
           @sendto = ();
       }
       if ($#sendto >= 0 && (($size + length($i)) > $max_arg || $nrcpt >= $Conf{'nrcpt'})) {
           &sendto($msg_header, $msg_body, $from, \@sendto);
           $numsmtp++;
           $nrcpt = $size = 0;
           @sendto = ();
       }
       $nrcpt++; $size += length($i) + 5;
       push(@sendto, $i);
       $j = $i;
   }
   if ($#sendto >= 0) {
       &sendto($msg_header, $msg_body, $from, \@sendto) if ($#sendto >= 0);
       $numsmtp++;
   }
   
   return $numsmtp;
}

1;





