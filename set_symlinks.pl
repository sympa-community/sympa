# set_symlinks.pl - This script sets symbolic links at installation time
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
## Set symbolic links at installation time

my @scenario_defaults = ('add.owner',
			 'd_edit.owner',
			 'd_read.private',
			 'del.owner',
			 'info.open',
			 'invite.private',
			 'remind.owner',
			 'review.owner',
			 'send.private',
			 'subscribe.open',
			 'topics_visibility.noconceal',
			 'unsubscribe.open',
			 'visibility.conceal'
			 );

$default_lang = 'us';

my %wws_template_equiv = ('lists' => ['which', 'search_list'],
			  'review' => ['search']
			  );

unless ($#ARGV >= 1) {
    printf STDERR "Usage %s web_tt2|mail_tt2|scenari <install directory>\n", $0;
    exit -1;
}

my ($action, $dir) = ($ARGV[0], $ARGV[1]);

unless ($action =~ /^web_tt2|mail_tt2|scenari$/) {
    printf STDERR "Usage %s web_tt2|mail_tt2|scenari <install directory>\n", $0;
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
}elsif ($action eq 'web_tt2') {
    chdir $dir;

    ## Set equiv
    unless (opendir DIR, '.') {
	printf STDERR "Failed to open directory %s: %s\n", $dir, $!;
	next;
    }

    foreach my $tpl (grep /\.tt2$/, readdir(DIR)) {
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

}elsif ($action eq 'mail_tt2') {
    chdir $dir;
}

exit 0;
