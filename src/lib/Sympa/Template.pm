# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
# Copyright 2017, 2018, 2020, 2021 The Sympa Community. See the
# AUTHORS.md file at the top-level directory of this distribution and at
# <https://github.com/sympa-community/sympa.git>.
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
use Encode qw();
use English qw(-no_match_vars);
use MIME::EncWords;
use Template;

use Sympa;
use Conf;
use Sympa::HTMLDecorator;
use Sympa::Language;
use Sympa::ListOpt;
use Sympa::Robot;
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
        Charset  => Conf::lang2charset($language->get_lang),
        Field    => "message-id"
    );
}

# OBSOLETED.  This is kept only for backward compatibility.
# Old name: tt2::escape_url().
sub _escape_url {
    my $string = shift;

    $string =~ s/([\s+])/sprintf('%%%02x', ord $1)/eg;
    # Some MUAs aren't able to decode ``%40'' (escaped ``@'') in e-mail
    # address of mailto: URL, or take ``@'' in query component for a
    # delimiter to separate URL from the rest.
    my ($body, $query) = split(/\?/, $string, 2);
    if (defined $query) {
        $query =~ s/(\@)/sprintf('%%%02x', ord $1)/eg;
        $string = $body . '?' . $query;
    }

    return $string;
}

# OBSOLETED.  This is kept only for backward compatibility.
# Old name:: tt2::escape_xml().
sub _escape_xml {
    my $string = shift;

    $string =~ s/&/&amp;/g;
    $string =~ s/</&lt;/g;
    $string =~ s/>/&gt;/g;
    $string =~ s/\'/&apos;/g;
    $string =~ s/\"/&quot;/g;

    return $string;
}

# Old name: tt2::escape_quote().
# No longer used.  Use _escape_cstr().
#sub _escape_quote;

sub _escape_cstr {
    my $string = shift;

    $string =~ s{([\t\n\r\'\"\\])}{
        ($1 eq "\t") ? "\\t" : 
        ($1 eq "\n") ? "\\n" : 
        ($1 eq "\r") ? "\\r" : 
        "\\$1"
    }eg;

    return $string;
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

# We use different catalog/textdomains depending on the template that
# requests translations.
# help.tt2 and help_*.tt2 templates use domain "web_help".  Others use default
# domain "sympa".
sub _template2textdomain {
    my $template_name = shift;
    return ($template_name =~ /\Ahelp(?:_[-\w]+)?[.]tt2\z/) ? 'web_help' : '';
}

sub maketext {
    my ($context, @arg) = @_;

    my $template_name = $context->stash->get('component')->{'name'};
    my $textdomain    = _template2textdomain($template_name);

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

    if (defined $arg and $arg =~ /\A-?\d+\z/) {
        return sub { $language->gettext_strftime($_[0], localtime $arg); };
    } elsif (defined $arg
        and $arg =~
        /\A(\d{4})\D(\d\d?)(?:\D(\d\d?)(?:\D(\d\d?)\D(\d\d?)(?:\D(\d\d?))?)?)?/
    ) {
        my @arg =
            ($6 || 0, $5 || 0, $4 || 0, $3 || 1, $2 - 1, $1 - 1900, 0, 0, 0);
        return sub { $language->gettext_strftime($_[0], @arg); };
    } else {
        return sub { $language->gettext("(unknown date)"); };
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

sub _mailbox {
    my ($context, $email, $comment) = @_;

    return sub {
        my $text = shift;

        return Sympa::Tools::Text::addrencode($email, $text,
            Conf::lang2charset($language->get_lang), $comment);
    };
}

sub _mailto {
    my ($context, $email, $query, $nodecode) = @_;

    return sub {
        my $text = shift;

        unless ($text =~ /\S/) {
            $text =
                $nodecode ? Sympa::Tools::Text::encode_html($email) : $email;
        }
        return sprintf '<a href="%s">%s</a>',
            Sympa::Tools::Text::encode_html(
            Sympa::Tools::Text::mailtourl(
                $email,
                decode_html => !$nodecode,
                query       => $query,
            )
            ),
            $text;
    };
}

sub _mailtourl {
    my ($context, $query) = @_;

    return sub {
        my $text = shift;

        return Sympa::Tools::Text::mailtourl($text, query => $query);
    };
}

sub _obfuscate {
    my ($context, $mode) = @_;

    return sub {shift}
        unless grep { $mode eq $_ } qw(at concealed javascript);

    return sub {
        my $text = shift;
        Sympa::HTMLDecorator->instance->decorate($text, email => $mode);
    };
}

sub _optdesc_func {
    my $self    = shift;
    my $type    = shift;
    my $withval = shift;

    my $that = $self->{context};
    my $encode_html = ($self->{subdir} && $self->{subdir} eq 'web_tt2');

    return sub {
        my $x = shift;
        return undef unless defined $x;
        return undef unless $x =~ /\S/;
        $x =~ s/^\s+//;
        $x =~ s/\s+$//;
        my $title = _get_option_description($that, $x, $type, $withval);
        $encode_html ? Sympa::Tools::Text::encode_html($title) : $title;
    };
}

# Old name: Sympa::List::get_option_title().
# Old name: Sympa::ListOpt::get_title().
# Old name: Sympa::ListOpt::get_option_description().
sub _get_option_description {
    my $that    = shift;
    my $option  = shift;
    my $type    = shift || '';
    my $withval = shift || 0;

    my $title = undef;

    if ($type eq 'dayofweek') {
        if ($option =~ /\A[0-9]+\z/) {
            $title = [
                split /:/,
                $language->gettext(
                    'Sunday:Monday:Tuesday:Wednesday:Thursday:Friday:Saturday'
                )
            ]->[$option % 7];
        }
    } elsif ($type eq 'lang') {
        $language->push_lang;
        if ($language->set_lang($option)) {
            $title = $language->native_name;
        }
        $language->pop_lang;
    } elsif ($type eq 'listtopic' or $type eq 'listtopic:leaf') {
        my $robot_id;
        if (ref $that eq 'Sympa::List') {
            $robot_id = $that->{'domain'};
        } elsif (ref $that eq 'Sympa::Family') {
            $robot_id = $that->{'domain'};
        } elsif ($that and $that ne '*') {
            $robot_id = $that;
        } else {
            $robot_id = '*';
        }
        if ($type eq 'listtopic') {
            $title = Sympa::Robot::topic_get_title($robot_id, $option);
        } else {
            $title =
                [Sympa::Robot::topic_get_title($robot_id, $option)]->[-1];
        }
    } elsif ($type eq 'password') {
        return '*' x length($option);    # return
    } elsif ($type eq 'unixtime') {
        $title = $language->gettext_strftime('%d %b %Y at %H:%M:%S',
            localtime $option);
    } else {
        my $map = {
            'reception'  => \%Sympa::ListOpt::reception_mode,
            'visibility' => \%Sympa::ListOpt::visibility_mode,
            'status'     => \%Sympa::ListOpt::list_status,
            'status:cap' => \%Sympa::ListOpt::list_status_capital,
        }->{$type}
            || \%Sympa::ListOpt::list_option;
        my $t = $map->{$option} || {};
        if ($t->{gettext_id}) {
            $title = $language->gettext($t->{gettext_id});
            $title =~ s/^\s+//;
            $title =~ s/\s+$//;
        }
    }

    if (defined $title) {
        return sprintf '%s (%s)', $title, $option if $withval;
        return $title;
    }
    return $option;
}

sub _permalink_id {
    my $string = shift;
    return Sympa::Tools::Text::permalink_id($string);
}

sub _url_func {
    my $self   = shift;
    my $is_abs = shift;
    my $data   = shift;
    my %options;
    @options{qw(paths query fragment)} = @_;

    # Flatten nested path components.
    if ($options{paths} and @{$options{paths}}) {
        $options{paths} =
            [map { ref $_ eq 'ARRAY' ? @$_ : ($_) } @{$options{paths}}];
    }

    @options{qw(authority decode_html nomenu)} = (
        ($is_abs ? 'default' : 'omit'),
        ($self->{subdir} && $self->{subdir} eq 'web_tt2'),
        ($self->{subdir} && $self->{subdir} eq 'web_tt2' && $data->{nomenu}),
    );

    my $that = $self->{context};
    my $robot_id =
          (ref $that eq 'Sympa::List')   ? $that->{'domain'}
        : (ref $that eq 'Sympa::Family') ? $that->{'domain'}
        : ($that and $that ne '*') ? $that
        :                            '*';

    return sub {
        my $action = shift;

        my %nomenu;
        if ($action and $action =~ m{\Anomenu/(.*)\z}) {
            $action = $1;
            %nomenu = (nomenu => 1);
        }
        my $url = Sympa::get_url($robot_id, $action, %options, %nomenu);
        $options{decode_html} ? Sympa::Tools::Text::encode_html($url) : $url;
    };
}

sub parse {
    my $self       = shift;
    my $data       = shift;
    my $tpl_string = shift;
    my $output     = shift;
    my %options    = @_;

    my @include_path;
    if (defined $self->{context}) {
        push @include_path,
            @{Sympa::get_search_path($self->{context}, %$self) || []};
    }
    if (@{$self->{include_path} || []}) {
        push @include_path, @{$self->{include_path}};
    }

    my $config = {
        ABSOLUTE     => ($self->{allow_absolute} ? 1 : 0),
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
            wrap      => [\&wrap,       1],
            mailbox   => [\&_mailbox,   1],
            mailto    => [\&_mailto,    1],
            mailtourl => [\&_mailtourl, 1],
            obfuscate => [\&_obfuscate, 1],
            optdesc => [sub { shift; $self->_optdesc_func(@_) }, 1],
            qencode     => [\&qencode,      0],
            escape_cstr => [\&_escape_cstr, 0],
            escape_xml  => [\&_escape_xml,  0],
            escape_url  => [\&_escape_url,  0],
            decode_utf8 => [\&decode_utf8,  0],
            encode_utf8 => [\&encode_utf8,  0],
            url_abs => [sub { shift; $self->_url_func(1, $data, @_) }, 1],
            url_rel => [sub { shift; $self->_url_func(0, $data, @_) }, 1],
            canonic_email => \&Sympa::Tools::Text::canonic_email,
            permalink_id  => [\&_permalink_id, 0],
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

=item {subdir}, {lang}, {lang_only}

TBD.

=back

=head2 Filters

These custom filters are defined by L<Sympa::Template>.
See L<Template::Manual::Filters> about usage of filters.

=over

=item canonic_email

Canonicalize e-mail address.

This filter was added by Sympa 6.2.17.

=item decode_utf8

No longer used.

=item encode_utf8

No longer used.

=item escape_cstr

Applies C-style escaping of a string (not enclosed by quotes).

This filter was added on Sympa 6.2.37b.1.

=item escape_quote

Escape quotation marks.

B<Deprecated>.
Use escape_cstr.

=item escape_url

Escapes URL.

This was OBSOLETED.  Use L</"mailtourl"> instead.

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

=item mailbox ( email, [ comment ] )

Generates mailbox string appropriately encoded to suit for addresses
in header fields.

=over

=item Filtered text

Display name, if any.

=item email

E-mail address.

=item comment

Comment, if any.

=back

This filter was introduced on Sympa 6.2.42.

=item mailto ( email, [ {key =E<gt> val, ...}, [ nodecode ] ] )

Generates HTML fragment linking to C<mailto:> URL,
i.e. C<E<lt>a href="mailto:I<email>"E<gt>I<filtered text>E<lt>/aE<gt>>.

=over

=item Filtered text

Content of linking element.
If it does not contain nonspaces, e-mail address will be used.

=item email

E-mail address(es) to be linked.

=item {key =E<gt> val, ...}

Optional query.

=item nodecode

If true, assumes arguments are not encoded as HTML entities.
By default entities are decoded at first.

This option does I<not> affect filtered text.

=back

Note:
This filter was introduced by Sympa 6.2.14.

=item mailtourl ( [ {key = val, ...} ] )

Generates C<mailto:> URL.

=over

=item Filtered text

E-mail address(es).
Note that any characters must not be encoded as HTML entities.

=item {key = val, ...}

Optional query.
Note that any characters must not be encoded as HTML entities.

=back

Note:
This filter was introduced by Sympa 6.2.14.

=item obfuscate ( mode )

Obfuscates email addresses in the HTML text according to mode.

=over

=item Filtered text

HTML document or fragment.

=item mode

Obfuscation mode.  C<at> or C<javascript>.
Invalid mode will be silently ignored.

=back

Note:
This filter was introduced by Sympa 6.2.14.

=item optdesc ( type, withval )

Generates i18n'ed description of list parameter value.

As of Sympa 6.2.17, if it is called by the web templates
(in C<web_tt2> subdirectories),
special characters in result will be encoded.

=over

=item Filtered text

Parameter value.

=item type

Type of list parameter value:
Special types (See L<Sympa::ListDef/"field_type">)
or others (default).

=item withval

If parameter value is added to the description.  False by default.

=back

=item permalink_id

Calculate permalink ID from message ID.

Note:
This filter was introduced by Sympa 6.2.71b.

=item qencode

Encode string by MIME header encoding.
Despite its name, appropriate encoding scheme
(C<Q> or C<B>) will be chosen.

=item unescape

No longer used.

=item url_abs ( ... )

Same as L</"url_rel"> but gives absolute URI.

Note:
This filter was introduced by Sympa 6.2.15.

=item url_rel ( [ paths, [ query, [ fragment ] ] ] )

Gives relative URI for specified action.

If it is called by the web templates (in C<web_tt2> subdirectories),
HTML entities in the arguments will be decoded
and special characters in resulting URL will be encoded.

=over

=item Filtered text

Name of action.

=item paths

Array.  Additional path components.

=item query

Hash.  Optional query.

=item fragment

Scalar.  Optional fragment.

=back

Note:
This filter was introduced by Sympa 6.2.15.

=item wrap ( init, subs, cols )

Generates folded text.

=over

=item init

Indentation (or its length) of each paragraph if any.

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
See <https://www.sympa.community/manual/customize/template-plugins.html>
about usage of plugins.

=head1 SEE ALSO

L<Template::Manual>.

=head1 HISTORY

Sympa 4.2b.3 adopted template engine based on Template Toolkit.

Plugin feature was added on Sympa 6.2.

L<tt2> module was renamed to L<Sympa::Template> on Sympa 6.2.

=cut
