## This module is part of ML and provides some tools

package tools;

use POSIX;
use Mail::Internet;
use Mail::Header;
use Conf;
use Language;
use Log;
use Time::Local;

## RCS identification.
#my $id = '@(#)$Id$';

## global var to store a CipherSaber object 
my $cipher;

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
## Do 3 trials and wait 10 seconds between each.
## Exit with a fatal error is fork failed after all
## tests have been exhausted.
sub safefork {
   my($i, $pid);
   
   for ($i = 1; $i < 360; $i++) {
      my($pid) = fork;
      return $pid if (defined($pid));
      do_log ('warning', "Can't create new process in safefork: %m");
      ## should send a mail to the listmaster
      sleep(10 * $i);
   }
   fatal_err("Can't create new process in safefork: %m");
   ## No return.
}

@avoid_hdr = (
        'help',
        'ind(ex)?',
        'lists?',
        '(please\s+)?(add|unsub?(scribe)?|remove|del|sub\s|sub?s?cribe|sign?o?f?f?)',
        'rev(iew)?\s+\S+',
        'stats\s+\S+',
        'get\s+\S+\s+\S+',
        'set\s+\S+\s+(no)?(mail|conceal|digest)',
        'purge\s+\S+\s+\S+',
        'exp(ire)?\s+\S+\s+\S+\s+\S+',
        'exp(ire)?del\s+\S+',
        'exp(ire)?ind(ex)?\s+\S+',
        'ind(ex)?exp(ire)?\s+\S+',
        'mod(eration)?ind(ex)?\s+\S+',
        'ind(ex)?mod(eration)?\s+\S+',
	'rev(iew)?\s+\S+',
        'dis(tribute)?\s+\S+\s+\S+',
        'rej(ect)?\s+\S+\s+\S+',
        '(re)?con(firm)?\s+\S+',
	'rev(iew)?\s+\S+',
);

## Check for commands in the body of the message. Returns true
## if there are some commands in it.
sub checkcommand {
   my($msg, $sender) = @_;
   do_log('debug2', 'tools::checkcommand(msg->head->get(subject): %s,%s)',$msg->head->get('Subject'), $sender);

   my($avoid, $i);

   my $hdr = $msg->head;

   ## Check for commands in the subject.
   my $subject = $msg->head->get('Subject');
   if ($subject) {
      foreach $avoid (@avoid_hdr) {
         if ($subject =~ /^\s*(quiet)?($avoid)(\s+|$)/im) {
            &rejectMessage($msg, $sender);
            return 1;
         }
      }
   }

   return 0 if ($#{$msg->body} >= 15);  ## More than 15 lines in the text.

   foreach $i (@{$msg->body}) {
      foreach $avoid (@avoid_hdr) {
         if ($i =~ /^\s*(quiet)?($avoid)(\s+|$)/im) {  ## Suspicious line
            &rejectMessage($msg, $sender);
            return 1;
         }
      }
      ## Control is only applied to first non-blank line
      last unless $i =~ /^\s*$/;
      
   }
   return 0;
}

sub rejectMessage {
   my($msg, $sender) = @_;
   do_log('debug2', 'tools::rejectMessage(%s)', $sender);

   *REJ = smtp::smtpto($Conf{'request'}, \$sender);
   print REJ "To: $sender\n";
   print REJ "Subject: [sympa] " . Msg(5, 2, "Misadressed message ?") . "\n";
   printf REJ "MIME-Version: %s\n", Msg(12, 1, '1.0');
   printf REJ "Content-Type: text/plain; charset=%s\n", Msg(12, 2, 'us-ascii');
   printf REJ "Content-Transfer-Encoding: %s\n", Msg(12, 3, '7bit');
   print REJ "\n";
   printf REJ Msg(5, 3, "\
Your message has been sent to a list but it seems it contains commands like
subscribe, signoff, help, index, get, ...

If your message did really contain a command, please note that such messages
must be sent to %s only.

If it happens that your message was by mistake considered as containing
commands, then please contact the manager of this service %s
so that he can take care of your problem.

Thank you for your attention.

------ Beginning of the suspect message --------
"), "$Conf{'sympa'}", $Conf{'request'};
   $msg->print(\*REJ);
   print REJ Msg(5, 4, "------- Fin message suspect ---------\n");
   close(REJ);
}

## return a hash from the edit_list_conf file
sub load_edit_list_conf {
    my $robot = shift;

    my $file;
    my $conf ;
    
    return undef 
	unless ($file = &tools::get_filename('etc','edit_list.conf',$robot));

    unless (open (FILE, $file)) {
	&do_log('info','Unable to open config file %s', $file);
	return undef;
    }

    $roles_regexp = 'listmaster|privileged_owner|owner|editor|subscriber|default';
    while (<FILE>) {
	next if /^\s*(\#.*|\s*)$/;

	if (/^\s*(\S+)\s+(($roles_regexp)\s*(,\s*($roles_regexp))*)\s+(read|write|hidden)\s*$/i) {
	    my ($param, $role, $priv) = ($1, $2, $6);
	    my @roles = split /,/, $role;
	    foreach my $r (@roles) {
		$r =~ s/^\s*(\S+)\s*$/$1/;
		if ($r eq 'default') {
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

    foreach my $dir ('--ETCBINDIR--/create_list_templates', "$Conf{'etc'}/create_list_templates") {
	if (opendir(DIR, $dir)) {
	    foreach my $template ( sort grep (!/^\./,readdir(DIR))) {

		my $status = $list_conf->{$template} || $list_conf->{'default'};

		next if ($status eq 'hidden') ;

		$list_templates->{$template}{'path'} = $dir;

		if (-r $dir.'/'.$template.'/comment') {
		    $list_templates->{$template}{'comment'} = $dir.'/'.$template.'/comment';
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

    my $cert = "$Conf{'home'}/$list/cert.pem";
    my $key = "$Conf{'home'}/$list/private_key";
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

     &do_log('debug2', "$Conf{'openssl'} smime -sign -signer $cert $pass_option -inkey $key -in $temporary_file");
     unless (open (NEWMSG,"$Conf{'openssl'} smime -sign -signer $cert $pass_option -inkey $key -in $temporary_file 2>&1 |")) {
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

    unlink ($temporary_file) unless ($main::options{'debug'} || $main::options{'debug2'}) ;
    
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

    my $msg = shift;
    my $sender = shift;
    my $file = shift;
    $sender= lc($sender);

    do_log('debug2', 'tools::smime_sign_check (message, %s, %s)', $sender, $file);

    my $is_signed = {};
    $is_signed->{'body'} = undef;   
    $is_signed->{'subject'} = undef;

    my $verify ;

    ## first step is the msg signing OK ; /tmp/sympa-smime.$$ is created
    ## to store the signer certificat for step two. I known, that's durty.



    my $temporary_file = "/tmp/smime-sender.".$$ ; 
    do_log('debug2', "xxx $Conf{'openssl'} smime -verify  $Conf{'trusted_ca_options'} -signer  $temporary_file");
    unless (open (MSGDUMP, "| $Conf{'openssl'} smime -verify  $Conf{'trusted_ca_options'} -signer $temporary_file > /dev/null")) {

	do_log('err', "unable to verify smime signature from $sender $verify");
	return undef ;
    }

#    unless (open MSG, $file) {
#	do_log('err', 'Unable to open file %s: %s', $file, $!);
#	return undef;
#    }

    $msg->print(\*MSGDUMP);
    close MSGDUMP; close MSG;
    
    ## second step is the message signer match the sender
    ## a better analyse should be performed to extract the signer email. 
    my $signer = `cat $temporary_file | $Conf{'openssl'}  x509 -subject -noout`;


    if ($signer =~ /email=$sender/i) {
	do_log('debug', "S/MIME signed message, signature checked and sender match signer(%s)",$signer);
        ## store the signer certificat
	unless (-d $Conf{'ssl_cert_dir'}) {
	    if ( mkdir ($Conf{'ssl_cert_dir'}, 0775)) {
		do_log('info', "creating spool $Conf{'ssl_cert_dir'}");
	    }else{
		do_log('err', "Unable to create user certificat directory $Conf{'ssl_cert_dir'}");
	    }
	}
	my $filename = "$Conf{'ssl_cert_dir'}/".&escape_chars($sender);

	open (CERTIF,$temporary_file);
	if (open (USERCERTIF, "> $filename")) {
	    print USERCERTIF <CERTIF> ;
	    close USERCERTIF ;
	}else{
	    &do_log('err','Unable to rename %s %s',$temporary_file,$filename);
	}
	close CERTIF;
	unlink($temporary_file) unless ($main::options{'debug'} || $main::options{'debug2'}) ;	

	$is_signed->{'body'} = 'smime';

	# futur version should check if the subject was part of the SMIME signature.
	$is_signed->{'subject'} = undef;
	return $is_signed;
    }else{
	unlink($temporary_file) unless ($main::options{'debug'} || $main::options{'debug2'}) ;	
	do_log('notice', "S/MIME signed message, sender($sender) do NOT match signer($signer)",$sender,$signer);
	return undef;
    }
    return undef ;    
}

# input : msg object, return a new message object encrypted
sub smime_encrypt {
    my $msg_header = shift;
    my $msg_body = shift;
    my $email = shift ;
    my $list = shift ;

    my $usercert;
    my $cryptedmsg;
    my $encrypted_body;    

    &do_log('debug2', 'tools::smime_encrypt(%s, %s, %s, %s',$msg_header, $msg_body, $email, $list);
    if ($list eq 'list') {
	$usercert = "$Conf{'home'}/$email/cert.pem";
    }else{
	$usercert = "$Conf{'ssl_cert_dir'}/".&tools::escape_chars($email);
    }
    if (-r $usercert) {
	my $temporary_file = $Conf{'tmpdir'}."/".$email.".".$$ ;

	## encrypt the incomming message parse it.
        do_log ('debug2', "xxxx $Conf{'openssl'} smime -encrypt -out $temporary_file -des3 $usercert");
	if (!open(MSGDUMP, "| $Conf{'openssl'} smime -encrypt -out $temporary_file -des3 $usercert")) {
	    &do_log('info', 'Can\'t encrypt message for recipient %s', $email);
	}
	$msg_header->print(\*MSGDUMP);
	printf MSGDUMP "\n%s", $msg_body;
	close(MSGDUMP);

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

unlink ($temporary_file) unless ($main::options{'debug'} || $main::options{'debug2'}) ;

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
    
    &do_log('debug2', 'tools::smime_decrypt message msg from %s,%s',$msg->head->get('from'),$list);

    my $certfile = "$Conf{'home'}/$list/cert.pem" ;
    unless (-r $certfile){
	do_log('err', "unable to decrypt message : cert missing  $certfile");
	return undef;
    }
    my $keyfile = "$Conf{'home'}/$list/private_key";

    unless (open (MSGDUMP , "> $Conf{'tmpdir'}/MSG.$$")) {
	&do_log('err', 'unable to open %s/MSG.%s',$Conf{'tmpdir'},$$);
	return undef;
    }
    my $temporary_file = $Conf{'tmpdir'}."/".$list.".".$$ ;
    
    ## dump the incomming message.
    if (!open(MSGDUMP,"> $temporary_file")) {
	&do_log('info', 'Can\'t store message in file %s',$temporary_file);
    }
    $msg->print(\*MSGDUMP);
    close(MSGDUMP);

    
    my $decryptedmsg,$pass_option;
    if ($Conf{'key_passwd'} ne '') {
	# if password is define in sympa.conf pass the password to OpenSSL using
	$pass_option = "-passin file:$Conf{'tmpdir'}/pass.$$";	
    }

    if ($Conf{'key_passwd'} ne '') {
	unless (&POSIX::mkfifo("$Conf{'tmpdir'}/pass.$$",0600)) {
	    do_log('notice', 'Unable to make fifo for %s/pass.%s',$Conf{'tmpdir'},$$);
	    return undef;
	}
    }

    open (NEWMSG, "$Conf{'openssl'} smime -decrypt -in $temporary_file -recip $certfile -inkey $keyfile $pass_option 2>&1 |");

    if ($Conf{'key_passwd'} ne '') {
	unless (open (FIFO,"> $Conf{'tmpdir'}/pass.$$")) {
	    do_log('notice', 'Unable to open fifo for %s/pass.%s',$Conf{'tmpdir'},$$);
	    return undef;
	}
	print FIFO $Conf{'key_passwd'};
	close FIFO;
	unlink ("$Conf{'tmpdir'}/pass.$$");
    }
    
    my $msg_as_string;
    while (<NEWMSG>) {
	$msg_as_string .= $_;
    }
	
    my $parser = new MIME::Parser;
    $parser->output_to_core(1);
    unless ($decryptedmsg = $parser->parse_data($msg_as_string)) {
	do_log('notice', 'Unable to parse message');
	return undef;
    }
    close NEWMSG ;
    unlink ($temporary_file) unless ($main::options{'debug'} || $main::options{'debug2'}) ;
    
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
    
    my @parts = $msg->parts();
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
    ##  !"#$%&'()+,:;<=>? AND accented chars
    ## escape % first
    foreach my $i (0x25,0x20..0x24,0x26..0x2c,0x3a..0x3f,0xc0..0xff) {
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
    foreach my $i (0x20..0x2c,0x3a..0x3f,0xc0..0xff) {
	my $hex_i = sprintf "%lx", $i;
	my $hex_s = sprintf "%c", $i;
	$s =~ s/%$hex_i/$hex_s/g;
    }

    return $s;
}

sub escape_html {
    my $s = shift;

    $s =~ s/\"/\&quot\;/g;

    return $s;
}

sub tmp_passwd {
    my $email = shift;

    return ('init'.substr(Digest::MD5->md5_hex(join('/', $Conf{'cookie'}, $email)), -8)) ;
}

# Check sum used to authenticate communication from wwsympa to sympa
sub sympa_checksum {
    my $rcpt = shift;
    return (substr(Digest::MD5->md5_hex(join('/', $Conf{'cookie'}, $rcpt)), -10)) ;
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

	    if ($head->mime_attr("content_type.name") =~ /\.(\S+)/) {
		$fileExt = $1 ;
	    }
	    elsif ($head->recommended_filename =~ /\.(\S+)/) {
		$fileExt = $1 ;
	    }
	    else {
		my $mime_types = &load_mime_types();

		$fileExt=$mime_types->{$head->mime_type};
		my $var=$head->mime_type;
	    }
	
	    

	    ## Store body in file 
	    unless (open OFILE, ">$dir/$pathname.$fileExt") {
		print STDERR "Unable to open $dir/$pathname.$fileExt\n" ;
		return undef ; 
	    }
	    
	    if ($encoding =~ /^binary|7bit|8bit|base64|quoted-printable|x-uu|x-uuencode|x-gzip64$/ ) {
		open TMP, ">$dir/$pathname.$fileExt.$encoding";
		$message->print_body (\*TMP);
		close TMP;

		open BODY, "$dir/$pathname.$fileExt.$encoding";

		my $decoder = new MIME::Decoder $encoding;
		$decoder->decode(\*BODY, \*OFILE);
		unlink "$dir/$pathname.$fileExt.$encoding";
	    }else {
		$message->print_body (\*OFILE) ;
	    }
	    close (OFILE);
	    printf "\t-------\t Create file %s\n", $pathname.'.'.$fileExt ;
	    
	    ## Delete files created twice or more (with Content-Type.name and Content-Disposition.filename)
	    $message->purge ;
    
	
    }
}

sub virus_infected {
    my $mail = shift ;
    my $file = shift ;
    &do_log('debug2', 'virus_infected (%s)', $file);
    
    # there is no virus anywhere if there is no antivus tools installed
    return 0 unless ($Conf{'antivirus_path'} );
    
    my @name = split(/\//,$file);
    my $work_dir = $Conf{'tmpdir'}.'/antivirus';
    
    unless ((-d $work_dir) ||( mkdir $work_dir, 0755)) {
	do_log('err', "Unable to create tmp antivirus directory $work_dir");
	return 0;
    }

    $work_dir = $Conf{'tmpdir'}.'/antivirus/'.$name[$#name];
    
    unless ( mkdir ($work_dir, 0755)) {
	do_log('err', "Unable to create tmp antivirus directory $work_dir");
	return 0;
    }

    #$mail->dump_skeleton;

    ## Call the procedure of spliting mail
    &split_mail ($mail,'msg', $work_dir) ;

    my $virusfound; 
    my $error_msg;
    my $result;

    ## McAfee
    if ($Conf{'antivirus_path'} =~  /\/uvscan$/) {

	# impossible to look for viruses with no option set
	return 0 unless ($Conf{'antivirus_args'});
    
	open (ANTIVIR,"$Conf{'antivirus_path'} $Conf{'antivirus_args'} $work_dir |") ; 
		
	while (<ANTIVIR>) {
	    $result .= $_; chomp $result;
	    if (/^\s*Found the\s+(.*)\s*virus.*$/i){
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
	    if ($status != 0);

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
	return 0 unless ($Conf{'antivirus_args'});

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
    }

    ## Error while running antivir, notify listmaster
    if ($error_msg) {
	&List::send_notify_to_listmaster('virus_scan_failed', $Conf{'domain'}, ($error_msg));
    }

    ## if debug mode is active, the working directory is kept
    unless ($main::options{'debug'}) {
	opendir (DIR, ${work_dir});
	my @list = readdir(DIR);
	close (DIR);
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
    my $time = $_[1]; # the epoch current date
 
    my $result;
    
     # decomposition of the argument date
    my $date;
    my $duration;
    my $op;

    if ($arg =~ /\+|\-/) {
	$date = $`;
	$duration = $';
	$op = $&;
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
	
    if ($arg =~ /^(\d\d\d\dy)(\d+m)?(\d+d)?(\d+h)?(\d+min)?$/) { # absolute date

	my @date = (0, "$5", "$4", "$3", "$2", "$1");
	for (my $i = 0; $i < 6; $i++) {
	    chop ($date[$i]);
	    if ($i == 1) {chop ($date[$i]); chop ($date[$i]);}
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
  
    $arg =~ /(\d+y)?(\d+m)?(\d+w)?(\d+d)?(\d+h)?(\d+min)?$/i ;
    my @date = ("$1", "$2", "$3", "$4", "$5", "$6");
    for (my $i = 0; $i < 6; $i++) {
	chop ($date[$i]);
	if ($i == 5) {chop ($date[$i]); chop ($date[$i]);}
	$date[$i] = 0 unless ($date[$i]);
    }
    
    my $duration = 60*($date[5]+60*($date[4]+24*($date[3]+7*$date[2]+365*$date[0])));
	
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
    
    if ($type eq 'etc') {
	my @dirs = ("$Conf{'etc'}/$robot",$Conf{'etc'},'--ETCBINDIR--');
	if ($list) {
	    ## No 'templates' subdir in list directory
	    if ($name =~ /^templates\/(.*)$/) {
		unshift @dirs, $list->{'dir'}.'/'.$1;
	    }else {
		unshift @dirs, $list->{'dir'}.'/'.$name;
	    }
	}	
	foreach my $dir (@dirs) {
#	    &do_log('debug','NAME: %s ; DIR %s', $name, $dir);
	    if (-r "$dir/$name") {
		return "$dir/$name";
	    }
	}
    }
    
    &do_log('info','Cannot find %s', $name);
    return undef;
}

1;
