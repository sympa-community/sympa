use warnings;
use strict;

package Sympa::OAuth1::Consumer::Website;
use base 'Sympa::OAuth1::Consumer';

use Sympa::Plugin::Util qw/plugin/;

use Sympa::Auth;

my @url_commands =
  ( 
    oauth_ready      =>
      { handler   => 'doOAuthReady'
      , path_args => [ qw/oauth_provider ticket/ ]
      , required  => [ qw/oauth_provider ticket oauth_token oauth_verifier/]
      }
  );

my @validate =
  ( oauth_provider  => '[^:]+:.+'
  );

#sub init($)
#{   my ($self, $args) = @_;
#    $self->SUPER::init($args);
#}

sub registerPlugin($)
{   my ($self, $args) = @_;
    push @{$args->{url_commands}}, @url_commands;
    push @{$args->{validate}}, @validate;
    $self->SUPER::registerPlugin($args);
}

=head1 NAME 

Sympa::OAuth1::Consumer::Website - OAuth v1 website component

=head1 SYNOPSIS

  extends Sympa::OAuth1::Consumer
    extends Sympa::Plugin

=head1 DESCRIPTION 

This module implements OAuth1 configuration via the website.

=head1 METHODS

=head2 Constructors

=head3 $obj = $class->new(OPTIONS)

=head2 Accessors

=head2 Actions

=head3 $obj->startAuth(PARAM, SESSION, CALLBACK)

=cut

sub startAuth(%)
{   my ($self, $param, $session, $come_back) = @_;

    my $ip       = $param->{session}{remote_addr} || 'mail';
    my $ticket   = Sympa::Auth::create_one_time_ticket($session->{user}
      , $param->{session}{robot}, $come_back, $ip);

    join '/', "$param->{base_url}$param->{path_cgi}"
      , oauth_ready => $session->{provider}, $ticket;
}

=head3 $obj->doAuthReady

=cut

sub doOAuthReady(%)
{   my ($self, %args) = @_;
    my $in    = $args{in};
    my $param = $args{param};

    my $callback = main::do_ticket();

    $in->{oauth_provider}   =~ /^([^:]+):(.+)$/
        or return undef;

    my ($type, $prov_id) = ($1, $2);   # type = oauth

    # XXX MO: this is not OK: OAuth can be used for other things
    my $consumer = plugin('Sympa::VOOT')->consumer($param, $prov_id)
        or return;

    my $session = $consumer->session;
    $session->{access} = $consumer->auth->get_access_token
      ( verifier => $in->{oauth_verifier}
      , token    => $in->{oauth_token}
      );
    $session->{request} = undef;
    $self->updateSession($session);

    $callback;
}

1;
