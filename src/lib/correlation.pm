# Correlation.pm - this module does the mail correlation processing
# RCS Identication ; mar, 15 septembre 2009 

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

package correlation;

use strict;

use DBI;
use CGI;
use Email::Simple;
use Log;

our $message_table = "mail_table";
our $notif_table = "notification_table";
our $status = "Waiting";   


##############################################
#  format_msg_id
##############################################
# Parses the argument and format it in order to 
# get an adequate message-id value. 
# 
# IN :-$message_id (+): the message-id to format
#
# OUT : $msgID | undef
#      
##############################################
sub format_msg_id{
	my $msgID = shift;
	
	unless ($msgID) {
        	&do_log('err', "Can't find message-id");
                return undef;	
	}
	if($msgID =~ /<(\S+@\S+)>/){
		($msgID)= $msgID =~ /<(\S+@\S+)>/;			
	}
	return $msgID;			
}

##############################################
#  format_from_address
##############################################
# Parses the argument and format it in order to 
# get an adequate mail address form. 
# 
# IN :-$from_header (+): the address to format
#
# OUT : $from_header | undef
#      
##############################################
sub format_from_address{
	my $from_header = shift;

	my @from;

	unless ($from_header) {
                &do_log('err', "Can't find from address");
                return undef;
	} 
	if($from_header =~ /\s.*/){
		@from = split /\s+/,$from_header;
		foreach my $from (@from){
			if($from =~ /<(\S+\@\S+)>/){
				($from)= $from =~ /<(\S+@\S+)>/;			
				$from_header = $from;
			}
		}
	}
	elsif($from_header =~ /<(\S+\@\S+)>/){
		($from_header)= $from_header =~ /<(\S+@\S+)>/;			
	}
	return $from_header;
}

##############################################
#  find_list_user_address
##############################################
# Collect and return the number and thes addresses 
# of the subscribers of the input list. 
# 
# IN :-$list (+): the list to analyse
#
# OUT : ($nb_addresses, @users ) | undef
#      
##############################################
sub find_list_user_address{
	my ($list) = @_;

	my @to;
	my $nb_addresses;

	unless ($list) {
                &do_log('err', "List parameter not found");
                return undef;
	} 
	my @users;
 	## Create the list of subscribers
 	for (my $user = $list->get_first_user(); $user; $user = $list->get_next_user()) {
 	    &do_log('debug2', 'USER: %s', $user->{'email'});
	    
	    my $address = $user->{'email'};
	    ($address)= $address =~ /(\S+@\S+)/;			
	    if( $address =~ /<(\S+@\S+)>/){
		($address)= $address =~ /<(\S+@\S+)>/;			
	    }			
 	    push @users, $address;
	    $nb_addresses = @users;
	}
	return ($nb_addresses, @users);
}

##############################################
#   connection
##############################################
# Function use to connect to a database 
# with the given arguments. 
# 
# IN :-$database (+): the database name
#     -$hostname (+): the hostname of the database
#     -$port (+): port to use
#     -$login (+): user identifiant
#     -$mdp (+): password for identification
#
# OUT : $dbh |undef
#      
##############################################
sub connection{
	my ($database, $hostname, $port, $login, $mdp) = @_;
	
	my $dsn = "DBI:mysql:database=$database:host=$hostname:port=$port";
	my $dbh;

	unless ($dbh = DBI->connect($dsn, $login, $mdp)) {
		&do_log('err', "Can't connect to the database");
		return undef;
	}
	return $dbh;
}

##############################################
#   get_pk_message
##############################################
# Function use to get the pk identificator of 
# a mail in a mysql database with the given message-id.
# A connection must already exist 
# 
# IN :-$dbh (+): the database connection
#     -$table (+): the database table to use
#     -$id (+): the message-id of the mail
#     -$listname (+): the name of the list to which the 
#		      mail has been sent
#
# OUT : $pk |undef
#      
##############################################
sub get_pk_message {
	my ($dbh, $table, $id, $listname) = @_;

	my $sth;
	my $pk;
	my $request = "SELECT pk_mail FROM $table WHERE `message_id_mail` = '$id' AND `list_mail` = '$listname'";

        &do_log('debug2', 'Request For Message Table : : %s', $request);

	unless ($sth = $dbh->prepare($request)) {
                &do_log('err','Unable to prepare SQL statement : %s', $dbh->errstr);
                return undef;
	}
	unless ($sth->execute) {
                &do_log('err','Unable to execute SQL statement "%s" : %s', $request, $dbh->errstr);
                return undef;
	}

	my @pk_mail = $sth->fetchrow_array;
	$pk = $pk_mail[0];
	$sth->finish();
	return $pk;
}

##############################################
#   get_recipients_number
##############################################
# Function use to ask the number of recipients
# of a message. Use the pk identifiant of the mail
# 
# IN :-$dbh (+): the database connection
#     -$pk_mail (+): the identifiant of the stored mail
#
# OUT : $pk |undef
#      
##############################################
sub get_recipients_number {
        my $dbh = shift;
        my $pk_mail = shift;

        my $sth;
        my $pk;
        my $request = "SELECT COUNT(*) FROM $notif_table WHERE `pk_mail_notification` = '$pk_mail' AND `type_notification` = 'DSN'";

        &do_log('debug2', 'Request For Message Table : : %s', $request);
        unless ($sth = $dbh->prepare($request)) {
                &do_log('err','Unable to prepare SQL statement : %s', $dbh->errstr);
                return undef;
        }
        unless ($sth->execute) {
                &do_log('err','Unable to execute SQL statement "%s" : %s', $request, $dbh->errstr);
                return undef;
        }
        my @pk_notif = $sth->fetchrow_array;
        $pk = $pk_notif[0];
        $sth->finish();
        return $pk;
}

##############################################
#   get_undelivered_recipients
##############################################
# Function use to get mail addresses and status of 
# the recipients who have a different DSN status than "delivered"
# Use the pk identifiant of the mail
# 
# IN :-$dbh (+): the database connection
#     -$pk_mail (+): the identifiant of the stored mail
#
# OUT : @pk_notifs |undef
#      
##############################################
sub get_undelivered_recipients {
        my $dbh = shift;
        my $pk_mail = shift;

        my $sth;
        my $pk;
        my $request = "SELECT recipient_notification, status_notification FROM $notif_table WHERE `pk_mail_notification` = '$pk_mail' AND `type_notification` = 'DSN' AND `status_notification` != 'delivered' ORDER BY `status_notification`";

        &do_log('debug2', 'Request For Message Table : : %s', $request);
        unless ($sth = $dbh->prepare($request)) {
                &do_log('err','Unable to prepare SQL statement : %s', $dbh->errstr);
                return undef;
        }
        unless ($sth->execute) {
                &do_log('err','Unable to execute SQL statement "%s" : %s', $request, $dbh->errstr);
                return undef;
        }
        my @pk_notif;
        my @pk_notifs;
        my $i = 0;
        while (@pk_notif = $sth->fetchrow_array){
                $pk_notifs[$i++] = $pk_notif[0];
                $pk_notifs[$i++] = $pk_notif[1];
        }
        $sth->finish();
        return @pk_notifs;
}

##############################################
#   get_not_displayed_recipients
##############################################
# Function use to get mail addresses and status of 
# the recipients who have a different MDN status than "displayed"
# Use the pk identifiant of the mail
# 
# IN :-$dbh (+): the database connection
#     -$pk_mail (+): the identifiant of the stored mail
#
# OUT : @pk_notifs |undef
#      
##############################################
sub get_not_displayed_recipients {
        my $dbh = shift;
        my $pk_mail = shift;

        my $sth;
        my $pk;
        my $request = "SELECT recipient_notification FROM $notif_table WHERE `pk_mail_notification` = '$pk_mail' AND `type_notification` = 'MDN' AND `status_notification` != 'displayed'";

        &do_log('debug2', 'Request For Message Table : : %s', $request);
        unless ($sth = $dbh->prepare($request)) {
                &do_log('err','Unable to prepare SQL statement : %s', $dbh->errstr);
                return undef;
        }
        unless ($sth->execute) {
                &do_log('err','Unable to execute SQL statement "%s" : %s', $request, $dbh->errstr);
                return undef;
        }
        my @pk_notif;
        my @pk_notifs;
        my $i = 0;
        while (@pk_notif = $sth->fetchrow_array){
                $pk_notifs[$i++] = $pk_notif[0];
        }
        $sth->finish();
        return @pk_notifs;
}

##############################################
#   get_pk_notifications
##############################################
# Function use a pk mail identifiant to get the list of corresponding 
# notification identifiants. 
# Use the pk identifiant of the mail.
# 
# IN :-$dbh (+): the database connection
#     -$pk_mail (+): the identifiant of the stored mail
#
# OUT : @pk_notifs |undef
#      
##############################################
sub get_pk_notifications {
        my $dbh = shift;
        my $pk_mail = shift;

        my $sth;
        my $pk;
        my $request = "SELECT pk_notification FROM $notif_table WHERE `pk_mail_notification` = '$pk_mail'";

        &do_log('debug2', 'Request For Message Table : : %s', $request);
        unless ($sth = $dbh->prepare($request)) {
                &do_log('err','Unable to prepare SQL statement : %s', $dbh->errstr);
                return undef;
        }
        unless ($sth->execute) {
                &do_log('err','Unable to execute SQL statement "%s" : %s', $request, $dbh->errstr);
                return undef;
        }
	my @pk_notif;
	my @pk_notifs;
	my $i = 0;
        while (@pk_notif = $sth->fetchrow_array){
		$pk_notifs[$i++] = $pk_notif[0];
	}
        $sth->finish();
        return @pk_notifs;
}

##############################################
#   get_pk_notification
##############################################
# Function use to get a specific notification identifiant 
# depending of the given message identifiant, the recipient name
# and the notification type.
# 
# IN :-$dbh (+): the database connection
#     -$table (+): the given table to ask
#     -$id (+): the storage identifiant of the corresponding mail
#     -$recipient (+): the address of one of the list subscribers
#     -$type (+): the notification type (DSN | MDN)
#
# OUT : $pk |undef
#      
##############################################
sub get_pk_notification {
        my ($dbh, $table, $id, $recipient, $type) = @_;

        my $sth;
        my $pk;
        my $request = "SELECT pk_notification FROM $table WHERE `pk_mail_notification` = '$id' AND `recipient_notification` = '$recipient' AND `type_notification`= '$type'";
        &do_log('debug2', 'Request For Message Table : : %s', $request);
        unless ($sth = $dbh->prepare($request)) {
                &do_log('err','Unable to prepare SQL statement : %s', $dbh->errstr);
                return undef;
        }
        unless ($sth->execute) {
                &do_log('err','Unable to execute SQL statement "%s" : %s', $request, $dbh->errstr);
                return undef;
        }

        my @pk_mail = $sth->fetchrow_array;
        $pk = $pk_mail[0];
        $sth->finish();
        return $pk;
}

##############################################
#   store_message_DB
##############################################
# Function use to store mail informations in
# the given table using the given database connection. 
# 
# IN :-$dbh (+): the database connection
#     -$table (+): the given table to store
#     -$id (+): the message-id of the mail
#     -$from (+): the sender address of the mail
#     -$date (+): the sending date
#     -$subject (+): the subject of the mail
#     -$list (+): the diffusion list to which the mail has been initially sent
#
# OUT : 1 |undef
#      
##############################################
sub store_message_DB{
	my ($dbh, $table, $id, $from, $date, $subject, $list) = @_;
	
	my $sth;
	my $request = "INSERT INTO $table VALUES ('', '$id', '$from', '$date','$subject', '$list->{'name'}')";
	
	&do_log('debug2', 'Request For Message Table : : %s', $request);
	unless ($sth = $dbh->prepare($request)) {
		&do_log('err','Unable to prepare SQL statement : %s', $dbh->errstr);
        	return undef;
	}
	unless ($sth->execute()) {
        	&do_log('err','Unable to execute SQL statement "%s" : %s', $request, $dbh->errstr);
        	return undef;
	}
        $sth->finish();
	return 1; 
}

##############################################
#   store_notif_DB
##############################################
# Function used to add a notification entry 
# corresponding to a subscriber of a mail.
# One entry for each subscriber.
# The entry is added in the given table 
# using the given database connection. 
# The status value is fixed to waiting
#
# IN :-$dbh (+): the database connection
#     -$table (+): the given table to store
#     -$id (+): the mail identifiant of the initial mail
#     -$status (+): the current state of the recipient entry. 
#		    Will change after a notification reception for this recipient.
#     -$address (+): the mail address of the subscriber
#     -$list (+): the list to which the mail has been initially sent
#     -$notif_type (+): the kind of notification representing this entry (DSN|MDN).
#
# OUT : $sth | undef
#      
##############################################
sub store_notif_DB{
	my ($dbh, $table, $id, $status, $address, $list, $notif_type) = @_;
	
	my $sth;
	my $request = "INSERT INTO $table VALUES ('','$id', '', '$address', '$status','','$notif_type','$list->{'name'}')";
	
	&do_log('debug2', 'Request For Notification Table : : %s', $request);
	unless ($sth = $dbh->prepare($request)) {
                &do_log('err','Unable to prepare SQL statement "%s": %s', $request, $dbh->errstr);
                return undef;
	}
	unless ($sth->execute()) {
                &do_log('err','Unable to execute SQL statement "%s" : %s', $request, $dbh->errstr);
                return undef;
	}
	return $sth;
}

##############################################
#   update_notif_table
##############################################
# Function used to update a notification entry 
# corresponding to a subscriber of a mail. This function
# is called when a mail report has been received.
# One entry for each subscriber.
# The entry is updated in the given table 
# using the given database connection. 
# The status value is changed according to the 
# report data.
#
# IN :-$dbh (+): the database connection
#     -$table (+): the given table to update
#     -$pk (+): the notification entry identifiant
#     -$msg_id (+): the report message-id
#     -$status (+): the new state of the recipient entry. 
#     -$date (+): the mail arrival date
#
# OUT : $sth | undef
#      
##############################################
sub update_notif_table{
	my ($dbh, $table, $pk, $msg_id, $status, $date) = @_;

	my $sth;
        my $request = "UPDATE $table SET `message_id_notification` = '$msg_id', `status_notification` = '$status', `arrival_date_notification` = '$date' WHERE pk_notification = '$pk'";

        &do_log('debug2', 'Request For Notification Table : : %s', $request);
        unless ($sth = $dbh->prepare($request)) {
                &do_log('err','Unable to prepare SQL statement "%s": %s', $request, $dbh->errstr);
                return undef;
        }
        unless ($sth->execute()) {
                &do_log('err','Unable to execute SQL statement "%s" : %s', $request, $dbh->errstr);
                return undef;
        }
	return $sth;
}

##############################################
#   db_insert_message
##############################################
# Function used to add a message entry 
# corresponding to a new mail send to a list. This function
# is called when a mail has been received.
# One entry for each mail.
# The entry is added in the given table 
# creating a new database connection. 
#
# IN :-$message (+): the input message to store
#     -$robot (+): the robot correponding to the given message
#     -$list (+): the list to which the message has been initially sent
#
# OUT : 1 | undef
#      
##############################################
sub db_insert_message{
    my ($message, $robot, $list) = @_;

    my $rcpt;
    my $hdr = $message->{'msg'}->head or &do_log('err', "Error : Extract header failed");
    my $cpt = $list->get_total();
    
    &do_log('debug2', "Message extracted  list name : %s  addresses number : %s", $list->{'name'}, $cpt);
    my $subject = $hdr->get('subject');
    chomp($subject);
    &do_log('debug2', "Message extracted : %s", $subject);

    my $send_date = $hdr->get('date');
    chomp($send_date);
    &do_log('debug2', "Message extracted : %s", $send_date);

    my $row_msgid = $hdr->get('Message-Id')or &do_log('notice', "Error : Extract msgID failed");
    chomp($row_msgid);
    &do_log('debug2', "Message extracted : %s", $row_msgid);

    my $content_type = $hdr->get('Content-Type');
    chomp($content_type);
    &do_log('debug2', "Message extracted : %s", $content_type);
 
    my $disposition_notif = $hdr->get('Disposition-Notification-To') or &do_log('notice', "Disposition-Notification Not Asked");
    chomp($disposition_notif);
    &do_log('debug2', "Message extracted : %s", $disposition_notif);

    my $cc = $hdr->get('Cc');
    chomp($cc);
    &do_log('debug2', "Message extracted : %s", $cc);
 
    my $row_from = $hdr->get('from');
    chomp($row_from);
    &do_log('debug2', "Message extracted : %s", $row_from);

    my $msg_string = $message->{'msg'}->as_string;
    &do_log('debug2', 'string message : %s', $msg_string);

    unless($content_type =~ /.*delivery-status.*/){

	&do_log('debug2', 'Waiting....');
	my $message_id = format_msg_id($row_msgid) or &do_log('notice', "Error : Format msgID failed"); 
	return undef unless ($message_id);
	&do_log('debug2', 'Message-Id Formated : %s', $message_id);
	my $from_address = format_from_address($row_from) or &do_log('notice', "Error : Format From address failed"); 
	&do_log('debug2', 'From Address Formated : %s', $from_address);
	my ($to_addresses_nb, @to_addresses) = find_list_user_address($list) or &do_log('notice', "Error : Format To header failed"); 
	return undef unless ($to_addresses_nb);
	foreach my $to_address (@to_addresses) {
		&do_log('debug2', 'To Address Formated : %s', $to_address);
	}
	
        my $dbh = connection($Conf::Conf{'db_name'}, $Conf::Conf{'db_host'}, $Conf::Conf{'db_port'}, $Conf::Conf{'db_user'}, $Conf::Conf{'db_passwd'});
	unless ($dbh and $dbh->ping) {
		&do_log('err', "Error : Can't join database");
		return undef;
	}
	unless (store_message_DB($dbh, $message_table, $message_id, $from_address, $send_date, $subject, $list)) {
                &do_log('err', 'Unable to execute message storage in mail table "%s"', $message_id);
                return undef;
	}
	my $pk_message;
	unless ($pk_message = get_pk_message($dbh, $message_table, $message_id, $list->{'name'}) ){
                &do_log('err', 'Unable to execute message key request on message : "%s"', $message_id);
                return undef;
	}
	
	my $sth;
	foreach my $to (@to_addresses) {

		&do_log('debug2', 'Recipient Address :%s', $to );
		unless ($sth = store_notif_DB($dbh, $notif_table, $pk_message, $status, $to, $list, 'DSN')) {
                	&do_log('err', 'Unable to execute message storage in notification table"%s"', $message_id);
                	return undef;
		}
		if(defined $disposition_notif) {
			unless ($sth = store_notif_DB($dbh, $notif_table, $pk_message, $status, $to, $list, 'MDN')) {
                        	&do_log('err', 'Unable to execute message storage in notification table"%s"', $message_id);
                        	return undef;
			}
		}
	} 
	$sth -> finish;
	$dbh -> disconnect;
	&do_log('notice', 'Successful Mail Treatment :%s', $subject );
    }
    return 1;
}

##############################################
#   db_insert_notification
##############################################
# Function used to add a notification entry 
# corresponding to a new report. This function
# is called when a report has been received.
# It build a new connection with the database
# using the default database parameter. Then it
# search the notification entry identifiant which 
# correspond to the received report. Finally it 
# update the recipient entry concerned by the report.
#
# IN :-$id (+): the identifiant entry of the initial mail
#     -$type (+): the notification entry type (DSN|MDN)
#     -$recipient (+): the list subscriber who correspond to this entry
#     -$msg_id (+): the report message-id
#     -$status (+): the new state of the recipient entry depending of the report data 
#     -$arrival_date (+): the mail arrival date.
#
# OUT : 1 | undef
#      
##############################################
sub db_insert_notification {
	my ($id, $type, $recipient, $msg_id, $status, $arrival_date) = @_;

        my $dbh = connection($Conf::Conf{'db_name'}, $Conf::Conf{'db_host'}, $Conf::Conf{'db_port'}, $Conf::Conf{'db_user'}, $Conf::Conf{'db_passwd'});

        unless ($dbh and $dbh->ping) {
                &do_log('err', "Error : Can't join database");
                return undef;
        }
	my $pk_notif;
        unless ($pk_notif = get_pk_notification($dbh, "notification_table", $id, $recipient, $type)) {
                &do_log('err', 'Unable to get notification identificator :  "%s"', $msg_id);
                return undef;
        }
        &do_log('debug2', "pk_notif value founded : %s", $pk_notif);
        my $sth;

        unless ($sth = update_notif_table($dbh, $notif_table, $pk_notif, $msg_id, $status, $arrival_date) ) {
                &do_log('err', 'Unable to update the notification table : "%s"', $msg_id);
                return undef;
        }
        $sth -> finish;
        $dbh -> disconnect;
        &do_log('notice', 'Successful Notification Treatment :%s', $msg_id);
	return 1;
}

##############################################
#   extract_msgid
##############################################
# Function use in order to get the message-id of the input mail
# 
# IN :-$email (+): the mail to parse
#
# OUT : $msgID
#      
##############################################
sub extract_msgid {
    my $email = Email::Simple->new($_[0]);

    my $msgID;
    my $tmp_msgID = $email->header('Message-ID');

    &do_log('debug2', "Start MessageID extraction recup : %s", $_[0]);
    &do_log('debug2', "Find MessageId : %s", $tmp_msgID);

    if ($tmp_msgID =~ /<(\S+@\S+)>/){
        ($msgID) = $tmp_msgID =~ /<(\S+@\S+)>/;
        }
    elsif ($tmp_msgID =~ /(\S+@\S+)/){
        ($msgID) = $tmp_msgID =~ /(\S+@\S+)/;
        }

    &do_log('debug2', "MessageId extracted : %s", $msgID);
    return $msgID;
}

##############################################
#   find_msg_key
##############################################
# Function used to get the key identificator of
# a mail by asking the database with an input message-id
# 
# IN :-$msgid (+): the input message-id
#     -$listname (+): the name of the list to which the mail
#			has been initially sent.
#
# OUT : $pk | undef
#      
##############################################
sub find_msg_key{

    my $msgid = shift;	
    my $listname = shift;	

    my $pk;
    my $message_id = format_msg_id($msgid) or &do_log('notice', "Error : Format msgID failed");

    return undef unless ($message_id);
    &do_log('debug2', 'Message-Id Formated : %s', $message_id);

    my $dbh = connection($Conf::Conf{'db_name'}, $Conf::Conf{'db_host'}, $Conf::Conf{'db_port'}, $Conf::Conf{'db_user'}, $Conf::Conf{'db_passwd'});
    unless ($dbh and $dbh->ping) {
          &do_log('err', "Error : Can't join database");
          return undef;
    }
    unless($pk = get_pk_message($dbh, "mail_table", $message_id, $listname)) {
          &do_log('err', "Unable to get the pk identificator of the message %s", $message_id);
          return undef;
    }
    $dbh -> disconnect;
    return $pk;
}

##############################################
#   change_mdn_receiver
##############################################
# Function used to change the Disposition-Notification-To value
# in order to return the MDN notification on the Sympa server.
# Then the server will can process to a treatment for correlation mode.
# 
# IN :-$msg_string (+): the input message
#     -$receiver (+): the new value of the disposition-notification-to header
#
# OUT : $email | undef
#      
##############################################
sub change_mdn_receiver{

	my ($msg_string, $receiver) = @_;

  	my $mdn_header;
  	my $email = Email::Simple->new($msg_string);
	
	&do_log('notice', 'Will change Disposition-Notification value to : %s', $receiver);
	if(undef($mdn_header = $email->header("Disposition-Notification-To")) ) {
	    &do_log('err', 'Disposition-Notification-To header not found');
	    return undef;
	}
	else {
   	    $email->header_set("Disposition-Notification-To", "$receiver");
	    &do_log('debug2', 'NEW e-mail Ready to be sent : %s', $email->as_string);
  	    return $email->as_string;
	}
}

##############################################
#   get_delivered_info
##############################################
# Function use to get all the correlation informations of an msg-id.
# Informations are return as a string.
# 
# IN :-$msgid (+): the given message-id
#     -$listname (+): the name of the list to which the mail has initially been sent.
#
# OUT : $infos | undef
#      
##############################################
sub get_delivered_info{
	
    my $msgid = shift;
    my $listname = shift;

    my $pkmsg;
    my @pk_notifs;
    my @recipients;
    my @recipients2;
    my $infos = "Unusual Recipients Deliveries : ";
    my $tmp_infos = "";
    my $nb_rcpt;

    unless($pkmsg = find_msg_key($msgid, $listname)) {
       &do_log('err', "Unable to get the pk identificator of the message %s", $msgid);
       return undef;
    }
    my $dbh = connection($Conf::Conf{'db_name'}, $Conf::Conf{'db_host'}, $Conf::Conf{'db_port'}, $Conf::Conf{'db_user'}, $Conf::Conf{'db_passwd'});
    unless ($dbh and $dbh->ping) {
         &do_log('err', "Error : Can't join database");
         return undef;
    }

    unless($nb_rcpt = get_recipients_number($dbh, $pkmsg)){
       &do_log('err', "Unable to get the number of recipients for message : %s", $msgid);
       return undef;
    }

    unless(@recipients = get_undelivered_recipients($dbh, $pkmsg)){
       &do_log('err', "Unable to get the pk identificators of the notifications for message : %s", $msgid);
       return undef;
    }
    my $i = 0;
    foreach my $recipient (@recipients){
	if( ($i%2) == 0){
		&do_log('debug2', "recipient : %s", $recipient);
		$tmp_infos .= "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<li>ADDRESS : <em>".$recipient."</em>";
	}
	else{
		&do_log('debug2', "status : %s", $recipient);
		$tmp_infos .= "&nbsp;&nbsp;&nbsp;&nbsp;STATUS : <em>".$recipient."</em></li>";
	} 
	$i++;
    }
    $i = $i/2;
    $infos .= "<strong>".$i."/".$nb_rcpt."</strong><br />".$tmp_infos;
    
    my $j = 0;
    if(@recipients2 = get_not_displayed_recipients($dbh, $pkmsg)){
        $infos .= "<br /><br />Recipients who did not read the message yet (or which has refused to send back a notification) :    ";
	$tmp_infos = "";
    	foreach my $recipient (@recipients2){
            &do_log('debug2', "recipient : %s", $recipient);
            $tmp_infos .= "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<li>ADDRESS : <em>".$recipient."</em></li>";
	    $j++;
	}
    $infos .= "<strong>".$j."/".$nb_rcpt."</strong><br />".$tmp_infos;
    }
    $dbh -> disconnect;
    return $infos;
 }

##############################################
#   get_delivered_info_percent
##############################################
# Function use to get all the correlation informations of an msg-id.
# The result is presented in percentage in order to preserve confidentiality.
# 
# IN :-$msgid (+): the given message-id
#     -$listname (+): the name of the list to which the mail has initially been sent.
#
# OUT : $infos | undef
#      
##############################################
sub get_delivered_info_percent{
	
    my $msgid = shift;
    my $listname = shift;

    my $pkmsg;
    my @pk_notifs;
    my @recipients;
    my @recipients2;
    my $infos = "Unusual Recipients Deliveries : ";
    my $tmp_infos = "";
    my $nb_rcpt;

    unless($pkmsg = find_msg_key($msgid, $listname)) {
       &do_log('err', "Unable to get the pk identificator of the message %s", $msgid);
       return undef;
    }
    my $dbh = connection($Conf::Conf{'db_name'}, $Conf::Conf{'db_host'}, $Conf::Conf{'db_port'}, $Conf::Conf{'db_user'}, $Conf::Conf{'db_passwd'});
    unless ($dbh and $dbh->ping) {
         &do_log('err', "Error : Can't join database");
         return undef;
    }

    unless($nb_rcpt = get_recipients_number($dbh, $pkmsg)){
       &do_log('err', "Unable to get the number of recipients for message : %s", $msgid);
       return undef;
    }

    unless(@recipients = get_undelivered_recipients($dbh, $pkmsg)){
       &do_log('err', "Unable to get the pk identificators of the notifications for message : %s", $msgid);
       return undef;
    }
    my $i = 0;
    foreach my $recipient (@recipients){
	if( ($i%2) == 0){
		&do_log('debug2', "recipient : %s", $recipient);
		$tmp_infos .= "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<li>ADDRESS : <em>".$recipient."</em>";
	}
	else{
		&do_log('debug2', "status : %s", $recipient);
		$tmp_infos .= "&nbsp;&nbsp;&nbsp;&nbsp;STATUS : <em>".$recipient."</em></li>";
	} 
	$i++;
    }
    $i = (($i/2)*100)/$nb_rcpt;
    $infos .= "<strong>".$i."%</strong><br />".$tmp_infos;
    
    my $j = 0;
    if(@recipients2 = get_not_displayed_recipients($dbh, $pkmsg)){
        $infos .= "<br /><br />Recipients who did not read the message yet (or which has refused to send back a notification) :    ";
	$tmp_infos = "";
    	foreach my $recipient (@recipients2){
            &do_log('debug2', "recipient : %s", $recipient);
            $tmp_infos .= "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<li>ADDRESS : <em>".$recipient."</em></li>";
	    $j++;
	}
   	$j = ($j*100)/$nb_rcpt;
   	$infos .= "<strong>".$j."%</strong><br />".$tmp_infos;
    }
    $dbh -> disconnect;
    return $infos;
}

##############################################
#   remove_message
##############################################
# Function use to remove the message and the corresponding notifications.
# 
# IN :-$msgid (+): the given message-id
#     -$listname (+): the name of the list to which the mail has initially been sent.
#
# OUT : 1 | undef
#      
##############################################
sub remove_message{
    my $msgid = shift;
    my $listname = shift;

    my $pkmsg;
    my @pk_notifs;

   
    unless($pkmsg = find_msg_key($msgid, $listname)) {
       &do_log('err', "Unable to get the pk identificator of the message %s", $msgid);
       return undef;
    }
    my $dbh = connection($Conf::Conf{'db_name'}, $Conf::Conf{'db_host'}, $Conf::Conf{'db_port'}, $Conf::Conf{'db_user'}, $Conf::Conf{'db_passwd'});
    unless ($dbh and $dbh->ping) {
         &do_log('notice', "Error : Can't join database");
         return undef;
    }
    unless(@pk_notifs = get_pk_notifications($dbh, $pkmsg)) {
        &do_log('err', "Unable to get the pk identificators of notifications corresponding to the message %s", $msgid);
	return undef;
    }
    unless(remove_entry($dbh, "mail", $pkmsg)) {
        &do_log('err', "Unable to remove %s", $pkmsg);
	return undef;
    }
    unless(remove_entries($dbh, "notification", @pk_notifs)) {
        &do_log('err', "Unable to remove %s", @pk_notifs);
	return undef;
    }
    $dbh -> disconnect;
    return 1;
}

##############################################
#   remove_entry
##############################################
# Function use to remove the entry in argument to the given datatable
# 
# IN :-$dbh (+): the database connection
#     -$table (+): the given table to update
#     -$pk (+): the entry identifiant
#
# OUT : $sth | undef
#      
##############################################
sub remove_entry{
    my $dbh = shift;
    my $table = shift;
    my $pk = shift;

    my $sth;
    my $table_name = $table."_table";
    my $pk_header = "pk_".$table;
    my $request = "DELETE FROM $table_name WHERE `$pk_header` = '$pk'";

    &do_log('debug2', 'Request For Table : : %s', $request);
    unless ($sth = $dbh->prepare($request)) {
            &do_log('err','Unable to prepare SQL statement "%s": %s', $request, $dbh->errstr);
            return undef;
    }
    unless ($sth->execute()) {
            &do_log('err','Unable to execute SQL statement "%s" : %s', $request, $dbh->errstr);
            return undef;
    }
    $sth -> finish;
    return 1;
}

##############################################
#   remove_entries
##############################################
# Function use to remove several entries in argument to the given datatable
# 
# IN :-$dbh (+): the database connection
#     -$table (+): the given table to update
#     -@pk (+): entry identifiants
#
# OUT : $sth | undef
#      
##############################################
sub remove_entries{
    my ($dbh, $table, @pks) = @_;

    foreach my $pk (@pks) {
    	unless(remove_entry($dbh, $table, $pk)){
            &do_log('err','Unable to remove entries; error on "%s"', $pk);
            return undef;
	}
    }
    return 1;
}

1;
