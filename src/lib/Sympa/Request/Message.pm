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

package Sympa::Request::Message;

use strict;
use warnings;

use Sympa::Log;
use Sympa::CommandDef;
use Sympa::Regexps;
use Sympa::Request;

my $log = Sympa::Log->instance;

# Methods.

sub new {
    my $class   = shift;
    my %options = @_;

    die 'bug in logic. Ask developer' unless $options{message};
    bless {%options, _metadatas => undef,} => $class;
}

sub next {
    my $self    = shift;

    unless ($self->{_metadatas}) {
        $self->{_metadatas} = $self->_load;
    }
    unless ($self->{_metadatas} and @{$self->{_metadatas}}) {
        undef $self->{_metadatas};
        return;
    }

    while (@{$self->{_metadatas}}) {
        my $request = shift @{$self->{_metadatas}};
        next unless $request;
        return ($request, 1);
    }
    return;
}

# Old name: (part of) DoCommand() in sympa_msg.pl.
sub _load {
    my $self = shift;

    my $message = $self->{message};

    my ($list, $robot);
    if (ref $message->{context} eq 'Sympa::List') {
        $list  = $message->{context};
        $robot = $list->{'domain'};
    } elsif ($message->{context} and $message->{context} ne '*') {
        $robot = $message->{context};
    } else {
        $robot = '*';
    }

    my $messageid = $message->{message_id};
    my $sender    = $message->{sender};

    # If type is subscribe or unsubscribe, parse as a single command.
    if (my $action =
        {subscribe => 'subscribe', unsubscribe => 'signoff'}
        ->{$message->{listtype} || ''}) {
        $log->syslog('debug', 'Processing message for %s type %s',
            $message->{context}, $message->{listtype});
        # FIXME: at this point $message->{'dkim_pass'} does not verify that
        # Subject: is part of the signature. It SHOULD !
        my $auth_level = $message->{'dkim_pass'} ? 'dkim' : undef;
        return [
            Sympa::Request->new_from_tuples(
                action => $action,
                cmd_line =>
                    sprintf('%s %s', $message->{listtype}, $list->{'name'}),
                context  => $list,
                email    => $message->{sender},
                message  => $message,
                sender   => $message->{sender},
                sign_mod => $auth_level,
            )
        ];
    }

    my $auth_level =
          $message->{'smime_signed'} ? 'smime'
        : $message->{'dkim_pass'}    ? 'dkim'
        :                              undef;

    ## Process the Subject of the message
    ## Search and process a command in the Subject field
    my $subject_field = $message->{'decoded_subject'};
    $subject_field = '' unless defined $subject_field;
    $subject_field =~ s/\n//mg;    ## multiline subjects
    my $re_regexp = Sympa::Regexps::re();
    $subject_field =~ s/^\s*(?:$re_regexp)?\s*(.*)\s*$/$1/i;
    if ($subject_field =~ /\S/) {
        my $request = _parse($robot, $subject_field, $auth_level, $message);
        return [$request] unless $request->{action} eq 'unknown';
    }

    # Process the body of the message unless subject contained commands or
    # message has no body.
    my $body = $message->get_plain_body;
    unless (defined $body) {
        $log->syslog('err', '%s: Could not change multipart to singlepart',
            $message);
        return [];
    }

    my @requests;
    foreach my $line (split /\r\n|\r|\n/, $body) {
        last if $line =~ /^-- $/;    # Ignore signature.
        $line =~ s/^\s*>?\s*(.*)\s*$/$1/g;
        next unless length $line;    # Skip empty lines.
        next if $line =~ /^\s*\#/;

        my $request = _parse($robot, $line, $auth_level, $message);
        if ($request) {
            if (@requests or $request->{action} ne 'unknown') {
                push @requests, $request;
            }
            last if $request->{action} eq 'unknown';
            last if $request->{action} eq 'finished';
        }
    }

    return [@requests];
}

# Parses the command and returns Sympa::Request instance.
# Old name: Sympa::Commands::parse().
sub _parse {
    $log->syslog('debug2', '(%s, %s, %s, %s)', @_);
    my $robot    = shift;
    my $line     = shift;
    my $sign_mod = shift;
    my $message  = shift;

    $log->syslog('notice', "Parsing: %s", $line);

    # Authentication key if 'auth' is present in the command line.
    my $auth = $1 if $line =~ s/\A\s*auth\s+(\S+)\s+(.+)\z/$2/i;
    # Boolean says if quiet is in the cmd line.
    my $quiet = 1 if $line =~ s/\Aquiet\s+(.+)\z/$1/i;

    my $l = $line;
    foreach my $action (sort keys %Sympa::CommandDef::comms) {
	my $comm = $Sympa::CommandDef::comms{$action};
        my $cmd_regexp = $comm->{cmd_regexp};
        my $arg_regexp = $comm->{arg_regexp};
        my $arg_keys   = $comm->{arg_keys};
        my $filter     = $comm->{filter};

        next unless $cmd_regexp and $l =~ s/\A($cmd_regexp)(\s+|\z)//;

        if (length $l) {
            $l =~ s/\A\s+//;
            $l =~ s/\s+\z//;
        }
        my (@matches, %args, $context);
        unless ($arg_regexp) {
            %args    = ();
            $context = $robot;
        } elsif (@matches = ($l =~ /\A$arg_regexp/)) {
            %args = (
                map {
                    my $value = shift @matches;
                    (defined $value and length $value)
                        ? (lc($_) => $value)
                        : ();
                    } @{$arg_keys}
            );

            if (not $args{anylists} and $args{localpart}) {
                # Load the list if not already done.
                $context =
                    Sympa::List->new($args{localpart}, $robot,
                    {just_try => 1});
            } else {
                $context = $robot || '*';
            }
        } else {
            return Sympa::Request->new_from_tuples(
                action   => $action,
                auth     => $auth,
                cmd_line => $line,
                context  => $robot,
                error    => 'syntax_error',
                message  => $message,
                quiet    => $quiet,
                sender   => $message->{sender},
                sign_mod => $sign_mod,
            );
        }

        my $request = Sympa::Request->new_from_tuples(
            %args,
            action   => $action,
            auth     => $auth,
            cmd_line => $line,
            context  => $context,
            message  => $message,
            quiet    => $quiet,
            sender   => $message->{sender},
            sign_mod => $sign_mod,
        );

        if (    not $args{anylists}
            and $args{localpart}
            and ref $request->{context} ne 'Sympa::List') {
            # Reject the command if this list is unknown to us.
            $request->{error} = 'unknown_list';
        } elsif ($filter and not $filter->($request)) {
            $request->{error} = 'syntax_error';
        }

        return $request;
    }

    # Unknown command.
    return Sympa::Request->new_from_tuples(
        action   => 'unknown',
        cmd_line => $line,
        context  => $robot,
        message  => $message,
        sender   => $message->{sender},
        sign_mod => $sign_mod,
    );
}

use constant quarantine => 1;
use constant remove     => 1;
use constant store      => 0;

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Request::Message - Command message as spool of requests

=head1 SYNOPSIS

  use Sympa::Request::Message;
  $spool = Sympa::Request::Message->new(message => $message);
  ($request, $handle) = $spool->next;

=head1 DESCRIPTION

L<Sympa::Request::Message> provides pseudo-spool to generate L<Sympa::Request>
instances from the L<Sympa::Message> instance.

=head2 Methods

=over

=item new ( message =E<gt> $message )

=item next ( )

Parses message $message and returns each command in it as L<Sympa::Request>
instance.

=back

=head1 HISTORY

L<Sympa::Request::Message> appeared in Sympa 6.2.13.

=cut
