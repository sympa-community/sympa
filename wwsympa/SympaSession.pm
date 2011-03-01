# SympaSession.pm - This module includes functions managing HTTP sessions in Sympa
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


package SympaSession;

use strict ;

use Digest::MD5;
use POSIX;
use CGI::Cookie;
use Time::Local;

use Log;
use Conf;

# this structure is used to define which session attributes are stored in a dedicated database col where others are compiled in col 'data_session'
my %session_hard_attributes = ('id_session' => 1, 
			       'date' => 1, 
			       'remote_addr'  => 1,
			       'robot'  => 1,
			       'email' => 1, 
			       'start_date' => 1, 
			       'hit' => 1,
			       'new_session' => 1,
			      );


sub new {
    my $pkg = shift; 
    my $robot = shift;
    my $context = shift;

    my $cookie = $context->{'cookie'};
    my $action = $context->{'action'};
    my $rss = $context->{'rss'};
    my $ajax =  $context->{'ajax'};

    &Log::do_log('debug', 'SympaSession::new(%s,%s,%s)', $robot,$cookie,$action);
    my $session={};
    bless $session, $pkg;
    
    unless ($robot) {
	&Log::do_log('err', 'Missing robot parameter, cannot create session object') ;
	return undef;
    }

#   passive_session are session not stored in the database, they are used for crawler bots and action such as css, wsdl, ajax and rss
    
    if (&tools::is_a_crawler($robot,{'user_agent_string' => $ENV{'HTTP_USER_AGENT'}})) {
	$session->{'is_a_crawler'} = 1;
	$session->{'passive_session'} = 1;
    }
    $session->{'passive_session'} = 1 if ($rss||$action eq 'wsdl'||$action eq 'css');

    # if a session cookie exist, try to restore an existing session, don't store sessions from bots
    if (($cookie)&&($session->{'passive_session'} != 1)){
	my $status ;
	$status = $session->load($cookie);
	unless (defined $status) {
	    return undef;
	}
	if ($status eq 'not_found') {
	    &Log::do_log('info',"SympaSession::new ignoring unknown session cookie '$cookie'" ); # start a new session (may ne a fake cookie)
	    return (new SympaSession ($robot));
	}
	# checking if the client host is unchanged during the session brake sessions when using multiple proxy with
        # load balancing (round robin, etc). This check is removed until we introduce some other method
	# if($session->{'remote_addr'} ne $ENV{'REMOTE_ADDR'}){
	#    &Log::do_log('info','SympaSession::new ignoring session cookie because remote host %s is not the original host %s', $ENV{'REMOTE_ADDR'},$session->{'remote_addr'}); # start a new session
	#    return (new SympaSession ($robot));
	#}
    }else{
	# create a new session context
	$session->{'new_session'} = 1; ## Tag this session as new, ie no data in the DB exist
        $session->{'id_session'} = &get_random();
	$session->{'email'} = 'nobody';
        $session->{'remote_addr'} = $ENV{'REMOTE_ADDR'};
	$session->{'date'} = time;
	$session->{'start_date'} = time;
	$session->{'hit'} = 1;
	$session->{'robot'} = $robot; 
	$session->{'data'} = '';
    }
    return $session;
}

sub load {
    my $self = shift;
    my $cookie = shift;

    &Log::do_log('debug', 'SympaSession::load(%s)', $cookie);

    unless ($cookie) {
	&Log::do_log('err', 'SympaSession::load() : internal error, SympaSession::load called with undef id_session');
	return undef;
    }
    
    my $sth;

    unless ($sth = &SDM::do_prepared_statement("SELECT id_session AS id_session, date_session AS \"date\", remote_addr_session AS remote_addr, robot_session AS robot, email_session AS email, data_session AS data, hit_session AS hit, start_date_session AS start_date FROM session_table WHERE id_session = ?",$cookie)) {
	&Log::do_log('err','Unable to load session %s', $cookie);
	return undef;
    }

    my $session = $sth->fetchrow_hashref('NAME_lc');

    if ( $sth->fetchrow_hashref('NAME_lc')){
	&Log::do_log('err',"the SQL statement %s did return more then one session. Is this a bug comming from dbi or mysql ? ");
	$session->{'email'} = '';
    }
    
    unless ($session) {
	return 'not_found';
    }
    
    my %datas= &tools::string_2_hash($session->{'data'});
    foreach my $key (keys %datas) {$self->{$key} = $datas{$key};} 

    $self->{'id_session'} = $session->{'id_session'};
    $self->{'date'} = $session->{'date'};
    $self->{'start_date'} = $session->{'start_date'};
    $self->{'hit'} = $session->{'hit'} +1 ;
    $self->{'remote_addr'} = $session->{'remote_addr'};
    $self->{'robot'} = $session->{'robot'};
    $self->{'email'} = $session->{'email'};    

    return ($self);
}

## This method will both store the session information in the database
sub store {

    my $self = shift;
    &Log::do_log('debug', '');

    return undef unless ($self->{'id_session'});
    return if ($self->{'is_a_crawler'}); # do not create a session in session table for crawlers; 
    return if ($self->{'passive_session'}); # do not create a session in session table for action such as RSS or CSS or wsdlthat do not require this sophistication; 

    my %hash ;    
    foreach my $var (keys %$self ) {
	next if ($session_hard_attributes{$var});
	next unless ($var);
	$hash{$var} = $self->{$var};
    }
    my $data_string = &tools::hash_2_string (\%hash);

    ## If this is a new session, then perform an INSERT
    if ($self->{'new_session'}) {
	## Store the new session ID in the DB
	unless(&SDM::do_query( "INSERT INTO session_table (id_session, date_session, remote_addr_session, robot_session, email_session, start_date_session, hit_session, data_session) VALUES (%s,%d,%s,%s,%s,%d,%d,%s)",&SDM::quote($self->{'id_session'}),time,&SDM::quote($ENV{'REMOTE_ADDR'}),&SDM::quote($self->{'robot'}),&SDM::quote($self->{'email'}),$self->{'start_date'},$self->{'hit'}, &SDM::quote($data_string))) {
	    &Log::&Log::do_log('err','Unable to add new session %s informations in database', $self->{'id_session'});
	    return undef;
	}   
      ## If the session already exists in DB, then perform an UPDATE
    }else {
	## Update the new session in the DB
	unless(&SDM::do_query("UPDATE session_table SET date_session=%d, remote_addr_session=%s, robot_session=%s, email_session=%s, start_date_session=%d, hit_session=%d, data_session=%s WHERE (id_session=%s)",time,&SDM::quote($ENV{'REMOTE_ADDR'}),&SDM::quote($self->{'robot'}),&SDM::quote($self->{'email'}),$self->{'start_date'},$self->{'hit'}, &SDM::quote($data_string), &SDM::quote($self->{'id_session'}))) {
	    &Log::&Log::do_log('err','Unable to update session %s information in database', $self->{'id_session'});
	    return undef;
	}    
    }

    return 1;
}

## This method will renew the session ID 
sub renew {

    my $self = shift;
    &Log::do_log('debug', 'id_session=(%s)',$self->{'id_session'});

    return undef unless ($self->{'id_session'});
    return if ($self->{'is_a_crawler'}); # do not create a session in session table for crawlers; 
    return if ($self->{'passive_session'}); # do not create a session in session table for action such as RSS or CSS or wsdlthat do not require this sophistication; 

    my %hash ;    
    foreach my $var (keys %$self ) {
	next if ($session_hard_attributes{$var});
	next unless ($var);
	$hash{$var} = $self->{$var};
    }
    my $data_string = &tools::hash_2_string (\%hash);

    ## Renew the session ID in order to prevent session hijacking
    my $new_id = &get_random();

    ## First remove the DB entry for the previous session ID
    unless(&SDM::do_query("UPDATE session_table SET id_session=%s WHERE (id_session=%s)",&SDM::quote($new_id), &SDM::quote($self->{'id_session'}))) {
	&Log::&Log::do_log('err','Unable to renew session ID for session %s',$self->{'id_session'});
	return undef;
    }	 

    ## Renew the session ID in order to prevent session hijacking
    $self->{'id_session'} = $new_id;

    return 1;
}

## remove old sessions from a particular robot or from all robots. delay is a parameter in seconds
## 
sub purge_old_sessions {

    my $robot = shift;

    &Log::do_log('info', 'SympaSession::purge_old_sessions(%s,%s)',$robot);

    my $delay = &tools::duration_conv($Conf{'session_table_ttl'}) ; 
    my $anonymous_delay = &tools::duration_conv($Conf{'anonymous_session_table_ttl'}) ; 

    unless ($delay) { &Log::do_log('info', 'SympaSession::purge_old_session(%s) exit with delay null',$robot); return;}
    unless ($anonymous_delay) { &Log::do_log('info', 'SympaSession::purge_old_session(%s) exit with anonymous delay null',$robot); return;}

    my @sessions ;
    my  $sth;

    my $robot_condition = sprintf "robot_session = %s", &SDM::quote($robot) unless (($robot eq '*')||($robot));

    my $delay_condition = time-$delay.' > date_session' if ($delay);
    my $anonymous_delay_condition = time-$anonymous_delay.' > date_session' if ($anonymous_delay);

    my $and = ' AND ' if (($delay_condition) && ($robot_condition));
    my $anonymous_and = ' AND ' if (($anonymous_delay_condition) && ($robot_condition));

    my $count_statement = sprintf "SELECT count(*) FROM session_table WHERE $robot_condition $and $delay_condition";
    my $anonymous_count_statement = sprintf "SELECT count(*) FROM session_table WHERE $robot_condition $anonymous_and $anonymous_delay_condition AND email_session = 'nobody' AND hit_session = '1'";


    my $statement = sprintf "DELETE FROM session_table WHERE $robot_condition $and $delay_condition";
    my $anonymous_statement = sprintf "DELETE FROM session_table WHERE $robot_condition $anonymous_and $anonymous_delay_condition AND email_session = 'nobody' AND hit_session = '1'";

    unless ($sth = &SDM::do_query($count_statement)) {
	&Log::do_log('err','Unable to count old session for robot %s',$robot);
	return undef;
    }
    
    my $total =  $sth->fetchrow;
    if ($total == 0) {
	&Log::do_log('debug','SympaSession::purge_old_sessions no sessions to expire');
    }else{
	unless ($sth = &SDM::do_query($statement)) {
	    &Log::do_log('err','Unable to purge old sessions for robot %s', $robot);
	    return undef;
	}
    }
    unless ($sth = &SDM::do_query($anonymous_count_statement)) {
	&Log::do_log('err','Unable to count anonymous sessions for robot %s', $robot);
	return undef;
    }
    my $anonymous_total =  $sth->fetchrow;
    if ($anonymous_total == 0) {
	&Log::do_log('debug','SympaSession::purge_old_sessions no anonymous sessions to expire');
	return $total ;
    }
    unless ($sth = &SDM::do_query($anonymous_statement)) {
	&Log::do_log('err','Unable to purge anonymous sessions for robot %s',$robot);
	return undef;
    }
    return $total+$anonymous_total;
}


## remove old one_time_ticket from a particular robot or from all robots. delay is a parameter in seconds
## 
sub purge_old_tickets {

    my $robot = shift;

    &Log::do_log('info', 'SympaSession::purge_old_tickets(%s,%s)',$robot);

    my $delay = &tools::duration_conv($Conf{'one_time_ticket_table_ttl'}) ; 

    unless ($delay) { &Log::do_log('info', 'SympaSession::purge_old_tickets(%s) exit with delay null',$robot); return;}

    my @tickets ;
    my  $sth;

    my $robot_condition = sprintf "robot_one_time_ticket = %s", &SDM::quote($robot) unless (($robot eq '*')||($robot));
    my $delay_condition = time-$delay.' > date_one_time_ticket' if ($delay);
    my $and = ' AND ' if (($delay_condition) && ($robot_condition));
    my $count_statement = sprintf "SELECT count(*) FROM one_time_ticket_table WHERE $robot_condition $and $delay_condition";
    my $statement = sprintf "DELETE FROM one_time_ticket_table WHERE $robot_condition $and $delay_condition";

    unless ($sth = &SDM::do_query($count_statement)) {
	&Log::do_log('err','Unable to count old one time tickets for robot %s',$robot);
	return undef;
    }
    
    my $total =  $sth->fetchrow;
    if ($total == 0) {
	&Log::do_log('debug','SympaSession::purge_old_tickets no tickets to expire');
    }else{
	unless ($sth = &SDM::do_query($statement)) {
	    &Log::do_log('err','Unable to delete expired one time tickets for robot %s',$robot);
	    return undef;
	}
    }
    return $total;
}

# list sessions for $robot where last access is newer then $delay. List is limited to connected users if $connected_only
sub list_sessions {
    my $delay = shift;
    my $robot = shift;
    my $connected_only = shift;

    &Log::do_log('debug', 'SympaSession::list_session(%s,%s,%s)',$delay,$robot,$connected_only);

    my @sessions ;
    my $sth;

    my $condition = sprintf "robot_session = %s", &SDM::quote($robot) unless ($robot eq '*');
    my $condition2 = time-$delay.' < date_session ' if ($delay);
    my $and = ' AND ' if (($condition) && ($condition2));
    $condition = $condition.$and.$condition2 ;

    my $condition3 =  " email_session != 'nobody' " if ($connected_only eq 'on');
    my $and2 = ' AND '  if (($condition) && ($condition3));
    $condition = $condition.$and2.$condition3 ;

    my $statement = sprintf "SELECT remote_addr_session, email_session, robot_session, date_session, start_date_session, hit_session FROM session_table WHERE $condition";
    &Log::do_log('debug', 'SympaSession::list_session() : statement = %s',$statement);

    unless ($sth = &SDM::do_query($statement)) {
	&Log::do_log('err','Unable to get the list of sessions for robot %s',$robot);
	return undef;
    }
    
    while (my $session = ($sth->fetchrow_hashref('NAME_lc'))) {

	$session->{'formated_date'} = &Language::gettext_strftime ("%d %b %y  %H:%M", localtime($session->{'date_session'}));
	$session->{'formated_start_date'} = &Language::gettext_strftime ("%d %b %y  %H:%M", localtime($session->{'start_date_session'}));

	push @sessions, $session;
    }

    return \@sessions;
}

###############################
# Subroutines to read cookies #
###############################

## Generic subroutine to get a cookie value
sub get_session_cookie {
    my $http_cookie = shift;

    if ($http_cookie =~/\S+/g) {
	my %cookies = parse CGI::Cookie($http_cookie);
	foreach (keys %cookies) {
	    my $cookie = $cookies{$_};
	    next unless ($cookie->name eq 'sympa_session');
	    return ($cookie->value);
	}
    }

    return (undef);
}


## Generic subroutine to set a cookie
## Set user $email cookie, ckecksum use $secret, expire=(now|session|#sec) domain=(localhost|<a domain>)
sub set_cookie {
    my ($self, $http_domain, $expires,$use_ssl) = @_ ;
    &Log::do_log('debug','Session::set_cookie(%s,%s,secure= %s)',$http_domain, $expires,$use_ssl );

    my $expiration;
    if ($expires =~ /now/i) {
	## 10 years ago
	$expiration = '-10y';
    }else{
	$expiration = '+'.$expires.'m';
    }

    if ($http_domain eq 'localhost') {
	$http_domain="";
    }

    my $cookie;
    if ($expires =~ /session/i) {
	$cookie = new CGI::Cookie (-name    => 'sympa_session',
				   -value   => $self->{'id_session'},
				   -domain  => $http_domain,
				   -path    => '/',
				   -secure => $use_ssl,
				   -httponly => 1 
				   );
    }else {
	$cookie = new CGI::Cookie (-name    => 'sympa_session',
				   -value   => $self->{'id_session'},
				   -expires => $expiration,
				   -domain  => $http_domain,
				   -path    => '/',
				   -secure => $use_ssl,
				   -httponly => 1 
				   );
    }

    ## Send cookie to the client
    printf "Set-Cookie: %s\n", $cookie->as_string;
    return 1;
}
    

sub get_random {
    &Log::do_log('debug', 'SympaSession::random ');
     my $random = int(rand(10**7)).int(rand(10**7)); ## Concatenates 2 integers for a better entropy
     $random =~ s/^0(\.|\,)//;
     return ($random)
}

## Return the session object content, as a hashref
sub as_hashref {
  my $self = shift;
  my $data;
  
  foreach my $key (keys %{$self}) {
    $data->{$key} = $self->{$key};
  }
  
  return $data;
}

## Return 1 if the Session object corresponds to an anonymous session.
sub is_anonymous {
    my $self = shift;
    if($self->{'email'} eq 'nobody' || $self->{'email'} eq '') {
	return 1;
    }else{
	return 0;
    }
}

1;

