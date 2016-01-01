# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016 GIP RENATER
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
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# TT2 adapter for sympa's template system - Chia-liang Kao <clkao@clkao.org>
# usage: replace require 'parser.pl' in wwwsympa and other .pl

package Sympa::Template;

use strict;
use warnings;
use CGI::Util;
use English qw(-no_match_vars);
use MIME::EncWords;
use Template;

use Sympa;
use Sympa::Constants;
use Sympa::Language;
use Sympa::ListOpt;
use tools;
use Sympa::Tools::Text;

my $language = Sympa::Language->instance;

sub new {
    my $class   = shift;
    my $that    = shift;
    my %options = @_;

    $options{include_path} ||= [];

    bless {%options, context => $that} => $class;
}

sub qencode {
    my $string = shift;
    # We are not able to determine the name of header field, so assume
    # longest (maybe) one.
    return MIME::EncWords::encode_mimewords(
        Encode::decode('utf8', $string),
        Encoding => 'A',
        Charset  => tools::lang2charset($language->get_lang),
        Field    => "message-id"
    );
}

sub encode_utf8 {
    my $string = shift;

    ## Skip if already internally tagged utf8
    if (Encode::is_utf8($string)) {
        return Encode::encode_utf8($string);
    }

    return $string;

}

sub decode_utf8 {
    my $string = shift;

    ## Skip if already internally tagged utf8
    unless (Encode::is_utf8($string)) {
        ## Wrapped with eval to prevent Sympa process from dying
        ## FB_CROAK is used instead of FB_WARN to pass $string intact to
        ## succeeding processes it operation fails
        eval { $string = Encode::decode('utf8', $string, Encode::FB_CROAK); };
        $EVAL_ERROR = '';
    }

    return $string;

}

## We use different catalog/textdomains depending on the template that
## requests translations
my %template2textdomain = (
    'help_admin.tt2'         => 'web_help',
    'help_arc.tt2'           => 'web_help',
    'help_editfile.tt2'      => 'web_help',
    'help_editlist.tt2'      => 'web_help',
    'help_faqadmin.tt2'      => 'web_help',
    'help_faquser.tt2'       => 'web_help',
    'help_introduction.tt2'  => 'web_help',
    'help_listconfig.tt2'    => 'web_help',
    'help_mail_commands.tt2' => 'web_help',
    'help_sendmsg.tt2'       => 'web_help',
    'help_shared.tt2'        => 'web_help',
    'help_suspend.tt2'       => 'web_help',
    'help.tt2'               => 'web_help',
    'help_user_options.tt2'  => 'web_help',
    'help_user.tt2'          => 'web_help',
);

sub maketext {
    my ($context, @arg) = @_;

    my $template_name = $context->stash->get('component')->{'name'};
    my $textdomain = $template2textdomain{$template_name} || '';

    return sub {
        my $ret = $language->maketext($textdomain, $_[0], @arg);
        # <acronym> was deprecated: Use <abbr> instead.
        $ret =~ s/(<\/?)acronym\b/${1}abbr/g
            if $ret and $textdomain eq 'web_help';
        return $ret;
    };
}

sub locdatetime {
    my ($fmt, $arg) = @_;
    if ($arg !~
        /^(\d{4})\D(\d\d?)(?:\D(\d\d?)(?:\D(\d\d?)\D(\d\d?)(?:\D(\d\d?))?)?)?/
        ) {
        return sub { $language->gettext("(unknown date)"); };
    } else {
        my @arg =
            ($6 || 0, $5 || 0, $4 || 0, $3 || 1, $2 - 1, $1 - 1900, 0, 0, 0);
        return sub { $language->gettext_strftime($_[0], @arg); };
    }
}

sub wrap {
    my ($context, $init, $subs, $cols) = @_;
    $init = '' unless defined $init;
    $init = ' ' x $init if $init =~ /^\d+$/;
    $subs = '' unless defined $subs;
    $subs = ' ' x $subs if $subs =~ /^\d+$/;

    return sub {
        my $text = shift;
        my $nl   = $text =~ /\n$/;
        my $ret  = Sympa::Tools::Text::wrap_text($text, $init, $subs, $cols);
        $ret =~ s/\n$// unless $nl;
        $ret;
    };
}

sub optdesc {
    my ($context, $type, $withval) = @_;
    return sub {
        my $x = shift;
        return undef unless defined $x;
        return undef unless $x =~ /\S/;
        $x =~ s/^\s+//;
        $x =~ s/\s+$//;
        return Sympa::ListOpt::get_title($x, $type, $withval);
    };
}

sub parse {
    my $self       = shift;
    my $data       = shift;
    my $tpl_string = shift;
    my $output     = shift;
    my %options    = @_;

    my @include_path;
    if ($self->{plugins}) {
        push @include_path, @{$self->{plugins}->tt2Paths || []};
    }
    if (defined $self->{context}) {
        push @include_path,
            @{Sympa::get_search_path($self->{context}, %$self) || []};
    }
    if (@{$self->{include_path} || []}) {
        push @include_path, @{$self->{include_path}};
    }

    my $config = {
        ABSOLUTE => ($self->{allow_absolute} ? 1 : 0),
        INCLUDE_PATH => [@include_path],
        PLUGIN_BASE  => 'Sympa::Template::Plugin',
        # PRE_CHOMP  => 1,
        UNICODE => 0,    # Prevent BOM auto-detection

        FILTERS => {
            unescape => \&CGI::Util::unescape,
            l        => [\&maketext, 1],
            loc      => [\&maketext, 1],
            helploc  => [\&maketext, 1],
            locdt    => [\&locdatetime, 1],
            wrap         => [\&wrap,                1],
            optdesc      => [\&optdesc,             1],
            qencode      => [\&qencode,             0],
            escape_xml   => [\&tools::escape_xml,   0],
            escape_url   => [\&tools::escape_url,   0],
            escape_quote => [\&tools::escape_quote, 0],
            decode_utf8  => [\&decode_utf8,         0],
            encode_utf8  => [\&encode_utf8,         0]
        }
    };

    #unless ($options->{'is_not_template'}) {
    #    $config->{'INCLUDE_PATH'} = $self->{include_path};
    #}

    # An array can be used as a template (instead of a filename)
    if (ref $tpl_string eq 'ARRAY') {
        $tpl_string = \join('', @$tpl_string);
    }
    # body is separated by an empty line.
    if ($options{'has_header'}) {
        if (ref $tpl_string) {
            $tpl_string = \("\n" . $$tpl_string);
        } else {
            $tpl_string = \"\n[% PROCESS $tpl_string %]";
        }
    }

    my $tt2 = Template->new($config)
        or die "Template error: " . Template->error();

    # Set language if possible: Must be restored later
    $language->push_lang($data->{lang} || undef);

    unless ($tt2->process($tpl_string, $data, $output)) {
        $self->{last_error} = $tt2->error();

        $language->pop_lang;
        return undef;
    } else {
        delete $self->{last_error};

        $language->pop_lang;
        return 1;
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Template - Template parser

=head1 SYNOPSIS

  use Sympa::Template;
  
  $template = Sympa::Template->new;
  $template->parse($data, $tpl_file, \$output);

=head1 DESCRIPTION

=head2 Methods

=over

=item new ( $that, [ property defaults ] )

I<Constructor>.
Creates new L<Sympa::Template> instance.

Parameters:

=over

=item $that

Context.  Site, Robot or List.

=item property defaults

Pairs to specify property defaults.

=back

=item parse ( $data, $tpl, $output, [ has_header => 1 ] )

I<Instance method>.
Parses template and outputs result.

Parameters:

=over

=item $data

A HASH ref containing the data.

=item $tpl

A string that contains the file name.
Or, scalarref or arrayref that contains the template.

=item $output

A file descriptor or a reference to scalar for the output.

=item has_header =E<gt> 0|1

If 1 is set, prepended header fields are assumed,
i.e. one newline will be inserted at beginning of output.

=item is_not_template =E<gt> 0|1

This option was obsoleted.

=back

Returns:

On success, returns C<1> and clears {last_error} property.
Otherwise returns C<undef> and sets {last_error} property.

=back

=head2 Properties

Instance of L<Sympa::Template> may have following attributes.

=over

=item {allow_absolute}

If set, absolute paths in C<INCLUDE> directive are allowed.

=item {include_path}

Reference to array containing additional template search paths.

=item {last_error}

I<Read only>.
Error occurred at the last execution of parse, or C<undef>.

=item {plugins}

TBD.

=item {subdir}, {lang}, {lang_only}

TBD.

=back

=head2 Filters

These custom filters are defined by L<Sympa::Template>.
See L<Template::Manual::Filters> about usage of filters.

=over

=item decode_utf8

No longer used.

=item encode_utf8

No longer used.

=item escape_quote

Escape quotation marks.

=item escape_url

Escape URL.

=item escape_xml

OBSOLETED.  Use L<Template::Manual::Filters/"xml">.

=item helploc ( parameters )

=item l ( parameters )

=item loc ( parameters )

Translates text using catalog.
Placeholders (C<%1>, C<%2>, ...) are replaced by parameters.

=item locdt ( argument )

Generates formatted (i18n'ized) date/time.

=over

=item Filtered text

strftime() style format string.

=item argument

A string representing date/time:
"YYYY/MM", "YYYY/MM/DD", "YYYY/MM/DD/HH/MM" or "YYYY/MM/DD/HH/MM/SS".

=back

=item optdesc ( type, withval )

Generates i18n'ed description of list parameter value.

=over

=item Filtered text

Parameter value.

=item type

Type of list parameter value: 'reception', 'visibility', 'status'
or others (default).

=item withval

If parameter value is added to the description.  False by default.

=back

=item qencode

Encode string by MIME header encoding.
Despite its name, appropriate encoding scheme
(C<Q> or C<B>) will be chosen.

=item unescape

No longer used.

=item wrap ( init, subs, cols )

Generates folded text.

=over

=item init

Indentation (or its length) of each paragraphm if any.

=item subs

Indentation (or its length) of other lines if any.

=item cols

Line width, defaults to 78.

=back

=back

B<Note>:

Calls of L</helploc>, L</loc> and L</locdt> in template files are
extracted during packaging process and are added to translation catalog.

=head2 Plugins

Plugins may be placed under F<LIBDIR/Sympa/Template/Plugin>.
See <https://www.sympa.org/manual/templates_plugins> about usage of
plugins.

=head1 SEE ALSO

L<Template::Manual>.

=head1 HISTORY

Sympa 4.2b.3 adopted template engine based on Template Toolkit.

Plugin feature was added on Sympa 6.2.

L<tt2> module was renamed to L<Sympa::Template> on Sympa 6.2.

=cut
