## This module does just the initial setup for the international
## messages.

package Language;

require Exporter;
use Carp;
@ISA = qw(Exporter);
@EXPORT = qw(Msg);

use strict;
use Locale::Msgcat;
use Log;
use Version;

my %Message;

my $dir;
my $current_lang;
my $default_lang;

sub LoadLang {
    my $catdir = pop;

    unless (-d $catdir && -r $catdir) {
	do_log('info','Cannot read Locale directory %s', $catdir);
	return undef;
    }

    $dir = $catdir;

    unless (opendir CATDIR, $catdir) {
	do_log('info','Unable to open directory %s', $catdir);
	return undef;
    }

    foreach my $file (grep /\.cat$/, readdir(CATDIR)) {    

	$file =~ /^([\w-]+)\.cat$/;
	
	my $catname = $1;

	my $catfile = $catdir.'/'.$catname.'.cat';
	unless (-r $catfile) {
	    do_log('info','Locale file %s not found', $catfile);
	    return undef;
	}

	$Message{$catname} = new Locale::Msgcat;

	unless ($Message{$catname}->catopen($catfile, 1)) {
	    do_log('info','Locale file %s.cat not used, using builtin messages', $catname);
	    return undef;
	}
	
	$current_lang = $catname;
	do_log('info', 'Loading locale file %s.cat version %s', $catname, Msg(1, 102, $Version));	
    }
    closedir CATDIR;

    return 1;
}

sub SetLang {
    my $catname = shift;
    
    unless (defined ($Message{$catname})) {
	do_log('info','unknown Locale %s', $catname);
	return undef;
    }
	    
    $current_lang = $catname;
    return 1;
}

sub Msg {
    
    if (defined ($Message{$current_lang})) {
	$Message{$current_lang}->catgets(@_);
    }else {
	$_[2];
    }
}

sub GetLang {
    return $current_lang;
}

1;

