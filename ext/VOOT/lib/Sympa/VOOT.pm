package Sympa::VOOT;
use base 'Sympa::Plugin', 'Sympa::Plugin::ListSource';

use warnings;
use strict;

our $VERSION = '0.10';

use JSON           qw/decode_json/;
use List::Util     qw/first/;

# Sympa modules
use Sympa;
use Sympa::Tools::Text;
use Sympa::Plugin::Util   qw/:log reporter/;
use Sympa::VOOT::Consumer ();

my $default_server = 'Net::VOOT::Renater';

=head1 NAME

Sympa::VOOT - manage VOOT use in Sympa

=head1 SYNOPSIS

  # extends Sympa::Plugin
  # extends Sympa::Plugin::ListSource

  my $voot = Sympa::VOOT->new(config => $filename);

=head1 DESCRIPTION

Intergrate VOOT with Sympa.  This module administers consumer objects
(L<Sympa::VOOT::Consumer>) per user session.  When in the website
environment, it will get extended by L<Sympa::VOOT::Website>.

=cut

#
## register plugin
#

# This ugly info is needed to be able to save the defined listsource
# to a file.  We need to get around it.
my %include_voot_group =
  ( group      => 'data_source'
  , gettext_id => 'VOOT group inclusion'
  , occurrence => '0-n'
  , format     =>
     [ name =>
        { gettext_id => 'short name for this source'
        , format     => '.+'
        }
     , provider => 
        { gettext_id => 'provider'
        , format     => '\S+'
        }
     , user =>
        { gettext_id => 'user'
        , format     => '\S+'
        }
     , group =>
        { gettext_id => 'group'
        , format     => '\S+'
        }
     ]
  );

=head1 METHODS

=head2 Constructors

=head3 $obj = $class->new(OPTIONS)

Options:

=over 4

=item * config =E<gt> FILENAME|HASH, voot configuration file (default voot.conf)

=back

=cut

sub init($)
{   my ($self, $args) = @_;
    $args->{website}     ||= 'Sympa::VOOT::Website';
    $self->SUPER::init($args);

    my $config = $args->{config} || Sympa::search_fullpath('*', 'voot.conf');

    if(ref $config eq 'HASH')
    {   $self->{SV_config}    = $config;
        $self->{SV_config_fn} = 'HASH';
    }
    else
    {   $self->{SV_config}    = $self->readConfig($config);
        $self->{SV_config_fn} = $config;
    }

    $self->Sympa::Plugin::ListSource::init( { name => 'voot_group' });
    $self;
}

sub registerPlugin($)
{   my ($class, $args) = @_;
    push @{$args->{listdef}}, include_voot_group => \%include_voot_group;

    (my $templ_dir = __FILE__) =~ s,\.pm$,/tt2,;
    push @{$args->{templates}}, {tt2_path => $templ_dir };

    $class->SUPER::registerPlugin($args);
}

=head2 Accessors

=head3 $obj->config

=head3 $obj->configFilename

=cut

sub config() { shift->{SV_config} }
sub configFilename() { shift->{SV_config_fn} }

sub listSource() {shift}     # I do it myself

=head2 Configuration handling

=head3 $thing->readConfig(FILENAME)

=cut

sub readConfig($)
{   my ($thing, $filename) = @_;
    local *IN;

    open IN, '<:encoding(utf8)', $filename
        or fatal "cannot read VOOT config from $filename";

    local $/;
    my $config = eval { decode_json <IN> };
    $@ and fatal "parse errors in VOOT config $filename: $@";

    close IN
        or fatal "read errors in VOOT config $filename: $@";

    $config;
}

=head3 $obj->consumer(PARAM, ID|NAME, OPTIONS)

Returns the object which handles the selected provider, an extension
of L<Net::VOOT>.

The OPTIONS are passed to the L<Sympa::VOOT::Consumer> constructor.
=cut

sub consumer($$@)
{   my ($self, $param, $ref, @args) = @_;

    my $fn   = $self->configFilename;
    my $info = first {   $_->{'voot.ProviderID'}   eq $ref
                      || $_->{'voot.ProviderName'} eq $ref
                     } $self->providerConfigs;

    $info
        or fatal "cannot find VOOT provider $ref in $fn";

    my $prov_id  = $info->{'voot.ProviderID'};
    my %provider = 
       ( id     => $prov_id
       , name   => $info->{'voot.ProviderName'}
       , server => ($info->{'voot.ServerClass'} || $default_server)
       );

    # old style (6.2-devel): flat list on top-level
    my $auth1 = $info->{oauth1};
    /^x?oauth\.(.*)/ && ($auth1->{$1} = $info->{$_})
         for keys %$info;

    my $auth = $auth1 && keys %$auth1 ? $auth1 : $info->{oauth2};

    # 20130409 MO: ugly, only used for oauth2 right now.
    # Needed because of a bug in current SURFconext implementation.  See
    # remark in https://wiki.surfnetlabs.nl/display/surfconextdev/API
    $auth->{redirect_uri} ||=
       "$param->{base_url}$param->{path_cgi}/oauth2_ready/$prov_id";

    # Sometimes, we only have an email address of the user
    my $user     = $param->{user};
    ref $user eq 'HASH' or $user = { email => $user };

    my $consumer = eval {
        Sympa::VOOT::Consumer->new
          ( provider => \%provider
          , auth     => $auth
          , user     => $user
          , @args
          )};

    $consumer
        or fatal "cannot start VOOT consumer to $ref: $@";

    $consumer;
}

=head3 $obj->providerConfigs

=head3 $obj->providers

=cut

sub providerConfigs() { @{shift->config} }

sub providers()
{   map +($_->{'voot.ProviderName'} || $_->{'voot.ProviderID'})
      , shift->providerConfigs;
}


=head2 The Sympa::Plugin::ListSource interface

See L<Sympa::Plugin::ListSource> for more details about the provided methods.

=head3 $obj->listSourceName

=cut


sub listSourceName() { 'voot_group' }

=head3 $obj->getListMembers(OPTIONS)

=cut

sub getListMembers(%)
{   my ($self, %args) = @_;

    my $admin_only = $args{admin_only} || 0;
    my $settings   = $args{settings};
    my $defaults   = $args{user_defaults};
    my $tied       = $args{keep_tied};
    my $users      = $args{users};

    my $email      = $settings->{user};
    my $provid     = $settings->{provider};
    my $groupid    = $settings->{group};
    my $sourceid   = $self->getSourceId($settings);
    trace_call($email, $provid, $groupid);

    my $consumer   = $self->consumer($settings, $provid);

    my @members    = eval { $consumer->voot->groupMembership($groupid) };
    if($@)
    {   log(err => "Unable to get group members for $email in $groupid at $provid: $@");
        return undef;
    }
    
    my $new_members = 0;
  MEMBER:
    foreach my $member (@members)
    {   # A VOOT user may define more than one email address, but we take
        # only the first, hopely the preferred.
        my $mem_email = $member->{emails}[0]
            or next MEMBER;

	unless (Sympa::Tools::Text::valid_email($mem_email))
        {   log(err => "skip malformed address '$mem_email' in $groupid");
            next MEMBER;
        }

        next MEMBER
            if $admin_only && $member->{role} !~ /admin/;

        # Check if user has already been included
	my %info;
        if(my $old = $users->{$mem_email})
        {   %info = ref $old eq 'HASH' ? %$old : split("\n", $old);
            defined $defaults->{$_} && ($info{$_} = $defaults->{$_})
                for qw/visibility reception profile info/;
	}
        else
        {   %info = %$defaults;
            $new_members++;
	}

        $info{email} = $mem_email;
        $info{gecos} = $member->{name};
        $info{id}   .= ($info{id} ? ',' : '') . $sourceid;

	$users->{$mem_email} = $tied ? join("\n", %info) : \%info;
    }

    log(info => "included $new_members new users from VOOT group"
      . "$groupid at provider $provid");

    $new_members;
}

=head3 $obj->reportListError(LIST, PROVID)

=cut

sub reportListError($$)
{   my ($self, $list, $provid) = @_;

    my $conf = first {$_->{name} eq $provid} $list->includes('voot_group');
    $conf or return;

    reporter->rejectToWeb
      ( user => 'sync_include_voot_failed.tt2', $conf
      , 'sync_include', $list->{'domain'}, $conf->{user}, $list->{'name'}
      );

    reporter->rejectPerEmail
      ( plugin => 'message_report_voot_failed.tt2', $conf->{user}
      , $conf, $list
      );

    1;
}

1;

__END__

=head1 DETAILS

The VOOT protocol is a subset of OpenSocial, used to share information
about users and groups of users between organisations.  You may find
more information at L<http://www.openvoot.org>.

=head2 Using VOOT

To be able to use VOOT with Sympa, you need to

=over 4

=item * install the plugins,

=item * create a configuration file F<voot.conf>, and

=item * configure to use some VOOT group for a mailinglist.

=back

=head2 Using a VOOT group

Go, as administrator of a mailinglist first to the OpenSocial menu-entry at
the left.  If you do not see that "OpenSocial" entry, the software is not
installed (correctly).  Search the logs for errors while loading the
plugins.

Then pick a provider provider in the OpenSocial interface, and then the
groups to associate the specific list with.

=head2 Setting-up VOOT

There are few VOOT server implementations.  Read more about how
to use them with Sympa in their specific man-pages:

=over 4

=item * L<Sympa::VOOT::SURFconext>, SURFnet NL using OAuth2

=item * L<Sympa::VOOT::Renater>, Renater FR using OAuth (v1)

=back

=head2 Description of the VOOT file

By default, the VOOT configuration is found in the Site's etc directory,
with name 'voot.conf'.  This is a JSON file which contains an ARRAY of
provider descriptions.

The OAuth and OAuth2 standards which are used, are weak standards: they
are extremely flexible.  You may need to configure a lot yourself to get
it to work.  This means that you have to provider loads of details about
your VOOT server.

Fields:

   voot.ProviderID     your abbreviation
   voot.ProviderName   beautified name (defaults to ID)
   voot.ServerClass    implementation (defaults to Net::VOOT::Renater)
   oauth  => HASH      parameters to Sympa::OAuth1::new()
   oauth2 => HASH      parameters to Sympa::OAuth2::new()

=cut
