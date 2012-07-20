# VOOTConsumer.pm - This module implements VOOT consumer facilities
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

I<VOOTConsumer.pm> - VOOT consumer facilities for internal use in Sympa

=head1 DESCRIPTION 

This package provides abstraction for the VOOT workflow (client side),
handles OAuth workflow if nedeed.

=cut 

package VOOTConsumer;

use strict;

use OAuthConsumer;

use JSON::XS;
use Data::Dumper;

#use List;
use tools;
#use tt2;
use Conf;
use Log;

=pod 

=head1 SUBFUNCTIONS 

This is the description of the subfunctions contained by VOOTConsumer.pm

=cut 


=pod 

=head2 sub new

Creates a new VOOTConsumer object.

=head3 Arguments 

=over 

=item * I<$user>, a user email

=item * I<$provider>, the VOOT provider key

=back 

=head3 Return 

=over 

=item * I<a VOOTConsumer object>, if created

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
	
	my $consumer;
	&Log::do_log('debug2', 'VOOTConsumer::new(%s, %s)', $param{'user'}, $param{'provider'});
	
	# Get oauth consumer and enpoints from provider_id
	$consumer->{'conf'} = &_get_config_for($param{'provider'});
	return undef unless(defined $consumer->{'conf'});
	
	$consumer->{'user'} = $param{'user'};
	$consumer->{'provider'} = $param{'provider'};
	
	$consumer->{'oauth_consumer'} = new OAuthConsumer(
		user => $param{'user'},
		provider => 'voot:'.$param{'provider'},
		consumer_key => $consumer->{'conf'}{'oauth.ConsumerKey'},
		consumer_secret => $consumer->{'conf'}{'oauth.ConsumerSecret'},
		request_token_path => $consumer->{'conf'}{'oauth.RequestURL'},
        access_token_path  => $consumer->{'conf'}{'oauth.AccessURL'},
        authorize_path => $consumer->{'conf'}{'oauth.AuthorizationURL'},
        here_path => $consumer->{'here_path'}
	);
	
	return bless $consumer, $pkg;
}

sub getOAuthConsumer {
	my $self = shift;
	return $self->{'oauth_consumer'};
}

=pod 

=head2 sub isMemberOf

Get user groups

=head3 Arguments 

=over 

=item * None

=back 

=head3 Return 

=over 

=item * I<a reference to a hash> contains groups definitions

=item * I<undef>, if something went wrong

=back 

=head3 Calls 

=over 

=item * None

=back 

=cut 

## Get groups for user
sub isMemberOf {
	my $self = shift;
	&Log::do_log('debug2', 'VOOTConsumer::isMemberOf(%s, %s)', $self->{'user'}, $self->{'provider'});
	
	my $data = $self->{'oauth_consumer'}->fetchRessource(url => $self->{'conf'}{'voot.BaseURL'}.'/groups/@me');
	return undef unless(defined $data);
	
	$data = _decode_json($data);
	return [] unless(defined $data);
	return &_get_groups($data);
}
sub check {
	my $self = shift;
	return $self->isMemberOf();
}

=pod 

=head2 sub getGroupMembers

Get members of a group.

=head3 Arguments 

=over 

=item * I<$self>, the OAuthConsumer to use.

=item * I<$group>, the group ID.

=back 

=head3 Return 

=over 

=item * I<a reference to a hash> contains members definitions

=item * I<undef>, if something went wrong

=back 

=head3 Calls 

=over 

=item * None

=back 

=cut 

## Get group members
sub getGroupMembers {
	my $self = shift;
	my %param = @_;
	&Log::do_log('debug2', 'VOOTConsumer::getGroupMembers(%s, %s, %s)', $self->{'user'}, $self->{'provider'}, $param{'group'});
	
	my $data = $self->{'oauth_consumer'}->fetchRessource(url => $self->{'conf'}{'voot.BaseURL'}.'/people/@me/'.$param{'group'});
	return undef unless(defined $data);
	
	$data = _decode_json($data);
	return [] unless(defined $data);
	return &_get_members($data);
}

=pod 

=head2 sub _get_groups

Fetch groups from response items.

=head3 Arguments 

=over 

=item * I<$data>, the parsed request response.

=back 

=head3 Return 

=over 

=item * I<a reference to a hash>, if everything's alright

=back 

=head3 Calls 

=over 

=item * None

=back 

=cut 

## Fetch groups from response items
sub _get_groups {
	my $data = shift;
	my $groups = {};
	
	foreach my $grp (@{$data->{'entry'}}) {
		$groups->{$grp->{'id'}} = {
			name => $grp->{'name'} || $grp->{'id'},
			description => (defined $grp->{'description'}) ? $grp->{'description'} : '',
			voot_membership_role => (defined $grp->{'voot_membership_role'}) ? $grp->{'voot_membership_role'} : undef
		};
	}
	
	return $groups;
}

=pod 

=head2 sub _get_members

Fetch members from response items.

=head3 Arguments 

=over 

=item * I<$data>, the parsed request response.

=back 

=head3 Return 

=over 

=item * I<a reference to an array>, if everything's alright

=back 

=head3 Calls 

=over 

=item * None

=back 

=cut 

## Fetch members from response items
sub _get_members {
	my $data = shift;
	my $members = [];
	my $i;
	
	foreach my $mmb (@{$data->{'entry'}}) {
		next unless(defined $mmb->{'emails'}); # Skip members without email data that are useless for Sympa
		my $member = {
			displayName => $mmb->{'displayName'},
			emails => [],
			voot_membership_role => (defined $mmb->{'voot_membership_role'}) ? $mmb->{'voot_membership_role'} : undef
		};
		foreach my $email (@{$mmb->{'emails'}}) {
			if(ref($email) eq 'HASH') {
				push(@{$member->{'emails'}}, $email->{'value'});
			}else{
				push(@{$member->{'emails'}}, $email);
			}
		}
		push(@$members, $member);
	}
	
	return $members;
}

=pod 

=head2 sub _get_config_for

Get provider information.

=head3 Arguments 

=over 

=item * I<$provider>, the provider to get info about.

=back 

=head3 Return 

=over 

=item * I<a reference to a hash>, if everything's alright

=back 

=head3 Calls 

=over 

=item * None

=back 

=cut 

## Get provider information
sub _get_config_for {
	my $provider = shift;
	&Log::do_log('debug2', 'VOOTConsumer::_get_config_for(%s)', $provider);
	
	my $file = $Conf::Conf{'etc'}.'/voot.conf';
	return undef unless (-f $file);
	
	open(my $fh, '<', $file) or return undef;
	my @ctn = <$fh>;
	chomp @ctn;
	close $fh;
	
	my $conf = _decode_json(join('', @ctn)); # Returns array ref
	return {} unless(defined $conf);
	foreach my $item (@$conf) {
		next unless($item->{'voot.ProviderID'} eq $provider);
		return $item;
	}
	
	return undef;
}


=pod 

=head2 sub getProviders

List providers.

=head3 Arguments 

=over 

=item * None.

=back 

=head3 Return 

=over 

=item * I<a reference to a hash>, if everything's alright

=back 

=head3 Calls 

=over 

=item * None

=back 

=cut 

## List providers
sub getProviders {
	&Log::do_log('debug2', 'VOOTConsumer::getProviders()');
	
	my $list = {};
	
	my $file = $Conf::Conf{'etc'}.'/voot.conf';
	return $list unless (-f $file);
	
	open(my $fh, '<', $file) or return $list;
	my @ctn = <$fh>;
	chomp @ctn;
	close $fh;
	
	my $conf = _decode_json(join('', @ctn)); # Returns array ref
	return {} unless(defined $conf);
	foreach my $item (@$conf) {
		$list->{$item->{'voot.ProviderID'}} = $item->{'voot.ProviderID'};
	}
	
	return $list;
}

=pod 

=head2 sub _decode_json

Decode a response in JSON format, handling dies, croak and the likes in submodule

=head3 Arguments 

=over 

=item * I<$v>, the JSON as a string.

=back 

=head3 Return 

=over 

=item * I<string> ref

=item * I<undef>, if something went wrong

=back 

=head3 Calls 

=over 

=item * None

=back 

=cut 

sub _decode_json {
	my $v;
	eval { $v = decode_json(shift) };
	return undef if($@);
	return $v;
}

## Packages must return true.
1;
=pod 

=head1 AUTHORS 

=over 

=item * Etienne Meleard <etienne.meleard AT renater.fr> 

=back 

=cut 
