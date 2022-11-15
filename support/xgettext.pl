#!/usr/bin/env perl
# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

use strict;
use warnings;
use Cwd qw();
use English;    # FIXME: Avoid $MATCH usage
use Getopt::Long qw(:config no_ignore_case);
use Pod::Usage;
use POSIX qw();

use constant NUL   => 0;
use constant BEG   => 1;
use constant PAR   => 2;
use constant QUO1  => 3;
use constant QUO2  => 4;
use constant QUO3  => 5;    # No longer used
use constant BEGM  => 6;
use constant PARM  => 7;
use constant QUOM1 => 8;
use constant QUOM2 => 9;
use constant COMM  => 10;

## A hash that will contain the strings to translate and their meta
## informations.
my %file;
## conatins informations if a string is a date string.
my %type_of_entries;
## Contains unique occurrences of each string
my %Lexicon;
## All the strings, in the order they were found while parsing the files
my @ordered_strings = ();

## Retrieving options.
my %opts;
GetOptions(
    \%opts,                 'add-comments|c:s',
    'copyright-holder=s',   'default-domain|d=s',
    'directory|D=s',        'files-from|f=s',
    'help|h',               'keyword|k:s@',
    'msgid-bugs-address=s', "output|o=s",
    'package-name=s',       'package-version=s',
    'version|V',            'verbose|v',
    't=s@',
) or pod2usage(-verbose => 1, -exitval => 1);

$opts{help} and pod2usage(-verbose => 2, -exitval => 0);
if ($opts{version}) {
    print "sympa-6\n";
    exit;
}

if ($opts{'files-from'}) {
    my $ifh;
    open $ifh, '<', $opts{'files-from'}
        or die sprintf "%s: %s\n", $opts{'files-from'}, $ERRNO;
    my @files = grep { /\S/ and !/\A\s*#/ } split /\r\n|\r|\n/,
        do { local $RS; <$ifh> };
    my $cwd = Cwd::getcwd();
    if ($opts{directory}) {
        chdir $opts{directory}
            or die sprintf "%s: %s\n", $opts{directory}, $ERRNO;
    }
    @ARGV = map { (glob $_) } @files;
    chdir $cwd;
} elsif (not @ARGV) {
    @ARGV = ('-');
}

# Gathering strings in the source files.
# They will finally be stored into %file.

my $cwd = Cwd::getcwd();
if ($opts{directory}) {
    chdir $opts{directory}
        or die sprintf "%s: %s\n", $opts{directory}, $ERRNO;
}

foreach my $file (@ARGV) {
    next if $file =~ m{ [.] po.? \z }ix;    # Don't parse po files

    printf STDOUT "Processing %s...\n", $file if $opts{verbose};
    unless (-f $file) {
        printf STDERR "Cannot open %s\n", $file;
        next;
    }

    # cpanfile
    if ($file eq 'cpanfile') {
        printf STDERR "%s is no longer supported\n", $file;
        next;
    }

    open my $fh, '<', $file or die sprintf "%s: %s\n", $file, $ERRNO;
    $_ = do { local $RS; <$fh> };
    close $fh;

    if ($file =~ m{ [.] (pm | pl | fcgi) ([.]in)? \z }x) {
        load_perl($file, $_);
    }

    if ($file =~ m{ [.] tt2 \z }x) {
        load_tt2($file, $_, $opts{t});
    }

    if ($file =~ m{ / scenari / | [.] task \z | / comment [.] tt2 \z }x) {
        load_title($file, $_);
    }
}

chdir $cwd;

## Transfers all data from %file to %Lexicon, removing duplicates in the
## process.
my $index = 0;
my @ordered_bis;
my %ordered_hash;
foreach my $str (@ordered_strings) {
    my $ostr  = $str;
    my $entry = $file{$str};
    my $lexi  = $Lexicon{$ostr} // '';

    ## Skip meta information (specific to Sympa)
    next if $str =~ /^_\w+\_$/;

    $str =~ s/"/\\"/g;
    $lexi =~ s/\\/\\\\/g;
    $lexi =~ s/"/\\"/g;

    unless ($ordered_hash{$str}) {
        $ordered_bis[$index] = $str;
        $index++;
        $ordered_hash{$str} = 1;
    }
    $Lexicon{$str} ||= '';
    next if $ostr eq $str;

    $Lexicon{$str} ||= $lexi;
    unless ($file{$str}) { $file{$str} = $entry; }
    delete $file{$ostr};
    delete $Lexicon{$ostr};
}
exit unless %Lexicon;

my $output_file =
       $opts{output}
    || ($opts{'default-domain'} and $opts{'default-domain'} . '.pot')
    || "messages.po";

my $out;
my $pot;
if (-r $output_file) {
    open $pot, '+<', $output_file
        or die sprintf "%s: %s\n", $output_file, $ERRNO;
    while (<$pot>) {
        if (1 .. /^$/) { $out .= $_; next }
        last;
    }

    $out =~ s/[\r\n]+\z//;
    $out .= "\n" if length $out;

    seek $pot, 0, 0;
    truncate $pot, 0;
} else {
    open $pot, '>', $output_file
        or die sprintf "%s: %s\n", $output_file, $ERRNO;
}
select $pot;

$out ||= (<< '.');
# SOME DESCRIPTIVE TITLE.
# Copyright (C) YEAR THE PACKAGE'S COPYRIGHT HOLDER
# This file is distributed under the same license as the PACKAGE package.
# FIRST AUTHOR <EMAIL@ADDRESS>, YEAR.
#
#, fuzzy
msgid ""
msgstr ""
"Project-Id-Version: PACKAGE VERSION\n"
"Report-Msgid-Bugs-To: \n"
"POT-Creation-Date: 2002-07-16 17:27+0800\n"
"PO-Revision-Date: YEAR-MO-DA HO:MI+ZONE\n"
"Last-Translator: FULL NAME <EMAIL@ADDRESS>\n"
"Language-Team: LANGUAGE <LL@li.org>\n"
"Language: \n"
"MIME-Version: 1.0\n"
"Content-Type: text/plain; charset=CHARSET\n"
"Content-Transfer-Encoding: 8bit\n"
.

$out =~ s{"(Project-Id-Version): .*\\n"}
    {"$1: $opts{'package-name'}-$opts{'package-version'}\\n"}
    if $opts{'package-name'} and $opts{'package-version'};
$out =~ s{"(Report-Msgid-Bugs-To): .*\\n"}
    {"$1: $opts{'msgid-bugs-address'}\\n"}
    if $opts{'msgid-bugs-address'};
my $cdate = POSIX::strftime('%Y-%m-%d %H:%M:%S+0000', gmtime time);
$out =~ s{"(POT-Creation-Date): .*\\n"}
    {"$1: $cdate\\n"};

print $out;

foreach my $entry (@ordered_bis) {
    my %f = (map { ("$_->[0]:$_->[1]" => 1) } @{$file{$entry}});
    my $f = join(' ', sort keys %f);
    $f = " $f" if length $f;

    my $nospace = $entry;
    $nospace =~ s/ +$//;

    if (!$Lexicon{$entry} and $Lexicon{$nospace}) {
        $Lexicon{$entry} =
            $Lexicon{$nospace} . (' ' x (length($entry) - length($nospace)));
    }

    my %seen;

    print "\n";

    # Print variables if any.
    foreach my $ent (grep { $_->[2] } @{$file{$entry}}) {
        my ($file, $line, $var) = @{$ent};
        $var =~ s/^\s*,\s*//;
        $var =~ s/\s*$//;
        print "#. ($var)\n" unless !length($var) or $seen{$var}++;
    }

    # If the entry is a date format, add a developper comment to help
    # translators.
    if ('date' eq ($type_of_entries{$entry} || '')) {
        print "#. This entry contains date/time conversions.  See\n";
        print "#. https://perldoc.perl.org/POSIX#strftime for details.\n";
    } elsif ('printf' eq ($type_of_entries{$entry} || '')) {
        print "#. This entry contains sprintf conversions.  See\n";
        print "#. https://perldoc.perl.org/functions/sprintf for details.\n";
    }

    # Print code/templates references.
    print "#:$f\n";
    if ('printf' eq ($type_of_entries{$entry} || '')) {
        print "#, c-format\n";
    } elsif ('maketext' eq ($type_of_entries{$entry} || '')) {
        print "#, smalltalk-format\n";
    }

    print "msgid ";
    output($entry);
    print "msgstr ";
    output($Lexicon{$entry});
}

## Add expressions to list of expressions to translate
## parameters : expression, filename, line, vars
sub add_expression {
    my $param = shift;

    push @ordered_strings, $param->{expression};
    push @{$file{$param->{expression}}},
        [$param->{filename}, $param->{line}, $param->{vars}];
    $type_of_entries{$param->{expression}} = $param->{type}
        if $param->{type};

}

sub load_tt2 {
    my $filename = shift;
    my $t        = shift;
    my $filters  = shift;

    # Initiliazing filter names with defaults if necessary.
    # Defaults stored separately because GetOptions append arguments to
    # defaults.
    # Building the string to insert into the regexp that will search strings
    # to extract.
    my $tt2_filters = join('|', @{$filters || []}) || 'locdt|loc';

    my ($tag_s, $tag_e);
    if ($filename eq 'default/mhonarc-ressources.tt2') {
        # Template Toolkit with ($tag$%...%$tag$) in mhonarc-ressources.tt2
        # (<=6.2.60; OBSOLETED)
        ($tag_s, $tag_e) = (qr{[(]\$tag\$%}, qr{%\$tag\$[)]});
    } elsif ($filename eq 'default/mhonarc_rc.tt2') {
        # Template Toolkit with <%...%> in mhonarc_rc.tt2 (6.2.61b.1 or later)
        ($tag_s, $tag_e) = (qr{<%}, qr{%>});
    } elsif ($filename =~ /[.]tt2\z/) {
        # Template Toolkit with [%...%]
        ($tag_s, $tag_e) = (qr{[[]%}, qr{%[]]});
    } else {
        die 'bug in logic. Ask developer';
    }

    my $line;

    $line = 1;
    pos($t) = 0;
    while (
        $t =~ m{
            \G .*?
            (?:
                # Short style: [% "..." | loc(...) %]
                $tag_s [-=~+]? \s*
                (?:
                    \'
                    ((?: \\. | [^'\\])*)
                    \'
                  |
                    \"
                    ((?: \\. | [^"\\])*)
                    \"
                ) \s*
                \| \s*
                ($tt2_filters)
                (.*?)
                \s* [-=~+]? $tag_e
              |
                # Enclosing style: [%|loc(...)%]...[%END%]
                $tag_s [-=~+]? \s*
                \| \s*
                ($tt2_filters)
                (.*?)
                \s* [-=~+]? $tag_e
                (.*?)
                $tag_s [-=~+]? \s*
                END
                \s* [-=~+]? $tag_e
            )
        }gsx
    ) {
        my $is_short = $3;
        my ($this_tag, $vars, $str) =
            $is_short ? ($3, $4, $1 // $2) : ($5, $6, $7);
        $line += (() = ($MATCH =~ /\n/g));    # cryptocontext!
        if ($is_short) {
            $str =~ s{\\(.)}{
                ($1 eq 't') ? "\t" :
                ($1 eq 'n') ? "\n" :
                ($1 eq 'r') ? "\r" :
                $1
            }eg;
            $vars =~ s/^\s*[(](.*?)[)].*/$1/ or $vars = '';
        } else {
            $str =~ s/\\\'/\'/g;
            $vars =~ s/^\s*\(//;
            $vars =~ s/\)\s*$//;
        }

        add_expression(
            {   expression => $str,
                filename   => $filename,
                line       => $line,
                vars       => $vars,
                (     ($this_tag eq 'locdt') ? (type => 'date')
                    : ($this_tag eq 'loc' and 0 <= index $str, '%')
                    ? (type => 'maketext')
                    : ()
                )
            }
        );
    }
}

sub load_perl {
    my $filename = shift;
    my $t        = shift;

    my $line;

    $t =~ s{(?<=\n)__END__\n.*}{}s;    # Omit postamble

    # Sympa variables (gettext_comment, gettext_id and gettext_unit)
    $line = 1;
    pos($t) = 0;
    while (
        $t =~ m{
            \G .*?
            ([\"\']?)
            (gettext_comment | gettext_id | gettext_unit)
            \1
            \s* => \s*
            (?:
                (\") ((?: \\. | [^\"])+) \"
              | (\') ((?: \\. | [^\'])+) \'
            )
        }gsx
    ) {
        my ($quot, $str) = ($3 // $5, $4 // $6);
        $line += (() = ($MATCH =~ /\n/g));    # cryptocontext!
        $str =~ s{(\\.)}{eval "$quot$1$quot"}esg;

        add_expression(
            {   expression => $str,
                filename   => $filename,
                line       => $line
            }
        );
    }

    # Perl source file
    my $state = 0;
    my $str;
    my $vars;
    my $type;

    pos($t) = 0;
    my $orig = 1 + (() = ((my $tmp = $t) =~ /\n/g));
PARSER: {
        $t = substr $t, pos $t if pos $t;
        my $line = $orig - (() = ((my $tmp = $t) =~ /\n/g));
        # maketext or loc or _
        if (    $state == NUL
            and $t =~ m/\b(
                translate
              | gettext(?:_strftime|_sprintf)?
              | maketext
              | __?
              | loc
              | x
            )/cgx
        ) {
            if ($1 eq 'gettext_strftime') {
                $state = BEGM;
                $type  = 'date';
            } elsif ($1 eq 'gettext_sprintf') {
                $state = BEGM;
                $type  = 'printf';
            } elsif ($1 eq 'maketext') {
                $state = BEG;
                $type  = 'maketext';
            } else {
                $state = BEG;
                undef $type;
            }
            redo;
        }
        if (($state == BEG or $state == BEGM) and $t =~ m/^([\s\t\n]*)/cg) {
            redo;
        }
        # begin ()
        if ($state == BEG and $t =~ m/^([\S\(])/cg) {
            $state = ($1 eq '(') ? PAR : NUL;
            redo;
        }
        if ($state == BEGM and $t =~ m/^([\(])/cg) {
            $state = PARM;
            redo;
        }

        # begin or end of string
        if ($state == PAR and $t =~ m/^\s*'/cg) {
            $state = QUO1;
            redo;
        }
        if ($state == QUO1 and $t =~ m/^((?:\\\\|\\'|[^'])+)/cg) {
            my $m = $1;
            $m =~
                s{(\\.)}{($1 eq "\\\\") ? "\\" : ($1 eq "\\'") ? "'" : $1}eg;
            $m =~ s{\\}{\\\\}g;
            $str .= $m;
            redo;
        }
        if ($state == QUO1 and $t =~ m/^'/cg) {
            $state = PAR;
            redo;
        }

        if ($state == PAR and $t =~ m/^\s*"/cg) {
            $state = QUO2;
            redo;
        }
        if ($state == QUO2 and $t =~ m/^((?:\\.|[^\\"])+)/cg) {
            $str .= $1;
            redo;
        }
        if ($state == QUO2 and $t =~ m/^"/cg) {
            $state = PAR;
            redo;
        }

        #if ($state == PAR and $t =~ m/^\s*\`/cg) {
        #    $state = QUO3;
        #    redo;
        #}
        #if ($state == QUO3 and $t =~ m/^([^\`]*)/cg) {
        #    $str .= $1;
        #    redo;
        #}
        #if ($state == QUO3 and $t =~ m/^\`/cg) {
        #    $state = PAR;
        #    redo;
        #}

        if ($state == BEGM and $t =~ m/^'/cg) {
            $state = QUOM1;
            redo;
        }
        if ($state == PARM and $t =~ m/^\s*'/cg) {
            $state = QUOM1;
            redo;
        }
        if ($state == QUOM1 and $t =~ m/^((?:\\\\|\\'|[^'])+)/cg) {
            my $m = $1;
            $m =~
                s{(\\.)}{($1 eq "\\\\") ? "\\" : ($1 eq "\\'") ? "'" : $1}eg;
            $m =~ s{\\}{\\\\}g;
            $str .= $m;
            redo;
        }
        if ($state == QUOM1 and $t =~ m/^'/cg) {
            $state = COMM;
            redo;
        }

        if ($state == BEGM and $t =~ m/^"/cg) {
            $state = QUOM2;
            redo;
        }
        if ($state == PARM and $t =~ m/^\s*"/cg) {
            $state = QUOM2;
            redo;
        }
        if ($state == QUOM2 and $t =~ m/^((?:\\.|[^\\"])+)/cg) {
            $str .= $1;
            redo;
        }
        if ($state == QUOM2 and $t =~ m/^"/cg) {
            $state = COMM;
            redo;
        }

        if ($state == BEGM) {
            $state = NUL;
            redo;
        }

        # end ()
        if (   ($state == PAR and $t =~ m/^\s*[\)]/cg)
            or ($state == PARM and $t =~ m/^\s*[\)]/cg)
            or ($state == COMM and $t =~ m/^\s*,/cg)) {
            $state = NUL;
            $vars =~ s/[\n\r]//g if $vars;

            add_expression(
                {   expression => $str,
                    filename   => $filename,
                    line       => $line - (() = $str =~ /\n/g),
                    vars       => $vars,
                    ($type ? (type => $type) : ())
                }
            ) if $str;
            undef $str;
            undef $vars;
            redo;
        }

        # a line of vars
        if ($state == PAR and $t =~ m/^([^\)]*)/cg) {
            $vars .= $1 . "\n";
            redo;
        }
        if ($state == PARM and $t =~ m/^([^\)]*)/cg) {
            $vars .= $1 . "\n";
            redo;
        }
    }

    unless ($state == NUL) {
        my $post = $t;
        $post =~ s/\A(\s*.*\n.*\n.*)\n(.|\n)+\z/$1\n.../;
        warn sprintf "Warning: incomplete state just before ---\n%s\n", $post;
    }
}

sub load_title {
    my $filename = shift;
    my $t        = shift;

    my $line;

    # Titles in scenarios, tasks and comment.tt2 (title.gettext)
    $line = 1;
    pos($t) = 0;
    while (
        $t =~ m{
            \G .*?
            title [.] gettext \s*
            ([^\n]+)
        }gsx
    ) {
        my $str = $1;
        $line += (() = ($MATCH =~ /\n/g));    # cryptocontext!

        add_expression(
            {   expression => $str,
                filename   => $filename,
                line       => $line
            }
        );
    }
}

sub output {
    my $str = shift // '';

    ## Normalize
    $str =~ s/\\n/\n/g;

    if ($str =~ /\n/) {
        print "\"\"\n";

        ## Avoid additional \n entries
        my @lines = split(/\n/, $str, -1);
        my @output_lines;

        ## Move empty lines to previous line as \n
        my $current_line;
        foreach my $line (@lines) {
            if ($line eq '') {
                unless (@output_lines) {
                    $current_line .= '\n';
                    next;
                } else {
                    $output_lines[-1] .= '\n';
                    next;
                }
            } else {
                $current_line .= $line;
            }
            push @output_lines, $current_line;
            $current_line = '';
        }

        # Add \n unless the last line
        print "\"" . join("\\n\"\n\"", @output_lines) . "\"\n";
    } else {
        print "\"$str\"\n";
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

xgettext.pl - Extract gettext strings from Sympa source

=head1 SYNOPSIS

  xgettext.pl [ options ... ] [ inputfile ... ]

=head1 OPTIONS

=over

=item C<--default-domain> I<domain>, C<-d>I<domain>

Specifies domain.
If this option is specified but output file is not specified
(see C<--output>), C<I<domain>.pot> is used.

=item C<--directory> I<path>, C<-D>I<path>

Specifies directory to search input files.

=item C<--files-from> I<path>, C<-f>I<path>

Get list of input files from the file.

=item C<-g>

B<Deprecated>.
Enables GNU gettext interoperability by printing C<#, maketext-format>
before each entry that has C<%> variables.

Instead, currently C<#, smalltalk-format>, the argument supported by
GNU gettext, is printed.

=item C<--help>, C<-h>

Shows this documentation and exits.

=item C<--msgid-bugs-address> I<address>

Includes email address or URL where bugs are reported in output.

=item C<--output> I<outputfile>, C<-o>I<outputfile>

POT file name to be written or incrementally
updated C<-> means writing to F<STDOUT>.  If neither this option nor
C<--default-domain> option specified,
F<messages.po> is used.

=item C<--package-name> I<name>

=item C<--package-version> I<version>

Includes name and version of package in output.

=item C<-t>I<tag1> ...

Specifies which tag(s) must be used to extract Template Toolkit strings.
Default is C<loc> and C<locdt>.
Can be specified multiple times.

This option is the extension by Sympa package.

=item C<-u>

B<Deprecated>.
Disables conversion from Maketext format to Gettext
format -- i.e. it leaves all brackets alone.  This is useful if you are
also using the Gettext syntax in your program.

=item C<--verbose>, C<-v>

Prints the names of processed files.

=item C<--version>, C<-V>

Prints "C<sympa-6>" and newline, and then exits.

=item C<--add-comments> [ I<tag> ] , C<-c>[ I<tag> ]

=item C<--copyright-holder> I<string>

=item C<--keyword> [ I<word> ], C<-k>[ I<word> ], ...

These options will do nothing.
They are prepared for compatibility to xgettext of GNU gettext.

=back

I<inputfile>... is the files to extract messages from, if C<--files-from>
option is not specified.

=head1 DESCRIPTION

This program extracts translatable strings from given input files, or
STDIN if none are given.

Currently the following formats of input files are supported:

=over

=item Perl source files

Valid localization function names are:
C<gettext>, C<gettext_sprintf> C<gettext_strftime>,
C<maketext>, C<translate>, C<loc> C<x>, C<_> and C<__>.
Hash keys C<gettext_comment>, C<gettext_id> and C<gettext_unit>
are also recognized.

=item Template Toolkit

Texts inside C<[%|loc%]...[%END%]> or C<[%|locdt%]...[%END%]>
are extracted, unless specified otherwise by C<-t> option.

The alternative format C<[%...|loc%]> is also recognized.

=item Scenario sources

Text content of C<title.gettext> line.

=back

=head1 SEE ALSO

L<Sympa::Language>, L<Sympa::Template>.

=head1 HISTORY

This script was initially based on F<xgettext.pl>
by Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>
which was bundled in L<Locale-Maketext-Lexicon>.
Afterward, it has been drastically rewritten to be adopted to Sympa
and original code hardly remains.

=cut
