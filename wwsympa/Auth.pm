# wwslib.pm - This module includes functions used by wwsympa.fcgi
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
use lib '--LIBDIR--';

use Exporter;
@ISA = ('Exporter');
@EXPORT = ();

use Log;
use Conf;
use List;

# use Net::SSLeay qw(&get_https);
# use Net::SSLeay;



 ## authentication : via email or uid
 sub check_auth{
     my $auth = shift; ## User email or UID
     my $pwd = shift; ## Password
     &do_log('debug', 'Auth::check_auth(%s)', $auth);

     my ($canonic, $user);

     if( &tools::valid_email($auth)) {
	 return &authentication($auth,$pwd);

     }else{
	 ## This is an UID
	 if ($canonic = &ldap_authentication($auth,$pwd,'uid_filter')){

	     unless($user = &List::get_user_db($canonic)){
		 $user = {'email' => $canonic};
	     }
	     return {'user' => $user,
		     'auth' => 'ldap',
		     'alt_emails' => {$canonic => 'ldap'}
		 };
	     
	 }else{
	     &main::error_message('incorrect_passwd') unless ($ENV{'SYMPA_SOAP'});
	     &do_log('err', "Incorrect Ldap password");
	     return undef;
	 }
     }
 }


sub authentication {
    my ($email,$pwd) = @_;
    my ($user,$canonic);
    &do_log('debug', 'Auth::authentication(%s)', $auth);


    unless ($user = &List::get_user_db($email)) {
	$user = {'email' => $email,
		 'password' => &tools::tmp_passwd($email)
		 };
    }    
    unless ($user->{'password'}) {
	$user->{'password'} = &tools::tmp_passwd($email);
    }
    


    foreach my $auth_service (@{$Conf{'auth_services'}}){
	next if ($email !~ /$auth_service->{'regexp'}/i);
	next if (($email =~ /$auth_service->{'negative_regexp'}/i)&&($auth_service->{'negative_regexp'}));
	if ($auth_service->{'auth_type'} eq 'user_table') {
     
	    if((($wwsconf->{'password_case'} eq 'insensitive') && (lc($pwd) eq lc($user->{'password'}))) || 
	       ($pwd eq $user->{'password'})) {
		return {'user' => $user,
			'auth' => 'classic',
			'alt_emails' => {$email => 'classic'}
			};
	    }
	}elsif($auth_service->{'auth_type'} eq 'ldap') {
	    if ($canonic = &ldap_authentication($email,$pwd,'email_filter')){
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
    unless ($ENV{'SYMPA_SOAP'}) {
	foreach my $auth_service (@{$Conf{'auth_services'}}){
	    next unless ($email !~ /$auth_service->{'regexp'}/i);
	    next unless (($email =~ /$auth_service->{'negative_regexp'}/i)&&($auth_service->{'negative_regexp'}));
	    if ($auth_service->{'auth_type'} eq 'user_table') {
		if ($user->{'password'} =~ /^init/i) {
		    &main::error_message('init_passwd');
		    last;
		}
	    }
	}
    }
    
    &main::error_message('incorrect_passwd') unless ($ENV{'SYMPA_SOAP'});
    &do_log('err','authentication: incorrect password for user %s', $email);

    $param->{'init_email'} = $email;
    $param->{'escaped_init_email'} = &tools::escape_chars($email);
    return undef;
}


sub ldap_authentication {
     my ($auth,$pwd,$whichfilter) = @_;
     my ($cnx, $mesg, $host,$ldap_passwd,$ldap_anonymous);
     &do_log('debug2','Auth::ldap_authentication(%s,%s,%s)', $auth,$pwd,$whichfilter);

     unless (&tools::get_filename('etc', 'auth.conf', $robot)) {
	 return undef;
     }

     ## No LDAP entry is defined in auth.conf
     if ($#{$Conf{'auth_services'}} < 0) {
	 &do_log('notice', 'Skipping empty auth.conf');
	 return undef;
     }

     unless (eval "require Net::LDAP") {
	 do_log ('err',"Unable to use LDAP library, Net::LDAP required, install perl-ldap (CPAN) first");
	 return undef;
     }
     require Net::LDAP;

     unless (eval "require Net::LDAP::Entry") {
	 do_log ('err',"Unable to use LDAP library,Net::LDAP::Entry required install perl-ldap (CPAN) first");
	 return undef;
     }
     require Net::LDAP::Entry;

     unless (eval "require Net::LDAP::Message") {
	 do_log ('err',"Unable to use LDAP library,Net::LDAP::Entry required install perl-ldap (CPAN) first");
	 return undef;
     }
     require Net::LDAP::Message;
     
     foreach my $ldap (@{$Conf{'auth_services'}}){
	 # only ldap service are to be applied here
	 next unless ($ldap->{'auth_type'} eq 'ldap');

	 # skip ldap auth service if the an email address was provided
	 # and this email address does not match the corresponding regexp 
	 next if ($auth =~ /@/ && $auth !~ /$ldap->{'regexp'}/i);
  
	 foreach $host (split(/,/,$ldap->{'host'})){

	     my @alternative_conf = split(/,/,$ldap->{'alternative_email_attribute'});
	     my $attrs = $ldap->{'email_attribute'};
	     my $filter = $ldap->{'get_dn_by_uid_filter'} if($whichfilter eq 'uid_filter');
	     $filter = $ldap->{'get_dn_by_email_filter'} if($whichfilter eq 'email_filter');
	     $filter =~ s/\[sender\]/$auth/ig;

	     ##anonymous bind in order to have the user's DN
	     my $ldap_anonymous;
	     if ($ldap->{'use_ssl'}) {
		 unless (eval "require Net::LDAPS") {
		     do_log ('err',"Unable to use LDAPS library, Net::LDAPS required");
		     return undef;
		 } 
		 require Net::LDAPS;

		 my %param;
		 $param{'timeout'} = $ldap->{'timeout'} if ($ldap->{'timeout'});
		 $param{'sslversion'} = $ldap->{'ssl_version'} if ($ldap->{'ssl_version'});
		 $param{'ciphers'} = $ldap->{'ssl_ciphers'} if ($ldap->{'ssl_ciphers'});

		 $ldap_anonymous = Net::LDAPS->new($host,%param);
	     }else {
		 $ldap_anonymous = Net::LDAP->new($host,timeout => $ldap->{'timeout'});
	     }

	     unless ($ldap_anonymous ){
		 do_log ('err','Unable to connect to the LDAP server %s',$host);
		 next;
	     }

	     my $cnx;
	     ## Not always anonymous...
	     if (defined ($ldap->{'bind_dn'}) && defined ($ldap->{'bind_password'})) {
		 $cnx = $ldap_anonymous->bind($ldap->{'bind_dn'}, password =>$ldap->{'bind_password'});
	     }else {
		 $cnx = $ldap_anonymous->bind;
	     }

	     unless(defined($cnx) && ($cnx->code() == 0)){
		 do_log('notice',"Can\'t bind to LDAP server $host");
		 last;
		 #do_log ('err','Ldap Error : %s, Ldap server error : %s',$cnx->error,$cnx->server_error);
		 #$ldap_anonymous->unbind;
	     }

	     $mesg = $ldap_anonymous->search(base => $ldap->{'suffix'},
					     filter => "$filter",
					     scope => $ldap->{'scope'} ,
					     timeout => $ldap->{'timeout'});

	     if ($mesg->count() == 0) {
		 do_log('notice','No entry in the Ldap Directory Tree of %s for %s',$host,$auth);
		 $ldap_anonymous->unbind;
		 last;
	     }

	     my $refhash=$mesg->as_struct();
	     my (@DN) = keys(%$refhash);
	     $ldap_anonymous->unbind;

	     ##  bind with the DN and the pwd
	     my $ldap_passwd;
	     if ($ldap->{'use_ssl'}) {
		 unless (eval "require Net::LDAPS") {
		     do_log ('err',"Unable to use LDAPS library, Net::LDAPS required");
		     return undef;
		 } 
		 require Net::LDAPS;

		 my %param;
		 $param{'timeout'} = $ldap->{'timeout'} if ($ldap->{'timeout'});
		 $param{'sslversion'} = $ldap->{'ssl_version'} if ($ldap->{'ssl_version'});
		 $param{'ciphers'} = $ldap->{'ssl_ciphers'} if ($ldap->{'ssl_ciphers'});

		 $ldap_passwd = Net::LDAPS->new($host,%param);
	     }else {
		 $ldap_passwd = Net::LDAP->new($host,timeout => $ldap->{'timeout'});
	     }

	     unless ($ldap_passwd) {
		 do_log('err','Unable to (re) connect to the LDAP server %s', $host);
		 do_log ('err','Ldap Error : %s, Ldap server error : %s',$ldap_passwd->error,$ldap_passwd->server_error);
		 next;
	     }

	     $cnx = $ldap_passwd->bind($DN[0], password => $pwd);
	     unless(defined($cnx) && ($cnx->code() == 0)){
		 do_log('notice', 'Incorrect password for user %s ; host: %s',$auth, $host);
		 #do_log ('err','Ldap Error : %s, Ldap server error : %s',$cnx->error,$cnx->server_error);
		 $ldap_passwd->unbind;
		 last;
	     }
	     # this bind is anonymous and may return 
	     # $ldap_passwd->bind($DN[0]);
	     $mesg= $ldap_passwd->search ( base => $ldap->{'suffix'},
					   filter => "$filter",
					   scope => $ldap->{'scope'},
					   timeout => $ldap->{'timeout'}
					   );

	     if ($mesg->count() == 0) {
		 do_log('notice',"No entry in the Ldap Directory Tree of %s,$host");
		 $ldap_passwd->unbind;
		 last;
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

	     $ldap_passwd->unbind or do_log('notice', "unable to unbind");
	     do_log('debug3',"canonic: $canonic_email[0]");
	     return lc($canonic_email[0]);
	 }

	 next unless ($ldap_anonymous);
	 next unless ($ldap_passwd);
	 next unless (defined($cnx) && ($cnx->code() == 0));
	 next if($mesg->count() == 0);
	 next if($mesg->code() != 0);
	 next unless ($host);
     }
 }


# fetch user email using his cas net_id and the paragrapah number in auth.conf
sub cas_get_email_by_net_id {
    
    my $net_id = shift;   
    my $auth_id = shift;

    do_log ('info',"Auth::cas_get_email_by_net_id($net_id,$auth_id)");

    unless (eval "require Net::LDAP") {
	do_log ('err',"Unable to use LDAP library, Net::LDAP required, install perl-ldap (CPAN) first");
	return undef;
    }
    require Net::LDAP;

    unless (eval "require Net::LDAP::Entry") {
	do_log ('err',"Unable to use LDAP library,Net::LDAP::Entry required install perl-ldap (CPAN) first");
	return undef;
    }
    require Net::LDAP::Entry;
    
    unless (eval "require Net::LDAP::Message") {
	do_log ('err',"Unable to use LDAP library,Net::LDAP::Entry required install perl-ldap (CPAN) first");
	return undef;
    }
    require Net::LDAP::Message;

    my $ldap = @{$Conf{'auth_services'}}[$auth_id];
    my $filter = $ldap->{'ldap_get_email_by_uid_filter'} ;
    $filter =~ s/\[uid\]/$net_id/ig;


    foreach my $host (split(/,/,$ldap->{'ldap_host'})){

#	my @alternative_conf = split(/,/,$ldap->{'alternative_email_attribute'});
		
	my $ldap_anonymous;

	my %param;
	$param{'timeout'} = $ldap->{'ldap_timeout'} || 3;
	$param{'async'} = 1;
	
	if ($ldap->{'ldap_use_ssl'}) {
	    $param{'sslversion'} = $ldap->{'ldap_ssl_version'} if ($ldap->{'ldap_ssl_version'});
	    $param{'ciphers'} = $ldap->{'ldap_ssl_ciphers'} if ($ldap->{'ldap_ssl_ciphers'});

	    unless (eval "require Net::LDAPS") {
		do_log ('err',"Unable to use LDAPS library, Net::LDAPS required");
		return undef;
	    } 
	    require Net::LDAPS;
	    
	    $ldap_anonymous = Net::LDAPS->new($host,%param);
	}else {
	    $ldap_anonymous = Net::LDAP->new($host,%param);
	}
	
	unless ($ldap_anonymous ){
	    do_log ('err','Unable to connect to the LDAP server %s',$host);
	    next;
	}
	
	my $cnx;
	## Not always anonymous...
	if (defined ($ldap->{'bind_dn'}) && defined ($ldap->{'bind_password'})) {
	    $cnx = $ldap_anonymous->bind($ldap->{'ldap_bind_dn'}, password =>$ldap->{'ldap_bind_password'});
	}else {
	    $cnx = $ldap_anonymous->bind;
	}
	
	unless(defined($cnx) && ($cnx->code() == 0)){
	    do_log('notice',"Can\'t bind to LDAP server $host");
	    last;
	    #do_log ('err','Ldap Error : %s, Ldap server error : %s',$cnx->error,$cnx->server_error);
	    #$ldap_anonymous->unbind;
	}
	do_log ('debug',"Binded to LDAP host $host, search base=$ldap->{'ldap_suffix'},filter=$filter,scope=$ldap->{'ldap_scope'},attrs=$ldap->{'ldap_email_attribute'}");
	
	my $emails= $ldap_anonymous->search ( base => $ldap->{'ldap_suffix'},
				      filter => $filter,
				      scope => $ldap->{'ldap_scope'},
				      timeout => $ldap->{'ldap_timeout'},
				      attrs =>  $ldap->{'ldap_email_attribute'}
				      );
	my $count = $emails->count();

	if ($emails->count() == 0) {
	    do_log('notice',"No entry in the Ldap Directory Tree of %s,$host");
	    $ldap_anonymous->unbind;
	    last;
	}

	my @results = $emails->entries;
	foreach my $result (@results){
	    return (lc($result->get_value($ldap->{'ldap_email_attribute'})));
	}

	
	## return only the first attribute
			
	my $entry = $emails->entry(0);
	my @canonic_email = $entry->get_value($ldap->{'ldap_email_attribute'},alloptions);
	foreach my $email (@canonic_email){
	    return(lc($email));
	}
    }

 }


1;


