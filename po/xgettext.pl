#!/usr/bin/perl

eval 'exec /usr/bin/perl  -S $0 ${1+"$@"}'
    if 0; # not running under some shell
# $File: //member/autrijus/Locale-Maketext-Lexicon/bin/xgettext.pl $ $Author$
# $Revision$ $Change: 5999 $ $DateTime: 2003/05/20 07:50:59 $
## [O. Salaun] 12/08/02 : Also look for gettext() in perl code
##                        No more escape '\' chars
##                        Extract gettext_id entries from List.pm
##                        Extract title.gettext entries from scenarios

use strict;
use Getopt::Std;
use Pod::Usage;
use constant NUL  => 0;
use constant BEG  => 1;
use constant PAR  => 2;
use constant QUO1 => 3;
use constant QUO2 => 4;
use constant QUO3 => 5;

=head1 NAME

xgettext.pl - Extract gettext strings from source

=head1 SYNOPSIS

B<xgettext.pl> [ B<-u> ] [ B<-g> ] [ B<-o> I<outputfile> ] [ I<inputfile>... ]

=head1 OPTIONS

[ B<-u> ] Disables conversion from B<Maketext> format to B<Gettext>
format -- i.e. it leaves all brackets alone.  This is useful if you are
also using the B<Gettext> syntax in your program.

[ B<-g> ] Enables GNU gettext interoperability by printing C<#,
maketext-format> before each entry that has C<%> variables.

[ B<-o> I<outputfile> ] PO file name to be written or incrementally
updated C<-> means writing to F<STDOUT>.  If not specified,
F<messages.po> is used.

[ I<inputfile>... ] is the files to extract messages from.

=head1 DESCRIPTION

This program extracts translatable strings from given input files, or
STDIN if none are given.

Currently the following formats of input files are supported:

=over 4

=item Perl source files

Valid localization function names are: C<translate>, C<maketext>,
C<loc>, C<x>, C<_> and C<__>.

=item HTML::Mason

The text inside C<E<lt>&|/lE<gt>I<...>E<lt>/&E<gt>> or
C<E<lt>&|/locE<gt>I<...>E<lt>/&E<gt>> will be extracted.

=item Template Toolkit

Texts inside C<[%|l%]...[%END%]> or C<[%|loc%]...[%END%]>
are extracted.

=item Text::Template

Sentences of texts between C<STARTxxx> and C<ENDxxx> are
extracted.

=cut

my (%file, %Lexicon, %opts);
my ($PO, $out);

# options as above. Values in %opts
getopts('hugo:', \%opts)
  or pod2usage( -verbose => 1, -exitval => 1 );
$opts{h} and pod2usage( -verbose => 2, -exitval => 0 );

$PO = $opts{o} || "messages.po";

@ARGV = ('-') unless @ARGV;

if (-r $PO) {
    open LEXICON, $PO or die $!;
    while (<LEXICON>) {
	if (1 .. /^$/) { $out .= $_; next }
	last;
    }

    1 while chomp $out;

    require Locale::Maketext::Lexicon::Gettext;
    %Lexicon = map {
	if ($opts{u}) {
	    s/\\/\\\\/g;
	    s/\"/\\"/g;
	    s/((?<!~)(?:~~)*)\[_(\d+)\]/$1%$2/g;
	    s/((?<!~)(?:~~)*)\[([A-Za-z#*]\w*),([^\]]+)\]/"$1%$2(".escape($3).")"/eg;
	    s/~([\~\[\]])/$1/g;
	}
	$_;
    } %{ Locale::Maketext::Lexicon::Gettext->parse(<LEXICON>) };
    close LEXICON;
    delete $Lexicon{''};
}

open PO, ">$PO" or die "Can't write to $PO:$!\n";
select PO;

undef $/;
foreach my $file (@ARGV) {
    next if ($file=~/\.po$/i); # Don't parse po files
    my $filename = $file;
    printf STDOUT "Processing $file...\n";	    
    unless (-f $file) {
	print STDERR "Cannot open $file\n";
	next;
    }
    open F, $file or die $!; $_ = <F>; $filename =~ s!^./!!;

    my $line = 1; pos($_) = 0;
    # Text::Template
    if (/^STARTTEXT$/m and /^ENDTEXT$/m) {
	require HTML::Parser;
	require Lingua::EN::Sentence;

	{
	    package MyParser;
	    @MyParser::ISA = 'HTML::Parser';
	    sub text {
		my ($self, $text, $is_cdata) = @_;
		my $sentences = Lingua::EN::Sentence::get_sentences($text) or return;
		$text =~ s/\n/ /g; $text =~ s/^\s+//; $text =~ s/\s+$//;
		push @{$file{$text}}, [ $filename, $line ];
	    }
	}   

	my $p = MyParser->new;
	while (m/\G(.*?)^(?:START|END)[A-Z]+$/smg) {
	    my ($str) = ($1);
	    $line += ( () = ($& =~ /\n/g) ); # cryptocontext!
	    $p->parse($str); $p->eof; 
	}
	$_ = '';
    }

    # HTML::Mason
    $line = 1; pos($_) = 0;
    while (m!\G.*?<&\|/l(?:oc)?(.*?)&>(.*?)</&>!sg) {
	my ($vars, $str) = ($1, $2);
	$line += ( () = ($& =~ /\n/g) ); # cryptocontext!
	$str =~ s/\\'/\'/g; 
	push @{$file{$str}}, [ $filename, $line, $vars ];
    }

    # Template Toolkit
    $line = 1; pos($_) = 0;
    while (m!\G.*?\[%\s*\|l(?:oc)?(.*?)\s*%\](.*?)\[%\s*END\s*%\]!sg) {
	my ($vars, $str) = ($1, $2);
	$line += ( () = ($& =~ /\n/g) ); # cryptocontext!
	$str =~ s/\\'/\'/g; 
	$vars =~ s/^\s*\(//;
	$vars =~ s/\)\s*$//;
	push @{$file{$str}}, [ $filename, $line, $vars ];
    }
	    
	    # Sympa variables (gettext_id)
	    $line = 1; pos($_) = 0;
	    while (/\G.*?\'gettext_id\'\s*=>\s*\"([^\"]+)\"/sg) {
		my $str = $1;
		$line += ( () = ($& =~ /\n/g) ); # cryptocontext!
		push @{$file{$str}}, [ $filename, $line];
	    }

	    # Sympa scenarios variables (title.gettext)
	    $line = 1; pos($_) = 0;
	    while (/\G.*?title.gettext\s*([^\n]+)/sg) {
		my $str = $1;
		$line += ( () = ($& =~ /\n/g) ); # cryptocontext!
		push @{$file{$str}}, [ $filename, $line];
	    }

    # Perl source file
    my ($state,$str,$vars)=(0);
    pos($_) = 0;
    my $orig = 1 + (() = ((my $__ = $_) =~ /\n/g));
  PARSER: {
      $_ = substr($_, pos($_)) if (pos($_));
      my $line = $orig - (() = ((my $__ = $_) =~ /\n/g));
      # maketext or loc or _
      $state == NUL &&
        m/\b(translate|gettext|maketext|__?|loc|x)/gcx && do { $state = BEG;  redo; };
      $state == BEG && m/^([\s\t\n]*)/gcx && do { redo; };
      # begin ()
      $state == BEG && m/^([\S\(]) /gcx && do {
	$state = ( ($1 eq '(') ? PAR : NUL) ;
	redo;
      };
      # begin or end of string
      $state == PAR  && m/^(\')  /gcx     && do { $state = QUO1; redo; };
      $state == QUO1 && m/^([^\']+)/gcx && do { $str.=$1; redo; };
      $state == QUO1 && m/^\'  /gcx     && do { $state = PAR;  redo; };

      $state == PAR  && m/^\"  /gcx     && do { $state = QUO2; redo; };
      $state == QUO2 && m/^([^\"]+)/gcx && do { $str.=$1; redo; };
      $state == QUO2 && m/^\"  /gcx     && do { $state = PAR;  redo; };

      $state == PAR  && m/^\`  /gcx     && do { $state = QUO3; redo; };
      $state == QUO3 && m/^([^\`]*)/gcx && do { $str.=$1; redo; };
      $state == QUO3 && m/^\`  /gcx     && do { $state = PAR;  redo; };

      # end ()
      $state == PAR && m/^[\)]/gcx
	&& do {
	  $state = NUL;	
	  $vars =~ s/[\n\r]//g if ($vars);
	  push @{$file{$str}}, [ $filename, $line - (() = $str =~ /\n/g), $vars] if ($str);
	  undef $str; undef $vars;
	  redo;
	};

      # a line of vars
      $state == PAR && m/^([^\)]*)/gcx && do { 	$vars.=$1."\n"; redo; };
    }
}

foreach my $str (sort keys %file) {
    my $ostr = $str;
    my $entry = $file{$str};
    my $lexi = $Lexicon{$ostr};

#    $str =~ s/\\/\\\\/g;
    $str =~ s/\"/\\"/g;
    $lexi =~ s/\\/\\\\/g;
    $lexi =~ s/\"/\\"/g;

    unless ($opts{u}) {
	$str =~ s/((?<!~)(?:~~)*)\[_(\d+)\]/$1%$2/g;
	$str =~ s/((?<!~)(?:~~)*)\[([A-Za-z#*]\w*)([^\]]+)\]/"$1%$2(".escape($3).")"/eg;
	$str =~ s/~([\~\[\]])/$1/g;
	$lexi =~ s/((?<!~)(?:~~)*)\[_(\d+)\]/$1%$2/g;
	$lexi =~ s/((?<!~)(?:~~)*)\[([A-Za-z#*]\w*)([^\]]+)\]/"$1%$2(".escape($3).")"/eg;
	$lexi =~ s/~([\~\[\]])/$1/g;
    }

    $Lexicon{$str} ||= '';
    next if $ostr eq $str;

    $Lexicon{$str} ||= $lexi;
    delete $file{$ostr}; delete $Lexicon{$ostr};
    $file{$str} = $entry;
}

exit unless %Lexicon;

print $out ? "$out\n" : (<< '.');
# SOME DESCRIPTIVE TITLE.
# Copyright (C) YEAR THE PACKAGE'S COPYRIGHT HOLDER
# This file is distributed under the same license as the PACKAGE package.
# FIRST AUTHOR <EMAIL@ADDRESS>, YEAR.
#
#, fuzzy
msgid ""
msgstr ""
"Project-Id-Version: PACKAGE VERSION\n"
"POT-Creation-Date: 2002-07-16 17:27+0800\n"
"PO-Revision-Date: YEAR-MO-DA HO:MI+ZONE\n"
"Last-Translator: FULL NAME <EMAIL@ADDRESS>\n"
"Language-Team: LANGUAGE <LL@li.org>\n"
"MIME-Version: 1.0\n"
"Content-Type: text/plain; charset=CHARSET\n"
"Content-Transfer-Encoding: 8bit\n"
.

foreach my $entry (sort keys %Lexicon) {
    my %f = (map { ( "$_->[0]:$_->[1]" => 1 ) } @{$file{$entry}});
    my $f = join(' ', sort keys %f);
    $f = " $f" if length $f;

    my $nospace = $entry;
    $nospace =~ s/ +$//;

    if (!$Lexicon{$entry} and $Lexicon{$nospace}) {
	$Lexicon{$entry} = $Lexicon{$nospace} . (' ' x (length($entry) - length($nospace)));
    }

    my %seen;
    print "\n#:$f\n";
    foreach my $entry ( grep { $_->[2] } @{$file{$entry}} ) {
	my ($file, $line, $var) = @{$entry};
	$var =~ s/^\s*,\s*//; $var =~ s/\s*$//;
	print "#. ($var)\n" unless !length($var) or $seen{$var}++;
    }

    print "#, maketext-format" if $opts{g} and /%(?:\d|\w+\([^\)]*\))/;
    print "msgid "; output($entry);
    print "msgstr "; output($Lexicon{$entry});
}

sub output {
    my $str = shift;

    if ($str =~ /\n/) {
	print "\"\"\n";
	print "\"$_\\n\"\n" foreach split(/\n/, $str, -1);
    }
    else {
	print "\"$str\"\n"
    }
}

sub escape {
    my $text = shift;
    $text =~ s/\b_(\d+)/%$1/;
    return $text;
}

1;

=head1 ACKNOWLEDGMENTS

Thanks to Jesse Vincent for contributing to an early version of this
utility.

Also to Alain Barbet, who effectively re-wrote the source parser with a
flex-like algorithm.

=head1 SEE ALSO

L<Locale::Maketext>, L<Locale::Maketext::Lexicon::Gettext>

=head1 AUTHORS

Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>

=head1 COPYRIGHT

Copyright 2002, 2003 by Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>.

This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
