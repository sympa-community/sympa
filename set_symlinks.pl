## Set symbolic links at installation time

my @scenario_defaults = ('add.owner',
			 'create_list.intranet',
			 'd_edit.owner',
			 'd_read.private',
			 'del.owner',
			 'info.open',
			 'invite.private',
			 'remind.owner',
			 'review.owner',
			 'review.public',
			 'send.private',
			 'subscribe.open',
			 'topics_visibility.noconceal',
			 'unsubscribe.open',
			 'visibility.conceal'
			 );

$default_lang = 'us';

my %wws_template_equiv = ('lists' => ['which', 'search_list','search_user'],
			  'review' => ['search']
			  );

unless ($#ARGV >= 1) {
    printf STDERR "Usage %s wws_templates|templates|scenari <install directory>\n", $0;
    exit -1;
}

my ($action, $dir) = ($ARGV[0], $ARGV[1]);

unless ($action =~ /^wws_templates|templates|scenari$/) {
    printf STDERR "Usage %s wws_templates|templates|scenari <install directory>\n", $0;
    exit -1;
}
 
unless ((-d $dir) && (-w $dir)) {
    printf STDERR "Directory %s, not found or no write access\n", $dir;
    exit -1;
}

if ($action eq 'scenari') {
    chdir $dir;
    foreach my $s (@scenario_defaults) {
	unless (-f $s) {
	    printf STDERR "File not found: %s\n", $s;
	    next;
	}
	
	$s =~ /^(.+)\.[^\.]+$/;
	$default_file = $1.'.default';

	if (-f $default_file) {
	    unless (unlink $default_file) {
		printf STDERR "Cannot delete file %s : %s\n", $default_file, $!;
		next;
	    }
	}

	printf "Setting symlink: %s => %s\n", $default_file, $s;
	unless (symlink $s, $default_file) {
	    printf STDERR "Failed to set symlink %s: %s\n", $default_file, $!;
	    next;
	}
	
    }
}elsif ($action eq 'wws_templates') {
    chdir $dir;
    ## Set defaults
    unless (opendir DIR, '.') {
	printf STDERR "Failed to open directory %s: %s\n", $dir, $!;
	next;
    }

    foreach my $tpl (grep /\.$default_lang\.tpl$/, readdir(DIR)) {
	$tpl =~ /^(.+)\.$default_lang\.tpl$/;
	my $link = $1.'.tpl';

	if (-f $link) {
	    unless (unlink $link) {
		printf STDERR "Cannot delete file %s : %s\n", $link, $!;
		next;
	    }
	}

	printf "Setting symlink: %s => %s\n", $link, $tpl;
	unless (symlink $tpl, $link) {
	    printf STDERR "Failed to set symlink %s: %s\n", $link, $!;
	    next;
	}
    }
    closedir DIR;
    

    ## Set equiv
    unless (opendir DIR, '.') {
	printf STDERR "Failed to open directory %s: %s\n", $dir, $!;
	next;
    }

    foreach my $tpl (grep /\.tpl$/, readdir(DIR)) {
	$tpl =~ /^(\w+)\.(.+)$/;
	my ($action, $suffix) = ($1, $2);

	if (defined $wws_template_equiv{$action}) {
	    foreach my $equiv (@{$wws_template_equiv{$action}}) {
		my $link = $equiv . '.' . $suffix;
		
		if (-f $link) {
		    unless (unlink $link) {
			printf STDERR "Cannot delete file %s : %s\n", $link, $!;
			next;
		    }
		}

		printf "Setting symlink: %s => %s\n", $link, $tpl;
		unless (symlink $tpl, $link) {
		    printf STDERR "Failed to set symlink %s: %s\n", $link, $!;
		    next;
		}

	    }
	}

	
    }
    closedir DIR;

}elsif ($action eq 'templates') {
    chdir $dir;
    ## Set defaults
    unless (opendir DIR, '.') {
	printf STDERR "Failed to open directory %s: %s\n", $dir, $!;
	next;
    }

    foreach my $tpl (grep /\.$default_lang\.tpl$/, readdir(DIR)) {
	$tpl =~ /^(.+)\.$default_lang\.tpl$/;
	my $link = $1.'.tpl';

	if (-f $link) {
	    unless (unlink $link) {
		printf STDERR "Cannot delete file %s : %s\n", $link, $!;
		next;
	    }
	}

	printf "Setting symlink: %s => %s\n", $link, $tpl;
	unless (symlink $tpl, $link) {
	    printf STDERR "Failed to set symlink %s: %s\n", $link, $!;
	    next;
	}
    }
    closedir DIR;
}

exit 0;
