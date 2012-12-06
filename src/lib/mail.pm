# mail.pm - This module includes mail sending functions and does the smtp job.
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

use strict;
require Exporter;
#use Carp; # currently not used.
use POSIX;
use Time::Local;
use MIME::EncWords;
use MIME::Tools;
# tentative
use Data::Dumper;

#use Conf; # used in Bulk - List - Site
#use Log; # load in Conf
use Language qw(gettext);
#use List; # no longer used
use Bulk; #FIXME: dependency loop between Bulk & mail
#use tools; # load in Conf
#use Sympa::Constants; # load in confdef - Conf

our @ISA = qw(Exporter);
our @EXPORT = qw(mail_file mail_message mail_forward set_send_spool);

my $opensmtp = 0;
my $fh = 'fh0000000000';	## File handle for the stream.

my $max_arg = eval { &POSIX::_SC_ARG_MAX; };
if ($@) {
    $max_arg = 4096;
    printf STDERR gettext("Your system does not conform to the POSIX P1003.1 standard, or\nyour Perl system does not define the _SC_ARG_MAX constant in its POSIX\nlibrary. You must modify the smtp.pm module in order to set a value\nfor variable %s.\n"), $max_arg;
} else {
    $max_arg = POSIX::sysconf($max_arg);
}

my %pid = ();

my $send_spool; ## for calling context



#################################### PUBLIC FUNCTIONS ##############################################


####################################################
# public set_send_spool      
####################################################
# set in global $send_spool, the concerned spool for
# sending message when it is not done by smtpto
#    
# IN : $spool (+): spool concerned by sending
# OUT :
#      
####################################################
sub set_send_spool {
    my $spool = pop;

    $send_spool = $spool;
}

####################################################
# public mail_file                          
####################################################
# send a tt2 file 
# 
#  
# IN : -$filename(+) : tt2 filename (with .tt2) | ''
#      -$rcpt(+) : SCALAR |ref(ARRAY) : SMTP "RCPT To:" field
#      -$data(+) : used to parse tt2 file, ref(HASH) with keys :
#         -return_path(+) : SMTP "MAIL From:" field if send by smtp, 
#                           "X-Sympa-From:" field if send by spool
#         -to : "To:" header field
#         -lang : tt2 language if $filename
#         -list :  ref(HASH) if $sign_mode = 'smime', keys are :
#            -name
#            -dir
#         -from : "From:" field if not a full msg
#         -subject : "Subject:" field if not a full msg
#         -replyto : "Reply-to:" field if not a full msg
#         -body  : body message if not $filename
#         -headers : ref(HASH) with keys are headers mail
#         -dkim : a set of parameters for appying DKIM signature
#            -d : d=tag
#            -i : i=tag (optionnal)
#            -selector : dkim dns selector
#            -key : the RSA private key
#      -$self(+) : ref(Robot) | "Site"
#      -$sign_mode :'smime' | '' | undef
#         
# OUT : 1 | undef
####################################################
## NOTE: This might be moved to Site module as mutative method.
sub mail_file {
    my $filename = shift;
    my $rcpt = shift;
    my $data = shift;
    my $robot = Robot::clean_robot(shift, 1); # May be Site
    my $return_message_as_string = shift;
    my $header_possible = $data->{'header_possible'};
    my $sign_mode = $data->{'sign_mode'};

    &Log::do_log('debug2', 'mail::mail_file(%s, %s, %s)', $filename, $rcpt, $sign_mode);

    my ($to,$message_as_string);

    ## boolean
    $header_possible = 0 unless (defined $header_possible);
    my %header_ok;           # hash containing no missing headers
    my $existing_headers = 0;# the message already contains headers
   
    ## We may receive a list a recepients
    if (ref ($rcpt)) {
	unless (ref ($rcpt) eq 'ARRAY') {
	    &Log::do_log('notice', 'Wrong type of reference for rcpt');
	    return undef;
	}
    }

    ## Charset for encoding
    &Language::PushLang($data->{'lang'}) if defined $data->{'lang'};
    $data->{'charset'} ||= &Language::GetCharset();
    &Language::PopLang() if defined $data->{'lang'};

    ## TT2 file parsing 
    if ($filename =~ /\.tt2$/) {
	my $output;
	my @path = split /\//, $filename;	   
	&Language::PushLang($data->{'lang'}) if (defined $data->{'lang'});
	&tt2::parse_tt2($data, $path[$#path], \$output);
	&Language::PopLang() if (defined $data->{'lang'});
	$message_as_string .= join('',$output);
	$header_possible = 1;

    }else { # or not
	$message_as_string .= $data->{'body'};
    }
       
    ## ## Does the message include headers ?
    if ($header_possible) {
	foreach my $line (split(/\n/,$message_as_string)) {
	    last if ($line=~/^\s*$/);  
	    if ($line=~/^[\w-]+:\s*/) { ## A header field
		$existing_headers=1;
	    }elsif ($existing_headers && ($line =~ /^\s/)) { ## Following of a header field
		next;
	    }else{
		last;
	    }
	    
	    foreach my $header ('date', 'to','from','subject','reply-to','mime-version', 'content-type','content-transfer-encoding') {
		if ($line=~/^$header:/i) {
		    $header_ok{$header} = 1;
		    last;
		}
	    }
	}
    }
    
    ## ADD MISSING HEADERS
    my $headers="";

    unless ($header_ok{'date'}) {
	my $now = time;
	my $tzoff = timegm(localtime $now) - $now;
	my $sign;
	if ($tzoff < 0) {
	   ($sign, $tzoff) = ('-', -$tzoff);
	} else {
	   $sign = '+';
	}
	$tzoff = sprintf '%s%02d%02d',
			 $sign, int($tzoff / 3600), int($tzoff / 60) % 60;
	Language::PushLang('en');
	$headers .= 'Date: ' .
		    POSIX::strftime("%a, %d %b %Y %H:%M:%S $tzoff",
				    localtime $now) .
		    "\n";
	Language::PopLang();
    }

    unless ($header_ok{'to'}) {
	# Currently, bare e-mail address is assumed.  Complex ones such as
	# "phrase" <email> won't be allowed.
	if (ref ($rcpt)) {
	    if ($data->{'to'}) {
		$to = $data->{'to'};
	    }else {
		$to = join(",\n   ", @{$rcpt});
	    }
	}else{
	    $to = $rcpt;
	}   
	$headers .= "To: $to\n";
    }     
    unless ($header_ok{'from'}) {
	if (! defined $data->{'from'} or $data->{'from'} eq 'sympa' or
	    $data->{'from'} eq $data->{'conf'}{'sympa'}) {
	    $headers .= 'From: ' . &tools::addrencode(
		$data->{'conf'}{'sympa'},
		$data->{'conf'}{'email_gecos'},
		$data->{'charset'}
	    ) . "\n";
	} else {
	    $headers .= "From: ".MIME::EncWords::encode_mimewords(
		Encode::decode('utf8', $data->{'from'}),
		'Encoding' => 'A', 'Charset' => $data->{'charset'}, 'Field' => 'From'
		)."\n"; 
	}
    }
    unless ($header_ok{'subject'}) {
	$headers .= "Subject: ".MIME::EncWords::encode_mimewords(
	    Encode::decode('utf8', $data->{'subject'}),
	    'Encoding' => 'A', 'Charset' => $data->{'charset'}, 'Field' => 'Subject'
	    )."\n";
    }
    unless ($header_ok{'reply-to'}) { 
	$headers .= "Reply-to: ".MIME::EncWords::encode_mimewords(
	    Encode::decode('utf8', $data->{'replyto'}),
	    'Encoding' => 'A', 'Charset' => $data->{'charset'}, 'Field' => 'Reply-to'
	    )."\n" if ($data->{'replyto'})
    }
    if ($data->{'headers'}) {
	foreach my $field (keys %{$data->{'headers'}}) {
	    $headers .= $field.': '.MIME::EncWords::encode_mimewords(
		Encode::decode('utf8', $data->{'headers'}{$field}),
		'Encoding' => 'A', 'Charset' => $data->{'charset'}, 'Field' => $field
		)."\n";
	}
    }
    unless ($header_ok{'mime-version'}) {
	$headers .= "MIME-Version: 1.0\n";
    }
    unless ($header_ok{'content-type'}) {
	$headers .= "Content-Type: text/plain; charset=".$data->{'charset'}."\n";
    }
    unless ($header_ok{'content-transfer-encoding'}) {
	$headers .= "Content-Transfer-Encoding: 8bit\n"; 
    }
    ## Determine what value the Auto-Submitted header field should take
    ## See http://www.tools.ietf.org/html/draft-palme-autosub-01
    ## the header filed can have one of the following values : auto-generated, auto-replied, auto-forwarded
    ## The header should not be set when wwsympa sends a command/mail to sympa.pl through its spool
    unless ($data->{'not_auto_submitted'} ||  $header_ok{'auto_submitted'}) {
      ## Default value is 'auto-generated'
      my $header_value = $data->{'auto_submitted'} || 'auto-generated';
      $headers .= "Auto-Submitted: $header_value\n"; 
    }

    unless ($existing_headers) {
	$headers .= "\n";
   }
   
    ## All these data provide mail attachements in service messages
    my @msgs = ();
    if (ref($data->{'msg_list'}) eq 'ARRAY') {
	@msgs = map {$_->{'msg'} || $_->{'full_msg'}} @{$data->{'msg_list'}};
    } elsif ($data->{'spool'}) {
	@msgs = @{$data->{'spool'}};
    } elsif ($data->{'msg'}) {
	push @msgs, $data->{'msg'};
    } elsif ($data->{'msg_path'} and open IN, '<'.$data->{'msg_path'}) {
	push @msgs, join('', <IN>);
	close IN;
    } elsif ($data->{'file'} and open IN, '<'.$data->{'file'}) {
	push @msgs, join('', <IN>);
	close IN;
    }

    my $listname = ''; 
    if (ref($data->{'list'}) eq "HASH") {
	$listname = $data->{'list'}{'name'};
    } elsif ($data->{'list'}) {
	$listname = $data->{'list'};
    }

    unless ($message_as_string = &reformat_message("$headers"."$message_as_string", \@msgs, $data->{'charset'})) {
    	&Log::do_log('err', "mail::mail_file: Failed to reformat message");
    }
    my $dump = &Dumper($message_as_string); open (DUMP,">>/tmp/dumper2"); printf DUMP 'avant \n%s',$dump ; close DUMP;

    ## Set it in case it was not set
    $data->{'return_path'} ||= $robot->request;
    $message_as_string = get_sympa_headers({'rcpt' => $rcpt, 'from' => $robot->request}).$message_as_string;
    
    return $message_as_string if($return_message_as_string);

    my $message = new Message ({'messageasstring'=>$message_as_string});

    ## SENDING
    return undef unless (defined &sending('message' => $message,
					  'rcpt' => $rcpt,
					  'from' => $data->{'return_path'},
					  'robot' => $robot,
					  'listname' => $listname,
					  'priority' => $robot->sympa_priority,
					  'sign_mode' => $sign_mode,
					  'use_bulk' => $data->{'use_bulk'},
					  'dkim' => $data->{'dkim'},
					  )
			 );
    return 1;
}

####################################################
# public mail_message                              
####################################################
# distribute a message to a list, Crypting if needed
# 
# IN : -$message(+) : ref(Message)
#      -$from(+) : message from
#      -$robot(+) : robot
#      -{verp=>[on|off]} : a hash to introduce verp parameters, starting just on or off, later will probably introduce optionnal parameters 
#      -@rcpt(+) : recepients
#       
####################################################
sub mail_message {

    my %params = @_;
    my $message =  $params{'message'};
    my $list =  $params{'list'};
    my $verp = $params{'verp'};
    my @rcpt =  @{$params{'rcpt'}};
    my $dkim  =  $params{'dkim_parameters'};
    my $tag_as_last = $params{'tag_as_last'};
    my $robot = $list->robot;
    
    unless (defined $message && ref($message) eq 'Message') {
	&Log::do_log('err', 'Invalid message parameter');
	return undef;	
    }

    # normal return_path (ie used if verp is not enabled)
    my $from = $list->get_address('return_path');
    
    &Log::do_log('debug', 'mail::mail_message(from: %s, , file:%s, %s, verp->%s, %d rcpt, last: %s)', $from, $message->{'filename'}, $message->{'smime_crypted'}, $verp, $#rcpt+1, $tag_as_last);
    return 0 if ($#rcpt == -1);
    
    my($i, $j, $nrcpt, $size); 
    my $numsmtp = 0;
    
    ## If message contain a footer or header added by Sympa  use the object message else
    ## Extract body from original file to preserve signature
    my $msg_body; my $msg_header;
    $msg_header = $message->get_mime_message->head;
    ##if (!($message->{'protected'})) {
	##$msg_body = $message->get_mime_message->body_as_string;
    ##}elsif ($message->{'smime_crypted'}) {
	##$msg_body = ${$message->{'msg_as_string'}};
    ##}else{
	## Get body from original message body
	my @bodysection =split("\n\n",$message->get_message_as_string);  # convert it as a tab with headers as first element
	shift @bodysection;                                          # remove headers
	$msg_body = join ("\n\n",@bodysection);                      # convert it back as string
    ##}	
    $message->{'body_as_string'} = $msg_body ;
	
    my %rcpt_by_dom ;

    my @sendto;
    my @sendtobypacket;

    my $cmd_size = length($robot->sendmail) + 1 +
		   length($robot->sendmail_args) +
		   length(' -N success,delay,failure -V ') + 32 +
		   length(" -f $from ");
    my $db_type = Site->db_type;

    while (defined ($i = shift(@rcpt))) {
	my @k = reverse(split(/[\.@]/, $i));
	my @l = reverse(split(/[\.@]/, $j));

	my $dom;
	if ($i =~ /\@(.*)$/) {
	    $dom = $1;
	    chomp $dom;
	}
	$rcpt_by_dom{$dom} += 1 ;
	&Log::do_log('debug3',
	    'domain: %s ; rcpt by dom: %s ; limit for this domain: %s',
	    $dom, $rcpt_by_dom{$dom}, Site->nrcpt_by_domain->{$dom});

	if (
	    # number of recipients by each domain
	    (defined Site->nrcpt_by_domain->{$dom} and
	     $rcpt_by_dom{$dom} >= Site->nrcpt_by_domain->{$dom}) or
	    # number of different domains
	    ($j and $#sendto >= $robot->avg and
	     lc "$k[0] $k[1]" ne lc "$l[0] $l[1]") or
	    # number of recipients in general, and ARG_MAX limitation
	    ($#sendto >= 0 and
	     ($cmd_size + $size + length($i) + 5 > $max_arg or
	      $nrcpt >= $robot->nrcpt)) or
	    # length of recipients field stored into bulkmailer table
	    # (these limits might be relaxed by future release of Sympa)
	    ($db_type eq 'mysql' and $size + length($i) + 5 > 65535) or
	    ($db_type !~ /^(mysql|SQLite)$/ and $size + length($i) + 5 > 500)
	   ) {
	    undef %rcpt_by_dom;
	    # do not replace this line by "push @sendtobypacket, \@sendto" !!!
	    my @tab =  @sendto; push @sendtobypacket, \@tab;
	    $numsmtp++;
	    $nrcpt = $size = 0;
	    @sendto = ();
	}
	
	$nrcpt++; $size += length($i) + 5;
	push(@sendto, $i);
	$j = $i;
    }

    if ($#sendto >= 0) {
	$numsmtp++ ;
	my @tab =  @sendto ; push @sendtobypacket, \@tab ;# do not replace this line by push @sendtobypacket, \@sendto !!!
    }


    unless (&sendto('message' => $message,
		    'from' => $from,
		    'rcpt' => \@sendtobypacket,
		    'listname' => $list->name,
		    'priority' => $list->priority,
		    'delivery_date' => $list->get_next_delivery_date,
		    'robot' => $robot,
		    'encrypt' => $message->{'smime_crypted'},
		    'use_bulk' => 1,
		    'verp' => $verp,
		    'dkim' => $dkim,
		    'merge' => $list->merge_feature,
		    'tag_as_last' => $tag_as_last
		    )) {
	Log::do_log('err', 'Failed to send message to list %s', $list);
	return undef;
    }
    
    return $numsmtp;
}

####################################################
# public mail_forward                              
####################################################
# forward a message.
# 
# IN : -$mmessage(+) : ref(Message)
#      -$from(+) : message from
#      -$rcpt(+) : ref(SCALAR) | ref(ARRAY)  - recepients
#      -$robot(+) : ref(Robot)
# OUT : 1 | undef
#
####################################################
sub mail_forward {
    my $message = shift;
    my $from = shift;
    my $rcpt = shift;
    my $robot = Robot::clean_robot(shift, 1); #FIXME: may be Site?
    &Log::do_log('debug2', "mail::mail_forward($from,$rcpt)");
    
    unless (ref($message) eq 'Message') {
	&Log::do_log('err',"Unexpected parameter type: %s.",ref($message));
	return undef;
    }
    ## Add an Auto-Submitted header field according to  http://www.tools.ietf.org/html/draft-palme-autosub-01
    $message->get_mime_message->head->add('Auto-Submitted', 'auto-forwarded');
    
    unless (defined &sending('message' => $message, 
			     'rcpt' => $rcpt,
			     'from' => $from,
			     'robot' => $message->{'robot'},
			     'priority'=> $message->{'robot'}->request_priority,
			     )) {
	&Log::do_log('err','mail::mail_forward from %s impossible to send',$from);
	return undef;
    }   
    return 1;
}

#####################################################################
# public reaper                              
#####################################################################
# Non blocking function called by : mail::smtpto(), sympa::main_loop
#  task_manager::INFINITE_LOOP scanning the queue, 
#  bounced::infinite_loop scanning the queue, 
# just to clean the defuncts list by waiting to any processes and 
#  decrementing the counter. 
# 
# IN : $block
# OUT : $i 
#####################################################################
sub reaper {
   my $block = shift;
   my $i;

   $block = 1 unless (defined($block));
   while (($i = waitpid(-1, $block ? &POSIX::WNOHANG : 0)) > 0) {
      $block = 1;
      if (!defined($pid{$i})) {
         &Log::do_log('debug2', "Reaper waited $i, unknown process to me");
         next;
      }
      $opensmtp--;
      delete($pid{$i});
   }
   &Log::do_log('debug2', "Reaper unwaited pids : %s\nOpen = %s\n", join(' ', sort keys %pid), $opensmtp);
   return $i;
}
     

#################################### PRIVATE FUNCTIONS ##############################################

####################################################
# sendto                              
####################################################
# send messages, S/MIME encryption if needed, 
# grouped sending (or not if encryption)
#  
# IN: $message (+): Message object 
#     $from (+): message from
#     $rcpt(+) : ref(SCALAR) | ref(ARRAY) - message recepients
#     $listname : use only to format return_path if VERP on
#     $robot(+) : ref(Robot)
#     $encrypt : 'smime_crypted' | undef
#     $verp : 1| undef  
#     $use_bulk : if defined,  send message using bulk
#     
# OUT : 1 - call to sending
#       
####################################################
sub sendto {
    my %params = @_;
    
    my $message = $params{'message'};
    my $msg_header = $message->get_mime_message->head;
    my $msg_body = $message->{'body_as_string'};
    my $from = $params{'from'};
    my $rcpt = $params{'rcpt'};
    my $listname = $params{'listname'};    
    my $robot = Robot::clean_robot($params{'robot'}); # may not be Site
    my $priority =  $params{'priority'}; 
    my $encrypt = $params{'encrypt'};
    my $verp = $params{'verp'};
    my $merge = $params{'merge'};
    my $dkim = $params{'dkim'};
    my $use_bulk = $params{'use_bulk'};
    my $tag_as_last = $params{'tag_as_last'};

    &Log::do_log('debug', 'mail::sendto(from : %s,listname: %s, encrypt : %s, verp : %s, priority = %s, last: %s, use_bulk: %s', $from, $listname, $encrypt, $verp, $priority, $tag_as_last, $use_bulk);

    my $delivery_date =  $params{'delivery_date'};
    $delivery_date = time() unless $delivery_date; # if not specified, delivery tile is right now (used for sympa messages etc)

    my $msg;

    if ($encrypt eq 'smime_crypted') {
        # encrypt message for each rcpt and send the message
	# this MUST be moved to the bulk mailer. This way, merge will be applied after the SMIME encryption is applied ! This is a bug !
	foreach my $bulk_of_rcpt (@{$rcpt}) {
	    # trace foreach my $unique_rcpt (@{$bulk_of_rcpt}) {
	    foreach my $email (@{$bulk_of_rcpt}) {
		if ($email !~ /@/) {
		    &Log::do_log('err',"incorrect call for encrypt with incorrect number of recipient"); 
		    return undef;
		}
		unless ($message->smime_encrypt ($email)){
    		    &Log::do_log('err',"Failed to encrypt message"); 
		    return undef;
                }	

		unless (&sending('message' => $message,
				 'rcpt' => $email,
				 'from' => $from,
				 'listname' => $listname,
				 'robot' => $robot,
				 'priority' => $priority,
				 'delivery_date' =>  $delivery_date,
				 'use_bulk' => $use_bulk,
				 'tag_as_last' => $tag_as_last)) {
		    &Log::do_log('err',"Failed to send encrypted message"); 
		    return undef;
		}
		$tag_as_last = 0;
	    }    
	}
    }else{
	$message->{'msg_as_string'} = $msg_header->as_string . "\n" . $msg_body;   
	my $result = &sending('message' => $message,
			      'rcpt' => $rcpt,
			      'from' => $from,
			      'listname' => $listname,
			      'robot' => $robot,
			      'priority' => $priority,
			      'delivery_date' =>  $delivery_date,
			      'verp' => $verp,
			      'merge' => $merge,
			      'use_bulk' => $use_bulk,
			      'dkim' => $dkim,
			      'tag_as_last' => $tag_as_last);
	return $result;
	
    }
    return 1;
}

####################################################
# sending                              
####################################################
# send a message using smpto function or puting it
# in spool according to the context
# Signing if needed
# 
#  
# IN : -$msg(+) : ref(MIME::Entity) | string - message to send
#      -$rcpt(+) : ref(SCALAR) | ref(ARRAY) - recepients 
#       (for SMTP : "RCPT To:" field)
#      -$from(+) : for SMTP "MAIL From:" field , for 
#        spool sending : "X-Sympa-From" field
#      -$robot(+) : ref(Robot) | "Site"
#      -$listname : listname | ''
#      -$sign_mode(+) : 'smime' | 'none' for signing
#      -$verp 
#      -dkim : a hash for dkim parameters
#
# OUT : 1 - call to smtpto (sendmail) | 0 - push in spool
#           | undef
#  
####################################################
sub sending {
    my %params = @_;
    my $message = $params{'message'};
    my $rcpt = $params{'rcpt'};
    my $from = $params{'from'};
    my $robot = Robot::clean_robot($params{'robot'}, 1); # May be Site
    my $listname = $params{'listname'};
    my $sign_mode = $params{'sign_mode'};
    my $sympa_email =  $params{'sympa_email'};
    my $priority_message =  $params{'priority'};
    my $priority_packet = $robot->sympa_packet_priority;
    my $delivery_date = $params{'delivery_date'};
    $delivery_date = time() unless ($delivery_date); 
    my $verp  =  $params{'verp'};
    my $merge  =  $params{'merge'};
    my $use_bulk = $params{'use_bulk'};
    my $dkim = $params{'dkim'};
    my $tag_as_last = $params{'tag_as_last'};
    my $sympa_file;
    my $fh;
    my $signed_msg; # if signing

    if ($sign_mode eq 'smime') {
	if ($signed_msg = &tools::smime_sign($message->get_mime_message, $listname, $robot)) {
	    $message->{'msg'} = $signed_msg->dup;
	}else{
	    &Log::do_log('notice', 'mail::sending : unable to sign message from %s', $listname);
	    return undef;
	}
    }
    # my $msg_id = $message->get_mime_message->head->get('Message-ID'); chomp $msg_id;

    my $verpfeature = (($verp eq 'on')||($verp eq 'mdn')||($verp eq 'dsn'));
    my $trackingfeature ;
    if (($verp eq 'mdn')||($verp eq 'dsn')) {
	$trackingfeature = $verp;
    }else{
	$trackingfeature ='';
    }
    my $mergefeature = ($merge eq 'on');
    
    if ($use_bulk){ # in that case use bulk tables to prepare message distribution 
	##Bulk package determine robots or site by its name.
	##FIXME: Would '*' be correct?
	my $robot_id;
	if (ref $robot and ref $robot eq 'Robot') {
	    $robot_id = $robot->name;
	} elsif ($robot eq 'Site') {
	    $robot_id = '*';
	}
	my $bulk_code = &Bulk::store('message' => $message,
				     'rcpts' => $rcpt,
				     'from' => $from,
				     'robot' => $robot_id,
				     'listname' => $listname,
				     'priority_message' => $priority_message,
				     'priority_packet' => $priority_packet,
				     'delivery_date' => $delivery_date,
				     'verp' => $verpfeature,
				     'tracking' => $trackingfeature,
				     'merge' => $mergefeature,
				     'dkim' => $dkim,
				     'tag_as_last' => $tag_as_last,
				     );
	
	unless (defined $bulk_code) {
	    &Log::do_log('err', 'Failed to store message for list %s', $listname);
	    $robot->send_notify_to_listmaster(
		'bulk_error',  {'listname' => $listname});
	    return undef;
	}
    }elsif(defined $send_spool) { # in context wwsympa.fcgi do not send message to reciepients but copy it to standard spool 
	&Log::do_log('trace',"NOT USING SPOOLER");

	my $message_as_string = $message->get_message_as_string;
	unless($message->get_mime_message->head->get('X-Sympa-To')) {
	    $message_as_string = get_sympa_headers({'rcpt' => $rcpt, 'from' => $from}).$message_as_string;
	}
	my $message = new Message ({'messageasstring' => $message_as_string});
	my %meta;
	$meta{'date'} = time;
	$meta{'robot'} = $message->{'robot_id'} if $message->{'robot_id'};
	$meta{'list'} = $message->{'list'}{'name'} if $message->{'list'};
	if ($message->{'priority'}) {
	    $meta{'priority'} = $message->{'priority'} ;
	}else{ 
	    $meta{'priority'} = 1;
	}
	$meta{'type'} = $message->{'type'} if $message->{'type'};
	
	my $msgspool = new Sympaspool('msg');
	
	my $messagekey = $msgspool->store($message_as_string,\%meta);
	unless($messagekey) {
	    Log::do_log('err',"Could not store message from %s to %s in db spool",$rcpt, $from);
	    return undef;
	}

	##$sympa_email = $robot->sympa;
	##$sympa_file = "$send_spool/T.$sympa_email.".time.'.'.int(rand(10000));
	##unless (open TMP, ">$sympa_file") {
	    ##&Log::do_log('notice', 'mail::sending Cannot create %s : %s', $sympa_file, $!);
	    ##return undef;
	##}
	##
	##my $all_rcpt;
	##if (ref($rcpt) eq 'SCALAR') {
	    ##$all_rcpt = $$rcpt;
	##}elsif (ref($rcpt) eq 'ARRAY') {
	    ##$all_rcpt = join(',', @{$rcpt});
	##}else {
	    ##$all_rcpt = $rcpt;
	##}
	##printf TMP "X-Sympa-To: %s\n", $all_rcpt;
	##printf TMP "X-Sympa-From: %s\n", $from;
	##printf TMP "X-Sympa-Checksum: %s\n", &tools::sympa_checksum($all_rcpt);
##
	##print TMP $message->{'msg_as_string'} ;
	##close TMP;
	##my $new_file = $sympa_file;
	##$new_file =~ s/T\.//g;
	##
	##unless (rename $sympa_file, $new_file) {
	    ##&Log::do_log('notice', 'Cannot rename %s to %s : %s', $sympa_file, $new_file, $!);
	    ##return undef;
	##}
    }else{ # send it now
	&Log::do_log('debug',"NOT USING BULK");
	*SMTP = &smtpto($from, $rcpt, $robot);	
	print SMTP $message->get_mime_message->as_string ;	
	unless (close SMTP) {
	    &Log::do_log('err', 'could not close safefork to sendmail');
	    return undef;
	};
    }	
    return 1;
}

##################################################################################
# smtpto                               
##################################################################################
# Makes a sendmail ready for the recipients given as argument, uses a file 
# descriptor in the smtp table which can be imported by other parties. 
# Before, waits for number of children process < number allowed by sympa.conf
# 
# IN : $from :(+) for SMTP "MAIL From:" field
#      $rcpt :(+) ref(SCALAR)|ref(ARRAY)- for SMTP "RCPT To:" field
#      $robot :(+) ref(Robot) | "Site"
#      $msgkey : a id of this message submission in notification table
# OUT : mail::$fh - file handle on opened file for ouput, for SMTP "DATA" field
#       | undef
#
##################################################################################
sub smtpto {
    Log::do_log('debug2', '(%s, %s, %s, %s, %s)', @_);
    my $from = shift;
    my $rcpt = shift;
    my $robot = Robot::clean_robot(shift, 1);
    my $msgkey = shift;
    my $sign_mode = shift;

   unless ($from) {
       &Log::do_log('err', 'Missing Return-Path in mail::smtpto()');
   }

   if (ref($rcpt) eq 'SCALAR') {
       &Log::do_log('debug2', 'mail::smtpto(%s, %s, %s )', $from, $$rcpt,$sign_mode);
   }elsif (ref($rcpt) eq 'ARRAY')  {
       &Log::do_log('debug2', 'mail::smtpto(%s, %s, %s)', $from, join(',', @{$rcpt}), $sign_mode);
   }
  
   my($pid, $str);
   
   ## Escape "-" at beginning of recepient addresses
   ## prevent sendmail from taking it as argument
   
   if (ref($rcpt) eq 'SCALAR') {
       $$rcpt =~ s/^-/\\-/;
   }elsif (ref($rcpt) eq 'ARRAY') {
       my @emails = @$rcpt;
       foreach my $i (0..$#emails) {
	   $rcpt->[$i] =~ s/^-/\\-/;
       }
   }
   
   ## Check how many open smtp's we have, if too many wait for a few
   ## to terminate and then do our job.

   &Log::do_log('debug3',"Open = $opensmtp");
   while ($opensmtp > $robot->maxsmtp) {
       &Log::do_log('debug3',"mail::smtpto: too many open SMTP ($opensmtp), calling reaper" );
       last if (&reaper(0) == -1); ## Blocking call to the reaper.
       }
    
   *IN = ++$fh; *OUT = ++$fh;
   

   if (!pipe(IN, OUT)) {
       &Log::fatal_err(sprintf gettext("Unable to create a channel in smtpto: %s"), "$!"); ## No return
   }
   $pid = &tools::safefork();
   $pid{$pid} = 0;
       
   my $sendmail = $robot->sendmail;
   my $sendmail_args = $robot->sendmail_args;
   if ($msgkey) {
       $sendmail_args .= ' -N success,delay,failure -V '.$msgkey;
   }
   if ($pid == 0) {

       close(OUT);
       open(STDIN, "<&IN");

	$from = '' if $from eq '<>'; # null sender
       if (! ref($rcpt)) {
	   exec $sendmail, split(/\s+/,$sendmail_args),'-f', $from, $rcpt;
       }elsif (ref($rcpt) eq 'SCALAR') {
	   exec $sendmail, split(/\s+/,$sendmail_args), '-f', $from, $$rcpt;
       }elsif (ref($rcpt) eq 'ARRAY'){
	   exec $sendmail, split(/\s+/,$sendmail_args), '-f', $from, @$rcpt;
       }

	exit 1; ## Should never get there.
       }
   if ($main::options{'mail'}) {
       $str = "safefork: $sendmail $sendmail_args -f '$from' ";
       if (! ref($rcpt)) {
	   $str .= $rcpt;
       }elsif (ref($rcpt) eq 'SCALAR') {
	   $str .= $$rcpt;
       }else {
	   $str .= join(' ', @$rcpt);
       }
       &Log::do_log('notice', '%s', $str);
   }
   unless (close(IN)){
       &Log::do_log('err',"mail::smtpto: could not close safefork" );
       return undef;
   }
   $opensmtp++;
   select(undef, undef,undef, 0.3) if $opensmtp < $robot->maxsmtp;
   return("mail::$fh"); ## Symbol for the write descriptor.
}

sub get_sympa_headers {
    my $data = shift;
    
    my $all_rcpt;
    if (ref($data->{'rcpt'}) eq 'SCALAR') {
	$all_rcpt = ${$data->{'rcpt'}};
    }elsif (ref($data->{'rcpt'}) eq 'ARRAY') {
	$all_rcpt = join(',', @{$data->{'rcpt'}});
    }else {
	$all_rcpt = $data->{'rcpt'};
    }

    my $sympa_headers = sprintf "X-Sympa-To: %s\n", $all_rcpt;
    $sympa_headers .= sprintf "X-Sympa-From: %s\n", $data->{'from'};
    $sympa_headers .= sprintf "X-Sympa-Checksum: %s\n", &tools::sympa_checksum($all_rcpt);

    return $sympa_headers;
}

####################################################
# send_in_spool      : not used but if needed ...
####################################################
# send a message by putting it in global $send_spool
#   
# IN : $rcpt (+): ref(SCALAR)|ref(ARRAY) - recepients
#      $robot(+) : ref(Robot) | "Site"
#      $sympa_email : for the file name
#      $XSympaFrom : for "X-Sympa-From" field
# OUT : $return->
#        -filename : name of temporary file 
#         needing to be renamed
#        -fh : file handle opened for writing
#         on 
####################################################
sub send_in_spool {
    my ($rcpt,$robot,$sympa_email,$XSympaFrom) = @_;
    &Log::do_log('debug3', 'mail::send_in_spool(%s,%s, %s)',$XSympaFrom,$rcpt);
    
    $sympa_email ||= $robot->sympa;
    $XSympaFrom ||= $robot->sympa;

    my $sympa_file = "$send_spool/T.$sympa_email.".time.'.'.int(rand(10000));
    
    my $all_rcpt;
    if (ref($rcpt) eq "ARRAY") {
	$all_rcpt = join (',', @$rcpt);
    } else {
	$all_rcpt = $$rcpt;
       }
    
    unless (open TMP, ">$sympa_file") {
	&Log::do_log('notice', 'Cannot create %s : %s', $sympa_file, $!);
	return undef;
   }

    printf TMP "X-Sympa-To: %s\n", $all_rcpt;
    printf TMP "X-Sympa-From: %s\n", $XSympaFrom;
    printf TMP "X-Sympa-Checksum: %s\n", &tools::sympa_checksum($all_rcpt);
    
    my $return;
    $return->{'filename'} = $sympa_file;     
    $return->{'fh'} = \*TMP;

    return $return;
}

#####################################################################


####################################################
# reformat_message
####################################################
# Reformat bodies of text parts contained in the message using
# recommended encoding schema and/or charsets defined by MIME::Charset.
#
# MIME-compliant headers are appended / modified.  And custom X-Mailer:
# header is appended :).
#
# IN : $msg: ref(MIME::Entity) | string - message to reformat
#      $attachments: ref(ARRAY) - messages to be attached as subparts.
# OUT : string
#
####################################################

####################################################
## Comments from Soji Ikeda below
##  Some paths of message processing in Sympa can't recognize Unicode strings.  
##  At least MIME::Parser::parse_data() and Template::proccess(): these methods 
## occationalily break strings containing Unicode characters.
##  
##  My mail_utf8 patch expects the behavior as following ---
##
##  Sub-messages to be attached (into digests, moderation notices etc.) will passed 
##  to mail::reformat_message() separately then attached to reformatted parent message
##  again.  As a result, sub-messages won't be broken.  Since they won't cause mixture 
##  of Unicode string (parent message generated by tt2::parse_tt2()) and byte string (sub-messages).
##
##  Note: For compatibility with old style, data passed to mail::reformat_message() already includes 
##  sub-message(s).  Then:
##   - When a part has an `X-Sympa-Attach:' header field for internal use, new style, 
##     mail::reformat_message() attaches raw sub-message to reformatted parent message again;
##   - When a part doesn't have any `X-Sympa-Attach:' header fields, sub-messages generated by 
##     [% INSERT %] directive(s) in the template will be used.
##
##  More Note: Latter behavior above will give expected result only if contents of sub-messages are 
##  US-ASCII or ISO-8859-1. In other cases customized templates (if any) should be modified so that they 
##  have appropriate `X-Sympa-Attach:' header fileds.
##
##  Sub-messages are gathered from template context paramenters.

sub reformat_message($;$$) {
    my $message = shift;
    my $attachments = shift || [];
    my $defcharset = shift;
    my $msg;

    my $parser = new MIME::Parser;
    unless (defined $parser) {
	&Log::do_log('err', "mail::reformat_message: Failed to create MIME parser");
	return undef;
    }
    $parser->output_to_core(1);

    if (ref($message) eq 'MIME::Entity') {
	$msg = $message;
    } else {
	eval {
	    $msg = $parser->parse_data($message);
	};
	if ($@) {
	    &Log::do_log('err', "mail::reformat_message: Failed to parse MIME data");
	    return undef;
	}
    }
    $msg->head->delete("X-Mailer");
    $msg = &fix_part($msg, $parser, $attachments, $defcharset);
    $msg->head->add("X-Mailer", sprintf "Sympa %s", Sympa::Constants::VERSION);
    return $msg->as_string;
}

sub fix_part($$$$) {
    my $part = shift;
    my $parser = shift;
    my $attachments = shift || [];
    my $defcharset = shift;
    return $part unless $part;

    my $enc = $part->head->mime_attr("Content-Transfer-Encoding");
    # Parts with nonstandard encodings aren't modified.

    if ($enc and $enc !~ /^(?:base64|quoted-printable|[78]bit|binary)$/i) {
	return $part;
    }
    my $eff_type = $part->effective_type;
    
    if ($eff_type =~ m{^multipart/(signed|encrypted)$}){
	return $part;
    }
    
    if ($part->head->get('X-Sympa-Attach')) { # Need re-attaching data.
	
	my $data = shift @{$attachments};
	if (ref($data) ne 'MIME::Entity') {
	    eval {
		$data = $parser->parse_data($data);
	    };
	    if ($@) {
		&Log::do_log('notice',"Failed to parse MIME data");
		$data = $parser->parse_data('');
	    }
	}
	$part->head->delete('X-Sympa-Attach');
	$part->parts([$data]);
    } elsif ($part->parts) {
	my @newparts = ();
	foreach ($part->parts) {
	    push @newparts, &fix_part($_, $parser, $attachments, $defcharset);
	}
	$part->parts(\@newparts);
    } elsif ($eff_type =~ m{^(?:multipart|message)(?:/|\Z)}i) {
	# multipart or message types without subparts.
	
	return $part;
    } elsif (MIME::Tools::textual_type($eff_type)) {
	my $bodyh = $part->bodyhandle;
	# Encoded body or null body won't be modified.
	return $part if !$bodyh or $bodyh->is_encoded;
	
	my $head = $part->head;
	my $body = $bodyh->as_string;
	my $wrap = $body;
	if ($head->get('X-Sympa-NoWrap')) { # Need not wrapping
	    $head->delete('X-Sympa-NoWrap');
	} elsif ($eff_type eq 'text/plain' and
		 lc($head->mime_attr('Content-type.Format')||'') ne 'flowed') {
	    $wrap = &tools::wrap_text($body);
	}
	my $charset = $head->mime_attr("Content-Type.Charset") || $defcharset;

	my ($newbody, $newcharset, $newenc) = 
	    MIME::Charset::body_encode(Encode::decode('utf8', $wrap), $charset,
				       Replacement => 'FALLBACK');
	if ($newenc eq $enc and $newcharset eq $charset and
	    $newbody eq $body) {
	    $head->add("MIME-Version", "1.0") unless $head->get("MIME-Version");
	    return $part;
	}

	# Fix headers and body.
	$head->mime_attr("Content-Type", "TEXT/PLAIN")
	    unless $head->mime_attr("Content-Type");
	$head->mime_attr("Content-Type.Charset", $newcharset);
	$head->mime_attr("Content-Transfer-Encoding", $newenc);
	$head->add("MIME-Version", "1.0") unless $head->get("MIME-Version"); 
	my $io = $bodyh->open("w");

	unless (defined $io) {
	    &Log::do_log('err', "mail::reformat_message: Failed to save message : $!");
	    return undef;
	}

	$io->print($newbody);
	$io->close;
	$part->sync_headers(Length => 'COMPUTE');
    } else {
	# Binary or text with long lines will be suggested to be BASE64.
	$part->head->mime_attr("Content-Transfer-Encoding",
			       $part->suggest_encoding);
	$part->sync_headers(Length => 'COMPUTE');
    }
    return $part;
}

1;
