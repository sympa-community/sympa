#!--PERL--

## Until Sympa release 3.4.3.1 HTML view of moderated messages was created by wwsympa.fgci, when needed.
## It is now created by sympa.pl when the message is received. 
## This script will create all missing HTML files in the moderation spool

use lib '--LIBDIR--';
use Conf; # to load Sympa conf which is needed by List.pm
use List;
use Log; # if you want to get logs of List.pm

unless (Conf::load('--CONFIG--')) {
    die "Can't load Sympa configuration file";
}
&do_openlog($Conf{'syslog'}, $Conf{'log_socket_type'}, 'sympa');

if ($Conf{'db_name'} and $Conf{'db_type'}) {
    unless (&Upgrade::probe_db()) {
	die "Sympa can't connect to database";
    }
} #  to check availabity of Sympa database
&List::_apply_defaults(); # else reading of a List configuration won't work 

# Set the UserID & GroupID for the process
$( = $) = (getgrnam('--GROUP--'))[2];
$< = $> = (getpwnam('--USER--'))[2];

# Sets the UMASK
umask(oct($Conf{'umask'}));

## Loads message list
unless (opendir SPOOL, $Conf{'queuemod'}) {
    die "Unable to read spool";
}

foreach $msg ( sort grep(!/^\./, readdir SPOOL )) {
    
    next if ($msg =~ /^\./);
    
    $msg =~ /^(.*)\_([^\_]+)$/;
    my ($listaddress, $modkey) = ($1, $2);
    
    
    if (-d "$Conf{'queuemod'}/.$msg") {
	next;
    }
    
    print "Creating HTML version for $Conf{'queuemod'}/$msg\n";
    
    my ($listname, $listrobot) = split /\@/, $listaddress;
    my $self = new List ($listname, $listrobot);
    
    my( @rcpt);
    my $admin = $self->{'admin'};
    my $name = $self->{'name'};
    my $host = $admin->{'host'};
    my $robot = $self->{'domain'};
    my $modqueue = $Conf{'queuemod'};
    unless ($name && $admin) {
	print STDERR "Unkown list $listaddress, skipping\n";
	next;
    }
    
    my $tmp_dir = "$modqueue\/.$name\_$modkey";
    unless (-d $tmp_dir) {
	unless (mkdir ($tmp_dir, 0777)) {
	    die "May not create $tmp_dir";
	}
	my $mhonarc_ressources = &tools::get_filename('etc',{},'mhonarc-ressources.tt2', $robot, $self);
	unless ($mhonarc_ressources) {
	    die "Cannot find any MhOnArc ressource file";
	}
	
	## generate HTML
	chdir $tmp_dir;
	my $mhonarc = &Conf::get_robot_conf($robot, 'mhonarc');
	open ARCMOD, "$mhonarc  -single -rcfile $mhonarc_ressources -definevars listname=$name -definevars hostname=$host $modqueue/$name\_$modkey|";
	open MSG, ">msg00000.html";
	print MSG <ARCMOD>;
	close MSG;
	close ARCMOD;
	chdir $Conf{'home'};
    }    
}
closedir SPOOL;


