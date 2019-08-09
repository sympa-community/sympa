# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
# Copyright 2019 The Sympa Community. See the AUTHORS.md file at
# the top-level directory of this distribution and at
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

package Sympa::Crash;

use strict;
use warnings;
use Carp qw();
use Encode qw();
use Scalar::Util qw();

BEGIN {
    no warnings;

    *Carp::format_arg = sub {
        my $arg = shift;

        if (Scalar::Util::blessed($arg) and $arg->can('get_id')) {
            $arg = sprintf('%s <%s>', ref $arg, $arg->get_id);
        } elsif (ref $arg) {
            $arg =
                defined($overload::VERSION) ? overload::StrVal($arg) : "$arg";
        } elsif (defined $arg) {
            unless (Scalar::Util::looks_like_number($arg)) {
                $arg = Carp::str_len_trim($arg, $Carp::MaxArgLen);
                $arg =~ s/([\\\'])/\\$1/g;
                $arg = "'$arg'";
            }
        } else {
            $arg = 'undef';
        }

        $arg =~ s/([^\x20-\x7E])/sprintf "\\x{%x}", ord $1/eg;
        Encode::_utf8_off($arg);
        return $arg;
    };
}

our $hook;

sub import {
    my $pkg     = shift;
    my %options = @_;

    if (exists $options{Hook} and ref $options{Hook} eq 'CODE') {
        $hook = $options{Hook};
    }
}

INIT {
    ## Register crash handler.  This is done during INIT phase so that
    ## compilation errors won't be captured.
    register_handler();
}

sub register_handler {
    $SIG{__DIE__} = \&_crash_handler;
}

# Handler for $SIG{__DIE__} to generate traceback.
# IN : error message
# OUT : none.  This function exits with status 255 or (if invoked from inside
# eval) simply returns.
our @CARP_NOT = qw(Carp);

sub _crash_handler {
    return if $^S;    # invoked from inside eval.

    my $mess = "$_[0]";
    chomp $mess;
    $mess =~ s/\r\n|\r|\n/ /g;

    local @CARP_NOT = qw(Carp);
    my $longmess = Carp::longmess("DIED: $mess\n");
    $longmess =~ s/(?<!\A)\n at \S+ line \d+\n/\n/;

    # Cleanup.
    # If any of corresponding modules have not been loaded, they are ignored.
    eval { Sympa::Log->instance->syslog('err', 'DIED: %s', $mess); };
    eval { Sympa::Spool::Listmaster->instance->flush(purge => 1); };
    eval { Sympa::DatabaseManager->disconnect(); };    # unlock database
    eval { Sys::Syslog::closelog(); };                 # flush log
    eval { Sympa::Log->instance->{level} = -1; };      # disable log

    # Call hook
    ($hook || \&_default_hook)->($_[0], $longmess);

    # If hook returns
    print STDERR $_[0];
    exit 255;
}

sub _default_hook {
    my ($mess, $longmess) = @_;

    print STDERR $longmess;
    exit 255;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Crash - Show traceback on critical error

=head1 SYNOPSIS

  use Sympa::Crash;
  
  # Registering custom hook.
  use Sympa::Crash Hook => \&myhook;

=head1 DESCRIPTION

Once L<Sympa::Crash> is loaded, crash by runtime error will be reported
via log and traceback will be shown in standard error.

If optional C<Hook> parameter is given, it will be executed instead.

=head2 Function

=over

=item register_handler ( )

Sometimes other modules overwrites error handler.
If that is the case, executing this function will register handler again.

=back

=head1 HISTORY

Sympa::Crash appeared on Sympa 6.2.

=cut
