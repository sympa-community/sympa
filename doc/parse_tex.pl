use lib "../src/";
use Conf;
use POSIX;
require "parser.pl";

my $in_file = $ARGV[0];
my $out_file = $ARGV[1];

$ENV{'LC_ALL'} = 'C';

my $date = (stat($in_file))[9];

open VERSION, '../.version';
my $version = <VERSION>;
chomp $version;
close VERSION;

## Init struct
my %data = ('escaped_start' => '[STARTPARSE]',
	    'date' => &POSIX::strftime("%d %B %Y", localtime((stat($in_file))[9])),
	    'version' => $version
	    );
## scenari
foreach my $file (<../src/etc/scenari/*.*>) {
    $file =~ /\/(\w+)\.(\w+)$/;
    my ($action, $name) = ($1, $2);
    my $title;
    open SCENARIO, $file;
    while (<SCENARIO>) {
	if (/^title.us\s*(.*)$/) {
	    $title = $1; last;
	}
    }
    close SCENARIO;
    $name =~ s/\_/\\\_/g;
    push @{$data{'scenari'}{$action}}, {'name' => $name,'title' => $title};
}

open OUT, ">$out_file" || die;
&parse_tpl(\%data, $in_file, \*OUT);
close OUT;

exit 0;
