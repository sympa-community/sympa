#!/usr/bin/perl
# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# This file is part of Sympa, see top-level README.md file for details

# Author: Gábor Hargitai <higany@sch.bme.hu.>

use strict;
my $dir = "./sympa-5.0b.1";

open(wwsympa, "<$dir/wwsympa/wwsympa.fcgi");
open(error,   "<$dir/web_tt2/error.tt2");
my %errors;
while (<wwsympa>) {
    if (/.*\&error_message\(\'(\w*)\'(.*)\);/) {
        $errors{$1} = $2;
    }
}
while (<error>) {
    if (/.*error\.msg[ =]*\'(\w*)\'.*/) {
        if (defined($errors{$1})) {
            delete $errors{$1};
        }
    }
}
print "Missing error messages:\n\n\n";
my ($name, $param);
while (($name, $param) = each(%errors)) {
#	printf "%15s%s\n",$name,$param;
    print "[% ELSIF error.msg == '$name' %]\n";
    print "[%|loc";
    if ($param ne "") {
        $param =~ /.*,.*\{\'(\w*)\'.*=>.*/;
        print "(error.$1)";
    }
    print "%]*****************[%END%]\n\n";
}

seek wwsympa, 0, 0;
open(notice, "<$dir/web_tt2/notice.tt2");
my %notices;
while (<wwsympa>) {
    if (/.*\&message\(\'(\w*)\'(.*)\);/) {
        $notices{$1} = $2;
    }
}
while (<notice>) {
    if (/.*notice\.msg[ =]*\'(\w*)\'.*/) {
        if (defined($notices{$1})) {
            delete $notices{$1};
        }
    }
}
print "\n\n\n\nMissing notice messages:\n\n\n";
my ($name, $param);
while (($name, $param) = each(%notices)) {
#	printf "%15s%s\n",$name,$param;
    print "[% ELSIF notice.msg == '$name' %]\n";
    print "[%|loc";
    if ($param ne "") {
        $param =~ /.*,.*\{\'(\w*)\'.*=>.*/;
        print "(notice.$1)";

    }
    print "%]*****************[%END%]\n\n";
}
