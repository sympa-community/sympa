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

=head1 METHODS

=item check_cookie( <VALUE OF THE COOKIE> )

This web service take the value of a cookie (I<VALUE OF THE COOKIE>) given by Sympa and try to check
if the cookie is not a fake one. A Server fault is given back if the cookie
is a fake one. If the cookie has been given by Sympa the email of the personn
authenticated is given back
 
=item lists(I<ROBOT>,I<SENDER>,I<TOPIC>,I<SUBTOPIC>)

Return the list of lists for a topic/subtopic
I<TOPIC> and I<SUBTOPIC> are optional parameters: if none specified, the list of all lists
is given back. 
I<SENDER> authentification is checked to know which lists can be see by the user.
If the authorization failed it return only list of public lists
If the number of parameters is incorrect it generates a SOAP.Client Exception.

=item login( <HTTP_HOST> <EMAIL> <PASSWORD> )

This web service gives back a cookie from Sympa (the one called sympauser) only
if the user I<EMAIL> gives his password (I<PASSWORD>). The parameter I<HTTP_HOST> is 
usually $ENV{HTTP_HOST}, but needs to be given in order to make the cookie.
 
=item isSubscriber( I<LIST>, I<USER>)

Return true of false weather I<USER> is a subscriber of I<LIST>
or not. If the number of parameters is incorrect it generates a SOAP.Client
Exception.
 
=item review( I<LIST>, I<ROBOT>, I<SENDER>, I<PASSWORD>)

Return the members of I<LIST> in the virtual robot I<ROBOT>, only
if I<SENDER> (e-mail) and his password (I<PASSWORD>) matchs and have
the rights. If not gives a reason of failure : unknown_list, no_subscribers,
undef.
If the number of parameters is incorrect it generates a SOAP.Client Exception.
If the authorization failed it generates a SOAP.Server Exception.
If request_action gives back nothing it generates a SOAP.Server Exception.
 
=item signoff( I<LIST>, I<ROBOT>, I<SENDER>, I<PASSWORD>, I<EMAIL>)

The user I<SENDER> sign off from the list I<LIST> with the given password (I<PASSWORD>)
and the given email I<EMAIL> (if it's a different one from I<SENDER>).

=item subscribe( I<LIST>, I<VIRTUAL ROBOT>, I<SENDER>, I<PASSWORD>, I<GECOS>)

The user I<SENDER> subscribe to the list I<LIST> with the following password (I<PASSWORD>)
and gecos (I<GECOS> is optionnal).

=item which(I<ROBOT>,I<SENDER>)

Return the list of subscribed lists for the sender
If the number of parameters is incorrect it generates a SOAP.Client Exception.


=cut

package sympasoap;

use Exporter;
use HTTP::Cookies;

@ISA = ('Exporter');
@EXPORT = ();

use Conf;
use Log;
use Auth;


sub check_cookie {
    my $class = shift;

    my $sender = $ENV{'USER_EMAIL'};

    unless ($sender) {
	die SOAP::Fault->faultcode('Client')
	    ->faultstring('User not authentified')
	    ->faultdetail('You should login first');
    }

    &Log::do_log('debug', 'SOAP check_cookie');
    
    return SOAP::Data->name('result')->type('string')->value($sender);
}

sub lists {

    my $self = shift; #$self is a service object
    my $topic = shift;
    my $subtopic = shift;
    my $sender = $ENV{'USER_EMAIL'};

    unless ($sender) {
	die SOAP::Fault->faultcode('Client')
	    ->faultstring('User not authentified')
	    ->faultdetail('You should login first');
    }

    my @result;  
    
    &do_log('info', 'SOAP lists(%s,%s)', $robot, $topic);
   
    foreach my $listname ( &List::get_lists() ) {
	
	my $list = new List ($listname);
	my $robot = $list->{'domain'};
	my $result_item = {};
	my $action = &List::request_action ('visibility','md5',$robot,
					    {'listname' =>  $listname,
					     'sender' => $sender}
					    );
	next unless ($action eq 'do_it');
	
	## determine status of user 
	if (($list->am_i('owner',$sender) || $list->am_i('owner',$sender))) {
	    $result_item->{'is_owner'} = 1;
	}
	if (($list->am_i('editor',$sender) || $list->am_i('editor',$sender))) {
	    $result_item->{'is_editor'} = 1;
	}
	if ($list->is_user($sender)) {
	    $result_item->{'is_subscriber'} = 1;
	}

	##building result packet
	$result_item->{'list_address'} = $listname.'@'.$list->{'domain'};
	$result_item->{'subject'} = $list->{'admin'}{'subject'};
	$result_item->{'homepage'} = $Conf{'wwsympa_url'}.'/info/'.$listname; 
		
	my $list_homepage = $Conf{'wwsympa_url'}.'/info/'.$listname;
	
	## no topic ; List all lists
	if (!$topic) {
	    push @result, SOAP::Data->name('result')->value($result_item);
	    
	}elsif ($list->{'admin'}{'topics'}) {
	    foreach my $topic (@{$list->{'admin'}{'topics'}}) {
		my @tree = split '/', $topic;
		
		next if (($topic) && ($tree[0] ne $topic));
		next if (($subtopic) && ($tree[1] ne $subtopic));
		
		push @result, SOAP::Data->name('result')->value($result_item);
	    }
	}elsif ($topic  eq 'topicsless') {
	    	push @result, SOAP::Data->name('result')->value($result_item);
	}
    }
    
    return SOAP::Data->name('return')->value(\@result);
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

    return SOAP::Data->name('result')->type('boolean')->value(1);
}

sub isSubscriber {
  my ($class,$listname,$user)=@_;

  unless ($listname and $user) {
      die SOAP::Fault->faultcode('Client')
	  ->faultstring('Incorrect number of parameters')
	  ->faultdetail('Use : <list> <user email>');
  }

  $listname = lc($listname);  
  my $thelist = new List ($listname);  

  &Log::do_log('debug', 'SOAP isSubscriber(%s)', $listname);

  if ($thelist) {
      return SOAP::Data->name('result')->type('boolean')->value($thelist->is_user($user));
  }
  else {
      die SOAP::Fault->faultcode('Server')
	  ->faultstring('Unknown list.')
	  ->faultdetail("List $listname unknown");
  }

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
 sub which {
     my $self = shift;
     &do_log('debug', 'which(%s)',$sender);
     my @result;
     my $sender = $ENV{'USER_EMAIL'};

     unless ($sender) {
	 die SOAP::Fault->faultcode('Client')
	     ->faultstring('User not authentified')
	     ->faultdetail('You should login first');
     }

     foreach my $listname( &List::get_which($sender,'*', 'member') ){ 	    
	 my $list = new List ($listname);
	 my $robot = $list->{'admin'}{'host'};
	 my $result_item = {};
	 
	 next unless (&List::request_action ('visibility', 'md5', $robot,
					     {'listname' =>  $listname,
					      'sender' =>$sender}) =~ /do_it/);
	 
	 $result_item->{'list_address'} = $listname.'@'.$list->{'domain'};
	 $result_item->{'subject'} = $list->{'admin'}{'subject'};
	 $result_item->{'homepage'} = $Conf{'wwsympa_url'}.'/info/'.$listname; 
	 
	 ## determine status of user 
	 if (($list->am_i('owner',$sender) || $list->am_i('owner',$sender))) {
	     $result_item->{'is_owner'} = 1;
	 }
	 if (($list->am_i('editor',$sender) || $list->am_i('editor',$sender))) {
	     $result_item->{'is_editor'} = 1;
	 }
	 if ($list->is_user($sender)) {
	     $result_item->{'is_subscriber'} = 1;
	 }
	 
	 push @result, SOAP::Data->name('result')->value($result_item);
	
     }

     &do_log('notice','SOAP: ....which()');

     return SOAP::Data->name('return')->value(\@result);

 }

1;
