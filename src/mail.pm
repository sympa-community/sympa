## This module is part of ML and provides some tools

package mail;

require Exporter;
use Carp;
@ISA = qw(Exporter);
@EXPORT = qw(mailback mailarc mailfile set_send_spool);

#use strict;

use Conf;
use Log;
use Language;
use List;

## RCS identification.
#my $id = '@(#)$Id$';

my $send_spool;

sub set_send_spool {
    my $spool = pop;

    $send_spool = $spool;
}

## Mail back a response to the given address.
## Data is a reference to an array or a scalar.
sub mailback {
   my($data, $subject, $from, $to, @rcpt) = @_;
   do_log('debug2', 'mail::mailback(%s, %s, %s)', $subject, $from, join(',', @rcpt));

   my ($fh, $sympa_file);
   
   ## Don't fork if used by a CGI (FastCGI problem)
   if (defined $send_spool) {
       $sympa_file = "$send_spool/T.sympa.".time.'.'.int(rand(10000));
       my $rcpt = join ',', @rcpt;

       unless (open TMP, ">$sympa_file") {
	   &do_log('notice', 'Cannot create %s : %s', $sympa_file, $!);
	   return undef;
       }
       
       printf TMP "X-Sympa-To: %s\n", $rcpt;
       printf TMP "X-Sympa-Checksum: %s\n", &tools::sympa_checksum($rcpt);
       
       $fh = \*TMP;
   }else {
       $fh = smtp::smtpto("$Conf{'sympa'}", \@rcpt);
   }
   
   printf $fh "To:  %s\n", $to;
   if ($from eq 'sympa') {
       printf $fh "From: %s\n", sprintf (Msg(12, 4, 'SYMPA <%s>'), $Conf{'sympa'});
   }else {
       printf $fh "From: %s\n", $from;
   }
   printf $fh "Subject: $subject\n";
   printf $fh "MIME-Version: %s\n", Msg(12, 1, '1.0');
   printf $fh "Content-Type: text/plain; charset=%s\n", Msg(12, 2, 'us-ascii');
   printf $fh "Content-Transfer-Encoding: %s\n", Msg(12, 3, '7bit');
   print $fh "\n";

   if (ref($data) eq 'SCALAR') {
      print $fh $$data;
   } elsif (ref($data) eq 'ARRAY') {
      print $fh @$data;
   }
   close($fh);
   
   if (defined $sympa_file) {
       my $new_file = $sympa_file;
       $new_file =~ s/T\.//g;
       
       unless (rename $sympa_file, $new_file) {
	   &do_log('notice', 'Cannot rename %s to %s : %s', $sympa_file, $new_file, $!);
	   return undef;
       }
   }

   return 1;
}

## send an archive file
sub mailarc {
   my($filename, $subject, @rcpt) = @_;
   do_log('debug2', 'mail::mailarc(%s, %s)', $subject, join(',', @rcpt));

   my($i);

   if (!open(IN, $filename)) {
      fatal_err("Can't send %s to %s: %m", $filename, join(',', @rcpt));
   }
   my($fh) = &smtp::smtpto($Conf{'request'}, \@rcpt);
   printf $fh "To: %s\n", join(",\n   ", @rcpt);
   print $fh "Subject: $subject\n";
   printf $fh "MIME-Version: %s\n", Msg(12, 1, '1.0');
   printf $fh "Content-Type: text/plain; charset=%s\n", Msg(12, 2, 'us-ascii');
   printf $fh "Content-Transfer-Encoding: %s\n", Msg(12, 3, '7bit');
   print $fh "\n";
   print $fh $i while ($i = <IN>);
   close($fh);
}

## send welcome, bye, expire removed or reminder message to a user
sub mailfile {
   my ($filename, $rcpt, $data, $sign_mode) = @_;
   do_log('debug2', 'mail::mailfile(%s, %s, %s)', $filename, $rcpt, $sign_mode);

   my ($full_msg, $return_path, $sendmail, $to, $sympa_file);

   ## We may receive a list a recepients
   
   if (ref ($rcpt)) {
       unless (ref ($rcpt) eq 'ARRAY') {
	   &do_log('notice', 'Wrong type of reference for rcpt');
	   return undef;
       }

       if ($sign_mode eq 'smime') {
	   &do_log('notice', 'Cannot sign a message with multiple recepients');
	   return undef;
       }

       if ($data->{'to'}) {
	   $to = $data->{'to'};
       }else {
	   $to = join(",\n   ", @{$rcpt});
       }
   }else{
       $to = $rcpt;
   }   

   ## Get a FD
#   unless ($sign_mode eq 'smime') {

       ## Don't fork if used by a CGI (FastCGI problem)
       if (defined $send_spool) {
	   $sympa_file = "$send_spool/T.sympa.".time.'.'.int(rand(10000));
	   
	   unless (open TMP, ">$sympa_file") {
	       &do_log('notice', 'Cannot create %s : %s', $sympa_file, $!);
	       return undef;
	   }

	   printf TMP "X-Sympa-To: %s\n", $rcpt;
	   printf TMP "X-Sympa-Checksum: %s\n", &tools::sympa_checksum($rcpt);
	   
	   $sendmail = \*TMP;
       }else {
	   
	   if (ref ($rcpt)) {
	       $sendmail = &smtp::smtpto($data->{'return_path'}, $rcpt);
	   }else {
	       $sendmail = &smtp::smtpto($data->{'return_path'}, \$rcpt);
	   }
       }
#  }

   ## Does the file include headers ?
   if ($filename =~ /\.tpl$/) {
       open TPL, $filename;
       my $first_line = <TPL>;
       $full_msg = 1 if ($first_line =~ /^From:\s/);
       close TPL;
   }

   ## If message needs to be signed
   my ($fh, $tmp_file);
   if ($sign_mode eq 'smime') {
       $tmp_file = $Conf{'tmpdir'}.'/sympa_mailfile_'.time.'.'.$$;

       unless (open TMP, ">$tmp_file") {
	   &do_log('notice', 'Cannot create %s : %s', $tmp_file, $!);
	   return undef;
       }

       $fh = \*TMP;
   }else {
       $fh = $sendmail;
   }

   printf $fh "To: %s\n", $to;


   ## Not a complete MIME message
   unless ( $full_msg or ($filename =~ /\.mime$/) ){
       print $fh "From: $data->{'from'}\n";
       print $fh "Subject: $data->{'subject'}\n";
       print $fh "Reply-to: $data->{'replyto'}\n" if ($data->{'replyto'}) ;
       printf $fh "MIME-Version: %s\n", Msg(12, 1, '1.0');
       printf $fh "Content-Type: text/plain; charset=%s\n", Msg(12, 2, 'us-ascii');
       printf $fh "Content-Transfer-Encoding: %s\n", Msg(12, 3, '7bit');
       print $fh "\n";
   }

   if ($filename) {
       if ($filename =~ /\.tpl$/) {
	   &main::parse_tpl($data, $filename, $fh);

       }else {
	   ## Old style
	   open IN, $filename;
	   while (<IN>) {
	       s/\[listname\]/$data->{'list'}{'name'}/g;
	       s/\[subscriber_email\]/$data->{'user'}{'email'}/g;
	       s/\[email_subscriber\]/$data->{'user'}{'email'}/g;
	       s/\[subscriber_gecos\]/$data->{'user'}{'gecos'}/g;
	       s/\[sympa_email\]/$data->{'conf'}{'sympa'}/g;
	       s/\[sympa_host\]/$data->{'conf'}{'host'}/g;
	       print $fh $_ ;
	   }
	   close IN;
       }
   }else{
       print $fh $data->{'body'};
   }
   close ($fh);
   
   if (defined $sympa_file) {
       my $new_file = $sympa_file;
       $new_file =~ s/T\.//g;

       unless (rename $sympa_file, $new_file) {
	   &do_log('notice', 'Cannot rename %s to %s : %s', $sympa_file, $new_file, $!);
	   return undef;
       }
   }

   if ($sign_mode eq 'smime') {
       ## Open and parse the file   
       if (!open(MSG, $tmp_file)) {
	   &do_log('info', 'Can\'t open %s: %m', $tmp_file);
	   return undef;
       }
    
       my $parser = new MIME::Parser;
       $parser->output_to_core(1);
       my $in_msg;
       unless ($in_msg = $parser->read(\*MSG)) {
	   do_log('notice', 'Unable to parse message %s', $file);
	   return undef;
       }
       close MSG;
       
       
       ## Signing the message
       my $signed_msg ;
       unless ($signed_msg = &tools::smime_sign($in_msg,$data->{'list'}{'name'})) {
	   do_log('notice', 'Unable to sign message from %s', $data->{'list'}{'name'});
	   return undef;
       }
       # dump signed message to sendmail

       $signed_msg->print($sendmail);
       close $sendmail;

   }
   
   return 1;
}


1;









