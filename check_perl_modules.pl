# check_perl_modules.pl - This script checks installed and required Perl modules
# It also does the required installations
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

use CPAN;

## assume version = 1.0 if not specified.
## 
%versions = ('perl' => '5.005',
             'Net::LDAP' =>, '0.27', 
	     'perl-ldap' => '0.10',
	     'Mail::Internet' => '1.51', 
	     'DBI' => '1.06',
	     'DBD::Pg' => '0.90',
	     'DBD::Sybase' => '0.90',
	     'DBD::mysql' => '2.0407',
	     'FCGI' => '0.48',
	     'MIME::Tools' => '5.209',
	     'File::Spec' => '0.8',
             'Crypt::CipherSaber' => '0.50',
	     'CGI' => '2.52',
	     'Digest::MD5' => '2.00',
	     'DB_File' => '1.75',
	     'IO::Socket::SSL' => '0.90',
	     'Net::SSLeay' => '1.16',
	     'Archive::Zip' => '1.05',
	     'Bundle::LWP' => '1.09'
	     );

### key:left "module" used by SYMPA, 
### right CPAN module.		     
%req_CPAN = ('DB_File' => 'DB_FILE',
	     'Digest::MD5' => 'Digest-MD5',
	     'Mail::Internet' =>, 'MailTools',
	     'IO::Scalar' => 'IO-stringy',
	     'MIME::Tools' => 'MIME-tools',
	     'MIME::Base64' => 'MIME-Base64',
	     'CGI' => 'CGI',
	     'File::Spec' => 'File-Spec',
	     'Archive::Zip' => 'Archive-Zip',
	     );

%opt_CPAN = ('DBI' => 'DBI',
	     'DBD::mysql' => 'Msql-Mysql-modules',
	     'DBD::Pg' => 'DBD-Pg',
	     'DBD::Oracle' => 'DBD-Oracle',
	     'DBD::Sybase' => 'DBD-Sybase',
	     'Net::LDAP' =>   'perl-ldap',
	     'CGI::Fast' => 'CGI',
             'Crypt::CipherSaber' => 'CipherSaber',
	     'FCGI' => 'FCGI',
	     'Net::SMTP' => 'libnet',
	     'IO::Socket::SSL' => 'IO-Socket-SSL',
	     'Net::SSLeay' => 'NET-SSLeay',
	     'Bundle::LWP' => 'LWP');

%opt_features = ('DBI' => 'a generic Database Driver, required by Sympa to access Subscriber information and User preferences. An additional Database Driver is required for each database type you wish to connect to.',
		 'DBD::mysql' => 'Mysql database driver, required if you connect to a Mysql database.\nYou first need to install the Mysql server and have it started before installing the Perl DBD module.',
		 'DBD::Pg' => 'PostgreSQL database driver, required if you connect to a PostgreSQL database.',
		 'DBD::Oracle' => 'Oracle database driver, required if you connect to a Oracle database.',
		 'DBD::Sybase' => 'Sybase database driver, required if you connect to a Sybase database.',
		 'Net::LDAP' =>   'required to query LDAP directories. Sympa can do LDAP-based authentication ; it can also build mailing lists with LDAP-extracted members.',
		 'CGI::Fast' => 'WWSympa, Sympa\'s web interface can run as a FastCGI (ie: a persistent CGI). If you install this module, you will also need to install the associated mod_fastcgi for Apache.',
		 'Crypt::CipherSaber' => 'this module provides reversible encryption of user passwords in the database.',
		 'Archive::Zip ' => 'this module provides zip/unzip for archive and shared document download/upload',
		 'FCGI' => 'WSympa, Sympa\'s web interface can run as a FastCGI (ie: a persistent CGI). If you install this module, you will also need to install the associated mod_fastcgi for Apache.',
		 'Net::SMTP' => 'this is required if you set \'list_check_smtp\' sympa.conf parameter, used to check existing aliases before mailing list creation.',
		 'IO::Socket::SSL' => 'required by the \'include_remote_sympa_list\' feature that includes members of a list on a remote server, using X509 authentication',
		 'Net::SSLeay' => 'required by the \'include_remote_sympa_list\' feature that includes members of a list on a remote server, using X509 authentication',
		 'Bundle::LWP' => 'required by the \'include_remote_sympa_list\' feature that includes members of a list on a remote server, using X509 authentication');

### main:
print "******* Check perl for SYMPA ********\n";
### REQ perl version
print "\nChecking for PERL version:\n-----------------------------\n";
$rpv = $versions{"perl"};
if ($] ge $versions{"perl"}){
    print "your version of perl is OK ($]  >= $rpv)\n";
}else {
    print "Your version of perl is TOO OLD ($]  < $rpv)\nPlease INSTALL a new one !\n";
}

print "\nChecking for REQUIRED modules:\n------------------------------------------\n";
&check_modules('y', %req_CPAN);
print "\nChecking for OPTIONAL modules:\n------------------------------------------\n";
&check_modules('n', %opt_CPAN);

print <<EOM;
******* NOTE *******
You can retrive all theses modules from any CPAN server
(for example ftp://ftp.pasteur.fr/pub/computing/CPAN/CPAN.html)
EOM
###--------------------------
# reports modules status
###--------------------------
sub check_modules {
    my($default, %todo) = @_;
    my($vs, $v, $rv, $status);

    print "perl module          from CPAN       STATUS\n"; 
    print "-----------          ---------       ------\n";

    foreach $mod (sort keys %todo) {
	printf ("%-20s %-15s", $mod, $todo{$mod});
	$status = &test_module($mod);
	if ($status == 1) {
	    $vs = "$mod" . "::VERSION";
	    $v = $$vs;
	    $rv = $versions{$mod} || "1.0" ;
	    ### OK: check version
	    if ($v ge $rv) {
		printf ("OK (%-6s >= %s)\n", $v, $rv);
		next;
	    }else {
		print "version is too old ($v < $rv).\n";
                print ">>>>>>> You must update \"$todo{$mod}\" to version \"$versions{$todo{$mod}}\" <<<<<<.\n";
		&install_module($mod, $default);
	    }
	} elsif ($status eq "nofile") {
	    ### not installed
	    print "was not found on this system.\n";

	    &install_module($mod, $default);

	} elsif ($status eq "pb_retval") {
	    ### doesn't return 1;
	    print "$mod doesn't return 1 (check it).\n";
	} else {
	    print "$status";
	}
    }
}

##----------------------
# Install a CPAN module
##----------------------
sub install_module {
    my ($module, $default) = @_;

    unless ($ENV{'FTP_PASSIVE'} eq 1) {
	$ENV{'FTP_PASSIVE'} = 1;
	print "Setting FTP Passive mode\n";
    }

    ## This is required on RedHat 9 for DBD::mysql installation
    my $lang = $ENV{'LANG'};
    $ENV{'LANG'} = 'C' if ($ENV{'LANG'} eq 'en_US.UTF-8');

    unless ($> == 0) {
	print "\#\# You need root privileges to install $module module. \#\#\n";
	print "\#\# Press the Enter key to continue checking modules. \#\#\n";
	my $t = <STDIN>;
	return undef;
    }

    printf "Description: %s\n", $opt_features{$module};
    print "Install module $module ? [$default]";
    my $answer = <STDIN>; chomp $answer;
    $answer ||= $default;
    next unless ($answer =~ /^y$/i);
  CPAN::Shell->conf('inactivity_timeout', 4);
    CPAN::Shell->install($module);

    ## Restore lang
    $ENV{'LANG'} = $lang if (defined $lang);

}

###--------------------------
# test if module is there
# (from man perlfunc ...)
###--------------------------
sub test_module {
    my($filename) = @_;
    my($realfilename, $result);

    $filename =~ s/::/\//g;
    $filename .= ".pm";
    return 1 if $INC{$filename};
    
  ITER: {
      foreach $prefix (@INC) {
	  $realfilename = "$prefix/$filename";
	  if (-f $realfilename) {
	      $result = do $realfilename;
	      last ITER;
	  }
      }
      return "nofile";
  }
    return "pb_retval" unless $result;
    return $result;
}
### EOF


