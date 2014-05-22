#!/usr/bin/perl

use strict;
use Getopt::Long;

my $lang;
GetOptions('lang=s' => \$lang) or die;
die unless $lang;

$/ = '';

while (<>) {
    last if /(\n|\A)msgid\s+/;
    print $_;
}

s/\"\n\"//g;
@_ = split /\n/, $_;
foreach my $line (@_) {
    if ($line =~ /\Amsgstr\s+\"(.*)\"\z/) {
        my $str = $1;
        $str =~ s/(\A|\\n)Language:(\\.|.)*?(?=\\n)/${1}Language: $lang/i
            or $str =~ s/\\n\z/\\nLanguage: $lang\\n/
            or $str =~ s/\z/\\nLanguage: $lang\\n/
            or die;
        $line = "msgstr \"$str\"";
    }

    $line =~ s/\A(msgid|msgstr)\s+/$1 \"\"\n/
        if $line =~ /\A(msgid|msgstr)\s+(\\.|.)*\\n/;
    $line =~ s/(\\.)/$1 eq "\\n" ? "\\n\"\n\"" : $1/eg;
    $line =~ s/\n\"\"\z//;
}
$_ = join "\n", @_;
s/\n*\z/\n\n/;

print $_;

while (<>) {
    print $_;
}

