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

package Sympa::ListDef;

use strict;
use warnings;

use Sympa::Regexps;

## List parameters defaults
our %default = (
    'occurrence' => '0-1',
    'length'     => 25
);

# DEPRECATED. No longer used.
#our @param_order;

# List parameter alias names
# DEPRECATED.  Use 'obsolete' elements.
#our %alias;

our %pinfo = (

    ### Global definition page ###

    'subject' => {
        order        => 10.01,
        'group'      => 'description',
        'gettext_id' => "Subject of the list",
        'gettext_comment' =>
            'This parameter indicates the subject of the list, which is sent in response to the LISTS mail command. The subject is a free form text limited to one line.',
        'format'     => '.+',
        'occurrence' => '1',
        'length'     => 50
    },

    'visibility' => {
        order        => 10.02,
        'group'      => 'description',
        'gettext_id' => "Visibility of the list",
        'gettext_comment' =>
            'This parameter indicates whether the list should feature in the output generated in response to a LISTS command or should be shown in the list overview of the web-interface.',
        'scenario' => 'visibility',
        'synonym'  => {
            'public'  => 'noconceal',
            'private' => 'conceal'
        },
        'default' => {'conf' => 'visibility'},
    },

    'owner' => {
        obsolete => 1,
        'format' => {
            'email' => {
                obsolete => 1,
                format_s => '$email',
            },
            'gecos' => {
                obsolete => 1,
                'format' => '.+',
            },
            'info' => {
                obsolete => 1,
                'format' => '.+',
            },
            'profile' => {
                obsolete => 1,
                'format' => ['privileged', 'normal'],
            },
            'reception' => {
                obsolete => 1,
                'format' => ['mail', 'nomail'],
            },
            'visibility' => {
                obsolete => 1,
                'format' => ['conceal', 'noconceal'],
            }
        },
        'occurrence' => '1-n'
    },

    'owner_include' => {
        order        => 60.02_1,
        'group'      => 'data_source',
        'gettext_id' => 'Owners defined in an external data source',
        'format'     => {
            'source' => {
                'order'      => 1,
                'gettext_id' => 'the data source',
                'datasource' => 1,
                'occurrence' => '1'
            },
            'source_parameters' => {
                'order'      => 2,
                'gettext_id' => 'data source parameters',
                'format'     => '.*',
                'occurrence' => '0-1'
            },
            'reception' => {
                'order'      => 4,
                'gettext_id' => 'reception mode',
                'format'     => ['mail', 'nomail'],
                'occurrence' => '1',
                'default'    => 'mail'
            },
            'visibility' => {
                'order'      => 5,
                'gettext_id' => "visibility",
                'format'     => ['conceal', 'noconceal'],
                'occurrence' => '1',
                'default'    => 'noconceal'
            },
            'profile' => {
                'order'      => 3,
                'gettext_id' => 'profile',
                'format'     => ['privileged', 'normal'],
                'occurrence' => '1',
                'default'    => 'normal'
            }
        },
        'occurrence' => '0-n'
    },

    'editor' => {
        obsolete => 1,
        'format' => {
            'email' => {
                obsolete => 1,
                format_s => '$email',
            },
            'reception' => {
                obsolete => 1,
                'format' => ['mail', 'nomail'],
            },
            'visibility' => {
                obsolete => 1,
                'format' => ['conceal', 'noconceal'],
            },
            'gecos' => {
                obsolete => 1,
                'format' => '.+',
            },
            'info' => {
                obsolete => 1,
                'format' => '.+',
            }
        },
        'occurrence' => '0-n'
    },

    'editor_include' => {
        order        => 60.02_2,
        'group'      => 'data_source',
        'gettext_id' => 'Moderators defined in an external data source',
        'format'     => {
            'source' => {
                'order'      => 1,
                'gettext_id' => 'the data source',
                'datasource' => 1,
                'occurrence' => '1'
            },
            'source_parameters' => {
                'order'      => 2,
                'gettext_id' => 'data source parameters',
                'format'     => '.*',
                'occurrence' => '0-1'
            },
            'reception' => {
                'order'      => 3,
                'gettext_id' => 'reception mode',
                'format'     => ['mail', 'nomail'],
                'occurrence' => '1',
                'default'    => 'mail'
            },
            'visibility' => {
                'order'      => 5,
                'gettext_id' => "visibility",
                'format'     => ['conceal', 'noconceal'],
                'occurrence' => '1',
                'default'    => 'noconceal'
            }
        },
        'occurrence' => '0-n'
    },

    'topics' => {
        order        => 10.07,
        'group'      => 'description',
        'gettext_id' => "Topics for the list",
        'gettext_comment' =>
            "This parameter allows the classification of lists. You may define multiple topics as well as hierarchical ones. WWSympa's list of public lists uses this parameter.",
        'format'     => [],          # Sympa::Robot::topic_keys() called later
        'field_type' => 'listtopic',
        'split_char' => ',',
        'occurrence' => '0-n',
        filters      => ['lc'],
    },

    'host' => {
        order        => 10.08,
        'group'      => 'description',
        'gettext_id' => "Internet domain",
        'gettext_comment' =>
            'Domain name of the list, default is the robot domain name set in the related robot.conf file or in file sympa.conf.',
        format_s   => '$host',
        filters    => ['canonic_domain'],
        'default'  => {'conf' => 'host'},
        'length'   => 20,
        'obsolete' => 1
    },

    'lang' => {
        order        => 10.09,
        'group'      => 'description',
        'gettext_id' => "Language of the list",
        'gettext_comment' =>
            "This parameter defines the language used for the list. It is used to initialize a user's language preference; Sympa command reports are extracted from the associated message catalog.",
        'format' => [],    ## Sympa::get_supported_languages() called later
        'file_format' => '\w+(\-\w+)*',
        'field_type'  => 'lang',
        'occurrence'  => '1',
        filters       => ['canonic_lang'],
        'default'     => {'conf' => 'lang'}
    },

    'family_name' => {
        order        => 10.10,
        'group'      => 'description',
        'gettext_id' => 'Family name',
        format_s     => '$family_name',
        'occurrence' => '0-1',
        'internal'   => 1
    },

    'max_list_members' => {
        order        => 10.11,
        'group'      => 'description',
        'gettext_id' => "Maximum number of list members",
        'gettext_comment' =>
            'limit for the number of subscribers. 0 means no limit.',
        'gettext_unit' => 'list members',
        'format'       => '\d+',
        'length'       => 8,
        'default'      => {'conf' => 'default_max_list_members'}
    },

    'priority' => {
        order        => 10.12,
        'group'      => 'description',
        'gettext_id' => "Priority",
        'gettext_comment' =>
            'The priority with which Sympa will process messages for this list. This level of priority is applied while the message is going through the spool. The z priority will freeze the message in the spool.',
        'format'     => [0 .. 9, 'z'],
        'length'     => 1,
        'occurrence' => '1',
        'default'    => {'conf' => 'default_list_priority'}
    },

    ### Sending page ###

    'send' => {
        order        => 20.01,
        'group'      => 'sending',
        'gettext_id' => "Who can send messages",
        'gettext_comment' =>
            'This parameter specifies who can send messages to the list.',
        'scenario' => 'send',
        'default'  => {'conf' => 'send'},
    },

    'delivery_time' => {
        order        => 20.02,
        'group'      => 'sending',
        'gettext_id' => "Delivery time (hh:mm)",
        'gettext_comment' =>
            'If this parameter is present, non-digest messages will be delivered to subscribers at this time: When this time has been past, delivery is postponed to the same time in next day.',
        'format'     => '[0-2]?\d\:[0-6]\d',
        'occurrence' => '0-1',
        'length'     => 5
    },

    'digest' => {
        order        => 20.03,
        'group'      => 'sending',
        'gettext_id' => "Digest frequency",
        'gettext_comment' =>
            'Definition of digest mode. If this parameter is present, subscribers can select the option of receiving messages in multipart/digest MIME format, or as a plain text digest. Messages are then grouped together, and compiled messages are sent to subscribers according to the frequency selected with this parameter.',
        'file_format' => '\d+(\s*,\s*\d+)*\s+\d+:\d+',
        'format'      => {
            'days' => {
                'order'       => 1,
                'gettext_id'  => "days",
                'format'      => [0 .. 6],
                'file_format' => '1|2|3|4|5|6|7',
                'field_type'  => 'dayofweek',
                'occurrence'  => '1-n'
            },
            'hour' => {
                'order'      => 2,
                'gettext_id' => "hour",
                'format'     => '\d+',
                'occurrence' => '1',
                'length'     => 2
            },
            'minute' => {
                'order'      => 3,
                'gettext_id' => "minute",
                'format'     => '\d+',
                'occurrence' => '1',
                'length'     => 2
            }
        },
    },

    'digest_max_size' => {
        order          => 20.04,
        'group'        => 'sending',
        'gettext_id'   => "Digest maximum number of messages",
        'gettext_unit' => 'messages',
        'format'       => '\d+',
        'default'      => 25,
        'length'       => 2
    },

    'available_user_options' => {
        order        => 20.05,
        'group'      => 'sending',
        'gettext_id' => "Available subscription options",
        'format'     => {
            'reception' => {
                'gettext_id' => "reception mode",
                'gettext_comment' =>
                    'Only these modes will be allowed for the subscribers of this list. If a subscriber has a reception mode not in the list, Sympa uses the mode specified in the default_user_options paragraph.',
                'format' => [
                    'mail',    'notice', 'digest', 'digestplain',
                    'summary', 'nomail', 'txt',    'urlize',
                    'not_me'
                ],
                'synonym'    => {'html' => 'mail'},
                'field_type' => 'reception',
                'occurrence' => '1-n',
                'split_char' => ',',
                'default' =>
                    'mail,notice,digest,digestplain,summary,nomail,txt,urlize,not_me'
            }
        }
    },

    'default_user_options' => {
        order        => 20.06,
        'group'      => 'sending',
        'gettext_id' => "Subscription profile",
        'gettext_comment' =>
            'Default profile for the subscribers of the list.',
        'format' => {
            'reception' => {
                'order'           => 1,
                'gettext_id'      => "reception mode",
                'gettext_comment' => 'Mail reception mode.',
                'format'          => [
                    'mail',    'notice', 'digest', 'digestplain',
                    'summary', 'nomail', 'txt',    'urlize',
                    'not_me'
                ],
                'synonym'    => {'html' => 'mail'},
                'field_type' => 'reception',
                'occurrence' => '1',
                'default'    => 'mail'
            },
            'visibility' => {
                'order'           => 2,
                'gettext_id'      => "visibility",
                'gettext_comment' => 'Visibility of the subscriber.',
                'format'          => ['conceal', 'noconceal'],
                'field_type'      => 'visibility',
                'occurrence'      => '1',
                'default'         => 'noconceal'
            }
        },
    },

    'msg_topic' => {
        order        => 20.07,
        'group'      => 'sending',
        'gettext_id' => "Topics for message categorization",
        'gettext_comment' =>
            "This paragraph defines a topic used to tag a message of a list, named by msg_topic.name (\"other\" is a reserved word), its title is msg_topic.title. The msg_topic.keywords entry is optional and allows automatic tagging. This should be a list of keywords, separated by ','.",
        'format' => {
            'name' => {
                'order'      => 1,
                'gettext_id' => "Message topic name",
                'format'     => '[\-\w]+',
                'occurrence' => '1',
                'length'     => 15,
                validations  => ['reserved_msg_topic_name'],
            },
            'keywords' => {
                'order'      => 2,
                'gettext_id' => "Message topic keywords",
                'format'     => '[^,\n]+(,[^,\n]+)*',
                'occurrence' => '0-1'
            },
            'title' => {
                'order'      => 3,
                'gettext_id' => "Message topic title",
                'format'     => '.+',
                'occurrence' => '1',
                'length'     => 35
            }
        },
        'occurrence' => '0-n'
    },

    'msg_topic_keywords_apply_on' => {
        order   => 20.08,
        'group' => 'sending',
        'gettext_id' =>
            "Defines to which part of messages topic keywords are applied",
        'gettext_comment' =>
            'This parameter indicates which part of the message is used to perform automatic tagging.',
        'format'     => ['subject', 'body', 'subject_and_body'],
        'occurrence' => '0-1',
        'default'    => 'subject'
    },

    'msg_topic_tagging' => {
        order        => 20.09,
        'group'      => 'sending',
        'gettext_id' => "Message tagging",
        'gettext_comment' =>
            'This parameter indicates if the tagging is optional or required for a list.',
        'format'     => ['required_sender', 'required_moderator', 'optional'],
        'occurrence' => '1',
        'default'    => 'optional'
    },

    'reply_to' => {
        'group'      => 'sending',
        'gettext_id' => "Reply address",
        'format'     => '\S+',
        'default'    => 'sender',
        'obsolete'   => 1
    },
    'reply-to' => {'obsolete' => 'reply_to'},
    'replyto'  => {'obsolete' => 'reply_to'},

    'forced_reply_to' => {
        'group'      => 'sending',
        'gettext_id' => "Forced reply address",
        'format'     => '\S+',
        'obsolete'   => 1
    },
    'forced_replyto'  => {'obsolete' => 'forced_reply_to'},
    'forced_reply-to' => {'obsolete' => 'forced_reply_to'},

    'reply_to_header' => {
        order        => 20.10,
        'group'      => 'sending',
        'gettext_id' => "Reply address",
        'gettext_comment' =>
            'This defines what Sympa will place in the Reply-To: SMTP header field of the messages it distributes.',
        'format' => {
            'value' => {
                'order'      => 1,
                'gettext_id' => "value",
                'gettext_comment' =>
                    "This parameter indicates whether the Reply-To: field should indicate the sender of the message (sender), the list itself (list), both list and sender (all) or an arbitrary e-mail address (defined by the other_email parameter).\nNote: it is inadvisable to change this parameter, and particularly inadvisable to set it to list. Experience has shown it to be almost inevitable that users, mistakenly believing that they are replying only to the sender, will send private messages to a list. This can lead, at the very least, to embarrassment, and sometimes to more serious consequences.",
                'format'     => ['sender', 'list', 'all', 'other_email'],
                'default'    => 'sender',
                'occurrence' => '1'
            },
            'other_email' => {
                'order'      => 2,
                'gettext_id' => "other email address",
                'gettext_comment' =>
                    'If value was set to other_email, this parameter defines the e-mail address used.',
                format_s => '$email',
            },
            'apply' => {
                'order'      => 3,
                'gettext_id' => "respect of existing header field",
                'gettext_comment' =>
                    'The default is to respect (preserve) the existing Reply-To: SMTP header field in incoming messages. If set to forced, Reply-To: SMTP header field will be overwritten.',
                'format'  => ['forced', 'respect'],
                'default' => 'respect'
            }
        }
    },

    'anonymous_sender' => {
        order        => 20.11,
        'group'      => 'sending',
        'gettext_id' => "Anonymous sender",
        'gettext_comment' =>
            "To hide the sender's email address before distributing the message. It is replaced by the provided email address.",
        'format' => '.+'
    },

    'custom_header' => {
        order        => 20.12,
        'group'      => 'sending',
        'gettext_id' => "Custom header field",
        'gettext_comment' =>
            'This parameter is optional. The headers specified will be added to the headers of messages distributed via the list. As of release 1.2.2 of Sympa, it is possible to put several custom header lines in the configuration file at the same time.',
        'format'     => '\S+:\s+.*',
        'occurrence' => '0-n',
        'length'     => 30
    },
    'custom-header' => {'obsolete' => 'custom_header'},

    'custom_subject' => {
        order        => 20.13,
        'group'      => 'sending',
        'gettext_id' => "Subject tagging",
        'gettext_comment' =>
            'This parameter is optional. It specifies a string which is added to the subject of distributed messages (intended to help users who do not use automatic tools to sort incoming messages). This string will be surrounded by [] characters.',
        'format' => '.+',
        'length' => 15
    },
    'custom-subject' => {'obsolete' => 'custom_subject'},

    'footer_type' => {
        order        => 20.14,
        'group'      => 'sending',
        'gettext_id' => "Attachment type",
        'gettext_comment' =>
            "List owners may decide to add message headers or footers to messages sent via the list. This parameter defines the way a footer/header is added to a message.\nmime: \nThe default value. Sympa will add the footer/header as a new MIME part.\nappend: \nSympa will not create new MIME parts, but will try to append the header/footer to the body of the message. Predefined message-footers will be ignored. Headers/footers may be appended to text/plain messages only.",
        'format'  => ['mime', 'append'],
        'default' => 'mime'
    },

    'max_size' => {
        order             => 20.15,
        'group'           => 'sending',
        'gettext_id'      => "Maximum message size",
        'gettext_comment' => 'Maximum size of a message in 8-bit bytes.',
        'gettext_unit'    => 'bytes',
        'format'          => '\d+',
        'length'          => 8,
        'default'         => {'conf' => 'max_size'}
    },
    'max-size' => {'obsolete' => 'max_size'},

    'merge_feature' => {
        order        => 20.16,
        'group'      => 'sending',
        'gettext_id' => "Allow message personalization",
        'format'     => ['on', 'off'],
        'occurrence' => '1',
        'default'    => {'conf' => 'merge_feature'}
    },

    'reject_mail_from_automates_feature' => {
        order   => 20.18,
        'group' => 'sending',
        'gettext_id' =>
            "Reject mail from automatic processes (crontab, etc)?",
        'format'     => ['on', 'off'],
        'occurrence' => '1',
        'default'    => {'conf' => 'reject_mail_from_automates_feature'}
    },

    'remove_headers' => {
        order        => 20.19,
        'group'      => 'sending',
        'gettext_id' => 'Incoming SMTP header fields to be removed',
        'format'     => '\S+',
        'default'    => {'conf' => 'remove_headers'},
        'occurrence' => '0-n',
        'split_char' => ','
    },

    'remove_outgoing_headers' => {
        order        => 20.20,
        'group'      => 'sending',
        'gettext_id' => 'Outgoing SMTP header fields to be removed',
        'format'     => '\S+',
        'default'    => {'conf' => 'remove_outgoing_headers'},
        'occurrence' => '0-n',
        'split_char' => ','
    },

    'rfc2369_header_fields' => {
        order        => 20.21,
        'group'      => 'sending',
        'gettext_id' => "RFC 2369 Header fields",
        'format' =>
            ['help', 'subscribe', 'unsubscribe', 'post', 'owner', 'archive'],
        'default'    => {'conf' => 'rfc2369_header_fields'},
        'occurrence' => '0-n',
        'split_char' => ','
    },

    'message_hook' => {
        order        => 20.17,
        'group'      => 'sending',
        'gettext_id' => 'Hook modules for message processing',
        'format'     => {
            'pre_distribute' => {
                'order'      => 1,
                'gettext_id' => 'A hook on the messages before distribution',
                'format'     => '(::|\w)+',
            },
            'post_archive' => {
                'order'      => 2,
                'gettext_id' => 'A hook on the messages just after archiving',
                'format'     => '(::|\w)+',
            },
        },
    },

    ### Privileges page ###

    'info' => {
        order        => 30.01,
        'group'      => 'command',
        'gettext_id' => "Who can view list information",
        'scenario'   => 'info',
        'default'    => {'conf' => 'info'},
    },

    'subscribe' => {
        order        => 30.02,
        'group'      => 'command',
        'gettext_id' => "Who can subscribe to the list",
        'gettext_comment' =>
            'The subscribe parameter defines the rules for subscribing to the list.',
        'scenario' => 'subscribe',
        'default'  => {'conf' => 'subscribe'},
    },
    'subscription' => {'obsolete' => 'subscribe'},

    'add' => {
        order        => 30.03,
        'group'      => 'command',
        'gettext_id' => "Who can add subscribers",
        'gettext_comment' =>
            'Privilege for adding (ADD command) a subscriber to the list',
        'scenario' => 'add',
        'default'  => {'conf' => 'add'},
    },

    'unsubscribe' => {
        order        => 30.04,
        'group'      => 'command',
        'gettext_id' => "Who can unsubscribe",
        'gettext_comment' =>
            'This parameter specifies the unsubscription method for the list. Use open_notify or auth_notify to allow owner notification of each unsubscribe command.',
        'scenario' => 'unsubscribe',
        'default'  => {'conf' => 'unsubscribe'},
    },
    'unsubscription' => {'obsolete' => 'unsubscribe'},

    'del' => {
        order        => 30.05,
        'group'      => 'command',
        'gettext_id' => "Who can delete subscribers",
        'scenario'   => 'del',
        'default'    => {'conf' => 'del'},
    },

    'invite' => {
        order        => 30.06,
        'group'      => 'command',
        'gettext_id' => "Who can invite people",
        'scenario'   => 'invite',
        'default'    => {'conf' => 'invite'},
    },

    'remind' => {
        order        => 30.07,
        'group'      => 'command',
        'gettext_id' => "Who can start a remind process",
        'gettext_comment' =>
            'This parameter specifies who is authorized to use the remind command.',
        'scenario' => 'remind',
        'default'  => {'conf' => 'remind'},
    },

    'review' => {
        order        => 30.08,
        'group'      => 'command',
        'gettext_id' => "Who can review subscribers",
        'gettext_comment' =>
            'This parameter specifies who can access the list of members. Since subscriber addresses can be abused by spammers, it is strongly recommended that you only authorize owners or subscribers to access the subscriber list. ',
        'scenario' => 'review',
        'synonym'  => {'open' => 'public',},
        'default'  => {'conf' => 'review'},
    },

    'owner_domain' => {
        order        => 30.085,
        'group'      => 'command',
        'gettext_id' => "Required domains for list owners",
        'gettext_comment' =>
            'Restrict list ownership to addresses in the specified domains.',
        'format_s'   => '$host( +$host)*',
        'length'     => 72,
        'occurrence' => '0-1',
        'split_char' => ' ',
        'default'    => {'conf' => 'owner_domain'},
    },

    'owner_domain_min' => {
        order        => 30.086,
        'group'      => 'command',
        'gettext_id' => "Minimum owners in required domains",
        'gettext_comment' =>
            'Require list ownership by a minimum number of addresses in the specified domains.',
        'format'     => '\d+',
        'length'     => 2,
        'occurrence' => '0-1',
        'default'    => {'conf' => 'owner_domain_min'},
    },

    'shared_doc' => {
        order        => 30.09,
        'group'      => 'command',
        'gettext_id' => "Shared documents",
        'gettext_comment' =>
            'This paragraph defines read and edit access to the shared document repository.',
        'format' => {
            'd_read' => {
                'order'      => 1,
                'gettext_id' => "Who can view",
                'scenario'   => 'd_read',
                'default'    => {'conf' => 'd_read'},
            },
            'd_edit' => {
                'order'      => 2,
                'gettext_id' => "Who can edit",
                'scenario'   => 'd_edit',
                'default'    => {'conf' => 'd_edit'},
            },
            'quota' => {
                'order'        => 3,
                'gettext_id'   => "quota",
                'gettext_unit' => 'Kbytes',
                'format'       => '\d+',
                'default'      => {'conf' => 'default_shared_quota'},
                'length'       => 8
            }
        }
    },

    ### Archives page ###

    'process_archive' => {
        order        => 40.01,
        'group'      => 'archives',
        'gettext_id' => "Store distributed messages into archive",
        'format'     => ['on', 'off'],
        'occurrence' => '1',
        'default'    => {'conf' => 'process_archive'},
    },
    'web_archive' => {
        'obsolete'   => '1',              # Merged into archive.
        'group'      => 'archives',
        'gettext_id' => "Web archives",
        'format'     => {
            'access' => {
                'order'      => 1,
                'gettext_id' => "access right",
                'scenario'   => 'archive_web_access',
                'default'    => {'conf' => 'archive_web_access'},
                'obsolete' => 1,          # Use archive.web_access
            },
            'quota' => {
                'order'        => 2,
                'gettext_id'   => "quota",
                'gettext_unit' => 'Kbytes',
                'format'       => '\d+',
                'default'      => {'conf' => 'default_archive_quota'},
                'length'       => 8,
                'obsolete' => 1,          # Use archive.quota
            },
            'max_month' => {
                'order'      => 3,
                'gettext_id' => "Maximum number of month archived",
                'format'     => '\d+',
                'length'     => 3,
                'obsolete' => 1,          # Use archive.max_month
            }
        }
    },
    'archive' => {
        order        => 40.02,
        'group'      => 'archives',
        'gettext_id' => "Archives",
        'gettext_comment' =>
            "Privilege for reading mail archives and frequency of archiving.\nDefines who can access the list's web archive.",
        'format' => {
            'period' => {
                'order'      => 1,
                'gettext_id' => "frequency",
                'format'     => ['day', 'week', 'month', 'quarter', 'year'],
                'synonym'    => {'weekly' => 'week'},
                'obsolete' => 1,    # Not yet implemented.
            },
            'access' => {
                'order'      => 2,
                'gettext_id' => "access right",
                'format'  => ['open', 'private', 'public', 'owner', 'closed'],
                'synonym' => {'open' => 'public'},
                'obsolete' => 1,    # Use archive.mail_access
            },
            'web_access' => {
                'order'      => 3,
                'gettext_id' => "access right",
                'scenario'   => 'archive_web_access',
                'default'    => {'conf' => 'archive_web_access'},
            },
            'mail_access' => {
                'order'      => 4,
                'gettext_id' => "access right by mail commands",
                'scenario'   => 'archive_mail_access',
                'synonym'    => {
                    'open' => 'public',    # Compat. with <=6.2b.3.
                },
                'default' => {'conf' => 'archive_mail_access'},
            },
            'quota' => {
                'order'        => 5,
                'gettext_id'   => "quota",
                'gettext_unit' => 'Kbytes',
                'format'       => '\d+',
                'default'      => {'conf' => 'default_archive_quota'},
                'length'       => 8
            },
            'max_month' => {
                'order'        => 6,
                'gettext_id'   => "Maximum number of month archived",
                'gettext_unit' => 'months',
                'format'       => '\d+',
                'length'       => 3
            }
        }
    },

    'archive_crypted_msg' => {
        order        => 40.03,
        'group'      => 'archives',
        'gettext_id' => "Archive encrypted mails as cleartext",
        'format'     => ['original', 'decrypted'],
        'occurrence' => '1',
        'default'    => 'original'
    },

    'web_archive_spam_protection' => {
        order        => 40.04,
        'group'      => 'archives',
        'gettext_id' => "email address protection method",
        'gettext_comment' =>
            'Idem spam_protection is provided but it can be used only for web archives. Access requires a cookie, and users must submit a small form in order to receive a cookie before browsing the archives. This blocks all robot, even google and co.',
        'format'     => ['cookie', 'javascript', 'at', 'gecos', 'none'],
        'occurrence' => '1',
        'default'    => {'conf' => 'web_archive_spam_protection'}
    },

    ### Bounces page ###

    'bounce' => {
        order        => 50.01,
        'group'      => 'bounces',
        'gettext_id' => "Bounces management",
        'format'     => {
            'warn_rate' => {
                'order'      => 1,
                'gettext_id' => "warn rate",
                'gettext_comment' =>
                    'The list owner receives a warning whenever a message is distributed and the number (percentage) of bounces exceeds this value.',
                'gettext_unit' => '%',
                'format'       => '\d+',
                'length'       => 3,
                'default'      => {'conf' => 'bounce_warn_rate'}
            },
            'halt_rate' => {
                'order'      => 2,
                'gettext_id' => "halt rate",
                'gettext_comment' =>
                    'NOT USED YET. If bounce rate reaches the halt_rate, messages for the list will be halted, i.e. they are retained for subsequent moderation.',
                'gettext_unit' => '%',
                'format'       => '\d+',
                'length'       => 3,
                'default'      => {'conf' => 'bounce_halt_rate'},
                'obsolete' => 1,    # Not yet implemented.
            }
        }
    },

    'bouncers_level1' => {
        order             => 50.02,
        'group'           => 'bounces',
        'gettext_id'      => "Management of bouncers, 1st level",
        'gettext_comment' => 'Level 1 is the lower level of bouncing users',
        'format'          => {
            'rate' => {
                'order'      => 1,
                'gettext_id' => "threshold",
                'gettext_comment' =>
                    "Each bouncing user have a score (from 0 to 100).\nThis parameter defines a lower limit for each category of bouncing users.For example, level 1 begins from 45 to level_2_treshold.",
                'gettext_unit' => 'points',
                'format'       => '\d+',
                'length'       => 2,
                'default'      => {'conf' => 'default_bounce_level1_rate'}
            },
            'action' => {
                'order'      => 2,
                'gettext_id' => "action for this population",
                'gettext_comment' =>
                    'This parameter defines which task is automatically applied on level 1 bouncers.',
                'format' => ['remove_bouncers', 'notify_bouncers', 'none'],
                'occurrence' => '1',
                'default'    => 'notify_bouncers'
            },
            'notification' => {
                'order'      => 3,
                'gettext_id' => "notification",
                'gettext_comment' =>
                    'When automatic task is executed on level 1 bouncers, a notification email can be send to listowner or listmaster.',
                'format'     => ['none', 'owner', 'listmaster'],
                'occurrence' => '1',
                'default'    => 'owner'
            }
        }
    },

    'bouncers_level2' => {
        order             => 50.03,
        'group'           => 'bounces',
        'gettext_id'      => "Management of bouncers, 2nd level",
        'gettext_comment' => 'Level 2 is the highest level of bouncing users',
        'format'          => {
            'rate' => {
                'order'      => 1,
                'gettext_id' => "threshold",
                'gettext_comment' =>
                    "Each bouncing user have a score (from 0 to 100).\nThis parameter defines the score range defining each category of bouncing users.For example, level 2 is for users with a score between 80 and 100.",
                'gettext_unit' => 'points',
                'format'       => '\d+',
                'length'       => 2,
                'default'      => {'conf' => 'default_bounce_level2_rate'},
            },
            'action' => {
                'order'      => 2,
                'gettext_id' => "action for this population",
                'gettext_comment' =>
                    'This parameter defines which task is automatically applied on level 2 bouncers.',
                'format' => ['remove_bouncers', 'notify_bouncers', 'none'],
                'occurrence' => '1',
                'default'    => 'remove_bouncers'
            },
            'notification' => {
                'order'      => 3,
                'gettext_id' => "notification",
                'gettext_comment' =>
                    'When automatic task is executed on level 2 bouncers, a notification email can be send to listowner or listmaster.',
                'format'     => ['none', 'owner', 'listmaster'],
                'occurrence' => '1',
                'default'    => 'owner'
            }
        }
    },

    'verp_rate' => {
        order        => 50.04,
        'group'      => 'bounces',
        'gettext_id' => "percentage of list members in VERP mode",
        'format' =>
            ['100%', '50%', '33%', '25%', '20%', '10%', '5%', '2%', '0%'],
        'occurrence' => '1',
        'default'    => {'conf' => 'verp_rate'}
    },

    'tracking' => {
        order        => 50.05,
        'group'      => 'bounces',
        'gettext_id' => "Message tracking feature",
        'format'     => {
            'delivery_status_notification' => {
                'order' => 1,
                'gettext_id' =>
                    "tracking message by delivery status notification",
                'format'     => ['on', 'off'],
                'occurrence' => '1',
                'default' =>
                    {'conf' => 'tracking_delivery_status_notification'}
            },
            'message_disposition_notification' => {
                'order' => 2,
                'gettext_id' =>
                    "tracking message by message disposition notification",
                'format'     => ['on', 'on_demand', 'off'],
                'occurrence' => '1',
                'default' =>
                    {'conf' => 'tracking_message_disposition_notification'}
            },
            'tracking' => {
                'order'      => 3,
                'gettext_id' => "who can view message tracking",
                'scenario'   => 'tracking',
                'default'    => {'conf' => 'tracking'},
            },
            'retention_period' => {
                'order' => 4,
                'gettext_id' =>
                    "Tracking datas are removed after this number of days",
                'gettext_unit' => 'days',
                'format'       => '\d+',
                'default' => {'conf' => 'tracking_default_retention_period'},
                'length'  => 5
            }
        }
    },

    'welcome_return_path' => {
        order        => 50.06,
        'group'      => 'bounces',
        'gettext_id' => "Welcome return-path",
        'gettext_comment' =>
            'If set to unique, the welcome message is sent using a unique return path in order to remove the subscriber immediately in the case of a bounce.',
        'format'  => ['unique', 'owner'],
        'default' => {'conf' => 'welcome_return_path'}
    },

    'remind_return_path' => {
        order        => 50.07,
        'group'      => 'bounces',
        'gettext_id' => "Return-path of the REMIND command",
        'gettext_comment' =>
            'Same as welcome_return_path, but applied to remind messages.',
        'format'  => ['unique', 'owner'],
        'default' => {'conf' => 'remind_return_path'}
    },

    ### Data sources page ###

    'inclusion_notification_feature' => {
        order   => 60.01,
        'group' => 'data_source',
        'gettext_id' =>
            "Notify subscribers when they are included from a data source?",
        'format'     => ['on', 'off'],
        'occurrence' => '1',
        'default'    => 'off',
    },

    'sql_fetch_timeout' => {
        order          => 60.03,
        'group'        => 'data_source',
        'gettext_id'   => "Timeout for fetch of include_sql_query",
        'gettext_unit' => 'seconds',
        'format'       => '\d+',
        'length'       => 6,
        'default'      => {'conf' => 'default_sql_fetch_timeout'},
    },

    'user_data_source' => {
        'group'      => 'data_source',
        'gettext_id' => "User data source",
        'format'     => '\S+',
        'default'    => 'include2',
        'obsolete'   => 1,
    },

    'include_file' => {
        order        => 60.04,
        'group'      => 'data_source',
        'gettext_id' => "File inclusion",
        'gettext_comment' =>
            'Include subscribers from this file.  The file should contain one e-mail address per line (lines beginning with a "#" are ignored).',
        'format'     => '\S+',
        'occurrence' => '0-n',
        'length'     => 20,
    },

    'include_remote_file' => {
        order        => 60.05,
        'group'      => 'data_source',
        'gettext_id' => "Remote file inclusion",
        'format'     => {
            'name' => {
                'order'      => 1,
                'gettext_id' => "short name for this source",
                'format'     => '.+',
                'length'     => 50,
            },
            'url' => {
                'order'      => 2,
                'gettext_id' => "data location URL",
                'format'     => '.+',
                'occurrence' => '1',
                'length'     => 50
            },
            'user' => {
                'order'      => 3,
                'gettext_id' => "remote user",
                'format'     => '.+',
                'occurrence' => '0-1'
            },
            'passwd' => {
                'order'      => 4,
                'gettext_id' => "remote password",
                'format'     => '.+',
                'field_type' => 'password',
                'occurrence' => '0-1',
                'length'     => 10
            },
            'timeout' => {
                'order'        => 5,
                'gettext_id'   => "idle timeout",
                'gettext_unit' => 'seconds',
                'format'       => '\d+',
                'length'       => 6,
                'default'      => 180,
            },
            'ssl_version' => {
                'order'      => 6,
                'gettext_id' => 'SSL version',
                'format'     => [
                    'ssl_any', 'sslv2',   'sslv3', 'tlsv1',
                    'tlsv1_1', 'tlsv1_2', 'tlsv1_3'
                ],
                'synonym'    => {'tls' => 'tlsv1'},
                'occurrence' => '0-1',
                'default'    => 'ssl_any',
            },
            'ssl_ciphers' => {
                'order'      => 7,
                'gettext_id' => 'SSL ciphers used',
                'format'     => '.+',
                'default'    => 'ALL'
            },
            # ssl_cert # Use cert.pem in list directory
            # ssl_key  # Use private_key in list directory

            # NOTE: The default of ca_verify is "none" that is different from
            #   include_ldap_query (required) or include_remote_sympa_list
            #   (optional).
            'ca_verify' => {
                'order'      => 8,
                'gettext_id' => 'Certificate verification',
                'format'     => ['none', 'optional', 'required'],
                'synonym'    => {'require' => 'required'},
                'occurrence' => '0-1',
                'default'    => 'none',
            },
            # ca_path # Not yet implemented
            # ca_file # Not yet implemented

            'nosync_time_ranges' => {
                'order'      => 10,
                'gettext_id' => "Time ranges when inclusion is not allowed",
                format_s     => '$time_ranges',
                'occurrence' => '0-1'
            },
        },
        'occurrence' => '0-n'
    },

    'include_list' => {
        'group'      => 'data_source',
        'gettext_id' => "List inclusion",
        format_s     => '$listname(\@$host)?(\s+filter\s+.+)?',
        'occurrence' => '0-n',
        'obsolete' => 1,    # 2.2.6 - 6.2.15.
    },

    'include_sympa_list' => {
        order        => 60.06,
        'group'      => 'data_source',
        'gettext_id' => "List inclusion",
        'gettext_comment' =>
            'Include subscribers from other list. All subscribers of list listname become subscribers of the current list. You may include as many lists as required, using one include_sympa_list paragraph for each included list. Any list at all may be included; you may therefore include lists which are also defined by the inclusion of other lists. Be careful, however, not to include list A in list B and then list B in list A, since this will give rise to an infinite loop.',
        'format' => {
            'name' => {
                'order'      => 1,
                'gettext_id' => "short name for this source",
                'format'     => '.+',
                'length'     => 50,
            },
            'listname' => {
                'order'      => 2,
                'gettext_id' => "list name to include",
                format_s     => '$listname(\@$host)?',
                'occurrence' => '1'
            },
            'filter' => {
                'order'      => 3,
                'gettext_id' => "filter definition",
                'format'     => '.*'
            },
            'nosync_time_ranges' => {
                'order'      => 4,
                'gettext_id' => "Time ranges when inclusion is not allowed",
                format_s     => '$time_ranges',
                'occurrence' => '0-1'
            },
        },
        'occurrence' => '0-n'
    },

    'include_remote_sympa_list' => {
        order        => 60.07,
        'group'      => 'data_source',
        'gettext_id' => "remote list inclusion",
        'gettext_comment' =>
            "Sympa can contact another Sympa service using HTTPS to fetch a remote list in order to include each member of a remote list as subscriber. You may include as many lists as required, using one include_remote_sympa_list paragraph for each included list. Be careful, however, not to give rise to an infinite loop resulting from cross includes.\nFor this operation, one Sympa site acts as a server while the other one acs as client. On the server side, the only setting needed is to give permission to the remote Sympa to review the list. This is controlled by the review scenario.",
        'format' => {
            'name' => {
                'order'      => 1,
                'gettext_id' => "short name for this source",
                'format'     => '.+',
                'length'     => 50,
            },
            'url' => {
                'order'      => 2,
                'gettext_id' => "data location URL",
                'format'     => '.+',
                'occurrence' => '0-1',    # Backward compat. <= 6.2.44
                'length'     => 50
            },
            'user' => {
                'order'      => 3,
                'gettext_id' => "remote user",
                'format'     => '.+',
                'occurrence' => '0-1'
            },
            'passwd' => {
                'order'      => 4,
                'gettext_id' => "remote password",
                'format'     => '.+',
                'field_type' => 'password',
                'occurrence' => '0-1',
                'length'     => 10,
            },
            'host' => {
                'order'           => 4.5,
                'gettext_id'      => "remote host",
                'gettext_comment' => 'obsoleted.  Use "data location URL".',
                format_s          => '$host',
                'occurrence'      => '1'
            },
            'port' => {
                'order'           => 4.6,
                'gettext_id'      => "remote port",
                'gettext_comment' => 'obsoleted.  Use "data location URL".',
                'format'          => '\d+',
                'default'         => 443,
                'length'          => 4
            },
            'path' => {
                'order'           => 4.7,
                'gettext_id'      => "remote path of sympa list dump",
                'gettext_comment' => 'obsoleted.  Use "data location URL".',
                'format'          => '\S+',
                'occurrence'      => '1',
                'length'          => 20
            },
            'cert' => {
                'order' => 4.8,
                'gettext_id' =>
                    "certificate for authentication by remote Sympa",
                'format'   => ['robot', 'list'],
                'default'  => 'list',
                'obsolete' => 1,
            },
            'timeout' => {
                'order'        => 5,
                'gettext_id'   => "idle timeout",
                'gettext_unit' => 'seconds',
                'format'       => '\d+',
                'length'       => 6,
                'default'      => 180,
            },
            'ssl_version' => {
                'order'      => 6,
                'gettext_id' => 'SSL version',
                'format'     => [
                    'ssl_any', 'sslv2',   'sslv3', 'tlsv1',
                    'tlsv1_1', 'tlsv1_2', 'tlsv1_3'
                ],
                'synonym'    => {'tls' => 'tlsv1'},
                'occurrence' => '0-1',
                'default'    => 'ssl_any',
            },
            'ssl_ciphers' => {
                'order'      => 7,
                'gettext_id' => 'SSL ciphers used',
                'format'     => '.+',
                'default'    => 'ALL'
            },
            # ssl_cert # Use cert.pem in list directory
            # ssl_key  # Use private_key in list directory

            # NOTE: The default of ca_verify is "none" that is different from
            #   include_ldap_query (required) or include_remote_file (none).
            'ca_verify' => {
                'order'      => 8,
                'gettext_id' => 'Certificate verification',
                'format'     => ['none', 'optional', 'required'],
                'synonym'    => {'require' => 'required'},
                'occurrence' => '0-1',
                'default'    => 'optional',
            },
            # ca_path # Not yet implemented
            # ca_file # Not yet implemented

            'nosync_time_ranges' => {
                'order'      => 10,
                'gettext_id' => "Time ranges when inclusion is not allowed",
                format_s     => '$time_ranges',
                'occurrence' => '0-1'
            },
        },
        'occurrence' => '0-n'
    },

    'member_include' => {
        order        => 60.02,
        'group'      => 'data_source',
        'gettext_id' => 'Subscribers defined in an external data source',
        'format'     => {
            'source' => {
                'order'      => 1,
                'gettext_id' => 'the data source',
                'datasource' => 1,
                'occurrence' => '1'
            },
            'source_parameters' => {
                'order'      => 2,
                'gettext_id' => 'data source parameters',
                'format'     => '.*',
                'occurrence' => '0-1'
            },
        },
        'occurrence' => '0-n'
    },

    'include_ldap_query' => {
        order        => 60.08,
        'group'      => 'data_source',
        'gettext_id' => "LDAP query inclusion",
        'gettext_comment' =>
            'This paragraph defines parameters for a query returning a list of subscribers. This feature requires the Net::LDAP (perlldap) PERL module.',
        'format' => {
            'name' => {
                'order'      => 1,
                'gettext_id' => "short name for this source",
                'format'     => '.+',
                'length'     => 50,
            },
            'host' => {
                'order'      => 2,
                'gettext_id' => "remote host",
                format_s     => '$multiple_host_or_url',
                'occurrence' => '1'
            },
            'port' => {
                'order'      => 2,
                'gettext_id' => "remote port",
                'format'     => '\d+',
                'obsolete'   => 1,
                'length'     => 4
            },
            'use_tls' => {
                'order'      => 2.4,
                'gettext_id' => 'use TLS (formerly SSL)',
                'format'     => ['starttls', 'ldaps', 'none'],
                'synonym'    => {'yes' => 'ldaps', 'no' => 'none'},
                'occurrence' => '1',
                'default'    => 'none',
            },
            'use_ssl' => {
                #'order'      => 2.5,
                #'gettext_id' => 'use SSL (LDAPS)',
                #'format'     => ['yes', 'no'],
                #'default'    => 'no'
                'obsolete' => 'use_tls',    # 5.3a.2 - 6.2.14
            },
            'ssl_version' => {
                'order'      => 2.6,
                'gettext_id' => 'SSL version',
                'format'     => [
                    'sslv2',   'sslv3', 'tlsv1', 'tlsv1_1',
                    'tlsv1_2', 'tlsv1_3'
                ],
                'synonym'    => {'tls' => 'tlsv1'},
                'occurrence' => '1',
                'default'    => 'tlsv1'
            },
            'ssl_ciphers' => {
                'order'      => 2.7,
                'gettext_id' => 'SSL ciphers used',
                'format'     => '.+',
                'default'    => 'ALL',
            },
            # ssl_cert # Not yet implemented
            # ssl_key # Not yet implemented
            'ca_verify' => {
                'order'      => 2.8,
                'gettext_id' => 'Certificate verification',
                'format'     => ['none', 'optional', 'required'],
                'synonym'    => {'require' => 'required'},
                'occurrence' => '1',
                'default'    => 'required',
            },
            # ca_path # Not yet implemented
            # ca_file # Not yet implemented
            'bind_dn' => {
                'order'      => 3,
                'gettext_id' => "remote user",
                'format'     => '.+'
            },
            'user'          => {obsolete => 'bind_dn'},
            'bind_password' => {
                'order'      => 3.5,
                'gettext_id' => "remote password",
                'format'     => '.+',
                'field_type' => 'password',
                'length'     => 10
            },
            'passwd' => {obsolete => 'bind_password'},
            'suffix' => {
                'order'      => 4,
                'gettext_id' => "suffix",
                'format'     => '.+'
            },
            'scope' => {
                'order'      => 5,
                'gettext_id' => "search scope",
                'format'     => ['base', 'one', 'sub'],
                'occurrence' => '1',
                'default'    => 'sub'
            },
            'timeout' => {
                'order'        => 6,
                'gettext_id'   => "connection timeout",
                'gettext_unit' => 'seconds',
                'format'       => '\w+',
                'length'       => 6,
                'default'      => 30
            },
            'filter' => {
                'order'      => 7,
                'gettext_id' => "filter",
                'format'     => '.+',
                'occurrence' => '1',
                'length'     => 50
            },
            'attrs' => {
                'order'      => 8,
                'gettext_id' => "extracted attribute",
                format_s     => '$ldap_attrdesc(\s*,\s*$ldap_attrdesc)?',
                'default'    => 'mail',
                'length'     => 50
            },
            'select' => {
                'order'      => 9,
                'gettext_id' => "selection (if multiple)",
                'format'     => ['all', 'first', 'regex'],
                'occurrence' => '1',
                'default'    => 'first'
            },
            'regex' => {
                'order'      => 10,
                'gettext_id' => "regular expression",
                'format'     => '.+',
                'default'    => '',
                'length'     => 50
            },
            'nosync_time_ranges' => {
                'order'      => 11,
                'gettext_id' => "Time ranges when inclusion is not allowed",
                format_s     => '$time_ranges',
                'occurrence' => '0-1'
            }
        },
        'occurrence' => '0-n'
    },

    'include_ldap_2level_query' => {
        order        => 60.09,
        'group'      => 'data_source',
        'gettext_id' => "LDAP 2-level query inclusion",
        'gettext_comment' =>
            'This paragraph defines parameters for a two-level query returning a list of subscribers. Usually the first-level query returns a list of DNs and the second-level queries convert the DNs into e-mail addresses. This feature requires the Net::LDAP (perlldap) PERL module.',
        'format' => {
            'name' => {
                'order'      => 1,
                'gettext_id' => "short name for this source",
                'format'     => '.+',
                'length'     => 50,
            },
            'host' => {
                'order'      => 2,
                'gettext_id' => "remote host",
                format_s     => '$multiple_host_or_url',
                'occurrence' => '1'
            },
            'port' => {
                'order'      => 2,
                'gettext_id' => "remote port",
                'format'     => '\d+',
                'obsolete'   => 1,
                'length'     => 4
            },
            'use_tls' => {
                'order'      => 2.4,
                'gettext_id' => 'use TLS (formerly SSL)',
                'format'     => ['starttls', 'ldaps', 'none'],
                'synonym'    => {'yes' => 'ldaps', 'no' => 'none'},
                'occurrence' => '1',
                'default'    => 'none',
            },
            'use_ssl' => {
                #'order'      => 2.5,
                #'gettext_id' => 'use SSL (LDAPS)',
                #'format'     => ['yes', 'no'],
                #'default'    => 'no'
                'obsolete' => 'use_tls',    # 5.3a.2 - 6.2.14
            },
            'ssl_version' => {
                'order'      => 2.6,
                'gettext_id' => 'SSL version',
                'format'     => [
                    'sslv2',   'sslv3', 'tlsv1', 'tlsv1_1',
                    'tlsv1_2', 'tlsv1_3'
                ],
                'synonym'    => {'tls' => 'tlsv1'},
                'occurrence' => '1',
                'default'    => 'tlsv1'
            },
            'ssl_ciphers' => {
                'order'      => 2.7,
                'gettext_id' => 'SSL ciphers used',
                'format'     => '.+',
                'default'    => 'ALL'
            },
            # ssl_cert # Not yet implemented
            # ssl_key # Not yet implemented
            'ca_verify' => {
                'order'      => 2.8,
                'gettext_id' => 'Certificate verification',
                'format'     => ['none', 'optional', 'required'],
                'synonym'    => {'require' => 'required'},
                'occurrence' => '1',
                'default'    => 'required',
            },
            # ca_path # Not yet implemented
            # ca_file # Not yet implemented
            'bind_dn' => {
                'order'      => 3,
                'gettext_id' => "remote user",
                'format'     => '.+'
            },
            'user'          => {obsolete => 'bind_dn'},
            'bind_password' => {
                'order'      => 3.5,
                'gettext_id' => "remote password",
                'format'     => '.+',
                'field_type' => 'password',
                'length'     => 10
            },
            'passwd'  => {obsolete => 'bind_password'},
            'suffix1' => {
                'order'      => 4,
                'gettext_id' => "first-level suffix",
                'format'     => '.+'
            },
            'scope1' => {
                'order'      => 5,
                'gettext_id' => "first-level search scope",
                'format'     => ['base', 'one', 'sub'],
                'default'    => 'sub'
            },
            'timeout1' => {
                'order'        => 6,
                'gettext_id'   => "first-level connection timeout",
                'gettext_unit' => 'seconds',
                'format'       => '\w+',
                'length'       => 6,
                'default'      => 30
            },
            'filter1' => {
                'order'      => 7,
                'gettext_id' => "first-level filter",
                'format'     => '.+',
                'occurrence' => '1',
                'length'     => 50
            },
            'attrs1' => {
                'order'      => 8,
                'gettext_id' => "first-level extracted attribute",
                format_s     => '$ldap_attrdesc',
                'length'     => 15
            },
            'select1' => {
                'order'      => 9,
                'gettext_id' => "first-level selection",
                'format'     => ['all', 'first', 'regex'],
                'occurrence' => '1',
                'default'    => 'first'
            },
            'regex1' => {
                'order'      => 10,
                'gettext_id' => "first-level regular expression",
                'format'     => '.+',
                'default'    => '',
                'length'     => 50
            },
            'suffix2' => {
                'order'      => 11,
                'gettext_id' => "second-level suffix template",
                'format'     => '.+'
            },
            'scope2' => {
                'order'      => 12,
                'gettext_id' => "second-level search scope",
                'format'     => ['base', 'one', 'sub'],
                'occurrence' => '1',
                'default'    => 'sub'
            },
            'timeout2' => {
                'order'        => 13,
                'gettext_id'   => "second-level connection timeout",
                'gettext_unit' => 'seconds',
                'format'       => '\w+',
                'length'       => 6,
                'default'      => 30
            },
            'filter2' => {
                'order'      => 14,
                'gettext_id' => "second-level filter template",
                'format'     => '.+',
                'occurrence' => '1',
                'length'     => 50
            },
            'attrs2' => {
                'order'      => 15,
                'gettext_id' => "second-level extracted attribute",
                format_s     => '$ldap_attrdesc(\s*,\s*$ldap_attrdesc)?',
                'default'    => 'mail',
                'length'     => 50
            },
            'select2' => {
                'order'      => 16,
                'gettext_id' => "second-level selection",
                'format'     => ['all', 'first', 'regex'],
                'occurrence' => '1',
                'default'    => 'first'
            },
            'regex2' => {
                'order'      => 17,
                'gettext_id' => "second-level regular expression",
                'format'     => '.+',
                'default'    => '',
                'length'     => 50
            },
            'nosync_time_ranges' => {
                'order'      => 18,
                'gettext_id' => "Time ranges when inclusion is not allowed",
                format_s     => '$time_ranges',
                'occurrence' => '0-1'
            }
        },
        'occurrence' => '0-n'
    },

    'include_sql_query' => {
        order        => 60.10,
        'group'      => 'data_source',
        'gettext_id' => "SQL query inclusion",
        'gettext_comment' =>
            'This parameter is used to define the SQL query parameters. ',
        'format' => {
            'name' => {
                'order'      => 1,
                'gettext_id' => "short name for this source",
                'format'     => '.+',
                'length'     => 50,
            },
            'db_type' => {
                'order'      => 1.5,
                'gettext_id' => "database type",
                'format'     => '\S+',
                'occurrence' => '1'
            },
            'db_host' => {
                'order'      => 2,
                'gettext_id' => "remote host",
                format_s     => '$host',
                # Not required for ODBC and SQLite. Optional for Oracle.
                # 'occurrence' => '1'
            },
            'host'    => {obsolete => 'db_host'},
            'db_port' => {
                'order'      => 3,
                'gettext_id' => "database port",
                'format'     => '\d+'
            },
            'db_name' => {
                'order'      => 4,
                'gettext_id' => "database name",
                'format'     => '\S+',
                'occurrence' => '1'
            },
            'db_options' => {
                'order'      => 4,
                'gettext_id' => "connection options",
                'format'     => '.+'
            },
            'connect_options' => {obsolete => 'db_options'},
            'db_env'          => {
                'order' => 5,
                'gettext_id' =>
                    "environment variables for database connection",
                'format' => '\w+\=\S+(;\w+\=\S+)*'
            },
            'db_user' => {
                'order'      => 6,
                'gettext_id' => "remote user",
                'format'     => '\S+',
            },
            'user'      => {obsolete => 'db_user'},
            'db_passwd' => {
                'order'      => 7,
                'gettext_id' => "remote password",
                'format'     => '.+',
                'field_type' => 'password'
            },
            'passwd'    => {obsolete => 'db_passwd'},
            'sql_query' => {
                'order'      => 8,
                'gettext_id' => "SQL query",
                format_s     => '$sql_query',
                'occurrence' => '1',
                'length'     => 50
            },
            'f_dir' => {
                'order' => 9,
                'gettext_id' =>
                    "Directory where the database is stored (used for DBD::CSV only)",
                'format' => '.+',
                obsolete => 'db_name',
                not_after => '6.2.70',
            },
            'nosync_time_ranges' => {
                'order'      => 10,
                'gettext_id' => "Time ranges when inclusion is not allowed",
                format_s     => '$time_ranges',
                'occurrence' => '0-1'
            }
        },
        'occurrence' => '0-n'
    },

    'ttl' => {
        order        => 60.12,
        'group'      => 'data_source',
        'gettext_id' => "Inclusions timeout",
        'gettext_comment' =>
            'Sympa caches user data extracted using the include parameter. Their TTL (time-to-live) within Sympa can be controlled using this parameter. The default value is 3600',
        'gettext_unit' => 'seconds',
        'format'       => '\d+',
        'default'      => {'conf' => 'default_ttl'},
        'length'       => 6
    },

    'distribution_ttl' => {
        order        => 60.13,
        'group'      => 'data_source',
        'gettext_id' => "Inclusions timeout for message distribution",
        'gettext_comment' =>
            "This parameter defines the delay since the last synchronization after which the user's list will be updated before performing either of following actions:\n* Reviewing list members\n* Message distribution",
        'gettext_unit' => 'seconds',
        'format'       => '\d+',
        'length'       => 6
    },

    'include_ldap_ca' => {
        order        => 60.14,
        'group'      => 'data_source',
        'gettext_id' => "LDAP query custom attribute",
        'format'     => {
            'name' => {
                'order'      => 1,
                'gettext_id' => "short name for this source",
                'format'     => '.+',
                'length'     => 50,
            },
            'host' => {
                'order'      => 2,
                'gettext_id' => "remote host",
                format_s     => '$multiple_host_or_url',
                'occurrence' => '1'
            },
            'port' => {
                'order'      => 2,
                'gettext_id' => "remote port",
                'format'     => '\d+',
                'obsolete'   => 1,
                'length'     => 4
            },
            'use_tls' => {
                'order'      => 2.4,
                'gettext_id' => 'use TLS (formerly SSL)',
                'format'     => ['starttls', 'ldaps', 'none'],
                'synonym'    => {'yes' => 'ldaps', 'no' => 'none'},
                'occurrence' => '1',
                'default'    => 'none',
            },
            'use_ssl' => {
                #'order'      => 2.5,
                #'gettext_id' => 'use SSL (LDAPS)',
                #'format'     => ['yes', 'no'],
                #'default'    => 'no'
                'obsolete' => 'use_tls',    # 6.2a? - 6.2.14
            },
            'ssl_version' => {
                'order'      => 2.6,
                'gettext_id' => 'SSL version',
                'format'     => [
                    'sslv2',   'sslv3', 'tlsv1', 'tlsv1_1',
                    'tlsv1_2', 'tlsv1_3'
                ],
                'synonym'    => {'tls' => 'tlsv1'},
                'occurrence' => '1',
                'default'    => 'tlsv1'
            },
            'ssl_ciphers' => {
                'order'      => 2.7,
                'gettext_id' => 'SSL ciphers used',
                'format'     => '.+',
                'default'    => 'ALL'
            },
            # ssl_cert # Not yet implemented
            # ssl_key # Not yet implemented
            'ca_verify' => {
                'order'      => 2.8,
                'gettext_id' => 'Certificate verification',
                'format'     => ['none', 'optional', 'required'],
                'synonym'    => {'require' => 'required'},
                'occurrence' => '1',
                'default'    => 'required',
            },
            # ca_path # Not yet implemented
            # ca_file # Not yet implemented
            'bind_dn' => {
                'order'      => 3,
                'gettext_id' => "remote user",
                'format'     => '.+'
            },
            'user'          => {obsolete => 'bind_dn'},
            'bind_password' => {
                'order'      => 3.5,
                'gettext_id' => "remote password",
                'format'     => '.+',
                'field_type' => 'password',
                'length'     => 10
            },
            'passwd' => {obsolete => 'bind_password'},
            'suffix' => {
                'order'      => 4,
                'gettext_id' => "suffix",
                'format'     => '.+'
            },
            'scope' => {
                'order'      => 5,
                'gettext_id' => "search scope",
                'format'     => ['base', 'one', 'sub'],
                'occurrence' => '1',
                'default'    => 'sub'
            },
            'timeout' => {
                'order'        => 6,
                'gettext_id'   => "connection timeout",
                'gettext_unit' => 'seconds',
                'format'       => '\w+',
                'length'       => 6,
                'default'      => 30
            },
            'filter' => {
                'order'      => 7,
                'gettext_id' => "filter",
                'format'     => '.+',
                'occurrence' => '1',
                'length'     => 50
            },
            'attrs' => {
                'order'      => 8,
                'gettext_id' => "extracted attribute",
                format_s     => '$ldap_attrdesc(\s*,\s*$ldap_attrdesc)?',
                'default'    => 'mail',
                'length'     => 15
            },
            'email_entry' => {
                'order'      => 9,
                'gettext_id' => "Name of email entry",
                'format'     => '\S+',
                'occurrence' => '1'
            },
            'select' => {
                'order'      => 10,
                'gettext_id' => "selection (if multiple)",
                'format'     => ['all', 'first', 'regex'],
                'occurrence' => '1',
                'default'    => 'first'
            },
            'regex' => {
                'order'      => 11,
                'gettext_id' => "regular expression",
                'format'     => '.+',
                'default'    => '',
                'length'     => 50
            },
            'nosync_time_ranges' => {
                'order'      => 12,
                'gettext_id' => "Time ranges when inclusion is not allowed",
                format_s     => '$time_ranges',
                'occurrence' => '0-1'
            }
        },
        'occurrence' => '0-n'
    },

    'include_ldap_2level_ca' => {
        order        => 60.15,
        'group'      => 'data_source',
        'gettext_id' => "LDAP 2-level query custom attribute",
        'format'     => {
            'name' => {
                'format'     => '.+',
                'gettext_id' => "short name for this source",
                'length'     => 50,
                'order'      => 1,
            },
            'host' => {
                'order'      => 1,
                'gettext_id' => "remote host",
                format_s     => '$multiple_host_or_url',
                'occurrence' => '1'
            },
            'port' => {
                'order'      => 2,
                'gettext_id' => "remote port",
                'format'     => '\d+',
                'obsolete'   => 1,
                'length'     => 4
            },
            'use_tls' => {
                'order'      => 2.4,
                'gettext_id' => 'use TLS (formerly SSL)',
                'format'     => ['starttls', 'ldaps', 'none'],
                'synonym'    => {'yes' => 'ldaps', 'no' => 'none'},
                'occurrence' => '1',
                'default'    => 'none',
            },
            'use_ssl' => {
                #'order'      => 2.5,
                #'gettext_id' => 'use SSL (LDAPS)',
                #'format'     => ['yes', 'no'],
                #'default'    => 'no'
                'obsolete' => 'use_tls',    # 6.2a? - 6.2.14
            },
            'ssl_version' => {
                'order'      => 2.6,
                'gettext_id' => 'SSL version',
                'format'     => [
                    'sslv2',   'sslv3', 'tlsv1', 'tlsv1_1',
                    'tlsv1_2', 'tlsv1_3'
                ],
                'synonym'    => {'tls' => 'tlsv1'},
                'occurrence' => '1',
                'default'    => 'tlsv1'
            },
            'ssl_ciphers' => {
                'order'      => 2.7,
                'gettext_id' => 'SSL ciphers used',
                'format'     => '.+',
                'default'    => 'ALL'
            },
            # ssl_cert # Not yet implemented
            # ssl_key # Not yet implemented
            'ca_verify' => {
                'order'      => 2.8,
                'gettext_id' => 'Certificate verification',
                'format'     => ['none', 'optional', 'required'],
                'synonym'    => {'require' => 'required'},
                'occurrence' => '1',
                'default'    => 'required',
            },
            # ca_path # Not yet implemented
            # ca_file # Not yet implemented
            'bind_dn' => {
                'order'      => 3,
                'gettext_id' => "remote user",
                'format'     => '.+',
            },
            'user'          => {obsolete => 'bind_dn'},
            'bind_password' => {
                'order'      => 3.5,
                'gettext_id' => "remote password",
                'format'     => '.+',
                'field_type' => 'password',
                'length'     => 10
            },
            'passwd'  => {obsolete => 'bind_password'},
            'suffix1' => {
                'order'      => 4,
                'gettext_id' => "first-level suffix",
                'format'     => '.+'
            },
            'scope1' => {
                'order'      => 5,
                'gettext_id' => "first-level search scope",
                'format'     => ['base', 'one', 'sub'],
                'occurrence' => '1',
                'default'    => 'sub'
            },
            'timeout1' => {
                'order'        => 6,
                'gettext_id'   => "first-level connection timeout",
                'gettext_unit' => 'seconds',
                'format'       => '\w+',
                'length'       => 6,
                'default'      => 30
            },
            'filter1' => {
                'order'      => 7,
                'gettext_id' => "first-level filter",
                'format'     => '.+',
                'occurrence' => '1',
                'length'     => 50
            },
            'attrs1' => {
                'order'      => 8,
                'gettext_id' => "first-level extracted attribute",
                format_s     => '$ldap_attrdesc',
                'length'     => 15
            },
            'select1' => {
                'order'      => 9,
                'gettext_id' => "first-level selection",
                'format'     => ['all', 'first', 'regex'],
                'occurrence' => '1',
                'default'    => 'first'
            },
            'regex1' => {
                'order'      => 10,
                'gettext_id' => "first-level regular expression",
                'format'     => '.+',
                'default'    => '',
                'length'     => 50
            },
            'suffix2' => {
                'order'      => 11,
                'gettext_id' => "second-level suffix template",
                'format'     => '.+'
            },
            'scope2' => {
                'order'      => 12,
                'gettext_id' => "second-level search scope",
                'format'     => ['base', 'one', 'sub'],
                'occurrence' => '1',
                'default'    => 'sub'
            },
            'timeout2' => {
                'order'        => 13,
                'gettext_id'   => "second-level connection timeout",
                'gettext_unit' => 'seconds',
                'format'       => '\w+',
                'length'       => 6,
                'default'      => 30
            },
            'filter2' => {
                'order'      => 14,
                'gettext_id' => "second-level filter template",
                'format'     => '.+',
                'occurrence' => '1',
                'length'     => 50
            },
            'attrs2' => {
                'order'      => 15,
                'gettext_id' => "second-level extracted attribute",
                format_s     => '$ldap_attrdesc',
                'default'    => 'mail',
                'length'     => 15
            },
            'select2' => {
                'order'      => 16,
                'gettext_id' => "second-level selection",
                'format'     => ['all', 'first', 'regex'],
                'occurrence' => '1',
                'default'    => 'first'
            },
            'regex2' => {
                'order'      => 17,
                'gettext_id' => "second-level regular expression",
                'format'     => '.+',
                'default'    => '',
                'length'     => 50
            },
            'email_entry' => {
                'order'      => 18,
                'gettext_id' => "Name of email entry",
                'format'     => '\S+',
                'occurrence' => '1'
            },
            'nosync_time_ranges' => {
                'order'      => 19,
                'gettext_id' => "Time ranges when inclusion is not allowed",
                format_s     => '$time_ranges',
                'occurrence' => '0-1'
            }
        },
        'occurrence' => '0-n'
    },

    'include_sql_ca' => {
        order        => 60.16,
        'group'      => 'data_source',
        'gettext_id' => "SQL query custom attribute",
        'format'     => {
            'name' => {
                'order'      => 1,
                'gettext_id' => "short name for this source",
                'format'     => '.+',
                'length'     => 50,
            },
            'db_type' => {
                'order'      => 1.5,
                'gettext_id' => "database type",
                'format'     => '\S+',
                'occurrence' => '1'
            },
            'db_host' => {
                'order'      => 2,
                'gettext_id' => "remote host",
                format_s     => '$host',
                # Not required for ODBC and SQLite. Optional for Oracle.
                #'occurrence' => '1'
            },
            'host'    => {obsolete => 'db_host'},
            'db_port' => {
                'order'      => 3,
                'gettext_id' => "database port",
                'format'     => '\d+'
            },
            'db_name' => {
                'order'      => 4,
                'gettext_id' => "database name",
                'format'     => '\S+',
                'occurrence' => '1'
            },
            'db_options' => {
                'order'      => 4.5,
                'gettext_id' => "connection options",
                'format'     => '.+'
            },
            'connect_options' => {obsolete => 'db_options'},
            'db_env'          => {
                'order' => 5,
                'gettext_id' =>
                    "environment variables for database connection",
                'format' => '\w+\=\S+(;\w+\=\S+)*'
            },
            'db_user' => {
                'order'      => 6,
                'gettext_id' => "remote user",
                'format'     => '\S+',
            },
            'user'      => {obsolete => 'db_user'},
            'db_passwd' => {
                'order'      => 7,
                'gettext_id' => "remote password",
                'format'     => '.+',
                'field_type' => 'password'
            },
            'passwd'    => {options => 'db_passwd'},
            'sql_query' => {
                'order'      => 8,
                'gettext_id' => "SQL query",
                format_s     => '$sql_query',
                'occurrence' => '1',
                'length'     => 50
            },
            'f_dir' => {
                'order' => 9,
                'gettext_id' =>
                    "Directory where the database is stored (used for DBD::CSV only)",
                'format' => '.+',
                obsolete => 'db_name',
                not_after => '6.2.70',
            },
            'email_entry' => {
                'order'      => 10,
                'gettext_id' => "Name of email entry",
                'format'     => '\S+',
                'occurrence' => '1'
            },
            'nosync_time_ranges' => {
                'order'      => 11,
                'gettext_id' => "Time ranges when inclusion is not allowed",
                format_s     => '$time_ranges',
                'occurrence' => '0-1'
            }
        },
        'occurrence' => '0-n'
    },

    ### DKIM page ###

    'dkim_feature' => {
        order        => 70.01,
        'group'      => 'dkim',
        'gettext_id' => "Insert DKIM signature to messages sent to the list",
        'gettext_comment' =>
            "Enable/Disable DKIM. This feature requires Mail::DKIM to be installed, and maybe some custom scenario to be updated",
        'format'     => ['on', 'off'],
        'occurrence' => '1',
        'default'    => {'conf' => 'dkim_feature'}
    },

    'dkim_parameters' => {
        order        => 70.02,
        'group'      => 'dkim',
        'gettext_id' => "DKIM configuration",
        'gettext_comment' =>
            'A set of parameters in order to define outgoing DKIM signature',
        'format' => {
            'private_key_path' => {
                'order'      => 1,
                'gettext_id' => "File path for list DKIM private key",
                'gettext_comment' =>
                    "The file must contain a RSA pem encoded private key",
                'format'     => '\S+',
                'occurrence' => '0-1',
                'default'    => {'conf' => 'dkim_private_key_path'}
            },
            'selector' => {
                'order'      => 2,
                'gettext_id' => "Selector for DNS lookup of DKIM public key",
                'gettext_comment' =>
                    "The selector is used in order to build the DNS query for public key. It is up to you to choose the value you want but verify that you can query the public DKIM key for <selector>._domainkey.your_domain",
                'format'     => '\S+',
                'occurrence' => '0-1',
                'default'    => {'conf' => 'dkim_selector'}
            },
            'header_list' => {
                'obsolete' => 1,    # Not yet implemented
                'order'    => 4,
                'gettext_id' =>
                    'List of headers to be included into the message for signature',
                'gettext_comment' =>
                    'You should probably use the default value which is the value recommended by RFC4871',
                'format'     => '\S+',
                'occurrence' => '1-n',
                'split_char' => ':',     #FIXME
                #'default'    => {'conf' => 'dkim_header_list'},
            },
            'signer_domain' => {
                'order' => 5,
                'gettext_id' =>
                    'DKIM "d=" tag, you should probably use the default value',
                'gettext_comment' =>
                    'The DKIM "d=" tag, is the domain of the signing entity. The list domain MUST be included in the "d=" domain',
                'format'     => '\S+',
                'occurrence' => '0-1',
                'default'    => {'conf' => 'dkim_signer_domain'}
            },
            'signer_identity' => {
                'order' => 6,
                'gettext_id' =>
                    'DKIM "i=" tag, you should probably leave this parameter empty',
                'gettext_comment' =>
                    'DKIM "i=" tag, you should probably not use this parameter, as recommended by RFC 4871, default for list brodcasted messages is i=<listname>-request@<domain>',
                'format'     => '\S+',
                'occurrence' => '0-1'
            },
        },
        'occurrence' => '0-1'
    },

    'dkim_signature_apply_on' => {
        order   => 70.03,
        'group' => 'dkim',
        'gettext_id' =>
            "The categories of messages sent to the list that will be signed using DKIM.",
        'gettext_comment' =>
            "This parameter controls in which case messages must be signed using DKIM, you may sign every message choosing 'any' or a subset. The parameter value is a comma separated list of keywords",
        'format' => [
            'md5_authenticated_messages',  'smime_authenticated_messages',
            'dkim_authenticated_messages', 'editor_validated_messages',
            'none',                        'any'
        ],
        'occurrence' => '0-n',
        'split_char' => ',',
        'default'    => {'conf' => 'dkim_signature_apply_on'}
    },

    'arc_feature' => {
        order        => 70.04,
        'group'      => 'dkim',
        'gettext_id' => "Add ARC seals to messages sent to the list",
        'gettext_comment' =>
            "Enable/Disable ARC. This feature requires Mail::DKIM::ARC to be installed, and maybe some custom scenario to be updated",
        'format'     => ['on', 'off'],
        'occurrence' => '1',
        'default'    => {'conf' => 'arc_feature'}
    },

    'arc_parameters' => {
        order        => 70.05,
        'group'      => 'dkim',
        'gettext_id' => "ARC configuration",
        'gettext_comment' =>
            'A set of parameters in order to define outgoing ARC seal',
        'format' => {
            'arc_private_key_path' => {
                'order'      => 1,
                'gettext_id' => "File path for list ARC private key",
                'gettext_comment' =>
                    "The file must contain a RSA pem encoded private key. Default is DKIM private key.",
                'format'     => '\S+',
                'occurrence' => '0-1',
                'default'    => {'conf' => 'arc_private_key_path'}
            },
            'arc_selector' => {
                'order'      => 2,
                'gettext_id' => "Selector for DNS lookup of ARC public key",
                'gettext_comment' =>
                    "The selector is used in order to build the DNS query for public key. It is up to you to choose the value you want but verify that you can query the public DKIM key for <selector>._domainkey.your_domain.  Default is selector for DKIM signature",
                'format'     => '\S+',
                'occurrence' => '0-1',
                'default'    => {'conf' => 'arc_selector'}
            },
            'arc_signer_domain' => {
                'order' => 3,
                'gettext_id' =>
                    'ARC "d=" tag, you should probably use the default value',
                'gettext_comment' =>
                    'The ARC "d=" tag, is the domain of the sealing entity. The list domain MUST be included in the "d=" domain',
                'format'     => '\S+',
                'occurrence' => '0-1',
                'default'    => {'conf' => 'arc_signer_domain'}
            },
        },
        'occurrence' => '0-1'
    },

    'dmarc_protection' => {
        order    => 70.07,
        'format' => {
            'mode' => {
                'format' => [
                    'none',           'all',
                    'dkim_signature', 'dmarc_reject',
                    'dmarc_any',      'dmarc_quarantine',
                    'domain_regex'
                ],
                'synonym' => {
                    'dkim'         => 'dkim_signature',
                    'dkim_exists'  => 'dkim_signature',
                    'dmarc_exists' => 'dmarc_any',
                    'domain'       => 'domain_regex',
                    'domain_match' => 'domain_regex',
                },
                'gettext_id' => "Protection modes",
                'split_char' => ',',
                'occurrence' => '0-n',
                'default'    => {'conf' => 'dmarc_protection_mode'},
                'gettext_comment' =>
                    'Select one or more operation modes.  "Domain matching regular expression" (domain_regex) matches the specified Domain regular expression; "DKIM signature exists" (dkim_signature) matches any message with a DKIM signature header; "DMARC policy ..." (dmarc_*) matches messages from sender domains with a DMARC policy as given; "all" (all) matches all messages.',
                'order' => 1
            },
            'domain_regex' => {
                'format'     => '.+',
                'gettext_id' => "Match domain regular expression",
                'occurrence' => '0-1',
                'gettext_comment' =>
                    'Regular expression match pattern for From domain',
                'order'   => 2,
                'default' => {'conf' => 'dmarc_protection_domain_regex'},
            },
            'other_email' => {
                'format'     => '.+',
                'gettext_id' => "New From address",
                'occurrence' => '0-1',
                'gettext_comment' =>
                    'This is the email address to use when modifying the From header.  It defaults to the list address.  This is similar to Anonymisation but preserves the original sender details in the From address phrase.',
                'order'   => 3,
                'default' => {'conf' => 'dmarc_protection_other_email'},
            },
            'phrase' => {
                'format' => [
                    'display_name',   'name_and_email',
                    'name_via_list',  'name_email_via_list',
                    'list_for_email', 'list_for_name',
                ],
                'synonym' =>
                    {'name' => 'display_name', 'prefixed' => 'list_for_name'},
                'default'    => {'conf' => 'dmarc_protection_phrase'},
                'gettext_id' => "New From name format",
                'occurrence' => '0-1',
                'gettext_comment' =>
                    'This is the format to be used for the sender name part of the new From header.',
                'order' => 4,
            },
        },
        'gettext_id' => "DMARC Protection",
        'group'      => 'dkim',
        'gettext_comment' =>
            "Parameters to define how to manage From address processing to avoid some domains' excessive DMARC protection",
        'occurrence' => '0-1',
    },

    ### Others page ###

    'account' => {
        'group'      => 'other',
        'gettext_id' => "Account",
        'format'     => '\S+',
        'length'     => 10,
        'obsolete'   => 1,
    },

    'clean_delay_queuemod' => {
        order          => 90.01,
        'group'        => 'other',
        'gettext_id'   => "Expiration of unmoderated messages",
        'gettext_unit' => 'days',
        'format'       => '\d+',
        'length'       => 3,
        'default'      => {'conf' => 'clean_delay_queuemod'}
    },

    'cookie' => {
        order        => 90.02,
        'group'      => 'other',
        'gettext_id' => "Secret string for generating unique keys",
        'gettext_comment' =>
            'This parameter is a confidential item for generating authentication keys for administrative commands (ADD, DELETE, etc.). This parameter should remain concealed, even for owners. The cookie is applied to all list owners, and is only taken into account when the owner has the auth parameter.',
        'format'     => '\S+',
        'field_type' => 'password',
        'length'     => 15,
        'default'    => {'conf' => 'cookie'}
    },

    'custom_vars' => {
        order        => 90.04,
        'group'      => 'other',
        'gettext_id' => "custom parameters",
        'format'     => {
            'name' => {
                'order'      => 1,
                'gettext_id' => 'var name',
                'format'     => '\S+',
                'occurrence' => '1'
            },
            'value' => {
                'order'      => 2,
                'gettext_id' => 'var value',
                'format'     => '.+',
                'occurrence' => '1',
            }
        },
        'occurrence' => '0-n'
    },

    'expire_task' => {
        order        => 90.05,
        'group'      => 'other',
        'gettext_id' => "Periodical subscription expiration task",
        'gettext_comment' =>
            "This parameter states which model is used to create an expire task. An expire task regularly checks the subscription or resubscription  date of subscribers and asks them to renew their subscription. If they don't they are deleted.",
        'task'     => 'expire',
        'obsolete' => 1,
    },

    'latest_instantiation' => {
        order        => 99.01,
        'group'      => 'other',
        'gettext_id' => 'Latest family instantiation',
        'format'     => {
            'email' => {
                'order'      => 1,
                'gettext_id' => 'who ran the instantiation',
                format_s     => 'listmaster|$email',
                'occurrence' => '0-1'
            },
            'date' => {
                #'order'      => 2,
                'obsolete'   => 1,
                'gettext_id' => 'date',
                'format'     => '.+'
            },
            'date_epoch' => {
                'order'      => 3,
                'gettext_id' => 'date',
                'format'     => '\d+',
                'field_type' => 'unixtime',
                'occurrence' => '1',
                'length'     => 10,
            }
        },
        'internal' => 1
    },

    'loop_prevention_regex' => {
        order   => 90.06,
        'group' => 'other',
        'gettext_id' =>
            "Regular expression applied to prevent loops with robots",
        'format'  => '\S*',
        'length'  => 70,
        'default' => {'conf' => 'loop_prevention_regex'}
    },

    'pictures_feature' => {
        order   => 90.07,
        'group' => 'other',
        'gettext_id' =>
            "Allow picture display? (must be enabled for the current robot)",
        'format'     => ['on', 'off'],
        'occurrence' => '1',
        'default'    => {'conf' => 'pictures_feature'}
    },

    'remind_task' => {
        order        => 90.08,
        'group'      => 'other',
        'gettext_id' => 'Periodical subscription reminder task',
        'gettext_comment' =>
            'This parameter states which model is used to create a remind task. A remind task regularly sends  subscribers a message which reminds them of their list subscriptions.',
        'task'    => 'remind',
        'default' => {'conf' => 'default_remind_task'}
    },

    'spam_protection' => {
        order        => 90.09,
        'group'      => 'other',
        'gettext_id' => "email address protection method",
        'gettext_comment' =>
            "There is a need to protect Sympa web sites against spambots which collect email addresses from public web sites. Various methods are available in Sympa and you can choose to use them with the spam_protection and web_archive_spam_protection parameters. Possible value are:\njavascript: \nthe address is hidden using a javascript. A user who enables javascript can see a nice mailto address where others have nothing.\nat: \nthe \@ char is replaced by the string \" AT \".\nnone: \nno protection against spammer.",
        'format'     => ['at', 'javascript', 'none'],
        'occurrence' => '1',
        'default'    => 'javascript'
    },

    'creation' => {
        order        => 99.02,
        'group'      => 'other',
        'gettext_id' => "Creation of the list",
        'format'     => {
            'date_epoch' => {
                'order'      => 3,
                'gettext_id' => "date",
                'format'     => '\d+',
                'field_type' => 'unixtime',
                'occurrence' => '1',
                'length'     => 10,
            },
            'date' => {
                #'order'      => 2,
                'obsolete'   => 1,
                'gettext_id' => "human readable",
                'format'     => '.+'
            },
            'email' => {
                'order'      => 1,
                'gettext_id' => "who created the list",
                format_s     => 'listmaster|$email',
                'occurrence' => '1'
            }
        },
        'occurrence' => '0-1',
        'internal'   => 1
    },

    'update' => {
        order        => 99.03,
        'group'      => 'other',
        'gettext_id' => "Last update of config",
        'format'     => {
            'email' => {
                'order'      => 1,
                'gettext_id' => 'who updated the config',
                format_s     => '(listmaster|automatic|$email)',
                'occurrence' => '0-1',
                'length'     => 30
            },
            'date' => {
                #'order'      => 2,
                'obsolete'   => 1,
                'gettext_id' => 'date',
                'format'     => '.+',
                'length'     => 30
            },
            'date_epoch' => {
                'order'      => 3,
                'gettext_id' => 'date',
                'format'     => '\d+',
                'field_type' => 'unixtime',
                'occurrence' => '1',
                'length'     => 10,
            }
        },
        'internal' => 1,
    },

    'status' => {
        order        => 99.04,
        'group'      => 'other',
        'gettext_id' => "Status of the list",
        'format' =>
            ['open', 'closed', 'pending', 'error_config', 'family_closed'],
        'field_type' => 'status',
        'default'    => 'open',
        'internal'   => 1
    },

    'serial' => {
        order        => 99.05,
        'group'      => 'other',
        'gettext_id' => "Serial number of the config",
        'format'     => '\d+',
        'default'    => 0,
        'internal'   => 1,
        'length'     => 3
    },

    'custom_attribute' => {
        order        => 90.03,
        'group'      => 'other',
        'gettext_id' => "Custom user attributes",
        'format'     => {
            'id' => {
                'order'      => 1,
                'gettext_id' => "internal identifier",
                'format'     => '\w+',
                'occurrence' => '1',
                'length'     => 20
            },
            'name' => {
                'order'      => 2,
                'gettext_id' => "label",
                'format'     => '.+',
                'occurrence' => '1',
                'length'     => 30
            },
            'comment' => {
                'order'      => 3,
                'gettext_id' => "additional comment",
                'format'     => '.+',
                'length'     => 100
            },
            'type' => {
                'order'      => 4,
                'gettext_id' => "type",
                'format'     => ['string', 'text', 'integer', 'enum'],
                'default'    => 'string',
                'occurrence' => 1
            },
            'enum_values' => {
                'order'      => 5,
                'gettext_id' => "possible attribute values (if enum is used)",
                'format'     => '.+',
                'length'     => 100
            },
            'optional' => {
                'order'      => 6,
                'gettext_id' => "is the attribute optional?",
                'format'     => ['required', 'optional'],
                'default'    => 'optional',
                'occurrence' => 1
            }
        },
        'occurrence' => '0-n'
    }
);

our %user_info = (
    owner => {
        order      => 10.03,
        group      => 'description',
        gettext_id => "Owners",
        gettext_comment =>
            'Owners are managing subscribers of the list. They may review subscribers and add or delete email addresses from the mailing list. If you are a privileged owner of the list, you can choose other owners for the mailing list. Privileged owners may edit a few more options than other owners. ',
        format => {
            email => {
                order       => 2,
                gettext_id  => "email address",
                format_s    => '$email',
                occurrence  => '1',
                length      => 30,
                filters     => ['canonic_email'],
                validations => [
                    qw(list_address list_special_addresses unique_paragraph_key)
                ],
            },
            gecos => {
                order      => 3,
                gettext_id => "name",
                format     => '.+',
                length     => 30
            },
            info => {
                order      => 6,
                gettext_id => "private information",
                format     => '.+',
                length     => 30
            },
            profile => {
                order      => 1,
                gettext_id => "profile",
                format     => ['privileged', 'normal'],
                occurrence => '1',
                default    => 'normal'
            },
            reception => {
                order      => 4,
                gettext_id => "reception mode",
                format     => ['mail', 'nomail'],
                occurrence => '1',
                default    => 'mail'
            },
            visibility => {
                order      => 5,
                gettext_id => "visibility",
                format     => ['conceal', 'noconceal'],
                occurrence => '1',
                default    => 'noconceal'
            },
            subscribed => {
                order      => 11,
                gettext_id => 'subscribed',
                format     => ['0', '1'],
                occurrence => '1',
                default    => '1',
                internal   => 1,
            },
            included => {
                #order      => 12,
                obsolete   => 1,
                gettext_id => 'included',
                format     => ['0', '1'],
                occurrence => '1',
                default    => '0',
                internal   => 1,
            },
            id => {
                #order      => 13,
                obsolete   => 1,
                gettext_id => 'name of external datasource',
                internal   => 1,
            },
            date => {
                order      => 14,
                gettext_id => 'delegated since',
                format     => '\d+',
                field_type => 'unixtime',
                internal   => 1,
            },
            update_date => {
                order      => 14.5,
                gettext_id => 'last update time',
                format     => '\d+',
                field_type => 'unixtime',
                internal   => 1,
            },
            inclusion => {
                order      => 14.6,
                gettext_id => 'last inclusion time',
                format     => '\d+',
                field_type => 'unixtime',
                internal   => 1,
            },
            inclusion_ext => {
                order      => 14.7,
                gettext_id => 'last inclusion time from external data source',
                format     => '\d+',
                field_type => 'unixtime',
                internal   => 1,
            },
        },
        occurrence => '1-n'
    },

    editor => {
        order      => 10.05,
        group      => 'description',
        gettext_id => "Moderators",
        gettext_comment =>
            "Moderators are responsible for moderating messages. If the mailing list is moderated, messages posted to the list will first be passed to the moderators, who will decide whether to distribute or reject it.\nFYI: Defining moderators will not make the list moderated; you will have to set the \"send\" parameter.\nFYI: If the list is moderated, any moderator can distribute or reject a message without the knowledge or consent of the other moderators. Messages that have not been distributed or rejected will remain in the moderation spool until they are acted on.",
        format => {
            email => {
                order       => 1,
                gettext_id  => "email address",
                format_s    => '$email',
                occurrence  => '1',
                length      => 30,
                filters     => ['canonic_email'],
                validations => [
                    qw(list_address list_editor_address unique_paragraph_key)
                ],
            },
            gecos => {
                order      => 2,
                gettext_id => "name",
                format     => '.+',
                length     => 30
            },
            info => {
                order      => 5,
                gettext_id => "private information",
                format     => '.+',
                length     => 30
            },
            reception => {
                order      => 3,
                gettext_id => "reception mode",
                format     => ['mail', 'nomail'],
                occurrence => '1',
                default    => 'mail'
            },
            visibility => {
                order      => 4,
                gettext_id => "visibility",
                format     => ['conceal', 'noconceal'],
                occurrence => '1',
                default    => 'noconceal'
            },
            subscribed => {
                order      => 11,
                gettext_id => 'subscribed',
                format     => ['0', '1'],
                occurrence => '1',
                default    => '1',
                internal   => 1,
            },
            included => {
                #order      => 12,
                obsolete   => 1,
                gettext_id => 'included',
                format     => ['0', '1'],
                occurrence => '1',
                default    => '0',
                internal   => 1,
            },
            id => {
                #order      => 13,
                obsolete   => 1,
                gettext_id => 'name of external datasource',
                internal   => 1,
            },
            date => {
                order      => 14,
                gettext_id => 'delegated since',
                format     => '\d+',
                field_type => 'unixtime',
                internal   => 1,
            },
            update_date => {
                order      => 14.5,
                gettext_id => 'last update time',
                format     => '\d+',
                field_type => 'unixtime',
                internal   => 1,
            },
            inclusion => {
                order      => 14.6,
                gettext_id => 'last inclusion time',
                format     => '\d+',
                field_type => 'unixtime',
                internal   => 1,
            },
            inclusion_ext => {
                order      => 14.7,
                gettext_id => 'last inclusion time from external data source',
                format     => '\d+',
                field_type => 'unixtime',
                internal   => 1,
            },
        },
        occurrence => '0-n'
    },
);

_apply_defaults();

## Apply defaults to parameters definition (%pinfo)
sub _apply_defaults {
    foreach my $p (keys %pinfo) {
        cleanup($p, $pinfo{$p});
    }
    foreach my $p (keys %user_info) {
        cleanup($p, $user_info{$p});
    }
}

sub cleanup {
    my $p = shift;
    my $v = shift;

    ## Apply defaults to %pinfo
    foreach my $d (keys %default) {
        unless (defined $v->{$d}) {
            $v->{$d} = $default{$d};
        }
    }

    if (exists $v->{format_s}) {
        my $format = $v->{format_s};
        if ($format =~ /\A\$(\w+)\z/) {
            $format = Sympa::Regexps->can($1)->();
        } else {
            $format =~ s/\$(\w+)/Sympa::Regexps->can($1)->()/eg;
        }
        $v->{format} = $format;
    } elsif ($v->{'scenario'}) {
        # Scenario format
        $v->{'format'} = Sympa::Regexps::scenario_config();
        #XXX$v->{'default'} = 'default';
    } elsif ($v->{'task'}) {
        # Task format
        $v->{'format'} = Sympa::Regexps::task();
    } elsif ($v->{'datasource'}) {
        # Data source format
        $v->{'format'} = Sympa::Regexps::datasource();
    }

    ## Enumeration
    if (ref($v->{'format'}) eq 'ARRAY') {
        $v->{'file_format'} ||= join '|', @{$v->{'format'}},
            keys %{$v->{synonym} || {}};
    }

    ## Set 'format' as default for 'file_format'
    $v->{'file_format'} ||= $v->{'format'};

    if (($v->{'occurrence'} =~ /n$/)
        && $v->{'split_char'}) {
        my $format = $v->{'file_format'};
        my $char   = $v->{'split_char'};
        $v->{'file_format'} = "($format)*(\\s*$char\\s*($format))*";
    }

    ref $v->{'format'} eq 'HASH' && ref $v->{'file_format'} eq 'HASH'
        or return;

    ## Parameter is a Paragraph)
    foreach my $k (keys %{$v->{'format'}}) {
        ## Defaults
        foreach my $d (keys %default) {
            unless (defined $v->{'format'}{$k}{$d}) {
                $v->{'format'}{$k}{$d} = $default{$d};
            }
        }

        if (ref $v->{'format'}{$k}) {
            if (exists $v->{'format'}{$k}{format_s}) {
                my $format = $v->{'format'}{$k}{format_s};
                if ($format =~ /\A\$(\w+)\z/) {
                    $format = Sympa::Regexps->can($1)->();
                } else {
                    $format =~ s/\$(\w+)/Sympa::Regexps->can($1)->()/eg;
                }
                $v->{'format'}{$k}{format} = $format;
            } elsif ($v->{'format'}{$k}{'scenario'}) {
                # Scenario format
                $v->{'format'}{$k}{'format'} =
                    Sympa::Regexps::scenario_config();
                #XXX$v->{'format'}{$k}{'default'} = 'default'
                #XXX    unless ($p eq 'web_archive' and $k eq 'access')
                #XXX    or ($p eq 'archive' and $k eq 'web_access');
            } elsif ($v->{'format'}{$k}{'task'}) {
                # Task format
                $v->{'format'}{$k}{'format'} = Sympa::Regexps::task();
            } elsif ($v->{'format'}{$k}{'datasource'}) {
                # Data source format
                $v->{'format'}{$k}{'format'} = Sympa::Regexps::datasource();
            }
        }

        ## Enumeration
        if (ref($v->{'format'}{$k}{'format'}) eq 'ARRAY') {
            $v->{'file_format'}{$k}{'file_format'} ||= join '|',
                @{$v->{'format'}{$k}{'format'}},
                keys %{$v->{'format'}{$k}{synonym} || {}};
        }

        next if $v->{format}{$k}{'obsolete'};

        #FIXME
        if (($v->{'file_format'}{$k}{'occurrence'} =~ /n$/)
            && $v->{'file_format'}{$k}{'split_char'}) {
            my $format = $v->{'file_format'}{$k}{'file_format'};
            my $char   = $v->{'file_format'}{$k}{'split_char'};
            $v->{'file_format'}{$k}{'file_format'} =
                "($format)*(\\s*$char\\s*($format))*";
        }

    }

    ref $v->{'file_format'} eq 'HASH'
        or return;

    foreach my $k (keys %{$v->{'file_format'}}) {
        ## Set 'format' as default for 'file_format'
        $v->{'file_format'}{$k}{'file_format'} ||=
            $v->{'file_format'}{$k}{'format'};
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Sympa::ListDef - Definition of list configuration parameters

=head1 DESCRIPTION

This module keeps definition of configuration parameters for each list.

=head2 Global variable

=over

=item %alias

Deprecated by Sympa 6.2.16.

=item %pinfo

This hash COMPLETELY defines ALL list parameters.
It is then used to load, save, view, edit list config files.

List parameters format accepts the following keywords :

=over

=item format

Regexp applied to the configuration file entry.
Or arrayref containing all possible values of parameter.

Or, if the parameter is paragraph, value of this item is a hashref containing
definitions of sub-parameters.

See also L<Sympa::List::Config/"Node types">.

=item format_s

Template of regexp applied to the configuration file entry;
see also L</format>.

Subpatterns C<$word> indicate the name of pattern defined in
L<Sympa::Regexps>.

This was introduced on Sympa 6.2.19b.2.

=item file_format

Config file format of the parameter might not be
the same in memory.

=item split_char

Character used to separate multiple parameters.
Used with the set or the array of scalars.

=item length

Length of a scalar variable ; used in web forms.

=item scenario

Tells that the parameter is a scenario, providing its name.

=item default

Default value for the param ; may be a robot configuration
parameter (conf).

If occurrence is C<0-1> or C<0-n>,
default value will be assigned
only when list is created or new node is added to configuration.

=item synonym

Defines synonyms for parameter values (for compatibility
reasons).

=item gettext_unit

Unit of the parameter ; this is used in web forms and refers
to translated
strings in NLS catalogs.

=item occurrence

Occurrence of the parameter in the config file
possible values: C<0-1>, C<1>, C<0-n> and C<1-n>.
Example: A list may have multiple owner.

See also L<Sympa::List::Config/"Node types">.

=item gettext_id

Title reference in NLS catalogs.

=item gettext_comment

Description text of a parameter.

=item group

Group of parameters.

=item obsolete

Obsolete parameter ; should not be displayed
nor saved.

As of 6.2.16, if the value is true value and is not C<1>,
defines parameter alias name mainly for backward compatibility.

=item obsolete_values

B<Deprecated>.

Defined obsolete values for a parameter.
These values should not get proposed on the web interface
edition form.

=item order

Order of parameters within paragraph.

=item internal

Indicates that the parameter is an internal parameter
that should always be saved in the config file.

=item field_type

Used to special treatment of parameter value to show it.

=over

=item C<'dayofweek'>

Day of week, C<0> - C<6>.

=item C<'lang'>

Language tag.

=item C<'password'>

The value to be concealed.

=item C<'reception'>

Reception mode of list member.

=item C<'status'>

Status of list.

=item C<'listtopic'>

List topic.

=item C<'unixtime'>

The time in second from Unix epoch.

=item C<'visibility'>

Visibility mode of list member.

=back

Most of field types were introduced on Sympa 6.2.17.

=item filters

See L<Sympa::List::Config/"Filters">.

Introduced on Sympa 6.2.17.

=item validations

See L<Sympa::List::Config/"Validations">.

Introduced on Sympa 6.2.17.

=item privilege

I<Dynamically assigned>.
Privilege for specified user:
C<'write'>, C<'read'> or C<'hidden'>.

Introduced on Sympa 6.2.17.

=item enum

I<Automatically assigned>.
TBD.

Introduced on Sympa 6.2.17.

=back

=back

=head1 SEE ALSO

L<list_config(5)>,
L<Sympa::List::Config>,
L<Sympa::ListOpt>.

=head1 HISTORY

L<Sympa::ListDef> was separated from L<List> module on Sympa 6.2.

=cut
