# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright 2018 The Sympa Community. See the AUTHORS.md file at the
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

use strict;
use warnings;
use English qw(-no_match_vars);

use Sympa;
use Conf;
use Sympa::List;
use Sympa::LockedFile;
use Sympa::Log;
use Sympa::Template;

use base qw(Sympa::Request::Handler);

use constant _action_scenario => undef;            # Only listmasters allowed.
use constant _context_class   => 'Sympa::Family';

my $log = Sympa::Log->instance;

# Old name: Sympa::Admin::update_list(), Sympa::Family::_update_list().
sub _twist {
    my $self    = shift;
    my $request = shift;

    my $family   = $request->{context};
    my $list     = $request->{current_list};
    my $param    = $request->{parameters};
    my $robot_id = $family->{'robot'};

    # Check the template supposed to be used exist.
    my $template_file = Sympa::search_fullpath($family, 'config.tt2');
    unless (defined $template_file) {
        $log->syslog('err', 'No config template from family %s', $family);
        $self->add_stash($request, 'intern');
        return undef;
    }

    my $config = '';
    my $template =
        Sympa::Template->new(undef, include_path => [$family->{'dir'}]);
    unless ($template->parse($param, 'config.tt2', \$config)) {
        $log->syslog('err', 'Can\'t parse %s/config.tt2: %s',
            $family->{'dir'}, $template->{last_error});
        $self->add_stash($request, 'intern');
        return undef;
    }

    ### Check topics
    #if (defined $param->{'topics'}) {
    #    unless (_check_topics($param->{'topics'}, $robot_id)) {
    #        $log->syslog('err', 'Topics param %s not defined in topics.conf',
    #            $param->{'topics'});
    #    }
    #}

    ## Lock config before openning the config file
    my $lock_fh = Sympa::LockedFile->new($list->{'dir'} . '/config', 5, '>');
    unless ($lock_fh) {
        $log->syslog('err', 'Impossible to create %s/config: %s',
            $list->{'dir'}, $ERRNO);
        $self->add_stash($request, 'intern');
        return undef;
    }

    # Write config.
    # - Write out permanent owners/editors in <role>.dump files.
    # - Write remainder to config file.
    $config =~ s/(\A|\n)[\t ]+(?=\n)/$1/g;      # normalize empty lines
    open my $ifh, '<', \$config;                # open "in memory" file
    my @config = do { local $RS = ''; <$ifh> };
    close $ifh;
    foreach my $role (qw(owner editor)) {
        my $file = $list->{'dir'} . '/' . $role . '.dump';
        if (!-e $file and open my $ofh, '>', $file) {
            my $admins = join '', grep {/\A\s*$role\b/} @config;
            print $ofh $admins;
            close $ofh;
        }
    }
    print $lock_fh join '', grep { !/\A\s*(owner|editor)\b/ } @config;

    ## Unlock config file
    $lock_fh->close;

    #FIXME: Would info file be updated?

    ## Create associated files if a template was given.
    my @files_to_parse;
    foreach my $file (split ',',
        Conf::get_robot_conf($robot_id, 'parsed_family_files')) {
        $file =~ s{\s}{}g;
        push @files_to_parse, $file;
    }
    for my $file (@files_to_parse) {
        my $template_file = Sympa::search_fullpath($family, $file . ".tt2");
        if (defined $template_file) {
            my $file_content;

            my $template =
                Sympa::Template->new(undef,
                include_path => [$family->{'dir'}]);
            my $tt_result =
                $template->parse($param, $file . ".tt2", \$file_content);
            unless ($tt_result) {
                $log->syslog(
                    'err',
                    'Template error. List %s from family %s@%s, file %s: %s',
                    $param->{'listname'},
                    $family->{'name'},
                    $robot_id,
                    $file,
                    $template->{last_error}
                );
                next;    #FIXME: Abort processing and rollback.
            }
            unless (open FILE, '>', "$list->{'dir'}/$file") {
                $log->syslog('err', 'Impossible to create %s/%s: %s',
                    $list->{'dir'}, $file, $!);
            }
            print FILE $file_content;
            close FILE;
        }
    }

    ## Create list object
    my $listname = $list->{'name'};
    unless ($list = Sympa::List->new($listname, $robot_id)) {
        $log->syslog('err', 'Unable to create list %s', $listname);
        $self->add_stash($request, 'intern');
        return undef;
    }

    # Store permanent list users.
    #XXX$list->restore_users('member');
    $list->restore_users('owner');
    $list->restore_users('editor');

    #FIXME: Not saved?
    $list->{'admin'}{'creation'}{'date_epoch'} = time;
    $list->{'admin'}{'creation'}{'email'}      = $param->{'creation_email'}
        || Sympa::get_address($robot_id, 'listmaster');
    $list->{'admin'}{'status'} = $param->{'status'} || 'open';
    $list->{'admin'}{'family_name'} = $family->{'name'};

    ## Synchronize list members if required
    if ($list->has_include_data_sources()) {
        $log->syslog('notice', "Synchronizing list members...");
        $list->sync_include();
    }

    return 1;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Request::Handler::update_automatic_list -
update_automatic_list request handler

=head1 DESCRIPTION

Update a list with family concept when the list already exists.

TBD.

=head1 HISTORY

L<Sympa::Request::Handler::update_automatic_list> appeared on Sympa 6.2.33b.2.

=cut
