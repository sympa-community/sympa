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

use strict;

#use Digest::MD5; # no longer used
#use POSIX; # no longer used
use CGI::Cookie;
#use Time::Local; # not used

#use Conf; # no longer used
#use Log; # used by SDM
use SDM;

# this structure is used to define which session attributes are stored in a
# dedicated database col where others are compiled in col 'data_session'
my %session_hard_attributes = ('id_session' => 1, 
			       'date' => 1, 
			       'remote_addr'  => 1,
			       'robot'  => 1,
			       'email' => 1, 
			       'start_date' => 1, 
			       'refresh_date' => 1,
			       'hit' => 1,
			       'new_session' => 1,
			      );

sub new {
    my $pkg = shift; 
    my $robot = Robot::clean_robot(shift, 1); #FIXME: maybe a Site object?
    my $context = shift || {};

    my $cookie = $context->{'cookie'};
    my $action = $context->{'action'};
    my $rss = $context->{'rss'};
    my $ajax =  $context->{'ajax'};
    Log::do_log('debug2', '(%s, cookie=%s, action=%s)',
	$robot, $cookie, $action);

    my $self = {'robot' => $robot};
    bless $self => $pkg;

    # passive_session are session not stored in the database, they are used
    # for crawler bots and action such as css, wsdl, ajax and rss

    if (tools::is_a_crawler($robot,
	{'user_agent_string' => $ENV{'HTTP_USER_AGENT'}})) {
	$self->{'is_a_crawler'} = 1;
	$self->{'passive_session'} = 1;
    }
    $self->{'passive_session'} = 1
	if $rss or $action eq 'wsdl' or $action eq 'css';

    # if a session cookie exists, try to restore an existing session, don't
    # store sessions from bots
    if ($cookie and $self->{'passive_session'} != 1){
	my $status ;
	$status = $self->load($cookie);
	unless (defined $status) {
	    return undef;
	}
	if ($status eq 'not_found') {
	    # start a new session (may be a fake cookie)
	    Log::do_log('info', 'ignoring unknown session cookie "%s"',
		$cookie);
	    return __PACKAGE__->new($robot);
	}
    }else{
	# create a new session context
	## Tag this session as new, ie no data in the DB exist
	$self->{'new_session'} = 1;
	$self->{'id_session'} = &get_random();
	$self->{'email'} = 'nobody';
	$self->{'remote_addr'} = $ENV{'REMOTE_ADDR'};
	$self->{'date'} = $self->{'start_date'} = time;
	$self->{'refresh_date'} = 0;
	$self->{'hit'} = 1;
	##$self->{'robot'} = $robot->name;
	$self->{'data'} = '';
    }
    return $self;
}

sub load {
    Log::do_log('debug2', '(%s, %s)', @_);
    my $self = shift;
    my $cookie = shift;

    unless ($cookie) {
	Log::do_log('err', 'internal error, undef id_session');
	return undef;
    }

    my $sth;

    unless ($sth = SDM::do_prepared_query(
	q{SELECT id_session AS id_session, date_session AS "date",
		 remote_addr_session AS remote_addr, robot_session AS robot,
		 email_session AS email, data_session AS data,
		 hit_session AS hit, start_date_session AS start_date,
		 refresh_date_session AS refresh_date
	 FROM session_table
	 WHERE id_session = ? AND robot_session = ?},
	$cookie, $self->{'robot'}->name
    )) {
	Log::do_log('err', 'Unable to load session %s', $cookie);
	return undef;
    }

    my $session = undef;
    my $new_session = undef;
    my $counter = 0;
    while ($new_session = $sth->fetchrow_hashref('NAME_lc')) {
	if ( $counter > 0){
	    &Log::do_log('err',"The SQL statement did return more than one session. Is this a bug coming from dbi or mysql?");
	    $session->{'email'} = '';
	    last;
	}
	$session = $new_session;
	$counter ++;
    }
    
    unless ($session) {
	return 'not_found';
    }
    
    my %datas= &tools::string_2_hash($session->{'data'});
    foreach my $key (keys %datas) {$self->{$key} = $datas{$key};} 

    $self->{'id_session'} = $session->{'id_session'};
    $self->{'date'} = $session->{'date'};
    $self->{'start_date'} = $session->{'start_date'};
    $self->{'refresh_date'} = $session->{'refresh_date'};
    $self->{'hit'} = $session->{'hit'} +1 ;
    $self->{'remote_addr'} = $session->{'remote_addr'};
    ##$self->{'robot'} = $session->{'robot'};
    $self->{'email'} = $session->{'email'};

    return ($self);
}

## This method will both store the session information in the database
sub store {
    Log::do_log('debug2', '(%s)', @_);
    my $self = shift;

    return undef unless $self->{'id_session'};
    # do not create a session in session table for crawlers; 
    return if $self->{'is_a_crawler'};
    # do not create a session in session table for action such as RSS or CSS
    # or wsdl that do not require this sophistication; 
    return if $self->{'passive_session'};

    my %hash;
    foreach my $var (keys %$self ) {
	next if ($session_hard_attributes{$var});
	next unless ($var);
	$hash{$var} = $self->{$var};
    }
    my $data_string = &tools::hash_2_string (\%hash);

    ## If this is a new session, then perform an INSERT
    if ($self->{'new_session'}) {
	## Store the new session ID in the DB
	unless (SDM::do_prepared_query(
	    q{INSERT INTO session_table
	      (id_session, date_session, remote_addr_session,
	       robot_session, email_session, start_date_session,
	       refresh_date_session, hit_session, data_session)
	     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)},
	    $self->{'id_session'}, time, $ENV{'REMOTE_ADDR'},
	    $self->{'robot'}->name, $self->{'email'}, $self->{'start_date'},
	    0, $self->{'hit'}, $data_string
	)) {
	    &Log::do_log('err','Unable to add new session %s informations in database', $self->{'id_session'});
	    return undef;
	}   
      ## If the session already exists in DB, then perform an UPDATE
    }else {
	## Update the new session in the DB
	my $sth = SDM::do_prepared_query(
	    q{UPDATE session_table
	      SET date_session = ?, remote_addr_session = ?, robot_session = ?,
		  email_session = ?, start_date_session = ?, hit_session = ?,
		  data_session = ?
	      WHERE id_session = ? AND robot_session = ?},
	    time, $ENV{'REMOTE_ADDR'}, $self->{'robot'}->name,
	    $self->{'email'}, $self->{'start_date'}, $self->{'hit'},
	    $data_string,
	    $self->{'id_session'}, $self->{'robot'}->name
	);
	unless ($sth) {
	    &Log::do_log('err','Unable to update session %s information in database', $self->{'id_session'});
	    return undef;
	} elsif ($sth->rows == 0) {
	    return 0;
	}
    }

    return 1;
}

## This method will renew the session ID 
## Returns 1 if renewal occurred and 0 otherwise.  Returns undef on error.
sub renew {
    Log::do_log('debug2', '(%s)', @_);
    my $self = shift;

    return undef unless $self->{'id_session'};
    # do not create a session in session table for crawlers; 
    return if $self->{'is_a_crawler'};
    # do not create a session in session table for action such as RSS or CSS
    # or wsdl that do not require this sophistication; 
    return if $self->{'passive_session'};

    my %hash;
    foreach my $var (keys %$self ) {
	next if ($session_hard_attributes{$var});
	next unless ($var);
	$hash{$var} = $self->{$var};
    }
    my $data_string = &tools::hash_2_string (\%hash);

    ## Renew the session ID in order to prevent session hijacking
    my $new_id = &get_random();
    my $time = time;
    my $remote_addr = $ENV{'REMOTE_ADDR'};
    my $refresh_term;
    if (Site->cookie_refresh == 0) {
	$refresh_term = $time;
    } else {
	my $cookie_refresh = Site->cookie_refresh;
	$refresh_term =
	    int($time - $cookie_refresh * 0.5 - rand $cookie_refresh);
    }

    ## Do refresh the cookie when remote address was changed or refresh
    ## interval is past.  Conditions also are checked by SQL so that
    ## simultaneous processes will be prevented renewing cookie.
    return 0
	unless $self->{'remote_addr'} != $remote_addr or
	    $self->{'refresh_date'} <= $refresh_term;
    my $sth = SDM::do_prepared_query(
	q{UPDATE session_table
	  SET id_session = ?, refresh_date_session = ?, remote_addr_session = ?
	  WHERE id_session = ? AND robot_session = ? AND
		(remote_addr_session <> ? OR refresh_date_session <= ?)},
	$new_id, $time, $remote_addr,
	$self->{'id_session'}, $self->{'robot'}->name,
	$remote_addr, $refresh_term
    );
    unless ($sth) {
	Log::do_log('err',
	    'Unable to renew session ID for session %s', $self);
	return undef;
    } elsif ($sth->rows == 0) {
	return 0;
    }

    ## Renew the session ID in order to prevent session hijacking
    Log::do_log('debug3',
	'renewed session ID for session %s to %s', $self, $new_id);
    $self->{'id_session'} = $new_id;
    $self->{'refresh_date'} = $time;
    $self->{'remote_addr'} = $remote_addr;

    return 1;
}

## remove old sessions from a particular robot or from all robots.
## delay is a parameter in seconds
sub purge_old_sessions {
    Log::do_log('debug2', @_);
    my $robot = Robot::clean_robot(shift, 1);

    my $delay = &tools::duration_conv(Site->session_table_ttl) ; 
    my $anonymous_delay = &tools::duration_conv(Site->anonymous_session_table_ttl) ; 

    unless ($delay) {
	Log::do_log('info', 'exit with delay null');
	return;
    }
    unless ($anonymous_delay) {
	Log::do_log('info', 'exit with anonymous delay null');
	return;
    }

    my @sessions ;
    my  $sth;

    my $condition = '';
    $condition = sprintf 'robot_session = %s', SDM::quote($robot->name)
	if ref $robot eq 'Robot';
    my $anonymous_condition = $condition;

    $condition .= sprintf '%s%d > date_session',
	($condition ? ' AND ' : ''), time - $delay
	if $delay;
    $condition = " WHERE $condition"
	if $condition;

    $anonymous_condition .= sprintf '%s%d > date_session',
	($anonymous_condition ? ' AND ' : ''), time - $anonymous_delay
	if $anonymous_delay;
    $anonymous_condition .= sprintf
	"%semail_session = 'nobody' AND hit_session = 1",
	($anonymous_condition ? ' AND ' : '');
    $anonymous_condition = " WHERE $anonymous_condition"
	if $anonymous_condition;

    my $count_statement = q{SELECT count(*) FROM session_table%s};
    my $anonymous_count_statement = q{SELECT count(*) FROM session_table%s};
    my $statement = q{DELETE FROM session_table%s};
    my $anonymous_statement = q{DELETE FROM session_table%s};

    unless ($sth = SDM::do_query($count_statement, $condition)) {
	Log::do_log('err', 'Unable to count old session for robot %s', $robot);
	return undef;
    }

    my $total =  $sth->fetchrow;
    if ($total == 0) {
	Log::do_log('debug', 'no sessions to expire');
    }else{
	unless ($sth = SDM::do_query($statement, $condition)) {
	    Log::do_log('err', 'Unable to purge old sessions for robot %s',
		$robot);
	    return undef;
	}
    }
    unless ($sth = SDM::do_query($anonymous_count_statement,
	$anonymous_condition)) {
	Log::do_log('err', 'Unable to count anonymous sessions for robot %s',
	    $robot);
	return undef;
    }
    my $anonymous_total =  $sth->fetchrow;
    if ($anonymous_total == 0) {
	Log::do_log('debug', 'no anonymous sessions to expire');
	return $total ;
    }
    unless ($sth = SDM::do_query($anonymous_statement,
	$anonymous_condition)) {
	Log::do_log('err', 'Unable to purge anonymous sessions for robot %s',
	    $robot);
	return undef;
    }
    return $total+$anonymous_total;
}


## remove old one_time_ticket from a particular robot or from all robots. delay is a parameter in seconds
## 
sub purge_old_tickets {
    Log::do_log('debug2', '(%s)', @_);
    my $robot = Robot::clean_robot(shift, 1);

    my $delay = &tools::duration_conv(Site->one_time_ticket_table_ttl) ; 
    unless ($delay) {
	Log::do_log('debug3', 'exit with delay null');
	return;
    }

    my @tickets ;
    my  $sth;

    my $condition = '';
    $condition = sprintf '%d > date_one_time_ticket', time - $delay
	if $delay;
    $condition .= sprintf '%srobot_one_time_ticket = %s',
	($condition ? ' AND ' : ''), SDM::quote($robot->name)
        if ref $robot eq 'Robot';
    $condition = " WHERE $condition"
	if $condition;

    unless ($sth = SDM::do_query(
	q{SELECT count(*) FROM one_time_ticket_table%s},
	$condition
    )) {
	Log::do_log('err',
	    'Unable to count old one time tickets for robot %s', $robot);
	return undef;
    }
    
    my $total =  $sth->fetchrow;
    if ($total == 0) {
	Log::do_log('debug3', 'no tickets to expire');
    }else{
	unless ($sth = SDM::do_query(
	    q{DELETE FROM one_time_ticket_table%s},
	    $condition
	)) {
	    Log::do_log('err',
		'Unable to delete expired one time tickets for robot %s',
		$robot);
	    return undef;
	}
    }
    return $total;
}

# list sessions for $robot where last access is newer then $delay. List is limited to connected users if $connected_only
sub list_sessions {
    Log::do_log('debug2', '(%s, %s, %s)', @_);
    my $delay = shift;
    my $robot = Robot::clean_robot(shift, 1);
    my $connected_only = shift;

    my @sessions ;
    my $sth;

    my $condition = '';
    $condition = sprintf 'robot_session = %s', SDM::quote($robot->name)
	if ref $robot eq 'Robot';
    $condition .= sprintf '%s%d < date_session',
	($condition ? ' AND ' : ''), time - $delay
	if $delay;
    $condition .= sprintf "%semail_session != 'nobody'",
	($condition ? ' AND ' : '')
	if $connected_only eq 'on';
    $condition = " WHERE $condition"
	if $condition;

    unless ($sth = SDM::do_query(
	q{SELECT remote_addr_session, email_session, robot_session,
	  date_session, start_date_session, hit_session
	  FROM session_table%s},
	$condition
    )) {
	Log::do_log('err','Unable to get the list of sessions for robot %s',
	    $robot);
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
	if ($key eq 'robot') {
	    $data->{$key} = $self->{'robot'}->name;
	} else {
	    $data->{$key} = $self->{$key};
	}
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

## Get unique ID
sub get_id {
    my $self = shift;
    return '' unless $self->{'id_session'} and $self->{'robot'};
    return sprintf '%s@%s', $self->{'id_session'}, $self->{'robot'}->name;
}

1;

