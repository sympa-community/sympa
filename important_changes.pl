# important_changes.pl - This script prints important changes in Sympa since last install
# It is based on the NEWS ***** entries
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

## Print important changes in Sympa since last install
## It is based on the NEWS ***** entries

use strict;
use version;
use Getopt::Long;

my %options;
GetOptions(
    \%options,
    'current=s',
    'previous=s',
);

die "no current given version, aborting" unless $options{current};

if (!$options{previous}) {
    print STDERR "No previous version given, assuming first installation";
    exit 0;
}

# use version objects
my $previous_version = version->new($options{previous});
my $current_version = version->new($options{current});

# exit immediatly if previous version is higher or equal
exit 0 if $previous_version >= $current_version;

print <<EOF;
You are upgrading from Sympa $previous_version
You should read CAREFULLY the changes listed below
They might be incompatible changes:
EOF

## Extracting Important changes from release notes
open NEWS, 'NEWS';
my ($current, $ok);
while (my $line = <NEWS>) {
    
    # extract version tags
    if (/^([\w.]+)\s/) {
        my $version = version->new($1);
        if ($previous_version >= $version) {
            last;
        } elsif ($version == $current_version) {
            $ok = 1;
        }
    }

    # start printing lines only after current version
    next unless $ok;

    print $line if $line =~ /^\*{4}/;
}
close NOTES;
