
my ($begchar, $endchar) = ('{','}');

my $file = $ARGV[0];

unless ($file) {
    die "Missing parameter";
}

unless (-r $file) {
    die "Cannot read $file file";
}

## Get current counter
open COUNTER, "counter";
my $max = &get_max($file);

open INPUT, $file;
open OUTPUT, ">$file.new";
while (<INPUT>) {
    s/{([^}]+)}/&parse($1)/eg;
    print OUTPUT;
}
close INPUT;
close OUPUT;

rename "$file.new", $file;

sub get_max {
    my $f = shift;
    my $max = 0;

    open F, $f;
    while (<F>) {
	s/{ref(\d+)[^}]+}/&count($1, \$max)/eg;
    }
    close F;

    return $max;
}

sub count {
    my ($val, $max) = @_;

    if ($val > $$max) {
	$$max = $val;
    }
    return 'DONE';
}

sub parse {
    my $string = pop;

    unless ($string =~ /^ref\d+:/) {
	$max++;
	return '{'."ref$max:$string".'}';
    } 

    return '{'.$string.'}';
} 
