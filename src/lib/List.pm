# list.pm - This module includes all list processing functions
# RCS Identication ; $Revision$ ; $Date$ 
#
# Sympa - SYsteme de Multi-Postage Automatique
# Copyrigh (c) 1997, 1998, 1999, 2000, 2001 Comite Reseau des Universites
# Copyright (c) 1997,1998, 1999 Institut Pasteur & Christophe Wolfhugel
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
# You should have received a copy of the GNU General Public License# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

package List;

use strict;
use POSIX;
use SQLSource;
use Datasource;
use LDAPSource;
use SDM;
use SQLSource qw(create_db);
use Upgrade;
use Lock;
use Task;
use Scenario;
use Fetch;
use WebAgent;
use Exporter;
use Data::Dumper;
# xxxxxxx faut-il virer encode ? Faut en faire un use ? 
require Encode;

use tt2;
use Sympa::Constants;

our @ISA = qw(Exporter);
our @EXPORT = qw(%list_of_lists);

use Fcntl qw(LOCK_SH LOCK_EX LOCK_NB LOCK_UN);

=head1 CONSTRUCTOR

=item new( [PHRASE] )

 List->new();

Creates a new object which will be used for a list and
eventually loads the list if a name is given. Returns
a List object.

=back

=head1 METHODS

=over 4

=item load ( LIST )

Loads the indicated list into the object.

=item save ( LIST )

Saves the indicated list object to the disk files.

=item savestats ()

Saves updates the statistics file on disk.

=item update_stats( BYTES )

Updates the stats, argument is number of bytes, returns the next
sequence number. Does nothing if no stats.

=item send_sub_to_owner ( WHO, COMMENT )
Send a message to the list owners telling that someone
wanted to subscribe to the list.

=item send_to_editor ( MSG )
    
Send a Mail::Internet type object to the editor (for approval).

=item send_msg ( MSG )

Sends the Mail::Internet message to the list.

=item send_file ( FILE, USER, GECOS )

Sends the file to the USER. FILE may only be welcome for now.

=item delete_list_member ( ARRAY )

Delete the indicated users from the list.
 
=item delete_list_admin ( ROLE, ARRAY )

Delete the indicated admin user with the predefined role from the list.

=item get_cookie ()

Returns the cookie for a list, if available.

=item get_max_size ()

Returns the maximum allowed size for a message.

=item get_reply_to ()

Returns an array with the Reply-To values.

=item get_default_user_options ()

Returns a default option of the list for subscription.

=item get_total ()

Returns the number of subscribers to the list.

=item get_global_user ( USER )

Returns a hash with the information regarding the indicated
user.

=item get_list_member ( USER )

Returns a subscriber of the list.

=item get_list_admin ( ROLE, USER)

Return an admin user of the list with predefined role

=item get_first_list_member ()

Returns a hash to the first user on the list.

=item get_first_list_admin ( ROLE )

Returns a hash to the first admin user with predefined role on the list.

=item get_next_list_member ()

Returns a hash to the next users, until we reach the end of
the list.

=item get_next_list_admin ()

Returns a hash to the next admin users, until we reach the end of
the list.

=item update_list_member ( USER, HASHPTR )

Sets the new values given in the hash for the user.

=item update_list_admin ( USER, ROLE, HASHPTR )

Sets the new values given in the hash for the admin user.

=item add_list_member ( USER, HASHPTR )

Adds a new user to the list. May overwrite existing
entries.

=item add_admin_user ( USER, ROLE, HASHPTR )

Adds a new admin user to the list. May overwrite existing
entries.

=item is_list_member ( USER )

Returns true if the indicated user is member of the list.
 
=item am_i ( FUNCTION, USER )

Returns true is USER has FUNCTION (owner, editor) on the
list.

=item get_state ( FLAG )

Returns the value for a flag : sig or sub.

=item may_do ( ACTION, USER )

Chcks is USER may do the ACTION for the list. ACTION can be
one of following : send, review, index, getm add, del,
reconfirm, purge.

=item is_moderated ()

Returns true if the list is moderated.

=item archive_exist ( FILE )

Returns true if the indicated file exists.

=item archive_send ( WHO, FILE )

Send the indicated archive file to the user, if it exists.

=item archive_ls ()

Returns the list of available files, if any.

=item archive_msg ( MSG )

Archives the Mail::Internet message given as argument.

=item is_archived ()

Returns true is the list is configured to keep archives of
its messages.

=item get_stats ( OPTION )

Returns either a formatted printable strings or an array whith
the statistics. OPTION can be 'text' or 'array'.

=item print_info ( FDNAME )

Print the list information to the given file descriptor, or the
currently selected descriptor.

=cut

use Carp;

use IO::Scalar;
use Storable;
use Mail::Header;
use Archive;
use Language;
use Log;
use Conf;
use mail;
use Ldap;
use Time::Local;
use MIME::Entity;
use MIME::EncWords;
use MIME::Parser;
use Message;
use Family;
use PlainDigest;


## Database and SQL statement handlers
my ($sth, @sth_stack);

my %list_cache;

## DB fields with numeric type
## We should not do quote() for these while inserting data
my %numeric_field = ('cookie_delay_user' => 1,
		     'bounce_score_subscriber' => 1,
		     'subscribed_subscriber' => 1,
		     'included_subscriber' => 1,
		     'subscribed_admin' => 1,
		     'included_admin' => 1,
		     'wrong_login_count' => 1,
		      );
		      
## List parameters defaults
my %default = ('occurrence' => '0-1',
	       'length' => 25
	       );

my @param_order = qw (subject visibility info subscribe add unsubscribe del owner owner_include
		      send editor editor_include delivery_time account topics 
		      host lang web_archive archive digest digest_max_size available_user_options 
		      default_user_options msg_topic msg_topic_keywords_apply_on msg_topic_tagging reply_to_header reply_to forced_reply_to * 
		      verp_rate tracking welcome_return_path remind_return_path user_data_source include_file include_remote_file 
		      include_list include_remote_sympa_list include_ldap_query
                      include_ldap_2level_query include_sql_query include_admin ttl distribution_ttl creation update 
		      status serial custom_attribute);

## List parameters aliases
my %alias = ('reply-to' => 'reply_to',
	     'replyto' => 'reply_to',
	     'forced_replyto' => 'forced_reply_to',
	     'forced_reply-to' => 'forced_reply_to',
	     'custom-subject' => 'custom_subject',
	     'custom-header' => 'custom_header',
	     'subscription' => 'subscribe',
	     'unsubscription' => 'unsubscribe',
	     'max-size' => 'max_size');

##############################################################
## This hash COMPLETELY defines ALL list parameters     
## It is then used to load, save, view, edit list config files
##############################################################
## List parameters format accepts the following keywords :
## format :      Regexp aplied to the configuration file entry; 
##               some common regexps are defined in %regexp
## file_format : Config file format of the parameter might not be
##               the same in memory
## split_char:   Character used to separate multiple parameters 
## length :      Length of a scalar variable ; used in web forms
## scenario :    tells that the parameter is a scenario, providing its name
## default :     Default value for the param ; may be a configuration parameter (conf)
## synonym :     Defines synonyms for parameter values (for compatibility reasons)
## gettext_unit :Unit of the parameter ; this is used in web forms and refers to translated
##               strings in PO catalogs
## occurrence :  Occurerence of the parameter in the config file
##               possible values: 0-1 | 1 | 0-n | 1-n
##               example : a list may have multiple owner 
## gettext_id :    Title reference in NLS catalogues
## description : deescription text of a parameter
## group :       Group of parameters
## obsolete :    Obsolete parameter ; should not be displayed 
##               nor saved
## obsolete_values : defined obsolete values for a parameter
##                   these values should not get proposed on the web interface edition form
## order :       Order of parameters within paragraph
## internal :    Indicates that the parameter is an internal parameter
##               that should always be saved in the config file
## field_type :  used to select passwords web input type
###############################################################
%::pinfo = ('account' => {'format' => '\S+',
			  'length' => 10,
			  'gettext_id' => "Account",
			  'group' => 'other'
			  },
	    'add' => {'scenario' => 'add',
		      'gettext_id' => "Who can add subscribers",
		      'group' => 'command'
		      },
	    'anonymous_sender' => {'format' => '.+',
				   'gettext_id' => "Anonymous sender",
				   'group' => 'sending'
				   },
	    'archive' => {'format' => {'period' => {'format' => ['day','week','month','quarter','year'],
						    'synonym' => {'weekly' => 'week'},
						    'gettext_id' => "frequency",
						    'order' => 1
						},
				       'access' => {'format' => ['open','private','public','owner','closed'],
						    'synonym' => {'open' => 'public'},
						    'gettext_id' => "access right",
						    'order' => 2
						}
				   },
			  'gettext_id' => "Text archives",
			  'group' => 'archives'
		      },
	    'archive_crypted_msg' => {'format' => ['original','decrypted'],
				    'default' => 'original',
				    'gettext_id' => "Archive encrypted mails as cleartext",
				    'group' => 'archives'
				    },
           'available_user_options' => {'format' => {'reception' => {'format' => ['mail','notice','digest','digestplain','summary','nomail','txt','html','urlize','not_me'],
								     'occurrence' => '1-n',
								     'split_char' => ',',
								     'default' => 'mail,notice,digest,digestplain,summary,nomail,txt,html,urlize,not_me',
								     'gettext_id' => "reception mode"
								     },
						     },
					 'gettext_id' => "Available subscription options",
					 'group' => 'sending'
				     },

	    'bounce' => {'format' => {'warn_rate' => {'format' => '\d+',
						      'length' => 3,
						      'gettext_unit' => '%',
						      'default' => {'conf' => 'bounce_warn_rate'},
						      'gettext_id' => "warn rate",
						      'order' => 1
						  },
				      'halt_rate' => {'format' => '\d+',
						      'length' => 3,
						      'gettext_unit' => '%',
						      'default' => {'conf' => 'bounce_halt_rate'},
						      'gettext_id' => "halt rate",
						      'order' => 2
						  }
				  },
			 'gettext_id' => "Bounces management",
			 'group' => 'bounces'
		     },
	    'bouncers_level1' => {'format' => {'rate' => {'format' => '\d+',
								 'length' => 2,
								 'gettext_unit' => 'points',
								 'default' => {'conf' => 'default_bounce_level1_rate'},
								 'gettext_id' => "threshold",
								 'order' => 1
								 },
				               'action' => {'format' => ['remove_bouncers','notify_bouncers','none'],
								   'default' => 'notify_bouncers',
								   'gettext_id' => "action for this population",
								   'order' => 2
								   },
					       'notification' => {'format' => ['none','owner','listmaster'],
									 'default' => 'owner',
									 'gettext_id' => "notification",
									 'order' => 3
									 }
					   },
				      'gettext_id' => "Management of bouncers, 1st level",
				      'group' => 'bounces'
				  },
	     'bouncers_level2' => {'format' => {'rate' => {'format' => '\d+',
								 'length' => 2,
								 'gettext_unit' => 'points',
								 'default' => {'conf' => 'default_bounce_level2_rate'},
								 'gettext_id' => "threshold",
								 'order' => 1
								 },
				               'action' => {'format' =>  ['remove_bouncers','notify_bouncers','none'],
								   'default' => 'remove_bouncers',
								   'gettext_id' => "action for this population",
								   'order' => 2
								   },
					       'notification' => {'format' => ['none','owner','listmaster'],
									 'default' => 'owner',
									 'gettext_id' => "notification",
									 'order' => 3
									 }
								     },
				      'gettext_id' => "Management of bouncers, 2nd level",
				      'group' => 'bounces'
				  },
	    'clean_delay_queuemod' => {'format' => '\d+',
				       'length' => 3,
				       'gettext_unit' => 'days',
				       'default' => {'conf' => 'clean_delay_queuemod'},
				       'gettext_id' => "Expiration of unmoderated messages",
				       'group' => 'other'
				       },
	    'cookie' => {'format' => '\S+',
			 'length' => 15,
			 'default' => {'conf' => 'cookie'},
			 'gettext_id' => "Secret string for generating unique keys",
			 'group' => 'other'
		     },
	    'tracking' => {'format' => {'delivery_status_notification' => {'format' => ['on','off'],
										'default' =>  {'conf' => 'tracking_delivery_status_notification'},
										'gettext_id' => "tracking message by delivery status notification",
										'order' => 1
									   },
					'message_delivery_notification' => {'format' => ['on','on_demand','off'],
										'default' =>  {'conf' => 'tracking_message_delivery_notification'},
										'gettext_id' => "tracking message by message delivery notification",
										'order' => 2
									   },
					'tracking' => {'scenario' => 'tracking',
						       'gettext_id' => "who can view message tracking",
						       'order' => 3 
						       },
					'retention_period' => {'format' => '\d+',
    							       'default' =>  {'conf' => 'tracking_default_retention_period'},
							       'gettext_unit' => 'days',
							       'length' => 5,
							       'gettext_id' => "Tracking datas are removed after this number of days",
							       'order' => 4 
  						               }
				        },
			   'group' => 'bounces',
			   'gettext_id' => "Message tracking feature"
			   },		
	    'creation' => {'format' => {'date_epoch' => {'format' => '\d+',
							 'occurrence' => '1',
							 'gettext_id' => "epoch date",
							 'order' => 3
						     },
					'date' => {'format' => '.+',
						   'gettext_id' => "human readable",
						   'order' => 2
						   },
					'email' => {'format' => 'listmaster|'.&tools::get_regexp('email'),
						    'occurrence' => '1',
						    'gettext_id' => "who created the list",
						    'order' => 1
						    }
				    },
			   'gettext_id' => "Creation of the list",
			   'occurrence' => '0-1',
			   'internal' => 1,
			   'group' => 'other'

		       },
	'custom_attribute' => {
		'format' => {
			'id' => {
				'format' => '\w+',
				'length' => 20,
				'gettext_id' => "internal identifier",
				'occurrence' => '1',
				'order' =>1
			},
			'name' => {
				'format' => '.+',
				'length' =>30,
				'occurrence' => '1',
				'gettext_id' => "label",
				'order' => 2
			},
			'comment' => {
				'format' => '.+',
				'length' => 100,
				'gettext_id' => "additional comment",
				'order' => 3
			},
			'type' => {
				'format' => ['string','text','integer','enum'],
				'default' => 'string',
				'occurence' => 1,
				'gettext_id' => "type",
				'order' => 4
			},
			'enum_values' => {
				'format' => '.+',
				'length' => 100,
				'gettext_id' => "possible attribute values (if enum is used)",
				'order' => 5
			},
			'optional' => {
				'format' => ['required','optional'],
				'gettext_id' => "is the attribute optional?",
				'order' => 6
			}
		
		},
		'occurrence' => '0-n',
		'gettext_id' => "Custom user attributes",
		'group' => 'other'
	},
	    'custom_header' => {'format' => '\S+:\s+.*',
				'length' => 30,
				'occurrence' => '0-n',
				'gettext_id' => "Custom header field",
				'group' => 'sending'
				},
	    'custom_subject' => {'format' => '.+',
				 'length' => 15,
				 'gettext_id' => "Subject tagging",
				 'group' => 'sending'
				 },
	    'custom_vars' => {'format' => {'name' => {'format' => '\S+',
						      'occurrence' => '1',
						      'gettext_id' => 'var name',
						      'order' => 1
						      },
					   'value' => {'format' => '\S+',
						       'occurrence' => '1',
						       'gettext_id' => 'var value',
						       'order' => 2
						       }
				       },
			      'gettext_id' => "custom parameters",
			      'occurrence' => '0-n',
			      'group' => 'other'
			      },			      

            'default_user_options' => {'format' => {'reception' => {'format' => ['digest','digestplain','mail','nomail','summary','notice','txt','html','urlize','not_me'],
								    'default' => 'mail',
								    'gettext_id' => "reception mode",
								    'order' => 1
								    },
						    'visibility' => {'format' => ['conceal','noconceal'],
								     'default' => 'noconceal',
								     'gettext_id' => "visibility",
								     'order' => 2
								     }
						},
				       'gettext_id' => "Subscription profile",
				       'group' => 'sending'
				   },
	    'del' => {'scenario' => 'del',
		      'gettext_id' => "Who can delete subscribers",
		      'group' => 'command'
		      },
	    'delivery_time' => {'format' => '[0-2]?\d\:[0-6]\d',
				'length' => 5,
				'gettext_id' => "Delivery time (hh:mm)",
				'occurrence' => '0-1',
				'group' => 'sending'
		      },
	    'digest' => {'file_format' => '\d+(\s*,\s*\d+)*\s+\d+:\d+',
			 'format' => {'days' => {'format' => [0..6],
						 'file_format' => '1|2|3|4|5|6|7',
						 'occurrence' => '1-n',
						 'gettext_id' => "days",
						 'order' => 1
						 },
				      'hour' => {'format' => '\d+',
						 'length' => 2,
						 'occurrence' => '1',
						 'gettext_id' => "hour",
						 'order' => 2
						 },
				      'minute' => {'format' => '\d+',
						   'length' => 2,
						   'occurrence' => '1',
						   'gettext_id' => "minute",
						   'order' => 3
						   }
				  },
			 'gettext_id' => "Digest frequency",
			 'group' => 'sending'
		     },

	    'digest_max_size' => {'format' => '\d+',
				  'length' => 2,
				  'gettext_unit' => 'messages',
				  'default' => 25,
				  'gettext_id' => "Digest maximum number of messages",				  
				  'group' => 'sending'
		       },	    

	    'distribution_ttl' => {'format' => '\d+',
		      'length' => 6,
		      'gettext_unit' => 'seconds',
		      'gettext_id' => "Inclusions timeout for message distribution",
		      'group' => 'data_source'
		      },

	    'dkim_feature' => {'format' => ['on','off'],
			      'occurence' => '0-1',
			      'default' => {'conf' => 'dkim_feature'},
			      'gettext_id' => "Insert DKIM signature to messages sent to the list",
			      'comment' =>  "Enable/Disable DKIM. This feature require Mail::DKIM to installed and may be some custom scenario to be updated",
			      'group' => 'dkim',
			  },
	    'dkim_signature_apply_on'=> {'format' => ['md5_authenticated_messages','smime_authenticated_messages','dkim_authenticated_messages','editor_validated_messages','none','any'],
					 'occurrence' => '0-n',
					 'split_char' => ',',
					 'default' => {'conf' => 'dkim_signature_apply_on'},
					 'gettext_id' => "The categories of messages sent to the list that will be signed using DKIM.",
					 'comment' => "This parameter controls in which case messages must be signed using DKIM, you may sign every message choosing 'any' or a subset. The parameter value is a comma separated list of keywords",
					 'group' => 'dkim',
					 },
	    'dkim_parameters'=> {'format' => {'private_key_path'=> {'format' => '\S+',
		                         			  'occurence' => '0-1',
			                                          'default' => {'conf' => 'dkim_private_key_path'},
			                                          'gettext_id' => "File path for list DKIM private key",
								  'comment' => "The file must contain a RSA pem encoded private key", 
								  'order' => 1
					                         },
					     'selector' => { 'format' => '\S+',
		                         			  'occurence' => '0-1',
			                                          'default' => {'conf' => 'dkim_selector'},
							          'comment' => "The selector is used in order to build the DNS query for public key. It is up to you to choose the value you want but verify that you can query the public DKIM key for <selector>._domainkey.your_domain",
			                                          'gettext_id' => "Selector for DNS lookup of DKIM public key",
								  'order' => 2
                                                                  },
							          
					     'header_list'=>      { 'format' => '\S+',
		                         			  'occurence' => '0-1',
			                                          'default' => {'conf' => 'dkim_header_list'},
			                                          'gettext_id' => 'List of headers to be included ito the message for signature',
								  'comment' => 'You should probably use teh default value which is the value recommended by RFC4871',
								  'order' => 4
                                                                  },
					     'signer_domain' =>   {'format' => '\S+',
		                         			  'occurence' => '0-1',
			                                          'default' => {'conf' => 'dkim_signer_domain'},
			                                          'gettext_id' => 'DKIM "d=" tag, you should probably use the default value',
								   'omment' => ' The DKIM "d=" tag, is the domain of the signing entity. the list domain MUST must be included in the "d=" domain',
								  'order' => 5
								 },
                                             'signer_identity'=>  {'format' => '\S+',
		                         			  'occurence' => '0-1',
								  'comment' => 'DKIM "i=" tag, you should probably not use this parameter, as recommended by RFC 4871, default for list brodcasted messages is i=<listname>-request@<domain>',
			                                          'gettext_id' => 'DKIM "i=" tag, you should probably leave this parameter empty',
								  'order' => 6
								 },
					     },
			      'group' => 'dkim',
			      'comment' => 'A set of parameters in order to define outgoing DKIM signature', 
			      'occurrence' => '0-1',
			      'gettext_id' => "DKIM configuration",
			  },
			      
	    'editor' => {'format' => {'email' => {'format' => &tools::get_regexp('email'),
						  'length' => 30,
						  'occurrence' => '1',
						  'gettext_id' => "email address",
						  'order' => 1
						  },
				      'reception' => {'format' => ['mail','nomail'],
						      'default' => 'mail',
						      'gettext_id' => "reception mode",
						      'order' => 4
						      },
				      'visibility' => {'format' => ['conceal','noconceal'],
						      'default' => 'noconceal',
						      'gettext_id' => "visibility",
						      'order' => 5
						      },
				      'gecos' => {'format' => '.+',
						  'length' => 30,
						  'gettext_id' => "name",
						  'order' => 2
						  },
				      'info' => {'format' => '.+',
						 'length' => 30,
						 'gettext_id' => "private information",
						 'order' => 3
						 }
				  },
			 'occurrence' => '0-n',
			 'gettext_id' => "Moderators",
			 'group' => 'description'
			 },
	    'editor_include' => {'format' => {'source' => {'datasource' => 1,
							   'occurrence' => '1',
							   'gettext_id' => 'the data source',
							   'order' => 1
							   },
					      'source_parameters' => {'format' => '.*',
								      'occurrence' => '0-1',
								      'gettext_id' => 'data source parameters',
								      'order' => 2
    								      },
					      'reception' => {'format' => ['mail','nomail'],
							      'default' => 'mail',
							      'gettext_id' => 'reception mode',
							       'order' => 3
							      },
				              'visibility' => {'format' => ['conceal','noconceal'],
							       'default' => 'noconceal',
							       'gettext_id' => "visibility",
							       'order' => 5
					                      }
					      
					      },
				  'occurrence' => '0-n',
				  'gettext_id' => 'Moderators defined in an external data source',
				  'group' => 'description',
			      },
	    'expire_task' => {'task' => 'expire',
			      'gettext_id' => "Periodical subscription expiration task",
			      'group' => 'other'
			 },
 	    'family_name' => {'format' => &tools::get_regexp('family_name'),
 			      'occurrence' => '0-1',
 			      'gettext_id' => 'Family name',
			      'internal' => 1,
 			      'group' => 'description'
 			      },
	    'footer_type' => {'format' => ['mime','append'],
			      'default' => 'mime',
			      'gettext_id' => "Attachment type",
			      'group' => 'sending'
			      },
	    'forced_reply_to' => {'format' => '\S+',
				  'gettext_id' => "Forced reply address",
				  'obsolete' => 1
			 },
	    'host' => {'format' => &tools::get_regexp('host'),
		       'length' => 20,
		       'default' => {'conf' => 'host'},
		       'gettext_id' => "Internet domain",
		       'group' => 'description'
		   },
	    'include_file' => {'format' => '\S+',
			       'length' => 20,
			       'occurrence' => '0-n',
			       'gettext_id' => "File inclusion",
			       'group' => 'data_source'
			       },
	    'include_remote_file' => {'format' => {'url' => {'format' => '.+',
							     'gettext_id' => "data location URL",
							     'occurrence' => '1',
							     'length' => 50,
							     'order' => 2
							     },					       
						   'user' => {'format' => '.+',
							      'gettext_id' => "remote user",
							      'order' => 3,
							      'occurrence' => '0-1'
							      },
						   'passwd' => {'format' => '.+',
								'length' => 10,
								'field_type' => 'password',
								'gettext_id' => "remote password",
								'order' => 4,
								'occurrence' => '0-1'
								},							      
						    'name' => {'format' => '.+',
							       'gettext_id' => "short name for this source",
							       'length' => 15,
							       'order' => 1
							       }
						     },
				      'gettext_id' => "Remote file inclusion",
				      'occurrence' => '0-n',
				      'group' => 'data_source'
				      },				  
	    'include_ldap_query' => {'format' => {'host' => {'format' => &tools::get_regexp('multiple_host_with_port'),
							     'occurrence' => '1',
							     'gettext_id' => "remote host",
							     'order' => 2
							     },
						  'port' => {'format' => '\d+',
							     'length' => 4,
							     'gettext_id' => "remote port",
							     'obsolete' => 1,
							     'order' => 2
							     },
						  'user' => {'format' => '.+',
							     'gettext_id' => "remote user",
							     'order' => 3
							     },
						  'passwd' => {'format' => '.+',
							       'length' => 10,
							       'field_type' => 'password',
							       'gettext_id' => "remote password",
							       'order' => 3
							       },
						  'suffix' => {'format' => '.+',
							       'gettext_id' => "suffix",
							       'order' => 4
							       },
						  'filter' => {'format' => '.+',
							       'length' => 50,
							       'occurrence' => '1',
							       'gettext_id' => "filter",
							       'order' => 7
							       },
						  'attrs' => {'format' => '\w+',
							      'length' => 15,
							      'default' => 'mail',
							      'gettext_id' => "extracted attribute",
							      'order' => 8
							      },
						  'select' => {'format' => ['all','first'],
							       'default' => 'first',
							       'gettext_id' => "selection (if multiple)",
							       'order' => 9
							       },
					          'scope' => {'format' => ['base','one','sub'],
							      'default' => 'sub',
							      'gettext_id' => "search scope",
							      'order' => 5
							      },
						  'timeout' => {'format' => '\w+',
								'default' => 30,
								'gettext_unit' => 'seconds',
								'gettext_id' => "connection timeout",
								'order' => 6
								},
						   'name' => {'format' => '.+',
							      'gettext_id' => "short name for this source",
							      'length' => 15,
							      'order' => 1
							      },
							      'use_ssl' => {'format' => ['yes','no'],
									    'default' => 'no',
									    'gettext_id' => 'use SSL (LDAPS)',
									    'order' => 2.5,
									},
							      'ssl_version' => {'format' => ['sslv2','sslv3','tls'],
										'default' => 'sslv3',
										'gettext_id' => 'SSL version',
										'order' => 2.5,
									    },
							      'ssl_ciphers' => {'format' => '.+',
										'default' => 'ALL',
										'gettext_id' => 'SSL ciphers used',
										'order' => 2.5,
									   },
							      
							      
									    
					      },
				     'occurrence' => '0-n',
				     'gettext_id' => "LDAP query inclusion",
				     'group' => 'data_source'
				     },
	    'include_ldap_2level_query' => {'format' => {'host' => {'format' => &tools::get_regexp('multiple_host_with_port'),
							     'occurrence' => '1',
							     'gettext_id' => "remote host",
							     'order' => 1
							     },
						  'port' => {'format' => '\d+',
							     'length' => 4,
							     'gettext_id' => "remote port",
							     'obsolete' => 1,
							     'order' => 2
							     },
						  'user' => {'format' => '.+',
							     'gettext_id' => "remote user",
							     'order' => 3
							     },
						  'passwd' => {'format' => '.+',
							       'length' => 10,
							       'field_type' => 'password',
							       'gettext_id' => "remote password",
							       'order' => 3
							       },
						  'suffix1' => {'format' => '.+',
							       'gettext_id' => "first-level suffix",
							       'order' => 4
							       },
						  'filter1' => {'format' => '.+',
							       'length' => 50,
							       'occurrence' => '1',
							       'gettext_id' => "first-level filter",
							       'order' => 7
							       },
						  'attrs1' => {'format' => '\w+',
							      'length' => 15,
							      'gettext_id' => "first-level extracted attribute",
							      'order' => 8
							      },
						  'select1' => {'format' => ['all','first','regex'],
							       'default' => 'first',
							       'gettext_id' => "first-level selection",
							       'order' => 9
							       },
					          'scope1' => {'format' => ['base','one','sub'],
							      'default' => 'sub',
							      'gettext_id' => "first-level search scope",
							      'order' => 5
							      },
						  'timeout1' => {'format' => '\w+',
								'default' => 30,
								'gettext_unit' => 'seconds',
								'gettext_id' => "first-level connection timeout",
								'order' => 6
								},
						  'regex1' => {'format' => '.+',
								'length' => 50,
								'default' => '',
								'gettext_id' => "first-level regular expression",
								'order' => 10
								},
						  'suffix2' => {'format' => '.+',
							       'gettext_id' => "second-level suffix template",
							       'order' => 11
							       },
						  'filter2' => {'format' => '.+',
							       'length' => 50,
							       'occurrence' => '1',
							       'gettext_id' => "second-level filter template",
							       'order' => 14
							       },
						  'attrs2' => {'format' => '\w+',
							      'length' => 15,
							      'default' => 'mail',
							      'gettext_id' => "second-level extracted attribute",
							      'order' => 15
							      },
						  'select2' => {'format' => ['all','first','regex'],
							       'default' => 'first',
							       'gettext_id' => "second-level selection",
							       'order' => 16
							       },
					          'scope2' => {'format' => ['base','one','sub'],
							      'default' => 'sub',
							      'gettext_id' => "second-level search scope",
							      'order' => 12
							      },
						  'timeout2' => {'format' => '\w+',
								'default' => 30,
								'gettext_unit' => 'seconds',
								'gettext_id' => "second-level connection timeout",
								'order' => 13
								},
						  'regex2' => {'format' => '.+',
								'length' => 50,
								'default' => '',
								'gettext_id' => "second-level regular expression",
								'order' => 17
								},
						   'name' => {'format' => '.+',
							      'gettext_id' => "short name for this source",
							      'length' => 15,
							      'order' => 1
							      },
							      'use_ssl' => {'format' => ['yes','no'],
									    'default' => 'no',
									    'gettext_id' => 'use SSL (LDAPS)',
									    'order' => 2.5,
									},
							      'ssl_version' => {'format' => ['sslv2','sslv3','tls'],
										'default' => '',
										'gettext_id' => 'SSL version',
										'order' => 2.5,
									    },
							      'ssl_ciphers' => {'format' => '.+',
										'default' => 'ALL',
										'gettext_id' => 'SSL ciphers used',
										'order' => 2.5,
									    },

					      },
				     'occurrence' => '0-n',
				     'gettext_id' => "LDAP 2-level query inclusion",
				     'group' => 'data_source'
				     },
	    'include_list' => {'format' => &tools::get_regexp('listname').'(\@'.&tools::get_regexp('host').')?',
			       'occurrence' => '0-n',
			       'gettext_id' => "List inclusion",
			       'group' => 'data_source'
			       },
	    'include_remote_sympa_list' => {'format' => {'host' => {'format' => &tools::get_regexp('host'),
							    'occurrence' => '1',
							    'gettext_id' => "remote host",
							    'order' => 1
							    },
							 'port' => {'format' => '\d+',
							     'default' => 443,
							     'length' => 4,
							     'gettext_id' => "remote port",
							     'order' => 2
							     },
							 'path' => {'format' => '\S+',
			                                     'length' => 20,
			                                     'occurrence' => '1',
			                                     'gettext_id' => "remote path of sympa list dump",
							     'order' => 3 

			                                     },
                                                         'cert' => {'format' => ['robot','list'],
							           'gettext_id' => "certificate for authentication by remote Sympa",
								   'default' => 'list',
								    'order' => 4
								    },
							   'name' => {'format' => '.+',
								      'gettext_id' => "short name for this source",
								      'length' => 15,
								      'order' => 1
								      }
					},

			       'occurrence' => '0-n',
			       'gettext_id' => "remote list inclusion",
			       'group' => 'data_source'
			       },
	    'include_sql_query' => {'format' => {'db_type' => {'format' => '\S+',
							       'occurrence' => '1',
							       'gettext_id' => "database type",
							       'order' => 1
							       },
						 'host' => {'format' => &tools::get_regexp('host'),
							    'occurrence' => '1',
							    'gettext_id' => "remote host",
							    'order' => 2
							    },
						 'db_port' => {'format' => '\d+',
							       'gettext_id' => "database port",
							       'order' => 3 
							       },
					         'db_name' => {'format' => '\S+',
							       'occurrence' => '1',
							       'gettext_id' => "database name",
							       'order' => 4 
							       },
						 'connect_options' => {'format' => '.+',
								       'gettext_id' => "connection options",
								       'order' => 4
								       },
						 'db_env' => {'format' => '\w+\=\S+(;\w+\=\S+)*',
							      'order' => 5,
							      'gettext_id' => "environment variables for database connection"
							      },
						 'user' => {'format' => '\S+',
							    'occurrence' => '1',
							    'gettext_id' => "remote user",
							    'order' => 6
							    },
						 'passwd' => {'format' => '.+',
							      'field_type' => 'password',
							      'gettext_id' => "remote password",
							      'order' => 7
							      },
						 'sql_query' => {'format' => &tools::get_regexp('sql_query'),
								 'length' => 50,
								 'occurrence' => '1',
								 'gettext_id' => "SQL query",
								 'order' => 8
								 },
						  'f_dir' => {'format' => '.+',
							     'gettext_id' => "Directory where the database is stored (used for DBD::CSV only)",
							     'order' => 9
							     },
						  'name' => {'format' => '.+',
							     'gettext_id' => "short name for this source",
							     'length' => 15,
							     'order' => 1
							     }
						 
					     },
				    'occurrence' => '0-n',
				    'gettext_id' => "SQL query inclusion",
				    'group' => 'data_source'
				    },
	    'inclusion_notification_feature' => {'format' => ['on','off'],
						 'occurence' => '0-1',
						 'default' => 'off',
						 'gettext_id' => "Notify subscribers when they are included from a data source?",
						 'group' => 'data_source',
					     },
	    'info' => {'scenario' => 'info',
		       'gettext_id' => "Who can view list information",
		       'group' => 'command'
		       },
	    'invite' => {'scenario' => 'invite',
			 'gettext_id' => "Who can invite people",
			 'group' => 'command'
			 },
	    'lang' => {'format' => [], ## &Language::GetSupportedLanguages() called later
		       'file_format' => '\w+',
		       'default' => {'conf' => 'lang'},
		       'gettext_id' => "Language of the list",
		       'group' => 'description'
		   },
 	    'latest_instantiation' => {'format' => {'date_epoch' => {'format' => '\d+',
 								     'occurrence' => '1',
 								     'gettext_id' => 'epoch date',
 								     'order' => 3
 								     },
 						    'date' => {'format' => '.+',
 							       'gettext_id' => 'date',
 							       'order' => 2
 							       },
 						    'email' => {'format' => 'listmaster|'.&tools::get_regexp('email'),
 								'occurrence' => '0-1',
 								'gettext_id' => 'who ran the instantiation',
 								'order' => 1
 								}
 						},
 				       'gettext_id' => 'Latest family instantiation',
				       'internal' => 1,
				       'group' => 'other'
 				       },
	    'loop_prevention_regex' => {'format' => '\S*',
					'length' => 70,
					'default' => {'conf' => 'loop_prevention_regex'},
					'gettext_id' => "Regular expression applied to prevent loops with robots",
					'group' => 'other'
					},
	    'max_size' => {'format' => '\d+',
			   'length' => 8,
			   'gettext_unit' => 'bytes',
			   'default' => {'conf' => 'max_size'},
			   'gettext_id' => "Maximum message size",
			   'group' => 'sending'
		       },
	    'msg_topic' => {'format' => {'name' => {'format' => '[\-\w]+',
						    'length' => 15,
						    'occurrence' => '1',
						    'gettext_id' => "Message topic name",
						    'order' => 1		
						    }, 
  					 'keywords' => {'format' => '[^,\n]+(,[^,\n]+)*',
							'occurrence' => '0-1',
							'gettext_id' => "Message topic keywords",
							'order' => 2		
							},
				         'title' => {'format' => '.+',
						     'length' => 35,
						     'occurrence' => '1',
						     'gettext_id' => "Message topic title",
						     'order' => 3		
						     }
				         },
			    'occurrence' => '0-n',
			    'gettext_id' => "Topics for message categorization",
			    'group' => 'sending'
			    },
	    'msg_topic_keywords_apply_on' => { 'format' => ['subject','body','subject_and_body'],
					       'occurrence' => '0-1',
					       'default' => 'subject',
					       'gettext_id' => "Defines to which part of messages topic keywords are applied",
					       'group' => 'sending'
					     },    

	    'msg_topic_tagging' => { 'format' => ['required_sender','required_moderator','optional'],
				      'occurrence' => '0-1',
				      'default' => 'optional',
				      'gettext_id' => "Message tagging",
				      'group' => 'sending'
				      },    	       				   
	    'owner' => {'format' => {'email' => {'format' => &tools::get_regexp('email'),
						 'length' =>30,
						 'occurrence' => '1',
						 'gettext_id' => "email address",
						 'order' => 1
						 },
				     'reception' => {'format' => ['mail','nomail'],
						     'default' => 'mail',
						     'gettext_id' => "reception mode",
						     'order' =>5
						     },
				     'visibility' => {'format' => ['conceal','noconceal'],
						      'default' => 'noconceal',
						      'gettext_id' => "visibility",
						      'order' => 6
				                     },
				     'gecos' => {'format' => '.+',
						 'length' => 30,
						 'gettext_id' => "name",
						 'order' => 2
						 },
				     'info' => {'format' => '.+',
						'length' => 30,
						'gettext_id' => "private information",
						'order' => 3
						},
				     'profile' => {'format' => ['privileged','normal'],
						   'default' => 'normal',
						   'gettext_id' => "profile",
						   'order' => 4
						   }
				 },
			'occurrence' => '1-n',
			'gettext_id' => "Owner",
			'group' => 'description'
			},
	    'owner_include' => {'format' => {'source' => {'datasource' => 1,
							  'occurrence' => '1',
							  'gettext_id' => 'the datasource',
							  'order' => 1
							  },
					     'source_parameters' => {'format' => '.*',
								     'occurrence' => '0-1',
								     'gettext_id' => 'datasource parameters',
								     'order' => 2
						      },
					     'reception' => {'format' => ['mail','nomail'],
							     'default' => 'mail',
							     'gettext_id' => 'reception mode',
							     'order' => 4
							 },
				             'visibility' => {'format' => ['conceal','noconceal'],
							      'default' => 'noconceal',
							      'gettext_id' => "visibility",
							      'order' => 5
				                             },
					     'profile' => {'format' => ['privileged','normal'],
							   'default' => 'normal',
							   'gettext_id' => 'profile',
							    'order' => 3
						       }
					 },
				'occurrence' => '0-n',
				'gettext_id' => 'Owners defined in an external data source',
				'group' => 'description',
			    },
	    'priority' => {'format' => [0..9,'z'],
			   'length' => 1,
			   'default' => {'conf' => 'default_list_priority'},
			   'gettext_id' => "Priority",
			   'group' => 'description'
		       },
	    'reject_mail_from_automates_feature' => {'format' => ['on','off'],
						     'occurence' => '0-1',
						     'default' => {'conf' => 'reject_mail_from_automates_feature'},
			       'gettext_id' => "Reject mail from automates (crontab, etc)?",
			       'group' => 'sending'
			       },	
	    'remind' => {'scenario' => 'remind',
			 'gettext_id' => "Who can start a remind process",
			 'group' => 'command'
			  },
	    'remind_return_path' => {'format' => ['unique','owner'],
				     'default' => {'conf' => 'remind_return_path'},
				     'gettext_id' => "Return-path of the REMIND command",
				     'group' => 'bounces'
				 },
	    'remind_task' => {'task' => 'remind',
			      'gettext_id' => 'Periodical subscription reminder task',
			      'default' => {'conf' => 'default_remind_task'},
			      'group' => 'other'
			      },
	    'remove_headers' => {'format' => '\S+',
				 'gettext_id' => 'Incoming SMTP header fields to be removed',
				 'default' => {'conf' => 'remove_headers'},
				 'group' => 'sending',
				 'occurrence' => '0-n',
				 'split_char' => ',',
				 },
	    'remove_outgoing_headers' => {'format' => '\S+',
					  'gettext_id' => 'Outgoing SMTP header fields to be removed',
					  'default' => {'conf' => 'remove_outgoing_headers'},
					  'group' => 'sending',
					  'occurrence' => '0-n',
					  'split_char' => ',',
					  },
	    'reply_to' => {'format' => '\S+',
			   'default' => 'sender',
			   'gettext_id' => "Reply address",
			   'group' => 'sending',
			   'obsolete' => 1
			   },
	    'reply_to_header' => {'format' => {'value' => {'format' => ['sender','list','all','other_email'],
							   'default' => 'sender',
							   'gettext_id' => "value",
							   'occurrence' => '1',
							   'order' => 1
							   },
					       'other_email' => {'format' => &tools::get_regexp('email'),
								 'gettext_id' => "other email address",
								 'order' => 2
								 },
					       'apply' => {'format' => ['forced','respect'],
							   'default' => 'respect',
							   'gettext_id' => "respect of existing header field",
							   'order' => 3
							   }
					   },
				  'gettext_id' => "Reply address",
				  'group' => 'sending'
				  },		
	    'review' => {'scenario' => 'review',
			 'synonym' => {'open' => 'public'},
			 'gettext_id' => "Who can review subscribers",
			 'group' => 'command'
			 },
	    'rfc2369_header_fields' => {'format' => ['help','subscribe','unsubscribe','post','owner','archive'],
					'default' => {'conf' => 'rfc2369_header_fields'},
					'occurrence' => '0-n',
					'split_char' => ',',
					'gettext_id' => "RFC 2369 Header fields",
					'group' => 'sending'
					},
	    'send' => {'scenario' => 'send',
		       'gettext_id' => "Who can send messages",
		       'group' => 'sending'
		       },
	    'serial' => {'format' => '\d+',
			 'default' => 0,
			 'length' => 3,
			 'default' => 0,
			 'gettext_id' => "Serial number of the config",
			 'internal' => 1,
			 'group' => 'other'
			 },
	    'shared_doc' => {'format' => {'d_read' => {'scenario' => 'd_read',
						       'gettext_id' => "Who can view",
						       'order' => 1
						       },
					  'd_edit' => {'scenario' => 'd_edit',
						       'gettext_id' => "Who can edit",
						       'order' => 2
						       },
					  'quota' => {'format' => '\d+',
						      'default' => {'conf' => 'default_shared_quota'},
						      'length' => 8,
						      'gettext_unit' => 'Kbytes',
						      'gettext_id' => "quota",
						      'order' => 3
						      }
				      },
			     'gettext_id' => "Shared documents",
			     'group' => 'command'
			 },
	    'spam_protection' => {'format' => ['at','javascript','none'],
			 'default' => 'javascript',
			 'gettext_id' => "email address protection method",
			 'group' => 'other'
			  },
	    'web_archive_spam_protection' => {'format' => ['cookie','javascript','at','none'],
			 'default' => {'conf' => 'web_archive_spam_protection'},
			 'gettext_id' => "email address protection method",
			 'group' => 'archives'
			  },

	    'status' => {'format' => ['open','closed','pending','error_config','family_closed'],
			 'default' => 'open',
			 'gettext_id' => "Status of the list",
			 'internal' => 1,
			 'group' => 'other'
			 },
	    'sql_fetch_timeout' => {'format' => '\d+',
		      'length' => 6,
		      'gettext_unit' => 'seconds',
		      'default' => {'conf' => 'default_sql_fetch_timeout'},
		      'gettext_id' => "Timeout for fetch of include_sql_query",
		      'group' => 'data_source'
		      },
	    'subject' => {'format' => '.+',
			  'length' => 50,
			  'occurrence' => '1',
			  'gettext_id' => "Subject of the list",
			  'group' => 'description'
			   },
	    'subscribe' => {'scenario' => 'subscribe',
			    'gettext_id' => "Who can subscribe to the list",
			    'group' => 'command'
			    },
	    'topics' => {'format' => '[\-\w]+(\/[\-\w]+)?',
			 'split_char' => ',',
			 'occurrence' => '0-n',
			 'gettext_id' => "Topics for the list",
			 'group' => 'description'
			 },
	    'ttl' => {'format' => '\d+',
		      'length' => 6,
		      'gettext_unit' => 'seconds',
		      'default' => 3600,
		      'gettext_id' => "Inclusions timeout",
		      'group' => 'data_source'
		      },
	    'unsubscribe' => {'scenario' => 'unsubscribe',
			      'gettext_id' => "Who can unsubscribe",
			      'group' => 'command'
			      },
	    'update' => {'format' => {'date_epoch' => {'format' => '\d+',
						       'length' => 8,
						       'occurrence' => '1',
						       'gettext_id' => 'epoch date',
						       'order' => 3
						       },
				      'date' => {'format' => '.+',
						 'length' => 30,
						 'gettext_id' => 'date',
						 'order' => 2
						 },
				      'email' => {'format' => '(listmaster|automatic|'.&tools::get_regexp('email').')',
						  'length' => 30,
						  'occurrence' => '1',
						  'gettext_id' => 'who updated the config',
						  'order' => 1
						  }
				  },
			 'gettext_id' => "Last update of config",
			 'internal' => 1,
			 'group' => 'other'
		     },
	    'user_data_source' => {'format' => ['database','file','include','include2'],
				   'default' => 'include2',
				   'obsolete_values'=> ['database','file','include'],
				   'gettext_id' => "User data source",
				   'group' => 'data_source'
				   },
	    'pictures_feature' => {'format' => ['on','off'],
			       'occurence' => '0-1',
			       'default' => {'conf' => 'pictures_feature'},
			       'gettext_id' => "Allow picture display? (must be enabled for the current robot)",
			       'group' => 'other'
			       },	
	    'merge_feature' => {'format' => ['on','off'],
			       'occurence' => '0-1',
			       'default' => {'conf' => 'merge_feature'},
			       'gettext_id' => "Allow message personnalization",
			       'group' => 'sending'
			       },
	    'visibility' => {'scenario' => 'visibility',
			     'synonym' => {'public' => 'noconceal',
					   'private' => 'conceal'},
			     'gettext_id' => "Visibility of the list",
			     'group' => 'description'
			     },
	    'web_archive'  => {'format' => {'access' => {'scenario' => 'access_web_archive',
							 'gettext_id' => "access right",
							 'order' => 1
							 },
					    'quota' => {'format' => '\d+',
							'default' => {'conf' => 'default_archive_quota'},
							'length' => 8,
							'gettext_unit' => 'Kbytes',
							'gettext_id' => "quota",
							'order' => 2
							},
 					    'max_month' => {'format' => '\d+',
							    'length' => 3,
							    'gettext_id' => "Maximum number of month archived",
							    'order' => 3 
  							     }
					},
			       
			       'gettext_id' => "Web archives",
			       'group' => 'archives'

			   },
	    'welcome_return_path' => {'format' => ['unique','owner'],
				      'default' => {'conf' => 'welcome_return_path'},
				      'gettext_id' => "Welcome return-path",
				      'group' => 'bounces'
				  },
	    'verp_rate' => {'format' => ['100%','50%','33%','25%','20%','10%','5%','2%','0%'],
			     'default' =>  {'conf' => 'verp_rate'},
			     'gettext_id' => "percentage of list members in VERP mode",
			     'group' => 'bounces'
			     },

	    );

## This is the generic hash which keeps all lists in memory.
my %list_of_lists = ();
my %list_of_robots = ();
our %list_of_topics = ();
my %edit_list_conf = ();

## Last modification times
my %mtime;

use Fcntl;
use DB_File;

$DB_BTREE->{compare} = \&_compare_addresses;

## Creates an object.
sub new {
    my($pkg, $name, $robot, $options) = @_;
    my $list={};
    &Log::do_log('debug2', 'List::new(%s, %s, %s)', $name, $robot, join('/',keys %$options));
    
    ## Allow robot in the name
    if ($name =~ /\@/) {
	my @parts = split /\@/, $name;
	$robot ||= $parts[1];
	$name = $parts[0];
    }

    ## Look for the list if no robot was provided
    $robot ||= &search_list_among_robots($name);

    unless ($robot) {
	&Log::do_log('err', 'Missing robot parameter, cannot create list object for %s',  $name) unless ($options->{'just_try'});
	return undef;
    }

    $options = {} unless (defined $options);

    ## Only process the list if the name is valid.
    my $listname_regexp = &tools::get_regexp('listname');
    unless ($name and ($name =~ /^$listname_regexp$/io) ) {
	&Log::do_log('err', 'Incorrect listname "%s"',  $name) unless ($options->{'just_try'});
	return undef;
    }
    ## Lowercase the list name.
    $name =~ tr/A-Z/a-z/;
    
    ## Reject listnames with reserved list suffixes
    my $regx = &Conf::get_robot_conf($robot,'list_check_regexp');
    if ( $regx ) {
	if ($name =~ /^(\S+)-($regx)$/) {
	    &Log::do_log('err', 'Incorrect name: listname "%s" matches one of service aliases',  $name) unless ($options->{'just_try'});
	    return undef;
	}
    }

    my $status ;
    if ($list_of_lists{$robot}{$name}){
	# use the current list in memory and update it
	$list=$list_of_lists{$robot}{$name};
	
	$status = $list->load($name, $robot, $options);
    }else{
	# create a new object list
	bless $list, $pkg;

	$options->{'first_access'} = 1;
	$status = $list->load($name, $robot, $options);
    }   
    unless (defined $status) {
	return undef;
    }

    ## Config file was loaded or reloaded
    if (($status == 1 && ! $options->{'skip_sync_admin'}) ||
	$options->{'force_sync_admin'}) {

	## Update admin_table
	unless (defined $list->sync_include_admin()) {
	    &Log::do_log('err','List::new() : sync_include_admin_failed') unless ($options->{'just_try'});
	}
	if ($list->get_nb_owners() < 1 &&
	    $list->{'admin'}{'status'} ne 'error_config') {
	    &Log::do_log('err', 'The list "%s" has got no owner defined',$list->{'name'}) ;
	    $list->set_status_error_config('no_owner_defined',$list->{'name'});
	}
    }

    return $list;
}

## When no robot is specified, look for a list among robots
sub search_list_among_robots {
    my $listname = shift;
    
    unless ($listname) {
 	&Log::do_log('err', 'List::search_list_among_robots() : Missing list parameter');
 	return undef;
    }
    
    ## Search in default robot
    if (-d $Conf::Conf{'home'}.'/'.$listname) {
 	return $Conf::Conf{'domain'};
    }
    
     foreach my $r (keys %{$Conf::Conf{'robots'}}) {
	 if (-d $Conf::Conf{'home'}.'/'.$r.'/'.$listname) {
	     return $r;
	 }
     }
    
     return 0;
}

## set the list in status error_config and send a notify to listmaster
sub set_status_error_config {
    my ($self, $message, @param) = @_;
    &Log::do_log('debug3', 'List::set_status_error_config');

    unless ($self->{'admin'}{'status'} eq 'error_config'){
	$self->{'admin'}{'status'} = 'error_config';

	my $host = &Conf::get_robot_conf($self->{'robot'}, 'host');
	## No more save config in error...
	#$self->save_config("listmaster\@$host");
	#$self->savestats();
	&Log::do_log('err', 'The list "%s" is set in status error_config',$self->{'name'});
	unless (&List::send_notify_to_listmaster($message, $self->{'domain'},\@param)) {
	    &Log::do_log('notice',"Unable to send notify '$message' to listmaster");
	};
    }
}

## set the list in status family_closed and send a notify to owners
sub set_status_family_closed {
    my ($self, $message, @param) = @_;
    &Log::do_log('debug2', 'List::set_status_family_closed');
    
    unless ($self->{'admin'}{'status'} eq 'family_closed'){
	
	my $host = &Conf::get_robot_conf($self->{'robot'}, 'host');	
	
	unless ($self->close_list("listmaster\@$host",'family_closed')) {
	    &Log::do_log('err','Impossible to set the list %s in status family_closed');
	    return undef;
	}
	&Log::do_log('err', 'The list "%s" is set in status family_closed',$self->{'name'});
	unless ($self->send_notify_to_owner($message,\@param)){
	    &Log::do_log('err','Impossible to send notify to owner informing status family_closed for the list %s',$self->{'name'});
	}
# messages : close_list
    }
    return 1;
}

## Saves the statistics data to disk.
sub savestats {
    my $self = shift;
    &Log::do_log('debug2', 'List::savestats');
   
    ## Be sure the list has been loaded.
    my $name = $self->{'name'};
    my $dir = $self->{'dir'};
    return undef unless ($list_of_lists{$self->{'domain'}}{$name});
    
    ## Lock file
    my $lock = new Lock ($dir.'/stats');
    unless (defined $lock) {
	&Log::do_log('err','Could not create new lock');
	return undef;
    }
    $lock->set_timeout(2); 
    unless ($lock->lock('write')) {
	return undef;
    }   

   _save_stats_file("$dir/stats", $self->{'stats'}, $self->{'total'}, $self->{'last_sync'}, $self->{'last_sync_admin_user'});
    
    ## Release the lock
    unless ($lock->unlock()) {
	return undef;
    }

    ## Changed on disk
    $self->{'mtime'}[2] = time;

    return 1;
}

## msg count.
sub increment_msg_count {
    my $self = shift;
    &Log::do_log('debug2', "List::increment_msg_count($self->{'name'})");
   
    ## Be sure the list has been loaded.
    my $name = $self->{'name'};
    my $file = "$self->{'dir'}/msg_count";
    
    my %count ; 
    if (open(MSG_COUNT, $file)) {	
	while (<MSG_COUNT>){
	    if ($_ =~ /^(\d+)\s(\d+)$/) {
		$count{$1} = $2;	
	    }
	}
	close MSG_COUNT ;
    }
    my $today = int(time / 86400);
    if ($count{$today}) {
	$count{$today}++;
    }else{
	$count{$today} = 1;
    }
    
    unless (open(MSG_COUNT, ">$file.$$")) {
	do_log('err', "Unable to create '%s.%s' : %s", $file,$$, $!);
	return undef;
    }
    foreach my $key (sort {$a <=> $b} keys %count) {
	printf MSG_COUNT "%d\t%d\n",$key,$count{$key} ;
    }
    close MSG_COUNT ;
    
    unless (rename("$file.$$", $file)) {
	do_log('err', "Unable to write '%s' : %s", $file, $!);
	return undef;
    }
    return 1;
}

# Returns the number of messages sent to the list
sub get_msg_count {
    my $self = shift;
    &Log::do_log('debug3', "Getting the number of messages for list %s",$self->{'name'});

    ## Be sure the list has been loaded.
    my $name = $self->{'name'};
    my $file = "$self->{'dir'}/stats";
    
    my $count = 0 ;
    if (open(MSG_COUNT, $file)) {	
	while (<MSG_COUNT>){
	    if ($_ =~ /^(\d+)\s+(.*)$/) {
		$count=$1;	
	    }
	}
	close MSG_COUNT ;
    }

    return $count;

}
## last date of distribution message .
sub get_latest_distribution_date {
    my $self = shift;
    &Log::do_log('debug3', "List::latest_distribution_date($self->{'name'})");
   
    ## Be sure the list has been loaded.
    my $name = $self->{'name'};
    my $file = "$self->{'dir'}/msg_count";
    
    my %count ; 
    my $latest_date = 0 ; 
    unless (open(MSG_COUNT, $file)) {
	do_log('debug2',"get_latest_distribution_date: unable to open $file");
	return undef ;
    }

    while (<MSG_COUNT>){
	if ($_ =~ /^(\d+)\s(\d+)$/) {
	    $latest_date = $1 if ($1 > $latest_date);
	}
    }
    close MSG_COUNT ;

    return undef if ($latest_date == 0); 
    return $latest_date ;
}

## Update the stats struct 
## Input  : num of bytes of msg
## Output : num of msgs sent
sub update_stats {
    my($self, $bytes) = @_;
    &Log::do_log('debug2', 'List::update_stats(%d)', $bytes);

    my $stats = $self->{'stats'};
    $stats->[0]++;
    $stats->[1] += $self->{'total'};
    $stats->[2] += $bytes;
    $stats->[3] += $bytes * $self->{'total'};

    ## Update 'msg_count' file, used for bounces management
    $self->increment_msg_count();

    return $stats->[0];
}

## Extract a set of rcpt for which verp must be use from a rcpt_tab.
## Input  :  percent : the rate of subscribers that must be threaded using verp
##           xseq    : the message sequence number
##           @rcpt   : a tab of emails
## return :  a tab of rcpt for which rcpt must be use depending on the message sequence number, this way every subscriber is "verped" from time to time
##           input table @rcpt is spliced : rcpt for which verp must be used are extracted from this table
sub extract_verp_rcpt() {
    my $percent = shift;
    my $xseq = shift;
    my $refrcpt = shift;
    my $refrcptverp = shift;

    &Log::do_log('debug','&extract_verp(%s,%s,%s,%s)',$percent,$xseq,$refrcpt,$refrcptverp)  ;

    my @result;

    if ($percent ne '0%') {
	my $nbpart ; 
	if ( $percent =~ /^(\d+)\%/ ) {
	    $nbpart = 100/$1;  
	}
	else {
	    &Log::do_log ('err', 'Wrong format for parameter extract_verp: %s. Can\'t process VERP.',$percent);
	    return undef;
	}
	
	my $modulo = $xseq % $nbpart ;
	my $lenght = int (($#{$refrcpt} + 1) / $nbpart) + 1;
	
	@result = splice @$refrcpt, $lenght*$modulo, $lenght ;
    }
    foreach my $verprcpt (@$refrcptverp) {
	push @result, $verprcpt;
    }
    return ( @result ) ;
}



## Dumps a copy of lists to disk, in text format
sub dump {
    my $self = shift;
    &Log::do_log('debug2', 'List::dump(%s)', $self->{'name'});

    unless (defined $self) {
	&Log::do_log('err','Unknown list');
	return undef;
    }

    my $user_file_name = "$self->{'dir'}/subscribers.db.dump";

    unless ($self->_save_list_members_file($user_file_name)) {
	&Log::do_log('err', 'Failed to save file %s', $user_file_name);
	return undef;
    }
    
    $self->{'mtime'} = [ (stat("$self->{'dir'}/config"))[9], (stat("$self->{'dir'}/subscribers"))[9], (stat("$self->{'dir'}/stats"))[9] ];

    return 1;
}

## Saves the configuration file to disk
sub save_config {
    my ($self, $email) = @_;
    &Log::do_log('debug3', 'List::save_config(%s,%s)', $self->{'name'}, $email);

    return undef 
	unless ($self);

    my $config_file_name = "$self->{'dir'}/config";

    ## Lock file
    my $lock = new Lock ($self->{'dir'}.'/config');
    unless (defined $lock) {
	&Log::do_log('err','Could not create new lock');
	return undef;
    }
    $lock->set_timeout(5); 
    unless ($lock->lock('write')) {
	return undef;
    }

    my $name = $self->{'name'};    
    my $old_serial = $self->{'admin'}{'serial'};
    my $old_config_file_name = "$self->{'dir'}/config.$old_serial";

    ## Update management info
    $self->{'admin'}{'serial'}++;
    $self->{'admin'}{'update'} = {'email' => $email,
				  'date_epoch' => time,
				  'date' => (gettext_strftime "%d %b %Y at %H:%M:%S", localtime(time)),
				  };

    unless (&_save_list_config_file($config_file_name, $old_config_file_name, $self->{'admin'})) {
	&Log::do_log('info', 'unable to save config file %s', $config_file_name);
	$lock->unlock();
	return undef;
    }
    
    ## Also update the binary version of the data structure
    if (&Conf::get_robot_conf($self->{'robot'}, 'cache_list_config') eq 'binary_file') {
	eval {&Storable::store($self->{'admin'},"$self->{'dir'}/config.bin")};
	if ($@) {
	    &Log::do_log('err', 'Failed to save the binary config %s. error: %s', "$self->{'dir'}/config.bin",$@);
	}
    }

#    $self->{'mtime'}[0] = (stat("$list->{'dir'}/config"))[9];
    
    ## Release the lock
    unless ($lock->unlock()) {
	return undef;
    }

    return 1;
}

## Loads the administrative data for a list
sub load {
    my ($self, $name, $robot, $options) = @_;
    &Log::do_log('debug2', 'List::load(%s, %s, %s)', $name, $robot, join('/',keys %$options));
    
    my $users;

    ## Set of initializations ; only performed when the config is first loaded
    if ($options->{'first_access'}) {

	## Search robot if none was provided
	unless ($robot) {
	    foreach my $r (keys %{$Conf::Conf{'robots'}}) {
		if (-d "$Conf::Conf{'home'}/$r/$name") {
		    $robot=$r;
		    last;
		}
	    }
	    
	    ## Try default robot
	    unless ($robot) {
		if (-d "$Conf::Conf{'home'}/$name") {
		    $robot = $Conf::Conf{'domain'};
		}
	    }
	}
	
	if ($robot && (-d "$Conf::Conf{'home'}/$robot")) {
	    $self->{'dir'} = "$Conf::Conf{'home'}/$robot/$name";
	}elsif (lc($robot) eq lc($Conf::Conf{'domain'})) {
	    $self->{'dir'} = "$Conf::Conf{'home'}/$name";
	}else {
	    &Log::do_log('err', 'No such robot (virtual domain) %s', $robot) unless ($options->{'just_try'});
	    return undef ;
	}
	
	$self->{'domain'} = $robot ;

	# default list host is robot domain
	$self->{'admin'}{'host'} ||= $self->{'domain'};
	$self->{'name'}  = $name ;
    }

    unless ((-d $self->{'dir'}) && (-f "$self->{'dir'}/config")) {
	&Log::do_log('debug2', 'Missing directory (%s) or config file for %s', $self->{'dir'}, $name) unless ($options->{'just_try'});
	return undef ;
    }

    my ($m1, $m2, $m3) = (0, 0, 0);
    ($m1, $m2, $m3) = @{$self->{'mtime'}} if (defined $self->{'mtime'});

    my $time_config = (stat("$self->{'dir'}/config"))[9];
    my $time_config_bin = (stat("$self->{'dir'}/config.bin"))[9];
    my $time_subscribers; 
    my $time_stats = (stat("$self->{'dir'}/stats"))[9];
    my $config_reloaded = 0;
    my $admin;
    
    if (&Conf::get_robot_conf($self->{'domain'}, 'cache_list_config') eq 'binary_file' &&
	$time_config_bin > $self->{'mtime'}->[0] &&
	$time_config <= $time_config_bin &&
	! $options->{'reload_config'}) { 

	## Get a shared lock on config file first 
	my $lock = new Lock ($self->{'dir'}.'/config');
	unless (defined $lock) {
	    &Log::do_log('err','Could not create new lock');
	    return undef;
	}
	$lock->set_timeout(5); 
	unless ($lock->lock('read')) {
	    return undef;
	}

	## Load a binary version of the data structure
	## unless config is more recent than config.bin
	eval {$admin = &Storable::retrieve("$self->{'dir'}/config.bin")};
	if ($@) {
	    &Log::do_log('err', 'Failed to load the binary config %s, error: %s', "$self->{'dir'}/config.bin",$@);
	    $lock->unlock();
	    return undef;
	}	    

	$config_reloaded = 1;
	$m1 = $time_config_bin;
	$lock->unlock();

    }elsif ($self->{'name'} ne $name || $time_config > $self->{'mtime'}->[0] ||
	    $options->{'reload_config'}) {	
	$admin = _load_list_config_file($self->{'dir'}, $self->{'domain'}, 'config');

	## Get a shared lock on config file first 
	my $lock = new Lock ($self->{'dir'}.'/config');
	unless (defined $lock) {
	    &Log::do_log('err','Could not create new lock');
	    return undef;
	}
	$lock->set_timeout(5); 
	unless ($lock->lock('write')) {
	    return undef;
	}

	## update the binary version of the data structure
	if (&Conf::get_robot_conf($self->{'domain'}, 'cache_list_config') eq 'binary_file') {
	    eval {&Storable::store($admin,"$self->{'dir'}/config.bin")};
	    if ($@) {
		&Log::do_log('err', 'Failed to save the binary config %s. error: %s', "$self->{'dir'}/config.bin",$@);
	    }
	}

	$config_reloaded = 1;
 	unless (defined $admin) {
 	    &Log::do_log('err', 'Impossible to load list config file for list % set in status error_config',$self->{'name'});
 	    $self->set_status_error_config('load_admin_file_error',$self->{'name'});
	    $lock->unlock();
 	    return undef;	    
 	}

	$m1 = $time_config;
	$lock->unlock();
    }
    
    ## If config was reloaded...
    if ($admin) {
 	$self->{'admin'} = $admin;
 	
 	## check param_constraint.conf if belongs to a family and the config has been loaded
 	if (defined $admin->{'family_name'} && ($admin->{'status'} ne 'error_config')) {
 	    my $family;
 	    unless ($family = $self->get_family()) {
 		&Log::do_log('err', 'Impossible to get list %s family : %s. The list is set in status error_config',$self->{'name'},$self->{'admin'}{'family_name'});
 		$self->set_status_error_config('no_list_family',$self->{'name'}, $admin->{'family_name'});
		return undef;
 	    }  
 	    my $error = $family->check_param_constraint($self);
 	    unless($error) {
 		&Log::do_log('err', 'Impossible to check parameters constraint for list % set in status error_config',$self->{'name'});
 		$self->set_status_error_config('no_check_rules_family',$self->{'name'}, $family->{'name'});
 	    }
	    if (ref($error) eq 'ARRAY') {
 		&Log::do_log('err', 'The list "%s" does not respect the rules from its family %s',$self->{'name'}, $family->{'name'});
 		$self->set_status_error_config('no_respect_rules_family',$self->{'name'}, $family->{'name'});
 	    }
 	}
     } 

    $self->{'as_x509_cert'} = 1  if ((-r "$self->{'dir'}/cert.pem") || (-r "$self->{'dir'}/cert.pem.enc"));
       
    ## Load stats file if first new() or stats file changed
    my ($stats, $total);
    if (! $self->{'mtime'}[2] || ($time_stats > $self->{'mtime'}[2])) {
	($stats, $total, $self->{'last_sync'}, $self->{'last_sync_admin_user'}) = _load_stats_file("$self->{'dir'}/stats");
	$m3 = $time_stats;

	$self->{'stats'} = $stats if (defined $stats);	
	$self->{'total'} = $total if (defined $total);	
    }
    
    $self->{'users'} = $users->{'users'} if ($users);
    $self->{'ref'}   = $users->{'ref'} if ($users);
    
    if ($users && defined($users->{'total'})) {
	$self->{'total'} = $users->{'total'};
    }

    ## We have updated %users, Total may have changed
    if ($m2 > $self->{'mtime'}[1]) {
	$self->savestats();
    }

    $self->{'mtime'} = [ $m1, $m2, $m3];

    $list_of_lists{$self->{'domain'}}{$name} = $self;
    return $config_reloaded;
}

## Return a list of hash's owners and their param
sub get_owners {
    my($self) = @_;
    &Log::do_log('debug3', 'List::get_owners(%s)', $self->{'name'});
  
    my $owners = ();

    # owners are in the admin_table ; they might come from an include data source
    for (my $owner = $self->get_first_list_admin('owner'); $owner; $owner = $self->get_next_list_admin()) {
	push(@{$owners},$owner);
    } 

    return $owners;
}

sub get_nb_owners {
    my($self) = @_;
    &Log::do_log('debug3', 'List::get_nb_owners(%s)', $self->{'name'});
    
    my $resul = 0;
    my $owners = $self->get_owners;

    if (defined $owners) {
	$resul = $#{$owners} + 1;
    }
    return $resul;
}

## Return a hash of list's editors and their param(empty if there isn't any editor)
sub get_editors {
    my($self) = @_;
    &Log::do_log('debug3', 'List::get_editors(%s)', $self->{'name'});
  
    my $editors = ();

    # editors are in the admin_table ; they might come from an include data source
    for (my $editor = $self->get_first_list_admin('editor'); $editor; $editor = $self->get_next_list_admin()) {
	push(@{$editors},$editor);
    } 

    return $editors;
}


## Returns an array of owners' email addresses
sub get_owners_email {
    my($self,$param) = @_;
    &Log::do_log('debug3', 'List::get_owners_email(%s,%s)', $self->{'name'}, $param -> {'ignore_nomail'});
    
    my @rcpt;
    my $owners = ();

    $owners = $self->get_owners();

    if ($param -> {'ignore_nomail'}) {
	foreach my $o (@{$owners}) {
	    push (@rcpt, lc($o->{'email'}));
	}
    }
    else {
	foreach my $o (@{$owners}) {
	    next if ($o->{'reception'} eq 'nomail');
	    push (@rcpt, lc($o->{'email'}));
	}
    }
    unless (@rcpt) {
	&Log::do_log('notice','Warning : no owner found for list %s', $self->{'name'} );
    }
    return @rcpt;
}

## Returns an array of editors' email addresses
#  or owners if there isn't any editors'email adress
sub get_editors_email {
    my($self,$param) = @_;
    &Log::do_log('debug3', 'List::get_editors_email(%s,%s)', $self->{'name'}, $param -> {'ignore_nomail'});
    
    my @rcpt;
    my $editors = ();

    $editors = $self->get_editors();

    if ($param -> {'ignore_nomail'}) {
	foreach my $e (@{$editors}) {
	    push (@rcpt, lc($e->{'email'}));
	}
    }
    else {
	foreach my $e (@{$editors}) {
	    next if ($e->{'reception'} eq 'nomail');
	    push (@rcpt, lc($e->{'email'}));
	}
    }
    unless (@rcpt) {
	&Log::do_log('notice','Warning : no editor found for list %s, getting owners', $self->{'name'} );
	@rcpt = $self->get_owners_email($param);
    }
    return @rcpt;
}

## Returns an object Family if the list belongs to a family
#  or undef
sub get_family {
    my $self = shift;
    &Log::do_log('debug3', 'List::get_family(%s)', $self->{'name'});
    
    if (ref($self->{'family'}) eq 'Family') {
	return $self->{'family'};
    }

    my $family_name;
    my $robot = $self->{'domain'};

    unless (defined $self->{'admin'}{'family_name'}) {
	&Log::do_log('err', 'List::get_family(%s) : this list has not got any family', $self->{'name'});
	return undef;
    }
        
    $family_name = $self->{'admin'}{'family_name'};
	    
    my $family;
    unless ($family = new Family($family_name,$robot) ) {
	&Log::do_log('err', 'List::get_family(%s) : new Family(%s) impossible', $self->{'name'},$family_name);
	return undef;
    }
  	
    $self->{'family'} = $family;
    return $family;
}

## return the config_changes hash
## Used ONLY with lists belonging to a family.
sub get_config_changes {
    my $self = shift;
    &Log::do_log('debug3', 'List::get_config_changes(%s)', $self->{'name'});
    
    unless ($self->{'admin'}{'family_name'}) {
	&Log::do_log('err', 'List::get_config_changes(%s) is called but there is no family_name for this list.',$self->{'name'});
	return undef;
    }
    
    ## load config_changes
    my $time_file = (stat("$self->{'dir'}/config_changes"))[9];
    unless (defined $self->{'config_changes'} && ($self->{'config_changes'}{'mtime'} >= $time_file)) {
	unless ($self->{'config_changes'} = $self->_load_config_changes_file()) {
	    &Log::do_log('err','Impossible to load file config_changes from list %s',$self->{'name'});
	    return undef;
	}
    }
    return $self->{'config_changes'};
}


## update file config_changes if the list belongs to a family by
#  writing the $what(file or param) name 
sub update_config_changes {
    my $self = shift;
    my $what = shift;
    # one param or a ref on array of param
    my $name = shift;
    &Log::do_log('debug2', 'List::update_config_changes(%s,%s)', $self->{'name'},$what);
    
    unless ($self->{'admin'}{'family_name'}) {
	&Log::do_log('err', 'List::update_config_changes(%s,%s,%s) is called but there is no family_name for this list.',$self->{'name'},$what);
	return undef;
    }
    unless (($what eq 'file') || ($what eq 'param')){
	&Log::do_log('err', 'List::update_config_changes(%s,%s) : %s is wrong : must be "file" or "param".',$self->{'name'},$what);
	return undef;
    } 
    
    # status parameter isn't updating set in config_changes
    if (($what eq 'param') && ($name eq 'status')) {
	return 1;
    }

    ## load config_changes
    my $time_file = (stat("$self->{'dir'}/config_changes"))[9];
    unless (defined $self->{'config_changes'} && ($self->{'config_changes'}{'mtime'} >= $time_file)) {
	unless ($self->{'config_changes'} = $self->_load_config_changes_file()) {
	    &Log::do_log('err','Impossible to load file config_changes from list %s',$self->{'name'});
	    return undef;
	}
    }
    
    if (ref($name) eq 'ARRAY' ) {
	foreach my $n (@{$name}) {
	    $self->{'config_changes'}{$what}{$n} = 1; 
	}
    } else {
	$self->{'config_changes'}{$what}{$name} = 1;
    }
    
    $self->_save_config_changes_file();
    
    return 1;
}

## return a hash of config_changes file
sub _load_config_changes_file {
    my $self = shift;
    &Log::do_log('debug3', 'List::_load_config_changes_file(%s)', $self->{'name'});

    my $config_changes = {};

    unless (-e "$self->{'dir'}/config_changes") {
	&Log::do_log('err','No file %s/config_changes. Assuming no changes', $self->{'dir'});
	return $config_changes;
    }

    unless (open (FILE,"$self->{'dir'}/config_changes")) {
	&Log::do_log('err','File %s/config_changes exists, but unable to open it: %s', $self->{'dir'},$_);
	return undef;
    }
    
    while (<FILE>) {
	
	next if /^\s*(\#.*|\s*)$/;

	if (/^param\s+(.+)\s*$/) {
	    $config_changes->{'param'}{$1} = 1;

	}elsif (/^file\s+(.+)\s*$/) {
	    $config_changes->{'file'}{$1} = 1;
	
	}else {
	    &Log::do_log ('err', 'List::_load_config_changes_file(%s) : bad line : %s',$self->{'name'},$_);
	    next;
	}
    }
    close FILE;

    $config_changes->{'mtime'} = (stat("$self->{'dir'}/config_changes"))[9];

    return $config_changes;
}

## save config_changes file in the list directory
sub _save_config_changes_file {
    my $self = shift;
    &Log::do_log('debug3', 'List::_save_config_changes_file(%s)', $self->{'name'});

    unless ($self->{'admin'}{'family_name'}) {
	&Log::do_log('err', 'List::_save_config_changes_file(%s) is called but there is no family_name for this list.',$self->{'name'});
	return undef;
    }
    unless (open (FILE,">$self->{'dir'}/config_changes")) {
	&Log::do_log('err','List::_save_config_changes_file(%s) : unable to create file %s/config_changes : %s',$self->{'name'},$self->{'dir'},$_);
	return undef;
    }

    foreach my $what ('param','file') {
	foreach my $name (keys %{$self->{'config_changes'}{$what}}) {
	    print FILE "$what $name\n";
	}
    }
    close FILE;
    
    return 1;
}




sub _get_param_value_anywhere {
    my $new_admin = shift;
    my $param = shift; 
    &Log::do_log('debug3', '_get_param_value_anywhere(%s %s)',$param);
    my $minor_p;
    my @values;

   if ($param =~ /^([\w-]+)\.([\w-]+)$/) {
	$param = $1;
	$minor_p = $2;
    }

    ## Multiple parameter (owner, custom_header, ...)
    if ((ref ($new_admin->{$param}) eq 'ARRAY') &&
	!($::pinfo{$param}{'split_char'})) {
	foreach my $elt (@{$new_admin->{$param}}) {
	    my $val = &List::_get_single_param_value($elt,$param,$minor_p);
	    if (defined $val) {
		push @values,$val;
	    }
	}

    }else {
	my $val = &List::_get_single_param_value($new_admin->{$param},$param,$minor_p);
	if (defined $val) {
	    push @values,$val;
	}
    }
    return \@values;
}


## Returns the list parameter value from $list->{'admin'}
#  the parameter is simple ($param) or composed ($param & $minor_param)
#  the value is a scalar or a ref on an array of scalar
# (for parameter digest : only for days)
sub get_param_value {
    my $self = shift;
    my $param = shift; 
    &Log::do_log('debug3', 'List::get_param_value(%s,%s)', $self->{'name'},$param);
    my $minor_param;
    my $value;

    if ($param =~ /^([\w-]+)\.([\w-]+)$/) {
	$param = $1;
	$minor_param = $2;
    }

    ## Multiple parameter (owner, custom_header, ...)
    if ((ref ($self->{'admin'}{$param}) eq 'ARRAY') &&
	! $::pinfo{$param}{'split_char'}) {
	my @values;
	foreach my $elt (@{$self->{'admin'}{$param}}) {
	    push @values,&_get_single_param_value($elt,$param,$minor_param) 
	}
	$value = \@values;
    }else {
	$value = &_get_single_param_value($self->{'admin'}{$param},$param,$minor_param);
    }
    return $value;
}

## Returns the single list parameter value from struct $p, with $key entrie,
#  $k is optionnal
#  the single value can be a ref on a list when the parameter value is a list
sub _get_single_param_value {
    my ($p,$key,$k) = @_;
    &Log::do_log('debug3', 'List::_get_single_value(%s %s)',$key,$k);

    if (defined ($::pinfo{$key}{'scenario'}) ||
        defined ($::pinfo{$key}{'task'})) {
	return $p->{'name'};
    
    }elsif (ref($::pinfo{$key}{'file_format'})) {
	
	if (defined ($::pinfo{$key}{'file_format'}{$k}{'scenario'})) {
	    return $p->{$k}{'name'};

	}elsif (($::pinfo{$key}{'file_format'}{$k}{'occurrence'} =~ /n$/)
		    && $::pinfo{$key}{'file_format'}{$k}{'split_char'}) {
	    return $p->{$k}; # ref on an array
	}else {
	    return $p->{$k};
	}

    }else {
	if (($::pinfo{$key}{'occurrence'} =~ /n$/)
	    && $::pinfo{$key}{'split_char'}) {
	    return $p; # ref on an array
	}elsif ($key eq 'digest') {
	    return $p->{'days'}; # ref on an array 
	}else {
	    return $p;
	}
    }
}



########################################################################################
#                       FUNCTIONS FOR MESSAGE SENDING                                  #
########################################################################################
#                                                                                      #
#  -list distribution   
#  -template sending                                                                   #
#  -service messages
#  -notification sending(listmaster, owner, editor, user)                              #
#                                                                 #

                                             
#########################   LIST DISTRIBUTION  #########################################


####################################################
# distribute_msg                              
####################################################
#  prepares and distributes a message to a list, do 
#  some of these :
#  stats, hidding sender, adding custom subject, 
#  archive, changing the replyto, removing headers, 
#  adding headers, storing message in digest
# 
#  
# IN : -$self (+): ref(List)
#      -$message (+): ref(Message)
#      -$apply_dkim_signature : on | off
# OUT : -$numsmtp : number of sendmail process
####################################################
sub distribute_msg {
    my $self = shift;
    my %param = @_;

    my $message = $param{'message'};
    my $apply_dkim_signature = $param{'apply_dkim_signature'};

    &Log::do_log('debug2', 'List::distribute_msg(%s, %s, %s, %s, %s, %s, apply_dkim_signature=%s)', $self->{'name'}, $message->{'msg'}, $message->{'size'}, $message->{'filename'}, $message->{'smime_crypted'}, $apply_dkim_signature );

    my $hdr = $message->{'msg'}->head;
    my ($name, $host) = ($self->{'name'}, $self->{'admin'}{'host'});
    my $robot = $self->{'domain'};

    ## Update the stats, and returns the new X-Sequence, if any.
    my $sequence = $self->update_stats($message->{'size'});
    
    ## Loading info msg_topic file if exists, add X-Sympa-Topic
    my $info_msg_topic;
    if ($self->is_there_msg_topic()) {
	my $msg_id = $hdr->get('Message-ID');
	chomp($msg_id);
	$info_msg_topic = $self->load_msg_topic_file($msg_id,$robot);

	# add X-Sympa-Topic header
	if (ref($info_msg_topic) eq "HASH") {
	    $message->add_topic($info_msg_topic->{'topic'});
	}
    }

    ## Hide the sender if the list is anonymoused
    if ( $self->{'admin'}{'anonymous_sender'} ) {

	foreach my $field (@{$Conf::Conf{'anonymous_header_fields'}}) {
	    $hdr->delete($field);
	}
	
	$hdr->add('From',"$self->{'admin'}{'anonymous_sender'}");
	my $new_id = "$self->{'name'}.$sequence\@anonymous";
	$hdr->add('Message-id',"<$new_id>");
	
	# rename msg_topic filename
	if ($info_msg_topic) {
	    my $queuetopic = &Conf::get_robot_conf($robot, 'queuetopic');
	    my $listname = "$self->{'name'}\@$robot";
	    rename("$queuetopic/$info_msg_topic->{'filename'}","$queuetopic/$listname.$new_id");
	    $info_msg_topic->{'filename'} = "$listname.$new_id";
	}
	
	## Virer eventuelle signature S/MIME
    }
    
    ## Add Custom Subject
    if ($self->{'admin'}{'custom_subject'}) {
	my $subject_field = $message->{'decoded_subject'};
	$subject_field =~ s/^\s*(.*)\s*$/$1/; ## Remove leading and trailing blanks
	
	## Search previous subject tagging in Subject
	my $custom_subject = $self->{'admin'}{'custom_subject'};

	## tag_regexp will be used to remove the custom subject if it is already present in the message subject.
	## Remember that the value of custom_subject can be "dude number [%list.sequence"%]" whereas the actual
	## subject will contain "dude number 42".
	my $tag_regexp = $custom_subject;
	$tag_regexp =~ s/([\[\]\*\-\(\)\+\{\}\?])/\\$1/g;  ## cleanup, just in case dangerous chars were left
	$tag_regexp =~ s/\\\[%\S+%\\\]/[^\]]\+/g; ## Replaces variables declarations by "[^\]]+"
	$tag_regexp =~ s/\s+/\\s+/g; ## Takes spaces into account
	
	## Add subject tag
	$message->{'msg'}->head->delete('Subject');
	my $parsed_tag;
	&tt2::parse_tt2({'list' => {'name' => $self->{'name'},
				    'sequence' => $self->{'stats'}->[0]
				    }},
			[$custom_subject], \$parsed_tag);

	## If subject is tagged, replace it with new tag
	## Splitting the subject in two parts :
	##   - what is before the custom subject (probably some "Re:")
	##   - what is after it : the orginal subject sent to the list.
	## The custom subject is not kept.
	my $before_tag = '';
	my $after_tag = $subject_field;
	$after_tag =~ s/.*\[$tag_regexp\]\s*//;
        $after_tag =~ s/\s*$//;

        if($subject_field =~ /(.*)\s*\[$tag_regexp\].*/) {
	    $before_tag = $1;
	}
	
 	## Encode subject using initial charset

	## Don't try to encode the subject if it was not originaly encoded.
	if ($message->{'subject_charset'}) {
	    $subject_field = MIME::EncWords::encode_mimewords([
							       [Encode::decode('utf8', $before_tag), $message->{'subject_charset'}],
							       [Encode::decode('utf8', '['.$parsed_tag.'] '), &Language::GetCharset()],
							       [Encode::decode('utf8', $after_tag), $message->{'subject_charset'}]
							       ], Encoding=>'A', Field=>'Subject');
	}else {
	    $subject_field = $before_tag . ' ' .  MIME::EncWords::encode_mimewords([
										    [Encode::decode('utf8', '['.$parsed_tag.']'), &Language::GetCharset()]
										    ], Encoding=>'A', Field=>'Subject') . ' ' . $after_tag;
	}

	$message->{'msg'}->head->add('Subject', $subject_field);
    }

    ## Prepare tracking if list config allow it
    my $apply_tracking = 'off';
    
    $apply_tracking = 'dsn' if ($self->{'admin'}{'tracking'}{'delivery_status_notification'} eq 'on');
    $apply_tracking = 'mdn' if ($self->{'admin'}{'tracking'}{'message_delivery_notification'} eq 'on');
    $apply_tracking = 'mdn' if (($self->{'admin'}{'tracking'}{'message_delivery_notification'}  eq 'on_demand') && ($hdr->get('Disposition-Notification-To')));

    if ($apply_tracking ne 'off'){
	$hdr->delete('Disposition-Notification-To'); # remove notification request becuse a new one will be inserted if needed
    }
    
    ## Remove unwanted headers if present.
    if ($self->{'admin'}{'remove_headers'}) {
        foreach my $field (@{$self->{'admin'}{'remove_headers'}}) {
            $hdr->delete($field);
        }
    }

    ## Archives
    my $msgtostore = $message->{'msg'};
    if (($message->{'smime_crypted'} eq 'smime_crypted') &&
	($self->{admin}{archive_crypted_msg} eq 'original')) {
	$msgtostore = $message->{'orig_msg'};
    }
    $self->archive_msg($msgtostore);
    
    ## Change the reply-to header if necessary. 
    if ($self->{'admin'}{'reply_to_header'}) {
	unless ($hdr->get('Reply-To') && ($self->{'admin'}{'reply_to_header'}{'apply'} ne 'forced')) {
	    my $reply;
	    
	    $hdr->delete('Reply-To');
	    
	    if ($self->{'admin'}{'reply_to_header'}{'value'} eq 'list') {
		$reply = "$name\@$host";
	    }elsif ($self->{'admin'}{'reply_to_header'}{'value'} eq 'sender') {
		$reply = $hdr->get('From');
	    }elsif ($self->{'admin'}{'reply_to_header'}{'value'} eq 'all') {
		$reply = "$name\@$host,".$hdr->get('From');
	    }elsif ($self->{'admin'}{'reply_to_header'}{'value'} eq 'other_email') {
		$reply = $self->{'admin'}{'reply_to_header'}{'other_email'};
	    }
	    
	    $hdr->add('Reply-To',$reply) if $reply;
	}
    }
    
    ## Add useful headers
    $hdr->add('X-Loop', "$name\@$host");
    $hdr->add('X-Sequence', $sequence);
    $hdr->add('Errors-to', $name.&Conf::get_robot_conf($robot, 'return_path_suffix').'@'.$host);
    $hdr->add('Precedence', 'list');
    $hdr->add('Precedence', 'bulk');
    $hdr->add('Sender', "$self->{'name'}-request\@$self->{'admin'}{'host'}"); # The Sender: header should be add at least for DKIM compatibility
    $hdr->add('X-no-archive', 'yes');
    foreach my $i (@{$self->{'admin'}{'custom_header'}}) {
	$hdr->add($1, $2) if ($i=~/^([\S\-\:]*)\s(.*)$/);
    }
    
    ## Add RFC 2919 header field
    if ($hdr->get('List-Id')) {
	&Log::do_log('notice', 'Found List-Id: %s', $hdr->get('List-Id'));
	$hdr->delete('List-ID');
    }
    $hdr->add('List-Id', sprintf ('<%s.%s>', $self->{'name'}, $self->{'admin'}{'host'}));
    
    ## Add RFC 2369 header fields
    foreach my $field (@{$self->{'admin'}{'rfc2369_header_fields'}}) {
	if ($field eq 'help') {
	    $hdr->add('List-Help', sprintf ('<mailto:%s@%s?subject=help>', &Conf::get_robot_conf($robot, 'email'), &Conf::get_robot_conf($robot, 'host')));
	}elsif ($field eq 'unsubscribe') {
	    $hdr->add('List-Unsubscribe', sprintf ('<mailto:%s@%s?subject=unsubscribe%%20%s>', &Conf::get_robot_conf($robot, 'email'), &Conf::get_robot_conf($robot, 'host'), $self->{'name'}));
	}elsif ($field eq 'subscribe') {
	    $hdr->add('List-Subscribe', sprintf ('<mailto:%s@%s?subject=subscribe%%20%s>', &Conf::get_robot_conf($robot, 'email'), &Conf::get_robot_conf($robot, 'host'), $self->{'name'}));
	}elsif ($field eq 'post') {
	    $hdr->add('List-Post', sprintf ('<mailto:%s@%s>', $self->{'name'}, $self->{'admin'}{'host'}));
	}elsif ($field eq 'owner') {
	    $hdr->add('List-Owner', sprintf ('<mailto:%s-request@%s>', $self->{'name'}, $self->{'admin'}{'host'}));
	}elsif ($field eq 'archive') {
	    if (&Conf::get_robot_conf($robot, 'wwsympa_url') and $self->is_web_archived()) {
		$hdr->add('List-Archive', sprintf ('<%s/arc/%s>', &Conf::get_robot_conf($robot, 'wwsympa_url'), $self->{'name'}));
	    }
	}
    }

    ## Remove outgoing header fileds
    ## Useful to remove some header fields that Sympa has set
    if ($self->{'admin'}{'remove_outgoing_headers'}) {
        foreach my $field (@{$self->{'admin'}{'remove_outgoing_headers'}}) {
            $hdr->delete($field);
        }
    }   
    
    ## store msg in digest if list accept digest mode (encrypted message can't be included in digest)
    if (($self->is_digest()) and ($message->{'smime_crypted'} ne 'smime_crypted')) {
	$self->archive_msg_digest($msgtostore);
    }

    ## Synchronize list members, required if list uses include sources
    ## unless sync_include has been performed recently.
    if ($self->has_include_data_sources()) {
	$self->on_the_fly_sync_include('use_ttl' => 1);
    }

    ## Blindly send the message to all users.
    my $numsmtp = $self->send_msg('message'=> $message, 'apply_dkim_signature'=>$apply_dkim_signature, 'apply_tracking'=>$apply_tracking);

    $self->savestats() if (defined ($numsmtp));
    return $numsmtp;
}

####################################################
# send_msg_digest                              
####################################################
# Send a digest message to the subscribers with 
# reception digest, digestplain or summary
# 
# IN : -$self(+) : ref(List)
#
# OUT : 1 : ok
#       | 0 if no subscriber for sending digest
#       | undef
####################################################
sub send_msg_digest {
    my ($self) = @_;

    my $listname = $self->{'name'};
    my $robot = $self->{'domain'};
    &Log::do_log('debug2', 'List:send_msg_digest(%s)', $listname);
    
    my $filename;
    ## Backward compatibility concern
    if (-f "$Conf::Conf{'queuedigest'}/$listname") {
 	$filename = "$Conf::Conf{'queuedigest'}/$listname";
    }else {
 	$filename = $Conf::Conf{'queuedigest'}.'/'.$self->get_list_id();
    }
    
    my $param = {'replyto' => "$self->{'name'}-request\@$self->{'admin'}{'host'}",
		 'to' => $self->get_list_address(),
		 'table_of_content' => sprintf(gettext("Table of contents:")),
		 'boundary1' => '----------=_'.&tools::get_message_id($robot),
		 'boundary2' => '----------=_'.&tools::get_message_id($robot),
		 };
    if ($self->get_reply_to() =~ /^list$/io) {
	$param->{'replyto'}= "$param->{'to'}";
    }
    
    my @tabrcpt ;
    my @tabrcptsummary;
    my @tabrcptplain;
    my $i;
    
    my (@list_of_mail);

    ## Create the list of subscribers in various digest modes
    for (my $user = $self->get_first_list_member(); $user; $user = $self->get_next_list_member()) {
	my $options;
	$options->{'email'} = $user->{'email'};
	$options->{'name'} = $self->{'name'};
	$options->{'domain'} = $self->{'domain'};
	my $user_data = &get_list_member_no_object($options);
	## test to know if the rcpt suspended her subscription for this list
	## if yes, don't send the message
	if ($user_data->{'suspend'} eq '1'){
	    if(($user_data->{'startdate'} <= time) && ((time <= $user_data->{'enddate'}) || (!$user_data->{'enddate'}))){
		next;
	    }elsif(($user_data->{'enddate'} < time) && ($user_data->{'enddate'})){
		## If end date is < time, update the BDD by deleting the suspending's data
		&restore_suspended_subscription($user->{'email'},$self->{'name'},$self->{'domain'});
	    }
	}
	if ($user->{'reception'} eq "digest") {
	    push @tabrcpt, $user->{'email'};

	}elsif ($user->{'reception'} eq "summary") {
	    ## Create the list of subscribers in summary mode
	    push @tabrcptsummary, $user->{'email'};
        
	}elsif ($user->{'reception'} eq "digestplain") {
	    push @tabrcptplain, $user->{'email'};              
	}
    }
    if (($#tabrcptsummary == -1) and ($#tabrcpt == -1) and ($#tabrcptplain == -1)) {
	&Log::do_log('info', 'No subscriber for sending digest in list %s', $listname);
	return 0;
    }

    my $old = $/;
    local $/ = "\n\n" . &tools::get_separator() . "\n\n";
    
    ## Digest split in individual messages
    open DIGEST, $filename or return undef;
    foreach (<DIGEST>){
	
	my @text = split /\n/;
	pop @text; pop @text;
	
	## Restore carriage returns
	foreach $i (0 .. $#text) {
	    $text[$i] .= "\n";
	}
	
	my $parser = new MIME::Parser;
	$parser->output_to_core(1);
	$parser->extract_uuencode(1);  
	$parser->extract_nested_messages(1);
#   $parser->output_dir($Conf::Conf{'spool'} ."/tmp");    
	my $mail = $parser->parse_data(\@text);
	
	next unless (defined $mail);

	push @list_of_mail, $mail;
    }
    close DIGEST;
    local $/ = $old;

    ## Deletes the introduction part
    splice @list_of_mail, 0, 1;
    
    ## Digest index
    my @all_msg;
    foreach $i (0 .. $#list_of_mail){
	my $mail = $list_of_mail[$i];
	my $subject = &MIME::EncWords::decode_mimewords($mail->head->get('Subject'), Charset=>'utf8');
	chomp $subject;
	my $from = &MIME::EncWords::decode_mimewords($mail->head->get('From'), Charset=>'utf8');
	chomp $from;    
	my $date = &MIME::EncWords::decode_mimewords($mail->head->get('Date'), Charset=>'utf8');
	chomp $date;    
	
        my $msg = {};
	$msg->{'id'} = $i+1;
        $msg->{'subject'} = $subject;	
	$msg->{'from'} = $from;
	$msg->{'date'} = $date;
	
	#$mail->tidy_body;
	
        ## Commented because one Spam made Sympa die (MIME::tools 5.413)
	#$mail->remove_sig;
	
	$msg->{'full_msg'} = $mail->as_string;
	$msg->{'body'} = $mail->body_as_string;
	$msg->{'plain_body'} = $mail->PlainDigest::plain_body_as_string();
	#$msg->{'body'} = $mail->bodyhandle->as_string();
	chomp $msg->{'from'};
	$msg->{'month'} = &POSIX::strftime("%Y-%m", localtime(time)); ## Should be extracted from Date:
	$msg->{'message_id'} = &tools::clean_msg_id($mail->head->get('Message-Id'));
	
	## Clean up Message-ID
	$msg->{'message_id'} = &tools::escape_chars($msg->{'message_id'});

        #push @{$param->{'msg_list'}}, $msg ;
	push @all_msg, $msg ;	
    }
    
    my @now  = localtime(time);
    $param->{'datetime'} = gettext_strftime "%a, %d %b %Y %H:%M:%S", @now;
    $param->{'date'} = gettext_strftime "%a, %d %b %Y", @now;

    ## Split messages into groups of digest_max_size size
    my @group_of_msg;
    while (@all_msg) {
	my @group = splice @all_msg, 0, $self->{'admin'}{'digest_max_size'};
	
	push @group_of_msg, \@group;
    }
    

    $param->{'current_group'} = 0;
    $param->{'total_group'} = $#group_of_msg + 1;
    ## Foreach set of digest_max_size messages...
    foreach my $group (@group_of_msg) {
	
	$param->{'current_group'}++;
	$param->{'msg_list'} = $group;
	$param->{'auto_submitted'} = 'auto-forwarded';
	
	## Prepare Digest
	if (@tabrcpt) {
	    ## Send digest
	    unless ($self->send_file('digest', \@tabrcpt, $robot, $param)) {
		&Log::do_log('notice',"Unable to send template 'digest' to $self->{'name'} list subscribers");
	    }
	}    
	
	## Prepare Plain Text Digest
	if (@tabrcptplain) {
	    ## Send digest-plain
	    unless ($self->send_file('digest_plain', \@tabrcptplain, $robot, $param)) {
		&Log::do_log('notice',"Unable to send template 'digest_plain' to $self->{'name'} list subscribers");
	    }
	}    
	
	
	## send summary
	if (@tabrcptsummary) {
	    unless ($self->send_file('summary', \@tabrcptsummary, $robot, $param)) {
		&Log::do_log('notice',"Unable to send template 'summary' to $self->{'name'} list subscribers");
	    }
	}
    }    
    
    return 1;
}


#########################   TEMPLATE SENDING  ##########################################


####################################################
# send_global_file                              
####################################################
#  Send a global (not relative to a list) 
#  message to a user.
#  Find the tt2 file according to $tpl, set up 
#  $data for the next parsing (with $context and
#  configuration )
#  
# IN : -$tpl (+): template file name (file.tt2),
#         without tt2 extension
#      -$who (+): SCALAR |ref(ARRAY) - recipient(s)
#      -$robot (+): robot
#      -$context : ref(HASH) - for the $data set up 
#         to parse file tt2, keys can be :
#         -user : ref(HASH), keys can be :
#           -email
#           -lang
#           -password
#         -auto_submitted auto-generated|auto-replied|auto-forwarded
#         -...
#      -$options : ref(HASH) - options
# OUT : 1 | undef
#       
####################################################
sub send_global_file {
    my($tpl, $who, $robot, $context, $options) = @_;
    &Log::do_log('debug2', 'List::send_global_file(%s, %s, %s)', $tpl, $who, $robot);

    my $data = &tools::dup_var($context);

    unless ($data->{'user'}) {
	$data->{'user'} = &get_global_user($who) unless ($options->{'skip_db'});
	$data->{'user'}{'email'} = $who unless (defined $data->{'user'});;
    }
    unless ($data->{'user'}{'lang'}) {
	$data->{'user'}{'lang'} = $Language::default_lang;
    }
    
    unless ($data->{'user'}{'password'}) {
	$data->{'user'}{'password'} = &tools::tmp_passwd($who);
    }

    ## Lang
    $data->{'lang'} = $data->{'lang'} || $data->{'user'}{'lang'} || &Conf::get_robot_conf($robot, 'lang');

    ## What file 
    my $lang = &Language::Lang2Locale($data->{'lang'});
    my $tt2_include_path = &tools::make_tt2_include_path($robot,'mail_tt2',$lang,'');

    foreach my $d (@{$tt2_include_path}) {
	&tt2::add_include_path($d);
    }

    my @path = &tt2::get_include_path();
    my $filename = &tools::find_file($tpl.'.tt2',@path);
 
    unless (defined $filename) {
	&Log::do_log('err','Could not find template %s.tt2 in %s', $tpl, join(':',@path));
	return undef;
    }

    foreach my $p ('email','host','sympa','request','listmaster','wwsympa_url','title','listmaster_email') {
	$data->{'conf'}{$p} = &Conf::get_robot_conf($robot, $p);
    }

    $data->{'sender'} = $who;
    $data->{'conf'}{'version'} = $main::Version;
    $data->{'from'} = "$data->{'conf'}{'email'}\@$data->{'conf'}{'host'}" unless ($data->{'from'});
    $data->{'robot_domain'} = $robot;
    $data->{'return_path'} = &Conf::get_robot_conf($robot, 'request');
    $data->{'boundary'} = '----------=_'.&tools::get_message_id($robot) unless ($data->{'boundary'});

    if ((&Conf::get_robot_conf($robot, 'dkim_feature') eq 'on')&&(&Conf::get_robot_conf($robot, 'dkim_add_signature_to')=~/robot/)){
	$data->{'dkim'} = &tools::get_dkim_parameters({'robot' => $robot});
    }
    
    $data->{'use_bulk'} = 1  unless ($data->{'alarm'}) ; # use verp excepted for alarms. We should make this configurable in order to support Sympa server on a machine without any MTA service
    unless (&mail::mail_file($filename, $who, $data, $robot)) {
	&Log::do_log('err',"List::send_global_file, could not send template $filename to $who");
	return undef;
    }

    return 1;
}

####################################################
# send_file                              
####################################################
#  Send a message to a user, relative to a list.
#  Find the tt2 file according to $tpl, set up 
#  $data for the next parsing (with $context and
#  configuration)
#  Message is signed if the list has a key and a 
#  certificate
#  
# IN : -$self (+): ref(List)
#      -$tpl (+): template file name (file.tt2),
#         without tt2 extension
#      -$who (+): SCALAR |ref(ARRAY) - recipient(s)
#      -$robot (+): robot
#      -$context : ref(HASH) - for the $data set up 
#         to parse file tt2, keys can be :
#         -user : ref(HASH), keys can be :
#           -email
#           -lang
#           -password
#         -auto_submitted auto-generated|auto-replied|auto-forwarded
#         -...
# OUT : 1 | undef
####################################################
sub send_file {
    my($self, $tpl, $who, $robot, $context) = @_;
    &Log::do_log('debug2', 'List::send_file(%s, %s, %s)', $tpl, $who, $robot);

    my $name = $self->{'name'};
    my $sign_mode;

    my $data = &tools::dup_var($context);

    ## Any recipients
    if ((ref ($who) && ($#{$who} < 0)) ||
	(!ref ($who) && ($who eq ''))) {
	&Log::do_log('err', 'No recipient for sending %s', $tpl);
	return undef;
    }
    
    ## Unless multiple recipients
    unless (ref ($who)) {
	unless ($data->{'user'}) {
	    unless ($data->{'user'} = &get_global_user($who)) {
		$data->{'user'}{'email'} = $who;
		$data->{'user'}{'lang'} = $self->{'admin'}{'lang'};
	    }
	}
	
	$data->{'subscriber'} = $self->get_list_member($who);
	
	if ($data->{'subscriber'}) {
	    $data->{'subscriber'}{'date'} = gettext_strftime "%d %b %Y", localtime($data->{'subscriber'}{'date'});
	    $data->{'subscriber'}{'update_date'} = gettext_strftime "%d %b %Y", localtime($data->{'subscriber'}{'update_date'});
	    if ($data->{'subscriber'}{'bounce'}) {
		$data->{'subscriber'}{'bounce'} =~ /^(\d+)\s+(\d+)\s+(\d+)(\s+(.*))?$/;
		
		$data->{'subscriber'}{'first_bounce'} = gettext_strftime "%d %b %Y", localtime($1);
	    }
	}
	
	unless ($data->{'user'}{'password'}) {
	    $data->{'user'}{'password'} = &tools::tmp_passwd($who);
	}
	
	## Unique return-path VERP
	if ((($self->{'admin'}{'welcome_return_path'} eq 'unique') && ($tpl eq 'welcome')) ||
	    (($self->{'admin'}{'remind_return_path'} eq 'unique') && ($tpl eq 'remind')))  {
	    my $escapercpt = $who ;
	    $escapercpt =~ s/\@/\=\=a\=\=/;
	    $data->{'return_path'} = "$Conf::Conf{'bounce_email_prefix'}+$escapercpt\=\=$name";
	    $data->{'return_path'} .= '==w' if ($tpl eq 'welcome');
	    $data->{'return_path'} .= '==r' if ($tpl eq 'remind');
	    $data->{'return_path'} .= "\@$self->{'domain'}";
	}
    }

    $data->{'return_path'} ||= $name.&Conf::get_robot_conf($robot, 'return_path_suffix').'@'.$self->{'admin'}{'host'};

    ## Lang
    $data->{'lang'} = $data->{'user'}{'lang'} || $self->{'admin'}{'lang'} || &Conf::get_robot_conf($robot, 'lang');

    ## Trying to use custom_vars
    if (defined $self->{'admin'}{'custom_vars'}) {
	$data->{'custom_vars'} = {};
	foreach my $var (@{$self->{'admin'}{'custom_vars'}}) {
 	    $data->{'custom_vars'}{$var->{'name'}} = $var->{'value'};
	}
    }
    
    ## What file   
    my $lang = &Language::Lang2Locale($data->{'lang'});
    my $tt2_include_path = &tools::make_tt2_include_path($robot,'mail_tt2',$lang,$self);

    push @{$tt2_include_path},$self->{'dir'};             ## list directory to get the 'info' file
    push @{$tt2_include_path},$self->{'dir'}.'/archives'; ## list archives to include the last message

    foreach my $d (@{$tt2_include_path}) {
	&tt2::add_include_path($d);
    }

    foreach my $p ('email','host','sympa','request','listmaster','wwsympa_url','title','listmaster_email') {
	$data->{'conf'}{$p} = &Conf::get_robot_conf($robot, $p);
    }

    my @path = &tt2::get_include_path();
    my $filename = &tools::find_file($tpl.'.tt2',@path);
    
    unless (defined $filename) {
	&Log::do_log('err','Could not find template %s.tt2 in %s', $tpl, join(':',@path));
	return undef;
    }

    $data->{'sender'} ||= $who;
    $data->{'list'}{'lang'} = $self->{'admin'}{'lang'};
    $data->{'list'}{'name'} = $name;
    $data->{'list'}{'domain'} = $data->{'robot_domain'} = $robot;
    $data->{'list'}{'host'} = $self->{'admin'}{'host'};
    $data->{'list'}{'subject'} = $self->{'admin'}{'subject'};
    $data->{'list'}{'owner'} = $self->get_owners();
    $data->{'list'}{'dir'} = $self->{'dir'};

    ## Sign mode
    if ($Conf::Conf{'openssl'} &&
	(-r $self->{'dir'}.'/cert.pem') && (-r $self->{'dir'}.'/private_key')) {
	$sign_mode = 'smime';
    }

    # if the list have it's private_key and cert sign the message
    # . used only for the welcome message, could be usefull in other case? 
    # . a list should have several certificats and use if possible a certificat
    #   issued by the same CA as the receipient CA if it exists 
    if ($sign_mode eq 'smime') {
	$data->{'fromlist'} = "$name\@$data->{'list'}{'host'}";
	$data->{'replyto'} = "$name"."-request\@$data->{'list'}{'host'}";
    }else{
	$data->{'fromlist'} = "$name"."-request\@$data->{'list'}{'host'}";
    }

    $data->{'from'} = $data->{'fromlist'} unless ($data->{'from'});
    $data->{'boundary'} = '----------=_'.&tools::get_message_id($robot) unless ($data->{'boundary'});
    $data->{'sign_mode'} = $sign_mode;
    
    if ((&Conf::get_robot_conf($self->{'domain'}, 'dkim_feature') eq 'on')&&(&Conf::get_robot_conf($self->{'domain'}, 'dkim_add_signature_to')=~/robot/)){
	$data->{'dkim'} = &tools::get_dkim_parameters({'robot' => $self->{'domain'}});
    } 
    $data->{'use_bulk'} = 1  unless ($data->{'alarm'}) ; # use verp excepted for alarms. We should make this configurable in order to support Sympa server on a machine without any MTA service
    unless (&mail::mail_file($filename, $who, $data, $self->{'domain'})) {
	&Log::do_log('err',"List::send_file, could not send template $filename to $who");
	return undef;
    }

    return 1;
}

####################################################
# send_msg                              
####################################################
# selects subscribers according to their reception 
# mode in order to distribute a message to a list
# and sends the message to them. For subscribers in reception mode 'mail', 
# and in a msg topic context, selects only one who are subscribed to the topic
# of the message.
# 
#  
# IN : -$self (+): ref(List)  
#      -$message (+): ref(Message)
# OUT : -$numsmtp : number of sendmail process 
#       | 0 : no subscriber for sending message in list
#       | undef 
####################################################
sub send_msg {

    my $self = shift;
    my %param = @_;

    my $message = $param{'message'};
    my $apply_dkim_signature = $param{'apply_dkim_signature'};
    my $apply_tracking = $param{'apply_tracking'};

    &Log::do_log('debug2', 'List::send_msg(filname = %s, smime_crypted = %s,apply_dkim_signature = %s )', $message->{'filename'}, $message->{'smime_crypted'},$apply_dkim_signature);
    my $hdr = $message->{'msg'}->head;
    my $original_message_id = $hdr->get('Message-Id');
    my $name = $self->{'name'};
    my $robot = $self->{'domain'};
    my $admin = $self->{'admin'};
    my $total = $self->get_total('nocache');
    my $sender_line = $hdr->get('From');
    my @sender_hdr = Mail::Address->parse($sender_line);
    my %sender_hash;
    foreach my $email (@sender_hdr) {
	$sender_hash{lc($email->address)} = 1;
    }
   
    unless (ref($message) eq 'Message') {
	&Log::do_log('err', 'Invalid message paramater');
	return undef;	
    }

    unless ($total > 0) {
	&Log::do_log('info', 'No subscriber in list %s', $name);
	return 0;
    }

    ## Bounce rate
    my $rate = $self->get_total_bouncing() * 100 / $total;
    if ($rate > $self->{'admin'}{'bounce'}{'warn_rate'}) {
	unless ($self->send_notify_to_owner('bounce_rate',{'rate' => $rate})) {
	    &Log::do_log('notice',"Unable to send notify 'bounce_rate' to $self->{'name'} listowner");
	}
    }
 
    ## Who is the enveloppe sender?
    my $host = $self->{'admin'}{'host'};
    my $from = $name.&Conf::get_robot_conf($robot, 'return_path_suffix').'@'.$host;

    # separate subscribers depending on user reception option and also if verp a dicovered some bounce for them.
    my (@tabrcpt, @tabrcpt_notice, @tabrcpt_txt, @tabrcpt_html, @tabrcpt_url, @tabrcpt_verp, @tabrcpt_notice_verp, @tabrcpt_txt_verp, @tabrcpt_html_verp, @tabrcpt_url_verp, @tabrcpt_digestplain, @tabrcpt_digest, @tabrcpt_summary, @tabrcpt_nomail, @tabrcpt_digestplain_verp, @tabrcpt_digest_verp, @tabrcpt_summary_verp, @tabrcpt_nomail_verp );
    my $mixed = ($message->{'msg'}->head->get('Content-Type') =~ /multipart\/mixed/i);
    my $alternative = ($message->{'msg'}->head->get('Content-Type') =~ /multipart\/alternative/i);
 
    for ( my $user = $self->get_first_list_member(); $user; $user = $self->get_next_list_member() ){
	unless ($user->{'email'}) {
	    &Log::do_log('err','Skipping user with no email address in list %s', $name);
	    next;
	}
	my $options;
	$options->{'email'} = $user->{'email'};
	$options->{'name'} = $name;
	$options->{'domain'} = $host;
	my $user_data = &get_list_member_no_object($options);
	## test to know if the rcpt suspended her subscription for this list
	## if yes, don't send the message
	if ($user_data->{'suspend'} eq '1'){
	    if(($user_data->{'startdate'} <= time) && ((time <= $user_data->{'enddate'}) || (!$user_data->{'enddate'}))){
		push @tabrcpt_nomail_verp, $user->{'email'}; next;
	    }elsif(($user_data->{'enddate'} < time) && ($user_data->{'enddate'})){
		## If end date is < time, update the BDD by deleting the suspending's data
		&restore_suspended_subscription($user->{'email'},$name,$host);
	    }
	}
	if ($user->{'reception'} eq 'digestplain') { # digest digestplain, nomail and summary reception option are initialized for tracking feature only
	    push @tabrcpt_digestplain_verp, $user->{'email'}; next;
	}elsif($user->{'reception'} eq 'digest') {
	    push @tabrcpt_digest_verp, $user->{'email'}; next;
	}elsif($user->{'reception'} eq 'summary'){
	    push @tabrcpt_summary_verp, $user->{'email'}; next;
	}elsif($user->{'reception'} eq 'nomail'){
	    push @tabrcpt_nomail_verp, $user->{'email'}; next;
	}elsif ($user->{'reception'} eq 'notice') {
	    if ($user->{'bounce_address'}) {
		push @tabrcpt_notice_verp, $user->{'email'}; 
	    }else{
		push @tabrcpt_notice, $user->{'email'}; 
	    }
	}elsif ($alternative and ($user->{'reception'} eq 'txt')) {
	    if ($user->{'bounce_address'}) {
		push @tabrcpt_txt_verp, $user->{'email'};
	    }else{
		push @tabrcpt_txt, $user->{'email'};
	    }
	}elsif ($alternative and ($user->{'reception'} eq 'html')) {
	    if ($user->{'bounce_address'}) {
		push @tabrcpt_html_verp, $user->{'email'};
	    }else{
		if ($user->{'bounce_address'}) {
		    push @tabrcpt_html_verp, $user->{'email'};
		}else{
		    push @tabrcpt_html, $user->{'email'};
		}    
	    }
	}elsif ($mixed and ($user->{'reception'} eq 'urlize')) {
	    if ($user->{'bounce_address'}) {
		push @tabrcpt_url_verp, $user->{'email'};
	    }else{
		push @tabrcpt_url, $user->{'email'};
	    }
	}elsif ($message->{'smime_crypted'} && 
		 (! -r $Conf::Conf{'ssl_cert_dir'}.'/'.&tools::escape_chars($user->{'email'}) &&
		  ! -r $Conf::Conf{'ssl_cert_dir'}.'/'.&tools::escape_chars($user->{'email'}.'@enc' ))) {
	    ## Missing User certificate
	    unless ($self->send_file('x509-user-cert-missing', $user->{'email'}, $robot, {'mail' => {'subject' => $message->{'msg'}->head->get('Subject'),
												     'sender' => $message->{'msg'}->head->get('From')},
											  'auto_submitted' => 'auto-generated'})) {
	    &Log::do_log('notice',"Unable to send template 'x509-user-cert-missing' to $user->{'email'}");
	    }
	}else{
	    if ($user->{'bounce_score'}) {
		push @tabrcpt_verp, $user->{'email'} unless ($sender_hash{$user->{'email'}})&&($user->{'reception'} eq 'not_me');
	    }else{	    
		push @tabrcpt, $user->{'email'} unless ($sender_hash{$user->{'email'}})&&($user->{'reception'} eq 'not_me');}
	    }	    
    }

    unless (@tabrcpt || @tabrcpt_notice || @tabrcpt_txt || @tabrcpt_html || @tabrcpt_url || @tabrcpt_verp || @tabrcpt_notice_verp || @tabrcpt_txt_verp || @tabrcpt_html_verp || @tabrcpt_url_verp) {
	&Log::do_log('info', 'No subscriber for sending msg in list %s', $name);
	return 0;
    }

    #save the message before modifying it
    my $saved_msg = $message->{'msg'}->dup;
    my $nbr_smtp = 0;
    my $nbr_verp = 0;

    # prepare verp parameter
    my $verp_rate =  $self->{'admin'}{'verp_rate'};
    $verp_rate = '100%' if (($apply_tracking eq 'dsn')||($apply_tracking eq 'mdn')); # force verp if tracking is requested.  

    my $xsequence =  $self->{'stats'}->[0] ;
    my $tags_to_use;

    # Define messages which can be tagged as first or last according to the verp rate.
    # If the VERP is 100%, then all the messages are VERP. Don't try to tag not VERP
    # messages as they won't even exist.
    if($verp_rate eq '0%'){
	$tags_to_use->{'tag_verp'} = 0;
	$tags_to_use->{'tag_noverp'} = 1;
    }else{
	$tags_to_use->{'tag_verp'} = 1;
	$tags_to_use->{'tag_noverp'} = 0;
    }
 
    my $dkim_parameters ;
    # prepare dkim parameters
    if ($apply_dkim_signature eq 'on') {
	$dkim_parameters = &tools::get_dkim_parameters({'robot'=>$self->{'domain'}, 'listname'=>$self->{'name'}});
    }
    ## Storing the not empty subscribers' arrays into a hash.
    my $available_rcpt;
    my $available_verp_rcpt;


    if (@tabrcpt) {
	$available_rcpt->{'tabrcpt'} = \@tabrcpt;
	$available_verp_rcpt->{'tabrcpt'} = \@tabrcpt_verp;	
    }
    if (@tabrcpt_notice) {
	$available_rcpt->{'tabrcpt_notice'} = \@tabrcpt_notice;
	$available_verp_rcpt->{'tabrcpt_notice'} = \@tabrcpt_notice_verp;
    }
    if (@tabrcpt_txt) {
	$available_rcpt->{'tabrcpt_txt'} = \@tabrcpt_txt;
	$available_verp_rcpt->{'tabrcpt_txt'} = \@tabrcpt_txt_verp;
    }
    if (@tabrcpt_html) {
	$available_rcpt->{'tabrcpt_html'} = \@tabrcpt_html;
	$available_verp_rcpt->{'tabrcpt_html'} = \@tabrcpt_html_verp;
    }
    if (@tabrcpt_url) {
	$available_rcpt->{'tabrcpt_url'} = \@tabrcpt_url;
	$available_verp_rcpt->{'tabrcpt_url'} = \@tabrcpt_url_verp;
    }
    if (@tabrcpt_digestplain_verp)  {
	$available_rcpt->{'tabrcpt_digestplain'} = \@tabrcpt_digestplain;
	$available_verp_rcpt->{'tabrcpt_digestplain'} = \@tabrcpt_digestplain_verp;
    }
    if (@tabrcpt_digest_verp) {
	$available_rcpt->{'tabrcpt_digest'} = \@tabrcpt_digest;
	$available_verp_rcpt->{'tabrcpt_digest'} = \@tabrcpt_digest_verp;
    }
    if (@tabrcpt_summary_verp) {
	$available_rcpt->{'tabrcpt_summary'} = \@tabrcpt_summary;
	$available_verp_rcpt->{'tabrcpt_summary'} = \@tabrcpt_summary_verp;
    }
    if (@tabrcpt_nomail_verp) {
	$available_rcpt->{'tabrcpt_nomail'} = \@tabrcpt_nomail;
	$available_verp_rcpt->{'tabrcpt_nomail'} = \@tabrcpt_nomail_verp;
    }
    foreach my $array_name (keys %$available_rcpt) {
	my $reception_option ;	 
	if ($array_name =~ /^tabrcpt_((nomail)|(summary)|(digest)|(digestplain)|(url)|(html)|(txt)|(notice))?(_verp)?/) {
	    $reception_option =  $1;	    
	    $reception_option = 'mail' unless $reception_option ;
	}
	my $new_message;
	##Prepare message for normal reception mode
	if ($array_name eq 'tabrcpt'){
	    ## Add a footer
	    unless ($message->{'protected'}) {
		my $new_msg = $self->add_parts($message->{'msg'});
		if (defined $new_msg) {
		    $message->{'msg'} = $new_msg;
		    $message->{'altered'} = '_ALTERED_';
		}
	    }
	    $new_message = $message;	    
	}elsif(($array_name eq 'tabrcpt_nomail')||($array_name eq 'tabrcpt_summary')||($array_name eq 'tabrcpt_digest')||($array_name eq 'tabrcpt_digestplain')){
	    $new_message = $message;
	}	##Prepare message for notice reception mode
	elsif($array_name eq 'tabrcpt_notice'){
	    my $notice_msg = $saved_msg->dup;
	    $notice_msg->bodyhandle(undef);    
	    $notice_msg->parts([]);
	    $new_message = new Message({'mimeentity' => $notice_msg});

	##Prepare message for txt reception mode
	}elsif($array_name eq 'tabrcpt_txt'){
	    my $txt_msg = $saved_msg->dup;
	    if (&tools::as_singlepart($txt_msg, 'text/plain')) {
		do_log('notice', 'Multipart message changed to singlepart');
	    }
	    
	    ## Add a footer
	    my $new_msg = $self->add_parts($txt_msg);
	    if (defined $new_msg) {
		$txt_msg = $new_msg;
	    }
	    $new_message = new Message({'mimeentity' => $txt_msg});

	##Prepare message for html reception mode
	}elsif($array_name eq 'tabrcpt_html'){
	    my $html_msg = $saved_msg->dup;
	    if (&tools::as_singlepart($html_msg, 'text/html')) {
		do_log('notice', 'Multipart message changed to singlepart');
	    }
	    ## Add a footer
	    my $new_msg = $self->add_parts($html_msg);
	    if (defined $new_msg) {
		$html_msg = $new_msg;
	    }
	    $new_message = new Message({'mimeentity' => $html_msg});
	    
	##Prepare message for urlize reception mode
	}elsif($array_name eq 'tabrcpt_url'){
	    my $url_msg = $saved_msg->dup; 
	    
	    my $expl = $self->{'dir'}.'/urlized';
	    
	    unless ((-d $expl) ||( mkdir $expl, 0775)) {
		do_log('err', "Unable to create urlize directory $expl");
		return undef;
	    }
	    
	    my $dir1 = &tools::clean_msg_id($url_msg->head->get('Message-ID'));
	    
	    ## Clean up Message-ID
	    $dir1 = &tools::escape_chars($dir1);
	    $dir1 = '/'.$dir1;
	    
	    unless ( mkdir ("$expl/$dir1", 0775)) {
		do_log('err', "Unable to create urlize directory $expl/$dir1");
		printf "Unable to create urlized directory $expl/$dir1";
		return 0;
	    }
	    my $mime_types = &tools::load_mime_types();
	    my @parts = $url_msg->parts();
	    
	    foreach my $i (0..$#parts) {
		my $entity = &_urlize_part ($url_msg->parts ($i), $self, $dir1, $i, $mime_types,  &Conf::get_robot_conf($robot, 'wwsympa_url')) ;
		if (defined $entity) {
		    $parts[$i] = $entity;
		}
	    }
	    
	    ## Replace message parts
	    $url_msg->parts (\@parts);
	    
	    ## Add a footer
	    my $new_msg = $self->add_parts($url_msg);
	    if (defined $new_msg) {
		$url_msg = $new_msg;
	    } 
	    $new_message = new Message({'mimeentity' => $url_msg});
	}else {
	    &Log::do_log('err', "Unknown variable/reception mode $array_name");
	    return undef;
	}

	unless (defined $new_message) {
		do_log('err', "Failed to create Message object");
		return undef;	    
	}

	## TOPICS
	my @selected_tabrcpt;
	my @possible_verptabrcpt;
	if ($self->is_there_msg_topic()){
	    @selected_tabrcpt = $self->select_list_members_for_topic($new_message->get_topic(),$available_rcpt->{$array_name});
	    @possible_verptabrcpt = $self->select_list_members_for_topic($new_message->get_topic(),$available_verp_rcpt->{$array_name});
	} else {
	    @selected_tabrcpt = @{$available_rcpt->{$array_name}};
	    @possible_verptabrcpt = @{$available_verp_rcpt->{$array_name}};
	}
	
	if ($array_name =~ /^tabrcpt_((nomail)|(summary)|(digest)|(digestplain)|(url)|(html)|(txt)|(notice))?(_verp)?/) {
	    my $reception_option =  $1;
	    
	    $reception_option = 'mail' unless $reception_option ;
	}
	
	## Preparing VERP receipients.
	my @verp_selected_tabrcpt = &extract_verp_rcpt($verp_rate, $xsequence,\@selected_tabrcpt, \@possible_verptabrcpt);
	my $verp= 'off';		
	my $result = &mail::mail_message('message'=>$new_message, 
					 'rcpt'=> \@selected_tabrcpt, 
					 'list'=>$self, 
					 'verp' => $verp,					 
					 'dkim_parameters'=>$dkim_parameters,
					 'tag_as_last' => $tags_to_use->{'tag_noverp'});
	unless (defined $result) {
	    &Log::do_log('err',"List::send_msg, could not send message to distribute from $from (verp desabled)");
	    return undef;
	}
	$tags_to_use->{'tag_noverp'} = 0 if ($result > 0);
	$nbr_smtp += $result;
	
	$verp= 'on';

	if (($apply_tracking eq 'dsn')||($apply_tracking eq 'mdn')){
	    $verp = $apply_tracking ;
	    &tracking::db_init_notification_table('listname'=> $self->{'name'},
						  'robot'=> $robot,
						  'msgid' => $original_message_id, # what ever the message is transformed because of the reception option, tracking use the original message id
						  'rcpt'=> \@verp_selected_tabrcpt, 
						  'reception_option' => $reception_option,
						  );
	    
	}	

	#  ignore those reception option where mail must not ne sent
        #  next if  (($array_name eq 'tabrcpt_digest') or ($array_name eq 'tabrcpt_digestlplain') or ($array_name eq 'tabrcpt_summary') or ($array_name eq 'tabrcpt_nomail')) ;
	next if  ($array_name =~ /^tabrcpt_((nomail)|(summary)|(digest)|(digestplain))(_verp)?/);
	
	## prepare VERP sending.
	$result = &mail::mail_message('message'=> $new_message, 
				      'rcpt'=> \@verp_selected_tabrcpt, 
				      'list'=> $self,
				      'verp' => $verp,
				      'dkim_parameters'=>$dkim_parameters,
				      'tag_as_last' => $tags_to_use->{'tag_verp'});
	unless (defined $result) {
	    &Log::do_log('err',"List::send_msg, could not send message to distribute from $from (verp enabled)");
	    return undef;
	}
	$tags_to_use->{'tag_verp'} = 0 if ($result > 0);
	$nbr_smtp += $result;
	$nbr_verp += $result;	
    }
    return $nbr_smtp;
}

#########################   SERVICE MESSAGES   ##########################################

###############################################################
# send_to_editor
###############################################################
# Sends a message to the list editor to ask him for moderation 
# ( in moderation context : editor or editorkey). The message 
# to moderate is set in spool queuemod with name containing
# a key (reference send to editor for moderation)
# In context of msg_topic defined the editor must tag it 
# for the moderation (on Web interface)
#  
# IN : -$self(+) : ref(List)
#      -$method : 'md5' - for "editorkey" | 'smtp' - for "editor"
#      -$message(+) : ref(Message) - the message to moderatte
# OUT : $modkey : the moderation key for naming message waiting 
#         for moderation in spool queuemod
#       | undef
#################################################################
sub send_to_editor {
   my($self, $method, $message) = @_;
   my ($msg, $file, $encrypt) = ($message->{'msg'}, $message->{'filename'});

   $encrypt = 'smime_crypted' if ($message->{'smime_crypted'}); 
   &Log::do_log('debug3', "List::send_to_editor, msg: $msg, file: $file method : $method, encrypt : $encrypt");

   my($i, @rcpt);
   my $admin = $self->{'admin'};
   my $name = $self->{'name'};
   my $host = $admin->{'host'};
   my $robot = $self->{'domain'};
   my $modqueue = $Conf::Conf{'queuemod'};
   return unless ($name && $admin);
  
   my @now = localtime(time);
   my $messageid=$now[6].$now[5].$now[4].$now[3].$now[2].$now[1]."."
                 .int(rand(6)).int(rand(6)).int(rand(6)).int(rand(6)).int(rand(6)).int(rand(6))."\@".$host;
   my $modkey=Digest::MD5::md5_hex(join('/', $self->get_cookie(),$messageid));
   my $boundary ="__ \<$messageid\>";
   
   ## Keeps a copy of the message
   if ($method eq 'md5'){  
       my $mod_file = $modqueue.'/'.$self->get_list_id().'_'.$modkey;
       unless (open(OUT, ">$mod_file")) {
	   &Log::do_log('notice', 'Could Not open %s', $mod_file);
	   return undef;
       }

       unless (open (MSG, $file)) {
	   &Log::do_log('notice', 'Could not open %s', $file);
	   return undef;   
       }

       print OUT <MSG>;
       close MSG ;
       close(OUT);

       my $tmp_dir = $modqueue.'/.'.$self->get_list_id().'_'.$modkey;
       unless (-d $tmp_dir) {
	   unless (mkdir ($tmp_dir, 0777)) {
	       &Log::do_log('err','Unable to create %s', $tmp_dir);
	       return undef;
	   }
	   my $mhonarc_ressources = &tools::get_filename('etc',{},'mhonarc-ressources.tt2', $robot, $self);

	   unless ($mhonarc_ressources) {
	       &Log::do_log('notice',"Cannot find any MhOnArc ressource file");
	       return undef;
	   }
	   ## generate HTML
	   chdir $tmp_dir;
	   my $mhonarc = &Conf::get_robot_conf($robot, 'mhonarc');
	   my $base_url = &Conf::get_robot_conf($robot, 'wwsympa_url');
	   open ARCMOD, "$mhonarc  -single --outdir .. -rcfile $mhonarc_ressources -definevars listname=$name -definevars hostname=$host -attachmenturl=viewmod/$name/$modkey $mod_file|";
	   open MSG, ">msg00000.html";
	   &Log::do_log('debug', "$mhonarc  -single -rcfile $mhonarc_ressources -definevars listname=$name -definevars hostname=$host $mod_file");
	   print MSG <ARCMOD>;
	   close MSG;
	   close ARCMOD;
	   chdir $Conf::Conf{'home'};
       }
   }

   @rcpt = $self->get_editors_email();
   
   my $hdr = $message->{'msg'}->head;

   ## Did we find a recipient?
   if ($#rcpt < 0) {
       &Log::do_log('notice', "No editor found for list %s. Trying to proceed ignoring nomail option", $self->{'name'});
       my $messageid = $hdr->get('Message-Id');
       
       @rcpt = $self->get_editors_email({'ignore_nomail',1});
       &Log::do_log('notice', 'Warning : no owner and editor defined at all in list %s', $name ) unless (@rcpt);
       
       ## Could we find a recipient by ignoring the "nomail" option?
       if ($#rcpt >= 0) {
	   &Log::do_log('notice', 'All the intended recipients of message %s in list %s have set the "nomail" option. Ignoring it and sending it to all of them.', $messageid, $self->{'name'} );
       }
       else {
	   &Log::do_log ('err','Impossible to send the moderation request for message %s to editors of list %s. Neither editor nor owner defined!',$messageid,$self->{'name'}) ;
	   return undef;
       }
   }
   
   my $subject = MIME::EncWords::decode_mimewords($hdr->get('Subject'), Charset=>'utf8');
   my $param = {'modkey' => $modkey,
		'boundary' => $boundary,
		'msg_from' => $message->{'sender'},
		'subject' => $subject,
		'spam_status' => $message->{'spam_status'},
		'mod_spool_size' => $self->get_mod_spool_size(),
		'method' => $method};

   if ($self->is_there_msg_topic()) {
       $param->{'request_topic'} = 1;
   }

       foreach my $recipient (@rcpt) {
       if ($encrypt eq 'smime_crypted') {	       
	   ## is $msg->body_as_string respect base64 number of char per line ??
	   my $cryptedmsg = &tools::smime_encrypt($msg->head, $msg->body_as_string, $recipient); 
	   unless ($cryptedmsg) {
	       &Log::do_log('notice', 'Failed encrypted message for moderator');
	       #  send a generic error message : X509 cert missing
	       return undef;
	   }

	   my $crypted_file = $Conf::Conf{'tmpdir'}.'/'.$self->get_list_id().'.moderate.'.$$;
	   unless (open CRYPTED, ">$crypted_file") {
	       &Log::do_log('notice', 'Could not create file %s', $crypted_file);
	       return undef;
	   }
	   print CRYPTED $cryptedmsg;
	   close CRYPTED;
	   $param->{'msg_path'} = $crypted_file;

   }else{
       $param->{'msg_path'} = $file;
       }
       # create a one time ticket that will be used as un md5 URL credential

       unless ($param->{'one_time_ticket'} = &Auth::create_one_time_ticket($recipient,$robot,'modindex/'.$name,'mail')){
	   &Log::do_log('notice',"Unable to create one_time_ticket for $recipient, service modindex/$name");
       }else{
	   &Log::do_log('notice',"ticket : $param->{'one_time_ticket'}");
       }
       &tt2::allow_absolute_path();
       $param->{'auto_submitted'} = 'auto-forwarded';

       unless ($self->send_file('moderate', $recipient, $self->{'domain'}, $param)) {
	   &Log::do_log('notice',"Unable to send template 'moderate' to $recipient");
	   return undef;
       }
   }
#  Old code 5.4 and before to be removed in 5.5
#   if ($encrypt eq 'smime_crypted') {
#
#       ## Send a different crypted message to each moderator
#       foreach my $recipient (@rcpt) {
#
#	   # create a one time ticket that will be used as un md5 URL credential
#	   $param->{'one_time_ticket'} = &Auth::create_one_time_ticket($in{'email'},$robot,'modindex/'.$name,$ip)
#
#	   ## $msg->body_as_string respecte-t-il le Base64 ??
#	   my $cryptedmsg = &tools::smime_encrypt($msg->head, $msg->body_as_string, $recipient); #
#	   unless ($cryptedmsg) {
#	       &Log::do_log('notice', 'Failed encrypted message for moderator');
#	       # xxxx send a generic error message : X509 cert missing
#	       return undef;
#	   }
#
#	   my $crypted_file = $Conf::Conf{'tmpdir'}.'/'.$self->get_list_id().'.moderate.'.$$;
#	   unless (open CRYPTED, ">$crypted_file") {
#	       &Log::do_log('notice', 'Could not create file %s', $crypted_file);
#	       return undef;
#	   }
#	   print CRYPTED $cryptedmsg;
#	   close CRYPTED;
#	   
#
#	   $param->{'msg_path'} = $crypted_file;
#
#	   &tt2::allow_absolute_path();
#	   unless ($self->send_file('moderate', $recipient, $self->{'domain'}, $param)) {
#	       &Log::do_log('notice',"Unable to send template 'moderate' to $recipient");
#	       return undef;
#	   }
#       }
#   }else{
#       $param->{'msg_path'} = $file;
#
#       &tt2::allow_absolute_path();
#       unless ($self->send_file('moderate', \@rcpt, $self->{'domain'}, $param)) {
#	   &Log::do_log('notice',"Unable to send template 'moderate' to $self->{'name'} editors");
#	   return undef;
#       }
#  }
   return $modkey;
}

####################################################
# send_auth                              
####################################################
# Sends an authentication request for a sent message to distribute.
# The message for distribution is copied in the authqueue 
# spool in order to wait for confirmation by its sender.
# This message is named with a key.
# In context of msg_topic defined, the sender must tag it 
# for the confirmation
#  
# IN : -$self (+): ref(List)
#      -$message (+): ref(Message)
#
# OUT : $authkey : the key for naming message waiting 
#         for confirmation (or tagging) in spool queueauth
#       | undef
####################################################
sub send_auth {
   my($self, $message) = @_;
   my ($sender, $msg, $file) = ($message->{'sender'}, $message->{'msg'}, $message->{'filename'});
   &Log::do_log('debug3', 'List::send_auth(%s, %s)', $sender, $file);

   ## Ensure 1 second elapsed since last message
   sleep (1);

   my($i, @rcpt);
   my $admin = $self->{'admin'};
   my $name = $self->{'name'};
   my $host = $admin->{'host'};
   my $robot = $self->{'domain'};
   my $authqueue = $Conf::Conf{'queueauth'};
   return undef unless ($name && $admin);
  

   my @now = localtime(time);
   my $messageid = $now[6].$now[5].$now[4].$now[3].$now[2].$now[1]."."
                   .int(rand(6)).int(rand(6)).int(rand(6)).int(rand(6))
		   .int(rand(6)).int(rand(6))."\@".$host;
   my $authkey = Digest::MD5::md5_hex(join('/', $self->get_cookie(),$messageid));
     
   my $auth_file = $authqueue.'/'.$self->get_list_id().'_'.$authkey;   
   unless (open OUT, ">$auth_file") {
       &Log::do_log('notice', 'Cannot create file %s', $auth_file);
       return undef;
   }

   unless (open IN, $file) {
       &Log::do_log('notice', 'Cannot open file %s', $file);
       return undef;
   }
   
   print OUT <IN>;

   close IN; close OUT;

   my $param = {'authkey' => $authkey,
		'boundary' => "----------------- Message-Id: \<$messageid\>",
		'file' => $file};
   
   if ($self->is_there_msg_topic()) {
       $param->{'request_topic'} = 1;
   }

   &tt2::allow_absolute_path();
   $param->{'auto_submitted'} = 'auto-replied';
   unless ($self->send_file('send_auth',$sender,$robot,$param)) {
       &Log::do_log('notice',"Unable to send template 'send_auth' to $sender");
       return undef;
   }

   return $authkey;
}

####################################################
# request_auth                              
####################################################
# sends an authentification request for a requested 
# command .
# 
#  
# IN : -$self : ref(List) if is present
#      -$email(+) : recepient (the personn who asked 
#                   for the command)
#      -$cmd : -signoff|subscribe|add|del|remind if $self
#              -remind else
#      -$robot(+) : robot
#      -@param : 0 : used if $cmd = subscribe|add|del|invite
#                1 : used if $cmd = add 
#
# OUT : 1 | undef
#
####################################################
sub request_auth {
    &Log::do_log('debug2', 'List::request_auth(%s, %s, %s, %s)', @_);
    my $first_param = shift;
    my ($self, $email, $cmd, $robot, @param);

    if (ref($first_param) eq 'List') {
	$self = $first_param;
	$email= shift;
    }else {
	$email = $first_param;
    }
    $cmd = shift;
    $robot = shift;
    @param = @_;
    &Log::do_log('debug3', 'List::request_auth() List : %s,$email: %s cmd : %s',$self->{'name'},$email,$cmd);

    
    my $keyauth;
    my $data = {'to' => $email};


    if (ref($self) eq 'List') {
	my $listname = $self->{'name'};
	$data->{'list_context'} = 1;

	if ($cmd =~ /signoff$/){
	    $keyauth = $self->compute_auth ($email, 'signoff');
	    $data->{'command'} = "auth $keyauth $cmd $listname $email";
	    $data->{'type'} = 'signoff';
	    
	}elsif ($cmd =~ /subscribe$/){
	    $keyauth = $self->compute_auth ($email, 'subscribe');
	    $data->{'command'} = "auth $keyauth $cmd $listname $param[0]";
	    $data->{'type'} = 'subscribe';

	}elsif ($cmd =~ /add$/){
	    $keyauth = $self->compute_auth ($param[0],'add');
	    $data->{'command'} = "auth $keyauth $cmd $listname $param[0] $param[1]";
	    $data->{'type'} = 'add';
	    
	}elsif ($cmd =~ /del$/){
	    my $keyauth = $self->compute_auth($param[0], 'del');
	    $data->{'command'} = "auth $keyauth $cmd $listname $param[0]";
	    $data->{'type'} = 'del';

	}elsif ($cmd eq 'remind'){
	    my $keyauth = $self->compute_auth('','remind');
	    $data->{'command'} = "auth $keyauth $cmd $listname";
	    $data->{'type'} = 'remind';
	
	}elsif ($cmd eq 'invite'){
	    my $keyauth = $self->compute_auth($param[0],'invite');
	    $data->{'command'} = "auth $keyauth $cmd $listname $param[0]";
	    $data->{'type'} = 'invite';
	}

	$data->{'command_escaped'} = &tt2::escape_url($data->{'command'});
	$data->{'auto_submitted'} = 'auto-replied';
	unless ($self->send_file('request_auth',$email,$robot,$data)) {
	    &Log::do_log('notice',"Unable to send template 'request_auth' to $email");
	    return undef;
	}

    }else {
	if ($cmd eq 'remind'){
	    my $keyauth = &List::compute_auth('',$cmd);
	    $data->{'command'} = "auth $keyauth $cmd *";
	    $data->{'command_escaped'} = &tt2::escape_url($data->{'command'});
	    $data->{'type'} = 'remind';
	    
	}
	$data->{'auto_submitted'} = 'auto-replied';
	unless (&send_global_file('request_auth',$email,$robot,$data)) {
	    &Log::do_log('notice',"Unable to send template 'request_auth' to $email");
	    return undef;
	}
    }


    return 1;
}


####################################################
# archive_send                              
####################################################
# sends an archive file to someone (text archive
# file : independant from web archives)
#  
# IN : -$self(+) : ref(List)
#      -$who(+) : recepient
#      -file(+) : name of the archive file to send
# OUT : - | undef
#
######################################################
sub archive_send {
   my($self, $who, $file) = @_;
   &Log::do_log('debug', 'List::archive_send(%s, %s)', $who, $file);

   return unless ($self->is_archived());
       
   my $dir = &Conf::get_robot_conf($self->{'domain'},'arc_path').'/'.$self->get_list_id();
   my $msg_list = Archive::scan_dir_archive($dir, $file);

   my $subject = 'File '.$self->{'name'}.' '.$file ;
   my $param = {'to' => $who,
		'subject' => $subject,
		'msg_list' => $msg_list } ;

   $param->{'boundary1'} = &tools::get_message_id($self->{'domain'});
   $param->{'boundary2'} = &tools::get_message_id($self->{'domain'});
   $param->{'from'} = &Conf::get_robot_conf($self->{'domain'},'sympa');

#    open TMP2, ">/tmp/digdump"; &tools::dump_var($param, 0, \*TMP2); close TMP2;
$param->{'auto_submitted'} = 'auto-replied';
   unless ($self->send_file('get_archive',$who,$self->{'domain'},$param)) {
	   &Log::do_log('notice',"Unable to send template 'archive_send' to $who");
	   return undef;
       }

}

####################################################
# archive_send_last                              
####################################################
# sends last archive file
#  
# IN : -$self(+) : ref(List)
#      -$who(+) : recepient
# OUT : - | undef
#
######################################################
sub archive_send_last {
   my($self, $who) = @_;
   &Log::do_log('debug', 'List::archive_send_last(%s, %s)',$self->{'listname'}, $who);

   return unless ($self->is_archived());
   my $dir = $self->{'dir'}.'/archives' ;

   my $mail = new Message({'file' => "$dir/last_message",'noxsympato'=>'noxsympato'});
   unless (defined $mail) {
       &Log::do_log('err', 'Unable to create Message object %s', "$dir/last_message");
       return undef;
   }
   
   my @msglist;
   my $msg = {};
   $msg->{'id'} = 1;
   
   $msg->{'subject'} = &MIME::EncWords::decode_mimewords($mail->{'msg'}->head->get('Subject'), Charset=>'utf8');
   chomp $msg->{'subject'};   
   $msg->{'from'} = &MIME::EncWords::decode_mimewords($mail->{'msg'}->head->get('From'), Charset=>'utf8');
   chomp $msg->{'from'};    	        	
   $msg->{'date'} = &MIME::EncWords::decode_mimewords($mail->{'msg'}->head->get('Date'), Charset=>'utf8');
   chomp $msg->{'date'};
   
   $msg->{'full_msg'} = $mail->{'msg'}->as_string;
   
   push @msglist,$msg;

   my $subject = 'File '.$self->{'name'}.'.last_message' ;
   my $param = {'to' => $who,
		'subject' => $subject,
		'msg_list' => \@msglist } ;


   $param->{'boundary1'} = &tools::get_message_id($self->{'domain'});
   $param->{'boundary2'} = &tools::get_message_id($self->{'domain'});
   $param->{'from'} = &Conf::get_robot_conf($self->{'domain'},'sympa');
   $param->{'auto_submitted'} = 'auto-replied';
#    open TMP2, ">/tmp/digdump"; &tools::dump_var($param, 0, \*TMP2); close TMP2;

   unless ($self->send_file('get_archive',$who,$self->{'domain'},$param)) {
	   &Log::do_log('notice',"Unable to send template 'archive_send' to $who");
	   return undef;
       }

}


#########################   NOTIFICATION SENDING  ######################################


####################################################
# send_notify_to_listmaster                         
####################################################
# Sends a notice to listmaster by parsing
# listmaster_notification.tt2 template
#  
# IN : -$operation (+): notification type
#      -$robot (+): robot
#      -$param(+) : ref(HASH) | ref(ARRAY)
#       values for template parsing
#    
# OUT : 1 | undef
#       
###################################################### 
sub send_notify_to_listmaster {

    my ($operation, $robot, $param) = @_;
    unless ($operation eq 'logs_failed') {
	&Log::do_log('debug2', 'List::send_notify_to_listmaster(%s,%s )', $operation, $robot );
    }

    unless ($operation eq 'logs_failed') {
	unless (defined $operation) {
	    &Log::do_log('err','List::send_notify_to_listmaster(%s) : missing incoming parameter "$operation"');
	    return undef;
	}
	unless (defined $robot) {
	    &Log::do_log('err','List::send_notify_to_listmaster(%s) : missing incoming parameter "$robot"');
	    return undef;
	}
    }
    my $host = &Conf::get_robot_conf($robot, 'host');
    my $listmaster = &Conf::get_robot_conf($robot, 'listmaster');
    my $to = "$Conf::Conf{'listmaster_email'}\@$host";
    my $options = {}; ## options for send_global_file()    

    if ($operation eq 'logs_failed') {
	my $data = {'to' => $to,
		    'type' => $operation,
		    'auto_submitted' => 'auto-generated',
		    'alarm' => 1, # bypass bulk
		};
	
	for my $i(0..$#{$param}) {
	    $data->{"param$i"} = $param->[$i];
	}
	unless (&send_global_file('listmaster_notification', $listmaster, $robot, $data, $options)) {
	    return undef;
	}
	return 1;
    }

    if (ref($param) eq 'HASH') {

	$param->{'to'} = $to;
	$param->{'type'} = $operation;
	$param->{'auto_submitted'} = 'auto-generated';

	## Prepare list-related data
	if ($param->{'list'} && ref($param->{'list'}) eq 'List') {
	  my $list = $param->{'list'};
	  $param->{'list'} = {'name' => $list->{'name'},
			      'host' => $list->{'domain'},
			      'subject' => $list->{'admin'}{'subject'},
			  };
	}

	## Automatic action done on bouncing adresses
	if ($operation eq 'automatic_bounce_management') {
	    my $list = new List ($param->{'listname'}, $robot);
	    unless (defined $list) {
		&Log::do_log('err','Parameter %s is not a valid list', $param->{'listname'});
		return undef;
	    }
	    unless ($list->send_file('listmaster_notification',$listmaster, $robot, $param, $options)) {
		&Log::do_log('notice',"Unable to send template 'listmaster_notification' to $listmaster");
		return undef;
	    }
	    
	}else {		
	    
	    ## No DataBase |  DataBase restored
	    if (($operation eq 'no_db')||($operation eq 'db_restored')) {
		
		$param->{'db_name'} = &Conf::get_robot_conf($robot, 'db_name');  
		$options->{'skip_db'} = 1; ## Skip DB access because DB is not accessible
		
				
	    ## Loop detected in Sympa
	    }elsif ($operation eq 'loop_command') {
		$param->{'boundary'} = '----------=_'.&tools::get_message_id($robot);
		&tt2::allow_absolute_path();
	    }


	    foreach my $email (split (/\,/, $listmaster)) {	
		if (($operation eq 'request_list_creation')or($operation eq 'request_list_renaming')) {
		    $param->{'one_time_ticket'} = &Auth::create_one_time_ticket($email,$robot,'get_pending_lists',$param->{'ip'});
		}
		$param->{'alarm'} = 1;
		unless (&send_global_file('listmaster_notification', $email, $robot, $param, $options)) {
		    &Log::do_log('notice',"Unable to send template 'listmaster_notification' to $listmaster");
		    return undef;
		}
	    }
	}
    
    }elsif(ref($param) eq 'ARRAY') {
	
	my $data = {'to' => $to,
		    'type' => $operation,
		    'auto_submitted' => 'auto-generated',
		    'alarm' => 1
		    };
	for my $i(0..$#{$param}) {
	    $data->{"param$i"} = $param->[$i];
	}
	unless (&send_global_file('listmaster_notification', $listmaster, $robot, $data, $options)) {
	    &Log::do_log('notice',"Unable to send template 'listmaster_notification' to $listmaster");
	    return undef;
	}
    }else {
	&Log::do_log('err','List::send_notify_to_listmaster(%s,%s) : error on incoming parameter "$param", it must be a ref on HASH or a ref on ARRAY', $operation, $robot );
	return undef;
    }
    return 1;
}


####################################################
# send_notify_to_owner                              
####################################################
# Sends a notice to list owner(s) by parsing
# listowner_notification.tt2 template
# 
# IN : -$self (+): ref(List)
#      -$operation (+): notification type
#      -$param(+) : ref(HASH) | ref(ARRAY)
#       values for template parsing
#
# OUT : 1 | undef
#    
######################################################
sub send_notify_to_owner {
    
    my ($self,$operation,$param) = @_;
    &Log::do_log('debug2', 'List::send_notify_to_owner(%s, %s)', $self->{'name'}, $operation);

    my $host = $self->{'admin'}{'host'};
    my @to = $self->get_owners_email();
    my $robot = $self->{'domain'};

    unless (@to) {
	do_log('notice', 'No owner defined or all of them use nomail option in list %s ; using listmasters as default', $self->{'name'} );
	@to = split /,/, &Conf::get_robot_conf($robot, 'listmaster');
    }
    unless (defined $operation) {
	&Log::do_log('err','List::send_notify_to_owner(%s) : missing incoming parameter "$operation"', $self->{'name'});
	return undef;
    }

    if (ref($param) eq 'HASH') {

	$param->{'auto_submitted'} = 'auto-generated';
	$param->{'to'} =join(',', @to);
	$param->{'type'} = $operation;


	if ($operation eq 'warn-signoff') {
	    $param->{'escaped_gecos'} = $param->{'gecos'};
	    $param->{'escaped_gecos'} =~ s/\s/\%20/g;
	    $param->{'escaped_who'} = $param->{'who'};
	    $param->{'escaped_who'} =~ s/\s/\%20/g;
	    foreach my $owner (@to) {
		$param->{'one_time_ticket'} = &Auth::create_one_time_ticket($owner,$robot,'search/'.$self->{'name'}.'/'.$param->{'escaped_who'},$param->{'ip'});
		unless ($self->send_file('listowner_notification',[$owner], $robot,$param)) {
		    &Log::do_log('notice',"Unable to send template 'listowner_notification' to $self->{'name'} list owner $owner");		    
		}
	    }
	}elsif ($operation eq 'subrequest') {
	    $param->{'escaped_gecos'} = $param->{'gecos'};
	    $param->{'escaped_gecos'} =~ s/\s/\%20/g;
	    $param->{'escaped_who'} = $param->{'who'};
	    $param->{'escaped_who'} =~ s/\s/\%20/g;
	    foreach my $owner (@to) {
		$param->{'one_time_ticket'} = &Auth::create_one_time_ticket($owner,$robot,'subindex/'.$self->{'name'},$param->{'ip'});
		unless ($self->send_file('listowner_notification',[$owner], $robot,$param)) {
		    &Log::do_log('notice',"Unable to send template 'listowner_notification' to $self->{'name'} list owner $owner");		    
		}
	    }
	}else{
	    if ($operation eq 'sigrequest') {
		$param->{'escaped_who'} = $param->{'who'};
		$param->{'escaped_who'} =~ s/\s/\%20/g;
		$param->{'sympa'} = &Conf::get_robot_conf($self->{'domain'}, 'sympa');
		
	    }elsif ($operation eq 'bounce_rate') {
		$param->{'rate'} = int ($param->{'rate'} * 10) / 10;
	    }
	    unless ($self->send_file('listowner_notification',\@to, $robot,$param)) {
		&Log::do_log('notice',"Unable to send template 'listowner_notification' to $self->{'name'} list owner");
		return undef;
	    }
	}

    }elsif(ref($param) eq 'ARRAY') {	

	my $data = {'to' => join(',', @to),
		    'type' => $operation};

	for my $i(0..$#{$param}) {
		$data->{"param$i"} = $param->[$i];
 	}
 	unless ($self->send_file('listowner_notification', \@to, $robot, $data)) {
	    &Log::do_log('notice',"Unable to send template 'listowner_notification' to $self->{'name'} list owner");
	    return undef;
	}

    }else {

	&Log::do_log('err','List::send_notify_to_owner(%s,%s) : error on incoming parameter "$param", it must be a ref on HASH or a ref on ARRAY', $self->{'name'},$operation);
	return undef;
    }
    return 1;
}

#########################
## Delete a member's picture file
#########################
# remove picture from user $2 in list $1 
#########################
sub delete_list_member_picture {
    my ($self,$email) = @_;    
    &Log::do_log('debug2', '(%s)', $email);
    
    my $fullfilename = undef;
    my $filename = &tools::md5_fingerprint($email);
    my $name = $self->{'name'};
    my $robot = $self->{'domain'};
    
    foreach my $ext ('.gif','.jpg','.jpeg','.png') {
  	if(-f &Conf::get_robot_conf($robot,'pictures_path').'/'.$name.'@'.$robot.'/'.$filename.$ext) {
  	    my $file = &Conf::get_robot_conf($robot,'pictures_path').'/'.$name.'@'.$robot.'/'.$filename.$ext;
  	    $fullfilename = $file;
  	    last;
  	} 	
    }
    
    if (defined $fullfilename) {
	unless(unlink($fullfilename)) {
	    &Log::do_log('err', 'Failed to delete '.$fullfilename);
	    return undef;  
	}

	do_log('notice', 'File deleted successfull '.$fullfilename);
    }

    return 1;
}


####################################################
# send_notify_to_editor                             
####################################################
# Sends a notice to list editor(s) or owner (if no editor)
# by parsing listeditor_notification.tt2 template
# 
# IN : -$self (+): ref(List)
#      -$operation (+): notification type
#      -$param(+) : ref(HASH) | ref(ARRAY)
#       values for template parsing
#
# OUT : 1 | undef
#    
######################################################
sub send_notify_to_editor {

    my ($self,$operation,$param) = @_;
    &Log::do_log('debug2', 'List::send_notify_to_editor(%s, %s)', $self->{'name'}, $operation);

    my @to = $self->get_editors_email();
    my $robot = $self->{'domain'};
    $param->{'auto_submitted'} = 'auto-generated';
      
      unless (@to) {
	do_log('notice', 'Warning : no editor or owner defined or all of them use nomail option in list %s', $self->{'name'} );
	return undef;
    }
    unless (defined $operation) {
	&Log::do_log('err','List::send_notify_to_editor(%s) : missing incoming parameter "$operation"', $self->{'name'});
	return undef;
    }
    if (ref($param) eq 'HASH') {

	$param->{'to'} =join(',', @to);
	$param->{'type'} = $operation;

	unless ($self->send_file('listeditor_notification',\@to, $robot,$param)) {
	    &Log::do_log('notice',"Unable to send template 'listeditor_notification' to $self->{'name'} list editor");
	    return undef;
	}
	
    }elsif(ref($param) eq 'ARRAY') {	
	
	my $data = {'to' => join(',', @to),
		    'type' => $operation};
	
	foreach my $i(0..$#{$param}) {
	    $data->{"param$i"} = $param->[$i];
 	}
 	unless ($self->send_file('listeditor_notification', \@to, $robot, $data)) {
	    &Log::do_log('notice',"Unable to send template 'listeditor_notification' to $self->{'name'} list editor");
	    return undef;
	}	
	
    }else {
	&Log::do_log('err','List::send_notify_to_editor(%s,%s) : error on incoming parameter "$param", it must be a ref on HASH or a ref on ARRAY', $self->{'name'},$operation);
	return undef;
    }
    return 1;
}


####################################################
# send_notify_to_user                             
####################################################
# Send a notice to a user (sender, subscriber ...)
# by parsing user_notification.tt2 template
# 
# IN : -$self (+): ref(List)
#      -$operation (+): notification type
#      -$user(+): email of notified user
#      -$param(+) : ref(HASH) | ref(ARRAY)
#       values for template parsing
#
# OUT : 1 | undef
#    
######################################################
sub send_notify_to_user{

    my ($self,$operation,$user,$param) = @_;
    &Log::do_log('debug2', 'List::send_notify_to_user(%s, %s, %s)', $self->{'name'}, $operation, $user);

    my $host = $self->{'admin'}->{'host'};
    my $robot = $self->{'domain'};
    $param->{'auto_submitted'} = 'auto-generated';

    unless (defined $operation) {
	&Log::do_log('err','List::send_notify_to_user(%s) : missing incoming parameter "$operation"', $self->{'name'});
	return undef;
    }
    unless ($user) {
	&Log::do_log('err','List::send_notify_to_user(%s) : missing incoming parameter "$user"', $self->{'name'});
	return undef;
    }
    
    if (ref($param) eq "HASH") {
	$param->{'to'} = $user;
	$param->{'type'} = $operation;

	if ($operation eq 'auto_notify_bouncers') {	
	}
	
 	unless ($self->send_file('user_notification',$user,$robot,$param)) {
	    &Log::do_log('notice',"Unable to send template 'user_notification' to $user");
	    return undef;
	}

    }elsif (ref($param) eq "ARRAY") {	
	
	my $data = {'to' => $user,
		    'type' => $operation};
	
	for my $i(0..$#{$param}) {
	    $data->{"param$i"} = $param->[$i];
 	}
 	unless ($self->send_file('user_notification',$user,$robot,$data)) {
	    &Log::do_log('notice',"Unable to send template 'user_notification' to $user");
	    return undef;
	}	
	
    }else {
	
	&Log::do_log('err','List::send_notify_to_user(%s,%s,%s) : error on incoming parameter "$param", it must be a ref on HASH or a ref on ARRAY', 
		$self->{'name'},$operation,$user);
	return undef;
    }
    return 1;
}
#                                                                                       #             
#                                                                                       #  
#                                                                                       #
######################### END functions for sending messages ############################



## genererate a md5 checksum using private cookie and parameters
sub compute_auth {
    &Log::do_log('debug3', 'List::compute_auth(%s, %s, %s)', @_);

    my $first_param = shift;
    my ($self, $email, $cmd);
    
    if (ref($first_param) eq 'List') {
	$self = $first_param;
	$email= shift;
    }else {
	$email = $email;
    }
    $cmd = shift;

    $email =~ y/[A-Z]/[a-z]/;
    $cmd =~ y/[A-Z]/[a-z]/;

    my ($cookie, $key, $listname) ;

    if ($self){
	$listname = $self->{'name'};
        $cookie = $self->get_cookie() || $Conf::Conf{'cookie'};
    }else {
	$cookie = $Conf::Conf{'cookie'};
    }
    
    $key = substr(Digest::MD5::md5_hex(join('/', $cookie, $listname, $email, $cmd)), -8) ;

    return $key;
}


## Add footer/header to a message
sub add_parts {
    my ($self, $msg) = @_;
    my ($listname,$type) = ($self->{'name'}, $self->{'admin'}{'footer_type'});
    my $listdir = $self->{'dir'};
    &Log::do_log('debug2', 'List:add_parts(%s, %s, %s)', $msg, $listname, $type);

    my ($header, $headermime);
    foreach my $file ("$listdir/message.header", 
		      "$listdir/message.header.mime",
		      "$Conf::Conf{'etc'}/mail_tt2/message.header", 
		      "$Conf::Conf{'etc'}/mail_tt2/message.header.mime") {
	if (-f $file) {
	    unless (-r $file) {
		&Log::do_log('notice', 'Cannot read %s', $file);
		next;
	    }
	    $header = $file;
	    last;
	} 
    }

    my ($footer, $footermime);
    foreach my $file ("$listdir/message.footer", 
		      "$listdir/message.footer.mime",
		      "$Conf::Conf{'etc'}/mail_tt2/message.footer", 
		      "$Conf::Conf{'etc'}/mail_tt2/message.footer.mime") {
	if (-f $file) {
	    unless (-r $file) {
		&Log::do_log('notice', 'Cannot read %s', $file);
		next;
	    }
	    $footer = $file;
	    last;
	} 
    }
    
    ## No footer/header
    unless (-f $footer or -f $header) {
 	return undef;
    }
    
    my $parser = new MIME::Parser;
    $parser->output_to_core(1);

    ## Msg Content-Type
    my $content_type = $msg->head->get('Content-Type');
    
    ## MIME footer/header
    if ($type eq 'append'){

	my (@footer_msg, @header_msg);
	if ($header) {
	    open HEADER, $header;
	    @header_msg = <HEADER>;
	    close HEADER;
	}
	
	if ($footer) {
	    open FOOTER, $footer;
	    @footer_msg = <FOOTER>;
	    close FOOTER;
	}
	
	if (!$content_type or $content_type =~ /^text\/plain/i) {
		    
	    my @body;
	    if (defined $msg->bodyhandle) {
		@body = $msg->bodyhandle->as_lines;
	    }

	    $msg->bodyhandle (new MIME::Body::Scalar [@header_msg,@body,@footer_msg] );

	}elsif ($content_type =~ /^multipart\/mixed/i) {
	    ## Append to first part if text/plain
	    
	    if ($msg->parts(0)->head->get('Content-Type') =~ /^text\/plain/i) {
		
		my $part = $msg->parts(0);
		my @body;
		
		if (defined $part->bodyhandle) {
		    @body = $part->bodyhandle->as_lines;
		}
		$part->bodyhandle (new MIME::Body::Scalar [@header_msg,@body,@footer_msg] );
	    }else {
		&Log::do_log('notice', 'First part of message not in text/plain ; ignoring footers and headers');
	    }

	}elsif ($content_type =~ /^multipart\/alternative/i) {
	    ## Append to first text/plain part

	    foreach my $part ($msg->parts) {
		&Log::do_log('debug3', 'TYPE: %s', $part->head->get('Content-Type'));
		if ($part->head->get('Content-Type') =~ /^text\/plain/i) {

		    my @body;
		    if (defined $part->bodyhandle) {
			@body = $part->bodyhandle->as_lines;
		    }
		    $part->bodyhandle (new MIME::Body::Scalar [@header_msg,@body,@footer_msg] );
		    next;
		}
	    }
	}

    }else {
	if ($content_type =~ /^multipart\/alternative/i || $content_type =~ /^multipart\/related/i) {

	    &Log::do_log('notice', 'Making $1 into multipart/mixed'); 
	    $msg->make_multipart("mixed",Force=>1); 
	}
	
	if ($header) {
	    if ($header =~ /\.mime$/) {
		
		my $header_part = $parser->parse_in($header);    
		$msg->make_multipart unless $msg->is_multipart;
		$msg->add_part($header_part, 0); ## Add AS FIRST PART (0)
		
		## text/plain header
	    }else {
		
		$msg->make_multipart unless $msg->is_multipart;
		my $header_part = build MIME::Entity Path        => $header,
		Type        => "text/plain",
		Filename    => "message-header.txt",
		Encoding    => "8bit",
		Charset     => "UTF-8";
		$msg->add_part($header_part, 0);
	    }
	}
	if ($footer) {
	    if ($footer =~ /\.mime$/) {
		
		my $footer_part = $parser->parse_in($footer);    
		$msg->make_multipart unless $msg->is_multipart;
		$msg->add_part($footer_part);
		
		## text/plain footer
	    }else {
		
		$msg->make_multipart unless $msg->is_multipart;
		$msg->attach(Path        => $footer,
			     Type        => "text/plain",
			     Filename    => "message-footer.txt",
			     Encoding    => "8bit",
			     Charset     => "UTF-8"
			     );
	    }
	}
    }

    return $msg;
}




## Delete a user in the user_table
sub delete_global_user {
    my @users = @_;
    
    &Log::do_log('debug2', '');
    
    return undef unless ($#users >= 0);
    
    foreach my $who (@users) {
	$who = &tools::clean_email($who);
	## Update field
	
	unless (&SDM::do_query("DELETE FROM user_table WHERE (email_user =%s)", &SDM::quote($who))) {
	    &Log::do_log('err','Unable to delete user %s', $who);
	    next;
	}
    }

    return $#users + 1;
}

## Delete the indicate list member 
## IN : - ref to array 
##      - option exclude
##
## $list->delete_list_member('users' => \@u, 'exclude' => 1)
## $list->delete_list_member('users' => [$email], 'exclude' => 1)
sub delete_list_member {
    my $self = shift;
    my %param = @_;
    my @u = @{$param{'users'}};
    my $exclude = $param{'exclude'};
    my $parameter = $param{'parameter'};#case of deleting : bounce? manual signoff or deleted by admin?
    my $daemon_name = $param{'daemon'};
    &Log::do_log('debug2', 'List::delete_list_member');

    my $name = $self->{'name'};
    my $total = 0;

    foreach my $who (@u) {
	$who = &tools::clean_email($who);

	## Include in exclusion_table only if option is set.
	if($exclude == 1){
	    ## Insert in exclusion_table if $user->{'included'} eq '1'
	    &insert_delete_exclusion($who, $name, $self->{'domain'}, 'insert');
	    
	}

	$list_cache{'is_list_member'}{$self->{'domain'}}{$name}{$who} = undef;    
	$list_cache{'get_list_member'}{$self->{'domain'}}{$name}{$who} = undef;    
	
	## Delete record in SUBSCRIBER
	unless(&SDM::do_query("DELETE FROM subscriber_table WHERE (user_subscriber=%s AND list_subscriber=%s AND robot_subscriber=%s)",
	&SDM::quote($who), 
	&SDM::quote($name), 
	&SDM::quote($self->{'domain'}))) {
	    &Log::do_log('err','Unable to remove list member %s', $who);
	    next;
	}
	
	#log in stat_table to make statistics
	&Log::db_stat_log({'robot' => $self->{'domain'}, 'list' => $name, 'operation' => 'del subscriber', 'parameter' => $parameter
			       , 'mail' => $who, 'client' => '', 'daemon' => $daemon_name});
	
	$total--;
    }

    $self->{'total'} += $total;
    $self->savestats();
    &delete_list_member_picture($self,shift(@u));
    return (-1 * $total);

}


## Delete the indicated admin users from the list.
sub delete_list_admin {
    my($self, $role, @u) = @_;
    &Log::do_log('debug2', '', $role); 

    my $name = $self->{'name'};
    my $total = 0;
    
    foreach my $who (@u) {
	$who = &tools::clean_email($who);
	my $statement;
	
	$list_cache{'is_admin_user'}{$self->{'domain'}}{$name}{$who} = undef;    
	    
	## Delete record in ADMIN
	unless(&SDM::do_query("DELETE FROM admin_table WHERE (user_admin=%s AND list_admin=%s AND robot_admin=%s AND role_admin=%s)",
	&SDM::quote($who), 
	&SDM::quote($name),
	&SDM::quote($self->{'domain'}),
	&SDM::quote($role))) {
	    &Log::do_log('err','Unable to remove list admin %s', $who);
	    next;
	}   
	
	$total--;
    }
    
    return (-1 * $total);
}

## Delete all admin_table entries
sub delete_all_list_admin {
    &Log::do_log('debug2', ''); 
	    
    my $total = 0;
    
    ## Delete record in ADMIN
    unless($sth = &SDM::do_query("DELETE FROM admin_table")) {
	&Log::do_log('err','Unable to remove all admin from database');
	return undef;
    }   
    
    return 1;
}


## Returns the cookie for a list, if any.
sub get_cookie {
   return shift->{'admin'}{'cookie'};
}

## Returns the maximum size allowed for a message to the list.
sub get_max_size {
   return shift->{'admin'}{'max_size'};
}

## Returns an array with the Reply-To data
sub get_reply_to {
    my $admin = shift->{'admin'};

    my $value = $admin->{'reply_to_header'}{'value'};

    $value = $admin->{'reply_to_header'}{'other_email'} if ($value eq 'other_email');

    return $value
}

## Returns a default user option
sub get_default_user_options {
    my $self = shift->{'admin'};
    my $what = shift;
    &Log::do_log('debug3', 'List::get_default_user_options(%s)', $what);

    if ($self) {
	return $self->{'default_user_options'};
    }
    return undef;
}

## Returns the number of subscribers to the list
sub get_total {
    my $self = shift;
    my $name = $self->{'name'};
    my $option = shift;
    &Log::do_log('debug3','List::get_total(%s)', $name);

    if ($option eq 'nocache') {
	$self->{'total'} = $self->_load_total_db($option);
    }
    
    return $self->{'total'};
}

## Returns a hash for a given user
sub get_global_user {
    my $who = &tools::clean_email(shift);
    &Log::do_log('debug2', '(%s)', $who);

    ## Additional subscriber fields
    my $additional;
    if ($Conf::Conf{'db_additional_user_fields'}) {
	$additional = ',' . $Conf::Conf{'db_additional_user_fields'};
    }

    
    push @sth_stack, $sth;

    $sth = &SDM::do_query("SELECT email_user AS email, gecos_user AS gecos, password_user AS password, cookie_delay_user AS cookie_delay, lang_user AS lang %s, attributes_user AS attributes, data_user AS data, last_login_date_user AS last_login_date, wrong_login_count_user AS wrong_login_count, last_login_host_user AS last_login_host FROM user_table WHERE email_user = %s ", $additional, &SDM::quote($who));
   
    my $user = $sth->fetchrow_hashref('NAME_lc');
 
    $sth->finish();

    $sth = pop @sth_stack;

    if (defined $user) {
	## decrypt password
	if ($user->{'password'}) {
	    $user->{'password'} = &tools::decrypt_password($user->{'password'});
	}

	## Turn user_attributes into a hash
	my $attributes = $user->{'attributes'};
	$user->{'attributes'} = undef;
	foreach my $attr (split (/\;/, $attributes)) {
	    my ($key, $value) = split (/\=/, $attr);
	    $user->{'attributes'}{$key} = $value;
	}    
	## Turn data_user into a hash
	 if ($user->{'data'}) {
	     my %prefs = &tools::string_2_hash($user->{'data'});
	     $user->{'prefs'} = \%prefs;
	 }
    }

    return $user;
}

## Returns an array of all users in User table hash for a given user
sub get_all_global_user {
    &Log::do_log('debug2', '');

    my @users;
    my $sth;
    push @sth_stack, $sth;
    
    unless ($sth = &SDM::do_query("SELECT email_user FROM user_table")) {
	do_log('err','Unable to gather all users in DB');
	return undef;
    }
    
    while (my $email = ($sth->fetchrow_array)[0]) {
	push @users, $email;
    }
 
    $sth->finish();

    $sth = pop @sth_stack;

    return @users;
}

######################################################################
###  suspend_subscription                                            #
## Suspend an user from list(s)                                      #
######################################################################
# IN:                                                                #
#   - email : the subscriber email                                   #
#   - list : the name of the list                                    #
#   - data : start_date and end_date                                 #
#   - robot : domain                                                 #
# OUT:                                                               #
#   - undef if something went wrong.                                 #
#   - 1 if user is suspended from the list                           #
######################################################################
sub suspend_subscription {
    
    my $email = shift;
    my $list = shift;
    my $data = shift;
    my $robot = shift;
    &Log::do_log('debug2', 'List::suspend_subscription("%s", "%s", "%s" )', $email, $list, $data);

    unless (&SDM::do_query("UPDATE subscriber_table SET suspend_subscriber='1', suspend_start_date_subscriber=%s, suspend_end_date_subscriber=%s WHERE (user_subscriber=%s AND list_subscriber=%s AND robot_subscriber = %s )", 
    &SDM::quote($data->{'startdate'}), 
    &SDM::quote($data->{'enddate'}), 
    &SDM::quote($email), 
    &SDM::quote($list),
    &SDM::quote($robot))) {
	&Log::do_log('err','Unable to suspend subscription of user %s to list %s@%s',$email, $list, $robot);
	return undef;
    }
    
    return 1;
}

######################################################################
###  restore_suspended_subscription                                  #
## Restore the subscription of an user from list(s)                  #
######################################################################
# IN:                                                                #
#   - email : the subscriber email                                   #
#   - list : the name of the list                                    #
#   - robot : domain                                                 #
# OUT:                                                               #
#   - undef if something went wrong.                                 #
#   - 1 if his/her subscription is restored                          #
######################################################################
sub restore_suspended_subscription {

    my $email = shift;
    my $list = shift;
    my $robot = shift;
    &Log::do_log('debug2', 'List::restore_suspended_subscription("%s", "%s", "%s")', $email, $list, $robot);
    
    unless (&SDM::do_query("UPDATE subscriber_table SET suspend_subscriber='0', suspend_start_date_subscriber=NULL, suspend_end_date_subscriber=NULL WHERE (user_subscriber=%s AND list_subscriber=%s AND robot_subscriber = %s )",  
    &SDM::quote($email), 
    &SDM::quote($list),
    &SDM::quote($robot))) {
	&Log::do_log('err','Unable to restore subscription of user %s to list %s@%s',$email, $list, $robot);
	return undef;
    }
    
    return 1;
}

######################################################################
###  insert_delete_exclusion                                         #
## Update the exclusion_table                                        #
######################################################################
# IN:                                                                #
#   - email : the subscriber email                                   #
#   - list : the name of the list                                    #
#   - robot : the name of the domain                                 #
#   - action : insert or delete                                      #
# OUT:                                                               #
#   - undef if something went wrong.                                 #
#   - 1                                                              #
######################################################################
sub insert_delete_exclusion {

    my $email = shift;
    my $list = shift;
    my $robot = shift;
    my $action = shift;
    &Log::do_log('info', 'List::insert_delete_exclusion("%s", "%s", "%s", "%s")', $email, $list, $robot, $action);

    if($action eq 'insert'){
	## INSERT only if $user->{'included'} eq '1'

	my $options;
	$options->{'email'} = $email;
	$options->{'name'} = $list;
	$options->{'domain'} = $robot;
	my $user = &get_list_member_no_object($options);
	my $date = time;

	if ($user->{'included'} eq '1') {
	    ## Insert : list, user and date
	    unless (&SDM::do_query("INSERT INTO exclusion_table (list_exclusion, user_exclusion, date_exclusion) VALUES (%s, %s, %s)", &SDM::quote($list), &SDM::quote($email), &SDM::quote($date))) {
		&Log::do_log('err','Unable to exclude user %s fomr liste %s@%s', $email, $list, $robot);
		return undef;
	    }
	}
	
    }elsif($action eq 'delete') {
	## If $email is in exclusion_table, delete it.
	my $data_excluded = &get_exclusion($list);
	my @users_excluded;

	my $key =0;
	while ($data_excluded->{'emails'}->[$key]){
	    push @users_excluded, $data_excluded->{'emails'}->[$key];
	    $key = $key + 1;
	}

	foreach my $users (@users_excluded) {
	    if($email eq $users){
		## Delete : list, user and date
		unless (&SDM::do_query("DELETE FROM exclusion_table WHERE (list_exclusion = %s AND user_exclusion = %s)", &SDM::quote($list), &SDM::quote($email))) {
		    &Log::do_log('err','Unable to remove entry %s for liste %s for table exclusion_table', $email, $list);
		    return undef;
		}
	    }
	}

    }else{
	&Log::do_log('err','You must choose an action');
	return undef;
    }
   
    return 1;
}

######################################################################
###  get_exclusion                                                   #
## Returns a hash with those excluded from the list and the date.    #
##                                                                   # 
# IN:  - name : the name of the list                                 #
# OUT: - data_exclu : * %data_exclu->{'emails'}->[]                  #
#                     * %data_exclu->{'date'}->[]                    # 
######################################################################
sub get_exclusion {
    
    my  $name= shift;
    &Log::do_log('debug2', 'List::get_exclusion(%s)', $name);
   
    push @sth_stack, $sth;

    unless (&SDM::do_query("SELECT user_exclusion AS email, date_exclusion AS date FROM exclusion_table WHERE list_exclusion = %s", 
    &SDM::quote($name))) {
	&Log::do_log('err','Unable to retrieve excluded users for list %s',$name);
	return undef;
    }

    my @users;
    my @date;
    my $data;
    while ($data = $sth->fetchrow_hashref){
	push @users, $data->{'email'};
	push @date, $data->{'date'};
    }
    ## in order to use the data, we add the emails and dates in differents array
    my $data_exclu = {"emails" => \@users,
		      "date"   => \@date
		      };
    
    $sth->finish();
    $sth = pop @sth_stack;
   
    unless($data_exclu){
	&Log::do_log('err','Unable to retrieve information from database for list %s', $name);
	return undef;
    }
    return $data_exclu;
}

######################################################################
###  get_list_member                                                  #
## Returns a subscriber of the list.  
## Options : 
##    probe : don't log error if user does not exist                             #
######################################################################
sub get_list_member {
    my  $self= shift;
    my  $email = &tools::clean_email(shift);
    my %options = @_;
    
    &Log::do_log('debug2', '(%s)', $email);

    my $name = $self->{'name'};
    
    ## Use session cache
    if (defined $list_cache{'get_list_member'}{$self->{'domain'}}{$name}{$email}) {
	return $list_cache{'get_list_member'}{$self->{'domain'}}{$name}{$email};
    }

    my $options;
    $options->{'email'} = $email;
    $options->{'name'} = $self->{'name'};
    $options->{'domain'} = $self->{'domain'};

    my $user = &get_list_member_no_object($options);

    unless($user){
	do_log('err','Unable to retrieve information from database for user %s', $email) unless ($options{'probe'});
	return undef;
    }
    $user->{'reception'} = $self->{'admin'}{'default_user_options'}{'reception'}
    unless ($self->is_available_reception_mode($user->{'reception'}));
    ## In case it was not set in the database
    $user->{'subscribed'} = 1 if ($self->{'admin'}{'user_data_source'} eq 'database');	

    ## Set session cache
    $list_cache{'get_list_member'}{$self->{'domain'}}{$self->{'name'}}{$email} = $user;

    return $user;
}

#######################################################################
# IN
#   - a single reference to a hash with the following keys:          #
#     * email : the subscriber email                                 #
#     * name: the name of the list                                   #
#     * domain: the virtual host under which the list is installed.  #
#
# OUT : undef if something wrong
#       a hash of tab of ressembling emails
sub get_ressembling_list_members_no_object {
    my $options = shift;
    &Log::do_log('debug2', '(%s, %s, %s)', $options->{'name'}, $options->{'email'}, $options->{'domain'});
    my $name = $options->{'name'};
    my @output;


    
    my $email = &tools::clean_email($options->{'email'});
    my $robot = $options->{'domain'};
    my $listname = $options->{'name'};
    
    
    $email =~ /^(.*)\@(.*)$/;
    my $local_part = $1;
    my $subscriber_domain = $2;
    my %subscribers_email;



    ##### plused
    # is subscriber a plused email ?
    if ($local_part =~ /^(.*)\+(.*)$/) {

	foreach my $subscriber (&find_list_member_by_pattern_no_object({'email_pattern' => $1.'@'.$subscriber_domain,'name'=>$listname,'domain'=>$robot})){
	    next if ($subscribers_email{$subscriber->{'email'}});
	    $subscribers_email{$subscriber->{'email'}} = 1;
	    push @output,$subscriber;
	}			       
    }
    # is some subscriber ressembling with a plused email ?    
    foreach my $subscriber (&find_list_member_by_pattern_no_object({'email_pattern' => $local_part.'+%@'.$subscriber_domain,'name'=>$listname,'domain'=>$robot})){
    	next if ($subscribers_email{$subscriber->{'email'}});
       $subscribers_email{ $subscriber->{'email'} } = 1;
    	push @output,$subscriber;
    }		

    # ressembling local part    
    # try to compare firstname.name@domain with name@domain
        foreach my $subscriber (&find_list_member_by_pattern_no_object({'email_pattern' => '%'.$local_part.'@'.$subscriber_domain,'name'=>$listname,'domain'=>$robot})){
    	next if ($subscribers_email{$subscriber->{'email'}});
    	$subscribers_email{ $subscriber->{'email'} } = 1;
    	push @output,$subscriber;
    }
    
    if ($local_part =~ /^(.*)\.(.*)$/) {
	foreach my $subscriber (&find_list_member_by_pattern_no_object({'email_pattern' => $2.'@'.$subscriber_domain,'name'=>$listname,'domain'=>$robot})){
	    next if ($subscribers_email{$subscriber->{'email'}});
	    $subscribers_email{ $subscriber->{'email'} } = 1;
	    push @output,$subscriber;
	}
    }

    #### Same local_part and ressembling domain
    #
    # compare host.domain.tld with domain.tld
    if ($subscriber_domain =~ /^[^\.]\.(.*)$/) {
	my $upperdomain = $1;
	if ($upperdomain =~ /\./) {
            # remove first token if there is still at least 2 tokens try to find a subscriber with that domain
	    foreach my $subscriber (&find_list_member_by_pattern_no_object({'email_pattern' => $local_part.'@'.$upperdomain,'name'=>$listname,'domain'=>$robot})){
	    	next if ($subscribers_email{$subscriber->{'email'}});
	    	$subscribers_email{ $subscriber->{'email'} } = 1;
	    	push @output,$subscriber;
	    }
	}
    }
    foreach my $subscriber (&find_list_member_by_pattern_no_object({'email_pattern' => $local_part.'@%'.$subscriber_domain,'name'=>$listname,'domain'=>$robot})){
    	next if ($subscribers_email{$subscriber->{'email'}});
    	$subscribers_email{ $subscriber->{'email'} } = 1;
    	push @output,$subscriber;
    }

    # looking for initial
    if ($local_part =~ /^(.*)\.(.*)$/) {
	my $givenname = $1;
	my $name= $2;
	my $initial = '';
	if ($givenname =~ /^([a-z])/){
	    $initial = $1;
	}
	if ($name =~ /^([a-z])/){
	    $initial = $initial.$1;
	}
	foreach my $subscriber (&find_list_member_by_pattern_no_object({'email_pattern' => $initial.'@'.$subscriber_domain,'name'=>$listname,'domain'=>$robot})){
	    next if ($subscribers_email{$subscriber->{'email'}});
	    $subscribers_email{ $subscriber->{'email'} } = 1;
	    push @output,$subscriber;
	}
    }
    


    #### users in the same local part in any other domain
    #
    foreach my $subscriber (&find_list_member_by_pattern_no_object({'email_pattern' => $local_part.'@%','name'=>$listname,'domain'=>$robot})){
	next if ($subscribers_email{$subscriber->{'email'}});
	$subscribers_email{ $subscriber->{'email'} } = 1;
	push @output,$subscriber;
    }

    return \@output;


}


######################################################################
###  find_list_member_by_pattern_no_object                            #
## Get details regarding a subscriber.                               #
# IN:                                                                #
#   - a single reference to a hash with the following keys:          #
#     * email pattern : the subscriber email patern looking for      #
#     * name: the name of the list                                   #
#     * domain: the virtual host under which the list is installed.  #
# OUT:                                                               #
#   - undef if something went wrong.                                 #
#   - a hash containing the user details otherwise                   #
######################################################################

sub find_list_member_by_pattern_no_object {
    my $options = shift;

    my $name = $options->{'name'};
    
    my $email_pattern = &tools::clean_email($options->{'email_pattern'});
    
    my @ressembling_users;

    push @sth_stack, $sth;

    ## Additional subscriber fields
    my $additional;
    if ($Conf::Conf{'db_additional_subscriber_fields'}) {
	$additional = ',' . $Conf::Conf{'db_additional_subscriber_fields'};
    }
    unless ($sth = SDM::do_query("SELECT user_subscriber AS email, comment_subscriber AS gecos, bounce_subscriber AS bounce, bounce_score_subscriber AS bounce_score, bounce_address_subscriber AS bounce_address, reception_subscriber AS reception,  topics_subscriber AS topics, visibility_subscriber AS visibility, %s AS 'date', %s AS update_date, subscribed_subscriber AS subscribed, included_subscriber AS included, include_sources_subscriber AS id, custom_attribute_subscriber AS custom_attribute, suspend_subscriber AS suspend, suspend_start_date_subscriber AS startdate, suspend_end_date_subscriber AS enddate %s FROM subscriber_table WHERE (user_subscriber LIKE %s AND list_subscriber = %s AND robot_subscriber = %s)", 
    &SDM::get_canonical_read_date('date_subscriber'), 
    &SDM::get_canonical_read_date('update_subscriber'), 
    $additional, 
    &SDM::quote($email_pattern), 
    &SDM::quote($name),
    &SDM::quote($options->{'domain'}))) {
	do_log('err','Unable to gather informations corresponding to pattern %s for list %s@%s',$email_pattern,$name,$options->{'domain'});
	return undef;
    }
    
    while (my $user = $sth->fetchrow_hashref('NAME_lc')){
	if (defined $user) {
	    
	    $user->{'reception'} ||= 'mail';
	    $user->{'escaped_email'} = &tools::escape_chars($user->{'email'});
	    $user->{'update_date'} ||= $user->{'date'};
	    if (defined $user->{custom_attribute}) {
		my %custom_attr = &parseCustomAttribute($user->{'custom_attribute'});
		$user->{'custom_attribute'} = \%custom_attr ;
		my @k = sort keys %custom_attr ;
	    }
	push @ressembling_users, $user;
	}
    }
    $sth->finish();
    
    $sth = pop @sth_stack;
    ## Set session cache

    return @ressembling_users;
}

######################################################################
###  get_list_member_no_object                                        #
## Get details regarding a subscriber.                               #
# IN:                                                                #
#   - a single reference to a hash with the following keys:          #
#     * email : the subscriber email                                 #
#     * name: the name of the list                                   #
#     * domain: the virtual host under which the list is installed.  #
# OUT:                                                               #
#   - undef if something went wrong.                                 #
#   - a hash containing the user details otherwise                   #
######################################################################

sub get_list_member_no_object {
    my $options = shift;
    &Log::do_log('debug2', '(%s, %s, %s)', $options->{'name'}, $options->{'email'}, $options->{'domain'});

    my $name = $options->{'name'};
    
    my $email = &tools::clean_email($options->{'email'});
    
    ## Use session cache
    if (defined $list_cache{'get_list_member'}{$options->{'domain'}}{$name}{$email}) {
	return $list_cache{'get_list_member'}{$options->{'domain'}}{$name}{$email};
    }

    push @sth_stack, $sth;

    ## Additional subscriber fields
    my $additional;
    if ($Conf::Conf{'db_additional_subscriber_fields'}) {
	$additional = ',' . $Conf::Conf{'db_additional_subscriber_fields'};
    }
    unless ($sth = SDM::do_query( "SELECT user_subscriber AS email, comment_subscriber AS gecos, bounce_subscriber AS bounce, bounce_score_subscriber AS bounce_score, bounce_address_subscriber AS bounce_address, reception_subscriber AS reception,  topics_subscriber AS topics, visibility_subscriber AS visibility, %s AS 'date', %s AS update_date, subscribed_subscriber AS subscribed, included_subscriber AS included, include_sources_subscriber AS id, custom_attribute_subscriber AS custom_attribute, suspend_subscriber AS suspend, suspend_start_date_subscriber AS startdate, suspend_end_date_subscriber AS enddate %s FROM subscriber_table WHERE (user_subscriber = %s AND list_subscriber = %s AND robot_subscriber = %s)", 
    &SDM::get_canonical_read_date('date_subscriber'), 
    &SDM::get_canonical_read_date('update_subscriber'), 
    $additional, 
    &SDM::quote($email), 
    &SDM::quote($name),
    &SDM::quote($options->{'domain'}))) {
	do_log('err','Unable to gather informations for user: %s', $email,$name,$options->{'domain'});
	return undef;
    }
    my $user = $sth->fetchrow_hashref('NAME_lc');
    if (defined $user) {
	
	$user->{'reception'} ||= 'mail';
	$user->{'update_date'} ||= $user->{'date'};
	do_log('debug2', 'custom_attribute  = (%s)', $user->{custom_attribute});
	if (defined $user->{custom_attribute}) {
	    &Log::do_log('debug2', '1. custom_attribute  = (%s)', $user->{custom_attribute});
	    my %custom_attr = &parseCustomAttribute($user->{'custom_attribute'});
	    $user->{'custom_attribute'} = \%custom_attr ;
	    &Log::do_log('debug2', '2. custom_attribute  = (%s)', %custom_attr);
	    &Log::do_log('debug2', '3. custom_attribute  = (%s)', $user->{custom_attribute});
	    my @k = sort keys %custom_attr ;
	    &Log::do_log('debug2', "keys custom_attribute  = @k");
	}

    }
 
    $sth->finish();

    $sth = pop @sth_stack;
    ## Set session cache
    $list_cache{'get_list_member'}{$options->{'domain'}}{$name}{$email} = $user;
    return $user;
}

## Returns an admin user of the list.
sub get_list_admin {
    my  $self= shift;
    my  $role= shift;
    my  $email = &tools::clean_email(shift);
    
    &Log::do_log('debug2', '(%s,%s)', $role,$email); 

    my $name = $self->{'name'};

    push @sth_stack, $sth;

    ## Use session cache
    if (defined $list_cache{'get_list_admin'}{$self->{'domain'}}{$name}{$role}{$email}) {
	return $list_cache{'get_list_admin'}{$self->{'domain'}}{$name}{$role}{$email};
    }

    unless ($sth = SDM::do_query("SELECT user_admin AS email, comment_admin AS gecos, reception_admin AS reception, visibility_admin AS visibility, %s AS 'date', %s AS update_date, info_admin AS info, profile_admin AS profile, subscribed_admin AS subscribed, included_admin AS included, include_sources_admin AS id FROM admin_table WHERE (user_admin = %s AND list_admin = %s AND robot_admin = %s AND role_admin = %s)", 
	&SDM::get_canonical_read_date('date_admin'), 
	&SDM::get_canonical_read_date('update_admin'), 
	&SDM::quote($email), 
	&SDM::quote($name), 
	&SDM::quote($self->{'domain'}),
	&SDM::quote($role))) {
	do_log('err','Unable to get admin %s for list %s@%s',$email,$name,$self->{'domain'});
	return undef;
    }
    
    my $admin_user = $sth->fetchrow_hashref('NAME_lc');

    if (defined $admin_user) {
	$admin_user->{'reception'} ||= 'mail';
	$admin_user->{'update_date'} ||= $admin_user->{'date'};
	
	## In case it was not set in the database
	$admin_user->{'subscribed'} = 1 if ($self->{'admin'}{'user_data_source'} eq 'database');
    }
    
    $sth->finish();
    
    $sth = pop @sth_stack;
    
    ## Set session cache
    $list_cache{'get_list_admin'}{$self->{'domain'}}{$name}{$role}{$email} = $admin_user;
    
    return $admin_user;
    
}


## Returns the first user for the list.
sub get_first_list_member {
    my ($self, $data) = @_;

    my ($sortby, $offset, $rows, $sql_regexp);
    $sortby = $data->{'sortby'};
    ## Sort may be domain, email, date
    $sortby ||= 'domain';
    $offset = $data->{'offset'};
    $rows = $data->{'rows'};
    $sql_regexp = $data->{'sql_regexp'};
    
    my $lock = new Lock ($self->{'dir'}.'/include');
    unless (defined $lock) {
	&Log::do_log('err','Could not create new lock');
	return undef;
    }
    $lock->set_timeout(10*60); 

    &Log::do_log('debug2', 'List::get_first_list_member(%s,%s,%d,%d)', $self->{'name'},$sortby, $offset, $rows);
        
    ## Get an Shared lock	    
    unless ($lock->lock('read')) {
	return undef;
    }
    
    my $name = $self->{'name'};
    my $statement;
    
    push @sth_stack, $sth;

    ## SQL regexp
    my $selection;
    if ($sql_regexp) {
	$selection = sprintf " AND (user_subscriber LIKE %s OR comment_subscriber LIKE %s)"
	    ,&SDM::quote($sql_regexp), &SDM::quote($sql_regexp);
    }
    
    ## Additional subscriber fields
    my $additional;
    if ($Conf::Conf{'db_additional_subscriber_fields'}) {
	$additional = ',' . $Conf::Conf{'db_additional_subscriber_fields'};
    }
    
    $statement = sprintf "SELECT user_subscriber AS 'email', comment_subscriber AS 'gecos', reception_subscriber AS 'reception', topics_subscriber AS 'topics', visibility_subscriber AS 'visibility', bounce_subscriber AS 'bounce', bounce_score_subscriber AS 'bounce_score', bounce_address_subscriber AS 'bounce_address',  %s AS 'date', %s AS 'update_date', subscribed_subscriber AS 'subscribed', included_subscriber AS 'included', include_sources_subscriber AS 'id', custom_attribute_subscriber AS 'custom_attribute', suspend_subscriber AS 'suspend', suspend_start_date_subscriber AS 'startdate', suspend_end_date_subscriber AS 'enddate' %s FROM subscriber_table WHERE (list_subscriber = %s AND robot_subscriber = %s %s)", 
    &SDM::get_canonical_read_date('date_subscriber'), 
    &SDM::get_canonical_read_date('update_subscriber'), 
    $additional, 
    &SDM::quote($name), 
    &SDM::quote($self->{'domain'}),
    $selection;
    
    ## SORT BY
    if ($sortby eq 'domain') {
	## Redefine query to set "dom"
	
	$statement = sprintf "SELECT user_subscriber AS 'email', comment_subscriber AS 'gecos', reception_subscriber AS 'reception', topics_subscriber AS 'topics', visibility_subscriber AS 'visibility', bounce_subscriber AS 'bounce', bounce_score_subscriber AS 'bounce_score', bounce_address_subscriber AS 'bounce_address',  %s AS 'date', %s AS 'update_date', subscribed_subscriber AS 'subscribed', included_subscriber AS 'included', include_sources_subscriber AS 'id', custom_attribute_subscriber AS 'custom_attribute', %s AS 'dom', suspend_subscriber AS 'suspend', suspend_start_date_subscriber AS 'startdate', suspend_end_date_subscriber AS 'enddate' %s FROM subscriber_table WHERE (list_subscriber = %s AND robot_subscriber = %s ) ORDER BY 'dom'", 
	&SDM::get_canonical_read_date('date_subscriber'), 
	&SDM::get_canonical_read_date('update_subscriber'), 
	&SDM::get_substring_clause({'source_field'=>'user_subscriber','separator'=>'\@','substring_length'=>'50',}),
	$additional, 
	&SDM::quote($name),
	&SDM::quote($self->{'domain'});
	
    }elsif ($sortby eq 'email') {
	## Default SORT
	$statement .= ' ORDER BY email';
	
    }elsif ($sortby eq 'date') {
	$statement .= ' ORDER BY date DESC';
	
    }elsif ($sortby eq 'sources') {
	$statement .= " ORDER BY subscribed DESC,id";
	
    }elsif ($sortby eq 'name') {
	$statement .= ' ORDER BY gecos';
    } 
    
    ## LIMIT clause
    if (defined($rows) and defined($offset)) {
	$statement .= &SDM::get_limit_clause({'rows_count'=>$rows,'offset'=>$offset});
    }
    
    unless ($sth = SDM::do_query($statement)) {
	do_log('err','Unable to get members of list %s@%s', $name, $self->{'domain'});
	return undef;
    }
    
    my $user = $sth->fetchrow_hashref('NAME_lc');
    if (defined $user) {
	&Log::do_log('err','Warning: entry with empty email address in list %s', $self->{'name'}) 
	    if (! $user->{'email'});
	$user->{'reception'} ||= 'mail';
	$user->{'reception'} = $self->{'admin'}{'default_user_options'}{'reception'}
	unless ($self->is_available_reception_mode($user->{'reception'}));
	$user->{'update_date'} ||= $user->{'date'};
	
	## In case it was not set in the database
	$user->{'subscribed'} = 1 if (defined($user) && ($self->{'admin'}{'user_data_source'} eq 'database'));

	############################################################################	    
	if (defined $user->{custom_attribute}) {
	    &Log::do_log('debug2', 'custom_attribute  = (%s)', $user->{custom_attribute});
	    my %custom_attr = &parseCustomAttribute($user->{'custom_attribute'});
	    $user->{'custom_attribute'} = \%custom_attr ;
	}


    }
    else {
	$sth->finish;
	$sth = pop @sth_stack;
	
	if ($self->{'admin'}{'user_data_source'} eq 'include2') {
	    
	    ## Release the Shared lock
	    unless ($lock->unlock()) {
		return undef;
	    }
	}
    }
    
    ## If no offset (for LIMIT) was used, update total of subscribers
    unless ($offset) {
	my $total = $self->_load_total_db('nocache');
	if ($total != $self->{'total'}) {
	    $self->{'total'} = $total;
	    $self->savestats();
	}
    }
    
    return $user;
}

# Create a custom attribute from an XML description
# IN : File handle or a string, XML formed data as stored in database
# OUT : HASH data storing custome attributes.
sub parseCustomAttribute {
	my $xmldoc = shift ;
	return undef if ($xmldoc eq '') ;

	my $parser = XML::LibXML->new();
	my $tree;

	## We should use eval to parse to prevent the program to crash if it fails
	if (ref($xmldoc) eq 'GLOB') {
	    $tree = eval {$parser->parse_fh($xmldoc)};
	}else {
	    $tree = eval {$parser->parse_string($xmldoc)};
	}

	unless (defined $tree) {
	    &Log::do_log('err', "Failed to parse XML data");
	    return undef;
	}

	my $doc = $tree->getDocumentElement;
	
	my @custom_attr = $doc->getChildrenByTagName('custom_attribute') ;
	my %ca ;
	foreach my $ca (@custom_attr) {
	        my $id = Encode::encode_utf8($ca->getAttribute('id'));
	        my $value = Encode::encode_utf8($ca->getElementsByTagName('value'));
		$ca{$id} = {value=>$value} ;
	}
	return %ca ;
}

# Create an XML Custom attribute to be stored into data base.
# IN : HASH data storing custome attributes
# OUT : string, XML formed data to be stored in database
sub createXMLCustomAttribute {
	my $custom_attr = shift ;
	return '<?xml version="1.0" encoding="UTF-8" ?><custom_attributes></custom_attributes>' if (not defined $custom_attr) ;
	my $XMLstr = '<?xml version="1.0" encoding="UTF-8" ?><custom_attributes>';
	foreach my $k (sort keys %{$custom_attr} ) {
		$XMLstr .= "<custom_attribute id=\"$k\"><value>".&tools::escape_html($custom_attr->{$k}{value})."</value></custom_attribute>";
	}
	$XMLstr .= "</custom_attributes>";
	
	return $XMLstr ;
}

## Returns the first admin_user with $role for the list.
sub get_first_list_admin {
    my ($self, $role, $data) = @_;

    my ($sortby, $offset, $rows, $sql_regexp);
    $sortby = $data->{'sortby'};
    ## Sort may be domain, email, date
    $sortby ||= 'domain';
    $offset = $data->{'offset'};
    $rows = $data->{'rows'};
    $sql_regexp = $data->{'sql_regexp'};
    my $fh;

    &Log::do_log('debug2', '(%s,%s,%s,%d,%d)', $self->{'name'},$role, $sortby, $offset, $rows);

    my $lock = new Lock ($self->{'dir'}.'/include_admin_user');
    unless (defined $lock) {
	&Log::do_log('err','Could not create new lock');
	return undef;
    }
    $lock->set_timeout(20); 

    ## Get a shared lock
    unless ($fh = $lock->lock('read')) {
	return undef;
    }
          
    my $name = $self->{'name'};
    my $statement;
    
    ## SQL regexp
    my $selection;
    if ($sql_regexp) {
	$selection = sprintf " AND (user_admin LIKE %s OR comment_admin LIKE %s)"
	    ,&SDM::quote($sql_regexp), &SDM::quote($sql_regexp);
    }
    push @sth_stack, $sth;	    
    
    $statement = sprintf "SELECT user_admin AS 'email', comment_admin AS 'gecos', reception_admin AS 'reception', visibility_admin AS 'visibility', %s AS 'date', %s AS 'update_date', info_admin AS 'info', profile_admin AS 'profile', subscribed_admin AS 'subscribed', included_admin AS 'included', include_sources_admin AS 'id' FROM admin_table WHERE (list_admin = %s AND robot_admin = %s %s AND role_admin = %s)", 
    &SDM::get_canonical_read_date('date_admin'), 
    &SDM::get_canonical_read_date('update_admin'), 
    &SDM::quote($name), 
    &SDM::quote($self->{'domain'}),
    $selection, 
    &SDM::quote($role);
    
    ## SORT BY
    if ($sortby eq 'domain') {
	## Redefine query to set "dom"
	
	$statement = sprintf "SELECT user_admin AS 'email', comment_admin AS 'gecos', reception_admin AS 'reception', visibility_admin AS 'visibility', %s AS 'date', %s AS 'update_date', info_admin AS 'info', profile_admin AS 'profile', subscribed_admin AS 'subscribed', included_admin AS 'included', include_sources_admin AS 'id', %s AS 'dom'  FROM admin_table WHERE (list_admin = %s AND robot_admin = %s AND role_admin = %s) ORDER BY 'dom'",
	&SDM::get_canonical_read_date('date_admin'), 
	&SDM::get_canonical_read_date('update_admin'), 
	&SDM::get_substring_clause({'source_field'=>'user_admin','separator'=>'\@','substring_length'=>'50'}),
	&SDM::quote($name), 
	&SDM::quote($self->{'domain'}),
	&SDM::quote($role);
    }elsif ($sortby eq 'email') {
	$statement .= ' ORDER BY email';
	
    }elsif ($sortby eq 'date') {
	$statement .= ' ORDER BY date DESC';
	
    }elsif ($sortby eq 'sources') {
	$statement .= " ORDER BY subscribed DESC,id";
	
    }elsif ($sortby eq 'email') {
	$statement .= ' ORDER BY gecos';
    }
	
    ## LIMIT clause
    if (defined($rows) and defined($offset)) {
	$statement .= &SDM::get_substring_clause({'rows_count'=>$rows,'offset'=>$offset});
    }
    
    unless ($sth = &SDM::do_query($statement)) {
	do_log('err','Unable to get admins having role %s for list %s@%s', $role,$name,$self->{'domain'});
	return undef;
    }
    
    my $admin_user = $sth->fetchrow_hashref('NAME_lc');
    if (defined $admin_user) {
	&Log::do_log('err','Warning: entry with empty email address in list %s', $self->{'name'}) 
	    if (! $admin_user->{'email'});
	$admin_user->{'reception'} ||= 'mail';
	$admin_user->{'update_date'} ||= $admin_user->{'date'};

	## In case it was not set in the database
	$admin_user->{'subscribed'} = 1 if (defined($admin_user) && ($self->{'admin'}{'user_data_source'} eq 'database'));

    }else {
	$sth->finish;
        $sth = pop @sth_stack;

	## Release the Shared lock
	my $lock = new Lock($self->{'dir'}.'/include_admin_user');
	unless (defined $lock) {
	    &Log::do_log('err','Could not create new lock');
	    return undef;
	}
	
	unless ($lock->unlock()) {
	    return undef;
	}
    }

    return $admin_user;
}
    
## Loop for all subsequent users.
sub get_next_list_member {
    my $self = shift;
    &Log::do_log('debug2', '');

    unless (defined $sth) {
	&Log::do_log('err', 'No handle defined, get_first_list_member(%s) was not run', $self->{'name'});
	return undef;
    }
    
    my $user = $sth->fetchrow_hashref('NAME_lc');
    
    if (defined $user) {
	&Log::do_log('err','Warning: entry with empty email address in list %s', $self->{'name'}) 
	    if (! $user->{'email'});
	$user->{'reception'} ||= 'mail';
	unless ($self->is_available_reception_mode($user->{'reception'})){
	    $user->{'reception'} = $self->{'admin'}{'default_user_options'}{'reception'}
	}
	$user->{'update_date'} ||= $user->{'date'};
	
	## In case it was not set in the database
	$user->{'subscribed'} = 1 if (defined($user) && ($self->{'admin'}{'user_data_source'} eq 'database'));

	do_log('debug2', '(email = %s)', $user->{'email'});
	if (defined $user->{custom_attribute}) {
	    &Log::do_log('debug2', '1. custom_attribute  = (%s)', $user->{custom_attribute});
	    my %custom_attr = &parseCustomAttribute($user->{'custom_attribute'});
	    $user->{'custom_attribute'} = \%custom_attr ;
	    &Log::do_log('debug2', '2. custom_attribute  = (%s)', %custom_attr);
	    &Log::do_log('debug2', '3. custom_attribute  = (%s)', $user->{custom_attribute});
	    my @k = sort keys %custom_attr ;
	    &Log::do_log('debug2', "keys custom_attribute  = @k");
	}
    }
    else {
	$sth->finish;
	$sth = pop @sth_stack;
	
	if ($self->{'admin'}{'user_data_source'} eq 'include2') {
	    
	    ## Release lock
	    my $lock = new Lock ($self->{'dir'}.'/include');
	    unless (defined $lock) {
		&Log::do_log('err','Could not create new lock');
		return undef;
	    }
	    unless ($lock->unlock()) {
		return undef;
	    }
	}
    }
    
#	$self->{'total'}++;
    
    return $user;
}

## Loop for all subsequent admin users with the role defined in get_first_list_admin.
sub get_next_list_admin {
    my $self = shift;
    &Log::do_log('debug2', ''); 

    unless (defined $sth) {
	&Log::do_log('err','Statement handle not defined in get_next_list_admin for list %s', $self->{'name'});
	return undef;
    }
    
    my $admin_user = $sth->fetchrow_hashref('NAME_lc');

    if (defined $admin_user) {
	&Log::do_log('err','Warning: entry with empty email address in list %s', $self->{'name'}) 
	    if (! $admin_user->{'email'});
	$admin_user->{'reception'} ||= 'mail';
	$admin_user->{'update_date'} ||= $admin_user->{'date'};
	
	## In case it was not set in the database
	$admin_user->{'subscribed'} = 1 if (defined($admin_user) && ($self->{'admin'}{'user_data_source'} eq 'database'));
    }
    else {
	$sth->finish;
	$sth = pop @sth_stack;
	
	## Release the Shared lock
	my $lock = new Lock($self->{'dir'}.'/include_admin_user');
	unless (defined $lock) {
	    &Log::do_log('err','Could not create new lock');
	    return undef;
	}
	
	unless ($lock->unlock()) {
	    return undef;
	}
    }
    return $admin_user;
}




## Returns the first bouncing user
sub get_first_bouncing_list_member {
    my $self = shift;
    &Log::do_log('debug2', '');

    my $lock = new Lock ($self->{'dir'}.'/include');
    unless (defined $lock) {
	&Log::do_log('err','Could not create new lock');
	return undef;
    }
    $lock->set_timeout(10*60); 

    ## Get an Shared lock
    unless ($lock->lock('read')) {
	return undef;
    }

    my $name = $self->{'name'};
    
    ## Additional subscriber fields
    my $additional;
    if ($Conf::Conf{'db_additional_subscriber_fields'}) {
	$additional = ',' . $Conf::Conf{'db_additional_subscriber_fields'};
    }

    push @sth_stack, $sth;

    unless ($sth = SDM::do_query("SELECT user_subscriber AS email, reception_subscriber AS reception, topics_subscriber AS topics, visibility_subscriber AS visibility, bounce_subscriber AS bounce,bounce_score_subscriber AS bounce_score, %s AS 'date', %s AS update_date,suspend_subscriber AS suspend, suspend_start_date_subscriber AS startdate, suspend_end_date_subscriber AS enddate %s FROM subscriber_table WHERE (list_subscriber = %s AND robot_subscriber = %s AND bounce_subscriber is not NULL)", 
	&SDM::get_canonical_read_date('date_subscriber'), 
	&SDM::get_canonical_read_date('update_subscriber'), 
	$additional, 
	&SDM::quote($name),
	&SDM::quote($self->{'domain'}))) {
	    &Log::do_log('err','Unable to get bouncing users %s@%s',$name,$self->{'domain'});
	    return undef;
	}

    my $user = $sth->fetchrow_hashref('NAME_lc');
	    
    if (defined $user) {
	&Log::do_log('err','Warning: entry with empty email address in list %s', $self->{'name'}) 
	    if (! $user->{'email'});
	
	## In case it was not set in the database
	$user->{'subscribed'} = 1 if (defined ($user) && ($self->{'admin'}{'user_data_source'} eq 'database'));    

    }else {
	$sth->finish;
	$sth = pop @sth_stack;
	
	## Release the Shared lock
	unless ($lock->unlock()) {
	    return undef;
	}
    }
    return $user;
}

## Loop for all subsequent bouncing users.
sub get_next_bouncing_list_member {
    my $self = shift;
    &Log::do_log('debug2', '');

    unless (defined $sth) {
	&Log::do_log('err', 'No handle defined, get_first_bouncing_list_member(%s) was not run', $self->{'name'});
	return undef;
    }
    
    my $user = $sth->fetchrow_hashref('NAME_lc');
    
    if (defined $user) {
	&Log::do_log('err','Warning: entry with empty email address in list %s', $self->{'name'}) 
	    if (! $user->{'email'});
	
	## In case it was not set in the database
	$user->{'subscribed'} = 1 if (defined ($user) && ($self->{'admin'}{'user_data_source'} eq 'database'));    
	if (defined $user->{custom_attribute}) {
	    	my %custom_attr = &parseCustomAttribute($user->{'custom_attribute'});
	    	$user->{'custom_attribute'} = \%custom_attr ;
	    }

    }else {
	$sth->finish;
	$sth = pop @sth_stack;
	
	## Release the Shared lock
	my $lock = new Lock ($self->{'dir'}.'/include');
	unless (defined $lock) {
	    &Log::do_log('err','Could not create new lock');
	    return undef;
	}
	unless ($lock->unlock()) {
	    return undef;
	}
    }

    return $user;
}

sub get_info {
    my $self = shift;

    my $info;
    
    unless (open INFO, "$self->{'dir'}/info") {
	&Log::do_log('err', 'Could not open %s : %s', $self->{'dir'}.'/info', $!);
	return undef;
    }
    
    while (<INFO>) {
	$info .= $_;
    }
    close INFO;

    return $info;
}

## Total bouncing subscribers
sub get_total_bouncing {
    my $self = shift;
    &Log::do_log('debug2', 'List::get_total_boucing');

    my $name = $self->{'name'};
   
    push @sth_stack, $sth;

    ## Query the Database
    unless ($sth = &SDM::do_query( "SELECT count(*) FROM subscriber_table WHERE (list_subscriber = %s  AND robot_subscriber = %s AND bounce_subscriber is not NULL)", &SDM::quote($name), &SDM::quote($self->{'domain'}))) {
	do_log('err','Unable to gather bouncing subscribers count for list %s@%s',$name,$self->{'domain'});
	return undef;
    }
    
    my $total =  $sth->fetchrow;

    $sth->finish();

    $sth = pop @sth_stack;

    return $total;
}

## Is the person in user table (db only)
sub is_global_user {
   my $who = &tools::clean_email(pop);
   &Log::do_log('debug3', '(%s)', $who);

   return undef unless ($who);
   
   push @sth_stack, $sth;

   ## Query the Database
   unless($sth = &SDM::do_query("SELECT count(*) FROM user_table WHERE email_user = %s", &SDM::quote($who))) {
       &Log::do_log('err','Unable to check whether user %s is in the user table.');
       return undef;
   }
   
   my $is_user = $sth->fetchrow();
   $sth->finish();
   
   $sth = pop @sth_stack;

   return $is_user;
}

## Is the indicated person a subscriber to the list?
sub is_list_member {
    my ($self, $who) = @_;
    $who = &tools::clean_email($who);
    &Log::do_log('debug3', '(%s)', $who);
    
    return undef unless ($self && $who);
    
    my $name = $self->{'name'};
    
    push @sth_stack, $sth;
    
    ## Use cache
    if (defined $list_cache{'is_list_member'}{$self->{'domain'}}{$name}{$who}) {
	return $list_cache{'is_list_member'}{$self->{'domain'}}{$name}{$who};
    }
    
    ## Query the Database
    unless ( $sth = &SDM::do_query("SELECT count(*) FROM subscriber_table WHERE (list_subscriber = %s AND robot_subscriber = %s AND user_subscriber = %s)",&SDM::quote($name), &SDM::quote($self->{'domain'}), &SDM::quote($who))) {
	do_log('err','Unable to check chether user %s is subscribed to list %s@%s : %s', $who, $name, $self->{'domain'});
	return undef;
    }
    
    my $is_user = $sth->fetchrow;
    
    $sth->finish();
    
    $sth = pop @sth_stack;
    
    ## Set cache
    $list_cache{'is_list_member'}{$self->{'domain'}}{$name}{$who} = $is_user;
    
    return $is_user;
}

## Sets new values for the given user (except gecos)
sub update_list_member {
    my($self, $who, $values) = @_;
    &Log::do_log('debug2', '(%s)', $who);
    $who = &tools::clean_email($who);    

    my ($field, $value);
    
    my ($user, $statement, $table);
    my $name = $self->{'name'};
    
    ## mapping between var and field names
    my %map_field = ( reception => 'reception_subscriber',
		      topics => 'topics_subscriber',
		      visibility => 'visibility_subscriber',
		      date => 'date_subscriber',
		      update_date => 'update_subscriber',
		      gecos => 'comment_subscriber',
		      password => 'password_user',
		      bounce => 'bounce_subscriber',
		      score => 'bounce_score_subscriber',
		      email => 'user_subscriber',
		      subscribed => 'subscribed_subscriber',
		      included => 'included_subscriber',
		      id => 'include_sources_subscriber',
		      bounce_address => 'bounce_address_subscriber',
		      custom_attribute => 'custom_attribute_subscriber',
		      suspend => 'suspend_subscriber',
		      startdate_subscriber => 'suspend_start_date_subscriber',
		      enddate => 'suspend_end_date_subscriber'
		      );
    
    ## mapping between var and tables
    my %map_table = ( reception => 'subscriber_table',
		      topics => 'subscriber_table', 
		      visibility => 'subscriber_table',
		      date => 'subscriber_table',
		      update_date => 'subscriber_table',
		      gecos => 'subscriber_table',
		      password => 'user_table',
		      bounce => 'subscriber_table',
		      score => 'subscriber_table',
		      email => 'subscriber_table',
		      subscribed => 'subscriber_table',
		      included => 'subscriber_table',
		      id => 'subscriber_table',
		      bounce_address => 'subscriber_table',
		      custom_attribute => 'subscriber_table',
		      suspend => 'subscriber_table',
		      startdate => 'subscriber_table',
		      enddate => 'subscriber_table'
		      );
    
    ## additional DB fields
    if (defined $Conf::Conf{'db_additional_subscriber_fields'}) {
	foreach my $f (split ',', $Conf::Conf{'db_additional_subscriber_fields'}) {
	    $map_table{$f} = 'subscriber_table';
	    $map_field{$f} = $f;
	}
    }
    
    if (defined $Conf::Conf{'db_additional_user_fields'}) {
	foreach my $f (split ',', $Conf::Conf{'db_additional_user_fields'}) {
	    $map_table{$f} = 'user_table';
	    $map_field{$f} = $f;
	}
    }
    
    &Log::do_log('debug2', " custom_attribute id: $Conf::Conf{'custom_attribute'}");
    ## custom attributes
    if (defined $Conf::Conf{'custom_attribute'}){
	foreach my $f (sort keys %{$Conf::Conf{'custom_attribute'}}){
	    &Log::do_log('debug2', "custom_attribute id: $Conf::Conf{'custom_attribute'}{id} name: $Conf::Conf{'custom_attribute'}{name} type: $Conf::Conf{'custom_attribute'}{type} ");
	    	
	}
    }
    
    ## Update each table
    foreach $table ('user_table','subscriber_table') {
	
	my @set_list;
	while (($field, $value) = each %{$values}) {
	    
	    unless ($map_field{$field} and $map_table{$field}) {
		&Log::do_log('err', 'Unknown database field %s', $field);
		next;
	    }
	    
	    if ($map_table{$field} eq $table) {
		if ($field eq 'date' || $field eq 'update_date') {
		    $value = &SDM::get_canonical_write_date($value);
		}elsif ($value eq 'NULL'){ ## get_null_value?
		    if ($Conf::Conf{'db_type'} eq 'mysql') {
			$value = '\N';
		    }
		}else {
		    if ($numeric_field{$map_field{$field}}) {
			$value ||= 0; ## Can't have a null value
		    }else {
			$value = &SDM::quote($value);
		    }
		}
		my $set = sprintf "%s=%s", $map_field{$field}, $value;
		push @set_list, $set;
	    }
	}
	next unless @set_list;
	
	## Update field
	if ($table eq 'user_table') {
	    unless ($sth = &SDM::do_query("UPDATE %s SET %s WHERE (email_user=%s)", $table, join(',', @set_list), &SDM::quote($who))) {
		&Log::do_log('err','Could not update informations for user %s in table %s',$who,$table);
		return undef;
	    }
	}elsif ($table eq 'subscriber_table') {
	    if ($who eq '*') {
		unless ($sth = &SDM::do_query("UPDATE %s SET %s WHERE (list_subscriber=%s AND robot_subscriber = %s)", 
		$table, 
		join(',', @set_list), 
		&SDM::quote($name), 
		&SDM::quote($self->{'domain'}))) {
		    &Log::do_log('err','Could not update informations for user %s in table %s for list %s@%s',$who,$table,$name,$self->{'domain'});
		    return undef;
		}	
	    }else {
		unless ($sth = &SDM::do_query("UPDATE %s SET %s WHERE (user_subscriber=%s AND list_subscriber=%s AND robot_subscriber = %s)", 
		$table, 
		join(',', @set_list), 
		&SDM::quote($who), 
		&SDM::quote($name),
		&SDM::quote($self->{'domain'}))) {
		    &Log::do_log('err','Could not update informations for user %s in table %s for list %s@%s',$who,$table,$name,$self->{'domain'});
		    return undef;
		}
	    }
	}
    }

    ## Rename picture on disk if user email changed
    if ($values->{'email'}) {
	my $file_name = &tools::md5_fingerprint($who);
	my $picture_file_path = &Conf::get_robot_conf($self->{'domain'},'pictures_path').'/'.$self->{'name'}.'@'.$self->{'domain'};

	foreach my $extension ('gif','png','jpg','jpeg') {
	    if (-f $picture_file_path.'/'.$file_name.'.'.$extension) {
		my $new_file_name = &tools::md5_fingerprint($values->{'email'});
		unless (rename $picture_file_path.'/'.$file_name.'.'.$extension, $picture_file_path.'/'.$new_file_name.'.'.$extension) {
		    &Log::do_log('err', "Failed to rename %s to %s : %s", $picture_file_path.'/'.$file_name.'.'.$extension, $picture_file_path.'/'.$new_file_name.'.'.$extension, $!);
		}
	    }
	}
    }
    
    ## Reset session cache
    $list_cache{'get_list_member'}{$self->{'domain'}}{$name}{$who} = undef;
    
    return 1;
}


## Sets new values for the given admin user (except gecos)
sub update_list_admin {
    my($self, $who,$role, $values) = @_;
    &Log::do_log('debug2', '(%s,%s)', $role, $who); 
    $who = &tools::clean_email($who);    

    my ($field, $value);
    
    my ($admin_user, $statement, $table);
    my $name = $self->{'name'};
    
    ## mapping between var and field names
    my %map_field = ( reception => 'reception_admin',
		      visibility => 'visibility_admin',
		      date => 'date_admin',
		      update_date => 'update_admin',
		      gecos => 'comment_admin',
		      password => 'password_user',
		      email => 'user_admin',
		      subscribed => 'subscribed_admin',
		      included => 'included_admin',
		      id => 'include_sources_admin',
		      info => 'info_admin',
		      profile => 'profile_admin',
		      role => 'role_admin'
		      );
    
    ## mapping between var and tables
    my %map_table = ( reception => 'admin_table',
		      visibility => 'admin_table',
		      date => 'admin_table',
		      update_date => 'admin_table',
		      gecos => 'admin_table',
		      password => 'user_table',
		      email => 'admin_table',
		      subscribed => 'admin_table',
		      included => 'admin_table',
		      id => 'admin_table',
		      info => 'admin_table',
		      profile => 'admin_table',
		      role => 'admin_table'
		      );
#### ??
    ## additional DB fields
#    if (defined $Conf::Conf{'db_additional_user_fields'}) {
#	foreach my $f (split ',', $Conf::Conf{'db_additional_user_fields'}) {
#	    $map_table{$f} = 'user_table';
#	    $map_field{$f} = $f;
#	}
#    }
    
    ## Update each table
    foreach $table ('user_table','admin_table') {
	
	my @set_list;
	while (($field, $value) = each %{$values}) {
	    
	    unless ($map_field{$field} and $map_table{$field}) {
		&Log::do_log('err', 'Unknown database field %s', $field);
		next;
	    }
	    
	    if ($map_table{$field} eq $table) {
		if ($field eq 'date' || $field eq 'update_date') {
		    $value = &SDM::get_canonical_write_date($value);
		}elsif ($value eq 'NULL'){ #get_null_value?
		    if ($Conf::Conf{'db_type'} eq 'mysql') {
			$value = '\N';
		    }
		}else {
		    if ($numeric_field{$map_field{$field}}) {
			$value ||= 0; ## Can't have a null value
		    }else {
			$value = &SDM::quote($value);
		    }
		}
		my $set = sprintf "%s=%s", $map_field{$field}, $value;

		push @set_list, $set;
	    }
	}
	next unless @set_list;
	
	## Update field
	if ($table eq 'user_table') {
	    unless ($sth = &SDM::do_query("UPDATE %s SET %s WHERE (email_user=%s)", $table, join(',', @set_list), &SDM::quote($who))) {
		&Log::do_log('err','Could not update informations for admin %s in table %s',$who,$table);
		return undef;
	    } 
	    
	}elsif ($table eq 'admin_table') {
	    if ($who eq '*') {
		unless ($sth = &SDM::do_query("UPDATE %s SET %s WHERE (list_admin=%s AND robot_admin=%s AND role_admin=%s)", 
		$table, 
		join(',', @set_list), 
		&SDM::quote($name), 
		&SDM::quote($self->{'domain'}),
		&SDM::quote($role))) {
		    &Log::do_log('err','Could not update informations for admin %s in table %s for list %s@%s',$who,$table,$name,$self->{'domain'});
		    return undef;
		}
	    }else {
		unless ($sth = &SDM::do_query("UPDATE %s SET %s WHERE (user_admin=%s AND list_admin=%s AND robot_admin=%s AND role_admin=%s )", 
		$table, 
		join(',', @set_list), 
		&SDM::quote($who), 
		&SDM::quote($name), 
		&SDM::quote($self->{'domain'}),
		&SDM::quote($role))) {
		    &Log::do_log('err','Could not update informations for admin %s in table %s for list %s@%s',$who,$table,$name,$self->{'domain'});
		    return undef;
		}
	    }
	}
    }

    ## Reset session cache
    $list_cache{'get_list_admin'}{$self->{'domain'}}{$name}{$role}{$who} = undef;
    
    return 1;
}



## Sets new values for the given user in the Database
sub update_global_user {
    my($who, $values) = @_;
    &Log::do_log('debug', '(%s)', $who);

    $who = &tools::clean_email($who);

    ## use md5 fingerprint to store password   
    $values->{'password'} = &Auth::password_fingerprint($values->{'password'}) if ($values->{'password'});

    my ($field, $value);
    
    my ($user, $statement, $table);
    
    ## mapping between var and field names
    my %map_field = ( gecos => 'gecos_user',
		      password => 'password_user',
		      cookie_delay => 'cookie_delay_user',
		      lang => 'lang_user',
		      attributes => 'attributes_user',
		      email => 'email_user',
		      data => 'data_user',
		      last_login_date => 'last_login_date_user',
		      last_login_host => 'last_login_host_user',
		      wrong_login_count => 'wrong_login_count_user'
		      );
    
    ## Update each table
    my @set_list;

    while (($field, $value) = each %{$values}) {
	unless ($map_field{$field}) {
	    &Log::do_log('error',"unkown field $field in map_field internal error");
	    next;
	};
	my $set;
	
	if ($numeric_field{$map_field{$field}})  {
	    $value ||= 0; ## Can't have a null value
	    $set = sprintf '%s=%s', $map_field{$field}, $value;
	}else { 
	    $set = sprintf '%s=%s', $map_field{$field}, &SDM::quote($value);
	}
	push @set_list, $set;
    }
    
    return undef unless @set_list;
    
    ## Update field

    unless ($sth = &SDM::do_query("UPDATE user_table SET %s WHERE (email_user=%s)"
	    , join(',', @set_list), &SDM::quote($who))) {
	&Log::do_log('err','Could not update informations for user %s in user_table',$who);
	return undef;
    }
    
    return 1;
}

## Adds a user to the user_table
sub add_global_user {
    my($values) = @_;
    &Log::do_log('debug2', '');

    my ($field, $value);
    my ($user, $statement, $table);
    
    ## encrypt password   
    $values->{'password'} = &Auth::password_fingerprint($values->{'password'}) if ($values->{'password'});
    
    return undef unless (my $who = &tools::clean_email($values->{'email'}));
    
    return undef if (is_global_user($who));
    
    ## mapping between var and field names
    my %map_field = ( email => 'email_user',
		      gecos => 'gecos_user',
		      custom_attribute => 'custom_attribute',
		      password => 'password_user',
		      cookie_delay => 'cookie_delay_user',
		      lang => 'lang_user',
		      attributes => 'attributes_user'
		      );
    
    ## Update each table
    my (@insert_field, @insert_value);
    while (($field, $value) = each %{$values}) {
	
	next unless ($map_field{$field});
	
	my $insert;
	if ($numeric_field{$map_field{$field}}) {
	    $value ||= 0; ## Can't have a null value
	    $insert = $value;
	}else {
	    $insert = sprintf "%s", &SDM::quote($value);
	}
	push @insert_value, $insert;
	push @insert_field, $map_field{$field}
    }
    
    unless (@insert_field) {
	&Log::do_log('err','The fields (%s) do not correspond to anything in the database',join (',',keys(%{$values})));
	return undef;
    }
    
    ## Update field
    unless($sth = &SDM::do_query("INSERT INTO user_table (%s) VALUES (%s)"
	, join(',', @insert_field), join(',', @insert_value))) {
	    do_log('err','Unable to add user %s to the DB table user_table', $values->{'email'});
	    return undef;
	}
    
    return 1;
}

## Adds a list member ; no overwrite.
sub add_list_member {
    my($self, @new_users, $daemon) = @_;
    &Log::do_log('debug2', '%s', $self->{'name'});
    
    my $name = $self->{'name'};
    my $total = 0;
    
    my $subscriptions = $self->get_subscription_requests();

    foreach my $new_user (@new_users) {
	my $who = &tools::clean_email($new_user->{'email'});
	next unless $who;
	
	# Delete from exclusion_table if new_user is in.
	&insert_delete_exclusion($who, $name, $self->{'domain'}, 'delete');

	$new_user->{'date'} ||= time;
	$new_user->{'update_date'} ||= $new_user->{'date'};
	
	my %custom_attr = %{ $subscriptions->{$who}{'custom_attribute'} } if (defined $subscriptions->{$who}{'custom_attribute'} );
	$new_user->{'custom_attribute'} ||= &createXMLCustomAttribute(\%custom_attr) ;
	do_log('debug2', 'custom_attribute = %s', $new_user->{'custom_attribute'});

	## Crypt password if it was not crypted
	unless ($new_user->{'password'} =~ /^crypt/) {
	    $new_user->{'password'} = &tools::crypt_password($new_user->{'password'});
	}
	
	$list_cache{'is_list_member'}{$self->{'domain'}}{$name}{$who} = undef;
	
	## Either is_included or is_subscribed must be set
	## default is is_subscriber for backward compatibility reason
	unless ($new_user->{'included'}) {
	    $new_user->{'subscribed'} = 1;
	}
	
	unless ($new_user->{'included'}) {
	    ## Is the email in user table?
	    if (! is_global_user($who)) {
		## Insert in User Table
		unless(&SDM::do_query("INSERT INTO user_table (email_user, gecos_user, lang_user, password_user) VALUES (%s,%s,%s,%s)",&SDM::quote($who), &SDM::quote($new_user->{'gecos'}), &SDM::quote($new_user->{'lang'}), &SDM::quote($new_user->{'password'}))){
		    &Log::do_log('err','Unable to add user %s to user_table.', $who);
		    next;
		}
	    }
	}	    
	
	$new_user->{'subscribed'} ||= 0;
	$new_user->{'included'} ||= 0;

	#Log in stat_table to make staistics
	&Log::db_stat_log({'robot' => $self->{'domain'}, 'list' => $self->{'name'}, 'operation' =>'add subscriber', 'parameter' => '', 'mail' => $new_user->{'email'},
		       'client' => '', 'daemon' => $daemon});
	
	## Update Subscriber Table
	unless(&SDM::do_query("INSERT INTO subscriber_table (user_subscriber, comment_subscriber, list_subscriber, robot_subscriber, date_subscriber, update_subscriber, reception_subscriber, topics_subscriber, visibility_subscriber,subscribed_subscriber,included_subscriber,include_sources_subscriber,custom_attribute_subscriber,suspend_subscriber,suspend_start_date_subscriber,suspend_end_date_subscriber) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)", 
	&SDM::quote($who), 
	&SDM::quote($new_user->{'gecos'}), 
	&SDM::quote($name), 
	&SDM::quote($self->{'domain'}),
	&SDM::get_canonical_write_date($new_user->{'date'}), 
	&SDM::get_canonical_write_date($new_user->{'update_date'}), 
	&SDM::quote($new_user->{'reception'}), 
	&SDM::quote($new_user->{'topics'}), 
	&SDM::quote($new_user->{'visibility'}), 
	$new_user->{'subscribed'}, 
	$new_user->{'included'}, 
	&SDM::quote($new_user->{'id'}),
	&SDM::quote($new_user->{'custom_attribute'}),
	&SDM::quote($new_user->{'suspend'}),
	&SDM::quote($new_user->{'startdate'}),
	&SDM::quote($new_user->{'enddate'}))){
	    &Log::do_log('err','Unable to add subscriber %s to table subscriber_table for list %s@%s %s', $who,$name,$self->{'domain'});
	    next;
	}
	$total++;
    }

    $self->{'total'} += $total;
    $self->savestats();

    return $total;
}


## Adds a new list admin user, no overwrite.
sub add_list_admin {
    my($self, $role, @new_admin_users) = @_;
    &Log::do_log('debug2', '');
    
    my $name = $self->{'name'};
    my $total = 0;
    
    foreach my $new_admin_user (@new_admin_users) {
	my $who = &tools::clean_email($new_admin_user->{'email'});
	
	next unless $who;
	
	$new_admin_user->{'date'} ||= time;
	$new_admin_user->{'update_date'} ||= $new_admin_user->{'date'};
	    
	$list_cache{'is_admin_user'}{$self->{'domain'}}{$name}{$who} = undef;
	    
	##  either is_included or is_subscribed must be set
	## default is is_subscriber for backward compatibility reason
	unless ($new_admin_user->{'included'}) {
	    $new_admin_user->{'subscribed'} = 1;
	}
	    
	unless ($new_admin_user->{'included'}) {
	    ## Is the email in user table?
	    if (! is_global_user($who)) {
		## Insert in User Table
		unless(&SDM::do_query("INSERT INTO user_table (email_user, gecos_user, lang_user, password_user) VALUES (%s,%s,%s,%s)",&SDM::quote($who), &SDM::quote($new_admin_user->{'gecos'}), &SDM::quote($new_admin_user->{'lang'}), &SDM::quote($new_admin_user->{'password'}))){
		    &Log::do_log('err','Unable to add admin %s to user_table', $who);
		    next;
		}
	    }
	}	    

	$new_admin_user->{'subscribed'} ||= 0;
 	$new_admin_user->{'included'} ||= 0;

	## Update Admin Table
	unless(&SDM::do_query("INSERT INTO admin_table (user_admin, comment_admin, list_admin, robot_admin, date_admin, update_admin, reception_admin, visibility_admin, subscribed_admin,included_admin,include_sources_admin, role_admin, info_admin, profile_admin) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)", 
	&SDM::quote($who), 
	&SDM::quote($new_admin_user->{'gecos'}), 
	&SDM::quote($name), 
	&SDM::quote($self->{'domain'}),
	&SDM::get_canonical_write_date($new_admin_user->{'date'}), 
	&SDM::get_canonical_write_date($new_admin_user->{'update_date'}), 
	&SDM::quote($new_admin_user->{'reception'}), 
	&SDM::quote($new_admin_user->{'visibility'}), 
	$new_admin_user->{'subscribed'}, 
	$new_admin_user->{'included'}, 
	&SDM::quote($new_admin_user->{'id'}), 
	&SDM::quote($role), 
	&SDM::quote($new_admin_user->{'info'}), 
	&SDM::quote($new_admin_user->{'profile'}))){
	    &Log::do_log('err','Unable to add admin %s to table admin_table for list %s@%s %s', $who,$name,$self->{'domain'});
	    next;
	}
	$total++;
    }

    return $total;
}

## Update subscribers and admin users (used while renaming a list)
sub rename_list_db {
    my($self, $new_listname, $new_robot) = @_;
    &Log::do_log('debug', 'List::rename_list_db(%s,%s,%s)', $self->{'name'},$new_listname, $new_robot);

    my $statement_subscriber;
    my $statement_admin;
    
    unless(&SDM::do_query("UPDATE subscriber_table SET list_subscriber=%s, robot_subscriber=%s WHERE (list_subscriber=%s AND robot_subscriber=%s)", 
    &SDM::quote($new_listname), 
    &SDM::quote($new_robot),
    &SDM::quote($self->{'name'}),
    &SDM::quote($self->{'domain'}))){
	&Log::do_log('err','Unable to rename list %s@%s to %s@%s in the database', $self->{'name'},$self->{'domain'},$new_listname,$new_robot);
	next;
    }
    
    &Log::do_log('debug', 'List::rename_list_db statement : %s',  $statement_subscriber );

    # admin_table is "alive" only in case include2
    unless(&SDM::do_query("UPDATE admin_table SET list_admin=%s, robot_admin=%s WHERE (list_admin=%s AND robot_admin=%s)", 
    &SDM::quote($new_listname), 
    &SDM::quote($new_robot),
    &SDM::quote($self->{'name'}),
    &SDM::quote($self->{'domain'}))){
	&Log::do_log('err','Unable to change admins in database while renaming list %s@%s to %s@%s', $self->{'name'},$self->{'domain'},$new_listname,$new_robot);
	next;
    }
    &Log::do_log('debug', 'List::rename_list_db statement : %s',  $statement_admin );
    
    return 1;
}


## Is the user listmaster
sub is_listmaster {
    my $who = shift;
    my $robot = shift;

    $who =~ y/A-Z/a-z/;

    return 0 unless ($who);

    foreach my $listmaster (@{&Conf::get_robot_conf($robot,'listmasters')}){
	return 1 if (lc($listmaster) eq lc($who));
    }
	
    foreach my $listmaster (@{&Conf::get_robot_conf('*','listmasters')}){
	return 1 if (lc($listmaster) eq lc($who));
    }    

    return 0;
}

## Does the user have a particular function in the list?
sub am_i {
    my($self, $function, $who, $options) = @_;
    &Log::do_log('debug2', 'List::am_i(%s, %s, %s)', $function, $self->{'name'}, $who);
    
    return undef unless ($self && $who);
    $function =~ y/A-Z/a-z/;
    $who =~ y/A-Z/a-z/;
    chomp($who);
    
    ## If 'strict' option is given, then listmaster does not inherit privileged
    unless (defined $options and $options->{'strict'}) {
	## Listmaster has all privileges except editor
	# sa contestable.
	if (($function eq 'owner' || $function eq 'privileged_owner') and &is_listmaster($who,$self->{'domain'})) {
	    $list_cache{'am_i'}{$function}{$self->{'domain'}}{$self->{'name'}}{$who} = 1;
	    return 1;
	}
    }
	
    ## Use cache
    if (defined $list_cache{'am_i'}{$function}{$self->{'domain'}}{$self->{'name'}}{$who} &&
	$function ne 'editor') { ## Defaults for editor may be owners) {
	# &Log::do_log('debug3', 'Use cache(%s,%s): %s', $name, $who, $list_cache{'is_list_member'}{$self->{'domain'}}{$name}{$who});
	return $list_cache{'am_i'}{$function}{$self->{'domain'}}{$self->{'name'}}{$who};
    }

    ##Check editors
    if ($function =~ /^editor$/i){
	
	## Check cache first
	if ($list_cache{'am_i'}{$function}{$self->{'domain'}}{$self->{'name'}}{$who} == 1) {
	    return 1;
	}
	
	my $editor = $self->get_list_admin('editor',$who);
	
	if (defined $editor) {
	    return 1;
	}else {
	    ## Check if any editor is defined ; if not owners are editors
	    my $editors = $self->get_editors();
	    if ($#{$editors} < 0) {
		
		# if no editor defined, owners has editor privilege
		$editor = $self->get_list_admin('owner',$who);
		if (defined $editor){
		    ## Update cache
		    $list_cache{'am_i'}{'editor'}{$self->{'domain'}}{$self->{'name'}}{$who} = 1;
		    
		    return 1;
		}
	    }else {
		
		## Update cache
		$list_cache{'am_i'}{'editor'}{$self->{'domain'}}{$self->{'name'}}{$who} = 0;
		
		return undef;
	    }
	}
    }
    ## Check owners
    if ($function =~ /^owner$/i){
	my $owner = $self->get_list_admin('owner',$who);
	if (defined $owner) {		    
	    ## Update cache
	    $list_cache{'am_i'}{'owner'}{$self->{'domain'}}{$self->{'name'}}{$who} = 1;
	    
	    return 1;
	}else {
	    
	    ## Update cache
	    $list_cache{'am_i'}{'owner'}{$self->{'domain'}}{$self->{'name'}}{$who} = 0;
	    
	    return undef;
	}
    }elsif ($function =~ /^privileged_owner$/i) {
	my $privileged = $self->get_list_admin('owner',$who);
	if ($privileged->{'profile'} eq 'privileged') {
	    
	    ## Update cache
	    $list_cache{'am_i'}{'privileged_owner'}{$self->{'domain'}}{$self->{'name'}}{$who} = 1;
	    
	    return 1;
	}else {
	    
	    ## Update cache
	    $list_cache{'am_i'}{'privileged_owner'}{$self->{'domain'}}{$self->{'name'}}{$who} = 0;
	    
	    return undef;
	}
    }
}

## Check list authorizations
## Higher level sub for request_action
sub check_list_authz {
    my $self = shift;
    my $operation = shift;
    my $auth_method = shift;
    my $context = shift;
    my $debug = shift;
    &Log::do_log('debug', 'List::check_list_authz %s,%s',$operation,$auth_method);

    $context->{'list_object'} = $self;

    return &Scenario::request_action($operation, $auth_method, $self->{'domain'}, $context, $debug);
}

## Initialize internal list cache
sub init_list_cache {
    &Log::do_log('debug2', 'List::init_list_cache()');
    
    undef %list_cache;
}

## May the indicated user edit the indicated list parameter or not?
sub may_edit {

    my($self,$parameter, $who) = @_;
    &Log::do_log('debug3', 'List::may_edit(%s, %s)', $parameter, $who);

    my $role;

    return undef unless ($self);

    my $edit_conf;

    # Load edit_list.conf: track by file, not domain (file may come from server, robot, family or list context)
    my $edit_conf_file = &tools::get_filename('etc',{},'edit_list.conf',$self->{'domain'},$self); 
    if (! $edit_list_conf{$edit_conf_file} || ((stat($edit_conf_file))[9] > $mtime{'edit_list_conf'}{$edit_conf_file})) {

        $edit_conf = $edit_list_conf{$edit_conf_file} = &tools::load_edit_list_conf($self->{'domain'}, $self);
	$mtime{'edit_list_conf'}{$edit_conf_file} = time;
    }else {
        $edit_conf = $edit_list_conf{$edit_conf_file};
    }

    ## What privilege?
    if (&is_listmaster($who,$self->{'domain'})) {
	$role = 'listmaster';
    }elsif ( $self->am_i('privileged_owner',$who) ) {
	$role = 'privileged_owner';
	
    }elsif ( $self->am_i('owner',$who) ) {
	$role = 'owner';
	
    }elsif ( $self->am_i('editor',$who) ) {
	$role = 'editor';
	
#    }elsif ( $self->am_i('subscriber',$who) ) {
#	$role = 'subscriber';
#	
    }else {
	return ('user','hidden');
    }

    ## What privilege does he/she has?
    my ($what, @order);

    if (($parameter =~ /^(\w+)\.(\w+)$/) &&
	($parameter !~ /\.tt2$/)) {
	my $main_parameter = $1;
	@order = ($edit_conf->{$parameter}{$role},
		  $edit_conf->{$main_parameter}{$role}, 
		  $edit_conf->{'default'}{$role}, 
		  $edit_conf->{'default'}{'default'})
    }else {
	@order = ($edit_conf->{$parameter}{$role}, 
		  $edit_conf->{'default'}{$role}, 
		  $edit_conf->{'default'}{'default'})
    }
    
    foreach $what (@order) {
	if (defined $what) {
	    return ($role,$what);
	}
    }
    
    return ('user','hidden');
}


## May the indicated user edit a paramter while creating a new list
## Dev note: This sub is never called. Shall we remove it?
sub may_create_parameter {

    my($self, $parameter, $who,$robot) = @_;
    &Log::do_log('debug3', 'List::may_create_parameter(%s, %s, %s)', $parameter, $who,$robot);

    if ( &is_listmaster($who,$robot)) {
	return 1;
    }
    my $edit_conf = &tools::load_edit_list_conf($robot,$self);
    $edit_conf->{$parameter} ||= $edit_conf->{'default'};
    if (! $edit_conf->{$parameter}) {
	do_log('notice','tools::load_edit_list_conf privilege for parameter $parameter undefined');
	return undef;
    }
    if ($edit_conf->{$parameter}  =~ /^(owner|privileged_owner)$/i ) {
	return 1;
    }else{
	return 0;
    }

}


## May the indicated user do something with the list or not?
## Action can be : send, review, index, get
##                 add, del, reconfirm, purge
sub may_do {
   my($self, $action, $who) = @_;
   &Log::do_log('debug3', 'List::may_do(%s, %s)', $action, $who);

   my $i;

   ## Just in case.
   return undef unless ($self && $action);
   my $admin = $self->{'admin'};
   return undef unless ($admin);

   $action =~ y/A-Z/a-z/;
   $who =~ y/A-Z/a-z/;

   if ($action =~ /^(index|get)$/io) {
       my $arc_access = $admin->{'archive'}{'access'};
       if ($arc_access =~ /^public$/io)  {
	   return 1;
       }elsif ($arc_access =~ /^private$/io) {
	   return 1 if ($self->is_list_member($who));
	   return $self->am_i('owner', $who);
       }elsif ($arc_access =~ /^owner$/io) {
	   return $self->am_i('owner', $who);
       }
       return undef;
   }

   if ($action =~ /^(review)$/io) {
       foreach $i (@{$admin->{'review'}}) {
	   if ($i =~ /^public$/io) {
	       return 1;
	   }elsif ($i =~ /^private$/io) {
	       return 1 if ($self->is_list_member($who));
	       return $self->am_i('owner', $who);
	   }elsif ($i =~ /^owner$/io) {
	       return $self->am_i('owner', $who);
	   }
	   return undef;
       }
   }

   if ($action =~ /^send$/io) {
      if ($admin->{'send'} =~/^(private|privateorpublickey|privateoreditorkey)$/i) {

         return undef unless ($self->is_list_member($who) || $self->am_i('owner', $who));
      }elsif ($admin->{'send'} =~ /^(editor|editorkey|privateoreditorkey)$/i) {
         return undef unless ($self->am_i('editor', $who));
      }elsif ($admin->{'send'} =~ /^(editorkeyonly|publickey|privatekey)$/io) {
         return undef;
      }
      return 1;
   }

   if ($action =~ /^(add|del|remind|reconfirm|purge)$/io) {
      return $self->am_i('owner', $who);
   }

   if ($action =~ /^(modindex)$/io) {
       return undef unless ($self->am_i('editor', $who));
       return 1;
   }

   if ($action =~ /^auth$/io) {
       if ($admin->{'send'} =~ /^(privatekey)$/io) {
	   return 1 if ($self->is_list_member($who) || $self->am_i('owner', $who));
       } elsif ($admin->{'send'} =~ /^(privateorpublickey)$/io) {
	   return 1 unless ($self->is_list_member($who) || $self->am_i('owner', $who));
       }elsif ($admin->{'send'} =~ /^(publickey)$/io) {
	   return 1;
       }
       return undef; #authent
   } 
   return undef;
}

## Does the list support digest mode
sub is_digest {
   return (shift->{'admin'}{'digest'});
}

## Does the file exist?
sub archive_exist {
   my($self, $file) = @_;
   &Log::do_log('debug', 'List::archive_exist (%s)', $file);

   return undef unless ($self->is_archived());
   my $dir = &Conf::get_robot_conf($self->{'domain'},'arc_path').'/'.$self->get_list_id();
   Archive::exist($dir, $file);

}


## List the archived files
sub archive_ls {
   my $self = shift;
   &Log::do_log('debug2', 'List::archive_ls');

   my $dir = &Conf::get_robot_conf($self->{'domain'},'arc_path').'/'.$self->get_list_id();

   Archive::list($dir) if ($self->is_archived());
}

## Archive 
sub archive_msg {
    my($self, $msg ) = @_;
    &Log::do_log('debug2', 'List::archive_msg for %s',$self->{'name'});

    my $is_archived = $self->is_archived();
    Archive::store_last($self, $msg) if ($is_archived);

    Archive::outgoing("$Conf::Conf{'queueoutgoing'}",$self->get_list_id(),$msg) 
      if ($self->is_web_archived());
}

sub archive_msg_digest {
   my($self, $msg) = @_;
   &Log::do_log('debug2', 'List::archive_msg_digest');

   $self->store_digest( $msg) if ($self->{'name'});
}

## Is the list moderated?                                                          
sub is_moderated {
    
    return 1 if (defined shift->{'admin'}{'editor'});
                                                          
    return 0;
}

## Is the list archived?
sub is_archived {
    &Log::do_log('debug', 'List::is_archived');    
    if (shift->{'admin'}{'web_archive'}{'access'}) {do_log('debug', 'List::is_archived : 1'); return 1 ;}  
    &Log::do_log('debug', 'List::is_archived : undef');
    return undef;
}

## Is the list web archived?
sub is_web_archived {
    return 1 if (shift->{'admin'}{'web_archive'}{'access'}) ;
    return undef;
   
}

## Returns 1 if the  digest  must be send 
sub get_nextdigest {
    my $self = shift;
    &Log::do_log('debug3', 'List::get_nextdigest (%s)');

    my $digest = $self->{'admin'}{'digest'};
    my $listname = $self->{'name'};

    ## Reverse compatibility concerns
    my $filename;
    foreach my $f ("$Conf::Conf{'queuedigest'}/$listname",
 		   $Conf::Conf{'queuedigest'}.'/'.$self->get_list_id()) {
 	$filename = $f if (-f $f);
    }
    
    return undef unless (defined $filename);

    unless ($digest) {
	return undef;
    }
    
    my @days = @{$digest->{'days'}};
    my ($hh, $mm) = ($digest->{'hour'}, $digest->{'minute'});
     
    my @now  = localtime(time);
    my $today = $now[6]; # current day
    my @timedigest = localtime( (stat $filename)[9]);

    ## Should we send a digest today
    my $send_digest = 0;
    foreach my $d (@days){
	if ($d == $today) {
	    $send_digest = 1;
	    last;
	}
    }

    return undef
	unless ($send_digest == 1);

    if (($now[2] * 60 + $now[1]) >= ($hh * 60 + $mm) and 
	(timelocal(0, $mm, $hh, $now[3], $now[4], $now[5]) > timelocal(0, $timedigest[1], $timedigest[2], $timedigest[3], $timedigest[4], $timedigest[5]))
        ){
	return 1;
    }

    return undef;
}

	
## Loads all scenari for an action
sub load_scenario_list {
    my ($self, $action,$robot) = @_;
    &Log::do_log('debug3', 'List::load_scenario_list(%s,%s)', $action,$robot);

    my $directory = "$self->{'dir'}";
    my %list_of_scenario;
    my %skip_scenario;

    foreach my $dir (
        "$directory/scenari",
        "$Conf::Conf{'etc'}/$robot/scenari",
        "$Conf::Conf{'etc'}/scenari",
        Sympa::Constants::DEFAULTDIR . '/scenari'
    ) {
	next unless (-d $dir);
	
	my $scenario_regexp = &tools::get_regexp('scenario');

	while (<$dir/$action.*:ignore>) {
	    if (/$action\.($scenario_regexp):ignore$/) {
		my $name = $1;
		$skip_scenario{$name} = 1;
	    }
	}

	while (<$dir/$action.*>) {
	    next unless (/$action\.($scenario_regexp)$/);
	    my $name = $1;
	    
	    next if (defined $list_of_scenario{$name});
	    next if (defined $skip_scenario{$name});

	    my $scenario = new Scenario ('robot' => $robot,
					 'directory' => $directory,
					 'function' => $action,
					 'name' => $name);
	    $list_of_scenario{$name} = $scenario;

	    ## Set the title in the current language
	    if (defined  $scenario->{'title'}{&Language::GetLang()}) {
		$list_of_scenario{$name}{'web_title'} = $scenario->{'title'}{&Language::GetLang()};
	    }elsif (defined $scenario->{'title'}{'gettext'}) {
		$list_of_scenario{$name}{'web_title'} = gettext($scenario->{'title'}{'gettext'});
	    }elsif (defined $scenario->{'title'}{'us'}) {
		$list_of_scenario{$name}{'web_title'} = gettext($scenario->{'title'}{'us'});
	    }else {
		$list_of_scenario{$name}{'web_title'} = $name;		     
	    }
	    $list_of_scenario{$name}{'name'} = $name;	    
	}
    }

    ## Return a copy of the data to prevent unwanted changes in the central scenario data structure
    return &tools::dup_var(\%list_of_scenario);
}

sub load_task_list {
    my ($self, $action,$robot) = @_;
    &Log::do_log('debug2', 'List::load_task_list(%s,%s)', $action,$robot);

    my $directory = "$self->{'dir'}";
    my %list_of_task;
    
    foreach my $dir (
        "$directory/list_task_models",
        "$Conf::Conf{'etc'}/$robot/list_task_models",
        "$Conf::Conf{'etc'}/list_task_models",
        Sympa::Constants::DEFAULTDIR . '/list_task_models'
    ) {

	next unless (-d $dir);

	foreach my $file (<$dir/$action.*>) {
	    next unless ($file =~ /$action\.(\w+)\.task$/);
	    my $name = $1;
	    
	    next if (defined $list_of_task{$name});
	    
	    $list_of_task{$name}{'name'} = $name;

	    my $titles = &List::_load_task_title ($file);

	    ## Set the title in the current language
	    if (defined  $titles->{&Language::GetLang()}) {
		$list_of_task{$name}{'title'} = $titles->{&Language::GetLang()};
	    }elsif (defined $titles->{'gettext'}) {
		$list_of_task{$name}{'title'} = gettext( $titles->{'gettext'});
	    }elsif (defined $titles->{'us'}) {
		$list_of_task{$name}{'title'} = gettext( $titles->{'us'});		
	    }else {
		$list_of_task{$name}{'title'} = $name;		     
	    }

	}
    }

    return \%list_of_task;
}

sub _load_task_title {
    my $file = shift;
    &Log::do_log('debug3', 'List::_load_task_title(%s)', $file);
    my $title = {};

    unless (open TASK, $file) {
	do_log('err', 'Unable to open file "%s"' , $file);
	return undef;
    }

    while (<TASK>) {
	last if /^\s*$/;

	if (/^title\.([\w-]+)\s+(.*)\s*$/) {
	    $title->{$1} = $2;
	}
    }

    close TASK;

    return $title;
}

## Loads all data sources
sub load_data_sources_list {
    my ($self, $robot) = @_;
    &Log::do_log('debug3', 'List::load_data_sources_list(%s,%s)', $self->{'name'},$robot);

    my $directory = "$self->{'dir'}";
    my %list_of_data_sources;

    foreach my $dir (
        "$directory/data_sources",
        "$Conf::Conf{'etc'}/$robot/data_sources",
        "$Conf::Conf{'etc'}/data_sources",
        Sympa::Constants::DEFAULTDIR . '/data_sources'
    ) {

	next unless (-d $dir);
	
	while  (my $f = <$dir/*.incl>) {
	    
	    next unless ($f =~ /([\w\-]+)\.incl$/);
	    
	    my $name = $1;
	    
	    next if (defined $list_of_data_sources{$name});
	    
	    $list_of_data_sources{$name}{'title'} = $name;
	    $list_of_data_sources{$name}{'name'} = $name;
	}
    }
    
    return \%list_of_data_sources;
}

## Loads the statistics information
sub _load_stats_file {
    my $file = shift;
    &Log::do_log('debug3', 'List::_load_stats_file(%s)', $file);

   ## Create the initial stats array.
   my ($stats, $total, $last_sync, $last_sync_admin_user);
 
   if (open(L, $file)){     
       if (<L> =~ /^(\d+)\s+(\d+)\s+(\d+)\s+(\d+)(\s+(\d+))?(\s+(\d+))?(\s+(\d+))?/) {
	   $stats = [ $1, $2, $3, $4];
	   $total = $6;
	   $last_sync = $8;
	   $last_sync_admin_user = $10;
	   
       } else {
	   $stats = [ 0, 0, 0, 0];
	   $total = 0;
	   $last_sync = 0;
	   $last_sync_admin_user = 0;
       }
       close(L);
   } else {
       $stats = [ 0, 0, 0, 0];
       $total = 0;
       $last_sync = 0;
       $last_sync_admin_user = 0;
   }

   ## Return the array.
   return ($stats, $total, $last_sync, $last_sync_admin_user);
}

## Loads the list of subscribers.
sub _load_list_members_file {
    my $file = shift;
    &Log::do_log('debug2', '(%s)', $file);
    
    ## Open the file and switch to paragraph mode.
    open(L, $file) || return undef;
    
    ## Process the lines
    local $/;
    my $data = <L>;

    my @users;
    foreach (split /\n\n/, $data) {
	my(%user, $email);
	$user{'email'} = $email = $1 if (/^\s*email\s+(.+)\s*$/om);
	$user{'gecos'} = $1 if (/^\s*gecos\s+(.+)\s*$/om);
	$user{'date'} = $1 if (/^\s*date\s+(\d+)\s*$/om);
	$user{'update_date'} = $1 if (/^\s*update_date\s+(\d+)\s*$/om);
	$user{'reception'} = $1 if (/^\s*reception\s+(digest|nomail|summary|notice|txt|html|urlize|not_me)\s*$/om);
	$user{'visibility'} = $1 if (/^\s*visibility\s+(conceal|noconceal)\s*$/om);

	push @users, \%user;
    }
    close(L);
    
    return @users;
}

## include a remote sympa list as subscribers.
sub _include_users_remote_sympa_list {
    my ($self, $users, $param, $dir, $robot, $default_user_options , $tied) = @_;

    my $host = $param->{'host'};
    my $port = $param->{'port'} || '443';
    my $path = $param->{'path'};
    my $cert = $param->{'cert'} || 'list';

    my $id = Datasource::_get_datasource_id($param);

    &Log::do_log('debug', 'List::_include_users_remote_sympa_list(%s) https://%s:%s/%s using cert %s,', $self->{'name'}, $host, $port, $path, $cert);
    
    my $total = 0; 
    my $get_total = 0;

    my $cert_file ; my $key_file ;

    $cert_file = $dir.'/cert.pem';
    $key_file = $dir.'/private_key';
    if ($cert eq 'list') {
	$cert_file = $dir.'/cert.pem';
	$key_file = $dir.'/private_key';
    }elsif($cert eq 'robot') {
	$cert_file = &tools::get_filename('etc',{},'cert.pem',$robot,$self);
	$key_file =  &tools::get_filename('etc',{},'private_key',$robot,$self);
    }
    unless ((-r $cert_file) && ( -r $key_file)) {
	do_log('err', 'Include remote list https://%s:%s/%s using cert %s, unable to open %s or %s', $host, $port, $path, $cert,$cert_file,$key_file);
	return undef;
    }
    
    my $getting_headers = 1;

    my %user ;
    my $email ;


    foreach my $line ( &Fetch::get_https($host,$port,$path,$cert_file,$key_file,{'key_passwd' => $Conf::Conf{'key_passwd'},
                                                                               'cafile'    => $Conf::Conf{'cafile'},
                                                                               'capath' => $Conf::Conf{'capath'}})
		){	
	chomp $line;

	if ($getting_headers) { # ignore http headers
	    next unless ($line =~ /^(date|update_date|email|reception|visibility)/);
	}
	undef $getting_headers;

	if ($line =~ /^\s*email\s+(.+)\s*$/o) {
	    $user{'email'} = $email = $1;
	    &Log::do_log('debug',"email found $email");
	    $get_total++;
	}
	$user{'gecos'} = $1 if ($line =~ /^\s*gecos\s+(.+)\s*$/o);
        
  	next unless ($line =~ /^$/) ;
	
	unless ($user{'email'}) {
	    &Log::do_log('debug','ignoring block without email definition');
	    next;
	}
	my %u;
	## Check if user has already been included
	if ($users->{$email}) {
	    &Log::do_log('debug3',"ignore $email because already member");
	    if ($tied) {
		%u = split "\n",$users->{$email};
	    }else {
		%u = %{$users->{$email}};
	    }
	}else{
	    &Log::do_log('debug3',"add new subscriber $email");
	    %u = %{$default_user_options};
	    $total++;
	}	    
	$u{'email'} = $user{'email'};
	$u{'id'} = join (',', split(',', $u{'id'}), $id);
	$u{'gecos'} = $user{'gecos'};delete $user{'gecos'};
	
	$u{'visibility'} = $default_user_options->{'visibility'} if (defined $default_user_options->{'visibility'});
	$u{'reception'} = $default_user_options->{'reception'} if (defined $default_user_options->{'reception'});
	$u{'profile'} = $default_user_options->{'profile'} if (defined $default_user_options->{'profile'});
	$u{'info'} = $default_user_options->{'info'} if (defined $default_user_options->{'info'});
	
	if ($tied) {
	    $users->{$email} = join("\n", %u);
	}else{
	    $users->{$email} = \%u;
	}
	delete $user{$email};undef $email;

    }
    &Log::do_log('info','Include %d users from list (%d subscribers) https://%s:%s%s',$total,$get_total,$host,$port,$path);
    return $total ;    
}



## include a list as subscribers.
sub _include_users_list {
    my ($users, $includelistname, $robot, $default_user_options, $tied) = @_;
    &Log::do_log('debug2', 'List::_include_users_list');

    my $total = 0;
    
    my $includelist;
    
    ## The included list is local or in another local robot
    if ($includelistname =~ /\@/) {
	$includelist = new List ($includelistname);
    }else {
	$includelist = new List ($includelistname, $robot);
    }

    unless ($includelist) {
	do_log('info', 'Included list %s unknown' , $includelistname);
	return undef;
    }
    
    my $id = Datasource::_get_datasource_id($includelistname);

    for (my $user = $includelist->get_first_list_member(); $user; $user = $includelist->get_next_list_member()) {
	my %u;

	## Check if user has already been included
	if ($users->{$user->{'email'}}) {
	    if ($tied) {
		%u = split "\n",$users->{$user->{'email'}};
	    }else {
		%u = %{$users->{$user->{'email'}}};
	    }
	}else {
	    %u = %{$default_user_options};
	    $total++;
	}
	    
	my $email =  $u{'email'} = $user->{'email'};
	$u{'gecos'} = $user->{'gecos'};
	$u{'id'} = join (',', split(',', $u{'id'}), $id);

	$u{'visibility'} = $default_user_options->{'visibility'} if (defined $default_user_options->{'visibility'});
	$u{'reception'} = $default_user_options->{'reception'} if (defined $default_user_options->{'reception'});
	$u{'profile'} = $default_user_options->{'profile'} if (defined $default_user_options->{'profile'});
	$u{'info'} = $default_user_options->{'info'} if (defined $default_user_options->{'info'});

	if ($tied) {
	    $users->{$email} = join("\n", %u);
	}else {
	    $users->{$email} = \%u;
	}
    }
    &Log::do_log('info',"Include %d users from list %s",$total,$includelistname);
    return $total ;
}

## include a lists owners lists privileged_owners or lists_editors.
sub _include_users_admin {
    my ($users, $selection, $role, $default_user_options,$tied) = @_;
#   il faut préparer une liste de hash avec le nom de liste, le nom de robot, le répertoire de la liset pour appeler
#    load_admin_file décommanter le include_admin
    my $lists;
    
    unless ($role eq 'listmaster') {
	
	if ($selection =~ /^\*\@(\S+)$/) {
	    $lists = &get_lists($1);
	    my $robot = $1;
	}else{
	    $selection =~ /^(\S+)@(\S+)$/ ;
	    $lists->[0] = $1;
	}
	
	foreach my $list (@$lists) {
	    #my $admin = _load_list_config_file($dir, $domain, 'config');
	}
    }
}
    
sub _include_users_file {
    my ($users, $filename, $default_user_options,$tied) = @_;
    &Log::do_log('debug2', 'List::_include_users_file(%s)', $filename);

    my $total = 0;
    
    unless (open(INCLUDE, "$filename")) {
	do_log('err', 'Unable to open file "%s"' , $filename);
	return undef;
    }
    &Log::do_log('debug2','including file %s' , $filename);

    my $id = Datasource::_get_datasource_id($filename);
    my $lines = 0;
    my $emails_found = 0;
    my $email_regexp = &tools::get_regexp('email');
    
    while (<INCLUDE>) {
	if($lines > 49 && $emails_found == 0){
	    &Log::do_log('err','Too much errors in file %s (%s lines, %s emails found). Source file probably corrupted. Cancelling.',$filename, $lines, $emails_found);
	    return undef;
	}
	next if /^\s*$/;
	next if /^\s*\#/;

	unless (/^\s*($email_regexp)(\s*(\S.*))?\s*$/) {
	    &Log::do_log('err', 'Not an email address: %s', $_);
	}

	my $email = &tools::clean_email($1);
        $lines++;
	next unless $email;
	my $gecos = $5;
	$emails_found++;

	my %u;
	## Check if user has already been included
	if ($users->{$email}) {
	    if ($tied) {
		%u = split "\n",$users->{$email};
	    }else {
		%u = %{$users->{$email}};
	    }
	}else {
	    %u = %{$default_user_options};
	    $total++;
	}
	$u{'email'} = $email;
	$u{'gecos'} = $gecos;
	$u{'id'} = join (',', split(',', $u{'id'}), $id);

	$u{'visibility'} = $default_user_options->{'visibility'} if (defined $default_user_options->{'visibility'});
	$u{'reception'} = $default_user_options->{'reception'} if (defined $default_user_options->{'reception'});
	$u{'profile'} = $default_user_options->{'profile'} if (defined $default_user_options->{'profile'});
	$u{'info'} = $default_user_options->{'info'} if (defined $default_user_options->{'info'});

	if ($tied) {
	    $users->{$email} = join("\n", %u);
	}else {
	    $users->{$email} = \%u;
	}
    }
    close INCLUDE ;
    
    
    &Log::do_log('info',"include %d new users from file %s",$total,$filename);
    return $total ;
}
    
sub _include_users_remote_file {
    my ($users, $param, $default_user_options,$tied) = @_;

    my $url = $param->{'url'};
    
    &Log::do_log('debug', "List::_include_users_remote_file($url)");

    my $total = 0;
    my $id = Datasource::_get_datasource_id($param);

    ## WebAgent package is part of Fetch.pm and inherites from LWP::UserAgent

    my $fetch = WebAgent->new (agent => 'Sympa/'. Sympa::Constants::VERSION);

    my $req = HTTP::Request->new(GET => $url);
    
    if (defined $param->{'user'} && defined $param->{'passwd'}) {
	&WebAgent::set_basic_credentials($param->{'user'},$param->{'passwd'});
    }

    my $res = $fetch->request($req);  

    # check the outcome
    if ($res->is_success) {
	my @remote_file = split(/\n/,$res->content);
	my $lines = 0;
	my $emails_found = 0;
	my $email_regexp = &tools::get_regexp('email');

	# forgot headers (all line before one that contain a email
	foreach my $line (@remote_file) {
	    if($lines > 49 && $emails_found == 0){
		&Log::do_log('err','Too much errors in file %s (%s lines, %s emails found). Source file probably corrupted. Cancelling.',$url, $lines, $emails_found);
		return undef;
	    }
	    next if ($line =~ /^\s*$/);
	    next if ($line =~ /^\s*\#/);

	    unless ( $line =~ /^\s*($email_regexp)(\s*(\S.*))?\s*$/) {
		&Log::do_log('err', 'Not an email address: %s', $_);
	    }     
	    my $email = &tools::clean_email($1);
	    $lines++;
	    next unless $email;
	    my $gecos = $5;		
	    $emails_found++;

	    my %u;
	    ## Check if user has already been included
	    if ($users->{$email}) {
		if ($tied) {
		    %u = split "\n",$users->{$email};
		}else{
		    %u = %{$users->{$email}};
		    foreach my $k (keys %u) {
		    }
		}
	    }else {
		%u = %{$default_user_options};
		$total++;
	    }
	    $u{'email'} = $email;
	    $u{'gecos'} = $gecos;
	    $u{'id'} = join (',', split(',', $u{'id'}), $id);
	    
	    $u{'visibility'} = $default_user_options->{'visibility'} if (defined $default_user_options->{'visibility'});
	    $u{'reception'} = $default_user_options->{'reception'} if (defined $default_user_options->{'reception'});
	    $u{'profile'} = $default_user_options->{'profile'} if (defined $default_user_options->{'profile'});
	    $u{'info'} = $default_user_options->{'info'} if (defined $default_user_options->{'info'});
	    
	    if ($tied) {
		$users->{$email} = join("\n", %u);
	    }else {
		$users->{$email} = \%u;
	    }
	}
    }
    else {
	do_log ('err',"List::include_users_remote_file: Unable to fetch remote file $url : %s", $res->message());
	return undef; 
    }

    ## Reset http credentials
    &WebAgent::set_basic_credentials('','');

    &Log::do_log('info',"include %d users from remote file %s",$total,$url);
    return $total ;
}


## Returns a list of subscribers extracted from a remote LDAP Directory
sub _include_users_ldap {
    my ($users, $param, $default_user_options, $tied) = @_;
    &Log::do_log('debug2', 'List::_include_users_ldap');
    
    my $id = Datasource::_get_datasource_id($param);

    my $user = $param->{'user'};
    my $passwd = $param->{'passwd'};
    my $ldap_suffix = $param->{'suffix'};
    my $ldap_filter = $param->{'filter'};
    my $ldap_attrs = $param->{'attrs'};
    my $ldap_select = $param->{'select'};
    
    ## LDAP and query handler
    my ($ldaph, $fetch);

    ## Connection timeout (default is 120)
    #my $timeout = 30; 
    
    my $param2 = &tools::dup_var($param);
    my $ds = new LDAPSource($param2);

    unless (defined $ds && $ds->connect()) {
	&Log::do_log('err',"Unable to connect to the LDAP server '%s'", $param2->{'host'});
	    return undef;
	}
    &Log::do_log('debug2', 'Searching on server %s ; suffix %s ; filter %s ; attrs: %s', $param->{'host'}, $ldap_suffix, $ldap_filter, $ldap_attrs);
    $fetch = $ds->{'ldap_handler'}->search ( base => "$ldap_suffix",
			      filter => "$ldap_filter",
			      attrs => [ "$ldap_attrs" ],
			      scope => "$param->{'scope'}");
    if ($fetch->code()) {
	do_log('err','Ldap search (single level) failed : %s (searching on server %s ; suffix %s ; filter %s ; attrs: %s)', 
	       $fetch->error(), $param->{'host'}, $ldap_suffix, $ldap_filter, $ldap_attrs);
        return undef;
    }
    
    ## Counters.
    my $total = 0;
    my $dn; 
    my @emails;
    my %emailsViewed;

    while (my $e = $fetch->shift_entry) {

	my $entry = $e->get_value($ldap_attrs, asref => 1);
	
	## Multiple values
	if (ref($entry) eq 'ARRAY') {
	    foreach my $email (@{$entry}) {
		my $cleanmail = &tools::clean_email($email);
		next if ($emailsViewed{$cleanmail});
		push @emails, $cleanmail;
		$emailsViewed{$cleanmail} = 1;
		last if ($ldap_select eq 'first');
	    }
	}else {
	    my $cleanmail = &tools::clean_email($entry);
	    unless ($emailsViewed{$cleanmail}) {
		push @emails, $cleanmail;
		$emailsViewed{$cleanmail} = 1;
	    }
	}
    }
    
    unless ($ds->disconnect()) {
	do_log('notice','Can\'t unbind from  LDAP server %s', $param->{'host'});
	return undef;
    }
    
    foreach my $email (@emails) {
	next if ($email =~ /^\s*$/);

	$email = &tools::clean_email($email);
	my %u;
	## Check if user has already been included
	if ($users->{$email}) {
	    if ($tied) {
		%u = split "\n",$users->{$email};
	    }else {
		%u = %{$users->{$email}};
	    }
	}else {
	    %u = %{$default_user_options};
	    $total++;
	}

	$u{'email'} = $email;
	$u{'date'} = time;
	$u{'update_date'} = time;
	$u{'id'} = join (',', split(',', $u{'id'}), $id);

	$u{'visibility'} = $default_user_options->{'visibility'} if (defined $default_user_options->{'visibility'});
	$u{'reception'} = $default_user_options->{'reception'} if (defined $default_user_options->{'reception'});
	$u{'profile'} = $default_user_options->{'profile'} if (defined $default_user_options->{'profile'});
	$u{'info'} = $default_user_options->{'info'} if (defined $default_user_options->{'info'});

	if ($tied) {
	    $users->{$email} = join("\n", %u);
	}else {
	    $users->{$email} = \%u;
	}
    }

    &Log::do_log('debug2',"unbinded from LDAP server %s ", $param->{'host'});
    &Log::do_log('info','%d new users included from LDAP query',$total);

    return $total;
}

## Returns a list of subscribers extracted indirectly from a remote LDAP
## Directory using a two-level query
sub _include_users_ldap_2level {
    my ($users, $param, $default_user_options,$tied) = @_;
    &Log::do_log('debug2', 'List::_include_users_ldap_2level');
    
    unless (eval "require Net::LDAP") {
	do_log('err',"Unable to use LDAP library, install perl-ldap (CPAN) first");
	return undef;
    }
    require Net::LDAP;

    my $id = Datasource::_get_datasource_id($param);

    my $user = $param->{'user'};
    my $passwd = $param->{'passwd'};
    my $ldap_suffix1 = $param->{'suffix1'};
    my $ldap_filter1 = $param->{'filter1'};
    my $ldap_attrs1 = $param->{'attrs1'};
    my $ldap_select1 = $param->{'select1'};
    my $ldap_scope1 = $param->{'scope1'};
    my $ldap_regex1 = $param->{'regex1'};
    my $ldap_suffix2 = $param->{'suffix2'};
    my $ldap_filter2 = $param->{'filter2'};
    my $ldap_attrs2 = $param->{'attrs2'};
    my $ldap_select2 = $param->{'select2'};
    my $ldap_scope2 = $param->{'scope2'};
    my $ldap_regex2 = $param->{'regex2'};
    my @sync_errors = ();
    
    ## LDAP and query handler
    my ($ldaph, $fetch);

    my $param2 = &tools::dup_var($param);
    my $ds = new LDAPSource($param2);
    
    unless (defined $ds && ($ldaph = $ds->connect())) {
	&Log::do_log('err',"Unable to connect to the LDAP server '%s'", $param2->{'host'});
	    return undef;
	}
    
    &Log::do_log('debug2', 'Searching on server %s ; suffix %s ; filter %s ; attrs: %s', $param->{'host'}, $ldap_suffix1, $ldap_filter1, $ldap_attrs1) ;
    $fetch = $ldaph->search ( base => "$ldap_suffix1",
			      filter => "$ldap_filter1",
			      attrs => [ "$ldap_attrs1" ],
			      scope => "$ldap_scope1");
    if ($fetch->code()) {
	do_log('err','LDAP search (1st level) failed : %s (searching on server %s ; suffix %s ; filter %s ; attrs: %s)', 
	       $fetch->error(), $param2->{'host'}, $ldap_suffix1, $ldap_filter1, $ldap_attrs1);
        return undef;
    }
    
    ## Counters.
    my $total = 0;
    my $dn; 
   
    ## returns a reference to a HASH where the keys are the DNs
    ##  the second level hash's hold the attributes

    my (@attrs, @emails);
 
    while (my $e = $fetch->shift_entry) {
	my $entry = $e->get_value($ldap_attrs1, asref => 1);
	## Multiple values
	if (ref($entry) eq 'ARRAY') {
	    foreach my $attr (@{$entry}) {
		next if (($ldap_select1 eq 'regex') && ($attr !~ /$ldap_regex1/));
		push @attrs, $attr;
		last if ($ldap_select1 eq 'first');
	    }
	}else {
	    push @attrs, $entry
		unless (($ldap_select1 eq 'regex') && ($entry !~ /$ldap_regex1/));
	}
    }

    my %emailsViewed;

    my ($suffix2, $filter2);
    foreach my $attr (@attrs) {
	($suffix2 = $ldap_suffix2) =~ s/\[attrs1\]/$attr/g;
	($filter2 = $ldap_filter2) =~ s/\[attrs1\]/$attr/g;

	do_log('debug2', 'Searching on server %s ; suffix %s ; filter %s ; attrs: %s', $param->{'host'}, $suffix2, $filter2, $ldap_attrs2);
	$fetch = $ldaph->search ( base => "$suffix2",
				  filter => "$filter2",
				  attrs => [ "$ldap_attrs2" ],
				  scope => "$ldap_scope2");
	if ($fetch->code()) {
	    &Log::do_log('err','LDAP search (2nd level) failed : %s. Node: %s (searching on server %s ; suffix %s ; filter %s ; attrs: %s)', 
		   $fetch->error(), $attr, $param->{'host'}, $suffix2, $filter2, $ldap_attrs2);
	    push @sync_errors, {'error',$fetch->error(), 'host', $param->{'host'}, 'suffix2', $suffix2, 'fliter2', $filter2,'ldap_attrs2', $ldap_attrs2};
	}

	## returns a reference to a HASH where the keys are the DNs
	##  the second level hash's hold the attributes
	
	while (my $e = $fetch->shift_entry) {
	    my $entry = $e->get_value($ldap_attrs2, asref => 1);

	    ## Multiple values
	    if (ref($entry) eq 'ARRAY') {
		foreach my $email (@{$entry}) {
		    my $cleanmail = &tools::clean_email($email);
		    next if (($ldap_select2 eq 'regex') && ($cleanmail !~ /$ldap_regex2/));
		    next if ($emailsViewed{$cleanmail});
		    push @emails, $cleanmail;
		    $emailsViewed{$cleanmail} = 1;
		    last if ($ldap_select2 eq 'first');
		}
	    }else {
		my $cleanmail = &tools::clean_email($entry);
		unless( (($ldap_select2 eq 'regex') && ($cleanmail !~ /$ldap_regex2/))||$emailsViewed{$cleanmail}) {
		    push @emails, $cleanmail;
		    $emailsViewed{$cleanmail} = 1;
		}
	    }
	}
    }
    
    unless ($ds->disconnect()) {
	do_log('err','Can\'t unbind from  LDAP server %s', $param->{'host'});
	return undef;
    }
    
    foreach my $email (@emails) {
	next if ($email =~ /^\s*$/);

	$email = &tools::clean_email($email);
	my %u;
	## Check if user has already been included
	if ($users->{$email}) {
	    if ($tied) {
		%u = split "\n",$users->{$email};
	    }else {
		%u = %{$users->{$email}};
	    }
	}else {
	    %u = %{$default_user_options};
	    $total++;
	}

	$u{'email'} = $email;
	$u{'date'} = time;
	$u{'update_date'} = time;
	$u{'id'} = join (',', split(',', $u{'id'}), $id);

	$u{'visibility'} = $default_user_options->{'visibility'} if (defined $default_user_options->{'visibility'});
	$u{'reception'} = $default_user_options->{'reception'} if (defined $default_user_options->{'reception'});
	$u{'profile'} = $default_user_options->{'profile'} if (defined $default_user_options->{'profile'});
	$u{'info'} = $default_user_options->{'info'} if (defined $default_user_options->{'info'});

	if ($tied) {
	    $users->{$email} = join("\n", %u);
	}else {
	    $users->{$email} = \%u;
	}
    }

    &Log::do_log('debug2',"unbinded from LDAP server %s ", $param->{'host'}) ;
    &Log::do_log('info','%d new users included from LDAP query',$total);

    my $result;
    $result->{'total'} = $total;
    if ($#sync_errors > -1) {$result->{'errors'} = \@sync_errors;}
    return $result;
}

## Returns a list of subscribers extracted from an remote Database
sub _include_users_sql {
    my ($users, $param, $default_user_options, $tied, $fetch_timeout) = @_;

    &Log::do_log('debug','List::_include_users_sql()');
    my $id = Datasource::_get_datasource_id($param);
    my $ds = new SQLSource($param);
    unless ($ds->connect && ($ds->do_query($param->{'sql_query'}))) {
	&Log::do_log('err','Unable to connect to SQL datasource with parameters host: %s, database: %s',$param->{'host'},$param->{'db_name'});
        return undef;
    }
    ## Counters.
    my $total = 0;
    
    ## Process the SQL results
    $ds->set_fetch_timeout($fetch_timeout);
    my $array_of_users = $ds->fetch;
	
    unless (defined $array_of_users && ref($array_of_users) eq 'ARRAY') {
	&Log::do_log('err', 'Failed to include users from %s',$param->{'name'});
	return undef;
    }

    foreach my $row (@{$array_of_users}) {
	my $email = $row->[0]; ## only get first field
	## Empty value
	next if ($email =~ /^\s*$/);

	$email = &tools::clean_email($email);
	my %u;
	## Check if user has already been included
	if ($users->{$email}) {
	    if ($tied eq 'tied') {
		%u = split "\n",$users->{$email};
	    }else {
		%u = %{$users->{$email}};
	    }
	}else {
	    %u = %{$default_user_options};
	    $total++;
	}

	$u{'email'} = $email;
	$u{'date'} = time;
	$u{'update_date'} = time;
	$u{'id'} = join (',', split(',', $u{'id'}), $id);

	$u{'visibility'} = $default_user_options->{'visibility'} if (defined $default_user_options->{'visibility'});
	$u{'reception'} = $default_user_options->{'reception'} if (defined $default_user_options->{'reception'});
	$u{'profile'} = $default_user_options->{'profile'} if (defined $default_user_options->{'profile'});
	$u{'info'} = $default_user_options->{'info'} if (defined $default_user_options->{'info'});

	if ($tied eq 'tied') {
	    $users->{$email} = join("\n", %u);
	}else {
	    $users->{$email} = \%u;
	}
    }
    $ds->disconnect();
    
    &Log::do_log('info','%d included users from SQL query', $total);
    return $total;
}

## Loads the list of subscribers from an external include source
sub _load_list_members_from_include {
    my $self = shift;
    my $name = $self->{'name'}; 
    my $admin = $self->{'admin'};
    my $dir = $self->{'dir'};
    &Log::do_log('debug2', 'List::_load_users_include for list %s',$name);
    my (%users, $depend_on, $ref);
    my $total = 0;
    my @errors;
    my $result;

    foreach my $type ('include_list','include_remote_sympa_list','include_file','include_ldap_query','include_ldap_2level_query','include_sql_query','include_remote_file') {
	last unless (defined $total);
	    
	foreach my $tmp_incl (@{$admin->{$type}}) {
	    my $included;
	    ## Work with a copy of admin hash branch to avoid including temporary variables into the actual admin hash.[bug #3182]
	    my $incl = &tools::dup_var($tmp_incl);

	    ## get the list of users
	    if ($type eq 'include_sql_query') {
		$included = _include_users_sql(\%users, $incl, $admin->{'default_user_options'}, 'untied', $admin->{'sql_fetch_timeout'});
		unless (defined $included){
		    push @errors, {'type' => $type, 'name' => $incl->{'name'}};
		}
	    }elsif ($type eq 'include_ldap_query') {
		$included = _include_users_ldap(\%users, $incl, $admin->{'default_user_options'});
		unless (defined $included){
		    push @errors, {'type' => $type, 'name' => $incl->{'name'}};
		}
	    }elsif ($type eq 'include_ldap_2level_query') {
		my $result = _include_users_ldap_2level(\%users, $incl, $admin->{'default_user_options'});
		if (defined $result) {
		    $included = $result->{'total'};
		    if (defined $result->{'errors'}){
			&Log::do_log('err', 'Errors occurred during the second LDAP passe');
			push @errors, {'type' => $type, 'name' => $incl->{'name'}};
		    }
		}else{
		    $included = undef;
		    push @errors, {'type' => $type, 'name' => $incl->{'name'}};
		}
	    }elsif ($type eq 'include_remote_sympa_list') {
		$included = $self->_include_users_remote_sympa_list(\%users, $incl, $dir,$admin->{'domain'},$admin->{'default_user_options'});
		unless (defined $included){
		    push @errors, {'type' => $type, 'name' => $incl->{'name'}};
		}
	    }elsif ($type eq 'include_list') {
		$depend_on->{$name} = 1 ;
		if (&_inclusion_loop ($name,$incl,$depend_on)) {
		    &Log::do_log('err','loop detection in list inclusion : could not include again %s in %s',$incl,$name);
		}else{
		    $depend_on->{$incl} = 1;
		    $included = _include_users_list (\%users, $incl, $self->{'domain'}, $admin->{'default_user_options'});
		    unless (defined $included){
			push @errors, {'type' => $type, 'name' => $incl};
		    }
		}
	    }elsif ($type eq 'include_file') {
		$included = _include_users_file (\%users, $incl, $admin->{'default_user_options'});
		unless (defined $included){
		    push @errors, {'type' => $type, 'name' => $incl};
		}
	    }elsif ($type eq 'include_remote_file') {
		$included = _include_users_remote_file (\%users, $incl, $admin->{'default_user_options'});
		unless (defined $included){
		    push @errors, {'type' => $type, 'name' => $incl->{'name'}};
		}
	    }
	    unless (defined $included) {
		&Log::do_log('err', 'Inclusion %s failed in list %s', $type, $name);
		next;
	    }
	    $total += $included;
	}
    }

    ## If an error occured, return an undef value
    $result->{'users'} = \%users;
    $result->{'errors'} = \@errors;
    return $result;
}

## Loads the list of admin users from an external include source
sub _load_list_admin_from_include {
    my $self = shift;
    my $role = shift;
    my $name = $self->{'name'};
   
    &Log::do_log('debug2', '(%s) for list %s',$role, $name); 

    my (%admin_users, $depend_on, $ref);
    my $total = 0;
    my $list_admin = $self->{'admin'};
    my $dir = $self->{'dir'};

    foreach my $entry (@{$list_admin->{$role."_include"}}) {
    
	next unless (defined $entry); 

	my %option;
	$option{'reception'} = $entry->{'reception'} if (defined $entry->{'reception'});
	$option{'visibility'} = $entry->{'visibility'} if (defined $entry->{'visibility'});
	$option{'profile'} = $entry->{'profile'} if (defined $entry->{'profile'} && ($role eq 'owner'));
	

      	my $include_file = &tools::get_filename('etc',{},"data_sources/$entry->{'source'}\.incl",$self->{'domain'},$self);

        unless (defined $include_file){
	    &Log::do_log('err', 'the file %s.incl doesn\'t exist',$entry->{'source'});
	    return undef;
	}

	my $include_admin_user;
	## the file has parameters
	if (defined $entry->{'source_parameters'}) {
	    my %parsing;
	    
	    $parsing{'data'} = $entry->{'source_parameters'};
	    $parsing{'template'} = "$entry->{'source'}\.incl";
	    
	    my $name = "$entry->{'source'}\.incl";
	    
	    my $include_path = $include_file;
	    if ($include_path =~ s/$name$//) {
		$parsing{'include_path'} = $include_path;
		$include_admin_user = &_load_include_admin_user_file($self->{'domain'},$include_path,\%parsing);	
	    } else {
		&Log::do_log('err', 'errors to get path of the the file %s.incl',$entry->{'source'});
		return undef;
	    }
	    
	    
	} else {
	    $include_admin_user = &_load_include_admin_user_file($self->{'domain'},$include_file);
	}
	foreach my $type ('include_list','include_remote_sympa_list','include_file','include_ldap_query','include_ldap_2level_query','include_sql_query','include_remote_file') {
	    last unless (defined $total);
	    
	    foreach my $tmp_incl (@{$include_admin_user->{$type}}) {
		my $included;
		
		## Work with a copy of admin hash branch to avoid including temporary variables into the actual admin hash.[bug #3182]
		my $incl = &tools::dup_var($tmp_incl);

		## get the list of admin users
		## does it need to define a 'default_admin_user_option'?
		if ($type eq 'include_sql_query') {
		    $included = _include_users_sql(\%admin_users, $incl,\%option, 'untied', $list_admin->{'sql_fetch_timeout'}); 
		}elsif ($type eq 'include_ldap_query') {
		    $included = _include_users_ldap(\%admin_users, $incl,\%option); 
		}elsif ($type eq 'include_ldap_2level_query') {
		    my $result = _include_users_ldap_2level(\%admin_users, $incl,\%option); 
		    if (defined $result) {
			$included = $result->{'total'};
			if (defined $result->{'errors'}){
			    &Log::do_log('err', 'Errors occurred during the second LDAP passe. Please verify your LDAP query.');
			}
		    }else{
			$included = undef;
		    }
		}elsif ($type eq 'include_remote_sympa_list') {
		    $included = $self->_include_users_remote_sympa_list(\%admin_users, $incl, $dir,$list_admin->{'domain'},\%option);
		}elsif ($type eq 'include_list') {
		    $depend_on->{$name} = 1 ;
		    if (&_inclusion_loop ($name,$incl,$depend_on)) {
			do_log('err','loop detection in list inclusion : could not include again %s in %s',$incl,$name);
		    }else{
			$depend_on->{$incl} = 1;
			$included = _include_users_list (\%admin_users, $incl, $self->{'domain'}, \%option);
		    }
		}elsif ($type eq 'include_file') {
		    $included = _include_users_file (\%admin_users, $incl, \%option);
		}elsif ($type eq 'include_remote_file') {
		    $included = _include_users_remote_file (\%admin_users, $incl, \%option);
		}
		unless (defined $included) {
		    &Log::do_log('err', 'Inclusion %s %s failed in list %s', $role, $type, $name);
		    next;
		}
		$total += $included;
	    }
	}

	## If an error occured, return an undef value
	unless (defined $total) {
	    return undef;
	}
    }
   
    return \%admin_users;
}


# Load an include admin user file (xx.incl)
sub _load_include_admin_user_file {
    my ($robot, $file, $parsing) = @_;
    &Log::do_log('debug2', 'List::_load_include_admin_user_file(%s,%s)',$robot, $file); 
    
    my %include;
    my (@paragraphs);
    
    # the file has parmeters
    if (defined $parsing) {
	my @data = split(',',$parsing->{'data'});
        my $vars = {'param' => \@data};
	my $output = '';
	
	unless (&tt2::parse_tt2($vars,$parsing->{'template'},\$output,[$parsing->{'include_path'}])) {
	    &Log::do_log('err', 'Failed to parse %s', $parsing->{'template'});
	    return undef;
	}
	
	my @lines = split('\n',$output);
	
	my $i = 0;
	foreach my $line (@lines) {
	    if ($line =~ /^\s*$/) {
		$i++ if $paragraphs[$i];
	    }else {
		push @{$paragraphs[$i]}, $line;
	    }
	}
    } else {
	unless (open INCLUDE, $file) {
	    &Log::do_log('info', 'Cannot open %s', $file);
	}
	
	## Just in case...
	local $/ = "\n";
	
	## Split in paragraphs
	my $i = 0;
	while (<INCLUDE>) {
	    if (/^\s*$/) {
		$i++ if $paragraphs[$i];
	    }else {
		push @{$paragraphs[$i]}, $_;
	    }
	}
	close INCLUDE;
    }
    
    for my $index (0..$#paragraphs) {
	my @paragraph = @{$paragraphs[$index]};
	
	my $pname;
	
	## Clean paragraph, keep comments
	for my $i (0..$#paragraph) {
	    my $changed = undef;
	    for my $j (0..$#paragraph) {
		if ($paragraph[$j] =~ /^\s*\#/) {
		    chomp($paragraph[$j]);
		    push @{$include{'comment'}}, $paragraph[$j];
		    splice @paragraph, $j, 1;
		    $changed = 1;
		}elsif ($paragraph[$j] =~ /^\s*$/) {
		    splice @paragraph, $j, 1;
		    $changed = 1;
		}
		
		last if $changed;
	    }
	    
	    last unless $changed;
	}
	
	## Empty paragraph
	next unless ($#paragraph > -1);
	
	## Look for first valid line
	unless ($paragraph[0] =~ /^\s*([\w-]+)(\s+.*)?$/) {
	    &Log::do_log('info', 'Bad paragraph "%s" in %s', @paragraph, $file);
	    next;
	}
	
	$pname = $1;   
	
	unless(($pname eq 'include_list')||($pname eq 'include_remote_sympa_list')||($pname eq 'include_file')||($pname eq 'include_remote_file')||
	       ($pname eq 'include_ldap_query')||($pname eq 'include_ldap_2level_query')||($pname eq 'include_sql_query'))   {
	    &Log::do_log('info', 'Unknown parameter "%s" in %s', $pname, $file);
	    next;
	}
	
	## Uniqueness
	if (defined $include{$pname}) {
	    unless (($::pinfo{$pname}{'occurrence'} eq '0-n') or
		    ($::pinfo{$pname}{'occurrence'} eq '1-n')) {
		&Log::do_log('info', 'Multiple parameter "%s" in %s', $pname, $file);
	    }
	}
	
	## Line or Paragraph
	if (ref $::pinfo{$pname}{'file_format'} eq 'HASH') {
	    ## This should be a paragraph
	    unless ($#paragraph > 0) {
		&Log::do_log('info', 'Expecting a paragraph for "%s" parameter in %s, ignore it', $pname, $file);
		next;
	    }
	    
	    ## Skipping first line
	    shift @paragraph;
	    
	    my %hash;
	    for my $i (0..$#paragraph) {	    
		next if ($paragraph[$i] =~ /^\s*\#/);
		
		unless ($paragraph[$i] =~ /^\s*(\w+)\s*/) {
		    &Log::do_log('info', 'Bad line "%s" in %s',$paragraph[$i], $file);
		}
		
		my $key = $1;
		
		unless (defined $::pinfo{$pname}{'file_format'}{$key}) {
		    &Log::do_log('info', 'Unknown key "%s" in paragraph "%s" in %s', $key, $pname, $file);
		    next;
		}
		
		unless ($paragraph[$i] =~ /^\s*$key\s+($::pinfo{$pname}{'file_format'}{$key}{'file_format'})\s*$/i) {
		    &Log::do_log('info', 'Bad entry "%s" in paragraph "%s" in %s', $paragraph[$i], $key, $pname, $file);
		    next;
		}
	       
		$hash{$key} = &_load_list_param($robot,$key, $1, $::pinfo{$pname}{'file_format'}{$key});
	    }

	    ## Apply defaults & Check required keys
	    my $missing_required_field;
	    foreach my $k (keys %{$::pinfo{$pname}{'file_format'}}) {

		## Default value
		unless (defined $hash{$k}) {
		    if (defined $::pinfo{$pname}{'file_format'}{$k}{'default'}) {
			$hash{$k} = &_load_list_param($robot,$k, 'default', $::pinfo{$pname}{'file_format'}{$k});
		    }
		}
		## Required fields
		if ($::pinfo{$pname}{'file_format'}{$k}{'occurrence'} eq '1') {
		    unless (defined $hash{$k}) {
			&Log::do_log('info', 'Missing key "%s" in param "%s" in %s', $k, $pname, $file);
			$missing_required_field++;
		    }
		}
	    }

	    next if $missing_required_field;

	    ## Should we store it in an array
	    if (($::pinfo{$pname}{'occurrence'} =~ /n$/)) {
		push @{$include{$pname}}, \%hash;
	    }else {
		$include{$pname} = \%hash;
	    }
	}else {
	    ## This should be a single line
	    unless ($#paragraph == 0) {
		&Log::do_log('info', 'Expecting a single line for "%s" parameter in %s', $pname, $file);
	    }

	    unless ($paragraph[0] =~ /^\s*$pname\s+($::pinfo{$pname}{'file_format'})\s*$/i) {
		&Log::do_log('info', 'Bad entry "%s" in %s', $paragraph[0], $file);
		next;
	    }

	    my $value = &_load_list_param($robot,$pname, $1, $::pinfo{$pname});

	    if (($::pinfo{$pname}{'occurrence'} =~ /n$/)
		&& ! (ref ($value) =~ /^ARRAY/)) {
		push @{$include{$pname}}, $value;
	    }else {
		$include{$pname} = $value;
	    }
	}
    }
    
    return \%include;
}

sub sync_include {
    my ($self) = shift;
    my $option = shift;
    my $name=$self->{'name'};
    &Log::do_log('debug', 'List:sync_include(%s)', $name);
    
    my %old_subscribers;
    my $total=0;
    my $errors_occurred=0;

    ## Load a hash with the old subscribers
    for (my $user=$self->get_first_list_member(); $user; $user=$self->get_next_list_member()) {
	$old_subscribers{lc($user->{'email'})} = $user;
	
	## User neither included nor subscribed = > set subscribed to 1 
	unless ($old_subscribers{lc($user->{'email'})}{'included'} || $old_subscribers{lc($user->{'email'})}{'subscribed'}) {
	    &Log::do_log('notice','Update user %s neither included nor subscribed', $user->{'email'});
	    unless( $self->update_list_member(lc($user->{'email'}),  {'update_date' => time,
							       'subscribed' => 1 }) ) {
		&Log::do_log('err', 'List:sync_include(%s): Failed to update %s', $name, lc($user->{'email'}));
		next;
	    }			    
	    $old_subscribers{lc($user->{'email'})}{'subscribed'} = 1;
	}

	$total++;
    }
    
    ## Load a hash with the new subscriber list
    my $new_subscribers;
    unless ($option eq 'purge') {
	my $result = $self->_load_list_members_from_include();
	$new_subscribers = $result->{'users'};
	my $tmp_errors = $result->{'errors'};
	my @errors = @$tmp_errors;
	## If include sources were not available, do not update subscribers
	## Use DB cache instead and warn the listmaster.
	if($#errors > -1) {
	    &Log::do_log('err', 'Errors occurred while synchronizing datasources for list %s', $name);
	    $errors_occurred = 1;
	    unless (&List::send_notify_to_listmaster('sync_include_failed', $self->{'domain'}, {'errors' => \@errors, 'listname' => $self->{'name'}})) {
		&Log::do_log('notice',"Unable to send notify 'sync_include_failed' to listmaster");
	    }
	    return undef;
	}
    }

    my $data_exclu;
    my @subscriber_exclusion;

    ## Récupérer un array d'emails pour une liste donnée in 'exclusion_table'
    $data_exclu = &get_exclusion($name);

    my $key =0;
    while ($data_exclu->{'emails'}->[$key]){
	push @subscriber_exclusion, $data_exclu->{'emails'}->[$key];
	$key = $key + 1;
    }
    

    my $users_added = 0;
    my $users_updated = 0;

    ## Get an Exclusive lock
    my $lock = new Lock ($self->{'dir'}.'/include');
    unless (defined $lock) {
	&Log::do_log('err','Could not create new lock');
	return undef;
    }
    $lock->set_timeout(10*60); 
    unless ($lock->lock('write')) {
	return undef;
    }

    ## Go though previous list of users
    my $users_removed = 0;
    my $user_removed;
    my @deltab;
    foreach my $email (keys %old_subscribers) {
	unless( defined($new_subscribers->{$email}) ) {
	    ## User is also subscribed, update DB entry
	    if ($old_subscribers{$email}{'subscribed'}) {
		&Log::do_log('debug', 'List:sync_include: updating %s to list %s', $email, $name);
		unless( $self->update_list_member($email,  {'update_date' => time,
						     'included' => 0,
						     'id' => ''}) ) {
		    &Log::do_log('err', 'List:sync_include(%s): Failed to update %s',  $name, $email);
		    next;
		}
		
		$users_updated++;

		## Tag user for deletion
	    }else {
		&Log::do_log('debug3', 'List:sync_include: removing %s from list %s', $email, $name);
		@deltab = ($email);
		unless($user_removed = $self->delete_list_member('users' => \@deltab)) {
		    &Log::do_log('err', 'List:sync_include(%s): Failed to delete %s', $name, $user_removed);
		    return undef;
		}
		if ($user_removed) {
		    $users_removed++;
		    ## Send notification if the list config authorizes it only.
		    if ($self->{'admin'}{'inclusion_notification_feature'} eq 'on') {
			unless ($self->send_file('removed', $email, $self->{'domain'},{})) {
			    &Log::do_log('err',"Unable to send template 'removed' to $email");
			}
		    }
		}
	    }
	}
    }
    if ($users_removed > 0) {
	&Log::do_log('notice', 'List:sync_include(%s): %d users removed', $name, $users_removed);
    }

    ## Go through new users
    my @add_tab;
    $users_added = 0;
    foreach my $email (keys %{$new_subscribers}) {
	if (defined($old_subscribers{$email}) ) {

	    if ($old_subscribers{$email}{'included'}) {

	      ## If one user attribute has changed, then we should update the user entry
	      foreach my $attribute ('id','gecos') {
		if ($old_subscribers{$email}{$attribute} ne $new_subscribers->{$email}{$attribute}) {
		  &Log::do_log('debug', 'List:sync_include: updating %s to list %s', $email, $name);
		  unless( $self->update_list_member($email,  {'update_date' => time,
						       $attribute => $new_subscribers->{$email}{$attribute} }) ) {
		    &Log::do_log('err', 'List:sync_include(%s): Failed to update %s', $name, $email);
		    next;
		  }
		  $users_updated++;
		}
	      }
		## User was already subscribed, update include_sources_subscriber in DB
	    }else {
		&Log::do_log('debug', 'List:sync_include: updating %s to list %s', $email, $name);
		unless( $self->update_list_member($email,  {'update_date' => time,
						     'included' => 1,
						     'id' => $new_subscribers->{$email}{'id'} }) ) {
		    &Log::do_log('err', 'List:sync_include(%s): Failed to update %s',
			    $name, $email);
		    next;
		}
		$users_updated++;
	    }

	    ## Add new included user
	}else {
	    my $compare = 0;
	    foreach my $sub_exclu (@subscriber_exclusion){
		unless ($compare eq '1'){
		    if ($email eq $sub_exclu){
			$compare = 1;
		    }else{
			next;
		    }
		}
	    }
	    if($compare eq '1'){
		next;
	    }
	    &Log::do_log('debug3', 'List:sync_include: adding %s to list %s', $email, $name);
	    my $u = $new_subscribers->{$email};
	    $u->{'included'} = 1;
	    $u->{'date'} = time;
	    @add_tab = ($u);
	    my $user_added = 0;
	    unless( $user_added = $self->add_list_member( @add_tab ) ) {
		&Log::do_log('err', 'List:sync_include(%s): Failed to add new users', $name);
		return undef;
	    }
	    if ($user_added) {
		$users_added++;
		## Send notification if the list config authorizes it only.
		if ($self->{'admin'}{'inclusion_notification_feature'} eq 'on') {
		    unless ($self->send_file('welcome', $u->{'email'}, $self->{'domain'},{})) {
			&Log::do_log('err',"Unable to send template 'welcome' to $u->{'email'}");
		    }
		}
	    }
	}
    }

    if ($users_added) {
        &Log::do_log('notice', 'List:sync_include(%s): %d users added', $name, $users_added);
    }

    &Log::do_log('notice', 'List:sync_include(%s): %d users updated', $name, $users_updated);

    ## Release lock
    unless ($lock->unlock()) {
	return undef;
    }

    ## Get and save total of subscribers
    $self->{'total'} = $self->_load_total_db('nocache');
    $self->{'last_sync'} = time;
    $self->savestats();

    return 1;
}

## The previous function (sync_include) is to be called by the task_manager.
## This one is to be called from anywhere else. This function deletes the scheduled
## sync_include task. If this deletion happened in sync_include(), it would disturb
## the normal task_manager.pl functionning.

sub on_the_fly_sync_include {
    my $self = shift;
    my %options = @_;

    my $pertinent_ttl = $self->{'admin'}{'distribution_ttl'}||$self->{'admin'}{'ttl'};
    &Log::do_log('debug2','List::on_the_fly_sync_include(%s)',$pertinent_ttl);
    if ( $options{'use_ttl'} != 1 || $self->{'last_sync'} < time - $pertinent_ttl) { 
	&Log::do_log('notice', "Synchronizing list members...");
	if ($self->sync_include()) {
	    $self->remove_task('sync_include');
	    return 1;
	}
	else {
	    return undef;
	}
    }
    return 1;
}

sub sync_include_admin {
    my ($self) = shift;
    my $option = shift;
    
    my $name=$self->{'name'};
    &Log::do_log('debug2', 'List:sync_include_admin(%s)', $name);

    ## don't care about listmaster role
    foreach my $role ('owner','editor'){
	my $old_admin_users = {};
        ## Load a hash with the old admin users
	for (my $admin_user=$self->get_first_list_admin($role); $admin_user; $admin_user=$self->get_next_list_admin()) {
	    $old_admin_users->{lc($admin_user->{'email'})} = $admin_user;
	}
	
	## Load a hash with the new admin user list from an include source(s)
	my $new_admin_users_include;
	## Load a hash with the new admin user users from the list config
	my $new_admin_users_config;
	unless ($option eq 'purge') {
	    
	    $new_admin_users_include = $self->_load_list_admin_from_include($role);
	    
	    ## If include sources were not available, do not update admin users
	    ## Use DB cache instead
	    unless (defined $new_admin_users_include) {
		&Log::do_log('err', 'Could not get %ss from an include source for list %s', $role, $name);
		unless (&List::send_notify_to_listmaster('sync_include_admin_failed', $self->{'domain'}, [$name])) {
		    &Log::do_log('notice',"Unable to send notify 'sync_include_admmin_failed' to listmaster");
		}
		return undef;
	    }

	    $new_admin_users_config = $self->_load_list_admin_from_config($role);
	    
	    unless (defined $new_admin_users_config) {
		&Log::do_log('err', 'Could not get %ss from config for list %s', $role, $name);
		return undef;
	    }
	}
	
	my @add_tab;
	my $admin_users_added = 0;
	my $admin_users_updated = 0;
	
	## Get an Exclusive lock
	my $lock = new Lock ($self->{'dir'}.'/include_admin_user');
	unless (defined $lock) {
	    &Log::do_log('err','Could not create new lock');
	    return undef;
	}
	$lock->set_timeout(20); 
	unless ($lock->lock('write')) {
	    return undef;
	}
	
	## Go through new admin_users_include
	foreach my $email (keys %{$new_admin_users_include}) {
	    
	    # included and subscribed
	    if (defined $new_admin_users_config->{$email}) {
		my $param;
		foreach my $p ('reception','visibility','gecos','info','profile') {
		    #  config parameters have priority on include parameters in case of conflict
		    $param->{$p} = $new_admin_users_config->{$email}{$p} if (defined $new_admin_users_config->{$email}{$p});
		    $param->{$p} ||= $new_admin_users_include->{$email}{$p};
		}

                #Admin User was already in the DB
		if (defined $old_admin_users->{$email}) {

		    $param->{'included'} = 1;
		    $param->{'id'} = $new_admin_users_include->{$email}{'id'};
		    $param->{'subscribed'} = 1;
		   
		    my $param_update = &is_update_param($param,$old_admin_users->{$email});
		    
		    # updating
		    if (defined $param_update) {
			if (%{$param_update}) {
			    &Log::do_log('debug', 'List:sync_include_admin : updating %s %s to list %s',$role, $email, $name);
			    $param_update->{'update_date'} = time;
			    
			    unless ($self->update_list_admin($email, $role,$param_update)) {
				&Log::do_log('err', 'List:sync_include_admin(%s): Failed to update %s %s', $name,$role,$email);
				next;
			    }
			    $admin_users_updated++;
			}
		    }
		    #for the next foreach (sort of new_admin_users_config that are not included)
		    delete ($new_admin_users_config->{$email});
		    
		# add a new included and subscribed admin user 
		}else {
		    &Log::do_log('debug2', 'List:sync_include_admin: adding %s %s to list %s',$email,$role, $name);
		    
		    foreach my $key (keys %{$param}) {  
			$new_admin_users_config->{$email}{$key} = $param->{$key};
		    }
		    $new_admin_users_config->{$email}{'included'} = 1;
		    $new_admin_users_config->{$email}{'subscribed'} = 1;
		    push (@add_tab,$new_admin_users_config->{$email});
		    
                    #for the next foreach (sort of new_admin_users_config that are not included)
		    delete ($new_admin_users_config->{$email});
		}
		
	    # only included
	    }else {
		my $param = $new_admin_users_include->{$email};

                #Admin User was already in the DB
		if (defined($old_admin_users->{$email}) ) {

		    $param->{'included'} = 1;
		    $param->{'id'} = $new_admin_users_include->{$email}{'id'};
		    $param->{'subscribed'} = 0;

		    my $param_update = &is_update_param($param,$old_admin_users->{$email});
		   
		    # updating
		    if (defined $param_update) {
			if (%{$param_update}) {
			    &Log::do_log('debug', 'List:sync_include_admin : updating %s %s to list %s', $role, $email, $name);
			    $param_update->{'update_date'} = time;
			    
			    unless ($self->update_list_admin($email, $role,$param_update)) {
				&Log::do_log('err', 'List:sync_include_admin(%s): Failed to update %s %s', $name, $role,$email);
				next;
			    }
			    $admin_users_updated++;
			}
		    }
		# add a new included admin user 
		}else {
		    &Log::do_log('debug2', 'List:sync_include_admin: adding %s %s to list %s', $role, $email, $name);
		    
		    foreach my $key (keys %{$param}) {  
			$new_admin_users_include->{$email}{$key} = $param->{$key};
		    }
		    $new_admin_users_include->{$email}{'included'} = 1;
		    push (@add_tab,$new_admin_users_include->{$email});
		}
	    }
	}   

	## Go through new admin_users_config (that are not included : only subscribed)
	foreach my $email (keys %{$new_admin_users_config}) {

	    my $param = $new_admin_users_config->{$email};
	    
	    #Admin User was already in the DB
	    if (defined($old_admin_users->{$email}) ) {

		$param->{'included'} = 0;
		$param->{'id'} = '';
		$param->{'subscribed'} = 1;
		my $param_update = &is_update_param($param,$old_admin_users->{$email});

		# updating
		if (defined $param_update) {
		    if (%{$param_update}) {
			&Log::do_log('debug', 'List:sync_include_admin : updating %s %s to list %s', $role, $email, $name);
			$param_update->{'update_date'} = time;
			
			unless ($self->update_list_admin($email, $role,$param_update)) {
			    &Log::do_log('err', 'List:sync_include_admin(%s): Failed to update %s %s', $name, $role, $email);
			    next;
			}
			$admin_users_updated++;
		    }
		}
	    # add a new subscribed admin user 
	    }else {
		&Log::do_log('debug2', 'List:sync_include_admin: adding %s %s to list %s', $role, $email, $name);
		
		foreach my $key (keys %{$param}) {  
		    $new_admin_users_config->{$email}{$key} = $param->{$key};
		}
		$new_admin_users_config->{$email}{'subscribed'} = 1;
		push (@add_tab,$new_admin_users_config->{$email});
	    }
	}
	
	if ($#add_tab >= 0) {
	    unless( $admin_users_added = $self->add_list_admin($role,@add_tab ) ) {
		&Log::do_log('err', 'List:sync_include_admin(%s): Failed to add new %ss',  $role, $name);
		return undef;
	    }
	}
	
	if ($admin_users_added) {
	    &Log::do_log('debug', 'List:sync_include_admin(%s): %d %s(s) added',
		    $name, $admin_users_added, $role);
	}
	
	&Log::do_log('debug', 'List:sync_include_admin(%s): %d %s(s) updated', $name, $admin_users_updated, $role);

	## Go though old list of admin users
	my $admin_users_removed = 0;
	my @deltab;
	
	foreach my $email (keys %$old_admin_users) {
	    unless (defined($new_admin_users_include->{$email}) || defined($new_admin_users_config->{$email})) {
		&Log::do_log('debug2', 'List:sync_include_admin: removing %s %s to list %s', $role, $email, $name);
		push(@deltab, $email);
	    }
	}
	
	if ($#deltab >= 0) {
	    unless($admin_users_removed = $self->delete_list_admin($role,@deltab)) {
		&Log::do_log('err', 'List:sync_include_admin(%s): Failed to delete %s %s',
			$name, $role, $admin_users_removed);
		return undef;
	    }
	    &Log::do_log('debug', 'List:sync_include_admin(%s): %d %s(s) removed',
		    $name, $admin_users_removed, $role);
	}

	## Release lock
	unless ($lock->unlock()) {
	    return undef;
	}
    }	
   
    $self->{'last_sync_admin_user'} = time;
    $self->savestats();
 
    return $self->get_nb_owners;
}

## Load param admin users from the config of the list
sub _load_list_admin_from_config {
    my $self = shift;
    my $role = shift; 
    my $name = $self->{'name'};
    my %admin_users;

    &Log::do_log('debug2', '(%s) for list %s',$role, $name);  

    foreach my $entry (@{$self->{'admin'}{$role}}) {
	my $email = lc($entry->{'email'});
	my %u;
  
	$u{'email'} = $email;
	$u{'reception'} = $entry->{'reception'};
	$u{'visibility'} = $entry->{'visibility'};
	$u{'gecos'} = $entry->{'gecos'};
	$u{'info'} = $entry->{'info'};
	$u{'profile'} = $entry->{'profile'} if ($role eq 'owner');
 
	$admin_users{$email} = \%u;
    }
    return \%admin_users;
}

## return true if new_param has changed from old_param
#  $new_param is changed to return only entries that need to
# be updated (only deals with admin user parameters, editor or owner)
sub is_update_param {
    my $new_param = shift;
    my $old_param = shift;
    my $resul = {};
    my $update = 0;

    &Log::do_log('debug2', 'List::is_update_param ');  

    foreach my $p ('reception','visibility','gecos','info','profile','id','included','subscribed') {
	if (defined $new_param->{$p}) {
	    if ($new_param->{$p} ne $old_param->{$p}) {
		$resul->{$p} = $new_param->{$p};
		$update = 1;
	    }
	}else {
	    if (defined $old_param->{$p} && ($old_param->{$p} ne '')) {
		$resul->{$p} = '';
		$update = 1;
	    }
	}
    }
    if ($update) {
	return $resul;
    }else {
	return undef;
    }
}



sub _inclusion_loop {

    my $name = shift;
    my $incl = shift;
    my $depend_on = shift;

    return 1 if ($depend_on->{$incl}) ; 
    
    return undef;
}

sub _load_total_db {
    my $self = shift;
    my $option = shift;
    &Log::do_log('debug2', 'List::_load_total_db(%s)', $self->{'name'});

    ## Use session cache
    if (($option ne 'nocache') && (defined $list_cache{'load_total_db'}{$self->{'domain'}}{$self->{'name'}})) {
	return $list_cache{'load_total_db'}{$self->{'domain'}}{$self->{'name'}};
    }

    push @sth_stack, $sth;

    ## Query the Database
    unless ($sth = &SDM::do_query( "SELECT count(*) FROM subscriber_table WHERE (list_subscriber = %s AND robot_subscriber = %s)", &SDM::quote($self->{'name'}), &SDM::quote($self->{'domain'}))) {
	do_log('debug','Unable to get subscriber count for list %s@%s',$self->{'name'},$self->{'domain'});
	return undef;
    }
    
    my $total = $sth->fetchrow;

    $sth->finish();

    $sth = pop @sth_stack;

    ## Set session cache
    $list_cache{'load_total_db'}{$self->{'domain'}}{$self->{'name'}} = $total;

    return $total;
}

## Writes to disk the stats data for a list.
sub _save_stats_file {
    my $file = shift;
    my $stats = shift;
    my $total = shift;
    my $last_sync = shift;
    my $last_sync_admin_user = shift;
    
    unless (defined $stats && ref ($stats) eq 'ARRAY') {
	&Log::do_log('err', 'List_save_stats_file() : incorrect parameter');
	return undef;
    }

    &Log::do_log('debug2', 'List::_save_stats_file(%s, %d, %d, %d)', $file, $total,$last_sync,$last_sync_admin_user );
    
    open(L, "> $file") || return undef;
    printf L "%d %.0f %.0f %.0f %d %d %d\n", @{$stats}, $total, $last_sync, $last_sync_admin_user;
    close(L);
}

## Writes the user list to disk
sub _save_list_members_file {
    my($self, $file) = @_;
    &Log::do_log('debug3', '(%s)', $file);
    
    my($k, $s);
    
    &Log::do_log('debug2','Saving user file %s', $file);
    
    rename("$file", "$file.old");
    open SUB, "> $file" or return undef;
    
    for ($s = $self->get_first_list_member(); $s; $s = $self->get_next_list_member()) {
	foreach $k ('date','update_date','email','gecos','reception','visibility') {
	    printf SUB "%s %s\n", $k, $s->{$k} unless ($s->{$k} eq '');
	    
	}
	print SUB "\n";
    }
    close SUB;
    return 1;
}

sub _compare_addresses {
   my ($a, $b) = @_;

   my ($ra, $rb);

   $a =~ tr/A-Z/a-z/;
   $b =~ tr/A-Z/a-z/;

   $ra = reverse $a;
   $rb = reverse $b;

   return ($ra cmp $rb);
}

## Does the real job : stores the message given as an argument into
## the digest of the list.
sub store_digest {
    my($self,$msg) = @_;
    &Log::do_log('debug3', 'List::store_digest');

    my($filename, $newfile);
    my $separator = &tools::get_separator();  

    unless ( -d "$Conf::Conf{'queuedigest'}") {
	return;
    }
    
    my @now  = localtime(time);

    ## Reverse compatibility concern
    if (-f "$Conf::Conf{'queuedigest'}/$self->{'name'}") {
  	$filename = "$Conf::Conf{'queuedigest'}/$self->{'name'}";
    }else {
 	$filename = $Conf::Conf{'queuedigest'}.'/'.$self->get_list_id();
    }

    $newfile = !(-e $filename);
    my $oldtime=(stat $filename)[9] unless($newfile);
  
    open(OUT, ">> $filename") || return;
    if ($newfile) {
	## create header
	printf OUT "\nThis digest for list has been created on %s\n\n",
      POSIX::strftime("%a %b %e %H:%M:%S %Y", @now);
	print OUT "------- THIS IS A RFC934 COMPLIANT DIGEST, YOU CAN BURST IT -------\n\n";
	printf OUT "\n%s\n\n", &tools::get_separator();

       # send the date of the next digest to the users
    }
    #$msg->head->delete('Received') if ($msg->head->get('received'));
    $msg->print(\*OUT);
    printf OUT "\n%s\n\n", &tools::get_separator();
    close(OUT);
    
    #replace the old time
    utime $oldtime,$oldtime,$filename   unless($newfile);
}

## List of lists hosted a robot
## Returns a ref to an array of List objects
sub get_lists {
    my $robot_context = shift || '*';
    my $options = shift;
    my $requested_lists = shift; ## Optional parameter to load only a subset of all lists

    my(@lists, $l,@robots);
    &Log::do_log('debug2', 'List::get_lists(%s)',$robot_context);

    if ($robot_context eq '*') {
	@robots = &get_robots ;
    }else{
	push @robots, $robot_context ;
    }
    
    foreach my $robot (@robots) {
    
	## Check cache first
	if (defined $list_cache{'get_lists'}{$robot}) {
	    push @lists, @{$list_cache{'get_lists'}{$robot}};
	}else {
	    my $robot_dir =  $Conf::Conf{'home'}.'/'.$robot ;
	    $robot_dir = $Conf::Conf{'home'}  unless ((-d $robot_dir) || ($robot ne $Conf::Conf{'domain'}));
	    
	    unless (-d $robot_dir) {
		do_log('err',"unknown robot $robot, Unable to open $robot_dir");
		return undef ;
	    }
	    
	    unless (opendir(DIR, $robot_dir)) {
		do_log('err',"Unable to open $robot_dir");
		return undef;
	    }

	    ## Load only requested lists if $requested_list is set
	    ## otherwise load all lists
	    my @files;
	    if ( defined($requested_lists)){
	      @files = sort @{$requested_lists};
	    }else {
	      @files = sort readdir(DIR);
	    }

	    foreach my $l (@files) {
		next if (($l =~ /^\./o) || (! -d "$robot_dir/$l") || (! -f "$robot_dir/$l/config"));
		
		my $list = new List ($l, $robot, $options);
		
		next unless (defined $list);
		
		push @lists, $list;
		
		## Also feed the cache
		## Unless we only loaded a subset of all lists ($requested_lists parameter used)
		unless (defined $requested_lists) {
		  push @{$list_cache{'get_lists'}{$robot}}, $list;
		}
		
	    }
	    closedir DIR;
	}
    }
    return \@lists;
}

## List of robots hosted by Sympa
sub get_robots {

    my(@robots, $r);
    &Log::do_log('debug2', 'List::get_robots()');

    unless (opendir(DIR, $Conf::Conf{'etc'})) {
	do_log('err',"Unable to open $Conf::Conf{'etc'}");
	return undef;
    }
    my $use_default_robot = 1 ;
    foreach $r (sort readdir(DIR)) {
	next unless (($r !~ /^\./o) && (-d "$Conf::Conf{'home'}/$r"));
	next unless (-r "$Conf::Conf{'etc'}/$r/robot.conf");
	push @robots, $r;
	undef $use_default_robot if ($r eq $Conf::Conf{'domain'});
    }
    closedir DIR;

    push @robots, $Conf::Conf{'domain'} if ($use_default_robot);
    return @robots ;
}

## List of lists in database mode which e-mail parameter is member of
## Results concern ALL robots
sub get_which_db {
    my $email = shift;
    my $function = shift;
    &Log::do_log('debug3', 'List::get_which_db(%s,%s)', $email, $function);
    
    my ($l, %which);

    if ($function eq 'member') {
 	## Get subscribers
	push @sth_stack, $sth;

	unless ($sth = &SDM::do_query( "SELECT list_subscriber, robot_subscriber, bounce_subscriber, reception_subscriber, topics_subscriber, include_sources_subscriber, subscribed_subscriber, included_subscriber  FROM subscriber_table WHERE user_subscriber = %s",&SDM::quote($email))) {
	    &Log::do_log('err','Unable to get the list of lists the user %s is subscribed to', $email);
	    return undef;
	}

	while ($l = $sth->fetchrow_hashref('NAME_lc')) {
	    my ($name, $robot) = ($l->{'list_subscriber'}, $l->{'robot_subscriber'});
	    $name =~ s/\s*$//;  ## usefull for PostgreSQL
	    $which{$robot}{$name}{'member'} = 1;
	    $which{$robot}{$name}{'reception'} = $l->{'reception_subscriber'};
	    $which{$robot}{$name}{'bounce'} = $l->{'bounce_subscriber'};
	    $which{$robot}{$name}{'topic'} = $l->{'topic_subscriber'};
	    $which{$robot}{$name}{'included'} = $l->{'included_subscriber'};
	    $which{$robot}{$name}{'subscribed'} = $l->{'subscribed_subscriber'};
	    $which{$robot}{$name}{'include_sources'} = $l->{'include_sources_subscriber'};
	}	
	$sth->finish();	
	$sth = pop @sth_stack;

    }else {
	## Get admin
	push @sth_stack, $sth;
	
	unless ($sth = &SDM::do_query( "SELECT list_admin, robot_admin, role_admin FROM admin_table WHERE user_admin = %s",&SDM::quote($email))) {
	    &Log::do_log('err','Unable to get the list of lists the user %s is subscribed to', $email);
	    return undef;
	}
	
	while ($l = $sth->fetchrow_hashref('NAME_lc')) {
	    $which{$l->{'robot_admin'}}{$l->{'list_admin'}}{$l->{'role_admin'}} = 1;
	}
	
	$sth->finish();
	
	$sth = pop @sth_stack;
    }

    return \%which;
}

## get idp xref to locally validated email address
sub get_netidtoemail_db {
    my $robot = shift;
    my $netid = shift;
    my $idpname = shift;
    &Log::do_log('debug', 'List::get_netidtoemail_db(%s, %s)', $netid, $idpname);

    my ($l, %which, $email);

    push @sth_stack, $sth;

    unless ($sth = &SDM::do_query( "SELECT email_netidmap FROM netidmap_table WHERE netid_netidmap = %s and serviceid_netidmap = %s and robot_netidmap = %s", &SDM::quote($netid), &SDM::quote($idpname), &SDM::quote($robot))) {
	&Log::do_log('err','Unable to get email address from netidmap_table for id %s, service %s, robot %s', $netid, $idpname, $robot);
	return undef;
    }

    $email = $sth->fetchrow;

    $sth->finish();

    $sth = pop @sth_stack;

    return $email;
}

## set idp xref to locally validated email address
sub set_netidtoemail_db {
    my $robot = shift;
    my $netid = shift;
    my $idpname = shift;
    my $email = shift; 
    &Log::do_log('debug', 'List::set_netidtoemail_db(%s, %s, %s)', $netid, $idpname, $email);

    my ($l, %which);

    unless (&SDM::do_query( "INSERT INTO netidmap_table (netid_netidmap,serviceid_netidmap,email_netidmap,robot_netidmap) VALUES (%s, %s, %s, %s)", &SDM::quote($netid), &SDM::quote($idpname), &SDM::quote($email), &SDM::quote($robot))) {
	&Log::do_log('err','Unable to set email address %s in netidmap_table for id %s, service %s, robot %s', $email, $netid, $idpname, $robot);
	return undef;
    }

    return 1;
}

## Update netidmap table when user email address changes
sub update_email_netidmap_db{
    my ($robot, $old_email, $new_email) = @_;
    
    unless (defined $robot && 
	    defined $old_email &&
	    defined $new_email) {
	&Log::do_log('err', 'Missing parameter');
	return undef;
    } 
    
    unless (&SDM::do_query( "UPDATE netidmap_table SET email_netidmap = %s WHERE (email_netidmap = %s AND robot_netidmap = %s)",&SDM::quote($new_email), &SDM::quote($old_email), &SDM::quote($robot))) {
	&Log::do_log('err','Unable to set new email address %s in netidmap_table to replace old address %s for robot %s', $new_email, $old_email, $robot);
	return undef;
    }

    return 1;
}

## &get_which(<email>,<robot>,<type>)
## Get lists of lists where <email> assumes this <type> (owner, editor or member) of
## function to any list in <robot>.
sub get_which {
    my $email = shift;
    my $robot =shift;
    my $function = shift;
    &Log::do_log('debug2', 'List::get_which(%s, %s)', $email, $function);

    my ($l, @which);

    ## WHICH in Database
    my $db_which = &get_which_db($email,  $function);
    my $requested_lists;
    @{$requested_lists} = keys %{$db_which->{$robot}};

    ## This call is required too 
    my $all_lists = &get_lists($robot, {}, $requested_lists);

    foreach my $list (@$all_lists){
 
	my $l = $list->{'name'};
	# next unless (($list->{'admin'}{'host'} eq $robot) || ($robot eq '*')) ;

	## Skip closed lists unless the user is Listmaster
	if ($list->{'admin'}{'status'} =~ /closed/) {
	    next;
	}

        if ($function eq 'member') {
	    if ($db_which->{$robot}{$l}{'member'}) {
		$list->{'user'}{'reception'} = $db_which->{$robot}{$l}{'reception'};
		$list->{'user'}{'topic'} = $db_which->{$robot}{$l}{'topic'};
		$list->{'user'}{'bounce'} = $db_which->{$robot}{$l}{'bounce'};
		$list->{'user'}{'subscribed'} = $db_which->{$robot}{$l}{'subscribed'};
		$list->{'user'}{'included'} = $db_which->{$robot}{$l}{'included'};
		
		push @which, $list ;
		
		## Update cache
		$list_cache{'is_list_member'}{$list->{'domain'}}{$l}{$email} = 1;
	    }else {
		## Update cache
		$list_cache{'is_list_member'}{$list->{'domain'}}{$l}{$email} = 0;		    
	    }
	    
	}elsif ($function eq 'owner') {
	    if ($db_which->{$robot}{$l}{'owner'} == 1) {
		push @which, $list ;
		
		## Update cache
		$list_cache{'am_i'}{'owner'}{$list->{'domain'}}{$l}{$email} = 1;
	    }else {
		## Update cache
		$list_cache{'am_i'}{'owner'}{$list->{'domain'}}{$l}{$email} = 0;		    
	    }
	}elsif ($function eq 'editor') {
	    if ($db_which->{$robot}{$l}{'editor'} == 1) {
		push @which, $list ;
		
		## Update cache
		$list_cache{'am_i'}{'editor'}{$list->{'domain'}}{$l}{$email} = 1;
	    }else {
		## Update cache
		$list_cache{'am_i'}{'editor'}{$list->{'domain'}}{$l}{$email} = 0;		    
	    }
	}else {
	    &Log::do_log('err',"Internal error, unknown or undefined parameter $function  in get_which");
            return undef ;
	}
    }
    
    return @which;
}



## return total of messages awaiting moderation
sub get_mod_spool_size {
    my $self = shift;
    &Log::do_log('debug3', 'List::get_mod_spool_size()');    
    my @msg;
    
    unless (opendir SPOOL, $Conf::Conf{'queuemod'}) {
	&Log::do_log('err', 'Unable to read spool %s', $Conf::Conf{'queuemod'});
	return undef;
    }

    my $list_name = $self->{'name'};
    my $list_id = $self->get_list_id();
    @msg = sort grep(/^($list_id|$list_name)\_\w+$/, readdir SPOOL);

    closedir SPOOL;
    return ($#msg + 1);
}

### moderation for shared

# return the status of the shared
sub get_shared_status {
    my $self = shift;
    &Log::do_log('debug3', '(%s)', $self->{'name'});
    
    if (-e $self->{'dir'}.'/shared') {
	return 'exist';
    }elsif (-e $self->{'dir'}.'/pending.shared') {
	return 'deleted';
    }else{
	return 'none';
    }
}

# return the list of documents shared waiting for moderation 
sub get_shared_moderated {
    my $self = shift;
    &Log::do_log('debug3', 'List::get_shared_moderated()');  
    my $shareddir = $self->{'dir'}.'/shared';

    unless (-e "$shareddir") {
	return undef;
    }
    
    ## sort of the shared
    my @mod_dir = &sort_dir_to_get_mod("$shareddir");
    return \@mod_dir;
}

# return the list of documents awaiting for moderation in a dir and its subdirs
sub sort_dir_to_get_mod {
    #dir to explore
    my $dir = shift;
    &Log::do_log('debug3', 'List::sort_dir_to_get_mod()');  
    
    # listing of all the shared documents of the directory
    unless (opendir DIR, "$dir") {
	do_log('err',"sort_dir_to_get_mod : cannot open $dir : $!");
	return undef;
    }
    
    # array of entry of the directory DIR 
    my @tmpdir = readdir DIR;
    closedir DIR;

    # private entry with documents not yet moderated
    my @moderate_dir = grep (/(\.moderate)$/, @tmpdir);
    @moderate_dir = grep (!/^\.desc\./, @moderate_dir);

    foreach my $d (@moderate_dir) {
	$d = "$dir/$d";
    }
   
    my $path_d;
    foreach my $d (@tmpdir) {
	# current document
        $path_d = "$dir/$d";

	if ($d =~ /^\.+$/){
	    next;
	}

	if (-d $path_d) {
	    push(@moderate_dir,&sort_dir_to_get_mod($path_d));
	}
    }
	
    return @moderate_dir;
    
 } 


## Get the type of a DB field
sub get_db_field_type {
    my ($table, $field) = @_;

    unless ($sth = &SDM::do_query("SHOW FIELDS FROM $table")) {
	do_log('err','get the list of fields for table %s', $table);
	return undef;
    }
	    
    while (my $ref = $sth->fetchrow_hashref('NAME_lc')) {
	next unless ($ref->{'Field'} eq $field);

	return $ref->{'Type'};
    }

    return undef;
}

## Lowercase field from database
sub lowercase_field {
    my ($table, $field) = @_;

    my $total = 0;

    unless ($sth = &SDM::do_query( "SELECT $field from $table")) {
	do_log('err','Unable to get values of field %s for table %s',$field,$table);
	return undef;
    }

    while (my $user = $sth->fetchrow_hashref('NAME_lc')) {
	my $lower_cased = lc($user->{$field});
	next if ($lower_cased eq $user->{$field});

	$total++;

	## Updating Db
	unless ($sth = &SDM::do_query( "UPDATE $table SET $field=%s WHERE ($field=%s)", &SDM::quote($lower_cased), &SDM::quote($user->{$field}))) {
	    do_log('err','Unable to set field % from table %s to value %s',$field,$lower_cased,$table);
	    next;
	}
    }
    $sth->finish();

    return $total;
}

## Loads the list of topics if updated
sub load_topics {
    
    my $robot = shift ;
    &Log::do_log('debug2', 'List::load_topics(%s)',$robot);

    my $conf_file = &tools::get_filename('etc',{},'topics.conf',$robot);

    unless ($conf_file) {
	&Log::do_log('err','No topics.conf defined');
	return undef;
    }

    my $topics = {};

    ## Load if not loaded or changed on disk
    if (! $list_of_topics{$robot} || ((stat($conf_file))[9] > $mtime{'topics'}{$robot})) {

	## delete previous list of topics
	%list_of_topics = undef;

	unless (-r $conf_file) {
	    &Log::do_log('err',"Unable to read $conf_file");
	    return undef;
	}
	
	unless (open (FILE, "<", $conf_file)) {
	    &Log::do_log('err',"Unable to open config file $conf_file");
	    return undef;
	}
	
	## Raugh parsing
	my $index = 0;
	my (@raugh_data, $topic);
	while (<FILE>) {
	    Encode::from_to($_, $Conf::Conf{'filesystem_encoding'}, 'utf8');
	    if (/^([\-\w\/]+)\s*$/) {
		$index++;
		$topic = {'name' => $1,
			  'order' => $index
			  };
	    }elsif (/^([\w\.]+)\s+(.+)\s*$/) {
		next unless (defined $topic->{'name'});
		
		$topic->{$1} = $2;
	    }elsif (/^\s*$/) {
		if (defined $topic->{'name'}) {
		    push @raugh_data, $topic;
		    $topic = {};
		}
	    }	    
	}
	close FILE;

	## Last topic
	if (defined $topic->{'name'}) {
	    push @raugh_data, $topic;
	    $topic = {};
	}

	$mtime{'topics'}{$robot} = (stat($conf_file))[9];

	unless ($#raugh_data > -1) {
	    &Log::do_log('notice', 'No topic defined in %s/topics.conf', $Conf::Conf{'etc'});
	    return undef;
	}

	## Analysis
	foreach my $topic (@raugh_data) {
	    my @tree = split '/', $topic->{'name'};
	    
	    if ($#tree == 0) {
		my $title = _get_topic_titles($topic);
		$list_of_topics{$robot}{$tree[0]}{'title'} = $title;
		$list_of_topics{$robot}{$tree[0]}{'visibility'} = $topic->{'visibility'}||'default';
		#$list_of_topics{$robot}{$tree[0]}{'visibility'} = &_load_scenario_file('topics_visibility', $robot,$topic->{'visibility'}||'default');
		$list_of_topics{$robot}{$tree[0]}{'order'} = $topic->{'order'};
	    }else {
		my $subtopic = join ('/', @tree[1..$#tree]);
		my $title = _get_topic_titles($topic);
		$list_of_topics{$robot}{$tree[0]}{'sub'}{$subtopic} = &_add_topic($subtopic,$title);
	    }
	}

	## Set undefined Topic (defined via subtopic)
	foreach my $t (keys %{$list_of_topics{$robot}}) {
	    unless (defined $list_of_topics{$robot}{$t}{'visibility'}) {
		#$list_of_topics{$robot}{$t}{'visibility'} = &_load_scenario_file('topics_visibility', $robot,'default');
	    }
	    
	    unless (defined $list_of_topics{$robot}{$t}{'title'}) {
		$list_of_topics{$robot}{$t}{'title'} = {'default' => $t};
	    }	
	}
    }

    ## Set the title in the current language
    my $lang = &Language::GetLang();
    foreach my $top (keys %{$list_of_topics{$robot}}) {
	my $topic = $list_of_topics{$robot}{$top};
	$topic->{'current_title'} = $topic->{'title'}{$lang} || $topic->{'title'}{'default'} || $top;

	foreach my $subtop (keys %{$topic->{'sub'}}) {
	$topic->{'sub'}{$subtop}{'current_title'} = $topic->{'sub'}{$subtop}{'title'}{$lang} || $topic->{'sub'}{$subtop}{'title'}{'default'} || $subtop;	    
	}
    }

    return %{$list_of_topics{$robot}};
}

sub _get_topic_titles {
    my $topic = shift;

    my $title;
    foreach my $key (%{$topic}) {
	if ($key =~ /^title(.(\w+))?$/) {
	    my $lang = $2 || 'default';
	    $title->{$lang} = $topic->{$key};
	}
    }
    
    return $title;
}

## Inner sub used by load_topics()
sub _add_topic {
    my ($name, $title) = @_;
    my $topic = {};

    my @tree = split '/', $name;
    if ($#tree == 0) {
	return {'title' => $title};
    }else {
	$topic->{'sub'}{$name} = &_add_topic(join ('/', @tree[1..$#tree]), $title);
	return $topic;
    }
}

############ THIS IS RELATED TO NEW LOAD_ADMIN_FILE #############

## Sort function for writing config files
sub by_order {
    ($::pinfo{$main::a}{'order'} <=> $::pinfo{$main::b}{'order'}) || ($main::a cmp $main::b);
}

## Apply defaults to parameters definition (%::pinfo)
sub _apply_defaults {
    &Log::do_log('debug3', 'List::_apply_defaults()');

    ## List of available languages
    $::pinfo{'lang'}{'format'} = &Language::GetSupportedLanguages();

    ## Parameter order
    foreach my $index (0..$#param_order) {
	if ($param_order[$index] eq '*') {
	    $default{'order'} = $index;
	}else {
	    $::pinfo{$param_order[$index]}{'order'} = $index;
	}
    }

    ## Parameters
    foreach my $p (keys %::pinfo) {

	## Apply defaults to %pinfo
	foreach my $d (keys %default) {
	    unless (defined $::pinfo{$p}{$d}) {
		$::pinfo{$p}{$d} = $default{$d};
	    }
	}

	## Scenario format
	if ($::pinfo{$p}{'scenario'}) {
	    $::pinfo{$p}{'format'} = &tools::get_regexp('scenario');
	    $::pinfo{$p}{'default'} = 'default';
	}

	## Task format
	if ($::pinfo{$p}{'task'}) {
	    $::pinfo{$p}{'format'} = &tools::get_regexp('task');
	}

	## Datasource format
	if ($::pinfo{$p}{'datasource'}) {
	    $::pinfo{$p}{'format'} = &tools::get_regexp('datasource');
	}

	## Enumeration
	if (ref ($::pinfo{$p}{'format'}) eq 'ARRAY') {
	    $::pinfo{$p}{'file_format'} ||= join '|', @{$::pinfo{$p}{'format'}};
	}


	## Set 'format' as default for 'file_format'
	$::pinfo{$p}{'file_format'} ||= $::pinfo{$p}{'format'};
	
	if (($::pinfo{$p}{'occurrence'} =~ /n$/) 
	    && $::pinfo{$p}{'split_char'}) {
	    my $format = $::pinfo{$p}{'file_format'};
	    my $char = $::pinfo{$p}{'split_char'};
	    $::pinfo{$p}{'file_format'} = "($format)*(\\s*$char\\s*($format))*";
	}


	next unless ((ref $::pinfo{$p}{'format'} eq 'HASH')
		     && (ref $::pinfo{$p}{'file_format'} eq 'HASH'));
	
	## Parameter is a Paragraph)
	foreach my $k (keys %{$::pinfo{$p}{'format'}}) {
	    ## Defaults
	    foreach my $d (keys %default) {
		unless (defined $::pinfo{$p}{'format'}{$k}{$d}) {
		    $::pinfo{$p}{'format'}{$k}{$d} = $default{$d};
		}
	    }
	    
	    ## Scenario format
	    if (ref($::pinfo{$p}{'format'}{$k}) && $::pinfo{$p}{'format'}{$k}{'scenario'}) {
		$::pinfo{$p}{'format'}{$k}{'format'} = &tools::get_regexp('scenario');
		$::pinfo{$p}{'format'}{$k}{'default'} = 'default' unless (($p eq 'web_archive') && ($k eq 'access'));
	    }

	    ## Task format
	    if (ref($::pinfo{$p}{'format'}{$k}) && $::pinfo{$p}{'format'}{$k}{'task'}) {
		$::pinfo{$p}{'format'}{$k}{'format'} = &tools::get_regexp('task');
	    }

	    ## Datasource format
	    if (ref($::pinfo{$p}{'format'}{$k}) && $::pinfo{$p}{'format'}{$k}{'datasource'}) {
		$::pinfo{$p}{'format'}{$k}{'format'} = &tools::get_regexp('datasource');
	    }

	    ## Enumeration
	    if (ref ($::pinfo{$p}{'format'}{$k}{'format'}) eq 'ARRAY') {
		$::pinfo{$p}{'file_format'}{$k}{'file_format'} ||= join '|', @{$::pinfo{$p}{'format'}{$k}{'format'}};
	    }

	    
	    if (($::pinfo{$p}{'file_format'}{$k}{'occurrence'} =~ /n$/) 
		&& $::pinfo{$p}{'file_format'}{$k}{'split_char'}) {
		my $format = $::pinfo{$p}{'file_format'}{$k}{'file_format'};
		my $char = $::pinfo{$p}{'file_format'}{$k}{'split_char'};
		$::pinfo{$p}{'file_format'}{$k}{'file_format'} = "($format)*(\\s*$char\\s*($format))*";
	    }

	}

	next unless (ref $::pinfo{$p}{'file_format'} eq 'HASH');

	foreach my $k (keys %{$::pinfo{$p}{'file_format'}}) {
	    ## Set 'format' as default for 'file_format'
	    $::pinfo{$p}{'file_format'}{$k}{'file_format'} ||= $::pinfo{$p}{'file_format'}{$k}{'format'};
	}
    }

    ## Default for user_data_source is 'file'
    ## if not using a RDBMS
    if ($SDM::use_db) {
	$::pinfo{'user_data_source'}{'default'} = 'include2';
    }else {
	$::pinfo{'user_data_source'}{'default'} = 'file';
    }
    
    return \%::pinfo;
}

## Save a parameter
sub _save_list_param {
    my ($key, $p, $defaults, $fd) = @_;
    &Log::do_log('debug3', '_save_list_param(%s)', $key);

    ## Ignore default value
    return 1 if ($defaults == 1);
#    next if ($defaults == 1);

    return 1 unless (defined ($p));
#    next  unless (defined ($p));

    if (defined ($::pinfo{$key}{'scenario'}) ||
        defined ($::pinfo{$key}{'task'}) ) {
	return 1 if ($p->{'name'} eq 'default');

	$fd->print(sprintf "%s %s\n", $key, $p->{'name'});
	$fd->print("\n");

    }elsif (ref($::pinfo{$key}{'file_format'})) {
	$fd->print(sprintf "%s\n", $key);
	foreach my $k (keys %{$p}) {

	    if (defined ($::pinfo{$key}{'file_format'}{$k}{'scenario'}) ) {
		## Skip if empty value
		next if ($p->{$k}{'name'} =~ /^\s*$/);

		$fd->print(sprintf "%s %s\n", $k, $p->{$k}{'name'});

	    }elsif (($::pinfo{$key}{'file_format'}{$k}{'occurrence'} =~ /n$/)
		    && $::pinfo{$key}{'file_format'}{$k}{'split_char'}) {
		
		$fd->print(sprintf "%s %s\n", $k, join($::pinfo{$key}{'file_format'}{$k}{'split_char'}, @{$p->{$k}}));
	    }else {
		## Skip if empty value
		next if ($p->{$k} =~ /^\s*$/);

		$fd->print(sprintf "%s %s\n", $k, $p->{$k});
	    }
	}
	$fd->print("\n");

    }else {
	if (($::pinfo{$key}{'occurrence'} =~ /n$/)
	    && $::pinfo{$key}{'split_char'}) {
	    ################" avant de debugger do_edit_list qui crée des nouvelles entrées vides
 	    my $string = join($::pinfo{$key}{'split_char'}, @{$p});
 	    $string =~ s/\,\s*$//;
	    
 	    $fd->print(sprintf "%s %s\n\n", $key, $string);
	}elsif ($key eq 'digest') {
	    my $value = sprintf '%s %d:%d', join(',', @{$p->{'days'}})
		,$p->{'hour'}, $p->{'minute'};
	    $fd->print(sprintf "%s %s\n\n", $key, $value);
	}else {
	    $fd->print(sprintf "%s %s\n\n", $key, $p);
	}
    }
    
    return 1;
}

## Load a single line
sub _load_list_param {
    my ($robot,$key, $value, $p, $directory) = @_;
    &Log::do_log('debug3','_load_list_param(%s,\'%s\',\'%s\')', $robot,$key, $value);
    
    ## Empty value
    if ($value =~ /^\s*$/) {
	return undef;
    }

    ## Default
    if ($value eq 'default') {
	$value = $p->{'default'};
    }

    ## Search configuration file
    if (ref($value) && defined $value->{'conf'}) {
	$value = &Conf::get_robot_conf($robot, $value->{'conf'});
    }

    ## Synonyms
    if (defined $p->{'synonym'}{$value}) {
	$value = $p->{'synonym'}{$value};
    }

    ## Include mode should not be used anymore
    ## Change value to include2 to shift to new behavior
    if ($key eq 'user_data_source' && $value eq 'include') {
	$value = 'include2';
    }

    ## Scenario
    if ($p->{'scenario'}) {
	$value =~ y/,/_/;
	my $scenario = new Scenario ('function' => $p->{'scenario'},
				     'robot' => $robot, 
				     'name' => $value, 
				     'directory' => $directory);

	## We store the path of the scenario in the sstructure
	## Later &Scenario::request_action() will look for the scenario in %Scenario::all_scenarios through Scenario::new()
	$value = {'file_path' => $scenario->{'file_path'},
		  'name' => $scenario->{'name'}};
    }elsif ($p->{'task'}) {
	$value = {'name' => $value};
    }

    ## Do we need to split param if it is not already an array
    if (($p->{'occurrence'} =~ /n$/)
	&& $p->{'split_char'}
	&& !(ref($value) eq 'ARRAY')) {
	my @array = split /$p->{'split_char'}/, $value;
	foreach my $v (@array) {
	    $v =~ s/^\s*(.+)\s*$/$1/g;
	}
	
	return \@array;
    }else {
	return $value;
    }
}



## Load the certificat file
sub get_cert {

    my $self = shift;
    my $format = shift;

    ## Default format is PEM (can be DER)
    $format ||= 'pem';

    &Log::do_log('debug2', 'List::load_cert(%s)',$self->{'name'});

    # we only send the encryption certificate: this is what the user
    # needs to send mail to the list; if he ever gets anything signed,
    # it will have the respective cert attached anyways.
    # (the problem is that netscape, opera and IE can't only
    # read the first cert in a file)
    my($certs,$keys) = tools::smime_find_keys($self->{dir},'encrypt');

    my @cert;
    if ($format eq 'pem') {
	unless(open(CERT, $certs)) {
	    &Log::do_log('err', "List::get_cert(): Unable to open $certs: $!");
	    return undef;
	}
	
	my $state;
	while(<CERT>) {
	    chomp;
	    if($state == 1) {
		# convert to CRLF for windows clients
		push(@cert, "$_\r\n");
		if(/^-+END/) {
		    pop @cert;
		    last;
		}
	    }elsif (/^-+BEGIN/) {
		$state = 1;
	    }
	}
	close CERT ;
    }elsif ($format eq 'der') {
	unless (open CERT, "$Conf::Conf{'openssl'} x509 -in $certs -outform DER|") {
	    &Log::do_log('err', "$Conf::Conf{'openssl'} x509 -in $certs -outform DER|");
	    &Log::do_log('err', "List::get_cert(): Unable to open get $certs in DER format: $!");
	    return undef;
	}

	@cert = <CERT>;
	close CERT;
    }else {
	do_log('err', "List::get_cert(): unknown '$format' certificate format");
	return undef;
    }
    
    return @cert;
}

## Load a config file of a list
sub _load_list_config_file {
    my ($directory,$robot, $file) = @_;
    &Log::do_log('debug3', '(%s, %s, %s)', $directory, $robot, $file);

    my $config_file = $directory.'/'.$file;

    my %admin;
    my (@paragraphs);

    ## Just in case...
    local $/ = "\n";

    ## Set defaults to 1
    foreach my $pname (keys %::pinfo) {
	$admin{'defaults'}{$pname} = 1 unless ($::pinfo{$pname}{'internal'});
    }

    ## Lock file
    my $lock = new Lock ($config_file);
    unless (defined $lock) {
	&Log::do_log('err','Could not create new lock on %s',$config_file);
	return undef;
    }
    $lock->set_timeout(5); 
    unless ($lock->lock('read')) {
	&Log::do_log('err','Could not put a read lock on the config file %s',$config_file);
	return undef;
    }   

    unless (open CONFIG, "<", $config_file) {
	&Log::do_log('info', 'Cannot open %s', $config_file);
    }

    ## Split in paragraphs
    my $i = 0;
    while (<CONFIG>) {
	if (/^\s*$/) {
	    $i++ if $paragraphs[$i];
	}else {
	    push @{$paragraphs[$i]}, $_;
	}
    }

    for my $index (0..$#paragraphs) {
	my @paragraph = @{$paragraphs[$index]};

	my $pname;

	## Clean paragraph, keep comments
	for my $i (0..$#paragraph) {
	    my $changed = undef;
	    for my $j (0..$#paragraph) {
		if ($paragraph[$j] =~ /^\s*\#/) {
		    chomp($paragraph[$j]);
		    push @{$admin{'comment'}}, $paragraph[$j];
		    splice @paragraph, $j, 1;
		    $changed = 1;
		}elsif ($paragraph[$j] =~ /^\s*$/) {
		    splice @paragraph, $j, 1;
		    $changed = 1;
		}

		last if $changed;
	    }

	    last unless $changed;
	}

	## Empty paragraph
	next unless ($#paragraph > -1);
	
	## Look for first valid line
	unless ($paragraph[0] =~ /^\s*([\w-]+)(\s+.*)?$/) {
	    &Log::do_log('err', 'Bad paragraph "%s" in %s, ignore it', @paragraph, $config_file);
	    next;
	}
	    
	$pname = $1;

	## Parameter aliases (compatibility concerns)
	if (defined $alias{$pname}) {
	    $paragraph[0] =~ s/^\s*$pname/$alias{$pname}/;
	    $pname = $alias{$pname};
	}
	
	unless (defined $::pinfo{$pname}) {
	    &Log::do_log('err', 'Unknown parameter "%s" in %s, ignore it', $pname, $config_file);
	    next;
	}

	## Uniqueness
	if (defined $admin{$pname}) {
	    unless (($::pinfo{$pname}{'occurrence'} eq '0-n') or
		    ($::pinfo{$pname}{'occurrence'} eq '1-n')) {
		&Log::do_log('err', 'Multiple occurences of a unique parameter "%s" in %s', $pname, $config_file);
	    }
	}
	
	## Line or Paragraph
	if (ref $::pinfo{$pname}{'file_format'} eq 'HASH') {
	    ## This should be a paragraph
	    unless ($#paragraph > 0) {
		&Log::do_log('err', 'Expecting a paragraph for "%s" parameter in %s, ignore it', $pname, $config_file);
		next;
	    }
	    
	    ## Skipping first line
	    shift @paragraph;

	    my %hash;
	    for my $i (0..$#paragraph) {	    
		next if ($paragraph[$i] =~ /^\s*\#/);
		
		unless ($paragraph[$i] =~ /^\s*(\w+)\s*/) {
		    &Log::do_log('err', 'Bad line "%s" in %s',$paragraph[$i], $config_file);
		}
		
		my $key = $1;
		
		unless (defined $::pinfo{$pname}{'file_format'}{$key}) {
		    &Log::do_log('err', 'Unknown key "%s" in paragraph "%s" in %s', $key, $pname, $config_file);
		    next;
		}
		
		unless ($paragraph[$i] =~ /^\s*$key\s+($::pinfo{$pname}{'file_format'}{$key}{'file_format'})\s*$/i) {
		    &Log::do_log('err', 'Bad entry "%s" in paragraph "%s" in %s', $paragraph[$i], $key, $pname, $config_file);
		    next;
		}

		$hash{$key} = &_load_list_param($robot,$key, $1, $::pinfo{$pname}{'file_format'}{$key}, $directory);
	    }

	    ## Apply defaults & Check required keys
	    my $missing_required_field;
	    foreach my $k (keys %{$::pinfo{$pname}{'file_format'}}) {

		## Default value
		unless (defined $hash{$k}) {
		    if (defined $::pinfo{$pname}{'file_format'}{$k}{'default'}) {
			$hash{$k} = &_load_list_param($robot,$k, 'default', $::pinfo{$pname}{'file_format'}{$k}, $directory);
		    }
		}

		## Required fields
		if ($::pinfo{$pname}{'file_format'}{$k}{'occurrence'} eq '1') {
		    unless (defined $hash{$k}) {
			&Log::do_log('info', 'Missing key "%s" in param "%s" in %s', $k, $pname, $config_file);
			$missing_required_field++;
		    }
		}
	    }

	    next if $missing_required_field;

	    delete $admin{'defaults'}{$pname};

	    ## Should we store it in an array
	    if (($::pinfo{$pname}{'occurrence'} =~ /n$/)) {
		push @{$admin{$pname}}, \%hash;
	    }else {
		$admin{$pname} = \%hash;
	    }
	}else {
	    ## This should be a single line
	    unless ($#paragraph == 0) {
		&Log::do_log('info', 'Expecting a single line for "%s" parameter in %s', $pname, $config_file);
	    }

	    unless ($paragraph[0] =~ /^\s*$pname\s+($::pinfo{$pname}{'file_format'})\s*$/i) {
		&Log::do_log('info', 'Bad entry "%s" in %s', $paragraph[0], $config_file);
		next;
	    }

	    my $value = &_load_list_param($robot,$pname, $1, $::pinfo{$pname}, $directory);

	    delete $admin{'defaults'}{$pname};

	    if (($::pinfo{$pname}{'occurrence'} =~ /n$/)
		&& ! (ref ($value) =~ /^ARRAY/)) {
		push @{$admin{$pname}}, $value;
	    }else {
		$admin{$pname} = $value;
	    }
	}
    }
    
    close CONFIG;

    ## Release the lock
    unless ($lock->unlock()) {
	&Log::do_log('err', 'Could not remove the read lock on file %s',$config_file);
	return undef;
    }

    ## Apply defaults & check required parameters
    foreach my $p (keys %::pinfo) {

	## Defaults
	unless (defined $admin{$p}) {

	    ## Simple (versus structured) parameter case
	    if (defined $::pinfo{$p}{'default'}) {
		$admin{$p} = &_load_list_param($robot,$p, $::pinfo{$p}{'default'}, $::pinfo{$p}, $directory);

	    ## Sructured parameters case : the default values are defined at the next level
	    }elsif ((ref $::pinfo{$p}{'format'} eq 'HASH')
		    && ($::pinfo{$p}{'occurrence'} =~ /1$/)) {
		## If the paragraph is not defined, try to apply defaults
		my $hash;
		
		foreach my $key (keys %{$::pinfo{$p}{'format'}}) {

		    ## Skip keys without default value.
		    unless (defined $::pinfo{$p}{'format'}{$key}{'default'}) {
			next;
		    }
		    
		    $hash->{$key} = &_load_list_param($robot,$key, $::pinfo{$p}{'format'}{$key}{'default'}, $::pinfo{$p}{'format'}{$key}, $directory);
		}

		$admin{$p} = $hash if (defined $hash);

	    }

#	    $admin{'defaults'}{$p} = 1;
	}
	
	## Required fields
	if ($::pinfo{$p}{'occurrence'} =~ /^1(-n)?$/ ) {
	    unless (defined $admin{$p}) {
		&Log::do_log('info','Missing parameter "%s" in %s', $p, $config_file);
	    }
	}
    }

    ## "Original" parameters
    if (defined ($admin{'digest'})) {
	if ($admin{'digest'} =~ /^(.+)\s+(\d+):(\d+)$/) {
	    my $digest = {};
	    $digest->{'hour'} = $2;
	    $digest->{'minute'} = $3;
	    my $days = $1;
	    $days =~ s/\s//g;
	    @{$digest->{'days'}} = split /,/, $days;

	    $admin{'digest'} = $digest;
	}
    }
    # The 'host' parameter is ignored if the list is stored on a 
    #  virtual robot directory
   
    # $admin{'host'} = $self{'domain'} if ($self{'dir'} ne '.'); 

	
    if (defined ($admin{'custom_subject'})) {
	if ($admin{'custom_subject'} =~ /^\s*\[\s*(\w+)\s*\]\s*$/) {
	    $admin{'custom_subject'} = $1;
	}
    }

    ## Format changed for reply_to parameter
    ## New reply_to_header parameter
    if (($admin{'forced_reply_to'} && ! $admin{'defaults'}{'forced_reply_to'}) ||
	($admin{'reply_to'} && ! $admin{'defaults'}{'reply_to'})) {
	my ($value, $apply, $other_email);
	$value = $admin{'forced_reply_to'} || $admin{'reply_to'};
	$apply = 'forced' if ($admin{'forced_reply_to'});
	if ($value =~ /\@/) {
	    $other_email = $value;
	    $value = 'other_email';
	}

	$admin{'reply_to_header'} = {'value' => $value,
				     'other_email' => $other_email,
				     'apply' => $apply};

	## delete old entries
	$admin{'reply_to'} = undef;
	$admin{'forced_reply_to'} = undef;
    }

    ############################################
    ## Bellow are constraints between parameters
    ############################################

    ## Subscription and unsubscribe add and del are closed 
    ## if subscribers are extracted via external include method
    ## (current version external method are SQL or LDAP query
    if ($admin{'user_data_source'} eq 'include') {
	foreach my $p ('subscribe','add','invite','unsubscribe','del') {
	    $admin{$p} = &_load_list_param($robot,$p, 'closed', $::pinfo{$p}, 'closed', $directory);
	}

    }

    ## Do we have a database config/access
    if (($admin{'user_data_source'} eq 'database') ||
	($admin{'user_data_source'} eq 'include2')){
	unless ($SDM::use_db) {
	    &Log::do_log('info', 'Sympa not setup to use DBI or no database access');
	    ## We should notify the listmaster here...
	    #return undef;
	}
    }

    ## This default setting MUST BE THE LAST ONE PERFORMED
#    if ($admin{'status'} ne 'open') {
#	## requested and closed list are just list hidden using visibility parameter
#	## and with send parameter set to closed.
#	$admin{'send'} = &_load_list_param('.','send', 'closed', $::pinfo{'send'}, $directory);
#	$admin{'visibility'} = &_load_list_param('.','visibility', 'conceal', $::pinfo{'visibility'}, $directory);
#    }

    ## reception of default_user_options must be one of reception of
    ## available_user_options. If none, warning and put reception of
    ## default_user_options in reception of available_user_options
    if (! grep (/^$admin{'default_user_options'}{'reception'}$/,
		@{$admin{'available_user_options'}{'reception'}})) {
      push @{$admin{'available_user_options'}{'reception'}}, $admin{'default_user_options'}{'reception'};
      &Log::do_log('info','reception is not compatible between default_user_options and available_user_options in %s',$directory);
    }

    return \%admin;
}

## Save a config file
sub _save_list_config_file {
    my ($config_file, $old_config_file, $admin) = @_;
    &Log::do_log('debug3', '(%s, %s, %s)', $config_file,$old_config_file, $admin);

    unless (rename $config_file, $old_config_file) {
	&Log::do_log('notice', 'Cannot rename %s to %s', $config_file, $old_config_file);
	return undef;
    }

    unless (open CONFIG, ">", $config_file) {
	&Log::do_log('info', 'Cannot open %s', $config_file);
	return undef;
    }
    my $config = '';
    my $fd = new IO::Scalar \$config;
    
    foreach my $c (@{$admin->{'comment'}}) {
	$fd->print(sprintf "%s\n", $c);
    }
    $fd->print("\n");

    foreach my $key (sort by_order keys %{$admin}) {

	next if ($key =~ /^(comment|defaults)$/);
	next unless (defined $admin->{$key});

	## Multiple parameter (owner, custom_header,...)
	if ((ref ($admin->{$key}) eq 'ARRAY') &&
	    ! $::pinfo{$key}{'split_char'}) {
	    foreach my $elt (@{$admin->{$key}}) {
		&_save_list_param($key, $elt, $admin->{'defaults'}{$key}, $fd);
	    }
	}else {
	    &_save_list_param($key, $admin->{$key}, $admin->{'defaults'}{$key}, $fd);
	}

    }
    print CONFIG $config;
    close CONFIG;

    return 1;
}

# Is a reception mode in the parameter reception of the available_user_options
# section?
sub is_available_reception_mode {
  my ($self,$mode) = @_;
  $mode =~ y/[A-Z]/[a-z]/;
  
  return undef unless ($self && $mode);

  my @available_mode = @{$self->{'admin'}{'available_user_options'}{'reception'}};
  
  foreach my $m (@available_mode) {
    if ($m eq $mode) {
      return $mode;
    }
  }

  return undef;
}

# List the parameter reception of the available_user_options section 
sub available_reception_mode {
  my $self = shift;
  
  return join (' ',@{$self->{'admin'}{'available_user_options'}{'reception'}});
}

########################################################################################
#                       FUNCTIONS FOR MESSAGE TOPICS                                   #
########################################################################################
#                                                                                      #
#                                                                                      #


####################################################
# is_there_msg_topic
####################################################
#  Test if some msg_topic are defined
# 
# IN : -$self (+): ref(List)
#      
# OUT : 1 - some are defined | 0 - not defined
####################################################
sub is_there_msg_topic {
    my ($self) = shift;
    
    if (defined $self->{'admin'}{'msg_topic'}) {
	if (ref($self->{'admin'}{'msg_topic'}) eq "ARRAY") {
	    if ($#{$self->{'admin'}{'msg_topic'}} >= 0) {
		return 1;
	    }
	}
    }
    return 0;
}

 
####################################################
# is_available_msg_topic
####################################################
#  Checks for a topic if it is available in the list
# (look foreach list parameter msg_topic.name)
# 
# IN : -$self (+): ref(List)
#      -$topic (+): string
# OUT : -$topic if it is available  | undef
####################################################
sub is_available_msg_topic {
    my ($self,$topic) = @_;
    
    my @available_msg_topic;
    foreach my $msg_topic (@{$self->{'admin'}{'msg_topic'}}) {
	return $topic
	    if ($msg_topic->{'name'} eq $topic);
    }
    
    return undef;
}


####################################################
# get_available_msg_topic
####################################################
#  Return an array of available msg topics (msg_topic.name)
# 
# IN : -$self (+): ref(List)
#
# OUT : -\@topics : ref(ARRAY)
####################################################
sub get_available_msg_topic {
    my ($self) = @_;
    
    my @topics;
    foreach my $msg_topic (@{$self->{'admin'}{'msg_topic'}}) {
	if ($msg_topic->{'name'}) {
	    push @topics,$msg_topic->{'name'};
	}
    }
    
    return \@topics;
}

####################################################
# is_msg_topic_tagging_required
####################################################
# Checks for the list parameter msg_topic_tagging
# if it is set to 'required'
#
# IN : -$self (+): ref(List)
#
# OUT : 1 - the msg must must be tagged 
#       | 0 - the msg can be no tagged
####################################################
sub is_msg_topic_tagging_required {
    my ($self) = @_;
    
    if ($self->{'admin'}{'msg_topic_tagging'} =~ /required/) {
	return 1;
    } else {
	return 0;
    }
}

####################################################
# automatic_tag
####################################################
#  Compute the topic(s) of the message and tag it.
#
# IN : -$self (+): ref(List)
#      -$msg (+): ref(MIME::Entity)
#      -$robot (+): robot
#
# OUT : string of tag(s), can be separated by ',', can be empty
#        | undef 
####################################################
sub automatic_tag {
    my ($self,$msg,$robot) = @_;
    my $msg_id = $msg->head->get('Message-ID');
    chomp($msg_id);
    &Log::do_log('debug3','automatic_tag(%s,%s)',$self->{'name'},$msg_id);


    my $topic_list = $self->compute_topic($msg,$robot);

    if ($topic_list) {
	my $filename = $self->tag_topic($msg_id,$topic_list,'auto');

	unless ($filename) {
	    &Log::do_log('err','Unable to tag message %s with topic "%s"',$msg_id,$topic_list);
	    return undef;
	}
    } 
	
    return $topic_list;
}


####################################################
# compute_topic
####################################################
#  Compute the topic of the message. The topic is got
#  from applying a regexp on the message, regexp 
#  based on keywords defined in list_parameter
#  msg_topic.keywords. The regexp is applied on the 
#  subject and/or the body of the message according
#  to list parameter msg_topic_keywords_apply_on
#
# IN : -$self (+): ref(List)
#      -$msg (+): ref(MIME::Entity)
#      -$robot(+) : robot
#
# OUT : string of tag(s), can be separated by ',', can be empty
####################################################
sub compute_topic {
    my ($self,$msg,$robot) = @_;
    my $msg_id = $msg->head->get('Message-ID');
    chomp($msg_id);
    &Log::do_log('debug3','compute_topic(%s,%s)',$self->{'name'},$msg_id);
    my @topic_array;
    my %topic_hash;
    my %keywords;


    ## TAGGING INHERITED BY THREAD
    # getting reply-to
    my $reply_to = $msg->head->get('In-Reply-To');
    $reply_to =  &tools::clean_msg_id($reply_to);
    my $info_msg_reply_to = $self->load_msg_topic_file($reply_to,$robot);

    # is msg reply to already tagged?	
    if (ref($info_msg_reply_to) eq "HASH") { 
	return $info_msg_reply_to->{'topic'};
    }
     


    ## TAGGING BY KEYWORDS
    # getting keywords
    foreach my $topic (@{$self->{'admin'}{'msg_topic'}}) {

	my $list_keyw = &tools::get_array_from_splitted_string($topic->{'keywords'});

	foreach my $keyw (@{$list_keyw}) {
	    $keywords{$keyw} = $topic->{'name'}
	}
    }

    # getting string to parse
    # We convert it to Unicode for case-ignore match with non-ASCII keywords.
    my $mail_string = '';
    if ($self->{'admin'}{'msg_topic_keywords_apply_on'} eq 'subject'){
	$mail_string = &MIME::EncWords::decode_mimewords($msg->head->get('subject'), Charset=>'_UNICODE_')."\n";
    }
    unless ($self->{'admin'}{'msg_topic_keywords_apply_on'} eq 'subject') {
	# get bodies of any text/* parts, not digging nested subparts.
	my @parts;
	if ($msg->effective_type =~ /^(multipart|message)\//i) {
	    @parts = $msg->parts();
	} else {
	    @parts = ($msg);
	}
	foreach my $part (@parts) {
	    next unless $part->effective_type =~ /^text\//i;
	    my $charset = $part->head->mime_attr("Content-Type.Charset");
	    $charset = MIME::Charset->new($charset);
	    if (defined $part->bodyhandle) {
		my $body = $msg->bodyhandle->as_string();
		my $converted;
		eval {
		    $converted = $charset->decode($body);
		};
		if ($@) {
		    $converted = Encode::decode('US-ASCII', $body);
		}
		$mail_string .= $converted."\n";
	    }
	}
    }

    # parsing
    foreach my $keyw (keys %keywords) {
	my $k = $keywords{$keyw};
	$keyw = Encode::decode_utf8($keyw);
	$keyw = &tools::escape_regexp($keyw);
	if ($mail_string =~ /$keyw/i){
	    $topic_hash{$k} = 1;
	}
    }


    
    # for no double
    foreach my $k (keys %topic_hash) {
	push @topic_array,$k if ($topic_hash{$k});
    }
    
    if ($#topic_array <0) {
	return '';

    } else {
	return (join(',',@topic_array));
    }
}

####################################################
# tag_topic
####################################################
#  tag the message by creating the msg topic file
# 
# IN : -$self (+): ref(List)
#      -$msg_id (+): string, msg_id of the msg to tag
#      -$topic_list (+): string (splitted by ',')
#      -$method (+) : 'auto'|'editor'|'sender'
#         the method used for tagging
#
# OUT : string - msg topic filename
#       | undef
####################################################
sub tag_topic {
    my ($self,$msg_id,$topic_list,$method) = @_;
    &Log::do_log('debug3','tag_topic(%s,%s,"%s",%s)',$self->{'name'},$msg_id,$topic_list,$method);

    my $robot = $self->{'domain'};
    my $queuetopic = &Conf::get_robot_conf($robot, 'queuetopic');
    my $list_id = $self->get_list_id();
    $msg_id = &tools::clean_msg_id($msg_id);
    $msg_id =~ s/>$//;
    my $file = $list_id.'.'.$msg_id;

    unless (open (FILE, ">$queuetopic/$file")) {
	&Log::do_log('info','Unable to create msg topic file %s/%s : %s', $queuetopic,$file, $!);
	return undef;
    }

    print FILE "TOPIC   $topic_list\n";
    print FILE "METHOD  $method\n";

    close FILE;

    return "$queuetopic/$file";
}



####################################################
# load_msg_topic_file
####################################################
#  Looks for a msg topic file from the msg_id of 
# the message, loads it and return contained information 
# in a HASH
#
# IN : -$self (+): ref(List)
#      -$msg_id (+): the message ID 
#      -$robot (+): the robot
#
# OUT : ref(HASH) file contents : 
#         - topic : string - list of topic name(s)
#         - method : editor|sender|auto - method used to tag
#         - msg_id : the msg_id
#         - filename : name of the file containing this information 
#     | undef 
####################################################
sub load_msg_topic_file {
    my ($self,$msg_id,$robot) = @_;
    $msg_id = &tools::clean_msg_id($msg_id);
    &Log::do_log('debug3','List::load_msg_topic_file(%s,%s)',$self->{'name'},$msg_id);
    
    my $queuetopic = &Conf::get_robot_conf($robot, 'queuetopic');
    my $list_id = $self->get_list_id();
    my $file = "$list_id.$msg_id";
    
    unless (open (FILE, "$queuetopic/$file")) {
	&Log::do_log('debug','No topic define ; unable to open %s/%s : %s', $queuetopic,$file, $!);
	return undef;
    }
    
    my %info = ();
    
    while (<FILE>) {
	next if /^\s*(\#.*|\s*)$/;
	
	if (/^(\S+)\s+(.+)$/io) {
	    my($keyword, $value) = ($1, $2);
	    $value =~ s/\s*$//;
	    
	    if ($keyword eq 'TOPIC') {
		$info{'topic'} = $value;
		
	    }elsif ($keyword eq 'METHOD') {
		if ($value =~ /^(editor|sender|auto)$/) {
		    $info{'method'} = $value;
		}else {
		    &Log::do_log('err','List::load_msg_topic_file(%s,%s): syntax error in file %s/%s : %s', $queuetopic,$file, $!);
		    return undef;
		}
	    }
	}
    }
    close FILE;
    
    if ((exists $info{'topic'}) && (exists $info{'method'})) {
	$info{'msg_id'} = $msg_id;
	$info{'filename'} = $file;
	
	return \%info;
    }
    return undef;
}


####################################################
# modifying_msg_topic_for_list_members()
####################################################
#  Deletes topics subscriber that does not exist anymore
#  and send a notify to concerned subscribers.
# 
# IN : -$self (+): ref(List)
#      -$new_msg_topic (+): ref(ARRAY) - new state 
#        of msg_topic parameters
#
# OUT : -0 if no subscriber topics have been deleted
#       -1 if some subscribers topics have been deleted 
##################################################### 
sub modifying_msg_topic_for_list_members(){
    my ($self,$new_msg_topic) = @_;
    &Log::do_log('debug3',"($self->{'name'}");
    my $deleted = 0;

    my @old_msg_topic_name;
    foreach my $msg_topic (@{$self->{'admin'}{'msg_topic'}}) {
	push @old_msg_topic_name,$msg_topic->{'name'};
    }

    my @new_msg_topic_name;
    foreach my $msg_topic (@{$new_msg_topic}) {
	push @new_msg_topic_name,$msg_topic->{'name'};
    }

    my $msg_topic_changes = &tools::diff_on_arrays(\@old_msg_topic_name,\@new_msg_topic_name);

    if ($#{$msg_topic_changes->{'deleted'}} >= 0) {
	
	for (my $subscriber=$self->get_first_list_member(); $subscriber; $subscriber=$self->get_next_list_member()) {
	    
	    if ($subscriber->{'reception'} eq 'mail') {
		my $topics = &tools::diff_on_arrays($msg_topic_changes->{'deleted'},&tools::get_array_from_splitted_string($subscriber->{'topics'}));
		
		if ($#{$topics->{'intersection'}} >= 0) {
		    my $wwsympa_url = &Conf::get_robot_conf($self->{'domain'}, 'wwsympa_url');
		    unless ($self->send_notify_to_user('deleted_msg_topics',$subscriber->{'email'},
						       {'del_topics' => $topics->{'intersection'},
							'url' => $wwsympa_url.'/suboptions/'.$self->{'name'}})) {
			&Log::do_log('err',"($self->{'name'}) : impossible to send notify to user about 'deleted_msg_topics'");
		    }
		    unless ($self->update_list_member(lc($subscriber->{'email'}), 
					       {'update_date' => time,
						'topics' => join(',',@{$topics->{'added'}})})) {
			&Log::do_log('err',"($self->{'name'} : impossible to update user '$subscriber->{'email'}'");
		    }
		    $deleted = 1;
		}
	    }
	}
    }
    return 1 if ($deleted);
    return 0;
}

####################################################
# select_list_members_for_topic
####################################################
# Select users subscribed to a topic that is in
# the topic list incoming when reception mode is 'mail', 'notice', 'not_me', 'txt', 'html' or 'urlize', and the other
# subscribers (recpetion mode different from 'mail'), 'mail' and no topic subscription
# 
# IN : -$self(+) : ref(List)
#      -$string_topic(+) : string splitted by ','
#                          topic list
#      -$subscribers(+) : ref(ARRAY) - list of subscribers(emails)
#
# OUT : @selected_users
#     
#
####################################################
sub select_list_members_for_topic {
    my ($self,$string_topic,$subscribers) = @_;
    &Log::do_log('debug3', '(%s, %s)', $self->{'name'},$string_topic); 
    
    my @selected_users;
    my $msg_topics;

    if ($string_topic) {
	$msg_topics = &tools::get_array_from_splitted_string($string_topic);
    }

    foreach my $user (@$subscribers) {

	# user topic
	my $info_user = $self->get_list_member($user);

	if ($info_user->{'reception'} !~ /^(mail|notice|not_me|txt|html|urlize)$/i) {
	    push @selected_users,$user;
	    next;
	}
	unless ($info_user->{'topics'}) {
	    push @selected_users,$user;
	    next;
	}
	my $user_topics = &tools::get_array_from_splitted_string($info_user->{'topics'});

	if ($string_topic) {
	    my $result = &tools::diff_on_arrays($msg_topics,$user_topics);
	    if ($#{$result->{'intersection'}} >=0 ) {
		push @selected_users,$user;
	    }
	}else {
	    my $result = &tools::diff_on_arrays(['other'],$user_topics);
	    if ($#{$result->{'intersection'}} >=0 ) {
		push @selected_users,$user;
	    }
	}
    }
    return @selected_users;
}

#                                                                                         #
#                                                                                         # 
#                                                                                         #
########## END - functions for message topics #############################################




sub _urlize_part {
    my $message = shift;
    my $list = shift;
    my $expl = $list->{'dir'}.'/urlized';
    my $robot = $list->{'domain'};
    my $dir = shift;
    my $i = shift;
    my $mime_types = shift;
    my $listname = $list->{'name'};
    my $wwsympa_url = shift;

    my $head = $message->head ;
    my $encoding = $head->mime_encoding ;

    ##  name of the linked file
    my $fileExt = $mime_types->{$head->mime_type};
    if ($fileExt) {
	$fileExt = '.'.$fileExt;
    }
    my $filename;

    if ($head->recommended_filename) {
	$filename = $head->recommended_filename;
    } else {
        $filename ="msg.$i".$fileExt;
    }
  
    ##create the linked file 	
    ## Store body in file 
    if (open OFILE, ">$expl/$dir/$filename") {
	my @ct = split(/;/,$head->get('Content-type'));
	chomp ($ct[0]); 
   	printf OFILE "Content-type: %s\n\n", $ct[0];
    } else {
	&Log::do_log('notice', "Unable to open $expl/$dir/$filename") ;
	return undef ; 
    }
    
    if ($encoding =~ /^(binary|7bit|8bit|base64|quoted-printable|x-uu|x-uuencode|x-gzip64)$/ ) {
	open TMP, ">$expl/$dir/$filename.$encoding";
	$message->print_body (\*TMP);
	close TMP;

	open BODY, "$expl/$dir/$filename.$encoding";
	my $decoder = new MIME::Decoder $encoding;
	$decoder->decode(\*BODY, \*OFILE);
	unlink "$expl/$dir/$filename.$encoding";
    }else {
	$message->print_body (\*OFILE) ;
    }
    close (OFILE);
    my $file = "$expl/$dir/$filename";
    my $size = (-s $file);

    ## Only URLize files with a moderate size
    if ($size < $Conf::Conf{'urlize_min_size'}) {
	unlink "$expl/$dir/$filename";
	return undef;
    }
	    
    ## Delete files created twice or more (with Content-Type.name and Content-Disposition.filename)
    $message->purge ;	

    (my $file_name = $filename) =~ s/\./\_/g;
    my $file_url = "$wwsympa_url/attach/$listname".&tools::escape_chars("$dir/$filename",'/'); # do NOT escape '/' chars

    my $parser = new MIME::Parser;
    $parser->output_to_core(1);
    my $new_part;

    my $lang = &Language::GetLang();
    my $charset = &Language::GetCharset();

    my $tt2_include_path = &tools::make_tt2_include_path($robot,'mail_tt2',$lang,$list);

    &tt2::parse_tt2({'file_name' => $file_name,
		     'file_url'  => $file_url,
		     'file_size' => $size ,
		     'charset' => $charset},
		    'urlized_part.tt2',
		    \$new_part,
		    $tt2_include_path);

    my $entity = $parser->parse_data(\$new_part);

    return $entity;
}

sub store_subscription_request {
    my ($self, $email, $gecos, $custom_attr) = @_;
    &Log::do_log('debug2', '(%s, %s, %s)', $self->{'name'}, $email, $gecos, $custom_attr);

    my $filename = $Conf::Conf{'queuesubscribe'}.'/'.$self->get_list_id().'.'.time.'.'.int(rand(1000));

    unless (opendir SUBSPOOL, "$Conf::Conf{'queuesubscribe'}") {
	&Log::do_log('err', 'Could not open %s', $Conf::Conf{'queuesubscribe'});
	return undef;
    }
    
    my @req_files = sort grep (!/^\.+$/,readdir(SUBSPOOL));
    closedir SUBSPOOL;

    my $listaddr = $self->{'name'}.'@'.$self->{'domain'};

    foreach my $file (@req_files) {
	next unless ($file =~ /$listaddr\..*/) ;
	unless (open OLDREQUEST, "$Conf::Conf{'queuesubscribe'}/$file") {
	    &Log::do_log('err', 'Could not open %s for verification', $file);
	    return undef;
	}
	foreach my $line (<OLDREQUEST>) {
	    if ($line =~ /^$email/i) {
		&Log::do_log('notice', 'Subscription already requested by %s', $email);
		return undef;
	    }
	}
	close OLDREQUEST;
    }

    unless (open REQUEST, ">$filename") {
	&Log::do_log('notice', 'Could not open %s', $filename);
	return undef;
    }

    ## First line of the file contains the user email address + his/her name
    printf REQUEST "$email\t$gecos\n";

    ## Following lines may contain custom attributes in an XML format
    printf REQUEST "$custom_attr\n";

    close REQUEST;

    return 1;
} 

sub get_subscription_requests {
    my ($self) = shift;
    &Log::do_log('debug2', 'List::get_subscription_requests(%s)', $self->{'name'});

    my %subscriptions;

    unless (opendir SPOOL, $Conf::Conf{'queuesubscribe'}) {
	&Log::do_log('info', 'Unable to read spool %s', $Conf::Conf{'queuesubscribe'});
	return undef;
    }

    foreach my $filename (sort grep(/^$self->{'name'}(\@$self->{'domain'})?\.\d+\.\d+$/, readdir SPOOL)) {
	unless (open REQUEST, "<:bytes", "$Conf::Conf{'queuesubscribe'}/$filename") {
	    &Log::do_log('err', 'Could not open %s', $filename);
	    closedir SPOOL;
	    next;
	}

	## First line of the file contains the user email address + his/her name
	my $line = <REQUEST>;
	my ($email, $gecos);
	if ($line =~ /^((\S+|\".*\")\@\S+)\s*([^\t]*)\t(.*)$/) {
	    ($email, $gecos) = ($1, $3); 
	    
	}else {
	    &Log::do_log('err', "Failed to parse subscription request %s",$filename);
	    next;
	}

	my $user_entry = $self->get_list_member($email, probe => 1);
	 
	if ( defined($user_entry) && ($user_entry->{'subscribed'} == 1)) {
	    &Log::do_log('err','User %s is subscribed to %s already. Deleting subscription request.', $email, $self->{'name'});
	    unless (unlink "$Conf::Conf{'queuesubscribe'}/$filename") {
		&Log::do_log('err', 'Could not delete file %s', $filename);
	    }
	    next;
	}
	## Following lines may contain custom attributes in an XML format
	my %xml = &parseCustomAttribute(\*REQUEST) ;
	close REQUEST;
	
	$subscriptions{$email} = {'gecos' => $gecos,
				  'custom_attribute' => \%xml};
	unless($subscriptions{$email}{'gecos'}) {
		my $user = get_global_user($email);
		if ($user->{'gecos'}) {
			$subscriptions{$email}{'gecos'} = $user->{'gecos'};
		}
	}

	$filename =~ /^$self->{'name'}(\@$self->{'domain'})?\.(\d+)\.\d+$/;
	$subscriptions{$email}{'date'} = $2;
    }
    closedir SPOOL;

    return \%subscriptions;
} 

sub get_subscription_request_count {
    my ($self) = shift;
    &Log::do_log('debug2', 'List::get_subscription_requests_count(%s)', $self->{'name'});

    my %subscriptions;
    my $i = 0 ;

    unless (opendir SPOOL, $Conf::Conf{'queuesubscribe'}) {
	&Log::do_log('info', 'Unable to read spool %s', $Conf::Conf{'queuesubscribe'});
	return undef;
    }

    foreach my $filename (sort grep(/^$self->{'name'}(\@$self->{'domain'})?\.\d+\.\d+$/, readdir SPOOL)) {
	$i++;
    }
    closedir SPOOL;

    return $i;
} 

sub delete_subscription_request {
    my ($self, @list_of_email) = @_;
    &Log::do_log('debug2', 'List::delete_subscription_request(%s, %s)', $self->{'name'}, join(',',@list_of_email));

    my $removed_file = 0;
    my $email_regexp = &tools::get_regexp('email');
    
    unless (opendir SPOOL, $Conf::Conf{'queuesubscribe'}) {
	&Log::do_log('info', 'Unable to read spool %s', $Conf::Conf{'queuesubscribe'});
	return undef;
    }

    foreach my $filename (sort grep(/^$self->{'name'}(\@$self->{'domain'})?\.\d+\.\d+$/, readdir SPOOL)) {
	
	unless (open REQUEST, "$Conf::Conf{'queuesubscribe'}/$filename") {
	    &Log::do_log('notice', 'Could not open %s', $filename);
	    next;
	}
	my $line = <REQUEST>;
	close REQUEST;

	foreach my $email (@list_of_email) {

	    unless ($line =~ /^($email_regexp)\s*/ && ($1 eq $email)) {
		next;
	    }
	    
	    unless (unlink "$Conf::Conf{'queuesubscribe'}/$filename") {
		&Log::do_log('err', 'Could not delete file %s', $filename);
		last;
	    }
	    $removed_file++;
	}
    }

    closedir SPOOL;
    
    unless ($removed_file > 0) {
	&Log::do_log('err', 'No pending subscription was found for users %s', join(',',@list_of_email));
	return undef;
    }

    return 1;
} 


sub get_shared_size {
    my $self = shift;

    return tools::get_dir_size("$self->{'dir'}/shared");
}

sub get_arc_size {
    my $self = shift;
    my $dir = shift;

    return tools::get_dir_size($dir.'/'.$self->get_list_id());
}

# return the date epoch for next delivery planified for a list
sub  get_next_delivery_date {
    my $self = shift;

    my $dtime = $self->{'admin'}{'delivery_time'} ;
    unless ($dtime =~ /(\d?\d)\:(\d\d)/ ) {
	# if delivery _time if not defined, the delivery time right now
	return time();
    }
    my $h = $1;
    my $m = $2;
    unless ((($h == 24)&&($m == 0))||(($h <= 23)&&($m <= 60))){
	&Log::do_log('err',"ignoring wrong parameter format delivery_time, delivery_tile must be smaller than 24:00");
	return time();
    }
    my $date = time();

    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =  localtime($date);

    my $plannified_time = (($h*60)+$m)*60;       # plannified time in sec
    my $now_time = ((($hour*60)+$min)*60)+$sec;  # Now #sec since to day 00:00
    
    my $result = $date - $now_time + $plannified_time;
    ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =  localtime($result);

    if ($now_time <= $plannified_time ) {
	return ( $date - $now_time + $plannified_time) ;
    }else{
	return ( $date - $now_time + $plannified_time + (24*3600)); # plannified time is past so report to tomorrow
    }
}


## Searches the include datasource corresponding to the provided ID
sub search_datasource {
    my ($self, $id) = @_;
    &Log::do_log('debug2','List::search_datasource(%s,%s)', $self->{'name'}, $id);

    ## Go through list parameters
    foreach my $p (keys %{$self->{'admin'}}) {
	next unless ($p =~ /^include/);
	
	## Go through sources
	foreach my $s (@{$self->{'admin'}{$p}}) {
	    if (&Datasource::_get_datasource_id($s) eq $id) {
		return {'type' => $p, 'def' => $s};
	    }
	}
    }

    return undef;
}

## Return the names of datasources, given a coma-separated list of source ids
# IN : -$class 
#      -$id : datasource ids (coma-separated)
# OUT : -$name : datasources names (scalar)
sub get_datasource_name {
    my ($self, $id) = @_;
    &Log::do_log('debug2','(%s,%s)', $self->{'name'}, $id);
    my %sources;

    my @ids = split /,/,$id;
    foreach my $id (@ids) {
	## User may come twice from the same datasource
	unless (defined ($sources{$id})) {
	    my $datasource = $self->search_datasource($id);
	    if (defined $datasource) {
		if (ref($datasource->{'def'})) {
		    $sources{$id} = $datasource->{'def'}{'name'} || $datasource->{'def'}{'host'};
		}else {
		    $sources{$id} = $datasource->{'def'};
		}
	    }
	}
    }
    
    return join(', ', values %sources);
}

## Remove a task in the tasks spool
sub remove_task {
    my $self = shift;
    my $task = shift;

    unless (opendir(DIR, $Conf::Conf{'queuetask'})) {
	&Log::do_log ('err', "error : can't open dir %s: %s", $Conf::Conf{'queuetask'}, $!);
	return undef;
    }
    my @tasks = grep !/^\.\.?$/, readdir DIR;
    closedir DIR;

    foreach my $task_file (@tasks) {
	if ($task_file =~ /^(\d+)\.\w*\.$task\.$self->{'name'}\@$self->{'domain'}$/) {
	    unless (unlink("$Conf::Conf{'queuetask'}/$task_file")) {
		&Log::do_log('err', 'Unable to remove task file %s : %s', $task_file, $!);
		return undef;
	    }
	    &Log::do_log('notice', 'Removing task file %s', $task_file);
	}
    }

    return 1;
}

## Close the list (remove from DB, remove aliases, change status to 'closed' or 'family_closed')
sub close_list {
    my ($self, $email, $status) = @_;

    return undef 
	unless ($self && ($list_of_lists{$self->{'domain'}}{$self->{'name'}}));
    
    ## Dump subscribers, unless list is already closed
    unless ($self->{'admin'}{'status'} eq 'closed') {
	$self->_save_list_members_file("$self->{'dir'}/subscribers.closed.dump");
    }

    ## Delete users
    my @users;
    for ( my $user = $self->get_first_list_member(); $user; $user = $self->get_next_list_member() ){
	push @users, $user->{'email'};
    }
    $self->delete_list_member('users' => \@users);

    ## Remove entries from admin_table
    foreach my $role ('owner','editor') {
	my @admin_users;
	for ( my $user = $self->get_first_list_admin($role); $user; $user = $self->get_next_list_admin() ){
	    push @admin_users, $user->{'email'};
	}
	$self->delete_list_admin($role, @admin_users);
    }

    ## Change status & save config
    $self->{'admin'}{'status'} = 'closed';

    if (defined $status) {
 	foreach my $s ('family_closed','closed') {
 	    if ($status eq $s) {
 		$self->{'admin'}{'status'} = $status;
 		last;
 	    }
 	}
    }
    
    $self->{'admin'}{'defaults'}{'status'} = 0;

    $self->save_config($email);
    $self->savestats();
    
    $self->remove_aliases();   

    #log in stat_table to make staistics
    &Log::db_stat_log({'robot' => $self->{'domain'}, 'list' => $self->{'name'}, 'operation' => 'close_list','parameter' => '', 
		       'mail' => $email, 'client' => '', 'daemon' => 'damon_name'});
		       
    
    return 1;
}

## Remove the list
sub purge {
    my ($self, $email) = @_;

    return undef 
	unless ($self && ($list_of_lists{$self->{'domain'}}{$self->{'name'}}));
    
    ## Remove tasks for this list
    &Task::list_tasks($Conf::Conf{'queuetask'});
    foreach my $task (&Task::get_tasks_by_list($self->get_list_id())) {
	unlink $task->{'filepath'};
    }
    
    ## Close the list first, just in case...
    $self->close_list();

    if ($self->{'name'}) {
	my $arc_dir = &Conf::get_robot_conf($self->{'domain'},'arc_path');
	&tools::remove_dir($arc_dir.'/'.$self->get_list_id());
	&tools::remove_dir($self->get_bounce_dir());
    }

    &tools::remove_dir($self->{'dir'});

    #log ind stat table to make statistics
    &Log::db_stat_log({'robot' => $self->{'domain'}, 'list' => $self->{'name'}, 'operation' => 'purge list', 'parameter' => '',
		       'mail' => $email, 'client' => '', 'daemon' => 'daemon_name'});
    
    return 1;
}

## Remove list aliases
sub remove_aliases {
    my $self = shift;

    return undef 
	unless ($self && ($list_of_lists{$self->{'domain'}}{$self->{'name'}})
		&& ($Conf::Conf{'sendmail_aliases'} !~ /^none$/i));
    
    my $alias_manager = $Conf::Conf{'alias_manager'};
    
    unless (-x $alias_manager) {
	&Log::do_log('err','Cannot run alias_manager %s', $alias_manager);
	return undef;
    }
    
    system ("$alias_manager del $self->{'name'} $self->{'admin'}{'host'}");
    my $status = $? / 256;
    unless ($status == 0) {
	do_log('err','Failed to remove aliases ; status %d : %s', $status, $!);
	return undef;
    }
    
    &Log::do_log('info','Aliases for list %s removed successfully', $self->{'name'});
    
    return 1;
}


##
## bounce management actions
##

# Sub for removing user
#
sub remove_bouncers {
    my $self = shift;
    my $reftab = shift;
    &Log::do_log('debug','List::remove_bouncers(%s)',$self->{'name'});
    
    ## Log removal
    foreach my $bouncer (@{$reftab}) {
	&Log::do_log('notice','Removing bouncing subsrciber of list %s : %s', $self->{'name'}, $bouncer);
    }

    unless ($self->delete_list_member('users' => $reftab, 'exclude' =>' 1')){
      &Log::do_log('info','error while calling sub delete_users');
      return undef;
    }
    return 1;
}

#Sub for notifying users : "Be carefull,You're bouncing"
#
sub notify_bouncers{
    my $self = shift;
    my $reftab = shift;
    &Log::do_log('debug','List::notify_bouncers(%s)', $self->{'name'});

    foreach my $user (@$reftab){
 	&Log::do_log('notice','Notifying bouncing subsrciber of list %s : %s', $self->{'name'}, $user);
	unless ($self->send_notify_to_user('auto_notify_bouncers',$user,{})) {
	    &Log::do_log('notice',"Unable to send notify 'auto_notify_bouncers' to $user");
	}
    }
    return 1;
}

## Create the document repository
sub create_shared {
    my $self = shift;

    my $dir = $self->{'dir'}.'/shared';

    if (-e $dir) {
	&Log::do_log('err',"List::create_shared : %s already exists", $dir);
	return undef;
    }

    unless (mkdir ($dir, 0777)) {
	&Log::do_log('err',"List::create_shared : unable to create %s : %s ", $dir, $!);
	return undef;
    }

    return 1;
}

## check if a list  has include-type data sources
sub has_include_data_sources {
    my $self = shift;

    foreach my $type ('include_file','include_list','include_remote_sympa_list','include_sql_query','include_remote_file',
		      'include_ldap_query','include_ldap_2level_query','include_admin','owner_include','editor_include') {
	if (ref($self->{'admin'}{$type}) eq 'ARRAY' && $#{$self->{'admin'}{$type}} >= 0) {
	    return 1;
	}
    }
    
    return 0
}

# move a message to a queue or distribute spool
sub move_message {
    my ($self, $file, $queue) = @_;
    &Log::do_log('debug2', "List::move_message($file, $self->{'name'}, $queue)");

    my $dir = $queue || $Conf::Conf{'queuedistribute'};    
    my $filename = $self->get_list_id().'.'.time.'.'.int(rand(999));

    unless (open OUT, ">$dir/T.$filename") {
	&Log::do_log('err', 'Cannot create file %s', "$dir/T.$filename");
	return undef;
    }
    
    unless (open IN, $file) {
	&Log::do_log('err', 'Cannot open file %s', $file);
	return undef;
    }
    
    print OUT <IN>; close IN; close OUT;
    unless (rename "$dir/T.$filename", "$dir/$filename") {
	&Log::do_log('err', 'Cannot rename file %s into %s',"$dir/T.$filename","$dir/$filename" );
	return undef;
    }
    return 1;
}

## Return the path to the list bounce directory, where bounces are stored
sub get_bounce_dir {
    my $self = shift;

    my $root_dir = &Conf::get_robot_conf($self->{'domain'}, 'bounce_path');
    
    return $root_dir.'/'.$self->get_list_id();
}

## Return the list email address
sub get_list_address {
    my $self = shift;

    return $self->{'name'}.'@'.$self->{'admin'}{'host'};
}

## Return the list ID, different from the list address (uses the robot name)
sub get_list_id {
    my $self = shift;

    return $self->{'name'}.'@'.$self->{'domain'};
}

##connect to stat_counter_table and extract data.
sub get_data {
    my ($data, $robotname, $listname) = @_;

    unless ( $sth = &SDM::do_query( "SELECT * FROM stat_counter_table WHERE data_counter = '%s' AND robot_counter = '%s' AND list_counter = '%s'", $data,$robotname, $listname)) {
	&Log::do_log('err','Unable to get stat data %s for liste %s@%s',$data,$listname,$robotname);
	return undef;
    }
    my $res = $sth->fetchall_hashref('id_counter');
    return $res;
}

    

    

###### END of the List package ######

## This package handles Sympa virtual robots
## It should :
##   * provide access to global conf parameters,
##   * deliver the list of lists
##   * determine the current robot, given a host
package Robot;

use Conf;

## Constructor of a Robot instance
sub new {
    my($pkg, $name) = @_;

    my $robot = {'name' => $name};
    &Log::do_log('debug2', '');
    
    unless (defined $name && $Conf::Conf{'robots'}{$name}) {
	&Log::do_log('err',"Unknown robot '$name'");
	return undef;
    }

    ## The default robot
    if ($name eq $Conf::Conf{'domain'}) {
	$robot->{'home'} = $Conf::Conf{'home'};
    }else {
	$robot->{'home'} = $Conf::Conf{'home'}.'/'.$name;
	unless (-d $robot->{'home'}) {
	    &Log::do_log('err', "Missing directory '$robot->{'home'}' for robot '$name'");
	    return undef;
	}
    }

    ## Initialize internal list cache
    undef %list_cache;

    # create a new Robot object
    bless $robot, $pkg;

    return $robot;
}

## load all lists belonging to this robot
sub get_lists {
    my $self = shift;

    return &List::get_lists($self->{'name'});
}


###### END of the Robot package ######

## Packages must return true.
1;
