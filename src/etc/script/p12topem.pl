#! --PERL--

# p12topem.pl - This script installs a List X509 cert and
# the associated private key in list directory
# Input is PKCS#12 file
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


use strict;

use lib '--modulesdir--';
use Getopt::Long;

my $sympa_conf_file = '--CONFIG--';
use Conf;
use List;

## Load sympa config
unless (&Conf::load($sympa_conf_file)) {
    die 'config_error';
}

## Probe Db if defined
if ($Conf{'db_name'} and $Conf{'db_type'}) {
    unless (&Upgrade::probe_db()) {
	&die('Database %s defined in sympa.conf has not the right structure or is unreachable. If you don\'t use any database, comment db_xxx parameters in sympa.conf', $Conf{'db_name'});
    }
}

## Apply defaults to %List::pinfo
&List::_apply_defaults();

my $openssl = $Conf{'openssl'};
my $home_sympa = $Conf{'home'};
my $outpass = $Conf{'key_passwd'};
my $etc_dir = $Conf{'etc'};

## Check option
my %options;
&GetOptions(\%main::options, 'pkcs12=s','listname=s', 'robot=s', 'help|h');

$main::options{'foreground'} = 1;
my $listname = $main::options{'listname'};
my $robot = $main::options{'robot'};
my $p12input = $main::options{'pkcs12'};


my ($cert,$privatekey,$inpass,$key);

if (($main::options{'help'} ne '') || 
    !(-r $main::options{'pkcs12'}) || 
    (($main::options{'listname'} ne '') && ($main::options{'robot'} ne ''))
   ){
    &print_usage(); 
}else{

    if ($listname) {
	my $self = new List($listname, $robot);
	$cert = $self->{'dir'}.'/cert.pem';
	$privatekey = $self->{'dir'}.'/private_key';
	unless (-d $self->{'dir'}) {
	    printf "unknown list $listname (directory $self->{'dir'} not found)\n";
	    die;
	}
    }elsif($robot) {
	if (-d $Conf{'etc'}.'/'.$robot) {
	    $cert = $Conf{'etc'}.'/'.$robot.'/cert.pem';
	    $privatekey = $Conf{'etc'}.'/'.$robot.'/private_key';
	}else{
	    $cert = $Conf{'etc'}.'/cert.pem';
	    $privatekey = $Conf{'etc'}.'/private_key';	    
	}
    }

    if (-r "$cert") {
	printf "$cert certificat already exist\n";
	die;
    }
    if (-r "$privatekey") {
	printf "$privatekey already exist\n";
	die;
    }
    
    unless ($openssl) {
	printf "You must first configure Sympa to use openssl. Check the parameter openssl in sympa.conf\n";
	die;
    }
    
    system 'stty', '-echo';
    printf "password to access to $p12input :";
    chop($inpass = <STDIN>);
    print "\n";
    system 'stty', 'echo';
    open  PASS, "| $openssl pkcs12 -in $p12input -out $cert -nokeys -clcerts -passin stdin";
    print PASS "$inpass\n";
    close PASS ;
    
    unless ($outpass) {
	system 'stty', '-echo';
	printf "sympa password to protect list private_key $key:";
	chop($outpass = <STDIN>);
	print "\n";
	system 'stty', 'echo';
    }
    open  PASS, "| $openssl pkcs12 -in $p12input -out $privatekey -nocerts -passin stdin -des3 -passout stdin";
    print PASS "$inpass\n$outpass\n";
    close PASS ;
    
    printf "$privatekey and  $cert created.\n";
    exit;
}



sub print_usage {
printf "

Usage p12topem.pl --pkcs12 <pkcs#12_cert_file> --listname <listname> or
      p12topem.pl --pkcs12 <pkcs#12_cert_file> --robot <robot>

This script is intended to convert a PKCS#12 certificates in PEM format
using Openssl. This is usefull because most PKI providerd deliver certificates
using a web interface so the certificat is stored in your browser.

When exporting a certificate from a browser (Netscape, IE, Mozilla etc)
the result is stored using PKCS#12 format.Sympa requires a pair of PEM
certificat and private key. You must then convert your pkcs#12 into PEM. 

For a list certificat, the file will be installed in
$home_sympa/<listname>/cert.pem and $home_sympa/<listname>/private_key

For Sympa itself a certificate will be installed in 
$Conf{'etc'}/<robot>/cert.pem and  $Conf{'etc'}/<robot>/private_key or
$Conf{'etc'}/cert.pem and Conf{'etc'}/private_key


You are then prompted for inpassword (the password used to encrypt the
pkc#12 file).\n";
unless ($outpass) {
printf "Because you did not configure Sympa's password \"key_passwd\"  in
sympa.conf you will also be prompted for the password used by sympa to access
to the list private key)\n";
} 
}
