#! --PERL-- -U


use SOAP::Lite;

# Use this line for more debug facility
#use SOAP::Lite +trace;
use SOAP::Transport::HTTP;

use lib '--LIBDIR--';

## Defines SOAP::Transport::HTTP::FCGI::Sympa with a modified handle()
use SympaTransport;

use Getopt::Long;
use strict;

## Sympa API
require 'parser.pl';
use List;
use smtp;
use Conf;
use Log;
use sympasoap;

## WWSympa librairies
use cookielib;

my $birthday = time ;

## Configuration
my $wwsconf = {};

## Change to your wwsympa.conf location
my $conf_file = '--WWSCONFIG--';
my $sympa_conf_file = '--CONFIG--';

## Load config 
unless ($wwsconf = &wwslib::load_config($conf_file)) {
    &Log::fatal_err('Unable to load config file %s', $conf_file);
}

## Load sympa config
unless (&Conf::load($sympa_conf_file)) {
    &Log::fatal_err('Unable to load sympa config file %s', $sympa_conf_file);
}

$log_level = $Conf{'log_level'} if ($Conf{'log_level'}); 


## Open log
$wwsconf->{'log_facility'}||= $Conf{'syslog'};

&Log::do_openlog($wwsconf->{'log_facility'}, $Conf{'log_socket_type'}, 'soap');
&Log::do_log('info', 'SOAP server launched');

unless ($List::use_db = &List::probe_db()) {
    &error_message('no_database');
    &do_log('info','SOAP server requires a RDBMS to run');
}

my $pinfo = &List::_apply_defaults();

## Loading all Lists at startup, in order to increase execution speed
foreach my $listname (&List::get_lists('*')){
     my $list = new List ($listname);
 }


##############################################################################################
#    Soap part
##############################################################################################

my $server = SOAP::Transport::HTTP::FCGI::Sympa->new(); 

$server->dispatch_with({'urn:do_lists' => 'sympasoap',
			'urn:do_login' => 'sympasoap',
			'urn:review' => 'sympasoap',
			'urn:signoff' => 'sympasoap',
			'urn:subscribe' => 'sympasoap',
			'urn:which' => 'sympasoap',
			'urn:amI' => 'sympasoap',
			'urn:do_which' => 'sympasoap',
			'urn:check_cookie' => 'sympasoap'
		    });
$server->handle($birthday);

