# OAuthProvider.pm - This module implements OAuth provider facilities
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

I<OAuthProvider.pm> - OAuth provider facilities for internal use in Sympa

=head1 DESCRIPTION 

This package provides abstraction from the OAuth workflow (server side) when getting requests for temporary/access tokens,
handles database storage and provides helpers.

=cut 

package OAuthProvider;

use strict;

use OAuth::Lite::ServerUtil;
use URI::Escape;

use Data::Dumper;

#use List;
use Auth;
use tools;
#use tt2;
use Conf;
use Log;

=pod 

=head1 SUBFUNCTIONS 

This is the description of the subfunctions contained by OAuthProvider.pm

=cut 


=pod 

=head2 sub new

Creates a new OAuthProvider object.

=head3 Arguments 

=over 

=item * I<$method>, http method

=item * I<$url>, request url

=item * I<$authorization_header>

=item * I<$request_parameters>

=item * I<$request_body>

=back 

=head3 Return 

=over 

=item * I<a OAuthProvider object>, if created

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
	
	my $p = &_findParameters(
		authorization_header => $param{'authorization_header'},
		request_parameters => $param{'request_parameters'},
		request_body => $param{'request_body'}
	);
	return undef unless(defined($p));
	return undef unless(defined($p->{'oauth_consumer_key'}));
	
	my $c = &_getConsumerConfigFor($p->{'oauth_consumer_key'});
	return undef unless(defined($c));
	return undef unless(defined($c->{'enabled'}));
	return undef unless($c->{'enabled'} eq '1');
	
	my $provider = {
		method => $param{'method'},
		url => $param{'url'},
		params => $p,
		consumer_key => $p->{'oauth_consumer_key'},
		consumer_secret => $c->{'secret'}
	};

	&Log::do_log('debug2', 'OAuthProvider::new(%s)', $param{'consumer_key'});
	
 	$provider->{'constants'} = {
		old_request_timeout => 600, # Max age for requests timestamps
		nonce_timeout => 3 * 30 * 24 * 3600, # Time the nonce tags are kept
		temporary_timeout => 3600, # Time left to use the temporary token
		verifier_timeout => 300, # Time left to request access once the verifier has been set
		access_timeout => 3 * 30 * 24 * 3600 # Access timeout
	};
	
	$provider->{'util'} = OAuth::Lite::ServerUtil->new;
	$provider->{'util'}->support_signature_method('HMAC-SHA1');
	$provider->{'util'}->allow_extra_params(qw/oauth_callback oauth_verifier/);
	
	unless(&SDM::do_query(
		'DELETE FROM oauthprovider_sessions_table WHERE isaccess_oauthprovider IS NULL AND lasttime_oauthprovider<%d',
		time - $provider->{'constants'}{'temporary_timeout'}
	)) {
		&Log::do_log('err', 'Unable to delete old temporary tokens in database');
		return undef;
	}
	
	return bless $provider, $pkg;
}

sub consumerFromToken {
	my $token = shift;
	
	my $sth;
	unless($sth = &SDM::do_prepared_query('SELECT consumer_oauthprovider AS consumer FROM oauthprovider_sessions_table WHERE token_oauthprovider=?', $token)) {
		&Log::do_log('err','Unable to load token data %s', $token);
		return undef;
	}
    
	my $data = $sth->fetchrow_hashref('NAME_lc');
	return undef unless($data);
	return $data->{'consumer'};
}

=pod 

=head2 sub _findParameters

Seek various request aspects for parameters

=head3 Arguments 

=over 

=item * I<$authorization_header>

=item * I<$request_parameters>

=item * I<$request_body>

=back 

=head3 Return 

=over 

=item * I<a reference to a hash>

=item * I<undef>, if something went wrong

=back 

=head3 Calls 

=over 

=item * &Log::do_log

=back 

=cut 

## Seek various request aspects for parameters
sub _findParameters {
	my %param = @_;
	
	my $p = {};
	if(defined($param{'authorization_header'}) && $param{'authorization_header'} =~ /^OAuth /) {
		foreach my $b (split(/,\s*/, $param{'authorization_header'})) {
			next unless($b =~ /^(OAuth\s)?\s*(x?oauth_[^=]+)="([^"]*)"\s*$/);
			$p->{$2} = uri_unescape($3);
		}
	}elsif(defined($param{'request_body'})) {
		foreach my $k (keys(%{$param{'request_body'}})) {
			next unless($k =~ /^x?oauth_/);
			$p->{$k} = uri_unescape($param{'request_body'}{$k});
		}
	}elsif(defined($param{'request_parameters'})) {
		foreach my $k (keys(%{$param{'request_parameters'}})) {
			next unless($k =~ /^x?oauth_/);
			$p->{$k} = uri_unescape($param{'request_parameters'}{$k});
		}
	}else{
		return undef;
	}
	
	return $p;
}


=pod 

=head2 sub checkRequest

Check if a request is valid

if(my $http_code = $provider->checkRequest()) {
	$server->error($http_code, $provider->{'util'}->errstr);
}

=head3 Arguments 

=over 

=item * I<$self>, the OAuthProvider object to test.

=item * I<$checktoken>, boolean

=back 

=head3 Return 

=over 

=item * I<!= 1>, if request is NOT valid (http error code)

=item * I<undef>, if request is valid

=back 

=head3 Calls 

=over 

=item * None

=back 

=cut 

## Check if a request is valid
sub checkRequest {
	my $self = shift;
	my %param = @_;
	
	&Log::do_log('debug2', 'OAuthProvider::checkRequest(%s)', $param{'url'});
	
	my $checktoken = defined($param{'checktoken'}) ? $param{'checktoken'} : undef;
	unless($self->{'util'}->validate_params($self->{'params'}, $checktoken)) {
		return 400;
	}
	
	my $nonce = $self->{'params'}{'oauth_nonce'};
	my $token = $self->{'params'}{'oauth_token'};
	my $timestamp = $self->{'params'}{'oauth_timestamp'};
	
	return 401 unless($timestamp > time - $self->{'constants'}{'old_request_timeout'});
	
	unless(&SDM::do_query('DELETE FROM oauthprovider_nonce_table WHERE time_oauthprovider<%d', time - $self->{'constants'}{'nonce_timeout'})) {
		&Log::do_log('err', 'Unable to clean nonce store in database');
		return 401;
	}
	
	if($checktoken) {
		my $sth;
		unless($sth = &SDM::do_prepared_query(
			'SELECT id_oauthprovider AS id FROM oauthprovider_sessions_table WHERE consumer_oauthprovider=? AND token_oauthprovider=?',
			$self->{'consumer_key'},
			$token
		)) {
			&Log::do_log('err','Unable to get token %s %s', $self->{'consumer_key'}, $token);
			return 401;
		}
		
		if(my $data = $sth->fetchrow_hashref('NAME_lc')) {
			my $id = $data->{'id'};
			
			unless($sth = &SDM::do_prepared_query(
				'SELECT nonce_oauthprovider AS nonce FROM oauthprovider_nonce_table WHERE id_oauthprovider=? AND nonce_oauthprovider=?',
				$id,
				$nonce
			)) {
				&Log::do_log('err','Unable to check nonce %d %s', $id, $nonce);
				return 401;
			}
			
			return 401 if($sth->fetchrow_hashref('NAME_lc')); # Already used nonce
			
			unless(&SDM::do_query(
				'INSERT INTO oauthprovider_nonce_table(id_oauthprovider, nonce_oauthprovider, time_oauthprovider) VALUES (%d, %s, %d)',
				$id,
				&SDM::quote($nonce),
				time
			)) {
				&Log::do_log('err', 'Unable to add nonce record %d %s in database', $id, $nonce);
				return 401;
			}
		}
	}
	
	my $secret = '';
	if($checktoken) {
		my $sth;
		unless($sth = &SDM::do_prepared_query('SELECT secret_oauthprovider AS secret FROM oauthprovider_sessions_table WHERE token_oauthprovider=?', $token)) {
			&Log::do_log('err','Unable to load token data %s', $token);
			return undef;
		}
		
		my $data = $sth->fetchrow_hashref('NAME_lc');
		return 401 unless($data);
		$secret = $data->{'secret'};
	}
	
	$self->{'util'}->verify_signature(
		method          => $self->{'method'},
		params          => $self->{'params'},
		url             => $self->{'url'},
		consumer_secret => $self->{'consumer_secret'},
		token_secret => $secret
	) or return 401;
	
	return undef;
}

=pod 

=head2 sub generateTemporary

Create a temporary token

=head3 Arguments 

=over 

=item * I<$self>, the OAuthProvider object.

=item * I<$authorize>, the authorization url.

=back 

=head3 Return 

=over 

=item * I<string> response body

=back 

=head3 Calls 

=over 

=item * None

=back 

=cut 

## Create a temporary token
sub generateTemporary {
	my $self = shift;
	my %param = @_;
	&Log::do_log('debug2', 'OAuthProvider::generateTemporary(%s)', $self->{'consumer_key'});
	
	my $token = &_generateRandomString(32); # 9x10^62 entropy ...
	my $secret = &_generateRandomString(32); # may be sha1-ed or such ...
	
	unless(&SDM::do_query(
		'INSERT INTO oauthprovider_sessions_table(token_oauthprovider, secret_oauthprovider, isaccess_oauthprovider, accessgranted_oauthprovider, consumer_oauthprovider, user_oauthprovider, firsttime_oauthprovider, lasttime_oauthprovider, verifier_oauthprovider, callback_oauthprovider) VALUES (%s, %s, NULL, NULL, %s, NULL, %d, %d, NULL, %s)',
		&SDM::quote($token),
		&SDM::quote($secret),
		&SDM::quote($self->{'consumer_key'}),
		time,
		time,
		&SDM::quote($self->{'params'}{'oauth_callback'})
	)) {
		&Log::do_log('err', 'Unable to add new token record %s %s in database', $token, $self->{'consumer_key'});
		return undef;
	}
	
	my $r = 'oauth_token='.uri_escape($token);
	$r .= '&oauth_token_secret='.uri_escape($secret);
	$r .= '&oauth_expires_in='.$self->{'constants'}{'temporary_timeout'};
	$r .= '&xoauth_request_auth_url='.$param{'authorize'} if(defined($param{'authorize'}));
	$r .= '&oauth_callback_confirmed=true';
	
	return $r;
}

=pod 

=head2 sub getTemporary

Retreive a temporary token from database.

=head3 Arguments 

=over 

=item * I<$self>, the OAuthProvider to use.

=item * I<$token>, the token key.

=item * I<$timeout_type>, the timeout key, temporary or verifier.

=back 

=head3 Return 

=over 

=item * I<a reference to a hash>, if everything's alright

=item * I<undef>, if token does not exist or is not valid anymore

=back 

=head3 Calls 

=over 

=item * None

=back 

=cut 

## Retreive a temporary token from database
sub getTemporary {
	my $self = shift;
	my %param = @_;
	&Log::do_log('debug2', 'OAuthProvider::getTemporary(%s)', $param{'token'});
	
	my $sth;
	unless($sth = &SDM::do_prepared_query(
		'SELECT id_oauthprovider AS id, token_oauthprovider AS token, secret_oauthprovider AS secret, firsttime_oauthprovider AS firsttime, lasttime_oauthprovider AS lasttime, callback_oauthprovider AS callback, verifier_oauthprovider AS verifier FROM oauthprovider_sessions_table WHERE isaccess_oauthprovider IS NULL AND consumer_oauthprovider=? AND token_oauthprovider=?', $self->{'consumer_key'}, $param{'token'})) {
		&Log::do_log('err','Unable to load token data %s %s', $self->{'consumer_key'}, $param{'token'});
		return undef;
	}
    
	my $data = $sth->fetchrow_hashref('NAME_lc');
	return undef unless($data);
	
	my $timeout = $self->{'constants'}{(defined($param{'timeout_type'}) ? $param{'timeout_type'} : 'temporary').'_timeout'};
	return undef unless($data->{'lasttime'} + $timeout >= time);
	
	return $data;
}

=pod 

=head2 sub generateVerifier

Create the verifier for a temporary token

=head3 Arguments 

=over 

=item * I<$self>, the OAuthProvider object.

=item * I<$token>, the token.

=item * I<$user>, the user.

=back 

=head3 Return 

=over 

=item * I<string> redirect url

=item * I<undef>, if token does not exist or is not valid anymore

=back 

=head3 Calls 

=over 

=item * None

=back 

=cut 

## Create the verifier for a temporary token
sub generateVerifier {
	my $self = shift;
	my %param = @_;
	&Log::do_log('debug2', 'OAuthProvider::generateVerifier(%s, %s, %s, %s)', $param{'token'}, $param{'user'}, $param{'granted'}, $self->{'consumer_key'});
	
	return undef unless(my $tmp = $self->getTemporary(token => $param{'token'}));
	
	my $verifier = &_generateRandomString(32);
	
	unless(&SDM::do_query(
		'DELETE FROM oauthprovider_sessions_table WHERE user_oauthprovider=%s AND consumer_oauthprovider=%s AND isaccess_oauthprovider=1',
		&SDM::quote($param{'user'}),
		&SDM::quote($self->{'consumer_key'})
	)) {
		&Log::do_log('err', 'Unable to delete other already granted access tokens for this user %s %s in database', &SDM::quote($param{'user'}), $self->{'consumer_key'});
		return undef;
	}
	
	unless(&SDM::do_query(
		'UPDATE oauthprovider_sessions_table SET verifier_oauthprovider=%s, user_oauthprovider=%s, accessgranted_oauthprovider=%d, lasttime_oauthprovider=%d WHERE isaccess_oauthprovider IS NULL AND consumer_oauthprovider=%s AND token_oauthprovider=%s',
		&SDM::quote($verifier),
		&SDM::quote($param{'user'}),
		$param{'granted'} ? 1 : 0,
		time,
		&SDM::quote($self->{'consumer_key'}),
		&SDM::quote($param{'token'})
	)) {
		&Log::do_log('err', 'Unable to set token verifier %s %s in database', $tmp->{'token'}, $self->{'consumer_key'});
		return undef;
	}
	
	my $r = $tmp->{'callback'};
	$r .= ($r =~ /^[^\?]\?/) ? '&' : '?';
	$r .= 'oauth_token='.uri_escape($tmp->{'token'});
	$r .= '&oauth_verifier='.uri_escape($verifier);
	
	return $r;
}

=pod 

=head2 sub generateAccess

Create an access token

=head3 Arguments 

=over 

=item * I<$self>, the OAuthProvider object.

=item * I<$token>, the temporary token.

=item * I<$verifier>, the verifier.

=back 

=head3 Return 

=over 

=item * I<string> response body

=item * I<undef>, if temporary token does not exist or is not valid anymore

=back 

=head3 Calls 

=over 

=item * None

=back 

=cut 

## Create an access token
sub generateAccess {
	my $self = shift;
	my %param = @_;
	&Log::do_log('debug2', 'OAuthProvider::generateAccess(%s, %s, %s)', $param{'token'}, $param{'verifier'}, $self->{'consumer_key'});
	
	return undef unless(my $tmp = $self->getTemporary(token => $param{'token'}, timeout_type => 'verifier'));
	return undef unless($param{'verifier'} eq $tmp->{'verifier'});
	
	my $token = &_generateRandomString(32);
	my $secret = &_generateRandomString(32);
	
	unless(&SDM::do_query(
		'UPDATE oauthprovider_sessions_table SET token_oauthprovider=%s, secret_oauthprovider=%s, isaccess_oauthprovider=1, lasttime_oauthprovider=%d, verifier_oauthprovider=NULL, callback_oauthprovider=NULL WHERE token_oauthprovider=%s AND verifier_oauthprovider=%s',
		&SDM::quote($token),
		&SDM::quote($secret),
		time,
		&SDM::quote($param{'token'}),
		&SDM::quote($param{'verifier'})
	)) {
		&Log::do_log('err', 'Unable to transform temporary token into access token record %s %s in database', &SDM::quote($tmp->{'token'}), $self->{'consumer_key'});
		return undef;
	}
	
	my $r = 'oauth_token='.uri_escape($token);
	$r .= '&oauth_token_secret='.uri_escape($secret);
	$r .= '&oauth_expires_in='.$self->{'constants'}{'access_timeout'};
	
	return $r;
}

=pod 

=head2 sub getAccess

Retreive an access token from database.

=head3 Arguments 

=over 

=item * I<$self>, the OAuthProvider to use.

=item * I<$token>, the token key.

=back 

=head3 Return 

=over 

=item * I<a reference to a hash>, if everything's alright

=item * I<undef>, if token does not exist or is not valid anymore

=back 

=head3 Calls 

=over 

=item * None

=back 

=cut 

## Retreive an access token from database
sub getAccess {
	my $self = shift;
	my %param = @_;
	&Log::do_log('debug2', 'OAuthProvider::getAccess(%s)', $param{'token'});
	
	my $sth;
	unless($sth = &SDM::do_prepared_query(
		'SELECT token_oauthprovider AS token, secret_oauthprovider AS secret, lasttime_oauthprovider AS lasttime, user_oauthprovider AS user, accessgranted_oauthprovider AS accessgranted FROM oauthprovider_sessions_table WHERE isaccess_oauthprovider=1 AND consumer_oauthprovider=? AND token_oauthprovider=?', $self->{'consumer_key'}, $param{'token'})) {
		&Log::do_log('err','Unable to load token data %s %s', $self->{'consumer_key'}, $param{'token'});
		return undef;
    }
    
	my $data = $sth->fetchrow_hashref('NAME_lc');
	return undef unless($data);
	
	return undef unless($data->{'lasttime'} + $self->{'constants'}{'access_timeout'} >= time);
	
	return $data;
}

=pod 

=head2 sub _generateRandomString

Create a random string

=head3 Arguments 

=over 

=item * I<$size>, the string length.

=back 

=head3 Return 

=over 

=item * I<string>

=back 

=head3 Calls 

=over 

=item * None

=back 

=cut

## Generate a random string
sub _generateRandomString {
	return join('', map { (0..9, 'a'..'z', 'A'..'Z')[rand 62] } (1..shift));
}

=pod 

=head2 sub _getConsumerConfigFor

Retreive config for a consumer

Config file is like :
# comment

<consumer_key>
secret <consumer_secret>
enabled 0|1

=head3 Arguments 

=over 

=item * I<string>, the consumer key.

=back 

=head3 Return 

=over 

=item * I<string>

=back 

=head3 Calls 

=over 

=item * None

=back 

=cut

## Generate a random string
sub _getConsumerConfigFor {
	my $key = shift;
	
	&Log::do_log('debug2', 'OAuthProvider::_getConsumerConfig(%s)', $key);
	
	my $file = $Conf::Conf{'etc'}.'/oauth_provider.conf';
	return undef unless (-f $file);
	
	my $c = {};
	my $k = '';
	open(my $fh, '<', $file) or return undef;
	while(my $l = <$fh>) {
		chomp $l;
		next if($l =~ /^#/);
		next if($k eq '' && $l ne $key);
		$k = $key;
		next if($l eq $key);
		last if($l eq '');
		next unless($l =~ /\s*([^\s]+)\s+(.+)$/);
		$c->{$1} = $2;
	}
	close $fh;
	
	return $c;
}

## Packages must return true.
1;
=pod 

=head1 AUTHORS 

=over 

=item * Etienne Meleard <etienne.meleard AT renater.fr> 

=back 

=cut 
