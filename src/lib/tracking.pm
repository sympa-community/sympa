# Tracking.pm - this module does the mail tracking processing
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

package tracking;

use strict;

use DBI;
use CGI;
use Email::Simple;
use Log;
use MIME::Base64;




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
#   get_recipients_status
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
sub get_recipients_status {
#        my $dbh = shift;
        my $msgid  = shift;
	my $listname = shift;
        my $robot =shift;

        &do_log('debug2', 'get_recipients_status(%s,%s,%s)', $msgid,$listname,$robot);

	my $dbh = &List::db_get_handler();

	## Check database connection
	unless ($dbh and $dbh->ping) {
	    return undef unless &List::db_connect();
	}
	
        my $sth;
        my $pk;

	# the message->head method return message-id including <blabla@dom> where mhonarc return blabla@dom that's why we test both of them
        my $request = sprintf "SELECT recipient_notification AS recipient,  reception_option_notification AS reception_option, status_notification AS status, arrival_date_notification AS arrival_date, type_notification as type, message_notification as notification_message FROM notification_table WHERE (list_notification = %s AND robot_notification = %s AND (message_id_notification = %s OR CONCAT('<',message_id_notification,'>') = %s OR message_id_notification = %s ))",$dbh->quote($listname),$dbh->quote($robot),$dbh->quote($msgid),$dbh->quote($msgid),$dbh->quote('<'.$msgid.'>');
	
        unless ($sth = $dbh->prepare($request)) {
                &do_log('err','Unable to prepare SQL statement : %s', $dbh->errstr);
                return undef;
        }
        unless ($sth->execute) {
                &do_log('err','Unable to execute SQL statement "%s" : %s', $request, $dbh->errstr);
                return undef;
        }
        my @pk_notifs;
        while (my $pk_notif = $sth->fetchrow_hashref){
	    if ($pk_notif->{'notification_message'}) { 
		$pk_notif->{'notification_message'} = MIME::Base64::decode($pk_notif->{'notification_message'});
	    }else{
		$pk_notif->{'notification_message'} = '';
	    }	    
	    push @pk_notifs, $pk_notif;
        }
        $sth->finish();
        return \@pk_notifs;	
}

##############################################
#   db_init_notification_table
##############################################
# Function used to initialyse notification table for each subscriber
# IN : 
#   listname
#   robot,
#   msgid  : the messageid of the original message
#   rcpt : a tab ref of recipients
#   reception_option : teh reception option of thoses subscribers
# OUT : 1 | undef
#      
##############################################
sub db_init_notification_table{

    my %params = @_;
    my $msgid =  $params{'msgid'}; chomp $msgid;
    my $listname =  $params{'listname'};
    my $robot =  $params{'robot'};
    my $reception_option =  $params{'reception_option'};
    my @rcpt =  @{$params{'rcpt'}};
    
    &do_log('debug2', "db_init_notification_table (msgid = %s, listname = %s, reception_option = %s",$msgid,$listname,$reception_option);

    my $dbh = connection($Conf::Conf{'db_name'}, $Conf::Conf{'db_host'}, $Conf::Conf{'db_port'}, $Conf::Conf{'db_user'}, $Conf::Conf{'db_passwd'});
    unless ($dbh and $dbh->ping) {
	&do_log('err', "Error : Can't join database");
	return undef;
    }
    
    my $sth;
    
    foreach my $email (@rcpt){
	my $email= lc($email);
	
	my $request = sprintf "INSERT INTO notification_table (message_id_notification,recipient_notification,reception_option_notification,list_notification,robot_notification) VALUES (%s,%s,%s,%s,%s)",$dbh->quote($msgid),$dbh->quote($email),$dbh->quote($reception_option),$dbh->quote($listname),$dbh->quote($robot);
	
	unless ($sth = $dbh->prepare($request)) {
                &do_log('err','Unable to prepare SQL statement "%s": %s', $request, $dbh->errstr);
                return undef;
	}
	unless ($sth->execute()) {
                &do_log('err','Unable to execute SQL statement "%s" : %s', $request, $dbh->errstr);
                return undef;
	}


    } 
    $sth -> finish;
    $dbh -> disconnect;
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
#     -$notification_as_string : the DSN or the MDM as string
#
# OUT : 1 | undef
#      
##############################################
sub db_insert_notification {
    my ($notification_id, $type, $status, $arrival_date ,$notification_as_string  ) = @_;
    
    &do_log('debug2', "db_insert_notification  :notification_id : %s, type : %s, recipient : %s, msgid : %s, status :%s",$notification_id, $type, $status); 
    
    chomp $arrival_date;
    
    my $dbh = connection($Conf::Conf{'db_name'}, $Conf::Conf{'db_host'}, $Conf::Conf{'db_port'}, $Conf::Conf{'db_user'}, $Conf::Conf{'db_passwd'});
    
    unless ($dbh and $dbh->ping) { 
	&do_log('err', "Error : Can't join database"); 
	return undef; 
    } 
    
    $notification_as_string = MIME::Base64::encode($notification_as_string);
    
    my $request = sprintf "UPDATE notification_table SET  `status_notification` = %s, `arrival_date_notification` = %s, `message_notification` = %s WHERE (pk_notification = %s)",$dbh->quote($status),$dbh->quote($arrival_date),$dbh->quote($notification_as_string),$dbh->quote($notification_id);

    # my $request_trace = sprintf "UPDATE notification_table SET  `status_notification` = %s, `arrival_date_notification` = %s, WHERE (pk_notification = %s)",$dbh->quote($status),$dbh->quote($arrival_date),$dbh->quote($notification_id);
    
    my $sth;
    
    unless ($sth = $dbh->prepare($request)) {
	&do_log('err','Unable to prepare SQL statement "%s": %s', $request, $dbh->errstr);
	return undef;
    }
    unless ($sth->execute()) {
	&do_log('err','Unable to execute SQL statement "%s" : %s', $request, $dbh->errstr);
	return undef;
    }
    
    $sth -> finish;
    $dbh -> disconnect;

    return 1;
}

##############################################
#   find_notification_id_by_message
##############################################
# return the tracking_id find by recipeint,message-id,listname and robot
# tracking_id areinitialized by sympa.pl by List::distribute_msg
# 
# used by bulk.pl in order to set return_path when tracking is required.
#      
##############################################

sub find_notification_id_by_message{
    my $recipient = shift;	
    my $msgid = shift;	chomp $msgid;
    my $listname = shift;	
    my $robot = shift;

    do_log('debug2','find_notification_id_by_message(%s,%s,%s,%s)',$recipient,$msgid ,$listname,$robot );
    my $pk;

    my $dbh = connection($Conf::Conf{'db_name'}, $Conf::Conf{'db_host'}, $Conf::Conf{'db_port'}, $Conf::Conf{'db_user'}, $Conf::Conf{'db_passwd'});
    unless ($dbh and $dbh->ping) {
          &do_log('err', "Error : Can't join database");
          return undef;
    }
    
    # the message->head method return message-id including <blabla@dom> where mhonarc return blabla@dom that's why we test both of them
    my $request = sprintf "SELECT pk_notification FROM notification_table WHERE ( recipient_notification = %s AND list_notification = %s AND robot_notification = %s AND (message_id_notification = %s OR CONCAT('<',message_id_notification,'>') = %s OR message_id_notification = %s ))", $dbh->quote($recipient),$dbh->quote($listname),$dbh->quote($robot),$dbh->quote($msgid),$dbh->quote($msgid),$dbh->quote('<'.$msgid.'>');
    
    my $sth;

    unless ($sth = $dbh->prepare($request)) {
	&do_log('err','Unable to prepare SQL statement %s : %s', $request, $dbh->errstr);
	return undef;
    }
    unless ($sth->execute) {
	&do_log('err','Unable to execute SQL statement "%s" : %s', $request, $dbh->errstr);
	return undef;
    }
    
    my @pk_notifications = $sth->fetchrow_array;
    if ($#pk_notifications > 0){
	&do_log('err','Found more then one pk_notification maching  (recipient=%s,msgis=%s,listname=%s,robot%s)',$recipient,$msgid ,$listname,$robot );	
	# we should return undef...
    }
    $sth->finish();
    $dbh -> disconnect;
    return @pk_notifications[0];
}

##############################################
#   remove_notifications
##############################################
# Function use to remove notifications in argument to the given datatable
# 
# IN :-$dbh (+): the database connection
#    : $msgid : id of related message
#    : $listname
#    : $robot
#
# OUT : $sth | undef
#      
##############################################
sub remove_notifications{
    my $dbh = shift;
    my $msgid =shift;
    my $listname =shift;
    my $robot =shift;

    &do_log('debug2', 'Remove notification id =  %s, listname = %s, robot = %s', $msgid,$listname,$robot );
    my $sth;

    my $request = sprintf "DELETE FROM notification_table WHERE `message_id_notification` = %s AND list_notification = %s AND robot_notification = %s", $dbh->quote($msgid),$dbh->quote($listname),$dbh->quote($robot);


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

1;
