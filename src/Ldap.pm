## This module handles the configuration file for Sympa.

package Ldap;

use Conf;

require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(%Ldap);

my @valid_options = qw(host port suffix filter scope);

my %valid_options = ();
map { $valid_options{$_}++; } @valid_options;

my %Default_Conf =
    ( 	'host'=> undef,
    	'port' => undef,
    	'suffix' => undef,
    	'filter' => undef,
    	'scope' => undef
   );

%Ldap = ();

## Loads and parses the configuration file. Reports errors if any.
sub load {
    my $config = shift;
    my $line_num = 0;
    my $config_err = 0;
    my($i, %o);

    ## Open the configuration file or return and read the lines.
    unless (open(IN, $config)) {
	printf STDERR  "load: Unable to open %s: %s\n", $config, $!;
	return undef;
    }
    while (<IN>) {
	$line_num++;
	next if (/^\s*$/o || /^[\#\;]/o);

	if (/^(\S+)\s+(.+)$/io) {
	    my($keyword, $value) = ($1, $2);
	    $value =~ s/\s*$//;
	
	    $o{$keyword} = [ $value, $line_num ];
	}else {
#	    printf STDERR Msg(1, 3, "Malformed line %d: %s"), $config, $_;
	    $config_err++;
	}
    }
    close(IN);


    ## Check if we have unknown values.
    foreach $i (sort keys %o) {
	next if ($valid_options{$i});
	printf STDERR  "Line %d, unknown field: %s \n", $o{$i}[1], $i;
	$config_err++;
    }
    ## Do we have all required values ?
    foreach $i (keys %valid_options) {
	unless (defined $o{$i} or defined $Default_Conf{$i}) {
	    printf "Required field not found : %s\n", $i;
	    $config_err++;
	    next;
	}
	$Ldap{$i} = $o{$i}[0] || $Default_Conf{$i};
	
    }
 return %Ldap;
}

## Packages must return true.
1;






