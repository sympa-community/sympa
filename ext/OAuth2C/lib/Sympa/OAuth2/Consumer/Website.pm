use warnings;
use strict;

package Sympa::OAuth2::Consumer::Website;
use base 'Sympa::OAuth2::Consumer';

our $VERSION = '0.10';

use Sympa::Plugin::Util  qw/plugin trace_call log/;

use JSON        ();
use Net::OAuth2::AccessToken ();

my @url_commands =
  ( oauth2_ready      =>
      { handler   => 'doAuthReady'
      , path_args => [ qw/voot_provider/ ]
      , required  => [ qw/code/ ]
      }
  );

my @validate =
  ( voot_provider => '.+'
  , code          => '.+'   # XXX any restrictions?
  );


=head1 NAME 

Sympa::OAuth2::Consumer - OAuth v2 Consumer

=head1 SYNOPSIS

=head1 DESCRIPTION 

Used by L<Sympa::VOOT::Consumer>

=head1 METHODS

=head2 Constructors

=head3 $obj = $class->new(OPTIONS)

=back 

=cut 

#sub init($)
#{   my ($self, $args) = @_;
#    $self;
#}

sub registerPlugin($)
{   my ($self, $args) = @_;
    push @{$args->{url_commands}}, @url_commands;
    push @{$args->{validate}}, @validate;
    $self->SUPER::registerPlugin($args);
}

=head2 Accessors

=head2 Actions

=head3 $obj->startAuth(PARAM, SESSION, CALLBACK)

=cut

sub startAuth(%)
{   my ($self, $param, $session, $come_back) = @_;

    $session->{next_page} = $come_back;
    $self->updateSession($session);

    join '/', "$param->{base_url}$param->{path_cgi}"
      , oauth2_ready => $session->{provider};
}


=head3 $obj->doAuthReady(OPTIONS)

=cut

# token and call the right action
sub doAuthReady(%)
{   my ($self, %args) = @_;
    my $in       = $args{in};
    my $param    = $args{param};

    my $prov_id  = $in->{voot_provider};

    # XXX MO: this is not OK: OAuth can be used for other things
    my $consumer = plugin('Sympa::VOOT')->consumer($param, $prov_id)
        or return;

    my $session = $consumer->session;
    $session->{access} ||= $consumer->voot->getAccessToken(code => $in->{code});

    my $callback = $session->{next_page}; # keep next_page for reload webpage
log(info => "next_page = $callback");
    $self->updateSession($session);

    main::do_redirect($callback);
}

1;
