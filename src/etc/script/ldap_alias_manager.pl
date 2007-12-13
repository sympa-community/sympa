#!--PERL--
#Author: Philippe Baumgart
#Company: BT
#License: GPL 
#Version: 1.0
## This version of alias_manager.pl has been customized by Ludovic Marcotte, Kazuo Moriwaka and Francis Lachapelle
## Modified by Philippe Baumgart:
## Added  Optional LDAPS support
## Added LDAP configuration stored in a separate config file --DIR--/etc/ldap_alias_manager.conf
#Purpose: It has the ability to add/remove list aliases in an LDAP directory
# You should edit all the --DIR--/etc/ldap_alias_manager.conf to use your own LDAP directory

$ENV{'PATH'} = '';

## Load Sympa.conf
use strict;
use lib '--LIBDIR--';
use Conf;
use POSIX;
require "tools.pl";
require "tt2.pl";

use Net::LDAP;
use Net::LDAPS;

unless (Conf::load('--CONFIG--')) {
   print gettext("The configuration file --CONFIG-- contains errors.\n");
   exit(1);
}

my $manager_conf_file = '--DIR--/etc/ldap_alias_manager.conf';

## LDAP configuration
my %ldap_params;
my ($ldap_host,$ldap_base_dn,$ldap_bind_dn,$ldap_bind_pwd,$ldap_mail_attribute,$ldap_objectclass,$ldap_ssl,$ldap_cachain)=(undef,undef,undef,undef,undef,undef,undef,undef);
&GetLdapParameter();

my $ldap_connection = undef;
$ldap_host = $ldap_params{'ldap_host'} or print STDERR "Missing required parameter ldap_host the config file $manager_conf_file\n" and exit 0;
$ldap_base_dn = $ldap_params{'ldap_base_dn'} or print STDERR "Missing required parameter ldap_base_dn the config file $manager_conf_file\n" and exit 0;
$ldap_bind_dn = $ldap_params{'ldap_bind_dn'} or print STDERR "Missing required parameter ldap_bind_dn the config file $manager_conf_file\n" and exit 0;
$ldap_bind_pwd = $ldap_params{'ldap_bind_pwd'} or print STDERR "Missing required parameter ldap_bind_pwd the config file $manager_conf_file\n" and exit 0;
$ldap_mail_attribute = $ldap_params{'ldap_mail_attribute'} or print STDERR "Missing required parameter ldap_mail_attribute the config file $manager_conf_file\n" and exit 0;
$ldap_objectclass=$ldap_params{'ldap_object_class'} or print STDERR "Missing required parameter ldap_object_class the config file $manager_conf_file\n" and exit 0;
$ldap_ssl=$ldap_params{'ldap_ssl'} or print STDERR "Missing required parameter ldap_ssl (possible value: 0 or 1) the config file $manager_conf_file\n" and exit 0;
$ldap_cachain=$ldap_params{'ldap_cachain'} or undef;


my $ldap_sample_dn = "uid={ALIAS},$ldap_base_dn";
my %ldap_attributes = ("objectClass" => ["top","person", "organizationalPerson", $ldap_objectclass],
		       "cn" => ['{ALIAS}'],
		       "sn" => ['{ALIAS}'],
		       "uid" => ['{ALIAS}'],		       
		       );

my $default_domain;
my ($operation, $listname, $domain, $file) = @ARGV;


if (($operation !~ /^(add)|(del)$/) || ($#ARGV < 2)) {
    printf "Usage: $0 <add|del> <listname> <domain> [<file>]\n";
    exit(2);
}

$default_domain = $Conf{'domain'};

my %data;
$data{'date'} =  &POSIX::strftime("%d %b %Y", localtime(time));
$data{'list'}{'domain'} = $data{'robot'} = $domain;
$data{'list'}{'name'} = $listname;
$data{'default_domain'} = $default_domain;
$data{'is_default_domain'} = 1 if ($domain eq $default_domain);
my @aliases ;

my $tt2_include_path = [$Conf{'etc'}.'/'.$domain,
                        $Conf{'etc'},
                        '/usr/share/sympa'];

my $aliases_dump;
&tt2::parse_tt2(\%data, 'list_aliases.tt2',\$aliases_dump, $tt2_include_path);

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

    if (!&initialize_ldap) {
	print STDERR "Can't bind to LDAP server\n";
	exit(14);
    }

    foreach my $alias (@aliases) {
	if ($alias =~ /^\#/) {
	    next;
	}
	
	$alias =~ /^([^:]+):\s*(\".*\")$/;
	my $alias_value = $1;
	my $command_value = $2;

	if ($command_value =~ m/bouncequeue/) {
	    $command_value = "sympabounce";
	} else{
	    $command_value = "sympa";
	} 

	# We create the new LDAP entry.
        my $entry = Net::LDAP::Entry->new;
	
	# We add the required mail attribute
	$entry->add($ldap_mail_attribute, $alias_value."\@".$domain);
	
	# We substitute all occurences of + by - for the rest of the attributes, including the dn.
	# The rationale behind this is that the "uid" attribute prevents the use of the '+' character.
	$alias_value =~ s/\+/\-/g;

	# We set the dn
	my $value = $ldap_sample_dn;
	$value =~ s/{ALIAS}/$alias_value/;
	$entry->dn($value);

	# We add the rest of the attributes
	foreach my $hash_key (keys %ldap_attributes) {
	    foreach my $hash_value (@{$ldap_attributes{$hash_key}}) {
		$value = $hash_value;
		$value =~ s/{ALIAS}/$alias_value/;
		#$value =~ s/{COMMAND}/$command_value/;
		$entry->add($hash_key, $value);
	    }
	}

	# We finally add the entry
	my $msg = $ldap_connection->add($entry);
	if ($msg->is_error()) {
	    print STDERR "Can't add entry for $alias_value\@$domain: ",$msg->error(),"\n";
	    exit(15);
	}
	$entry = undef;
    }

    &finalize_ldap;

}
elsif ($operation eq 'del') {
    
    if (!&initialize_ldap) {
	print STDERR "Can't bind to LDAP server\n";
	exit(7);
    }

    foreach my $alias (@aliases) {
	if ($alias =~ /^\#/) {
	    next;
	}
	
	$alias =~ /^([^:]+):/; 
	my $alias_value = $1;
	$alias_value =~ s/\+/\-/g;

	my $value = $ldap_sample_dn;
	$value =~ s/{ALIAS}/$alias_value/;
	$ldap_connection->delete($value);
    }

    &finalize_ldap;
}
else {
    print STDERR "Action $operation not implemented yet\n";
    exit(2);
}

exit 0;

## Check if an alias is already defined  
sub already_defined {
    
    my @aliases = @_;

    &initialize_ldap;

    foreach my $alias (@aliases) {
	
	$alias =~ /^([^:]+):/;

	my $source_result = $ldap_connection->search(filter => "(".$ldap_mail_attribute."=".$1."\@".$domain.")",
						     base => $ldap_base_dn);
	if ($source_result->count != 0) {
	    print STRERR "Alias already defined : $1\n";
	    &finalize_ldap;
	    return 1;
	}
    }
    
    &finalize_ldap;
    return 0;
}

## Parse the alias_ldap.conf config file
sub GetLdapParameter {
	#read the config file
	open(LDAPCONFIG,$manager_conf_file) or print STDERR "Can't read the config file $manager_conf_file\n" and return 0;
	my @ldap_conf=<LDAPCONFIG>;
	close LDAPCONFIG;
	foreach(@ldap_conf)
	{
        	#we skip the comments
        	if ($_ =~ /^\#/)
        	{
        		next;
        	}        	
        	elsif ($_  =~ /^\s*(\w+)\s+(.+)\s*$/)
        	{
        		
        		my ($param_name, $param_value) = ($1, $2);
        		$ldap_params{$param_name}=$param_value;
        		#print "$param_name: $ldap_params{$param_name}\n";     		
        	}
        	#we skip the blank line
        	elsif ($_  =~ /^$/)
        	{
        		next;
        	}
        	else
        	{
        		print STDERR "Unknown syntax in config file $manager_conf_file\n" and return 0;
        	}        
        
        }
         
}
	


## Initialize the LDAP connection
sub initialize_ldap {
    
    
    if ($ldap_ssl eq '1')
    {
    	if ($ldap_cachain)
    	{
    		unless ($ldap_connection = Net::LDAPS->new($ldap_host), version => 3, verify => 'require', sslversion=> 'sslv3',
        		                  cafile => $ldap_cachain) {
			print STDERR "Can't connect to LDAP server using SSL or unable to verify Server certificate for $ldap_host: $@\n";
			return 0;
    		}
    	}
    	else
    	{
    		unless ($ldap_connection = Net::LDAPS->new($ldap_host), version => 3, verify => 'none', sslversion=> 'sslv3') {
			print STDERR "Can't connect to LDAP server using SSL for $ldap_host: $@\n";
			return 0;
    		}
    	}
    }        
    else 
    {
    	unless ($ldap_connection = Net::LDAP->new($ldap_host), version => 3) {
		print STDERR "Can't connect to LDAP server $ldap_host: $@\n";
		return 0;
    	}
    }
    
    
    my $msg = $ldap_connection->bind($ldap_bind_dn, password => $ldap_bind_pwd);
    if ($msg->is_error()) {
	print STDERR "Can't bind to server $ldap_host: ",$msg->error(),"\n";
	return 0;
    }

    return 1;
}

## Close the LDAP connection
sub finalize_ldap {
    if (defined $ldap_connection) {
	$ldap_connection->unbind;
	$ldap_connection = undef;
    }
}
