# Challenge.pm - This module includes functions managing email challenges
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


package Challenge;

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
my %challenge_hard_attributes = ('id_challenge' => 1, 'date' => 1, 'robot'  => 1,'email' => 1, 'list' => 1);


# create a challenge context and store it in challenge table
sub create {
    my ($robot, $email, $context) = @_;

    do_log('debug', 'Challenge::new(%s, %s, %s)', $challenge_id, $email, $robot);

    my $challenge={};
    
    unless ($robot) {
	&do_log('err', 'Missing robot parameter, cannot create challenge object') ;
	return undef;
    }
    
    unless ($email) {
	&do_log('err', 'Missing email parameter, cannot create challenge object') ;
	return undef;
    }

    $challenge->{'id_challenge'} = &get_random();
    $challenge->{'email'} = $email
    $challenge->{'date'} = time;
    $challenge->{'robot'} = $robot; 
    $challenge->{'data'} = $context;
    return undef unless (&Challenge::store($challenge));
    return $challenge->{'id_challenge'}     
}
    


sub load {

    my $id_challenge = shift;

    do_log('debug', 'Challenge::load(%s)', $id_challenge);

    unless ($challenge_id) {
	do_log('err', 'Challenge::load() : internal error, SympaSession::load called with undef id_challenge');
	return undef;
    }
    
    my $statement ;

    $statement = sprintf "SELECT id_challenge AS id_challenge, date_challenge AS date, remote_addr_challenge AS remote_addr, robot_challenge AS robot, email_challenge AS email, data_challenge AS data, hit_challenge AS hit, start_date_challenge AS start_date FROM challenge_table WHERE id_challenge = %s", $cookie;

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
    my $challenge = $sth->fetchrow_hashref;
    $sth->finish();
    
    unless ($challenge) {
	return 'not_found';
    }
    my $challenge_datas

    my %datas= &tools::string_2_hash($challenge->{'data'});
    foreach my $key (keys %datas) {$challenge_datas->{$key} = $datas{$key};} 

    $challenge_datas->{'id_challenge'} = $challenge->{'id_challenge'};
    $challenge_datas->{'date'} = $challenge->{'date'};
    $challenge_datas->{'robot'} = $challenge->{'robot'};
    $challenge_datas->{'email'} = $challenge->{'email'};

    my $del_statement = sprintf "DELETE FROM challenge_table WHERE (id_challenge=%s)",$id_challenge;
	do_log('debug3', 'Challenge::load(): removing existing challenge del_statement = %s',$del_statement);	
	unless ($dbh->do($del_statement)) {
	    do_log('info','Challenge::load(): unable to remove existing challenge %s ',$id_challenge);
	    return undef;
	}	

    return ('expired') if (time - $challenge_datas->{'date'} >= &tools::duration_conv($Conf{'challenge_table_ttl'}));
    return ($challenge_datas);
}


sub store {

    my $challenge = shift;
    do_log('debug', 'Challenge::store()');

    return undef unless ($challenge->{'id_challenge'});

    my %hash ;    
    foreach my $var (keys %$challenge ) {
	next if ($challenge_hard_attributes{$var});
	next unless ($var);
	$hash{$var} = $challenge->{$var};
    }
    my $data_string = &tools::hash_2_string (\%hash);
    my $dbh = &List::db_get_handler();
    my $sth;

    ## Check database connection
    unless ($dbh and $dbh->ping) {
	return undef unless &db_connect();
    }	   

    my $add_statement = sprintf "INSERT INTO challenge_table (id_challenge, date_challenge, robot_challenge, email_challenge, data_challenge) VALUES ('%s','%s','%s','%s','%s'')",$challenge->{'id_challenge'},$challenge->{'date'},$challenge->{'robot'},$challenge->{'email'},$data_string;
    unless ($dbh->do($add_statement)) {
	do_log('err','Unable to store challenge information in database while execute SQL statement "%s" : %s', $add_statement, $dbh->errstr);
	return undef;
    }    
}

1;

