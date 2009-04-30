# Auth.pm - This module provides web authentication functions
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


package Auth;

use Exporter;
our @ISA = ('Exporter');
our @EXPORT = ();

use Language;
use Log;
use Conf;
use List;
use report;
use Digest::MD5;

## return the password finger print (this proc allow futur replacement of md5 by sha1 or ....)
sub password_fingerprint{

    do_log('debug', 'Auth::password_fingerprint');

    my $pwd = shift;
    if(&Conf::get_robot_conf('*','password_case') eq 'insensitive') {
	return &tools::md5_fingerprint(lc($pwd));
    }else{
	return &tools::md5_fingerprint($pwd);
    }    
}


## authentication : via email or uid
 sub check_auth{
     my $robot = shift;
     my $auth = shift; ## User email or UID
     my $pwd = shift; ## Password
     &do_log('debug', 'Auth::check_auth(%s)', $auth);

     my ($canonic, $user);

     if( &tools::valid_email($auth)) {
	 return &authentication($robot, $auth,$pwd);

     }else{
	 ## This is an UID
       foreach my $ldap (@{$Conf{'auth_services'}{$robot}}){
	 # only ldap service are to be applied here
	 next unless ($ldap->{'auth_type'} eq 'ldap');
	 
	 $canonic = &ldap_authentication($robot, $ldap, $auth,$pwd,'uid_filter');
	 last if ($canonic); ## Stop at first match
       }
       if ($canonic){

	     unless($user = &List::get_user_db($canonic)){
		 $user = {'email' => $canonic};
	     }
	     return {'user' => $user,
		     'auth' => 'ldap',
		     'alt_emails' => {$canonic => 'ldap'}
		 };
	     
	 }else{
	     &report::reject_report_web('user','incorrect_passwd',{}) unless ($ENV{'SYMPA_SOAP'});
	     &do_log('err', "Incorrect Ldap password");
	     return undef;
	 }
     }
 }

## This subroutine if Sympa may use its native authentication for a given user
## It might not if no user_table paragraph is found in auth.conf or if the regexp or
## negative_regexp exclude this user
## IN : robot, user email
## OUT : boolean
sub may_use_sympa_native_auth {
    my ($robot, $user_email) = @_;

    my $ok = 0;
    ## check each auth.conf paragrpah
    foreach my $auth_service (@{$Conf{'auth_services'}{$robot}}){
	next unless ($auth_service->{'auth_type'} eq 'user_table');

	next if ($auth_service->{'regexp'} && ($user_email !~ /$auth_service->{'regexp'}/i));
	next if ($auth_service->{'negative_regexp'} && ($user_email =~ /$auth_service->{'negative_regexp'}/i));
	
	$ok = 1; last;
    }
    
    return $ok;
}

sub authentication {
    my ($robot, $email,$pwd) = @_;
    my ($user,$canonic);
    &do_log('debug', 'Auth::authentication(%s)', $email);


    unless ($user = &List::get_user_db($email)) {
	$user = {'email' => $email };
    }    
    unless ($user->{'password'}) {
	$user->{'password'} = '';
    }
    
    foreach my $auth_service (@{$Conf{'auth_services'}{$robot}}){
	next if ($auth_service->{'auth_type'} eq 'authentication_info_url');
	next if ($email !~ /$auth_service->{'regexp'}/i);
	next if (($email =~ /$auth_service->{'negative_regexp'}/i)&&($auth_service->{'negative_regexp'}));

	## Only 'user_table' and 'ldap' backends will need that Sympa collects the user passwords
	## Other backends are Single Sign-On solutions
	if ($auth_service->{'auth_type'} eq 'user_table') {
	    my $fingerprint = &password_fingerprint ($pwd);
	    
	    if ($fingerprint eq $user->{'password'}) {
		return {'user' => $user,
			'auth' => 'classic',
			'alt_emails' => {$email => 'classic'}
			};
	    }
	}elsif($auth_service->{'auth_type'} eq 'ldap') {
	    if ($canonic = &ldap_authentication($robot, $auth_service, $email,$pwd,'email_filter')){
		unless($user = &List::get_user_db($canonic)){
		    $user = {'email' => $canonic};
		}
		return {'user' => $user,
			'auth' => 'ldap',
			'alt_emails' => {$email => 'ldap'}
			};
	    }
	}
    }

    ## If web context and password has never been changed
    ## Then prompt user
    # xxxxxxxxxxxxx to be removed
#    unless ($ENV{'SYMPA_SOAP'}) {
#	foreach my $auth_service (@{$Conf{'auth_services'}{$robot}}){
#	    next unless ($email !~ /$auth_service->{'regexp'}/i);
#	    next unless (($email =~ /$auth_service->{'negative_regexp'}/i)&&($auth_service->{'negative_regexp'}));
#	    if ($auth_service->{'auth_type'} eq 'user_table') {
#		if ($user->{'password'} =~ /^init/i) {
#		    &report::reject_report_web('user','init_passwd',{});
#		    last;
#		}
#	    }
#	}
#    }
    
    &report::reject_report_web('user','incorrect_passwd',{}) unless ($ENV{'SYMPA_SOAP'});
    &do_log('err','authentication: incorrect password for user %s', $email);

    $param->{'init_email'} = $email;
    $param->{'escaped_init_email'} = &tools::escape_chars($email);
    return undef;
}


sub ldap_authentication {
     my ($robot, $ldap, $auth, $pwd, $whichfilter) = @_;
     my ($mesg, $host,$ldap_passwd,$ldap_anonymous);
     &do_log('debug2','Auth::ldap_authentication(%s,%s,%s)', $auth,'****',$whichfilter);
     &do_log('debug3','Password used: %s',$pwd);

     unless (&tools::get_filename('etc',{},'auth.conf', $robot)) {
	 return undef;
     }

     ## No LDAP entry is defined in auth.conf
     if ($#{$Conf{'auth_services'}{$robot}} < 0) {
	 &do_log('notice', 'Skipping empty auth.conf');
	 return undef;
     }

     # only ldap service are to be applied here
     return undef unless ($ldap->{'auth_type'} eq 'ldap');
     
     # skip ldap auth service if the an email address was provided
     # and this email address does not match the corresponding regexp 
     return undef if ($auth =~ /@/ && $auth !~ /$ldap->{'regexp'}/i);
     
     my @alternative_conf = split(/,/,$ldap->{'alternative_email_attribute'});
     my $attrs = $ldap->{'email_attribute'};
     my $filter = $ldap->{'get_dn_by_uid_filter'} if($whichfilter eq 'uid_filter');
     $filter = $ldap->{'get_dn_by_email_filter'} if($whichfilter eq 'email_filter');
     $filter =~ s/\[sender\]/$auth/ig;
     
     ## bind in order to have the user's DN
     my $ldap_anonymous;
     my $param = &tools::dup_var($ldap);
     my $ds = new Datasource('LDAP', $param);
     
     unless (defined $ds && ($ldap_anonymous = $ds->connect())) {
       &do_log('err',"Unable to connect to the LDAP server '%s'", $ldap->{'host'});
       return undef;
     }
     
     
     $mesg = $ldap_anonymous->search(base => $ldap->{'suffix'},
				     filter => "$filter",
				     scope => $ldap->{'scope'} ,
				     timeout => $ldap->{'timeout'});
     
     if ($mesg->count() == 0) {
       do_log('notice','No entry in the Ldap Directory Tree of %s for %s',$ldap->{'host'},$auth);
       $ds->disconnect();
       return undef;
     }
     
     my $refhash=$mesg->as_struct();
     my (@DN) = keys(%$refhash);
     $ds->disconnect();
     
     ##  bind with the DN and the pwd
     my $ldap_passwd;
     
     ## Duplicate structure first
     ## Then set the bind_dn and password according to the current user
     my $param = &tools::dup_var($ldap);
     $param->{'ldap_bind_dn'} = $DN[0];
     $param->{'ldap_bind_password'} = $pwd;
     
     my $ds = new Datasource('LDAP', $param);
     
     unless (defined $ds && ($ldap_passwd = $ds->connect())) {
       do_log('err',"Unable to connect to the LDAP server '%s'", $param->{'host'});
       return undef;
     }
     
     $mesg= $ldap_passwd->search ( base => $ldap->{'suffix'},
				   filter => "$filter",
				   scope => $ldap->{'scope'},
				   timeout => $ldap->{'timeout'}
				 );
     
     if ($mesg->count() == 0 || $mesg->code() != 0) {
       do_log('notice',"No entry in the Ldap Directory Tree of %s", $ldap->{'host'});
       $ds->disconnect();
       return undef;
     }
     
     ## To get the value of the canonic email and the alternative email
     my (@canonic_email, @alternative);
     
     ## Keep previous alt emails not from LDAP source
     my $previous = {};
     foreach my $alt (keys %{$param->{'alt_emails'}}) {
       $previous->{$alt} = $param->{'alt_emails'}{$alt} if ($param->{'alt_emails'}{$alt} ne 'ldap');
     }
     $param->{'alt_emails'} = {};
     
     my $entry = $mesg->entry(0);
     @canonic_email = $entry->get_value($attrs,alloptions);
     foreach my $email (@canonic_email){
       my $e = lc($email);
       $param->{'alt_emails'}{$e} = 'ldap' if ($e);
     }
     
     foreach my $attribute_value (@alternative_conf){
       @alternative = $entry->get_value($attribute_value,alloptions);
       foreach my $alter (@alternative){
	 my $a = lc($alter); 
	 $param->{'alt_emails'}{$a} = 'ldap' if($a) ;
       }
     }
     
     ## Restore previous emails
     foreach my $alt (keys %{$previous}) {
       $param->{'alt_emails'}{$alt} = $previous->{$alt};
     }
     
     $ds->disconnect() or &do_log('notice', "unable to unbind");
     &do_log('debug3',"canonic: $canonic_email[0]");
     return lc($canonic_email[0]);
     
 }


# fetch user email using his cas net_id and the paragrapah number in auth.conf
sub get_email_by_net_id {
    
    my $robot = shift;
    my $auth_id = shift;
    my $attributes = shift;
    
    do_log ('debug',"Auth::get_email_by_net_id($auth_id,$attributes->{'uid'})");
    
    if (defined $Conf{'auth_services'}{$robot}[$auth_id]{'internal_email_by_netid'}) {
	my $sso_config = @{$Conf{'auth_services'}{$robot}}[$auth_id];
	my $netid_cookie = $sso_config->{'netid_http_header'} ;
	
	$netid_cookie =~ s/(\w+)/$attributes->{$1}/ig;
	
	$email = &List::get_netidtoemail_db($robot, $netid_cookie, $Conf{'auth_services'}{$robot}[$auth_id]{'service_id'});
	
	return $email;
    }
 
    my $ldap = @{$Conf{'auth_services'}{$robot}}[$auth_id];

    my $param = &tools::dup_var($ldap);
    my $ds = new Datasource('LDAP', $param);
    my $ldap_anonymous;
    
    unless (defined $ds && ($ldap_anonymous = $ds->connect())) {
	&do_log('err',"Unable to connect to the LDAP server '%s'", $ldap->{'ldap_host'});
	return undef;
    }

    my $filter = $ldap->{'ldap_get_email_by_uid_filter'} ;
    $filter =~ s/\[([\w-]+)\]/$attributes->{$1}/ig;

#	my @alternative_conf = split(/,/,$ldap->{'alternative_email_attribute'});
		
	my $emails= $ldap_anonymous->search ( base => $ldap->{'ldap_suffix'},
				      filter => $filter,
				      scope => $ldap->{'ldap_scope'},
				      timeout => $ldap->{'ldap_timeout'},
				      attrs =>  $ldap->{'ldap_email_attribute'}
				      );
	my $count = $emails->count();

	if ($emails->count() == 0) {
	    do_log('notice',"No entry in the Ldap Directory Tree of %s", $host);
	$ds->disconnect();
	return undef;
	}

    $ds->disconnect();
    
    ## return only the first attribute
	my @results = $emails->entries;
	foreach my $result (@results){
	    return (lc($result->get_value($ldap->{'ldap_email_attribute'})));
	}

 }

# check trusted_application_name et trusted_application_password : return 1 or undef;
sub remote_app_check_password {
    
    my ($trusted_application_name,$password,$robot) = @_;
    do_log('debug','Auth::remote_app_check_password (%s,%s)',$trusted_application_name,$robot);
    
    my $md5 = &tools::md5_fingerprint($password);
    
    my $vars;
    # seach entry for trusted_application in Conf
    my @trusted_apps ;
    
    # select trusted_apps from robot context or symap context
    if ((defined $robot) &&  (defined $Conf::Conf{'robots'}{$robot}{'trusted_applications'})) {
 	@trusted_apps = @{$Conf::Conf{'robots'}{$robot}{'trusted_applications'}{'trusted_application'}};
    }else{
 	@trusted_apps = @{$Conf::Conf{'trusted_applications'}{'trusted_application'}};
    }
    
    foreach my $application (@trusted_apps){
	
 	if (lc($application->{'name'}) eq lc($trusted_application_name)) {
 	    if ($md5 eq $application->{'md5password'}) {
 		# &do_log('debug', 'Auth::remote_app_check_password : authentication succeed for %s',$application->{'name'});
 		my %proxy_for_vars ;
 		foreach my $varname (@{$application->{'proxy_for_variables'}}) {
 		    $proxy_for_vars{$varname}=1;
 		}		
 		return (\%proxy_for_vars);
 	    }else{
 		&do_log('info', 'Auth::remote_app_check_password: bad password from %s', $trusted_application_name);
 		return undef;
 	    }
 	}
    }				 
    # no matching application found
    &do_log('info', 'Auth::remote_app-check_password: unknown application name %s', $trusted_application_name);
    return undef;
}
 
# create new entry in one_time_ticket table using a rand as id so later access is authenticated
#

sub create_one_time_ticket {
    my $email = shift;
    my $robot = shift;
    my $data_string = shift;
    my $remote_addr = shift; ## Value may be 'mail' if the IP address is not known

    my $ticket = &SympaSession::get_random();
    do_log('info', 'Auth::create_one_time_ticket(%s,%s,%s,%s) value = %s',$email,$robot,$data_string,$remote_addr,$ticket);

    my $date = time;
    my $dbh = &List::db_get_handler();
    my $sth;

    ## Check database connection
    unless ($dbh and $dbh->ping) {
	return undef unless &List::db_connect();
    }
    
    my $statement = sprintf "INSERT INTO one_time_ticket_table (ticket_one_time_ticket, robot_one_time_ticket, email_one_time_ticket, date_one_time_ticket, data_one_time_ticket, remote_addr_one_time_ticket, status_one_time_ticket) VALUES ('%s','%s','%s','%s','%s','%s','%s')",$ticket,$robot,$email,time,$data_string,$remote_addr,'open';

    unless ($dbh->do($statement)) {
	do_log('err','Unable to insert in table one_time_ticket_table while executing SQL statement "%s" : %s', $statement, $dbh->errstr);
	return undef;
    }   
    return $ticket;
}

# read one_time_ticket from table and remove it
#
sub get_one_time_ticket {
    my $ticket_number = shift;
    my $addr = shift; 
    
    do_log('debug2', '(%s)',$ticket_number);
    
    my $dbh = &List::db_get_handler();
    my $sth;
    
    ## Check database connection
    unless ($dbh and $dbh->ping) {
	return return {'result'=>'error'} unless &List::db_connect();
    }
    my $statement;
    $statement = sprintf "SELECT ticket_one_time_ticket AS ticket, robot_one_time_ticket AS robot, email_one_time_ticket AS email, date_one_time_ticket AS date, data_one_time_ticket AS data, remote_addr_one_time_ticket AS remote_addr, status_one_time_ticket as status FROM one_time_ticket_table WHERE ticket_one_time_ticket = %s ", $ticket_number;
    
    unless ($sth = $dbh->prepare($statement)) {
	do_log('err','Auth::get_one_time_ticket: Unable to prepare SQL statement : %s', $dbh->errstr);
	return {'result'=>'error'};
    }
    unless ($sth->execute) {
	do_log('err','Auth::get_one_time_ticket: Unable to execute SQL statement "%s" : %s', $statement, $dbh->errstr);
	return {'result'=>'error'};
    }    
 
    my $ticket = $sth->fetchrow_hashref('NAME_lc');
    $sth->finish();
    
    unless ($ticket) {	
	do_log('info','Auth::get_one_time_ticket: Unable to find one time ticket %s (SQL query %s)%s', $ticket,$statement, $dbh->errstr);
	return {'result'=>'not_found'};
    }
    
    my $result;
    my $printable_date = gettext_strftime "%d %b %Y at %H:%M:%S", localtime($ticket->{'date'});

    if ($ticket->{'status'} ne 'open') {
	$result = 'closed';
	do_log('info','Auth::get_one_time_ticket: ticket %s from %s has been used before (%s)',$ticket_number,$ticket->{'email'},$printable_date);
    }
    elsif (time - $ticket->{'date'} > 48 * 60 * 60) {
	do_log('info','Auth::get_one_time_ticket: ticket %s from %s refused because expired (%s)',$ticket_number,$ticket->{'email'},$printable_date);
	$result = 'expired';
    }else{
	$result = 'success';
    }
    $statement = sprintf "UPDATE one_time_ticket_table SET status_one_time_ticket = '%s' WHERE (ticket_one_time_ticket='%s')", $addr, $ticket_number;
    
    unless ($dbh->do($statement)) {
    	do_log('err','Auth::get_one_time_ticket  Unable to execute SQL statement "%s" : %s', $statement, $dbh->errstr);
    }

    do_log('info', 'xxxx Auth::get_one_time_ticket(%s) : result : %s',$ticket_number,$result);
    return {'result'=>$result,
	    'date'=>$ticket->{'date'},
	    'email'=>$ticket->{'email'},
	    'remote_addr'=>$ticket->{'remote_addr'},
	    'robot'=>$ticket->{'robot'},
	    'data'=>$ticket->{'data'},
	    'status'=>$ticket->{'status'}
	};
}
    
1;


