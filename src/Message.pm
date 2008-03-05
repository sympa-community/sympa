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

=head1 NAME 

I<Message.pm> - mail message embedding for internal use in Sympa

=head1 DESCRIPTION 

While processing a message in Sympa, we need to link informations to rhe message, mdify headers and such. This was quite a problem when a message was signed, as modifying anything in the message body would alter its MD5 footprint. And probably make the message to be rejected by clients verifying its identity (which is somehow a good thing as it is the reason why people use MD5 after all). With such messages, the process was complex. We then decided to embed any message treated in a "Message" object, thus making the process easier.

=cut 

package Message;

use strict;
require Exporter;
require 'tools.pl';
require 'tt2.pl';
my @ISA = qw(Exporter);
my @EXPORT = qw();

use Carp;

use Mail::Header;
use Mail::Internet;
use Mail::Address;
use List;
use MIME::Entity;
use MIME::EncWords;
use MIME::Parser;
use Conf;
use Log;

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

=item * do_log

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
    my($pkg, $file, $noxsympato) = @_;
    my $message;
    &do_log('debug2', 'Message::new(%s,%s)',$file,$noxsympato);
    
    if (ref($file) =~ /MIME::Entity/i) {
	$message->{'msg'} = $file;
	$message->{'altered'} = '_ALTERED';
	
	## Bless Message object
	bless $message, $pkg;
	
	return $message;
    }

    ## Parse message as a MIME::Entity
    $message->{'filename'} = $file;
    unless (open FILE, $file) {
	&do_log('err', 'Cannot open message file %s : %s',  $file, $!);
	return undef;
    }
    
    my $parser = new MIME::Parser;
    $parser->output_to_core(1);
    
    my $msg;
    unless ($msg = $parser->read(\*FILE)) {
	do_log('err', 'Unable to parse message %s', $file);
	return undef;
    }
    $message->{'msg'} = $msg;
    $message->{'msg_as_string'} = $msg->as_string;

    ## Message size
    $message->{'size'} = -s $file;    

    my $hdr = $message->{'msg'}->head;

    if ($Conf{'antispam_feature'} =~ /on/i){
	if ($hdr->get($Conf{'antispam_tag_header_name'}) =~ /$Conf{'antispam_tag_header_spam_regexp'}/i) {
	    $message->{'spam_status'} = 'spam';
	}elsif($hdr->get($Conf{'antispam_tag_header_name'}) =~ /$Conf{'antispam_tag_header_ham_regexp'}/i) {
	    $message->{'spam_status'} = 'ham';
	}
    }else{
	$message->{'spam_status'} = 'not configured';
    }

    ## Extract sender address
    unless ($hdr->get('From')) {
	do_log('notice', 'No From found in message %s, skipping.', $file);
	return undef;
    }   
    my @sender_hdr = Mail::Address->parse($hdr->get('From'));
    if ($#sender_hdr == -1) {
	do_log('err', 'No valid address in From: field in %s, skipping', $file);
	return undef;
    }
    $message->{'sender'} = lc($sender_hdr[0]->address);

    unless (&tools::valid_email($message->{'sender'})) {
	do_log('err', "Invalid From: field '%s'", $message->{'sender'});
	return undef;
    }

    ## Store decoded subject
    my $subject = $hdr->get('Subject');
    my @decoded_subject = MIME::EncWords::decode_mimewords($subject);
    foreach my $token (@decoded_subject) {
	$message->{'subject_charset'} ||= $token->[1];
    }
    
    ## Don't try to decode if subject is empty to prevent a bug of 
    ## decode_mimeords that would set the subject to 'Charset'
    ## Strangely the problem disappeared when using $subject instead of $hdr->get('Subject')
    ## as parameter to deocde_mimewords()
    unless ($subject =~ /^$/) {
	$message->{'decoded_subject'} = MIME::EncWords::decode_mimewords(
									 $subject, Charset=>'utf8');
	chomp $message->{'decoded_subject'};
    }

    ## Extract recepient address (X-Sympa-To)
    $message->{'rcpt'} = $hdr->get('X-Sympa-To');
    chomp $message->{'rcpt'};
    unless (defined $noxsympato) { # message.pm can be used for mesage not in the spool but in archive
	unless ($message->{'rcpt'}) {
	    do_log('err', 'no X-Sympa-To found, ignoring message file %s', $file);
	    return undef;
	}
	
	## Strip of the initial X-Sympa-To field
	# Used by checksum later
	#$hdr->delete('X-Sympa-To');
	
	## Do not check listname if processing a web message
	unless ($hdr->get('X-Sympa-From')) {
	    ## get listname & robot
	    my ($listname, $robot) = split(/\@/,$message->{'rcpt'});
	    
	    $robot = lc($robot);
	    $listname = lc($listname);
	    $robot ||= $Conf{'host'};
	    
	    my $conf_email = &Conf::get_robot_conf($robot, 'email');
	    my $conf_host = &Conf::get_robot_conf($robot, 'host');
	    unless ($listname =~ /^(sympa|$Conf{'listmaster_email'}|$conf_email)(\@$conf_host)?$/i) {
		my $list_check_regexp = &Conf::get_robot_conf($robot,'list_check_regexp');
	        if ($listname =~ /^(\S+)-($list_check_regexp)$/) {
		    $listname = $1;
		}
		
		$message->{'list'} = new List ($listname, $robot);
		unless ($message->{'rcpt'}) {
		    do_log('err', 'Could not create List object for list %s in robot %s', $listname, $robot);
		    return undef;
		}
		
	    }
	}
    }

    ## S/MIME
    if ($Conf{'openssl'}) {

	## Decrypt messages
	if (($hdr->get('Content-Type') =~ /application\/(x-)?pkcs7-mime/i) &&
	    ($hdr->get('Content-Type') !~ /signed-data/)){
	    my ($dec, $dec_as_string) = &tools::smime_decrypt ($message->{'msg'}, $message->{'list'});
	    
	    unless (defined $dec) {
		do_log('debug', "Message %s could not be decrypted", $file);
		return undef;
		## We should the sender and/or the listmaster
	    }

	    $message->{'smime_crypted'} = 'smime_crypted';
	    $message->{'orig_msg'} = $message->{'msg'};
	    $message->{'msg'} = $dec;
	    $message->{'msg_as_string'} = $dec_as_string;
	    $hdr = $dec->head;
	    do_log('debug', "message %s has been decrypted", $file);

	}
	
	## Check S/MIME signatures
	if ($hdr->get('Content-Type') =~ /multipart\/signed|application\/(x-)?pkcs7-mime/i) {
	    $message->{'protected'} = 1; ## Messages that should not be altered (not footer)
	    my $signed = &tools::smime_sign_check ($message);
	    if ($signed->{'body'}) {
		$message->{'smime_signed'} = 1;
		$message->{'smime_subject'} = $signed->{'subject'};
		do_log('debug', "message %s is signed, signature is checked", $file);
	    }
	    ## Il faudrait traiter les cas d'erreur (0 différent de undef)
	}
	
    }

    ## TOPICS
    my $topics;
    if ($topics = $hdr->get('X-Sympa-Topic')){
	$message->{'topic'} = $topics;
    }

    ## Bless Message object
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


## Packages must return true.
1;
=pod 

=head1 AUTHORS 

=over 

=item * Serge Aumont <sa AT cru.fr> 

=item * Olivier Salaün <os AT cru.fr> 

=back 

=cut 
