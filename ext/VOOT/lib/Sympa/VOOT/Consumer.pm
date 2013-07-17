package Sympa::VOOT::Consumer;

use warnings;
use strict;

use Sympa::Plugin::Util qw/:log plugin/;

=head1 NAME

Sympa::VOOT::Consumer - represent one VOOT source in Sympa

=head1 SYNOPSIS

  my $voot = Sympa::VOOT->new;

  my $consumer = $voot->consumer
    ( provider => \%info
    , user     => \%user
    , auth     => \%config
    );
  # $consumer is a Sympa::VOOT::Consumer

=head1 DESCRIPTION

This object combines three aspects, to organize a voor session for a single
user:

=over 4

=item * a session set-up and administration, implemented by L<Sympa::OAuth1::Consumer> and L<Sympa::OAuth2::Consumer>

=item * the VOOT interrogation protocol, implemented by various L<Net::VOOT> extensions.

=item * some Sympa specific flow logic, in here

=back

=head1 METHODS

=head2 Constructors

=head3 $class->new(OPTIONS)

Options:

=over 4

=item * provider =E<gt> INFO

=item * user =E<gt> HASH

=item * auth =E<gt> HASH, configuration

=back

=cut

sub new(%) { my ($class, %args) = @_; (bless {}, $class)->init(\%args) }

sub init($)
{   my ($self, $args) = @_;
    my $provider = $self->{SVP_provider} = $args->{provider};
    my $user     = $self->{SVP_user} = $args->{user};
    my $provid   = $provider->{id};

    my $server   = $provider->{server};
    eval "require $server"
        or fatal "cannot load voot server class $server for $provid: $@";

    # the Net::VOOT::* modules are Sympa independent
    my $voot = $self->{SVP_voot} = $server->new
      ( provider     => $provider->{id}
      , auth         => $args->{auth}
      );

    # the Sympa::OAuth*::Consumer is 'Sympa'-aware
    my $auth_class = 'Sympa::'.$voot->authType.'::Consumer';
    my $auth       = $self->{SVP_auth} = plugin($auth_class)
        or fatal "plugin $auth_class is not loaded, required for $provid";

    # the session is the activity of the user, it may not yet exist
    my $session    = $self->{SVP_session} 
       = $auth->loadSession($voot, $user->{email}, $provid);

    $self;
}


=head2 Accessors

=head3 $obj->provider

=head3 $obj->voot

=head3 $obj->session

=head3 $obj->auth

=head3 $obj->user

=cut

sub provider() {shift->{SVP_provider}}
sub voot()     {shift->{SVP_voot}}
sub session()  {shift->{SVP_session}}
sub auth()     {shift->{SVP_auth}}
sub user()     {shift->{SVP_user}}


=head2 Action

=head3 $self->get(URL, PARAMS)

Returns the L<HTTP::Response> on success.

=cut

sub get($$)
{   my ($self, $url, $params) = @_;
    my $resp = $self->voot->get($self->session, $url, $params);
    $resp->is_success ? $resp : undef;
}


=head3 $self->startAuth(OPTIONS)

=over 4

=item * param =E<gt> HASH

It is a pity that the global paramers have to entry this module: the
authorization component needs access to the url.

=item * next_page =E<gt> URL

=back

=cut

sub startAuth(%)
{   my ($self, %args) = @_;
    trace_call($self->user->{email}, $self->provider->{id}, %args);

    my $voot    = $self->voot;
    my $session = $self->auth->createSession
      ( user      => $self->user
      , provider  => $self->provider
      , voot      => $voot
      );

    my $callback = $self->auth
        ->startAuth($args{param}, $session, $args{next_page});

    # $callback is the right one for $oauth1 ?
    $voot->getAuthorizationStarter($session);
}

=head3 $self->hasAccess

Returns true when the consumer has access to the VOOT resource.

=cut

sub hasAccess() { shift->voot->hasAccess }

1;
