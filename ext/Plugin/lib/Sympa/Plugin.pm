package Sympa::Plugin;
use warnings;
use strict;

use Sympa::Plugin::Util qw/:log default_db/;


=head1 NAME

Sympa::Plugin - add plugin system to Sympa

=head1 SYNOPSIS

  # in each plugin
  package Sympa::VOOT;  # example
  use parent 'Sympa::Plugin';

=head1 DESCRIPTION

In the Sympa system (version 6.2), each logic component has code fragments
and configuration scattered all over the code.  This hinders maintenance.
This module implements a few tricky hacks to move towards accepting
optional modules which can get upgraded between major Sympa releases.

=head1 METHODS

=head2 Constructors

=head3 $class->new(OPTIONS)

Options:

=over 4

=item * website =E<gt> CLASS

The CLASS to instantiate if we have a web environment.  This might be
the plugin itself or an extension of the plugin class.

=item * application =E<gt> NAME

(required) Which application do we run

=item * db =E<gt> OBJECT

Close to all plugins need the database, so let's provide it by default.

=back

=cut

sub new(@)
{   my ($class, %args) = @_;
    (bless {}, $class)->init(\%args);
}

sub init($)
{   my ($self, $args) = @_;
    $self->{SP_db} = $args->{db} || default_db;
    my $appl       = $self->{SP_appl} = $args->{application};

    if($appl eq 'website')
    {    # Upgrade the object to be able to handle websites.
        if(my $ws = $args->{website})
        {   eval "require $ws"
                or fatal "cannot load website extension $ws: $@";
            $ws->isa(ref $self)
                or fatal "class $ws does not extend ".ref $self;
            bless $self, $ws;
        }
    }

    $self->registerPlugin({});
    $self;
}


=head2 Accessors

=head3 $obj->application

=head3 $obj->db

=cut

sub application() {shift->{SP_appl}}
sub db() {shift->{SP_db}}


=head2 Plugin loader

The following code is really tricky: it tries to separate the components
from the existing interface.

=head3 $obj->registerPlugin(OPTIONS)

The OPTIONS are passed as HASH here, not as LIST.

When the application is C<website>, you get these options:

=over 4

=item * url_commands =E<gt> PAIRS

=item * validate =E<gt> PAIRS

=item * templates =E<gt> HASHES

=back

When the plugin implements listSource:

=over 4

=item * listdef =E<gt> HASHES

=back

See the source of L<Sympa::VOOT> for an extended example.

=cut

sub registerPlugin($)
{   my ($self, $args) = @_;

    $self->registerWebsite($args)
       if $self->application eq 'website';

    $self->registerListSource($args)
       if $self->can('listSource');

    $self;
}

=head3 registerWebsite

Create the web-interface compenents for this plugin.

=cut

sub registerWebsite($)
{   my ($self, $args) = @_;

use Data::Dumper;
warn ref $self, Dumper $args;

    if(my $url = $args->{url_commands})
    {   my @url = @$url;
        while(@url)
        {   my ($command, $settings) = (shift @url, shift @url);
            my $method = $settings->{handler};

            $main::comm{$command} = sub
              { log(debug2 => "plugin $command, handler $method on $self");
                $self->$method
                  ( in       => \%main::in
                  , param    => $main::param
                  , session  => $main::session
                  , list     => $main::list
                  , robot_id => $main::robot_id
                  , @_
                  );
              };

            if(my $a = $settings->{path_args})
            {   $main::action_args{$command} = ref $a ? $a : [ $a ];
            }
            if(my $r = $settings->{required})
            {   $main::required_args{$command} = ref $r ? $r : [ $r ];
            }
	    if(my $p = $settings->{privilege})
            {   # default is 'everybody'
                $main::required_privileges{$command} = ref $p ? $p : [$p];
            }
        }
    }
    if(my $val = $args->{validate})
    {   my @val = @$val;
        while(@val)
        {   my $param = shift @val;
            $main::in_regexp{$param} = shift @val;
        }
    }

    if(my $templ = $args->{templates})
    {   $main::plugins->addTemplates(%$_)
            for ref $templ ? @$templ : $templ;
    }
}

sub registerListSource($)
{   my ($self, $args) = @_;

    # Add info to ListDef.pm table.  This can be made simpler with some
    # better defaults in ListDef.pm itself.
    if(my $form = $args->{listdef})
    {   my @form = @$form;
        while(@form)
        {   my ($header, $fields) = (shift @form, shift @form);
            my $format = $fields->{format};
            if(ref $format eq 'ARRAY')
            {   # for convenience: automatically add 'order' when the
                # format is passed as ARRAY
                my %h;
                my @format = @$format;
                while(@format)
                {   my ($field, $def) = (shift @format, shift @format);
                    $def->{order} = keys(%h) + 1;
                    $h{$field}    = $def;
                }
                $format = $fields->{format} = \%h;
            }

            # for convenience, default occurence==1
            $_->{occurrence} ||= 1 for values %$format;

            Sympa::ListDef::cleanup($header, $fields);
            $Sympa::ListDef::pinfo{$header} = $fields;
            $fields->{order} = @Sympa::ListDef::param_order;  # to late for init
            push @Sympa::ListDef::param_order, $header;
        }
    }

    List->registerPlugin($self);
}


=head3 $class->upgrade(OPTIONS)

Upgrade the information in the system.  Returned is the next version
for that information: you can better not make more than one step at
the time for the upgrade: we would like to update the plugin status
inbetween these steps.

=over 4

=item * from_version =E<gt> VERSION

=back

=cut

sub upgrade(%)
{   my ($class, %args) = @_;
    my $from = $args{from_version};

    my $upgrade_class = $class.'::Upgrade';
    eval "require $upgrade_class"

# XXX MO: upgrades yet to be implemented in most plugins
        or fatal "cannot upgrade via $upgrade_class: $@";
#or return $class->VERSION;

    return $upgrade_class->upgrade(from => $from, to => $class->VERSION)
        if $from;

    # First run
    $upgrade_class->setup;
    $class->VERSION;
}

1;
