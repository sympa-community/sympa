# List.pm - This module includes all list processing functions
# <!-- RCS Identication ; $Revision$ ; $Date$ -->

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

package Message;

use strict;
require Exporter;
require 'tools.pl';
require 'parser.pl';
my @ISA = qw(Exporter);
my @EXPORT = qw();

use Carp;

use Mail::Header;
use Mail::Internet;
use Mail::Address;
use List;
use MIME::Entity;
use MIME::Words;
use MIME::Parser;
use Conf;
use Log;

## Creates a new object
sub new {
    my($pkg, $file) = @_;
    my $message;
    &do_log('debug2', 'Message::new(%s)', $file);
    
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
    
    ## Message size
    $message->{'size'} = -s $file;    

    my $hdr = $message->{'msg'}->head;


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

    ## Extract recepient address (X-Sympa-To)
    $message->{'rcpt'} = $hdr->get('X-Sympa-To');
    chomp $message->{'rcpt'};
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
	unless ($listname =~ /^(sympa|listmaster|$conf_email)(\@$conf_host)?$/i) {
	    $message->{'list'} = new List ($listname, $robot);
	}
    }

    ## S/MIME
    if ($Conf{'openssl'}) {

	## Decrypt messages
	if (($hdr->get('Content-Type') =~ /application\/(x-)?pkcs7-mime/i) &&
	    ($hdr->get('Content-Type') !~ /signed-data/)){
	    my ($dec, $dec_as_string) = &tools::smime_decrypt ($message->{'msg'}, $message->{'list'});
	    if ($dec) {
		$message->{'smime_crypted'} = 'smime_crypted';
		$message->{'orig_msg'} = $message->{'msg'};
		$message->{'msg'} = $dec;
		$message->{'msg_as_string'} = $dec_as_string;
		$hdr = $dec->head;
		do_log('debug', "message %s has been decrypted", $file);
	    }
	    ## We should process errors here (0 != undef)
	}
	
	## Check S/MIME signatures
	if ($hdr->get('Content-Type') =~ /multipart\/signed|application\/(x-)?pkcs7-mime/i) {
	    my $signed = &tools::smime_sign_check ($message);
	    if ($signed->{'body'}) {
		$message->{'smime_signed'} = 1;
		$message->{'smime_subject'} = $signed->{'subject'};
		do_log('debug', "message %s is signed, signature is checked", $file);
	    }
	    ## Il faudrait traiter les cas d'erreur (0 différent de undef)
	}
	
    }

    ## Bless Message object
    bless $message, $pkg;

    return $message;
}

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

## Packages must return true.
1;
