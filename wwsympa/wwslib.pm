# wwslib.pm - This module includes functions used by wwsympa.fcgi
# RCS Identication ; $Revision$ ; $Date$ 
#
# Sympa - SYsteme de Multi-Postage Automatique
# Copyright (c) 1997, 1998, 1999, 2000, 2001 Comite Reseau des Universites
# Copyright (c) 1997,1998, 1999 Institut Pasteur & Christophe Wolfhugel
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.


package wwslib;
use lib '--LIBDIR--';

use Exporter;
@ISA = ('Exporter');
@EXPORT = ();

use Log;
use Conf;
# use Net::SSLeay qw(&get_https);
# use Net::SSLeay;

## Supported web languages
@languages = ('fr','us','es','it','nl','cn','cz','de','hu','et','ro','fi');

%reception_mode = ('mail' => 'normal',
		   'digest' => 'digest',
		   'summary' => 'summary',
		   'notice' => 'notice',
		   'txt' => 'txt',
		   'html'=> 'html',
		   'urlize' => 'urlize',
		   'nomail' => 'no mail',
		   'not_me' => 'not_me');

## Cookie expiration periods with corresponding entry in NLS
%cookie_period = (0     => 1,
		  10    => 2,
		  30    => 3, 
		  60    => 4,
		  360   => 5,
		  1440  => 6, 
		  43200 => 7);

%visibility_mode = ('noconceal' => 'public',
		    'conceal' => 'conceal');

## Filenames with corresponding entry in NLS set 15
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
	      'homepage' => 14,
	      'create_list_request.tpl' => 15,
	      'list_created.tpl' => 16,
	      'your_infected_msg.tpl' => 17,
	      'list_aliases.tpl' => 18
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



## if Crypt::CipherSaber installed store the cipher object
my $cipher;

## Load WWSympa configuration file
sub load_config {
    my $file = pop;

    ## Old params
    my %old_param = ('alias_manager' => 'No more used, using --SBINDIR--/alias_manager.pl',
		     'wws_path' => 'No more used');

    ## Valid params
    my %default_conf = (arc_path => '/home/httpd/html/arc',
			archive_default_index => 'thrd',
			archived_pidfile => '--PIDDIR--/archived.pid',		  
			bounce_path => '/var/bounce',
			bounced_pidfile => '--PIDDIR--/bounced.pid',
			cookie_domain => 'localhost',
			cookie_expire => 0,
			icons_url => '/icons',
			mhonarc => '/usr/bin/mhonarc',
			review_page_size => 25,
			task_manager_pidfile => '--PIDDIR--/task_manager.pid',
			title => 'Mailing Lists Service',
			use_fast_cgi => 1,
			default_home => 'home',
			log_facility => '',
			robots => '',
			password_case => 'insensitive',
			);

    my $conf = \%default_conf;

    unless (open (FILE, $file)) {
	&Log::do_log('err',"load_config: unable to open $file");
	return undef;
    }
    
    while (<FILE>) {
	next if /^\s*\#/;

	if (/^\s*(\S+)\s+(.+)$/i) {
	    my ($k, $v) = ($1, $2);
	    $v =~ s/\s*$//;
	    if (defined ($conf->{$k})) {
		$conf->{$k} = $v;
	    }elsif (defined $old_param{$k}) {
		&Log::do_log('err',"Parameter %s in %s no more supported : %s", $k, $file, $old_param{$k});
	    }else {
		&Log::do_log('err',"Unknown parameter %s in %s", $k, $file);
	    }
	}
	next;
    }
    
    close FILE;

    ## Check binaries and directories
    if ($conf->{'arc_path'} && (! -d $conf->{'arc_path'})) {
	&Log::do_log('err',"No web archives directory: %s\n", $conf->{'arc_path'});
    }

    if ($conf->{'bounce_path'} && (! -d $conf->{'bounce_path'})) {
	&Log::do_log('err',"No bounces directory: %s", $conf->{'bounce_path'});
    }

    if ($conf->{'mhonarc'} && (! -x $conf->{'mhonarc'})) {
	&Log::do_log('err',"MHonArc is not installed or %s is not executable.", $conf->{'mhonarc'});
    }

    # robots <robot_domain>,<http_host>,<robot title>(|<robot_domain>,<http_host>,<robot title>)+
    foreach my $robot (split /\|/, $conf->{'robots'}) {
	my ($domain,$host,$title) = split /\,/, $robot  ;
	$conf->{'robot_domain'}{$host} = $domain;
	$conf->{'robot_title'}{$domain} = $title;
    }
    

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
	    &Log::do_log('err',"load_mime_types: unable to open $loc");
	    return undef;
	}
    }
    
    while (<CONF>) {
	next if /^\s*\#/;
	
	if (/^(\S+)\s+(.+)\s*$/i) {
	    my ($k, $v) = ($1, $2);
	    
	    my @extensions = split / /, $v;
	
	    ## provides file extention, given the content-type
	    if ($#extensions >= 0) {
		$types->{$k} = $extensions[0];
	    }
    
	    foreach my $ext (@extensions) {
		$types->{$ext} = $k;
	    }
	    next;
	}
    }
    
    close FILE;
    return $types;
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

    return 'init'.$passwd;
}

## Basic check of an email address
sub valid_email {
    my $email = shift;
    
    $email =~ /^([\w\-\_\.\/\+\=]+|\".*\")\@[\w\-]+(\.[\w\-]+)+$/;
}

# create a cipher
sub ciphersaber_installed {
    if (require (Crypt::CipherSaber)) {
	return &Crypt::CipherSaber->new($Conf{'cookie'});
    }else{
	return ('no_cipher');
    }
}

## encrypt a password
sub crypt_passwd {
    my $inpasswd = shift ;

    unless (define($cipher)){
	$cipher = ciphersaber_installed();
    }
    return $inpasswd if ($cipher eq 'no_cipher') ;
    return ("crypt.".$cipher->encrypt ($inpasswd)) ;
}

## decrypt a password
sub decrypt_passwd {
    my $inpasswd = shift ;

    return $inpasswd unless ($inpasswd =~ /^crypt\.(.*)$/) ;
    $inpasswd = $1;

    unless (define($cipher)){
	$cipher = ciphersaber_installed();
    }
    if ($cipher eq 'no_cipher') {
	do_log('info','password seems crypted while CipherSaber is not installed !');
	return $inpasswd ;
    }
    return $cipher->decrypt ($inpasswd);
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

sub get_my_url {
    
		 
    my $return_url;
    
    if ($ENV{SSL_PROTOCOL}) {
	$return_url = 'https';
    }else{
	$return_url = 'http';	
    }	     

    $return_url .= '://'.$ENV{'HTTP_HOST'};
    $return_url .= ':'.$ENV{'SERVER_PORT'} unless (($ENV{'SERVER_PORT'} eq '80')||($ENV{'SERVER_PORT'} eq '443'));
    $return_url .= $ENV{'REQUEST_URI'};
    return ($return_url);
}

1;







