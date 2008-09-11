#!--PERL--

# Sympa - SYsteme de Multi-Postage Automatique
# Copyright (c) 1997, 1998, 1999, 2000, 2001 Comite Reseau des Universites
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

## Authors :
##           Serge Aumont <sa@cru.fr>
##           Olivier Salaün <os@cru.fr>

## Change this to point to your Sympa bin directory
use lib '--LIBDIR--';

use strict vars;
use POSIX;
require 'tools.pl';
require 'Conf.pm' unless ($ARGV[0] eq '-c');

## Configuration

my $wwsconf = {};

## Change to your wwsympa.conf location
my $wwsympa_conf = "$ENV{'DESTDIR'}--WWSCONFIG--";
my $sympa_conf = "$ENV{'DESTDIR'}--CONFIG--";
my $somechange = 0;

## parameters that can be edited with this script

## Only parameters listes in @params will be saved

## This defines the parameters to be edited :
##   title  : Title for the group of parameters following
##   name   : Name of the parameter
##   file   : Conf file where the param. is defined
##   edit   : 1|0
##   query  : Description of the parameter
##   advice : Additionnal advice concerning the parameter

my @params = ({'title' => 'Directories and file location'},
	      {'name' => 'home',
	       'default' => '--EXPL_DIR--',
	       'query' => 'Directory containing mailing lists subdirectories',
	       'file' => 'sympa.conf','edit' => '1',
               'advice' =>''},

	      {'name' => 'etc',
	       'default' => '--ETCDIR--',
	       'query' => 'Directory for configuration files ; it also contains scenari/ and templates/ directories',
	       'file' => 'sympa.conf'},

	      {'name' => 'pidfile',
	       'default' => '--PIDDIR--/sympa.pid',
	       'query' => 'File containing Sympa PID while running.',
	       'file' => 'sympa.conf',
               'advice' =>'Sympa also locks this file to ensure that it is not running more than once. Caution : user sympa need to write access without special privilegee.'},
	      
	      {'name' => 'umask',
	       'default' => '027',
	       'query' => 'Umask used for file creation by Sympa',
	       'file' => 'sympa.conf'},

	      {'name' => 'archived_pidfile',
	       'query' => 'File containing archived PID while running.',
	       'file' => 'wwsympa.conf',
               'advice' =>''},
	      
	      {'name' => 'bounced_pidfile',
	       'query' => 'File containing bounced PID while running.',
	       'file' => 'wwsympa.conf',
               'advice' =>''},
	      
	      {'name' => 'task_manager_pidfile',
	       'query' => 'File containing task_manager PID while running.',
	       'file' => 'wwsympa.conf',
               'advice' =>''},

	      {'name' => 'arc_path',
	       'default' => '--DIR--/arc',
	       'query' => 'Where to store HTML archives',
	       'file' => 'wwsympa.conf','edit' => '1',
               'advice' =>'Better if not in a critical partition'},
	      
	      {'name' => 'bounce_path',
	       'default' => '--DIR--/bounce',
	       'query' => 'Where to store bounces',
	       'file' => 'wwsympa.conf',
               'advice' =>'Better if not in a critical partition'},
	      
	      {'name' => 'localedir',
	       'default' => '--LOCALEDIR--',
	       'query' => 'Directory containing available NLS catalogues (Message internationalization)',
	       'file' => 'sympa.conf',
	       'advice' =>''},
	      
	      {'name' => 'spool',
	       'default' => '--SPOOLDIR--',
	       'query' => 'The main spool containing various specialized spools',
	       'file' => 'sympa.conf',
	       'advice' => 'All spool are created at runtime by sympa.pl'},

	      {'name' => 'queue',
	       'default' => '--SPOOLDIR--/msg',
	       'query' => 'Incoming spool',
	       'file' => 'sympa.conf',
	       'advice' =>''},
	      
	      {'name' => 'queuebounce',
	       'default' => '--SPOOLDIR--/bounce',
	       'query' => 'Bounce incoming spool',
	       'file' => 'sympa.conf',
	       'advice' =>''},

	      {'name' => 'static_content_path',
	       'default' => '--DIR--/static_content',
	       'query' => 'The directory where Sympa stores static contents (CSS, members pictures, documentation) directly delivered by Apache',
	       'file' => 'sympa.conf',
	       'advice' =>''},	      
	      
	      {'name' => 'static_content_url',
	       'default' => '/static-sympa',
	       'query' => 'The URL mapped with the static_content_path directory defined above',
	       'file' => 'sympa.conf',
	       'advice' =>''},	      

	      {'title' => 'Syslog'},

	      {'name' => 'syslog',
	       'default' => 'LOCAL1',
	       'query' => 'The syslog facility for sympa',
	       'file' => 'sympa.conf','edit' => '1',
	       'advice' =>'Do not forget to edit syslog.conf'},
	      
	      {'name' => 'log_socket_type',
	       'default' => '--LOG_SOCKET_TYPE--',
	       'query' => 'Communication mode with syslogd is either unix (via Unix sockets) or inet (use of UDP)',
	       'file' => 'sympa.conf'},
	      
	      {'name' => 'log_facility',
	       'query' => 'The syslog facility for wwsympa, archived and bounced',
	       'file' => 'wwsympa.conf','edit' => '1',
	       'advice' =>'default is to use previously defined sympa log facility'},
	      
	      {'name' => 'log_level',
	       'default' => '0',
	       'query' => 'Log intensity',
	       'file' => 'sympa.conf',
	       'advice' =>'0 : normal, 2,3,4 for debug'},
	      
	      {'title' => 'General definition'},
	      
	      {'name' => 'domain',
	       'default' => '--HOST--',
	       'query' => 'Main robot hostname',
	       'file' => 'sympa.conf',
	       'advice' =>''},
	      
	      {'name' => 'listmaster',
	       'default' => 'your_email_address@--HOST--',
	       'query' => 'Listmasters email list comma separated',
	       'file' => 'sympa.conf','edit' => '1',
	       'advice' =>'Sympa will associate listmaster privileges to these email addresses (mail and web interfaces). Some error reports may also be sent to these addresses.'},
	      
	      {'name' => 'email',
	       'default' => 'sympa',
	       'query' => 'Local part of sympa email adresse',
	       'file' => 'sympa.conf',
	       'advice' =>"Effective address will be \[EMAIL\]@\[HOST\]"},

	      {'name' => 'create_list',
	       'default' => 'public_listmaster',
	       'query' => 'Who is able to create lists',
	       'file' => 'sympa.conf','edit' => '1',
	       'advice' =>'This parameter is a scenario, check sympa documentation about scenarios if you want to define one'},

	      {'title' => 'Tuning'},
	      	      

	      {'name' => 'cache_list_config',
	       'default' => 'none',
	       'query' => 'Use of binary version of the list config structure on disk: none | binary_file',
	       'file' => 'sympa.conf','edit' => '1',
	       'advice' =>'Set this parameter to "binary_file" if you manage a big amount of lists (1000+) ; it should make the web interface startup faster'},

	      {'name' => 'sympa_priority',
	       'query' => 'Sympa commands priority',
	       'file' => 'sympa.conf',
	       'advice' =>''},
	      
	      {'name' => 'default_list_priority',
	       'query' => 'Default priority for list messages',
	       'file' => 'sympa.conf',
	       'advice' =>''},
	       
	      {'name' => 'cookie',
	       'default' => '--COOKIE--',
	       'query' => 'Secret used by Sympa to make MD5 fingerprint in web cookies secure',
	       'file' => 'sympa.conf',
	       'advice' =>'Should not be changed ! May invalid all user password'},

	      {'name' => 'password_case',
	       'query' => 'Password case (insensitive | sensitive)',
	       'file' => 'wwsympa.conf',
	       'advice' =>'Should not be changed ! May invalid all user password'},

	      {'name' => 'cookie_expire',
	       'query' => 'HTTP cookies lifetime',
	       'file' => 'wwsympa.conf',
	       'advice' =>''},

	      {'name' => 'cookie_domain',
	       'query' => 'HTTP cookies validity domain',
	       'file' => 'wwsympa.conf',
	       'advice' =>''},

	      {'name' => 'max_size',
	       'query' => 'The default maximum size (in bytes) for messages (can be re-defined for each list)',
	       'file' => 'sympa.conf','edit' => '1',
	       'advice' =>''},

	      {'name' => 'use_blacklist',
	       'query' => 'comma separated list of operation for which blacklist filter is applyed', 
               'default' => 'send,create_list',
	       'file' => 'sympa.conf','edit' => '1',
	       'advice' =>'set this parameter to "none" hidde blacklist feature'},

	      {'name'  => 'rfc2369_header_fields',
	       'query' => 'Specify which rfc2369 mailing list headers to add',
	       'file' => 'sympa.conf',
	       'advice' => '' },


	      {'name'  => 'remove_headers',
	       'query' => 'Specify header fields to be removed before message distribution',
	       'file' => 'sympa.conf',
	       'advice' => '' },

	      {'title' => 'Internationalization'},

	      {'name' => 'lang',
	       'default' => 'en_US',
	       'query' => 'Default lang (ca | cs | de | el | es | et_EE | en_US | fr | hu | it | ja_JP | ko | nl | oc | pt_BR | ru | sv | tr | zh_CN | zh_TW)',
	       'file' => 'sympa.conf','edit' => '1',
	       'advice' =>'This is the default language used by Sympa'},

	      {'name' => 'supported_lang',
	       'default' => 'ca,cs,de,el,es,et_EE,en_US,fr,hu,it,ja_JP,ko,nl,oc,pt_BR,ru,sv,tr,zh_CN,zh_TW',
	       'query' => 'Supported languages',
	       'file' => 'sympa.conf','edit' => '1',
	       'advice' =>'This is the set of language that will be proposed to your users for the Sympa GUI. Don\'t select a language if you don\'t have the proper locale packages installed.'},

	      {'title' => 'Errors management'},

	      {'name'  => 'bounce_warn_rate',
	       'sample' => '20',
	       'query' => 'Bouncing email rate for warn list owner',
	       'file' => 'sympa.conf','edit' => '1',
	       'advice' => '' },

	      {'name'  => 'bounce_halt_rate',
	       'sample' => '50',
	       'query' => 'Bouncing email rate for halt the list (not implemented)',
	       'file' => 'sympa.conf',
	       'advice' => 'Not yet used in current version, Default is 50' },


	      {'name'  => 'expire_bounce_task',
	       'sample' => 'daily',
	       'query' => 'Task name for expiration of old bounces',
	       'file' => 'sympa.conf',
	       'advice' => '' },
	      
	      {'name'  => 'welcome_return_path',
	       'sample' => 'unique',
	       'query' => 'Welcome message return-path',
	       'file' => 'sympa.conf',
	       'advice' => 'If set to unique, new subcriber is removed if welcome message bounce' },
	       
	      {'name'  => 'remind_return_path',
	       'query' => 'Remind message return-path',
	       'file' => 'sympa.conf',
	       'advice' => 'If set to unique, subcriber is removed if remind message bounce, use with care' },

	      {'title' => 'MTA related'},

	      {'name' => 'sendmail',
	       'default' => '/usr/sbin/sendmail',
	       'query' => 'Path to the MTA (sendmail, postfix, exim or qmail)',
	       'file' => 'sympa.conf','edit' => '1',
	       'advice' => "should point to a sendmail-compatible binary (eg: a binary named \'sendmail\' is distributed with Postfix)"},

	      {'name' => 'nrcpt',
	       'default' => '25',
	       'query' => 'Maximum number of recipients per call to Sendmail. The nrcpt_by_domain.conf file allows a different tuning per destination domain.',
	       'file' => 'sympa.conf',
	       'advice' =>''},

	      {'name' => 'avg',
	       'default' => '10',
	       'query' => 'Max. number of different domains per call to Sendmail',
	       'file' => 'sympa.conf',
	       'advice' =>''},


	      {'name' => 'maxsmtp',
	       'default' => '40',
	       'query' => 'Max. number of Sendmail processes (launched by Sympa) running simultaneously',
	       'file' => 'sympa.conf',
	       'advice' =>'Proposed value is quite low, you can rise it up to 100, 200 or even 300 with powerfull systems.'},

	      {'title' => 'Pluggin'},

	      {'name' => 'antivirus_path',
	       'sample' => '/usr/local/uvscan/uvscan',
	       'query' => 'Path to the antivirus scanner engine',
	       'file' => 'sympa.conf','edit' => '1',
	       'advice' =>'supported antivirus : McAfee/uvscan, Fsecure/fsav, Sophos, AVP and Trend Micro/VirusWall'},


	      {'name' => 'antivirus_args',
	       'sample' => '--secure --summary --dat /usr/local/uvscan',
	       'query' => 'Antivirus pluggin command argument',
	       'file' => 'sympa.conf','edit' => '1',
	       'advice' =>''},

              {'name' => 'mhonarc',
	       'default' => '/usr/bin/mhonarc',
	       'query' => 'Path to MhOnarc mail2html pluggin',
	       'file' => 'wwsympa.conf','edit' => '1',
	       'advice' =>'This is required for HTML mail archiving'},

	      {'title' => 'S/MIME pluggin'},
	      {'name' => 'openssl',
	       'sample' => '--OPENSSL--',
	       'query' => 'Path to OpenSSL',
	       'file' => 'sympa.conf','edit' => '1',
	       'advice' =>'Sympa knowns S/MIME if openssl is installed'},

	      {'name' => 'capath',
	       'sample' => '--ETCDIR--/ssl.crt',
	       'query' => 'The directory path use by OpenSSL for trusted CA certificates',
	       'file' => 'sympa.conf','edit' => '1'},

	      {'name' => 'cafile',
	       'sample' => '/usr/local/apache/conf/ssl.crt/ca-bundle.crt',
	       'query' => ' This parameter sets the all-in-one file where you can assemble the Certificates of Certification Authorities (CA)',
	       'file' => 'sympa.conf','edit' => '1'},

	      {'name' => 'ssl_cert_dir',
	       'default' => '--SSLCERTDIR--',
	       'query' => 'User CERTs directory',
	       'file' => 'sympa.conf'},

	      {'name' => 'key_passwd',
	       'sample' => 'your_password',
	       'query' => 'Password used to crypt lists private keys',
	       'file' => 'sympa.conf','edit' => '1',
	       'advice' =>''},

	      {'title' => 'Database'},
	      
	      {'name' => 'db_type',
	       'default' => 'mysql',
	       'query' => 'Database type (mysql | Pg | Oracle | Sybase | SQLite)',
	       'file' => 'sympa.conf','edit' => '1',
	       'advice' =>'be carefull to the case'},

	      {'name' => 'db_name',
	       'default' => 'sympa',
	       'query' => 'Name of the database',
	       'file' => 'sympa.conf','edit' => '1',
	       'advice' =>'with SQLite, the name of the DB corresponds to the DB file'},

	      {'name' => 'db_host',
	       'sample' => 'localhost',
	       'query' => 'The host hosting your sympa database',
	       'file' => 'sympa.conf','edit' => '1',
	       'advice' =>''},

	      {'name' => 'db_port',
	       'query' => 'The database port',
	       'file' => 'sympa.conf',
	       'advice' =>''},

	      {'name' => 'db_user',
	       'sample' => 'sympa',
	       'query' => 'Database user for connexion',
	       'file' => 'sympa.conf','edit' => '1',
	       'advice' =>''},
	      
	      {'name' => 'db_passwd',
	       'sample' => 'your_passwd',
	       'query' => 'Database password (associated to the db_user)',
	       'file' => 'sympa.conf','edit' => '1',
	       'advice' =>'What ever you use a password or not, you must protect the SQL server (is it a not a public internet service ?)'},

	      {'name' => 'db_env',
	       'query' => 'Environment variables setting for database',
	       'file' => 'sympa.conf',
	       'advice' =>'This is usefull for definign ORACLE_HOME '},

	      {'name'  => 'db_additional_user_fields',
	       'sample' => 'age,address',
	       'query' => 'Database private extention to user table',
	       'file' => 'sympa.conf',
	       'advice' => 'You need to extend the database format with these fields' },

	      {'name'  => 'db_additional_subscriber_fields',
	       'sample' => 'billing_delay,subscription_expiration',
	       'query' => 'Database private extention to subscriber table',
	       'file' => 'sympa.conf',
	       'advice' => 'You need to extend the database format with these fields' },

	      {'title' => 'Web interface'},

	      {'name' => 'use_fast_cgi',
	       'default' => '1',
	       'query' => 'Is fast_cgi module for Apache (or Roxen) installed (0 | 1)',
	       'file' => 'wwsympa.conf','edit' => '1',
	       'advice' =>'This module provide much faster web interface'},

	      {'name' => 'wwsympa_url',
	       'default' => 'http://--HOST--/sympa',
	       'query' => "Sympa\'s main page URL",
	       'file' => 'sympa.conf','edit' => '1',
	       'advice' =>''},

	      {'name' => 'title',
	       'default' => 'Mailing lists service',
	       'query' => 'Title of main web page',
	       'file' => 'wwsympa.conf','edit' => '1',
	       'advice' =>''},

	      {'name' => 'default_home',
	       'sample' => 'lists',
	       'query' => 'Main page type (lists | home)',
	       'file' => 'wwsympa.conf','edit' => '1',
	       'advice' =>''},

	       {'name' => 'default_shared_quota',
	       'query' => 'Default disk quota for shared repository',
	       'file' => 'sympa.conf','edit' => '1',
	       'advice' =>''},

	       {'name' => 'antispam_tag_header_name',
	       'query' => 'If a spam filter (like spamassassin or j-chkmail) add a smtp headers to tag spams, name of this header (example X-Spam-Status)',
	       'file' => 'sympa.conf','edit' => '1',
	       'advice' =>''},

	       {'name' => 'antispam_tag_header_spam_regexp',
	       'query' => 'The regexp applied on this header to verify message is a spam (example \s*Yes)',
	       'file' => 'sympa.conf','edit' => '1',
	       'advice' =>''},

	       {'name' => 'antispam_tag_header_ham_regexp',
	       'query' => 'The regexp applied on this header to verify message is NOT a spam (example \s*No)',
	       'file' => 'sympa.conf','edit' => '1',
	       'advice' =>''},


	      );


if ($ARGV[0] eq '-c') {
    my $file = $ARGV[1];

    my $conf;
    if ($file eq 'sympa.conf') {
	$conf = $sympa_conf;
    }elsif ($file eq 'wwsympa.conf') {
	$conf = $wwsympa_conf;
    }else {
	print STDERR "$file is not a valid argument\n";
	print STDERR "Usage: $0 -c sympa.conf | wwsympa.conf\n";
	exit 1;
    }
    
    if (-f $conf) {
	print STDERR "$conf file already exists, exiting\n";
	exit 1;
    }
    
    unless (open (NEWF,"> $conf")){
	die "Unable to open $conf : $!";
    };
    
    if ($file eq 'sympa.conf') {
	print NEWF "## Configuration file for Sympa\n## many parameters are optional (defined in src/Conf.pm)\n## refer to the documentation for a detailed list of parameters\n\n";
    }elsif ($file eq 'wwsympa.conf') {

    }
    
    foreach my $i (0..$#params) {
	
	if ($params[$i]->{'title'}) {
	    printf NEWF "###\\\\\\\\ %s ////###\n\n", $params[$i]->{'title'};
		next;
	}
	
	next unless ($params[$i]->{'file'} eq $file);
	
	next unless ((defined $params[$i]->{'default'}) ||
		     (defined $params[$i]->{'sample'}));
	
	printf NEWF "## %s\n", $params[$i]->{'query'}
	if (defined $params[$i]->{'query'});
	
	printf NEWF "## %s\n", $params[$i]->{'advice'}
	if ($params[$i]->{'advice'});
	
	printf NEWF "%s\t%s\n\n", $params[$i]->{'name'}, $params[$i]->{'default'}
	if (defined $params[$i]->{'default'});
	
	printf NEWF "#%s\t%s\n\n", $params[$i]->{'name'}, $params[$i]->{'sample'}
	if (defined $params[$i]->{'sample'});
    }

    close NEWF;
    print STDERR "$conf file has been created\n";

    exit 0;
}

### This is the normal behavior of the wizard
### ie edition of existing sympa.conf and wwsympa.conf

## Load config 
unless ($wwsconf = &wwslib::load_config($wwsympa_conf)) {
    die("Unable to load config file $wwsympa_conf");
}

## Load sympa config
unless (&Conf::load( $sympa_conf )) {
    die('Unable to load sympa config file $sympa_conf');
}

my (@new_wwsympa_conf, @new_sympa_conf);

## Edition mode
foreach my $i (0..$#params) {
    my $desc;

    if ($params[$i]->{'title'}) {
	my $title = $params[$i]->{'title'};
	printf "\n\n** $title **\n";

	## write to conf file
	push @new_wwsympa_conf, sprintf "###\\\\\\\\ %s ////###\n\n", $params[$i]->{'title'};
	push @new_sympa_conf, sprintf "###\\\\\\\\ %s ////###\n\n", $params[$i]->{'title'};

	next;
    }    

    my $file = $params[$i]->{'file'} ;
    my $name = $params[$i]->{'name'} ; 
    my $query = $params[$i]->{'query'} ;
    my $advice = $params[$i]->{'advice'} ;
    my $sample = $params[$i]->{'sample'} ;
    my $current_value ;
    if ($file eq 'wwsympa.conf') {	
	$current_value = $wwsconf->{$name} ;
    }elsif ($file eq 'sympa.conf') {
	$current_value = $Conf::Conf{$name}; 
    }else {
	printf STDERR "incorrect definition of $name\n";
    }
    my $new_value;
    if ($params[$i]->{'edit'} eq '1') {
	printf "... $advice\n" unless ($advice eq '') ;
	printf "$name: $query \[$current_value\] : ";
	$new_value = <STDIN> ;
	chomp $new_value;
    }
    if ($new_value eq '') {
	$new_value = $current_value;
    }

    ## SKip empty parameters
    next if (($new_value eq '') &&
	     ! $sample);

    ## param is an ARRAY
    if (ref($new_value) eq 'ARRAY') {
	$new_value = join ',',@{$new_value};
    }

    if ($file eq 'wwsympa.conf') {
	$desc = \@new_wwsympa_conf;
    }elsif ($file eq 'sympa.conf') {
	$desc = \@new_sympa_conf;
    }else{
	printf STDERR "incorrect parameter $name definition \n";
    }

    if ($new_value eq '') {
	next unless $sample;
	
	push @{$desc}, sprintf "## $query\n";
	
	unless ($advice eq '') {
	    push @{$desc}, sprintf "## $advice\n";
	}
	
	push @{$desc}, sprintf "# $name\t$sample\n\n";
    }else {
	push @{$desc}, sprintf "## $query\n";
	unless ($advice eq '') {
	    push @{$desc}, sprintf "## $advice\n";
	}
	
	if ($current_value ne $new_value) {
	    push @{$desc}, sprintf "# was $name $current_value\n";
	    $somechange = 1;
	}
    
	push @{$desc}, sprintf "$name\t$new_value\n\n";
    }
}

if ($somechange) {

    my $date = &POSIX::strftime("%d.%b.%Y-%H.%M.%S", localtime(time));

    ## Keep old config files
    unless (rename $wwsympa_conf, $wwsympa_conf.'.'.$date) {
	warn "Unable to rename $wwsympa_conf : $!";
    }

    unless (rename $sympa_conf, $sympa_conf.'.'.$date) {
	warn "Unable to rename $sympa_conf : $!";
    }

    ## Write new config files
    unless (open (WWSYMPA,"> $wwsympa_conf")){
	die "unable to open $wwsympa_conf : $!";
    };

    unless (open (SYMPA,"> $sympa_conf")){
	die "unable to open $sympa_conf : $!";
    };

    print SYMPA @new_sympa_conf;
    print WWSYMPA @new_wwsympa_conf;

    close SYMPA;
    close WWSYMPA;

    printf "$sympa_conf and $wwsympa_conf have been updated.\nPrevious versions have been saved as $sympa_conf.$date and $wwsympa_conf.$date\n";
}
    


