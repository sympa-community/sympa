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

package SOAP::XMLSchema1999::Serializer;

#sub as_listType {
#    my $self = shift;
#    my($value, $name, $type, $attr) = @_;
#    return [$name, $attr, $value];
##    return [$name, {'xsi:type' => 'sympaType:listType', %$attr}, $value];
#}


package sympasoap;

use Exporter;
use HTTP::Cookies;

@ISA = ('Exporter');
@EXPORT = ();

use Conf;
use Log;
use Auth;
use CAS;

## Define types of SOAP type listType
my %types = ('listType' => {'listAddress' => 'string',
			    'homepage' => 'string',
			    'isSubscriber' => 'boolean',
			    'isOwner' => 'boolean',
			    'isEditor' => 'boolean',
			    'subject' => 'string'}
	     );

sub checkCookie {
    my $class = shift;

    my $sender = $ENV{'USER_EMAIL'};

    unless ($sender) {
	die SOAP::Fault->faultcode('Client')
	    ->faultstring('User not authentified')
	    ->faultdetail('You should login first');
    }

    &Log::do_log('debug', 'SOAP checkCookie');
    
    return SOAP::Data->name('result')->type('string')->value($sender);
}

sub lists {
    my $self = shift; #$self is a service object
    my $topic = shift;
    my $subtopic = shift;
    my $mode = shift;
    my $sender = $ENV{'USER_EMAIL'};
    &Log::do_log('notice', 'lists(%s,%s,%s)', $topic, $subtopic,$sender);

    unless ($sender) {
	die SOAP::Fault->faultcode('Client')
	    ->faultstring('User not authentified')
	    ->faultdetail('You should login first');
    }

    my @result;  
    
    &do_log('info', 'SOAP lists(%s,%s)', $topic, $subtopic);
   
    foreach my $listname ( &List::get_lists() ) {
	
	my $list = new List ($listname);
	my $robot = $list->{'domain'};
	my $result_item = {};
	my $action = &List::request_action ('visibility','md5',$robot,
					    {'listname' =>  $listname,
					     'sender' => $sender}
					    );
	next unless ($action eq 'do_it');
	
	##building result packet
	$result_item->{'listAddress'} = $listname.'@'.$list->{'domain'};
	$result_item->{'subject'} = $list->{'admin'}{'subject'};
	$result_item->{'subject'} =~ s/;/,/g;
	$result_item->{'homepage'} = $Conf{'wwsympa_url'}.'/info/'.$listname; 
	
	my $listInfo;
	if ($mode eq 'complex') {
	    $listInfo = struct_to_soap($result_item);
	}else {
	    $listInfo = struct_to_soap($result_item, 'as_string');
	}
	
	## no topic ; List all lists
	if (!$topic) {
	    push @result, $listInfo;
	    
	}elsif ($list->{'admin'}{'topics'}) {
	    foreach my $list_topic (@{$list->{'admin'}{'topics'}}) {
		my @tree = split '/', $list_topic;
		
		next if (($topic) && ($tree[0] ne $topic));
		next if (($subtopic) && ($tree[1] ne $subtopic));
		
		push @result, $listInfo;
	    }
	}elsif ($topic  eq 'topicsless') {
	    	push @result, $listInfo;
	}
    }
    
    return SOAP::Data->name('listInfo')->value(\@result);
}

sub login {
    my $class = shift;
    my $email = shift;
    my $passwd = shift;

    my $http_host = $ENV{'SERVER_NAME'};
    &Log::do_log('notice', 'login(%s)', $email);
    
    #foreach my  $k (keys %ENV) {
    #&Log::do_log('notice', 'ENV %s = %s', $k, $ENV{$k});
    #}

    unless ($http_host and $email and $passwd) {
	&do_log('err', 'login(): incorrect number of parameters');
	die SOAP::Fault->faultcode('Client')
	    ->faultstring('Incorrect number of parameters')
	    ->faultdetail('Use : <HTTP host> <email> <password>');
    }
    
    ## Authentication of the sender
    ## Set an env var to find out if in a SOAP context
    $ENV{'SYMPA_SOAP'} = 1;
    my $user = &Auth::check_auth($email,$passwd);

    unless($user){
	&do_log('notice', "SOAP : login authentication failed");
	die SOAP::Fault->faultcode('Server')
	    ->faultstring('Authentification failed')
	    ->faultdetail("Incorrect password for user $email or bad login");
    } 

    my $expire = $param->{'user'}{'cookie_delay'} || $wwsconf->{'cookie_expire'};

    unless(&cookielib::set_cookie_soap($email,$Conf::Conf{'cookie'},$http_host,$expire)) {
	&Log::do_log('notice', 'SOAP : could not set HTTP cookie for external_auth');
	die SOAP::Fault->faultcode('Server')
	    ->faultstring('Cookie not set')
	    ->faultdetail('Could not set HTTP cookie for external_auth');
    }

    ## Also return the cookie value
    return SOAP::Data->name('result')->type('string')->value(&cookielib::get_mac($email,$Conf::Conf{'cookie'}));

#    return SOAP::Data->name('result')->type('boolean')->value(1);
}

sub casLogin {
    my $class = shift;
    my $proxyTicket = shift;

    my $http_host = $ENV{'SERVER_NAME'};
    &Log::do_log('notice', 'casLogin(%s)', $proxyTicket);
    
    unless ($http_host and $proxyTicket) {
	&do_log('err', 'casLogin(): incorrect number of parameters');
	die SOAP::Fault->faultcode('Client')
	    ->faultstring('Incorrect number of parameters')
	    ->faultdetail('Use : <HTTP host> <proxyTicket>');
    }
    
    ## Validate the CAS ST against all known CAS servers defined in auth.conf
    ## CAS server response will include the user's NetID
    my ($user, @proxies, $email, $cas_id);
    foreach my $service_id (0..$#{$Conf{'auth_services'}}){
	my $auth_service = $Conf{'auth_services'}[$service_id];
	next unless ($auth_service->{'auth_type'} eq 'cas'); ## skip non CAS entries
	
	my $cas = new CAS(casUrl => $auth_service->{'base_url'}, 
			  #CAFile => '/usr/local/apache/conf/ssl.crt/ca-bundle.crt',
			  );
	
	($user, @proxies) = $cas->validatePT($Conf::Conf{'soap_url'}, $proxyTicket);
	unless (defined $user) {
	    &do_log('err', 'CAS ticket %s not validated by server %s : %s', $proxyTicket, $auth_service->{'base_url'}, &CAS::get_errors());
	    next;
	}

	&do_log('notice', 'User %s authenticated against server %s', $user, $auth_service->{'base_url'});
	
	## User was authenticated
	$cas_id = $service_id;
	last;	
    }
    
    unless($user){
	&do_log('notice', "SOAP : login authentication failed");
	die SOAP::Fault->faultcode('Server')
	    ->faultstring('Authentification failed')
	    ->faultdetail("Proxy ticket could not be validated");
    } 

    ## Now fetch email attribute from LDAP
    unless ($email = &Auth::cas_get_email_by_net_id($user, $cas_id)) {
	&do_log('err','Could not get email address from LDAP for user %s', $user);
	die SOAP::Fault->faultcode('Server')
	    ->faultstring('Authentification failed')
	    ->faultdetail("Could not get email address from LDAP directory");
    }

    my $expire = $param->{'user'}{'cookie_delay'} || $wwsconf->{'cookie_expire'};

    unless(&cookielib::set_cookie_soap($email,$Conf::Conf{'cookie'},$http_host,$expire)) {
	&Log::do_log('notice', 'SOAP : could not set HTTP cookie for external_auth');
	die SOAP::Fault->faultcode('Server')
	    ->faultstring('Cookie not set')
	    ->faultdetail('Could not set HTTP cookie for external_auth');
    }

    ## Also return the cookie value
    return SOAP::Data->name('result')->type('string')->value(&cookielib::get_mac($email,$Conf::Conf{'cookie'}));

#    return SOAP::Data->name('result')->type('boolean')->value(1);
}

## Used to call a service as an authenticated user without using HTTP cookies
## First parameter is the secret contained in the cookie
sub authenticateAndRun {
    my ($self, $email, $cookie, $service, $parameters) = @_;

    &do_log('notice','authenticateAndRun(%s,%s,%s,%s)', $email, $cookie, $service, join(',',@$parameters));

    unless ($email and $cookie and $service) {
	die SOAP::Fault->faultcode('Client')
	    ->faultstring('Incorrect number of parameters')
	    ->faultdetail('Use : <email> <cookie> <service>');
    }

    unless (&cookielib::get_mac($email, $Conf::Conf{'cookie'}) eq $cookie) {
	&do_log('notice', "authenticateAndRun(): authentication failed");
	die SOAP::Fault->faultcode('Server')
	    ->faultstring('Authentification failed')
	    ->faultdetail("Incorrect cookie $cookie for user $email");
    }

    $ENV{'USER_EMAIL'} = $email;

    &{$service}($self,@$parameters);
}

sub amI {
  my ($class,$listname,$function,$user)=@_;

  unless ($listname and $user and $function) {
      die SOAP::Fault->faultcode('Client')
	  ->faultstring('Incorrect number of parameters')
	  ->faultdetail('Use : <list> <function> <user email>');
  }

  $listname = lc($listname);  
  my $list = new List ($listname);  

  &Log::do_log('debug', 'SOAP isSubscriber(%s)', $listname);

  if ($list) {
      if ($function eq 'subscriber') {
	  return SOAP::Data->name('result')->type('boolean')->value($list->is_user($user));
      }elsif ($function =~ /^owner|editor$/) {
	  return SOAP::Data->name('result')->type('boolean')->value($list->am_i($function, $user));
      }else {
	  die SOAP::Fault->faultcode('Server')
	      ->faultstring('Unknown function.')
	      ->faultdetail("Function $function unknown");
      }
  }else {
      die SOAP::Fault->faultcode('Server')
	  ->faultstring('Unknown list.')
	  ->faultdetail("List $listname unknown");
  }

}

sub info {
    my $class = shift;
    my $listname  = shift;
    
    my $sender = $ENV{'USER_EMAIL'};

    unless ($sender) {
	die SOAP::Fault->faultcode('Client')
	    ->faultstring('User not authentified')
	    ->faultdetail('You should login first');
    }    

    my @resultSoap;

    unless ($listname) {
	die SOAP::Fault->faultcode('Client')
	    ->faultstring('Incorrect number of parameters')
	    ->faultdetail('Use : <list>');
    }
	
    &Log::do_log('notice', 'SOAP info(%s)', $listname);

    my $list = new List ($listname);
    unless ($list) {
	&Log::do_log('info', 'Info %s from %s refused, list unknown', $listname,$sender);
	die SOAP::Fault->faultcode('Server')
	    ->faultstring('Unknown list')
	    ->faultdetail("List $listname unknown");
    }

    my $robot = $list->{'domain'};

    my $sympa = &Conf::get_robot_conf($robot, 'sympa');

    my $user;

    # Part of the authorization code
    $user = &List::get_user_db($sender);
     
    my $action = &List::request_action ('info','md5',$robot,
                                     {'listname' => $listname,
                                      'sender' => $sender});

    die SOAP::Fault->faultcode('Server')
	->faultstring('No action available')
	unless (defined $action);

    if ($action =~ /reject(\(\'?(\w+)\'?\))?/i) {
	&Log::do_log('info', 'SOAP : info %s from %s refused (not allowed)', $listname,$sender);
	die SOAP::Fault->faultcode('Server')
	    ->faultstring('Not allowed')
	    ->faultdetail("You don't have proper rights");
    }
    if ($action =~ /do_it/i) {
	my $result_item;

	$result_item->{'listAddress'} = SOAP::Data->name('listAddress')->type('string')->value($listname.'@'.$list->{'domain'});
	$result_item->{'subject'} = SOAP::Data->name('subject')->type('string')->value($list->{'admin'}{'subject'});
	$result_item->{'homepage'} = SOAP::Data->name('homepage')->type('string')->value($Conf{'wwsympa_url'}.'/info/'.$listname); 
	
	## determine status of user 
	if (($list->am_i('owner',$sender) || $list->am_i('owner',$sender))) {
	     $result_item->{'isOwner'} = SOAP::Data->name('isOwner')->type('boolean')->value(1);
	 }
	if (($list->am_i('editor',$sender) || $list->am_i('editor',$sender))) {
	    $result_item->{'isEditor'} = SOAP::Data->name('isEditor')->type('boolean')->value(1);
	}
	if ($list->is_user($sender)) {
	    $result_item->{'isSubscriber'} = SOAP::Data->name('isSubscriber')->type('boolean')->value(1);
	}
	
	#push @result, SOAP::Data->type('listType')->value($result_item);
	return SOAP::Data->value($result_item);
    }
    &Log::do_log('info', 'SOAP : info %s from %s aborted, unknown requested action in scenario',$listname,$sender);
    die SOAP::Fault->faultcode('Server')
	->faultstring('Unknown requested action')
	    ->faultdetail("SOAP info : %s from %s aborted because unknown requested action in scenario",$listname,$sender);
}

sub review {
    my $class = shift;
    my $listname  = shift;
    
    my $sender = $ENV{'USER_EMAIL'};

    unless ($sender) {
	die SOAP::Fault->faultcode('Client')
	    ->faultstring('User not authentified')
	    ->faultdetail('You should login first');
    }
    

    my @resultSoap;

    unless ($listname) {
	die SOAP::Fault->faultcode('Client')
	    ->faultstring('Incorrect number of parameters')
	    ->faultdetail('Use : <list>');
    }
	
    &Log::do_log('debug', 'SOAP review(%s,%s)', $listname,$robot);

    my $list = new List ($listname);
    unless ($list) {
	&Log::do_log('info', 'Review %s from %s refused, list unknown to robot %s', $listname,$sender,$robot);
	die SOAP::Fault->faultcode('Server')
	    ->faultstring('Unknown list')
	    ->faultdetail("List $listname unknown");
    }

    my $robot = $list->{'domain'};

    my $sympa = &Conf::get_robot_conf($robot, 'sympa');

    my $user;

    # Part of the authorization code
    $user = &List::get_user_db($sender);
     
    my $action = &List::request_action ('review','md5',$robot,
                                     {'listname' => $listname,
                                      'sender' => $sender});

    die SOAP::Fault->faultcode('Server')
	->faultstring('No action available')
	unless (defined $action);

    if ($action =~ /reject(\(\'?(\w+)\'?\))?/i) {
	&Log::do_log('info', 'SOAP : review %s from %s refused (not allowed)', $listname,$sender);
	die SOAP::Fault->faultcode('Server')
	    ->faultstring('Not allowed')
		->faultdetail("You don't have proper rights");
    }
    if ($action =~ /do_it/i) {
	my $is_owner = $list->am_i('owner', $sender);
	unless ($user = $list->get_first_user({'sortby' => 'email'})) {
	    &Log::do_log('err', "SOAP : no subscribers in list '%s'", $list->{'name'});
	    push @resultSoap, SOAP::Data->name('result')->type('string')->value('no_subscribers');
	    return SOAP::Data->name('return')->value(\@resultSoap);
	}
	do {
	    ## Owners bypass the visibility option
	    unless ( ($user->{'visibility'} eq 'conceal') 
		     and (! $is_owner) ) {
		
		## Lower case email address
		$user->{'email'} =~ y/A-Z/a-z/;
		push @resultSoap, SOAP::Data->name('item')->type('string')->value($user->{'email'});
	    }
	} while ($user = $list->get_next_user());
	&Log::do_log('info', 'SOAP : review %s from %s accepted', $listname, $sender);
	return SOAP::Data->name('return')->value(\@resultSoap);
    }
    &Log::do_log('info', 'SOAP : review %s from %s aborted, unknown requested action in scenario',$listname,$sender);
    die SOAP::Fault->faultcode('Server')
	->faultstring('Unknown requested action')
	    ->faultdetail("SOAP review : %s from %s aborted because unknown requested action in scenario",$listname,$sender);
}

sub signoff {
    my ($class,$listname)=@_;
    my $sender = $ENV{'USER_EMAIL'};
    &Log::do_log('notice', 'SOAP signoff(%s,%s)', $listname,$sender);
    
    unless ($sender) {
	die SOAP::Fault->faultcode('Client')
	    ->faultstring('User not authentified')
	    ->faultdetail('You should login first');
    }
    
    unless ($listname) {
	die SOAP::Fault->faultcode('Client')
	    ->faultstring('Incorrect number of parameters.')
	    ->faultdetail('Use : <list> ');
    }
    
    
    my $l;
    my $list = new List ($listname);
    
    ## Is this list defined
    unless ($list) {
	&Log::do_log('info', 'SOAP : sign off from %s for %s refused, list unknown', $listname,$sender);
	die SOAP::Fault->faultcode('Server')
	    ->faultstring('Unknown list.')
	    ->faultdetail("List $listname unknown");	
    }
    
    my $robot = $list->{'domain'};
    
    my $host = &Conf::get_robot_conf($robot, 'host');
    
    if ($listname eq '*') {
	my $success;
	foreach $l ( List::get_which ($sender,$robot,'member') ){
	    $success ||= &signoff($l,$sender);
	}
	return SOAP::Data->name('result')->value($success);
    } 
    
    $list = new List ($listname, $robot);
    
    # Part of the authorization code
    my $user = &List::get_user_db($sender);
    
    my $action = &List::request_action('unsubscribe','md5',$robot,
				       {'listname' => $listname,
					'email' => $sender,
					'sender' => $sender });
    
    die SOAP::Fault->faultcode('Server')
	->faultstring('No action available.')
	unless (defined $action);   
    
    if ($action =~ /reject(\(\'?(\w+)\'?\))?/i) {
	&Log::do_log('info', 'SOAP : sign off from %s for the email %s of the user %s refused (not allowed)', 
		     $listname,$sender,$sender);
	die SOAP::Fault->faultcode('Server')
	    ->faultstring('Not allowed.')
	    ->faultdetail("You don't have proper rights");
    }
    if ($action =~ /do_it/i) {
	## Now check if we know this email on the list and
	## remove it if found, otherwise just reject the
	## command.
	unless ($list->is_user($sender)) {
	    &Log::do_log('info', 'SOAP : sign off %s from %s refused, not on list', $listname, $sender);
	    
	    ## Tell the owner somebody tried to unsubscribe
	    if ($action =~ /notify/i) {
		$list->send_notify_to_owner({'who' => $sender, 
					     'type' => 'warn-signoff'});
	    }
	    die SOAP::Fault->faultcode('Server')
		->faultstring('Not allowed.')
		->faultdetail("Email address $email has not been found on the list $list{'name'}. You did perhaps subscribe using a different address ?");
	}
	
	## Really delete and rewrite to disk.
	$list->delete_user($sender);

	## Notify the owner
	if ($action =~ /notify/i) {
	    $list->send_notify_to_owner({'who' => $sender,
					 'type' => 'signoff'});
	}

	## Send bye.tpl to sender
	my %context;
	$context{'subject'} = sprintf(&Language::Msg(6 , 71, 'Signoff from list %s'), $list->{'name'});
	$context{'body'} = sprintf(&Language::Msg(6 , 31, "You have been removed from list %s.\n Thanks for being with us.\n"), $list->{'name'});
	$list->send_file('bye', $sender, $robot, \%context);
	
	$list->save();

	&Log::do_log('info', 'SOAP : sign off %s from %s accepted', $listname, $sender);
	
	return SOAP::Data->name('result')->type('boolean')->value(1);
    }

  &Log::do_log('info', 'SOAP : sign off %s from %s aborted, unknown requested action in scenario',$listname,$sender);
  die SOAP::Fault->faultcode('Server')
      ->faultstring('Undef')
	  ->faultdetail("Sign off %s from %s aborted because unknown requested action in scenario",$listname,$sender);
}

sub subscribe {
  my ($class,$listname,$gecos)=@_;
  my $sender = $ENV{'USER_EMAIL'};
  &Log::do_log('info', 'subscribe(%s,%s, %s)', $listname,$sender, $gecos);

  unless ($sender) {
      die SOAP::Fault->faultcode('Client')
	  ->faultstring('User not authentified')
	  ->faultdetail('You should login first');
  }

  unless ($listname) {
      die SOAP::Fault->faultcode('Client')
	  ->faultstring('Incorrect number of parameters')
	      ->faultdetail('Use : <list> [user gecos]');
  } 

  &Log::do_log('notice', 'SOAP subscribe(%s,%s)', $listname, $sender);
  
  ## Load the list if not already done, and reject the
  ## subscription if this list is unknown to us.
  my $list = new List ($listname);
  unless ($list) {
      &Log::do_log('info', 'Subscribe to %s from %s refused, list unknown to robot %s', $listname,$sender,$robot);
      die SOAP::Fault->faultcode('Server')
	  ->faultstring('Unknown list')
	  ->faultdetail("List $listname unknown");	  
  }

  my $robot = $list->{'domain'};

  ## This is a really minimalistic handling of the comments,
  ## it is far away from RFC-822 completeness.
  $gecos =~ s/"/\\"/g;
  $gecos = "\"$gecos\"" if ($gecos =~ /[<>\(\)]/);
  
  ## query what to do with this subscribtion request
  my $action = &List::request_action('subscribe','md5',$robot,
				     {'listname' => $listname,
				      'sender' => $sender });
 
  die SOAP::Fault->faultcode('Server')
      ->faultstring('No action available.')
	  unless (defined $action); 
  
  &Log::do_log('debug2', 'SOAP subscribe action : %s', $action);
  
  if ($action =~ /reject(\(\'?(\w+)\'?\))?/i) {
      &Log::do_log('info', 'SOAP subscribe to %s from %s refused (not allowed)', $listname,$sender);
      die SOAP::Fault->faultcode('Server')
	  ->faultstring('Not allowed.')
	  ->faultdetail("You don't have proper rights");
  }
  if ($action =~ /owner/i) {
      push @msg::report, sprintf Msg(6, 25, $msg::subscription_forwarded);
      ## Send a notice to the owners.
      my $keyauth = $list->compute_auth($sender,'add');
      $list->send_sub_to_owner($sender, $keyauth, &Conf::get_robot_conf($robot, 'sympa'), $gecos);
      $list->store_susbscription_request($sender, $gecos);
      &Log::do_log('info', 'SOAP subscribe : %s from %s forwarded to the owners of the list (%d seconds)',$listname,$sender,time-$time_command);
      return SOAP::Data->name('result')->type('boolean')->value(1);
  }
  if ($action =~ /request_auth/i) {
      my $cmd = 'subscribe';
      $cmd = "quiet $cmd" if $quiet;
      $list->request_auth ($sender, $cmd, $robot, $gecos );
      &Log::do_log('info', 'SOAP subscribe :  %s from %s, auth requested (%d seconds)',$listname,$sender,time-$time_command);
      return SOAP::Data->name('result')->type('boolean')->value(1);
  }
  if ($action =~ /do_it/i) {
      
      my $is_sub = $list->is_user($sender);
      
      unless (defined($is_sub)) {
	  &Log::do_log('err','SOAP subscribe : user lookup failed');
	  die SOAP::Fault->faultcode('Server')
	      ->faultstring('Undef')
	      ->faultdetail("SOAP subscribe : user lookup failed");
      }
      
      if ($is_sub) {
	  
	  ## Only updates the date
	  ## Options remain the same
	  my $user = {};
	  $user->{'update_date'} = time;
	  $user->{'gecos'} = $gecos if $gecos;

	  &Log::do_log('err','Subscribe : user already subscribed');

	  die SOAP::Fault->faultcode('Server')
	      ->faultstring('Undef.')
		  ->faultdetail("SOAP subscribe : update user failed")
		      unless $list->update_user($sender, $user);
      }else {
	  
	  my $u;
	  my $defaults = $list->get_default_user_options();
	  %{$u} = %{$defaults};
	  $u->{'email'} = $sender;
	  $u->{'gecos'} = $gecos;
	  $u->{'password'} = &tools::crypt_password($password);
	  $u->{'date'} = $u->{'update_date'} = time;
	  
	  die SOAP::Fault->faultcode('Server')
	      ->faultstring('Undef')
		  ->faultdetail("SOAP subscribe : add user failed")
		      unless $list->add_user($u);
      }
      
      if ($List::use_db) {
	  my $u = &List::get_user_db($sender);
	  
	  &List::update_user_db($sender, {'lang' => $u->{'lang'} || $list->{'admin'}{'lang'},
					  'password' => $u->{'password'} || &tools::tmp_passwd($sender)
					  });
      }
      
      $list->save();

      ## Now send the welcome file to the user
      unless ($quiet || ($action =~ /quiet/i )) {
	  my %context;
	  $context{'subject'} = sprintf(&Language::Msg(8, 6, "Welcome to list %s"), $list->{'name'});
	  $context{'body'} = sprintf(&Language::Msg(8, 6, "You are now subscriber of list %s"), $list->{'name'});
	  $list->send_file('welcome', $sender, $robot, \%context);
      }
      
      ## If requested send notification to owners
      if ($action =~ /notify/i) {
	  $list->send_notify_to_owner({'who' => $sender,
				       'gecos' => $gecos,
				       'type' => 'subscribe'});
      }
      &Log::do_log('info', 'SOAP subcribe : %s from %s accepted', $listname, $sender);
      
      return SOAP::Data->name('result')->type('boolean')->value(1);
  }
  
  &Log::do_log('info', 'SOAP subscribe : %s from %s aborted, unknown requested action in scenario',$listname,$sender);
  die SOAP::Fault->faultcode('Server')
      ->faultstring('Undef')
      ->faultdetail("SOAP subscribe : %s from %s aborted because unknown requested action in scenario",$listname,$sender);
}

 ## Which list the user is subscribed to 
 ## TODO (pour listmaster, toutes les listes)
 sub complexWhich {
     my $self = shift;
     my @result;
     my $sender = $ENV{'USER_EMAIL'};
     &do_log('notice', 'complexWhich(%s)',$sender);

     $self->which('complex');
 }

 sub complexLists {
     my $self = shift;
     my $topic = shift || '';
     my $subtopic = shift || '';
     my @result;
     my $sender = $ENV{'USER_EMAIL'};
     &do_log('notice', 'complexLists(%s)',$sender);

     $self->lists($topic, $subtopic, 'complex');
 }

## Which list the user is subscribed to 
## TODO (pour listmaster, toutes les listes)
## Simplified return structure
sub which {
    my $self = shift;
    my $mode = shift;
    my @result;
    my $sender = $ENV{'USER_EMAIL'};
    &do_log('notice', 'which(%s,%s)',$sender,$mode);

    unless ($sender) {
	die SOAP::Fault->faultcode('Client')
	    ->faultstring('User not authentified')
	    ->faultdetail('You should login first');
    }
    
    foreach my $listname( &List::get_which($sender,'*', 'member') ){ 	    
	my $list = new List ($listname);
	my $robot = $list->{'admin'}{'host'};
	my $list_address;
	my $result_item;

	next unless (&List::request_action ('visibility', 'md5', $robot,
					    {'listname' =>  $listname,
					     'sender' =>$sender}) =~ /do_it/);
	
	$result_item->{'listAddress'} = $listname.'@'.$list->{'domain'};
	$result_item->{'subject'} = $list->{'admin'}{'subject'};
	$result_item->{'subject'} =~ s/;/,/g;
	$result_item->{'homepage'} = $Conf{'wwsympa_url'}.'/info/'.$listname;
	 
	## determine status of user 
	$result_item->{'isOwner'} = 0;
	if (($list->am_i('owner',$sender) || $list->am_i('owner',$sender))) {
	    $result_item->{'isOwner'} = 1;
	}
	$result_item->{'isEditor'} = 0;
	if (($list->am_i('editor',$sender) || $list->am_i('editor',$sender))) {
	     $result_item->{'isEditor'} = 1;
	 }
	$result_item->{'isSubscriber'} = 0;
	if ($list->is_user($sender)) {
	    $result_item->{'isSubscriber'} = 1;
	}
	
	my $listInfo;
	if ($mode eq 'complex') {
	    $listInfo = struct_to_soap($result_item);
	}else {
	    $listInfo = struct_to_soap($result_item, 'as_string');
	}

	push @result, $listInfo;
	
    }
    
#    return SOAP::Data->name('return')->type->('ArrayOfString')->value(\@result);
    return SOAP::Data->name('return')->value(\@result);
}

## Return a structure in SOAP data format
## either flat (string) or structured (complexType)
sub struct_to_soap {
    my ($data, $format) = @_;
    my $soap_data;
    
    unless (ref($data) eq 'HASH') {
	return undef;
    }

    if ($format eq 'as_string') {
	my @all;
	my $formated_data;
	foreach my $k (keys %$data) {
	    push @all, $k.'='.$data->{$k};
	}

	$formated_data = join ';', @all;
	$soap_data = SOAP::Data->type('string')->value($formated_data);
    }else {	
	my $formated_data;
	foreach my $k (keys %$data) {
	    $formated_data->{$k} = SOAP::Data->name($k)->type($types{'listType'}{$k})->value($data->{$k});
	}

	$soap_data = SOAP::Data->value($formated_data);
    }

    return $soap_data;
}

1;
