# parse_tex.pl - This script parses parts of the sympa.tex.tpl
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

use lib "../src/";
use lib "../wwsympa/";
use Log;
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
&parser::parse_tpl(\%data, $in_file, \*OUT);
close OUT;

exit 0;
