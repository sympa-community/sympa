# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright 2021 The Sympa Community. See the
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

package Sympa::CLI::md5_digest;

use strict;
use warnings;
use Digest::MD5;

use parent qw(Sympa::CLI);

use constant _options   => qw();
use constant _args      => qw(string);
use constant _need_priv => 0;

sub _run {
    my $class   = shift;
    my $options = shift;
    my $string  = shift;

    my $md5 = Digest::MD5::md5_hex($string);
    printf "md5 digest : %s \n", $md5;

    exit 0;

}

1;
__END__

=encoding utf-8

=head1 NAME

sympa-md5_digest - Output a MD5 digest

=head1 SYNOPSIS

C<sympa md5_digest> I<string>

=head1 DESCRIPTION

Output a MD5 digest of a string.
It is useful as password digest for SOAP client trusted application.

=cut
