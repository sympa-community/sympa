# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
# Copyright 2017, 2019 The Sympa Community. See the AUTHORS.md file at
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

package Sympa::Spindle::ProcessArchive;

use strict;
use warnings;
use English qw(-no_match_vars);
use POSIX qw();

use Sympa;
use Sympa::Archive;
use Conf;
use Sympa::List;
use Sympa::Log;
use Sympa::Process;
use Sympa::Spool::Listmaster;
use Sympa::Tools::File;

use base qw(Sympa::Spindle);

my $log = Sympa::Log->instance;

use constant _distaff => 'Sympa::Spool::Archive';

sub _init {
    my $self  = shift;
    my $state = shift;

    if ($state == 1) {
        # Process grouped notifications.
        Sympa::Spool::Listmaster->instance->flush;
    }

    1;
}

# Old name: process_message() in archived.pl.
sub _twist {
    my $self    = shift;
    my $message = shift;

    $log->syslog('notice', 'Processing %s; sender: %s; message ID: %s',
        $message, $message->{'sender'}, $message->{'message_id'});

    my ($robot_id, $list, $type);
    if (ref $message->{context} eq 'Sympa::List') {
        $robot_id = $message->{context}->{'domain'};
        $list     = $message->{context};
    } else {
        $robot_id = $message->{context};
    }
    $type = $message->{'listtype'} || '';

    # Unknown robot
    unless ($robot_id and $robot_id ne '*') {
        $log->syslog('err', 'Robot %s does not exist', $robot_id);
        return undef;
    }

    if ($type eq 'sympa') {
        return _do_command($robot_id, $message);
    } elsif (not $type and $list) {
        $log->syslog('notice', 'Archiving %s for list %s', $message, $list);
        if ($Conf::Conf{'custom_archiver'}) {
            # As id of the message object in archive spool includes filename,
            # it is filesystem-safe.
            my $tmpfile =
                'custom_archiver.' . [split /\//, $message->get_id]->[0];

            if (open my $fh, '>', $Conf::Conf{'tmpdir'} . '/' . $tmpfile) {
                print $fh $message->to_string(original => 1);
                close $fh;
            } else {
                $log->syslog('err', 'Can\'t open temporary file for %s: %m',
                    $message);
                return undef;
            }

            my $status = system($Conf::Conf{'custom_archiver'},
                '--list=' . $list->get_id,
                '--file=' . $Conf::Conf{'tmpdir'} . '/' . $tmpfile,
            ) >> 8;
            unlink $Conf::Conf{'tmpdir'} . '/' . $tmpfile;

            if ($status) {
                $log->syslog('err', 'Custom archiver exits with code %d',
                    $status);
                return undef;
            }
        } else {
            unless (_mail2arc($message)) {
                Sympa::send_notify_to_listmaster(
                    $robot_id,
                    'archiving_failed',
                    {   'file' => $message->get_id,
                        'bad'  => $self->{distaff}->{bad_directory}
                    }
                );
                return undef;
            }
        }
    } else {
        $log->syslog('err', 'Illegal format: %s', $message);
        return undef;
    }

    return 1;
}

# Private subroutines.

sub _do_command {
    my $robot_id = shift;
    my $message  = shift;

    my ($bodyh, $io);
    unless ($bodyh = $message->as_entity->bodyhandle
        and $io = $bodyh->open('r')) {
        $log->syslog('err', 'Format error: %s', $message);
        return undef;
    }

    while (my $line = $io->getline) {
        chomp $line;
        next unless $line =~ /\S/;
        next if $line =~ /\A\s*#/;

        my ($order, $listname, $args) = split /\s+/, $line, 3;

        my $context;
        if ($listname and $listname eq '*') {
            $context = $robot_id;
        } else {
            $context = Sympa::List->new($listname, $robot_id);
            unless ($context) {
                $log->syslog('err', 'Unknown list %s', $listname);
                next;
            }
        }

        if ($order eq 'remove_arc') {
            my ($arc, $msgid) = split /\s+/, $args, 2;
            unless (ref $context eq 'Sympa::List') {
                $log->syslog('err', 'Unknown list %s', $listname);
                next;
            }
            unless ($arc =~ /\A\d{4}-\d{2}\z/) {
                $log->syslog('err', 'Illegal archive path "%s"', $arc);
                next;
            }
            unless ($msgid and $msgid !~ /NO-ID-FOUND\.mhonarc\.org/) {
                $log->syslog('err', 'No message id found');
                next;
            }

            _do_remove_arc($context, $arc, $msgid, $message->{sender});
        } elsif ($order eq 'signal_spam') {
            my ($arc, $msgid) = split /\s+/, $args, 2;
            unless (ref $context eq 'Sympa::List') {
                $log->syslog('err', 'Unknown list %s', $listname);
                next;
            }
            unless ($arc =~ /\A\d{4}-\d{2}\z/) {
                $log->syslog('err', 'Illegal archive path "%s"', $arc);
                next;
            }
            unless ($msgid and $msgid !~ /NO-ID-FOUND\.mhonarc\.org/) {
                $log->syslog('err', 'No message id found');
                next;
            }

            _do_signal_as_spam($context, $arc, $msgid, $message->{sender});
        } elsif ($order eq 'rebuildarc') {
            my $arc = (defined $args and length $args) ? $args : '*';
            unless ($arc =~ /\A\d{4}-\d{2}\z/ or $arc eq '*') {
                $log->syslog('err', 'Illegal archive path "%s"', $arc);
                next;
            }

            if (ref $context eq 'Sympa::List') {
                _do_rebuildarc($context, $arc);
            } else {
                my $all_lists = Sympa::List::get_lists($context);
                foreach my $list (@{$all_lists || []}) {
                    _do_rebuildarc($list, $arc);
                }
            }
        } else {
            $log->syslog('err', 'Format error: Unknown command "%s"', $order);
            return undef;
        }
    }

    return 1;
}

# Note: Though namings "remove_arc" and "rebuildarc" are inconsistent, they
# are intentional, to keep in sync with functions of WWSympa.
# Old name: do_remove_arc() in archived.pl.
sub _do_remove_arc {
    $log->syslog('debug2', '(%s, %s, %s, %s)', @_);
    my $list   = shift;
    my $arc    = shift;
    my $msgid  = shift;
    my $sender = shift;

    my $archive = Sympa::Archive->new(context => $list);
    unless ($archive->select_archive($arc)) {
        $log->syslog('err', 'No archive %s of %s', $arc, $archive);
        return undef;
    }
    my ($arc_message, $arc_handle) = $archive->fetch(message_id => $msgid);
    unless ($arc_message) {
        $log->syslog('err',
            'Unable to load message with message ID %s found in %s of %s',
            $msgid, $arc, $archive);
        return undef;
    }

    # If not list owner, list editor nor listmaster, check if
    # sender of remove order is sender of the message to be
    # removed.
    unless ($list->is_admin('owner', $sender)
        or $list->is_admin('editor', $sender)
        or Sympa::is_listmaster($list, $sender)) {
        unless (lc $sender eq lc($arc_message->{sender} || '')) {
            $log->syslog('err',
                'Remove command for %s by unauthorized sender: %s',
                $arc_message, $sender);
            return undef;
        }
    }
    # At this point, requested command is from an authorized person
    # (message sender or list admin or listmaster).

    $log->syslog('notice', 'Removing %s in %s of archive %s',
        $msgid, $arc, $archive);

    unless ($archive->html_remove($msgid) and $archive->remove($arc_handle)) {
        return undef;
    }

    $log->db_log(
        'robot'      => $list->{'domain'},
        'list'       => $list->{'name'},
        'action'     => 'remove_arc',
        'parameters' => $msgid,
        'msg_id'     => $msgid,
        'status'     => 'success',
        'user_email' => $sender
    );
    $log->add_stat(
        'robot'     => $list->{'domain'},
        'list'      => $list->{'name'},
        'operation' => 'remove_arc',
        'mail'      => $sender
    );

    return 1;
}

sub _do_signal_as_spam {
    $log->syslog('debug2', '(%s, %s, %s, %s)', @_);
    my $list   = shift;
    my $arc    = shift;
    my $msgid  = shift;
    my $sender = shift;

    my $archive = Sympa::Archive->new(context => $list);
    unless ($archive->select_archive($arc)) {
        $log->syslog('err', 'No archive %s of %s', $arc, $archive);
        return undef;
    }
    my ($arc_message, $arc_handle) = $archive->fetch(message_id => $msgid);
    unless ($arc_message) {
        $log->syslog('err',
            'Unable to load message with message ID %s found in %s of %s',
            $msgid, $arc, $archive);
        return undef;
    }

    # If not list owner nor listmaster, check if
    # sender of remove order is sender of the message to be
    # removed.
    unless ($list->is_admin('owner', $sender)
        or Sympa::is_listmaster($list, $sender)) {
        unless (lc $sender eq lc($arc_message->{sender} || '')) {
            $log->syslog('err',
                'Signal as spam command for %s by unauthorized sender: %s',
                $arc_message, $sender);
            return undef;
        }
    }
    # At this point, requested command is from an authorized person
    # (message sender or list admin or listmaster).

    $log->syslog('notice', 'Signaling %s in %s of archive %s as spam',
        $msgid, $arc, $archive);

    if ($Conf::Conf{'reporting_spam_script_path'} ne '') {
        if (-x $Conf::Conf{'reporting_spam_script_path'}) {
            my $script;
            unless (
                open($script, "|$Conf::Conf{'reporting_spam_script_path'}")) {
                $log->syslog('err',
                    "could not execute $Conf::Conf{'reporting_spam_script_path'}"
                );
                return undef;
            }
            # Sending encrypted form in case a crypted message would be
            # sent by error.
            print $script $arc_message->as_string;

            if (close($script)) {
                $log->syslog('info',
                    "message $msgid reported as spam by $sender");
            } else {
                $log->syslog('err',
                    "could not report message $msgid as spam (close failed)");
                return undef;
            }
        } else {
            $log->syslog('err',
                "ignoring parameter reporting_spam_script_path, value $Conf::Conf{'reporting_spam_script_path'} because not an executable script"
            );
            return undef;
        }
    }

    $log->db_log(
        'robot'      => $list->{'domain'},
        'list'       => $list->{'name'},
        'action'     => 'signal_spam',
        'parameters' => $msgid,
        'msg_id'     => $msgid,
        'status'     => 'success',
        'user_email' => $sender
    );
    $log->add_stat(
        'robot'     => $list->{'domain'},
        'list'      => $list->{'name'},
        'operation' => 'signal_spam',
        'mail'      => $sender
    );

    return 1;
}

# Old name: do_rebuildarc() in archived.pl.
sub _do_rebuildarc {
    $log->syslog('debug2', '(%s, %s)', @_);
    my $list = shift;
    my $arc  = shift;

    my $archive = Sympa::Archive->new(context => $list, create => 1);

    if ($arc and $arc ne '*') {
        $log->syslog('notice', 'Rebuilding %s of %s', $arc, $archive);
        $archive->html_rebuild($arc);
    } else {
        $log->syslog('notice', 'Rebuilding archive of %s completely', $list);
        foreach my $arc ($archive->get_archives) {
            $archive->html_rebuild($arc);
        }
        $log->syslog('notice', 'Rebuild of %s archives completed', $list);
    }
}

# Old name: mail2arc() in archived.pl.
sub _mail2arc {
    $log->syslog('debug2', '(%s)', @_);
    my $message = shift;

    my $list = $message->{context};
    my $archive = Sympa::Archive->new(context => $list, create => 1);

    # chdir $arcpath;

    ## Check quota
    if ($list->{'admin'}{'archive'}{'quota'}) {
        my $used =
            Sympa::Tools::File::get_dir_size($archive->{base_directory});

        if ($used >= $list->{'admin'}{'archive'}{'quota'} * 1024) {
            $log->syslog('err', 'Web archive quota exceeded for list %s',
                $list);
            $list->send_notify_to_owner('arc_quota_exceeded',
                {'size' => $used});
            return undef;
        }
        if ($used >= ($list->{'admin'}{'archive'}{'quota'} * 1024 * 0.95)) {
            $log->syslog('err', 'Web archive quota exceeded for list %s',
                $list);
            $list->send_notify_to_owner(
                'arc_quota_95',
                {   'size' => $used,
                    'rate' => int(
                        $used * 100 /
                            ($list->{'admin'}{'archive'}{'quota'} * 1024)
                    )
                }
            );
        }
    }

    if ($list->{'admin'}{'archive'}{'max_month'}) {
        my $arc = POSIX::strftime('%Y-%m', localtime $message->{date});

        unless ($archive->select_archive($arc)) {
            $archive->add_archive($arc);
            unless ($archive->select_archive($arc)) {
                $log->syslog('err',
                    'Cannot create directory %s in archive %s',
                    $arc, $archive);
                return undef;
            }

            # maybe need to remove some old archive
            my @archives = $archive->get_archives;
            my $nb_month = scalar @archives;
            my $i        = 0;
            while ($nb_month > $list->{'admin'}{'archive'}{'max_month'}) {
                $log->syslog(
                    'info',
                    'Removing %s/%s',
                    $archive->{base_directory},
                    $archives[$i]
                );

                unless ($archives[$i] eq $arc) {
                    $archive->purge_archive($archives[$i]);
                }
                $i++;
                $nb_month--;
            }
        }
    }
    eval { 
        unless ($archive->store($message) and $archive->html_store($message)) {
            return undef;
        }
    } or return undef;
    return 1;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Spindle::ProcessArchive - Workflow of archive storage

=head1 SYNOPSIS

  use Sympa::Spindle::ProcessArchive;

  my $spindle = Sympa::Spindle::ProcessArchive->new;
  $spindle->spin;

=head1 DESCRIPTION

L<Sympa::Spindle::ProcessArchive> defines workflow to store messages into
archives.

When spin() method is invoked, messages kept in archive spool are
processed.
Archive spool may contain two sorts of messages:
Normal messages and control messages.

=over

=item *

Normal messages have List context and may be stored into archive.

=item *

Control messages have Robot context and their body contains one or more
command lines.  Following commands are available.

=over

=item remove_arc I<listname> I<yyyy>-I<mm> I<message-ID>

Removes a message from archive I<yyyy>-I<mm> of the list.
Text message is preserved.

=item rebuildarc I<listname> *

Rebuilds all HTML archives of the list.

=item rebuildarc * *

Rebuilds all HTML archives of all the lists on the robot.

=back

=back

=head2 Public methods

See also L<Sympa::Spindle/"Public methods">.

=head2 Properties

See also L<Sympa::Spindle/"Properties">.

=over

=item {distaff}

Instance of L<Sympa::Spool::Archive> class.

=back

=head1 SEE ALSO

L<Sympa::Archive>, L<Sympa::Spindle>, L<Sympa::Spool::Archive>.

=head1 HISTORY

L<Sympa::Spindle::StoreArchive> appeared on Sympa 6.2.10.
It was renamed to L<Sympa::Spindle::ProcessArchive> on Sympa 6.2.13.

=cut
