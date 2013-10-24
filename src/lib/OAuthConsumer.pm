# OAuthConsumer.pm - This module implements OAuth consumer facilities
#<!-- RCS Identication ; $Revision: 7207 $ ; $Date: 2011-09-05 15:33:26 +0200 (lun 05 sep 2011) $ --> 

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

=pod 

=head1 NAME 

I<OAuthConsumer.pm> - OAuth consumer facilities for internal use in Sympa

=head1 DESCRIPTION 

This package provides abstraction from the OAuth workflow (client side) when performing authorization request,
handles token retrieving as well as database storage.

=cut 

package OAuthConsumer;

use strict;

use OAuth::Lite::Consumer;

use Data::Dumper;

#use List;
use Auth;
use tools;
#use tt2;
use Conf;
use Log;

=pod 

=head1 SUBFUNCTIONS 

This is the description of the subfunctions contained by OAuthConsumer.pm

=cut 


=pod 

=head2 sub new

Creates a new OAuthConsumer object.

=head3 Arguments 

=over 

=item * I<$user>, a user email

=item * I<$provider>, the OAuth provider key

=item * I<$provider_secret>, the OAuth provider shared secret

=item * I<$request_token_path>, the temporary token request URL

=item * I<$access_token_path>, the access token request URL

=item * I<$authorize_path>, the authorization URL

=back 

=head3 Return 

=over 

=item * I<a OAuthConsumer object>, if created

=item * I<undef>, if something went wrong

=back 

=head3 Calls 

=over 

=item * &Log::do_log

=back 

=cut 

## Creates a new object
sub new {
	my $pkg = shift;
	my %param = @_;
	
	my $consumer = {
		user => $param{'user'},
		provider => $param{'provider'},
		consumer_key => $param{'consumer_key'},
		consumer_secret => $param{'consumer_secret'},
		request_token_path => $param{'request_token_path'},
		access_token_path  => $param{'access_token_path'},
		authorize_path => $param{'authorize_path'},
		redirect_url => undef
 	};
	&Log::do_log('debug2', 'OAuthConsumer::new(%s, %s, %s)', $param{'user'}, $param{'provider'}, $param{'consumer_key'});
	
	$consumer->{'handler'} = OAuth::Lite::Consumer->new(
		consumer_key => $param{'consumer_key'},
		consumer_secret => $param{'consumer_secret'},
		request_token_path => $param{'request_token_path'},
        access_token_path  => $param{'access_token_path'},
        authorize_path => $param{'authorize_path'}
	);
	
	my $sth;
	unless($sth = &SDM::do_prepared_query('SELECT tmp_token_oauthconsumer AS tmp_token, tmp_secret_oauthconsumer AS tmp_secret, access_token_oauthconsumer AS access_token, access_secret_oauthconsumer AS access_secret FROM oauthconsumer_sessions_table WHERE user_oauthconsumer=? AND provider_oauthconsumer=?', $param{'user'}, $param{'provider'})) {
		&Log::do_log('err','Unable to load token data %s %s', $param{'user'}, $param{'provider'});
		return undef;
    }
    
	$consumer->{'session'} = {
		defined => undef,
		tmp => undef,
		access => undef
	};
	if(my $data = $sth->fetchrow_hashref('NAME_lc')) {
		$consumer->{'session'}{'tmp'} = new OAuth::Lite::Token(
			token => $data->{'tmp_token'},
			secret => $data->{'tmp_secret'}
		) if($data->{'tmp_token'});
		$consumer->{'session'}{'access'} = new OAuth::Lite::Token(
			token => $data->{'access_token'},
			secret => $data->{'access_secret'}
		) if($data->{'access_token'});
		$consumer->{'session'}{'defined'} = 1;
	}
	
	return bless $consumer, $pkg;
}

sub setWebEnv {
	my $self = shift;
	my %param = @_;
	
	$self->{'robot'} = $param{'robot'};
	$self->{'here_path'} = $param{'here_path'};
	$self->{'base_path'} = $param{'base_path'};
}

sub mustRedirect {
	my $self = shift;
	return $self->{'redirect_url'};
}

=pod 

=head2 sub fetchRessource

Check if user has an access token already and fetch ressource

=head3 Arguments 

=over 

=item * I<$self>, the OAuthConsumer object to test.

=item * I<$url>, the ressource url.

=item * I<$params>, (optionnal) the request parameters.

=back 

=head3 Return 

=over 

=item * I<string>, ressource body

=item * I<undef>, if something went wrong

=back 

=head3 Calls 

=over 

=item * None

=back 

=cut 

## Check if user has an access token already and fetch ressource
sub fetchRessource {
	my $self = shift;
	my %param = @_;
	
	&Log::do_log('debug2', 'OAuthConsumer::fetchRessource(%s)', $param{'url'});
	
	# Get access token, return 1 if it exists
	my $token = $self->hasAccess();
	return undef unless(defined $token); # Should never return here unless failed to retreive token
	
	my $res = $self->{'handler'}->request(
		method => 'GET', 
		url    => $param{'url'},
		token  => $token,
		params => $param{'params'},
	);
	
	unless($res->is_success) {
		if($res->code == 400 || $res->code == 401) {
			my $auth_header = $res->header('WWW-Authenticate');
			if($auth_header && $auth_header =~ /^OAuth/) {
				# access token may be expired,
				# get request-token and authorize again
				if($self->{'here_path'}) { # We are running in web env.
					$self->triggerFlow();
				}
				return undef;
			}else{
				# another auth error.
				return undef;
			}
		}
		# another error.
		return undef;
	}
	
	return $res->decoded_content || $res->content;
}

=pod 

=head2 sub hasAccess

Check if user has an access token already, triggers OAuth workflow otherwise

=head3 Arguments 

=over 

=item * I<$self>, the OAuthConsumer object to test.

=back 

=head3 Return 

=over 

=item * I<reference to a hash>, if there is a known access token

=item * I<undef>, if no access token found

=back 

=head3 Calls 

=over 

=item * None

=back 

=cut 

## Check if user has an access token already, triggers OAuth workflow if none found
sub hasAccess {
	my $self = shift;
	&Log::do_log('debug2', 'OAuthConsumer::hasAccess(%s, %s)', $self->{'user'}, $self->{'consumer_type'}.':'.$self->{'provider'});
	
	unless(defined $self->{'session'}{'access'}) {
		if($self->{'here_path'}) { # We are running in web env.
			$self->triggerFlow();
		}
		return undef;
	}
	
	return $self->{'session'}{'access'};
}

=pod 

=head2 sub triggerFlow

Triggers OAuth authorization workflow, call only in web env.

=head3 Arguments 

=over 

=item * I<$self>, the OAuthConsumer to use.

=back 

=head3 Return 

=over 

=item * I<1>, if everything's alright

=back 

=head3 Calls 

=over 

=item * None

=back 

=cut 

## Triggers OAuth workflow, call only in web env.
sub triggerFlow {
	my $self = shift;
	&Log::do_log('debug2', 'OAuthConsumer::triggerFlow(%s, %s)', $self->{'user'}, $self->{'consumer_type'}.':'.$self->{'provider'});
	
	my $ticket = &Auth::create_one_time_ticket(
		$self->{'user'},
		$self->{'robot'},
		$self->{'here_path'},
		'mail'
	);
	my $callback = $self->{'base_path'}.'/oauth_ready/'.$self->{'provider'}.'/'.$ticket;
	
	my $tmp = $self->{'handler'}->get_request_token(
		callback_url => $callback
	);

	unless(defined $tmp) {
		&Log::do_log('err', 'Unable to get tmp token for %s %s %s', $self->{'user'}, $self->{'provider'}, $self->{'handler'}->errstr);
		return undef;
	}
	
	if(defined $self->{'session'}{'defined'}) {
		unless(&SDM::do_query('UPDATE oauthconsumer_sessions_table SET tmp_token_oauthconsumer=%s, tmp_secret_oauthconsumer=%s WHERE user_oauthconsumer=%s AND provider_oauthconsumer=%s', &SDM::quote($tmp->{'token'}), &SDM::quote($tmp->{'secret'}), &SDM::quote($self->{'user'}), &SDM::quote($self->{'provider'}))) {
			&Log::do_log('err', 'Unable to update token record %s %s in database', $self->{'user'}, $self->{'provider'});
			return undef;
		}
	}else{
		unless(&SDM::do_query('INSERT INTO oauthconsumer_sessions_table(user_oauthconsumer, provider_oauthconsumer, tmp_token_oauthconsumer, tmp_secret_oauthconsumer) VALUES (%s, %s, %s, %s)', &SDM::quote($self->{'user'}), &SDM::quote($self->{'provider'}), &SDM::quote($tmp->{'token'}), &SDM::quote($tmp->{'secret'}))) {
			&Log::do_log('err', 'Unable to add new token record %s %s in database', $self->{'user'}, $self->{'provider'});
			return undef;
		}
	}
	
	$self->{'session'}{'tmp'} = $tmp;
	
	my $url = $self->{'handler'}->url_to_authorize(
		token => $tmp
	);
	
	&Log::do_log('info', 'Ask for redirect to %s with callback %s for %s', $url, $callback, $self->{'here_path'});
	$self->{'redirect_url'} = $url;
	
	return 1;
}

=pod 

=head2 sub getAccessToken

Try to obtain access token from verifier.

=head3 Arguments 

=over 

=item * I<$self>, the OAuthConsumer object to test.

=back 

=head3 Return 

=over 

=item * I<1>, if the token was retreived successfully

=item * I<undef>, if something went wrong

=back 

=head3 Calls 

=over 

=item * None

=back 

=cut 

## Try to obtain access token from verifier
sub getAccessToken {
	my $self = shift;
	my %param = @_;
	&Log::do_log('debug2', 'OAuthConsumer::getAccessToken(%s, %s)', $self->{'user'}, $self->{'consumer_type'}.':'.$self->{'provider'});
	
	return $self->{'session'}{'access'} if(defined $self->{'session'}{'access'});
	
	return undef unless(defined $self->{'session'}{'tmp'} && $self->{'session'}{'tmp'}->token eq $param{'token'} && defined $param{'verifier'} && $param{'verifier'} ne '');
	
	my $access = $self->{'handler'}->get_access_token(
		token => $self->{'session'}{'tmp'},
		verifier => $param{'verifier'}
	);
	
	$self->{'session'}{'access'} = $access;
	$self->{'session'}{'tmp'} = undef;
	
	unless(&SDM::do_query('UPDATE oauthconsumer_sessions_table SET tmp_token_oauthconsumer=NULL, tmp_secret_oauthconsumer=NULL, access_token_oauthconsumer=%s, access_secret_oauthconsumer=%s WHERE user_oauthconsumer=%s AND provider_oauthconsumer=%s', &SDM::quote($access->{'token'}), &SDM::quote($access->{'secret'}), &SDM::quote($self->{'user'}), &SDM::quote($self->{'provider'}))) {
		&Log::do_log('err', 'Unable to update token record %s %s in database', $self->{'user'}, $self->{'provider'});
		return undef;
	}
	
	return $self->{'session'}{'access'};
}

## Packages must return true.
1;
=pod 

=head1 AUTHORS 

=over 

=item * Etienne Meleard <etienne.meleard AT renater.fr> 

=back 

=cut 
