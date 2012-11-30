## This package handles Sympa global site
## It should :
##   * provide access to global conf parameters,

####
#### Site_r package
####
#### Don't access to the contents of this class directly.  This class is
#### used by subclasses such as List to exclude autoloading accessors
#### from inherited methods.
package Site_r;

use strict;
use warnings;
use Carp qw(croak);

use Conf;
use Language qw(gettext gettext_strftime);
use User;

=head1 NAME

Site - Sympa Site

=head1 DESCRIPTION

=cut

our %robots;
our $robots_ok;
our %listmaster_messages_stack;

=head2 INITIALIZER

=over 4

=item load ( OBJECT, [ OPT => VAL, ... ] )

    # To load global config
    Site->load();
    # To load robot config
    $robot->load();

Loads and parses the configuration file.  Reports errors if any.

do not try to load database values if 'no_db' option is set;
do not change global hash %Conf if 'return_result' option is set;

##we known that's dirty, this proc should be rewritten without this global var %Conf

NOTE: To load entire robots config, use C<Robot::get_robots('force_reload' =E<gt> 1)>.

=back

=cut

sub load {
    &Log::do_log('debug2', '(%s, ...)', @_);

    ## NOTICE: Don't use accessors like "$self->etc" but "$self->{'etc'}",
    ## since the object has not been fully initialized yet.

    my $self = shift;
    my %opts = @_;

    if (ref $self and ref $self eq 'Robot') {
	unless ($self->{'name'} and $self->{'etc'}) {
	    &Log::do_log('err', 'object %s has not been initialized', $self);
	    return undef;
	}
	$opts{'config_file'} = $self->{'etc'} . '/robot.conf';
	$opts{'robot'}       = $self->{'name'};
    } elsif ($self eq 'Site') {
	$opts{'config_file'} ||= Conf::get_sympa_conf();
	$opts{'robot'} = '*';
    } else {
	croak 'bug in logic.  Ask developer';
    }

    my $result = Conf::load_robot_conf(\%opts);

    ## Robot cache must be reloaded if Site config had been reloaded.
    Site->init_robot_cache() if !ref $self and $self eq 'Site' and $result;

    return undef unless defined $result;
    return $result if $opts{'return_result'};

    ## Site configuration was successfully initialized.
    $Site::is_initialized = 1 if !ref $self and $self eq 'Site';

    return 1;
}

=head2 METHODS

=head3 Users

=over 4

=item get_address ( [ TYPE ] )

    # To get super listmaster address
    $addr = Site->get_address('listmaster');
    # To get normal (per-robot) listmaster address
    $addr = $robot->get_address('listmaster');
    # To get list addresses
    $addr = $list->get_address();
    $addr = $list->get_address('owner');

On Site class or Robot object,
returns the site or robot email address of type TYPE: "listmaster".

On List object,
returns the list email address of type TYPE: posting address (default),
"owner", "editor" or (non-VERP) "return_path".

=back

=cut

sub get_address {
    my $self = shift;
    my $type = shift || '';

    if (ref $self and ref $self eq 'List') {
	unless ($type) {
	    return $self->name . '@' . $self->host;
	} elsif ($type eq 'owner') {
	    return $self->name . '-request' . '@' . $self->host;
	} elsif ($type eq 'editor') {
	    return $self->name . '-editor' . '@' . $self->host;
	} elsif ($type eq 'return_path') {
	    return $self->name . $self->robot->return_path_suffix . '@' .
		$self->host;
	}
    } elsif (ref $self and ref $self eq 'Robot' or $self eq 'Site') {
	if ($type eq 'listmaster') {
	    return $self->listmaster_email . '@' . $self->host;
	}
    } else {
	croak 'bug in logic.  Ask developer';
    }
    &Log::do_log('err', 'Unknown type of address "%s".  Ask developer',
	$type);
    return undef;
}

=over 4

=item is_listmaster ( WHO )

    # Is the user super listmaster?
    if (Site->is_listmaster($email) ...
    # Is the user normal or super listmaster?
    if ($robot->is_listmaster($email) ...

Is the user listmaster?

=back

=cut

sub is_listmaster {
    my $self = shift;
    my $who = tools::clean_email(shift || '');
    return 0 unless $who;

    if (ref $self and ref $self eq 'Robot') {
	foreach my $listmaster (($self->listmasters,)) {
	    return 1 if $listmaster eq $who;
	}
    } elsif ($self eq 'Site') {
	;
    } else {
	croak 'bug is logic.  Ask developer';
    }

    foreach my $listmaster ((Site->listmasters,)) {
	return 1 if $listmaster eq $who;
    }

    return 0;
}

=head3 Handling the Authentication Token

=over 4

=item compute_auth

    # To compute site-wide token
    Site->compute_auth('user@dom.ain', 'remind');
    # To cpmpute a token specific to a list
    $list->compute_auth('user@dom.ain', 'subscribe');

Genererate a md5 checksum using private cookie and parameters

=back

=cut

sub compute_auth {
    &Log::do_log('debug3', '(%s, %s, %s)', @_);
    my $self  = shift;
    my $email = lc(shift || '');
    my $cmd   = lc(shift || '');

    my ($cookie, $key, $listname);

    if (ref $self and ref $self eq 'List') {
	$listname = $self->name;
    } elsif (ref $self and ref $self eq 'Robot') {
	## Method excluded from inheritance chain
	croak sprintf 'Can\'t locate object method "%s" via package "%s"',
	    'compute_auth', ref $self;
    } elsif ($self eq 'Site') {
	$listname = '';
    } else {
	croak 'bug in logic.  Ask developer';
    }
    $cookie = $self->cookie;

    $key = substr(
	Digest::MD5::md5_hex(join('/', $cookie, $listname, $email, $cmd)),
	-8);

    return $key;
}

=over 4

=item request_auth

    # To send robot or site auth request
    Site->request_auth('user@dom.ain', 'remind');
    # To send auth request specific to a list
    $list->request_auth('user@dom.ain', 'subscribe'):

Sends an authentification request for a requested
command.

IN : 
      -$self : ref(List) | "Site"
      -$email(+) : recepient (the personn who asked
                   for the command)
      -$cmd : -signoff|subscribe|add|del|remind if $self is List
              -remind else
      -@param : 0 : used if $cmd = subscribe|add|del|invite
                1 : used if $cmd = add

OUT : 1 | undef

=back

=cut

sub request_auth {
    &Log::do_log('debug2', '(%s, %s, %s)', @_);
    my $self  = shift;
    my $email = shift;
    my $cmd   = shift;
    my @param = @_;
    my $keyauth;
    my $data = {'to' => $email};

    if (ref $self and ref $self eq 'List') {
	my $listname = $self->name;
	$data->{'list_context'} = 1;

	if ($cmd =~ /signoff$/) {
	    $keyauth = $self->compute_auth($email, 'signoff');
	    $data->{'command'} = "auth $keyauth $cmd $listname $email";
	    $data->{'type'}    = 'signoff';

	} elsif ($cmd =~ /subscribe$/) {
	    $keyauth = $self->compute_auth($email, 'subscribe');
	    $data->{'command'} = "auth $keyauth $cmd $listname $param[0]";
	    $data->{'type'}    = 'subscribe';

	} elsif ($cmd =~ /add$/) {
	    $keyauth = $self->compute_auth($param[0], 'add');
	    $data->{'command'} =
		"auth $keyauth $cmd $listname $param[0] $param[1]";
	    $data->{'type'} = 'add';

	} elsif ($cmd =~ /del$/) {
	    my $keyauth = $self->compute_auth($param[0], 'del');
	    $data->{'command'} = "auth $keyauth $cmd $listname $param[0]";
	    $data->{'type'}    = 'del';

	} elsif ($cmd eq 'remind') {
	    my $keyauth = $self->compute_auth('', 'remind');
	    $data->{'command'} = "auth $keyauth $cmd $listname";
	    $data->{'type'}    = 'remind';

	} elsif ($cmd eq 'invite') {
	    my $keyauth = $self->compute_auth($param[0], 'invite');
	    $data->{'command'} = "auth $keyauth $cmd $listname $param[0]";
	    $data->{'type'}    = 'invite';
	}
    } elsif (ref $self and ref $self eq 'Robot') {
	## Method excluded from inheritance chain
	croak sprintf 'Can\'t locate object method "%s" via package "%s"',
	    'request_auth', ref $self;
    } elsif ($self eq 'Site') {
	if ($cmd eq 'remind') {
	    my $keyauth = $self->compute_auth('', $cmd);
	    $data->{'command'} = "auth $keyauth $cmd *";
	    $data->{'type'}    = 'remind';
	}
    } else {
	croak 'bug in logic.  Ask developer';
    }

    $data->{'command_escaped'} = &tt2::escape_url($data->{'command'});
    $data->{'auto_submitted'}  = 'auto-replied';
    unless ($self->send_file('request_auth', $email, $data)) {
	&Log::do_log('notice', 'Unable to send template "request_auth" to %s',
	    $email);
	return undef;
    }

    return 1;
}

=head3 Finding config files and templates

=over 4

=item get_etc_filename

    # To get file name for global site
    $file = Site->get_etc_filename($name);
    # To get file name for a robot
    $file = $robot->get_etc_filename($name);
    # To get file name for a family
    $file = $family->get_etc_filename($name);
    # To get file name for a list
    $file = $list->get_etc_filename($name);

Look for a file in the list > robot > server > default locations.

Possible values for $options : order=all

=back

=cut

sub get_etc_filename {
    &Log::do_log('debug3', '(%s, %s, %s)', @_);
    my $self    = shift;
    my $name    = shift;
    my $options = shift || {};

    if (ref $self eq 'List') {
	;
    } elsif (ref $self eq 'Family') {
	;
    } elsif (ref $self eq 'Robot') {
	;
    } elsif ($self eq 'Site') {
	;
    } else {
	croak 'bug in logic.  Ask developer';
    }

    my (@try, $default_name);

    ## template refers to a language
    ## => extend search to default tpls
    ## FIXME: family path precedes to list path.  Is it appropriate?
    ## FIXME: Should language subdirectories be searched?
    if ($name =~ /^(\S+)\.([^\s\/]+)\.tt2$/) {
	$default_name = $1 . '.tt2';
	@try =
	    map { ($_ . '/' . $name, $_ . '/' . $default_name) }
	    @{$self->make_tt2_include_path};
    } else {
	@try = map { $_ . '/' . $name } @{$self->make_tt2_include_path};
    }

    my @result;
    foreach my $f (@try) {
	if (-r $f) {
	    &Log::do_log('debug3', 'name: %s ; dir %s', $name, $f);
	    if ($options->{'order'} and $options->{'order'} eq 'all') {
		push @result, $f;
	    } else {
		return $f;
	    }
	}
    }
    if ($options->{'order'} and $options->{'order'} eq 'all') {
	return @result;
    }

    return undef;
}

=over 4

=item make_tt2_include_path

    # To make include path for global site
    @path = @{Site->make_tt2_include_path};
    # To make include path for a robot
    @path = @{$robot->make_tt2_include_path};
    # To make include path for a family
    @path = @{$family->make_tt2_include_path};
    # To make include path for a list
    @path = @{$list->make_tt2_include_path};

make an array of include path for tt2 parsing

IN :
      -$self(+) : ref(List) | ref(Family) | ref(Robot) | "Site"
      -$dir : directory ending each path
      -$lang : lang

OUT : ref(ARRAY) of tt2 include path

=back

=cut

sub _make_tt2_include_path {
    &Log::do_log('debug3', '(%s, %s, %s)', @_);
    my $self = shift;
    my ($dir, $lang) = @_;

    my @include_path;

    if (ref $self and ref $self eq 'List') {
	my $path_list;
	my $path_family;
	@include_path = $self->robot->_make_tt2_include_path(@_);

	if ($dir) {
	    $path_list = $self->dir . '/' . $dir;
	} else {
	    $path_list = $self->dir;
	}
	if ($lang) {
	    unshift @include_path, $path_list . '/' . $lang, $path_list;
	} else {
	    unshift @include_path, $path_list;
	}

	if (defined $self->family) {
	    my $family = $self->family;
	    if ($dir) {
		$path_family = $family->dir . '/' . $dir;
	    } else {
		$path_family = $family->dir;
	    }
	    if ($lang) {
		unshift @include_path,
		    $path_family . '/' . $lang, $path_family;
	    } else {
		unshift @include_path, $path_family;
	    }
	}
    } elsif (ref $self and ref $self eq 'Family') {
	my $path_family;
	@include_path = $self->robot->_make_tt2_include_path(@_);

	if ($dir) {
	    $path_family = $self->dir . '/' . $dir;
	} else {
	    $path_family = $self->dir;
	}
	if ($lang) {
	    unshift @include_path, $path_family . '/' . $lang, $path_family;
	} else {
	    unshift @include_path, $path_family;
	}
    } elsif (ref $self and ref $self eq 'Robot') {
	my $path_robot;
	@include_path = Site->_make_tt2_include_path(@_);

	if ($self->etc ne Site->etc) {
	    if ($dir) {
		$path_robot = $self->etc . '/' . $dir;
	    } else {
		$path_robot = $self->etc;
	    }
	    if ($lang) {
		unshift @include_path, $path_robot . '/' . $lang, $path_robot;
	    } else {
		unshift @include_path, $path_robot;
	    }
	}
    } elsif ($self eq 'Site') {
	my $path_etcbindir;
	my $path_etcdir;

	if ($dir) {
	    $path_etcbindir = Sympa::Constants::DEFAULTDIR . '/' . $dir;
	    $path_etcdir    = Site->etc . '/' . $dir;
	} else {
	    $path_etcbindir = Sympa::Constants::DEFAULTDIR;
	    $path_etcdir    = Site->etc;
	}
	if ($lang) {
	    @include_path = (
		$path_etcdir . '/' . $lang,    $path_etcdir,
		$path_etcbindir . '/' . $lang, $path_etcbindir
	    );
	} else {
	    @include_path = ($path_etcdir, $path_etcbindir);
	}
    } else {
	croak 'bug in logic.  Ask developer';
    }

    return @include_path;
}

sub make_tt2_include_path {
    &Log::do_log('debug3', '(%s, %s, %s)', @_);
    my $self = shift;
    ## Not always expose viewmail directory.
    ##return [Site->viewmail_dir, $self->_make_tt2_include_path(@_)];
    return [$self->_make_tt2_include_path(@_)];
}

=head3 Sending Notifications

=over 4

=item send_dsn ( MESSAGE_OBJECT, [ OPTIONS, [ STATUS, [ DIAG ] ] ] )

    # To send site-wide DSN
    Site->send_dsn($message, {'recipient' => $rcpt},
        '5.1.2', 'Unknown robot');
    # To send DSN related to a robot
    $robot->send_dsn($message, {'listname' => $name},
        '5.1.1', 'Unknown list');
    # To send DSN specific to a list
    $list->send_dsn($message, {}, '2.1.5', 'Success');

Sends a delivery status notification (DSN) to SENDER
by parsing dsn.tt2 template.

=back

=cut

sub send_dsn {
    my $self    = shift;
    my $message = shift;
    my $param   = shift || {};
    my $status  = shift;
    my $diag    = shift || '';

    unless (ref $message and ref $message eq 'Message') {
	&Log::do_log('err', 'object %s is not Message', $message);
	return undef;
    }

    my $sender;
    if (defined($sender = $message->{'envsender'})) {
	## Won't reply to message with null envelope sender.
	return 0 if $sender eq '<>';
    } elsif (!defined($sender = $message->{'sender'})) {
	&Log::do_log('err', 'no sender found');
	return undef;
    }

    my $recipient = '';
    if (ref $self and ref $self eq 'List') {
	$recipient = $self->get_address;
	$status ||= '5.1.1';
    } elsif (ref $self and ref $self eq 'Robot') {
	if ($param->{'listname'}) {
	    if ($param->{'function'}) {
		$recipient = sprintf '%s-%s@%s', $param->{'listname'},
		    $param->{'function'}, $self->host;
	    } else {
		$recipient = sprintf '%s@%s', $param->{'listname'},
		    $self->host;
	    }
	}
	$recipient ||= $param->{'recipient'};
	$status ||= '5.1.1';
    } elsif ($self eq 'Site') {
	$recipient = $param->{'recipient'};
	$status ||= '5.1.2';
    } else {
	croak 'bug in logic.  Ask developer';
    }

    ## Default diagnostic messages taken from IANA registry:
    ## http://www.iana.org/assignments/smtp-enhanced-status-codes/
    ## They should be modified to fit in Sympa.
    $diag ||= {

	# success
	'2.1.5' => 'Destination address valid',

	# no available family, dynamic list creation failed, etc.
	'4.2.1' => 'Mailbox disabled, not accepting messages',

	# no subscribers in dynamic list
	'4.2.4' => 'Mailing list expansion problem',

	# unknown list address
	'5.1.1' => 'Bad destination mailbox address',

	# unknown robot
	'5.1.2' => 'Bad destination system address',

	# too large
	'5.2.3' => 'Message length exceeds administrative limit',

	# misconfigured family list
	'5.3.5' => 'System incorrectly configured',

	# loop detected
	'5.4.6' => 'Routing loop detected',

	# virus found
	'5.7.0' => 'Other or undefined security status',
	}->{$status} ||
	'Other undefined Status';
    ## Delivery result, "failed" or "delivered".
    my $action = (index($status, '2') == 0) ? 'delivered' : 'failed';

    my $header = $message->{'msg'}->head->as_string;

    Language::PushLang('en');
    my $date = POSIX::strftime("%a, %d %b %Y %H:%M:%S +0000", gmtime time);
    Language::PopLang();

    unless (
	$self->send_file(
	    'dsn', $sender,
	    {   %$param,
		'recipient'       => $recipient,
		'to'              => $sender,
		'date'            => $date,
		'header'          => $header,
		'auto_submitted'  => 'auto-replied',
		'action'          => $action,
		'status'          => $status,
		'diagnostic_code' => $diag,
		'return_path'     => '<>'
	    }
	)
	) {
	&Log::do_log('err', 'Unable to send DSN to %s', $sender);
	return undef;
    }

    return 1;
}

=over 4

=item send_file                              

    # To send site-global (not relative to a list or a robot)
    # message
    Site->send_file($template, $who, ...);
    # To send global (not relative to a list, but relative to a
    # robot) message 
    $robot->send_file($template, $who, ...);
    # To send message relative to a list
    $list->send_file($template, $who, ...);

Send a message to user(s).
Find the tt2 file according to $tpl, set up 
$data for the next parsing (with $context and
configuration)
Message is signed if the list has a key and a 
certificate

Note: List::send_global_file() was deprecated.

IN :
      -$self (+): ref(List) | ref(Robot) | "Site"
      -$tpl (+): template file name (file.tt2),
         without tt2 extension
      -$who (+): SCALAR |ref(ARRAY) - recipient(s)
      -$context : ref(HASH) - for the $data set up 
         to parse file tt2, keys can be :
         -user : ref(HASH), keys can be :
           -email
           -lang
           -password
         -auto_submitted auto-generated|auto-replied|auto-forwarded
         -...
      -$options : ref(HASH) - options

OUT : 1 | undef

=back

=cut

## This method proxies site-global, robot-global and list-local methods,
## i.e. Site->send_file(), $robot->send_file() and $list->send_file().

sub send_file {
    &Log::do_log('debug2', '(%s, %s, %s, ...)', @_);
    my $self    = shift;
    my $tpl     = shift;
    my $who     = shift;
    my $context = shift || {};
    my $options = shift || {};

    my ($robot, $list, $robot_id);
    if (ref $self and ref $self eq 'List') {
	$robot    = $self->robot;
	$list     = $self;
	$robot_id = $self->robot->name;
    } elsif (ref $self and ref $self eq 'Robot') {
	$robot    = $self;
	$list     = '';
	$robot_id = $self->name;
    } elsif ($self eq 'Site') {
	$robot    = $self;
	$list     = '';
	$robot_id = '*';
    } else {
	croak 'bug in logic.  Ask developer';
    }

    my $data = &tools::dup_var($context);

    ## Any recipients
    if (!defined $who or
	ref $who and
	!scalar @$who or
	!ref $who and
	!length $who) {
	&Log::do_log('err', 'No recipient for sending %s', $tpl);
	return undef;
    }

    ## Unless multiple recipients
    unless (ref $who) {
	$who = tools::clean_email($who);
	my $lang = $self->lang || 'en';
	unless (ref $data->{'user'} and $data->{'user'}{'email'}) {
	    if ($options->{'skip_db'}) {
		$data->{'user'} =
		    bless {'email' => $who, 'lang' => $lang} => 'User';
	    } else {
		$data->{'user'} = User->new($who, 'lang' => $lang);
	    }
	} else {
	    $data->{'user'} = User::clean_user($data->{'user'});
	}

	if (ref $self eq 'List') {
	    $data->{'subscriber'} = $self->get_list_member($who);

	    if ($data->{'subscriber'}) {
		$data->{'subscriber'}{'date'} = gettext_strftime "%d %b %Y",
		    localtime($data->{'subscriber'}{'date'});
		$data->{'subscriber'}{'update_date'} =
		    gettext_strftime "%d %b %Y",
		    localtime($data->{'subscriber'}{'update_date'});
		if ($data->{'subscriber'}{'bounce'}) {
		    $data->{'subscriber'}{'bounce'} =~
			/^(\d+)\s+(\d+)\s+(\d+)(\s+(.*))?$/;

		    $data->{'subscriber'}{'first_bounce'} =
			gettext_strftime "%d %b %Y", localtime($1);
		}
	    }
	}

	unless ($data->{'user'}->password) {
	    $data->{'user'}->password(&tools::tmp_passwd($who));
	}

	if (ref $self eq 'List') {
	    ## Unique return-path VERP
	    if ($self->welcome_return_path eq 'unique' and
		$tpl eq 'welcome') {
		$data->{'return_path'} = $self->get_bounce_address($who, 'w');
	    } elsif ($self->remind_return_path eq 'unique' and
		$tpl eq 'remind') {
		$data->{'return_path'} = $self->get_bounce_address($who, 'r');
	    }
	}
    } else {
	$who = User::clean_users($who);
    }

    ## Lang
    undef $data->{'lang'};
    $data->{'lang'} = $data->{'user'}->lang if ref $data->{'user'};
    $data->{'lang'} ||= $self->lang if ref $self eq 'List';
    $data->{'lang'} ||= $robot->lang;

    if (ref $self eq 'List') {
	## Trying to use custom_vars
	if (defined $self->custom_vars) {
	    $data->{'custom_vars'} = {};
	    foreach my $var (@{$self->custom_vars}) {
		$data->{'custom_vars'}{$var->{'name'}} = $var->{'value'};
	    }
	}
    }

    ## What file
    my $lang = &Language::Lang2Locale($data->{'lang'});
    my $tt2_include_path = $self->make_tt2_include_path('mail_tt2', $lang);
    if (ref $self eq 'List') {
	## list directory to get the 'info' file
	push @{$tt2_include_path}, $self->dir;
	## list archives to include the last message
	push @{$tt2_include_path}, $self->dir . '/archives';
    }

    foreach my $d (@{$tt2_include_path}) {
	&tt2::add_include_path($d);
    }

    my @path = &tt2::get_include_path();
    my $filename = &tools::find_file($tpl . '.tt2', @path);

    unless (defined $filename) {
	&Log::do_log('err', 'Could not find template %s.tt2 in %s',
	    $tpl, join(':', @path));
	return undef;
    }

    $data->{'conf'} ||= {};
    foreach my $p (
	'email',       'email_gecos',
	'host',        'sympa',
	'request',     'listmaster',
	'wwsympa_url', 'title',
	'listmaster_email'
	) {
	$data->{'conf'}{$p} = $robot->$p;
    }

    $data->{'sender'} ||= $who;

    $data->{'conf'}{'version'} = $main::Version if defined $main::Version;
    $data->{'robot_domain'} = $robot_id;
    if (ref $self eq 'List') {
	foreach my $p ('lang', 'name', 'domain', 'host', 'subject', 'dir') {
	    $data->{'list'}{$p} = $self->$p;
	}
	$data->{'list'}{'owner'} = $self->get_owners();

	## Sign mode
	my $sign_mode;
	if (Site->openssl and
	    -r $self->dir . '/cert.pem' and
	    -r $self->dir . '/private_key') {
	    $sign_mode = 'smime';
	}
	$data->{'sign_mode'} = $sign_mode;

	# if the list have it's private_key and cert sign the message
	# . used only for the welcome message, could be usefull in other case?
	# . a list should have several certificats and use if possible a
	#   certificat issued by the same CA as the receipient CA if it exists
	if ($sign_mode and $sign_mode eq 'smime') {
	    $data->{'fromlist'} = $self->get_address();
	    $data->{'replyto'}  = $self->get_address('owner');
	} else {
	    $data->{'fromlist'} = $self->get_address('owner');
	}
	$data->{'from'} = $data->{'fromlist'} unless $data->{'from'};
	$data->{'return_path'} ||= $self->get_address('return_path');
    } else {
	$data->{'from'} ||= $self->sympa;
	unless ($data->{'return_path'} and $data->{'return_path'} eq '<>') {
	    $data->{'return_path'} = $self->request;
	}
    }

    $data->{'boundary'} = '----------=_' . &tools::get_message_id($robot)
	unless $data->{'boundary'};

    my $dkim_feature          = $robot->dkim_feature;
    my $dkim_add_signature_to = $robot->dkim_add_signature_to;
    if ($dkim_feature eq 'on' and $dkim_add_signature_to =~ /robot/) {
	$data->{'dkim'} = &tools::get_dkim_parameters($robot);
    }

    # use verp excepted for alarms. We should make this configurable in
    # order to support Sympa server on a machine without any MTA service
    $data->{'use_bulk'} = 1
	unless ($data->{'alarm'});
    my $r =
	&mail::mail_file($filename, $who, $data, $robot,
	$options->{'parse_and_return'});
    return $r if $options->{'parse_and_return'};

    unless ($r) {
	&Log::do_log('err', 'Could not send template "%s" to %s',
	    $filename, $who);
	return undef;
    }

    return 1;
}

=over 4

=item send_notify_to_listmaster ( OPERATION, DATA, CHECKSTACK, PURGE )

    # To send notify to super listmaster(s)
    Site->send_notify_to_listmaster('css_updated', ...);
    # To send notify to normal (per-robot) listmaster(s)
    $robot->send_notify_to_listmaster('web_tt2_error', ...);

Sends a notice to (super or normal) listmaster by parsing
listmaster_notification.tt2 template

Note: List::send_notify_to_listmaster() was deprecated.

IN :
       -$self (+): ref(Robot) | "Site"
       -$operation (+): notification type
       -$param(+) : ref(HASH) | ref(ARRAY)
        values for template parsing

OUT : 1 | undef

=back

=cut

## This method proxies site-global and robot-global methods, i.e.
## Site->send_notify_to_listmaster() and $robot->send_notify_to_listmaster().

sub send_notify_to_listmaster {
    &Log::do_log('debug2', '(%s, %s, ...)', @_);
    my $self       = shift;
    my $operation  = shift;
    my $data       = shift;
    my $checkstack = shift;
    my $purge      = shift;

    my $robot_id;
    if (ref $self and ref $self eq 'List') {
	## Method excluded from inheritance chain
	croak sprintf 'Can\'t locate object method "%s" via package "%s"',
	    'send_notify_to_listmaster', ref $self;
    } elsif (ref $self and ref $self eq 'Robot') {
	$robot_id = $self->name;
    } elsif ($self eq 'Site') {
	$robot_id = '*';
    } else {
	croak 'bug in logic.  Ask developer';
    }

    if ($checkstack or $purge) {
	foreach my $robot_id (keys %listmaster_messages_stack) {
	    my $robot;
	    if (!$robot_id or $robot_id eq '*') {
		$robot = 'Site';
	    } else {
		$robot = Robot->new($robot_id);
	    }

	    foreach
		my $operation (keys %{$listmaster_messages_stack{$robot_id}})
	    {
		my $first_age =
		    time -
		    $listmaster_messages_stack{$robot_id}{$operation}
		    {'first'};
		my $last_age = time -
		    $listmaster_messages_stack{$robot_id}{$operation}{'last'};

		# not old enough to send and first not too old
		next
		    unless ($purge or ($last_age > 30) or ($first_age > 60));
		next
		    unless ($listmaster_messages_stack{$robot_id}{$operation}
		    {'messages'});

		my %messages =
		    %{$listmaster_messages_stack{$robot_id}{$operation}
			{'messages'}};
		&Log::do_log(
		    'info', 'got messages about "%s" (%s)',
		    $operation, join(', ', keys %messages)
		);

		##### bulk send
		foreach my $email (keys %messages) {
		    my $param = {
			to                    => $email,
			auto_submitted        => 'auto-generated',
			alarm                 => 1,
			operation             => $operation,
			notification_messages => $messages{$email},
			boundary              => '----------=_' .
			    &tools::get_message_id($robot)
		    };

		    my $options = {};
		    $options->{'skip_db'} = 1
			if (($operation eq 'no_db') ||
			($operation eq 'db_restored'));

		    &Log::do_log('info', 'send messages to %s', $email);
		    unless (
			$robot->send_file(
			    'listmaster_groupednotifications',
			    $email, $param, $options
			)
			) {
			&Log::do_log('notice',
			    "Unable to send template 'listmaster_notification' to $email"
			) unless ($operation eq 'logs_failed');
			return undef;
		    }
		}

		&Log::do_log('info', 'cleaning stacked notifications');
		delete $listmaster_messages_stack{$robot_id}{$operation};
	    }
	}
	return 1;
    }

    my $stack = 0;
    $listmaster_messages_stack{$robot_id}{$operation}{'first'} = time
	unless ($listmaster_messages_stack{$robot_id}{$operation}{'first'});
    $listmaster_messages_stack{$robot_id}{$operation}{'counter'}++;
    $listmaster_messages_stack{$robot_id}{$operation}{'last'} = time;
    if ($listmaster_messages_stack{$robot_id}{$operation}{'counter'} > 3) {

	# stack if too much messages w/ same code
	$stack = 1;
    }

    unless (defined $operation) {
	&Log::do_log('err', 'Missing incoming parameter "$operation"');
	return undef;
    }

    unless ($operation eq 'logs_failed') {
	unless (defined $robot_id) {
	    &Log::do_log('err', 'Missing incoming parameter "$robot_id"');
	    return undef;
	}
    }

    my $host       = $self->host;
    my $listmaster = $self->listmaster;
    my $to         = $self->listmaster_email . '@' . $host;
    my $options = {};    ## options for send_file()

    if (!ref $data and length $data) {
	$data = [$data];
    }
    unless (ref $data eq 'HASH' or ref $data eq 'ARRAY') {
	&Log::do_log(
	    'err',
	    'Error on incoming parameter "%s", it must be a ref on HASH or a ref on ARRAY',
	    $data
	) unless $operation eq 'logs_failed';
	return undef;
    }

    if (ref($data) ne 'HASH') {
	my $d = {};
	for my $i (0 .. $#{$data}) {
	    $d->{"param$i"} = $data->[$i];
	}
	$data = $d;
    }

    $data->{'to'}             = $to;
    $data->{'type'}           = $operation;
    $data->{'auto_submitted'} = 'auto-generated';
    $data->{'alarm'}          = 1;

    my $list = undef;
    if ($data->{'list'} and ref($data->{'list'}) eq 'List') {
	$list = $data->{'list'};
	$data->{'list'} = {
	    'name'    => $list->name,
	    'host'    => $list->domain,   #FIXME: robot name or mail hostname?
	    'subject' => $list->subject,
	};
    }

    my @tosend;

    if ($operation eq 'automatic_bounce_management') {
	## Automatic action done on bouncing adresses
	delete $data->{'alarm'};
	unless (defined $list and ref $list eq 'List') {
	    &Log::do_log('err', 'Parameter %s is not a valid list', $list);
	    return undef;
	}
	unless (
	    $list->send_file(
		'listmaster_notification',
		$listmaster, $data, $options
	    )
	    ) {
	    &Log::do_log('notice',
		'Unable to send template "listmaster_notification" to %s',
		$listmaster);
	    return undef;
	}
	return 1;
    }

    if ($operation eq 'no_db' or $operation eq 'db_restored') {
	## No DataBase |  DataBase restored
	$data->{'db_name'} = $self->db_name;
	## Skip DB access because DB is not accessible
	$options->{'skip_db'} = 1;
    }

    if ($operation eq 'loop_command') {
	## Loop detected in Sympa
	$data->{'boundary'} = '----------=_' . &tools::get_message_id($self);
	&tt2::allow_absolute_path();
    }

    if (($operation eq 'request_list_creation') or
	($operation eq 'request_list_renaming')) {
	foreach my $email (split(/\,/, $listmaster)) {
	    my $cdata = &tools::dup_var($data);
	    $cdata->{'one_time_ticket'} =
		&Auth::create_one_time_ticket($email, $robot_id,
		'get_pending_lists', $cdata->{'ip'});
	    push @tosend,
		{
		email => $email,
		data  => $cdata
		};
	}
    } else {
	push @tosend,
	    {
	    email => $listmaster,
	    data  => $data
	    };
    }

    foreach my $ts (@tosend) {
	$options->{'parse_and_return'} = 1 if ($stack);
	my $r =
	    $self->send_file('listmaster_notification', $ts->{'email'},
	    $ts->{'data'}, $options);
	if ($stack) {
	    &Log::do_log('info', 'stacking message about "%s" for %s (%s)',
		$operation, $ts->{'email'}, $robot_id);
	    ## stack robot object and parsed message.
	    push @{$listmaster_messages_stack{$robot_id}{$operation}
		    {'messages'}{$ts->{'email'}}}, $r;
	    return 1;
	}

	unless ($r) {
	    &Log::do_log('notice',
		'Unable to send template "listmaster_notification" to %s',
		$listmaster)
		unless $operation eq 'logs_failed';
	    return undef;
	}
    }

    return 1;
}

=head3 Handling Memory Caches

=over 4

=item init_robot_cache

Clear robot cache on memory.

=back

=cut

sub init_robot_cache {
    %robots    = ();
    $robots_ok = undef;
}

=over 4

=item robots ( [ NAME, [ ROBOT ] )

Handles cached information of robots on memory.

I<Getter>.
Gets cached robot(s) on memory.  If memory cache is missed, returns C<undef>.
Note: To ensure that all robots are cached, check L<robots_ok>.

I<Setter>.
Updates memory cache.
If C<undef> was given as ROBOT, cache entry on the memory will be removed.

=back

=cut

sub robots {
    my $self = shift;
    unless (scalar @_) {
	return map { $robots{$_} } sort keys %robots;
    }

    my $name = shift;
    if (scalar @_) {
	my $v = shift;
	unless (defined $v) {
	    delete $robots{$name};
	    delete Site->robots_config->{$name};
	} else {
	    $robots{$name} = $v;
	}
    }
    $robots{$name};
}

=over 4

=item robots_ok

I<Setter>.
XXX @todo doc

=back

=cut

sub robots_ok {
    my $self = shift;
    $robots_ok = shift if scalar @_;
    $robots_ok;
}

###### END of the Site_r package ######

####
#### Site class
####
#### This implements accessor methods to global config
####
package Site;

use strict;
use warnings;
use Carp qw(croak);

our @ISA = qw(Site_r);

####
#### global variables
####
our $is_initialized;
our $use_db;

=head3 ACCESSORS

=over 4

=item E<lt>config parameterE<gt>

I<Getters>.
Gets global or default config parameters.
For example: C<Site-E<gt>syslog> returns "syslog" global parameter;
C<Site-E<gt>domain> returns default "domain" parameter.

Some parameters may be vary by each robot from default value given by these
methods.  Use C<$robot-E<gt>>E<lt>config parameterE<gt> accessors instead.
See L<Robot/ACCESSORS>.

=item list_check_regexp

=item locale2charset

=item pictures_path

=item request

=item robot_by_http_host

=item sympa

=item ... etc.

I<Getters>.
Gets derived config parameters.

=back

=cut

our $AUTOLOAD;

sub DESTROY;

sub AUTOLOAD {
    Log::do_log('debug3', 'Autoloading %s', $AUTOLOAD);
    $AUTOLOAD =~ m/^(.*)::(.*)/;
    my $pkg  = $1;
    my $attr = $2;

    my $type = {};
    ## getters for site/robot attributes.
    $type->{'RobotAttribute'} =
	scalar(grep { $_ eq $attr } qw(etc home name));
    ## getters for site/robot parameters.
    $type->{'RobotParameter'} = scalar(
	grep { $_ eq $attr }
	    qw(blacklist list_check_regexp loging_condition loging_for_module
	    pictures_path request sympa)
	) ||
	scalar(grep { !defined $_->{'title'} and $_->{'name'} eq $attr }
	    @confdef::params);
    ## getters for attributes specific to global config.
    $type->{'SiteAttribute'} = scalar(
	grep { $_ eq $attr }
	    qw(auth_services authentication_info_url
	    cas_id cas_number crawlers_detection
	    generic_sso_id generic_sso_number
	    ldap ldap_export ldap_number
	    locale2charset nrcpt_by_domain
	    robot_by_http_host robot_by_soap_url
	    use_passwd)
    );

    unless (scalar keys %$type) {
	## getter for unknwon list attributes.
	## XXX This code would be removed later.
	if (index($attr, '_') != 0 and
	    ((ref $_[0] and exists $_[0]->{$attr}) or
		exists $Conf::Conf{$attr})
	    ) {
	    &Log::do_log(
		'err',
		'Unconcerned object method "%s" via package "%s".  Though it may not be fatal, you might want to report it developer',
		$attr,
		$pkg
	    );
	    no strict "refs";
	    *{$AUTOLOAD} = sub {
		croak "Can't modify \"$attr\" attribute" if scalar @_ > 1;
		shift->{$attr};
	    };
	    goto &$AUTOLOAD;
	}
	## XXX Code above would be removed later.

	croak "Can't locate object method \"$2\" via package \"$1\"";
    }

    no strict "refs";
    *{$AUTOLOAD} = sub {
	my $self = shift;

	if (ref $self and ref $self eq 'Robot') {
	    if ($type->{'RobotAttribute'}) {
		## getter for list attributes.
		croak "Can't modify \"$attr\" attribute" if scalar @_ > 1;
		return $self->{$attr};
	    } elsif ($type->{'RobotParameter'}) {
		## getters for robot parameters.
		unless ($self->{'etc'} eq Site->etc or
		    defined Site->robots_config->{$self->{'name'}}) {
		    croak "Can't call method \"$attr\" on uninitialized " .
			(ref $self) . " object";
		}
		croak "Can't modify \"$attr\" attribute" if scalar @_;

		if ($self->{'etc'} ne Site->etc and
		    defined Site->robots_config->{$self->{'name'}}{$attr}) {
		    ##FIXME: Might "exists" be used?
		    Site->robots_config->{$self->{'name'}}{$attr};
		} else {
		    Site->$attr;
		}
	    } else {
		croak "Can't call method \"$attr\" on " . (ref $self) .
		    " object";
	    }
	} elsif ($self eq 'Site') {
	    ## getter for internal config parameters.
	    croak "Can't call method \"$attr\" on uninitialized $self class"
		unless $Site::is_initialized;
	    croak "Can't modify \"$attr\" attribute"
		if scalar @_ > 1;

	    my $ret = $Conf::Conf{$attr};

	    # To avoid "Can't use an undefined value as a HASH reference"
	    if (!defined $ret and $type->{'SiteAttribute'}) {
		return {};
	    }
	    $ret;
	} else {
	    croak 'bug in logic.  Ask developer';
	}
    };
    goto &$AUTOLOAD;
}

=over 4

=item listmasters

I<Getter>.
Gets default listmasters.
In array context, returns array of default listmasters.
In scalar context, returns arrayref to them.

=back

=cut

sub listmasters {
    my $self = shift;

    croak "Can't modify \"listmasters\" attribute" if scalar @_ > 1;
    if (ref $self and ref $self eq 'Robot') {
	if (wantarray) {
	    @{Site->robots_config->{$self->domain}{'listmasters'} || []};
	} else {
	    Site->robots_config->{$self->domain}{'listmasters'};
	}
    } elsif ($self eq 'Site') {
	croak "Can't call method \"listmasters\" on uninitialized $self class"
	    unless $Site::is_initialized;

	if (wantarray) {
	    @{$Conf::Conf{'listmasters'} || []};
	} else {
	    $Conf::Conf{'listmasters'};
	}
    } else {
	croak 'bug in loginc.  Ask developer';
    }
}

=over 4

=item supported_languages

I<Getter>.
Gets supported languages, canonicalized.
In array context, returns array of globally supported languages.
In scalar context, returns arrayref to them.

=back

=cut

sub supported_languages {
    my $self = shift;
    my $supported_lang = $self->supported_lang;
    unless ($supported_lang) {
	return () if wantarray;
	return undef;
    }

    my @lang_list = map { $Language::lang2locale{$_} || $_ }
	split /\s*,\s*/, $supported_lang;
    return @lang_list if wantarray;
    return \@lang_list;
}

=head3 Miscelaneous

=over 4

=item import

XXX @todo doc

=back

=cut

sub import {
    ## register crash handler.
    $SIG{'__DIE__'} = \&_crash_handler;
}

## Handler for $SIG{__DIE__} to generate traceback.
## IN : error message
## OUT : none.  This function exits with status 255 or (if invoked from
## inside eval) simply returns.
sub _crash_handler {
    return if $^S;    # invoked from inside eval.

    #exit 255 unless ${^GLOBAL_PHASE} eq 'RUN';

    my $msg = $_[0];
    chomp $msg;
    &Log::do_log('err', 'DIED: %s', $msg);
    eval { Site->send_notify_to_listmaster(undef, undef, undef, 1); };
    eval { &SDM::db_disconnect; };    # unlock database
    Sys::Syslog::closelog();          # flush log

    ## gather traceback information
    my @calls;
    my @f;
    $_[0] =~ /.+ at (.+? line \d+\.)\n$/s;
    @calls = ($1) if $1;
    for (my $i = 1; @f = caller($i); $i++) {
	$calls[0] = "In $f[3] at $calls[0]" if @calls;
	unshift @calls, "$f[1] line $f[2].";
    }
    $calls[0] = "In (top-level) at $calls[0]";

    print STDERR join "\n", "DIED: $msg", @calls;
    print STDERR "\n";
    exit 255;
}

=over 4

=item robots_config

Get C<'robots'> item of loaded config.

I<NOT RECOMMENDED>.
This class method is prepared for backward compatibility.
L<Robot/get_robots> should be used.

=back

=cut

sub robots_config {
    return $Conf::Conf{'robots'} || {};
}

## Packages must return true.
1;
