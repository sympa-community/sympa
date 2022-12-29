# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright 2020 The Sympa Community. See the AUTHORS.md
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

package Sympa::WWW::FastCGI;

use strict;
use warnings;

use base qw(CGI::Fast);

use Sympa::WWW::Tools;

sub new {
    my $class = shift;
    my @args  = @_;

    my $self = $class->SUPER::new(@args);

    # Determin mail domain (a.k.a. "robot") the request is dispatched.
    # N.B. As of 6.2.15, the http_host parameter (replaced with
    # wwsympa_url_local parameter on 6.2.55b) will match with the host name
    # and path locally detected by server.  If remotely detected host name
    # and / or path should be differ, the proxy must adjust them.
    # N.B. As of 6.2.34, wwsympa_url parameter may be optional.
    my @vars =
        Sympa::WWW::Tools::get_robot('wwsympa_url_local', 'wwsympa_url');
    if (@vars) {
        @ENV{qw(ORIG_SCRIPT_NAME ORIG_PATH_INFO)} =
            @ENV{qw(SCRIPT_NAME PATH_INFO)};
        @ENV{qw(SYMPA_DOMAIN SCRIPT_NAME PATH_INFO)} = @vars;
    } else {
        delete $ENV{SYMPA_DOMAIN};
    }

    $self;
}

1;

__END__

=encoding utf-8

=head1 NAME

Sympa::WWW::FastCGI - CGI Interface for FastCGI of Sympa

=head1 SYNOPOSIS

  TBD.

=head1 DESCRIPTION

TBD.

=head1 SEE ALSO

L<CGI::Fast>.

RFC 3875, The Common Gateway Interface (CGI) Version 1.1.
L<https://tools.ietf.org/html/rfc3875>.

=head1 HISTORY

L<Sympa::WWW::FastCGI> appeared on Sympa 6.2.55b.

=cut

