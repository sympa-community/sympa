# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
# Copyright 2017, 2018, 2020 The Sympa Community. See the AUTHORS.md
# file at the top-level directory of this distribution and at
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

package Sympa::WWW::Tools;

use strict;
use warnings;
use Digest::MD5;
use English qw(-no_match_vars);
use File::Path qw();
use URI;
use URI::Escape qw();

use Sympa;
use Conf;
use Sympa::ConfDef;
use Sympa::Constants;
use Sympa::Language;
use Sympa::List;
use Sympa::LockedFile;
use Sympa::Log;
use Sympa::Regexps;
use Sympa::Template;
use Sympa::Tools::File;
use Sympa::Tools::Text;

my $log = Sympa::Log->instance;

## Cookie expiration periods with corresponding entry in NLS
our %cookie_period = (
    0     => {'gettext_id' => "session"},
    10    => {'gettext_id' => "10 minutes"},
    30    => {'gettext_id' => "30 minutes"},
    60    => {'gettext_id' => "1 hour"},
    360   => {'gettext_id' => "6 hours"},
    1440  => {'gettext_id' => "1 day"},
    10800 => {'gettext_id' => "1 week"},
    43200 => {'gettext_id' => "30 days"}
);

# File names with corresponding entry in NLS set
our %filenames = (
    'welcome.tt2'       => {'gettext_id' => "welcome message"},
    'bye.tt2'           => {'gettext_id' => "unsubscribe message"},
    'removed.tt2'       => {'gettext_id' => "deletion message"},
    'message_header'    => {'gettext_id' => "message header"},
    'message_footer'    => {'gettext_id' => "message footer"},
    'remind.tt2'        => {'gettext_id' => "remind message"},
    'reject.tt2'        => {'gettext_id' => "moderator rejection message"},
    'invite.tt2'        => {'gettext_id' => "subscribing invitation message"},
    'helpfile.tt2'      => {'gettext_id' => "help file"},
    'lists.tt2'         => {'gettext_id' => "directory of lists"},
    'global_remind.tt2' => {'gettext_id' => "global reminder message"},
    'summary.tt2'       => {'gettext_id' => "summary message"},
    'info'              => {'gettext_id' => "list description"},
    'homepage'          => {'gettext_id' => "list homepage"},
    'create_list_request.tt2' =>
        {'gettext_id' => "list creation request message"},
    'list_created.tt2' =>
        {'gettext_id' => "list creation notification message"},
    'your_infected_msg.tt2' => {'gettext_id' => "virus infection message"},
    'list_aliases.tt2'      => {'gettext_id' => "list aliases template"}
);

# Taken from IANA registry:
# <http://www.iana.org/assignments/smtp-enhanced-status-codes>
our %bounce_status = (
    '0.0'  => 'Other undefined Status',
    '1.0'  => 'Other address status',
    '1.1'  => 'Bad destination mailbox address',
    '1.2'  => 'Bad destination system address',
    '1.3'  => 'Bad destination mailbox address syntax',
    '1.4'  => 'Destination mailbox address ambiguous',
    '1.5'  => 'Destination address valid',
    '1.6'  => 'Destination mailbox has moved, No forwarding address',
    '1.7'  => 'Bad sender\'s mailbox address syntax',
    '1.8'  => 'Bad sender\'s system address',
    '1.9'  => 'Message relayed to non-compliant mailer',
    '1.10' => 'Recipient address has null MX',
    '2.0'  => 'Other or undefined mailbox status',
    '2.1'  => 'Mailbox disabled, not accepting messages',
    '2.2'  => 'Mailbox full',
    '2.3'  => 'Message length exceeds administrative limit',
    '2.4'  => 'Mailing list expansion problem',
    '3.0'  => 'Other or undefined mail system status',
    '3.1'  => 'Mail system full',
    '3.2'  => 'System not accepting network messages',
    '3.3'  => 'System not capable of selected features',
    '3.4'  => 'Message too big for system',
    '3.5'  => 'System incorrectly configured',
    '3.6'  => 'Requested priority was changed',
    '4.0'  => 'Other or undefined network or routing status',
    '4.1'  => 'No answer from host',
    '4.2'  => 'Bad connection',
    '4.3'  => 'Directory server failure',
    '4.4'  => 'Unable to route',
    '4.5'  => 'Mail system congestion',
    '4.6'  => 'Routing loop detected',
    '4.7'  => 'Delivery time expired',
    '5.0'  => 'Other or undefined protocol status',
    '5.1'  => 'Invalid command',
    '5.2'  => 'Syntax error',
    '5.3'  => 'Too many recipients',
    '5.4'  => 'Invalid command arguments',
    '5.5'  => 'Wrong protocol version',
    '5.6'  => 'Authentication Exchange line is too long',
    '6.0'  => 'Other or undefined media error',
    '6.1'  => 'Media not supported',
    '6.2'  => 'Conversion required and prohibited',
    '6.3'  => 'Conversion required but not supported',
    '6.4'  => 'Conversion with loss performed',
    '6.5'  => 'Conversion Failed',
    '6.6'  => 'Message content not available',
    '6.7'  => 'Non-ASCII addresses not permitted for that sender/recipient',
    '6.8' =>
        'UTF-8 string reply is required, but not permitted by the SMTP client',
    '6.9' =>
        'UTF-8 header message cannot be transferred to one or more recipients, so the message must be rejected',
    #'6.10' => '',    # Duplicate of 6.8, deprecated.
    '7.0'  => 'Other or undefined security status',
    '7.1'  => 'Delivery not authorized, message refused',
    '7.2'  => 'Mailing list expansion prohibited',
    '7.3'  => 'Security conversion required but not possible',
    '7.4'  => 'Security features not supported',
    '7.5'  => 'Cryptographic failure',
    '7.6'  => 'Cryptographic algorithm not supported',
    '7.7'  => 'Message integrity failure',
    '7.8'  => 'Authentication credentials invalid',
    '7.9'  => 'Authentication mechanism is too weak',
    '7.10' => 'Encryption Needed',
    '7.11' => 'Encryption required for requested authentication mechanism',
    '7.12' => 'A password transition is needed',
    '7.13' => 'User Account Disabled',
    '7.14' => 'Trust relationship required',
    '7.15' => 'Priority Level is too low',
    '7.16' => 'Message is too big for the specified priority',
    '7.17' => 'Mailbox owner has changed',
    '7.18' => 'Domain owner has changed',
    '7.19' => 'RRVS test cannot be completed',
    '7.20' => 'No passing DKIM signature found',
    '7.21' => 'No acceptable DKIM signature found',
    '7.22' => 'No valid author-matched DKIM signature found',
    '7.23' => 'SPF validation failed',
    '7.24' => 'SPF validation error',
    '7.25' => 'Reverse DNS validation failed',
    '7.26' => 'Multiple authentication checks failed',
    '7.27' => 'Sender address has null MX',
);

## Load WWSympa configuration file
##sub load_config
## MOVED: use Conf::_load_wwsconf().

## Load HTTPD MIME Types
# Moved to Conf::_load_mime_types().
#sub load_mime_types();

## Returns user information extracted from the cookie
# Deprecated.  Use Sympa::WWW::Session->new etc.
#sub get_email_from_cookie;

# NO LONGER USED.
#sub new_passwd;

## Basic check of an email address
# DUPLICATE: Use Sympa::Tools::Text::valid_email().
#sub valid_email($email);

# 6.2b: added $robot parameter.
# DEPRECATED.  No longer used.
#sub init_passwd;

# NOTE: As of 6.2.15, by default, less trustworthy "X-Forwarded-Host:" request
# field is not referred and this function returns host name and path
# respecting wwsympa_url robot parameter.  To change this behavior, use
# "authority" option (See Sympa::get_url()).
sub get_my_url {
    my $robot   = shift;
    my %options = @_;

    my $path_info    = $ENV{PATH_INFO} // '';
    my $query_string = $ENV{QUERY_STRING} // '';

    return
          Sympa::get_url($robot, undef, authority => $options{authority})
        . Sympa::Tools::Text::encode_uri($path_info, omit => '/')
        . (length $query_string ? '?' : '')
        . $query_string;
}

# Determine robot.
sub get_robot {
    my @keys = @_;

    # Get host part of script-URI from standard CGI environment variable
    # SERVER_NAME.
    # NOTE: As of 6.2.15, less trustworthy "X-Forwarded-Server:" request field
    # is _no longer_ referred and this function returns only locally detected
    # server name.
    my $request_host = lc($ENV{SERVER_NAME} // '');
    return unless length $request_host;
    my $ipv6_re = Sympa::Regexps::ipv6();
    if ($request_host =~ /\A$ipv6_re\z/) {    # IPv6 address
        $request_host = sprintf '[%s]', $request_host;
    }

    # Since CGI of some HTTP servers might split script-path and extra-path of
    # script-URI inproperly, we'd be better to reconstruct them from these
    # standard CGI environment variables:
    #   - SCRIPT_NAME: a URI path which could identify the CGI script.
    #   - PATH_INFO: derived from the portion of the URI path hierarchy
    #     following the part that identifies the script itself.
    # Note that they are not URL-encoded, unlike non-standard REQUEST_URI.
    my $org_script_name = $ENV{SCRIPT_NAME} // '';
    my $org_path_info   = $ENV{PATH_INFO} // '';
    return unless '' eq $org_script_name or 0 == index $org_script_name, '/';
    return unless '' eq $org_path_info   or 0 == index $org_path_info,   '/';
    my $request_path = $org_script_name . $org_path_info;

    # Find mail domain (a.k.a. "robot") of which web URL matches script-URI.
    my ($robot_id, $script_path) = (undef, undef);
    foreach my $rid (Sympa::List::get_robots()) {
        my $local_url;
        foreach my $key (@keys) {
            $local_url = Conf::get_robot_conf($rid, $key);
            last if $local_url;
        }
        next unless $local_url;

        if ($local_url =~ m{\A[-+\w]+:}) {
            ;
        } elsif ($local_url =~ m{\A//}) {
            $local_url = 'http:' . $local_url;
        } else {
            $local_url = 'http://' . $local_url;
        }

        my $uri = URI->new($local_url);
        next
            unless $uri
            and $uri->scheme
            and grep { $uri->scheme eq $_ } qw(http https);

        my $host = lc URI::Escape::uri_unescape($uri->host // '');
        my $path = URI::Escape::uri_unescape($uri->path // '');
        next unless $request_host eq $host;
        next
            unless $request_path eq $path
            or 0 == index $request_path, $path . '/';

        # The longest path wins.
        ($robot_id, $script_path) = ($rid, $path)
            if not defined $script_path
            or length $script_path < length $path;
    }

    return unless $robot_id;
    return
        wantarray
        ? ($robot_id, $script_path, substr $request_path, length $script_path)
        : $robot_id;
}

# Old name: (part of) get_header_field() in wwsympa.fcgi.
# No longer used.
#sub _get_server_name;

# Old name: (part of) get_header_field() in wwsympa.fcgi.
# NOTE: As of 6.2.15, less trustworthy "X-Forwarded-Host:" request field is
# _no longer_ referred and this function returns only locally detected host
# information.
sub get_http_host {
    my ($host, $port);

    my $hostport_re = Sympa::Regexps::hostport();
    my $ipv6_re     = Sympa::Regexps::ipv6();
    unless ($host = $ENV{HTTP_HOST} and $host =~ /\A$hostport_re\z/) {
        $host = $ENV{SERVER_NAME};
        $port = $ENV{SERVER_PORT};
    }
    return undef unless $host;

    if ($host =~ /\A$ipv6_re\z/) {    # IPv6 address
        $host = "[$host]";
    }
    unless ($host =~ /:\d+\z/) {
        $host = "$host:$port" if $port;
    }

    return lc $host;
}

# Determin cookie domain.
sub get_cookie_domain {
    my $robot = shift;

    # In case HTTP_HOST does not match cookie_domain, use former.
    # N.B. As of 6.2.15, the cookie domain will match with the host name
    # locally detected by server.  If remotely detected name should be differ,
    # the proxy must adjust it.
    my $cookie_domain = Conf::get_robot_conf($robot, 'cookie_domain');
    my $http_host = Sympa::WWW::Tools::get_http_host() || '';
    $http_host =~ s/:\d+\z//;    # Suppress port.
    my $dotdom = lc $cookie_domain;
    $dotdom =~ s/\A(?![.])/./;

    unless (substr($http_host, -length($dotdom)) eq $dotdom
        or ".$http_host" eq $dotdom
        or $cookie_domain eq 'localhost') {
        $log->syslog('debug',
            '(%s) Does NOT match HTTP_HOST; setting cookie_domain to %s',
            $cookie_domain, $http_host);
        return $http_host;
    }

    return $cookie_domain;
}

# Uploade source file to the destination on the server
# DEPRECATED.  No longer used.
#sub upload_file_to_server;

# DEPRECATED: No longer used.
#sub no_slash_end;

# DEPRECATED: No longer used.
#sub make_visible_path;

## returns a mailto according to list spam protection parameter
# DEPRECATED.  Use [%|mailto()%] and [%|obfuscate()%] filters in template.
#sub mailto;

# DEPRECATED: No longer used.
#sub find_edit_mode;

# DEPRECATED: No longer used.
#sub merge_edit;

# Moved: Use Sympa::WWW::SharedDocument::_load_desc_file().
#sub get_desc_file;

# DEPRECATED: No longer used.
#sub get_directory_content;

# DEPRECATED: No longer used (a subroutine of get_directory_content()).
#sub select_my_files;

# Moved to Sympa::WWW::SharedDocument::_get_icon().
#sub get_icon;

# Moved to: Conf::get_mime_type().
#sub get_mime_type;

## return a hash from the edit_list_conf file
# Old name: tools::load_create_list_conf().
sub _load_create_list_conf {
    my $robot = shift;

    my $file;
    my $conf;

    $file = Sympa::search_fullpath($robot, 'create_list.conf');
    unless ($file) {
        $log->syslog(
            'info',
            'Unable to read %s',
            Sympa::Constants::DEFAULTDIR . '/create_list.conf'
        );
        return undef;
    }

    unless (open(FILE, $file)) {
        $log->syslog('info', 'Unable to open config file %s', $file);
        return undef;
    }

    while (<FILE>) {
        next if /^\s*(\#.*|\s*)$/;

        if (/^\s*(\S+)\s+(read|hidden)\s*$/i) {
            $conf->{$1} = lc($2);
        } else {
            $log->syslog(
                'info',
                'Unknown parameter in %s (Ignored) %s',
                "$Conf::Conf{'etc'}/create_list.conf", $_
            );
            next;
        }
    }

    close FILE;
    return $conf;
}

# Old name: tools::get_list_list_tpl().
sub get_list_list_tpl {
    my $robot = shift;

    my $language = Sympa::Language->instance;

    my $list_conf;
    my $list_templates;
    unless ($list_conf = _load_create_list_conf($robot)) {
        return undef;
    }

    my %tpl_names;
    foreach my $directory (
        @{  Sympa::get_search_path(
                $robot,
                subdir => 'create_list_templates',
                lang   => $language->get_lang
            )
        }
    ) {
        my $dh;
        if (opendir $dh, $directory) {
            foreach my $tpl_name (readdir $dh) {
                next if $tpl_name =~ /\A\./;
                next unless -d $directory . '/' . $tpl_name;

                $tpl_names{$tpl_name} = 1;
            }
            closedir $dh;
        }
    }

LOOP_FOREACH_TPL_NAME:
    foreach my $tpl_name (keys %tpl_names) {
        my $status = $list_conf->{$tpl_name}
            || $list_conf->{'default'};
        next if $status eq 'hidden';

        # Look for a comment.tt2.
        # Check old style locale first then canonic language and its
        # fallbacks.
        my $comment_tt2 = Sympa::search_fullpath(
            $robot, 'comment.tt2',
            subdir => 'create_list_templates/' . $tpl_name,
            lang   => $language->get_lang
        );
        next unless $comment_tt2;

        open my $fh, '<', $comment_tt2 or next;
        my $tpl_string = do { local $RS; <$fh> };
        close $fh;

        pos $tpl_string = 0;
        my %titles;
        while ($tpl_string =~ /\G(title(?:[.][-\w]+)?[ \t]+(?:.*))(\n|\z)/cgi
            or $tpl_string =~ /\G(\s*)(\n|\z)/cg) {
            my $line = $1;
            last if $line =~ /\A\s*\z/;

            if ($line =~ /^title\.gettext\s+(.*)\s*$/i) {
                $titles{'gettext'} = $1;
            } elsif ($line =~ /^title\.(\S+)\s+(.*)\s*$/i) {
                my ($lang, $title) = ($1, $2);
                # canonicalize lang if possible.
                $lang = Sympa::Language::canonic_lang($lang) || $lang;
                $titles{$lang} = $title;
            } elsif (/^title\s+(.*)\s*$/i) {
                $titles{'default'} = $1;
            }
        }

        $list_templates->{$tpl_name}{'html_content'} = substr $tpl_string,
            pos $tpl_string;

        # Set the title in the current language
        foreach
            my $lang (Sympa::Language::implicated_langs($language->get_lang))
        {
            if (exists $titles{$lang}) {
                $list_templates->{$tpl_name}{'title'} = $titles{$lang};
                next LOOP_FOREACH_TPL_NAME;
            }
        }
        if ($titles{'gettext'}) {
            $list_templates->{$tpl_name}{'title'} =
                $language->gettext($titles{'gettext'});
        } elsif ($titles{'default'}) {
            $list_templates->{$tpl_name}{'title'} = $titles{'default'};
        }
    }

    return $list_templates;
}

# Old name: tools::get_templates_list().
sub get_templates_list {
    $log->syslog('debug3', '(%s, %s, %s => %s)', @_);
    my $that    = shift;
    my $type    = shift;
    my %options = @_;

    my ($list, $robot_id);
    if (ref $that eq 'Sympa::List') {
        $list     = $that;
        $robot_id = $that->{'domain'};
    } elsif ($that and $that ne '*') {
        $robot_id = $that;
    } else {
        die 'bug in logic. Ask developer';
    }

    my $listdir;

    unless ($type and ($type eq 'web' or $type eq 'mail')) {
        $log->syslog('info', 'Internal error incorrect parameter');
    }

    my $distrib_dir = Sympa::Constants::DEFAULTDIR . '/' . $type . '_tt2';
    my $site_dir    = $Conf::Conf{'etc'} . '/' . $type . '_tt2';
    my $robot_dir =
        $Conf::Conf{'etc'} . '/' . $robot_id . '/' . $type . '_tt2';

    my @try;

    ## The 'ignore_global' option allows to look for files at list level only
    unless ($options{ignore_global}) {
        push @try, $distrib_dir;
        push @try, $site_dir;
        push @try, $robot_dir;
    }

    if ($list) {
        $listdir = $list->{'dir'} . '/' . $type . '_tt2';
        push @try, $listdir;
    } else {
        $listdir = '';
    }

    my $i = 0;
    my $tpl;

    foreach my $dir (@try) {
        opendir my $dh, $dir or next;

        foreach my $file (grep { !/\A[.]/ } readdir $dh) {
            # Subdirectory for a lang
            if (-d $dir . '/' . $file) {
                #FIXME: Templates in subdirectories would be listed.
                next unless Sympa::Language::canonic_lang($file);

                my $lang = $file;
                opendir my $dh_lang, $dir . '/' . $lang or next;

                foreach my $file (grep { !/\A[.]/ } readdir $dh_lang) {
                    next unless ($file =~ /\.tt2$/);
                    if ($dir eq $distrib_dir) {
                        $tpl->{$file}{'distrib'}{$lang} =
                            $dir . '/' . $lang . '/' . $file;
                    }
                    if ($dir eq $site_dir) {
                        $tpl->{$file}{'site'}{$lang} =
                            $dir . '/' . $lang . '/' . $file;
                    }
                    if ($dir eq $robot_dir) {
                        $tpl->{$file}{'robot'}{$lang} =
                            $dir . '/' . $lang . '/' . $file;
                    }
                    if ($dir eq $listdir) {
                        $tpl->{$file}{'list'}{$lang} =
                            $dir . '/' . $lang . '/' . $file;
                    }
                }
                closedir $dh_lang;

            } else {
                next unless ($file =~ /\.tt2$/);
                if ($dir eq $distrib_dir) {
                    $tpl->{$file}{'distrib'}{'default'} = $dir . '/' . $file;
                }
                if ($dir eq $site_dir) {
                    $tpl->{$file}{'site'}{'default'} = $dir . '/' . $file;
                }
                if ($dir eq $robot_dir) {
                    $tpl->{$file}{'robot'}{'default'} = $dir . '/' . $file;
                }
                if ($dir eq $listdir) {
                    $tpl->{$file}{'list'}{'default'} = $dir . '/' . $file;
                }
            }
        }
        closedir $dh;
    }
    return ($tpl);

}

# Returns the path for a specific template.
# Old name: tools::get_template_path().
sub get_template_path {
    $log->syslog('debug2', '(%s, %s. %s, %s, %s)', @_);
    my $that  = shift;
    my $type  = shift;
    my $scope = shift;
    my $tpl   = shift;
    my $lang  = shift || 'default';

    my ($list, $robot_id);
    if (ref $that eq 'Sympa::List') {
        $list     = $that;
        $robot_id = $that->{'domain'};
    } elsif ($that and $that ne '*') {
        $robot_id = $that;
    } else {
        die 'bug in logic. Ask developer';
    }

    my $subdir = '';
    # canonicalize language name which may be old-style locale name.
    unless ($lang eq 'default') {
        my $oldlocale = Sympa::Language::lang2oldlocale($lang);
        unless ($oldlocale eq $lang) {
            $subdir = Sympa::Language::canonic_lang($lang);
            unless ($subdir) {
                $log->syslog('info', 'Internal error incorrect parameter');
                return undef;
            }
        }
    }

    unless ($type and ($type eq 'web' or $type eq 'mail')) {
        $log->syslog('info', 'Internal error incorrect parameter');
        return undef;
    }

    my $dir;
    if ($scope eq 'list') {
        unless ($list) {
            $log->syslog('err', 'Missing parameter "list"');
            return undef;
        }
        $dir = $list->{'dir'};
    } elsif ($scope eq 'robot') {
        $dir = $Conf::Conf{'etc'} . '/' . $robot_id;
    } elsif ($scope eq 'site') {
        $dir = $Conf::Conf{'etc'};
    } elsif ($scope eq 'distrib') {
        $dir = Sympa::Constants::DEFAULTDIR;
    } else {
        return undef;
    }

    $dir .= '/' . $type . '_tt2';
    $dir .= '/' . $subdir if length $subdir;
    return $dir . '/' . $tpl;
}

# Old name: Conf::update_css().
# DEPRECATED.  No longer used.
#sub update_css;

my %hash;

# get_css_url($robot, [ force => 1 ], [ lang => $lang | custom_css => $param ])
# Old name: (part of) Conf::update_css().
sub get_css_url {
    my $robot   = shift;
    my %options = @_;

    my ($url, $hash);
    if ($options{custom_css}) {
        my $umask = umask 022;
        ($url) = _get_css_url($robot, %options);
        umask $umask;
    } elsif ($options{lang}) {
        my $lang = Sympa::Language::canonic_lang($options{lang});
        return undef unless $lang;    # Malformed lang parameter.

        my $umask = umask 022;
        ($url, $hash) = _get_css_url($robot, %options, lang => $lang);
        umask $umask;

        $hash{$lang} = $hash if $hash;
    } else {
        my $umask = umask 022;
        ($url, $hash) = _get_css_url($robot, %options);
        umask $umask;

        $hash{_main} = $hash if $hash;
    }
    return $url;
}

sub _get_css_url {
    my $robot   = shift;
    my %options = @_;

    my %colors = %{$options{custom_css} || {}};
    my $lang = $options{lang};

    # Get parameters for parsing.
    my $param = {};
    foreach my $p (
        grep { /_color\z/ or /\Acolor_/ or /_url\z/ }
        map { $_->{name} }
        grep { not $_->{obsolete} and $_->{name} } @Sympa::ConfDef::params
    ) {
        $param->{$p} = Conf::get_robot_conf($robot, $p);
    }
    if (%colors) {
        # Override colors for parsing.
        my @keys =
            grep { defined $colors{$_} and length $colors{$_} } keys %colors;
        @{$param}{@keys} = @colors{@keys};
        $param->{custom_css} = 1;
    } elsif ($lang) {
        $param->{lang} = $lang;
    }
    $param->{css} = 'style.css';    # Compat. <= 6.2.16.

    # Get path and mtime of template file.
    my ($template_path, $template_mtime);
    if ($lang) {
        # Include only locale paths.
        $template_path = Sympa::search_fullpath(
            $robot, 'css.tt2',
            subdir    => 'web_tt2',
            lang      => $lang,
            lang_only => 1
        );
        # No template for specified language.
        return unless $template_path;
    } else {
        # Do not include locale paths (lang parameter).
        # The css.tt2 by each locale will override styles in main CSS.
        $template_path =
            Sympa::search_fullpath($robot, 'css.tt2', subdir => 'web_tt2');
        unless ($template_path) {    # Impossible case.
            my $url = Sympa::Tools::Text::weburl($Conf::Conf{'css_url'},
                [$robot, 'style.css']);
            return ($url);
        }
    }
    $template_mtime = Sympa::Tools::File::get_mtime($template_path);
    $param->{path}  = $template_path;
    $param->{mtime} = $template_mtime;

    my $hash = Digest::MD5::md5_hex(
        join ',',
        map { $_ . '=' . $param->{$_} }
            grep { defined $param->{$_} and length $param->{$_} }
            sort keys %$param
    );

    my ($dir, $path, $url);
    if (%colors) {
        $dir = sprintf '%s/%s', $Conf::Conf{'css_path'}, $robot;
        # Expire old files.
        if (opendir my $dh, $dir) {
            foreach my $file (readdir $dh) {
                next unless $file =~ /\Astyle[.][0-9a-f]+[.]css\b/;
                next unless -f $dir . '/' . $file;
                next
                    if time - 3600 <
                    Sympa::Tools::File::get_mtime($dir . '/' . $file);
                unlink $dir . '/' . $file;
            }
            closedir $dh;
        }

        $path = sprintf '%s/style.%s.css', $dir, $hash;
        $url = Sympa::Tools::Text::weburl($Conf::Conf{'css_url'},
            [$robot, sprintf 'style.%s.css', $hash]);
    } elsif ($lang) {
        $dir = sprintf '%s/%s/%s', $Conf::Conf{'css_path'}, $robot, $lang;

        $path = sprintf '%s/lang.css', $dir;
        $url = Sympa::Tools::Text::weburl(
            $Conf::Conf{'css_url'},
            [$robot, $lang, 'lang.css'],
            query => {h => $hash}
        );
    } else {
        # Use css_path and css_url parameters so that the user may provide
        # their own CSS.
        $dir = sprintf '%s/%s', $Conf::Conf{'css_path'}, $robot;

        $path = $dir . '/style.css';
        $url  = Sympa::Tools::Text::weburl(
            $Conf::Conf{'css_url'},
            [$robot, 'style.css'],
            query => {h => $hash}
        );
    }

    # Update the CSS if it is missing or if css.tt2 or configuration was
    # changed.
    if (-f $path and not $options{force}) {
        if (%colors) {
            return ($url);
        } elsif (
            (exists $hash{$lang || '_main'})
            ? ($hash{$lang || '_main'} eq $hash)
            : ($template_mtime < Sympa::Tools::File::get_mtime($path))
        ) {
            return ($url, $hash);
        }
    }

    $log->syslog(
        'notice',
        'Template file %s or configuration has changed; updating CSS file %s',
        $template_path,
        $path
    );

    # Create directory if required
    unless (-d $dir) {
        my $error;
        File::Path::make_path(
            $dir,
            {   mode  => 0755,
                owner => Sympa::Constants::USER(),
                group => Sympa::Constants::GROUP(),
                error => \$error
            }
        );
        if (@$error) {
            my ($target, $err) = %{$error->[-1] || {}};

            Sympa::send_notify_to_listmaster(
                $robot,
                'css_update_failed',
                {   error   => 'cannot_mkdir',
                    target  => $target,
                    message => $err
                }
            );
            $log->syslog('err', 'Failed to create %s: %s', $target, $err);

            return;
        }
    }

    # Lock file to prevent multiple processes from writing it.
    my $lock_fh = Sympa::LockedFile->new($path, -1, '+');
    unless ($lock_fh) {
        return ($url);
    }

    my $fh;
    unless (open $fh, '>', $path . '.new') {
        my $errno = $ERRNO;
        Sympa::send_notify_to_listmaster(
            $robot,
            'css_update_failed',
            {   error   => 'cannot_open_file',
                file    => $path,
                message => $errno,
            }
        );
        $log->syslog('err', 'Failed to open (write) file %s: %s',
            $path, $errno);

        return ($url) if -f $path;
        return;
    }

    my $template;
    if ($lang) {
        $template = Sympa::Template->new(
            $robot,
            subdir    => 'web_tt2',
            lang      => $lang,
            lang_only => 1
        );
    } else {
        $template = Sympa::Template->new($robot, subdir => 'web_tt2');
    }
    unless ($template->parse($param, 'css.tt2', $fh)) {
        my $error = $template->{last_error};
        $error = $error->as_string if ref $error;
        Sympa::send_notify_to_listmaster($robot, 'css_update_failed',
            {error => 'tt2_error', message => $error});
        $log->syslog('err', 'Error while installing %s', $path);

        # Keep previous file.
        close $fh;
        unlink $path . '.new';

        return ($url) if -f $path;
        return;
    }

    close $fh;

    # Keep copy of previous file.
    unless (
        (not -f $path or rename($path, $path . '.' . time) or unlink $path)
        and rename($path . '.new', $path)) {
        my $errno = $ERRNO;
        Sympa::send_notify_to_listmaster($robot, 'css_update_failed',
            {error => 'cannot_rename_file', message => $errno});
        $log->syslog('err', 'Error while installing %s: %s', $path, $errno);

        return;
    }

    # Expire old files.
    foreach my $file (<$path.*>) {
        next
            unless 0 == index($file, $path)
            and substr($file, length $path) =~ /\A[.]\d+\z/
            and -f $file;
        unlink $file;
    }

    return ($url, $hash);
}

# Old name: tools::escape_html().
# DEPRECATED.  No longer used.
#sub escape_html_minimum;

# Old name: tools::unescape_html().
# DEPRECATED.  No longer used.
#sub unescape_html_minimum;

1;
__END__
