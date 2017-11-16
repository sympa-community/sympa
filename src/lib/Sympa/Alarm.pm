# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4

# This file is part of Sympa, see top-level README.md file for details

package Sympa::Alarm;

use strict;
use warnings;

use Sympa;
use Sympa::Bulk;
use Conf;
use Sympa::Log;
use Sympa::Mailer;
use Sympa::Message::Template;

use base qw(Class::Singleton);

my $log = Sympa::Log->instance;

# Constructor for Class::Singleton.
sub _new_instance {
    my $class = shift;

    bless {
        use_bulk => undef,
        _stack   => {},
    } => $class;
}

sub store {
    my $self    = shift;
    my $message = shift;
    my $rcpt    = shift;
    my %options = @_;

    my $mailer =
        $self->{use_bulk} ? Sympa::Bulk->new : Sympa::Mailer->instance;
    my $operation = $options{operation};

    my $robot_id;
    if (ref $message->{context} eq 'Sympa::List') {
        $robot_id = $message->{context}->{'domain'};
    } elsif ($message->{context} and $message->{context} ne '*') {
        $robot_id = $message->{context};
    } else {
        $robot_id = '*';
    }

    $self->{_stack}->{$robot_id}{$operation}{'first'} = time
        unless $self->{_stack}->{$robot_id}{$operation}{'first'};
    $self->{_stack}->{$robot_id}{$operation}{'counter'}++;
    $self->{_stack}->{$robot_id}{$operation}{'last'} = time;

    if ($self->{_stack}->{$robot_id}{$operation}{'counter'} > 3) {
        my @rcpts = ref $rcpt ? @$rcpt : ($rcpt);

        # stack if too much messages w/ same code
        $log->syslog('info', 'Stacking message about "%s" for %s (%s)',
            $operation, join(', ', @rcpts), $robot_id)
            unless $operation eq 'logs_failed';
        foreach my $rcpt (@rcpts) {
            push @{$self->{_stack}->{$robot_id}{$operation}{'messages'}{$rcpt}
                },
                $message->as_string;
        }
        return 1;
    } else {
        # Overwrite envelope sender
        $message->{envelope_sender} = Sympa::get_address($robot_id, 'owner');
        #FIXME: Priority would better to be '0', isn't it?
        $message->{priority} =
            Conf::get_robot_conf($robot_id, 'sympa_priority');

        return $mailer->store($message, $rcpt);
    }
}

sub flush {
    my $self    = shift;
    my %options = @_;

    my $mailer =
        $self->{use_bulk} ? Sympa::Bulk->new : Sympa::Mailer->instance;
    my $purge = $options{purge};

    foreach my $robot_id (keys %{$self->{_stack}}) {
        foreach my $operation (keys %{$self->{_stack}->{$robot_id}}) {
            my $first_age =
                time - $self->{_stack}->{$robot_id}{$operation}{'first'};
            my $last_age =
                time - $self->{_stack}->{$robot_id}{$operation}{'last'};
            # not old enough to send and first not too old
            next
                unless $purge
                or $last_age > 30
                or $first_age > 60;
            next
                unless $self->{_stack}->{$robot_id}{$operation}{'messages'};

            my %messages =
                %{$self->{_stack}->{$robot_id}{$operation}{'messages'}};
            $log->syslog(
                'info', 'Got messages about "%s" (%s)',
                $operation, join(', ', keys %messages)
            );

            ##### bulk send
            foreach my $rcpt (keys %messages) {
                my $param = {
                    to                    => $rcpt,
                    auto_submitted        => 'auto-generated',
                    operation             => $operation,
                    notification_messages => $messages{$rcpt},
                    boundary              => '----------=_'
                        . Sympa::unique_message_id($robot_id)
                };

                $log->syslog('info', 'Send messages to %s', $rcpt);

                # Skip DB access because DB is not accessible
                $rcpt = [$rcpt]
                    if $operation eq 'missing_dbd'
                    or $operation eq 'no_db'
                    or $operation eq 'db_restored';

                my $message = Sympa::Message::Template->new(
                    context  => $robot_id,
                    template => 'listmaster_groupednotifications',
                    rcpt     => $rcpt,
                    data     => $param
                );
                unless ($message) {
                    $log->syslog(
                        'notice',
                        'Unable to send template "listmaster_groupnotification" to %s listmaster %s',
                        $robot_id,
                        $rcpt
                    ) unless $operation eq 'logs_failed';
                    return undef;
                }
                unless (defined $mailer->store($message, $rcpt)) {
                    $log->syslog(
                        'notice',
                        'Unable to send template "listmaster_groupnotification" to %s listmaster %s',
                        $robot_id,
                        $rcpt
                    ) unless $operation eq 'logs_failed';
                    return undef;
                }
            }

            $log->syslog('info', 'Cleaning stacked notifications');
            delete $self->{_stack}->{$robot_id}{$operation};
        }
    }
    return 1;
}

1;

__END__

=encoding utf-8

=head1 NAME

Sympa::Alarm - Spool on memory for listmaster notification

=head1 SYNOPSIS

    use Sympa::Alarm;
    my $alarm = Sympa::Alarm->instance;

    $alarm->store($message, $rcpt, $operation);

    $alarm->flush();
    $alarm->flush(purge => 1);

=head1 DESCRIPTION

L<Sympa::Alarm> implements on-memory spool for listmaster notification.

=head2 Methods

=over

=item instance ( )

I<Constructor>.
Creates a singleton instance of L<Sympa::Alarm> object.

Returns:

A new L<Sympa::Alarm> instance, or undef for failure.

=item store ( $message, $rcpt, operation => $operation )

I<Instance method>.
Stores a message of a operation to spool.

Parameters:

=over

=item $message

L<Sympa::Message> object to be stored.

=item $rcpt

Arrayref or scalar.  Recipient of notification.

=item operation => $operation

A string specifys tag of the message.

=back

Returns:

True value if succeed, otherwise C<undef>.

=item flush ( [ purge => $purge ] )

I<Instance method>.
Sends compiled messages in spool.

If true value is given as optional argument, all messages in spool will be
sent.

=back

=head2 Attribute

The instance of L<Sympa::Alarm> has following attribute.

=over

=item {use_bulk}

If set to be true, messages to be sent will be stored into spool
instead of being stored to sendmail.

Default is false.

=back

=head1 HISTORY

Feature to compile notification to listmaster in group appeared on Sympa 6.2.

L<Sympa::Alarm> appeared on Sympa 6.2.

=cut
