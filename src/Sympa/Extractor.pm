package Sympa::Extractor;

use strict;
use base qw(Locale::Maketext::Extract::Plugin::Base);

our $VERSION = '0.1';

=head1 NAME

Sympa::Extractor - Sympa plugin for Locale::Maketext::Extract

=head1 SYNOPSIS

    $plugin = Sympa::Extractor->new(
        $lexicon            # A Locale::Maketext::Extract object
        @file_types         # Optionally specify a list of recognised file types
    )

    $plugin->extract($filename,$filecontents);

=head1 DESCRIPTION

Extracts strings to localise from List.pm and scenarios files

=head1 VALID FORMATS

gettext_id entries from List.pm, and title.gettext entries from scenarios are
extracted.

=head1 KNOWN FILE TYPES

=over 4

=item All file types

=back

=cut

sub file_types {
    return qw( * );
}


sub extract {
    my $self = shift;
    local $_ = shift;

    my $count = 1;

    foreach my $line (split(/\n/, $_)) {
        # scenarios
        if ($line =~ /^title.gettext\s+(.+)$/) {
            $self->add_entry($1, $count, '');
        }
        # List.pm
        if ($line =~ /'gettext_id'\s+=>\s+(["'])(.+)\1/) {
            $self->add_entry($2, $count, '');
        }
        $count++;
    }
}

1;
