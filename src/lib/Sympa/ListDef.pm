# -*- indent-tabs-mode: nil; -*-
# vim:ft=perl:et:sw=4
# $Id$

# Sympa - SYsteme de Multi-Postage Automatique
#
# Copyright (c) 1997, 1998, 1999 Institut Pasteur & Christophe Wolfhugel
# Copyright (c) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
# 2006, 2007, 2008, 2009, 2010, 2011 Comite Reseau des Universites
# Copyright (c) 2011, 2012, 2013, 2014, 2015 GIP RENATER
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

our @param_order =
    qw (subject visibility info subscribe add unsubscribe del owner owner_include
    send editor editor_include delivery_time account topics
    host lang process_archive web_archive archive digest digest_max_size available_user_options
    default_user_options msg_topic msg_topic_keywords_apply_on msg_topic_tagging reply_to_header reply_to forced_reply_to *
    verp_rate tracking welcome_return_path remind_return_path user_data_source include_file include_remote_file
    include_list include_remote_sympa_list include_ldap_query
    include_ldap_2level_query include_sql_query include_voot_group ttl distribution_ttl creation update
    status serial custom_attribute include_ldap_ca include_ldap_2level_ca include_sql_ca);

## List parameters aliases
my %alias = (
    'reply-to'        => 'reply_to',
    'replyto'         => 'reply_to',
    'forced_replyto'  => 'forced_reply_to',
    'forced_reply-to' => 'forced_reply_to',
    'custom-subject'  => 'custom_subject',
    'custom-header'   => 'custom_header',
    'subscription'    => 'subscribe',
    'unsubscription'  => 'unsubscribe',
    'max-size'        => 'max_size'
);

our %pinfo = (

    ### Global definition page ###

    'subject' => {
        'group'      => 'description',
        'gettext_id' => "Subject of the list",
        'format'     => '.+',
        'occurrence' => '1',
        'length'     => 50
    },

    'visibility' => {
        'group'      => 'description',
        'gettext_id' => "Visibility of the list",
        'scenario'   => 'visibility',
        'synonym'    => {
            'public'  => 'noconceal',
            'private' => 'conceal'
        }
    },

    'owner' => {
        'group'      => 'description',
        'gettext_id' => "Owner",
        'format'     => {
            'email' => {
                'order'      => 1,
                'gettext_id' => "email address",
                'format'     => Sympa::Regexps::email(),
                'occurrence' => '1',
                'length'     => 30
            },
            'gecos' => {
                'order'      => 2,
                'gettext_id' => "name",
                'format'     => '.+',
                'length'     => 30
            },
            'info' => {
                'order'      => 3,
                'gettext_id' => "private information",
                'format'     => '.+',
                'length'     => 30
            },
            'profile' => {
                'order'      => 4,
                'gettext_id' => "profile",
                'format'     => ['privileged', 'normal'],
                'default'    => 'normal'
            },
            'reception' => {
                'order'      => 5,
                'gettext_id' => "reception mode",
                'format'     => ['mail', 'nomail'],
                'default'    => 'mail'
            },
            'visibility' => {
                'order'      => 6,
                'gettext_id' => "visibility",
                'format'     => ['conceal', 'noconceal'],
                'default'    => 'noconceal'
            }
        },
        'occurrence' => '1-n'
    },

    'owner_include' => {
        'group'      => 'description',
        'gettext_id' => 'Owners defined in an external data source',
        'format'     => {
            'source' => {
                'order'      => 1,
                'gettext_id' => 'the datasource',
                'datasource' => 1,
                'occurrence' => '1'
            },
            'source_parameters' => {
                'order'      => 2,
                'gettext_id' => 'datasource parameters',
                'format'     => '.*',
                'occurrence' => '0-1'
            },
            'reception' => {
                'order'      => 4,
                'gettext_id' => 'reception mode',
                'format'     => ['mail', 'nomail'],
                'default'    => 'mail'
            },
            'visibility' => {
                'order'      => 5,
                'gettext_id' => "visibility",
                'format'     => ['conceal', 'noconceal'],
                'default'    => 'noconceal'
            },
            'profile' => {
                'order'      => 3,
                'gettext_id' => 'profile',
                'format'     => ['privileged', 'normal'],
                'default'    => 'normal'
            }
        },
        'occurrence' => '0-n'
    },

    'editor' => {
        'group'      => 'description',
        'gettext_id' => "Moderators",
        'format'     => {
            'email' => {
                'order'      => 1,
                'gettext_id' => "email address",
                'format'     => Sympa::Regexps::email(),
                'occurrence' => '1',
                'length'     => 30
            },
            'reception' => {
                'order'      => 4,
                'gettext_id' => "reception mode",
                'format'     => ['mail', 'nomail'],
                'default'    => 'mail'
            },
            'visibility' => {
                'order'      => 5,
                'gettext_id' => "visibility",
                'format'     => ['conceal', 'noconceal'],
                'default'    => 'noconceal'
            },
            'gecos' => {
                'order'      => 2,
                'gettext_id' => "name",
                'format'     => '.+',
                'length'     => 30
            },
            'info' => {
                'order'      => 3,
                'gettext_id' => "private information",
                'format'     => '.+',
                'length'     => 30
            }
        },
        'occurrence' => '0-n'
    },

    'editor_include' => {
        'group'      => 'description',
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
                'default'    => 'mail'
            },
            'visibility' => {
                'order'      => 5,
                'gettext_id' => "visibility",
                'format'     => ['conceal', 'noconceal'],
                'default'    => 'noconceal'
            }
        },
        'occurrence' => '0-n'
    },

    'topics' => {
        'group'      => 'description',
        'gettext_id' => "Topics for the list",
        'format'     => '[\-\w]+(\/[\-\w]+)?',
        'split_char' => ',',
        'occurrence' => '0-n'
    },

    'host' => {
        'group'      => 'description',
        'gettext_id' => "Internet domain",
        'format'     => Sympa::Regexps::host(),
        'default'    => {'conf' => 'host'},
        'length'     => 20
    },

    'lang' => {
        'group'      => 'description',
        'gettext_id' => "Language of the list",
        'format' => [],    ## Sympa::get_supported_languages() called later
        'file_format' => '\w+(\-\w+)*',
        'default'     => {'conf' => 'lang'}
    },

    'family_name' => {
        'group'      => 'description',
        'gettext_id' => 'Family name',
        'format'     => Sympa::Regexps::family_name(),
        'occurrence' => '0-1',
        'internal'   => 1
    },

    'max_list_members' => {
        'group'        => 'description',
        'gettext_id'   => "Maximum number of list members",
        'gettext_unit' => 'list members',
        'format'       => '\d+',
        'length'       => 8,
        'default'      => {'conf' => 'default_max_list_members'}
    },

    'priority' => {
        'group'      => 'description',
        'gettext_id' => "Priority",
        'format'     => [0 .. 9, 'z'],
        'length'     => 1,
        'default'    => {'conf' => 'default_list_priority'}
    },

    ### Sending page ###

    'send' => {
        'group'      => 'sending',
        'gettext_id' => "Who can send messages",
        'scenario'   => 'send'
    },

    'delivery_time' => {
        'group'      => 'sending',
        'gettext_id' => "Delivery time (hh:mm)",
        'format'     => '[0-2]?\d\:[0-6]\d',
        'occurrence' => '0-1',
        'length'     => 5
    },

    'digest' => {
        'group'       => 'sending',
        'gettext_id'  => "Digest frequency",
        'file_format' => '\d+(\s*,\s*\d+)*\s+\d+:\d+',
        'format'      => {
            'days' => {
                'order'       => 1,
                'gettext_id'  => "days",
                'format'      => [0 .. 6],
                'file_format' => '1|2|3|4|5|6|7',
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
        'group'        => 'sending',
        'gettext_id'   => "Digest maximum number of messages",
        'gettext_unit' => 'messages',
        'format'       => '\d+',
        'default'      => 25,
        'length'       => 2
    },

    'available_user_options' => {
        'group'      => 'sending',
        'gettext_id' => "Available subscription options",
        'format'     => {
            'reception' => {
                'gettext_id' => "reception mode",
                'format'     => [
                    'mail',    'notice', 'digest', 'digestplain',
                    'summary', 'nomail', 'txt',    'html',
                    'urlize',  'not_me'
                ],
                'occurrence' => '1-n',
                'split_char' => ',',
                'default' =>
                    'mail,notice,digest,digestplain,summary,nomail,txt,html,urlize,not_me'
            }
        }
    },

    'default_user_options' => {
        'group'      => 'sending',
        'gettext_id' => "Subscription profile",
        'format'     => {
            'reception' => {
                'order'      => 1,
                'gettext_id' => "reception mode",
                'format'     => [
                    'digest',  'digestplain', 'mail', 'nomail',
                    'summary', 'notice',      'txt',  'html',
                    'urlize',  'not_me'
                ],
                'default' => 'mail'
            },
            'visibility' => {
                'order'      => 2,
                'gettext_id' => "visibility",
                'format'     => ['conceal', 'noconceal'],
                'default'    => 'noconceal'
            }
        },
    },

    'msg_topic' => {
        'group'      => 'sending',
        'gettext_id' => "Topics for message categorization",
        'format'     => {
            'name' => {
                'order'      => 1,
                'gettext_id' => "Message topic name",
                'format'     => '[\-\w]+',
                'occurrence' => '1',
                'length'     => 15
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
        'group' => 'sending',
        'gettext_id' =>
            "Defines to which part of messages topic keywords are applied",
        'format'     => ['subject', 'body', 'subject_and_body'],
        'occurrence' => '0-1',
        'default'    => 'subject'
    },

    'msg_topic_tagging' => {
        'group'      => 'sending',
        'gettext_id' => "Message tagging",
        'format'     => ['required_sender', 'required_moderator', 'optional'],
        'occurrence' => '0-1',
        'default'    => 'optional'
    },

    'reply_to' => {
        'group'      => 'sending',
        'gettext_id' => "Reply address",
        'format'     => '\S+',
        'default'    => 'sender',
        'obsolete'   => 1
    },

    'forced_reply_to' => {
        'group'      => 'sending',
        'gettext_id' => "Forced reply address",
        'format'     => '\S+',
        'obsolete'   => 1
    },

    'reply_to_header' => {
        'group'      => 'sending',
        'gettext_id' => "Reply address",
        'format'     => {
            'value' => {
                'order'      => 1,
                'gettext_id' => "value",
                'format'     => ['sender', 'list', 'all', 'other_email'],
                'default'    => 'sender',
                'occurrence' => '1'
            },
            'other_email' => {
                'order'      => 2,
                'gettext_id' => "other email address",
                'format'     => Sympa::Regexps::email()
            },
            'apply' => {
                'order'      => 3,
                'gettext_id' => "respect of existing header field",
                'format'     => ['forced', 'respect'],
                'default'    => 'respect'
            }
        }
    },

    'anonymous_sender' => {
        'group'      => 'sending',
        'gettext_id' => "Anonymous sender",
        'format'     => '.+'
    },

    'custom_header' => {
        'group'      => 'sending',
        'gettext_id' => "Custom header field",
        'format'     => '\S+:\s+.*',
        'occurrence' => '0-n',
        'length'     => 30
    },

    'custom_subject' => {
        'group'      => 'sending',
        'gettext_id' => "Subject tagging",
        'format'     => '.+',
        'length'     => 15
    },

    'footer_type' => {
        'group'      => 'sending',
        'gettext_id' => "Attachment type",
        'format'     => ['mime', 'append'],
        'default'    => 'mime'
    },

    'max_size' => {
        'group'        => 'sending',
        'gettext_id'   => "Maximum message size",
        'gettext_unit' => 'bytes',
        'format'       => '\d+',
        'length'       => 8,
        'default'      => {'conf' => 'max_size'}
    },

    'merge_feature' => {
        'group'      => 'sending',
        'gettext_id' => "Allow message personalization",
        'format'     => ['on', 'off'],
        'occurrence' => '0-1',
        'default'    => {'conf' => 'merge_feature'}
    },

    'reject_mail_from_automates_feature' => {
        'group'      => 'sending',
        'gettext_id' => "Reject mail from automates (crontab, etc)?",
        'format'     => ['on', 'off'],
        'occurrence' => '0-1',
        'default'    => {'conf' => 'reject_mail_from_automates_feature'}
    },

    'remove_headers' => {
        'group'      => 'sending',
        'gettext_id' => 'Incoming SMTP header fields to be removed',
        'format'     => '\S+',
        'default'    => {'conf' => 'remove_headers'},
        'occurrence' => '0-n',
        'split_char' => ','
    },

    'remove_outgoing_headers' => {
        'group'      => 'sending',
        'gettext_id' => 'Outgoing SMTP header fields to be removed',
        'format'     => '\S+',
        'default'    => {'conf' => 'remove_outgoing_headers'},
        'occurrence' => '0-n',
        'split_char' => ','
    },

    'rfc2369_header_fields' => {
        'group'      => 'sending',
        'gettext_id' => "RFC 2369 Header fields",
        'format' =>
            ['help', 'subscribe', 'unsubscribe', 'post', 'owner', 'archive'],
        'default'    => {'conf' => 'rfc2369_header_fields'},
        'occurrence' => '0-n',
        'split_char' => ','
    },

    'message_hook' => {
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

    ### Command page ###

    'info' => {
        'group'      => 'command',
        'gettext_id' => "Who can view list information",
        'scenario'   => 'info'
    },

    'subscribe' => {
        'group'      => 'command',
        'gettext_id' => "Who can subscribe to the list",
        'scenario'   => 'subscribe'
    },

    'add' => {
        'group'      => 'command',
        'gettext_id' => "Who can add subscribers",
        'scenario'   => 'add'
    },

    'unsubscribe' => {
        'group'      => 'command',
        'gettext_id' => "Who can unsubscribe",
        'scenario'   => 'unsubscribe'
    },

    'del' => {
        'group'      => 'command',
        'gettext_id' => "Who can delete subscribers",
        'scenario'   => 'del'
    },

    'invite' => {
        'group'      => 'command',
        'gettext_id' => "Who can invite people",
        'scenario'   => 'invite'
    },

    'remind' => {
        'group'      => 'command',
        'gettext_id' => "Who can start a remind process",
        'scenario'   => 'remind'
    },

    'review' => {
        'group'      => 'command',
        'gettext_id' => "Who can review subscribers",
        'scenario'   => 'review',
        'synonym'    => {'open' => 'public'}
    },

    'shared_doc' => {
        'group'      => 'command',
        'gettext_id' => "Shared documents",
        'format'     => {
            'd_read' => {
                'order'      => 1,
                'gettext_id' => "Who can view",
                'scenario'   => 'd_read'
            },
            'd_edit' => {
                'order'      => 2,
                'gettext_id' => "Who can edit",
                'scenario'   => 'd_edit'
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
        'group'      => 'archives',
        'gettext_id' => "Store distributed messages into archive",
        'format'     => ['on', 'off'],
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
                'scenario'   => 'access_web_archive',
                'obsolete'   => 1,                    # Use archive.web_access
            },
            'quota' => {
                'order'        => 2,
                'gettext_id'   => "quota",
                'gettext_unit' => 'Kbytes',
                'format'       => '\d+',
                'default'      => {'conf' => 'default_archive_quota'},
                'length'       => 8,
                'obsolete' => 1,                      # Use archive.quota
            },
            'max_month' => {
                'order'      => 3,
                'gettext_id' => "Maximum number of month archived",
                'format'     => '\d+',
                'length'     => 3,
                'obsolete' => 1,                      # Use archive.max_month
            }
        }
    },
    'archive' => {
        'group'      => 'archives',
        'gettext_id' => "Archives",
        'format'     => {
            'period' => {
                'order'      => 1,
                'gettext_id' => "frequency",
                'format'     => ['day', 'week', 'month', 'quarter', 'year'],
                'synonym'  => {'weekly' => 'week'},
                'obsolete' => 1,        # Not yet implemented.
            },
            'access' => {
                'order'      => 2,
                'gettext_id' => "access right",
                'format' => ['open', 'private', 'public', 'owner', 'closed'],
                'synonym'  => {'open' => 'public'},
                'obsolete' => 1,      # Use archive.mail_access
            },
            'web_access' => {
                'order'      => 3,
                'gettext_id' => "access right",
                'scenario'   => 'access_web_archive'
            },
            'mail_access' => {
                'order'      => 4,
                'gettext_id' => "access right by mail commands",
                'scenario'   => 'archive_mail_access',
                'synonym' => {'open' => 'public'}    # Compat. with <=6.2b.3.
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
        'group'      => 'archives',
        'gettext_id' => "Archive encrypted mails as cleartext",
        'format'     => ['original', 'decrypted'],
        'default'    => 'original'
    },

    'web_archive_spam_protection' => {
        'group'      => 'archives',
        'gettext_id' => "email address protection method",
        'format'     => ['cookie', 'javascript', 'at', 'none'],
        'default' => {'conf' => 'web_archive_spam_protection'}
    },

    ### Bounces page ###

    'bounce' => {
        'group'      => 'bounces',
        'gettext_id' => "Bounces management",
        'format'     => {
            'warn_rate' => {
                'order'        => 1,
                'gettext_id'   => "warn rate",
                'gettext_unit' => '%',
                'format'       => '\d+',
                'length'       => 3,
                'default'      => {'conf' => 'bounce_warn_rate'}
            },
            'halt_rate' => {
                'order'        => 2,
                'gettext_id'   => "halt rate",
                'gettext_unit' => '%',
                'format'       => '\d+',
                'length'       => 3,
                'default'      => {'conf' => 'bounce_halt_rate'},
                'obsolete'     => 1,
            }
        }
    },

    'bouncers_level1' => {
        'group'      => 'bounces',
        'gettext_id' => "Management of bouncers, 1st level",
        'format'     => {
            'rate' => {
                'order'        => 1,
                'gettext_id'   => "threshold",
                'gettext_unit' => 'points',
                'format'       => '\d+',
                'length'       => 2,
                'default'      => {'conf' => 'default_bounce_level1_rate'}
            },
            'action' => {
                'order'      => 2,
                'gettext_id' => "action for this population",
                'format'  => ['remove_bouncers', 'notify_bouncers', 'none'],
                'default' => 'notify_bouncers'
            },
            'notification' => {
                'order'      => 3,
                'gettext_id' => "notification",
                'format'     => ['none', 'owner', 'listmaster'],
                'default'    => 'owner'
            }
        }
    },

    'bouncers_level2' => {
        'group'      => 'bounces',
        'gettext_id' => "Management of bouncers, 2nd level",
        'format'     => {
            'rate' => {
                'order'        => 1,
                'gettext_id'   => "threshold",
                'gettext_unit' => 'points',
                'format'       => '\d+',
                'length'       => 2,
                'default'      => {'conf' => 'default_bounce_level2_rate'},
            },
            'action' => {
                'order'      => 2,
                'gettext_id' => "action for this population",
                'format'  => ['remove_bouncers', 'notify_bouncers', 'none'],
                'default' => 'remove_bouncers'
            },
            'notification' => {
                'order'      => 3,
                'gettext_id' => "notification",
                'format'     => ['none', 'owner', 'listmaster'],
                'default'    => 'owner'
            }
        }
    },

    'verp_rate' => {
        'group'      => 'bounces',
        'gettext_id' => "percentage of list members in VERP mode",
        'format' =>
            ['100%', '50%', '33%', '25%', '20%', '10%', '5%', '2%', '0%'],
        'default' => {'conf' => 'verp_rate'}
    },

    'tracking' => {
        'group'      => 'bounces',
        'gettext_id' => "Message tracking feature",
        'format'     => {
            'delivery_status_notification' => {
                'order' => 1,
                'gettext_id' =>
                    "tracking message by delivery status notification",
                'format' => ['on', 'off'],
                'default' =>
                    {'conf' => 'tracking_delivery_status_notification'}
            },
            'message_disposition_notification' => {
                'order' => 2,
                'gettext_id' =>
                    "tracking message by message disposition notification",
                'format' => ['on', 'on_demand', 'off'],
                'default' =>
                    {'conf' => 'tracking_message_disposition_notification'}
            },
            'tracking' => {
                'order'      => 3,
                'gettext_id' => "who can view message tracking",
                'scenario'   => 'tracking'
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
        'group'      => 'bounces',
        'gettext_id' => "Welcome return-path",
        'format'     => ['unique', 'owner'],
        'default'    => {'conf' => 'welcome_return_path'}
    },

    'remind_return_path' => {
        'group'      => 'bounces',
        'gettext_id' => "Return-path of the REMIND command",
        'format'     => ['unique', 'owner'],
        'default'    => {'conf' => 'remind_return_path'}
    },

    ### Datasources page ###

    'inclusion_notification_feature' => {
        'group' => 'data_source',
        'gettext_id' =>
            "Notify subscribers when they are included from a data source?",
        'format'     => ['on', 'off'],
        'occurrence' => '0-1',
        'default'    => 'off',
    },

    'sql_fetch_timeout' => {
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
        'group'      => 'data_source',
        'gettext_id' => "File inclusion",
        'format'     => '\S+',
        'occurrence' => '0-n',
        'length'     => 20,
    },

    'include_remote_file' => {
        'group'      => 'data_source',
        'gettext_id' => "Remote file inclusion",
        'format'     => {
            'name' => {
                'order'      => 1,
                'gettext_id' => "short name for this source",
                'format'     => '.+',
                'length'     => 15
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
            }
        },
        'occurrence' => '0-n'
    },

    'include_list' => {
        'group'      => 'data_source',
        'gettext_id' => "List inclusion",
        'format'     => Sympa::Regexps::listname() . '(\@'
            . Sympa::Regexps::host()
            . ')?(\s+filter\s+.+)?',
        'occurrence' => '0-n'
    },

    'include_remote_sympa_list' => {
        'group'      => 'data_source',
        'gettext_id' => "remote list inclusion",
        'format'     => {
            'name' => {
                'order'      => 1,
                'gettext_id' => "short name for this source",
                'format'     => '.+',
                'length'     => 15
            },
            'host' => {
                'order'      => 1.5,
                'gettext_id' => "remote host",
                'format'     => Sympa::Regexps::host(),
                'occurrence' => '1'
            },
            'port' => {
                'order'      => 2,
                'gettext_id' => "remote port",
                'format'     => '\d+',
                'default'    => 443,
                'length'     => 4
            },
            'path' => {
                'order'      => 3,
                'gettext_id' => "remote path of sympa list dump",
                'format'     => '\S+',
                'occurrence' => '1',
                'length'     => 20
            },
            'cert' => {
                'order' => 4,
                'gettext_id' =>
                    "certificate for authentication by remote Sympa",
                'format'  => ['robot', 'list'],
                'default' => 'list'
            }
        },
        'occurrence' => '0-n'
    },

    'member_include' => {
        'group'      => 'data_source',
        'gettext_id' => 'Users included from parameterizable data sources',
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
        'group'      => 'data_source',
        'gettext_id' => "LDAP query inclusion",
        'format'     => {
            'name' => {
                'order'      => 1,
                'gettext_id' => "short name for this source",
                'format'     => '.+',
                'length'     => 15
            },
            'host' => {
                'order'      => 2,
                'gettext_id' => "remote host",
                'format'     => Sympa::Regexps::multiple_host_or_url(),
                'occurrence' => '1'
            },
            'port' => {
                'order'      => 2,
                'gettext_id' => "remote port",
                'format'     => '\d+',
                'obsolete'   => 1,
                'length'     => 4
            },
            'use_ssl' => {
                'order'      => 2.5,
                'gettext_id' => 'use SSL (LDAPS)',
                'format'     => ['yes', 'no'],
                'default'    => 'no'
            },
            'ssl_version' => {
                'order'      => 2.6,
                'gettext_id' => 'SSL version',
                'format' => ['sslv2', 'sslv3', 'tlsv1', 'tlsv1_1', 'tlsv1_2'],
                'synonym' => {'tls' => 'tlsv1'},
                'default' => 'tlsv1'
            },
            'ssl_ciphers' => {
                'order'      => 2.7,
                'gettext_id' => 'SSL ciphers used',
                'format'     => '.+',
                'default'    => 'ALL',
            },
            'ca_verify' => {
                'order'      => 2.8,
                'gettext_id' => 'Certificate verification',
                'format'     => ['none', 'optional', 'required'],
                'synonym'    => {'require' => 'required'},
                'default'    => 'required',
                'occurrence' => '0-1'
            },
            'user' => {
                'order'      => 3,
                'gettext_id' => "remote user",
                'format'     => '.+'
            },
            'passwd' => {
                'order'      => 3.5,
                'gettext_id' => "remote password",
                'format'     => '.+',
                'field_type' => 'password',
                'length'     => 10
            },
            'suffix' => {
                'order'      => 4,
                'gettext_id' => "suffix",
                'format'     => '.+'
            },
            'scope' => {
                'order'      => 5,
                'gettext_id' => "search scope",
                'format'     => ['base', 'one', 'sub'],
                'default'    => 'sub'
            },
            'timeout' => {
                'order'        => 6,
                'gettext_id'   => "connection timeout",
                'gettext_unit' => 'seconds',
                'format'       => '\w+',
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
                'format'     => '\w+(\s*,\s*\w+)?',
                'default'    => 'mail',
                'length'     => 50
            },
            'select' => {
                'order'      => 9,
                'gettext_id' => "selection (if multiple)",
                'format'     => ['all', 'first'],
                'default'    => 'first'
            },
            'nosync_time_ranges' => {
                'order'      => 10,
                'gettext_id' => "Time ranges when inclusion is not allowed",
                'format'     => Sympa::Regexps::time_ranges(),
                'occurrence' => '0-1'
            }
        },
        'occurrence' => '0-n'
    },

    'include_ldap_2level_query' => {
        'group'      => 'data_source',
        'gettext_id' => "LDAP 2-level query inclusion",
        'format'     => {
            'name' => {
                'order'      => 1,
                'gettext_id' => "short name for this source",
                'format'     => '.+',
                'length'     => 15
            },
            'host' => {
                'order'      => 2,
                'gettext_id' => "remote host",
                'format'     => Sympa::Regexps::multiple_host_or_url(),
                'occurrence' => '1'
            },
            'port' => {
                'order'      => 2,
                'gettext_id' => "remote port",
                'format'     => '\d+',
                'obsolete'   => 1,
                'length'     => 4
            },
            'use_ssl' => {
                'order'      => 2.5,
                'gettext_id' => 'use SSL (LDAPS)',
                'format'     => ['yes', 'no'],
                'default'    => 'no'
            },
            'ssl_version' => {
                'order'      => 2.6,
                'gettext_id' => 'SSL version',
                'format' => ['sslv2', 'sslv3', 'tlsv1', 'tlsv1_1', 'tlsv1_2'],
                'synonym' => {'tls' => 'tlsv1'},
                'default' => 'tlsv1'
            },
            'ssl_ciphers' => {
                'order'      => 2.7,
                'gettext_id' => 'SSL ciphers used',
                'format'     => '.+',
                'default'    => 'ALL'
            },
            'ca_verify' => {
                'order'      => 2.8,
                'gettext_id' => 'Certificate verification',
                'format'     => ['none', 'optional', 'required'],
                'synonym'    => {'require' => 'required'},
                'default'    => 'required',
                'occurrence' => '0-1'
            },
            'user' => {
                'order'      => 3,
                'gettext_id' => "remote user",
                'format'     => '.+'
            },
            'passwd' => {
                'order'      => 3.5,
                'gettext_id' => "remote password",
                'format'     => '.+',
                'field_type' => 'password',
                'length'     => 10
            },
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
                'format'     => '\w+',
                'length'     => 15
            },
            'select1' => {
                'order'      => 9,
                'gettext_id' => "first-level selection",
                'format'     => ['all', 'first', 'regex'],
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
                'default'    => 'sub'
            },
            'timeout2' => {
                'order'        => 13,
                'gettext_id'   => "second-level connection timeout",
                'gettext_unit' => 'seconds',
                'format'       => '\w+',
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
                'format'     => '\w+(\s*,\s*\w+)?',
                'default'    => 'mail',
                'length'     => 50
            },
            'select2' => {
                'order'      => 16,
                'gettext_id' => "second-level selection",
                'format'     => ['all', 'first', 'regex'],
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
                'format'     => Sympa::Regexps::time_ranges(),
                'occurrence' => '0-1'
            }
        },
        'occurrence' => '0-n'
    },

    'include_sql_query' => {
        'group'      => 'data_source',
        'gettext_id' => "SQL query inclusion",
        'format'     => {
            'name' => {
                'order'      => 1,
                'gettext_id' => "short name for this source",
                'format'     => '.+',
                'length'     => 15
            },
            'db_type' => {
                'order'      => 1.5,
                'gettext_id' => "database type",
                'format'     => '\S+',
                'occurrence' => '1'
            },
            'host' => {
                'order'      => 2,
                'gettext_id' => "remote host",
                'format'     => Sympa::Regexps::host(),
                # Not required for ODBC
                # 'occurrence' => '1'
            },
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
            'connect_options' => {
                'order'      => 4,
                'gettext_id' => "connection options",
                'format'     => '.+'
            },
            'db_env' => {
                'order' => 5,
                'gettext_id' =>
                    "environment variables for database connection",
                'format' => '\w+\=\S+(;\w+\=\S+)*'
            },
            'user' => {
                'order'      => 6,
                'gettext_id' => "remote user",
                'format'     => '\S+',
                'occurrence' => '1'
            },
            'passwd' => {
                'order'      => 7,
                'gettext_id' => "remote password",
                'format'     => '.+',
                'field_type' => 'password'
            },
            'sql_query' => {
                'order'      => 8,
                'gettext_id' => "SQL query",
                'format'     => Sympa::Regexps::sql_query(),
                'occurrence' => '1',
                'length'     => 50
            },
            'f_dir' => {
                'order' => 9,
                'gettext_id' =>
                    "Directory where the database is stored (used for DBD::CSV only)",
                'format' => '.+'
            },
            'nosync_time_ranges' => {
                'order'      => 10,
                'gettext_id' => "Time ranges when inclusion is not allowed",
                'format'     => Sympa::Regexps::time_ranges(),
                'occurrence' => '0-1'
            }
        },
        'occurrence' => '0-n'
    },

    'include_voot_group' => {
        'group'      => 'data_source',
        'gettext_id' => "VOOT group inclusion",
        'format'     => {
            'name' => {
                'order'      => 1,
                'gettext_id' => "short name for this source",
                'format'     => '.+',
                'length'     => 15
            },
            'user' => {
                'order'      => 2,
                'gettext_id' => "user",
                'format'     => '\S+',
                'occurrence' => '1'
            },
            'provider' => {
                'order'      => 3,
                'gettext_id' => "provider",
                'format'     => '\S+',
                'occurrence' => '1'
            },
            'group' => {
                'order'      => 4,
                'gettext_id' => "group",
                'format'     => '\S+',
                'occurrence' => '1'
            }
        },
        'occurrence' => '0-n'
    },

    'ttl' => {
        'group'        => 'data_source',
        'gettext_id'   => "Inclusions timeout",
        'gettext_unit' => 'seconds',
        'format'       => '\d+',
        'default'      => 3600,
        'length'       => 6
    },

    'distribution_ttl' => {
        'group'        => 'data_source',
        'gettext_id'   => "Inclusions timeout for message distribution",
        'gettext_unit' => 'seconds',
        'format'       => '\d+',
        'length'       => 6
    },

    'include_ldap_ca' => {
        'group'      => 'data_source',
        'gettext_id' => "LDAP query custom attribute",
        'format'     => {
            'name' => {
                'order'      => 1,
                'gettext_id' => "short name for this source",
                'format'     => '.+',
                'length'     => 15
            },
            'host' => {
                'order'      => 2,
                'gettext_id' => "remote host",
                'format'     => Sympa::Regexps::multiple_host_or_url(),
                'occurrence' => '1'
            },
            'port' => {
                'order'      => 2,
                'gettext_id' => "remote port",
                'format'     => '\d+',
                'obsolete'   => 1,
                'length'     => 4
            },
            'use_ssl' => {
                'order'      => 2.5,
                'gettext_id' => 'use SSL (LDAPS)',
                'format'     => ['yes', 'no'],
                'default'    => 'no'
            },
            'ssl_version' => {
                'order'      => 2.6,
                'gettext_id' => 'SSL version',
                'format' => ['sslv2', 'sslv3', 'tlsv1', 'tlsv1_1', 'tlsv1_2'],
                'synonym' => {'tls' => 'tlsv1'},
                'default' => 'tlsv1'
            },
            'ssl_ciphers' => {
                'order'      => 2.7,
                'gettext_id' => 'SSL ciphers used',
                'format'     => '.+',
                'default'    => 'ALL'
            },
            'ca_verify' => {
                'order'      => 2.8,
                'gettext_id' => 'Certificate verification',
                'format'     => ['none', 'optional', 'required'],
                'synonym'    => {'require' => 'required'},
                'default'    => 'required',
                'occurrence' => '0-1'
            },
            'user' => {
                'order'      => 3,
                'gettext_id' => "remote user",
                'format'     => '.+'
            },
            'passwd' => {
                'order'      => 3.5,
                'gettext_id' => "remote password",
                'format'     => '.+',
                'field_type' => 'password',
                'length'     => 10
            },
            'suffix' => {
                'order'      => 4,
                'gettext_id' => "suffix",
                'format'     => '.+'
            },
            'scope' => {
                'order'      => 5,
                'gettext_id' => "search scope",
                'format'     => ['base', 'one', 'sub'],
                'default'    => 'sub'
            },
            'timeout' => {
                'order'        => 6,
                'gettext_id'   => "connection timeout",
                'gettext_unit' => 'seconds',
                'format'       => '\w+',
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
                'format'     => '\w+',
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
                'format'     => ['all', 'first'],
                'default'    => 'first'
            },
            'nosync_time_ranges' => {
                'order'      => 11,
                'gettext_id' => "Time ranges when inclusion is not allowed",
                'format'     => Sympa::Regexps::time_ranges(),
                'occurrence' => '0-1'
            }
        },
        'occurrence' => '0-n'
    },

    'include_ldap_2level_ca' => {
        'group'      => 'data_source',
        'gettext_id' => "LDAP 2-level query custom attribute",
        'format'     => {
            'name' => {
                'format'     => '.+',
                'gettext_id' => "short name for this source",
                'length'     => 15,
                'order'      => 1,
            },
            'host' => {
                'order'      => 1,
                'gettext_id' => "remote host",
                'format'     => Sympa::Regexps::multiple_host_or_url(),
                'occurrence' => '1'
            },
            'port' => {
                'order'      => 2,
                'gettext_id' => "remote port",
                'format'     => '\d+',
                'obsolete'   => 1,
                'length'     => 4
            },
            'use_ssl' => {
                'order'      => 2.5,
                'gettext_id' => 'use SSL (LDAPS)',
                'format'     => ['yes', 'no'],
                'default'    => 'no'
            },
            'ssl_version' => {
                'order'      => 2.6,
                'gettext_id' => 'SSL version',
                'format' => ['sslv2', 'sslv3', 'tlsv1', 'tlsv1_1', 'tlsv1_2'],
                'synonym' => {'tls' => 'tlsv1'},
                'default' => 'tlsv1'
            },
            'ssl_ciphers' => {
                'order'      => 2.7,
                'gettext_id' => 'SSL ciphers used',
                'format'     => '.+',
                'default'    => 'ALL'
            },
            'ca_verify' => {
                'order'      => 2.8,
                'gettext_id' => 'Certificate verification',
                'format'     => ['none', 'optional', 'required'],
                'synonym'    => {'require' => 'required'},
                'default'    => 'required',
                'occurrence' => '0-1'
            },
            'user' => {
                'order'      => 3,
                'gettext_id' => "remote user",
                'format'     => '.+',
            },
            'passwd' => {
                'order'      => 3.5,
                'gettext_id' => "remote password",
                'format'     => '.+',
                'field_type' => 'password',
                'length'     => 10
            },
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
                'format'     => '\w+',
                'length'     => 15
            },
            'select1' => {
                'order'      => 9,
                'gettext_id' => "first-level selection",
                'format'     => ['all', 'first', 'regex'],
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
                'default'    => 'sub'
            },
            'timeout2' => {
                'order'        => 13,
                'gettext_id'   => "second-level connection timeout",
                'gettext_unit' => 'seconds',
                'format'       => '\w+',
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
                'format'     => '\w+',
                'default'    => 'mail',
                'length'     => 15
            },
            'select2' => {
                'order'      => 16,
                'gettext_id' => "second-level selection",
                'format'     => ['all', 'first', 'regex'],
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
                'format'     => Sympa::Regexps::time_ranges(),
                'occurrence' => '0-1'
            }
        },
        'occurrence' => '0-n'
    },

    'include_sql_ca' => {
        'group'      => 'data_source',
        'gettext_id' => "SQL query custom attribute",
        'format'     => {
            'name' => {
                'order'      => 1,
                'gettext_id' => "short name for this source",
                'format'     => '.+',
                'length'     => 15
            },
            'db_type' => {
                'order'      => 1.5,
                'gettext_id' => "database type",
                'format'     => '\S+',
                'occurrence' => '1'
            },
            'host' => {
                'order'      => 2,
                'gettext_id' => "remote host",
                'format'     => Sympa::Regexps::host(),
                'occurrence' => '1'
            },
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
            'connect_options' => {
                'order'      => 4.5,
                'gettext_id' => "connection options",
                'format'     => '.+'
            },
            'db_env' => {
                'order' => 5,
                'gettext_id' =>
                    "environment variables for database connection",
                'format' => '\w+\=\S+(;\w+\=\S+)*'
            },
            'user' => {
                'order'      => 6,
                'gettext_id' => "remote user",
                'format'     => '\S+',
                'occurrence' => '1'
            },
            'passwd' => {
                'order'      => 7,
                'gettext_id' => "remote password",
                'format'     => '.+',
                'field_type' => 'password'
            },
            'sql_query' => {
                'order'      => 8,
                'gettext_id' => "SQL query",
                'format'     => Sympa::Regexps::sql_query(),
                'occurrence' => '1',
                'length'     => 50
            },
            'f_dir' => {
                'order' => 9,
                'gettext_id' =>
                    "Directory where the database is stored (used for DBD::CSV only)",
                'format' => '.+'
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
                'format'     => Sympa::Regexps::time_ranges(),
                'occurrence' => '0-1'
            }
        },
        'occurrence' => '0-n'
    },

    ### DKIM page ###

    'dkim_feature' => {
        'group'      => 'dkim',
        'gettext_id' => "Insert DKIM signature to messages sent to the list",
        'gettext_comment' =>
            "Enable/Disable DKIM. This feature require Mail::DKIM to installed and may be some custom scenario to be updated",
        'format'     => ['on', 'off'],
        'occurrence' => '0-1',
        'default' => {'conf' => 'dkim_feature'}
    },

    'dkim_parameters' => {
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
                'order' => 4,
                'gettext_id' =>
                    'List of headers to be included ito the message for signature',
                'gettext_comment' =>
                    'You should probably use the default value which is the value recommended by RFC4871',
                'format'     => '\S+',
                'occurrence' => '0-1',
                'default'    => {'conf' => 'dkim_header_list'},
                'obsolete'   => 1,
            },
            'signer_domain' => {
                'order' => 5,
                'gettext_id' =>
                    'DKIM "d=" tag, you should probably use the default value',
                'gettext_comment' =>
                    'The DKIM "d=" tag, is the domain of the signing entity. the list domain MUST be included in the "d=" domain',
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

    'dmarc_protection' => {
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
                    'Select one or more operation modes.  "Domain matching regular expression" (domain_regex) matches the specified Domain regexp; "DKIM signature exists" (dkim_signature) matches any message with a DKIM signature header; "DMARC policy ..." (dmarc_*) matches messages from sender domains with a DMARC policy as given; "all" (all) matches all messages.',
                'order' => 1
            },
            'domain_regex' => {
                'format'          => '.+',
                'gettext_id'      => "Match domain regexp",
                'occurrence'      => '0-1',
                'gettext_comment' => 'Regexp match pattern for From domain',
                'order'           => 2,
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
                'default' => {'conf' => 'dmarc_protection_phrase'},
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
        'group'        => 'other',
        'gettext_id'   => "Expiration of unmoderated messages",
        'gettext_unit' => 'days',
        'format'       => '\d+',
        'length'       => 3,
        'default'      => {'conf' => 'clean_delay_queuemod'}
    },

    'cookie' => {
        'group'      => 'other',
        'gettext_id' => "Secret string for generating unique keys",
        'format'     => '\S+',
        'length'     => 15,
        'default'    => {'conf' => 'cookie'}
    },

    'custom_vars' => {
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
        'group'      => 'other',
        'gettext_id' => "Periodical subscription expiration task",
        'task'       => 'expire'
    },

    'latest_instantiation' => {
        'group'      => 'other',
        'gettext_id' => 'Latest family instantiation',
        'format'     => {
            'email' => {
                'order'      => 1,
                'gettext_id' => 'who ran the instantiation',
                'format'     => 'listmaster|' . Sympa::Regexps::email(),
                'occurrence' => '0-1'
            },
            'date' => {
                'order'      => 2,
                'gettext_id' => 'date',
                'format'     => '.+'
            },
            'date_epoch' => {
                'order'      => 3,
                'gettext_id' => 'epoch date',
                'format'     => '\d+',
                'occurrence' => '1'
            }
        },
        'internal' => 1
    },

    'loop_prevention_regex' => {
        'group' => 'other',
        'gettext_id' =>
            "Regular expression applied to prevent loops with robots",
        'format'  => '\S*',
        'length'  => 70,
        'default' => {'conf' => 'loop_prevention_regex'}
    },

    'pictures_feature' => {
        'group' => 'other',
        'gettext_id' =>
            "Allow picture display? (must be enabled for the current robot)",
        'format'     => ['on', 'off'],
        'occurrence' => '0-1',
        'default' => {'conf' => 'pictures_feature'}
    },

    'remind_task' => {
        'group'      => 'other',
        'gettext_id' => 'Periodical subscription reminder task',
        'task'       => 'remind',
        'default'    => {'conf' => 'default_remind_task'}
    },

    'spam_protection' => {
        'group'      => 'other',
        'gettext_id' => "email address protection method",
        'format'     => ['at', 'javascript', 'none'],
        'default'    => 'javascript'
    },

    'creation' => {
        'group'      => 'other',
        'gettext_id' => "Creation of the list",
        'format'     => {
            'date_epoch' => {
                'order'      => 3,
                'gettext_id' => "epoch date",
                'format'     => '\d+',
                'occurrence' => '1'
            },
            'date' => {
                'order'      => 2,
                'gettext_id' => "human readable",
                'format'     => '.+'
            },
            'email' => {
                'order'      => 1,
                'gettext_id' => "who created the list",
                'format'     => 'listmaster|' . Sympa::Regexps::email(),
                'occurrence' => '1'
            }
        },
        'occurrence' => '0-1',
        'internal'   => 1
    },

    'update' => {
        'group'      => 'other',
        'gettext_id' => "Last update of config",
        'format'     => {
            'email' => {
                'order'      => 1,
                'gettext_id' => 'who updated the config',
                'format'     => '(listmaster|automatic|'
                    . Sympa::Regexps::email() . ')',
                'occurrence' => '0-1',
                'length'     => 30
            },
            'date' => {
                'order'      => 2,
                'gettext_id' => 'date',
                'format'     => '.+',
                'length'     => 30
            },
            'date_epoch' => {
                'order'      => 3,
                'gettext_id' => 'epoch date',
                'format'     => '\d+',
                'occurrence' => '1',
                'length'     => 8
            }
        },
        'internal' => 1,
    },

    'status' => {
        'group'      => 'other',
        'gettext_id' => "Status of the list",
        'format' =>
            ['open', 'closed', 'pending', 'error_config', 'family_closed'],
        'default'  => 'open',
        'internal' => 1
    },

    'serial' => {
        'group'      => 'other',
        'gettext_id' => "Serial number of the config",
        'format'     => '\d+',
        'default'    => 0,
        'internal'   => 1,
        'length'     => 3
    },

    'custom_attribute' => {
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
                'format'     => ['required', 'optional']
            }
        },
        'occurrence' => '0-n'
    }
);

_apply_defaults();

## Apply defaults to parameters definition (%pinfo)
sub _apply_defaults {
    return if exists $default{'order'};    # already loaded

    ## Parameter order
    foreach my $index (0 .. $#param_order) {
        if ($param_order[$index] eq '*') {
            $default{'order'} = $index;
        } else {
            $pinfo{$param_order[$index]}{'order'} = $index;
        }
    }

    ## Parameters
    foreach my $p (keys %pinfo) {
        cleanup($p, $pinfo{$p});
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

    ## Scenario format
    if ($v->{'scenario'}) {
        $v->{'format'}  = Sympa::Regexps::scenario();
        $v->{'default'} = 'default';
    }

    ## Task format
    if ($v->{'task'}) {
        $v->{'format'} = Sympa::Regexps::task();
    }

    ## Datasource format
    if ($v->{'datasource'}) {
        $v->{'format'} = Sympa::Regexps::datasource();
    }

    ## Enumeration
    if (ref($v->{'format'}) eq 'ARRAY') {
        $v->{'file_format'} ||= join '|', @{$v->{'format'}};
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

        ## Scenario format
        if (ref($v->{'format'}{$k})
            && $v->{'format'}{$k}{'scenario'}) {
            $v->{'format'}{$k}{'format'}  = Sympa::Regexps::scenario();
            $v->{'format'}{$k}{'default'} = 'default'
                unless ($p eq 'web_archive' and $k eq 'access')
                or ($p eq 'archive' and $k eq 'web_access');
        }

        ## Task format
        if (ref($v->{'format'}{$k})
            && $v->{'format'}{$k}{'task'}) {
            $v->{'format'}{$k}{'format'} = Sympa::Regexps::task();
        }

        ## Datasource format
        if (ref($v->{'format'}{$k})
            && $v->{'format'}{$k}{'datasource'}) {
            $v->{'format'}{$k}{'format'} = Sympa::Regexps::datasource();
        }

        ## Enumeration
        if (ref($v->{'format'}{$k}{'format'}) eq 'ARRAY') {
            $v->{'file_format'}{$k}{'file_format'} ||= join '|',
                @{$v->{'format'}{$k}{'format'}};
        }

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

=item %pinfo

This hash COMPLETELY defines ALL list parameters.
It is then used to load, save, view, edit list config files.

List parameters format accepts the following keywords :

=over

=item format

Regexp aplied to the configuration file entry;
some common regexps are defined in L<Sympa::Regexps>.

If the parameter is paragraph, value of this item is a hashref containing
definitions of sub-parameters.

=item file_format

Config file format of the parameter might not be
the same in memory.

=item split_char

Character used to separate multiple parameters.

=item length

Length of a scalar variable ; used in web forms.

=item scenario

Tells that the parameter is a scenario, providing its name.

=item default

Default value for the param ; may be a robot configuration
parameter (conf).

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

=item gettext_id

Title reference in NLS catalogs.

=item gettext_comment

Deescription text of a parameter.

=item group

Group of parameters.

=item obsolete

Obsolete parameter ; should not be displayed
nor saved.

=item obsolete_values

Defined obsolete values for a parameter.
These values should not get proposed on the web interface
edition form.

=item order

Order of parameters within paragraph.

=item internal

Indicates that the parameter is an internal parameter
that should always be saved in the config file.

=item field_type

Used to select passwords web input type.

=back

=item @param_order

XXX

=back

=head1 SEE ALSO

L<config(5)>.

=cut
