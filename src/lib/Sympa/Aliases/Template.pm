#!--PERL--
# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright 2017, 2018 The Sympa Community. See the AUTHORS.md file at the
# top-level directory of this distribution and at
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

package Sympa::Aliases::Template;

use strict;
use warnings;
use English qw(-no_match_vars);

use Conf;
use Sympa::Constants;
use Sympa::Language;
use Sympa::LockedFile;
use Sympa::Log;
use Sympa::Template;

use base qw(Sympa::Aliases::CheckSMTP);

my $language = Sympa::Language->instance;
my $log      = Sympa::Log->instance;

sub _aliases {
    my $self = shift;
    my $list = shift;

    my $domain   = $list->{'domain'};
    my $listname = $list->{'name'};

    my $data = {
        'date' => $language->gettext_strftime('%d %b %Y', localtime time),
        'list' => {
            'name'   => $listname,
            'domain' => $domain,
            # Compat. < 6.2.32
            'host' => $domain,
        },
        'is_default_domain' => ($domain eq $Conf::Conf{'domain'}),
        'return_path_suffix' =>
            Conf::get_robot_conf($domain, 'return_path_suffix'),

        # No longer used by default.
        'robot'          => $domain,
        'default_domain' => $Conf::Conf{'domain'},
    };

    my $aliases_dump;
    my $template = Sympa::Template->new($domain);
    unless ($template->parse($data, 'list_aliases.tt2', \$aliases_dump)) {
        $log->syslog(
            'err',
            'Can\'t parse list_aliases.tt2: %s',
            $template->{last_error}
        );
        return;
    }

    my @aliases = split /\n/, $aliases_dump;
    unless (@aliases) {
        $log->syslog('err', 'No aliases defined');
        return;
    }
    return @aliases;
}

sub add {
    my $self = shift;
    my $list = shift;

    return 0
        if lc Conf::get_robot_conf($list->{'domain'}, 'sendmail_aliases') eq
        'none';

    my @aliases = $self->_aliases($list);
    return undef unless @aliases;

    my $alias_file =
           $self->{file}
        || Conf::get_robot_conf($list->{'domain'}, 'sendmail_aliases')
        || Sympa::Constants::SENDMAIL_ALIASES();
    # Create a lock
    my $lock_fh;
    unless ($lock_fh = Sympa::LockedFile->new($alias_file, 20, '+>>')) {
        $log->syslog('err', 'Can\'t lock %s', $alias_file);
        return undef;
    }

    # Check existing aliases
    if (_already_defined($lock_fh, @aliases)) {
        $log->syslog('err', 'Some alias already exist');
        return undef;
    }

    # Append new entries.
    unless (seek $lock_fh, 0, 2) {
        $log->syslog('err', 'Unable to seek: %m');
        return undef;
    }
    foreach (@aliases) {
        print $lock_fh "$_\n";
    }
    $lock_fh->flush;

    # Newaliases
    unless ($self->{file}) {
        system(alias_wrapper($list), '--domain=' . $list->{'domain'});
        if ($CHILD_ERROR == -1) {
            $log->syslog('err', 'Failed to execute sympa_newaliases: %m');
            return undef;
        } elsif ($CHILD_ERROR & 127) {
            $log->syslog(
                'err',
                'sympa_newaliases was terminated by signal %d',
                $CHILD_ERROR & 127
            );
            return undef;
        } elsif ($CHILD_ERROR) {
            $log->syslog(
                'err',
                'sympa_newaliases exited with status %d',
                $CHILD_ERROR >> 8
            );
            return undef;
        }
    }

    # Unlock
    $lock_fh->close;

    return 1;
}

sub del {
    my $self = shift;
    my $list = shift;

    return 0
        if lc Conf::get_robot_conf($list->{'domain'}, 'sendmail_aliases') eq
        'none';

    my @aliases = $self->_aliases($list);
    return undef unless @aliases;

    my $alias_file =
           $self->{file}
        || Conf::get_robot_conf($list->{'domain'}, 'sendmail_aliases')
        || Sympa::Constants::SENDMAIL_ALIASES();
    # Create a lock
    my $lock_fh;
    unless ($lock_fh = Sympa::LockedFile->new($alias_file, 20, '+<')) {
        $log->syslog('err', 'Can\'t lock %s', $alias_file);
        return undef;
    }

    # Check existing aliases.
    my (@deleted_lines, @new_aliases);
    my @to_be_deleted =
        grep { defined $_ }
        map { ($_ and m{^([^\s:]+)[\s:]}) ? $1 : undef } @aliases;
    while (my $alias = <$lock_fh>) {
        my $left_side = ($alias =~ /^([^\s:]+)[\s:]/) ? $1 : '';
        if (grep { $left_side eq $_ } @to_be_deleted) {
            push @deleted_lines, $alias;
        } else {
            push @new_aliases, $alias;
        }
    }

    unless (@deleted_lines) {
        $log->syslog('err', 'No matching line in %s', $alias_file);
        return 0;
    }

    # Replace old aliases file.
    unless (seek $lock_fh, 0, 0) {
        $log->syslog('err', 'Could not seek: %m');
        return undef;
    }
    print $lock_fh join '', @new_aliases;
    $lock_fh->flush;
    truncate $lock_fh, tell $lock_fh;

    # Newaliases
    unless ($self->{file}) {
        system(alias_wrapper($list), '--domain=' . $list->{'domain'});
        if ($CHILD_ERROR == -1) {
            $log->syslog('err', 'Failed to execute sympa_newaliases: %m');
            return undef;
        } elsif ($CHILD_ERROR & 127) {
            $log->syslog(
                'err',
                'sympa_newaliases was terminated by signal %d',
                $CHILD_ERROR & 127
            );
            return undef;
        } elsif ($CHILD_ERROR) {
            $log->syslog(
                'err',
                'sympa_newaliases exited with status %d',
                $CHILD_ERROR >> 8
            );
            return undef;
        }
    }

    # Unlock
    $lock_fh->close;

    return 1;
}

sub alias_wrapper {
    my $list = shift;
    my $command;

    if (Conf::get_robot_conf($list->{'domain'}, 'aliases_wrapper') eq 'on'
        and -e Sympa::Constants::LIBEXECDIR . '/sympa_newaliases-wrapper') {
        return Sympa::Constants::LIBEXECDIR . '/sympa_newaliases-wrapper';
    }

    return Sympa::Constants::SBINDIR . '/sympa_newaliases.pl';
}

# Check if an alias is already defined.
# Old name: already_defined() in alias_manager.pl.
sub _already_defined {
    my $fh      = shift;
    my @aliases = @_;

    unless (seek $fh, 0, 0) {
        $log->syslog('err', 'Could not seek: %m');
        return undef;
    }

    my $ret = 0;
    while (my $alias = <$fh>) {
        # skip comment
        next if $alias =~ /^#/;
        $alias =~ /^([^\s:]+)[\s:]/;
        my $left_side = $1;
        next unless ($left_side);
        foreach (@aliases) {
            next unless ($_ =~ /^([^\s:]+)[\s:]/);
            my $new_left_side = $1;
            if ($left_side eq $new_left_side) {
                $log->syslog('info', 'Alias already defined: %s', $left_side);
                $ret++;
            }
        }
    }

    return $ret;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Aliases::Template -
Alias management: Aliases file based on template

=head1 SYNOPSIS

  use Sympa::Aliases;
  my $aliases = Sympa::Aliases->new('Template',
      [ file => '/path/to/file' ] );
  $aliases->check('listname', 'domain');
  $aliases->add($list);
  $aliases->del($list);

=head1 DESCRIPTION

L<Sympa::Aliases::Template> manages list aliases based on template
F<list_aliases.tt2>.

=head2 Methods

=over

=item check ( $listname, $domain )

See L<Sympa::Aliases::CheckSMTP>.

=item add ( $list )

=item del ( $list )

Adds or removes aliases of list $list.

If constructor was called with C<file> option, it will be used as aliases
file and F<sympa_newaliases> utility will not be executed.
Otherwise, value of C<sendmail_aliases> parameter will be used as aliases
file and F<sympa_newaliases> utility will be executed to update
alias database.
If C<sendmail_aliases> parameter is set to C<none>, aliases will never be
updated.

=back

=head2 Configuration parameters

=over

=item return_path_suffix

Suffix of list return address.

=item sendmail_aliases

Path of the file that contains all list related aliases.

=item tmpdir

A directory temporary files are placed.

=back

=head1 FILES

=over

=item F<$SYSCONFDIR/I<domain name>/list_aliases.tt2>

=item F<$SYSCONFDIR/list_aliases.tt2>

=item F<$DEFAULTDIR/list_aliases.tt2>

Template of aliases: Specific to a domain, global context and the default.

=item F<$SENDMAIL_ALIASES>

Default location of aliases file.

=item F<$SBINDIR/sympa_newaliases>

Auxiliary program to update alias database.

=back

=head1 SEE ALSO

L<Sympa::Aliases>,
L<Sympa::Aliases::CheckSMTP>,
L<sympa_newaliases(1)>.

=head1 HISTORY

F<alias_manager.pl> to manage aliases using template appeared on
Sympa 3.1b.13.

L<Sympa::Aliases::Template> module appeared on Sympa 6.2.23b,
and it obsoleted F<alias_manager(8)>.

=cut
