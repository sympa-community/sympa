# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015 GIP RENATER
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

package Sympa::Spindle::ProcessTemplate;

use strict;
use warnings;

use Sympa::Log;

use base qw(Sympa::Spindle);

my $log = Sympa::Log->instance;

use constant _distaff => 'Sympa::Message::Template';

sub _on_failure {
    shift->{finish} = 'failure';
}

use constant _on_garbage => 1;
use constant _on_skip    => 1;

sub _on_success {
    shift->{finish} = 'success';
}

sub _twist {
    my $self    = shift;
    my $message = shift;

    $log->syslog(
        'notice',
        'Processing %s; envelope_sender=%s; message_id=%s; recipients=%s; sender=%s; template=%s; %s',
        $message,
        $message->{envelope_sender},
        $message->{message_id},
        $self->{rcpt},
        $message->{sender},
        $self->{template},
        join('; ',
            map { $self->{data}->{$_} ? ("$_=$self->{data}->{$_}") : () }
                qw(type action reason status))
    );

    $message->{rcpt} = $self->{rcpt};

    return $self->{splicing_to} || ['Sympa::Spindle::ToOutgoing'];
}

1;
__END__
