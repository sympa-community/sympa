# Bulk.pm - This module includes bulk mailer subroutines
#
# Sympa - SYsteme de Multi-Postage Automatique
# Copyrigh (c) 1997, 1998, 1999, 2000, 2001 Comite Reseau des Universites
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
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

package Bulk;

use strict;

#use Carp; # currently not used
use Encode;
#use Time::HiRes qw(time); # For more precise date; currently not used
use MIME::Base64;
use MIME::Charset;
use Sys::Hostname;
use URI::Escape;
use constant MAX => 100_000;
# tentative
use Data::Dumper;

#use List;
##The line above was removed to avoid dependency loop.
##"use List" MUST precede to "use Bulk".

#use tools; # used in List - Site - Conf
#use tt2; # used in List
use Language qw(gettext_strftime);
#use Log; # used in Conf
#use SDM; # used in Conf
use Sympaspool;

## Database and SQL statement handlers
my $sth;


# last message stored in spool, this global var is used to prevent multiple stored of the same message in spool table 
my $last_stored_message_key;

# create an empty Bulk
#sub new {
#    my $pkg = shift;
#    my $packet = &Bulk::next();;
#    bless \$packet, $pkg;
#    return $packet
#}
## 
# get next packet to process, order is controled by priority_message, then by priority_packet, then by creation date.
# Packets marked as being sent with VERP will be treated last.
# Next lock the packetb to prevent multiple proccessing of a single packet 

sub next {
    Log::do_log('debug2', '()');

    # lock next packet
    my $lock = &tools::get_lockname();

    my $order;
    my $limit_oracle='';
    my $limit_sybase='';
	## Only the first record found is locked, thanks to the "LIMIT 1" clause
    $order = 'ORDER BY priority_message_bulkmailer ASC, priority_packet_bulkmailer ASC, reception_date_bulkmailer ASC, verp_bulkmailer ASC';
    if (Site->db_type eq 'mysql' or Site->db_type eq 'Pg' or
	Site->db_type eq 'SQLite') {
	$order.=' LIMIT 1';
    } elsif (Site->db_type eq 'Oracle') {
	$limit_oracle = 'AND rownum<=1';
    } elsif (Site->db_type eq 'Sybase') {
	$limit_sybase = 'TOP 1';
    }

    # Select the most prioritary packet to lock.
    unless ($sth = &SDM::do_prepared_query( sprintf("SELECT %s messagekey_bulkmailer AS messagekey, packetid_bulkmailer AS packetid FROM bulkmailer_table WHERE lock_bulkmailer IS NULL AND delivery_date_bulkmailer <= ? %s %s",$limit_sybase, $limit_oracle, $order), int(time()))) {
	&Log::do_log('err','Unable to get the most prioritary packet from database');
	return undef;
    }

    my $packet;
    unless($packet = $sth->fetchrow_hashref('NAME_lc')){	
	$sth->finish;
	return undef;
    }
    $sth->finish;

    # Lock the packet previously selected.
    unless ($sth = SDM::do_prepared_query(
	q{UPDATE bulkmailer_table
	  SET lock_bulkmailer = ?
	  WHERE messagekey_bulkmailer = ? AND packetid_bulkmailer = ? AND
		lock_bulkmailer IS NULL},
	$lock, $packet->{'messagekey'}, $packet->{'packetid'}
    )) {
	Log::do_log('err',
	    'Unable to lock packet %s for message %s',
	    $packet->{'packetid'}, $packet->{'messagekey'}
	);
	return undef;
    }
    
    if ($sth->rows < 0) {
	Log::do_log('err',
	    'Unable to lock packet %s for message %s, though the query succeeded',
	    $packet->{'packetid'}, $packet->{'messagekey'}
	);
	return undef;
    }
    unless ($sth->rows) {
	Log::do_log('info','Bulk packet is already locked');
	return undef;
    }

    # select the packet that has been locked previously
    unless ($sth = &SDM::do_query( "SELECT messagekey_bulkmailer AS messagekey, messageid_bulkmailer AS messageid, packetid_bulkmailer AS packetid, receipients_bulkmailer AS receipients, returnpath_bulkmailer AS returnpath, listname_bulkmailer AS listname, robot_bulkmailer AS robot, priority_message_bulkmailer AS priority_message, priority_packet_bulkmailer AS priority_packet, verp_bulkmailer AS verp, tracking_bulkmailer AS tracking, merge_bulkmailer as merge, reception_date_bulkmailer AS reception_date, delivery_date_bulkmailer AS delivery_date FROM bulkmailer_table WHERE lock_bulkmailer=%s %s",&SDM::quote($lock), $order)) {
	&Log::do_log('err','Unable to retrieve informations for packet %s of message %s',$packet->{'packetid'}, $packet->{'messagekey'});
	return undef;
    }
    
    my $result = $sth->fetchrow_hashref('NAME_lc');

    ## add objects
    my $robot_id = $result->{'robot'};
    my $listname = $result->{'listname'};
    my $robot;

    if ($robot_id and $robot_id ne '*') {
	$robot = Robot->new($robot_id);
    }
    if ($robot) {
	if ($listname and length $listname) {
	    $result->{'list_object'} = List->new($listname, $robot);
	}
	$result->{'robot_object'} = $robot;
    }
   
    return $result;
}


# remove a packet from database by packet id. return undef if packet does not exist

sub remove {
    my $messagekey = shift;
    my $packetid= shift;

    &Log::do_log('debug', "Bulk::remove(%s,%s)",$messagekey,$packetid);

    unless ($sth = &SDM::do_query( "DELETE FROM bulkmailer_table WHERE packetid_bulkmailer = %s AND messagekey_bulkmailer = %s",&SDM::quote($packetid),&SDM::quote($messagekey))) {
	&Log::do_log('err','Unable to delete packet %s of message %s', $packetid,$messagekey);
	return undef;
    }
    return $sth;
}

sub messageasstring {
    my $messagekey = shift;
    &Log::do_log('debug', 'Bulk::messageasstring(%s)',$messagekey);
    
    unless ($sth = &SDM::do_query( "SELECT message_bulkspool AS message FROM bulkspool_table WHERE messagekey_bulkspool = %s",&SDM::quote($messagekey))) {
	&Log::do_log('err','Unable to retrieve message %s text representation from database', $messagekey);
	return undef;
    }

    my $messageasstring = $sth->fetchrow_hashref('NAME_lc') ;

    unless ($messageasstring ){
	&Log::do_log('err',"could not fetch message $messagekey from spool");
	return undef;
    }
    my $msg = MIME::Base64::decode($messageasstring->{'message'});
    unless ($msg){
	&Log::do_log('err',"could not decode message $messagekey extracted from spool (base64)"); 
	return undef;
    }
    return $msg;
}
#################################"
# fetch message from bulkspool_table by key 
#
sub message_from_spool {
    my $messagekey = shift;
    &Log::do_log('debug', '(messagekey : %s)',$messagekey);
    
    unless ($sth = &SDM::do_query( "SELECT message_bulkspool AS message, messageid_bulkspool AS messageid, dkim_d_bulkspool AS  dkim_d,  dkim_i_bulkspool AS  dkim_i, dkim_privatekey_bulkspool AS dkim_privatekey, dkim_selector_bulkspool AS dkim_selector FROM bulkspool_table WHERE messagekey_bulkspool = %s",&SDM::quote($messagekey))) {
	&Log::do_log('err','Unable to retrieve message %s full data from database', $messagekey);
	return undef;
    }

    my $message_from_spool = $sth->fetchrow_hashref('NAME_lc') ;
    $sth->finish;

    return({'messageasstring'=> MIME::Base64::decode($message_from_spool->{'message'}),
	    'messageid' => $message_from_spool->{'messageid'},
	    'dkim_d' => $message_from_spool->{'dkim_d'},
	    'dkim_i' => $message_from_spool->{'dkim_i'},
	    'dkim_selector' => $message_from_spool->{'dkim_selector'},
	    'dkim_privatekey' => $message_from_spool->{'dkim_privatekey'},});

}

############################################################
#  merge_msg                                               #
############################################################
#  Merge a message with custom attributes of a user.       #
#                                                          #
#                                                          #
#  IN : - MIME::Entity                                     #
#       - $rcpt : a recipient                              #
#       - $bulk : HASH                                     #
#       - $data : HASH with user's data                    #
#  OUT : 1 | undef                                         #
#                                                          #
############################################################
## OBSOLETED: Use Message::personalize().
sub merge_msg {
    my $entity = shift;
    my $rcpt   = shift;
    my $bulk   = shift;
    my $data   = shift;

    unless (ref $entity eq 'MIME::Entity') {
	Log::do_log('err', 'false entity');
	return undef;
    }

    my $enc = $entity->head->mime_encoding;
    # Parts with nonstandard encodings aren't modified.
    if ($enc and $enc !~ /^(?:base64|quoted-printable|[78]bit|binary)$/i) {
	return $entity;
    }
    my $eff_type = $entity->effective_type || 'text/plain';
    # Signed or encrypted parts aren't modified.
    if ($eff_type =~ m{^multipart/(signed|encrypted)$}){
	return $entity;
    }

    if ($entity->parts) {
	foreach my $part ($entity->parts) {
	    unless (merge_msg($part, $rcpt, $bulk, $data)) {
		Log::do_log('err', 'Failed to merge message part');
		return undef;
	    }
	}
    } elsif ($eff_type =~ m{^(?:multipart|message)(?:/|\Z)}i) {
	# multipart or message types without subparts.
	return $entity;
    } elsif (MIME::Tools::textual_type($eff_type)) {
	my ($charset, $in_cset, $bodyh, $body, $utf8_body);

	$bodyh = $entity->bodyhandle;
	# Encoded body or null body won't be modified.
	if (!$bodyh or $bodyh->is_encoded) {
	    return $entity;
	}

	$body = $bodyh->as_string;
	unless (defined $body and length $body) {
	    return $entity;
	}

	## Detect charset.  If charset is unknown, detect 7-bit charset.
	$charset = $entity->head->mime_attr('Content-Type.Charset');
	$in_cset = MIME::Charset->new($charset || 'NONE');
	unless ($in_cset->decoder) {
	    $in_cset = MIME::Charset->new(
		MIME::Charset::detect_7bit_charset($body) || 'NONE');
	}
	unless ($in_cset->decoder) {
	    Log::do_log('err', 'Unknown charset "%s"', $charset);
	    return undef;
	}
	$in_cset->encoder($in_cset); # no charset conversion

	## Only decodable bodies are allowed.
	eval { $utf8_body = Encode::encode_utf8($in_cset->decode($body, 1)); };
	if ($@) {
	    Log::do_log('err', 'Cannot decode by charset "%s"', $charset);
	    return undef;
	}

	## PARSAGE ##

	my $message_output;
	unless (
	    merge_data(
		'rcpt'           => $rcpt,
		'messageid'      => $bulk->{'messageid'},
		'listname'       => $bulk->{'listname'},
		'robot'          => $bulk->{'robot'},
		'data'           => $data,
		'body'           => $utf8_body,
		'message_output' => \$message_output,
	    )
	    ) {
	    Log::do_log('err', 'error merging message');
	    return undef;
	}
	$utf8_body = $message_output;

	## Data not encodable by original charset will fallback to UTF-8.
	my ($newcharset, $newenc);
	($body, $newcharset, $newenc) =
	    $in_cset->body_encode(Encode::decode_utf8($utf8_body),
	    Replacement => 'FALLBACK');
	unless ($newcharset) { # bug in MIME::Charset?
	    Log::do_log('err', 'Can\'t determine output charset');
	    return undef;
	} elsif ($newcharset ne $in_cset->as_string) {
	    $entity->head->mime_attr(
		'Content-Transfer-Encoding' => $newenc);
	    $entity->head->mime_attr('Content-Type.Charset' => $newcharset);

	    ## normalize newline to CRLF if transfer-encoding is BASE64.
	    $body =~ s/\r\n|\r|\n/\r\n/g
		if $newenc and $newenc eq 'BASE64';
	} else {
	    ## normalize newline to CRLF if transfer-encoding is BASE64.
	    $body =~ s/\r\n|\r|\n/\r\n/g
		if $enc and uc $enc eq 'BASE64';
	}

	## Save new body.
	my $io = $bodyh->open('w');
	unless ($io and
	    $io->print($body) and
	    $io->close) {
	    Log::do_log('err', 'Can\'t write in Entity: %s', $!);
	    return undef;
	}
	$entity->sync_headers(Length => 'COMPUTE')
	    if $entity->head->get('Content-Length');

	return $entity;
    }

    return $entity;
}

############################################################
#  merge_data                                              #
############################################################
#  This function retrieves the customized data of the      #
#  users then parse the message. It returns the message    #
#  personalized to bulk.pl                                 #
#  It uses the method &tt2::parse_tt2                      #
#  It uses the method &tools::get_fingerprint              #
#                                                          #
# IN : - rcpt : the recipient email                        #
#      - listname : the name of the list                   #
#      - robot_id : the host                               #
#      - data : HASH with many data                        #
#      - body : message with the TT2                       #
#      - message_output : object, IO::Scalar               #
#                                                          #
# OUT : - message_output : customized message              #
#     | undef                                              #
#                                                          #
############################################################ 
## OBSOLETED: Use Message::personalize_text().
sub merge_data {

    my %params = @_;
    my $rcpt = $params{'rcpt'},
    my $listname = $params{'listname'},
    my $robot_id = $params{'robot'},
    my $data = $params{'data'},
    my $body = $params{'body'},
    my $message_output = $params{'message_output'},
    
    my $options;
    $options->{'is_not_template'} = 1;

    my $list = new List($listname,$robot_id);
    my $user = $list->user('member',$rcpt);

    $user->{'escaped_email'} = &URI::Escape::uri_escape($rcpt);
    $user->{'friendly_date'} = gettext_strftime("%d %b %Y  %H:%M", localtime($user->{'date'}));

    # this method as been removed because some users may forward authentication link
    # $user->{'fingerprint'} = &tools::get_fingerprint($rcpt);

    $data->{'user'} = $user;
    $data->{'robot'} = $robot_id;
    $data->{'listname'} = $listname;

    # Parse the TT2 in the message : replace the tags and the parameters by the corresponding values
    unless (&tt2::parse_tt2($data,\$body, $message_output, '', $options)) {
	&Log::do_log('err','Unable to parse body : "%s"', \$body);
	return undef;
    }

    return 1;
}

## 
sub store { 
    my %data = @_;
    
    my $message = $data{'message'};
    my $msg_id = $message->{'msg'}->head->get('Message-ID'); chomp $msg_id;
    my $rcpts = $data{'rcpts'};
    my $from = $data{'from'};
    my $robot = Robot::clean_robot($data{'robot'}, 1); # maybe Site
    my $listname = $data{'listname'};
    my $priority_message = $data{'priority_message'};
    my $priority_packet = $data{'priority_packet'};
    my $delivery_date = $data{'delivery_date'};
    my $verp  = $data{'verp'};
    my $tracking  = $data{'tracking'};
    $tracking  = '' unless (($tracking  eq 'dsn')||($tracking  eq 'mdn'));
    $verp=0 unless($verp);
    my $merge  = $data{'merge'};
    $merge=0 unless($merge);
    my $dkim = $data{'dkim'};
    my $tag_as_last = $data{'tag_as_last'};

    &Log::do_log('trace', 'Bulk::store(<msg>,rcpts: %s,from = %s,robot = %s,listname= %s,priority_message = %s, delivery_date= %s,verp = %s, tracking = %s, merge = %s, dkim: d= %s i=%s, last: %s)',$rcpts,$from,$robot,$listname,$priority_message,$delivery_date,$verp,$tracking, $merge,$dkim->{'d'},$dkim->{'i'},$tag_as_last);


    $priority_message = $robot->sympa_priority unless $priority_message;
    $priority_packet = $robot->sympa_packet_priority unless $priority_packet;
    
    my $msg;
    if ($message->is_crypted) {
	$msg = $message->get_encrypted_mime_message->as_string;
    }elsif ($message->is_signed) {
	$msg = $message->get_message_as_string;
    }else{
	$msg = $message->get_mime_message->as_string;
    }
    my $message_sender = $message->get_sender_email();

    # first store the message in spool_table 
    # because as soon as packet are created bulk.pl may distribute the
    # $last_stored_message_key is a global var used in order to detect if a message as been already stored    
    my $message_already_on_spool ;
    my $bulkspool = new Sympaspool ('bulk');

    if (($last_stored_message_key) && ($message->{'messagekey'} eq $last_stored_message_key)) {
	$message_already_on_spool = 1;
    }else{
	my $lock = $$.'@'.hostname() ;
	if ($message->{'messagekey'}) {
	    # move message to spool bulk and keep it locked
	    $bulkspool->update({'messagekey'=>$message->{'messagekey'}},{'messagelock'=>$lock,'spoolname'=>'bulk','message' => $msg});
	}else{
	    $message->{'messagekey'} = $bulkspool->store($msg,
							 {'dkim_d'=>$dkim->{d},
							  'dkim_i'=>$dkim->{i},
							  'dkim_selector'=>$dkim->{selector},
							  'dkim_privatekey'=>$dkim->{private_key},
							  'dkim_header_list'=>$dkim->{header_list}},
							 $lock);
	    unless($message->{'messagekey'}) {
		Log::do_log('err',"could not store message in spool distribute, message lost ?");
		return undef;
	    }
	}
	$last_stored_message_key = $message->{'messagekey'};
	
	#log in stat_table to make statistics...
	my $robot_domain = $robot->domain;
	unless (index($message_sender, "$robot_domain\@") >= 0) {
	    #ignore messages sent by robot
	    unless (index($message_sender, "$listname-request") >= 0) {
		#ignore messages of requests			
		Log::db_stat_log({'robot' => $robot->name, 'list' => $listname, 'operation' => 'send_mail', 'parameter' => length($msg),
				   'mail' => $message_sender, 'client' => '', 'daemon' => 'sympa.pl'});
	    }
	}
    }

    my $current_date = int(time);
    
    # second : create each recipient packet in bulkmailer_table
    my $type = ref $rcpts;

    unless (ref $rcpts) {
	my @tab = ($rcpts);
	my @tabtab;
	push @tabtab, \@tab;
	$rcpts = \@tabtab;
    }

    my $priority_for_packet;
    my $already_tagged = 0;
    my $packet_rank = 0; # Initialize counter used to check whether we are copying the last packet.
    foreach my $packet (@{$rcpts}) {
	$priority_for_packet = $priority_packet;
	if($tag_as_last && !$already_tagged){
	    $priority_for_packet = $priority_packet + 5;
	    $already_tagged = 1;
	}
	$type = ref $packet;
	my $rcptasstring ;
	if  (ref $packet eq 'ARRAY'){
	    $rcptasstring  = join ',',@{$packet};
	}else{
	    $rcptasstring  = $packet;
	}
	my $packetid =  &tools::md5_fingerprint($rcptasstring);
	my $packet_already_exist;
	if (ref $listname eq 'List') {
	    $listname = $listname->name;
	}
	if ($message_already_on_spool) {
	    ## search if this packet is already in spool database : mailfile may perform multiple submission of exactly the same message 
	    unless ($sth = &SDM::do_query( "SELECT count(*) FROM bulkmailer_table WHERE ( messagekey_bulkmailer = %s AND  packetid_bulkmailer = %s)", &SDM::quote($message->{'messagekey'}),&SDM::quote($packetid))) {
		&Log::do_log('err','Unable to check presence of packet %s of message %s in database', $packetid, $message->{'messagekey'});
		return undef;
	    }	
	    $packet_already_exist = $sth->fetchrow;
	    $sth->finish();
	}
	
	if ($packet_already_exist) {
	    &Log::do_log('err','Duplicate message not stored in bulmailer_table');
	    
	}else {
	    unless (SDM::do_prepared_query(
		q{INSERT INTO bulkmailer_table
		  (messagekey_bulkmailer, messageid_bulkmailer,
		   packetid_bulkmailer,
		   receipients_bulkmailer, returnpath_bulkmailer,
		   robot_bulkmailer,
		   listname_bulkmailer,
		   verp_bulkmailer, tracking_bulkmailer, merge_bulkmailer,
		   priority_message_bulkmailer, priority_packet_bulkmailer,
		   reception_date_bulkmailer, delivery_date_bulkmailer)
		  VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)},
		$message->{'messagekey'}, $msg_id,
		$packetid,
		$rcptasstring, $from,
		$robot->name, ## '*' for Site
		$listname,
		$verp, $tracking, $merge,
		$priority_message, $priority_for_packet,
		$current_date, $delivery_date
	    )) {
		Log::do_log('err',
		    'Unable to add packet %s of message %s to database spool',
		    $packetid, $msg_id
		);
		return undef;
	    }
	}
	$packet_rank++;
    }
    $bulkspool->unlock_message($message->{'messagekey'});
    return 1;
}

## remove file that are not referenced by any packet
sub purge_bulkspool {
    &Log::do_log('debug', 'purge_bulkspool');

    unless ($sth = &SDM::do_query( "SELECT messagekey_spool AS messagekey FROM spool_table LEFT JOIN bulkmailer_table ON messagekey_spool = messagekey_bulkmailer WHERE messagekey_bulkmailer IS NULL AND messagelock_spool IS NULL AND spoolname_spool = %s",&SDM::quote('bulk'))) {
	&Log::do_log('err','Unable to check messages unreferenced by packets in database');
	return undef;
    }

    my $count = 0;
    while (my $key = $sth->fetchrow_hashref('NAME_lc')) {	
	if ( &Bulk::remove_bulkspool_message('spool',$key->{'messagekey'}) ) {
	    $count++;
	}else{
	    &Log::do_log('err','Unable to remove message (key = %s) from spool_table',$key->{'messagekey'});	    
	}
   }
    $sth->finish;
    return $count;
}

sub remove_bulkspool_message {
    my $spool = shift;
    my $messagekey = shift;

    my $table = $spool.'_table';
    my $key = 'messagekey_'.$spool ;

    unless (&SDM::do_query( "DELETE FROM %s WHERE %s = %s",$table,$key,&SDM::quote($messagekey))) {
	&Log::do_log('err','Unable to delete %s %s from %s',$table,$key,$messagekey);
	return undef;
    }

    return 1;
}
## Return the number of remaining packets in the bulkmailer table.
sub get_remaining_packets_count {
    &Log::do_log('debug3', 'get_remaining_packets_count');

    my $m_count = 0;

    unless ($sth = &SDM::do_prepared_query( "SELECT COUNT(*) FROM bulkmailer_table WHERE lock_bulkmailer IS NULL")) {
	&Log::do_log('err','Unable to count remaining packets in bulkmailer_table');
	return undef;
    }

    my @result = $sth->fetchrow_array();
    
    return $result[0];
}

## Returns 1 if the number of remaining packets in the bulkmailer table exceeds
## the value of the 'bulk_fork_threshold' config parameter.
sub there_is_too_much_remaining_packets {
    &Log::do_log('debug3', 'there_is_too_much_remaining_packets');
    my $remaining_packets = &get_remaining_packets_count();
    if ($remaining_packets > Site->bulk_fork_threshold) {
	return $remaining_packets;
    }else{
	return 0;
    }
}

## Packages must return true.
1;
