#!--PERL--
# postfix_manager.pl - this script is intended to automatically create
# list aliases for Postfix when using Sympa.
# Aliases can be added or removed in files --SENDMAIL_ALIASES--
# and --VIRTUAL_ALIASES-- (for virtual hosts).
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

## Load Sympa.conf
use lib '--LIBDIR--';
use Conf;

unless (Conf::load('--CONFIG--')) {
   print Msg(1, 1, "Configuration file --CONFIG-- has errors.\n");
   exit(1);
}
my $tmp_alias_file = $Conf{'tmpdir'}.'/sympa_aliases.'.time;
my $tmp_virtual_file = $Conf{'tmpdir'}.'/sympa_virtual.'.time;

my $alias_file = '--SENDMAIL_ALIASES--';
my $virtual_file = '--VIRTUAL_ALIASES--';
my $alias_wrapper = '--MAILERPROGDIR--/aliaswrapper';
my $virtual_wrapper = '--MAILERPROGDIR--/virtualwrapper';
my $lock_file = '--DIR--/postfix_manager.lock';
my $default_domain;
my $path_to_queue = '--MAILERPROGDIR--/queue';
my $path_to_bouncequeue = '--MAILERPROGDIR--/bouncequeue';
my $sympa_conf_file = '--CONFIG--';

my @suffixes=('-request', '-editor', '-owner', '-unsubscribe');
my @admin=('sympa', 'listmaster', 'sympa-request', 'sympa-owner',
	   'majordomo', 'listserv', 'listserv-request', 'listserv-owner');

$ENV{'PATH'} = '';

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
    if (/^\s*(host|domain)\s+(\S+)\s*$/) {
	$default_domain = $2;
	last;
    }
}
close CONF;
unless ($default_domain) {
    print STDERR "Could not get default domain from $sympa_conf_file\n";
}

if (-e "$alias_file" && ! -w "$alias_file") {
    die "Unable to access $alias_file";
}

if (-e "$virtual_file" && ! -w "$virtual_file") {
    die "Unable to access $virtual_file";
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

    if ($listname eq 'sympa') {
	
	my $lsuffix = '+'.$domain
	    unless ($domain eq $default_domain);
	my $rsuffix = '@'.$domain
	    unless ($domain eq $default_domain);

	printf ALIAS "sympa$lsuffix: \"|$path_to_queue sympa$rsuffix\"\n";
	printf ALIAS "listmaster$lsuffix: \"|$path_to_queue listmaster$rsuffix\"\n";
	printf ALIAS "bounce+*$lsuffix: \"|$path_to_bouncequeue sympa$rsuffix\"\n";
	printf ALIAS "sympa-request$lsuffix: postmaster$rsuffix\n";
	printf ALIAS "sympa-owner$lsuffix: postmaster$rsuffix\n";
	printf ALIAS "majordomo$lsuffix: sympa$rsuffix\n";
	printf ALIAS "listserv$lsuffix: sympa$rsuffix\n";
	printf ALIAS "listserv-request$lsuffix: sympa-request$rsuffix\n";
	printf ALIAS "listserv-owner$lsuffix: sympa-owner$rsuffix\n";

    } else {

	# print ALIAS "# --- aliases for list $listname\n";
	foreach my $suffix ('', @suffixes) {
	    
	    my $alias = $listname . $suffix;
	    $alias .= '+'.$domain
		unless ($domain eq $default_domain);
	    
	    if ($suffix eq '-owner') {
		printf ALIAS "$alias: \"\|$path_to_bouncequeue $listname\@$domain\"\n";
	    }else {
		printf ALIAS "$alias: \"\|$path_to_queue $listname$suffix\@$domain\"\n";
	    }
	}
    }

    close ALIAS;

    ## Newaliases
    unless (system($alias_wrapper) == 0) {
	die "Failed to execute newaliases: $!";
    }

    unless ($domain eq $default_domain) {
	
	## Check existing aliases in virtual file
	exit(-1) if (&already_defined_virtual($listname.$suffix, $domain));
	
	unless (open  VIRTUAL, ">> $virtual_file") {
	    die "Unable to append to $virtual_file";
	}
	
	## Write aliases to virtual file

	if ($listname eq 'sympa') {
	    
	    foreach my $alias (@admin, 'bounce+*') {
		
		printf VIRTUAL "$alias\@$domain $alias+$domain\n";
	    }
	} else {
	    
	    # print VIRTUAL "# --- aliases for list $listname\n";
	    foreach my $suffix ('', @suffixes) {
		
		my $alias = $listname . $suffix;
		printf VIRTUAL "$alias\@$domain $alias+$domain\n";
	    }
	}
	
	close VIRTUAL;
	
	## Postmap
	unless (system($virtual_wrapper) == 0) {
	    die "Failed to execute postmap: $!";
	}
	
    }

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
      
      if ($listname eq 'sympa') {
	  
	  foreach my $local (@admin, 'bounce\+\*') {
	      if (( ("$default_domain" eq "$domain") && (/^\s*$local\:/)) ||
		  ( /^\s*$local\+$domain/)) {
		  
		  ## delete alias
		  $deleted_lines++;
		  next FIC;
	      }
	  }  
      } else {
	  
	  if (/^\s*$listname/) {
	      
	      foreach my $suffix ('', @suffixes) {
		  my $local = $listname . $suffix;
		  if (( ("$default_domain" eq "$domain") && (/^\s*$local\:/)) ||
		      ( /^\s*$local\+$domain/)) {
		      
		      ## delete alias
		      $deleted_lines++;
		      next FIC;
		  }
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
    unlink $tmp_alias_file;

    ## Newaliases
    unless (system($alias_wrapper) == 0) {
	die "Failed to execute newaliases: $!";
    }

    unless ($domain eq $default_domain) {
	
	unless (open  VIRTUAL, "$virtual_file") {
	    die "Could not read $virtual_file";
	}
	
	unless (open NEWVIRTUAL, ">$tmp_virtual_file") {
	    die "Could not create $tmp_virtual_file";
	}
		
	my $deleted_lines;
      FIC: while (<VIRTUAL>) {
	  
	  if ($listname eq 'sympa') {
	      
	      foreach my $local (@admin, 'bounce\+\*') {
		  if ( /^\s*$local\@$domain/) {
		      
		      ## delete alias
		      $deleted_lines++;
		      next FIC;
		  }
	      }
	  } else {
	      if (/^\s*$listname/) {
		  
		  foreach my $suffix ('', @suffixes) {
		      my $local = $listname . $suffix;
		      if ( /^\s*$local\@$domain/) {
			  
			  ## delete alias
			  $deleted_lines++;
			  next FIC;
		      }
		  }
	      }
	  }

	  ## append to new aliases file
	  print NEWVIRTUAL $_;
      }
	
	close VIRTUAL ;
	close NEWVIRTUAL;
	
	print STDERR "No matching line in $virtual_file\n"
	    unless $deleted_lines;
	
	## replace old virtual file
	unless (open  NEWVIRTUAL, "$tmp_virtual_file") {
	    die "Could not read $tmp_virtual_file";
	}
	
	unless (open OLDVIRTUAL, ">$virtual_file") {
	    die "Could not overwrite $virtual_file";
	}
	print OLDVIRTUAL <NEWVIRTUAL>;
	close OLDVIRTUAL ;
	close NEWVIRTUAL;
	unlink $tmp_virtual_file;
	
	## Postalias
	unless (system($virtual_wrapper) == 0) {
	    die "Failed to execute postalias: $!";
	}
    }

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
	    foreach my $suffix ('', @suffixes) {
		my $local = $listname . $suffix;
		if (( ("$default_domain" eq "$domain") && (/^\s*$local\:/)) ||
		    ( /^\s*$local\+$domain/)) {
		    print STDERR "Alias already defined : $local\n";
		    return 1;
		}
	    }
	}
    }
    
    close ALIAS ;
    return 0;
}

## Check if a virtual alias is already defined  
sub already_defined_virtual {
    my $listname = shift;
    my $domain = shift;
    
    unless (open  VIRTUAL, "$virtual_file") {
	die "Could not read $virtual_file";
    }

    while (<VIRTUAL>) {
	if (/^\s*$listname/) {
	    foreach my $suffix ('', @suffixes) {
		my $local = $listname . $suffix;
		if ( /^\s*$local\@$domain/ ) {
		    print STDERR "Virtual alias already defined : $local\n";
		    return 1;
		}
	    }
	}
    }
    
    close VIRTUAL ;
    return 0;
}
