# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016, 2017 GIP RENATER
# Copyright 2017, 2018, 2019 The Sympa Community. See the AUTHORS.md file at
# the top-level directory of this distribution and at
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

package Sympa::DatabaseDescription;

use strict;
use warnings;

use Sympa::Constants;

my $email_struct  = sprintf 'varchar(%d)', Sympa::Constants::EMAIL_LEN();
my $family_struct = sprintf 'varchar(%d)', Sympa::Constants::FAMILY_LEN();
my $list_struct   = sprintf 'varchar(%d)', Sympa::Constants::LIST_LEN();
my $robot_struct  = sprintf 'varchar(%d)', Sympa::Constants::ROBOT_LEN();
my $list_id_struct = sprintf 'varchar(%d)',
    Sympa::Constants::LIST_LEN() + 1 + Sympa::Constants::ROBOT_LEN();

my %full_db_struct = (
    'subscriber_table' => {
        'fields' => {
            'user_subscriber' => {
                'struct'   => $email_struct,
                'doc'      => 'email of subscriber',
                'primary'  => 1,
                'not_null' => 1,
                'order'    => 1
            },
            'list_subscriber' => {
                'struct'   => $list_struct,
                'doc'      => 'list name of a subscription',
                'primary'  => 1,
                'not_null' => 1,
                'order'    => 2
            },
            'robot_subscriber' => {
                'struct'   => $robot_struct,
                'doc'      => 'robot (domain) of the list',
                'primary'  => 1,
                'not_null' => 1,
                'order'    => 3
            },
            'reception_subscriber' => {
                'struct' => 'varchar(20)',
                'doc' =>
                    'reception format option of subscriber (digest, summary, etc.)',
                'order' => 4,
            },
            'suspend_subscriber' => {
                'struct' => 'int(1)',
                'doc'    => 'boolean set to 1 if subscription is suspended',
                'order'  => 5,
            },
            'suspend_start_date_subscriber' => {
                'struct' => 'int(11)',
                'doc' => 'the Unix time when message reception is suspended',
                'order' => 6,
            },
            'suspend_end_date_subscriber' => {
                'struct' => 'int(11)',
                'doc' =>
                    'the Unix time when message reception should be restored',
                'order' => 7,
            },
            'bounce_subscriber' => {
                'struct' => 'varchar(35)',
                'doc'    => 'FIXME',
                'order'  => 8,
            },
            'bounce_score_subscriber' => {
                'struct' => 'smallint(6)',
                'doc'    => 'FIXME',
                'order'  => 9,
            },
            'bounce_address_subscriber' => {
                'struct' => $email_struct,
                'doc'    => 'FIXME',
                'order'  => 10,
            },
            #'date_subscriber' => {
            #    'struct'   => 'datetime',
            #    'doc'      => 'date of subscription',
            #    'not_null' => 1,
            #    'order'    => 11,
            #},
            'date_epoch_subscriber' => {
                'struct'   => 'int(11)',
                'doc'      => 'date of subscription',
                'not_null' => 1,
                'order'    => 11.5,
            },
            # Obsoleted as of 6.2.25b.2. Use update_epoch_subscriber.
            #'update_subscriber' => {
            #    'struct' => 'datetime',
            #    'doc' =>
            #        'the latest date where subscription is confirmed by subscriber',
            #    'order' => 12,
            #},
            'update_epoch_subscriber' => {
                'struct' => 'int(11)',
                'doc' =>
                    'the last time when subscription is confirmed by subscriber',
                'order' => 12.5,
            },
            'inclusion_subscriber' => {
                'struct' => 'int(11)',
                'doc' =>
                    'the last time when list user is synchronized with data source',
                'order' => 12.6,
            },
            'inclusion_ext_subscriber' => {
                'struct' => 'int(11)',
                'doc' =>
                    'the last time when list user is synchronized with external data source',
                'order' => 12.7,
            },
            'inclusion_label_subscriber' => {
                'struct' => 'varchar(50)',
                'doc'    => 'name of data source',
                'order'  => 12.8,
            },
            'comment_subscriber' => {
                'struct' => 'varchar(150)',
                'doc'    => 'free form name',
                'order'  => 13,
            },
            'number_messages_subscriber' => {
                'struct'   => 'int(5)',
                'doc'      => 'the number of message the subscriber sent',
                'not_null' => 1,
                'order'    => 5,
                'order'    => 14,
            },
            'visibility_subscriber' => {
                'struct' => 'varchar(20)',
                'doc'    => 'FIXME',
                'order'  => 15,
            },
            'topics_subscriber' => {
                'struct' => 'varchar(200)',
                'doc'    => 'topic subscription specification',
                'order'  => 16,
            },
            'subscribed_subscriber' => {
                'struct' => 'int(1)',
                'doc' =>
                    'boolean set to 1 if subscriber comes from ADD or SUB',
                'order' => 17,
            },
            # Obsoleted as of 6.2.45b. Use inclusion_subscriber.
            #'included_subscriber' => {
            #    'struct' => 'int(1)',
            #    'doc' =>
            #        'boolean, set to 1 is subscriber comes from an external datasource. Note that included_subscriber and subscribed_subscriber can both value 1',
            #    'order' => 18,
            #},
            # Ditto.
            #'include_sources_subscriber' => {
            #    'struct' => 'varchar(50)',
            #    'doc' =>
            #        'comma separated list of datasource that contain this subscriber',
            #    'order' => 19,
            #},
            'custom_attribute_subscriber' => {
                'struct' => 'text',
                'doc'    => 'FIXME',
                'order'  => 20,
            },

        },
        'doc'   => 'This table store subscription, subscription option etc.',
        'order' => 1,
    },
    'user_table' => {
        'fields' => {
            'email_user' => {
                'struct'   => $email_struct,
                'doc'      => 'email of user',
                'primary'  => 1,
                'not_null' => 1,
                'order'    => 1,
            },
            'gecos_user' => {
                'struct' => 'varchar(150)',
                'doc'    => 'display name of user',
                'order'  => 3,
            },
            'password_user' => {
                'struct' => 'varchar(64)',
                'doc'    => 'password are stored as finger print',
                'order'  => 2,
            },
            'last_login_date_user' => {
                'struct' => 'int(11)',
                'doc' =>
                    'Unix time of last login, printed in login result for security purpose',
                'order' => 4,
            },
            'last_login_host_user' => {
                'struct' => 'varchar(60)',
                'doc' =>
                    'host of last login, printed in login result for security purpose',
                'order' => 5,
            },
            'wrong_login_count_user' => {
                'struct' => 'int(11)',
                'doc' =>
                    'login attempt count, used to prevent brute force attack',
                'order' => 6,
            },
            'last_active_date_user' => {
                'struct' => 'int(11)',
                'doc' =>
                    'the last Unix time when this user was confirmed their activity by purge_user_table task',
                'order' => 7,
            },
            'cookie_delay_user' => {
                'struct' => 'int(11)',
                'doc'    => 'FIXME',
                'order'  => 8,
            },
            'lang_user' => {
                'struct' => 'varchar(10)',
                'doc'    => 'user language preference',
                'order'  => 9,
            },
            'attributes_user' => {
                'struct' => 'text',
                'doc'    => 'FIXME',
                'order'  => 10,
            },
            'data_user' => {
                'struct' => 'text',
                'doc'    => 'FIXME',
                'order'  => 11,
            },
        },
        'doc' =>
            'The user_table is mainly used to manage login from web interface. A subscriber may not appear in the user_table if they never log through the web interface.',
        'order' => 2,
    },
    #'bulkspool_table' => {
    #    'fields' => {
    #        'messagekey_bulkspool' => {
    #            'struct'   => 'varchar(33)',
    #            'doc'      => 'primary key',
    #            'primary'  => 1,
    #            'not_null' => 1,
    #            'order'    => 1,
    #        },
    #        'message_bulkspool' => {
    #            'struct' => 'longtext',
    #            'doc'    => 'message as string b64 encoded',
    #            'order'  => 2,
    #        },
    #        #'messageid_bulkspool' => {
    #        #    'struct' => 'varchar(300)',
    #        #    'doc'    => 'stored to list spool content faster',
    #        #    'order'  => 4,
    #        #},
    #        'lock_bulkspool' => {
    #            'struct' => 'int(1)',
    #            'doc' =>
    #                'when set to 1, this field prevents Sympa from processing the message',
    #            'order' => 5,
    #        },
    #        #'dkim_privatekey_bulkspool' => {
    #        #    'struct' => 'varchar(2000)',
    #        #    'doc' =>
    #        #        'DKIM parameter stored for bulk daemon because bulk ignore list parameters, private key to sign message',
    #        #    'order' => 6,
    #        #},
    #        #'dkim_selector_bulkspool' => {
    #        #    'struct' => 'varchar(50)',
    #        #    'doc' =>
    #        #        'DKIM parameter stored for bulk daemon because bulk ignore list parameters, DKIM selector to sign message',
    #        #    'order' => 7,
    #        #},
    #        #'dkim_d_bulkspool' => {
    #        #    'struct' => 'varchar(50)',
    #        #    'doc' =>
    #        #        'DKIM parameter stored for bulk daemon because bulk ignore list parameters, the d DKIM parameter',
    #        #    'order' => 8,
    #        #},
    #        #'dkim_i_bulkspool' => {
    #        #    'struct' => $email_struct,
    #        #    'doc' =>
    #        #        'DKIM parameter stored for bulk daemon because bulk ignore list parameters, DKIM i signature parameter',
    #        #    'order' => 9,
    #        #},
    #    },
    #    'doc'   => 'This table contains the messages to be sent by bulk.pl',
    #    'order' => 3,
    #},
    #'bulkmailer_table' => {
    #    'fields' => {
    #        'messagekey_bulkmailer' => {
    #            'struct' => 'varchar(80)',
    #            'doc' =>
    #                'A pointer to a message in spool_table.It must be a value of a line in table spool_table with same value as messagekey_bulkspool',
    #            'primary'  => 1,
    #            'not_null' => 1,
    #            'order'    => 1,
    #        },
    #        'packetid_bulkmailer' => {
    #            'struct'   => 'varchar(33)',
    #            'doc'      => 'An id for the packet',
    #            'primary'  => 1,
    #            'not_null' => 1,
    #            'order'    => 2,
    #        },
    #        #'messageid_bulkmailer' => {
    #        #    'struct' => 'varchar(200)',
    #        #    'doc'    => 'The message Id',
    #        #    'order'  => 3,
    #        #},
    #        ##FIXME: column name is "recEipients_bulkmailer"
    #        'receipients_bulkmailer' => {
    #            'struct' => 'text',
    #            'doc' =>
    #                'the comma separated list of recipient email for this message',
    #            'order' => 4,
    #        },
    #        #'returnpath_bulkmailer' => {
    #        #    'struct' => $email_struct,
    #        #    'doc' =>
    #        #        'the return path value that must be set when sending the message',
    #        #    'order' => 5,
    #        #},
    #        'robot_bulkmailer' => {
    #            'struct' => $robot_struct,
    #            'doc'    => '',
    #            'order'  => 6,
    #        },
    #        'listname_bulkmailer' => {
    #            'struct' => $list_struct,
    #            'doc'    => '',
    #            'order'  => 7,
    #        },
    #        #'verp_bulkmailer' => {
    #        #    'struct' => 'int(1)',
    #        #    'doc' =>
    #        #        'A boolean to specify if VERP is requiered, in this case return_path will be formatted using VERP form',
    #        #    'order' => 8,
    #        #},
    #        #'tracking_bulkmailer' => {
    #        #    'struct' => "enum('mdn','dsn')",
    #        #    'doc' => 'Is DSN or MDN requiered when sending this message?',
    #        #    'order' => 9,
    #        #},
    #        #'merge_bulkmailer' => {
    #        #    'struct' => 'int(1)',
    #        #    'doc' =>
    #        #        'Boolean, if true, the message is to be parsed as a TT2 template foreach recipient',
    #        #    'order' => 10,
    #        #},
    #        'priority_message_bulkmailer' => {
    #            'struct' => 'smallint(10)',
    #            'doc'    => 'FIXME',
    #            'order'  => 11,
    #        },
    #        'priority_packet_bulkmailer' => {
    #            'struct' => 'smallint(10)',
    #            'doc'    => 'FIXME',
    #            'order'  => 12,
    #        },
    #        'reception_date_bulkmailer' => {
    #            'struct' => 'double',
    #            'doc'    => 'The date where the message was received',
    #            'order'  => 13,
    #        },
    #        'delivery_date_bulkmailer' => {
    #            'struct' => 'int(11)',
    #            'doc'    => 'The date the message was sent',
    #            'order'  => 14,
    #        },
    #        'lock_bulkmailer' => {
    #            'struct' => 'varchar(30)',
    #            'doc' =>
    #                'A lock. It is set as process-number @ hostname so multiple bulkmailer can handle this spool',
    #            'order' => 15,
    #        },
    #        'tag_bulkmailer' => {
    #            'struct' => 'varchar(10)',
    #            'doc'    => 'Additional tag used to sort packets',
    #            'order'  => 16,
    #        },
    #    },
    #    'doc' =>
    #        'storage of recipients with a ref to a message in spool_table. So a very simple process can distribute them',
    #    'order' => 4,
    #},
    'exclusion_table' => {
        'fields' => {
            'list_exclusion' => {
                # "family:" and family name.
                'struct' => sprintf(
                    'varchar(%d)', Sympa::Constants::FAMILY_LEN() + 7
                ),
                'doc'      => 'FIXME',
                'order'    => 1,
                'primary'  => 1,
                'not_null' => 1,
            },
            'robot_exclusion' => {
                'struct'   => $robot_struct,
                'doc'      => 'FIXME',
                'order'    => 2,
                'primary'  => 1,
                'not_null' => 1,
            },
            'user_exclusion' => {
                'struct'   => $email_struct,
                'doc'      => 'FIXME',
                'order'    => 3,
                'primary'  => 1,
                'not_null' => 1,
            },
            'family_exclusion' => {
                'struct'  => $family_struct,
                'doc'     => 'FIXME',
                'primary' => 1,
                'order'   => 4,
            },
            'date_exclusion' => {
                'struct' => 'int(11)',
                'doc'    => 'FIXME',
                'order'  => 5,
            },
        },
        'doc' =>
            'Exclusion table is used in order to manage unsubscription for subscriber included from an external data source.',
        'order' => 5,
    },
    'inclusion_table' => {
        'fields' => {
            'target_inclusion' => {
                'struct'   => $list_id_struct,
                'doc'      => 'list ID of including list',
                'order'    => 1,
                'primary'  => 1,
                'not_null' => 1,
            },
            'role_inclusion' => {
                'struct'   => "enum('member','owner','editor')",
                'doc'      => 'role of included user',
                'order'    => 2,
                'primary'  => 1,
                'not_null' => 1,
            },
            'source_inclusion' => {
                'struct'   => $list_id_struct,
                'doc'      => 'list ID of included list',
                'order'    => 3,
                'primary'  => 1,
                'not_null' => 1,
            },
            'update_epoch_inclusion' => {
                'struct' => 'int(11)',
                'doc'    => 'the date this entry was created or updated',
                'order'  => 4,
            },
        },
        'doc' =>
            'Inclusion table is used in order to manage lists included from / including subscribers of other lists.',
        'order' => 4,
    },
    'session_table' => {
        'fields' => {
            'id_session' => {
                'struct'   => 'varchar(30)',
                'doc'      => 'the identifier of the database record',
                'primary'  => 1,
                'not_null' => 1,
                'order'    => 1,
            },
            'prev_id_session' => {
                'struct' => 'varchar(30)',
                'doc'    => 'previous identifier of the database record',
                'order'  => 2,
            },
            'start_date_session' => {
                'struct'   => 'int(11)',
                'doc'      => 'the date when the session was created',
                'not_null' => 1,
                'order'    => 3,
            },
            'date_session' => {
                'struct' => 'int(11)',
                'doc' =>
                    'Unix time of the last use of this session. It is used in order to expire old sessions',
                'not_null' => 1,
                'order'    => 4,
            },
            'refresh_date_session' => {
                'struct' => 'int(11)',
                'doc' =>
                    'Unix time of the last refresh of this session.  It is used in order to refresh available sessions',
                'order' => 5,
            },
            'remote_addr_session' => {
                'struct' => 'varchar(60)',
                'doc' =>
                    'the IP address of the computer from which the session was created',
                'order' => 6,
            },
            'robot_session' => {
                'struct' => $robot_struct,
                'doc' => 'the virtual host in which the session was created',
                'order' => 7,
            },
            'email_session' => {
                'struct' => $email_struct,
                'doc'    => 'the email associated to this session',
                'order'  => 8,
            },
            'hit_session' => {
                'struct' => 'int(11)',
                'doc' =>
                    'the number of hit performed during this session. Used to detect crawlers',
                'order' => 9,
            },
            'data_session' => {
                'struct' => 'text',
                'doc' =>
                    'parameters attached to this session that don\'t have a dedicated column in the database',
                'order' => 10,
            },
        },
        'doc'   => 'Management of HTTP session.',
        'order' => 6,
    },
    'one_time_ticket_table' => {
        'fields' => {
            'ticket_one_time_ticket' => {
                'struct'  => 'varchar(30)',
                'doc'     => 'FIXME',
                'primary' => 1,
                'order'   => 1,
            },
            'email_one_time_ticket' => {
                'struct' => $email_struct,
                'doc'    => 'FIXME',
                'order'  => 2,
            },
            'robot_one_time_ticket' => {
                'struct' => $robot_struct,
                'doc'    => 'FIXME',
                'order'  => 3,
            },
            'date_one_time_ticket' => {
                'struct' => 'int(11)',
                'doc'    => 'FIXME',
                'order'  => 4,
            },
            'data_one_time_ticket' => {
                'struct' => 'varchar(200)',
                'doc'    => 'FIXME',
                'order'  => 5,
            },
            'remote_addr_one_time_ticket' => {
                'struct' => 'varchar(60)',
                'doc'    => 'FIXME',
                'order'  => 6,
            },
            'status_one_time_ticket' => {
                'struct' => 'varchar(60)',
                'doc'    => 'FIXME',
                'order'  => 7,
            },
        },
        'doc' =>
            'One time ticket are random value used for authentication challenge. A ticket is associated with a context which look like a session.',
        'order' => 7,
    },
    'notification_table' => {
        'fields' => {
            'pk_notification' => {
                'struct'        => 'bigint(20)',
                'doc'           => 'autoincrement key',
                'autoincrement' => 1,
                'primary'       => 1,
                'not_null'      => 1,
                'order'         => 1,
            },
            'message_id_notification' => {
                'struct' => 'varchar(100)',
                'doc' =>
                    'initial message-id. This field is used to search DSN and MDN related to a particular message',
                'order' => 2,
            },
            'recipient_notification' => {
                'struct' => $email_struct,
                'doc' =>
                    'email address of recipient for which a DSN or MDN was received',
                'order' => 3,
            },
            'reception_option_notification' => {
                'struct' => 'varchar(20)',
                'doc' =>
                    'the subscription option of the subscriber when the related message was sent to the list. Useful because some recipient may have option such as //digest// or //nomail//',
                'order' => 4,
            },
            'status_notification' => {
                'struct' => 'varchar(100)',
                'doc'    => 'value of notification',
                'order'  => 5,
            },
            'arrival_date_notification' => {
                'struct' => 'varchar(80)',
                'doc'    => 'reception date of latest DSN or MDN',
                'order'  => 6,
            },
            'arrival_epoch_notification' => {
                'struct' => 'int(11)',
                'doc'    => 'reception date of latest DSN or MDN',
                'order'  => 7,
            },
            'type_notification' => {
                'struct' => "enum('DSN', 'MDN')",
                'doc'    => 'type of the notification (DSN or MDN)',
                'order'  => 8,
            },
            'list_notification' => {
                'struct' => $list_struct,
                'doc'    => 'the listname the message was issued for',
                'order'  => 9,
            },
            'robot_notification' => {
                'struct' => $robot_struct,
                'doc'    => 'the robot the message is related to',
                'order'  => 10,
            },
            'date_notification' => {
                'struct'   => 'int(11)',
                'doc'      => 'FIXME',
                'not_null' => 1,
                'order'    => 11,
            },
        },
        'doc' =>
            'Used for message tracking feature. If the list is configured for tracking, outgoing messages include a delivery status notification request and optionally a message disposition notification request. When DSN and MDN are received by Sympa, they are stored in this table in relation with the related list and message ID.',
        'order' => 8,
    },
    'logs_table' => {
        'fields' => {
            #'id_logs' => {
            #    'struct'   => 'bigint(20)',
            #    'doc'      => 'unique log\'s identifier',
            #    'primary'  => 1,
            #    'not_null' => 1,
            #    'order'    => 1,
            #},
            'user_email_logs' => {
                'struct' => $email_struct,
                'doc' =>
                    'e-mail address of the message sender or email of identified web interface user (or soap user)',
                'order' => 2,
            },
            'date_logs' => {
                'struct'   => 'int(11)',
                'doc'      => 'date when the action was executed',
                'not_null' => 1,
                'order'    => 3,
            },
            'usec_logs' => {
                'struct' => 'int(6)',
                'doc' =>
                    'subsecond in microsecond when the action was executed',
                'order' => 3.5,
            },
            'robot_logs' => {
                'struct' => $robot_struct,
                'doc' =>
                    'name of the robot in which context the action was executed',
                'order' => 4,
            },
            'list_logs' => {
                'struct' => $list_struct,
                'doc' =>
                    'name of the mailing-list in which context the action was executed',
                'order' => 5,
            },
            'action_logs' => {
                'struct' => 'varchar(50)',
                'doc' =>
                    'name of the Sympa subroutine which initiated the log',
                'not_null' => 1,
                'order'    => 6,
            },
            'parameters_logs' => {
                'struct' => 'varchar(100)',
                'doc' =>
                    'comma-separated list of parameters. The amount and type of parameters can differ from an action to another',
                'order' => 7,
            },
            'target_email_logs' => {
                'struct' => $email_struct,
                'doc'    => 'e-mail address (if any) targeted by the message',
                'order'  => 8,
            },
            'msg_id_logs' => {
                'struct' => 'varchar(255)',
                'doc' =>
                    'identifier of the message which triggered the action',
                'order' => 9,
            },
            'status_logs' => {
                'struct' => 'varchar(10)',
                'doc' =>
                    'exit status of the action. If it was an error, it is likely that the error_type_logs field will contain a description of this error',
                'not_null' => 1,
                'order'    => 10,
            },
            'error_type_logs' => {
                'struct' => 'varchar(150)',
                'doc' =>
                    'name of the error string - if any - issued by the subroutine',
                'order' => 11,
            },
            'client_logs' => {
                'struct' => 'varchar(100)',
                'doc' =>
                    'IP address of the client machine from which the message was sent',
                'order' => 12,
            },
            'daemon_logs' => {
                'struct'   => 'varchar(10)',
                'doc'      => 'name of the Sympa daemon which ran the action',
                'not_null' => 1,
                'order'    => 13,
            },
        },
        'doc' =>
            'Each important event is stored in this table. List owners and listmaster can search entries in this table using web interface.',
        'order' => 9,
    },
    'stat_table' => {
        'fields' => {
            #'id_stat' => {
            #    'struct'   => 'bigint(20)',
            #    'doc'      => 'FIXME',
            #    'order'    => 1,
            #    'primary'  => 1,
            #    'not_null' => 1,
            #},
            'date_stat' => {
                'struct'   => 'int(11)',
                'doc'      => 'FIXME',
                'order'    => 2,
                'not_null' => 1,
            },
            'email_stat' => {
                'struct' => $email_struct,
                'doc'    => 'FIXME',
                'order'  => 3,
            },
            'operation_stat' => {
                'struct'   => 'varchar(50)',
                'doc'      => 'FIXME',
                'order'    => 4,
                'not_null' => 1,
            },
            'list_stat' => {
                'struct' => $list_struct,
                'doc'    => 'FIXME',
                'order'  => 5,
            },
            'daemon_stat' => {
                'struct' => 'varchar(20)',
                'doc'    => 'FIXME',
                'order'  => 6,
            },
            'user_ip_stat' => {
                'struct' => 'varchar(100)',
                'doc'    => 'FIXME',
                'order'  => 7,
            },
            'robot_stat' => {
                'struct'   => $robot_struct,
                'doc'      => 'FIXME',
                'order'    => 8,
                'not_null' => 1,
            },
            'parameter_stat' => {
                'struct' => 'varchar(50)',
                'doc'    => 'FIXME',
                'order'  => 9,
            },
            'read_stat' => {
                'struct'   => 'tinyint(1)',
                'doc'      => 'FIXME',
                'order'    => 10,
                'not_null' => 1,
            },
        },
        'doc' =>
            'Statistics item are stored in this table, Sum average and so on are stored in stat_counter_table.',
        'order' => 10,
    },
    'stat_counter_table' => {
        'fields' => {
            #'id_counter' => {
            #    'struct'   => 'bigint(20)',
            #    'doc'      => 'FIXME',
            #    'order'    => 1,
            #    'primary'  => 1,
            #    'not_null' => 1,
            #},
            'beginning_date_counter' => {
                'struct'   => 'int(11)',
                'doc'      => 'FIXME',
                'order'    => 2,
                'not_null' => 1,
            },
            'end_date_counter' => {
                'struct' => 'int(11)',
                'doc'    => 'FIXME',
                'order'  => 1,
            },
            'data_counter' => {
                'struct'   => 'varchar(50)',
                'doc'      => 'FIXME',
                'not_null' => 1,
                'order'    => 3,
            },
            'robot_counter' => {
                'struct'   => $robot_struct,
                'doc'      => 'FIXME',
                'not_null' => 1,
                'order'    => 4,
            },
            'list_counter' => {
                'struct' => $list_struct,
                'doc'    => 'FIXME',
                'order'  => 5,
            },
            #'variation_counter' => {
            #    'struct' => 'int',
            #    'doc'    => 'FIXME',
            #    'order'  => 6,
            #},
            #'total_counter' => {
            #    'struct' => 'int',
            #    'doc'    => 'FIXME',
            #    'order'  => 7,
            #},
            'count_counter' => {
                'struct' => 'int',
                'doc'    => 'FIXME',
                'order'  => 8,
            },
        },
        'doc' => 'Used in conjunction with stat_table for users statistics.',
        'order' => 11,
    },

    'admin_table' => {
        'fields' => {

            'user_admin' => {
                'struct'   => $email_struct,
                'primary'  => 1,
                'not_null' => 1,
                'doc'      => 'list admin email',
                'order'    => 1,
            },
            'list_admin' => {
                'struct'   => $list_struct,
                'primary'  => 1,
                'not_null' => 1,
                'doc'      => 'list name',
                'order'    => 2,
            },
            'robot_admin' => {
                'struct'   => $robot_struct,
                'primary'  => 1,
                'not_null' => 1,
                'doc'      => 'list domain',
                'order'    => 3,
            },
            'role_admin' => {
                'struct'  => "enum('listmaster','owner','editor')",
                'primary' => 1,
                'doc' =>
                    'a role of this user for this list (editor, owner or listmaster which a kind of list owner too)',
                'order' => 4,
            },
            'profile_admin' => {
                'struct' => "enum('privileged','normal')",
                'doc' =>
                    'privilege level for this owner, value //normal// or //privileged//. The related privilege are listed in edit_list.conf. ',
                'order' => 5,
            },
            #'date_admin' => {
            #    'struct'   => 'datetime',
            #    'doc'      => 'date this user become a list admin',
            #    'not_null' => 1,
            #    'order'    => 6,
            #},
            'date_epoch_admin' => {
                'struct'   => 'int(11)',
                'doc'      => 'date this user become a list admin',
                'not_null' => 1,
                'order'    => 6.5,
            },
            # Obsoleted as of 6.2.25b.2. Use update_epoch_admin.
            #'update_admin' => {
            #    'struct' => 'datetime',
            #    'doc'    => 'last update timestamp',
            #    'order'  => 7,
            #},
            'update_epoch_admin' => {
                'struct' => 'int(11)',
                'doc'    => 'last update time',
                'order'  => 7.5,
            },
            'inclusion_admin' => {
                'struct' => 'int(11)',
                'doc' =>
                    'the last time when list user is synchronized with data source',
                'order' => 7.6,
            },
            'inclusion_ext_admin' => {
                'struct' => 'int(11)',
                'doc' =>
                    'the last time when list user is synchronized with external data source',
                'order' => 7.7,
            },
            'inclusion_label_admin' => {
                'struct' => 'varchar(50)',
                'doc'    => 'name of data source',
                'order'  => 7.8,
            },
            'reception_admin' => {
                'struct' => 'varchar(20)',
                'doc' =>
                    'email reception option for list management messages',
                'order' => 8,
            },
            'visibility_admin' => {
                'struct' => 'varchar(20)',
                'doc' =>
                    'admin user email can be hidden in the list web page description',
                'order' => 9,
            },
            'comment_admin' => {
                'struct' => 'varchar(150)',
                'doc'    => 'FIXME',
                'order'  => 10,
            },
            'subscribed_admin' => {
                'struct' => 'int(1)',
                'doc' =>
                    'set to 1 if user is list admin by definition in list config file',
                'order' => 11,
            },
            # Obsoleted as of 6.2.45b. Use inclusion_admin.
            #'included_admin' => {
            #    'struct' => 'int(1)',
            #    'doc' =>
            #        'set to 1 if user is admin by an external data source. Note that included_admin and subscribed_admin can both value 1',
            #    'order' => 12,
            #},
            # Ditto.
            #'include_sources_admin' => {
            #    'struct' => 'varchar(50)',
            #    'doc'    => 'name of external datasource',
            #    'order'  => 13,
            #},
            'info_admin' => {
                'struct' => 'varchar(150)',
                'doc' =>
                    'private information usually dedicated to listmasters who needs some additional information about list owners',
                'order' => 14,
            },

        },
        'doc' =>
            'This table is an internal cash where list admin roles are stored. It is just a cash and it does not need to be saved. You may remove its content if needed. It will just make next Sympa startup slower.',
        'order' => 12,
    },
    'netidmap_table' => {
        'fields' => {
            'netid_netidmap' => {
                'struct'   => 'varchar(100)',
                'doc'      => 'FIXME',
                'primary'  => 1,
                'not_null' => 1,
                'order'    => 1,
            },
            'serviceid_netidmap' => {
                'struct'   => 'varchar(100)',
                'doc'      => 'FIXME',
                'primary'  => 1,
                'not_null' => 1,
                'order'    => 2,
            },
            'email_netidmap' => {
                'struct' => $email_struct,
                'doc'    => 'FIXME',
                'order'  => 4,
            },
            'robot_netidmap' => {
                'struct'   => $robot_struct,
                'doc'      => 'FIXME',
                'primary'  => 1,
                'not_null' => 1,
                'order'    => 3,
            },
        },
        'order' => 13,
        'doc'   => 'FIXME',
    },
    'conf_table' => {
        'fields' => {
            'robot_conf' => {
                'struct'  => $robot_struct,
                'doc'     => 'FIXME',
                'primary' => 1,
                'order'   => 1,
            },
            'label_conf' => {
                'struct'  => 'varchar(80)',
                'doc'     => 'FIXME',
                'primary' => 1,
                'order'   => 2,
            },
            'value_conf' => {
                'struct' => 'varchar(300)',
                'doc' =>
                    'the value of parameter //label_conf// of robot //robot_conf//.',
                'order' => 3,
            },
        },
        'doc'   => 'FIXME',
        'order' => 14,
    },
    'list_table' => {
        'fields' => {
            ## Identification
            'name_list' => => {
                'struct'   => $list_struct,
                'doc'      => 'name of the list',
                'order'    => 1,
                'primary'  => 1,
                'not_null' => 1,
            },
            'robot_list' => {
                'struct'  => $robot_struct,
                'doc'     => 'name of the robot (domain) the list belongs to',
                'order'   => 2,
                'primary' => 1,
                'not_null' => 1,
            },
            ## basic profile
            'family_list' => {
                'struct' => $family_struct,
                'doc'    => 'name of the family the list belongs to',
                'order'  => 3,
            },
            'status_list' => {
                'struct' =>
                    "enum('open','closed','pending','error_config','family_closed')",
                'doc'   => 'status of the list',
                'order' => 4,
            },
            'creation_email_list' => {
                'struct' => $email_struct,
                'doc'    => 'email of user who created the list',
                'order'  => 5,
            },
            'creation_epoch_list' => {
                'struct' => 'int(11)',
                'doc'    => 'UNIX time when the list was created',
                'order'  => 6,
            },
            'update_email_list' => {
                'struct' => $email_struct,
                'doc'    => 'email of user who updated the list',
                'order'  => 7,
            },
            'update_epoch_list' => {
                'struct' => 'int(11)',
                'doc'    => 'UNIX time when the list was updated',
                'order'  => 8,
            },
            ## Other indices to help searching lists
            'searchkey_list' => {
                'struct' => 'varchar(255)',
                'doc'    => 'case-folded list subject to help searching',
                'order'  => 10,
            },
            'web_archive_list' => {
                'struct' => 'tinyint(1)',
                'doc'    => 'if the list has archives',
                'order'  => 11,
            },
            'topics_list' => {
                'struct' => 'varchar(255)',
                'doc' =>
                    'topics of the list, separated and enclosed by commas',
                'order' => 12,
            },
            ## total cache
            'total_list' => {
                'struct' => 'int(7)',
                'doc'    => 'estimated number of subscribers',
                'order'  => 90,
            },
#             ## cache management
#             'cache_epoch_list' => {
#                 'struct' => 'int(11)',
#                 'doc'    => 'UNIX time of cache entry',
#                 'order'  => 98,
#             },
#             ## admin cache
#             'config_list' => {
#                 'struct' => 'mediumblob',
#                 'doc'    => 'Serialized list config',
#                 'order'  => 99,
#             },
        },
        'doc' =>
            'The list_table holds cached list config and some items to help searching lists.',
        'order' => 18,
    },
);

sub full_db_struct {
    return %full_db_struct;
}

# OBSOLETED.  Use Sympa::DatabaseManager::_db_struct().
#sub db_struct;

sub not_null {
    my %not_null;
    my %full_db_struct = full_db_struct();

    foreach my $table (keys %full_db_struct) {
        foreach my $field (keys %{$full_db_struct{$table}{'fields'}}) {
            $not_null{'$field'} =
                $full_db_struct{$table}{'fields'}{$field}{'not_null'};
        }
    }
    return %not_null;
}

sub autoincrement {
    my %autoincrement;
    my %full_db_struct = full_db_struct();

    foreach my $table (keys %full_db_struct) {
        foreach my $field (keys %{$full_db_struct{$table}{'fields'}}) {
            $autoincrement{$table} = $field
                if (
                $full_db_struct{$table}{'fields'}{$field}{'autoincrement'});
        }
    }
    return %autoincrement;
}

sub primary {
    my %primary;
    my %full_db_struct = full_db_struct();

    foreach my $table (keys %full_db_struct) {
        my @primarykey;
        foreach my $field (keys %{$full_db_struct{$table}{'fields'}}) {
            push(@primarykey, $field)
                if ($full_db_struct{$table}{'fields'}{$field}{'primary'});
        }

        $primary{$table} = \@primarykey;
    }
    return %primary;
}

## List the required INDEXES
##   1st key is the concerned table
##   2nd key is the index name
##   the table lists the field on which the index applies
our %indexes = (
    'admin_table'      => {'admin_user_index'      => ['user_admin']},
    'subscriber_table' => {'subscriber_user_index' => ['user_subscriber']},
    'stat_table'       => {'stats_user_index'      => ['email_stat']},
    'session_table'    => {'session_prev_id_index' => ['prev_id_session']},
);

# table indexes that can be removed during upgrade process
our @former_indexes = (
    'user_subscriber',      'list_subscriber',
    'subscriber_idx',       'admin_idx',
    'netidmap_idx',         'user_admin',
    'list_admin',           'role_admin',
    'admin_table_index',    'logs_table_index',
    'netidmap_table_index', 'subscriber_table_index',
    'user_index'
);

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::DatabaseDescription - Definition of core database structure

=head1 DESCRIPTION

This module keeps structure of database used by Sympa software.

=head2 Functions

=over

=item full_db_struct ()

I<Function>.
Returns a heshref containing definitions of all tables.
Each item has the name of table as key and definition as value.

Each definition is hashref containing following keys:

=over

=item fields

See below.

=item doc

Description of the table.

=item order

TBD.

=back

C<fields> item is hashref which may contain following items.

=over

=item struct

Column data types.  Definitions are based on MySQL.
Following types are recognized:

=over

=item varchar(I<length>)

Text with length up to I<length>.  I<length> must be lower than 2^16 - 2.

=item int(1)

Boolean, 1 or 0.

=item int(11)

Unix time.

=item int(I<cols>)

Integer with columns up to I<cols>, with its value from -2^31 to 2^31 - 1.

=item tinyint

Integer, -2^7 to 2^7 - 1.

=item smallint

Integer, -2^15 to 2^15 - 1.

=item bigint

Integer, -2^63 to 2^63 - 1.

=item double

IEEE floating point number, 8 bytes.

=item enum

Keyword with length up to 20 o.

=item text

Text with length up to 2000 o at minimum.
4000 o or longer is recommended.

Note:
On Sympa 6.2.36 or earlier, required size was 500 o.

=item longtext

Text with length up to 2^32 - 4 o.

=item datetime

Timestamp.
B<Deprecated> as of Sympa 6.2.25b.3.
Use C<int(11)> (Unix time) instead.

=item mediumblob

Binary data with length up to 2^24 - 3 o.

=back

=item doc

Description of the field.

=item primary

If this is true, primary key consists of this field.

=item not_null

If this is true, Null value is not allowed.
Note that fields included in primary key always don't allow Null value.

=back

=item db_struct ()

This function was OBSOLETED.

=item not_null ()

I<Function>.
TBD.

=item autoincrement ()

I<Function>.
TBD.

=item primary ()

I<Function>.
TBD.


=back

=head1 SEE ALSO

L<sympa_database(5)>,
L<Sympa::DatabaseManager>.

=head1 HISTORY

L<Sympa::DatabaseDescription> was introduced behind the veil on Sympa 6.1.
It began to be referred overtly as a part of Sympa Database Manager (SDM) on
Sympa 6.2.

=cut
