package Net::VOOT::SURFconext;
use base 'Net::VOOT';

use warnings;
use strict;

use Sympa::Log::Syslog::Report 'net-voot';

use Net::OAuth2::Profile::WebServer ();
use Scalar::Util qw/blessed/;

my $test_site = 'https://frko.surfnetlabs.nl/frkonext/';
my $live_site = 'https://api.surfconext.nl/v1';

my %providers =
 ( 'surfconext-test' =>
     { voot_base => "$test_site/php-voot-proxy/voot.php"
     , oauth2    =>
        { site              => $test_site
        , authorize_path    => 'php-oauth/authorize.php'
        , access_token_path => 'php-oauth/token.php'
        }
     }
 , surfconext        =>
     { voot_base => "$live_site/social/rest"
     , oauth2    =>
        { site              => "$live_site/oauth2/"
        , authorize_path    => 'authorize'
        , access_token_path => 'token'
        }
     }
 );

=chapter NAME

Net::VOOT::SURFconext - access to a VOOT server of SURFnet

=chapter SYNOPSIS

  my $voot = Net::VOOT::SURFconext->new(test => 1);

=chapter DESCRIPTION

"SURFconext" is a Dutch (i.e. The Netherlands) national infrastructure
(organized by SURFnet) which arranges access rights to people on
universities and research institutes (participants) to facilities offered
by other participants.  For instance, a student on one university can
use the library and WiFi of an other university when he is on visit there.

SURFconext uses OAuth2 authentication.

=chapter METHODS

=section Constructors

=c_method new OPTIONS

=requires provider 'surfconext'|'surfconext-test'

=default voot_base <depends on provider>

=option  auth M<Net::OAuth2::Profile::WebServer>|HASH
=default auth <created for you>
If you do not provide an object, you need to add some parameters to
initialize the object.  See M<createAuth()> for the OPTIONS.

=option  token M<Net::OAuth2::AccessToken>-object
=default token <requested when needed>

=cut

sub init($)
{   my ($self, $args) = @_;

    my $provid = $args->{provider} || 'surfconext';

    my $config = $providers{$provid}
        or error __x"unknown provider `{name}' for SURFconext", name => $provid;

    $args->{voot_base} ||= $config->{voot_base};

    $self->SUPER::init($args) or return;

    $self->{NVS_token}   = $args->{token};

    my $auth = $args->{auth};
    $self->{NVS_auth}    = blessed $auth ? $auth : $self->createAuth(%$auth);
    $self;
}

#---------------------------
=section Attributes

=method auth
=method authType
=method token
=cut

sub authType() { 'OAuth2' }
sub auth()     {shift->{NVS_auth}}
sub token()    {shift->{NVS_token}}
sub site()     {shift->{NVS_site}}


=method setAccessToken TOKEN
=cut

sub setAccessToken($) { $_[0]->{NVS_token} = $_[1] }

#---------------------------
=section Actions
=cut

sub get($)
{   my ($self, $uri) = @_;
    my $token = $self->token or return;
    $token->get($uri);
}

#---------------------------
=section Helpers

=method createAuth OPTIONS
Returns an M<Net::OAuth2::Profile::WebServer> object.
The C<client_id>, C<client_secret> and C<redirect_uri> are registered
at the VOOT provider: they relate to the C<site>.

=requires site          URI
=requires client_id     STRING
=requires client_secret PASSWORD
=requires redirect_uri  URI
=cut

sub createAuth(%)
{   my ($self, %args) = @_;
    my $provname = $self->provider;
    my $settings = $providers{$provname}{oauth2}
        or error __x"unknown oauth2 provider `{name}' for SURFconext"
           , name => $provname;

    my $auth = Net::OAuth2::Profile::WebServer->new
      ( client_id         => ($args{client_id}     || panic)
      , client_secret     => ($args{client_secret} || panic)
      , token_scheme      => 'auth-header:Bearer'
      , authorize_method  => 'GET'
      , redirect_uri      => ($args{redirect_uri}  || panic)
      , %$settings
      );

    trace "initialized oauth2 for voot to ".$self->provider if $auth;
    $auth;
}

=method getAccessToken OPTIONS
=requires code STRING
=cut

sub getAccessToken(%)
{   my ($self, %args) = @_;
    my $auth  = $self->auth;
    my $token = $auth->get_access_token($args{code});
    trace 'received token from '.$self->provider. ' for '.$auth->id;

    $token;
}

sub hasAccess()
{   my $token = shift->token;
    $token && !$token->expired;
}

sub getAuthorizationStarter()
{   shift->auth->authorize(scope => 'read');
}

#-------------------

=chapter DETAILS

SURFconext is a service provided by SURFnet Nederland BV (NL)

SURFconext is an authorization provider which encapsulates authorization
mechanisms of all Dutch universities (and other higher educational
institutes) and many research organisations.  SURFconext enables the
students and employees of the participants to use each other's facilities.

B<Be warned:> SURFconext uses OAuth2 which requires that your client
website uses secure HTTP: https!

=section Setting up the test server

SURFnet's test environment is currently located at
L<https://frko.surfnetlabs.nl/frkonext/>.
On that page, you can register applications, which otherwise is a task
for SURFnet's security manager.

Go to the page which demonstrates the "manage applications" feature.  Login
using the C<admin> username as listed on the front page.  Register your
application with

=over 4

=item I<identifier>
Pick a clear identifier based on the service and your organisation.  For
instance, C<sympa-uva> for organisation UvA service sympa.  You
need to pass this to C<new(client_id)>

=item I<profile>
Only profile "Web Application" is supported by this module, for now.

=item I<redirect URI>
This will bring people back to your own installation after verfication
has succeeded.

=item pick any string as I<secret>
You need to pass that as C<new(client_secret)>.  Be warned: everyone
logs-in as the same admin user, so can see your secret.

=item Set I<Allowed Scope> to "read" or "write"

=back

B<Be aware> the registrations in the test-environment are regularly and
unpredictably flushed.  Also, the location of the service may change without
notice.

=section Setting up the "live" server

See F<https://wiki.surfnetlabs.nl/display/surfconextdev/>

=cut

1;
