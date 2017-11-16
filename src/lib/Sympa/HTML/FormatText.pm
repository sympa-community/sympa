# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# This file is part of Sympa, see top-level README.md file for details

package Sympa::HTML::FormatText;

# This is a subclass of the HTML::FormatText object.
# This subclassing is done to allow internationalisation of some strings

use strict;

use Sympa::Language;

use base qw(HTML::FormatText);

my $language = Sympa::Language->instance;

sub img_start {
    my ($self, $node) = @_;

    my $alt = $node->attr('alt');
    $alt = Encode::encode_utf8($alt) if defined $alt;
    $self->out(
        Encode::decode_utf8(
            (defined $alt and $alt =~ /\S/)
            ? $language->gettext_sprintf("[Image:%s]", $alt)
            : $language->gettext("[Image]")
        )
    );
}

1;
