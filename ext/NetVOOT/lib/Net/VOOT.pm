package Net::VOOT;

use warnings;
use strict;

use Log::Report 'net-voot';

use URI  ();
use JSON ();

=chapter NAME
Net::VOOT - access to a VOOT Server

=chapter SYNOPSIS

  my $voot = Net::VOOT->new(provider => 'surfnet');

=chapter DESCRIPTION
The VOOT (Virtual Organization Orthogonal Technology) protocol is a subset
of OpenSocial, used to manage group membership. The primary motivation
for VOOT is as a simple tool for managing virtual organization in RE<amp>E
federations.

One of the alternative specifications for VOOT can be found at
L<http://openvoot.org>

=chapter METHODS

=section Constructors

=c_method new OPTIONS

=requires provider NAME
Representative NAME for a VOOT server, mainly used in error and
log messages.

=requires voot_base URI
URI used as base for addressing the VOOT service.
=cut

sub new(@) { my $class = shift; (bless {}, $class)->init({@_}) }

sub init($)
{   my ($self, $args) = @_;

    my $provider = $self->{NV_provider} = $args->{provider}
        or error __x"provider needed for VOOT";

    $self->{NV_voot_base} = $args->{voot_base}
        or error __x"VOOT need base for {provider}", provider => $provider;

    $self;
}

#---------------------------
=section Attributes

=method provider
=method vootBase
=method authType
=cut

sub provider() {shift->{NV_provider}}
sub vootBase() {shift->{NV_voot_base}}
sub authType() {panic "not implemented"}

#---------------------------
=section Sessions

=method newSession OPTIONS
Create a new session, which will trigger authentication.

=method restoreSession DATA

=cut

sub newSession(%)     { panic "not implemented" }
sub restoreSession(%) { panic "not implemented" }

#---------------------------
=section Actions

=subsection Interpreted return

=method userGroups [USER]
Returns a HASH which contains information about all groups for the USER,
by default '@me'.  The HASH maps group-id's to a HASH with more info about
that group.
=cut

sub userGroups(;$)
{   my $self = shift;
    my $user = shift || '@me';
    my $r    = $self->userGroupInfo($user) or return {};
use Data::Dumper;
if(open OUT, '>/tmp/user-groups') {print OUT Dumper $r; close OUT }
    my $got  = $r->{entry} or return {};

    my %groups;
    foreach my $g (@$got)
    {   my $id = $g->{id};
        $groups{$id} =
          { name        => $g->{title}
          , id          => $id
          , description => $g->{description}
          , role        => $g->{voot_membership_role}
          };
    }
if(open OUT, '>/tmp/user-groups2') {print OUT Dumper \%groups; close OUT }
    \%groups;
}

=method groupMembership GROUP, [USER]
Returns a LIST of membership records (HASHes).
=cut

sub groupMembership($;$)
{   my $self = shift;
    my $r    = $self->groupMemberInfo(@_) or return ();
    my $got  = $r->{entry} or return ();

    my @members;
    foreach my $m (@$got)
    {   my $emails = $m->{emails} or next;
        my @emails = map {ref $_ eq 'HASH' ? $_->{value} : $_} @$emails;
        my %member =
          ( name   => $m->{displayName}
          , emails => \@emails
          , role   => $m->{voot_membership_role}
          );
        push @members, \%member;
    }

   @members;
}

=method user [USER]
=cut

sub user(;$)
{   my $self = shift;
    my $user = shift || '@me';
    my $r    = $self->userInfo($user);
    my $info = $r->{entry}[0] or return;

      +{ name  => $info->{displayName}
       , id    => $info->{id}
       , email => $info->{mail}
       };
}

#---------------------------
=subsection Raw return information

=method userGroupInfo [USER][REQPARAMS]
Returns a raw HASH of information about the groups of the USER.
M<userGroups()> is more convenient.
=cut

sub userGroupInfo(;$%)
{   my $self   = shift;
    my $user   = (@_%2 ? shift : undef) || '@me';
    my %params = @_;
    $self->query("/groups/$user", \%params);
}

=method groupMemberInfo GROUP, [USER], [REQPARAMS]
Returns a raw HASH of information about USER in GROUP.
M<groupMembership()> is more convenient.
=cut

sub groupMemberInfo($;$)
{   my $self    = shift;
    my $groupid = shift;
    my $userid  = (@_%1 ? shift: undef) || '@me';
    my %params  = @_;
    $self->query("/people/$userid/$groupid", \%params);
}

=method userInfo [USER][REQPARAMS]
Returns a raw HASH with information about the user.
=cut

sub userInfo(;$%)
{   my $self   = shift;
    my $user   = (@_%1 ? shift : undef) || '@me';
    my %params = @_;
    $self->query("/people/$user", \%params);
}

#---------------------------
=section Helpers

=method get URI
=cut

sub get($) { panic }

=method query ACTION, PARAMS
Call the VOOT server to perform ACTION.  Generic query parameters:
C<sortBy>, C<startIndex>, and C<count>.
=cut

sub query($$)
{   my ($self, $action, $params) = @_;
    my $uri = URI->new($self->vootBase.$action);
    $uri->query_form($params) if $params;

    my $resp = $self->get($uri->as_string)
        or return;

    my $data = JSON->new->decode($resp->decoded_content || $resp->content);
use Data::Dumper;
if(open OUT, '>/tmp/query') {print OUT Dumper $data; close OUT}
   $data;
}

=method hasAccess
Returns true when there is a token to use with the VOOT provider.
=cut

sub hasAccess() { panic "not implemented" }

=method getAuthorizationStarter
=cut

sub getAuthorizationStarter() {panic}

1;
