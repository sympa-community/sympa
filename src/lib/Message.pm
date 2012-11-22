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
	    my $signed = &tools::smime_sign_check ($message);
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
    foreach my $line (split '\n', &Dumper($self)) {
	Log::do_log('trace','%s',$line);
    }

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
