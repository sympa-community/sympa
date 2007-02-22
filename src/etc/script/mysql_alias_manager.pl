#!--PERL--

## This version of alias_manager.pl has been customized by Bea.
## It has the ability to add/remove list aliases in a MySQL database for vpopmail
## To make sympa use this script, you should install it as /home/sympa/bin/alias_manager.pl
## You should edit all the $mysql_xxx below to use your own mysql database

$ENV{'PATH'} = '';

## Load Sympa.conf
use strict;
use lib '--LIBDIR--';
use Conf;
use POSIX;
require "tools.pl";
require "tt2.pl";

use DBI;

unless (Conf::load('--CONFIG--')) {
   print gettext("The configuration file --CONFIG-- contains errors.\n");
   exit(1);
}

## MYSQL configuration
my $mysql_host = "localhost";
my $mysql_base = "vpopmail";
my $mysql_user = "vpopmail";
my $mysql_pass = "password";

my $default_domain;
my $return_path_suffix;
my ($operation, $listname, $domain, $file) = @ARGV;

my $dbh;
my $sql;
my @enr;

if (($operation !~ /^(add)|(del)$/) || ($#ARGV < 2)) {
    printf "Usage: $0 <add|del> <listname> <domain> [<file>]\n";
    exit(2);
}

$default_domain = $Conf{'domain'};
$return_path_suffix = $Conf{'return_path_suffix'};

my %data;
$data{'date'} =  &POSIX::strftime("%d %b %Y", localtime(time));
$data{'list'}{'domain'} = $data{'robot'} = $domain;
$data{'list'}{'name'} = $listname;
$data{'default_domain'} = $default_domain;
#$data{'is_default_domain'} = 1 if ($domain eq $default_domain);
$data{'is_default_domain'} = 1;
$data{'return_path_suffix'} = $return_path_suffix;
my @aliases ;

my $tt2_include_path = &tools::make_tt2_include_path($domain,'',,);

my $aliases_dump;
&tt2::parse_tt2 (\%data, 'list_aliases.tt2',\$aliases_dump, $tt2_include_path);

@aliases = split /\n/, $aliases_dump;

unless (@aliases) {
        print STDERR "No aliases defined\n";
        exit(15);
}

if ($operation eq 'add') {

    ## Check existing aliases
    if (&already_defined(@aliases)) {
	print STDERR "some alias already exist\n";
	exit(13);
    }

    if (!&initialize_mysql) {
	print STDERR "Can't connect to MySQL database\n";
	exit(14);
    }

    foreach my $alias (@aliases) {
	if ($alias =~ /^\#/) {
	    next;
	}
	
	$alias =~ /^([^:]+):\s*(\".*\")$/;
	my $alias_value = $1;
	my $command_value = $2;
	$command_value =~ s/\"//g;

	# We create the new mysql alias.
	$sql = "INSERT INTO valias SET alias = '".$alias_value."', domain = '".$domain."', valias_line = '".$command_value."'";

	# We finally add the entry
	$dbh->do($sql) or die "$sql : $DBI::errstr";
    }

    &finalize_mysql;

}
elsif ($operation eq 'del') {
    
    if (!&initialize_mysql) {
	print STDERR "Can't connect to MySQL database\n";
	exit(7);
    }

    foreach my $alias (@aliases) {
	if ($alias =~ /^\#/) {
	    next;
	}
	
	$alias =~ /^([^:]+):/; 
	my $alias_value = $1;
	$alias_value =~ s/\+/\-/g;

	$sql = "DELETE FROM valias WHERE alias = '".$alias_value."' and domain = '".$domain."'";
        $dbh->do($sql) or die "$sql : $DBI::errstr";
    }

    &finalize_mysql;
}
else {
    print STDERR "Action $operation not implemented yet\n";
    exit(2);
}

exit 0;

## Check if an alias is already defined  
sub already_defined {
    
    my @aliases = @_;

    &initialize_mysql;

    foreach my $alias (@aliases) {
        if ($alias =~ /^\#/) {
	    next;
	}
	
	$alias =~ /^([^:]+):/; 
	my $alias_value = $1;
	$alias_value =~ s/\+/\-/g;	
    
        $sql = "SELECT COUNT(alias) as e_alias FROM valias where alias = '".$alias_value."' and domain = '".$domain."'";
        $dbh->do($sql) or die "$sql : $DBI::errstr";

        @enr = $dbh->selectrow_array($sql);
	if (@enr[0] != 0) {
	    print STDERR "Alias already defined : $alias_value\n";
	    &finalize_mysql;
	    return 1;
	}
    }
    
    &finalize_mysql;
    return 0;
}

## Connect to MySQL Database
sub initialize_mysql {
    unless ($dbh = DBI->connect("DBI:mysql:dbname=$mysql_base;host=$mysql_host", $mysql_user, $mysql_pass)) {
        print "Can't connect to Database :", $DBI::errstr;
	return 0
    }
    return 1;
}

## Close the MySQL Connection
sub finalize_mysql {
    $dbh->disconnect;
}

