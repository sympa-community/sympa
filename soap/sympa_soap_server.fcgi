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
require 'tt2.pl';
use List;
use mail;
use Conf;
use Log;
use Language;
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

&Log::set_log_level($Conf{'log_level'}) if ($Conf{'log_level'}); 


## Open log
$wwsconf->{'log_facility'}||= $Conf{'syslog'};

&Log::do_openlog($wwsconf->{'log_facility'}, $Conf{'log_socket_type'}, 'soap');
&Log::do_log('info', 'SOAP server launched');

unless ($List::use_db = &List::check_db_connect()) {
    &do_log('err','SOAP server requires a RDBMS to run');
}

my $pinfo = &List::_apply_defaults();

## The process should not fork for sending mail
## Messages will be spooled instead
&mail::set_send_spool($Conf{'queue'});

## Loading all Lists at startup, in order to increase execution speed

my $all_lists = &List::get_lists('*');
foreach my $list (@$all_lists){
    ## Nothing to do here
 }


##############################################################################################
#    Soap part
##############################################################################################

my $server = SOAP::Transport::HTTP::FCGI::Sympa->new(); 

#$server->dispatch_with({'urn:Sympa' => 'sympasoap'});
$server->dispatch_to('--LIBDIR--/bin','sympasoap');

$server->handle($birthday);

