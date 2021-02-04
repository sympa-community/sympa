#!/usr/bin/env perl
# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

use strict;
use warnings;
use Cwd qw();
use Getopt::Long;
use Pod::Usage;

use constant NUL   => 0;
use constant BEG   => 1;
use constant PAR   => 2;
use constant QUO1  => 3;
use constant QUO2  => 4;
use constant QUO3  => 5;
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
## Contains unique occurences of each string
my %Lexicon;
## All the strings, in the order they were found while parsing the files
my @ordered_strings = ();
## One occurence of each string, in the order they were found while parsing
## the files
my @unique_keys = ();
## A hash used for control when filling @unique_keys
my %unique_keys;

## Retrieving options.
my %opts;
GetOptions(
    \%opts,                 'add-comments|c:s',
    'copyright-holder=s',   'default-domain|d=s',
    'directory|D=s',        'files-from|f=s',
    'help|h',               'keyword|k:s@',
    'msgid-bugs-address=s', "output|o=s",
    'package-name=s',       'package-version=s',
    'version|v',            't=s@',
) or pod2usage(-verbose => 1, -exitval => 1);

$opts{help} and pod2usage(-verbose => 2, -exitval => 0);
if ($opts{version}) {
    print "sympa-6\n";
    exit;
}

# Initiliazing tags with defaults if necessary.
# Defaults stored separately because GetOptions append arguments to defaults.
# Building the string to insert into the regexp that will search strings to
# extract.
my $available_tags = join('|', @{$opts{t} || []}) || 'locdt|loc';

if ($opts{'files-from'}) {
    my $ifh;
    open $ifh, '<', $opts{'files-from'} or die "$opts{'files-from'}: $!\n";
    my @files = grep { /\S/ and !/\A\s*#/ } split /\r\n|\r|\n/,
        do { local $/; <$ifh> };
    my $cwd = Cwd::getcwd();
    if ($opts{'directory'}) {
        chdir $opts{'directory'} or die "$opts{'directory'}: $!\n";
    }
    @ARGV = map { (glob $_) } @files;
    chdir $cwd;
} elsif (not @ARGV) {
    @ARGV = ('-');
}

## Ordering files to present the most interresting strings to translate first.
my %files_to_parse;
foreach my $file_to_parse (@ARGV) {
    $files_to_parse{$file_to_parse} = 1;
}
my %favoured_files;
my @ordered_files;
my @planned_ordered_files = (
    "../web_tt2/help.tt2",       "../web_tt2/help_introduction.tt2",
    "../web_tt2/help_user.tt2",  "../web_tt2/help_admin.tt2",
    "../web_tt2/home.tt2",       "../web_tt2/login.tt2",
    "../web_tt2/main.tt2",       "../web_tt2/title.tt2",
    "../web_tt2/menu.tt2",       "../web_tt2/login_menu.tt2",
    "../web_tt2/your_lists.tt2", "../web_tt2/footer.tt2",
    "../web_tt2/list_menu.tt2",  "../web_tt2/list_panel.tt2",
    "../web_tt2/admin.tt2",      "../web_tt2/list_admin_menu.tt2"
);
foreach my $file (@planned_ordered_files) {
    if ($files_to_parse{$file}) {
        @ordered_files = (@ordered_files, $file);
    }
}
my @ordered_directories =
    ("../web_tt2", "../mail_tt2", "../src/etc/scenari", "../src/etc");

foreach my $file (@ordered_files) {
    $favoured_files{$file} = 1;
}
## Sorting by directories
foreach my $dir (@ordered_directories) {
    foreach my $file (@ARGV) {
        unless ($favoured_files{$file}) {
            if ($file =~ /^$dir/g) {
                @ordered_files = (@ordered_files, $file);
                $favoured_files{$file} = 1;
            }
        }
    }
}

## Sorting by files
foreach my $file (@ARGV) {
    unless ($favoured_files{$file}) {
        @ordered_files = (@ordered_files, $file);
    }
}

## Gathering strings in the source files.
## They will finally be stored into %file

my $cwd = Cwd::getcwd();
if ($opts{'directory'}) {
    chdir $opts{'directory'} or die "$opts{'directory'}: $!\n";
}

foreach my $file (@ordered_files) {
    next if ($file =~ /\.po.?$/i);    # Don't parse po files
    my $filename = $file;
    printf STDOUT "Processing $file...\n";
    unless (-f $file) {
        print STDERR "Cannot open $file\n";
        next;
    }

    # cpanfile
    if ($file eq 'cpanfile') {
        CPANFile::load();
        next;
    }

    open my $fh, '<', $file or die "$file: $!\n";
    $_ = do { local $/; <$fh> };
    close $fh;
    $filename =~ s!^./!!;
    my $line;

    # Template Toolkit: [%|loc(...)%]...[%END%]
    $line = 1;
    pos($_) = 0;
    while (
        m!\G.*?\[%[-=~+]?\s*\|\s*($available_tags)(.*?)\s*[-=~+]?%\](.*?)\[%[-=~+]?\s*END\s*[-=~+]?%\]!sg
    ) {
        my ($this_tag, $vars, $str) = ($1, $2, $3);
        $line += (() = ($& =~ /\n/g));    # cryptocontext!
        $str =~ s/\\\'/\'/g;
        $vars =~ s/^\s*\(//;
        $vars =~ s/\)\s*$//;
        my $expression = {
            'expression' => $str,
            'filename'   => $filename,
            'line'       => $line,
            'vars'       => $vars
        };
        $expression->{'type'} = 'date' if ($this_tag eq 'locdt');
        &add_expression($expression);
    }

    # Template Toolkit: [% "..." | loc(...) %]
    $line = 1;
    pos $_ = 0;
    while (
        m{
        \G .*?
        \[ % [-=~+]? \s*
        (?: \' ((?:\\.|[^'\\])*) \' | \" ((?:\\.|[^"\\])*) \" ) \s*
        \| \s*
        ($available_tags)
        (.*?)
        \s* [-=~+]? % \]
    }sgx
    ) {
        my $str      = $1 || $2;
        my $this_tag = $3;
        my $vars     = $4;

        $line += (() = ($& =~ /\n/g));
        $str =~ s{\\(.)}{
            ($1 eq 't') ? "\t" :
            ($1 eq 'n') ? "\n" :
            ($1 eq 'r') ? "\r" :
            $1
        }eg;
        $vars =~ s/^\s*[(](.*?)[)].*/$1/ or $vars = '';

        my $expression = {
            'expression' => $str,
            'filename'   => $filename,
            'line'       => $line,
            'vars'       => $vars
        };
        $expression->{'type'} = 'date' if ($this_tag eq 'locdt');
        &add_expression($expression);
    }

    # Template Toolkit with ($tag$%|loc%$tag$)...($tag$%END%$tag$) in archives
    $line = 1;
    pos($_) = 0;
    while (
        m!\G.*?\(\$tag\$%\s*\|($available_tags)(.*?)\s*%\$tag\$\)(.*?)\(\$tag\$%[-=~+]?\s*END\s*[-=~+]?%\$tag\$\)!sg
    ) {
        my ($this_tag, $vars, $str) = ($1, $2, $3);
        $line += (() = ($& =~ /\n/g));    # cryptocontext!
        $str =~ s/\\\'/\'/g;
        $vars =~ s/^\s*\(//;
        $vars =~ s/\)\s*$//;
        my $expression = {
            'expression' => $str,
            'filename'   => $filename,
            'line'       => $line,
            'vars'       => $vars
        };
        $expression->{'type'} = 'date' if ($this_tag eq 'locdt');
        &add_expression($expression);
    }

    # Sympa variables (gettext_comment, gettext_id and gettext_unit)
    $line = 1;
    pos($_) = 0;
    while (
        /\G.*?(\'?)(gettext_comment|gettext_id|gettext_unit)\1\s*=>\s*\"((\\.|[^\"])+)\"/sg
    ) {
        my $str = $3;
        $line += (() = ($& =~ /\n/g));    # cryptocontext!
        $str =~ s{(\\.)}{eval "\"$1\""}esg;
        &add_expression(
            {   'expression' => $str,
                'filename'   => $filename,
                'line'       => $line
            }
        );
    }

    $line = 1;
    pos($_) = 0;
    while (
        /\G.*?(\'?)(gettext_comment|gettext_id|gettext_unit)\1\s*=>\s*\'((\\.|[^\'])+)\'/sg
    ) {
        my $str = $3;
        $line += (() = ($& =~ /\n/g));    # cryptocontext!
        $str =~ s{(\\.)}{eval "'$1'"}esg;
        &add_expression(
            {   'expression' => $str,
                'filename'   => $filename,
                'line'       => $line
            }
        );
    }

    # Sympa scenarios variables (title.gettext)
    $line = 1;
    pos($_) = 0;
    while (/\G.*?title[.]gettext\s*([^\n]+)/sg) {
        my $str = $1;
        $line += (() = ($& =~ /\n/g));    # cryptocontext!
        &add_expression(
            {   'expression' => $str,
                'filename'   => $filename,
                'line'       => $line
            }
        );
    }

    # Perl source file
    my ($state, $str, $vars) = (0);
    my $is_date   = 0;
    my $is_printf = 0;

    pos($_) = 0;
    my $orig = 1 + (() = ((my $__ = $_) =~ /\n/g));
PARSER: {
        $_ = substr($_, pos($_)) if (pos($_));
        my $line = $orig - (() = ((my $__ = $_) =~ /\n/g));
        # maketext or loc or _
        $state == NUL
            && m/\b(translate|gettext(?:_strftime|_sprintf)?|maketext|__?|loc|x)/gcx
            && do {
            if ($& eq 'gettext_strftime' or $& eq 'gettext_sprintf') {
                $state     = BEGM;
                $is_date   = ($& eq 'gettext_strftime');
                $is_printf = ($& eq 'gettext_sprintf');
            } else {
                $state     = BEG;
                $is_date   = 0;
                $is_printf = 0;
            }
            redo;
            };
        ($state == BEG || $state == BEGM)
            && m/^([\s\t\n]*)/gcx
            && do { redo; };
        # begin ()
        $state == BEG && m/^([\S\(]) /gcx && do {
            $state = (($1 eq '(') ? PAR : NUL);
            redo;
        };
        $state == BEGM && m/^([\(])  /gcx && do { $state = PARM; redo };

        # begin or end of string
        $state == PAR && m/^\s*(\')  /gcx && do { $state = QUO1; redo; };
        $state == QUO1 && m/^([^\']+)/gcx && do { $str .= $1; redo; };
        $state == QUO1 && m/^\'  /gcx && do { $state = PAR; redo; };

        $state == PAR && m/^\s*\"  /gcx && do { $state = QUO2; redo; };
        $state == QUO2 && m/^([^\"]+)/gcx && do { $str .= $1; redo; };
        $state == QUO2 && m/^\"  /gcx && do { $state = PAR; redo; };

        $state == PAR && m/^\s*\`  /gcx && do { $state = QUO3; redo; };
        $state == QUO3 && m/^([^\`]*)/gcx && do { $str .= $1; redo; };
        $state == QUO3 && m/^\`  /gcx && do { $state = PAR; redo; };

        $state == BEGM && m/^(\') /gcx    && do { $state = QUOM1; redo; };
        $state == PARM && m/^\s*(\') /gcx && do { $state = QUOM1; redo; };
        $state == QUOM1 && m/^([^\']+)/gcx && do { $str .= $1; redo; };
        $state == QUOM1 && m/^\'  /gcx && do { $state = COMM; redo; };

        $state == BEGM && m/^(\") /gcx    && do { $state = QUOM2; redo; };
        $state == PARM && m/^\s*(\") /gcx && do { $state = QUOM2; redo; };
        $state == QUOM2 && m/^([^\"]+)/gcx && do { $str .= $1; redo; };
        $state == QUOM2 && m/^\"  /gcx && do { $state = COMM; redo; };

        $state == BEGM && do { $state = NUL; redo; };

        # end ()
        (          $state == PAR && m/^\s*[\)]/gcx
                || $state == PARM && m/^\s*[\)]/gcx
                || $state == COMM && m/^\s*,/gcx)
            && do {
            $state = NUL;
            $vars =~ s/[\n\r]//g if ($vars);
            if ($str) {
                my $expression = {
                    'expression' => $str,
                    'filename'   => $filename,
                    'line'       => $line - (() = $str =~ /\n/g),
                    'vars'       => $vars
                };
                $expression->{'type'} = 'date'   if ($is_date);
                $expression->{'type'} = 'printf' if ($is_printf);

                &add_expression($expression);
            }
            undef $str;
            undef $vars;
            redo;
            };

        # a line of vars
        $state == PAR  && m/^([^\)]*)/gcx && do { $vars .= $1 . "\n"; redo; };
        $state == PARM && m/^([^\)]*)/gcx && do { $vars .= $1 . "\n"; redo; };
    }

    unless ($state == NUL) {
        my $post = $_;
        $post =~ s/\A(\s*.*\n.*\n.*)\n(.|\n)+\z/$1\n.../;
        warn sprintf "Warning: incomplete state just before ---\n%s\n", $post;
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
    next if ($str =~ /^_\w+\_$/);

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
    open $pot, '+<', $output_file or die "$output_file: $!\n";
    while (<$pot>) {
        if (1 .. /^$/) { $out .= $_; next }
        last;
    }

    1 while chomp $out;

    seek $pot, 0, 0;
    truncate $pot, 0;
} else {
    open $pot, '>', $output_file or die "$output_file: $!\n";
}
select $pot;

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

    ## Print code/templates references
    print "\n#:$f\n";

    ## Print variables if any
    foreach my $entry (grep { $_->[2] } @{$file{$entry}}) {
        my ($file, $line, $var) = @{$entry};
        $var =~ s/^\s*,\s*//;
        $var =~ s/\s*$//;
        print "#. ($var)\n" unless !length($var) or $seen{$var}++;
    }

    ## If the entry is a date format, add a developper comment to help
    ## translators
    if ($type_of_entries{$entry} and $type_of_entries{$entry} eq 'date') {
        print "#. This entry is a date/time format\n";
        print
            "#. Check the strftime manpage for format details : http://docs.freebsd.org/info/gawk/gawk.info.Time_Functions.html\n";
    } elsif ($type_of_entries{$entry}
        and $type_of_entries{$entry} eq 'printf') {
        print "#. This entry is a sprintf format\n";
        print
            "#. Check the sprintf manpage for format details : http://perldoc.perl.org/functions/sprintf.html\n";
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

    @ordered_strings = (@ordered_strings, $param->{'expression'});
    push @{$file{$param->{'expression'}}},
        [$param->{'filename'}, $param->{'line'}, $param->{'vars'}];
    $type_of_entries{$param->{'expression'}} = $param->{'type'}
        if ($param->{'type'});

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
        foreach my $i (0 .. $#lines) {
            if ($lines[$i] eq '') {
                if ($#output_lines < 0) {
                    $current_line .= '\n';
                    next;
                } else {
                    $output_lines[$#output_lines] .= '\n';
                    next;
                }
            } else {
                $current_line .= $lines[$i];
            }
            push @output_lines, $current_line;
            $current_line = '';
        }

        ## Add \n unless
        foreach my $i (0 .. $#output_lines) {
            if ($i == $#output_lines) {
                ## No additional \n
                print "\"$output_lines[$i]\"\n";
            } else {
                print "\"$output_lines[$i]\\n\"\n";
            }
        }

    } else {
        print "\"$str\"\n";
    }
}

sub escape {
    my $text = shift;
    $text =~ s/\b_(\d+)/%$1/;
    return $text;
}

## Dump a variable's content
sub dump_var {
    my ($var, $level, $fd) = @_;

    return undef unless ($fd);

    if (ref($var)) {
        if (ref($var) eq 'ARRAY') {
            foreach my $index (0 .. $#{$var}) {
                print $fd "\t" x $level . $index . "\n";
                &dump_var($var->[$index], $level + 1, $fd);
            }
        } elsif (ref($var) eq 'HASH'
            || ref($var) eq 'Scenario'
            || ref($var) eq 'List') {
            foreach my $key (sort keys %{$var}) {
                print $fd "\t" x $level . '_' . $key . '_' . "\n";
                &dump_var($var->{$key}, $level + 1, $fd);
            }
        } else {
            printf $fd "\t" x $level . "'%s'" . "\n", ref($var);
        }
    } else {
        if (defined $var) {
            print $fd "\t" x $level . "'$var'" . "\n";
        } else {
            print $fd "\t" x $level . "UNDEF\n";
        }
    }
}

package CPANFile;

use strict;
use warnings;
use lib qw(.);

my @entries;

sub feature {
    push @entries,
        {
        expression => $_[1],
        filename   => 'cpanfile',
        line       => [caller]->[2],
        };
}
sub on         { $_[1]->() }
sub recommends { }
sub requires   { }

sub load {
    do 'cpanfile';
    die unless @entries;
    foreach my $entry (@entries) {
        main::add_expression($entry);
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

=item C<--help>, C<-h>

Shows this documentation and exits.

=item C<--output> I<outputfile>, C<-o>I<outputfile>

POT file name to be written or incrementally
updated C<-> means writing to F<STDOUT>.  If neither this option nor
C<--default-domain> option specified,
F<messages.po> is used.

=item C<-t>I<tag1> ...

Specifies which tag(s) must be used to extract Template Toolkit strings.
Default is C<loc> and C<locdt>.
Can be specified multiple times.

=item C<-u>

B<Deprecated>.
Disables conversion from Maketext format to Gettext
format -- i.e. it leaves all brackets alone.  This is useful if you are
also using the Gettext syntax in your program.

=item C<--version>, C<-v>

Prints "C<sympa-6>" and newline, and then exits.

=item C<--add-comments> [ I<tag> ] , C<-c>[ I<tag> ]

=item C<--copyright-holder> I<string>

=item C<--keyword> [ I<word> ], C<-k>[ I<word> ], ...

=item C<--msgid-bugs-address> I<address>

=item C<--package-name> I<name>

=item C<--package-version> I<version>

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

Part of changes are as following:

=over

=item [O. Salaun] 12/08/02 :

Also look for gettext() in perl code.
No more escape '\' chars.
Extract gettext_comment, gettext_id and gettext_unit entries from List.pm.
Extract title.gettext entries from scenarios.

=item [D. Verdin] 05/11/2007 :

Strings ordered following the order in which files are read and
the order in which they appear in the files.
Switch to Getopt::Long to allow multiple value parameter.
Added 't' parameter the specifies which tags to explore in TT2.

=back

=cut
