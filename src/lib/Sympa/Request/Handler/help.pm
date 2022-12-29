# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
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

package Sympa::Request::Handler::help;

use strict;
use warnings;
use Time::HiRes qw();

use Sympa;
use Sympa::Language;
use Sympa::List;
use Sympa::Log;
use Sympa::User;

use base qw(Sympa::Request::Handler);

my $language = Sympa::Language->instance;
my $log      = Sympa::Log->instance;

use constant _action_scenario => undef;

# Old name: Sympa::Commands::help().
sub _twist {
    my $self    = shift;
    my $request = shift;

    my $robot  = $request->{context};
    my $sender = $request->{sender};

    my $data = {};

    my @owner  = Sympa::List::get_which($sender, $robot, 'owner');
    my @editor = Sympa::List::get_which($sender, $robot, 'editor');

    $data->{'is_owner'}  = 1 if @owner;
    $data->{'is_editor'} = 1 if @editor;
    $data->{'user'}      = Sympa::User->new($sender);
    $language->set_lang($data->{'user'}->lang)
        if $data->{'user'}->lang;
    $data->{'subject'}        = $language->gettext("User guide");
    $data->{'auto_submitted'} = 'auto-replied';

    unless (Sympa::send_file($robot, "helpfile", $sender, $data)) {
        $log->syslog('notice', 'Unable to send template "helpfile" to %s',
            $sender);
        $self->add_stash($request, 'intern');
        return undef;
    }

    $log->syslog(
        'info',  'HELP from %s accepted (%.2f seconds)',
        $sender, Time::HiRes::time() - $self->{start_time}
    );

    return 1;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Request::Handler::help - help request handler

=head1 DESCRIPTION

Sends the help file for the software using 'helpfile' template.

=head1 SEE ALSO

L<Sympa::Request::Handler>.

=head1 HISTORY

=cut
