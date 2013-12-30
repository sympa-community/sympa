use warnings;
use strict;

##### THERE IS STILL WORK TO DO HERE!  IT WILL NOT WORK NOW

package Sympa::OAuth1::Consumer;
use base 'Sympa::Plugin';

use Sympa::Plugin::Util qw/log/;

use OAuth::Lite::Token  ();

our $VERSION = '0.10';

=head1 NAME 

Sympa::OAuth1::Consumer - OAuth v1 administration

=head1 SYNOPSIS

=head1 DESCRIPTION 

This module implements OAuth1 session handling, including the token
administration.

=head1 METHODS

=head2 Constructors

=head3 $obj = $class->new(OPTIONS)

Create the object, returns C<undef> on failure.

Options:

=over 4

=item * auth =E<gt> L<OAuth::Lite::Consumer>

=back 

=cut 

sub init($)
{   my ($self, $args) = @_;
    $args->{website} ||= 'Sympa::OAuth1::Consumer::Website';
    $self->SUPER::init($args);
}

#sub registerPlugin($)
#{   my ($self, $args) = @_;
#    $self->SUPER::registerPlugin($args);
#}

=head2 Accessors

=head2 Sessions

=head3 $obj->loadSession(EMAIL, PROVIDER)

=cut

sub loadSession($$)
{   my ($self, $email, $prov_id) = @_;

    my $sth  = $self->db->prepared(<<'__GET_TMP_TOKEN', $email, $prov_id);
SELECT tmp_token_oauthconsumer     AS tmp_token
     , tmp_secret_oauthconsumer    AS tmp_secret
     , access_token_oauthconsumer  AS access_token
     , access_secret_oauthconsumer AS access_secret
  FROM oauthconsumer_sessions_table
 WHERE user_oauthconsumer     = ?
   AND provider_oauthconsumer = ?
__GET_TMP_TOKEN

    unless($sth)
    {   log(err => "Unable to load token data for $email at $prov_id");
        return undef;
    }
    
    my $data = $sth->fetchrow_hashref('NAME_lc')
        or return undef;

    my %session = (user => $email, provider => $prov_id);

    $session{request} = OAuth::Lite::Token->new
      ( token  => $data->{tmp_token}
      , secret => $data->{tmp_secret}
      ) if $data->{tmp_token};

    $session{access} = OAuth::Lite::Token->new
      ( token  => $data->{access_token},
      , secret => $data->{access_secret}
      ) if $data->{access_token};

    \%session;
}

=head3 $obj->updateSession(SESSION)

=cut

sub updateSession($)
{   my ($self, $session) = @_;
    my $request = $session->{request};
    my $access  = $session->{access};
    my $user    = $session->{user};
    my $provid  = $session->{provider};

    my @bind   =
      ( $request->token, $request->secret
      , $access->token,  $access->secret
      , $user, $provid
      );

    unless($self->db->do(<<'__UPDATE_SESSION', @bind))
UPDATE oauthconsumer_sessions_table
   SET tmp_token_oauthconsumer     = ? 
     , tmp_secret_oauthconsumer    = ?
     , access_token_oauthconsumer  = ?
     , access_secret_oauthconsumer = ?
 WHERE user_oauthconsumer          = ?
   AND provider_oauthconsumer      = ?
__UPDATE_SESSION
    {   log(err => "Unable to update token record $user $provid");
        return undef;
    }

    $self
}

=head3 $session = $self->createSession(OPTIONS)

Returns a session HASH.

Options:

=over 4

=item * user

=item * provider

=item * voot

=item * callback

=back

=cut

sub createSession(%)
{   my ($self, %args) = @_;
    my $email   = $args{user}{email};
    my $provid  = $args{provider}{id};

    my $request = eval { $args{voot}->getRequestToken($args{callback}) };
    unless($request)
    {   log(err => "Unable to get request token for $email at $provid: $@");
        return undef;
    }

    my @bind   = ($email, $provid, $request->token, $request->secret);

    unless($self->db->do(<<'__INSERT_SESSION', @bind))
INSERT OR REPLACE INTO oauthconsumer_sessions_table
   SET user_oauthconsumer          = ?
     , provider_oauthconsumer      = ?
     , tmp_token_oauthconsumer     = ?
     , tmp_secret_oauthconsumer    = ?
     , access_token_oauthconsumer  = NULL
     , access_secret_oauthconsumer = NULL
__INSERT_SESSION
    {   log(err => "Unable to add new token record ($email, $provid)");
        return undef;
    }

    +{ user => $email, provider => $provid, request => $request };
}

1;
