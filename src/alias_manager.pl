#!--PERL--
# alias_manager.pl -  this script is intended to create automatically list aliases
# when using sympa. Aliases can be added or removed in file --SENDMAIL_ALIASES--
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
use strict;
use lib '--LIBDIR--';
use Conf;
use POSIX;
require "tools.pl";
require "parser.pl";


unless (Conf::load('--CONFIG--')) {
   print Msg(1, 1, "Configuration file --CONFIG-- has errors.\n");
   exit(1);
}
my $tmp_alias_file = $Conf{'tmpdir'}.'/sympa_aliases.'.time;

my $alias_file = '--SENDMAIL_ALIASES--';
my $alias_wrapper = '--MAILERPROGDIR--/aliaswrapper';
my $lock_file = '--DIR--/alias_manager.lock';
my $default_domain;
my $path_to_queue = '--MAILERPROGDIR--/queue';
my $path_to_bouncequeue = '--MAILERPROGDIR--/bouncequeue';
my $sympa_conf_file = '--CONFIG--';

$ENV{'PATH'} = '';

my ($operation, $listname, $domain) = @ARGV;


if (($#ARGV != 2) 
    || ($operation !~ /^(add)|(del)$/)) {
    printf "Usage: $0 <add|del> <listname> <domain>\n";
    exit(2);
}

$default_domain = $Conf{'domain'};

unless (-w "$alias_file") {
    print STDERR "Unable to access $alias_file";
    exit(5);
}
    
my %data;
$data{'date'} =  &POSIX::strftime("%d %b %Y", localtime(time));
$data{'path_to_queue'} = '--MAILERPROGDIR--/queue';
$data{'path_to_bouncequeue'} = '--MAILERPROGDIR--/bouncequeue';
$data{'domain'} = $data{'robot'} = $domain;
$data{'listname'} = $listname;
$data{'default_domain'} = $default_domain;
$data{'is_default_domain'} = 1 if ($domain eq $default_domain);
my $template_file = &tools::get_filename('etc', 'alias.tpl', $domain);
my @aliases ;
&parser::parse_tpl (\%data,$template_file,\@aliases);


if ($operation eq 'add') {
    ## Create a lock
    unless (open(LF, ">>$lock_file")) { 
	print STDERR "Can't open lock file $lock_file";
	exit(14);
    }
    flock LF, 2;

    ## Check existing aliases
    if (&already_defined(@aliases)) {
	printf STDERR "some alias already exist\n";
	exit(13);
    }

    unless (open  ALIAS, ">> $alias_file") {
	print STDERR "Unable to append to $alias_file";
	exit(5);
    }

    foreach (@aliases) {
	print ALIAS "$_";
    }
    close ALIAS;

    ## Newaliases
    unless (system($alias_wrapper) == 0) {
	print STDERR "Failed to execute newaliases: $!";
	exit(6)
    }

    ## Unlock
    flock LF, 8;
    close LF;
    
}elsif ($operation eq 'del') {

    ## Create a lock
    open(LF, ">>$lock_file") || die "Can't open lock file $lock_file";
    flock LF, 2;

    unless (open  ALIAS, "$alias_file") {
	print STDERR "Could not read $alias_file";
	exit(7);
    }
    
    unless (open NEWALIAS, ">$tmp_alias_file") {
	printf STDERR "Could not create $tmp_alias_file";
	exit (8);
    }

    my @deleted_lines;
    while (my $alias = <ALIAS>) {
	my $left_side = '';
	$left_side = $1 if ($alias =~ /^([^:]+):/);

	my $to_be_deleted = 0;
	foreach my $new_alias (@aliases) {
	    next unless ($new_alias =~ /^([^:]+):/);
	    my $new_left_side = $1;
	    
	    if ($left_side eq  $new_left_side) {
		push @deleted_lines, $alias;
		$to_be_deleted = 1 ;
		last;
	    }
	}
	unless ($to_be_deleted)  {
	    ## append to new aliases file
	    print NEWALIAS $alias;
	}
    }
    close ALIAS ;
    close NEWALIAS;
    
    if ($#deleted_lines == -1) {
	print STDERR "No matching line in $alias_file\n" ;
	exit(9);
    }
    ## replace old aliases file
    unless (open  NEWALIAS, "$tmp_alias_file") {
	print STDERR "Could not read $tmp_alias_file";
	exit(10);
    }
    
    unless (open OLDALIAS, ">$alias_file") {
	print STDERR "Could not overwrite $alias_file";
	exit (11);
    }
    print OLDALIAS <NEWALIAS>;
    close OLDALIAS ;
    close NEWALIAS;
    unlink $tmp_alias_file;

    ## Newaliases
    unless (system($alias_wrapper) == 0) {
	print STDERR "Failed to execute newaliases: $!";
	exit (6);
    }

    ## Unlock
    flock LF, 8;
    close LF;

}else {
    print STDERR "Action $operation not implemented yet";
    exit(2);
}

exit 0;

## Check if an alias is already defined  
sub already_defined {
    my @aliases = @_;
    
    unless (open  ALIAS, "$alias_file") {
	printf STDERR "Could not read $alias_file";
	exit (7);
    }

    while (my $alias = <ALIAS>) {
	# skip comment
	next if $alias =~ /^#/ ; 
	$alias =~ /^([^:]+):/;
	my $left_side = $1;
	next unless ($left_side);
	foreach (@aliases) {
	    next unless ($_ =~ /^([^:]+):/); 
	    my $new_left_side = $1;
	    if ($left_side eq  $new_left_side) {
		print STDERR "Alias already defined : $left_side\n";
		return 1;
	    }
	}	
    }
    
    close ALIAS ;
    return 0;
}



