#!/usr/bin/perl

# this script is intended to create automatically list aliases
# when using sympa. Aliases can be added or removed in file $path_alias

my $path_alias = '/tmp/aliases.listes';
my $defaultdomaine = 'cru.fr';

($operation,$listname,$domaine,$path_to_queue,$path_to_bouncequeue) = @ARGV;

if (($#ARGV != 4)||($operation !~ /^(add)|(del)$/)) {
    printf "Usage $ARGV[-1] <add|del> <listname> <domaine> <path_to_queue> <path_to_bouncequeue>\n";
    exit(1);
}

unless (-w "$path_alias") {
    printf "Unable to access to $path_alias \n";
    exit(1);
}

if ("$operation" eq 'add') {
    exit(1) if (&allready_defined($listname,$domaine));
    exit(1) if (&allready_defined($listname-request,$domaine));
    exit(1) if (&allready_defined($listname-owner,$domaine));
    exit(1) if (&allready_defined($listname-unsubscribe,$domaine));
    exit(1) if (&allready_defined($listname-subscribe,$domaine));

    open  ALIAS, ">> $path_alias";
    printf ALIAS "$listname\@$domaine: \"\|$path_to_queue $listname\"\n";
    printf ALIAS "$listname-request\@$domaine: \"\|$path_to_queue $listname-request\"\n";
    printf ALIAS "$listname-unsubscribe\@$domaine: \"\|$path_to_queue $listname-unsubscribe\"\n";
    printf ALIAS "\#$listname-subscribe\@$domaine: \"\|$path_to_queue $listname-subscribe\"\n";
    printf ALIAS "$listname-owner\@$domaine: \"\|$path_to_bouncequeue $listname\"\n";
}

sub allready_defined {
    my $local = shift;
    my $domaine = shift;
    
    open  ALIAS, "$path_alias";
    while (<ALIAS>) {
	if (( /^\s*$local(\s*\:)/) ||
	    ( ("$defaultdomaine" eq "$domaine") && (/^\s*$local\@/)) ||
	    ( /^\s*$local\@$domaine/)) {
	    printf "alias allready exist : $local \n";
	    return undef;
	}
    }
    close ALIAS ;
    return (1);
}



