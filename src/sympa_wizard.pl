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
use Conf;

## Configuration

my $new_wws_conf = '/tmp/wwsympa.conf';
my $new_sympa_conf = '/tmp/sympa.conf';

my $wwsconf = {};

## Change to your wwsympa.conf location
my $conf_file = '--WWSCONFIG--';
my $sympa_conf_file = '--CONFIG--';
my $somechange = 0;

## paraméters that can be edited with this script
my @params = ({'title' => 'Directories and file location'},
	      {'name' => 'home',
	       'query' => 'the home directory for sympa',
	       'file' => 'sympa.conf','edit' => '1',
               'advice' =>''},

	      {'name' => 'pidfile',
	       'query' => 'File containing Sympa PID while running.',
	       'file' => 'sympa.conf','edit' => '0',
               'advice' =>''},
	      
	      {'name' => 'archives_pidfile',
	       'query' => 'File containing archived PID while running.',
	       'file' => 'wwsympa.conf','edit' => '0',
               'advice' =>''},
	      
	      {'name' => 'bounced_pidfile',
	       'query' => 'File containing bounced PID while running.',
	       'file' => 'wwsympa.conf','edit' => '0',
               'advice' =>''},
	      
	      {'name' => 'arc_path',
	       'query' => 'Where to store html archives',
	       'file' => 'wwsympa.conf','edit' => '1',
               'advice' =>'Better if not in a critical partition'},
	      
	      {'name' => 'bounce_path',
	       'query' => 'Where to store bounces',
	       'file' => 'wwsympa.conf','edit' => '0',
               'advice' =>'Better if not in a critical partition'},
	      
	      {'name' => 'msgcat',
	       'query' => 'Directory containig available NLS catalogues',
	       'file' => 'sympa.conf','edit' => '0',
	       'advice' =>''},
	      
	      {'name' => 'queue',
	       'query' => 'Incomming spool',
	       'file' => 'sympa.conf','edit' => '0',
	       'advice' =>''},
	      
	      {'name' => 'queuebounce',
	       'query' => 'Bounce incomming spool',
	       'file' => 'sympa.conf','edit' => '0',
	       'advice' =>''},
	      
	      {'title' => 'Syslog'},

	      {'name' => 'syslog',
	       'query' => 'Specify the syslog facility for sympa',
	       'file' => 'sympa.conf','edit' => '1',
	       'advice' =>'Do not forget to edit syslog.conf'},
	      
	      {'name' => 'log_facility',
	       'query' => 'Specify the syslog facility for wwsympa',
	       'file' => 'wwsympa.conf','edit' => '1',
	       'advice' =>''},
	      
	      {'name' => 'log_socket_type',
	       'query' => 'Specify the syslog socket unix|inet',
	       'file' => 'wwsympa.conf','edit' => '0',
	       'advice' =>''},
	      
	      {'name' => 'log_level',
	       'query' => 'Log intensity',
	       'file' => 'wwsympa.conf','edit' => '0',
	       'advice' =>'0 : normal, 2,3,4 for debug'},
	      
	      {'title' => 'General definition'},
	      
	      {'name' => 'sleep',
	       'query' => 'Main sympa loop sleep',
	       'file' => 'sympa.conf','edit' => '0',
	       'advice' =>''},
	      
	      {'name' => 'sympa_priority',
	       'query' => 'Sympa commands priority',
	       'file' => 'sympa.conf','edit' => '0',
	       'advice' =>''},
	      
	      {'name' => 'default_list_priority',
	       'query' => 'Default priority for mist message',
	       'file' => 'sympa.conf','edit' => '0',
	       'advice' =>''},
	       
	      {'name' => 'umask',
	       'query' => 'Umask used for file creation by Sympa',
	       'file' => 'sympa.conf','edit' => '0',
	       'advice' =>''},
	      
	      {'name' => 'cookie',
	       'query' => 'Secret used by Sympa to make MD5 fingerprint in web cookies secure',
	       'file' => 'sympa.conf','edit' => '0',
	       'advice' =>'Should not be changed ! May invalid all user password'},

	      {'name' => 'password_case',
	       'query' => 'password case : insensitive|sensitive',
	       'file' => 'wwsympa.conf','edit' => '0',
	       'advice' =>'Should not be changed ! May invalid all user password'},

	      {'name' => 'cookie_expire',
	       'query' => 'cookies life time',
	       'file' => 'wwsympa.conf','edit' => '0',
	       'advice' =>''},

	      {'name' => 'cookie_domain',
	       'query' => 'cookies validity domain',
	       'file' => 'wwsympa.conf','edit' => '0',
	       'advice' =>''},

	      {'name' => 'listmaster',
	       'query' => 'listmasters email list colon separated',
	       'file' => 'sympa.conf','edit' => '1',
	       'advice' =>''},

	      {'name' => 'max_size',
	       'query' => 'the default maximum size for messages (can be re-defined for each list)',
	       'file' => 'sympa.conf','edit' => '1',
	       'advice' =>''},


	      {'name' => 'host',
	       'query' => 'Name of the host',
	       'file' => 'sympa.conf','edit' => '0',
	       'advice' =>''},

	      {'name' => 'email',
	       'query' => 'Local part of sympa email adresse',
	       'file' => 'sympa.conf','edit' => '0',
	       'advice' =>'Effective address will be \[EMAIL\]@\[HOST\]'},


	      {'name' => 'lang',
	       'query' => 'Default lang',
	       'file' => 'sympa.conf','edit' => '1',
	       'advice' =>''},

	      {'name' => 'create_list',
	       'query' => 'Who is able to create lists',
	       'file' => 'sympa.conf','edit' => '1',
	       'advice' =>'This parameter is a scenario, check sympa documentation about scenarii if you want to define one'},

	      {'name'  => 'rfc2369_header_fields',
	       'query' => 'Specify which rfc2369 mailing list headers to add',
	       'file' => 'sympa.conf','edit' => '0',
	       'advice' => '' },


	      {'name'  => 'remove_headers',
	       'query' => 'Specify headers to remove before distribute message',
	       'file' => 'sympa.conf','edit' => '0',
	       'advice' => '' },

	      {'title' => 'Errors management'},

	      {'name'  => 'bounce_warn_rate',
	       'query' => 'bouncing email rate for warn list owner',
	       'file' => 'sympa.conf','edit' => '1',
	       'comment' => 'bounce_warn_rate 20',
	       'advice' => '' },

	      {'name'  => 'bounce_halt_rate',
	       'query' => 'bouncing email rate for halt the list',
	       'file' => 'sympa.conf','edit' => '0',
	       'comment' => 'bounce_halt_rate 50',
	       'advice' => 'Not yet used in current version, Default is 50' },


	      {'name'  => 'expire_bounce',
	       'query' => 'task name for expiration of old bounces',
	       'file' => 'sympa.conf','edit' => '0',
	       'comment' => 'expire_bounce daily',
	       'advice' => '' },
	      
	      {'name'  => 'welcome_return_path',
	       'query' => 'welcome message return-path',
	       'file' => 'sympa.conf','edit' => '0',
	       'comment' => 'welcome_return_path unique',
	       'advice' => 'If set to unique, new subcriber is removed if welcome message bounce' },
	       
	      {'name'  => 'remind_return_path',
	       'query' => 'remind message return-path',
	       'file' => 'sympa.conf','edit' => '0',
	       'advice' => 'If set to unique, subcriber is removed if remind message bounce, use with care' },

	      {'title' => 'MTA related'},

	      {'name' => 'sendmail',
	       'query' => 'Path to the MTA (sendmail, postfix, exim or qmail)',
	       'file' => 'sympa.conf','edit' => '1',
	       'advice' =>''},

	      {'name' => 'nrcpt',
	       'query' => 'Maximum number of recipients per call to Sendmail',
	       'file' => 'sympa.conf','edit' => '0',
	       'comment' => 'nrcpt 20',
	       'advice' =>''},

	      {'name' => 'avg',
	       'query' => 'Max. number of different domains perl call to Sendmail',
	       'file' => 'sympa.conf','edit' => '0',
	       'comment' => 'maxsmtp 10',
	       'advice' =>''},


	      {'name' => 'maxsmtp',
	       'query' => 'Max. number of Sendmail processes (launched by Sympa) running simultaneously',
	       'file' => 'sympa.conf','edit' => '0',
	       'comment' => 'maxsmtp 60',
	       'advice' =>'Proposed value is quite low, you can rise it up to 100, 200 or even 300 with powerfull systems.'},

	       {'name' => 'alias_manager',
	       'query' => 'path to program managing alias',
	       'file' => 'sympa.conf','edit' => '0',
		'comment' => 'alias_manager /home/sympa/bin/alias_manager.pl',
	       'advice' =>'May be you have to look at the one proposed by Sympa authors and adapt it to your system'},

	       {'title' => 'pluging'},

	      {'name' => 'antivirus_path',
	       'query' => 'Path to the antivirus scanner engine',
	       'file' => 'sympa.conf','edit' => '1',
	       'advice' =>'supported antivirus : McAfee/uvscan, Fsecure/fsav, Sophos, AVP and Trend Micro/VirusWall'},


	      {'name' => 'antivirus_args',
	       'query' => 'Antivirus plugging command argument',
	       'file' => 'sympa.conf','edit' => '1',
	       'advice' =>''},

              {'name' => 'mhonarc',
	       'query' => 'Path to MhOnarc mai2html plugging',
	       'file' => 'wwsympa.conf','edit' => '1',
	       'advice' =>''},

	      {'title' => 'S/MIME pluggins'},
	      {'name' => 'openssl',
	       'query' => 'Path to openssl',
	       'file' => 'sympa.conf','edit' => '1',
	       'advice' =>'Sympa knowns S/MIME if openssl is installed'},

	      {'name' => 'trusted_ca_options',
	       'query' => 'the OpenSSL option string to qualify trusted CAs',
	       'file' => 'sympa.conf','edit' => '1',
	       'advice' =>'This parameter is used by sympa when sending some URL by mail'},
	      {'name' => 'key_passwd',
	       'query' => 'password used to crypt lists private keys',
	       'file' => 'sympa.conf','edit' => '1',
	       'advice' =>''},

	      {'title' => 'Database'},
	      
	      {'name' => 'db_type',
	       'query' => 'data base type (mysql,Pg,Oracle,Sybase)',
	       'file' => 'sympa.conf','edit' => '1',
	       'advice' =>'take care with case'},

	      {'name' => 'db_name',
	       'query' => 'name of the database',
	       'file' => 'sympa.conf','edit' => '1',
	       'advice' =>''},

	      {'name' => 'db_host',
	       'query' => 'the host hosting your sympa database',
	       'file' => 'sympa.conf','edit' => '1',
	       'advice' =>''},

	      {'name' => 'db_port',
	       'query' => 'SQL database port',
	       'file' => 'sympa.conf','edit' => '0',
	       'advice' =>''},

	      {'name' => 'db_user',
	       'query' => 'data base user',
	       'file' => 'sympa.conf','edit' => '1',
	       'advice' =>''},
	      
	      {'name' => 'db_passwd',
	       'query' => 'data base passord',
	       'file' => 'sympa.conf','edit' => '1',
	       'advice' =>'What ever you use a password or not, you must protect the SQL server (is it a not a public internet service ?)'},

	      {'name' => 'db_env',
	       'query' => 'Environement variables setting for database (oracle)',
	       'file' => 'sympa.conf','edit' => '0',
	       'advice' =>''},

	      {'name'  => 'db_additional_subscriber_fields',
	       'query' => 'database private extention to subscriber table',
	       'file' => 'sympa.conf','edit' => '0',
	       'comment' => 'db_additional_subscriber_fields billing_delay,subscription_expiration',
	       'advice' => 'First, you must defined it in your database' },


	      {'title' => 'Web interface'},
	      {'name' => 'use_fast_cgi',
	       'query' => 'is fast_cgi module for Apache (or Roxen) installed (0|1)',
	       'file' => 'wwsympa.conf','edit' => '1',
	       'advice' =>'This module provide much more faster web interface'},

	      {'name' => 'wwsympa_url',
	       'query' => 'Sympa main page URL',
	       'file' => 'wwsympa.conf','edit' => '1',
	       'advice' =>''},

	      {'name' => 'title',
	       'query' => 'title of main web page',
	       'file' => 'wwsympa.conf','edit' => '1',
	       'advice' =>''},

	      {'name' => 'default_home',
	       'query' => 'main page type (lists|home)',
	       'file' => 'wwsympa.conf','edit' => '1',
	       'advice' =>''},

	       {'name' => 'default_shared_quota',
	       'query' => 'Default disk quota for shared repository',
	       'file' => 'wwsympa.conf','edit' => '1',
	       'advice' =>''},

	      {'name' => 'dark_color',
	       'query' => 'web interface color : dark',
	       'file' => 'sympa.conf','edit' => '1',
	       'advice' =>''},
	      
	      {'name' => 'selected_color',
	       'query' => 'web interface color : selected_color',
	       'file' => 'sympa.conf','edit' => '1',
	       'advice' =>''},
	      
	      {'name' => 'light_color',
	       'query' => 'web interface color : light',
	       'file' => 'sympa.conf','edit' => '1',
	       'advice' =>''},
	      
	      {'name' => 'shaded_color',
	       'query' => 'web_interface color : shaded',
	       'file' => 'sympa.conf','edit' => '1',
	       'advice' =>''},
	      
	      {'name' => 'bg_color',
	       'query' => 'web_interface color : background',
	       'file' => 'sympa.conf','edit' => '1',
	       'advice' =>''},
	      
	      );


## Load config 
unless ($wwsconf = &wwslib::load_config($conf_file)) {
    &fatal_err('Unable to load config file %s', $conf_file);
}

#printf "Conf WWS: %s\n", join(',', %{$wwsconf});

## Load sympa config
unless (&Conf::load( $sympa_conf_file )) {
    &fatal_err('Unable to load sympa config file %s', $sympa_conf_file);
}

unless (open (WWSYMPA,"> $new_wws_conf")){
    printf STDERR "unable to open $new_wws_conf, exiting";
    exit;
};

unless (open (SYMPA,"> $new_sympa_conf")){
    printf STDERR "unable to open $new_sympa_conf, exiting";
    exit;
};

foreach my $i (0..$#params) {
    if ($params[$i]->{'title'}) {
	my $title = $params[$i]->{'title'};
	printf "\n\n$title\n";
	next;
    }
    my $file = $params[$i]->{'file'} ;
    my $name = $params[$i]->{'name'} ; 
    my $query = $params[$i]->{'query'} ;
    my $advice = $params[$i]->{'advice'} ;
    my $comment = $params[$i]->{'comment'} ;
    my $current_value ;
    if ($file eq 'wwsympa.conf') {	
	$current_value = $wwsconf->{$name} ;
    }elsif ($file eq 'sympa.conf') {
	$current_value = $Conf{$name}; 
    }else {
	printf STDERR "incorrect definition of $name\n";
    }
    my $new_value;
    if ($params[$i]->{'edit'} eq '1') {
	printf "$advice\n" unless ($advice eq '') ;
	printf "Parameter $name: $query \[$current_value\] : ";
	$new_value = <STDIN> ;
	chomp $new_value;
    }
    if ($new_value eq '') {
	$new_value = $current_value;
    }
    my $desc ;
    if ($file eq 'wwsympa.conf') {
	$desc = \*WWSYMPA;
    }elsif ($file eq 'sympa.conf') {
	$desc = \*SYMPA;
    }else{
	printf STDERR "incorrect parameter $name definition \n";
    }
    printf $desc "# $query\n";
    unless ($advice eq '') {
	printf $desc "# $advice\n";
    }
    
    if ($current_value ne $new_value) {
	printf $desc "# was $name $current_value\n";
	$somechange = 1;
    }elsif($comment ne '') {
	printf $desc "# $comment\n";
    }
    printf $desc "$name $new_value\n\n";
}

close SYMPA;
close WWSYMPA;

if ($somechange ne '0') {

    open (IN, "$conf_file");
    my $date = &POSIX::strftime("%d.%b.%Y-%H.%M.%S", localtime(time));
    unless (open (OUT, ">$conf_file.$date")) {
	printf STDERR "unable to rename $conf_file, aborting without saving change\n";
	exit;
    }
    while (<IN>){printf OUT $_;}
    close IN;
    close OUT;

    open (IN, "$sympa_conf_file");
    unless (open (OUT, ">sympa_conf_file.$date")) {
	printf STDERR "unable to rename $sympa_conf_file, aborting without saving change\n";
	exit;
    }
    while (<IN>){printf OUT $_;}
    close IN;
    close OUT;

    open (IN, "$new_sympa_conf");
    unless (open (OUT, ">$sympa_conf_file")) {
	printf STDERR "unable to save $sympa_conf_file, aborting without saving change\n";
	exit;
    }
    while (<IN>){printf OUT $_;}
    close IN;
    close OUT;

    open (IN, "$new_wws_conf");
    unless (open (OUT, ">$conf_file")) {
	printf STDERR "unable to save $conf_file, aborting without saving change\n";
	exit;
    }
    while (<IN>){printf OUT $_;}
    close IN;
    close OUT;

    printf "$sympa_conf_file and $conf_file updated. Previous version saved in $sympa_conf_file.$date and $conf_file.$date\n";
}
    


