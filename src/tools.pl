# tools.pl - This module provides various tools for Sympa
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

package tools;

use POSIX;
use Mail::Internet;
use Mail::Header;
use Conf;
use Language;
use Log;
use Time::Local;
use File::Find;
use Digest::MD5;

## RCS identification.
#my $id = '@(#)$Id$';

## global var to store a CipherSaber object 
my $cipher;

my $separator="------- CUT --- CUT --- CUT --- CUT --- CUT --- CUT --- CUT -------";

## Regexps for list params
## Caution : if this regexp changes (more/less parenthesis), then regexp using it should 
## also be changed
%regexp = ('email' => '([\w\-\_\.\/\+\=\']+|\".*\")\@[\w\-]+(\.[\w\-]+)+',
	   'host' => '[\w\.\-]+',
	   'multiple_host_with_port' => '[\w\.\-]+(:\d+)?(,[\w\.\-]+(:\d+)?)*',
	   'listname' => '[a-z0-9][a-z0-9\-\.\+_]*',
	   'sql_query' => '(SELECT|select).*',
	   'scenario' => '[\w,\.\-]+',
	   'task' => '\w+'
	   );

my %openssl_errors = (1 => 'an error occurred parsing the command options',
		      2 => 'one of the input files could not be read',
		      3 => 'an error occurred creating the PKCS#7 file or when reading the MIME message',
		      4 => 'an error occurred decrypting or verifying the message',
		      5 => 'the message was verified correctly but an error occurred writing out the signers certificates');

## Sorts the list of adresses by domain name
## Input : users hash
## Sort by domain.
sub sortbydomain {
   my($x, $y) = @_;
   $x = join('.', reverse(split(/[@\.]/, $x)));
   $y = join('.', reverse(split(/[@\.]/, $y)));
   #print "$x $y\n";
   $x cmp $y;
}

## Safefork does several tries before it gives up.
## Do 3 trials and wait 10 seconds * $i between each.
## Exit with a fatal error is fork failed after all
## tests have been exhausted.
sub safefork {
   my($i, $pid);
   
   for ($i = 1; $i < 4; $i++) {
      my($pid) = fork;
      return $pid if (defined($pid));
      do_log ('warning', "Can't create new process in safefork: %m");
      ## should send a mail to the listmaster
      sleep(10 * $i);
   }
   fatal_err("Can't create new process in safefork: %m");
   ## No return.
}

## Check for commands in the body of the message. Returns true
## if there are some commands in it.
sub checkcommand {
   my($msg, $sender, $robot) = @_;
   do_log('debug3', 'tools::checkcommand(msg->head->get(subject): %s,%s)',$msg->head->get('Subject'), $sender);

   my($avoid, $i);

   my $hdr = $msg->head;

   ## Check for commands in the subject.
   my $subject = $msg->head->get('Subject');
   if ($subject) {
       if ($Conf{'misaddressed_commands_regexp'} && ($subject =~ /^$Conf{'misaddressed_commands_regexp'}$/im)) {
	   &rejectMessage($msg, $sender,$robot);
	   return 1;
       }
   }

   return 0 if ($#{$msg->body} >= 5);  ## More than 5 lines in the text.

   foreach $i (@{$msg->body}) {
       if ($Conf{'misaddressed_commands_regexp'} && ($i =~ /^$Conf{'misaddressed_commands_regexp'}$/im)) {
	   &rejectMessage($msg, $sender, $robot);
	   return 1;
       }

       ## Control is only applied to first non-blank line
       last unless $i =~ /^\s*$/;
   }
   return 0;
}

sub rejectMessage {
   my($msg, $sender, $robot) = @_;
   do_log('debug2', 'tools::rejectMessage(%s)', $sender);

   *REJ = smtp::smtpto(&Conf::get_robot_conf($robot, 'request'), \$sender);
   print REJ "To: $sender\n";
   print REJ "Subject: [sympa] " . gettext("Routing error ?") . "\n";
   printf REJ "MIME-Version: 1.0\n";
   printf REJ "Content-Type: text/plain; charset=%s\n", gettext("_charset_");
   printf REJ "Content-Transfer-Encoding: %s\n", gettext("_encoding_");
   print REJ "\n";
   printf REJ gettext("The following message was sent to a list while it seems to contain\ncommands like subscribe, unsubscribe, help, index, get, ...\n\nIf your message effectively contained a command, please notice that \ncommands should never ever be sent to lists. Commands must be sent\nto %s exclusively.\n\nIf your message was effectively addressed to the list, it has been\ninterpreted by the software as a command. Please contact the manager\nof the service : %s so that they can take care of your message.\n\nThank you for your attention.\n\n------ Beginning of suspected message ------\n"), &Conf::get_robot_conf($robot, 'sympa'), &Conf::get_robot_conf($robot, 'request');
   $msg->print(\*REJ);
   print REJ gettext("------ End of suspected message ------\n");
   close(REJ);
}

## return a hash from the edit_list_conf file
sub load_edit_list_conf {
    my $robot = shift;
    do_log('debug2', 'tools::load_edit_list_conf (%s)',$robot);

    my $file;
    my $conf ;
    
    return undef 
	unless ($file = &tools::get_filename('etc','edit_list.conf',$robot));

    unless (open (FILE, $file)) {
	&do_log('info','Unable to open config file %s', $file);
	return undef;
    }

    my $error_in_conf;
    $roles_regexp = 'listmaster|privileged_owner|owner|editor|subscriber|default';
    while (<FILE>) {
	next if /^\s*(\#.*|\s*)$/;

	if (/^\s*(\S+)\s+(($roles_regexp)\s*(,\s*($roles_regexp))*)\s+(read|write|hidden)\s*$/i) {
	    my ($param, $role, $priv) = ($1, $2, $6);
	    my @roles = split /,/, $role;
	    foreach my $r (@roles) {
		$r =~ s/^\s*(\S+)\s*$/$1/;
		if ($r eq 'default') {
		    $error_in_conf = 1;
		    &do_log('notice', '"default" is no more recognised');
		    foreach my $set ('owner','privileged_owner','listmaster') {
			$conf->{$param}{$set} = $priv;
		    }
		    next;
		}
		$conf->{$param}{$r} = $priv;
	    }
	}else{
	    &do_log ('info', 'unknown parameter in %s  (Ignored) %s', "$Conf{'etc'}/edit_list.conf",$_ );
	    next;
	}
    }

    if ($error_in_conf) {
	&List::send_notify_to_listmaster('edit_list_error', $robot, $file);
    }
    
    close FILE;
    return $conf;
}


## return a hash from the edit_list_conf file
sub load_create_list_conf {
    my $robot = shift;

    my $file;
    my $conf ;
    
    $file = &tools::get_filename('etc', 'create_list.conf', $robot);
    unless ($file) {
	&do_log('info','unable to read --ETCBINDIR--/create_list.conf');
	return undef;
    }

    unless (open (FILE, $file)) {
	&do_log('info','Unable to open config file %s', $file);
	return undef;
    }

    while (<FILE>) {
	next if /^\s*(\#.*|\s*)$/;

	if (/^\s*(\S+)\s+(read|hidden)\s*$/i) {
	    $conf->{$1} = lc($2);
	}else{
	    &do_log ('info', 'unknown parameter in %s  (Ignored) %s', "$Conf{'etc'}/create_list.conf",$_ );
	    next;
	}
    }
    
    close FILE;
    return $conf;
}

sub _add_topic {
    my ($name, $title) = @_;
    my $topic = {};

    my @tree = split '/', $name;
    if ($#tree == 0) {
	return {'title' => $title};
    }else {
	$topic->{'sub'}{$name} = &_add_topic(join ('/', @tree[1..$#tree]), $title);
	return $topic;
    }
}

sub get_list_list_tpl {
    my $robot = shift;

    my $list_conf;
    my $list_templates ;
    unless ($list_conf = &load_create_list_conf($robot)) {
	return undef;
    }
    
    foreach my $dir ('--ETCBINDIR--/create_list_templates', "$Conf{'etc'}/create_list_templates",
		     "$Conf{'etc'}/$robot/create_list_templates") {
	if (opendir(DIR, $dir)) {
	    foreach my $template ( sort grep (!/^\./,readdir(DIR))) {

		my $status = $list_conf->{$template} || $list_conf->{'default'};

		next if ($status eq 'hidden') ;

		$list_templates->{$template}{'path'} = $dir;

		if (-r $dir.'/'.$template.'/comment.tt2') {
		    $list_templates->{$template}{'comment'} = $dir.'/'.$template.'/comment.tt2';
		}
	    }
	    closedir(DIR);
	}
    }

    return ($list_templates);
}

# input object msg and listname, output signed message object
sub smime_sign {
    my $in_msg = shift;
    my $list = shift;
    my $dir = shift;

    do_log('debug2', 'tools::smime_sign (%s,%s)',$in_msg,$list);

    my $self = new List($list);
    my($cert, $key) = &smime_find_keys($self->{dir}, 'sign');
    my $temporary_file = $Conf{'tmpdir'}."/".$list.".".$$ ;    

    my ($signed_msg,$pass_option );
    $pass_option = "-passin file:$Conf{'tmpdir'}/pass.$$" if ($Conf{'key_passwd'} ne '') ;

    ## Keep a set of header fields ONLY
    ## OpenSSL only needs content type & encoding to generate a multipart/signed msg
    my $dup_msg = $in_msg->dup;
    foreach my $field ($dup_msg->head->tags) {
         next if ($field =~ /^content-type|content-transfer-encoding$/i);
         $dup_msg->head->delete($field);
    }
	    

    ## dump the incomming message.
    if (!open(MSGDUMP,"> $temporary_file")) {
	&do_log('info', 'Can\'t store message in file %s', $temporary_file);
	return undef;
    }
    $dup_msg->print(\*MSGDUMP);
    close(MSGDUMP);

    if ($Conf{'key_passwd'} ne '') {
	unless ( &POSIX::mkfifo("$Conf{'tmpdir'}/pass.$$",0600)) {
	    do_log('notice', 'Unable to make fifo for %s/pass.%s',$Conf{'tmpdir'},$$);
	}
    }

     &do_log('debug3', "$Conf{'openssl'} smime -sign -signer $cert $pass_option -inkey $key -in $temporary_file");
     unless (open (NEWMSG,"$Conf{'openssl'} smime -sign -signer $cert $pass_option -inkey $key -in $temporary_file |")) {
    	&do_log('notice', 'Cannot sign message');
    }

    if ($Conf{'key_passwd'} ne '') {
	unless (open (FIFO,"> $Conf{'tmpdir'}/pass.$$")) {
	    do_log('notice', 'Unable to open fifo for %s/pass.%s',$Conf{'tmpdir'},$$);
	}

	print FIFO $Conf{'key_passwd'};
	close FIFO;
	unlink ("$Conf{'tmpdir'}/pass.$$");
    }

    my $parser = new MIME::Parser;

    $parser->output_to_core(1);
    unless ($signed_msg = $parser->read(\*NEWMSG)) {
	do_log('notice', 'Unable to parse message');
	return undef;
    }
    close NEWMSG ;

    my $status = $?/256 ;
    unless ($status == 0) {
	do_log('notice', 'Unable to S/MIME sign message : status = %d', $status);
	return undef;	
    }

    unlink ($temporary_file) unless ($main::options{'debug'}) ;
    
    ## foreach header defined in  the incomming message but undefined in the
    ## crypted message, add this header in the crypted form.
    my $predefined_headers ;
    foreach my $header ($signed_msg->head->tags) {
	$predefined_headers->{$header} = 1 if ($signed_msg->head->get($header)) ;
    }
    foreach my $header ($in_msg->head->tags) {
	$signed_msg->head->add($header,$in_msg->head->get($header)) unless $predefined_headers->{$header} ;
    }

    return $signed_msg;
}


sub smime_sign_check {
    my $message = shift;

    my $sender = $message->{'sender'};
    my $file = $message->{'filename'};

    do_log('debug2', 'tools::smime_sign_check (message, %s, %s)', $sender, $file);

    my $is_signed = {};
    $is_signed->{'body'} = undef;   
    $is_signed->{'subject'} = undef;

    my $verify ;

    ## first step is the msg signing OK ; /tmp/sympa-smime.$$ is created
    ## to store the signer certificat for step two. I known, that's durty.

    my $temporary_file = "/tmp/smime-sender.".$$ ;
    my $trusted_ca_options = '';
    $trusted_ca_options = "-CAfile $Conf{'cafile'} " if ($Conf{'cafile'});
    $trusted_ca_options .= "-CApath $Conf{'capath'} " if ($Conf{'capath'});
    do_log('debug3', "$Conf{'openssl'} smime -verify  $trusted_ca_options -signer  $temporary_file");

    unless (open (MSGDUMP, "| $Conf{'openssl'} smime -verify  $trusted_ca_options -signer $temporary_file > /dev/null")) {

	do_log('err', "unable to verify smime signature from $sender $verify");
	return undef ;
    }

    if ($message->{'smime_crypted'}) {
	$message->{'msg'}->head->print(\*MSGDUMP);
	print MSGDUMP "\n";
	print MSGDUMP ${$message->{'msg_as_string'}};
    }else {
	unless (open MSG, $file) {
	    do_log('err', 'Unable to open file %s: %s', $file, $!);
	    return undef;
	}
	print MSGDUMP <MSG>;
    }

    close MSG;
    close MSGDUMP;

    my $status = $?/256 ;
    unless ($status == 0) {
	do_log('err', 'Unable to check S/MIME signature : %s', $openssl_errors{$status});
	return undef ;
    }
    
    ## second step is the message signer match the sender
    ## a better analyse should be performed to extract the signer email. 
    my $signer = smime_parse_cert({file => $temporary_file});

    unless ($signer->{'email'} eq lc($sender)) {
	unlink($temporary_file) unless ($main::options{'debug'}) ;	
	&do_log('notice', "S/MIME signed message, sender(%s) does NOT match signer(%s)",$sender,$signer->{'email'});
	return undef;
    }

    &do_log('debug', "S/MIME signed message, signature checked and sender match signer(%s)",$signer->{'email'});
    ## store the signer certificat
    unless (-d $Conf{'ssl_cert_dir'}) {
	if ( mkdir ($Conf{'ssl_cert_dir'}, 0775)) {
	    do_log('info', "creating spool $Conf{'ssl_cert_dir'}");
	}else{
	    do_log('err', "Unable to create user certificat directory $Conf{'ssl_cert_dir'}");
	}
    }

    ## It gets a bit complicated now. openssl smime -signer only puts
    ## the _signing_ certificate into the given file; to get all included
    ## certs, we need to extract them from the signature proper, and then
    ## we need to check if they are for our user (CA and intermediate certs
    ## are also included), and look at the purpose:
    ## "S/MIME signing : Yes/No"
    ## "S/MIME encryption : Yes/No"
    my $certbundle = "$Conf{tmpdir}/certbundle.$$";
    my $tmpcert = "$Conf{tmpdir}/cert.$$";
    my $nparts = $message->{msg}->parts;
    my $extracted = 0;
    &do_log('debug2', "smime_sign_check: parsing $nparts parts");
    if($nparts == 0) { # could be opaque signing...
	$extracted +=&smime_extract_certs($message->{msg}, $certbundle);
    } else {
	for (my $i = 0; $i < $nparts; $i++) {
	    my $part = $message->{msg}->parts($i);
	    $extracted += &smime_extract_certs($part, $certbundle);
	    last if $extracted;
	}
    }
    
    unless($extracted) {
	&do_log('err', "No application/x-pkcs7-* parts found");
	return undef;
    }

    unless(open(BUNDLE, $certbundle)) {
	&do_log('err', "Can't open cert bundle $certbundle: $!");
	return undef;
    }
    
    ## read it in, split on "-----END CERTIFICATE-----"
    my $cert = '';
    my(%certs);
    while(<BUNDLE>) {
	$cert .= $_;
	if(/^-----END CERTIFICATE-----$/) {
	    my $workcert = $cert;
	    $cert = '';
	    unless(open(CERT, ">$tmpcert")) {
		&do_log('err', "Can't create $tmpcert: $!");
		return undef;
	    }
	    print CERT $workcert;
	    close(CERT);
	    my($parsed) = &smime_parse_cert({file => $tmpcert});
	    unless($parsed) {
		&do_log('err', 'No result from smime_parse_cert');
		return undef;
	    }
	    unless($parsed->{'email'}) {
		&do_log('debug', "No email in cert for $parsed->{subject}, skipping");
		next;
	    }
	    
	    &do_log('debug', "Found cert for <$parsed->{email}>");

	    if (lc($sender) eq $parsed->{email}) {
		if ($parsed->{'purpose'}{'sign'} && $parsed->{'purpose'}{'enc'}) {
		    $certs{'both'} = $workcert;
		    &do_log('debug', 'Found a signing + encryption cert');
		}elsif ($parsed->{'purpose'}{'sign'}) {
		    $certs{'sign'} = $workcert;
		    &do_log('debug', 'Found a signing cert');
		} elsif($parsed->{'purpose'}{'enc'}) {
		    $certs{'enc'} = $workcert;
		    &do_log('debug', 'Found an encryption cert');
		}
	    }
	    last if(($certs{'both'}) || ($certs{'sign'} && $certs{'enc'}));
	}
    }
    close(BUNDLE);
    if(!($certs{both} || ($certs{sign} && $certs{enc}))) {
	&do_log('err', "Could not extract certificate for $signer->{email}");
	return undef;
    }
    ## OK, now we have the certs, either a combined sign+encryption one
    ## or a pair of single-purpose. save them, as email@addr if combined,
    ## or as email@addr@sign / email@addr@enc for split certs.
    foreach my $c (keys %certs) {
	my $fn = "$Conf{ssl_cert_dir}/" . &escape_chars(lc($sender));
	if ($c ne 'both') {
	    unlink($fn); # just in case there's an old cert left...
	    $fn .= "\@$c";
	}else {
	    unlink("$fn\@enc");
	    unlink("$fn\@sign");
	}
	&do_log('debug', "Saving $c cert in $fn");
	unless (open(CERT, ">$fn")) {
	    &do_log('err', "Unable to create certificate file $fn: $!");
	    return undef;
	}
	print CERT $certs{$c};
	close(CERT);
    }

    unless ($main::options{'debug'}) {
	unlink($temporary_file);
	unlink($tmpcert);
	unlink($certbundle);
    }

    $is_signed->{'body'} = 'smime';
    
    # futur version should check if the subject was part of the SMIME signature.
    $is_signed->{'subject'} = $signer;
    return $is_signed;
}

# input : msg object, return a new message object encrypted
sub smime_encrypt {
    my $msg_header = shift;
    my $msg_body = shift;
    my $email = shift ;
    my $list = shift ;

    my $usercert;
    my $dummy;
    my $cryptedmsg;
    my $encrypted_body;    

    &do_log('debug2', 'tools::smime_encrypt( %s, %s', $email, $list);
    if ($list eq 'list') {
	my $self = new List($email);
	($usercert, $dummy) = smime_find_keys($self->{dir}, 'encrypt');
    }else{
	my $base = "$Conf{'ssl_cert_dir'}/".&tools::escape_chars($email);
	if(-f "$base\@enc") {
	    $usercert = "$base\@enc";
	} else {
	    $usercert = "$base";
	}
    }
    if (-r $usercert) {
	my $temporary_file = $Conf{'tmpdir'}."/".$email.".".$$ ;

	## encrypt the incomming message parse it.
        do_log ('debug3', "tools::smime_encrypt : $Conf{'openssl'} smime -encrypt -out $temporary_file -des3 $usercert");

	if (!open(MSGDUMP, "| $Conf{'openssl'} smime -encrypt -out $temporary_file -des3 $usercert")) {
	    &do_log('info', 'Can\'t encrypt message for recipient %s', $email);
	}
## don't; cf RFC2633 3.1. netscape 4.7 at least can't parse encrypted stuff
## that contains a whole header again... since MIME::Tools has got no function
## for this, we need to manually extract only the MIME headers...
##	$msg_header->print(\*MSGDUMP);
##	printf MSGDUMP "\n%s", $msg_body;
	my $mime_hdr = $msg_header->dup();
	foreach my $t ($mime_hdr->tags()) {
	  $mime_hdr->delete($t) unless ($t =~ /^(mime|content)-/i);
	}
	$mime_hdr->print(\*MSGDUMP);

	printf MSGDUMP "\n%s", $msg_body;
	close(MSGDUMP);

	my $status = $?/256 ;
	unless ($status == 0) {
	    do_log('err', 'Unable to S/MIME encrypt message : %s', $openssl_errors{$status});
	    return undef ;
	}

        ## Get as MIME object
	open (NEWMSG, $temporary_file);
	my $parser = new MIME::Parser;
	$parser->output_to_core(1);
	unless ($cryptedmsg = $parser->read(\*NEWMSG)) {
	    do_log('notice', 'Unable to parse message');
	    return undef;
	}
	close NEWMSG ;

        ## Get body
	open (NEWMSG, $temporary_file);
        my $in_header = 1 ;
	while (<NEWMSG>) {
	   if ( !$in_header)  { 
	     $encrypted_body .= $_;       
	   }else {
	     $in_header = 0 if (/^$/); 
	   }
	}						    
	close NEWMSG;

unlink ($temporary_file) unless ($main::options{'debug'}) ;

	## foreach header defined in  the incomming message but undefined in the
        ## crypted message, add this header in the crypted form.
	my $predefined_headers ;
	foreach my $header ($cryptedmsg->head->tags) {
	    $predefined_headers->{$header} = 1 
	        if ($cryptedmsg->head->get($header)) ;
	}
	foreach my $header ($msg_header->tags) {
	    $cryptedmsg->head->add($header,$msg_header->get($header)) 
	        unless $predefined_headers->{$header} ;
	}

    }else{
	do_log ('notice','unable to encrypt message to %s (missing certificat %s)',$email,$usercert);
	return undef;
    }
        
    return $cryptedmsg->head->as_string . "\n" . $encrypted_body;
}

# input : msg object for a list, return a new message object decrypted
sub smime_decrypt {
    my $msg = shift;
    my $list = shift ; ## the recipient of the msg
    
    &do_log('debug2', 'tools::smime_decrypt message msg from %s,%s',$msg->head->get('from'),$list->{'name'});

    ## an empty "list" parameter means mail to sympa@, listmaster@...
    my $dir = $list->{dir};
    unless ($dir) {
	$dir = $Conf{home} . '/sympa';
    }
    my ($certs,$keys) = smime_find_keys($dir, 'decrypt');
    unless (defined $certs && @$certs) {
	do_log('err', "Unable to decrypt message : missing certificate file");
	return undef;
    }

    my $temporary_file = $Conf{'tmpdir'}."/".$list->{'name'}.".".$$ ;
    
    ## dump the incomming message.
    if (!open(MSGDUMP,"> $temporary_file")) {
	&do_log('info', 'Can\'t store message in file %s',$temporary_file);
    }
    $msg->print(\*MSGDUMP);
    close(MSGDUMP);
    
    my ($decryptedmsg, $pass_option, $msg_as_string);
    if ($Conf{'key_passwd'} ne '') {
	# if password is define in sympa.conf pass the password to OpenSSL using
	$pass_option = "-passin file:$Conf{'tmpdir'}/pass.$$";	
    }

    ## try all keys/certs until one decrypts.
    while (my $certfile = shift @$certs) {
	my $keyfile = shift @$keys;
	&do_log('debug', "Trying decrypt with $certfile, $keyfile");
	if ($Conf{'key_passwd'} ne '') {
	    unless (&POSIX::mkfifo("$Conf{'tmpdir'}/pass.$$",0600)) {
		&do_log('err', 'Unable to make fifo for %s/pass.%s',$Conf{'tmpdir'},$$);
		return undef;
	    }
	}

	&do_log('debug',"$Conf{'openssl'} smime -decrypt -in $temporary_file -recip $certfile -inkey $keyfile $pass_option");
	open (NEWMSG, "$Conf{'openssl'} smime -decrypt -in $temporary_file -recip $certfile -inkey $keyfile $pass_option |");

	if ($Conf{'key_passwd'} ne '') {
	    unless (open (FIFO,"> $Conf{'tmpdir'}/pass.$$")) {
		&do_log('notice', 'Unable to open fifo for %s/pass.%s',$Conf{'tmpdir'},$$);
		return undef;
	    }
	    print FIFO $Conf{'key_passwd'};
	    close FIFO;
	    unlink ("$Conf{'tmpdir'}/pass.$$");
	}
	
	while (<NEWMSG>) {
	    $msg_as_string .= $_;
	}
	close NEWMSG ;
	my $status = $?/256;
	
	unless ($status == 0) {
	    do_log('notice', 'Unable to decrypt S/MIME message : %s', $openssl_errors{$status});
	    next;
	}
	
	unlink ($temporary_file) unless ($main::options{'debug'}) ;
	
	my $parser = new MIME::Parser;
	$parser->output_to_core(1);
	unless ($decryptedmsg = $parser->parse_data($msg_as_string)) {
	    &do_log('notice', 'Unable to parse message');
	    last;
	}
    }
	
    ## Now remove headers from $msg_as_string
    my @msg_tab = split(/\n/, $msg_as_string);
    my $line;
    do {$line = shift(@msg_tab)} while ($line !~ /^\s*$/);
    $msg_as_string = join("\n", @msg_tab);
    
    ## foreach header defined in the incomming message but undefined in the
    ## decrypted message, add this header in the decrypted form.
    my $predefined_headers ;
    foreach my $header ($decryptedmsg->head->tags) {
	$predefined_headers->{$header} = 1 if ($decryptedmsg->head->get($header)) ;
    }
    
    foreach my $header ($msg->head->tags) {
	$decryptedmsg->head->add($header,$msg->head->get($header)) unless $predefined_headers->{$header} ;
    }
    ## Some headers from the initial message should not be restored
    ## Content-Disposition and Content-Transfer-Encoding if the result is multipart
    $decryptedmsg->head->delete('Content-Disposition') if ($msg->head->get('Content-Disposition'));
    if ($decryptedmsg->head->get('Content-Type') =~ /multipart/) {
	$decryptedmsg->head->delete('Content-Transfer-Encoding') if ($msg->head->get('Content-Transfer-Encoding'));
    }

    return ($decryptedmsg, \$msg_as_string);
}


## Make a multipart/alternative, a singlepart
sub as_singlepart {
    &do_log('debug2', 'tools::as_singlepart()');
    my ($msg, $preferred_type) = @_;
    my $done = 0;
    
    # First, if the message has a type of multipart/alternative
    # make this the main message so we can get at the sub parts
    my @parts = $msg->parts();
    foreach my $index (0..$#parts) {
        if ($parts[$index]->effective_type() =~ /^multipart\/alternative/) {
            ## Only keep the multipart/alternative part
            $msg->parts([$parts[$index]]);
            $msg->make_singlepart();
            last;
        }
    }

    # Now look for the preferred_type and if found, make this the main message
    @parts = $msg->parts();
    foreach my $index (0..$#parts) {
	if ($parts[$index]->effective_type() =~ /^$preferred_type$/) {
	    ## Only keep the first matching part
	    $msg->parts([$parts[$index]]);
	    $msg->make_singlepart();
	    $done = 1;
	    last;
	}
    }

    return $done;
}


## Escape weird characters
sub escape_chars {
    my $s = shift;    
    my $except = shift; ## Exceptions
    my $ord_except = ord($except) if (defined $except);

    ## Escape chars
    ##  !"#$%&'()+,:;<=>?[] AND accented chars
    ## escape % first
    foreach my $i (0x25,0x20..0x24,0x26..0x2c,0x3a..0x3f,0x5b,0x5d,0x80..0x9f,0xa0..0xff) {
	next if ($i == $ord_except);
	my $hex_i = sprintf "%lx", $i;
	$s =~ s/\x$hex_i/%$hex_i/g;
    }
    $s =~ s/\//%a5/g unless ($except eq '/');  ## Special traetment for '/'

    return $s;
}

## Unescape weird characters
sub unescape_chars {
    my $s = shift;

    $s =~ s/%a5/\//g;  ## Special traetment for '/'
    foreach my $i (0x20..0x2c,0x3a..0x3f,0x5b,0x5d,0x80..0x9f,0xa0..0xff) {
	my $hex_i = sprintf "%lx", $i;
	my $hex_s = sprintf "%c", $i;
	$s =~ s/%$hex_i/$hex_s/g;
    }

    return $s;
}

sub escape_html {
    my $s = shift;

    $s =~ s/\"/\&quot\;/g;
    $s =~ s/\</&lt\;/g;
    $s =~ s/\>/&gt\;/g;
    
    return $s;
}

sub tmp_passwd {
    my $email = shift;

    return ('init'.substr(Digest::MD5::md5_hex(join('/', $Conf{'cookie'}, $email)), -8)) ;
}

# Check sum used to authenticate communication from wwsympa to sympa
sub sympa_checksum {
    my $rcpt = shift;
    return (substr(Digest::MD5::md5_hex(join('/', $Conf{'cookie'}, $rcpt)), -10)) ;
}

# create a cipher
sub ciphersaber_installed {

    my $is_installed;
    foreach my $dir (@INC) {
	if (-f "$dir/Crypt/CipherSaber.pm") {
	    $is_installed = 1;
	    last;
	}
    }

    if ($is_installed) {
	require Crypt::CipherSaber;
	$cipher = Crypt::CipherSaber->new($Conf{'cookie'});
    }else{
	$cipher = 'no_cipher';
    }
}

# create a cipher
sub cookie_changed {
    my $current=shift;
    my $changed = 1 ;
    if (-f "$Conf{'etc'}/cookies.history") {
	unless (open COOK, "$Conf{'etc'}/cookies.history") {
	    do_log('err', "Unable to read $Conf{'etc'}/cookies.history") ;
	    return undef ; 
	}
	my $oldcook = <COOK>;
	close COOK;

	my @cookies = split(/\s+/,$oldcook );
	

	if ($cookies[$#cookies] eq $current) {
	    do_log('debug2', "cookie is stable") ;
	    $changed = 0;
#	}else{
#	    push @cookies, $current ;
#	    unless (open COOK, ">$Conf{'etc'}/cookies.history") {
#		do_log('err', "Unable to create $Conf{'etc'}/cookies.history") ;
#		return undef ; 
#	    }
#	    printf COOK "%s",join(" ",@cookies) ;
#	    
#	    close COOK;
	}
	return $changed ;
    }else{
	unless (open COOK, ">$Conf{'etc'}/cookies.history") {
	    do_log('err', "Unable to create $Conf{'etc'}/cookies.history") ;
	    return undef ; 
	}
	printf COOK "$current ";
	close COOK;
	return(0);
    }
}

## encrypt a password
sub crypt_password {
    my $inpasswd = shift ;

    unless (defined($cipher)){
	$cipher = ciphersaber_installed();
    }
    return $inpasswd if ($cipher eq 'no_cipher') ;
    return ("crypt.".&MIME::Base64::encode($cipher->encrypt ($inpasswd))) ;
}

## decrypt a password
sub decrypt_password {
    my $inpasswd = shift ;
    do_log('debug2', 'tools::decrypt_password (%s)', $inpasswd);

    return $inpasswd unless ($inpasswd =~ /^crypt\.(.*)$/) ;
    $inpasswd = $1;

    unless (defined($cipher)){
	$cipher = ciphersaber_installed();
    }
    if ($cipher eq 'no_cipher') {
	do_log('info','password seems crypted while CipherSaber is not installed !');
	return $inpasswd ;
    }
    return ($cipher->decrypt(&MIME::Base64::decode($inpasswd)));
}

sub load_mime_types {
    my $types = {};

    my @localisation = ('/etc/mime.types',
			'/usr/local/apache/conf/mime.types',
			'/etc/httpd/conf/mime.types','mime.types');

    foreach my $loc (@localisation) {
        next unless (-r $loc);

        unless(open (CONF, $loc)) {
            printf STDERR "load_mime_types: unable to open $loc\n";
            return undef;
        }
    }
    
    while (<CONF>) {
        next if /^\s*\#/;
        
        if (/^(\S+)\s+(.+)\s*$/i) {
            my ($k, $v) = ($1, $2);
            
            my @extensions = split / /, $v;
        
            ## provides file extention, given the content-type
            if ($#extensions >= 0) {
                $types->{$k} = $extensions[0];
            }
    
            foreach my $ext (@extensions) {
                $types->{$ext} = $k;
            }
            next;
        }
    }
    
    close FILE;
    return $types;
}

sub split_mail {
    my $message = shift ; 
    my $pathname = shift ;
    my $dir = shift ;

    my $head = $message->head ;
    my $body = $message->body ;
    my $encoding = $head->mime_encoding ;

    if ($message->is_multipart
	|| ($message->mime_type eq 'message/rfc822')) {

        for (my $i=0 ; $i < $message->parts ; $i++) {
            &split_mail ($message->parts ($i), $pathname.'.'.$i, $dir) ;
        }
    }
    else { 
	    my $fileExt ;

	    if ($head->mime_attr("content_type.name") =~ /\.(\w+)\s*\"*$/) {
		$fileExt = $1 ;
	    }
	    elsif ($head->recommended_filename =~ /\.(\w+)\s*\"*$/) {
		$fileExt = $1 ;
	    }
	    else {
		my $mime_types = &load_mime_types();

		$fileExt=$mime_types->{$head->mime_type};
		my $var=$head->mime_type;
	    }
	
	    

	    ## Store body in file 
	    unless (open OFILE, ">$dir/$pathname.$fileExt") {
		&do_log('err', "Unable to create $dir/$pathname.$fileExt : $!") ;
		return undef ; 
	    }
	    
	    if ($encoding =~ /^(binary|7bit|8bit|base64|quoted-printable|x-uu|x-uuencode|x-gzip64)$/ ) {
		open TMP, ">$dir/$pathname.$fileExt.$encoding";
		$message->print_body (\*TMP);
		close TMP;

		open BODY, "$dir/$pathname.$fileExt.$encoding";

		my $decoder = new MIME::Decoder $encoding;
		unless (defined $decoder) {
		    &do_log('err', 'Cannot create decoder for %s', $encoding);
		    return undef;
		}
		$decoder->decode(\*BODY, \*OFILE);
		close BODY;
		unlink "$dir/$pathname.$fileExt.$encoding";
	    }else {
		$message->print_body (\*OFILE) ;
	    }
	    close (OFILE);
	    printf "\t-------\t Create file %s\n", $pathname.'.'.$fileExt ;
	    
	    ## Delete files created twice or more (with Content-Type.name and Content-Disposition.filename)
	    $message->purge ;	
    }
    
    return 1;
}

sub virus_infected {
    my $mail = shift ;
    my $file = shift ;

    &do_log('debug2', 'Scan virus in %s', $file);
    
    unless ($Conf{'antivirus_path'} ) {
        &do_log('debug', 'Sympa not configured to scan virus in message');
	return 0;
    }
    my @name = split(/\//,$file);
    my $work_dir = $Conf{'tmpdir'}.'/antivirus';
    
    unless ((-d $work_dir) ||( mkdir $work_dir, 0755)) {
	do_log('err', "Unable to create tmp antivirus directory $work_dir");
	return undef;
    }

    $work_dir = $Conf{'tmpdir'}.'/antivirus/'.$name[$#name];
    
    unless ( mkdir ($work_dir, 0755)) {
	do_log('err', "Unable to create tmp antivirus directory $work_dir");
	return undef;
    }

    #$mail->dump_skeleton;

    ## Call the procedure of spliting mail
    unless (&split_mail ($mail,'msg', $work_dir)) {
	&do_log('err', 'Could not split mail %s', $mail);
	return undef;
    }

    my $virusfound; 
    my $error_msg;
    my $result;

    ## McAfee
    if ($Conf{'antivirus_path'} =~  /\/uvscan$/) {

	# impossible to look for viruses with no option set
	unless ($Conf{'antivirus_args'}) {
	    &do_log('err', "Missing 'antivirus_args' in sympa.conf");
	    return undef;
	}
    
	open (ANTIVIR,"$Conf{'antivirus_path'} $Conf{'antivirus_args'} $work_dir |") ; 
		
	while (<ANTIVIR>) {
	    $result .= $_; chomp $result;
	    if ((/^\s*Found the\s+(.*)\s*virus.*$/i) ||
		(/^\s*Found application\s+(.*)\.\s*$/i)){
		$virusfound = $1;
	    }
	}
	close ANTIVIR;
    
	my $status = $?/256 ;

        ## uvscan status =13 (*256) => virus
        if (( $status == 13) and not($virusfound)) { 
	    $virusfound = "unknown";
	}

	$error_msg = $result
	    if ($status != 0 && $status != 13);

    ## Trend Micro
    }elsif ($Conf{'antivirus_path'} =~  /\/vscan$/) {

	open (ANTIVIR,"$Conf{'antivirus_path'} $Conf{'antivirus_args'} $work_dir |") ; 
		
	while (<ANTIVIR>) {
	    if (/Found virus (\S+) /i){
		$virusfound = $1;
	    }
	}
	close ANTIVIR;
    
	my $status = $?/256 ;

        ## uvscan status = 1 | 2 (*256) => virus
        if ((( $status == 1) or ( $status == 2)) and not($virusfound)) { 
	    $virusfound = "unknown";
	}

    ## F-Secure
    } elsif($Conf{'antivirus_path'} =~  /\/fsav$/) {
	$dbdir=$` ;

	# impossible to look for viruses with no option set
	unless ($Conf{'antivirus_args'}) {
	    &do_log('err', "Missing 'antivirus_args' in sympa.conf");
	    return undef;
	}

	open (ANTIVIR,"$Conf{'antivirus_path'} --databasedirectory $dbdir $Conf{'antivirus_args'} $work_dir |") ;

	while (<ANTIVIR>) {

	    if (/infection:\s+(.*)/){
		$virusfound = $1;
	    }
	}
	
	close ANTIVIR;
    
	my $status = $?/256 ;

        ## fsecure status =3 (*256) => virus
        if (( $status == 3) and not($virusfound)) { 
	    $virusfound = "unknown";
	}    
    }elsif($Conf{'antivirus_path'} =~ /f-prot\.sh$/) {

        &do_log('debug2', 'f-prot is running');    

        open (ANTIVIR,"$Conf{'antivirus_path'} $Conf{'antivirus_args'} $work_dir |") ;
        
        while (<ANTIVIR>) {
        
            if (/Infection:\s+(.*)/){
                $virusfound = $1;
            }
        }
        
        close ANTIVIR;
        
        my $status = $?/256 ;
        
        &do_log('debug2', 'Status: '.$status);    
        
        ## f-prot status =3 (*256) => virus
        if (( $status == 3) and not($virusfound)) { 
            $virusfound = "unknown";
        }    
    }elsif ("${Conf{'antivirus_path'}}" =~ /kavscanner/) {

	# impossible to look for viruses with no option set
	unless ($Conf{'antivirus_args'}) {
	    &do_log('err', "Missing 'antivirus_args' in sympa.conf");
	    return undef;
	}
    
	open (ANTIVIR,"$Conf{'antivirus_path'} $Conf{'antivirus_args'} $work_dir |") ; 
		
	while (<ANTIVIR>) {
	    if (/infected:\s+(.*)/){
		$virusfound = $1;
	    }
	    elsif (/suspicion:\s+(.*)/i){
		$virusfound = $1;
	    }
	}
	close ANTIVIR;
    
	my $status = $?/256 ;

        ## uvscan status =3 (*256) => virus
        if (( $status >= 3) and not($virusfound)) { 
	    $virusfound = "unknown";
	}

        ## Sophos Antivirus... by liuk@publinet.it
    }elsif ("${Conf{'antivirus_path'}}" =~ /\/sweep$/) {
	
        # impossible to look for viruses with no option set
	unless ($Conf{'antivirus_args'}) {
	    &do_log('err', "Missing 'antivirus_args' in sympa.conf");
	    return undef;
	}
    
        open (ANTIVIR,"$Conf{'antivirus_path'} $Conf{'antivirus_args'} $work_dir |") ;
	
	while (<ANTIVIR>) {
	    if (/Virus\s+(.*)/) {
		$virusfound = $1;
	    }
	}       
	close ANTIVIR;
        
	my $status = $?/256 ;
        
	## sweep status =3 (*256) => virus
	if (( $status == 3) and not($virusfound)) {
	    $virusfound = "unknown";
	}

	## Clam antivirus
    }elsif ("${Conf{'antivirus_path'}}" =~ /\/clamscan$/) {
	
        open (ANTIVIR,"$Conf{'antivirus_path'} $Conf{'antivirus_args'} $work_dir |") ;
	
	while (<ANTIVIR>) {
	    if (/^\S+:\s(.*)\sFOUND$/) {
		$virusfound = $1;
	    }
	}       
	close ANTIVIR;
        
	my $status = $?/256 ;
        
	## Clamscan status =1 (*256) => virus
	if (( $status == 1) and not($virusfound)) {
	    $virusfound = "unknown";
	}
    }         

    ## Error while running antivir, notify listmaster
    if ($error_msg) {
	&List::send_notify_to_listmaster('virus_scan_failed', $Conf{'domain'}, ($file,$error_msg));
    }

    ## if debug mode is active, the working directory is kept
    unless ($main::options{'debug'}) {
	opendir (DIR, ${work_dir});
	my @list = readdir(DIR);
	closedir (DIR);
        foreach (@list) {
	    my $nbre = unlink ("$work_dir/$_")  ;
	}
	rmdir ($work_dir) ;
    }
   
    return ($virusfound);
   
}

## subroutines for epoch and human format date processings


## convert an epoch date into a readable date scalar
sub adate {

    my $epoch = $_[0];
    my @date = localtime ($epoch);
    my $date = POSIX::strftime ("%e %a %b %Y  %H h %M min %S s", @date);
    
    return $date;
}

## human format (used in task models and scenarii)

# -> absolute date :
#  xxxxYxxMxxDxxHxxMin
# Y year ; M : month (1-12) ; D : day (1-28|29|30|31) ; H : hour (0-23) ; Min : minutes (0-59)
# H and Min parameters are optionnal
# ex 2001y9m13d14h10min

# -> duration :
# +|- xxYxxMxxWxxDxxHxxMin
# W week, others are the same
# all parameters are optionnals
# before the duration you may write an absolute date, an epoch date or the keyword 'execution_date' which refers to the epoch date when the subroutine is executed. If you put nothing, the execution_date is used


## convert a human format date into an epoch date
sub epoch_conv {

    my $arg = $_[0]; # argument date to convert
    my $time = $_[1] || time; # the epoch current date

    &do_log('debug4','tools::epoch_conv(%s, %d)', $arg, $time);

    my $result;
    
     # decomposition of the argument date
    my $date;
    my $duration;
    my $op;

    if ($arg =~ /^(.+)(\+|\-)(.+)$/) {
	$date = $1;
	$duration = $3;
	$op = $2;
    } else {
	$date = $arg;
	$duration = '';
	$op = '+';
	}

     #conversion
    $date = date_conv ($date, $time);
    $duration = duration_conv ($duration, $date);

    if ($op eq '+') {$result = $date + $duration;}
    else {$result = $date - $duration;}

    return $result;
}

sub date_conv {
   
    my $arg = $_[0];
    my $time = $_[1];

    if ( ($arg eq 'execution_date') ){ # execution date
	return time;
    }

    if ($arg =~ /^\d+$/) { # already an epoch date
	return $arg;
    }
	
    if ($arg =~ /^(\d\d\d\dy)(\d+m)?(\d+d)?(\d+h)?(\d+min)?(\d+sec)?$/) { # absolute date

	my @date = ("$6", "$5", "$4", "$3", "$2", "$1");
	for (my $i = 0; $i < 6; $i++) {
	    chop ($date[$i]);
	    if (($i == 1) || ($i== 2)) {chop ($date[$i]); chop ($date[$i]);}
	    $date[$i] = 0 unless ($date[$i]);
	}
	$date[3] = 1 if ($date[3] == 0);
	$date[4]-- if ($date[4] != 0);
	$date[5] -= 1900;
	
	return timelocal (@date);
    }
    
    return time;
}

sub duration_conv {
    
    my $arg = $_[0];
    my $start_date = $_[1];

    return 0 unless $arg;
  
    $arg =~ /(\d+y)?(\d+m)?(\d+w)?(\d+d)?(\d+h)?(\d+min)?(\d+sec)?$/i ;
    my @date = ("$1", "$2", "$3", "$4", "$5", "$6", "$7");
    for (my $i = 0; $i < 7; $i++) {
	chop ($date[$i]);
	if (($i == 5) || ($i == 6)) {chop ($date[$i]); chop ($date[$i]);}
	$date[$i] = 0 unless ($date[$i]);
    }
    
    my $duration = $date[6]+60*($date[5]+60*($date[4]+24*($date[3]+7*$date[2]+365*$date[0])));
	
    # specific processing for the months because their duration varies
    my @months = (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31,
		  31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);
    my $start  = (localtime ($start_date))[4];
    for (my $i = 0; $i < $date[1]; $i++) {
	$duration += $months[$start + $i] * 60 * 60 * 24;
    }
	
    return $duration;
}

## Look for a file in the list > robot > server > default locations
sub get_filename {
    my ($type, $name, $robot, $list) = @_;
    &do_log('debug3','tools::get_filename(%s,%s,%s,%s)', $type, $name, $robot, $list->{'name'});

    if ($type eq 'etc') {
	my (@try, $default_name);
	
	## template refers to a language
	## => extend search to default tpls
	if ($name =~ /^(\S+)\.([^\s\/]+)\.tt2$/) {
	    $default_name = $1.'.tt2';
	    
	    @try = ("$Conf{'etc'}/$robot".'/'.$name,
		    "$Conf{'etc'}/$robot".'/'.$default_name,
		    $Conf{'etc'}.'/'.$name,
		    $Conf{'etc'}.'/'.$default_name,
		    '--ETCBINDIR--'.'/'.$name,
		    '--ETCBINDIR--'.'/'.$default_name);
	}else {
	    @try = ("$Conf{'etc'}/$robot".'/'.$name,
		    $Conf{'etc'}.'/'.$name,
		    '--ETCBINDIR--'.'/'.$name);
	}
	if ($list->{'name'}) {
	    ## Default tpl
	    if ($default_name) {
		unshift @try, $list->{'dir'}.'/'.$default_name;
	    }
	    
	    unshift @try, $list->{'dir'}.'/'.$name;
	}
	foreach my $f (@try) {
	    &do_log('debug3','get_filname : NAME: %s ; DIR %s', $name, $f  );
	    if (-r $f) {
		return $f;
	    }
	}
    }
    
    &do_log('debug3','tools::get_filename: Cannot find %s', $name);
    return undef;
}

sub write_pid {
    my ($pidfile, $pid) = @_;

    my $uid = (getpwnam('--USER--'))[2];
    my $gid = (getgrnam('--GROUP--'))[2];

    my $piddir = $pidfile;
    $piddir =~ s/\/[^\/]+$//;

    ## Create piddir
    unless (-d $piddir) {
	mkdir $piddir, 0755;
    }
    
    chown $uid, $gid, $piddir;

    ## Create and write the pidfile
    unless (open(LOCK, "+>> $pidfile")) {
	 fatal_err("Could not open %s, exiting", $pidfile);
    } 
    unless (flock(LOCK, 6)) {
	fatal_err("Could not lock %s, process is probably already running : %s", $pidfile, $!);
    }
    unless (open(LCK, "> $pidfile")) {
	fatal_err("Could not open %s, exiting", $pidfile);
    }
    unless (truncate(LCK, 0)) {
	fatal_err("Could not truncate %s, exiting.", $pidfile);
    }
    
    print LCK "$pid\n";
    close(LCK);
    
    chown $uid, $gid, $pidfile;

    return 1;
}

sub get_message_id {
    my $robot = shift;

    my $id = sprintf '<sympa.%d.%d.%d@%s>', time, $$, int(rand(999)), $robot;

    return $id;
}


sub get_dir_size {
    my $dir =shift;
    
    my $size=0;

    if (opendir(DIR, $dir)) {
	foreach my $file ( sort grep (!/^\./,readdir(DIR))) {
	    if (-d "$dir/$file") {
		$size += get_dir_size("$dir/$file");
	    }
	    else{
		my @info = stat "$dir/$file" ;
		$size += $info[7];
	    }
	}
        closedir DIR;
    }

    return $size;
}

## Basic check of an email address
sub valid_email {
    my $email = shift;
    
    $email =~ /^$tools::regexp{'email'}$/;
}

## Clean email address
sub clean_email {
    my $email = shift;

    ## Lower-case
    $email = lc($email);

    ## remove leading and trailing spaces
    $email =~ s/^\s*//;
    $email =~ s/\s*$//;

    return $email;
}

## Function for Removing a non-empty directory
## It takes a variale number of arguments : 
## it can be a list of directory
## or few direcoty paths
sub remove_dir {
    
    do_log('info','remove_dir()');
    
    foreach my $current_dir (@_){

	finddepth(\&del,$current_dir);
    }
    sub del {
	my $name = $File::Find::name;

	if (!-l && -d _) {
	    &do_log('info','removing dir %s',$name);
	    unless (rmdir($name)) {
		&do_log('info','Error while removing dir %s',$name);
	    }
	}else{
	    unless (unlink($name)) {
		&do_log('info','Error while removing file  %s',$name);
	    }
	}
    }
    return 1;
}

## Return canonical email address (lower-cased + space cleanup)
## It could also support alternate email
sub get_canonical_email {
    my $email = shift;

    ## Remove leading and trailing white spaces
    $email =~ s/^\s*(\S.*\S)\s*$/$1/;

    ## Lower-case
    $email = lc($email);

    return $email;
}

## Function for Removing a non-empty directory
## It takes a variale number of arguments : 
## it can be a list of directory
## or few direcoty paths
sub remove_dir {
    
    do_log('info','remove_dir()');
    
    foreach my $current_dir (@_){
	my @tree = split /\//, $current_dir ;
	if ($#tree < 4) {
	    do_log('info',"$current_dir not removed (not enough / in directory name)");
	    next;
	}
	finddepth({wanted => \&del, no_chdir => 1},$current_dir);
    }
    sub del {
	my $name = $File::Find::name;

	if (!-l && -d _) {
	    &do_log('info','removing dir %s',$name);
	    unless (rmdir($name)) {
		&do_log('info','Error while removing dir %s',$name);
	    }
	}else{
	    unless (unlink($name)) {
		&do_log('info','Error while removing file  %s',$name);
	    }
	}
    }
    return 1;
}

## Return canonical email address (lower-cased + space cleanup)
## It could also support alternate email
sub get_canonical_email {
    my $email = shift;

    ## Remove leading and trailing white spaces
    $email =~ s/^\s*(\S.*\S)\s*$/$1/;

    ## Lower-case
    $email = lc($email);

    return $email;
}

## find the appropriate S/MIME keys/certs for $oper in $dir.
## $oper can be:
## 'sign' -> return the preferred signing key/cert
## 'decrypt' -> return a list of possible decryption keys/certs
## 'encrypt' -> return the preferred encryption key/cert
## returns ($certs, $keys)
## for 'sign' and 'encrypt', these are strings containing the absolute filename
## for 'decrypt', these are arrayrefs containing absolute filenames
sub smime_find_keys {
    my($dir, $oper) = @_;
    &do_log('debug', 'tools::smime_find_keys(%s, %s)', $dir, $oper);

    my(%certs, %keys);
    my $ext = ($oper eq 'sign' ? 'sign' : 'enc');

    unless (opendir(D, $dir)) {
	do_log('err', "unable to opendir $dir: $!");
	return undef;
    }

    while (my $fn = readdir(D)) {
	if ($fn =~ /^cert\.pem/) {
	    $certs{"$dir/$fn"} = 1;
	}elsif ($fn =~ /^private_key/) {
	    $keys{"$dir/$fn"} = 1;
	}
    }
    closedir(D);

    foreach my $c (keys %certs) {
	my $k = $c;
	$k =~ s/\/cert\.pem/\/private_key/;
	unless ($keys{$k}) {
	    do_log('notice', "$c exists, but matching $k doesn't");
	    delete $certs{$c};
	}
    }

    foreach my $k (keys %keys) {
	my $c = $k;
	$c =~ s/\/private_key/\/cert\.pem/;
	unless ($certs{$c}) {
	    do_log('notice', "$k exists, but matching $c doesn't");
	    delete $keys{$k};
	}
    }

    my ($certs, $keys);
    if ($oper eq 'decrypt') {
	$certs = [ sort keys %certs ];
	$keys = [ sort keys %keys ];
    }else {
	if($certs{"$dir/cert.pem.$ext"}) {
	    $certs = "$dir/cert.pem.$ext";
	    $keys = "$dir/private_key.$ext";
	} elsif($certs{"$dir/cert.pem"}) {
	    $certs = "$dir/cert.pem";
	    $keys = "$dir/private_key";
	} else {
	    do_log('info', "$dir: no certs/keys found for $oper");
	    return undef;
	}
    }

    return ($certs,$keys);
}

# IN: hashref:
# file => filename
# text => PEM-encoded cert
# OUT: hashref
# email => email address from cert
# subject => distinguished name
# purpose => hashref
#  enc => true if v3 purpose is encryption
#  sign => true if v3 purpose is signing
sub smime_parse_cert {
    my($arg) = @_;
    &do_log('debug', 'tools::smime_parse_cert(%s)', join('/',%{$arg}));

    unless (ref($arg)) {
	&do_log('err', "smime_parse_cert: must be called with hashref, not %s", ref($arg));
	return undef;
    }

    ## Load certificate
    my @cert;
    if($arg->{'text'}) {
	@cert = ($arg->{'text'});
    }elsif ($arg->{file}) {
	unless (open(PSC, "$arg->{file}")) {
	    &do_log('err', "smime_parse_cert: open $file: $!");
	    return undef;
	}
	@cert = <PSC>;
	close(PSC);
    }else {
	&do_log('err', 'smime_parse_cert: neither "text" nor "file" given');
	return undef;
    }

    ## Extract information from cert
    my ($tmpfile) = $Conf{'tmpdir'}."/parse_cert.$$";
    unless (open(PSC, "| $Conf{openssl} x509 -email -subject -purpose -noout > $tmpfile")) {
	&do_log('err', "smime_parse_cert: open |openssl: $!");
	return undef;
    }
    print PSC join('', @cert);

    unless (close(PSC)) {
	&do_log('err', "smime_parse_cert: close openssl: $!, $@");
	return undef;
    }

    unless (open(PSC, "$tmpfile")) {
	&do_log('err', "smime_parse_cert: open $tmpfile: $!");
	return undef;
    }

    my @output = <PSC>;
    my %res;

    $res{'email'} = lc($output[0]);
    chomp $res{'email'};

    if ($output[1] =~ /^subject=\s+(\S.+)\s*$/) {
	$res{'subject'} = $1;
    }

    if ($output[2] =~ /^Certificate purposes:/) {
	foreach my $i (3..$#output) {
	    $_ = $output[$i];
	    
	    if (/^S\/MIME signing : (\S+)/) {
		$res{purpose}->{sign} = ($1 eq 'Yes');
	    }elsif (/^S\/MIME encryption : (\S+)/) {
		$res{purpose}->{enc} = ($1 eq 'Yes');
	    }
	}
    }
    
    ## OK, so there's CAs which put the email in the subjectAlternateName only
    ## and ones that put it in the DN only...
    if(!$res{email} && ($res{subject} =~ /\/email(address)?=([^\/]+)/)) {
	$res{email} = $1;
    }
    close(PSC);
    unlink($tmpfile);
    return \%res;
}

sub smime_extract_certs {
    my($mime, $outfile) = @_;
    &do_log('debug2', "tools::smime_extract_certs(%s)",$mime->mime_type);

    if ($mime->mime_type =~ /application\/(x-)?pkcs7-/) {
	unless (open(MSGDUMP, "| $Conf{openssl} pkcs7 -print_certs ".
		     "-inform der > $outfile")) {
	    &do_log('err', "unable to run openssl pkcs7: $!");
	    return 0;
	}
	print MSGDUMP $mime->bodyhandle->as_string;
	close(MSGDUMP);
	if ($?) {
	    &do_log('err', "openssl pkcs7 returned an error: ", $?/256);
	    return 0;
	}
	return 1;
    }
}

## Dump a variable's content
sub dump_var {
    my ($var, $level, $fd) = @_;
    
    if (ref($var)) {
	if (ref($var) eq 'ARRAY') {
	    foreach my $index (0..$#{$var}) {
		print $fd "\t"x$level.$index."\n";
		&dump_var($var->[$index], $level+1, $fd);
	    }
	}elsif (ref($var) eq 'HASH') {
	    foreach my $key (sort keys %{$var}) {
		print $fd "\t"x$level.'_'.$key.'_'."\n";
		&dump_var($var->{$key}, $level+1, $fd);
	    }    
	}
    }else {
	if (defined $var) {
	    print $fd "\t"x$level."'$var'"."\n";
	}else {
	    print $fd "\t"x$level."UNDEF\n";
	}
    }
}

## Change X-Sympa-To: header field in the message
sub change_x_sympa_to {
    my ($file, $value) = @_;
    
    ## Change X-Sympa-To
    unless (open FILE, $file) {
	&wwslog('err', "Unable to open '%s' : %s", $file, $!);
	next;
    }	 
    my @content = <FILE>;
    close FILE;
    
    unless (open FILE, ">$file") {
	&wwslog('err', "Unable to open '%s' : %s", "$file", $!);
	next;
    }	 
    foreach (@content) {
	if (/^X-Sympa-To:/i) {
	    $_ = "X-Sympa-To: $value\n";
	}
	print FILE;
    }
    close FILE;
    
    return 1;
}

## Compare 2 versions of Sympa
sub higher_version {
    my ($v1, $v2) = @_;

    my @tab1 = split /\./,$v1;
    my @tab2 = split /\./,$v2;
    
    
    my $max = $#tab1;
    $max = $#tab2 if ($#tab2 > $#tab1);

    for $i (0..$max) {
    
        if ($tab1[0] =~ /^(\d*)a$/) {
            $tab1[0] = $1 - 0.5;
        }elsif ($tab1[0] =~ /^(\d*)b$/) {
            $tab1[0] = $1 - 0.25;
        }

        if ($tab2[0] =~ /^(\d*)a$/) {
            $tab2[0] = $1 - 0.5;
        }elsif ($tab2[0] =~ /^(\d*)b$/) {
            $tab2[0] = $1 - 0.25;
        }

        if ($tab1[0] eq $tab2[0]) {
            #printf "\t%s = %s\n",$tab1[0],$tab2[0];
            shift @tab1;
            shift @tab2;
            next;
        }
        return ($tab1[0] > $tab2[0]);
    }

    return 0;
}

sub LOCK_SH {1};
sub LOCK_EX {2};
sub LOCK_NB {4};
sub LOCK_UN {8};



## lock a file 
sub lock {
    my $lock_file = shift;
    my $mode = shift; ## read or write
    
    my $operation;
    my $open_mode;

    if ($mode eq 'read') {
	$operation = LOCK_SH;
    }else {
	$operation = LOCK_EX;
	$open_mode = '>>';
    }
    
    ## Read access to prevent "Bad file number" error on Solaris
    unless (open FH, $open_mode.$lock_file) {
	&do_log('err', 'Cannot open %s: %s', $lock_file, $!);
	return undef;
    }
    
    my $got_lock = 1;
    unless (flock (FH, $operation | LOCK_NB)) {
	&do_log('notice','Waiting for %s lock on %s', $mode, $lock_file);
	$got_lock = undef;
	for (my $i = 1; $i < 10; $i++) {
	    sleep (10 * $i);
	    if (flock (FH, $operation | LOCK_NB)) {
		$got_lock = 1;
		last;
	    }
	    &do_log('notice','Waiting for %s lock on %s', $mode, $lock_file);
	}
    }
	
    if ($got_lock) {
	&do_log('debug2', 'Got lock for %s on %s', $mode, $lock_file);
    }else {
	&do_log('err', 'Failed locking %s: %s', $lock_file, $!);
	return undef;
    }

    return \*FH;
}

## unlock a file 
sub unlock {
    my $lock_file = shift;
    my $fh = shift;
    
    unless (flock($fh,LOCK_UN)) {
	&do_log('err', 'Failed UNlocking %s: %s', $lock_file, $!);
	return undef;
    }
    close $fh;
    &do_log('debug2', 'Release lock on %s', $lock_file);
    
    return 1;
}

1;

