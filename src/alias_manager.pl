#!--PERL--

# this script is intended to create automatically list aliases
# when using sympa. Aliases can be added or removed in file --SENDMAIL_ALIASES--

my $alias_file = '--SENDMAIL_ALIASES--';
my $tmp_alias_file = '/tmp/sympa_aliases.new';
my $lock_file = '--DIR--/alias_manager.lock';
my $default_domain;
my $path_to_queue = '--MAILERPROGDIR--/queue';
my $path_to_bouncequeue = '--MAILERPROGDIR--/bouncequeue';
my $sympa_conf_file = '--CONFIG--';

my ($operation, $listname, $domain) = @ARGV;

if (($#ARGV != 2) 
    || ($operation !~ /^(add)|(del)$/)) {
    printf "Usage: $0 <add|del> <listname> <domain>\n";
    exit(1);
}

## Get default domain from sympa.conf
unless (open CONF, $sympa_conf_file) {
    die "Could not read $sympa_conf_file";
}
while (<CONF>) {
    if (/^\s*host\s+(\S+)\s*$/) {
	$default_domain = $1;
	last;
    }
}
close CONF;
unless ($default_domain) {
    print STDERR "Could not get default domain from $sympa_conf_file\n";
}

unless (-w "$alias_file") {
    die "Unable to access to $alias_file";
}

if ($operation eq 'add') {
    ## Create a lock
    open(LF, ">>$lock_file") || die "Can't open lock file $lock_file";
    flock LF, 2;

    ## Check existing aliases
    exit(-1) if (&already_defined($listname.$suffix, $domain));
	
    unless (open  ALIAS, ">> $alias_file") {
	die "Unable to append to $alias_file";
    }
    
    ## Write aliases
    print ALIAS "# --- aliases for list $listname\n";
    foreach my $suffix ('', '-request', '-owner', '-unsubscribe') {
	
	my $address = $listname . $suffix;
	$address .= '@'.$domain
	    unless ($domain eq $default_domain);
	
	if ($suffix eq '-owner') {
	    printf ALIAS "$address: \"\|$path_to_bouncequeue $listname\"\n";
	}else {
	    printf ALIAS "$address: \"\|$path_to_queue $listname$suffix\"\n";
	}
    }

    close ALIAS;

    ## Unlock
    flock LF, 8;
    close LF;
    
}elsif ($operation eq 'del') {

    ## Create a lock
    open(LF, ">>$lock_file") || die "Can't open lock file $lock_file";
    flock LF, 2;

    unless (open  ALIAS, "$alias_file") {
	die "Could not read $alias_file";
    }
    
    unless (open NEWALIAS, ">$tmp_alias_file") {
	die "Could not create $tmp_alias_file";
    }

    my $deleted_lines;
  FIC: while (<ALIAS>) {
      if (/^\s*$listname/) {
	  foreach my $suffix ('', '-request', '-owner', '-unsubscribe') {
	      my $local = $listname . $suffix;
	      if (( /^\s*$local(\s*\:)/) ||
		  ( ("$default_domain" eq "$domain") && (/^\s*$local\@/)) ||
		  ( /^\s*$local\@$domain/)) {
		  
		  ## delete alias
		  $deleted_lines++;
		  next FIC;
	      }
	  }
      }
      
      ## append to new aliases file
      print NEWALIAS $_;
  }
    
    close ALIAS ;
    close NEWALIAS;
    
    print STDERR "No matching line in $alias_file\n"
	unless $deleted_lines;
    
    ## replace old aliases file
    unless (open  NEWALIAS, "$tmp_alias_file") {
	die "Could not read $tmp_alias_file";
    }
    
    unless (open OLDALIAS, ">$alias_file") {
	die "Could not overwrite $alias_file";
    }
    print OLDALIAS <NEWALIAS>;
    close OLDALIAS ;
    close NEWALIAS;

    ## Unlock
    flock LF, 8;
    close LF;

}else {
    die "Action $operation not implemented yet";
}

exit 0;

## Check if an alias is already defined  
sub already_defined {
    my $listname = shift;
    my $domain = shift;
    
    unless (open  ALIAS, "$alias_file") {
	die "Could not read $alias_file";
    }

    while (<ALIAS>) {
	if (/^\s*$listname/) {
	    foreach my $suffix ('', '-request', '-owner', '-unsubscribe') {
		my $local = $listname . $suffix;
		if (( /^\s*$local(\s*\:)/) ||
		    ( ("$default_domain" eq "$domain") && (/^\s*$local\@/)) ||
		    ( /^\s*$local\@$domain/)) {
		    print STDERR "Alias already defined : $local\n";
		    return 1;
		}
	    }
	}
    }
    
    close ALIAS ;
    return 0;
}



