# Chalenge.pm - This module includes functions managing email chalenge
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


package Chalenge;

use Exporter;
@ISA = ('Exporter');
@EXPORT = ();


use Digest::MD5;
use POSIX;
use CGI::Cookie;
use Log;
use Conf;
use SympaSession;
use Time::Local;
use Text::Wrap;

use strict ;


# this structure is used to define which session attributes are stored in a dedicated database col where others are compiled in col 'data_session'
my %chalenge_hard_attributes = ('id_chalenge' => 1, 'date' => 1, 'robot'  => 1,'email' => 1, 'list' => 1);


# cerate a chalenge context and store it in chalenge table
sub create {
    my ($robot, $email, $context) = @_;

    do_log('debug', 'Chalenge::new(%s, %s, %s)', $chalenge_id, $email, $robot);

    my $chalenge={};
    
    unless ($robot) {
	&do_log('err', 'Missing robot parameter, cannot create chalenge object') ;
	return undef;
    }
    
    unless ($email) {
	&do_log('err', 'Missing email parameter, cannot create chalenge object') ;
	return undef;
    }

    $chalenge->{'id_chalenge'} = &get_random();
    $chalenge->{'email'} = $email
    $chalenge->{'date'} = time;
    $chalenge->{'robot'} = $robot; 
    $chalenge->{'data'} = $context;
    return undef unless (&Chalenge::store($chalenge));
    return $chalenge->{'id_chalenge'}     
}
    


sub load {

    my $id_chalenge = shift;

    do_log('debug', 'Chalenge::load(%s)', $id_chalenge);

    unless ($chalenge_id) {
	do_log('err', 'Chalenge::load() : internal error, SympaSession::load called with undef id_chalenge');
	return undef;
    }
    
    my $statement ;

    if ($Conf{'db_type'} eq 'Oracle') {
	## "AS" not supported by Oracle
	$statement = sprintf "SELECT id_chalenge \"id_chalenge\", date_chalenge \"date\", robot_chalenge \"robot\", email_chalenge \"email\", data_chalenge \"data\" FROM chalenge_table WHERE id_chalenge = %s", $id_chalenge;
    }else {
	$statement = sprintf "SELECT id_chalenge AS id_chalenge, date_chalenge AS date, remote_addr_chalenge AS remote_addr, robot_chalenge AS robot, email_chalenge AS email, data_chalenge AS data, hit_chalenge AS hit, start_date_chalenge AS start_date FROM chalenge_table WHERE id_chalenge = %s", $cookie;
    }    
    my $dbh = &List::db_get_handler();
    my $sth;

    ## Check database connection
    unless ($dbh and $dbh->ping) {
	return undef unless &db_connect();
    }
    unless ($sth = $dbh->prepare($statement)) {
	do_log('err','Unable to prepare SQL statement : %s', $dbh->errstr);
	return undef;
    }
    unless ($sth->execute) {
	do_log('err','Unable to execute SQL statement "%s" : %s', $statement, $dbh->errstr);
	return undef;
    }    
    my $chalenge = $sth->fetchrow_hashref;
    $sth->finish();
    
    unless ($chalenge) {
	do_log('info',"xxxxxxxxxxxx chalenge from client not found in chalenge_table");
	return 'not_found';
    }
    my $chalenge_datas

    my %datas= &tools::string_2_hash($chalenge->{'data'});
    foreach my $key (keys %datas) {$chalenge_datas->{$key} = $datas{$key};} 

    $chalenge_datas->{'id_chalenge'} = $chalenge->{'id_chalenge'};
    $chalenge_datas->{'date'} = $chalenge->{'date'};
    $chalenge_datas->{'robot'} = $chalenge->{'robot'};
    $chalenge_datas->{'email'} = $chalenge->{'email'};

    my $del_statement = sprintf "DELETE FROM chalenge_table WHERE (id_chalenge=%s)",$id_chalenge;
	do_log('debug3', 'chalenge::load() : removing existing chalenge del_statement = %s',$del_statement);	
	unless ($dbh->do($del_statement)) {
	    do_log('info','Chalenge::load unable to remove existing chalenge %s ',$id_chalenge);
	    return undef;
	}	

    return ('expired') if (time - $chalenge_datas->{'date'} >= &tools::duration_conv($Conf{'chalenge_table_ttl'}));
    return ($chalenge_datas);
}


sub store {

    my $chalenge = shift;
    do_log('debug', 'Chalenge::store()');

    return undef unless ($chalenge->{'id_chalenge'});

    my %hash ;    
    foreach my $var (keys %$chalenge ) {
	next if ($chalenge_hard_attributes{$var});
	next unless ($var);
	$hash{$var} = $chalenge->{$var};
    }
    my $data_string = &tools::hash_2_string (\%hash);
    my $dbh = &List::db_get_handler();
    my $sth;

    ## Check database connection
    unless ($dbh and $dbh->ping) {
	return undef unless &db_connect();
    }	   

    my $add_statement = sprintf "INSERT INTO chalenge_table (id_chalenge, date_chalenge, robot_chalenge, email_chalenge, data_chalenge) VALUES ('%s','%s','%s','%s','%s'')",$chalenge->{'id_chalenge'},$chalenge->{'date'},$chalenge->{'robot'},$chalenge->{'email'},$data_string;
    do_log('info', 'xxxxxxxx Chalenge::store() : add_statement = %s',$add_statement);
    unless ($dbh->do($add_statement)) {
	do_log('err','Unable to store chalenge information in database while execute SQL statement "%s" : %s', $add_statement, $dbh->errstr);
	return undef;
    }    
}

1;

