# check for perl and modules for SYMPA
#
# Laurent Ghys (Laurent.Ghys@ircam.fr)
#
# Changes
# 04/03/2001 [OS] Add DBD drivers
#                 Perl 5.005 is required because of CipherSaber
# 03/02/2001 [SA] Add Cipher:Saber as a optional module
# 03/08/2000 [O Salaun] arg passed to CPAN::Shell->install() is the module name
# 02/08/2000 [O Salaun] require CGI 2.52 (Vars())
# 26/07/2000 [O Salaun] corrected MIME::Tools to MIME::tools
# 13/07/2000 [L Ghys]   sort %todo to avoid error message with CGI::Fast
# 10/07/2000 [O Salaun] MIME::tools now require File::Spec
# 19/06/2000 [O Salaun] require Net::LDAP 0.19
# 05/06/2000 [O Salaun] Installing required modules
# 31/05/2000 [O Salaun] Added FCGI & CGI::Fast
# 12/05/99 [O Salaun] Net-LDAP changed to Netperl-ldap 
# 20/05/99 [L Ghys]   added stuff for CPAN modules

use CPAN;

## assume version = 1.0 if not specified.
## 
%versions = ('perl' => '5.005',
             'Net::LDAP' =>, '0.10', 
	     'perl-ldap' => '0.10',
	     'Mail::Internet' => '1.32', 
	     'DBI' => '1.06',
	     'DBD::Pg' => '0.90',
	     'DBD::Sybase' => '0.90',
	     'FCGI' => '0.48',
	     'MIME::Tools' => '5.209',
	     'File::Spec' => '0.8',
             'Crypt::CipherSaber' => '0.50',
	     'CGI' => '2.52');

### key:left "module" used by SYMPA, 
### right CPAN module.		     
%req_CPAN = ('DB_File' => 'DB_FILE',
	     'Locale::Msgcat' => 'Msgcat',
	     'MD5' => 'MD5',
	     'Mail::Internet' =>, 'MailTools',
	     'IO::Scalar' => 'IO-stringy',
	     'MIME::Tools' => 'MIME-tools',
	     'MIME::Base64' => 'MIME-Base64',
	     'CGI' => 'CGI',
	     'File::Spec' => 'File-Spec');

%opt_CPAN = ('DBI' => 'DBI',
	     'DBD::mysql' => 'Msql-Mysql-modules',
	     'DBD::Pg' => ' DBD-Pg',
	     'DBD::Oracle' => 'DBD-Oracle',
	     'DBD::Sybase' => 'DBD-Sybase',
	     'Net::LDAP' =>   'perl-ldap',
	     'CGI::Fast' => 'CGI',
             'Crypt::CipherSaber' => 'CipherSaber',
	     'FCGI' => 'FCGI');

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
	    print "seems to be not available on this system.\n";

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

    unless ($> == 0) {
	print "\#\# You need root privileges to install $module module. \#\#\n";
	print "\#\# Press the Enter key to continue checking modules. \#\#\n";
	my $t = <STDIN>;
	return undef;
    }

    print "Install module $module ? [$default]";
    my $answer = <STDIN>; chomp $answer;
    $answer ||= $default;
    next unless ($answer =~ /^y$/i);
  CPAN::Shell->conf('inactivity_timeout', 4);
    CPAN::Shell->install($module);
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


