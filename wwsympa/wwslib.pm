package wwslib;

use Exporter;
@ISA = ('Exporter');
@EXPORT = ();

@languages = ('fr','us','es','it','cn-gb');

%reception_mode = ('mail' => 'normal',
		   'digest' => 'digest',
		   'summary' => 'summary',
		   'notice' => 'notice',
		   'nomail' => 'no mail');

%visibility_mode = ('noconceal' => 'public',
		    'conceal' => 'conceal');

## Filenames with corresponding entry in NLS
%filenames = ('welcome.tpl' => 1,
	      'bye.tpl' => 2,
	      'removed.tpl'=> 3,
	      'message.footer' => 4,
	      'message.header' => 5,
	      'remind.tpl' => 6,
	      'reject.tpl' => 7,
	      'invite.tpl' => 8,
	      'helpfile.tpl' => 9,
	      'lists.tpl' => 10,
	      'global_remind.tpl' => 11,
	      'summary.tpl' => 12,
	      'info' => 13,
	      'homepage' => 14
	      );

## Defined in RFC 1893
%bounce_status = ('1.0' => 'Other address status',
		  '1.1' => 'Bad destination mailbox address',
		  '1.2' => 'Bad destination system address',
		  '1.3' => 'Bad destination mailbox address syntax',
		  '1.4' => 'Destination mailbox address ambiguous',
		  '1.5' => 'Destination mailbox address valid',
		  '1.6' => 'Mailbox has moved',
		  '1.7' => 'Bad sender\'s mailbox address syntax',
		  '1.8' => 'Bad sender\'s system address',
		  '2.0' => 'Other or undefined mailbox status',
		  '2.1' => 'Mailbox disabled, not accepting messages',
		  '2.2' => 'Mailbox full',
		  '2.3' => 'Message length exceeds administrative limit',
		  '2.4' => 'Mailing list expansion problem',
		  '3.0' => 'Other or undefined mail system status',
		  '3.1' => 'Mail system full',
		  '3.2' => 'System not accepting network messages',
		  '3.3' => 'System not capable of selected features',
		  '3.4' => 'Message too big for system',
		  '4.0' => 'Other or undefined network or routing status',
		  '4.1' => 'No answer from host',
		  '4.2' => 'Bad connection',
		  '4.3' => 'Routing server failure',
		  '4.4' => 'Unable to route',
		  '4.5' => 'Network congestion',
		  '4.6' => 'Routing loop detected',
		  '4.7' => 'Delivery time expired',
		  '5.0' => 'Other or undefined protocol status',
		  '5.1' => 'Invalid command',
		  '5.2' => 'Syntax error',
		  '5.3' => 'Too many recipients',
		  '5.4' => 'Invalid command arguments',
		  '5.5' => 'Wrong protocol version',
		  '6.0' => 'Other or undefined media error',
		  '6.1' => 'Media not supported',
		  '6.2' => 'Conversion required and prohibited',
		  '6.3' => 'Conversion required but not supported',
		  '6.4' => 'Conversion with loss performed',
		  '6.5' => 'Conversion failed',
		  '7.0' => 'Other or undefined security status',
		  '7.1' => 'Delivery not authorized, message refused',
		  '7.2' => 'Mailing list expansion prohibited',
		  '7.3' => 'Security conversion required but not possible',
		  '7.4' => 'Security features not supported',
		  '7.5' => 'Cryptographic failure',
		  '7.6' => 'Cryptographic algorithm not supported',
		  '7.7' => 'Message integrity failure');


## Load WWSympa configuration file
sub load_config {
    my $file = pop;

    ## Valid params
    my %default_conf = (arc_path => '/home/httpd/html/arc',
			archive_default_index => 'thrd',
			archived_pidfile => 'archived.pid',		  
			bounce_path => '/var/bounce',
			bounced_pidfile => 'bounced.pid',
			cookie_domain => 'localhost',
			cookie_expire => 0,
			icons_url => '/icons',
			mhonarc => '/usr/bin/mhonarc',
			review_page_size => 25,
			title => 'Mailing Lists Service',
			use_fast_cgi => 1,
			wws_path => '--BINDIR--',
			default_home => 'home',
			log_facility => ''
			);

    my $conf = \%default_conf;

    unless (open (FILE, $file)) {
	printf STDERR "load_config: unable to open $file\n";
	return undef;
    }
    
    while (<FILE>) {
	next if /^\s*\#/;

	if (/^\s*(\S+)\s+(.+)$/i) {
	    my ($k, $v) = ($1, $2);
	    $v =~ s/\s*$//;
	    if (defined ($conf->{$k})) {
		$conf->{$k} = $v;
	    }else {
		&Log::do_log ('info', 'unknown parameter %s', $k);
	    }
	}
	next;
    }
    
    close FILE;
    return $conf;
}

## Load HTTPD MIME Types
sub load_mime_types {
    my $types = {};

    @localisation = ('/etc/mime.types', '/usr/local/apache/conf/mime.types',
		     '/etc/httpd/conf/mime.types','mime.types');

    foreach my $loc (@localisation) {
	next unless (-r $loc);

	unless(open (CONF, $loc)) {
	    printf STDERR "load_mime_types: unable to open $loc\n";
	    return undef;
	}
    }
    
    while (<CONF>) {
	next if /^\s*\#/;
	
	if (/^(\S+)\s+(.+)\s*$/i) {
	    my ($k, $v) = ($1, $2);
	    
	    my @extensions = split / /, $v;
	    
	    foreach my $ext (@extensions) {
		$types->{$ext} = $k;
	    }
	    next;
	}
    }
    
    close FILE;
    return $types;
}

## Check user password in sympa database
sub check_pwd {
    my ($email, $pwd) = @_;
    my $user = &List::get_user_db($email);
    my $real_pwd = $user->{'password'};

    unless ($real_pwd) {
	&Log::do_log('info', 'password not found or user %s unknown', $email);
	&main::message('pwd_not_found');
	return undef;
    }

    unless ($pwd eq $real_pwd) {
        &Log::do_log('info', 'check_pwd: incorrect password');
	&main::message('incorrect_password');
        return undef;
    } 

    return 1;
}

## Returns user information extracted from the cookie
sub get_email_from_cookie {
#    &Log::do_log('debug', 'get_email_from_cookie');
    my $secret = shift;
    my $email ;

    unless ($secret) {
	&main::message('error in sympa configuration');
	&Log::do_log('info', 'parameter cookie undefine, authentication failure');
    }

    unless ($ENV{'HTTP_COOKIE'}) {
	&main::message('error in sympa missing cookie');
	&Log::do_log('info', ' ENV{HTTP_COOKIE} undefined, authentication failure');
    }

    unless ( $email = &cookielib::check_cookie ($ENV{'HTTP_COOKIE'}, $secret)) {
	&main::message('auth failed');
	&Log::do_log('info', 'get_email_from_cookie: auth failed for user %s', $email);
	return undef;
    }    

    return $email;
}

sub new_passwd {

    my $passwd;
    my $nbchar = int(rand 5) + 6;
    foreach my $i (0..$nbchar) {
	$passwd .= chr(int(rand 26) + ord('a'));
    }

    return 'INIT'.$passwd;
}

## Basic check of an email address
sub valid_email {
    my $email = shift;

    $email =~ /^(\S+|\".*\")@\S+$/;

}

sub init_passwd {
    my ($email, $data) = @_;
    
    my ($passwd, $user);
    
    if (&List::is_user_db($email)) {
	$user = &List::get_user_db($email);
	
	$passwd = $user->{'password'};
	
	unless ($passwd) {
	    $passwd = &new_passwd();
	    
	    unless ( &List::update_user_db($email,
					   {'password' => $passwd,
					    'lang' => $user->{'lang'} || $data->{'lang'}} )) {
		&main::message('update_failed');
		&Log::do_log('info','init_passwd: update failed');
		return undef;
	    }
	}
    }else {
	$passwd = &new_passwd();
	unless ( &List::add_user_db({'email' => $email,
				     'password' => $passwd,
				     'lang' => $data->{'lang'},
				     'gecos' => $data->{'gecos'}})) {
	    &main::message('add_failed');
	    &Log::do_log('info','init_passwd: add failed');
	    return undef;
	}
    }
    
    return 1;
}


1;







