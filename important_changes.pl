## Print important changes in Sympa since last install
## It is based on the RELEASE_NOTES ***** entries

my ($first_install, $current_version, $previous_version);

$current_version = $ENV{'SYMPA_VERSION'};

unless ($current_version) {
    print STDERR "Could not get current Sympa version\n";
    exit -1;
}

## Get previous installed version of Sympa
unless (open VERSION, "$ENV{'BINDIR'}/Version.pm") {
    print STDERR "Could not find previous install of Sympa ; asuming first install\n";
    exit 0;
}

unless ($first_install) {
    while (<VERSION>) {
	if (/^\$Version = \'(\S+)\'\;/) {
	    $previous_version = $1;
	    last;
	}
    }
}
close VERSION;

print "You are upgrading from Sympa $previous_version\nYou should read CAREFULLY the changes listed below ; they might be uncompatible changes :\n<RETURN>";
my $wait = <STDIN>;

## Extracting Important changes from release notes
open NOTES, 'RELEASE_NOTES';
my ($current, $ok);
while (<NOTES>) {
    if (/^$previous_version/) {
	last;
    }elsif (/^$current_version/) {
	$ok = 1;
    }

    next unless $ok;

    if (/^\*{4}/) {
	print "\n" unless $current;
	$current = 1;
	print;
    }else {
	$current = 0;
    }
    
}
close NOTES;
print "<RETURN>";
my $wait = <STDIN>;

