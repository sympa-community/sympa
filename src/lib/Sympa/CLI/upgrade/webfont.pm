# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright 2023 The Sympa Community. See the
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

package Sympa::CLI::upgrade::webfont;

use strict;
use warnings;
use English qw(-no_match_vars);
use IO::Scalar;

use Conf;
use Sympa::Constants;
use Sympa::Tools::File;

use parent qw(Sympa::CLI::upgrade);

use constant _options   => qw(dry-run|n);
use constant _args      => qw();
use constant _need_priv => 1;

my %fa4_fa6 = (
    'check-square-o' => ['check-square',         'far'],    # f14a
    'eye'            => ['eye',                  'far'],    # f06e
    'file-audio-o'   => ['file-audio',           'far'],    # f1c7
    'file-code-o'    => ['file-code',            'far'],    # f1c9
    'file-image-o'   => ['file-image',           'far'],    # f1c5
    'file-o'         => ['file',                 'far'],    # f15b
    'file-pdf-o'     => ['file-pdf',             'far'],    # f1c1
    'file-text-o'    => ['file-alt',             'far'],    # f15c
    'file-video-o'   => ['file-video',           'far'],    # f1c8
    'life-ring'      => ['life-ring',            'far'],    # f1cd
    'list-alt'       => ['list-alt',             'far'],    # f022
    'pencil'         => ['pencil-alt',           'fas'],    # f303
    'pencil-square'  => ['pen-square',           'fas'],    # f14b
    'shield'         => ['shield-alt',           'fas'],    # f3ed
    'star-o'         => ['star',                 'far'],    # f005
    'trash'          => ['trash-alt',            'fas'],    # f2ed
    'warning'        => ['exclamation-triangle', 'fas'],    # f071

    'pulse' => ['spin-pulse', 'fa'],
);

my %fi_fa4 = (
    'x'     => 'xmark',
    'alert' => 'warning',
);

sub _conv_fa_names {
    my @names = split /\s+/, shift;
    my $prefix = '';

    foreach (@names) {
        if (/\Afa-(.+)\z/) {
            my ($new, $pre) = @{$fa4_fa6{$1} || [$1, 'fa']};
            if ($prefix and $prefix ne $pre) {
                if ($prefix =~ /fas?\z/ and $pre =~ /fas?\z/) {
                    $pre = 'fas';
                } else {
                    warn "$new: $prefix vs $pre\n";
                }
            }

            $prefix = $pre;
            $_      = "fa-$new";
        }
    }
    $prefix ||= 'fa';
    @names = map { ($_ eq 'fa') ? $prefix : $_ } @names;

    return join ' ', @names;
}

sub _conv_fi_name {
    my @names = split /\s+/, shift;
    my $prefix = '';

    foreach (@names) {
        next unless /\Afi-(.+)\z/;
        my $name = $1;

        if (0 == index $name, 'social-') {
            next;
        } elsif (my $new = $fi_fa4{$name}) {
            $prefix = 'fa';
            $_      = "fa-$new";
        } else {
            $prefix = 'fa';
            $_      = "fa-$name";
        }
    }

    if ($prefix) {
        return _conv_fa_names(join ' ', $prefix, @names);
    } else {
        return join ' ', @names;
    }
}

sub _run {
    my $class   = shift;
    my $options = shift;

    my @directories;
    my @templates;

    if (-d "$Conf::Conf{'etc'}/web_tt2") {
        push @directories, "$Conf::Conf{'etc'}/web_tt2";
    }
    if (-f "$Conf::Conf{'etc'}/mhonarc_rc.tt2") {
        push @templates, "$Conf::Conf{'etc'}/mhonarc_rc.tt2";
    }

    foreach my $vr (keys %{$Conf::Conf{'robots'}}) {
        if (-d "$Conf::Conf{'etc'}/$vr/web_tt2") {
            push @directories, "$Conf::Conf{'etc'}/$vr/web_tt2";
        }
        if (-f "$Conf::Conf{'etc'}/$vr/mhonarc_rc.tt2") {
            push @templates, "$Conf::Conf{'etc'}/$vr/mhonarc_rc.tt2";
        }
    }

    my $all_lists = Sympa::List::get_lists('*');
    foreach my $list (@$all_lists) {
        if (-d ($list->{'dir'} . '/web_tt2')) {
            push @directories, $list->{'dir'} . '/web_tt2';
        }
        if (-f ($list->{'dir'} . '/mhonarc_rc.tt2')) {
            push @templates, $list->{'dir'} . '/mhonarc_rc.tt2';
        }
    }

    foreach my $d (@directories) {
        my $dh;
        unless (opendir $dh, $d) {
            printf STDERR "Error: Cannot read %s directory: %s", $d, $ERRNO;
            next;
        }

        foreach my $tt2 (sort grep {/[.]tt2$/} readdir $dh) {
            push @templates, "$d/$tt2";
        }

        closedir $dh;
    }

    my $umask = umask 022;

    foreach my $tpl (sort @templates) {
        process($tpl, $options);
    }

    umask $umask;
}

sub process {
    my $in      = shift;
    my $options = shift;

    my $ifh;
    unless (open $ifh, '<', $in) {
        warn sprintf "%s: %s\n", $in, $ERRNO;
        return;
    }
    $_ = do { local $RS; <$ifh> };
    close $ifh;
    my $orig = $_;

    my $out = '';
    my $ofh = IO::Scalar->new(\$out);

    pos $_ = 0;
    while (
        m{
          \G
          (
            [^<]+
          | <i\s+[^>]*?\bclass="([^"]*\bfa\b[^"]*)"[^>]*>
          | <i\s+[^>]*?\bclass="(fi-[^"]*)"[^>]*>
          | <[^>]*>
          )
        }cgsx
    ) {
        if (defined $2) {
            my ($elm, $cls) = ($1, $2);
            $cls =~ s/\A\s+//;
            $cls =~ s/\s+\z//;
            my $new = _conv_fa_names($cls);
            $elm =~ s/\bclass="[^"]+"/class="$new"/
                unless $new eq $cls;
            print $ofh $elm;
        } elsif (defined $3) {
            my ($elm, $cls) = ($1, $3);
            $cls =~ s/\A\s+//;
            $cls =~ s/\s+\z//;
            my $new = _conv_fi_name($cls);
            $elm =~ s/\bclass="[^"]+"/class="$new"/
                unless $new eq $cls;
            print $ofh $elm;
        } else {
            print $ofh $1;
            next;
        }
    }

    if ($orig eq $out) {
        warn sprintf "%s: no changes.\n", $in unless $options->{noout};
    } else {
        warn sprintf "%s: updated.\n", $in unless $options->{noout};
        unless ($options->{dry_run}) {
            unless (rename $in, sprintf '%s.upgrade%d', $in, time()) {
                warn "%s: %s\n", $in, $ERRNO;
                return;
            }
            if (open my $ofh, '>', $in) {
                print $ofh $out;
                Sympa::Tools::File::set_file_rights(
                    file  => $in,
                    user  => Sympa::Constants::USER(),
                    group => Sympa::Constants::GROUP()
                );
            } else {
                warn "%s: %s\n", $in, $ERRNO;
                return;
            }
        }
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

sympa-upgrade-webfont - Upgrading font in web templates

=head1 SYNOPSIS

  sympa upgrade webfont [--dry_run|-n]

=head1 OPTIONS

=over

=item --dry_run|-n

Shows what will be done but won't really perform the upgrade process.

=back

=head1 DESCRIPTION

Versions 6.2.72 or later uses Font Awesome Free which is not compatible to
Font Awesome 4.x or earlier.
To solve this problem, this command upgrades customized web templates.

=head1 HISTORY

This command appeared on Sympa 6.2.72.

=cut

