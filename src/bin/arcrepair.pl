#! /usr/bin/perl

## This script should be run on server where Sympa 4.1 has been running
## Sympa 4.1 included a bug that lead to incorrect archiving of messages
## This script will detect incorrectly archived messages and move them back 
## in the archiving spool (outgoing)

unless ($#ARGV >= 0) {
    die "Usage: $0 <path_to_outgoing_dir> <path_to_web_archives>";
}

my $outgoing = $ARGV[0];
my $arc_path = $ARGV[1];

unless (-d $outgoing) {
    die "Missing directory $outgoing";
}

unless (-d $arc_path) {
    die "Missing directory $arc_path";
}

opendir(DIR, $arc_path);
my @files =  (grep(!/^\.{1,2}$/, readdir DIR ));

my $i = 0;

foreach my $d1 (@files) {
    if ($d1 =~ /\.(\d+)$/) {
	my $f1 = "$arc_path/$d1/1970-01/arctxt/1";
	unless (-f $f1) {
	    die "Could not find $f1";
	    next;
	}
	print "Moving $f1 to $outgoing/$d1.$i\n";
	rename $f1, "$outgoing/$d1.$i";      
	$i++;
	`rm -rf $arc_path/$d1`;
    }
}
closedir DIR;
