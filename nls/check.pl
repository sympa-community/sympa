#!/usr/bin/perl


# checking nls, add a new langage : just next line
my @langages = ("us.msg","fr.msg","es.msg","de.msg","it.msg","et.msg");

# fr.msg is used as the reference nls
my $reference = "fr.msg";

unless (open MSG,"$reference") {
    print "fatal error unable to open $reference\n";
    exit 1;
}
my $set;

while (<MSG>) {

    if (/^(\d+)\t/) {
	$msg = $1;
 	$cat{$reference}[$set][$msg] = 1;
#       print "\t$msg\n";
    }elsif (/^\$delset\s(\d+)/) {
	$set = $1;
#       print "delset $1 ($reference)\n";
    }
}
close MSG;    


foreach $langage (@langages) {
    next if ($langage eq $reference);
 
    unless (open MSG,"$langage") {
	print "fatal error unable to open $langage\n";
	exit 1;
    }
    print "---------- $langage\n";    
    my $set;
    while (<MSG>) {
	
	if (/^(\d+)\t/) {
	    $msg = $1;
	    $cat{$langage}[$set][$msg] = 1;
#           print "\t$msg\n";
	    if ($cat{$reference}[$set][$msg] != 1) {
		printf "delset %s, msg %s defined in %s but not in %s\n",$set,$msg,$langage,$reference;
	    }
	}elsif (/^\$delset\s(\d+)/) {
	    $set = $1;
#           print "delset $1 ($langage)\n"
	}
    }
    close MSG;    
}


foreach $src ("sympa.pl","List.pm","Version.pm","Log.pm","Conf.pm","Archive.pm","Commands.pm","Language.pm","msg.pl","mail.pl","smtp.pm","subst.pl","tools.pl") {
    unless (open SRC, "../src/$src") {
	print STDERR "unable to open file $src\n";
    }
    while (<SRC>) {
	if (/Msg\s*\(\s*(\d+)\s*\,\s*(\d+)/) {
	    $cat{src}[$1][$2] = 1;
            foreach $langage (@langages){
		if ($cat{$langage}[$1][$2] != 1) {
		    printf "delset $1, msg $2 use in file $src but undefined in nls $langage\n";
		}
	    }
	}
    }
    close SRC ;
}

foreach $category (keys %cat) {
#    print "$category\n";

    foreach $delset (1..$#{$cat{$category}}){
    my $head="-------------  DELSET $delset\n";
#	print "\t$delset\n";
	    foreach $msg (1..$#{$cat{$category}[$delset]}) {
#		print"\t\t$msg\n";
		my $at_least_one_is_defined = 0;
                my $error = '';
		foreach $cat2 (keys %cat) {
		    if ($cat{$cat2}[$delset][$msg] != 1) {
			$error = "$error\t\t\t msg ($delset,$msg)  undefined in $cat2\n";
		    }
		    else{
			$at_least_one_is_defined = 1;
		    }
                
		}
#		print "define $at_least_one_is_defined\n";

		if ($at_least_one_is_defined  != 0) {
		    print "$head$error" ;
                    $head='';
		}
		
        
	}

    }


}






