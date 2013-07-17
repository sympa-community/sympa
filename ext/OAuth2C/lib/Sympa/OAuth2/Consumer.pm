use warnings;
use strict;

package Sympa::OAuth2::Consumer;
use base 'Sympa::Plugin';

our $VERSION = '0.10';

use Sympa::Plugin::Util  qw/trace_call log/;

use JSON        ();
use Net::OAuth2::AccessToken ();

=head1 NAME 

Sympa::OAuth2::Consumer - OAuth v2 Consumer

=head1 SYNOPSIS

=head1 DESCRIPTION 

Used by L<Sympa::VOOT::Consumer>

=head1 METHODS

=head2 Constructors

=head3 $obj = $class->new(OPTIONS)

=cut 

sub init($)
{   my ($self, $args) = @_;
    $args->{website} ||= 'Sympa::OAuth2::Consumer::Website';
    $self->SUPER::init($args);
}

#sub registerPlugin($)
#{   my ($self, $args) = @_;
#    $self->SUPER::registerPlugin($args);
#}


=head2 Accessors

=head2 Sessions

=head3 $obj->loadSession(VOOT, EMAIL, PROV_ID)

=cut

sub loadSession($$$)
{   my ($self, $voot, $email, $prov_id) = @_;
    trace_call($email, $prov_id);

    my $sth  = $self->db->prepared(<<'__LOAD_SESSION', $email, $prov_id);
SELECT session
  FROM oauth2_sessions
 WHERE user     = ?
   AND provider = ?
__LOAD_SESSION

    unless($sth)
    {   log(err => "Unable to load token data for $email at $prov_id");
        return undef;
    }
 
    my $record = $sth->fetchrow_hashref('NAME_lc')
        or return undef;

    my $session = JSON->new->decode($record->{session})
        or return;

    if(my $access = delete $session->{access})
    {   my $access = $session->{access} = Net::OAuth2::AccessToken
          ->session_thaw($access, profile => $voot->auth);

        $voot->setAccessToken($access);
    }

    $session;
}

=head3 updateSession SESSION

=cut

sub updateSession($)
{   my ($self, $session) = @_;
    my $email  = $session->{user};
    my $provid = $session->{provider};

    my $dump;
    if(my $access = delete $session->{access})
    {   $session->{access} = $access->session_freeze;
        $dump   = JSON->new->encode($session);
        $session->{access} = $access;
    }
    else
    {   $dump   = JSON->new->encode($session);
    }

    trace_call($email, $provid, $dump);

    unless($self->db->do(<<'__UPDATE_SESSION', $dump, $email, $provid))
UPDATE oauth2_sessions
   SET session  = ?
 WHERE user     = ?
   AND provider = ?
__UPDATE_SESSION
    {   log(err => "Unable to update token record $email $provid");
        return undef;
    }

    1;
}

=head3 createSession OPTIONS

=over 4

=item * user

=item * provider

=item * next_page

=back

=cut

sub createSession(%)
{   my ($self, %args) = @_;
    my $email  = $args{user}{email};
    my $provid = $args{provider}{id};

    my %session =
      ( user      => $email
      , provider  => $provid
      );

    my $dump    = JSON->new->encode(\%session);
    trace_call($email, $provid, $dump);

    unless($self->db->do(<<'__INSERT_SESSION', $dump, $email, $provid))
REPLACE oauth2_sessions
   SET session  = ?
     , user     = ?
     , provider = ?
__INSERT_SESSION
    {   log(err => "Unable to add new token record $email $provid");
        return undef;
    }

    \%session;
}

1;
