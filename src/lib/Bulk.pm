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
# You should have received a copy of the GNU General Public License# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

package Bulk;

use strict;

use Encode;
use Fcntl qw(LOCK_SH LOCK_EX LOCK_NB LOCK_UN);
use Carp;
use IO::Scalar;
use Storable;
use Mail::Header;
use Time::HiRes qw(time);
use Time::Local;
use MIME::Entity;
use MIME::EncWords;
use MIME::WordDecoder;
use MIME::Parser;
use MIME::Base64;
use Term::ProgressBar;
use constant MAX => 100_000;

use Datasource;
use SQLSource qw(create_db %date_format);
use Lock;
use Task;
use Fetch;
use WebAgent;
use tools;
use tt2;
use Language;
use Log;
use Conf;
use mail;
use Ldap;
use Message;
use List;

## Database and SQL statement handlers
my ($dbh, $sth, $db_connected, @sth_stack, $use_db);


# fingerprint of last message stored in bulkspool
my $message_fingerprint;

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
    &do_log('debug', 'Bulk::next');

    $dbh = &List::db_get_handler();

    ## Check database connection
    unless ($dbh and $dbh->ping) {
	return undef unless &List::db_connect();
	$dbh = &List::db_get_handler();
    }

    # lock next packet
    my $lock = &tools::get_lockname();

    my $order;
    my $limit_oracle='';
    my $limit_sybase='';
	## Only the first record found is locked, thanks to the "LIMIT 1" clause
    $order = 'ORDER BY priority_message_bulkmailer ASC, priority_packet_bulkmailer ASC, reception_date_bulkmailer ASC, verp_bulkmailer ASC';
    if (lc($Conf::Conf{'db_type'}) eq 'mysql' || lc($Conf::Conf{'db_type'}) eq 'Pg' || lc($Conf::Conf{'db_type'}) eq 'SQLite'){
	$order.=' LIMIT 1';
    }elsif (lc($Conf::Conf{'db_type'}) eq 'Oracle'){
	$limit_oracle = 'AND rownum<=1';
    }elsif (lc($Conf::Conf{'db_type'}) eq 'Sybase'){
	$limit_sybase = 'TOP 1';
    }

    my $statement;
    # Select the most prioritary packet to lock.
    $statement = sprintf "SELECT %s messagekey_bulkmailer AS messagekey, packetid_bulkmailer AS packetid FROM bulkmailer_table WHERE lock_bulkmailer IS NULL AND delivery_date_bulkmailer <= %d %s %s", $limit_sybase, time(), $limit_oracle, $order;

    unless ($sth = $dbh->prepare($statement)) {
	do_log('err','Unable to prepare SQL statement : %s', $dbh->errstr);
	return undef;
    }
    
    unless ($sth->execute) {
	do_log('err','Unable to select a packet to lock: "%s" : %s', $statement, $dbh->errstr);
	return undef;
    }
    my $packet;
    unless($packet = $sth->fetchrow_hashref('NAME_lc')){
	return undef;
    }
    $sth->finish();

    # Lock the packet previously selected.
    $statement = sprintf "UPDATE bulkmailer_table SET lock_bulkmailer=%s WHERE messagekey_bulkmailer='%s' AND packetid_bulkmailer='%s'",$dbh->quote($lock), $packet->{'messagekey'}, $packet->{'packetid'};

    unless ($dbh->do($statement)) {
	do_log('err','Unable to lock bulk packet  SQL statement "%s"; error : %s', $statement, $dbh->errstr);
	return undef;
    }
    
    # select the packet that has been locked previously
    $statement = sprintf "SELECT messagekey_bulkmailer AS messagekey, messageid_bulkmailer AS messageid, packetid_bulkmailer AS packetid, receipients_bulkmailer AS receipients, returnpath_bulkmailer AS returnpath, listname_bulkmailer AS listname, robot_bulkmailer AS robot, priority_message_bulkmailer AS priority_message, priority_packet_bulkmailer AS priority_packet, verp_bulkmailer AS verp, merge_bulkmailer as merge, reception_date_bulkmailer AS reception_date, delivery_date_bulkmailer AS delivery_date FROM bulkmailer_table WHERE lock_bulkmailer=%s %s",$dbh->quote($lock), $order;

    unless ($sth = $dbh->prepare($statement)) {
	do_log('err','Unable to prepare SQL statement : %s', $dbh->errstr);
	return undef;
    }
    
    unless ($sth->execute) {
	do_log('err','Unable to execute SQL statement "%s" : %s', $statement, $dbh->errstr);
	return undef;
    }
    
    my $result = $sth->fetchrow_hashref('NAME_lc');
    $sth->finish();
    return $result;

}


# remove a packet from database by packet id. return undef if packet does not exist

sub remove {
    my $messagekey = shift;
    my $packetid= shift;
    #
    &do_log('debug', "Bulk::remove(%s,%s)",$messagekey,$packetid);

    my $statement = sprintf "DELETE FROM bulkmailer_table WHERE packetid_bulkmailer = %s AND messagekey_bulkmailer = %s",$dbh->quote($packetid),$dbh->quote($messagekey),;
    unless ($dbh and $dbh->ping) {
	return undef unless &List::db_connect();
    }	   
    return ($dbh->do($statement));
}

sub messageasstring {
    my $messagekey = shift;
    &do_log('debug', 'Bulk::messageasstring(%s)',$messagekey);
    
    my $statement = sprintf "SELECT message_bulkspool AS message FROM bulkspool_table WHERE messagekey_bulkspool = %s",$dbh->quote($messagekey);
    
    unless ($dbh and $dbh->ping) {
	return undef unless &List::db_connect();
    }
    unless ($sth = $dbh->prepare($statement)) {
	do_log('err','Unable to prepare SQL statement : %s', $dbh->errstr);
	return undef;
    }
    
    unless ($sth->execute) {
	do_log('err','Unable to execute SQL statement "%s" : %s', $statement, $dbh->errstr);
	return undef;
    }
    my $messageasstring = $sth->fetchrow_hashref('NAME_lc') ;
    $sth->finish;

    unless ($messageasstring ){
	do_log('err',"could not fetch message $messagekey from spool"); 
    }
    my $msg = MIME::Base64::decode($messageasstring->{'message'});
    unless ($msg){
	do_log('err',"could not decode message $messagekey extrated from spool (base64)"); 
    }
    return( $msg );
}
#################################"
# fetch message from bulkspool_table by key 
#
sub message_from_spool {
    my $messagekey = shift;
    &do_log('debug', '(messagekey : %s)',$messagekey);
    
    my $statement = sprintf "SELECT message_bulkspool AS message, messageid_bulkspool AS messageid, dkim_d_bulkspool AS  dkim_d,  dkim_i_bulkspool AS  dkim_i, dkim_privatekey_bulkspool AS dkim_privatekey, dkim_selector_bulkspool AS dkim_selector,dkim_header_list_bulkspool AS dkim_header_list FROM bulkspool_table WHERE messagekey_bulkspool = %s",$dbh->quote($messagekey);

    unless ($dbh and $dbh->ping) {
	return undef unless &List::db_connect();
    }
    unless ($sth = $dbh->prepare($statement)) {
	do_log('err','Unable to prepare SQL statement : %s', $dbh->errstr);
	return undef;
    }
    
    unless ($sth->execute) {
	do_log('err','Unable to execute SQL statement "%s" : %s', $statement, $dbh->errstr);
	return undef;
    }
    my $message_from_spool = $sth->fetchrow_hashref('NAME_lc') ;
    $sth->finish;

    return({'messageasstring'=> MIME::Base64::decode($message_from_spool->{'message'}),
	    'messageid' => $message_from_spool->{'messageid'},
	    'dkim_d' => $message_from_spool->{'dkim_d'},
	    'dkim_i' => $message_from_spool->{'dkim_i'},
	    'dkim_selector' => $message_from_spool->{'dkim_selector'},
	    'dkim_privatekey' => $message_from_spool->{'dkim_privatekey'},
	    'dkim_header_list' => $message_from_spool->{'dkim_header_list'}});

}

############################################################
#  merge_msg                                               #
############################################################
#  Merge a message with custom attributes of a user.       #
#                                                          #
#                                                          #
#  IN : - MIME:Entity                                      #
#       - $rcpt : a receipient                             #
#       - $bulk : HASH                                     #
#       - $data : HASH with user's data                    #
#  OUT : 1 | undef                                         #
#                                                          #
############################################################
sub merge_msg {

    my $entity = shift;
    my $rcpt = shift;
    my $bulk = shift;
    my $data = shift;

    ## Test MIME::Entity
    unless (defined $entity && ref($entity) eq 'MIME::Entity') {
	&do_log('err', 'echec entity');
	return undef;
    }

    my $body;
    if(defined $entity->bodyhandle){
	$body      = $entity->bodyhandle->as_string;
    }
    ## Get the Content-Type / Charset / Content-Transfer-encoding of a message
    my $type      = $entity->mime_type;
    my $charset   = unmime $entity->head->mime_attr('content-type.charset');
    my $encoding  = unmime $entity->head->mime_encoding;

    my $message_output;
    my $IO;
    
    ## If Content-Type is a text/*
    if($entity->mime_type =~ /^text/){
	
	if(defined $body){
	    ## --------- Initial Charset to UTF-8 --------- ##
	    unless($charset =~ /UTF-8/){
		# Put the charset to UTF-8
		Encode::from_to($body, $charset, 'UTF-8');
	      }
	    ## PARSAGE ##
	    
	    &merge_data('rcpt' => $rcpt,
			'messageid' => $bulk->{'messageid'},
			'listname' => $bulk->{'listname'},
			'robot' => $bulk->{'robot'},
			'data' => $data,
			'body' => $body,
			'message_output' => \$message_output,
			); 
	    $body = $message_output;

	    unless($charset =~ /UTF-8/){
		# Put the charset to the initial
		Encode::from_to($body, 'UTF-8',$charset);
	      }
	    
	    # Write the new body in the entity
	    unless($IO = $entity->bodyhandle->open("w") || die "open body: $!"){
		&do_log('err', "Can't open Entity");
		return undef;
	    }
	    unless($IO->print($body)){
		&do_log('err', "Can't write in Entity");
		return undef;
	    }
	    unless($IO->close || die "close I/O handle: $!"){
		&do_log('err', "Can't close Entity");
		return undef;
	    }
	}
    }
    
    ##--- Recursive call of the method. ---##
    ## Course on the different parts of the message at all levels. 
    foreach my $part ($entity->parts) {
	unless(&merge_msg($part, $rcpt, $bulk, $data)){
	    &do_log('err', "Failed to merge message part.");
	    return undef;
	}  
    }

    return 1;

}

############################################################
#  merge_data                                              #
############################################################
#  This function retrieves the customized data of the      #
#  users then parse the message. It returns the message    #
#  personalized to bulk.pl                                 #
#  It uses the method &tt2::parse_tt2                      #
#  It uses the method &List::get_subscriber_no_object      #
#  It uses the method &tools::get_fingerprint              #
#                                                          #
# IN : - rcpt : the receipient email                       #
#      - listname : the name of the list                   #
#      - robot : the host                                  #
#      - data : HASH with many data                        #
#      - body : message with the TT2                       #
#      - message_output : object, IO::Scalar               #
#                                                          #
# OUT : - message_output : customized message              #
#     | undef                                              #
#                                                          #
############################################################ 
sub merge_data {

    my %params = @_;
    my $rcpt = $params{'rcpt'},
    my $listname = $params{'listname'},
    my $robot = $params{'robot'},
    my $data = $params{'data'},
    my $body = $params{'body'},
    my $message_output = $params{'message_output'},
    
    my $options;
    $options->{'is_not_template'} = 1;
    
    my $user_details;
    $user_details->{'email'} = $rcpt;
    $user_details->{'name'} = $listname;
    $user_details->{'domain'} = $robot;
    
    # get_subscriber_no_object() return the user's details with the custom attributes
    my $user = &List::get_subscriber_no_object($user_details);

    $user->{'friendly_date'} = &POSIX::strftime("%d %b %Y  %H:%M", localtime($user->{'date'}));

    # this method as been removed because some users may forward authentication link
    # $user->{'fingerprint'} = &tools::get_fingerprint($rcpt);
    my $url = $data->{'wwsympa_url'};
    
    $data = {
	'user' => $user,
	'robot' => $robot,
	'listname' => $listname,
	'url' => $url, 
    };

    # Parse the TT2 in the message : replace the tags and the parameters by the corresponding values
    unless (&tt2::parse_tt2($data,\$body, $message_output, '', $options)) {
	&do_log('err','Unable to parse body : "%s"', \$body);
	return undef;
    }

    return 1;
}

## 
sub store { 
    my %data = @_;
    
    my $msg = $data{'msg'};
    my $msg_id = $data{'msg_id'};
    my $rcpts = $data{'rcpts'};
    my $from = $data{'from'};
    my $robot = $data{'robot'};
    my $listname = $data{'listname'};
    my $priority_message = $data{'priority_message'};
    my $priority_packet = $data{'priority_packet'};
    my $delivery_date = $data{'delivery_date'};
    my $verp  = $data{'verp'};
    $verp=0 unless($verp);
    my $merge  = $data{'merge'};
    my $dkim = $data{'dkim'};
    my $tag_as_last = $data{'tag_as_last'};

    &do_log('debug', 'Bulk::store(<msg>,<rcpts>,from = %s,robot = %s,listname= %s,priority_message = %s, delivery_date= %s,verp = %s, merge = %s, dkim: d= %s i=%s, last: %s)',$from,$robot,$listname,$priority_message,$delivery_date,$verp,$merge,$dkim->{'d'},$dkim->{'i'},$tag_as_last);

    $dbh = &List::db_get_handler();

    $priority_message = &Conf::get_robot_conf($robot,'sympa_priority') unless ($priority_message);

    $priority_packet = &Conf::get_robot_conf($robot,'sympa_packet_priority') unless ($priority_packet);
    
    unless ($dbh and $dbh->ping) {
	return undef unless &List::db_connect();
    }
    
    $msg = MIME::Base64::encode($msg);

    my $messagekey = &tools::md5_fingerprint($msg);

    # first store the message in bulk_message_table (because as soon as packet are created bulk.pl may distribute them).
    # if messagekey is equal to message_fingerprint, the message is already stored in database
    
    my $message_already_on_spool;

    if ($messagekey ne $message_fingerprint) {

	## search if this message is already in spool database : mailfile may perform multiple submission of exactly the same message 
	my $statement = sprintf "SELECT count(*) FROM bulkspool_table WHERE ( messagekey_bulkspool = %s )", $dbh->quote($messagekey);
    
	unless ($sth = $dbh->prepare($statement)) {
	    do_log('err','Unable to prepare SQL statement : %s', $dbh->errstr);
	    return undef;
	}	
	unless ($sth->execute) {
	    do_log('err','Unable to execute SQL statement "%s" : %s', $statement, $dbh->errstr);
	    return undef;
	}
	
	$message_already_on_spool = $sth->fetchrow;
	$sth->finish();
	
	# if message is not found in bulkspool_table store it
	if ($message_already_on_spool == 0) {	    
	    my $statement      = sprintf "INSERT INTO bulkspool_table (messagekey_bulkspool, messageid_bulkspool, message_bulkspool, lock_bulkspool, dkim_d_bulkspool,dkim_i_bulkspool,dkim_selector_bulkspool, dkim_privatekey_bulkspool,dkim_header_list_bulkspool) VALUES (%s, %s, %s, '1', %s, %s, %s ,%s ,%s)",$dbh->quote($messagekey),$dbh->quote($msg_id),$dbh->quote($msg),$dbh->quote($dkim->{d}), $dbh->quote($dkim->{i}),$dbh->quote($dkim->{selector}),$dbh->quote($dkim->{private_key}), $dbh->quote($dkim->{header_list}); 

	    my $statementtrace = sprintf "INSERT INTO bulkspool_table (messagekey_bulkspool, messageid_bulkspool, message_bulkspool, lock_bulkspool, dkim_d_bulkspool, dkim_i_bulkspool, dkim_selector_bulkspool, dkim_privatekey_bulkspool, dkim_header_list_bulkspool) VALUES (%s, %s, %s, '1', %s ,%s ,%s, %s, %s)",$dbh->quote($messagekey),$dbh->quote($msg_id),$dbh->quote(substr($msg, 0, 100)), $dbh->quote($dkim->{d}), $dbh->quote($dkim->{i}),$dbh->quote($dkim->{selector}),$dbh->quote(substr($dkim->{private_key},0,30)), $dbh->quote($dkim->{header_list});  
	    # do_log('debug',"insert : $statement_trace");

		unless ($dbh->do($statement)) {
		    do_log('err','Unable to add message in bulkspool_table "%s"; error : %s', $statementtrace, $dbh->errstr);
		    return undef;
		}

	    $message_fingerprint = $messagekey;
	}
    }

    my $current_date = int(time);
    
    # second : create each receipient packet in bulkmailer_table
    my $type = ref $rcpts;

    unless (ref $rcpts) {
	my @tab = ($rcpts);
	my @tabtab;
	push @tabtab, \@tab;
	$rcpts = \@tabtab;
    }

    my $priority_for_packet;
    my $already_tagged = 0;
    my $packet_rank = 0; # Initialize counter used to check wether we are copying the last packet.
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
	if ($message_already_on_spool) {
	    ## search if this packet is already in spool database : mailfile may perform multiple submission of exactly the same message 
	    my $statement = sprintf "SELECT count(*) FROM bulkmailer_table WHERE ( messagekey_bulkmailer = %s AND  packetid_bulkmailer = %s)", $dbh->quote($messagekey),$dbh->quote($packetid);
	    unless ($sth = $dbh->prepare($statement)) {
		do_log('err','Unable to prepare SQL statement : %s', $dbh->errstr);
		return undef;
	    }	
	    unless ($sth->execute) {
		do_log('err','Unable to execute SQL statement "%s" : %s', $statement, $dbh->errstr);
		return undef;
	    }	    
	    $packet_already_exist = $sth->fetchrow;
	    $sth->finish();
	}
	unless ($packet_already_exist) {
	    my $statement = sprintf "INSERT INTO bulkmailer_table (messagekey_bulkmailer,messageid_bulkmailer,packetid_bulkmailer,receipients_bulkmailer,returnpath_bulkmailer,robot_bulkmailer,listname_bulkmailer, verp_bulkmailer, merge_bulkmailer, priority_message_bulkmailer, priority_packet_bulkmailer, reception_date_bulkmailer, delivery_date_bulkmailer) VALUES (%s,%s,%s,%s,%s,%s,%s,'%s','%s','%s','%s','%s','%s')", $dbh->quote($messagekey),$dbh->quote($msg_id),$dbh->quote($packetid),$dbh->quote($rcptasstring),$dbh->quote($from),$dbh->quote($robot),$dbh->quote($listname),$verp,$merge,$priority_message, $priority_for_packet, $current_date,$delivery_date;
	    unless ($sth = $dbh->do($statement)) {
		do_log('err','Unable to add packet in bulkmailer_table "%s"; error : %s', $statement, $dbh->errstr);
		return undef;
	    }
	}
	$packet_rank++;
    }
    # last : unlock message in bulkspool_table so it is now possible to remove this message if no packet have a ref on it			
    my $statement = sprintf "UPDATE bulkspool_table SET lock_bulkspool='0' WHERE messagekey_bulkspool = %s",$dbh->quote($messagekey) ;                                        ;
    unless ($dbh->do($statement)) {
	do_log('err','Unable to unlock packet in bulkmailer_table "%s"; error : %s', $statement, $dbh->errstr);
	return undef;
    }
}

## remove file that are not referenced by any packet
sub purge_bulkspool {
    &do_log('debug', 'purge_bulkspool');

    my $dbh = &List::db_get_handler();
    my $sth;

    unless ($dbh and $dbh->ping) {
	return undef unless &List::db_connect();
    }
    my $statement = "SELECT messagekey_bulkspool AS messagekey FROM bulkspool_table LEFT JOIN bulkmailer_table ON messagekey_bulkspool = messagekey_bulkmailer WHERE messagekey_bulkmailer IS NULL AND lock_bulkspool = 0";
    unless ($sth = $dbh->prepare($statement)) {
	do_log('err','Unable to prepare SQL statement : %s', $dbh->errstr);
	return undef;
    }
    
    unless ($sth->execute) {
	do_log('err','Unable to execute SQL statement "%s" : %s', $statement, $dbh->errstr);
	return undef;
    }

    my $count = 0;
    while (my $key = $sth->fetchrow_hashref('NAME_lc')) {	
	if ( &Bulk::remove_bulkspool_message('bulkspool',$key->{'messagekey'}) ) {
	    $count++;
	}else{
	    &do_log('err','Unable to remove message (key = %s) from bulkspool_table',$key->{'messagekey'});	    
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
    my $dbh = &List::db_get_handler();
    my $sth;

    unless ($dbh and $dbh->ping) {
	return undef unless &List::db_connect();
    }

    my $statement = sprintf "DELETE FROM `%s` WHERE `%s` = '%s'",$table,$key,$messagekey;

    unless ($sth = $dbh->prepare($statement)) {
	do_log('err','Unable to prepare SQL statement : %s', $dbh->errstr);
	return undef;
    }

    unless ($sth->execute) {
	do_log('err','Unable to execute SQL statement (while trying to remove packet from bulkmailer_table) "%s" : %s', $statement, $dbh->errstr);
	return undef;
    }
    return 1;
}

# test the maximal message size the database will accept
sub store_test { 
    my $value_test = shift;
    my $divider = 100;
    my $steps = 50;
    my $maxtest = $value_test/$divider;
    my $size_increment = $divider*$maxtest/$steps;
    my $barmax = $size_increment*$steps*($steps+1)/2;
    my $even_part = $barmax/$steps;
    my $rcpts = 'nobody@cru.fr';
    my $from = 'sympa-test@notadomain' ;
    my $robot = 'notarobot' ;
    my $listname = 'notalist';
    my $priority_message = 9;
    my $delivery_date = time;
    my $verp  = 1;
    my $merge  = 1;
    
    &do_log('debug', 'Bulk::store_test(<msg>,<rcpts>,from = %s,robot = %s,listname= %s,priority_message = %s,delivery_date= %s,verp = %s, merge = %s)',$from,$robot,$listname,$priority_message,$delivery_date,$verp,$merge);

    print "maxtest: $maxtest\n";
    print "barmax: $barmax\n";
    my $progress = Term::ProgressBar->new({name  => 'Total size transfered',
                                         count => $barmax,
                                         ETA   => 'linear', });
    $dbh = &List::db_get_handler();

    unless ($dbh and $dbh->ping) {
	return undef unless &List::db_connect();
    }
    
    $priority_message = 9;

    my $messagekey = &tools::md5_fingerprint(time());
    my $msg;
    $progress->max_update_rate(1);
    my $next_update = 0;
    my $total = 0;

    my $result = 0;
    
    for (my $z=1;$z<=$steps;$z++){	
	$msg = MIME::Base64::decode($msg);
	for(my $i=1;$i<=1024*$size_increment;$i++){
	    $msg .=  'a';
	}
	$msg = MIME::Base64::encode($msg);
	my $time = time();
        $progress->message(sprintf "Test storing and removing of a %5d kB message (step %s out of %s)", $z*$size_increment, $z, $steps);
	# 
	my $statement = sprintf "INSERT INTO bulkspool_table (messagekey_bulkspool, message_bulkspool, lock_bulkspool) VALUES (%s, %s, '1')",$dbh->quote($messagekey),$dbh->quote($msg);
	my $statementtrace = sprintf "INSERT INTO bulkspool_table (messagekey_bulkspool, message_bulkspool, lock_bulkspool) VALUES (%s, %s, '1')",$dbh->quote($messagekey),$dbh->quote(substr($msg, 0, 100));	    
	unless ($dbh->do($statement)) {
	    return (($z-1)*$size_increment);
	}
	unless ( &Bulk::remove_bulkspool_message('bulkspool',$messagekey) ) {
	    &do_log('err','Unable to remove test message (key = %s) from bulkspool_table',$messagekey);	    
	}
	$total += $z*$size_increment;
        $progress->message(sprintf ".........[OK. Done in %.2f sec]", time() - $time);
	$next_update = $progress->update($total+$even_part)
	    if $total > $next_update && $total < $barmax;
	$result = $z*$size_increment;
    }
    $progress->update($barmax)
	if $barmax >= $next_update;
    return $result;
}

## Return the number of remaining packets in the bulkmailer table.
sub get_remaining_packets_count {
    &do_log('debug3', 'get_remaining_packets_count');

    my $dbh = &List::db_get_handler();
    my $sth;

    my $m_count = 0;

    unless ($dbh and $dbh->ping) {
	return undef unless &List::db_connect();
    }

    my $statement = "SELECT COUNT(*) FROM bulkmailer_table";

    unless ($sth = $dbh->prepare($statement)) {
	do_log('err','Unable to prepare SQL statement : %s', $dbh->errstr);
	return undef;
    }

    unless ($sth->execute) {
	do_log('err','Unable to execute SQL statement (while trying to count remaining packets in bulkmailer_table) "%s" : %s', $statement, $dbh->errstr);
	return undef;
    }
    my @result = $sth->fetchrow_array();
    return $result[0];
}

## Returns 1 if the number of remaining packets inthe bulkmailer table exceeds
## the value of the 'bulk_fork_threshold' config parameter.
sub there_is_too_much_remaining_packets {
    &do_log('debug3', 'there_is_too_much_remaining_packets');
    my $remaining_packets = &get_remaining_packets_count();
    if ($remaining_packets > $Conf::Conf{'bulk_fork_threshold'}) {
	return $remaining_packets;
    }else{
	return 0;
    }
}

## Packages must return true.
1;
