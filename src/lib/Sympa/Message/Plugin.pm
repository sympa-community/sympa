# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# This file is part of Sympa, see top-level README.md file for details

package Sympa::Message::Plugin;

use strict;
use warnings;
use English qw(-no_match_vars);

use Sympa::Log;

our %handlers;

sub execute {
    my $hook_name = shift;
    my $message   = shift;
    my @params    = @_;

    my $log = Sympa::Log->instance;

    my $list = $message->{context};

    my $hook_module;
    my $hook_handler;

    unless ($hook_name and $hook_name =~ /\A\w+\z/) {
        die 'bug in Logic.  Ask developer';
    }
    $hook_module = $list->{'admin'}{'message_hook'}->{$hook_name};    #XXX
    unless ($hook_module and $hook_module =~ /\A(::|\w)+\z/) {
        return 0;
    }
    $hook_module = 'Sympa::Message::Plugin::' . $hook_module
        unless $hook_module =~ /::/;

    unless (exists $handlers{$hook_module . '->' . $hook_name}) {
        eval "use $hook_module;";
        if ($EVAL_ERROR) {
            $log->syslog('err', 'Cannot load hook module %s: %s',
                $hook_module, $EVAL_ERROR);
            return undef;
        }
        eval { $hook_handler = $hook_module->can($hook_name); };
        if ($EVAL_ERROR) {
            $log->syslog('err', 'Cannot get hook handler %s->%s: %s',
                $hook_module, $hook_name, $EVAL_ERROR);
            return undef;
        }
        $handlers{$hook_module . '->' . $hook_name} = $hook_handler;
    }
    unless (ref($handlers{$hook_module . '->' . $hook_name}) eq 'CODE') {
        return 0;
    }

    my $result;
    eval {
        $result = $hook_module->$hook_name($hook_name, $message, @params);
    };
    if ($EVAL_ERROR) {
        $log->syslog('err', 'Error processing %s->%s on %s: %s',
            $hook_module, $hook_name, $list, $EVAL_ERROR);
        return undef;
    }
    return $result;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::Message::Plugin - process hooks

=head1 SYNOPSIS

    Sympa::Message::Plugin::execute('post_archive', $message);

=head1 DESCRIPTION

Sympa::Message::Plugin provides hook mechanism to intervene in processing by
Sympa.
Each hook may modify objects (messages and so on) or may break ordinary
processing.

B<Notice>:
Hook mechanism is expreimental.
Module names and interfaces may be changed in the future.

=head2 Methods

=over 4

=item execute ( HOOK_NAME, MESSAGE, [ KEY =E<gt> VAL, ... ] )

Process message hook.

=back

=head2 Hooks

Currently, following hooks are supported:

=over 4

=item pre_distribute

I<Message hook>.
Message had been approved distribution (by scenario or by moderator), however,
it has not been decorated (adding custom subject etc.) nor archived yet.

=item post_archive

I<Message hook>.
Message had been archived, however, it has not been distributed to users
including digest spool; message has not been signed nor encrypted (if
necessary).

=back

=head2 How to add a hook to your Sympa

First, write your hook module:

  package My::Hook;

  use constant gettext_id => 'My message hook';
  
  sub post_archive {
      my $module  = shift;    # module name: "My::Hook"
      my $name    = shift;    # handler name: "post_archive"
      my $message = shift;    # Message object
      my %options = @_;
  
      # Processing, possiblly changing $message...
  
      # Return suitable result.
      # If unrecoverable error occurred, you may return undef or simply die.
      return 1;
  }
  
  1;

Then activate hook handler in your list config:

  message_hook
    post_archive My::Hook

=head1 SEE ALSO

L<Sympa::Message::Plugin::FixEncoding> - An example module for message hook.

=head1 HISTORY

L<Sympa::Message::Plugin> appeared on Sympa 6.2.
It was initially written by IKEDA Soji <ikeda@conversion.co.jp>.
