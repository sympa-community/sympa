#!--PERL--
# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright 2017 The Sympa Community. See the AUTHORS.md file at the top-level
# directory of this distribution and at
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

use Sympatic -oo;

extends 'Sympa::Aliases';

use Conf;
use Sympa::Constants;
use Sympa::Language;
use Sympa::LockedFile;
use Sympa::Log;
use Sympa::Template;

my $language = Sympa::Language->instance;
my $alias_wrapper =
    Sympa::Constants::LIBEXECDIR . '/sympa_newaliases-wrapper';

sub _aliases {
    my $self = shift;
    my $list = shift;

    my $domain   = $list->{'domain'};
    my $listname = $list->{'name'};

    my $data = {
        'date' => $language->gettext_strftime('%d %b %Y', localtime time),
        'list' => {
            'domain' => $domain,
            'host'   => $list->{'admin'}{'host'},
            'name'   => $listname,
        },
        'robot'             => $domain,
        'default_domain'    => $Conf::Conf{'domain'},
        'is_default_domain' => ($domain eq $Conf::Conf{'domain'}),
        'return_path_suffix' =>
            Conf::get_robot_conf($domain, 'return_path_suffix'),
    };

    my $aliases_dump;
    my $template = Sympa::Template->new($domain);
    unless ($template->parse($data, 'list_aliases.tt2', \$aliases_dump)) {
        $self->log()->syslog(
            'err',
            'Can\'t parse list_aliases.tt2: %s',
            $template->{last_error}
        );
        return;
    }

    my @aliases = split /\n/, $aliases_dump;
    unless (@aliases) {
        $self->log()->syslog('err', 'No aliases defined');
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

    # Create a lock
    my $lock_fh;
    my $lock_file = Sympa::Constants::PIDDIR() . '/alias_manager.lock';
    unless ($lock_fh = Sympa::LockedFile->new($lock_file, 5, '+')) {
        $self->log()->syslog('err', 'Can\'t lock %s', $lock_file);
        return undef;
    }

    my $alias_file =
           $self->{file}
        || Conf::get_robot_conf($list->{'domain'}, 'sendmail_aliases')
        || Sympa::Constants::SENDMAIL_ALIASES;
    my @aliases = $self->_aliases($list);
    return undef unless @aliases;

    ## Check existing aliases
    if ($self->_already_defined($alias_file, @aliases)) {
        $self->log()->syslog('err', 'Some alias already exist');
        return undef;
    }

    my $fh;
    unless (open $fh, '>>', $alias_file) {
        $self->log()->syslog('err', 'Unable to append to %s: %m', $alias_file);
        return undef;
    }

    foreach (@aliases) {
        print $fh "$_\n";
    }
    close $fh;

    # Newaliases
    unless ($self->{file}) {
        system($alias_wrapper, '--domain=' . $list->{'domain'});
        if ($CHILD_ERROR == -1) {
            $self->log()->syslog('err', 'Failed to execute sympa_newaliases: %m');
            return undef;
        } elsif ($CHILD_ERROR & 127) {
            $self->log()->syslog(
                'err',
                'sympa_newaliases was terminated by signal %d',
                $CHILD_ERROR & 127
            );
            return undef;
        } elsif ($CHILD_ERROR) {
            $self->log()->syslog(
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

    # Create a lock
    my $lock_fh;
    my $lock_file = Sympa::Constants::PIDDIR() . '/alias_manager.lock';
    unless ($lock_fh = Sympa::LockedFile->new($lock_file, 5, '+')) {
        $self->log()->syslog('err', 'Can\'t lock %s', $lock_file);
        return undef;
    }

    my @aliases = $self->_aliases($list);
    return undef unless @aliases;

    my $alias_file =
           $self->{file}
        || Conf::get_robot_conf($list->{'domain'}, 'sendmail_aliases')
        || Sympa::Constants::SENDMAIL_ALIASES;
    my $tmp_alias_file = $Conf::Conf{'tmpdir'} . '/sympa_aliases.' . time;

    my $ifh;
    unless (open $ifh, '<', $alias_file) {
        $self->log()->syslog('err', 'Could not read %s: %m', $alias_file);
        return undef;
    }

    my $ofh;
    unless (open $ofh, '>', $tmp_alias_file) {
        $self->log()->syslog('err', 'Could not create %s: %m', $tmp_alias_file);
        return undef;
    }

    my @deleted_lines;
    while (my $alias = <$ifh>) {
        my $left_side = '';
        $left_side = $1 if $alias =~ /^([^\s:]+)[\s:]/;

        my $to_be_deleted = 0;
        foreach my $new_alias (@aliases) {
            next unless ($new_alias =~ /^([^\s:]+)[\s:]/);
            my $new_left_side = $1;

            if ($left_side eq $new_left_side) {
                push @deleted_lines, $alias;
                $to_be_deleted = 1;
                last;
            }
        }
        unless ($to_be_deleted) {
            ## append to new aliases file
            print $ofh $alias;
        }
    }
    close $ifh;
    close $ofh;

    unless (@deleted_lines) {
        $self->log()->syslog('err', 'No matching line in %s', $alias_file);
        return 0;
    }
    # Replace old aliases file.
    unless (open $ifh, '<', $tmp_alias_file) {
        $self->log()->syslog('err', 'Could not read %s: %m', $tmp_alias_file);
        return undef;
    }
    unless (open $ofh, '>', $alias_file) {
        $self->log()->syslog('err', 'Could not overwrite %s: %m', $alias_file);
        return undef;
    }
    print $ofh do { local $RS; <$ifh> };
    close $ofh;
    close $ifh;
    unlink $tmp_alias_file;

    # Newaliases
    unless ($self->{file}) {
        system($alias_wrapper, '--domain=' . $list->{'domain'});
        if ($CHILD_ERROR == -1) {
            $self->log()->syslog('err', 'Failed to execute sympa_newaliases: %m');
            return undef;
        } elsif ($CHILD_ERROR & 127) {
            $self->log()->syslog(
                'err',
                'sympa_newaliases was terminated by signal %d',
                $CHILD_ERROR & 127
            );
            return undef;
        } elsif ($CHILD_ERROR) {
            $self->log()->syslog(
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

# Check if an alias is already defined.
# Old name: already_defined() in alias_manager.pl.
sub _already_defined {
    my $self = shift;
    my $alias_file = shift;
    my @aliases    = @_;

    my $fh;
    unless (open $fh, '<', $alias_file) {
        $self->log()->syslog('err', 'Could not read %s: %m', $alias_file);
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
                $self->log()->syslog('info', 'Alias already defined: %s', $left_side);
                $ret++;
            }
        }
    }

    close $fh;
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
