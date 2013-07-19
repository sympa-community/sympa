package Net::VOOT::Renater;
use base 'Net::VOOT';

use warnings;
use strict;

use Sympa::Log::Syslog::Report 'net-voot';

use OAuth::Lite::Consumer ();
use OAuth::Lite::Token    ();

# default parameters for Renater servers
# XXX MO: to be filled in
my %auth_defaults;

=chapter NAME
Net::VOOT::Renater - access to a VOOT server of Renater

=chapter SYNOPSIS

  my $voot = Net::VOOT::Renater->new(auth => $auth);

=chapter DESCRIPTION
This module provides an implementation of a VOOT client in a Renater-style
VOOT setup, which may be served via Sympa.

=chapter METHODS

=section Constructors

=c_method new OPTIONS

=requires auth M<OAuth::Lite::Consumer>|HASH

=cut

sub init($)
{   my ($self, $args) = @_;
    $self->SUPER::init($args) or return;

    my $auth = $args->{auth};
    $auth    = OAuth::Lite::Consumer->new(%auth_defaults, %$auth)
        if ref $auth eq 'HASH';

    $self->{NVR_auth} = $auth
       or error __x"no configuration for authorization provided";

    $self;
}

#---------------------------
=section Attributes
=method auth
=cut

sub auth()        {shift->{NVR_auth}}
sub authType()    { 'OAuth1' }

#---------------------------
=section Actions
=cut

sub get($$$)
{   my ($self, $session, $url, $params) = @_;

    my $resp = $self->auth->request
      ( method => 'GET'
      , url    => $url
      , token  => $self->accessToken($session)
      , params => $params
      );

    return $resp
        if $resp->is_success;

    if($resp->status > 400)
    {   my $auth_header = $resp->header('WWW-Authenticate') || '';

        # access token may be expired, retry
        $self->triggerFlow if $auth_header =~ /^OAuth/;
    }

    $resp;
}

=method getAuthorizationStarter SESSION
=cut

sub getAuthorizationStarter($)
{   my ($self, $session) = @_;
    $self->auth->url_to_authorize(token => $session->requestToken);
}

=section Session

The session is managed outside the scope of this module.  However, it
is a HASH which contains a C<request> (request token) and C<access>
(access token) field.  Both may be either undefined or an
L<OAuth::Lite::Token>.

=method getRequestToken SESSION, CALLBACK
=cut

sub getRequestToken($$)
{   my ($self, $session, $callback) = @_;

    my $req_token = $self->auth->get_request_token(callback_url => $callback)
        or error __x"unable to get request token: {err}", $auth->errstr;

    $session->{request} = $req_token;
}

=method requestToken SESSION
=cut

sub requestToken($)
{   my ($self, $session) = @_;
    $session->{request};
}

=method accessToken SESSION
=cut

sub accessToken($)
{   my ($self, $session) = @_;
    $session->{access};
}

1;
