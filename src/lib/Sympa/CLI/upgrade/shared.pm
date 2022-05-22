# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright 2022 The Sympa Community. See the
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

package Sympa::CLI::upgrade::shared;

use strict;
use warnings;
use Encode qw();
use Encode::Guess qw();
use English qw(-no_match_vars);
use POSIX qw();

use Conf;
use Sympa::Constants;
use Sympa::Language;
use Sympa::List;
use Sympa::Log;
use Sympa::Tools::Text;

use parent qw(Sympa::CLI::upgrade);

use constant _options => qw(fix_qencode);
use constant _args => qw(list|site);
use constant _need_priv => 1;

my $language = Sympa::Language->instance;
my $log      = Sympa::Log->instance;

sub _run {
    my $class = shift;
    my $options = shift;
    my $that = shift;

if (ref $that eq 'Sympa::List') {
    process($that, $options);
} elsif ($that eq '*') {
    my $all_lists = Sympa::List::get_lists('*');
    foreach my $list (@{$all_lists || []}) {
        process($list, $options);
    }
} else {
    exit 1;
}

exit 0;
}

sub process {
    my $list = shift;
    my $options = shift;

    return unless ref $list eq 'Sympa::List';

    $log->syslog('notice', 'Upgrade shared for %s', $list);

    my $listname;
    my $robot;

    $listname = $list->{'name'};
    $robot    = $list->{'domain'};

    if (-d $list->{'dir'} . '/shared') {
        $log->syslog('notice', 'Processing list %s...', $list);

        ## Determine default lang for this list
        ## It should tell us what character encoding was used for
        ## filenames
        $language->push_lang($list->{'admin'}{'lang'},
            Conf::get_robot_conf($robot, 'lang'), 'en');
        my $list_encoding = Conf::lang2charset($language->get_lang);
        $language->pop_lang;

        my $count = _qencode_hierarchy($list->{'dir'} . '/shared',
            ($options->{fix_qencode} ? 'utf-8' : $list_encoding),
            $options);

        if ($count) {
            $log->syslog('notice', 'List %s: %d filenames has been changed',
                $list->{'name'}, $count);
        }
    }
    $log->syslog('notice', 'Upgrade_shared process finished');
}

# Old names: tools::qencode_hierarchy(),
# Sympa::Tools::File::qencode_hierarchy().
sub _qencode_hierarchy {
    my $dir               = shift;  # Root directory
    my $original_encoding = shift;  # Suspected original encoding of filenames
    my $options = shift;

    my $count;
    my @all_files;
    _list_dir($dir, \@all_files, $original_encoding);

    foreach my $f_struct (reverse @all_files) {

        ## At least one 8bit char
        next
            unless $f_struct->{'filename'} =~ /[^\x00-\x7f]/;

        my $new_filename;
        if ($options->{fix_qencoding}) {    #FIXME:Typo on key.
            # Decode and re-encode filename.
            $new_filename =
                Sympa::Tools::Text::qencode_filename(
                Sympa::Tools::Text::qdecode_filename($f_struct->{'filename'})
                );
        } else {
            $new_filename = $f_struct->{'filename'};
            my $encoding = $f_struct->{'encoding'};
            Encode::from_to($new_filename, $encoding, 'utf8') if $encoding;
            # Q-encode filename to escape chars with accents.
            $new_filename =
                Sympa::Tools::Text::qencode_filename($new_filename);
        }

        my $orig_f = $f_struct->{'directory'} . '/' . $f_struct->{'filename'};
        my $new_f  = $f_struct->{'directory'} . '/' . $new_filename;

        # Rename the file using utf-8.
        $count++ if rename $orig_f, $new_f;
    }

    return $count;
}

# Old name: Sympa::Tools::File::list_dir().
sub _list_dir {
    my $dir               = shift;
    my $all               = shift;
    my $original_encoding = shift;  # Suspected original encoding of filenames

    if (opendir my $dh, $dir) {
        foreach my $file (sort grep !/^\.\.?$/, readdir $dh) {
            if ($original_encoding eq 'utf-8') {
                push @$all,
                    {
                    'directory' => $dir,
                    'filename'  => $file,
                    'encoding'  => 'utf-8',
                    };
            } else {
                # Guess filename encoding
                my ($encoding, $guess);
                my $decoder =
                    Encode::Guess::guess_encoding($file, $original_encoding,
                    'utf-8');
                if (ref $decoder) {
                    $encoding = $decoder->name;
                } else {
                    $guess = $decoder;
                }

                push @$all,
                    {
                    'directory' => $dir,
                    'filename'  => $file,
                    'encoding'  => $encoding,
                    'guess'     => $guess
                    };
            }
            if (-d "$dir/$file") {
                _list_dir($dir . '/' . $file, $all, $original_encoding);
            }
        }
        closedir $dh;
    }

    return 1;
}

__END__

=encoding utf-8

=head1 NAME

sympa-upgrade-shared -
Migrating shared repository created by earlier versions

=head1 SYNOPSIS

  sympa upgrade shared LISTNAME@DOMAIN [ --fix_qencode ]

  sympa upgrade shared * [ --fix_qencode ]

=head1 DESCRIPTION

C< sympa upgrade shared> renames file names in shared repositories
that may be incorrectly encoded because of previous Sympa versions.

=over

=item *

As of Sympa 5.3a.8, file names in shared repository are Q-encoded,
therefore made easier to store on any filesystem with any encoding.

=item *

As of Sympa 6.1b.5, 
Encoding of shared documents was not consistent with recent
version of MIME::EncWords module:
MIME::EncWords::encode_mimewords() used to encode characters C<-!*+/>.
Now these characters are preserved, according to RFC 2047 section 5.
We had to change encoding of shared documents according to new algorithm.

=back

=head1 OPTIONS

=over

=item LISTNAME@DOMAIN | C<"*">

Specifies target list(s).

=item --fix_qencode

If specified, fixes Q-encoding changed on Sympa 6.1b.5.
Otherwise, applies Q-encoding introduced by Sympa 5.3a.8.

=back

=head1 HISTORY

upgrade_shared_repository.pl appeared as separate executable on Sympa 6.2.17.

Its function was moved to C<sympa upgrade shared> on Sympa 6.2.70.

=cut

