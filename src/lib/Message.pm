# Message.pm - This module includes Message processing functions
#<!-- RCS Identication ; $Revision$ ; $Date$ --> 

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

=pod 

=encoding utf-8

=head1 NAME 

I<Message.pm> - mail message embedding for internal use in Sympa

=head1 DESCRIPTION 

While processing a message in Sympa, we need to link informations to rhe message, mdify headers and such. This was quite a problem when a message was signed, as modifying anything in the message body would alter its MD5 footprint. And probably make the message to be rejected by clients verifying its identity (which is somehow a good thing as it is the reason why people use MD5 after all). With such messages, the process was complex. We then decided to embed any message treated in a "Message" object, thus making the process easier.

=cut 

package Message;

use strict;
use Data::Dumper;
use Carp;
use Mail::Header;
use Mail::Address;
use MIME::Entity;
use MIME::EncWords;
use MIME::Parser;
use POSIX qw(mkfifo);

use Site;

#use List;
##The line above was removed to avoid dependency loop.
##"use List" MUST precede to "use Message".
#use tools; # loaded in Conf
#use tt2; # loaded by List
#use Conf; # loaded in List - Site
#use Log; # loaded in Conf

my %openssl_errors = (1 => 'an error occurred parsing the command options',
		      2 => 'one of the input files could not be read',
		      3 => 'an error occurred creating the PKCS#7 file or when reading the MIME message',
		      4 => 'an error occurred decrypting or verifying the message',
		      5 => 'the message was verified correctly but an error occurred writing out the signers certificates');
=pod 

=head1 SUBFUNCTIONS 

This is the description of the subfunctions contained by Message.pm

=cut 


=pod 

=head2 sub new

Creates a new Message object.

=head3 Arguments 

=over 

=item * I<$pkg>, a package name 

=item * I<$file>, the message file

=item * I<$noxsympato>, a boolean

=back 

=head3 Return 

=over 

=item * I<a Message object>, if created

=item * I<undef>, if something went wrong

=back 

=head3 Calls 

=over 

=item * Log::do_log

=item * Conf::get_robot_conf

=item * List::new

=item * Mail::Address::parse

=item * MIME::EncWords::decode_mimewords

=item * MIME::Entity::as_string

=item * MIME::Head::get

=item * MIME::Parser::output_to_core

=item * MIME::Parser::read

=item * tools::valid_email

=item * tools::smime_decrypt

=item * tools::smime_sign_check

=back 

=cut 

## Creates a new object
sub new {
    
    my $pkg =shift;
    my $datas = shift;

    my $file = $datas->{'file'};
    my $noxsympato = $datas->{'noxsympato'};
    my $messageasstring = $datas->{'messageasstring'};
    my $mimeentity = $datas->{'mimeentity'};
    my $message_in_spool= $datas->{'message_in_spool'};

    my $message;
    my $input = 'file' if $file;
    $input = 'messageasstring' if $messageasstring; 
    $input = 'message_in_spool' if $message_in_spool; 
    $input = 'mimeentity' if $mimeentity; 
    Log::do_log('debug2', 'Message::new(input= %s, noxsympato= %s)',$input,$noxsympato);
    
    if ($mimeentity) {
	$message->{'msg'} = $mimeentity;
	$message->{'altered'} = '_ALTERED';

	## Bless Message object
	bless $message, $pkg;
	
	return $message;
    }

    my $parser = new MIME::Parser;
    $parser->output_to_core(1);
    
    my $msg;

    if ($message_in_spool){
	$messageasstring = $message_in_spool->{'messageasstring'};
	$message->{'messagekey'}= $message_in_spool->{'messagekey'};
	$message->{'spoolname'}= $message_in_spool->{'spoolname'};
	$message->{'create_list_if_needed'}= $message_in_spool->{'create_list_if_needed'};
    }
    if ($file) {
	## Parse message as a MIME::Entity
	$message->{'filename'} = $file;
	unless (open FILE, "$file") {
	    Log::do_log('err', 'Cannot open message file %s : %s',  $file, $!);
	    return undef;
	}
	while (<FILE>){
	    $messageasstring = $messageasstring.$_;
	}
	close(FILE);
	# my $dump = &Dumper($messageasstring); open (DUMP,">>/tmp/dumper"); printf DUMP 'lecture du fichier \n%s',$dump ; close DUMP; 
    }
    if($messageasstring){
	if (ref ($messageasstring)){
	    $msg = $parser->parse_data($messageasstring);
	}else{
	    $msg = $parser->parse_data(\$messageasstring);
	}

	# get envelope sender
	##FIXME: currently won't work as expected.
	my $from_ = undef;
	if (ref $messageasstring) {
	    if (ref $messageasstring eq 'ARRAY' and
		$messageasstring->[0] =~ /^From (\S+)/) {
		$from_ = $1;
	    } elsif ($$messageasstring =~ /^From (\S+)/) {
		$from_ = $1;
	    }
	} elsif ($messageasstring =~ /^From (\S+)/) {
	    $from_ = $1;
	}
	if (defined $from_) {
	    if ($from_ =~ /<>/) {
		$from_ = '<>';
	    } else {
		$from_ = tools::clean_email($from_);
	    }
	    $message->{'envsender'} = $from_ if $from_;
	}
    }  

    unless ($msg){
	Log::do_log('err',"could not parse message"); 
	return undef;
    }
    $message->{'msg'} = $msg;
#    $message->{'msg_as_string'} = $msg->as_string; 
    $message->{'msg_as_string'} = $messageasstring; 
    $message->{'size'} = length($msg->as_string);

    my $hdr = $message->{'msg'}->head;

    ## Extract sender address
    unless ($hdr->get('From')) {
	Log::do_log('err', 'No From found in message %s, skipping.', $file);
	return undef;
    }   
    my @sender_hdr = Mail::Address->parse($hdr->get('From'));
    if ($#sender_hdr == -1) {
	Log::do_log('err', 'No valid address in From: field in %s, skipping', $file);
	return undef;
    }
    $message->{'sender'} = lc($sender_hdr[0]->address);

    unless (&tools::valid_email($message->{'sender'})) {
	Log::do_log('err', "Invalid From: field '%s'", $message->{'sender'});
	return undef;
    }

    ## Store decoded subject and its original charset
    my $subject = $hdr->get('Subject');
    if ($subject =~ /\S/) {
	my @decoded_subject = MIME::EncWords::decode_mimewords($subject);
	$message->{'subject_charset'} = 'US-ASCII';
	foreach my $token (@decoded_subject) {
	    unless ($token->[1]) {
		# don't decode header including raw 8-bit bytes.
		if ($token->[0] =~ /[^\x00-\x7F]/) {
		    $message->{'subject_charset'} = undef;
		    last;
		}
		next;
	    }
	    my $cset = MIME::Charset->new($token->[1]);
	    # don't decode header encoded with unknown charset.
	    unless ($cset->decoder) {
		$message->{'subject_charset'} = undef;
		last;
	    }
	    unless ($cset->output_charset eq 'US-ASCII') {
		$message->{'subject_charset'} = $token->[1];
	    }
	}
    } else {
	$message->{'subject_charset'} = undef;
    }
    if ($message->{'subject_charset'}) {
	$message->{'decoded_subject'} =
	    MIME::EncWords::decode_mimewords($subject, Charset => 'utf8');
    } else {
	$message->{'decoded_subject'} = $subject;
    }
    chomp $message->{'decoded_subject'};

    ## Extract recepient address (X-Sympa-To)
    $message->{'rcpt'} = $hdr->get('X-Sympa-To');
    chomp $message->{'rcpt'};
    unless (defined $noxsympato) { # message.pm can be used not only for message coming from queue
	unless ($message->{'rcpt'}) {
	    Log::do_log('err', 'no X-Sympa-To found, ignoring message file %s', $file);
	    return undef;
	}
	    
	## get listname & robot
	my ($listname, $robot) = split(/\@/,$message->{'rcpt'});
	
	$robot = lc($robot);
	$listname = lc($listname);
	$robot ||= Site->domain;
	my $spam_status = &Scenario::request_action('spam_status','smtp',$robot, {'message' => $message});
	$message->{'spam_status'} = 'unkown';
	if(defined $spam_status) {
	    if (ref($spam_status ) eq 'HASH') {
		$message->{'spam_status'} =  $spam_status ->{'action'};
	    }else{
		$message->{'spam_status'} = $spam_status ;
	    }
	}
	
	my $conf_email = &Conf::get_robot_conf($robot, 'email');
	my $conf_host = &Conf::get_robot_conf($robot, 'host');
	my $site_email = Site->listmaster_email;
	my $site_host = Site->host;
	unless ($listname =~ /^(sympa|$site_email|$conf_email)(\@$conf_host)?$/i) {
	    my $list_check_regexp = &Conf::get_robot_conf($robot,'list_check_regexp');
	    if ($listname =~ /^(\S+)-($list_check_regexp)$/) {
		$listname = $1;
	    }
	    
	    my $list = new List ($listname, $robot, {'just_try' => 1});
	    if ($list) {
		$message->{'list'} = $list;
	    }	
	}
	# verify DKIM signature
	if (&Conf::get_robot_conf($robot, 'dkim_feature') eq 'on'){
	    $message->{'dkim_pass'} = &tools::dkim_verifier($message->{'msg_as_string'});
	}
    }
        
    ## valid X-Sympa-Checksum prove the message comes from web interface with authenticated sender
    if ( $hdr->get('X-Sympa-Checksum')) {
	my $chksum = $hdr->get('X-Sympa-Checksum'); chomp $chksum;
	my $rcpt = $hdr->get('X-Sympa-To'); chomp $rcpt;

	if ($chksum eq &tools::sympa_checksum($rcpt)) {
	    $message->{'md5_check'} = 1 ;
	}else{
	    Log::do_log('err',"incorrect X-Sympa-Checksum header");	
	}
    }

    ## S/MIME
    if (Site->openssl) {

	## Decrypt messages
	if (($hdr->get('Content-Type') =~ /application\/(x-)?pkcs7-mime/i) &&
	    ($hdr->get('Content-Type') !~ /signed-data/)){
	    unless (defined smime_decrypt($message)) {
		Log::do_log('debug', "Message %s could not be decrypted", $file);
		return undef;
		## We should warn the sender and/or the listmaster
	    }
	    $hdr = $message->{'msg'}->head;
	    Log::do_log('debug', "message %s has been decrypted", $file);
	}
	
	## Check S/MIME signatures
	if ($hdr->get('Content-Type') =~ /multipart\/signed|application\/(x-)?pkcs7-mime/i) {
	    $message->{'protected'} = 1; ## Messages that should not be altered (no footer)
	    my $signed = smime_sign_check ($message);
	    if ($signed->{'body'}) {
		$message->{'smime_signed'} = 1;
		$message->{'smime_subject'} = $signed->{'subject'};
		Log::do_log('debug', "message %s is signed, signature is checked", $file);
	    }
	    ## Il faudrait traiter les cas d'erreur (0 différent de undef)
	}
	
    }
    ## TOPICS
    my $topics;
    if ($topics = $hdr->get('X-Sympa-Topic')){
	$message->{'topic'} = $topics;
    }

    bless $message, $pkg;
    return $message;
}

# input : msg object, return a new message object encrypted
sub smime_encrypt {
    ##my $self = shift;
    my $msg_header = shift;
    my $msg_body = shift;
    my $email = shift ;
    my $list = shift ;

    my $usercert;
    my $dummy;
    my $cryptedmsg;
    my $encrypted_body;    

    &Log::do_log('debug2', 'tools::smime_encrypt( %s, %s', $email, $list);
    if ($list eq 'list') {
	my $self = new List($email);
	($usercert, $dummy) = smime_find_keys($self->{dir}, 'encrypt');
    }else{
	my $base = Site->ssl_cert_dir . '/' . &tools::escape_chars($email);
	if(-f "$base\@enc") {
	    $usercert = "$base\@enc";
	} else {
	    $usercert = "$base";
	}
    }
    if (-r $usercert) {
	my $temporary_file = Site->tmpdir."/".$email.".".$$ ;

	## encrypt the incomming message parse it.
	my $cmd = sprintf '%s smime -encrypt -out %s -des3 %s',
	    Site->openssl, $temporary_file, $usercert;
        &Log::do_log ('debug3', '%s', $cmd);
	if (!open(MSGDUMP, "| $cmd")) {
	    &Log::do_log('info', 'Can\'t encrypt message for recipient %s',
		$email);
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
	    &Log::do_log('err', 'Unable to S/MIME encrypt message : %s', $openssl_errors{$status});
	    return undef ;
	}

        ## Get as MIME object
	open (NEWMSG, $temporary_file);
	my $parser = new MIME::Parser;
	$parser->output_to_core(1);
	unless ($cryptedmsg = $parser->read(\*NEWMSG)) {
	    &Log::do_log('notice', 'Unable to parse message');
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
	    $predefined_headers->{lc $header} = 1 
	        if ($cryptedmsg->head->get($header)) ;
	}
	foreach my $header (split /\n(?![ \t])/, $msg_header->as_string) {
	    next unless $header =~ /^([^\s:]+)\s*:\s*(.*)$/s;
	    my ($tag, $val) = ($1, $2);
	    $cryptedmsg->head->add($tag, $val) 
	        unless $predefined_headers->{lc $tag};
	}

    }else{
	&Log::do_log ('notice','unable to encrypt message to %s (missing certificat %s)',$email,$usercert);
	return undef;
    }
        
    return $cryptedmsg->head->as_string . "\n" . $encrypted_body;
}

sub smime_sign_check {
    my $message = shift;

    my $sender = $message->{'sender'};

    &Log::do_log('debug', 'tools::smime_sign_check (message, %s, %s)', $sender, $message->{'filename'});

    my $is_signed = {};
    $is_signed->{'body'} = undef;   
    $is_signed->{'subject'} = undef;

    my $verify ;

    ## first step is the msg signing OK ; /tmp/sympa-smime.$$ is created
    ## to store the signer certificat for step two. I known, that's durty.

    my $temporary_file = Site->tmpdir."/".'smime-sender.'.$$ ;
    my $trusted_ca_options = '';
    $trusted_ca_options = "-CAfile " . Site->cafile . " " if Site->cafile;
    $trusted_ca_options .= "-CApath " . Site->capath . " " if Site->capath;
    my $cmd = sprintf '%s smime -verify %s -signer %s',
	Site->openssl, $trusted_ca_options, $temporary_file;
    &Log::do_log('debug3', '%s', $cmd);

    unless (open MSGDUMP, "| $cmd > /dev/null") {
	&Log::do_log('err',
	    'unable to verify smime signature from %s %s',
	    $sender, $verify);
	return undef ;
    }
    
    if ($message->{'smime_crypted'}){
	$message->{'msg'}->head->print(\*MSGDUMP);
	print MSGDUMP "\n";
	print MSGDUMP $message->{'msg_as_string'};
    }elsif (! $message->{'filename'}) {
	print MSGDUMP $message->{'msg_as_string'};
    }else{
	unless (open MSG, $message->{'filename'}) {
	    &Log::do_log('err', 'Unable to open file %s: %s', $message->{'filename'}, $!);
	    return undef;

	}
	print MSGDUMP <MSG>;
	close MSG;
    }
    close MSGDUMP;

    my $status = $?/256 ;
    unless ($status == 0) {
	&Log::do_log('err', 'Unable to check S/MIME signature : %s', $openssl_errors{$status});
	return undef ;
    }
    ## second step is the message signer match the sender
    ## a better analyse should be performed to extract the signer email. 
    my $signer = tools::smime_parse_cert({file => $temporary_file});

    unless ($signer->{'email'}{lc($sender)}) {
	unlink($temporary_file) unless ($main::options{'debug'}) ;
	&Log::do_log('err', "S/MIME signed message, sender(%s) does NOT match signer(%s)",$sender, join(',', keys %{$signer->{'email'}}));
	return undef;
    }

    &Log::do_log('debug', "S/MIME signed message, signature checked and sender match signer(%s)", join(',', keys %{$signer->{'email'}}));
    ## store the signer certificat
    unless (-d Site->ssl_cert_dir) {
	if ( mkdir (Site->ssl_cert_dir, 0775)) {
	    &Log::do_log('info', 'creating spool %s', Site->ssl_cert_dir);
	}else{
	    &Log::do_log('err',
		'Unable to create user certificat directory %s',
		Site->ssl_cert_dir);
	}
    }

    ## It gets a bit complicated now. openssl smime -signer only puts
    ## the _signing_ certificate into the given file; to get all included
    ## certs, we need to extract them from the signature proper, and then
    ## we need to check if they are for our user (CA and intermediate certs
    ## are also included), and look at the purpose:
    ## "S/MIME signing : Yes/No"
    ## "S/MIME encryption : Yes/No"
    my $certbundle = Site->tmpdir . "/certbundle.$$";
    my $tmpcert = Site->tmpdir . "/cert.$$";
    my $nparts = $message->{msg}->parts;
    my $extracted = 0;
    &Log::do_log('debug2', "smime_sign_check: parsing $nparts parts");
    if($nparts == 0) { # could be opaque signing...
	$extracted +=tools::smime_extract_certs($message->{msg}, $certbundle);
    } else {
	for (my $i = 0; $i < $nparts; $i++) {
	    my $part = $message->{msg}->parts($i);
	    $extracted += tools::smime_extract_certs($part, $certbundle);
	    last if $extracted;
	}
    }
    
    unless($extracted) {
	&Log::do_log('err', "No application/x-pkcs7-* parts found");
	return undef;
    }

    unless(open(BUNDLE, $certbundle)) {
	&Log::do_log('err', "Can't open cert bundle $certbundle: $!");
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
		&Log::do_log('err', "Can't create $tmpcert: $!");
		return undef;
	    }
	    print CERT $workcert;
	    close(CERT);
	    my($parsed) = tools::smime_parse_cert({file => $tmpcert});
	    unless($parsed) {
		&Log::do_log('err', 'No result from smime_parse_cert');
		return undef;
	    }
	    unless($parsed->{'email'}) {
		&Log::do_log('debug', "No email in cert for $parsed->{subject}, skipping");
		next;
	    }
	    
	    &Log::do_log('debug2', "Found cert for <%s>", join(',', keys %{$parsed->{'email'}}));
	    if ($parsed->{'email'}{lc($sender)}) {
		if ($parsed->{'purpose'}{'sign'} && $parsed->{'purpose'}{'enc'}) {
		    $certs{'both'} = $workcert;
		    &Log::do_log('debug', 'Found a signing + encryption cert');
		}elsif ($parsed->{'purpose'}{'sign'}) {
		    $certs{'sign'} = $workcert;
		    &Log::do_log('debug', 'Found a signing cert');
		} elsif($parsed->{'purpose'}{'enc'}) {
		    $certs{'enc'} = $workcert;
		    &Log::do_log('debug', 'Found an encryption cert');
		}
	    }
	    last if(($certs{'both'}) || ($certs{'sign'} && $certs{'enc'}));
	}
    }
    close(BUNDLE);
    if(!($certs{both} || ($certs{sign} || $certs{enc}))) {
	&Log::do_log('err', "Could not extract certificate for %s", join(',', keys %{$signer->{'email'}}));
	return undef;
    }
    ## OK, now we have the certs, either a combined sign+encryption one
    ## or a pair of single-purpose. save them, as email@addr if combined,
    ## or as email@addr@sign / email@addr@enc for split certs.
    foreach my $c (keys %certs) {
	my $fn = Site->ssl_cert_dir . '/' . tools::escape_chars(lc($sender));
	if ($c ne 'both') {
	    unlink($fn); # just in case there's an old cert left...
	    $fn .= "\@$c";
	}else {
	    unlink("$fn\@enc");
	    unlink("$fn\@sign");
	}
	&Log::do_log('debug', "Saving $c cert in $fn");
	unless (open(CERT, ">$fn")) {
	    &Log::do_log('err', "Unable to create certificate file $fn: $!");
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


=pod 

=head2 sub dump

Dump a Message object to a stream.

=head3 Arguments 

=over 

=item * I<$self>, the Message object to dump

=item * I<$output>, the stream to which dump the object

=back 

=head3 Return 

=over 

=item * I<1>, if everything's alright

=back 

=head3 Calls 

=over 

=item * None

=back 

=cut 

## Dump the Message object
sub dump {
    my ($self, $output) = @_;
#    my $output ||= \*STDERR;

    my $old_output = select;
    select $output;

    foreach my $key (keys %{$self}) {
	if (ref($self->{$key}) eq 'MIME::Entity') {
	    printf "%s =>\n", $key;
	    $self->{$key}->print;
	}else {
	    printf "%s => %s\n", $key, $self->{$key};
	}
    }
    
    select $old_output;

    return 1;
}

=pod 

=head2 sub add_topic

Add topic and put header X-Sympa-Topic.

=head3 Arguments 

=over 

=item * I<$self>, the Message object to which add a topic

=item * I<$output>, the string containing the topic to add

=back 

=head3 Return 

=over 

=item * I<1>, if everything's alright

=back 

=head3 Calls 

=over 

=item * MIME::Head::add

=back 

=cut 

## Add topic and put header X-Sympa-Topic
sub add_topic {
    my ($self,$topic) = @_;

    $self->{'topic'} = $topic;
    my $hdr = $self->{'msg'}->head;
    $hdr->add('X-Sympa-Topic', $topic);

    return 1;
}


=pod 

=head2 sub add_topic

Add topic and put header X-Sympa-Topic.

=head3 Arguments 

=over 

=item * I<$self>, the Message object whose topic is retrieved

=back 

=head3 Return 

=over 

=item * I<the topic>, if it exists

=item * I<empty string>, otherwise

=back 

=head3 Calls 

=over 

=item * MIME::Head::add

=back 

=cut 

## Get topic
sub get_topic {
    my ($self) = @_;

    if (defined $self->{'topic'}) {
	return $self->{'topic'};

    } else {
	return '';
    }
}

sub clean_html {
    my $self = shift;
    my ($listname, $robot) = split(/\@/,$self->{'rcpt'});
    $robot = lc($robot);
    $listname = lc($listname);
    $robot ||= Site->host;
    my $new_msg;
    if($new_msg = &fix_html_part($self->{'msg'},$robot)) {
	$self->{'msg'} = $new_msg;
	return 1;
    }
    return 0;
}

sub fix_html_part {
    my $part = shift;
    my $robot = shift;
    return $part unless $part;
    my $eff_type = $part->head->mime_attr("Content-Type");
    if ($part->parts) {
	my @newparts = ();
	foreach ($part->parts) {
	    push @newparts, &fix_html_part($_,$robot);
	}
	$part->parts(\@newparts);
    } elsif ($eff_type =~ /^text\/html/i) {
	my $bodyh = $part->bodyhandle;
	# Encoded body or null body won't be modified.
	return $part if !$bodyh or $bodyh->is_encoded;

	my $body = $bodyh->as_string;
	# Re-encode parts with 7-bit charset (ISO-2022-*), since
	# StripScripts cannot handle them correctly.
	my $cset = MIME::Charset->new($part->head->mime_attr('Content-Type.Charset') || '');
	unless ($cset->decoder) {
	    # Charset is unknown.  Detect 7-bit charset.
	    my ($dummy, $charset) =
		MIME::Charset::body_encode($body, '', Detect7Bit => 'YES');
	    $cset = MIME::Charset->new($charset);
	}
	if ($cset->decoder and $cset->as_string =~ /^ISO-2022-/i) {
	    $part->head->mime_attr('Content-Type.Charset', 'UTF-8');
	    $cset->encoder('UTF-8');
	    $body = $cset->encode($body);
	}

	my $filtered_body = &tools::sanitize_html('string' => $body, 'robot'=> $robot);

	my $io = $bodyh->open("w");
	unless (defined $io) {
	    Log::do_log('err', "Failed to save message : $!");
	    return undef;
	}
	$io->print($filtered_body);
	$io->close;
    }
    return $part;
}

# extract body as string from msg_as_string
# do NOT use Mime::Entity in order to preserveB64 encoding form and so preserve S/MIME signature
sub get_body_from_msg_as_string {
    my $msg =shift;

    my @bodysection =split("\n\n",$msg );    # convert it as a tab with headers as first element
    shift @bodysection;                      # remove headers
    return (join ("\n\n",@bodysection));  # convert it back as string
}

# input : msg object for a list, return a new message object decrypted
sub smime_decrypt {
    my $self = shift;
    my $from = $self->{'msg'}->head->get('from');
    my $list = $self->{'list'};

    use Data::Dumper;
    Log::do_log('debug2', 'Decrypting message from %s,%s', $from, $list->{'name'});

    ## an empty "list" parameter means mail to sympa@, listmaster@...
    my $dir = $list->{'dir'};
    unless ($dir) {
	$dir = Site->home . '/sympa';
    }
    my ($certs,$keys) = tools::smime_find_keys($dir, 'decrypt');
    unless (defined $certs && @$certs) {
	Log::do_log('err', "Unable to decrypt message : missing certificate file");
	return undef;
    }

    my $temporary_file = Site->tmpdir."/".$list->get_list_id().".".$$ ;
    my $temporary_pwd = Site->tmpdir.'/pass.'.$$;

    ## dump the incoming message.
    if (!open(MSGDUMP,"> $temporary_file")) {
	Log::do_log('info', 'Can\'t store message in file %s',$temporary_file);
	return undef;
    }
    $self->{'msg'}->print(\*MSGDUMP);
    close(MSGDUMP);
    
    my $pass_option;
    $self->{'decrypted_msg_as_string'} = '';
    if (Site->key_passwd ne '') {
	# if password is defined in sympa.conf pass the password to OpenSSL
	$pass_option = "-passin file:$temporary_pwd";	
    }

    ## try all keys/certs until one decrypts.
    while (my $certfile = shift @$certs) {
	my $keyfile = shift @$keys;
	Log::do_log('debug', "Trying decrypt with $certfile, $keyfile");
	if (Site->key_passwd ne '') {
	    unless (mkfifo($temporary_pwd,0600)) {
		Log::do_log('err', 'Unable to make fifo for %s', $temporary_pwd);
		return undef;
	    }
	}
	my $cmd = sprintf '%s smime -decrypt -in %s -recip %s -inkey %s %s',
	    Site->openssl, $temporary_file, $certfile, $keyfile,
	    $pass_option;
	Log::do_log('debug3', $cmd);
	open (NEWMSG, "$cmd |");

	if (defined Site->key_passwd and Site->key_passwd ne '') {
	    unless (open (FIFO,"> $temporary_pwd")) {
		Log::do_log('notice', 'Unable to open fifo for %s', $temporary_pwd);
		return undef;
	    }
	    print FIFO Site->key_passwd;
	    close FIFO;
	    unlink ($temporary_pwd);
	}
	
	while (<NEWMSG>) {
	    $self->{'decrypted_msg_as_string'} .= $_;
	}
	close NEWMSG ;
	my $status = $?/256;
	
	unless ($status == 0) {
	    Log::do_log('notice', 'Unable to decrypt S/MIME message : %s', $openssl_errors{$status});
	    next;
	}
	
	unlink ($temporary_file) unless ($main::options{'debug'}) ;
	
	my $parser = new MIME::Parser;
	$parser->output_to_core(1);
	unless ($self->{'decrypted_msg'} = $parser->parse_data($self->{'decrypted_msg_as_string'})) {
	    Log::do_log('notice', 'Unable to parse message');
	    last;
	}
    }
	
    unless (defined $self->{'decrypted_msg'}) {
      Log::do_log('err', 'Message could not be decrypted');
      return undef;
    }

    ## Now remove headers from $self->{'decrypted_msg_as_string'}
    my @msg_tab = split(/\n/, $self->{'decrypted_msg_as_string'});
    my $line;
    do {$line = shift(@msg_tab)} while ($line !~ /^\s*$/);
    $self->{'decrypted_msg_as_string'} = join("\n", @msg_tab);
    
    ## foreach header defined in the incoming message but undefined in the
    ## decrypted message, add this header in the decrypted form.
    my $predefined_headers ;
    foreach my $header ($self->{'decrypted_msg'}->head->tags) {
	if ($self->{'decrypted_msg'}->head->get($header)) {
	    $predefined_headers->{lc $header} = 1;
	}
    }
    foreach my $header (split /\n(?![ \t])/, $self->{'msg'}->head->as_string) {
	next unless $header =~ /^([^\s:]+)\s*:\s*(.*)$/s;
	my ($tag, $val) = ($1, $2);
	unless ($predefined_headers->{lc $tag}) {
	    $self->{'decrypted_msg'}->head->add($tag, $val);
	}
    }
    ## Some headers from the initial message should not be restored
    ## Content-Disposition and Content-Transfer-Encoding if the result is multipart
    $self->{'decrypted_msg'}->head->delete('Content-Disposition') if ($self->{'decrypted_msg'}->head->get('Content-Disposition'));
    if ($self->{'decrypted_msg'}->head->get('Content-Type') =~ /multipart/) {
	$self->{'decrypted_msg'}->head->delete('Content-Transfer-Encoding') if ($self->{'decrypted_msg'}->head->get('Content-Transfer-Encoding'));
    }

    ## Now add headers to message as string
    $self->{'decrypted_msg_as_string'}  = $self->{'decrypted_msg'}->head->as_string."\n".$self->{'decrypted_msg_as_string'};
    
    $self->{'smime_crypted'} = 'smime_crypted';
    $self->{'orig_msg'} = $self->{'msg'};
    $self->{'msg'} = $self->{'decrypted_msg'};
    $self->{'msg_as_string'} = $self->{'decrypted_msg_as_string'};
    delete $self->{'decrypted_msg_as_string'};
    delete $self->{'decrypted_msg'};
    ##foreach my $line (split '\n', &Dumper($self)) {
	##Log::do_log('trace','%s',$line);
    ##}

    return 1;
}

## Packages must return true.
1;
=pod 

=head1 AUTHORS 

=over 

=item * Serge Aumont <sa AT cru.fr> 

=item * Olivier SalaE<0xfc>n <os AT cru.fr> 

=back 

=cut 
