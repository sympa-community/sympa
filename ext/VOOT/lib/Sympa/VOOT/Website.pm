package Sympa::VOOT::Website;
use base 'Sympa::VOOT';

use warnings;
use strict;

use JSON           qw/decode_json/;
use List::Util     qw/first/;

# Sympa modules
use Sympa::Plugin::Util   qw/:log reporter/;

=head1 NAME

Sympa::VOOT::Website - Website interface for VOOT on Sympa

=head1 SYNOPSIS

  extends Sympa::VOOT
    extends Sympa::Plugin

=head1 DESCRIPTION

This module handles the web interface for VOOT.

=cut


#
## register plugin
#

my @url_commands =
  ( opensocial =>
      { handler   => 'doOpenSocial'
      , path_args => 'list'
      , required  => [ qw/param.user.email param.list/ ]
      , privilege => 'owner'
      }
  , select_voot_provider_request =>
      { handler   => 'doSelectProvider'
      , path_args => 'list'
      , required  => [ qw/param.user.email param.list/ ]
      , privilege => 'owner'
      }
  , select_voot_groups_request  =>
      { handler   => 'doListVootGroups'
      , path_args => [ qw/list voot_provider/ ]
      , required  => [ qw/param.user.email param.list/ ]
      , privilege => 'owner'
      }
  , select_voot_groups =>
      { handler   => 'doAcceptVootGroup'
      , path_args => [ qw/list voot_provider/ ]
      , required  => [ qw/param.user.email param.list/ ]
      , privilege => 'owner'
      }
  );

my @validate =
  ( voot_path     => '[^<>\\\*\$\n]+'
  , voot_provider => '[\w-]+'
  );  

my @fragments =
  ( list_menu     => 'list_menu_opensocial.tt2'
  , help_editlist => 'help_editlist_voot.tt2'
  );

sub registerPlugin($)
{   my ($class, $args) = @_;
    push @{$args->{url_commands}}, @url_commands;
    push @{$args->{validate}}, @validate;
    push @{$args->{templates}}, {tt2_fragments => \@fragments};
    $class->SUPER::registerPlugin($args);
}

=head1 METHODS

=head2 Constructors

=head3 $obj = $class->new(OPTIONS)

Options:

=over 4

=item * all options from L<Sympa::VOOT> method new().

=back

=cut

sub init($)
{   my ($self, $args) = @_;
    $self->SUPER::init($args);
}

=head2 Accessors

=head2 Web interface actions

=head3 $obj->doOpenSocial

=cut

sub doOpenSocial {
    # Currently nice interface to select groups
    return 'select_voot_provider_request';
}

=head3 $obj->doSelectProvider

=cut

sub doSelectProvider(%)
{   my ($self, %args) = @_;
    my $param = $args{param};

    my @providers;
    foreach my $info ($self->providerConfigs)
    {   my $id   = $info->{'voot.ProviderID'};
        my $name = $info->{'voot.ProviderName'} || $id;
        push @providers,
          +{id => $id, name => $name, next => 'select_voot_groups_request'};
    }
    $param->{voot_providers} = [ sort {$a->{name} cmp $b->{name}} @providers ];
    return 1;
}

=head3 $obj->doListVootGroups

=cut

sub doListVootGroups(%)
{   my ($self, %args) = @_;

    my $param    = $args{param};
    my $prov_id  = $args{in}{voot_provider};

    wwslog(info => "get voot groups of $param->{user}{email} for provider $prov_id");

    my $consumer = $self->consumer($param, $prov_id);
    unless($consumer->hasAccess)
    {   my $here = "select_voot_groups_request/$param->{list}/$prov_id";
        return $self->getAccessFor($consumer, $param, $here);
    }

    $param->{voot_provider} = $consumer->provider;

    # Request groups
    my $groups   = eval { $consumer->voot->userGroups };
    if($@)
    {   $param->{error} = 'failed to get user groups';
        log(err => "failed to get user groups: $@");
        return 1;
    }

    # Keep all previously selected groups selected
    $_->{selected} = '' for values %$groups;
    if(my $list  = $args{list})
    {   foreach my $included ($list->includes('voot_group'))
        {   my $group = $groups->{$included->{group}} or next;
            $group->{selected} = 'CHECKED';
        }
    }

    # XXX: needs to become language specific sort
    $param->{voot_groups} = [sort {$a->{name} cmp $b->{name}} values %$groups]
        if $groups && keys %$groups;

    1;
}

sub getAccessFor($$$)
{   my ($self, $consumer, $param, $here) = @_;
    my $goto  = $consumer->startAuth(param => $param
      , next_page => "$param->{base_url}$param->{path_cgi}/$here"
      );
    log(info => "going for access at $goto");
    $goto ? main::do_redirect($goto) : 1;

}

=head3 $obj->doAcceptVootGroup

=cut

# VOOT groups choosen, generate config
sub doAcceptVootGroup(%)
{   my ($self, %args) = @_;
    my $param    = $args{param};
    my $in       = $args{in};
    my $robot_id = $args{robot_id};
    my $list     = $args{list};

    my $provid   = $param->{voot_provider} = $in->{voot_provider};
    my $email    = $param->{user}{email};

    # Get all the voot_groups fields from the form
    my @groupids;
    foreach my $k (keys %$in)
    {   $k =~ /^voot_groups\[([^\]]+)\]$/ or next;
        push @groupids, $1 if $in->{$k}==1;
    }
    $param->{voot_groups} = \@groupids;

    # Keep all groups from other providers
    my %groups   = map +($_->{name} => $_)
       , grep $_->{provider} ne $provid
          , $list->includes('voot_group');

    # Add the groups from this provider
    foreach my $gid (@groupids)
    {   my $name = $provid.'::'.$gid;
        $groups{$name} =
         +{ name     => $name
          , user     => $email
          , provider => $provid
          , group    => $gid
          };
    }

    $list->defaults(include_voot_group => undef); # No save otherwise ...
    $list->includes(voot_group => [values %groups]);

    my $action = $param->{action};
    unless($list->save_config($email))
    {   reporter->rejectToWeb('intern', 'cannot_save_config', {}
          , $action, $list, $email, $robot_id);

        wwslog(info => 'cannot save config file');
        web_db_log({status => 'error', error_type => 'internal'});
        return undef;
    }    

    if($list->on_the_fly_sync_include(use_ttl => 0))
    {   reporter->noticeToWeb('subscribers_updated', {}, $action);
    }
    else
    {   reporter->rejectToWeb('intern', 'sync_include_failed'
           , {}, $action, $list, $email, $robot_id);
    }

    'review';   # show current members
}
