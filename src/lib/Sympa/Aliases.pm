# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright 2017, 2018, 2021, 2024 The Sympa Community. See the
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

package Sympa::Aliases;

use strict;
use warnings;
use English qw(-no_match_vars);

use Conf;
use Sympa::Constants;
use Sympa::List;
use Sympa::Log;
use Sympa::Regexps;

my $log = Sympa::Log->instance;

# Sympa::Aliases is the proxy class of subclasses.
# The constructor may be overridden by _new() method.
sub new {
    my $class   = shift;
    my $type    = shift;
    my %options = @_;

    return undef unless $type;

    # Special cases:
    # - To disable aliases management, specify "none" as $type.
    # - "External" module is used for full path to program.
    # - However, "Template" module is used instead of obsoleted program
    #   alias_manager.pl.
    return $class->_new if $type eq 'none';

    if ($type eq Sympa::Constants::SBINDIR() . '/alias_manager.pl') {
        $type = 'Sympa::Aliases::Template';
    } elsif (0 == index $type, '/' and -x $type) {
        $options{program} = $type;
        $type = 'Sympa::Aliases::External';
    }

    # Returns appropriate subclasses.
    if ($type !~ /[^\w:]/) {
        $type = sprintf 'Sympa::Aliases::%s', $type unless $type =~ /::/;
        unless (eval sprintf('require %s', $type)
            and $type->isa('Sympa::Aliases')) {
            $log->syslog(
                'err', 'Unable to use %s module: %s',
                $type, $EVAL_ERROR || 'Not a Sympa::Aliases class'
            );
            return undef;
        }
        return $type->_new(%options);
    }

    return undef;
}

sub _new {
    my $class   = shift;
    my %options = @_;

    return bless {%options} => $class;
}

sub check {0}

sub add {0}

sub del {0}

# Check listname.
sub check_new_listname {
    my $listname = shift;
    my $robot_id = shift;

    unless (defined $listname and length $listname) {
        $log->syslog('err', 'No listname');
        return ('user', 'listname_needed');
    }

    $listname = lc $listname;

    my $listname_re = Sympa::Regexps::listname();
    unless (defined $listname
        and $listname =~ /^$listname_re$/i
        and length $listname <= Sympa::Constants::LIST_LEN()) {
        $log->syslog('err', 'Incorrect listname %s', $listname);
        return ('user', 'incorrect_listname', {bad_listname => $listname});
    }

    my $sfxs = Conf::get_robot_conf($robot_id, 'list_check_suffixes') // [];
    if (grep { lc("-$_") eq substr $listname, -length("-$_") } @$sfxs) {
        $log->syslog('err',
            'Incorrect listname %s matches one of service aliases',
            $listname);
        return ('user', 'listname_matches_aliases',
            {new_listname => $listname});
    }

    # Avoid "sympa", "listmaster", "bounce" and "bounce+XXX".
    if (   $listname eq Conf::get_robot_conf($robot_id, 'email')
        or $listname eq Conf::get_robot_conf($robot_id, 'listmaster_email')
        or $listname eq Conf::get_robot_conf($robot_id, 'bounce_email_prefix')
        or 0 == index(
            $listname,
            Conf::get_robot_conf($robot_id, 'bounce_email_prefix') . '+'
        )
    ) {
        $log->syslog('err',
            'Incorrect listname %s matches one of service aliases',
            $listname);
        return ('user', 'listname_matches_aliases',
            {new_listname => $listname});
    }

    # Prevent to use prohibited listnames
    my $regex = '';
    if ($Conf::Conf{'prohibited_listnames_regex'}) {
        $regex = eval(sprintf 'qr(%s)',
            $Conf::Conf{'prohibited_listnames_regex'} // '');
    }
    if ($Conf::Conf{'prohibited_listnames'}) {
        foreach my $l (split ',', $Conf::Conf{'prohibited_listnames'}) {
            $l =~ s/([^\s\w\x80-\xff])/\\$1/g;
            $l =~ s/(\\.)/$1 eq "\\*" ? '.*' : $1/eg;
            $l = sprintf('^%s$', $l);

            if ($regex) {
                $regex .= '|' . $l;
            } else {
                $regex .= $l;
            }
        }
    }
    if ($regex && $listname =~ m/$regex/i) {
        $log->syslog('err', 'Prohibited "%s"', $listname);
        return ('user', 'prohibited_listname', {argument => $listname});
    }

    # Check listname on SMTP server.
    my $aliases =
        Sympa::Aliases->new(Conf::get_robot_conf($robot_id, 'alias_manager'));
    my $res = $aliases->check($listname, $robot_id) if $aliases;
    unless (defined $res) {
        $log->syslog('err', 'Can\'t check list %.128s on %s',
            $listname, $robot_id);
        return ('intern');
    }

    # Check this listname doesn't exist already.
    if ($res or Sympa::List->new($listname, $robot_id, {'just_try' => 1})) {
        $log->syslog('err',
            'Could not create list %s: list on %s already exist',
            $listname, $robot_id);
        return ('user', 'list_already_exists', {new_listname => $listname});
    }

    return;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Aliases - Base class for alias management

=head1 SYNOPSIS

  package Sympa::Aliases::FOO;
  
  use base qw(Sympa::Aliases);
  
  sub check { ... }
  sub add { ... }
  sub del { ... }
  
  1;

=head1 DESCRIPTION 

This module is the base class for subclasses to manage list aliases of Sympa.

=head2 Methods

=over

=item new ( $type, [ key =E<gt> value, ... ] )

I<Constructor>.
Creates new instance of L<Sympa::Aliases>.

Returns one of appropriate subclasses according to $type:

=over

=item C<'none'>

No aliases management.

=item Full path to executable

Use external program to manage aliases.
See L<Sympa::Aliases::External>.

=item Name of subclass

Use a subclass C<Sympa::Aliases::I<name>> to manage aliases.

=back

For invalid types returns C<undef>.

Note:
For compatibility to the earlier versions of Sympa,
if a string C<SBINDIR/alias_manager.pl> was given as $type,
L<Sympa::Aliases::Template> subclass will be used.

Optional C<I<key> =E<gt> I<value>> pairs are included in the instance as
hash entries.

=item check ($listname, $robot_id)

I<Instance method>, I<overridable>.
Checks if the addresses of requested list exist already.

Parameters:

=over

=item $listname

Name of the list.
Mandatory.

=item $robot_id

List's robot.

=back

Returns:

True value if one of addresses exists.
C<0> if none found.
C<undef> if something wrong happened.

By default, this method always returns C<0>.

=item add ($list)

I<Instance method>, I<overridable>.
Installs aliases for the list $list.

Parameters:

=over

=item $list

An instance of L<Sympa::List>.

=back

Returns:

C<1> if installation succeeded.
C<0> if there were no aliases to be installed.
C<undef> if not applicable.

By default, this method always returns C<0>.

=item del ($list)

I<Instance method>, I<overridable>.
Removes aliases for the list $list.

Parameters:

=over

=item $list

An instance of L<Sympa::List>.

=back

Returns:

C<1> if removal succeeded.
C<0> if there were no aliases to be removed.
C<undef> if not applicable.

By default, this method always returns C<0>.

=back

=head2 Function

=over

=item check_new_listname ( $listname, $robot )

I<Function>.
Checks if a new listname is allowed.

TBD.

Parameteres:

=over

=item $listname

A list name to be checked.

=item $robot

Robot context.

=back

Returns:

If check fails, an array including information of errors.
If it succeeds, empty array.

B<Note>:
This should be used to check name of list to be created.
Names of existing lists may not necessarily pass checks by this function.

This function was added on Sympa 6.2.37b.2.

=back

=head1 SEE ALSO

L<Sympa::Aliases::CheckSMTP>,
L<Sympa::Aliases::External>,
L<Sympa::Aliases::Template>.

=head1 HISTORY

F<alias_manager.pl> as a program to automate alias management appeared on
Sympa 3.1b.13.

L<Sympa::Aliases> module as an OO-based class appeared on Sympa 6.2.23b,
and it obsoleted F<alias_manager.pl>.

=cut 
