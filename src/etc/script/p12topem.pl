#! --PERL--

($p12input,$listname) = @ARGV;


use lib '--BINDIR--';
$sympa_conf_file = '--CONFIG--';
use Conf;

## Load sympa config
unless (&Conf::load($sympa_conf_file)) {
    die 'config_error';
}
my $openssl = $Conf::Conf{'openssl'};
my $home_sympa = $Conf::Conf{'home'};
my $outpass = $Conf::Conf{'key_passwd'};

if (($p12input =~ /help$/) || ($#ARGV != 1)) {
printf "

Usage $ARGV[-1] <pkcs#12cert> <listname>

This script is intended to convert a PKCS#12 certificates in PEM format
using Openssl. This is usefull because most PKI providerd deliver certificates
using a web interface so the certificat is stored in your browser.

When exporting a certificate from Netscape the result is stored using
PKCS#12 format.

Sympa requires a pair of PEM certificat and private key. You must then convert
your pkcs#12 into PEM :
 - $home_sympa/<listname>/cert.pem
 - $home_sympa/<listname>/private_key

This can be done using  $ARGV[-1] <pkcs#12cert> <listname>

You are then prompted for inpassword (the password used to encrypt the
pkc#12 file).\n";
unless ($outpass) {
printf "Because Sympa's password \"key_passwd\" is not configured in sympa.conf you will
also be prompted for the password used by sympa to access to the list private key)\n";
} 

}else{

    $cert = "$home_sympa/$listname/cert.pem";
    $privatekey = "$home_sympa/$listname/private_key";

    unless (-d "$home_sympa/$listname") {
	printf "unknown list $listname (directory $home_sympa/$listname not found)\n";
        die;
    }
    if (-r "$cert") {
	printf "$listname list X509 certificat allready exist ($cert)\n";
        die;
    }
    if (-r "$privatekey") {
	printf "$listname list privatekey allready exist ($privatekey)\n";
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

    printf "
$privatekey and  $cert created. Now welcome message for list $listname will be signed\n
using S/MIME. Encrypted messages will be distributed in a crypted form to each subscriber\n
using their X509 certificat.\n";
}


