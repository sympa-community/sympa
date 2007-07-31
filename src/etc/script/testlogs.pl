#!--PERL--

use strict;

use lib '--LIBDIR--';
use Getopt::Long;
use Conf;
use Log;


my $config_file = $main::options{'config'} || '/etc/sympa.conf';
## Load configuration file
unless (Conf::load($config_file)) {
   &fatal_err("Configuration file $config_file has errors.");
}

my %options;
&GetOptions(\%main::options, 'debug|d', 'log_level=s', 'config|f=s');


## Open the syslog and say we're read out stuff.
do_openlog($Conf{'syslog'}, $Conf{'log_socket_type'}, 'sympa');

# setting log_level using conf unless it is set by calling option
if ($main::options{'log_level'}) {
    do_log('info', "Logs seems OK, log level set using options : $main::options{'log_level'}"); 
}else{
    &Log::set_log_level($Conf{'log_level'});
    do_log('info', "Logs seems OK, default log level $Conf{'log_level'}"); 
}
printf "Ok, now check logs \n";

1;


