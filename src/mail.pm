# mail.pm - This module includes mail sending functions
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
   my($data, $headers, $from, $to, $robot, @rcpt) = @_;
   do_log('debug2', 'mail::mailback(%s, %s)', $from, join(',', @rcpt));

   my ($fh, $sympa_file);
   
   my $sympa_email =  &Conf::get_robot_conf($robot, 'sympa');

   ## Don't fork if used by a CGI (FastCGI problem)
   if (defined $send_spool) {
       $sympa_file = "$send_spool/T.$sympa_email.".time.'.'.int(rand(10000));
       my $rcpt = join ',', @rcpt;

       unless (open TMP, ">$sympa_file") {
	   &do_log('notice', 'Cannot create %s : %s', $sympa_file, $!);
	   return undef;
       }
       
       printf TMP "X-Sympa-To: %s\n", $rcpt;
       printf TMP "X-Sympa-From: %s\n", $sympa_email;
       printf TMP "X-Sympa-Checksum: %s\n", &tools::sympa_checksum($rcpt);
       
       $fh = \*TMP;
   }else {
       $fh = smtp::smtpto($sympa_email, \@rcpt);
   }
   
   ## Charset for encoding
   my $charset = sprintf (Msg(12, 2, 'us-ascii'));

   printf $fh "To:  %s\n", MIME::Words::encode_mimewords($to, 'Q', $charset);
   if ($from eq 'sympa') {
       printf $fh "From: %s\n", MIME::Words::encode_mimewords((sprintf (Msg(12, 4, 'SYMPA <%s>'), $sympa_email)), 'Q', $charset);
   }else {
       printf $fh "From: %s\n", $from;
   }
   foreach my $field (keys %{$headers}) {
       printf $fh "%s: %s\n", $field, MIME::Words::encode_mimewords($headers->{$field}, 'Q', $charset);
   }
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
   my($fh) = &smtp::smtpto($Conf{'robots'}{$robot}{'sympa'} || $Conf{'request'}, \@rcpt);
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
   my ($filename, $rcpt, $data, $robot, $sign_mode) = @_;
   do_log('debug2', 'mail::mailfile(%s, %s, %s, %s)', $filename, $rcpt, $robot, $sign_mode);

   my ($full_msg, $return_path, $sendmail, $to, $sympa_file);

   ## We may receive a list a recepients
   
   if (ref ($rcpt)) {
       unless (ref ($rcpt) eq 'ARRAY') {
	   &do_log('notice', 'Wrong type of reference for rcpt');
	   return undef;
       }

#       if ($sign_mode eq 'smime') {
#	   &do_log('notice', 'Cannot sign a message with multiple recepients');
#	   return undef;
#       }

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
	   my $sympa_email = $data->{'conf'}{'sympa'} || &Conf::get_robot_conf($robot, 'sympa');
	   $sympa_file = "$send_spool/T.$sympa_email.".time.'.'.int(rand(10000));
	   
	   unless (open TMPMSG, ">$sympa_file") {
	       &do_log('notice', 'Cannot create %s : %s', $sympa_file, $!);
	       return undef;
	   }

	   printf TMPMSG "X-Sympa-To: %s\n", $rcpt;
	   printf TMPMSG "X-Sympa-From: %s\n", $data->{'return_path'};
	   printf TMPMSG "X-Sympa-Checksum: %s\n", &tools::sympa_checksum($rcpt);
	   
	   $sendmail = \*TMPMSG;
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

       unless (open TMPSMIME, ">$tmp_file") {
	   &do_log('notice', 'Cannot create %s : %s', $tmp_file, $!);
	   return undef;
       }

       $fh = \*TMPSMIME;
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
	   &parser::parse_tpl($data, $filename, $fh);

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
       unless ($signed_msg = &tools::smime_sign($in_msg,$data->{'list'}{'name'}, $data->{'list'}{'dir'})) {
	   do_log('notice', 'Unable to sign message from %s', $data->{'list'}{'name'});
	   return undef;
       }
       # dump signed message to sendmail

       $signed_msg->print($sendmail);
       close $sendmail;

   }
   
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


1;









