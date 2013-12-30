use warnings;
use strict;

###### This code is not ready!

package Sympa::OAuth1P;
use base 'Sympa::Plugin';

our $VERSION = '0.10';

use Sympa::OAuth1::Provider;

my @url_commands =
  ( oauth_temporary  =>
      { handler   => 'doOAuthTemporary'
      }
  , oauth_authorize  =>
      { handler   => 'doOAuthAuthorize'
      , required  => [ qw/param.user.email oauth_token/ ]
      }
  , oauth_access     =>
      { handler   => 'doOauthAccess'
      }
  , voot =>
      { handler   => 'doVoot'
      , path_args => '@voot_path'
      }

  );

my @validate =
  ( oauth_authorize_ok => '.+'
  , oauth_authorize_no => '.+'
  , oauth_signature    => '[a-zA-Z0-9\+\/\=\%]+'
  , oauth_callback     => '[^\\\$\*\"\'\`\^\|\<\>\n]+'
  );

sub registerPlugin($)
{   my ($class, $args) = @_;
    push @{$args->{url_commands}}, @url_commands;
    push @{$args->{validate}}, @validate;
    $class->SUPER::registerPlugin($args);
}

#### Using HTTP_AUTHORIZATION header requires httpd config customization :
# <Location /sympa>
#   RewriteEngine on
#   RewriteBase /sympa/
#   RewriteCond %{HTTP:Authorization} (.+)
#   RewriteRule ^ - [e=HTTP_AUTHORIZATION:%1,L]
#   SetHandler fcgid-script
# </Location>

# Consumer requests a temporary token
sub doOAuthTemporary(%)
{   my ($self, %args) = @_;

    my $param = $args{param};
    my $in    = $args{in};

    $param->{bypass} = 'extreme';

    my $provider = $self->createProvider('oauth_temporary', $param, $in, 0)
        or return 1;

    print $provider->generateTemporary;
    1;
}

# User needs to authorize access
sub doOAuthAuthorize(%)
{   my ($self, %args) = @_;
    my $in      = $args{in};
    my $param   = $args{param};
    my $session = $args{session};

    my $token   = $param->{oauth_token} = $in->{oauth_token};
    my $oauth1  = 'Sympa::OAuth1P::Provider';

    my $key     = $param->{consumer_key} = $oauth1->consumerFromToken($token)
        or return undef;

    $param->{consumer_key} = $key;

    my $verifier = $session->{oauth_authorize_verifier};
    my $in_verif = $in->{oauth_authorize_verifier} || '';
    if(!$verifier || $verifier ne $in_verif)
    {   $session->{oauth_authorize_verifier}
          = $param->{oauth_authorize_verifier}
          = $oauth1->generateRandomString(32);
        return 1;
    }

    delete $session->{oauth_authorize_verifier};

    my $provider = $oauth1->new
      ( method => $ENV{REQUEST_METHOD}
      , request_parameters =>
         +{ oauth_token        => $token
          , oauth_consumer_key => $key
          }
      ) or return;


    my $access_granted = defined $in->{oauth_authorize_ok}
                     && !defined $in->{oauth_authorize_no};

    my $r = $provider->generateVerifier
      ( token   => $token
      , user    => $param->{user}{email}
      , granted => $access_granted
      ) or return;

    main::do_redirect($r);
    1;
}

# Consumer requests an access token
sub doOauthAccess(%)
{   my ($self, %args) = @_;
    my $param        = $args{param};
    $param->{bypass} = 'extreme';

    my $provider = $self->createProvider('oauth_access', $param, $args{in}, 1)
        or return 1;

    print $provider->generateAccess;
    return 1;
}

# VOOT request
sub doVoot(%)
{   my ($self, %args) = @_;

    my $param = $args{param};
    my $in    = $args{in};

    $param->{bypass} = 'extreme';
    
    my $voot_path = $in->{voot_path};

my $prov_id;
    my $consumer  = $self->consumer($param, $prov_id);

    $consumer->get
      ( method    => $ENV{REQUEST_METHOD}
      , voot_path => $voot_path
      , url       => "$param->{base_url}$param->{path_cgi}/voot/$voot_path"
      , authorization_header => $ENV{HTTP_AUTHORIZATION}
      , request_parameters   => $in
      , robot     => $args{robot_id}
      );
    
    my ($http_code, $http_str)
       = $consumer ? $consumer->checkRequest : (400, 'Bad Request');
    
    my $r      = $consumer->response;
    my $err    = $consumer->{error};
    my $status = $err || "$http_code $http_str";
    
    print <<__HEADER;
Status: $status
Cache-control: no-cache
Content-type: text/plain
__HEADER

    print $r unless $err;
    return 1;
}

sub createProvider($$$$)
{   my ($thing, $for, $param, $in, $check) = @_;

    my $provider = Sympa::OAuth1P::Provider->new
      ( method               => $ENV{REQUEST_METHOD}
      , url                  => "$param->{base_url}$param->{path_cgi}/$for"
      , authorization_header => $ENV{HTTP_AUTHORIZATION}
      , request_parameters   => $in
      );

    my $bad = $provider ? $provider->checkRequest(checktoken => $check) : 400;
    my $http_code = $bad || 200;
    my $http_str  = !$bad ? 'OK'
                  : $provider ? $provider->{util}->errstr
                  : 'Bad Request';

    print <<__HEADER;
Status: $http_code $http_str
Cache-control: no-cache
Content-type: text/plain

__HEADER

    $bad ? undef : $provider;
}

1;
