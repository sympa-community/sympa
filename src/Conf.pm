## This module handles the configuration file for Sympa.

package Conf;

use Log;
use Language;

require Exporter;
use Carp;

@ISA = qw(Exporter);
@EXPORT = qw(%Conf);

my @valid_options = qw(
		       avg bounce_warn_rate bounce_halt_rate
		       clean_delay_queue clean_delay_queueauth clean_delay_queuemod 
		       cookie create_list db_host db_name db_options db_passwd db_type db_user 
		       db_additional_subscriber_fields db_additional_user_fields
		       default_list_priority edit_list email etc
		       global_remind home host lang listmaster log_socket_type 
		       max_size maxsmtp msgcat nrcpt owner_priority pidfile spool queue 
		       queueauth queuebounce queuedigest queueexpire queuemod queueoutgoing tmpdir
		       loop_command_max loop_command_sampling_delay loop_command_decrease_factor
		       remind_return_path request_priority rfc2369_header_fields sendmail sleep 
		       sort sympa_priority syslog umask welcome_return_path wwsympa_url
                       openssl trusted_ca_options key_passwd ssl_cert_dir remove_headers
		       antivirus_path antivirus_args anonymous_header_fields
);
my %valid_options = ();
map { $valid_options{$_}++; } @valid_options;

my %Default_Conf = 
    ('home'    => '--DIR--/expl',
     'etc'     => '--DIR--/etc',
     'trusted_ca_options' => '-CAfile --ETCBINDIR--/ca-bundle.crt',
     'key_passwd' => '',
     'ssl_cert_dir' => '--DIR--/expl/X509-user-certs',
     'umask'   => '027',
     'syslog'  => 'LOCAL1',
     'nrcpt'   => 25,
     'avg'     => 10,
     'maxsmtp' => 20,
     'sendmail'=> '/usr/sbin/sendmail',
     'openssl' => '',
     'host'    => undef,
     'email'   => 'sympa',
     'pidfile' => '--DIR--/sympa.pid',
     'msgcat'  => '--DIR--/nls',
     'sort'    => 'fr,ca,be,ch,uk,edu,*,com',
     'spool'   => '--DIR--/spool',
     'queue'   => undef,
     'queuedigest'=> undef,
     'queuemod'   => undef,
     'queueexpire'=> undef,
     'queueauth'  => undef,
     'queueoutgoing'  => undef,
     'queuebounce'  => undef,     
     'tmpdir'  => undef,     
     'sleep'      => 5,
     'clean_delay_queue'    => 1,
     'clean_delay_queuemod' => 10,
     'clean_delay_queueauth' => 3,
     'log_socket_type'      => 'unix',
     'remind_return_path' => 'owner',
     'welcome_return_path' => 'owner',
     'db_type' => '',
     'db_name' => '',
     'db_host' => '',
     'db_user' => '', 
     'db_passwd'  => '',
     'db_options' => '',
     'db_additional_subscriber_fields' => '',
     'db_additional_user_fields' => '',
     'listmaster' => undef,
     'default_list_priority' => 5,
     'sympa_priority' => 1,
     'request_priority' => 0,
     'owner_priority' => 9,
     'lang' => 'us',
     'max_size' => 5242880,
     'edit_list' => 'owner',
     'create_list' => 'public_listmaster',
     'global_remind' => 'listmaster',
     'wwsympa_url' => undef,
     'bounce_warn_rate' => '30',
     'bounce_halt_rate' => '50',
     'cookie' => undef,
     'loop_command_max' => 200,
     'loop_command_sampling_delay' => 3600,
     'loop_command_decrease_factor' => 0.5,
     'rfc2369_header_fields' => 'help,subscribe,unsubscribe,post,owner,archive',
     'remove_headers' => 'Return-Receipt-To,Precedence,X-Sequence,Disposition-Notification-To',
     'antivirus_path' => '',
     'antivirus_args' => '',
     'anonymous_header_fields' => 'Sender,X-Sender,Received,Message-id,From,X-Envelope-To,Resent-From,Reply-To,Organization,Disposition-Notification-To,X-Envelope-From,X-X-Sender'
   );
   
%Conf = ();

## Loads and parses the configuration file. Reports errors if any.
sub load {
    my $config = shift;
    my $line_num = 0;
    my $config_err = 0;
    my($i, %o);
    
    ## Open the configuration file or return and read the lines.
    unless (open(IN, $config)) {
	printf STDERR  "load: Unable to open %s: %s\n", $config, $!;
	return undef;
    }
    while (<IN>) {
	$line_num++;
	next if (/^\s*$/o || /^[\#\;]/o);
#	if (/^(\S+)\s+(\S+|\`.*\`)\s*$/io) {
	if (/^(\S+)\s+(.+)$/io) {
	    my($keyword, $value) = ($1, $2);
	    $value =~ s/\s*$//;
	    ##  'tri' is a synonime for 'sort' (for compatibily with old versions)
	    $keyword = 'sort' if ($keyword eq 'tri');
	    ## Special case: `command`
	    if ($value =~ /^\`(.*)\`$/) {
		$value = qx/$1/;
		chomp($value);
	    }
	    $o{$keyword} = [ $value, $line_num ];
	}else {
	    printf STDERR Msg(1, 3, "Malformed line %d: %s"), $config, $_;
	    $config_err++;
	}
    }
    close(IN);

    ## Defaults
    unless (defined $o{'wwsympa_url'}) {
	$o{'wwsympa_url'}[0] = "http://$o{'host'}[0]/wws";
    }
    my $spool = $o{'spool'}[0] || $Default_Conf{'spool'};

    unless (defined $o{'queuedigest'}) {
	$o{'queuedigest'}[0] = "$spool/digest";
    }
    unless (defined $o{'queuemod'}) {
	$o{'queuemod'}[0] = "$spool/moderation";
    }
    unless (defined $o{'queueexpire'}) {
	$o{'queueexpire'}[0] = "$spool/expire";
    }
    unless (defined $o{'queueauth'}) {
	$o{'queueauth'}[0] = "$spool/auth";
    }
    unless (defined $o{'queueoutgoing'}) {
	$o{'queueoutgoing'}[0] = "$spool/outgoing";
    }
    unless (defined $o{'tmpdir'}) {
	$o{'tmpdir'}[0] = "$spool/tmp";
    }

    ## Check if we have unknown values.
    foreach $i (sort keys %o) {
	next if ($valid_options{$i});
	printf STDERR  "Line %d, unknown field: %s in sympa.conf\n", $o{$i}[1], $i;
	$config_err++;
    }
    ## Do we have all required values ?
    foreach $i (keys %valid_options) {
	unless (defined $o{$i} or defined $Default_Conf{$i}) {
	    printf "Required field not found in sympa.conf: %s\n", $i;
	    $config_err++;
	    next;
	}
	$Conf{$i} = $o{$i}[0] || $Default_Conf{$i};
    }
    
    my $p = 1;
    foreach (split(/,/, $Conf{'sort'})) {
	$Conf{'poids'}{$_} = $p++;
    }
    $Conf{'poids'}{'*'} = $p if ! $Conf{'poids'}{'*'};
    
    if ($config_err) {
	return undef;
    }

    if ($Conf{'rfc2369_header_fields'} eq 'none') {
	delete $Conf{'rfc2369_header_fields'};
    }else {
	$Conf{'rfc2369_header_fields'} = [split(/,/, $Conf{'rfc2369_header_fields'})];
    }

    if ($Conf{'anonymous_header_fields'} eq 'none') {
	delete $Conf{'anonymous_header_fields'};
    }else {
	$Conf{'anonymous_header_fields'} = [split(/,/, $Conf{'anonymous_header_fields'})];
    }

    if ($Conf{'remove_headers'} eq 'none') {
	delete $Conf{'remove_headers'};
    }else {
	$Conf{'remove_headers'} = [split(/,/, $Conf{'remove_headers'})];
    }

    @{$Conf{'listmasters'}} = split(/,/, $Conf{'listmaster'});

    $Conf{'sympa'} = "$Conf{'email'}\@$Conf{'host'}";
    $Conf{'request'} = "$Conf{'email'}-request\@$Conf{'host'}";
    
    return 1;
}

## Check a few files
sub checkfiles {
    my $config_err = 0;
    
    foreach my $p ('sendmail','openssl','antivirus_path') {
	next unless $Conf{$p};

	unless (-x $Conf{$p}) {
	    do_log('err', "File %s does not exist or is not executable", $Conf{$p});
	    $config_err++;
	}
    }

    foreach my $qdir ('spool','queue','queuedigest','queuemod','queueexpire','queueauth','queueoutgoing','queuebounce','tmpdir') {
	unless (-d $Conf{$qdir}) {
	    do_log('info', "creating spool $Conf{$qdir}");
	    unless ( mkdir ($Conf{$qdir}, 0775)) {
		do_log('err', 'Unable to create spool %s', $Conf{$qdir});
		$config_err++;
	    }
	}
    }

    return undef if ($config_err);
    return 1;
}

## Packages must return true.
1;
