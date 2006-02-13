# list.pm - This module includes all list processing functions
# RCS Identication ; $Revision$ ; $Date$ 
#
# Sympa - SYsteme de Multi-Postage Automatique
# Copyright (c) 1997, 1998, 1999, 2000, 2001 Comite Reseau des Universites
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
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

package List;

use strict;
require Fetch;
require Exporter;
#require Encode;
require 'tools.pl';
require "--LIBDIR--/tt2.pl";

my @ISA = qw(Exporter);
my @EXPORT = qw(%list_of_lists);

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

=item delete_user ( ARRAY )

Delete the indicated users from the list.
 
=item delete_admin_user ( ROLE, ARRAY )

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

=item get_user_db ( USER )

Returns a hash with the informations regarding the indicated
user.

=item get_subscriber ( USER )

Returns a subscriber of the list.

=item get_admin_user ( ROLE, USER)

Return an admin user of the list with predefined role

=item get_first_user ()

Returns a hash to the first user on the list.

=item get_first_admin_user ( ROLE )

Returns a hash to the first admin user with predifined role on the list.

=item get_next_user ()

Returns a hash to the next users, until we reach the end of
the list.

=item get_next_admin_user ()

Returns a hash to the next admin users, until we reach the end of
the list.

=item update_user ( USER, HASHPTR )

Sets the new values given in the hash for the user.

=item update_admin_user ( USER, ROLE, HASHPTR )

Sets the new values given in the hash for the admin user.

=item add_user ( USER, HASHPTR )

Adds a new user to the list. May overwrite existing
entries.

=item add_admin_user ( USER, ROLE, HASHPTR )

Adds a new admin user to the list. May overwrite existing
entries.

=item is_user ( USER )

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

Print the list informations to the given file descriptor, or the
currently selected descriptor.

=cut

use Carp;

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
use MIME::Words;
use MIME::WordDecoder;
use MIME::Parser;
use Message;
use Family;
use PlainDigest;

## Database and SQL statement handlers
my ($dbh, $sth, $db_connected, @sth_stack, $use_db, $include_lock_count, $include_admin_user_lock_count);

my %list_cache;
my %persistent_cache;

my %date_format = (
		   'read' => {
		       'Pg' => 'date_part(\'epoch\',%s)',
		       'mysql' => 'UNIX_TIMESTAMP(%s)',
		       'Oracle' => '((to_number(to_char(%s,\'J\')) - to_number(to_char(to_date(\'01/01/1970\',\'dd/mm/yyyy\'), \'J\'))) * 86400) +to_number(to_char(%s,\'SSSSS\'))',
		       'Sybase' => 'datediff(second, "01/01/1970",%s)',
		       'SQLite' => 'strftime(\'%%s\',%s,\'utc\')'
		       },
		   'write' => {
		       'Pg' => '\'epoch\'::timestamp with time zone + \'%d sec\'',
		       'mysql' => 'FROM_UNIXTIME(%d)',
		       'Oracle' => 'to_date(to_char(round(%s/86400) + to_number(to_char(to_date(\'01/01/1970\',\'dd/mm/yyyy\'), \'J\'))) || \':\' ||to_char(mod(%s,86400)), \'J:SSSSS\')',
		       'Sybase' => 'dateadd(second,%s,"01/01/1970")',
		       'SQLite' => 'datetime(%d,\'unixepoch\',\'localtime\')'
		       }
	       );

## DB fields with numeric type
## We should not do quote() for these while inserting data
my %numeric_field = ('cookie_delay_user' => 1,
		      'bounce_score_subscriber' => 1,
		      'subscribed_subscriber' => 1,
		      'included_subscriber' => 1,
		      'subscribed_admin' => 1,
		      'included_admin' => 1,
		      );
		      
## List parameters defaults
my %default = ('occurrence' => '0-1',
	       'length' => 25
	       );

my @param_order = qw (subject visibility info subscribe add unsubscribe del owner owner_include
		      send editor editor_include account topics 
		      host lang web_archive archive digest digest_max_size available_user_options 
		      default_user_options msg_topic msg_topic_keywords_apply_on msg_topic_tagging reply_to_header reply_to forced_reply_to * 
		      verp_rate welcome_return_path remind_return_path user_data_source include_file include_remote_file 
		      include_list include_remote_sympa_list include_ldap_query
                      include_ldap_2level_query include_sql_query include_admin ttl creation update 
		      status serial);

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
## unit :        Unit of the parameter ; this is used in web forms
## occurrence :  Occurerence of the parameter in the config file
##               possible values: 0-1 | 1 | 0-n | 1-n
##               example : a list may have multiple owner 
## gettext_id :    Title reference in NLS catalogues
## description : deescription text of a parameter
## group :       Group of parameters
## obsolete :    Obsolete parameter ; should not be displayed 
##               nor saved
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
								      }
						  },
					 'gettext_id' => "Available subscription options",
					 'group' => 'sending'
				     },

	    'bounce' => {'format' => {'warn_rate' => {'format' => '\d+',
						      'length' => 3,
						      'unit' => '%',
						      'default' => {'conf' => 'bounce_warn_rate'},
						      'gettext_id' => "warn rate",
						      'order' => 1
						  },
				      'halt_rate' => {'format' => '\d+',
						      'length' => 3,
						      'unit' => '%',
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
								 'unit' => 'Points',
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
								 'unit' => 'Points',
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
				       'unit' => 'days',
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
	    'creation' => {'format' => {'date_epoch' => {'format' => '\d+',
							 'occurrence' => '1',
							 'gettext_id' => "",
							 'order' => 3
						     },
					'date' => {'format' => '.+',
						   'gettext_id' => "",
						   'order' => 2
						   },
					'email' => {'format' => $tools::regexp{'email'},
						    'occurrence' => '1',
						    'gettext_id' => "",
						    'order' => 1
						    }
				    },
			   'gettext_id' => "Creation of the list",
			   'internal' => 1,
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
				  'unit' => 'messages',
				  'default' => 25,
				  'gettext_id' => "Digest maximum number of messages",
				  'group' => 'sending'
		       },	    
	    'editor' => {'format' => {'email' => {'format' => $tools::regexp{'email'},
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
							       'order' => 3
							      }
					      
					      },
				  'occurrence' => '0-n',
				  'gettext_id' => 'Moderators defined in an external datasource',
				  'group' => 'description',
			      },
	    'expire_task' => {'task' => 'expire',
			      'gettext_id' => "Periodical subscription expiration task",
			      'group' => 'other'
			 },
 	    'family_name' => {'format' => $tools::regexp{'family_name'},
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
	    'host' => {'format' => $tools::regexp{'host'},
		       'length' => 20,
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
	    'include_ldap_query' => {'format' => {'host' => {'format' => $tools::regexp{'multiple_host_with_port'},
							     'occurrence' => '1',
							     'gettext_id' => "remote host",
							     'order' => 2
							     },
						  'port' => {'format' => '\d+',
							     'default' => 389,
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
								'unit' => 'seconds',
								'gettext_id' => "connection timeout",
								'order' => 6
								},
						   'name' => {'format' => '.+',
							      'gettext_id' => "short name for this source",
							      'length' => 15,
							      'order' => 1
							      }
					      },
				     'occurrence' => '0-n',
				     'gettext_id' => "LDAP query inclusion",
				     'group' => 'data_source'
				     },
	    'include_ldap_2level_query' => {'format' => {'host' => {'format' => $tools::regexp{'multiple_host_with_port'},
							     'occurrence' => '1',
							     'gettext_id' => "remote host",
							     'order' => 1
							     },
						  'port' => {'format' => '\d+',
							     'default' => 389,
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
								'unit' => 'seconds',
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
								'unit' => 'seconds',
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
							      }

					      },
				     'occurrence' => '0-n',
				     'gettext_id' => "LDAP 2-level query inclusion",
				     'group' => 'data_source'
				     },
	    'include_list' => {'format' => "$tools::regexp{'listname'}(\@$tools::regexp{'host'})?",
			       'occurrence' => '0-n',
			       'gettext_id' => "List inclusion",
			       'group' => 'data_source'
			       },
	    'include_remote_sympa_list' => {'format' => {'host' => {'format' => $tools::regexp{'host'},
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
						 'host' => {'format' => $tools::regexp{'host'},
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
							      'gettext_id' => "environment variables for database connexion"
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
						 'sql_query' => {'format' => $tools::regexp{'sql_query'},
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
 						    'email' => {'format' => $tools::regexp{'email'},
 								'occurrence' => '0-1',
 								'gettext_id' => 'who ran the instantiation',
 								'order' => 1
 								}
 						},
 				       'gettext_id' => 'Latest family instantiation',
				       'internal' => 1,
				       'group' => 'other'
 				       },
	    'max_size' => {'format' => '\d+',
			   'length' => 8,
			   'unit' => 'bytes',
			   'default' => {'conf' => 'max_size'},
			   'gettext_id' => "Maximum message size",
			   'group' => 'sending'
		       },
	    'msg_topic' => {'format' => {'name' => {'format' => '\w+',
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
					       'gettext_id' => "On which part of messages, topic keywords are applied",
					       'group' => 'sending'
					     },    

	    'msg_topic_tagging' => { 'format' => ['required','optional'],
				      'occurrence' => '0-1',
				      'default' => 'optional',
				      'gettext_id' => "Message tagging",
				      'group' => 'sending'
				      },    
						   
	    'owner' => {'format' => {'email' => {'format' => $tools::regexp{'email'},
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
				     'gecos' => {'format' => '.+',
						 'length' => 30,
						 'gettext_id' => "name",
						 'order' => 2
						 },
				     'info' => {'format' => '.+',
						'length' => 30,
						'gettext_id' => "private informations",
						'order' => 3
						},
				     'profile' => {'format' => ['privileged','normal'],
						   'default' => 'normal',
						   'gettext_id' => "profile",
						   'order' => 4
						   }
				 },
			'occurrence' => '0-n',
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
					     'profile' => {'format' => ['privileged','normal'],
							   'default' => 'normal',
							   'gettext_id' => 'profile',
							    'order' => 3
						       }
					 },
				'occurrence' => '0-n',
				'gettext_id' => 'Owners defined in an external datasource',
				'group' => 'description',
			    },
	    'priority' => {'format' => [0..9,'z'],
			   'length' => 1,
			   'default' => {'conf' => 'default_list_priority'},
			   'gettext_id' => "Priority",
			   'group' => 'description'
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
			      'gettext-id' => 'Periodical subscription reminder task',
			      'default' => {'conf' => 'default_remind_task'},
			      'group' => 'other'
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
					       'other_email' => {'format' => $tools::regexp{'email'},
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
						      'unit' => 'Kbytes',
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
	    'topics' => {'format' => '\w+(\/\w+)?',
			 'split_char' => ',',
			 'occurrence' => '0-n',
			 'gettext_id' => "Topics for the list",
			 'group' => 'description'
			 },
	    'ttl' => {'format' => '\d+',
		      'length' => 6,
		      'unit' => 'seconds',
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
				      'email' => {'format' => $tools::regexp{'email'},
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
				   'gettext_id' => "User data source",
				   'group' => 'data_source'
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
							'unit' => 'Kbytes',
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

	    'export' => {'format' => '\w+',
			 'split_char' => ',',
			 'occurrence' => '0-n',
			 'default' =>'',
			 'group' => 'data_source'
		     }
	    
	    );

## This is the generic hash which keeps all lists in memory.
my %list_of_lists = ();
my %list_of_robots = ();
my %list_of_topics = ();
my %edit_list_conf = ();
my %list_of_fh = ();

## Last modification times
my %mtime;

use Fcntl;
use DB_File;

$DB_BTREE->{compare} = \&_compare_addresses;

sub LOCK_SH {1};
sub LOCK_EX {2};
sub LOCK_NB {4};
sub LOCK_UN {8};

## Connect to Database
sub db_connect {
    my $option = shift;

    do_log('debug3', 'List::db_connect');

    my $connect_string;

    unless (eval "require DBI") {
	do_log('info',"Unable to use DBI library, install DBI (CPAN) first");
	return undef;
    }
    require DBI;

    ## Do we have db_xxx required parameters
    foreach my $db_param ('db_type','db_name') {
	unless ($Conf{$db_param}) {
	    do_log('info','Missing parameter %s for DBI connection', $db_param);
	    return undef;
	}
    }
    
    ## SQLite just need a db_name
    unless ($Conf{'db_type'} eq 'SQLite') {
	foreach my $db_param ('db_type','db_name','db_host','db_user') {
	    unless ($Conf{$db_param}) {
		do_log('info','Missing parameter %s for DBI connection', $db_param);
		return undef;
	    }
	}
    }

    ## Used by Oracle (ORACLE_HOME)
    if ($Conf{'db_env'}) {
	foreach my $env (split /;/, $Conf{'db_env'}) {
	    my ($key, $value) = split /=/, $env;
	    $ENV{$key} = $value if ($key);
	}
    }

    if ($Conf{'db_type'} eq 'Oracle') {
	## Oracle uses sids instead of dbnames
	$connect_string = sprintf 'DBI:%s:sid=%s;host=%s', $Conf{'db_type'}, $Conf{'db_name'}, $Conf{'db_host'};

    }elsif ($Conf{'db_type'} eq 'Sybase') {
	$connect_string = sprintf 'DBI:%s:database=%s;server=%s', $Conf{'db_type'}, $Conf{'db_name'}, $Conf{'db_host'};

    }elsif ($Conf{'db_type'} eq 'SQLite') {
	$connect_string = sprintf 'DBI:%s:dbname=%s', $Conf{'db_type'}, $Conf{'db_name'};

    }else {
	$connect_string = sprintf 'DBI:%s:dbname=%s;host=%s', $Conf{'db_type'}, $Conf{'db_name'}, $Conf{'db_host'};
    }

    if ($Conf{'db_port'}) {
	$connect_string .= ';port=' . $Conf{'db_port'};
    }

    if ($Conf{'db_options'}) {
	$connect_string .= ';' . $Conf{'db_options'};
    }

    unless ( $dbh = DBI->connect($connect_string, $Conf{'db_user'}, $Conf{'db_passwd'}) ) {

	return undef if ($option eq 'just_try');

	do_log('err','Can\'t connect to Database %s as %s, still trying...', $connect_string, $Conf{'db_user'});

	unless (&send_notify_to_listmaster('no_db', $Conf{'domain'},{})) {
	    &do_log('notice',"Unable to send notify 'no_db' to listmaster");
	}

	## Die if first connect and not in web context
	unless ($db_connected || $ENV{'HTTP_HOST'}) {
	    &fatal_err('Sympa cannot connect to database %s, dying', $Conf{'db_name'});
	}

	## Loop until connect works
	my $sleep_delay = 60;
	do {
	    sleep $sleep_delay;
	    $sleep_delay += 10;
	} until ($dbh = DBI->connect($connect_string, $Conf{'db_user'}, $Conf{'db_passwd'}) );
	
	do_log('notice','Connection to Database %s restored.', $connect_string);
	unless (&send_notify_to_listmaster('db_restored', $Conf{'domain'},{})) {
	    &do_log('notice',"Unable to send notify 'db_restored' to listmaster");
	}

#	return undef;
    }

    if ($Conf{'db_type'} eq 'Pg') { # Configure Postgres to use ISO format dates
       $dbh->do ("SET DATESTYLE TO 'ISO';");
    }

    ## added sybase support
    if ($Conf{'db_type'} eq 'Sybase') { # Configure to use sympa database 
	my $dbname;
	$dbname="use $Conf{'db_name'}";
        $dbh->do ($dbname);
    }

    if ($Conf{'db_type'} eq 'SQLite') { # Configure to use sympa database
        $dbh->func( 'func_index', -1, sub { return index($_[0],$_[1]) }, 'create_function' );
	if(defined $Conf{'db_timeout'}) { $dbh->func( $Conf{'db_timeout'}, 'busy_timeout' ); }
	else { $dbh->func( 5000, 'busy_timeout' ); }
    }

    do_log('debug3','Connected to Database %s',$Conf{'db_name'});
    $db_connected = 1;

    return 1;
}

## Disconnect from Database
sub db_disconnect {
    do_log('debug3', 'List::db_disconnect');

    unless ($dbh->disconnect()) {
	do_log('notice','Can\'t disconnect from Database %s : %s',$Conf{'db_name'}, $dbh->errstr);
	return undef;
    }

    return 1;
}

## Get database handler
sub db_get_handler {
    do_log('debug3', 'List::db_get_handler');


    return $dbh;
}

## Creates an object.
sub new {
    my($pkg, $name, $robot, $options) = @_;
    my $list={};
    do_log('debug2', 'List::new(%s,%s)', $name, $robot);
    
    ## Allow robot in the name
    if ($name =~ /\@/) {
	my @parts = split /\@/, $name;
	$robot ||= $parts[1];
	$name = $parts[0];
    }

    ## Look for the list if no robot was provided
    $robot ||= &search_list_among_robots($name);

    unless ($robot) {
	&do_log('err', 'Missing robot parameter, cannot create list object for %s',  $name) unless ($options->{'just_try'});
	return undef;
    }

    $options = {} unless (defined $options);

    ## Only process the list if the name is valid.
    unless ($name and ($name =~ /^$tools::regexp{'listname'}$/io) ) {
	&do_log('err', 'Incorrect listname "%s"',  $name) unless ($options->{'just_try'});
	return undef;
    }
    ## Lowercase the list name.
    $name =~ tr/A-Z/a-z/;
    
    ## Reject listnames with reserved list suffixes
    my $regx = &Conf::get_robot_conf($robot,'list_check_regexp');
    if ( $regx ) {
	if ($name =~ /^(\S+)-($regx)$/) {
	    &do_log('err', 'Incorrect name: listname "%s" matches one of service aliases',  $name) unless ($options->{'just_try'});
	    return undef;
	}
    }

    if ($list_of_lists{$robot}{$name}){
	# use the current list in memory and update it
	$list=$list_of_lists{$robot}{$name};
    }else{
	# create a new object list
	bless $list, $pkg;
    }
    
    my $status = $list->load($name, $robot, $options);
    
    unless (defined $status) {
	return undef;
    }

    ## Config file was loaded or reloaded
    if (($status == 1 && ! $options->{'skip_sync_admin'}) ||
	$options->{'force_sync_admin'}) {

	## Update admin_table
	unless (defined $list->sync_include_admin()) {
	    &do_log('err','List::new() : sync_include_admin_failed') unless ($options->{'just_try'});
	}
	if ($list->get_nb_owners() < 1 &&
	    $list->{'admin'}{'status'} ne 'error_config') {
	    &do_log('err', 'The list "%s" has got no owner defined',$list->{'name'}) ;
	    $list->set_status_error_config('no_owner_defined',$list->{'name'});
	}
    }

    return $list;
}

## When no robot is specified, look for a list among robots
sub search_list_among_robots {
    my $listname = shift;
    
    unless ($listname) {
 	&do_log('err', 'List::search_list_among_robots() : Missing list parameter');
 	return undef;
    }
    
    ## Search in default robot
    if (-d $Conf{'home'}.'/'.$listname) {
 	return $Conf{'host'};
    }
    
     foreach my $r (keys %{$Conf{'robots'}}) {
	 if (-d $Conf{'home'}.'/'.$r.'/'.$listname) {
	     return $r;
	 }
     }
    
     return 0;
}

## set the list in status error_config and send a notify to listmaster
sub set_status_error_config {
    my ($self, $message, @param) = @_;
    &do_log('debug3', 'List::set_status_error_config');

    unless ($self->{'admin'}{'status'} eq 'error_config'){
	$self->{'admin'}{'status'} = 'error_config';

	my $host = &Conf::get_robot_conf($self->{'robot'}, 'host');
	## No more save config in error...
	#$self->save_config("listmaster\@$host");
	#$self->savestats();
	&do_log('err', 'The list "%s" is set in status error_config',$self->{'name'});
	unless (&List::send_notify_to_listmaster($message, $self->{'domain'},\@param)) {
	    &do_log('notice',"Unable to send notify '$message' to listmaster");
	};
    }
}

## set the list in status family_closed and send a notify to owners
sub set_status_family_closed {
    my ($self, $message, @param) = @_;
    &do_log('debug2', 'List::set_status_family_closed');
    
    unless ($self->{'admin'}{'status'} eq 'family_closed'){
	
	my $host = &Conf::get_robot_conf($self->{'robot'}, 'host');	
	
	unless ($self->close("listmaster\@$host",'family_closed')) {
	    &do_log('err','Impossible to set the list %s in status family_closed');
	    return undef;
	}
	&do_log('err', 'The list "%s" is set in status family_closed',$self->{'name'});
	unless ($self->send_notify_to_owner($message,\@param)){
	    &do_log('err','Impossible to send notify to owner informing status family_closed for the list %s',$self->{'name'});
	}
# messages : close_list
    }
    return 1;
}

## Saves the statistics data to disk.
sub savestats {
    my $self = shift;
    do_log('debug2', 'List::savestats');
   
    ## Be sure the list has been loaded.
    my $name = $self->{'name'};
    my $dir = $self->{'dir'};
    return undef unless ($list_of_lists{$self->{'domain'}}{$name});
    
   _save_stats_file("$dir/stats", $self->{'stats'}, $self->{'total'}, $self->{'last_sync'}, $self->{'last_sync_admin_user'});
    
    ## Changed on disk
    $self->{'mtime'}[2] = time;

    return 1;
}

## msg count.
sub increment_msg_count {
    my $self = shift;
    do_log('debug2', "List::increment_msg_count($self->{'name'})");
   
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

## last date of distribution message .
sub get_latest_distribution_date {
    my $self = shift;
    do_log('debug3', "List::latest_distribution_date($self->{'name'})");
   
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
    do_log('debug2', 'List::update_stats(%d)', $bytes);

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


    &do_log('debug','&extract_verp(%s,%s,%s,%s)',$percent,$xseq,$refrcpt,$refrcptverp)  ;

    if ($percent == '0%') {
	return ();
    }
    
    my $nbpart ; 
    if ( $percent =~ /^(\d+)\%/ ) {
	$nbpart = 100/$1;  
    }
    
    my $modulo = $xseq % $nbpart ;
    my $lenght = int (($#{$refrcpt} + 1) / $nbpart) + 1;

    &do_log('debug','&extract_verp(%s,%s,%s,%s)',$percent,$xseq,$refrcpt,$refrcptverp)  ;

    
    my @result = splice @$refrcpt, $lenght*$modulo, $lenght ;
    
    foreach my $verprcpt (@$refrcptverp) {
	push @result, $verprcpt;
    }
    return ( @result ) ;
}



## Dumps a copy of lists to disk, in text format
sub dump {
    my $self = shift;
    do_log('debug2', 'List::dump(%s)', $self->{'name'});

    unless (defined $self) {
	&do_log('err','Unknown list');
	return undef;
    }

    my $user_file_name = "$self->{'dir'}/subscribers.db.dump";

    unless ($self->_save_users_file($user_file_name)) {
	&do_log('err', 'Failed to save file %s', $user_file_name);
	return undef;
    }
    
    $self->{'mtime'} = [ (stat("$self->{'dir'}/config"))[9], (stat("$self->{'dir'}/subscribers"))[9], (stat("$self->{'dir'}/stats"))[9] ];

    return 1;
}

## Saves a copy of the list to disk. Does not remove the
## data.
sub save {
    my $self = shift;
    do_log('debug3', 'List::save');

    my $name = $self->{'name'};    
 
    return undef 
	unless ($list_of_lists{$self->{'domain'}}{$name});
 
    my $user_file_name;

    if ($self->{'admin'}{'user_data_source'} eq 'file') {
	$user_file_name = "$self->{'dir'}/subscribers";

        unless ($self->_save_users_file($user_file_name)) {
	    &do_log('info', 'unable to save user file %s', $user_file_name);
	    return undef;
	}
        $self->{'mtime'} = [ (stat("$self->{'dir'}/config"))[9], (stat("$self->{'dir'}/subscribers"))[9], (stat("$self->{'dir'}/stats"))[9] ];
    }
    
    return 1;
}

## Saves the configuration file to disk
sub save_config {
    my ($self, $email) = @_;
    do_log('debug3', 'List::save_config(%s,%s)', $self->{'name'}, $email);

    my $name = $self->{'name'};    
    my $old_serial = $self->{'admin'}{'serial'};
    my $config_file_name = "$self->{'dir'}/config";
    my $old_config_file_name = "$self->{'dir'}/config.$old_serial";

    return undef 
	unless ($self);

    ## Update management info
    $self->{'admin'}{'serial'}++;
    $self->{'admin'}{'update'} = {'email' => $email,
				  'date_epoch' => time,
				  'date' => &POSIX::strftime("%d %b %Y at %H:%M:%S", localtime(time))
				  };

    unless (&_save_admin_file($config_file_name, $old_config_file_name, $self->{'admin'})) {
	&do_log('info', 'unable to save config file %s', $config_file_name);
	return undef;
    }
    
    ## Also update the binary version of the data structure
    unless (&Storable::store($self->{'admin'},"$self->{'dir'}/config.bin")) {
	&do_log('err', 'Failed to save the binary config %s', "$self->{'dir'}/config.bin");
    }

#    $self->{'mtime'}[0] = (stat("$list->{'dir'}/config"))[9];
    
    return 1;
}

## Loads the administrative data for a list
sub load {
    my ($self, $name, $robot, $options) = @_;
    do_log('debug2', 'List::load(%s, %s)', $name, $robot);
    
    my $users;

    ## Search robot if none was provided
    unless ($robot) {
	foreach my $r (keys %{$Conf{'robots'}}) {
	    if (-d "$Conf{'home'}/$r/$name") {
		$robot=$r;
		last;
	    }
	}
	
	## Try default robot
	unless ($robot) {
	    if (-d "$Conf{'home'}/$name") {
		$robot = $Conf{'host'};
	    }
	}
    }

    if ($robot && (-d "$Conf{'home'}/$robot")) {
	$self->{'dir'} = "$Conf{'home'}/$robot/$name";
    }elsif (lc($robot) eq lc($Conf{'host'})) {
 	$self->{'dir'} = "$Conf{'home'}/$name";
    }else {
	&do_log('err', 'No such list %s', $name) unless ($options->{'just_try'});
	return undef ;
    }
    
    $self->{'domain'} = $robot ;
    unless ((-d $self->{'dir'}) && (-f "$self->{'dir'}/config")) {
	&do_log('info', 'Missing directory (%s) or config file for %s', $self->{'dir'}, $name) unless ($options->{'just_try'});
	return undef ;
    }

    $self->{'name'}  = $name ;

    my ($m1, $m2, $m3) = (0, 0, 0);
    ($m1, $m2, $m3) = @{$self->{'mtime'}} if (defined $self->{'mtime'});

    my $time_config = (stat("$self->{'dir'}/config"))[9];
    my $time_config_bin = (stat("$self->{'dir'}/config.bin"))[9];
    my $time_subscribers; 
    my $time_stats = (stat("$self->{'dir'}/stats"))[9];
    my $config_reloaded = 0;
    my $admin;
    
    if ($time_config_bin > $self->{'mtime'}->[0] &&
	$time_config <= $time_config_bin &&
	! $options->{'reload_config'}) { 
	## Load a binary version of the data structure
	## unless config is more recent than config.bin
	unless ($admin = &Storable::retrieve("$self->{'dir'}/config.bin")) {
	    &do_log('err', 'Failed to load the binary config %s', "$self->{'dir'}/config.bin");
	    return undef;
	}

	$m1 = $time_config_bin;

    }elsif ($self->{'name'} ne $name || $time_config > $self->{'mtime'}->[0] ||
	    $options->{'reload_config'}) {	
	$admin = _load_admin_file($self->{'dir'}, $self->{'domain'}, 'config');

	## update the binary version of the data structure
	unless (&Storable::store($admin,"$self->{'dir'}/config.bin")) {
	    &do_log('err', 'Failed to save the binary config %s', "$self->{'dir'}/config.bin");
	}

	$config_reloaded = 1;
 	unless (defined $admin) {
 	    &do_log('err', 'Impossible to load list config file for list % set in status error_config',$self->{'name'});
 	    $self->set_status_error_config('load_admin_file_error',$self->{'name'});
 	    return undef;	    
 	}

	$m1 = $time_config;
    }
    
     if ($admin) {
 	$self->{'admin'} = $admin;
 	
 	## check param_constraint.conf if belongs to a family and the config has been loaded
 	if (defined $admin->{'family_name'} && ($admin->{'status'} ne 'error_config')) {
 	    my $family;
 	    unless ($family = $self->get_family()) {
 		&do_log('err', 'Impossible to get list %s family : %s. The list is set in status error_config',$self->{'name'},$self->{'admin'}{'family_name'});
 		$self->set_status_error_config('no_list_family',$self->{'name'}, $admin->{'family_name'});
		return undef;
 	    }  
 	    my $error = $family->check_param_constraint($self);
 	    unless($error) {
 		&do_log('err', 'Impossible to check parameters constraint for list % set in status error_config',$self->{'name'});
 		$self->set_status_error_config('no_check_rules_family',$self->{'name'}, $family->{'name'});
 	    }
	    if (ref($error) eq 'ARRAY') {
 		&do_log('err', 'The list "%s" does not respect the rules from its family %s',$self->{'name'}, $family->{'name'});
 		$self->set_status_error_config('no_respect_rules_family',$self->{'name'}, $family->{'name'});
 	    }
 	}
     } 

    # default list host is robot domain
    $self->{'admin'}{'host'} ||= $self->{'domain'};
    # uncomment the following line if you want virtual robot to overwrite list->host
    # $self->{'admin'}{'host'} = $self->{'domain'} if ($self->{'domain'} ne $Conf{'host'});
 
    # Would make sympa same 'dir' as a parameter
    #$self->{'admin'}{'dir'} ||= $self->{'dir'};

    $self->{'as_x509_cert'} = 1  if ((-r "$self->{'dir'}/cert.pem") || (-r "$self->{'dir'}/cert.pem.enc"));
    
    if ($self->{'admin'}{'user_data_source'} eq 'database') {
	
    }elsif($self->{'admin'}->{'user_data_source'} eq 'file') { 
	
	$time_subscribers = (stat("$self->{'dir'}/subscribers"))[9] if (-f "$self->{'dir'}/subscribers");

	## Touch subscribers file if not exists
	unless ( -r "$self->{'dir'}/subscribers") {
	    open L, ">$self->{'dir'}/subscribers" or return undef;
	    close L;
	    do_log('info','No subscribers file, creating %s',"$self->{'dir'}/subscribers");
	}
	
	if ($self->{'name'} ne $name || $time_subscribers > $self->{'mtime'}[1]) {
	    $users = _load_users("$self->{'dir'}/subscribers");
	    unless (defined $users) {
		do_log('err', 'Could not load subscribers for list %s', $self->{'name'});
		#return undef;
	    }
	    $m2 = $time_subscribers;
	}

    }elsif ($self->{'admin'}{'user_data_source'} eq 'include2') {
	## currently no check

    }elsif($self->{'admin'}{'user_data_source'} eq 'include') {

    ## include other subscribers as defined in include directives (list|ldap|sql|file|owners|editors)
	unless ( $self->has_include_data_sources()) {
	    &do_log('err', 'Include paragraph missing in configuration file %s', "$self->{'dir'}/config");
#	    return undef;
	}

	$time_subscribers = (stat("$self->{'dir'}/subscribers.db"))[9] if (-f "$self->{'dir'}/subscribers.db");


	## Update 'subscriber.db'
	if ( ## 'config' is more recent than 'subscribers.db'
	     ($time_config > $time_subscribers) || 
	     ## 'ttl'*2 is NOT over
	     (time > ($time_subscribers + $self->{'admin'}{'ttl'} * 2)) ||
	     ## 'ttl' is over AND not Web context
	     ((time > ($time_subscribers + $self->{'admin'}{'ttl'})) &&
	      !($ENV{'HTTP_HOST'} && (-f "$self->{'dir'}/subscribers.db")))) {
	    
	    $users = $self->_load_users_include("$self->{'dir'}/subscribers.db", 0);
	    unless (defined $users) {
		do_log('err', 'Could not load subscribers for list %s', $self->{'name'});
		#return undef;
	    }

	    $m2 = time;
	}elsif (## First new()
		! $self->{'users'} ||
		## 'subscribers.db' is more recent than $self->{'users'}
		($time_subscribers > $self->{'mtime'}->[1])) {

	    ## Use cache
	    $users = $self->_load_users_include("$self->{'dir'}/subscribers.db", 1);

	    unless (defined $users) {
		return undef;
	    }

	    $m2 = $time_subscribers;
	}
	
    }else { 
	do_log('notice','Wrong value for user_data_source');
	return undef;
    }
    
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

#    elsif ($self->{'admin'}{'user_data_source'} eq 'database'){
#	## If no total found in 'stats' AND database mode
#	$self->{'total'} = _load_total_db($name);
#    }elsif ($self->{'admin'}{'user_data_source'} eq 'file'){
#	$self->{'total'} = $users->{'total'};
#    }

    $self->{'mtime'} = [ $m1, $m2, $m3];

    $list_of_lists{$self->{'domain'}}{$name} = $self;
    return $config_reloaded;
}

## Return a list of hash's owners and their param
sub get_owners {
    my($self) = @_;
    &do_log('debug3', 'List::get_owners(%s)', $self->{'name'});
  
    my $owners = ();

    # owners are in the admin_table
    if ($self->{'admin'}{'user_data_source'} eq 'include2') {
	for (my $owner = $self->get_first_admin_user('owner'); $owner; $owner = $self->get_next_admin_user()) {
	    push(@{$owners},$owner);
	} 

    #owners are only in the config
    } else {
	$owners = $self->{'admin'}{'owner'};
    }
    return $owners;
}

sub get_nb_owners {
    my($self) = @_;
    &do_log('debug3', 'List::get_nb_owners(%s)', $self->{'name'});
    
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
    &do_log('debug3', 'List::get_editors(%s)', $self->{'name'});
  
    my $editors = ();

    # editors are in the admin_table
    if ($self->{'admin'}{'user_data_source'} eq 'include2') {
	for (my $editor = $self->get_first_admin_user('editor'); $editor; $editor = $self->get_next_admin_user()) {
	    push(@{$editors},$editor);
	} 

    #editors are only in the config
    } else {
	$editors = $self->{'admin'}{'editor'};
    }
    return $editors;
}


## Returns an array of owners' email addresses (unless reception nomail)
sub get_owners_email {
    my($self) = @_;
    do_log('debug3', 'List::get_owners_email(%s)', $self->{'name'});
    
    my @rcpt;
    my $owners = ();

    $owners = $self->get_owners();
    foreach my $o (@{$owners}) {
	next if ($o->{'reception'} eq 'nomail');
	push (@rcpt, lc($o->{'email'}));
	}
    return @rcpt;
}

## Returns an array of editors' email addresses (unless reception nomail)
#  or owners if there isn't any editors'email adress
sub get_editors_email {
    my($self) = @_;
    do_log('debug3', 'List::get_editors_email(%s)', $self->{'name'});
    
    my @rcpt;
    my $editors = ();

    $editors = $self->get_editors();
    foreach my $e (@{$editors}) {
	next if ($e->{'reception'} eq 'nomail');
	push (@rcpt, lc($e->{'email'}));
    }

    unless (@rcpt) {
	@rcpt = $self->get_owners_email();
	do_log('notice','Warning : no editor defined for list %s, getting owners', $self->{'name'} );
    }
    return @rcpt;
}

## Returns an object Family if the list belongs to a family
#  or undef
sub get_family {
    my $self = shift;
    &do_log('debug3', 'List::get_family(%s)', $self->{'name'});
    
    if (ref($self->{'family'}) eq 'Family') {
	return $self->{'family'};
    }

    my $family_name;
    my $robot = $self->{'domain'};

    unless (defined $self->{'admin'}{'family_name'}) {
	&do_log('err', 'List::get_family(%s) : this list has not got any family', $self->{'name'});
	return undef;
    }
        
    my $family_name = $self->{'admin'}{'family_name'};
	    
    my $family;
    unless ($family = new Family($family_name,$robot) ) {
	&do_log('err', 'List::get_family(%s) : new Family(%s) impossible', $self->{'name'},$family_name);
	return undef;
    }
  	
    $self->{'family'} = $family;
    return $family;
}

## return the config_changes hash
sub get_config_changes {
    my $self = shift;
    &do_log('debug3', 'List::get_config_changes(%s)', $self->{'name'});
    
    unless ($self->{'admin'}{'family_name'}) {
	&do_log('err', 'List::get_config_changes(%s) is called but there is no family_name for this list.',$self->{'name'});
	return undef;
    }
    
    ## load config_changes
    my $time_file = (stat("$self->{'dir'}/config_changes"))[9];
    unless (defined $self->{'config_changes'} && ($self->{'config_changes'}{'mtime'} >= $time_file)) {
	unless ($self->{'config_changes'} = $self->_load_config_changes_file()) {
	    &do_log('err','Impossible to load file config_changes from list %s',$self->{'name'});
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
    &do_log('debug2', 'List::update_config_changes(%s,%s)', $self->{'name'},$what);
    
    unless ($self->{'admin'}{'family_name'}) {
	&do_log('err', 'List::update_config_changes(%s,%s,%s) is called but there is no family_name for this list.',$self->{'name'},$what);
	return undef;
    }
    unless (($what eq 'file') || ($what eq 'param')){
	&do_log('err', 'List::update_config_changes(%s,%s) : %s is wrong : must be "file" or "param".',$self->{'name'},$what);
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
	    &do_log('err','Impossible to load file config_changes from list %s',$self->{'name'});
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
    &do_log('debug3', 'List::_load_config_changes_file(%s)', $self->{'name'});

    unless (open (FILE,"$self->{'dir'}/config_changes")) {
	&do_log('err','Unable to open file %s/config_changes : %s', $self->{'dir'},$_);
	return undef;
    }
    
    my $config_changes = {};
    while (<FILE>) {
	
	next if /^\s*(\#.*|\s*)$/;

	if (/^param\s+(.+)\s*$/) {
	    $config_changes->{'param'}{$1} = 1;

	}elsif (/^file\s+(.+)\s*$/) {
	    $config_changes->{'file'}{$1} = 1;
	
	}else {
	    &do_log ('err', 'List::_load_config_changes_file(%s) : bad line : %s',$self->{'name'},$_);
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
    &do_log('debug3', 'List::_save_config_changes_file(%s)', $self->{'name'});

    unless ($self->{'admin'}{'family_name'}) {
	&do_log('err', 'List::_save_config_changes_file(%s) is called but there is no family_name for this list.',$self->{'name'});
	return undef;
    }
    unless (open (FILE,">$self->{'dir'}/config_changes")) {
	&do_log('err','List::_save_config_changes_file(%s) : unable to create file %s/config_changes : %s',$self->{'name'},$self->{'dir'},$_);
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
    &do_log('debug3', '_get_param_value_anywhere(%s %s)',$param);
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
    &do_log('debug3', 'List::get_param_value(%s,%s)', $self->{'name'},$param);
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
    &do_log('debug4', 'List::_get_single_value(%s %s)',$key,$k);

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
# OUT : -$numsmtp : number of sendmail process
####################################################
sub distribute_msg {
    my($self, $message) = @_;
    do_log('debug2', 'List::distribute_msg(%s, %s, %s, %s, %s)', $self->{'name'}, $message->{'msg'}, $message->{'size'}, $message->{'filename'}, $message->{'smime_crypted'});

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

	foreach my $field (@{$Conf{'anonymous_header_fields'}}) {
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
	
	## xxxxxx Virer eventuelle signature S/MIME
    }
    
    ## Add Custom Subject
    if ($self->{'admin'}{'custom_subject'}) {
	my $subject_field = $message->{'decoded_subject'};
	$subject_field =~ s/^\s*(.*)\s*$/$1/; ## Remove leading and trailing blanks
	
	## Search previous subject tagging in Subject
	my $tag_regexp = $self->{'admin'}{'custom_subject'};
	$tag_regexp =~ s/([\[\]\*\-\(\)\+\{\}\?])/\\$1/g;  ## cleanup, just in case dangerous chars were left
	$tag_regexp =~ s/\[\S+\]/\.\+/g;
	
	## Add subject tag
	$message->{'msg'}->head->delete('Subject');
	my @parsed_tag;
	&parser::parse_tpl({'list' => {'name' => $self->{'name'},
				       'sequence' => $self->{'stats'}->[0]
				       }},
			   [$self->{'admin'}{'custom_subject'}], \@parsed_tag);
	
	## If subject is tagged, replace it with new tag
	if ($subject_field =~ /\[$tag_regexp\]/) {
	    $subject_field =~ s/\[$tag_regexp\]/\[$parsed_tag[0]\]/;
	}else {
	    $subject_field = '['.$parsed_tag[0].'] '.$subject_field;
	}
 	## Encode subject using initial charset
 	$subject_field = MIME::Words::encode_mimewords($subject_field, ('Encode' => 'Q', 'Charset' => $message->{'subject_charset'}));

	$message->{'msg'}->head->add('Subject', $subject_field);
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
		$reply = undef;
	    }elsif ($self->{'admin'}{'reply_to_header'}{'value'} eq 'all') {
		$reply = "$name\@$host,".$hdr->get('From');
	    }elsif ($self->{'admin'}{'reply_to_header'}{'value'} eq 'other_email') {
		$reply = $self->{'admin'}{'reply_to_header'}{'other_email'};
	    }
	    
	    $hdr->add('Reply-To',$reply) if $reply;
	}
    }
    
    ## Remove unwanted headers if present.
    if ($Conf{'remove_headers'}) {
        foreach my $field (@{$Conf{'remove_headers'}}) {
            $hdr->delete($field);
        }
    }
    
    ## Add useful headers
    $hdr->add('X-Loop', "$name\@$host");
    $hdr->add('X-Sequence', $sequence);
    $hdr->add('Errors-to', $name.&Conf::get_robot_conf($robot, 'return_path_suffix').'@'.$host);
    $hdr->add('Precedence', 'list');
    $hdr->add('X-no-archive', 'yes');
    foreach my $i (@{$self->{'admin'}{'custom_header'}}) {
	$hdr->add($1, $2) if ($i=~/^([\S\-\:]*)\s(.*)$/);
    }
    
    ## Add RFC 2919 header field
    if ($hdr->get('List-Id')) {
	&do_log('notice', 'Found List-Id: %s', $hdr->get('List-Id'));
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
    
    ## store msg in digest if list accept digest mode (encrypted message can't be included in digest)
    if (($self->is_digest()) and ($message->{'smime_crypted'} ne 'smime_crypted')) {
	$self->archive_msg_digest($msgtostore);
    }
    
    ## Blindly send the message to all users.
    my $numsmtp = $self->send_msg($message);
    unless (defined ($numsmtp)) {
	return $numsmtp;
    }
    
    $self->savestats();
    
    return $numsmtp;
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
    my($self, $message) = @_;
    do_log('debug2', 'List::send_msg(%s, %s)', $message->{'filename'}, $message->{'smime_crypted'});
    
    my $hdr = $message->{'msg'}->head;
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
   
    unless ($total > 0) {
	&do_log('info', 'No subscriber in list %s', $name);
	return 0;
    }

    ## Bounce rate
    ## Available in database mode only
    if (($admin->{'user_data_source'} eq 'database') ||
	($admin->{'user_data_source'} eq 'include2')){
	my $rate = $self->get_total_bouncing() * 100 / $total;
	if ($rate > $self->{'admin'}{'bounce'}{'warn_rate'}) {
	    unless ($self->send_notify_to_owner('bounce_rate',{'rate' => $rate})) {
		&do_log('notice',"Unable to send notify 'bounce_rate' to $self->{'name'} listowner");
	    }
	}
    }
 
    ## Who is the enveloppe sender ?
    my $host = $self->{'admin'}{'host'};
    my $from = $name.&Conf::get_robot_conf($robot, 'return_path_suffix').'@'.$host;

    # separate subscribers depending on user reception option and also if verp a dicovered some bounce for them.
    my (@tabrcpt, @tabrcpt_notice, @tabrcpt_txt, @tabrcpt_html, @tabrcpt_url, @tabrcpt_verp, @tabrcpt_notice_verp, @tabrcpt_txt_verp, @tabrcpt_html_verp, @tabrcpt_url_verp);
    my $mixed = ($message->{'msg'}->head->get('Content-Type') =~ /multipart\/mixed/i);
    my $alternative = ($message->{'msg'}->head->get('Content-Type') =~ /multipart\/alternative/i);
 
    for ( my $user = $self->get_first_user(); $user; $user = $self->get_next_user() ){
	unless ($user->{'email'}) {
	    &do_log('err','Skipping user with no email address in list %s', $name);
	    next;
	}
#	&do_log('debug','trace distribution VERP email %s,reception %s,bounce_address %s',$user->{'email'},$user->{'reception'},$user->{'bounce_address'} );
	if ($user->{'reception'} =~ /^digest|digestplain|summary|nomail$/i) {
	    next;
	} elsif ($user->{'reception'} eq 'notice') {
	    if ($user->{'bounce_address'}) {
		push @tabrcpt_notice_verp, $user->{'email'}; 
	    }else{
		push @tabrcpt_notice, $user->{'email'}; 
	    }
        } elsif ($alternative and ($user->{'reception'} eq 'txt')) {
	    if ($user->{'bounce_address'}) {
		push @tabrcpt_txt_verp, $user->{'email'};
	    }else{
		push @tabrcpt_txt, $user->{'email'};
	    }
        } elsif ($alternative and ($user->{'reception'} eq 'html')) {
	    if ($user->{'bounce_address'}) {
		push @tabrcpt_html_verp, $user->{'email'};
	    }else{
		if ($user->{'bounce_address'}) {
		    push @tabrcpt_html_verp, $user->{'email'};
		}else{
		    push @tabrcpt_html, $user->{'email'};
		}
	   }
	} elsif ($mixed and ($user->{'reception'} eq 'urlize')) {
	    if ($user->{'bounce_address'}) {
		push @tabrcpt_url_verp, $user->{'email'};
	    }else{
		push @tabrcpt_url, $user->{'email'};
	    }
	} elsif (($message->{'smime_crypted'}) && (! -r "$Conf{'ssl_cert_dir'}/".&tools::escape_chars($user->{'email'}))) {
	    ## Missing User certificate
	    unless ($self->send_file('x509-user-cert-missing', $user->{'email'}, $robot, {'mail' => {'subject' => $message->{'msg'}->head->get('Subject'),
												     'sender' => $message->{'msg'}->head->get('From')}})) {
	    &do_log('notice',"Unable to send template 'x509-user-cert-missing' to $user->{'email'}");
	    }
	}else{
	    if ($user->{'bounce_address'}) {
		push @tabrcpt_verp, $user->{'email'} unless ($sender_hash{$user->{'email'}})&&($user->{'reception'} eq 'not_me');
	    }else{	    
		push @tabrcpt, $user->{'email'} unless ($sender_hash{$user->{'email'}})&&($user->{'reception'} eq 'not_me');}
	    }	    
       }    

    ## sa  return 0  = Pb  ?
    unless (@tabrcpt || @tabrcpt_notice || @tabrcpt_txt || @tabrcpt_html || @tabrcpt_url || @tabrcpt_verp || @tabrcpt_notice_verp || @tabrcpt_txt_verp || @tabrcpt_html_verp || @tabrcpt_url_verp) {
	&do_log('info', 'No subscriber for sending msg in list %s', $name);
	return 0;
    }
    #save the message before modifying it
    my $saved_msg = $message->{'msg'}->dup;
    my $nbr_smtp;
    my $nbr_verp;


    # prepare verp parameter
    my $verp_rate =  $self->{'admin'}{'verp_rate'};
    my $xsequence =  $self->{'stats'}->[0] ;

    ##Send message for normal reception mode
    if (@tabrcpt) {
	## Add a footer
	unless ($message->{'protected'}) {
	    my $new_msg = $self->add_parts($message->{'msg'});
	    if (defined $new_msg) {
		$message->{'msg'} = $new_msg;
		$message->{'altered'} = '_ALTERED_';
	    }
	}
	
	## TOPICS
	my @selected_tabrcpt;
	if ($self->is_there_msg_topic()){
	    @selected_tabrcpt = $self->select_subscribers_for_topic($message->get_topic(),\@tabrcpt);
	} else {
	    @selected_tabrcpt = @tabrcpt;
	}

	my @verp_selected_tabrcpt = &extract_verp_rcpt($verp_rate, $xsequence,\@selected_tabrcpt, \@tabrcpt_verp);


	my $result = &mail::mail_message($message, $self, {'enable' => 'off'}, @selected_tabrcpt);
	unless (defined $result) {
	    &do_log('err',"List::send_msg, could not send message to distribute from $from (verp desabled)");
	    return undef;
	}
	$nbr_smtp = $result;
	
	$result = &mail::mail_message($message, $self, {'enable' => 'on'}, @verp_selected_tabrcpt);
	unless (defined $result) {
	    &do_log('err',"List::send_msg, could not send message to distribute from $from (verp enabled)");
	    return undef;
	}
	$nbr_smtp += $result;
	$nbr_verp = $result;

    }

    ##Prepare and send message for notice reception mode
    if (@tabrcpt_notice) {
	my $notice_msg = $saved_msg->dup;
        $notice_msg->bodyhandle(undef);    
	$notice_msg->parts([]);
	my $new_message = new Message($notice_msg);
	
	my @verp_tabrcpt_notice = &extract_verp_rcpt($verp_rate, $xsequence,\@tabrcpt_notice, \@tabrcpt_notice_verp);

	my $result = &mail::mail_message($new_message, $self, {'enable' => 'off'}, @tabrcpt_notice);
	unless (defined $result) {
	    &do_log('err',"List::send_msg, could not send message to distribute from $from (verp desabled)");
	    return undef;
	}
	$nbr_smtp += $result;

	$result = &mail::mail_message($new_message, $self , {'enable' => 'on'}, @verp_tabrcpt_notice);
	unless (defined $result) {
	    &do_log('err',"List::send_msg, could not send message to distribute from $from  (verp enabled)");
	    return undef;
	}
	$nbr_smtp += $result;
	$nbr_verp += $result;

    }

    ##Prepare and send message for txt reception mode
    if (@tabrcpt_txt) {
	my $txt_msg = $saved_msg->dup;
	if (&tools::as_singlepart($txt_msg, 'text/plain')) {
	    do_log('notice', 'Multipart message changed to singlepart');
	}
	
	## Add a footer
	my $new_msg = $self->add_parts($txt_msg);
	if (defined $new_msg) {
	    $txt_msg = $new_msg;
	}
	my $new_message = new Message($txt_msg);

	my @verp_tabrcpt_txt = &extract_verp_rcpt($verp_rate, $xsequence,\@tabrcpt_txt, \@tabrcpt_txt_verp);
	
	my $result = &mail::mail_message($new_message, $self,  {'enable' => 'off'}, @tabrcpt_txt);
	unless (defined $result) {
	    &do_log('err',"List::send_msg, could not send message to distribute from $from  (verp desabled)");
	    return undef;
	}
	$nbr_smtp += $result;

	$result = &mail::mail_message($new_message, $self , {'enable' => 'on'}, @verp_tabrcpt_txt);
	unless (defined $result) {
	    &do_log('err',"List::send_msg, could not send message to distribute from $from  (verp enabled)");
	    return undef;
	}
	$nbr_smtp += $result;
	$nbr_verp += $result;

    }

   ##Prepare and send message for html reception mode
    if (@tabrcpt_html) {
	my $html_msg = $saved_msg->dup;
	if (&tools::as_singlepart($html_msg, 'text/html')) {
	    do_log('notice', 'Multipart message changed to singlepart');
	}
        ## Add a footer
	my $new_msg = $self->add_parts($html_msg);
	if (defined $new_msg) {
	    $html_msg = $new_msg;
        }
	my $new_message = new Message($html_msg);

	my @verp_tabrcpt_html = &extract_verp_rcpt($verp_rate, $xsequence,\@tabrcpt_html, \@tabrcpt_html_verp);

	my $result = &mail::mail_message($new_message, $self , {'enable' => 'off'}, @tabrcpt_html);
	unless (defined $result) {
	    &do_log('err',"List::send_msg, could not send message to distribute from $from  (verp desabled)");
	    return undef;
	}
	$nbr_smtp += $result;

	$result = &mail::mail_message($new_message, $self , {'enable' => 'on'}, @verp_tabrcpt_html);
	unless (defined $result) {
	    &do_log('err',"List::send_msg, could not send message to distribute from $from  (verp enabled)");
	    return undef;
	}
	$nbr_smtp += $result;
	$nbr_verp += $result;
    }

   ##Prepare and send message for urlize reception mode
    if (@tabrcpt_url) {
	my $url_msg = $saved_msg->dup; 
 
	my $expl = $self->{'dir'}.'/urlized';
    
	unless ((-d $expl) ||( mkdir $expl, 0775)) {
	    do_log('err', "Unable to create urlize directory $expl");
	    return undef;
	}

	my $dir1 = $url_msg->head->get('Message-ID');
	chomp($dir1);

	## Clean up Message-ID
	$dir1 =~ s/^\<(.+)\>$/$1/;
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
	my $new_message = new Message($url_msg);


	my @verp_tabrcpt_url = &extract_verp_rcpt($verp_rate, $xsequence,\@tabrcpt_url, \@tabrcpt_url_verp);

	my $result = &mail::mail_message($new_message, $self , {'enable' => 'off'}, @tabrcpt_url);
	unless (defined $result) {
	    &do_log('err',"List::send_msg, could not send message to distribute from $from  (verp desabled)");
	    return undef;
	}
	$nbr_smtp += $result;

	$result = &mail::mail_message($new_message, $self , {'enable' => 'on'}, @verp_tabrcpt_url);
	unless (defined $result) {
	    &do_log('err',"List::send_msg, could not send message to distribute from $from  (verp enabled)");
	    return undef;
	}
	$nbr_smtp += $result;
	$nbr_verp += $result;

    }

    return $nbr_smtp;
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
    do_log('debug2', 'List:send_msg_digest(%s)', $listname);
    
    my $filename;
    ## Backward compatibility concern
    if (-f "$Conf{'queuedigest'}/$listname") {
 	$filename = "$Conf{'queuedigest'}/$listname";
    }else {
 	$filename = $Conf{'queuedigest'}.'/'.$self->get_list_id();
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
    for (my $user = $self->get_first_user(); $user; $user = $self->get_next_user()) {
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
	&do_log('info', 'No subscriber for sending digest in list %s', $listname);
	return 0;
    }

    my $old = $/;
    $/ = "\n\n" . $tools::separator . "\n\n";
    
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
#   $parser->output_dir($Conf{'spool'} ."/tmp");    
	my $mail = $parser->parse_data(\@text);
	
	next unless (defined $mail);

	push @list_of_mail, $mail;
    }
    close DIGEST;
    $/ = $old;

    ## Deletes the introduction part
    splice @list_of_mail, 0, 1;
    
    ## Digest index
    my @all_msg;
    foreach $i (0 .. $#list_of_mail){
	my $mail = $list_of_mail[$i];
	my $subject = &MIME::Words::decode_mimewords($mail->head->get('Subject'));
	chomp $subject;
	my $from = &MIME::Words::decode_mimewords($mail->head->get('From'));
	chomp $from;    
	
        my $msg = {};
	$msg->{'id'} = $i+1;
        $msg->{'subject'} = $subject;	
	$msg->{'from'} = $from;
	$msg->{'date'} = $mail->head->get('Date');
	chomp $msg->{'date'};
	
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
    $param->{'datetime'} = sprintf "%s", POSIX::strftime("%a, %d %b %Y %H:%M:%S", @now);
    $param->{'date'} = sprintf "%s", POSIX::strftime("%a, %d %b %Y", @now);

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
	
	## Prepare Digest
	if (@tabrcpt) {
	    ## Send digest
	    unless ($self->send_file('digest', \@tabrcpt, $robot, $param)) {
		&do_log('notice',"Unable to send template 'digest' to $self->{'name'} list subscribers");
	    }
	}    
	
	## Prepare Plain Text Digest
	if (@tabrcptplain) {
	    ## Send digest-plain
	    unless ($self->send_file('digest_plain', \@tabrcptplain, $robot, $param)) {
		&do_log('notice',"Unable to send template 'digest_plain' to $self->{'name'} list subscribers");
	    }
	}    
	
	
	## send summary
	if (@tabrcptsummary) {
	    unless ($self->send_file('summary', \@tabrcptsummary, $robot, $param)) {
		&do_log('notice',"Unable to send template 'summary' to $self->{'name'} list subscribers");
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
#      -$who (+): SCALAR |ref(ARRAY) - recepient(s)
#      -$robot (+): robot
#      -$context : ref(HASH) - for the $data set up 
#         to parse file tt2, keys can be :
#         -user : ref(HASH), keys can be :
#           -email
#           -lang
#           -password
#         -...
# OUT : 1 | undef
#       
####################################################
sub send_global_file {
    my($tpl, $who, $robot, $context) = @_;
    do_log('debug2', 'List::send_global_file(%s, %s, %s)', $tpl, $who, $robot);

    my $data = $context;

    unless ($data->{'user'}) {
	unless ($data->{'user'} = &get_user_db($who)) {
	    $data->{'user'}{'email'} = $who;
	}
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
	&do_log('err','Could not find template %s.tt2 in %s', $tpl, join(':',@path));
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

    unless (&mail::mail_file($filename, $who, $data, $robot)) {
	&do_log('err',"List::send_global_file, could not send template $filename to $who");
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
#  Message is signed if the list as a key and a 
#  certificat
#  
# IN : -$self (+): ref(List)
#      -$tpl (+): template file name (file.tt2),
#         without tt2 extension
#      -$who (+): SCALAR |ref(ARRAY) - recepient(s)
#      -$robot (+): robot
#      -$context : ref(HASH) - for the $data set up 
#         to parse file tt2, keys can be :
#         -user : ref(HASH), keys can be :
#           -email
#           -lang
#           -password
#         -...
# OUT : 1 | undef
####################################################
sub send_file {
    my($self, $tpl, $who, $robot, $context) = @_;
    do_log('debug2', 'List::send_file(%s, %s, %s)', $tpl, $who, $robot);

    my $name = $self->{'name'};
    my $sign_mode;

    my $data = $context;

    ## Any recepients
    if ((ref ($who) && ($#{$who} < 0)) ||
	(!ref ($who) && ($who eq ''))) {
	&do_log('err', 'No recipient for sending %s', $tpl);
	return undef;
    }
    
    ## Unless multiple recepients
    unless (ref ($who)) {
	unless ($data->{'user'}) {
	    unless ($data->{'user'} = &get_user_db($who)) {
		$data->{'user'}{'email'} = $who;
		$data->{'user'}{'lang'} = $self->{'admin'}{'lang'};
	    }
	}
	
	$data->{'subscriber'} = $self->get_subscriber($who);
	
	if ($data->{'subscriber'}) {
	    $data->{'subscriber'}{'date'} = &POSIX::strftime("%d %b %Y", localtime($data->{'subscriber'}{'date'}));
	    $data->{'subscriber'}{'update_date'} = &POSIX::strftime("%d %b %Y", localtime($data->{'subscriber'}{'update_date'}));
	    if ($data->{'subscriber'}{'bounce'}) {
		$data->{'subscriber'}{'bounce'} =~ /^(\d+)\s+(\d+)\s+(\d+)(\s+(.*))?$/;
		
		$data->{'subscriber'}{'first_bounce'} =  &POSIX::strftime("%d %b %Y",localtime($1));
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
	    $data->{'return_path'} = "$Conf{'bounce_email_prefix'}+$escapercpt\=\=$name";
	    $data->{'return_path'} .= '==w' if ($tpl eq 'welcome');
	    $data->{'return_path'} .= '==r' if ($tpl eq 'remind');
	    $data->{'return_path'} .= "\@$self->{'domain'}";
	}
    }

    $data->{'return_path'} ||= $name.&Conf::get_robot_conf($robot, 'return_path_suffix').'@'.$self->{'admin'}{'host'};

    ## Lang
    $data->{'lang'} = $data->{'user'}{'lang'} || $self->{'admin'}{'lang'} || &Conf::get_robot_conf($robot, 'lang');

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
	&do_log('err','Could not find template %s.tt2 in %s', $tpl, join(':',@path));
	return undef;
    }

    $data->{'sender'} = $who;
    $data->{'list'}{'lang'} = $self->{'admin'}{'lang'};
    $data->{'list'}{'name'} = $name;
    $data->{'list'}{'domain'} = $data->{'robot_domain'} = $robot;
    $data->{'list'}{'host'} = $self->{'admin'}{'host'};
    $data->{'list'}{'subject'} = $self->{'admin'}{'subject'};
    $data->{'list'}{'owner'} = $self->get_owners();
    $data->{'list'}{'dir'} = $self->{'dir'};

    ## Sign mode
    if ($Conf{'openssl'} &&
	(-r $self->{'dir'}.'/cert.pem') && (-r $self->{'dir'}.'/private_key')) {
	$sign_mode = 'smime';
    }

    # if the list have it's private_key and cert sign the message
    # . used only for the welcome message, could be usefull in other case ? 
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

    unless (&mail::mail_file($filename, $who, $data, $self->{'domain'}, $sign_mode)) {
	&do_log('err',"List::send_file, could not send template $filename to $who");
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
    my($self, $message) = @_;
    do_log('debug2', 'List::send_msg(%s, %s)', $message->{'filename'}, $message->{'smime_crypted'});
    
    my $hdr = $message->{'msg'}->head;
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
   
    unless ($total > 0) {
	&do_log('info', 'No subscriber in list %s', $name);
	return 0;
    }

    ## Bounce rate
    ## Available in database mode only
    if (($admin->{'user_data_source'} eq 'database') ||
	($admin->{'user_data_source'} eq 'include2')){
	my $rate = $self->get_total_bouncing() * 100 / $total;
	if ($rate > $self->{'admin'}{'bounce'}{'warn_rate'}) {
	    unless ($self->send_notify_to_owner('bounce_rate',{'rate' => $rate})) {
		&do_log('notice',"Unable to send notify 'bounce_rate' to $self->{'name'} listowner");
	    }
	}
    }
 
    ## Who is the enveloppe sender ?
    my $host = $self->{'admin'}{'host'};
    my $from = $name.&Conf::get_robot_conf($robot, 'return_path_suffix').'@'.$host;

    # separate subscribers depending on user reception option and also if verp a dicovered some bounce for them.
    my (@tabrcpt, @tabrcpt_notice, @tabrcpt_txt, @tabrcpt_html, @tabrcpt_url, @tabrcpt_verp, @tabrcpt_notice_verp, @tabrcpt_txt_verp, @tabrcpt_html_verp, @tabrcpt_url_verp);
    my $mixed = ($message->{'msg'}->head->get('Content-Type') =~ /multipart\/mixed/i);
    my $alternative = ($message->{'msg'}->head->get('Content-Type') =~ /multipart\/alternative/i);
 
    for ( my $user = $self->get_first_user(); $user; $user = $self->get_next_user() ){
	unless ($user->{'email'}) {
	    &do_log('err','Skipping user with no email address in list %s', $name);
	    next;
	}
#	&do_log('debug','trace distribution VERP email %s,reception %s,bounce_address %s',$user->{'email'},$user->{'reception'},$user->{'bounce_address'} );
	if ($user->{'reception'} =~ /^digest|digestplain|summary|nomail$/i) {
	    next;
	} elsif ($user->{'reception'} eq 'notice') {
	    if ($user->{'bounce_address'}) {
		push @tabrcpt_notice_verp, $user->{'email'}; 
	    }else{
		push @tabrcpt_notice, $user->{'email'}; 
	    }
        } elsif ($alternative and ($user->{'reception'} eq 'txt')) {
	    if ($user->{'bounce_address'}) {
		push @tabrcpt_txt_verp, $user->{'email'};
	    }else{
		push @tabrcpt_txt, $user->{'email'};
	    }
        } elsif ($alternative and ($user->{'reception'} eq 'html')) {
	    if ($user->{'bounce_address'}) {
		push @tabrcpt_html_verp, $user->{'email'};
	    }else{
		if ($user->{'bounce_address'}) {
		    push @tabrcpt_html_verp, $user->{'email'};
		}else{
		    push @tabrcpt_html, $user->{'email'};
		}
	   }
	} elsif ($mixed and ($user->{'reception'} eq 'urlize')) {
	    if ($user->{'bounce_address'}) {
		push @tabrcpt_url_verp, $user->{'email'};
	    }else{
		push @tabrcpt_url, $user->{'email'};
	    }
	} elsif (($message->{'smime_crypted'}) && (! -r "$Conf{'ssl_cert_dir'}/".&tools::escape_chars($user->{'email'}))) {
	    ## Missing User certificate
	    unless ($self->send_file('x509-user-cert-missing', $user->{'email'}, $robot, {'mail' => {'subject' => $message->{'msg'}->head->get('Subject'),
												     'sender' => $message->{'msg'}->head->get('From')}})) {
	    &do_log('notice',"Unable to send template 'x509-user-cert-missing' to $user->{'email'}");
	    }
	}else{
	    if ($user->{'bounce_address'}) {
		push @tabrcpt_verp, $user->{'email'} unless ($sender_hash{$user->{'email'}})&&($user->{'reception'} eq 'not_me');
	    }else{	    
		push @tabrcpt, $user->{'email'} unless ($sender_hash{$user->{'email'}})&&($user->{'reception'} eq 'not_me');}
	    }	    
       }    

    ## sa  return 0  = Pb  ?
    unless (@tabrcpt || @tabrcpt_notice || @tabrcpt_txt || @tabrcpt_html || @tabrcpt_url || @tabrcpt_verp || @tabrcpt_notice_verp || @tabrcpt_txt_verp || @tabrcpt_html_verp || @tabrcpt_url_verp) {
	&do_log('info', 'No subscriber for sending msg in list %s', $name);
	return 0;
    }
    #save the message before modifying it
    my $saved_msg = $message->{'msg'}->dup;
    my $nbr_smtp;
    my $nbr_verp;


    # prepare verp parameter
    my $verp_rate =  $self->{'admin'}{'verp_rate'};
    my $xsequence =  $self->{'stats'}->[0] ;

    ##Send message for normal reception mode
    if (@tabrcpt) {
	## Add a footer
	unless ($message->{'protected'}) {
	    my $new_msg = $self->add_parts($message->{'msg'});
	    if (defined $new_msg) {
		$message->{'msg'} = $new_msg;
		$message->{'altered'} = '_ALTERED_';
	    }
	}
	
	## TOPICS
	my @selected_tabrcpt;
	if ($self->is_there_msg_topic()){
	    @selected_tabrcpt = $self->select_subscribers_for_topic($message->get_topic(),\@tabrcpt);
	} else {
	    @selected_tabrcpt = @tabrcpt;
	}

	my @verp_selected_tabrcpt = &extract_verp_rcpt($verp_rate, $xsequence,\@selected_tabrcpt, \@tabrcpt_verp);


	my $result = &mail::mail_message($message, $self, {'enable' => 'off'}, @selected_tabrcpt);
	unless (defined $result) {
	    &do_log('err',"List::send_msg, could not send message to distribute from $from (verp desabled)");
	    return undef;
	}
	$nbr_smtp = $result;
	
	$result = &mail::mail_message($message, $self, {'enable' => 'on'}, @verp_selected_tabrcpt);
	unless (defined $result) {
	    &do_log('err',"List::send_msg, could not send message to distribute from $from (verp enabled)");
	    return undef;
	}
	$nbr_smtp += $result;
	$nbr_verp = $result;

    }

    ##Prepare and send message for notice reception mode
    if (@tabrcpt_notice) {
	my $notice_msg = $saved_msg->dup;
        $notice_msg->bodyhandle(undef);    
	$notice_msg->parts([]);
	my $new_message = new Message($notice_msg);
	
	my @verp_tabrcpt_notice = &extract_verp_rcpt($verp_rate, $xsequence,\@tabrcpt_notice, \@tabrcpt_notice_verp);

	my $result = &mail::mail_message($new_message, $self, {'enable' => 'off'}, @tabrcpt_notice);
	unless (defined $result) {
	    &do_log('err',"List::send_msg, could not send message to distribute from $from (verp desabled)");
	    return undef;
	}
	$nbr_smtp += $result;

	$result = &mail::mail_message($new_message, $self , {'enable' => 'on'}, @verp_tabrcpt_notice);
	unless (defined $result) {
	    &do_log('err',"List::send_msg, could not send message to distribute from $from  (verp enabled)");
	    return undef;
	}
	$nbr_smtp += $result;
	$nbr_verp += $result;

    }

    ##Prepare and send message for txt reception mode
    if (@tabrcpt_txt) {
	my $txt_msg = $saved_msg->dup;
	if (&tools::as_singlepart($txt_msg, 'text/plain')) {
	    do_log('notice', 'Multipart message changed to singlepart');
	}
	
	## Add a footer
	my $new_msg = $self->add_parts($txt_msg);
	if (defined $new_msg) {
	    $txt_msg = $new_msg;
	}
	my $new_message = new Message($txt_msg);

	my @verp_tabrcpt_txt = &extract_verp_rcpt($verp_rate, $xsequence,\@tabrcpt_txt, \@tabrcpt_txt_verp);
	
	my $result = &mail::mail_message($new_message, $self,  {'enable' => 'off'}, @tabrcpt_txt);
	unless (defined $result) {
	    &do_log('err',"List::send_msg, could not send message to distribute from $from  (verp desabled)");
	    return undef;
	}
	$nbr_smtp += $result;

	$result = &mail::mail_message($new_message, $self , {'enable' => 'on'}, @verp_tabrcpt_txt);
	unless (defined $result) {
	    &do_log('err',"List::send_msg, could not send message to distribute from $from  (verp enabled)");
	    return undef;
	}
	$nbr_smtp += $result;
	$nbr_verp += $result;

    }

   ##Prepare and send message for html reception mode
    if (@tabrcpt_html) {
	my $html_msg = $saved_msg->dup;
	if (&tools::as_singlepart($html_msg, 'text/html')) {
	    do_log('notice', 'Multipart message changed to singlepart');
	}
        ## Add a footer
	my $new_msg = $self->add_parts($html_msg);
	if (defined $new_msg) {
	    $html_msg = $new_msg;
        }
	my $new_message = new Message($html_msg);

	my @verp_tabrcpt_html = &extract_verp_rcpt($verp_rate, $xsequence,\@tabrcpt_html, \@tabrcpt_html_verp);

	my $result = &mail::mail_message($new_message, $self , {'enable' => 'off'}, @tabrcpt_html);
	unless (defined $result) {
	    &do_log('err',"List::send_msg, could not send message to distribute from $from  (verp desabled)");
	    return undef;
	}
	$nbr_smtp += $result;

	$result = &mail::mail_message($new_message, $self , {'enable' => 'on'}, @verp_tabrcpt_html);
	unless (defined $result) {
	    &do_log('err',"List::send_msg, could not send message to distribute from $from  (verp enabled)");
	    return undef;
	}
	$nbr_smtp += $result;
	$nbr_verp += $result;
    }

   ##Prepare and send message for urlize reception mode
    if (@tabrcpt_url) {
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
	my $new_message = new Message($url_msg);


	my @verp_tabrcpt_url = &extract_verp_rcpt($verp_rate, $xsequence,\@tabrcpt_url, \@tabrcpt_url_verp);

	my $result = &mail::mail_message($new_message, $self , {'enable' => 'off'}, @tabrcpt_url);
	unless (defined $result) {
	    &do_log('err',"List::send_msg, could not send message to distribute from $from  (verp desabled)");
	    return undef;
	}
	$nbr_smtp += $result;

	$result = &mail::mail_message($new_message, $self , {'enable' => 'on'}, @verp_tabrcpt_url);
	unless (defined $result) {
	    &do_log('err',"List::send_msg, could not send message to distribute from $from  (verp enabled)");
	    return undef;
	}
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
   my $encrypt;

   $encrypt = 'smime_crypted' if ($message->{'smime_crypted'}); 
   do_log('debug3', "List::send_to_editor, msg: $msg, file: $file method : $method, encrypt : $encrypt");

   my($i, @rcpt);
   my $admin = $self->{'admin'};
   my $name = $self->{'name'};
   my $host = $admin->{'host'};
   my $robot = $self->{'domain'};
   my $modqueue = $Conf{'queuemod'};
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
	   do_log('notice', 'Could Not open %s', $mod_file);
	   return undef;
       }

       unless (open (MSG, $file)) {
	   do_log('notice', 'Could not open %s', $file);
	   return undef;   
       }

       print OUT <MSG>;
       close MSG ;
       close(OUT);

       my $tmp_dir = $modqueue.'/.'.$self->get_list_id().'_'.$modkey;
       unless (-d $tmp_dir) {
	   unless (mkdir ($tmp_dir, 0777)) {
	       &do_log('err','Unable to create %s', $tmp_dir);
	       return undef;
	   }
	   my $mhonarc_ressources = &tools::get_filename('etc', 'mhonarc-ressources.tt2', $robot, $self);

	   unless ($mhonarc_ressources) {
	       do_log('notice',"Cannot find any MhOnArc ressource file");
	       return undef;
	   }

	   ## generate HTML
	   chdir $tmp_dir;
	   my $mhonarc = &Conf::get_robot_conf($robot, 'mhonarc');
	   
	   open ARCMOD, "$mhonarc  -single -rcfile $mhonarc_ressources -definevars listname=$name -definevars hostname=$host $mod_file|";
	   open MSG, ">msg00000.html";
	   

	   &do_log('debug', "$mhonarc  -single -rcfile $mhonarc_ressources -definevars listname=$name -definevars hostname=$host $mod_file");

########################## APRES
	   print MSG <ARCMOD>;
########################## AVANT

	   close MSG;
	   close ARCMOD;
	   chdir $Conf{'home'};

       }
   }

   @rcpt = $self->get_editors_email();
   unless (@rcpt) {
       do_log('notice','Warning : no editor defined for list %s, contacting owners', $name );
   }

   my $param = {'modkey' => $modkey,
		'boundary' => $boundary,
		'msg_from' => $message->{'sender'},
		'mod_spool_size' => $self->get_mod_spool_size(),
		'method' => $method};

   if ($self->is_there_msg_topic()) {
       $param->{'request_topic'} = 1;
   }

   if ($encrypt eq 'smime_crypted') {

       ## Send a different crypted message to each moderator
       foreach my $recipient (@rcpt) {

	   ## $msg->body_as_string respecte-t-il le Base64 ??
	   my $cryptedmsg = &tools::smime_encrypt($msg->head, $msg->body_as_string, $recipient); 
	   unless ($cryptedmsg) {
	       &do_log('notice', 'Failed encrypted message for moderator');
	       # xxxx send a generic error message : X509 cert missing
	       return undef;
	   }

	   my $crypted_file = $Conf{'tmpdir'}.'/'.$self->get_list_id().'.moderate.'.$$;
	   unless (open CRYPTED, ">$crypted_file") {
	       &do_log('notice', 'Could not create file %s', $crypted_file);
	       return undef;
	   }
	   print CRYPTED $cryptedmsg;
	   close CRYPTED;
	   

	   $param->{'msg'} = $crypted_file;

	   &tt2::allow_absolute_path();
	   unless ($self->send_file('moderate', $recipient, $self->{'domain'}, $param)) {
	       &do_log('notice',"Unable to send template 'moderate' to $recipient");
	       return undef;
	   }
       }
   }else{
       $param->{'msg'} = $file;

       &tt2::allow_absolute_path();
       unless ($self->send_file('moderate', \@rcpt, $self->{'domain'}, $param)) {
	   &do_log('notice',"Unable to send template 'moderate' to $self->{'name'} editors");
	   return undef;
       }
   }
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
   &do_log('debug3', 'List::send_auth(%s, %s)', $sender, $file);

   ## Ensure 1 second elapsed since last message
   sleep (1);

   my($i, @rcpt);
   my $admin = $self->{'admin'};
   my $name = $self->{'name'};
   my $host = $admin->{'host'};
   my $robot = $self->{'domain'};
   my $authqueue = $Conf{'queueauth'};
   return undef unless ($name && $admin);
  

   my @now = localtime(time);
   my $messageid = $now[6].$now[5].$now[4].$now[3].$now[2].$now[1]."."
                   .int(rand(6)).int(rand(6)).int(rand(6)).int(rand(6))
		   .int(rand(6)).int(rand(6))."\@".$host;
   my $authkey = Digest::MD5::md5_hex(join('/', $self->get_cookie(),$messageid));
     
   my $auth_file = $authqueue.'/'.$self->get_list_id().'_'.$authkey;   
   unless (open OUT, ">$auth_file") {
       &do_log('notice', 'Cannot create file %s', $auth_file);
       return undef;
   }

   unless (open IN, $file) {
       &do_log('notice', 'Cannot open file %s', $file);
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
   unless ($self->send_file('send_auth',$sender,$robot,$param)) {
       &do_log('notice',"Unable to send template 'send_auth' to $sender");
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
    do_log('debug2', 'List::request_auth(%s, %s, %s, %s)', @_);
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
    &do_log('debug3', 'List::request_auth() List : %s,$email: %s cmd : %s',$self->{'name'},$email,$cmd);

    
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
	unless ($self->send_file('request_auth',$email,$robot,$data)) {
	    &do_log('notice',"Unable to send template 'request_auth' to $email");
	    return undef;
	}

    }else {
	if ($cmd eq 'remind'){
	    my $keyauth = &List::compute_auth('',$cmd);
	    $data->{'command'} = "auth $keyauth $cmd *";
	    $data->{'command_escaped'} = &tt2::escape_url($data->{'command'});
	    $data->{'type'} = 'remind';
	}

	unless (&send_global_file('request_auth',$email,$robot,$data)) {
	    &do_log('notice',"Unable to send template 'request_auth' to $email");
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
   do_log('debug', 'List::archive_send(%s, %s)', $who, $file);

   return unless ($self->is_archived());
       
   my $dir = &Conf::get_robot_conf($self->{'domain'},'arc_path').'/'.$self->get_list_id();
   $dir = $self->{'dir'}.'/archives' if ($file eq 'last_message');

   my $msg_list = Archive::scan_dir_archive($dir, $file);


   my $subject = 'File '.$self->{'name'}.' '.$file ;
   my $param = {'to' => $who,
		'subject' => $subject,
		'msg_list' => $msg_list } ;


   $param->{'boundary1'} = &tools::get_message_id($self->{'domain'});
   $param->{'boundary2'} = &tools::get_message_id($self->{'domain'});
   $param->{'from'} = &Conf::get_robot_conf($self->{'domain'},'sympa');

#    open TMP2, ">/tmp/digdump"; &tools::dump_var($param, 0, \*TMP2); close TMP2;

   unless ($self->send_file('get_archive',$who,$self->{'domain'},$param)) {
	   &do_log('notice',"Unable to send template 'archive_send' to $who");
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
    &do_log('debug2', 'List::send_notify_to_listmaster(%s,%s )', $operation, $robot );

    unless (defined $operation) {
	&do_log('err','List::send_notify_to_listmaster(%s) : missing incoming parameter "$operation"');
	return undef;
    }
    unless (defined $robot) {
	&do_log('err','List::send_notify_to_listmaster(%s) : missing incoming parameter "$robot"');
	return undef;
    }


    my $host = &Conf::get_robot_conf($robot, 'host');
    my $listmaster = &Conf::get_robot_conf($robot, 'listmaster');
    my $to = "$Conf{'listmaster_email'}\@$host";

    if (ref($param) eq 'HASH') {

	$param->{'to'} = $to;
	$param->{'type'} = $operation;

	## Automatic action done on bouncing adresses
	if ($operation eq 'automatic_bounce_management') {
	    my $list = new List ($param->{'listname'}, $robot);
	    unless (defined $list) {
		&do_log('err','Parameter %s is not a valid list', $param->{'listname'});
		return undef;
	    }
	    unless ($list->send_file('listmaster_notification',$listmaster, $robot,$param)) {
		&do_log('notice',"Unable to send template 'listmaster_notification' to $listmaster");
		return undef;
	    }
	    
	}else {		
	    
	    ## No DataBase |  DataBase restored
	    if (($operation eq 'no_db')||($operation eq 'db_restored')) {
		
		$param->{'db_name'} = &Conf::get_robot_conf($robot, 'db_name');  
		
	    ## creation list requested
	    }elsif ($operation eq 'request_list_creation') {
		my $list = new List ($param->{'listname'}, $robot);
		unless (defined $list) {
		    &do_log('err','Parameter %s is not a valid list', $param->{'listname'});
		    return undef;
		}
		$param->{'list'} = {'name' => $list->{'name'},
				    'host' => $list->{'domain'},
				    'subject' => $list->{'admin'}{'subject'}};
				
	    ## Loop detected in Sympa
	    }elsif ($operation eq 'loop_command') {
		$param->{'boundary'} = '----------=_'.&tools::get_message_id($robot);
		&tt2::allow_absolute_path();
	    }

	    unless (&send_global_file('listmaster_notification', $listmaster, $robot,$param)) {
		&do_log('notice',"Unable to send template 'listmaster_notification' to $listmaster");
		return undef;
	    }
	}
    
    }elsif(ref($param) eq 'ARRAY') {
	
	my $data = {'to' => $to,
		    'type' => $operation};
	for my $i(0..$#{$param}) {
	    $data->{"param$i"} = $param->[$i];
	}
	unless (&send_global_file('listmaster_notification', $listmaster, $robot, $data)) {
	    &do_log('notice',"Unable to send template 'listmaster_notification' to $listmaster");
	    return undef;
	}

    }else {
	&do_log('err','List::send_notify_to_listmaster(%s,%s) : error on incoming parameter "$param", it must be a ref on HASH or a ref on ARRAY', $operation, $robot );
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
    &do_log('debug2', 'List::send_notify_to_owner(%s, %s)', $self->{'name'}, $operation);

    my $host = $self->{'admin'}{'host'};
    my @to = $self->get_owners_email;
    my $robot = $self->{'domain'};

    unless (@to) {
	do_log('notice', 'Warning : no owner defined or all of them use nomail option in list %s', $self->{'name'} );
	return undef;
    }
    unless (defined $operation) {
	&do_log('err','List::send_notify_to_owner(%s) : missing incoming parameter "$operation"', $self->{'name'});
	return undef;
    }

    if (ref($param) eq 'HASH') {

	$param->{'to'} =join(',', @to);
	$param->{'type'} = $operation;

	if ($operation eq 'subrequest') {
	    $param->{'escaped_gecos'} = $param->{'gecos'};
	    $param->{'escaped_gecos'} =~ s/\s/\%20/g;
	    $param->{'escaped_who'} = $param->{'who'};
	    $param->{'escaped_who'} =~ s/\s/\%20/g;

	}elsif ($operation eq 'sigrequest') {
	    $param->{'escaped_who'} = $param->{'who'};
	    $param->{'escaped_who'} =~ s/\s/\%20/g;
	    $param->{'sympa'} = &Conf::get_robot_conf($self->{'domain'}, 'sympa');

	}elsif ($operation eq 'bounce_rate') {
	    $param->{'rate'} = int ($param->{'rate'} * 10) / 10;
	}

	unless ($self->send_file('listowner_notification',\@to, $robot,$param)) {
	    &do_log('notice',"Unable to send template 'listowner_notification' to $self->{'name'} list owner");
	    return undef;
	}

    }elsif(ref($param) eq 'ARRAY') {	

	my $data = {'to' => join(',', @to),
		    'type' => $operation};

	for my $i(0..$#{$param}) {
		$data->{"param$i"} = $param->[$i];
 	}
 	unless ($self->send_file('listowner_notification', \@to, $robot, $data)) {
	    &do_log('notice',"Unable to send template 'listowner_notification' to $self->{'name'} list owner");
	    return undef;
	}

    }else {

	&do_log('err','List::send_notify_to_owner(%s,%s) : error on incoming parameter "$param", it must be a ref on HASH or a ref on ARRAY', $self->{'name'},$operation);
	return undef;
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
    &do_log('debug2', 'List::send_notify_to_editor(%s, %s)', $self->{'name'}, $operation);

    my @to = $self->get_editors_email();
    my $robot = $self->{'domain'};

    unless (@to) {
	do_log('notice', 'Warning : no editor or owner defined or all of them use nomail option in list %s', $self->{'name'} );
	return undef;
    }
    unless (defined $operation) {
	&do_log('err','List::send_notify_to_editor(%s) : missing incoming parameter "$operation"', $self->{'name'});
	return undef;
    }
    if (ref($param) eq 'HASH') {

	$param->{'to'} =join(',', @to);
	$param->{'type'} = $operation;

	unless ($self->send_file('listeditor_notification',\@to, $robot,$param)) {
	    &do_log('notice',"Unable to send template 'listeditor_notification' to $self->{'name'} list editor");
	    return undef;
	}
	
    }elsif(ref($param) eq 'ARRAY') {	
	
	my $data = {'to' => join(',', @to),
		    'type' => $operation};
	
	foreach my $i(0..$#{$param}) {
	    $data->{"param$i"} = $param->[$i];
 	}
 	unless ($self->send_file('listeditor_notification', \@to, $robot, $data)) {
	    &do_log('notice',"Unable to send template 'listeditor_notification' to $self->{'name'} list editor");
	    return undef;
	}	
	
    }else {
	&do_log('err','List::send_notify_to_editor(%s,%s) : error on incoming parameter "$param", it must be a ref on HASH or a ref on ARRAY', $self->{'name'},$operation);
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
    &do_log('debug2', 'List::send_notify_to_user(%s, %s, %s)', $self->{'name'}, $operation, $user);

    my $host = $self->{'admin'}->{'host'};
    my $robot = $self->{'domain'};
    
    unless (defined $operation) {
	&do_log('err','List::send_notify_to_user(%s) : missing incoming parameter "$operation"', $self->{'name'});
	return undef;
    }
    unless ($user) {
	&do_log('err','List::send_notify_to_user(%s) : missing incoming parameter "$user"', $self->{'name'});
	return undef;
    }
    
    if (ref($param) eq "HASH") {
	$param->{'to'} = $user;
	$param->{'type'} = $operation;

	if ($operation eq 'auto_notify_bouncers') {	
	}
	
 	unless ($self->send_file('user_notification',$user,$robot,$param)) {
	    &do_log('notice',"Unable to send template 'user_notification' to $user");
	    return undef;
	}

    }elsif (ref($param) eq "ARRAY") {	
	
	my $data = {'to' => $user,
		    'type' => $operation};
	
	for my $i(0..$#{$param}) {
	    $data->{"param$i"} = $param->[$i];
 	}
 	unless ($self->send_file('user_notification',$user,$robot,$data)) {
	    &do_log('notice',"Unable to send template 'user_notification' to $user");
	    return undef;
	}	
	
    }else {
	
	&do_log('err','List::send_notify_to_user(%s,%s,%s) : error on incoming parameter "$param", it must be a ref on HASH or a ref on ARRAY', 
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
    do_log('debug3', 'List::compute_auth(%s, %s, %s)', @_);

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
        $cookie = $self->get_cookie() || $Conf{'cookie'};
    }else {
	$cookie = $Conf{'cookie'};
    }
    
    $key = substr(Digest::MD5::md5_hex(join('/', $cookie, $listname, $email, $cmd)), -8) ;

    return $key;
}


## Add footer/header to a message
sub add_parts {
    my ($self, $msg) = @_;
    my ($listname,$type) = ($self->{'name'}, $self->{'admin'}{'footer_type'});
    my $listdir = $self->{'dir'};
    do_log('debug2', 'List:add_parts(%s, %s, %s)', $msg, $listname, $type);

    my ($header, $headermime);
    foreach my $file ("$listdir/message.header", 
		      "$listdir/message.header.mime",
		      "$Conf{'etc'}/mail_tt2/message.header", 
		      "$Conf{'etc'}/mail_tt2/message.header.mime") {
	if (-f $file) {
	    unless (-r $file) {
		&do_log('notice', 'Cannot read %s', $file);
		next;
	    }
	    $header = $file;
	    last;
	} 
    }

    my ($footer, $footermime);
    foreach my $file ("$listdir/message.footer", 
		      "$listdir/message.footer.mime",
		      "$Conf{'etc'}/mail_tt2/message.footer", 
		      "$Conf{'etc'}/mail_tt2/message.footer.mime") {
	if (-f $file) {
	    unless (-r $file) {
		&do_log('notice', 'Cannot read %s', $file);
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
		    
	    my @body = $msg->bodyhandle->as_lines;
	    $msg->bodyhandle (new MIME::Body::Scalar [@header_msg,@body,@footer_msg] );

	}elsif ($content_type =~ /^multipart\/mixed/i) {
	    ## Append to first part if text/plain
	    
	    if ($msg->parts(0)->head->get('Content-Type') =~ /^text\/plain/i) {
		
		my $part = $msg->parts(0);
		my @body = $part->bodyhandle->as_lines;
		$part->bodyhandle (new MIME::Body::Scalar [@header_msg,@body,@footer_msg] );
	    }else {
		&do_log('notice', 'First part of message not in text/plain ; ignoring footers and headers');
	    }

	}elsif ($content_type =~ /^multipart\/alternative/i) {
	    ## Append to first text/plain part

	    foreach my $part ($msg->parts) {
		&do_log('debug3', 'TYPE: %s', $part->head->get('Content-Type'));
		if ($part->head->get('Content-Type') =~ /^text\/plain/i) {

		    my @body = $part->bodyhandle->as_lines;
		    $part->bodyhandle (new MIME::Body::Scalar [@header_msg,@body,@footer_msg] );
		    next;
		}
	    }
	}

    }else {
	if ($content_type =~ /^multipart\/alternative/i) {

	    &do_log('notice', 'Making multipart/alternative into multipart/mixed'); 
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
		Encoding    => "8bit";
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
			     Encoding    => "8bit"
			     );
	    }
	}
    }

    return $msg;
}




## Delete a new user to Database (in User table)
sub delete_user_db {
    my @users = @_;
    
    do_log('debug2', 'List::delete_user_db');
    
    return undef unless ($#users >= 0);
    
    unless ($List::use_db) {
	&do_log('info', 'Sympa not setup to use DBI');
	return undef;
    }
    
    ## Check database connection
    unless ($dbh and $dbh->ping) {
	return undef unless &db_connect();
    }	   

    foreach my $who (@users) {
	my $statement;
	
	$who = &tools::clean_email($who);
	
	## Update field
	$statement = sprintf "DELETE FROM user_table WHERE (email_user =%s)", $dbh->quote($who); 
	
	unless ($dbh->do($statement)) {
	    do_log('err','Unable to execute SQL statement "%s" : %s', $statement, $dbh->errstr);
	    next;
	}
    }

    return $#users + 1;
}

## Delete the indicate users from the list.
sub delete_user {
    my($self, @u) = @_;
    do_log('debug2', 'List::delete_user');

    my $name = $self->{'name'};
    my $total = 0;
    
    if (($self->{'admin'}{'user_data_source'} eq 'database') ||
	($self->{'admin'}{'user_data_source'} eq 'include2')){
	
	## Check database connection
	unless ($dbh and $dbh->ping) {
	    return undef unless &db_connect();
	}
	    
	foreach my $who (@u) {
	    $who = &tools::clean_email($who);
	    my $statement;
	    
	    $list_cache{'is_user'}{$self->{'domain'}}{$name}{$who} = undef;    
	    
	    ## Delete record in SUBSCRIBER
	    $statement = sprintf "DELETE FROM subscriber_table WHERE (user_subscriber=%s AND list_subscriber=%s AND robot_subscriber=%s)",
 	    $dbh->quote($who), 
 	    $dbh->quote($name), 
 	    $dbh->quote($self->{'domain'});

	    
	    unless ($dbh->do($statement)) {
		do_log('err','Unable to execute SQL statement %s : %s', $statement, $dbh->errstr);
		next;
	    }   

	    $total--;
	}
    }else {
	my $users = $self->{'users'};

	foreach my $who (@u) {
	    $who = &tools::clean_email($who);
	    
	    delete $self->{'users'}{$who};
	    $total-- unless (exists $users->{$who});
	}
    }

    $self->{'total'} += $total;
    $self->savestats();
    return (-1 * $total);
}


## Delete the indicated admin users from the list.
sub delete_admin_user {
    my($self, $role, @u) = @_;
    do_log('debug2', 'List::delete_admin_user(%s)', $role); 

    my $name = $self->{'name'};
    my $total = 0;
    
    unless($self->{'admin'}{'user_data_source'} eq 'include2'){
	&do_log('err', 'Cannot delete %s in list %s, user_data_source different than include2 ',$role, $self->{'name'}); 
	return undef;
    }

    ## Check database connection
    unless ($dbh and $dbh->ping) {
	return undef unless &db_connect();
    }
	    
    foreach my $who (@u) {
	$who = &tools::clean_email($who);
	my $statement;
	
	$list_cache{'is_admin_user'}{$self->{'domain'}}{$name}{$who} = undef;    
	    
	## Delete record in ADMIN
	$statement = sprintf "DELETE FROM admin_table WHERE (user_admin=%s AND list_admin=%s AND robot_admin=%s AND role_admin=%s)",
	$dbh->quote($who), 
	$dbh->quote($name),
	$dbh->quote($self->{'domain'}),
	$dbh->quote($role);
	
	unless ($dbh->do($statement)) {
	    do_log('err','Unable to execute SQL statement %s : %s', $statement, $dbh->errstr);
	    next;
	}   
	
	$total--;
    }
    
    return (-1 * $total);
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
    do_log('debug3', 'List::get_default_user_options(%s)', $what);

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
    &do_log('debug3','List::get_total(%s)', $name);

    if (($self->{'admin'}{'user_data_source'} eq 'database') ||
	($self->{'admin'}{'user_data_source'} eq 'include2')) {
	if ($option eq 'nocache') {
	    $self->{'total'} = $self->_load_total_db($option);
	}
    }
#    if ($self->{'admin'}{'user_data_source'} eq 'database') {
	## If stats file was updated
#	my $time = (stat("$name/stats"))[9];
#	if ($time > $self->{'mtime'}[0]) {
#	    $self->{'total'} = $self->_load_total_db();
#	}
#    }
    
    return $self->{'total'};
}

## Returns a hash for a given user
sub get_user_db {
    my $who = &tools::clean_email(shift);
    do_log('debug2', 'List::get_user_db(%s)', $who);

    my $statement;
 
    unless ($List::use_db) {
	&do_log('info', 'Sympa not setup to use DBI');
	return undef;
    }

    ## Check database connection
    unless ($dbh and $dbh->ping) {
	return undef unless &db_connect();
    }

    ## Additional subscriber fields
    my $additional;
    if ($Conf{'db_additional_user_fields'}) {
	$additional = ',' . $Conf{'db_additional_user_fields'};
    }

    if ($Conf{'db_type'} eq 'Oracle') {
	## "AS" not supported by Oracle
	$statement = sprintf "SELECT email_user \"email\", gecos_user \"gecos\", password_user \"password\", cookie_delay_user \"cookie_delay\", lang_user \"lang\", attributes_user \"attributes\" %s FROM user_table WHERE email_user = %s ", $additional, $dbh->quote($who);
    }else {
	$statement = sprintf "SELECT email_user AS email, gecos_user AS gecos, password_user AS password, cookie_delay_user AS cookie_delay, lang_user AS lang %s, attributes_user AS attributes FROM user_table WHERE email_user = %s ", $additional, $dbh->quote($who);
    }
    
    push @sth_stack, $sth;

    unless ($sth = $dbh->prepare($statement)) {
	do_log('err','Unable to prepare SQL statement : %s', $dbh->errstr);
	return undef;
    }
    
    unless ($sth->execute) {
	do_log('err','Unable to execute SQL statement "%s" : %s', $statement, $dbh->errstr);
	return undef;
    }
    
    my $user = $sth->fetchrow_hashref;
 
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
	foreach my $attr (split /;/, $attributes) {
	    my ($key, $value) = split /=/, $attr;
	    $user->{'attributes'}{$key} = $value;
	}    
    }

    return $user;
}

## Returns an array of all users in User table hash for a given user
sub get_all_user_db {
    do_log('debug2', 'List::get_all_user_db()');

    my $statement;
    my @users;
 
    unless ($List::use_db) {
	&do_log('info', 'Sympa not setup to use DBI');
	return undef;
    }

    ## Check database connection
    unless ($dbh and $dbh->ping) {
	return undef unless &db_connect();
    }

    $statement = sprintf "SELECT email_user FROM user_table";
    
    push @sth_stack, $sth;

    unless ($sth = $dbh->prepare($statement)) {
	do_log('err','Unable to prepare SQL statement : %s', $dbh->errstr);
	return undef;
    }
    
    unless ($sth->execute) {
	do_log('err','Unable to execute SQL statement "%s" : %s', $statement, $dbh->errstr);
	return undef;
    }
    
    while (my $email = ($sth->fetchrow_array)[0]) {
	push @users, $email;
    }
 
    $sth->finish();

    $sth = pop @sth_stack;

    return @users;
}


## Returns a subscriber of the list.
sub get_subscriber {
    my  $self= shift;
    my  $email = &tools::clean_email(shift);
    
    do_log('debug2', 'List::get_subscriber(%s)', $email);

    if (($self->{'admin'}{'user_data_source'} eq 'database') ||
	($self->{'admin'}{'user_data_source'} eq 'include2')){

	my $name = $self->{'name'};
	my $statement;
	my $date_field = sprintf $date_format{'read'}{$Conf{'db_type'}}, 'date_subscriber', 'date_subscriber';
	my $update_field = sprintf $date_format{'read'}{$Conf{'db_type'}}, 'update_subscriber', 'update_subscriber';	

	## Use session cache
	if (defined $list_cache{'get_subscriber'}{$self->{'domain'}}{$name}{$email}) {
	    &do_log('debug3', 'xxx Use cache(get_subscriber, %s,%s)', $name, $email);
	    return $list_cache{'get_subscriber'}{$self->{'domain'}}{$name}{$email};
	}

	## Check database connection
	unless ($dbh and $dbh->ping) {
	    return undef unless &db_connect();
	}

	## Additional subscriber fields
	my $additional;
	if ($Conf{'db_additional_subscriber_fields'}) {
	    $additional = ',' . $Conf{'db_additional_subscriber_fields'};
	}

	if ($Conf{'db_type'} eq 'Oracle') {
	    ## "AS" not supported by Oracle
	    $statement = sprintf "SELECT user_subscriber \"email\", comment_subscriber \"gecos\", bounce_subscriber \"bounce\", bounce_score_subscriber \"bounce_score\", bounce_address_subscriber \"bounce_address\", reception_subscriber \"reception\", topics_subscriber \"topics\", visibility_subscriber \"visibility\", %s \"date\", %s \"update_date\", subscribed_subscriber \"subscribed\", included_subscriber \"included\", include_sources_subscriber \"id\"  %s FROM subscriber_table WHERE (user_subscriber = %s AND list_subscriber = %s AND robot_subscriber = %s)", 
	    $date_field, 
	    $update_field, 
	    $additional, 
	    $dbh->quote($email), 
	    $dbh->quote($name),
	    $dbh->quote($self->{'domain'});
	}else {
	    $statement = sprintf "SELECT user_subscriber AS email, comment_subscriber AS gecos, bounce_subscriber AS bounce, bounce_score_subscriber AS bounce_score, bounce_address_subscriber AS bounce_address, reception_subscriber AS reception,  topics_subscriber AS topics, visibility_subscriber AS visibility, %s AS date, %s AS update_date, subscribed_subscriber AS subscribed, included_subscriber AS included, include_sources_subscriber AS id %s FROM subscriber_table WHERE (user_subscriber = %s AND list_subscriber = %s AND robot_subscriber = %s)", 
	    $date_field, 
	    $update_field, 
	    $additional, 
	    $dbh->quote($email), 
	    $dbh->quote($name),
	    $dbh->quote($self->{'domain'});
	}

	push @sth_stack, $sth;

	unless ($sth = $dbh->prepare($statement)) {
	    do_log('err','Unable to prepare SQL statement : %s', $dbh->errstr);
	    return undef;
	}
	
	unless ($sth->execute) {
	    do_log('err','Unable to execute SQL statement "%s" : %s', $statement, $dbh->errstr);
	    return undef;
	}
	
	my $user = $sth->fetchrow_hashref;

	if (defined $user) {
	    $user->{'reception'} ||= 'mail';
	    $user->{'reception'} = $self->{'admin'}{'default_user_options'}{'reception'}
	    unless ($self->is_available_reception_mode($user->{'reception'}));
	    
	    $user->{'update_date'} ||= $user->{'date'};

	    ## In case it was not set in the database
	    $user->{'subscribed'} = 1
		if ($self->{'admin'}{'user_data_source'} eq 'database');

	}

	$sth->finish();

	$sth = pop @sth_stack;

	## Set session cache
	$list_cache{'get_subscriber'}{$self->{'domain'}}{$name}{$email} = $user;

	return $user;
    }else {
	my $i;
	return undef 
	    unless $self->{'users'}{$email};

	my %user = split(/\n/, $self->{'users'}{$email});

	$user{'reception'} ||= 'mail';
	$user{'reception'} = $self->{'admin'}{'default_user_options'}{'reception'}
	     unless ($self->is_available_reception_mode($user{'reception'}));
	
	## In case it was not set in the database
	$user{'subscribed'} = 1 if (defined(%user));

	return \%user;
    }
}
## Returns an array of all users in User table hash for a given user
sub get_subscriber_by_bounce_address {

    my  $self= shift;
    my  $bounce_address = &tools::clean_email(shift);
    
    do_log('debug2', 'List::get_subscriber_by_bounce_address (%s)', $bounce_address);

    return undef unless $bounce_address;

    my $statement;
    my @users;
    my @subscribers;
 
    unless ($List::use_db) {
	&do_log('info', 'Sympa not setup to use DBI');
	return undef;
    }

    my $listname = $self->{'name'};
    my $robot = $self->{'domain'};

    ## Check database connection
    unless ($dbh and $dbh->ping) {
	return undef unless &db_connect();
    }

    return undef unless (($self->{'admin'}{'user_data_source'} eq 'database') || ($self->{'admin'}{'user_data_source'} eq 'include2'));

    $statement = sprintf "SELECT user_subscriber AS email, bounce_address_subscriber AS bounce_address FROM subscriber_table WHERE (list_subscriber=%s AND robot_subscriber=%s AND bounce_address_subscriber LIKE %s",$dbh->quote($listname),$dbh->quote($robot),$dbh->quote($bounce_address);
    
    push @sth_stack, $sth;

    unless ($sth = $dbh->prepare($statement)) {
	do_log('err','Unable to prepare SQL statement : %s', $dbh->errstr);
	return undef;
    }
    unless ($sth->execute) {
	do_log('err','Unable to execute SQL statement "%s" : %s', $statement, $dbh->errstr);
	return undef;
    }
    while (my $subscriber = $sth->fetchrow_hashref) {
	push @subscribers, $subscriber;
    }
    $sth->finish();
    $sth = pop @sth_stack;
    return @subscribers;
}


## Returns an admin user of the list.
sub get_admin_user {
    my  $self= shift;
    my  $role= shift;
    my  $email = &tools::clean_email(shift);
    
    do_log('debug2', 'List::get_admin_user(%s,%s)', $role,$email); 

    unless($self->{'admin'}{'user_data_source'} eq 'include2'){
	&do_log('err', 'Cannot add %s in list %s, user_data_source different than include2 ', $role, $self->{'name'}); 
	return undef;
    }

    my $name = $self->{'name'};
    my $statement;
    my $date_field = sprintf $date_format{'read'}{$Conf{'db_type'}}, 'date_admin', 'date_admin';
    my $update_field = sprintf $date_format{'read'}{$Conf{'db_type'}}, 'update_admin', 'update_admin';	

    ## Use session cache
    if (defined $list_cache{'get_admin_user'}{$self->{'domain'}}{$name}{$role}{$email}) {
	&do_log('debug3', 'xxx Use cache(get_admin_user, %s,%s,%s)', $name, $role, $email);
	return $list_cache{'get_admin_user'}{$self->{'domain'}}{$name}{$role}{$email};
    }

    ## Check database connection
    unless ($dbh and $dbh->ping) {
	return undef unless &db_connect();
    }

    if ($Conf{'db_type'} eq 'Oracle') {
	## "AS" not supported by Oracle
	$statement = sprintf "SELECT user_admin \"email\", comment_admin \"gecos\", reception_admin \"reception\", %s \"date\", %s \"update_date\", info_admin \"info\", profile_admin \"profile\",  subscribed_admin \"subscribed\", included_admin \"included\", include_sources_admin \"id\"  FROM admin_table WHERE (user_admin = %s AND list_admin = %s AND robot_admin = %s AND role_admin = %s)", 
	$date_field, 
	$update_field, 
	$dbh->quote($email), 
	$dbh->quote($name), 
	$dbh->quote($self->{'domain'}),
 	$dbh->quote($role);
    }else {
	$statement = sprintf "SELECT user_admin AS email, comment_admin AS gecos, reception_admin AS reception, %s AS date, %s AS update_date, info_admin AS info, profile_admin AS profile, subscribed_admin AS subscribed, included_admin AS included, include_sources_admin AS id FROM admin_table WHERE (user_admin = %s AND list_admin = %s AND robot_admin = %s AND role_admin = %s)", 
	$date_field, 
	$update_field, 
	$dbh->quote($email), 
	$dbh->quote($name), 
	$dbh->quote($self->{'domain'}),
	$dbh->quote($role);
    }
    
    push @sth_stack, $sth;

    unless ($sth = $dbh->prepare($statement)) {
	do_log('err','Unable to prepare SQL statement : %s', $dbh->errstr);
	return undef;
    }
    
    unless ($sth->execute) {
	do_log('err','Unable to execute SQL statement "%s" : %s', $statement, $dbh->errstr);
	return undef;
    }
    
    my $admin_user = $sth->fetchrow_hashref;

    if (defined $admin_user) {
	$admin_user->{'reception'} ||= 'mail';
	$admin_user->{'update_date'} ||= $admin_user->{'date'};
	
	## In case it was not set in the database
	$admin_user->{'subscribed'} = 1
	    if ($self->{'admin'}{'user_data_source'} eq 'database');
    }
    
    $sth->finish();
    
    $sth = pop @sth_stack;
    
    ## Set session cache
    $list_cache{'get_admin_user'}{$self->{'domain'}}{$name}{$role}{$email} = $admin_user;
    
    return $admin_user;
    
}


## Returns the first user for the list.
sub get_first_user {
    my ($self, $data) = @_;

    my ($sortby, $offset, $rows, $sql_regexp);
    $sortby = $data->{'sortby'};
    ## Sort may be domain, email, date
    $sortby ||= 'domain';
    $offset = $data->{'offset'};
    $rows = $data->{'rows'};
    $sql_regexp = $data->{'sql_regexp'};

    do_log('debug2', 'List::get_first_user(%s,%s,%d,%d)', $self->{'name'},$sortby, $offset, $rows);
        
    if (($self->{'admin'}{'user_data_source'} eq 'database') ||
	($self->{'admin'}{'user_data_source'} eq 'include2')){

	if ($self->{'admin'}{'user_data_source'} eq 'include2') {
	    ## Get an Shared lock
	    $include_lock_count++;

	    ## first lock
	    if ($include_lock_count == 1) {
		my $lock_file = $self->{'dir'}.'/include.lock';
		
		## Create include.lock if needed
		unless (-f $lock_file) {
		    unless (open FH, ">>$lock_file") {
			&do_log('err', 'Cannot open %s: %s', $lock_file, $!);
			return undef;
		    }
		}
		close $lock_file;

		unless ($list_of_fh{$lock_file} = &tools::lock($lock_file,'read')) {
		    return undef;
		}
	    }
	}

	my $name = $self->{'name'};
	my $statement;
	my $date_field = sprintf $date_format{'read'}{$Conf{'db_type'}}, 'date_subscriber', 'date_subscriber';
	my $update_field = sprintf $date_format{'read'}{$Conf{'db_type'}}, 'update_subscriber', 'update_subscriber';
	
	## Check database connection
	unless ($dbh and $dbh->ping) {
	    return undef unless &db_connect();
	}

	## SQL regexp
	my $selection;
	if ($sql_regexp) {
	    $selection = sprintf " AND (user_subscriber LIKE %s OR comment_subscriber LIKE %s)"
		,$dbh->quote($sql_regexp), $dbh->quote($sql_regexp);
	}

	## Additional subscriber fields
	my $additional;
	if ($Conf{'db_additional_subscriber_fields'}) {
	    $additional = ',' . $Conf{'db_additional_subscriber_fields'};
	}
	
	## Oracle
	if ($Conf{'db_type'} eq 'Oracle') {

	    $statement = sprintf "SELECT user_subscriber \"email\", comment_subscriber \"gecos\", reception_subscriber \"reception\", topics_subscriber \"topics\", visibility_subscriber \"visibility\", bounce_subscriber \"bounce\", bounce_score_subscriber \"bounce_score\", bounce_address_subscriber \"bounce_address\", %s \"date\", %s \"update_date\", subscribed_subscriber \"subscribed\", included_subscriber \"included\", include_sources_subscriber \"id\" %s FROM subscriber_table WHERE (list_subscriber = %s AND robot_subscriber = %s %s)", 
	    $date_field, 
	    $update_field, 
	    $additional, 
	    $dbh->quote($name), 
	    $dbh->quote($self->{'domain'}),
	    $selection;

	    ## SORT BY
	    if ($sortby eq 'domain') {
		$statement = sprintf "SELECT user_subscriber \"email\", comment_subscriber \"gecos\", reception_subscriber \"reception\", topics_subscriber \"topics\", visibility_subscriber \"visibility\", bounce_subscriber \"bounce\", bounce_score_subscriber \"bounce_score\",bounce_address_subscriber \"bounce_address\", %s \"date\", %s \"update_date\", subscribed_subscriber \"subscribed\", included_subscriber \"included\", include_sources_subscriber \"id\", substr(user_subscriber,instr(user_subscriber,'\@')+1) \"dom\" %s FROM subscriber_table WHERE (list_subscriber = %s AND robot_subscriber = %s) ORDER BY \"dom\"", 
		$date_field, 
		$update_field, 
		$additional, 
		$dbh->quote($name),
		$dbh->quote($self->{'domain'});

	    }elsif ($sortby eq 'email') {
		$statement .= " ORDER BY \"email\"";

	    }elsif ($sortby eq 'date') {
		$statement .= " ORDER BY \"date\" DESC";

	    }elsif ($sortby eq 'sources') {
		$statement .= " ORDER BY \"subscribed\" DESC,\"id\"";

	    }elsif ($sortby eq 'name') {
		$statement .= " ORDER BY \"gecos\"";
	    } 

	## Sybase
	}elsif ($Conf{'db_type'} eq 'Sybase'){

	    $statement = sprintf "SELECT user_subscriber \"email\", comment_subscriber \"gecos\", reception_subscriber \"reception\", topics_subscriber \"topics\", visibility_subscriber \"visibility\", bounce_subscriber \"bounce\", bounce_score_subscriber \"bounce_score\", bounce_address_subscriber \"bounce_address\", %s \"date\", %s \"update_date\", subscribed_subscriber \"subscribed\", included_subscriber \"included\", include_sources_subscriber \"id\" %s FROM subscriber_table WHERE (list_subscriber = %s AND robot_subscriber = %s %s)", 
	    $date_field, 
	    $update_field, 
	    $additional, 
	    $dbh->quote($name), 
	    $dbh->quote($self->{'domain'}),
	    $selection;
	    
	    ## SORT BY
	    if ($sortby eq 'domain') {
		$statement = sprintf "SELECT user_subscriber \"email\", comment_subscriber \"gecos\", reception_subscriber \"reception\", topics_subscriber \"topics\", visibility_subscriber \"visibility\", bounce_subscriber \"bounce\", bounce_score_subscriber \"bounce_score\",  bounce_address_subscriber \"bounce_address\",%s \"date\", %s \"update_date\", subscribed_subscriber \"subscribed\", included_subscriber \"included\", include_sources_subscriber \"id\", substring(user_subscriber,charindex('\@',user_subscriber)+1,100) \"dom\" %s FROM subscriber_table WHERE (list_subscriber = %s AND robot_subscriber = %s) ORDER BY \"dom\"", 
		$date_field, 
		$update_field, 
		$additional, 
		$dbh->quote($name),
		$dbh->quote($self->{'domain'});
		
	    }elsif ($sortby eq 'email') {
		$statement .= " ORDER BY \"email\"";
		
	    }elsif ($sortby eq 'date') {
		$statement .= " ORDER BY \"date\" DESC";
		
	    }elsif ($sortby eq 'sources') {
		$statement .= " ORDER BY \"subscribed\" DESC,\"id\"";
		
	    }elsif ($sortby eq 'name') {
		$statement .= " ORDER BY \"gecos\"";
	    }
	    
	    
	    ## mysql
	}elsif ($Conf{'db_type'} eq 'mysql') {
	    
	    $statement = sprintf "SELECT user_subscriber AS email, comment_subscriber AS gecos, reception_subscriber AS reception, topics_subscriber AS topics, visibility_subscriber AS visibility, bounce_subscriber AS bounce, bounce_score_subscriber AS bounce_score, bounce_address_subscriber AS bounce_address,  %s AS date, %s AS update_date, subscribed_subscriber AS subscribed, included_subscriber AS included, include_sources_subscriber AS id %s FROM subscriber_table WHERE (list_subscriber = %s AND robot_subscriber = %s %s)", 
	    $date_field, 
	    $update_field, 
	    $additional, 
	    $dbh->quote($name), 
	    $dbh->quote($self->{'domain'}),
	    $selection;
	    
	    ## SORT BY
	    if ($sortby eq 'domain') {
		## Redefine query to set "dom"
		
		$statement = sprintf "SELECT user_subscriber AS email, comment_subscriber AS gecos, reception_subscriber AS reception, topics_subscriber AS topics, visibility_subscriber AS visibility, bounce_subscriber AS bounce, bounce_score_subscriber AS bounce_score, bounce_address_subscriber AS bounce_address,  %s AS date, %s AS update_date, subscribed_subscriber AS subscribed, included_subscriber AS included, include_sources_subscriber AS id, REVERSE(SUBSTRING(user_subscriber FROM position('\@' IN user_subscriber) FOR 50)) AS dom %s FROM subscriber_table WHERE (list_subscriber = %s AND robot_subscriber = %s ) ORDER BY dom", 
		$date_field, 
		$update_field, 
		$additional, 
		$dbh->quote($name),
		$dbh->quote($self->{'domain'});
		
	    }elsif ($sortby eq 'email') {
		## Default SORT
		$statement .= ' ORDER BY email';
		
	    }elsif ($sortby eq 'date') {
		$statement .= ' ORDER BY date DESC';
		
	    }elsif ($sortby eq 'sources') {
		$statement .= " ORDER BY \"subscribed\" DESC,\"id\"";
		
	    }elsif ($sortby eq 'name') {
		$statement .= ' ORDER BY gecos';
	    } 
	    
	    ## LIMIT clause
	    if (defined($rows) and defined($offset)) {
		$statement .= sprintf " LIMIT %d, %d", $offset, $rows;
	    }
	    
	    ## SQLite
	}elsif ($Conf{'db_type'} eq 'SQLite') {
    
	    $statement = sprintf "SELECT user_subscriber AS email, comment_subscriber AS gecos, reception_subscriber AS reception, visibility_subscriber AS visibility, bounce_subscriber AS bounce, bounce_score_subscriber AS bounce_score, bounce_address_subscriber AS bounce_address, %s AS date, %s AS update_date, subscribed_subscriber AS subscribed, included_subscriber AS included, include_sources_subscriber AS id %s FROM subscriber_table WHERE (list_subscriber = %s AND robot_subscriber = %s %s)", 
	    $date_field, 
	    $update_field, 
	    $additional, 
	    $dbh->quote($name), 
	    $dbh->quote($self->{'domain'}),
	    $selection;
 	    
 	    ## SORT BY
 	    if ($sortby eq 'domain') {
 		## Redefine query to set "dom"
		
 		$statement = sprintf "SELECT user_subscriber AS email, comment_subscriber AS gecos, reception_subscriber AS reception, visibility_subscriber AS visibility, bounce_subscriber AS bounce, bounce_score_subscriber AS bounce_score, bounce_address_subscriber AS bounce_address, %s AS date, %s AS update_date, subscribed_subscriber AS subscribed, included_subscriber AS included, include_sources_subscriber AS id, substr(user_subscriber,0,func_index(user_subscriber,'\@')+1) AS dom %s FROM subscriber_table WHERE (list_subscriber = %s AND robot_subscriber = %s) ORDER BY dom", 
		$date_field, 
		$update_field, 
		$additional, 
		$dbh->quote($name),
		$dbh->quote($self->{'domain'});
		
 	    }elsif ($sortby eq 'email') {
 		## Default SORT
 		$statement .= ' ORDER BY email';
		
 	    }elsif ($sortby eq 'date') {
 		$statement .= ' ORDER BY date DESC';
 
 	    }elsif ($sortby eq 'sources') {
 		$statement .= " ORDER BY \"subscribed\" DESC,\"id\"";
		
 	    }elsif ($sortby eq 'name') {
 		$statement .= ' ORDER BY gecos';
 	    } 
 	    
 	    ## LIMIT clause
 	    if (defined($rows) and defined($offset)) {
 		$statement .= sprintf " LIMIT %d, %d", $offset, $rows;
 	    }
 	    
	    ## Pg    
	}else {
	    
	    $statement = sprintf "SELECT user_subscriber AS email, comment_subscriber AS gecos, reception_subscriber AS reception, topics_subscriber AS topics, visibility_subscriber AS visibility, bounce_subscriber AS bounce, bounce_score_subscriber AS bounce_score, bounce_address_subscriber AS bounce_address, %s AS date, %s AS update_date, subscribed_subscriber AS subscribed, included_subscriber AS included, include_sources_subscriber AS id %s FROM subscriber_table WHERE (list_subscriber = %s AND robot_subscriber = %s %s)", 
	    $date_field, 
	    $update_field, 
	    $additional, 
	    $dbh->quote($name), 
	    $dbh->quote($self->{'domain'}),
	    $selection;
	    
	    ## SORT BY
	    if ($sortby eq 'domain') {
		## Redefine query to set "dom"

		$statement = sprintf "SELECT user_subscriber AS email, comment_subscriber AS gecos, reception_subscriber AS reception, topics_subscriber AS topics, visibility_subscriber AS visibility, bounce_subscriber AS bounce, bounce_score_subscriber AS bounce_score, bounce_address_subscriber AS bounce_address, %s AS date, %s AS update_date, subscribed_subscriber AS subscribed, included_subscriber AS included, include_sources_subscriber AS id, SUBSTRING(user_subscriber FROM position('\@' IN user_subscriber) FOR 50) AS dom %s FROM subscriber_table WHERE (list_subscriber = %s AND robot_subscriber = %s) ORDER BY dom", 
		$date_field, 
		$update_field, 
		$additional, 
		$dbh->quote($name),
		$dbh->quote($self->{'domain'});

	    }elsif ($sortby eq 'email') {
		$statement .= ' ORDER BY email';

	    }elsif ($sortby eq 'date') {
		$statement .= ' ORDER BY date DESC';

	    }elsif ($sortby eq 'sources') {
		$statement .= " ORDER BY \"subscribed\" DESC,\"id\"";

	    }elsif ($sortby eq 'email') {
		$statement .= ' ORDER BY gecos';
	    }
	    
	    ## LIMIT clause
	    if (defined($rows) and defined($offset)) {
		$statement .= sprintf " LIMIT %d OFFSET %d", $rows, $offset;
	    }
	}
	push @sth_stack, $sth;

	unless ($sth = $dbh->prepare($statement)) {
	    do_log('err','Unable to prepare SQL statement : %s', $dbh->errstr);
	    return undef;
	}
	
	unless ($sth->execute) {
	    do_log('err','Unable to execute SQL statement "%s" : %s', $statement, $dbh->errstr);
	    return undef;
	}
	
	my $user = $sth->fetchrow_hashref;
	if (defined $user) {
	    &do_log('err','Warning: entry with empty email address in list %s', $self->{'name'}) 
		if (! $user->{'email'});
	    $user->{'reception'} ||= 'mail';
	    $user->{'reception'} = $self->{'admin'}{'default_user_options'}{'reception'}
	    unless ($self->is_available_reception_mode($user->{'reception'}));
	    $user->{'update_date'} ||= $user->{'date'};

	    ## In case it was not set in the database
	    $user->{'subscribed'} = 1
		if (defined($user) && ($self->{'admin'}{'user_data_source'} eq 'database'));
	}
	else {
	    $sth->finish;
	    $sth = pop @sth_stack;
	    	    
	    if ($self->{'admin'}{'user_data_source'} eq 'include2') {
		## Release the Shared lock
		$include_lock_count--;

		## Last lock
		if ($include_lock_count == 0) {
		    my $lock_file = $self->{'dir'}.'/include.lock';
		    unless (&tools::unlock($lock_file, $list_of_fh{$lock_file})) {
			return undef;
		    }
		    delete $list_of_fh{$lock_file};
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
    }else {
	my ($i, $j);
	my $ref = $self->{'ref'};
	
	 if (defined($ref) && $ref->seq($i, $j, R_FIRST) == 0)  {
	    my %user = split(/\n/, $j);

	    $self->{'_loading_total'} = 1;

	    $user{'reception'} ||= 'mail';
	    $user{'reception'} = $self->{'admin'}{'default_user_options'}{'reception'}
	    unless ($self->is_available_reception_mode($user{'reception'}));
	    $user{'subscribed'} = 1 if (defined(%user));
	    return \%user;
	}
	return undef;
    }
}

## Returns the first admin_user with $role for the list.
sub get_first_admin_user {
    my ($self, $role, $data) = @_;

    my ($sortby, $offset, $rows, $sql_regexp);
    $sortby = $data->{'sortby'};
    ## Sort may be domain, email, date
    $sortby ||= 'domain';
    $offset = $data->{'offset'};
    $rows = $data->{'rows'};
    $sql_regexp = $data->{'sql_regexp'};

    &do_log('debug2', 'List::get_first_admin_user(%s,%s,%s,%d,%d)', $self->{'name'},$role, $sortby, $offset, $rows);

    unless($self->{'admin'}{'user_data_source'} eq 'include2'){
	&do_log('err', 'List::get_first_admin_user(%s,%s,%s,%d,%d) isn\'t defined when user_data_source is different than include2',
		 $self->{'name'},$role,$sortby, $offset, $rows); 
	return undef;
    }
   
  
    ## Get an Shared lock
    $include_admin_user_lock_count++;
    
    ## first lock
    if ($include_admin_user_lock_count == 1) {
	my $lock_file = $self->{'dir'}.'/include_admin_user.lock';
	
	## Create include_admin_user.lock if needed
	unless (-f $lock_file) {
	    unless (open FH, ">>$lock_file") {
		&do_log('err', 'Cannot open %s: %s', $lock_file, $!);
		return undef;
	    }
	}
	
	close $lock_file;
	
	unless ($list_of_fh{$lock_file} = &tools::lock($lock_file,'read')) {
		return undef;
	    }
	}
          
    my $name = $self->{'name'};
    my $statement;
    
    my $date_field = sprintf $date_format{'read'}{$Conf{'db_type'}}, 'date_admin', 'date_admin';
    my $update_field = sprintf $date_format{'read'}{$Conf{'db_type'}}, 'update_admin', 'update_admin';
    
    ## Check database connection
    unless ($dbh and $dbh->ping) {
	return undef unless &db_connect();
    }
    
    ## SQL regexp
    my $selection;
    if ($sql_regexp) {
	$selection = sprintf " AND (user_admin LIKE %s OR comment_admin LIKE %s)"
	    ,$dbh->quote($sql_regexp), $dbh->quote($sql_regexp);
    }
    
     ## Oracle
# and ok ?
    if ($Conf{'db_type'} eq 'Oracle') {
	
	$statement = sprintf "SELECT user_admin \"email\", comment_admin \"gecos\", reception_admin \"reception\", %s \"date\", %s \"update_date\", info_admin \"info\", profile_admin \"profile\", subscribed_admin \"subscribed\", included_admin \"included\", include_sources_admin \"id\" FROM admin_table WHERE (list_admin = %s AND robot_admin = %s %s AND role_admin = %s)", 
	$date_field, 
	$update_field, 
	$dbh->quote($name), 
	$dbh->quote($self->{'domain'}),
	$selection, 
	$dbh->quote($role);
	
	## SORT BY
	if ($sortby eq 'domain') {
	    $statement = sprintf "SELECT user_admin \"email\", comment_admin \"gecos\", reception_admin \"reception\", %s \"date\", %s \"update_date\", info_admin \"info\", profile_admin \"profile\", subscribed_admin \"subscribed\", included_admin \"included\", include_sources_admin \"id\", substr(user_admin,instr(user_admin,'\@')+1) \"dom\"  FROM admin_table WHERE (list_admin = %s AND robot_admin = %s AND role_admin = %s ) ORDER BY \"dom\"", 
	    $date_field, 
	    $update_field, 
	    $dbh->quote($name), 
	    $dbh->quote($self->{'domain'}),
	    $dbh->quote($role);
	    
	}elsif ($sortby eq 'email') {
	    $statement .= " ORDER BY \"email\"";
	    
	}elsif ($sortby eq 'date') {
	    $statement .= " ORDER BY \"date\" DESC";
	    
	}elsif ($sortby eq 'sources') {
	    $statement .= " ORDER BY \"subscribed\" DESC,\"id\"";
	    
	}elsif ($sortby eq 'name') {
	    $statement .= " ORDER BY \"gecos\"";
	} 
	
	## Sybase
    }elsif ($Conf{'db_type'} eq 'Sybase'){
	
	$statement = sprintf "SELECT user_admin \"email\", comment_admin \"gecos\", reception_admin \"reception\", %s \"date\", %s \"update_date\", info_admin \"info\", profile_admin \"profile\", subscribed_admin \"subscribed\", included_admin \"included\", include_sources_admin \"id\" FROM admin_table WHERE (list_admin = %s AND robot_admin = %s %s AND role_admin = %s)", 
	$date_field, 
	$update_field, 
	$dbh->quote($name), 
	$dbh->quote($self->{'domain'}),
	$selection, 
	$dbh->quote($role);
	## SORT BY
	if ($sortby eq 'domain') {
	    $statement = sprintf "SELECT user_admin \"email\", comment_admin \"gecos\", reception_admin \"reception\", %s \"date\", %s \"update_date\", info_admin \"info\", profile_admin \"profile\", subscribed_admin \"subscribed\", included_admin \"included\", include_sources_admin \"id\", substring(user_admin,charindex('\@',user_admin)+1,100) \"dom\" FROM admin_table WHERE (list_admin = %s  AND robot_admin = %s AND role_admin = %s) ORDER BY \"dom\"", 
	    $date_field, 
	    $update_field, 
	    $dbh->quote($name), 
	    $dbh->quote($self->{'domain'}),
	    $dbh->quote($role);
	    
	}elsif ($sortby eq 'email') {
	    $statement .= " ORDER BY \"email\"";
	    
	}elsif ($sortby eq 'date') {
	    $statement .= " ORDER BY \"date\" DESC";
	    
	}elsif ($sortby eq 'sources') {
	    $statement .= " ORDER BY \"subscribed\" DESC,\"id\"";
	    
	}elsif ($sortby eq 'name') {
	    $statement .= " ORDER BY \"gecos\"";
	}
	
	
	## mysql
    }elsif ($Conf{'db_type'} eq 'mysql') {
	
	$statement = sprintf "SELECT user_admin AS email, comment_admin AS gecos, reception_admin AS reception, %s AS date, %s AS update_date, info_admin AS info, profile_admin AS profile, subscribed_admin AS subscribed, included_admin AS included, include_sources_admin AS id  FROM admin_table WHERE (list_admin = %s AND robot_admin = %s %s AND role_admin = %s)", 
	$date_field, 
	$update_field, 
	$dbh->quote($name), 
	$dbh->quote($self->{'domain'}),
	$selection, 
	$dbh->quote($role);
	
	## SORT BY
	if ($sortby eq 'domain') {
	    ## Redefine query to set "dom"
	    
	    $statement = sprintf "SELECT user_admin AS email, comment_admin AS gecos, reception_admin AS reception, %s AS date, %s AS update_date, info_admin AS info, profile_admin AS profile, subscribed_admin AS subscribed, included_admin AS included, include_sources_admin AS id, REVERSE(SUBSTRING(user_admin FROM position('\@' IN user_admin) FOR 50)) AS dom FROM admin_table WHERE (list_admin = %s AND robot_admin = %s AND role_admin = %s ) ORDER BY dom", 
	    $date_field, 
	    $update_field, 
	    $dbh->quote($name), 
	    $dbh->quote($self->{'domain'}),
	    $dbh->quote($role);
	    
	}elsif ($sortby eq 'email') {
	    ## Default SORT
	    $statement .= ' ORDER BY email';
	    
	}elsif ($sortby eq 'date') {
	    $statement .= ' ORDER BY date DESC';
	    
	}elsif ($sortby eq 'sources') {
	    $statement .= " ORDER BY \"subscribed\" DESC,\"id\"";
	    
	}elsif ($sortby eq 'name') {
	    $statement .= ' ORDER BY gecos';
	} 
	
	## LIMIT clause
	if (defined($rows) and defined($offset)) {
	    $statement .= sprintf " LIMIT %d, %d", $offset, $rows;
	}
	
	## SQLite
    }elsif ($Conf{'db_type'} eq 'SQLite') {
	
	$statement = sprintf "SELECT user_admin AS email, comment_admin AS gecos, reception_admin AS reception, %s AS date, %s AS update_date, info_admin AS info, profile_admin AS profile, subscribed_admin AS subscribed, included_admin AS included, include_sources_admin AS id  FROM admin_table WHERE (list_admin = %s AND robot_admin = %s %s AND role_admin = %s)", 
	$date_field, 
	$update_field, 
	$dbh->quote($name), 
	$dbh->quote($self->{'domain'}),
	$selection, 
	$dbh->quote($role);
	
	## SORT BY
	if ($sortby eq 'domain') {
	    ## Redefine query to set "dom"
	    
	    $statement = sprintf "SELECT user_admin AS email, comment_admin AS gecos, reception_admin AS reception, %s AS date, %s AS update_date, info_admin AS info, profile_admin AS profile, subscribed_admin AS subscribed, included_admin AS included, include_sources_admin AS id, substr(user_admin,func_index(user_admin,'\@')+1,50) AS dom FROM admin_table WHERE (list_admin = %s AND robot_admin = %s AND role_admin = %s ) ORDER BY dom", 
	    $date_field, 
	    $update_field, 
	    $dbh->quote($name), 
	    $dbh->quote($self->{'domain'}),
	    $dbh->quote($role);
	    
	}elsif ($sortby eq 'email') {
	    ## Default SORT
	    $statement .= ' ORDER BY email';
	    
	}elsif ($sortby eq 'date') {
	    $statement .= ' ORDER BY date DESC';
	    
	}elsif ($sortby eq 'sources') {
	    $statement .= " ORDER BY \"subscribed\" DESC,\"id\"";
	    
	}elsif ($sortby eq 'name') {
	    $statement .= ' ORDER BY gecos';
	} 
	
	## LIMIT clause
	if (defined($rows) and defined($offset)) {
	    $statement .= sprintf " LIMIT %d, %d", $offset, $rows;
	}
	
	## Pg    
    }else {
	
	$statement = sprintf "SELECT user_admin AS email, comment_admin AS gecos, reception_admin AS reception, %s AS date, %s AS update_date, info_admin AS info, profile_admin AS profile, subscribed_admin AS subscribed, included_admin AS included, include_sources_admin AS id FROM admin_table WHERE (list_admin = %s AND robot_admin = %s %s AND role_admin = %s)", 
	$date_field, 
	$update_field, 
	$dbh->quote($name), 
	$dbh->quote($self->{'domain'}),
	$selection, 
	$dbh->quote($role);
	
	## SORT BY
	if ($sortby eq 'domain') {
	    ## Redefine query to set "dom"
	    
	    $statement = sprintf "SELECT user_admin AS email, comment_admin AS gecos, reception_admin AS reception, %s AS date, %s AS update_date, info_admin AS info, profile_admin AS profile, subscribed_admin AS subscribed, included_admin AS included, include_sources_admin AS id, SUBSTRING(user_admin FROM position('\@' IN user_admin) FOR 50) AS dom  FROM admin_table WHERE (list_admin = %s AND robot_admin = %s AND role_admin = %s) ORDER BY dom", 
	    $date_field, 
	    $update_field, 
	    $dbh->quote($name), 
	    $dbh->quote($self->{'domain'}),
	    $dbh->quote($role);
	    
	}elsif ($sortby eq 'email') {
	    $statement .= ' ORDER BY email';
	    
	}elsif ($sortby eq 'date') {
	    $statement .= ' ORDER BY date DESC';
	    
	}elsif ($sortby eq 'sources') {
	    $statement .= " ORDER BY \"subscribed\" DESC,\"id\"";
	    
	}elsif ($sortby eq 'email') {
	    $statement .= ' ORDER BY gecos';
	}
	
	## LIMIT clause
	if (defined($rows) and defined($offset)) {
	    $statement .= sprintf " LIMIT %d OFFSET %d", $rows, $offset;
	}
    }
    push @sth_stack, $sth;	    

    &do_log('debug2','SQL: %s', $statement);
    
    unless ($sth = $dbh->prepare($statement)) {
	do_log('err','Unable to prepare SQL statement : %s', $dbh->errstr);
	return undef;
    }
    
    unless ($sth->execute) {
	do_log('err','Unable to execute SQL statement "%s" : %s', $statement, $dbh->errstr);
	return undef;
    }
    
    my $admin_user = $sth->fetchrow_hashref;
    if (defined $admin_user) {
	&do_log('err','Warning: entry with empty email address in list %s', $self->{'name'}) 
	    if (! $admin_user->{'email'});
	$admin_user->{'reception'} ||= 'mail';
	$admin_user->{'update_date'} ||= $admin_user->{'date'};
	
	## In case it was not set in the database
	$admin_user->{'subscribed'} = 1
	    if (defined($admin_user) && ($self->{'admin'}{'user_data_source'} eq 'database'));
    }
    return $admin_user;
}
    
## Loop for all subsequent users.
sub get_next_user {
    my $self = shift;
    do_log('debug2', 'List::get_next_user');

    if (($self->{'admin'}{'user_data_source'} eq 'database') ||
	($self->{'admin'}{'user_data_source'} eq 'include2')){

	unless (defined $sth) {
	    &do_log('err', 'No handle defined, get_first_user(%s) was not run', $self->{'name'});
	    return undef;
	}
	
	my $user = $sth->fetchrow_hashref;

	if (defined $user) {
	    &do_log('err','Warning: entry with empty email address in list %s', $self->{'name'}) 
		if (! $user->{'email'});
	    $user->{'reception'} ||= 'mail';
	    unless ($self->is_available_reception_mode($user->{'reception'})){
		$user->{'reception'} = $self->{'admin'}{'default_user_options'}{'reception'}
	    }
	    $user->{'update_date'} ||= $user->{'date'};

	    ## In case it was not set in the database
	    $user->{'subscribed'} = 1
		if (defined($user) && ($self->{'admin'}{'user_data_source'} eq 'database'));
	}
	else {
	    $sth->finish;
	    $sth = pop @sth_stack;
	    	    
	    if ($self->{'admin'}{'user_data_source'} eq 'include2') {
		## Release the Shared lock
		$include_lock_count--;

		## Last lock
		if ($include_lock_count == 0) {
		    my $lock_file = $self->{'dir'}.'/include.lock';
		    unless (&tools::unlock($lock_file, $list_of_fh{$lock_file})) {
			return undef;
		    }
		    delete $list_of_fh{$lock_file};
		}
	    }
	}

#	$self->{'total'}++;

	return $user;
    }else {
	my ($i, $j);
	my $ref = $self->{'ref'};
	
	if ($ref->seq($i, $j, R_NEXT) == 0) {
	    my %user = split(/\n/, $j);

	    $self->{'_loading_total'}++;

	    $user{'reception'} ||= 'mail';
	    $user{'reception'} = $self->{'admin'}{'default_user_options'}{'reception'}
	      unless ($self->is_available_reception_mode($user{'reception'}));
	    $user{'subscribed'} = 1 if (defined(%user));
	    return \%user;
	}
	## Update total
	$self->{'total'} = $self->{'_loading_total'}; 
	$self->{'_loading_total'} = undef;
	$self->savestats();

	return undef;
    }
}

## Loop for all subsequent admin users with the role defined in get_first_admin_user.
sub get_next_admin_user {
    my $self = shift;
    do_log('debug2', 'List::get_next_admin_user'); 

    unless($self->{'admin'}{'user_data_source'} eq 'include2'){
	&do_log('err', 'List::get_next_admin_user(%s) isn\'t defined when user_data_source is different than include2',
		$self->{'name'}); 
	return undef;
    }
    
    unless (defined $sth) {
	&do_log('err','Statement handle not defined in get_next_admin_user for list %s', $self->{'name'});
	return undef;
    }
    
    my $admin_user = $sth->fetchrow_hashref;

    if (defined $admin_user) {
	&do_log('err','Warning: entry with empty email address in list %s', $self->{'name'}) 
	    if (! $admin_user->{'email'});
	$admin_user->{'reception'} ||= 'mail';
	$admin_user->{'update_date'} ||= $admin_user->{'date'};
	
	## In case it was not set in the database
	$admin_user->{'subscribed'} = 1
	    if (defined($admin_user) && ($self->{'admin'}{'user_data_source'} eq 'database'));
    }
    else {
	$sth->finish;
	$sth = pop @sth_stack;
	
	## Release the Shared lock
	$include_admin_user_lock_count--;
	
	## Last lock
	if ($include_admin_user_lock_count == 0) {
	    my $lock_file = $self->{'dir'}.'/include_admin_user.lock';
	    unless (&tools::unlock($lock_file, $list_of_fh{$lock_file})) {
		return undef;
	    }
	    delete $list_of_fh{$lock_file};
	}
    }
   return $admin_user;
}




## Returns the first bouncing user
sub get_first_bouncing_user {
    my $self = shift;
    do_log('debug2', 'List::get_first_bouncing_user');

    unless (($self->{'admin'}{'user_data_source'} eq 'database') ||
	    ($self->{'admin'}{'user_data_source'} eq 'include2')){
	&do_log('info', "Function get_first_bouncing_user not available for list  $self->{'name'} because not in database mode");
	return undef;
    }
    
    if ($self->{'admin'}{'user_data_source'} eq 'include2') {
	## Get an Shared lock
	$include_lock_count++;
	
	## first lock
	if ($include_lock_count == 1) {
	    my $lock_file = $self->{'dir'}.'/include.lock';

	    ## Create include.lock if needed
	    unless (-f $lock_file) {
		unless (open FH, ">>$lock_file") {
		    &do_log('err', 'Cannot open %s: %s', $lock_file, $!);
		    return undef;
		}
	    }
	    close $lock_file;
	    

	    unless ($list_of_fh{$lock_file} = &tools::lock($lock_file,'read')) {
		return undef;
	    }
	}
    }

    my $name = $self->{'name'};
    my $statement;
    my $date_field = sprintf $date_format{'read'}{$Conf{'db_type'}}, 'date_subscriber', 'date_subscriber';
    my $update_field = sprintf $date_format{'read'}{$Conf{'db_type'}}, 'update_subscriber', 'update_subscriber';
    
    ## Check database connection
    unless ($dbh and $dbh->ping) {
	return undef unless &db_connect();
    }

    ## Additional subscriber fields
    my $additional;
    if ($Conf{'db_additional_subscriber_fields'}) {
	$additional = ',' . $Conf{'db_additional_subscriber_fields'};
    }

    if ($Conf{'db_type'} eq 'Oracle') {
	## "AS" not supported by Oracle
	$statement = sprintf "SELECT user_subscriber \"email\", reception_subscriber \"reception\", topics_subscriber \"topics\", visibility_subscriber \"visibility\", bounce_subscriber \"bounce\",bounce_score_subscriber \"bounce_score\", %s \"date\", %s \"update_date\" %s FROM subscriber_table WHERE (list_subscriber = %s AND robot_subscriber = %s AND bounce_subscriber is not NULL)", 
	$date_field, 
	$update_field, 
	$additional, 
	$dbh->quote($name),
	$dbh->quote($self->{'domain'});
    }else {
	$statement = sprintf "SELECT user_subscriber AS email, reception_subscriber AS reception, topics_subscriber AS topics, visibility_subscriber AS visibility, bounce_subscriber AS bounce,bounce_score_subscriber AS bounce_score, %s AS date, %s AS update_date %s FROM subscriber_table WHERE (list_subscriber = %s AND robot_subscriber = %s AND bounce_subscriber is not NULL)", 
	$date_field, 
	$update_field, 
	$additional, 
	$dbh->quote($name),
	$dbh->quote($self->{'domain'});
    }

    push @sth_stack, $sth;

    unless ($sth = $dbh->prepare($statement)) {
	do_log('err','Unable to prepare SQL statement : %s', $dbh->errstr);
	return undef;
    }
    
    unless ($sth->execute) {
	do_log('err','Unable to execute SQL statement "%s" : %s', $statement, $dbh->errstr);
	return undef;
    }
    
    my $user = $sth->fetchrow_hashref;
	    
    if (defined $user) {
	&do_log('err','Warning: entry with empty email address in list %s', $self->{'name'}) 
	    if (! $user->{'email'});
	
	## In case it was not set in the database
	$user->{'subscribed'} = 1
	    if (defined ($user) && ($self->{'admin'}{'user_data_source'} eq 'database'));    

    }else {
	$sth->finish;
	$sth = pop @sth_stack;
	
	if ($self->{'admin'}{'user_data_source'} eq 'include2') {
	    ## Release the Shared lock
	    $include_lock_count--;
	    
	    ## Last lock
	    if ($include_lock_count == 0) {
		my $lock_file = $self->{'dir'}.'/include.lock';
		unless (&tools::unlock($lock_file, $list_of_fh{$lock_file})) {
		    return undef;
		}
		delete $list_of_fh{$lock_file};
	    }
	}
    }
    return $user;
}

## Loop for all subsequent bouncing users.
sub get_next_bouncing_user {
    my $self = shift;
    do_log('debug2', 'List::get_next_bouncing_user');

    unless (($self->{'admin'}{'user_data_source'} eq 'database') ||
	    ($self->{'admin'}{'user_data_source'} eq 'include2')){
	&do_log('info', 'Function available for lists in database mode only');
	return undef;
    }

    unless (defined $sth) {
	&do_log('err', 'No handle defined, get_first_bouncing_user(%s) was not run', $self->{'name'});
	return undef;
    }
    
    my $user = $sth->fetchrow_hashref;
    
    if (defined $user) {
	&do_log('err','Warning: entry with empty email address in list %s', $self->{'name'}) 
	    if (! $user->{'email'});
	
	## In case it was not set in the database
	$user->{'subscribed'} = 1
	    if (defined ($user) && ($self->{'admin'}{'user_data_source'} eq 'database'));    

    }else {
	$sth->finish;
	$sth = pop @sth_stack;
	
	if ($self->{'admin'}{'user_data_source'} eq 'include2') {
	    ## Release the Shared lock
	    $include_lock_count--;
	    
	    ## Last lock
	    if ($include_lock_count == 0) {
		my $lock_file = $self->{'dir'}.'/include.lock';
		unless (&tools::unlock($lock_file, $list_of_fh{$lock_file})) {
		    return undef;
		}
		delete $list_of_fh{$lock_file};
	    }
	}
    }

    return $user;
}

sub get_info {
    my $self = shift;

    my $info;
    
    unless (open INFO, "$self->{'dir'}/info") {
	&do_log('err', 'Could not open %s : %s', $self->{'dir'}.'/info', $!);
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
    do_log('debug2', 'List::get_total_boucing');

    unless (($self->{'admin'}{'user_data_source'} eq 'database') ||
	    ($self->{'admin'}{'user_data_source'} eq 'include2')){
	&do_log('info', 'Function available for lists in database mode only');
	return undef;
    }

    my $name = $self->{'name'};
    my $statement;
   
    ## Check database connection
    unless ($dbh and $dbh->ping) {
	return undef unless &db_connect();
    }	   
    
    ## Query the Database
    $statement = sprintf "SELECT count(*) FROM subscriber_table WHERE (list_subscriber = %s  AND robot_subscriber = %s AND bounce_subscriber is not NULL)", $dbh->quote($name), $dbh->quote($self->{'domain'});
    
    push @sth_stack, $sth;

    unless ($sth = $dbh->prepare($statement)) {
	do_log('err','Unable to prepare SQL statement : %s', $dbh->errstr);
	return undef;
    }
    
    unless ($sth->execute) {
	do_log('err','Unable to execute SQL statement "%s" : %s', $statement, $dbh->errstr);
	return undef;
    }
    
    my $total =  $sth->fetchrow;

    $sth->finish();

    $sth = pop @sth_stack;

    return $total;
}

## Is the person in user table (db only)
sub is_user_db {
   my $who = &tools::clean_email(pop);
   do_log('debug3', 'List::is_user_db(%s)', $who);

   return undef unless ($who);

   unless ($List::use_db) {
       &do_log('info', 'Sympa not setup to use DBI');
       return undef;
   }

   my $statement;
   
   ## Check database connection
   unless ($dbh and $dbh->ping) {
       return undef unless &db_connect();
   }	   
   
   ## Query the Database
   $statement = sprintf "SELECT count(*) FROM user_table WHERE email_user = %s", $dbh->quote($who);
   
   push @sth_stack, $sth;

   unless ($sth = $dbh->prepare($statement)) {
       do_log('err','Unable to prepare SQL statement : %s', $dbh->errstr);
       return undef;
   }
   
   unless ($sth->execute) {
       do_log('err','Unable to execute SQL statement "%s" : %s', $statement, $dbh->errstr);
       return undef;
   }
   
   my $is_user = $sth->fetchrow();
   $sth->finish();
   
   $sth = pop @sth_stack;

   return $is_user;
}

## Is the indicated person a subscriber to the list ?
sub is_user {
    my ($self, $who) = @_;
    $who = &tools::clean_email($who);
    do_log('debug3', 'List::is_user(%s)', $who);
    
    return undef unless ($self && $who);
    
    if (($self->{'admin'}{'user_data_source'} eq 'database') ||
	($self->{'admin'}{'user_data_source'} eq 'include2')){
	
	my $statement;
	my $name = $self->{'name'};
	
	## Use cache
	if (defined $list_cache{'is_user'}{$self->{'domain'}}{$name}{$who}) {
	    # &do_log('debug3', 'Use cache(%s,%s): %s', $name, $who, $list_cache{'is_user'}{$self->{'domain'}}{$name}{$who});
	    return $list_cache{'is_user'}{$self->{'domain'}}{$name}{$who};
	}
	
	## Check database connection
	unless ($dbh and $dbh->ping) {
	    return undef unless &db_connect();
	}	   
	
	## Query the Database
	$statement = sprintf "SELECT count(*) FROM subscriber_table WHERE (list_subscriber = %s AND robot_subscriber = %s AND user_subscriber = %s)",$dbh->quote($name), $dbh->quote($self->{'domain'}), $dbh->quote($who);
	
	push @sth_stack, $sth;
	
	unless ($sth = $dbh->prepare($statement)) {
	    do_log('err','Unable to prepare SQL statement : %s', $dbh->errstr);
	    return undef;
	}
	
	unless ($sth->execute) {
	    do_log('err','Unable to execute SQL statement "%s" : %s', $statement, $dbh->errstr);
	    return undef;
	}
	
	my $is_user = $sth->fetchrow;
	
	$sth->finish();
	
	$sth = pop @sth_stack;

	## Set cache
	$list_cache{'is_user'}{$self->{'domain'}}{$name}{$who} = $is_user;

       return $is_user;
   }else {
       my $users = $self->{'users'};
       return 0 unless ($users);
       
       return 1 if ($users->{$who});
       return 0;
   }
}

## Sets new values for the given user (except gecos)
sub update_user {
    my($self, $who, $values) = @_;
    do_log('debug2', 'List::update_user(%s)', $who);
    $who = &tools::clean_email($who);    

    my ($field, $value);
    
    ## Subscribers extracted from external data source
    if ($self->{'admin'}{'user_data_source'} eq 'include') {
	&do_log('notice', 'Cannot update user in list %s, user_data_source include', $self->{'admin'}{'user_data_source'});
	return undef;

	## Subscribers stored in database
    } elsif (($self->{'admin'}{'user_data_source'} eq 'database') ||
	     ($self->{'admin'}{'user_data_source'} eq 'include2')){
	
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
			  bounce_address => 'bounce_address_subscriber'
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
			  bounce_address => 'subscriber_table'
			  );

	## additional DB fields
	if (defined $Conf{'db_additional_subscriber_fields'}) {
	    foreach my $f (split ',', $Conf{'db_additional_subscriber_fields'}) {
		$map_table{$f} = 'subscriber_table';
		$map_field{$f} = $f;
	    }
	}

	if (defined $Conf{'db_additional_user_fields'}) {
	    foreach my $f (split ',', $Conf{'db_additional_user_fields'}) {
		$map_table{$f} = 'user_table';
		$map_field{$f} = $f;
	    }
	}
	
	
	## Check database connection
	unless ($dbh and $dbh->ping) {
	    return undef unless &db_connect();
	}	   
	
	## Update each table
	foreach $table ('user_table','subscriber_table') {
	    
	    my @set_list;
	    while (($field, $value) = each %{$values}) {

		unless ($map_field{$field} and $map_table{$field}) {
		    &do_log('err', 'Unknown database field %s', $field);
		    next;
		}

		if ($map_table{$field} eq $table) {
		    if ($field eq 'date') {
			$value = sprintf $date_format{'write'}{$Conf{'db_type'}}, $value, $value;
		    }elsif ($field eq 'update_date') {
			$value = sprintf $date_format{'write'}{$Conf{'db_type'}}, $value, $value;
		    }elsif ($value eq 'NULL'){
			if ($Conf{'db_type'} eq 'mysql') {
			    $value = '\N';
			}
		    }else {
			if ($numeric_field{$map_field{$field}}) {
			    $value ||= 0; ## Can't have a null value
			}else {
			    $value = $dbh->quote($value);
			}
		    }
		    my $set = sprintf "%s=%s", $map_field{$field}, $value;
		    push @set_list, $set;
		}
	    }
	    next unless @set_list;
	    
	    ## Update field
	    if ($table eq 'user_table') {
		$statement = sprintf "UPDATE %s SET %s WHERE (email_user=%s)", $table, join(',', @set_list), $dbh->quote($who); 

	    }elsif ($table eq 'subscriber_table') {
		if ($who eq '*') {
		    $statement = sprintf "UPDATE %s SET %s WHERE (list_subscriber=%s AND robot_subscriber = %s)", 
		    $table, 
		    join(',', @set_list), 
		    $dbh->quote($name), 
		    $dbh->quote($self->{'domain'});
		}else {
		    $statement = sprintf "UPDATE %s SET %s WHERE (user_subscriber=%s AND list_subscriber=%s AND robot_subscriber = %s)", 
		    $table, 
		    join(',', @set_list), 
		    $dbh->quote($who), 
		    $dbh->quote($name),
		    $dbh->quote($self->{'domain'});
		}
	    }
	    
	    unless ($dbh->do($statement)) {
		do_log('err','Unable to execute SQL statement "%s" : %s', $statement, $dbh->errstr);
		return undef;
	    }
	}

	## Reset session cache
	$list_cache{'get_subscriber'}{$self->{'domain'}}{$name}{$who} = undef;

	## Subscribers in text file
    }else {
	my $user = $self->{'users'}->{$who};
	return undef unless $user;
	
	my %u = split(/\n/, $user);
	my ($i, $j);
	$u{$i} = $j while (($i, $j) = each %{$values});
	
	while (($field, $value) = each %{$values}) {
	    $u{$field} = $value;
	}
	
	$user = join("\n", %u);      
	if ($values->{'email'}) {

	    ## Decrease total if new email was already subscriber
	    if ($self->{'users'}->{$values->{'email'}}) {
		$self->{'total'}--;
	    }
	    delete $self->{'users'}{$who};
	    $self->{'users'}->{$values->{'email'}} = $user;
	}else {
	    $self->{'users'}->{$who} = $user;
	}
    }
    
    return 1;
}


## Sets new values for the given admin user (except gecos)
sub update_admin_user {
    my($self, $who,$role, $values) = @_;
    do_log('debug2', 'List::update_admin_user(%s,%s)', $role, $who); 
    $who = &tools::clean_email($who);    

    my ($field, $value);
    
    unless($self->{'admin'}{'user_data_source'} eq 'include2'){
	&do_log('err', 'Cannot update %s in list %s, user_data_source different than include2', $role, $self->{'name'}); 
	return undef;
    }
   
    my ($admin_user, $statement, $table);
    my $name = $self->{'name'};
    
    ## mapping between var and field names
    my %map_field = ( reception => 'reception_admin',
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
#    if (defined $Conf{'db_additional_user_fields'}) {
#	foreach my $f (split ',', $Conf{'db_additional_user_fields'}) {
#	    $map_table{$f} = 'user_table';
#	    $map_field{$f} = $f;
#	}
#    }
    
    ## Check database connection
    unless ($dbh and $dbh->ping) {
	return undef unless &db_connect();
    }	   
    
    ## Update each table
    foreach $table ('user_table','admin_table') {
	
	my @set_list;
	while (($field, $value) = each %{$values}) {
	    
	    unless ($map_field{$field} and $map_table{$field}) {
		&do_log('err', 'Unknown database field %s', $field);
		next;
	    }
	    
	    if ($map_table{$field} eq $table) {
		if ($field eq 'date') {
		    $value = sprintf $date_format{'write'}{$Conf{'db_type'}}, $value, $value;
		}elsif ($field eq 'update_date') {
		    $value = sprintf $date_format{'write'}{$Conf{'db_type'}}, $value, $value;
		}elsif ($value eq 'NULL'){
		    if ($Conf{'db_type'} eq 'mysql') {
			$value = '\N';
		    }
		}else {
		    if ($numeric_field{$map_field{$field}}) {
			$value ||= 0; ## Can't have a null value
		    }else {
			$value = $dbh->quote($value);
		    }
		}
		my $set = sprintf "%s=%s", $map_field{$field}, $value;

		push @set_list, $set;
	    }
	}
	next unless @set_list;
	
	## Update field
	if ($table eq 'user_table') {
	    $statement = sprintf "UPDATE %s SET %s WHERE (email_user=%s)", $table, join(',', @set_list), $dbh->quote($who); 
	    
	}elsif ($table eq 'admin_table') {
	    if ($who eq '*') {
		$statement = sprintf "UPDATE %s SET %s WHERE (list_admin=%s AND robot_admin=%s AND role_admin=%s)", 
		$table, 
		join(',', @set_list), 
		$dbh->quote($name), 
		$dbh->quote($self->{'domain'}),
		$dbh->quote($role);
	    }else {
		$statement = sprintf "UPDATE %s SET %s WHERE (user_admin=%s AND list_admin=%s AND robot_admin=%s AND role_admin=%s )", 
		$table, 
		join(',', @set_list), 
		$dbh->quote($who), 
		$dbh->quote($name), 
		$dbh->quote($self->{'domain'}),
		$dbh->quote($role);
	    }
	}
    }
    
    unless ($dbh->do($statement)) {
	do_log('err','Unable to execute SQL statement "%s" : %s', $statement, $dbh->errstr);
	return undef;
    }

    ## Reset session cache
    $list_cache{'get_admin_user'}{$self->{'domain'}}{$name}{$role}{$who} = undef;
    
    return 1;
}




## Sets new values for the given user in the Database
sub update_user_db {
    my($who, $values) = @_;
    do_log('debug2', 'List::update_user_db(%s)', $who);
    $who = &tools::clean_email($who);

    unless ($List::use_db) {
	&do_log('info', 'Sympa not setup to use DBI');
	return undef;
    }

    ## encrypt password   
    $values->{'password'} = &tools::crypt_password($values->{'password'}) if ($values->{'password'});

    my ($field, $value);
    
    my ($user, $statement, $table);
    
    ## mapping between var and field names
    my %map_field = ( gecos => 'gecos_user',
		      password => 'password_user',
		      cookie_delay => 'cookie_delay_user',
		      lang => 'lang_user',
		      attributes => 'attributes_user',
		      email => 'email_user'
		      );
    
    ## Check database connection
    unless ($dbh and $dbh->ping) {
	return undef unless &db_connect();
    }	   
    
    ## Update each table
    my @set_list;
    while (($field, $value) = each %{$values}) {
	next unless ($map_field{$field});
	my $set;
	
	if ($numeric_field{$map_field{$field}})  {
	    $value ||= 0; ## Can't have a null value
	    $set = sprintf '%s=%s', $map_field{$field}, $value;
	}else { 
	    $set = sprintf '%s=%s', $map_field{$field}, $dbh->quote($value);
	}

	push @set_list, $set;
    }
    
    return undef 
	unless @set_list;
    
    ## Update field

    $statement = sprintf "UPDATE user_table SET %s WHERE (email_user=%s)"
	    , join(',', @set_list), $dbh->quote($who); 
    
    unless ($dbh->do($statement)) {
	do_log('err','Unable to execute SQL statement "%s" : %s', $statement, $dbh->errstr);
	return undef;
    }
    
    return 1;
}

## Adds a new user to Database (in User table)
sub add_user_db {
    my($values) = @_;
    do_log('debug2', 'List::add_user_db');

    my ($field, $value);
    my ($user, $statement, $table);
    
    unless ($List::use_db) {
	&do_log('info', 'Sympa not setup to use DBI');
	return undef;
    }
 
    ## encrypt password   
    $values->{'password'} = &tools::crypt_password($values->{'password'}) if $values->{'password'};
    
    return undef unless (my $who = &tools::clean_email($values->{'email'}));
    
    return undef if (is_user_db($who));
    
    ## mapping between var and field names
    my %map_field = ( email => 'email_user',
		      gecos => 'gecos_user',
		      password => 'password_user',
		      cookie_delay => 'cookie_delay_user',
		      lang => 'lang_user',
		      attributes => 'attributes_user'
		      );
    
    ## Check database connection
    unless ($dbh and $dbh->ping) {
	return undef unless &db_connect();
    }	   
    
    ## Update each table
    my (@insert_field, @insert_value);
    while (($field, $value) = each %{$values}) {
	
	next unless ($map_field{$field});
	
	my $insert;
	if ($numeric_field{$map_field{$field}}) {
	    $value ||= 0; ## Can't have a null value
	    $insert = $value;
	}else {
	    $insert = sprintf "%s", $dbh->quote($value);
	}
	push @insert_value, $insert;
	push @insert_field, $map_field{$field}
    }
    
    return undef 
	unless @insert_field;
    
    ## Update field
    $statement = sprintf "INSERT INTO user_table (%s) VALUES (%s)"
	, join(',', @insert_field), join(',', @insert_value); 
    
    unless ($dbh->do($statement)) {
	do_log('err','Unable to execute SQL statement "%s" : %s', $statement, $dbh->errstr);
	return undef;
    }
    
    return 1;
}

## Adds a new user, no overwrite.
sub add_user {
    my($self, @new_users) = @_;
    do_log('debug2', 'List::add_user');
    
    my $name = $self->{'name'};
    my $total = 0;
    
    if (($self->{'admin'}{'user_data_source'} eq 'database') ||
	($self->{'admin'}{'user_data_source'} eq 'include2')){
	
	## Check database connection
	unless ($dbh and $dbh->ping) {
	    return undef unless &db_connect();
	}	   
	
	foreach my $new_user (@new_users) {
	    my $who = &tools::clean_email($new_user->{'email'});

	    next unless $who;

	    $new_user->{'date'} ||= time;
	    $new_user->{'update_date'} ||= $new_user->{'date'};
	    
	    my $date_field = sprintf $date_format{'write'}{$Conf{'db_type'}}, $new_user->{'date'}, $new_user->{'date'};
	    my $update_field = sprintf $date_format{'write'}{$Conf{'db_type'}}, $new_user->{'update_date'}, $new_user->{'update_date'};
	    
	    $list_cache{'is_user'}{$self->{'domain'}}{$name}{$who} = undef;
	    
	    my $statement;

	    ## Either is_included or is_subscribed must be set
	    ## default is is_subscriber for backward compatibility reason
	    unless ($new_user->{'included'}) {
		$new_user->{'subscribed'} = 1;
	    }
	    
	    unless ($new_user->{'included'}) {
		## Is the email in user table ?
		if (! is_user_db($who)) {
		    ## Insert in User Table
		    $statement = sprintf "INSERT INTO user_table (email_user, gecos_user, lang_user, password_user) VALUES (%s,%s,%s,%s)",$dbh->quote($who), $dbh->quote($new_user->{'gecos'}), $dbh->quote($new_user->{'lang'}), $dbh->quote($new_user->{'password'});
		    
		    unless ($dbh->do($statement)) {
			do_log('err','Unable to execute SQL statement "%s" : %s', $statement, $dbh->errstr);
			next;
		    }
		}
	    }	    

	    $new_user->{'subscribed'} ||= 0;
 	    $new_user->{'included'} ||= 0;

	    ## Update Subscriber Table
	    $statement = sprintf "INSERT INTO subscriber_table (user_subscriber, comment_subscriber, list_subscriber, robot_subscriber, date_subscriber, update_subscriber, reception_subscriber, topics_subscriber, visibility_subscriber,subscribed_subscriber,included_subscriber,include_sources_subscriber) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)", 
	    $dbh->quote($who), 
	    $dbh->quote($new_user->{'gecos'}), 
	    $dbh->quote($name), 
	    $dbh->quote($self->{'domain'}),
	    $date_field, 
	    $update_field, 
	    $dbh->quote($new_user->{'reception'}), 
	    $dbh->quote($new_user->{'topics'}), 
	    $dbh->quote($new_user->{'visibility'}), 
	    $new_user->{'subscribed'}, 
	    $new_user->{'included'}, 
	    $dbh->quote($new_user->{'id'});
	    
	    unless ($dbh->do($statement)) {
		do_log('err','Unable to execute SQL statement "%s" : %s', $statement, $dbh->errstr);
		next;
	    }
	    $total++;
	}
    }else {
	my (%u, $i, $j);
	
	foreach my $new_user (@new_users) {
	    my $who = &tools::clean_email($new_user->{'email'});
	    
	    next unless $who;
	    
	    $new_user->{'date'} ||= time;
	    $new_user->{'update_date'} ||= $new_user->{'date'};

	    $total++ unless ($self->{'users'}->{$who});
	    $u{$i} = $j while (($i, $j) = each %{$new_user});
	    $self->{'users'}->{$who} = join("\n", %u);
	}
    }

    $self->{'total'} += $total;
    $self->savestats();

    return $total;
}


## Adds a new admin user, no overwrite.
sub add_admin_user {
    my($self, $role, @new_admin_users) = @_;
    do_log('debug2', 'List::add_admin_user');
    
    my $name = $self->{'name'};
    my $total = 0;
    
    unless($self->{'admin'}{'user_data_source'} eq 'include2'){
	&do_log('err', 'Cannot add %s in list %s, user_data_source different than include2', $role, $self->{'name'}); 
	return undef;
    }

    ## Check database connection
    unless ($dbh and $dbh->ping) {
	return undef unless &db_connect();
    }	   
	
    foreach my $new_admin_user (@new_admin_users) {
	my $who = &tools::clean_email($new_admin_user->{'email'});
	
	next unless $who;
	
	$new_admin_user->{'date'} ||= time;
	$new_admin_user->{'update_date'} ||= $new_admin_user->{'date'};
	    
	my $date_field = sprintf $date_format{'write'}{$Conf{'db_type'}}, $new_admin_user->{'date'}, $new_admin_user->{'date'};
	my $update_field = sprintf $date_format{'write'}{$Conf{'db_type'}}, $new_admin_user->{'update_date'}, $new_admin_user->{'update_date'};
	    
	$list_cache{'is_admin_user'}{$self->{'domain'}}{$name}{$who} = undef;
	    
	my $statement;

	##  either is_included or is_subscribed must be set
	## default is is_subscriber for backward compatibility reason
#	if ($self->{'admin'}{'user_data_source'} eq 'include2') {
	    unless ($new_admin_user->{'included'}) {
		$new_admin_user->{'subscribed'} = 1;
	    }
#	}
	    
	unless ($new_admin_user->{'included'}) {
	    ## Is the email in user table ?
	    if (! is_user_db($who)) {
		## Insert in User Table
		$statement = sprintf "INSERT INTO user_table (email_user, gecos_user, lang_user, password_user) VALUES (%s,%s,%s,%s)",$dbh->quote($who), $dbh->quote($new_admin_user->{'gecos'}), $dbh->quote($new_admin_user->{'lang'}), $dbh->quote($new_admin_user->{'password'});
		
		unless ($dbh->do($statement)) {
		    do_log('err','Unable to execute SQL statement "%s" : %s', $statement, $dbh->errstr);
		    next;
		}
	    }
	}	    

	$new_admin_user->{'subscribed'} ||= 0;
 	$new_admin_user->{'included'} ||= 0;

	## Update Admin Table
	$statement = sprintf "INSERT INTO admin_table (user_admin, comment_admin, list_admin, robot_admin, date_admin, update_admin, reception_admin,subscribed_admin,included_admin,include_sources_admin, role_admin, info_admin, profile_admin) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)", 
	$dbh->quote($who), 
	$dbh->quote($new_admin_user->{'gecos'}), 
	$dbh->quote($name), 
	$dbh->quote($self->{'domain'}),
	$date_field, 
	$update_field, 
	$dbh->quote($new_admin_user->{'reception'}), 
	$new_admin_user->{'subscribed'}, 
	$new_admin_user->{'included'}, 
	$dbh->quote($new_admin_user->{'id'}), 
	$dbh->quote($role), 
	$dbh->quote($new_admin_user->{'info'}), 
	$dbh->quote($new_admin_user->{'profile'});
	
	unless ($dbh->do($statement)) {
	    do_log('err','Unable to execute SQL statement "%s" : %s', $statement, $dbh->errstr);
	    next;
	}
	$total++;
    }

    return $total;
}

## Update subscribers and admin users (used while renaming a list)
sub rename_list_db {
    my($self, $new_listname, $new_robot) = @_;
    do_log('debug', 'List::rename_list_db(%s,%s,%s)', $self->{'name'},$new_listname, $new_robot);

    unless ($List::use_db) {
	&do_log('info', 'Sympa not setup to use DBI');
	return undef;
    }

    my $statement_subscriber;
    my $statement_admin;
    
    ## Check database connection
    unless ($dbh and $dbh->ping) {
	return undef unless &db_connect();
    }	   
    
    $statement_subscriber =  sprintf "UPDATE subscriber_table SET list_subscriber=%s, robot_subscriber=%s WHERE (list_subscriber=%s AND robot_subscriber=%s)", 
    $dbh->quote($new_listname), 
    $dbh->quote($new_robot),
    $dbh->quote($self->{'name'}),
    $dbh->quote($self->{'domain'}) ; 

    do_log('debug', 'List::rename_list_db statement : %s',  $statement_subscriber );

    unless ($dbh->do($statement_subscriber)) {
	do_log('err','Unable to execute SQL statement "%s" : %s', $statement_subscriber, $dbh->errstr);
	return undef;
    }

    # admin_table is "alive" only in case include2
    if ($self->{'admin'}{'user_data_source'} eq 'include2'){

	$statement_admin =  sprintf "UPDATE admin_table SET list_admin=%s, robot_admin=%s WHERE (list_admin=%s AND robot_admin=%s)", 
	$dbh->quote($new_listname), 
	$dbh->quote($new_robot),
	$dbh->quote($self->{'name'}),
	$dbh->quote($self->{'domain'}) ; 

	do_log('debug', 'List::rename_list_db statement : %s',  $statement_admin );

	unless ($dbh->do($statement_admin)) {
	    do_log('err','Unable to execute SQL statement "%s" : %s', $statement_admin, $dbh->errstr);
	    return undef;
	}
    }
    
    return 1;
}


## Is the user listmaster
sub is_listmaster {
    my $who = shift;
    my $robot = shift;

    $who =~ y/A-Z/a-z/;

    return 0 unless ($who);

    if ($robot && (defined $Conf{'robots'}{$robot}) && $Conf{'robots'}{$robot}{'listmasters'}) {
	foreach my $listmaster (@{$Conf{'robots'}{$robot}{'listmasters'}}){
	    return 1 if (lc($listmaster) eq lc($who));
	} 
    }
	
    foreach my $listmaster (@{$Conf{'listmasters'}}){
	    return 1 if (lc($listmaster) eq lc($who));
	}    

    return 0;
}

## Does the user have a particular function in the list ?
sub am_i {
    my($self, $function, $who, $options) = @_;
    do_log('debug2', 'List::am_i(%s, %s, %s)', $function, $self->{'name'}, $who);
    
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
	# &do_log('debug3', 'Use cache(%s,%s): %s', $name, $who, $list_cache{'is_user'}{$self->{'domain'}}{$name}{$who});
	return $list_cache{'am_i'}{$function}{$self->{'domain'}}{$self->{'name'}}{$who};
    }

    if ($self->{'admin'}{'user_data_source'} eq 'include2'){

	##Check editors
	if ($function =~ /^editor$/i){

	    ## Check cache first
 	    if ($list_cache{'am_i'}{$function}{$self->{'domain'}}{$self->{'name'}}{$who} == 1) {
 		return 1;
 	    }

	    my $editor = $self->get_admin_user('editor',$who);

	    if (defined $editor) {
		return 1;
	    }else {
 		## Check if any editor is defined ; if not owners are editors
 		my $editors = $self->get_editors();
 		if ($#{$editors} < 0) {

		    # if no editor defined, owners has editor privilege
		    $editor = $self->get_admin_user('owner',$who);
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
	    my $owner = $self->get_admin_user('owner',$who);
	    if (defined $owner) {		    
		## Update cache
		$list_cache{'am_i'}{'owner'}{$self->{'domain'}}{$self->{'name'}}{$who} = 1;

		return 1;
	    }else {
		    
		## Update cache
		$list_cache{'am_i'}{'owner'}{$self->{'domain'}}{$self->{'name'}}{$who} = 0;

		return undef;
	    }
	}
	elsif ($function =~ /^privileged_owner$/i) {
	    my $privileged = $self->get_admin_user('owner',$who);
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
	else {
	    return undef;
	}
    }else {
	my $u;

	if ($function =~ /^editor$/i){
	    if ($self->{'admin'}{$function} && ($#{$self->{'admin'}{$function}} >= 0)) {
		foreach $u (@{$self->{'admin'}{$function}}) {
		    return 1 if (lc($u->{'email'}) eq lc($who));
		}
		## if no editor defined, owners has editor privilege
	    }else{
		foreach $u (@{$self->{'admin'}{'owner'}}) {
		    if (ref($u->{'email'})) {
			foreach my $o (@{$u->{'email'}}) {
			    return 1 if (lc($o) eq lc($who));
			}
		    }else {
			return 1 if (lc($u->{'email'}) eq lc($who));
		    }
		} 
	    }
	    return undef;
	}
	## Check owners
	if ($function =~ /^owner$/i){
	    return undef unless ($self->{'admin'} && $self->{'admin'}{'owner'});
	    
	    foreach $u (@{$self->{'admin'}{'owner'}}) {
		if (ref($u->{'email'})) {
		    foreach my $o (@{$u->{'email'}}) {
			return 1 if (lc($o) eq lc($who));
		    }
		}else {
		    return 1 if (lc($u->{'email'}) eq lc($who));
		}
	    }
	}
	elsif ($function =~ /^privileged_owner$/i) {
	    foreach $u (@{$self->{'admin'}{'owner'}}) {
		next unless ($u->{'profile'} =~ 'privileged');
		if (ref($u->{'email'})) {
		    foreach my $o (@{$u->{'email'}}) {
			return 1 if (lc($o) eq lc($who));
		    }
		}else {
		    return 1 if (lc($u->{'email'}) eq lc($who));
		}
	    }
	}
	return undef;
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
    &do_log('debug', 'List::check_list_authz %s,%s',$operation,$auth_method);

    $context->{'listname'} = $self->{'name'};

    return &request_action($operation, $auth_method, $self->{'domain'}, $context, $debug);
}

####################################################
# request_action
####################################################
# Return the action to perform for 1 sender 
# using 1 auth method to perform 1 operation
#
# IN : -$operation (+) : scalar
#      -$auth_method (+) : 'smtp'|'md5'|'pgp'|'smime'
#      -$robot (+) : scalar
#      -$context (+) : ref(HASH) containing information
#        to evaluate scenario (scenario var)
#      -$debug : adds keys in the returned HASH 
#
# OUT : undef | ref(HASH) containing keys :
#        -action : 'do_it'|'reject'|'request_auth'
#           |'owner'|'editor'|'editorkey'|'listmaster'
#        -reason : defined if action == 'reject' 
#           and in scenario : reject(reason='...')
#           key for template authorization_reject.tt2
#        -tt2 : defined if action == 'reject'  
#           and in scenario : reject(tt2='...') or reject('...tt2')
#           match a key in authorization_reject.tt2
#        -condition : the checked condition 
#           (defined if $debug)
#        -auth_method : the checked auth_method 
#           (defined if $debug)
###################################################### 
sub request_action {
    my $operation = shift;
    my $auth_method = shift;
    my $robot=shift;
    my $context = shift;
    my $debug = shift;
    do_log('debug', 'List::request_action %s,%s,%s',$operation,$auth_method,$robot);

    $context->{'sender'} ||= 'nobody' ;
    $context->{'email'} ||= $context->{'sender'};
    $context->{'remote_host'} ||= 'unknown_host' ;
    $context->{'robot_domain'} = $robot ;
    $context->{'msg'} = $context->{'message'}->{'msg'} if (defined $context->{'message'});
    $context->{'msg_encrypted'} = 'smime' if (defined $context->{'message'} && 
					      $context->{'message'}->{'smime_crypted'} eq 'smime_crypted');

    unless ( $auth_method =~ /^(smtp|md5|pgp|smime)/) {
	do_log('info',"fatal error : unknown auth method $auth_method in List::get_action");
	return undef;
    }
    my (@rules, $name) ;
    my $list;
    if ($context->{'listname'}) {
        unless ( $list = new List ($context->{'listname'}, $robot) ){
	    do_log('info',"request_action :  unable to create object $context->{'listname'}");
	    return undef ;
	}
    
	my @operations = split /\./, $operation;
	my $data_ref;
	if ($#operations == 0) {
	    $data_ref = $list->{'admin'}{$operation};
	}else{
	    $data_ref = $list->{'admin'}{$operations[0]}{$operations[1]};
	}
	
	unless ((defined $data_ref) && (defined $data_ref->{'rules'})) {
	    do_log('info',"request_action: no entry $operation defined for list");
	    return undef ;
	}

	## pending/closed lists => send/visibility are closed
	unless ($list->{'admin'}{'status'} eq 'open') {
	    if ($operation =~ /^send|visibility$/) {
		my $return = {'action' => 'reject',
			      'reason' => 'list-no-open',
			      'auth_method' => '',
			      'condition' => ''
			      };
		return $return;
	    }
	}

	### the following lines are used by the document sharing action 
	if (defined $context->{'scenario'}) { 
	    # information about the  scenario to load
	    my $s_name = $context->{'scenario'}; 
	    
	    # loading of the structure
	    my  $scenario = &_load_scenario_file ($operations[$#operations], $robot, $s_name,$list->{'dir'});
	    return undef unless (defined $scenario);
	    @rules = @{$scenario->{'rules'}};
	    $name = $scenario->{'name'}; 
	    $data_ref = $scenario;
	}

	@rules = @{$data_ref->{'rules'}};
	$name = $data_ref->{'name'};

    }elsif ($context->{'topicname'}) {
	my $scenario = $list_of_topics{$robot}{$context->{'topicname'}}{'visibility'};
	@rules = @{$scenario->{'rules'}};
	$name = $scenario->{'name'};

    }else{	
	my $scenario;
	my $p;
	
	$p = &Conf::get_robot_conf($robot, $operation);

	return undef 
	    unless ($scenario = &_load_scenario_file ($operation, $robot, $p));
        @rules = @{$scenario->{'rules'}};
	$name = $scenario->{'name'};
    }

    unless ($name) {
	do_log('err',"internal error : configuration for operation $operation is not yet performed by scenario");
	return undef;
    }

    my $return = {};
    foreach my $rule (@rules) {
	next if ($rule eq 'scenario');
	if ($auth_method eq $rule->{'auth_method'}) {

	    my $result =  &verify ($context,$rule->{'condition'});
	    
	    if (! defined ($result)) {
		do_log('info',"error in $rule->{'condition'},$rule->{'auth_method'},$rule->{'action'}" );
		
#		if (defined $context->{'listname'}) {
		&do_log('info', 'Error in %s scenario, in list %s', $context->{'scenario'}, $context->{'listname'});
#		}
		
		if ($debug) {
		    $return = {'action' => 'reject',
			       'reason' => 'error-performing-condition',
			       'auth_method' => $rule->{'auth_method'},
			       'condition' => $rule->{'condition'}
			   };
		    return $return;
		}
		unless (&List::send_notify_to_listmaster('error-performing-condition', $robot, [$context->{'listname'}."  ".$rule->{'condition'}] )) {
		    &do_log('notice',"Unable to send notify 'error-performing-condition' to listmaster");
		}
		return undef;
	    }
	    if ($result == -1) {
		do_log('debug3',"rule $rule->{'condition'},$rule->{'auth_method'},$rule->{'action'} rejected");
		next;
	    }
	    
	    my $action = $rule->{'action'};

            ## reject : get parameters
	    if ($action =~/^reject(\((.+)\))?(\s?,\s?(quiet))?/) {

		if ($4 eq 'quiet') { 
		    $action = 'reject,quiet';
		} else{
		    $action = 'reject';	
		}
		my @param = split /,/,$2;
		
       		foreach my $p (@param){
		    if  ($p =~ /^reason=\'?(\w+)\'?/){
			$return->{'reason'} = $1;
			next;
			
		    }elsif ($p =~ /^tt2=\'?(\w+)\'?/){
			$return->{'tt2'} = $1;
			next;
			
		    }
		    if ($p =~ /^\'?[^=]+\'?/){
			$return->{'tt2'} = $p;
			# keeping existing only, not merging with reject parameters in scenarios
			last;
		    }
		}
	    }

	    $return->{'action'} = $action;
	    
	    if ($result == 1) {
		&do_log('debug3',"rule $rule->{'condition'},$rule->{'auth_method'},$rule->{'action'} accepted");
		if ($debug) {
		    $return->{'auth_method'} = $rule->{'auth_method'};
		    $return->{'condition'} = $rule->{'condition'};
		    return $return;
		}

		## Check syntax of returned action
		unless ($action =~ /^(do_it|reject|request_auth|owner|editor|editorkey|listmaster)/) {
		    &do_log('err', "Matched unknown action '%s' in scenario", $rule->{'action'});
		    return undef;
		}
		return $return;
	    }
	}
    }
    &do_log('debug3',"no rule match, reject");

    $return = {'action' => 'reject',
	       'reason' => 'no-rule-match',
			   'auth_method' => 'default',
			   'condition' => 'default²'
			   };
    return $return;
}

## Initialize internal list cache
sub init_list_cache {
    &do_log('debug2', 'List::init_list_cache()');
    
    undef %list_cache;
}

## check if email respect some condition
sub verify {
    my ($context, $condition) = @_;
    do_log('debug3', 'List::verify(%s)', $condition);

    my $robot = $context->{'robot_domain'};

#    while (my($k,$v) = each %{$context}) {
#	do_log('debug3',"verify: context->{$k} = $v");
#    }

    unless (defined($context->{'sender'} )) {
	do_log('info',"internal error, no sender find in List::verify, report authors");
	return undef;
    }

    $context->{'execution_date'} = time unless ( defined ($context->{'execution_date'}) );

    if (defined ($context->{'msg'})) {
	my $header = $context->{'msg'}->head;
	unless (($header->get('to') && ($header->get('to') =~ /$context->{'listname'}/i)) || 
		($header->get('cc') && ($header->get('cc') =~ /$context->{'listname'}/i))) {
	    $context->{'is_bcc'} = 1;
	}else{
	    $context->{'is_bcc'} = 0;
	}
	
    }
    my $list;
    if (defined ($context->{'listname'})) {
	$list = new List ($context->{'listname'}, $robot);
	unless ($list) {
	    do_log('err','Unable to create list object %s', $context->{'listname'});
	    return undef;
	}

	$context->{'host'} = $list->{'admin'}{'host'};
    }

    unless ($condition =~ /(\!)?\s*(true|is_listmaster|is_editor|is_owner|is_subscriber|match|equal|message|older|newer|all|search)\s*\(\s*(.*)\s*\)\s*/i) {
	&do_log('err', "error rule syntaxe: unknown condition $condition");
	return undef;
    }
    my $negation = 1 ;
    if ($1 eq '!') {
	$negation = -1 ;
    }

    my $condition_key = lc($2);
    my $arguments = $3;
    my @args;

    while ($arguments =~ s/^\s*(
				\[\w+(\-\>[\w\-]+)?\]
				|
				([\w\-\.]+)
				|
				'[^,)]*'
				|
				"[^,)]*"
				|
				\/([^\/\\]+|\\\/|\\)+[^\\]+\/
				|(\w+)\.ldap
				)\s*,?//x) {
	my $value=$1;

	## Config param
	if ($value =~ /\[conf\-\>([\w\-]+)\]/i) {
	    if (my $conf_value = &Conf::get_robot_conf($robot, $1)) {
		
		$value =~ s/\[conf\-\>([\w\-]+)\]/$conf_value/;
	    }else{
		do_log('debug',"undefine variable context $value in rule $condition");
		# a condition related to a undefined context variable is always false
		return -1 * $negation;
 #		return undef;
	    }

	    ## List param
	}elsif ($value =~ /\[list\-\>([\w\-]+)\]/i) {
	    if ($1 =~ /^name|total$/) {
		$value =~ s/\[list\-\>([\w\-]+)\]/$list->{$1}/;
	    }elsif ($list->{'admin'}{$1} and (!ref($list->{'admin'}{$1})) ) {
		$value =~ s/\[list\-\>([\w\-]+)\]/$list->{'admin'}{$1}/;
	    }else{
		do_log('err','Unknown list parameter %s in rule %s', $value, $condition);
		return undef;
	    }

	}elsif ($value =~ /\[env\-\>([\w\-]+)\]/i) {
	    
	    $value =~ s/\[env\-\>([\w\-]+)\]/$ENV{$1}/;

	    ## Sender's user/subscriber attributes (if subscriber)
	}elsif ($value =~ /\[user\-\>([\w\-]+)\]/i) {

	    $context->{'user'} ||= &get_user_db($context->{'sender'});	    
	    $value =~ s/\[user\-\>([\w\-]+)\]/$context->{'user'}{$1}/;

	}elsif ($value =~ /\[user_attributes\-\>([\w\-]+)\]/i) {
	    
	    $context->{'user'} ||= &get_user_db($context->{'sender'});
	    $value =~ s/\[user_attributes\-\>([\w\-]+)\]/$context->{'user'}{'attributes'}{$1}/;

	}elsif (($value =~ /\[subscriber\-\>([\w\-]+)\]/i) && defined ($context->{'sender'} ne 'nobody')) {
	    
	    $context->{'subscriber'} ||= $list->get_subscriber($context->{'sender'});
	    $value =~ s/\[subscriber\-\>([\w\-]+)\]/$context->{'subscriber'}{$1}/;

	    ## SMTP Header field
	}elsif ($value =~ /\[(msg_header|header)\-\>([\w\-]+)\]/i) {
	    my $field_name = $2;
	    if (defined ($context->{'msg'})) {
		my $header = $context->{'msg'}->head;
		my $field = $header->get($field_name);
		$value =~ s/\[(msg_header|header)\-\>$field_name\]/$field/;
	    }else {
		return -1 * $negation;
	    }
	    
	}elsif ($value =~ /\[msg_body\]/i) {
	    return -1 * $negation unless (defined ($context->{'msg'}));
	    return -1 * $negation unless (defined ($context->{'msg'}->effective_type() =~ /^text/));
	    return -1 * $negation unless (defined $context->{'msg'}->bodyhandle);

	    $value = $context->{'msg'}->bodyhandle->as_string();

	}elsif ($value =~ /\[msg_part\-\>body\]/i) {
	    return -1 * $negation unless (defined ($context->{'msg'}));
	    
	    my @bodies;
	    my @parts = $context->{'msg'}->parts();
	    
	    ## Should be recurcive...
	    foreach my $i (0..$#parts) {
		next unless ($parts[$i]->effective_type() =~ /^text/);
		next unless ($parts[$i]->bodyhandle);

		push @bodies, $parts[$i]->bodyhandle->as_string();
	    }
	    $value = \@bodies;

	}elsif ($value =~ /\[msg_part\-\>type\]/i) {
	    return -1 * $negation unless (defined ($context->{'msg'}));
	    
	    my @types;
	    my @parts = $context->{'msg'}->parts();
	    foreach my $i (0..$#parts) {
		push @types, $parts[$i]->effective_type();
	    }
	    $value = \@types;

	}elsif ($value =~ /\[current_date\]/i) {
	    my $time = time;
	    $value =~ s/\[current_date\]/$time/;
	    
	    ## Quoted string
	}elsif ($value =~ /\[(\w+)\]/i) {

	    if (defined ($context->{$1})) {
		$value =~ s/\[(\w+)\]/$context->{$1}/i;
	    }else{
		do_log('debug',"undefine variable context $value in rule $condition");
		# a condition related to a undefined context variable is always false
		return -1 * $negation;
 #		return undef;
	    }
	    
	}elsif ($value =~ /^'(.*)'$/ || $value =~ /^"(.*)"$/) {
	    $value = $1;
	}
	push (@args,$value);
	
    }
    # condition that require 0 argument
    if ($condition_key =~ /^true|all$/i) {
	unless ($#args == -1){ 
	    do_log('err',"error rule syntaxe : incorrect number of argument or incorrect argument syntaxe $condition") ; 
	    return undef ;
	}
	# condition that require 1 argument
    }elsif ($condition_key eq 'is_listmaster') {
	unless ($#args == 0) { 
	     do_log('err',"error rule syntaxe : incorrect argument number for condition $condition_key") ; 
	    return undef ;
	}
	# condition that require 2 args
#
    }elsif ($condition_key =~ /^is_owner|is_editor|is_subscriber|match|equal|message|newer|older|search$/i) {
	unless ($#args == 1) {
	    do_log('err',"error rule syntaxe : incorrect argument number for condition $condition_key") ; 
	    return undef ;
	}
    }else{
	do_log('err', "error rule syntaxe : unknown condition $condition_key");
	return undef;
    }
    ## Now eval the condition
    ##### condition : true
    if ($condition_key =~ /\s*(true|any|all)\s*/i) {
	return $negation;
    }
    ##### condition is_listmaster
    if ($condition_key eq 'is_listmaster') {
	
	if ($args[0] eq 'nobody') {
	    return -1 * $negation ;
	}

	if ( &is_listmaster($args[0],$robot)) {
	    return $negation;
	}else{
	    return -1 * $negation;
	}
    }

    ##### condition older
    if ($condition_key =~ /older|newer/) {
	 
	$negation *= -1 if ($condition_key eq 'newer');
 	my $arg0 = &tools::epoch_conv($args[0]);
 	my $arg1 = &tools::epoch_conv($args[1]);
 
	&do_log('debug4', '%s(%d, %d)', $condition_key, $arg0, $arg1);
 	if ($arg0 <= $arg1 ) {
 	    return $negation;
 	}else{
 	    return -1 * $negation;
 	}
     }


    ##### condition is_owner, is_subscriber and is_editor
    if ($condition_key =~ /is_owner|is_subscriber|is_editor/i) {

	my ($list2);

	if ($args[1] eq 'nobody') {
	    return -1 * $negation ;
	}

	## The list is local or in another local robot
	if ($args[0] =~ /\@/) {
	    $list2 = new List ($args[0]);
	}else {
	    $list2 = new List ($args[0], $robot);
	}
		
	if (! $list2) {
	    do_log('err',"unable to create list object \"$args[0]\"");
	    return -1 * $negation ;
	}

	if ($condition_key eq 'is_subscriber') {

	    if ($list2->is_user($args[1])) {
		return $negation ;
	    }else{
		return -1 * $negation ;
	    }

	}elsif ($condition_key eq 'is_owner') {
	    if ($list2->am_i('owner',$args[1])) {
		return $negation ;
	    }else{
		return -1 * $negation ;
	    }

	}elsif ($condition_key eq 'is_editor') {
	    if ($list2->am_i('editor',$args[1])) {
		return $negation ;
	    }else{
		return -1 * $negation ;
	    }
	}
    }
    ##### match
    if ($condition_key eq 'match') {
	unless ($args[1] =~ /^\/(.*)\/$/) {
	    &do_log('err', 'Match parameter %s is not a regexp', $args[1]);
	    return undef;
	}
	my $regexp = $1;
	
	if ($regexp =~ /\[host\]/) {
	    my $reghost = &Conf::get_robot_conf($robot, 'host');
            $reghost =~ s/\./\\./g ;
            $regexp =~ s/\[host\]/$reghost/g ;
	}

	if (ref($args[0])) {
	    foreach my $arg (@{$args[0]}) {
		return $negation 
		    if ($arg =~ /$regexp/i);
	    }
	}else {
	    if ($args[0] =~ /$regexp/i) {
		return $negation ;
	    }
	}
	
	return -1 * $negation ;

    }
    
    ##search
    if ($condition_key eq 'search') {
	my $val_search;
 	# we could search in the family if we got ref on Family object
 	if (defined $list){
 	    $val_search = &search($args[0],$args[1],$robot,$list);
 	}else {
 	    $val_search = &search($args[0],$args[1],$robot);
 	}

	if($val_search == 1) { 
	    return $negation;
	}else {
	    return -1 * $negation;
    	}
    }

    ## equal
    if ($condition_key eq 'equal') {
	if (ref($args[0])) {
	    foreach my $arg (@{$args[0]}) {
		&do_log('debug3', 'ARG: %s', $arg);
		return $negation 
		    if ($arg =~ /^$args[1]$/i);
	    }
	}else {
	    if ($args[0] =~ /^$args[1]$/i) {
		return $negation ;
	    }
	}

	return -1 * $negation ;
    }
    return undef;
}

## Verify if a given user is part of an LDAP search filter
sub search{
    my $filter_file = shift;
    my $sender = shift;
    my $robot = shift;
    my $list = shift;

    &do_log('debug2', 'List::search(%s,%s,%s)', $filter_file, $sender, $robot);

    my $file;

    unless ($file = &tools::get_filename('etc',"search_filters/$filter_file", $robot, $list)) {
	&do_log('err', 'Could not find search filter %s', $filter_file);
	return undef;
    }   

    if ($filter_file =~ /\.ldap$/) {
	
    my $timeout = 3600;

    my $var;
    my $time = time;
    my $value;

    my %ldap_conf;
    
    return undef unless (%ldap_conf = &Ldap::load($file));

 
    my $filter = $ldap_conf{'filter'};	
    $filter =~ s/\[sender\]/$sender/g;
    
	if (defined ($persistent_cache{'named_filter'}{$filter_file}{$filter}) &&
	    (time <= $persistent_cache{'named_filter'}{$filter_file}{$filter}{'update'} + $timeout)){ ## Cache has 1hour lifetime
        &do_log('notice', 'Using previous LDAP named filter cache');
	    return $persistent_cache{'named_filter'}{$filter_file}{$filter}{'value'};
    }

    unless (eval "require Net::LDAP") {
	do_log('err',"Unable to use LDAP library, Net::LDAP required, install perl-ldap (CPAN) first");
	return undef;
    }
    require Net::LDAP;
    
    ## There can be replicates
    foreach my $host_entry (split(/,/,$ldap_conf{'host'})) {

	$host_entry =~ s/^\s*(\S.*\S)\s*$/$1/;
	my ($host,$port) = split(/:/,$host_entry);
	
	## If port a 'port' entry was defined, use it as default
	$port = $port || $ldap_conf{'port'} || 389;
	
	my $ldap = Net::LDAP->new($host, port => $port );
	
	unless ($ldap) {	
	    do_log('notice','Unable to connect to the LDAP server %s:%d',$host, $port);
	    next;
	}
	
	my $status; 

	if (defined $ldap_conf{'bind_dn'} && defined $ldap_conf{'bind_password'}) {
	    $status = $ldap->bind($ldap_conf{'bind_dn'}, password =>$ldap_conf{'bind_password'});
	}else {
	    $status = $ldap->bind();
	}

	unless ($status && ($status->code == 0)) {
	    do_log('notice','Unable to bind to the LDAP server %s:%d',$host, $port);
	    next;
	}
	
	my $mesg = $ldap->search(base => "$ldap_conf{'suffix'}" ,
				 filter => "$filter",
				 scope => "$ldap_conf{'scope'}");
    	
	
	if ($mesg->count() == 0){
		$persistent_cache{'named_filter'}{$filter_file}{$filter}{'value'} = 0;
	    
	}else {
		$persistent_cache{'named_filter'}{$filter_file}{$filter}{'value'} = 1;
	}
      	
	$ldap->unbind or do_log('notice','List::search_ldap.Unbind impossible');
	    $persistent_cache{'named_filter'}{$filter_file}{$filter}{'update'} = time;
	
	    return $persistent_cache{'named_filter'}{$filter_file}{$filter}{'value'};
	}
    }
    
    return undef;
}

## May the indicated user edit the indicated list parameter or not ?
sub may_edit {

    my($self,$parameter, $who) = @_;
    do_log('debug3', 'List::may_edit(%s, %s)', $parameter, $who);

    my $role;

    return undef unless ($self);

    my $edit_conf;

    # Load edit_list.conf: track by file, not domain (file may come from server, robot, family or list context)
    my $edit_conf_file = &tools::get_filename('etc','edit_list.conf',$self->{'domain'},$self); 
    if (! $edit_list_conf{$edit_conf_file} || ((stat($edit_conf_file))[9] > $mtime{'edit_list_conf'}{$edit_conf_file})) {

        $edit_conf = $edit_list_conf{$edit_conf_file} = &tools::load_edit_list_conf($self->{'domain'}, $self);
	$mtime{'edit_list_conf'}{$edit_conf_file} = time;
    }else {
        $edit_conf = $edit_list_conf{$edit_conf_file};
    }

    ## What privilege ?
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

    ## What privilege does he/she has ?
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
# sa cette procédure est appelée nul part, je lui ajoute malgrès tout le paramêtre robot
# edit_conf devrait être aussi dépendant du robot
sub may_create_parameter {

    my($self, $parameter, $who,$robot) = @_;
    do_log('debug3', 'List::may_create_parameter(%s, %s, %s)', $parameter, $who,$robot);

    if ( &is_listmaster($who,$robot)) {
	return 1;
    }
    my $edit_conf = &tools::load_edit_list_conf($robot,$self);
    $edit_conf->{$parameter} ||= $edit_conf->{'default'};
    if (! $edit_conf->{$parameter}) {
	do_log('notice','tools::load_edit_list_conf privilege for parameter $parameter undefined');
	return undef;
    }
    if ($edit_conf->{$parameter}  =~ /^(owner)||(privileged_owner)$/i ) {
	return 1;
    }else{
	return 0;
    }

}


## May the indicated user do something with the list or not ?
## Action can be : send, review, index, get
##                 add, del, reconfirm, purge
sub may_do {
   my($self, $action, $who) = @_;
   do_log('debug3', 'List::may_do(%s, %s)', $action, $who);

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
	   return 1 if ($self->is_user($who));
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
	       return 1 if ($self->is_user($who));
	       return $self->am_i('owner', $who);
	   }elsif ($i =~ /^owner$/io) {
	       return $self->am_i('owner', $who);
	   }
	   return undef;
       }
   }

   if ($action =~ /^send$/io) {
      if ($admin->{'send'} =~/^(private|privateorpublickey|privateoreditorkey)$/i) {

         return undef unless ($self->is_user($who) || $self->am_i('owner', $who));
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
	   return 1 if ($self->is_user($who) || $self->am_i('owner', $who));
       } elsif ($admin->{'send'} =~ /^(privateorpublickey)$/io) {
	   return 1 unless ($self->is_user($who) || $self->am_i('owner', $who));
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

## Does the file exist ?
sub archive_exist {
   my($self, $file) = @_;
   do_log('debug', 'List::archive_exist (%s)', $file);

   return undef unless ($self->is_archived());
   my $dir = &Conf::get_robot_conf($self->{'domain'},'arc_path').'/'.$self->get_list_id();
   Archive::exist($dir, $file);

}


## List the archived files
sub archive_ls {
   my $self = shift;
   do_log('debug2', 'List::archive_ls');

   my $dir = &Conf::get_robot_conf($self->{'domain'},'arc_path').'/'.$self->get_list_id();

   Archive::list($dir) if ($self->is_archived());
}

## Archive 
sub archive_msg {
    my($self, $msg ) = @_;
    do_log('debug2', 'List::archive_msg for %s',$self->{'name'});

    my $is_archived = $self->is_archived();
    Archive::store_last($self, $msg) if ($is_archived);

    Archive::outgoing("$Conf{'queueoutgoing'}",$self->get_list_id(),$msg) 
      if ($self->is_web_archived());
}

sub archive_msg_digest {
   my($self, $msg) = @_;
   do_log('debug2', 'List::archive_msg_digest');

   $self->store_digest( $msg) if ($self->{'name'});
}

## Is the list moderated ?                                                          
sub is_moderated {
    
    return 1 if (defined shift->{'admin'}{'editor'});
                                                          
    return 0;
}

## Is the list archived ?
sub is_archived {
    do_log('debug', 'List::is_archived');    
    if (shift->{'admin'}{'web_archive'}{'access'}) {do_log('debug', 'List::is_archived : 1'); return 1 ;}  
    do_log('debug', 'List::is_archived : undef');
    return undef;
}

## Is the list web archived ?
sub is_web_archived {
    return 1 if (shift->{'admin'}{'web_archive'}{'access'}) ;
    return undef;
   
}

## Returns 1 if the  digest  must be send 
sub get_nextdigest {
    my $self = shift;
    do_log('debug3', 'List::get_nextdigest (%s)');

    my $digest = $self->{'admin'}{'digest'};
    my $listname = $self->{'name'};

    ## Reverse compatibility concerns
    my $filename;
    foreach my $f ("$Conf{'queuedigest'}/$listname",
 		   $Conf{'queuedigest'}.'/'.$self->get_list_id()) {
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

## load a scenario if not inline (in the list configuration file)
sub _load_scenario_file {
    my ($function, $robot, $name, $directory)= @_;
    ## Too much log
    do_log('debug3', 'List::_load_scenario_file(%s, %s, %s, %s)', $function, $robot, $name, $directory);

    my $structure;
    
    ## List scenario

   
    # sa tester le chargement de scenario spécifique à un répertoire du shared
    my $scenario_file = $directory.'/scenari/'.$function.'.'.$name ;
    unless (($directory) && (open SCENARI, $scenario_file)) {
	## Robot scenario
	$scenario_file = "$Conf{'etc'}/$robot/scenari/$function.$name";
	unless (($robot) && (open SCENARI, $scenario_file)) {

	    ## Site scenario
	    $scenario_file = "$Conf{'etc'}/scenari/$function.$name";
	    unless (open SCENARI, $scenario_file) {
		
		## Distrib scenario
		$scenario_file = "--ETCBINDIR--/scenari/$function.$name";
		unless (open SCENARI,$scenario_file) {
		    do_log('err',"Unable to open scenario file $function.$name, please report to listmaster") unless ($name =~ /\.header$/) ;
		    return &_load_scenario ($function,$robot,$name,'true() smtp -> reject', $directory) unless ($function eq 'include');
		}
	    }
	}
    }
    my $paragraph= join '',<SCENARI>;
    close SCENARI;
    unless ($structure = &_load_scenario ($function,$robot,$name,$paragraph, $directory)) { 
	do_log('err',"Error in $function scenario $scenario_file ");
	return undef;
    }
     
    return $structure ;
}

sub _load_scenario {
    my ($function, $robot,$scenario_name, $paragraph, $directory ) = @_;
    do_log('debug3', 'List::_load_scenario(%s,%s,%s)', $function,$robot,$scenario_name);

    my $structure = {};
    $structure->{'name'} = $scenario_name ;
    my @scenario;
    my @rules = split /\n/, $paragraph;

    

    ## Following lines are ordered
    push(@scenario, 'scenario');
    unless ($function eq 'include') {
	my $include = &_load_scenario_file ('include',$robot,"$function.header", $directory);
	
	push(@scenario,@{$include->{'rules'}}) if ($include);
    }
    foreach (@rules) {
	next if (/^\s*\w+\s*$/o); # skip paragraph name
	my $rule = {};
	s/\#.*$//;         # remove comments
        next if (/^\s*$/); # reject empty lines
	if (/^\s*title\.gettext\s+(.*)\s*$/i) {
	    $structure->{'title'}{'gettext'} = $1;
	    next;
	}elsif (/^\s*title\.(\w+)\s+(.*)\s*$/i) {
	    $structure->{'title'}{$1} = $2;
	    next;
	}
        
        if (/^\s*include\s*(.*)\s*$/i) {
        ## introducing in few common rules using include
	    my $include = &_load_scenario_file ('include',$robot,$1, $directory);
            push(@scenario,@{$include->{'rules'}}) if ($include) ;
	    next;
	}

#	unless (/^\s*(.*)\s+(md5|pgp|smtp|smime)\s*->\s*(.*)\s*$/i) {
	unless (/^\s*(.*)\s+(md5|pgp|smtp|smime)((\s*,\s*(md5|pgp|smtp|smime))*)\s*->\s*(.*)\s*$/i) {
	    do_log('err', "error rule syntaxe in scenario $function rule line $. expected : <condition> <auth_mod> -> <action>");
	    do_log('err',"error parsing $rule");
	    return undef;
	}
	$rule->{condition}=$1;
	$rule->{auth_method}=$2 || 'smtp';
	$rule->{'action'} = $6;

	
#	## Make action an ARRAY
#	my $action = $6;
#	my @actions;
#	while ($action =~ s/^\s*((\w+)(\s?\([^\)]*\))?)(\s|\,|$)//) {
#	    push @actions, $1;
#	}
#	$rule->{action} = \@actions;
	       
	push(@scenario,$rule);
#	do_log('debug3', "load rule 1: $rule->{'condition'} $rule->{'auth_method'} ->$rule->{'action'}");

        my $auth_list = $3 ; 
        while ($auth_list =~ /\s*,\s*(md5|pgp|smtp|smime)((\s*,\s*(md5|pgp|smtp|smime))*)\s*/i) {
	    push(@scenario,{'condition' => $rule->{condition}, 
                            'auth_method' => $1,
                            'action' => $rule->{action}});
	    $auth_list = $2;
#	    do_log('debug3', "load rule ite: $rule->{'condition'} $1 -> $rule->{'action'}");
	}
	
    }
    
    ## Restore paragraph mode
    $structure->{'rules'} = \@scenario;
   
    return $structure; 
}

## Loads all scenari for an action
sub load_scenario_list {
    my ($self, $action,$robot) = @_;
    do_log('debug3', 'List::load_scenario_list(%s,%s)', $action,$robot);

    my $directory = "$self->{'dir'}";
    my %list_of_scenario;
    my %skip_scenario;

    foreach my $dir ("$directory/scenari", "$Conf{'etc'}/$robot/scenari", "$Conf{'etc'}/scenari", "--ETCBINDIR--/scenari") {

	next unless (-d $dir);

	while (<$dir/$action.*:ignore>) {
	    if (/$action\.($tools::regexp{'scenario'}):ignore$/) {
		my $name = $1;
		$skip_scenario{$name} = 1;
	    }
	}

	while (<$dir/$action.*>) {
	    next unless (/$action\.($tools::regexp{'scenario'})$/);
	    my $name = $1;
	    
	    next if (defined $list_of_scenario{$name});
	    next if (defined $skip_scenario{$name});

	    my $scenario = &List::_load_scenario_file ($action, $robot, $name, $directory);
	    $list_of_scenario{$name} = $scenario;

	    ## Set the title in the current language
	    if (defined  $scenario->{'title'}{&Language::GetLang()}) {
		$list_of_scenario{$name}{'title'} = $scenario->{'title'}{&Language::GetLang()};
	    }elsif (defined $scenario->{'title'}{'gettext'}) {
		$list_of_scenario{$name}{'title'} = gettext($scenario->{'title'}{'gettext'});
	    }elsif (defined $scenario->{'title'}{'us'}) {
		$list_of_scenario{$name}{'title'} = gettext($scenario->{'title'}{'us'});
	    }else {
		$list_of_scenario{$name}{'title'} = $name;		     
	    }
	    $list_of_scenario{$name}{'name'} = $name;	    
	}
    }

    return \%list_of_scenario;
}

sub load_task_list {
    my ($self, $action,$robot) = @_;
    do_log('debug2', 'List::load_task_list(%s,%s)', $action,$robot);

    my $directory = "$self->{'dir'}";
    my %list_of_task;
    
    foreach my $dir ("$directory/list_task_models", "$Conf{'etc'}/$robot/list_task_models", "$Conf{'etc'}/list_task_models", "--ETCBINDIR--/list_task_models") {

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
    do_log('debug3', 'List::_load_task_title(%s)', $file);
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
    do_log('debug3', 'List::load_data_sources_list(%s,%s)', $self->{'name'},$robot);

    my $directory = "$self->{'dir'}";
    my %list_of_data_sources;

    foreach my $dir ("$directory/data_sources", "$Conf{'etc'}/$robot/data_sources", "$Conf{'etc'}/data_sources", "--ETCBINDIR--/data_sources") {

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

## Loads the statistics informations
sub _load_stats_file {
    my $file = shift;
    do_log('debug3', 'List::_load_stats_file(%s)', $file);

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
   return ($stats, $total);
}

## Loads the list of subscribers as a tied hash
sub _load_users {
    my $file = shift;
    do_log('debug2', 'List::_load_users(%s)', $file);

    ## Create the in memory btree using DB_File.
    my %users;
    my @users_list = (&_load_users_file($file)) ;     
    my $btree = new DB_File::BTREEINFO;
    return undef unless ($btree);
    $btree->{'compare'} = \&_compare_addresses;
    $btree->{'cachesize'} = 200 * ( $#users_list + 1 ) ;
    my $ref = tie %users, 'DB_File', undef, O_CREAT|O_RDWR, 0600, $btree;
    return undef unless ($ref);

    ## Counters.
    my $total = 0;

    foreach my $user ( @users_list ) {
	my $email = $user->{'email'};
	unless ($users{$email}) {
	    $total++;
	    $users{$email} = join("\n", %{$user});
	    unless ( defined ( $users{$email} )) { 
		# $btree->{'cachesize'} under-sized
		&do_log('err', '_load_users : cachesise too small : (%d users)', $total);
		return undef;  
	    }
	}
    }

    my $l = {
	'ref'	=>	$ref,
	'users'	=>	\%users,
	'total'	=>	$total
	};
    
    $l;
}

## Loads the list of subscribers.
sub _load_users_file {
    my $file = shift;
    do_log('debug2', 'List::_load_users_file(%s)', $file);
    
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

    my $id = _get_datasource_id($param);

    do_log('debug', 'List::_include_users_remote_sympa_list(%s) https://%s:%s/%s using cert %s,', $self->{'name'}, $host, $port, $path, $cert);
    
    my $total = 0; 
    my $get_total = 0;

    my $cert_file ; my $key_file ;

    $cert_file = $dir.'/cert.pem';
    $key_file = $dir.'/private_key';
    if ($cert eq 'list') {
	$cert_file = $dir.'/cert.pem';
	$key_file = $dir.'/private_key';
    }elsif($cert eq 'robot') {
	$cert_file = &tools::get_filename('etc','cert.pem',$robot,$self);
	$key_file =  &tools::get_filename('etc','private_key',$robot,$self);
    }
    unless ((-r $cert_file) && ( -r $key_file)) {
	do_log('err', 'Include remote list https://%s:%s/%s using cert %s, unable to open %s or %s', $host, $port, $path, $cert,$cert_file,$key_file);
	return undef;
    }
    
    my $getting_headers = 1;

    my %user ;
    my $email ;


    foreach my $line ( &Fetch::get_https($host,$port,$path,$cert_file,$key_file,{'key_passwd' => $Conf{'key_passwd'},
                                                                               'cafile'    => $Conf{'cafile'},
                                                                               'capath' => $Conf{'capath'}})
		){	
	chomp $line;

	if ($getting_headers) { # ignore http headers
	    next unless ($line =~ /^(date|update_date|email|reception|visibility)/);
	}
	undef $getting_headers;

	if ($line =~ /^\s*email\s+(.+)\s*$/o) {
	    $user{'email'} = $email = $1;
	    do_log('debug',"email found $email");
	    $get_total++;
	}
	$user{'gecos'} = $1 if ($line =~ /^\s*gecos\s+(.+)\s*$/o);
#	$user{'options'} = $1 if ($line =~ /^\s*options\s+(.+)\s*$/o);
#	$user{'auth'} = $1 if ($line =~ /^\s*auth\s+(\S+)\s*$/o);
#	$user{'password'} = $1 if ($line =~ /^\s*password\s+(.+)\s*$/o);
#	$user{'stats'} = "$1 $2 $3" if ($line =~ /^\s*stats\s+(\d+)\s+(\d+)\s+(\d+)\s*$/o);
#	$user{'firstbounce'} = $1 if ($line =~ /^\s*firstbounce\s+(\d+)\s*$/o);
	$user{'date'} = $1 if ($line =~ /^\s*date\s+(\d+)\s*$/o);
	$user{'update_date'} = $1 if ($line =~ /^\s*update_date\s+(\d+)\s*$/o);
	$user{'reception'} = $1 if ($line =~ /^\s*reception\s+(digest|nomail|summary|notice|txt|html|urlize|not_me)\s*$/o);
	$user{'visibility'} = $1 if ($line =~ /^\s*visibility\s+(conceal|noconceal)\s*$/o);
        
  	next unless ($line =~ /^$/) ;
	
	unless ($user{'email'}) {
	    do_log('debug','ignoring block without email definition');
	    next;
	}
	my %u;
	## Check if user has already been included
	if ($users->{$email}) {
	    do_log('debug4',"ignore $email because already member");
	    if ($tied) {
		%u = split "\n",$users->{$email};
	    }else {
		%u = %{$users->{$email}};
	    }
	}else{
	    do_log('debug4',"add new subscriber $email");
	    %u = %{$default_user_options};
	    $total++;
	}	    
	$u{'email'} = $user{'email'};
	$u{'id'} = join (',', split(',', $u{'id'}), $id);
	$u{'gecos'} = $user{'gecos'};delete $user{'gecos'};
 	$u{'date'} = $user{'date'};delete$user{'date'};
	$u{'update_date'} = $user{'update_date'};delete $user{'update_date'};
 	$u{'reception'} = $user{'reception'};delete $user{'reception'};
 	$u{'visibility'} = $user{'visibility'};delete $user{'visibility'};
	
	if ($default_user_options->{'mode_force'}) {
	    $u{'reception'} = $default_user_options->{'reception'} if (defined $default_user_options->{'reception'});
	    $u{'profile'} = $default_user_options->{'profile'} if (defined $default_user_options->{'profile'});
	    $u{'info'} = $default_user_options->{'info'} if (defined $default_user_options->{'info'});
	}

	if ($tied) {
	    $users->{$email} = join("\n", %u);
	}else{
	    $users->{$email} = \%u;
	}
	delete $user{$email};undef $email;

    }
    do_log('info','Include %d users from list (%d subscribers) https://%s:%s%s',$total,$get_total,$host,$port,$path);
    return $total ;    
}



## include a list as subscribers.
sub _include_users_list {
    my ($users, $includelistname, $robot, $default_user_options, $tied) = @_;
    do_log('debug2', 'List::_include_users_list');

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
    
    my $id = _get_datasource_id($includelistname);

    for (my $user = $includelist->get_first_user(); $user; $user = $includelist->get_next_user()) {
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
 	$u{'date'} = $user->{'date'};
	$u{'update_date'} = $user->{'update_date'};
 	$u{'reception'} = $user->{'reception'};
 	$u{'visibility'} = $user->{'visibility'};

	if ($default_user_options->{'mode_force'}) {
	    $u{'reception'} = $default_user_options->{'reception'} if (defined $default_user_options->{'reception'});
	    $u{'profile'} = $default_user_options->{'profile'} if (defined $default_user_options->{'profile'});
	    $u{'info'} = $default_user_options->{'info'} if (defined $default_user_options->{'info'});
	}

	if ($tied) {
	    $users->{$email} = join("\n", %u);
	}else {
	    $users->{$email} = \%u;
	}
    }
    do_log('info',"Include %d users from list %s",$total,$includelistname);
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
	    #my $admin = _load_admin_file($dir, $domain, 'config');
	}
    }
}
    
sub _include_users_file {
    my ($users, $filename, $default_user_options,$tied) = @_;
    do_log('debug2', 'List::_include_users_file(%s)', $filename);

    my $total = 0;
    
    unless (open(INCLUDE, "$filename")) {
	do_log('err', 'Unable to open file "%s"' , $filename);
	return undef;
    }
    do_log('debug2','including file %s' , $filename);

    my $id = _get_datasource_id($filename);
    
    while (<INCLUDE>) {
	next if /^\s*$/;
	next if /^\s*\#/;

	unless (/^\s*($tools::regexp{'email'})(\s*(\S.*))?\s*$/) {
	    &do_log('notice', 'Not an email address: %s', $_);
	}

	my $email = &tools::clean_email($1);
	my $gecos = $5;

	next unless $email;

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

	if ($default_user_options->{'mode_force'}) {
	    $u{'reception'} = $default_user_options->{'reception'} if (defined $default_user_options->{'reception'});
	    $u{'profile'} = $default_user_options->{'profile'} if (defined $default_user_options->{'profile'});
	    $u{'info'} = $default_user_options->{'info'} if (defined $default_user_options->{'info'});
	}

	if ($tied) {
	    $users->{$email} = join("\n", %u);
	}else {
	    $users->{$email} = \%u;
	}
    }
    close INCLUDE ;
    
    
    do_log('info',"include %d new users from file %s",$total,$filename);
    return $total ;
}
    
sub _include_users_remote_file {
    my ($users, $param, $default_user_options,$tied) = @_;

    my $url = $param->{'url'};
    
    do_log('debug', "List::_include_users_remote_file($url)");

    my $total = 0;
    my $id = _get_datasource_id($param);

    ## WebAgent package is part of Fetch.pm and inherites from LWP::UserAgent

    my $fetch = WebAgent->new (agent => 'Sympa/'.$Version::Version);

    my $req = HTTP::Request->new(GET => $url);
    
    if (defined $param->{'user'} && defined $param->{'passwd'}) {
	&WebAgent::set_basic_credentials($param->{'user'},$param->{'passwd'});
    }

    my $res = $fetch->request($req);  

    # check the outcome
    if ($res->is_success) {
	my @remote_file = split(/\n/,$res->content);

	# forgot headers (all line before one that contain a email
	foreach my $line (@remote_file) {
	    next if ($line =~ /^\s*$/);
	    next if ($line =~ /^\s*\#/);

	    unless ( $line =~ /^\s*($tools::regexp{'email'})(\s*(\S.*))?\s*$/) {
		&do_log('err', 'Not an email address: %s', $_);
	    }     
	    my $email = &tools::clean_email($1);
	    next unless $email;
	    my $gecos = $5;		

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
	    
	    if ($default_user_options->{'mode_force'}) {
		$u{'reception'} = $default_user_options->{'reception'} if (defined $default_user_options->{'reception'});
		$u{'profile'} = $default_user_options->{'profile'} if (defined $default_user_options->{'profile'});
		$u{'info'} = $default_user_options->{'info'} if (defined $default_user_options->{'info'});
	    }
	    
	    if ($tied) {
		$users->{$email} = join("\n", %u);
	    }else {
		$users->{$email} = \%u;
	    }
	}
    }
    else {
	do_log ('err',"List::include_users_remote_file: Unable to fetch remote file $url");
	return undef; 
    }

    ## Reset http credentials
    &WebAgent::set_basic_credentials('','');

    do_log('info',"include %d new subscribers from remote file %s",$total,$url);
    return $total ;
}


## Returns a list of subscribers extracted from a remote LDAP Directory
sub _include_users_ldap {
    my ($users, $param, $default_user_options, $tied) = @_;
    do_log('debug2', 'List::_include_users_ldap');
    
    unless (eval "require Net::LDAP") {
	do_log('err',"Unable to use LDAP library, install perl-ldap (CPAN) first");
	return undef;
    }
    require Net::LDAP;
    
    my $id = _get_datasource_id($param);

    my $host;
    @{$host} = split(/,/, $param->{'host'});
    my $port = $param->{'port'} || '389';
    my $user = $param->{'user'};
    my $passwd = $param->{'passwd'};
    my $ldap_suffix = $param->{'suffix'};
    my $ldap_filter = $param->{'filter'};
    my $ldap_attrs = $param->{'attrs'};
    my $ldap_select = $param->{'select'};
    
#    my $default_reception = $admin->{'default_user_options'}{'reception'};
#    my $default_visibility = $admin->{'default_user_options'}{'visibility'};

    ## LDAP and query handler
    my ($ldaph, $fetch);

    ## Connection timeout (default is 120)
    #my $timeout = 30; 
    
    unless ($ldaph = Net::LDAP->new($host, timeout => $param->{'timeout'}, async => 1)) {

	do_log('notice',"Can\'t connect to LDAP server '%s' : $@", join(',',@{$host}));
	return undef;
    }
    
    do_log('debug2', "Connected to LDAP server %s", join(',',@{$host}));
    my $status;
    
    if ( defined $user ) {
	$status = $ldaph->bind ($user, password => "$passwd");
	unless (defined($status) && ($status->code == 0)) {
	    do_log('notice',"Can\'t bind with server %s as user '$user' : $@", join(',',@{$host}));
	    return undef;
	}
    }else {
	$status = $ldaph->bind;
	unless (defined($status) && ($status->code == 0)) {
	    do_log('notice',"Can\'t do anonymous bind with server %s : $@", join(',',@{$host}));
	    return undef;
	}
    }

    do_log('debug2', "Binded to LDAP server %s ; user : '$user'", join(',',@{$host})) ;
    
    do_log('debug2', 'Searching on server %s ; suffix %s ; filter %s ; attrs: %s', join(',',@{$host}), $ldap_suffix, $ldap_filter, $ldap_attrs);
    $fetch = $ldaph->search ( base => "$ldap_suffix",
                                      filter => "$ldap_filter",
				      attrs => "$ldap_attrs",
				      scope => "$param->{'scope'}");
    unless ($fetch) {
        do_log('err',"Unable to perform LDAP search in $ldap_suffix for $ldap_filter : $@");
        return undef;
    }
    
    unless ($fetch->code == 0) {
	do_log('err','Ldap search failed : %s (searching on server %s ; suffix %s ; filter %s ; attrs: %s)', 
	       $fetch->error(), join(',',@{$host}), $ldap_suffix, $ldap_filter, $ldap_attrs);
        return undef;
    }
    
    ## Counters.
    my $total = 0;
    my $dn; 
    my @emails;

    while (my $e = $fetch->shift_entry) {

	my $entry = $e->get_value($ldap_attrs, asref => 1);
	
	## Multiple values
	if (ref($entry) eq 'ARRAY') {
	    foreach my $email (@{$entry}) {
		push @emails, &tools::clean_email($email);
		last if ($ldap_select eq 'first');
	    }
	}else {
	    push @emails, $entry;
	}
    }
    
    unless ($ldaph->unbind) {
	do_log('notice','Can\'t unbind from  LDAP server %s', join(',',@{$host}));
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

	if ($default_user_options->{'mode_force'}) {
	    $u{'reception'} = $default_user_options->{'reception'} if (defined $default_user_options->{'reception'});
	    $u{'profile'} = $default_user_options->{'profile'} if (defined $default_user_options->{'profile'});
	    $u{'info'} = $default_user_options->{'info'} if (defined $default_user_options->{'info'});
	}

	if ($tied) {
	    $users->{$email} = join("\n", %u);
	}else {
	    $users->{$email} = \%u;
	}
    }

    do_log('debug2',"unbinded from LDAP server %s ", join(',',@{$host}));
    do_log('debug2','%d new users included from LDAP query',$total);

    return $total;
}

## Returns a list of subscribers extracted indirectly from a remote LDAP
## Directory using a two-level query
sub _include_users_ldap_2level {
    my ($users, $param, $default_user_options,$tied) = @_;
    do_log('debug2', 'List::_include_users_ldap_2level');
    
    unless (eval "require Net::LDAP") {
	do_log('err',"Unable to use LDAP library, install perl-ldap (CPAN) first");
	return undef;
    }
    require Net::LDAP;

    my $id = _get_datasource_id($param);

    my $host;
    @{$host} = split(/,/, $param->{'host'});
    my $port = $param->{'port'} || '389';
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
    
#    my $default_reception = $admin->{'default_user_options'}{'reception'};
#    my $default_visibility = $admin->{'default_user_options'}{'visibility'};

    ## LDAP and query handler
    my ($ldaph, $fetch);

    ## Connection timeout (default is 120)
    #my $timeout = 30; 
    
    unless ($ldaph = Net::LDAP->new($host, timeout => $param->{'timeout'}, async => 1)) {
	do_log('notice',"Can\'t connect to LDAP server '%s' : $@",join(',',@{$host}) );
	return undef;
    }
    
    do_log('debug2', "Connected to LDAP server %s", join(',',@{$host}));
    my $status;
    
    if ( defined $user ) {
	$status = $ldaph->bind ($user, password => "$passwd");
	unless (defined($status) && ($status->code == 0)) {
	    do_log('err',"Can\'t bind with server %s as user '$user' : $@", join(',',@{$host}));
	    return undef;
	}
    }else {
	$status = $ldaph->bind;
	unless (defined($status) && ($status->code == 0)) {
	    do_log('err',"Can\'t do anonymous bind with server %s : $@", join(',',@{$host}));
	    return undef;
	}
    }

    do_log('debug2', "Binded to LDAP server %s ; user : '$user'", join(',',@{$host})) ;
    
    do_log('debug2', 'Searching on server %s ; suffix %s ; filter %s ; attrs: %s', join(',',@{$host}), $ldap_suffix1, $ldap_filter1, $ldap_attrs1) ;
    unless ($fetch = $ldaph->search ( base => "$ldap_suffix1",
                                      filter => "$ldap_filter1",
				      attrs => "$ldap_attrs1",
				      scope => "$ldap_scope1")) {
        do_log('err',"Unable to perform LDAP search in $ldap_suffix1 for $ldap_filter1 : $@");
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

    my ($suffix2, $filter2);
    foreach my $attr (@attrs) {
	($suffix2 = $ldap_suffix2) =~ s/\[attrs1\]/$attr/g;
	($filter2 = $ldap_filter2) =~ s/\[attrs1\]/$attr/g;

	do_log('debug2', 'Searching on server %s ; suffix %s ; filter %s ; attrs: %s', join(',',@{$host}), $suffix2, $filter2, $ldap_attrs2);
	unless ($fetch = $ldaph->search ( base => "$suffix2",
					filter => "$filter2",
					attrs => "$ldap_attrs2",
					scope => "$ldap_scope2")) {
	    do_log('err',"Unable to perform LDAP search in $suffix2 for $filter2 : $@");
	    return undef;
	}

	## returns a reference to a HASH where the keys are the DNs
	##  the second level hash's hold the attributes

	while (my $e = $fetch->shift_entry) {
	    my $entry = $e->get_value($ldap_attrs2, asref => 1);

	    ## Multiple values
	    if (ref($entry) eq 'ARRAY') {
		foreach my $email (@{$entry}) {
		    next if (($ldap_select2 eq 'regex') && ($email !~ /$ldap_regex2/));
		    push @emails, &tools::clean_email($email);
		    last if ($ldap_select2 eq 'first');
		}
	    }else {
		push @emails, $entry
		    unless (($ldap_select2 eq 'regex') && ($entry !~ /$ldap_regex2/));
	    }
	}
    }
    
    unless ($ldaph->unbind) {
	do_log('err','Can\'t unbind from  LDAP server %s',join(',',@{$host}));
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

	if ($default_user_options->{'mode_force'}) {
	    $u{'reception'} = $default_user_options->{'reception'} if (defined $default_user_options->{'reception'});
	    $u{'profile'} = $default_user_options->{'profile'} if (defined $default_user_options->{'profile'});
	    $u{'info'} = $default_user_options->{'info'} if (defined $default_user_options->{'info'});
	}

	if ($tied) {
	    $users->{$email} = join("\n", %u);
	}else {
	    $users->{$email} = \%u;
	}
    }

    do_log('debug2',"unbinded from LDAP server %s ",join(',',@{$host})) ;
    do_log('debug2','%d new users included from LDAP query',$total);

    return $total;
}

## Returns a list of subscribers extracted from an remote Database
sub _include_users_sql {
    my ($users, $param, $default_user_options, $tied) = @_;

    &do_log('debug2','List::_include_users_sql()');

    unless ( eval "require DBI" ){
	do_log('err',"Intall module DBI (CPAN) before using include_sql_query");
	return undef ;
    }
    require DBI;

    my $id = _get_datasource_id($param);

    my $db_type = $param->{'db_type'};
    my $db_name = $param->{'db_name'};
    my $host = $param->{'host'};
    my $port = $param->{'db_port'};
    my $user = $param->{'user'};
    my $passwd = $param->{'passwd'};
    my $sql_query = $param->{'sql_query'};

    ## For CSV (Comma Separated Values) 
    my $f_dir = $param->{'f_dir'}; 

    my ($dbh, $sth);
    my $connect_string;

    if ($f_dir) {
	$connect_string = "DBI:CSV:f_dir=$f_dir";
    }elsif ($db_type eq 'Oracle') {
	$connect_string = "DBI:Oracle:";
	if ($host && $db_name) {
	    $connect_string .= "host=$host;sid=$db_name";
	}
	if (defined $port) {
	    $connect_string .= ';port=' . $port;
	}
    }elsif ($db_type eq 'Pg') {
	$connect_string = "DBI:Pg:dbname=$db_name;host=$host";
    }elsif ($db_type eq 'Sybase') {
	$connect_string = "DBI:Sybase:database=$db_name;server=$host";
    }elsif ($db_type eq 'SQLite') {
	$connect_string = "DBI:SQLite:dbname=$db_name";
    }else {
	$connect_string = "DBI:$db_type:$db_name:$host";
    }

    if ($param->{'connect_options'}) {
	$connect_string .= ';' . $param->{'connect_options'};
    }
    if (defined $port) {
	$connect_string .= ';port=' . $port;
    }
 
    ## Set environment variables
    ## Used by Oracle (ORACLE_HOME)
    if ($param->{'db_env'}) {
	foreach my $env (split /;/,$param->{'db_env'}) {
	    my ($key, $value) = split /=/, $env;
	    $ENV{$key} = $value if ($key);
	}
    }

    unless ($dbh = DBI->connect($connect_string, $user, $passwd)) {
	do_log('err','Can\'t connect to Database %s',$db_name);
	return undef;
    }
    do_log('debug2','Connected to Database %s',$db_name);
    
    unless ($sth = $dbh->prepare($sql_query)) {
        do_log('err','Unable to prepare SQL query : %s', $dbh->errstr);
        return undef;
    }
    unless ($sth->execute) {
        do_log('err','Unable to perform SQL query %s : %s ',$sql_query, $dbh->errstr);
        return undef;
    }
    
    ## Counters.
    my $total = 0;
    
    ## Process the SQL results
    my $email;
    my $rows = $sth->rows;
    foreach (1..$rows) { ## This way we don't stop at the first NULL entry found
	$email = $sth->fetchrow;
	## Empty value
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

	if ($default_user_options->{'mode_force'}) {
	    $u{'reception'} = $default_user_options->{'reception'} if (defined $default_user_options->{'reception'});
	    $u{'profile'} = $default_user_options->{'profile'} if (defined $default_user_options->{'profile'});
	    $u{'info'} = $default_user_options->{'info'} if (defined $default_user_options->{'info'});
	}

	if ($tied) {
	    $users->{$email} = join("\n", %u);
	}else {
	    $users->{$email} = \%u;
	}
    }
    $sth->finish ;
    $dbh->disconnect();

    do_log('debug2','%d included users from SQL query', $total);
    return $total;
}

## Loads the list of subscribers from an external include source
sub _load_users_include {
    my $self = shift;
    my $db_file = shift;
    my $use_cache = shift;
    my $name = $self->{'name'}; 
    my $admin = $self->{'admin'};
    my $dir = $self->{'dir'};
    do_log('debug2', 'List::_load_users_include for list %s ; use_cache: %d',$name, $use_cache);

    my (%users, $depend_on, $ref);
    my $total = 0;

    ## Create in memory btree using DB_File.
    my $btree = new DB_File::BTREEINFO;
    return undef unless ($btree);
    $btree->{'compare'} = \&_compare_addresses;

    if (!$use_cache && (-f $db_file)) {
        rename $db_file, $db_file.'old';
    }

    unless ($use_cache) {
	unless ($ref = tie %users, 'DB_File', $db_file, O_CREAT|O_RDWR, 0600, $btree) {
	    &do_log('err', '(no cache) Could not tie to DB_File %s',$db_file);
	    return undef;
	}

	## Lock DB_File
	my $fd = $ref->fd;

	unless (open DB_FH, "+<&$fd") {
	    &do_log('err', 'Cannot open %s: %s', $db_file, $!);
	    return undef;
	}
	unless (flock (DB_FH, LOCK_EX | LOCK_NB)) {
	    &do_log('notice','Waiting for writing lock on %s', $db_file);
	    unless (flock (DB_FH, LOCK_EX)) {
		&do_log('err', 'Failed locking %s: %s', $db_file, $!);
		return undef;
	    }
	}
	&do_log('debug3', 'Got lock for writing on %s', $db_file);

	foreach my $type ('include_list','include_remote_sympa_list','include_file','include_ldap_query','include_ldap_2level_query','include_sql_query','include_remote_file') {
	    last unless (defined $total);
	    
	    foreach my $incl (@{$admin->{$type}}) {
		my $included;
		
		## get the list of users
		if ($type eq 'include_sql_query') {
		    $included = _include_users_sql(\%users, $incl, $admin->{'default_user_options'}, 'tied');
		}elsif ($type eq 'include_ldap_query') {
		    $included = _include_users_ldap(\%users, $incl, $admin->{'default_user_options'}, 'tied');
		}elsif ($type eq 'include_ldap_2level_query') {
		    $included = _include_users_ldap_2level(\%users, $incl, $admin->{'default_user_options'}, 'tied');
		}elsif ($type eq 'include_list') {
		    $depend_on->{$name} = 1 ;
		    if (&_inclusion_loop ($name,$incl,$depend_on)) {
			do_log('err','loop detection in list inclusion : could not include again %s in %s',$incl,$name);
		    }else{
			$depend_on->{$incl};
			$included = _include_users_list (\%users, $incl, $self->{'domain'}, $admin->{'default_user_options'}, 'tied');

		    }
		}elsif ($type eq 'include_remote_sympa_list') {
		    $included = $self->_include_users_remote_sympa_list(\%users, $incl, $dir,$admin->{'domain'},$admin->{'default_user_options'}, 'tied');
		}elsif ($type eq 'include_file') {
		    $included = _include_users_file (\%users, $incl, $admin->{'default_user_options'}, 'tied');
		}elsif ($type eq 'include_remote_file') {
		    $included = _include_users_remote_file (\%users, $incl, $admin->{'default_user_options'}, 'tied');
		}
		unless (defined $included) {
		    &do_log('err', 'Inclusion %s failed in list %s', $type, $name);
		    $total = undef;
		    last;
		}
		
		$total += $included;
	    }
	}
  
	## Unlock
	$ref->sync;
	flock(DB_FH,LOCK_UN);
	&do_log('debug3', 'Release lock on %s', $db_file);
	undef $ref;
	untie %users;
	close DB_FH;
	
	unless (defined $total) {
	    if (-f $db_file.'old') {
	        unlink $db_file;
		rename $db_file.'old', $db_file;
		$total = 0;
	    }
	}
    }

    unless ($ref = tie %users, 'DB_File', $db_file, O_CREAT|O_RDWR, 0600, $btree) {
	&do_log('err', '(use cache) Could not tie to DB_File %s',$db_file);
	return undef;
    }

    ## Lock DB_File
    my $fd = $ref->fd;
    unless (open DB_FH, "+<&$fd") {
	&do_log('err', 'Cannot open %s: %s', $db_file, $!);
	return undef;
    }
    unless (flock (DB_FH, LOCK_SH | LOCK_NB)) {
	&do_log('notice','Waiting for reading lock on %s', $db_file);
	unless (flock (DB_FH, LOCK_SH)) {
	    &do_log('err', 'Failed locking %s: %s', $db_file, $!);
	    return undef;
	}
    }
    &do_log('debug3', 'Got lock for reading on %s', $db_file);

    ## Unlock DB_file
    flock(DB_FH,LOCK_UN);
    &do_log('debug3', 'Release lock on %s', $db_file);
    
    ## Inclusion failed, clear cache
    unless (defined $total) {
	undef $ref;
	#untie %users;
	close DB_FH;
	unlink $db_file;
	return undef;
    }

    my $l = {	 'ref'    => $ref,
		 'users'  => \%users
	     };
    $l->{'total'} = $total
	if $total;

    undef $ref;
    #untie %users;
    close DB_FH;
    $l;
}

## Loads the list of subscribers from an external include source
sub _load_users_include2 {
    my $self = shift;
    my $name = $self->{'name'}; 
    my $admin = $self->{'admin'};
    my $dir = $self->{'dir'};
    do_log('debug2', 'List::_load_users_include for list %s',$name);

    my (%users, $depend_on, $ref, $error);
    my $total = 0;

    foreach my $type ('include_list','include_remote_sympa_list','include_file','include_ldap_query','include_ldap_2level_query','include_sql_query','include_remote_file') {
	last unless (defined $total);
	    
	foreach my $incl (@{$admin->{$type}}) {
	    my $included;

	    ## get the list of users
	    if ($type eq 'include_sql_query') {
		$included = _include_users_sql(\%users, $incl, $admin->{'default_user_options'});
	    }elsif ($type eq 'include_ldap_query') {
		$included = _include_users_ldap(\%users, $incl, $admin->{'default_user_options'});
	    }elsif ($type eq 'include_ldap_2level_query') {
		$included = _include_users_ldap_2level(\%users, $incl, $admin->{'default_user_options'});
	    }elsif ($type eq 'include_remote_sympa_list') {
		$included = $self->_include_users_remote_sympa_list(\%users, $incl, $dir,$admin->{'domain'},$admin->{'default_user_options'});
	    }elsif ($type eq 'include_list') {
		$depend_on->{$name} = 1 ;
		if (&_inclusion_loop ($name,$incl,$depend_on)) {
		    do_log('err','loop detection in list inclusion : could not include again %s in %s',$incl,$name);
		}else{
		    $depend_on->{$incl};
		    $included = _include_users_list (\%users, $incl, $self->{'domain'}, $admin->{'default_user_options'});
		}
	    }elsif ($type eq 'include_file') {
		$included = _include_users_file (\%users, $incl, $admin->{'default_user_options'});
#	    }elsif ($type eq 'include_admin') {
#		$included = _include_users_admin (\\%users, $incl, $admin->{'default_user_options'});
#	    }
	    }elsif ($type eq 'include_remote_file') {
		$included = _include_users_remote_file (\%users, $incl, $admin->{'default_user_options'});
	    }
	    unless (defined $included) {
		&do_log('err', 'Inclusion %s failed in list %s', $type, $name);
		$error = 1;
		next;
	    }
	    
	    $total += $included;
	}
    }

    ## If an error occured, return an undef value
    if ($error) {
	return undef;
    }
    return \%users;
}

## Loads the list of admin users from an external include source
sub _load_admin_users_include {
    my $self = shift;
    my $role = shift;
    my $name = $self->{'name'};
   
    &do_log('debug2', 'List::_load_admin_users_include(%s) for list %s',$role, $name); 

    my (%admin_users, $depend_on, $ref);
    my $total = 0;
    my $list_admin = $self->{'admin'};
    my $dir = $self->{'dir'};

    unless($self->{'admin'}{'user_data_source'} eq 'include2'){
	&do_log('err', '_load_admin_users_include isn\'t defined when user_data_source is different than include2 for list %s',
	 $self->{'name'}); 
	return undef;
    }

    foreach my $entry (@{$list_admin->{$role."_include"}}) {
    
	next unless (defined $entry); 

	my %option;
	$option{'mode_force'} = 1; # to force option values in _include_..._query
	$option{'reception'} = $entry->{'reception'} if (defined $entry->{'reception'});
	$option{'profile'} = $entry->{'profile'} if (defined $entry->{'profile'} && ($role eq 'owner'));
	

      	my $include_file = &tools::get_filename('etc',"data_sources/$entry->{'source'}\.incl",$self->{'domain'},$self);

        unless (defined $include_file){
	    &do_log('err', '_load_admin_users_include : the file %s.incl doesn\'t exist',$entry->{'source'});
	    return undef;
	}

	my $include_admin_user;
	## the file has parameters
	if (defined $entry->{'source_parameters'}) {
	    my %parsing;
	    
	    $parsing{'data'} = $entry->{'source_parameters'};
	    $parsing{'template'} = "$entry->{'source'}\.incl";
	    
	    my $name = "$entry->{'source'}\.incl";
	    
	    if ($include_file =~ s/$name$//) {
		$parsing{'include_path'} = $include_file;
		$include_admin_user = &_load_include_admin_user_file($self->{'domain'},$include_file,\%parsing);	
	    } else {
		&do_log('err', '_load_admin_users_include : errors to get path of the the file %s.incl',$entry->{'source'});
		return undef;
	    }
	    
	    
	} else {
	    $include_admin_user = &_load_include_admin_user_file($self->{'domain'},$include_file);
	}
	foreach my $type ('include_list','include_remote_sympa_list','include_file','include_ldap_query','include_ldap_2level_query','include_sql_query') {
	    last unless (defined $total);
	    
	    foreach my $incl (@{$include_admin_user->{$type}}) {
		my $included;
		
		## get the list of admin users
		## does it need to define a 'default_admin_user_option' ?
		if ($type eq 'include_sql_query') {
		    $included = _include_users_sql(\%admin_users, $incl,\%option); 
		}elsif ($type eq 'include_ldap_query') {
		    $included = _include_users_ldap(\%admin_users, $incl,\%option); 
		}elsif ($type eq 'include_ldap_2level_query') {
		    $included = _include_users_ldap_2level(\%admin_users, $incl,\%option); 
		}elsif ($type eq 'include_remote_sympa_list') {
		    $included = $self->_include_users_remote_sympa_list(\%admin_users, $incl, $dir,$list_admin->{'domain'},\%option);
		}elsif ($type eq 'include_list') {
		    $depend_on->{$name} = 1 ;
		    if (&_inclusion_loop ($name,$incl,$depend_on)) {
			do_log('err','loop detection in list inclusion : could not include again %s in %s',$incl,$name);
		    }else{
			$depend_on->{$incl};
			$included = _include_users_list (\%admin_users, $incl, $self->{'domain'}, \%option);
		    }
		}elsif ($type eq 'include_file') {
		    $included = _include_users_file (\%admin_users, $incl, \%option);
		}
		unless (defined $included) {
		    &do_log('err', 'Inclusion %s %s failed in list %s', $role, $type, $name);
		    $total = undef;
		    last;
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
    &do_log('debug2', 'List::_load_include_admin_user_file(%s,%s)',$robot, $file); 
    
    my %include;
    my (@paragraphs);
    
    # the file has parmeters
    if (defined $parsing) {
	my @data = split(',',$parsing->{'data'});
        my $vars = {'param' => \@data};
	my $output = '';
	
	unless (&tt2::parse_tt2($vars,$parsing->{'template'},\$output,[$parsing->{'include_path'}])) {
	    &do_log('err', 'Failed to parse %s', $parsing->{'template'});
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
	    &do_log('info', 'Cannot open %s', $file);
	}
	
	## Just in case...
	$/ = "\n";
	
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
	    &do_log('info', 'Bad paragraph "%s" in %s', @paragraph, $file);
	    next;
	}
	
	$pname = $1;   
	
	unless(($pname eq 'include_list')||($pname eq 'include_remote_sympa_list')||($pname eq 'include_file')||
	       ($pname eq 'include_ldap_query')||($pname eq 'include_ldap_2level_query')||($pname eq 'include_sql_query'))   {
	    &do_log('info', 'Unknown parameter "%s" in %s', $pname, $file);
	    next;
	}
	
	## Uniqueness
	if (defined $include{$pname}) {
	    unless (($::pinfo{$pname}{'occurrence'} eq '0-n') or
		    ($::pinfo{$pname}{'occurrence'} eq '1-n')) {
		&do_log('info', 'Multiple parameter "%s" in %s', $pname, $file);
	    }
	}
	
	## Line or Paragraph
	if (ref $::pinfo{$pname}{'file_format'} eq 'HASH') {
	    ## This should be a paragraph
	    unless ($#paragraph > 0) {
		&do_log('info', 'Expecting a paragraph for "%s" parameter in %s, ignore it', $pname, $file);
		next;
	    }
	    
	    ## Skipping first line
	    shift @paragraph;
	    
	    my %hash;
	    for my $i (0..$#paragraph) {	    
		next if ($paragraph[$i] =~ /^\s*\#/);
		
		unless ($paragraph[$i] =~ /^\s*(\w+)\s*/) {
		    &do_log('info', 'Bad line "%s" in %s',$paragraph[$i], $file);
		}
		
		my $key = $1;
		
		unless (defined $::pinfo{$pname}{'file_format'}{$key}) {
		    &do_log('info', 'Unknown key "%s" in paragraph "%s" in %s', $key, $pname, $file);
		    next;
		}
		
		unless ($paragraph[$i] =~ /^\s*$key\s+($::pinfo{$pname}{'file_format'}{$key}{'file_format'})\s*$/i) {
		    &do_log('info', 'Bad entry "%s" in paragraph "%s" in %s', $paragraph[$i], $key, $pname, $file);
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
			&do_log('info', 'Missing key "%s" in param "%s" in %s', $k, $pname, $file);
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
		&do_log('info', 'Expecting a single line for "%s" parameter in %s', $pname, $file);
	    }

	    unless ($paragraph[0] =~ /^\s*$pname\s+($::pinfo{$pname}{'file_format'})\s*$/i) {
		&do_log('info', 'Bad entry "%s" in %s', $paragraph[0], $file);
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
    &do_log('debug', 'List:sync_include(%s)', $name);

    my %old_subscribers;
    my $total=0;

    ## Load a hash with the old subscribers
    for (my $user=$self->get_first_user(); $user; $user=$self->get_next_user()) {
	$old_subscribers{lc($user->{'email'})} = $user;
	
	## User neither included nor subscribed = > set subscribed to 1 
	unless ($old_subscribers{lc($user->{'email'})}{'included'} || $old_subscribers{lc($user->{'email'})}{'subscribed'}) {
	    &do_log('notice','Update user %s neither included nor subscribed', $user->{'email'});
	    unless( $self->update_user(lc($user->{'email'}),  {'update_date' => time,
							       'subscribed' => 1 }) ) {
		&do_log('err', 'List:sync_include(%s): Failed to update %s', $name, lc($user->{'email'}));
		next;
	    }			    
	    $old_subscribers{lc($user->{'email'})}{'subscribed'} = 1;
	}

	$total++;
    }

    ## Load a hash with the new subscriber list
    my $new_subscribers;
    unless ($option eq 'purge') {
	$new_subscribers = $self->_load_users_include2();

	## If include sources were not available, do not update subscribers
	## Use DB cache instead
	unless (defined $new_subscribers) {
	    &do_log('err', 'Could not include subscribers for list %s', $name);
	    unless (&List::send_notify_to_listmaster('sync_include_failed', $self->{'domain'}, [$name])) {
		&do_log('notice',"Unable to send notify 'sync_include_failed' to listmaster");
	    }
	    return undef;
	}
    }

    my $users_added = 0;
    my $users_updated = 0;

    ## Get an Exclusive lock
    my $lock_file = $self->{'dir'}.'/include.lock';
    unless ($list_of_fh{$lock_file} = &tools::lock($lock_file,'write')) {
	return undef;
    }

    ## Go through new users
    my @add_tab;
    foreach my $email (keys %{$new_subscribers}) {
	if (defined($old_subscribers{$email}) ) {	   
	    if ($old_subscribers{$email}{'included'}) {

		## Include sources have changed for the user
		if ($old_subscribers{$email}{'id'} ne $new_subscribers->{$email}{'id'}) {
		    &do_log('debug', 'List:sync_include: updating %s to list %s', $email, $name);
		    unless( $self->update_user($email,  {'update_date' => time,
							 'id' => $new_subscribers->{$email}{'id'} }) ) {
			&do_log('err', 'List:sync_include(%s): Failed to update %s', $name, $email);
			next;
		    }
		    $users_updated++;
		}

		## Gecos have changed for the user
		if ($old_subscribers{$email}{'gecos'} ne $new_subscribers->{$email}{'gecos'}) {
		    &do_log('debug', 'List:sync_include: updating %s to list %s', $email, $name);
		    unless( $self->update_user($email,  {'update_date' => time,
							 'gecos' => $new_subscribers->{$email}{'gecos'} }) ) {
			&do_log('err', 'List:sync_include(%s): Failed to update %s', $name, $email);
			next;
		    }
		    $users_updated++;
		}

		## User was already subscribed, update include_sources_subscriber in DB
	    }else {
		&do_log('debug', 'List:sync_include: updating %s to list %s', $email, $name);
		unless( $self->update_user($email,  {'update_date' => time,
						     'included' => 1,
						     'id' => $new_subscribers->{$email}{'id'} }) ) {
		    &do_log('err', 'List:sync_include(%s): Failed to update %s',
			    $name, $email);
		    next;
		}
		$users_updated++;
	    }

	    ## Add new included user
	}else {
	    &do_log('debug3', 'List:sync_include: adding %s to list %s', $email, $name);
	    my $u = $new_subscribers->{$email};
	    $u->{'included'} = 1;
	    push @add_tab, $u;
	}
    }

    if ($#add_tab >= 0) {
	unless( $users_added = $self->add_user( @add_tab ) ) {
	    &do_log('err', 'List:sync_include(%s): Failed to add new users', $name);
	    return undef;
	}
    }

    if ($users_added) {
        &do_log('notice', 'List:sync_include(%s): %d users added',
		$name, $users_added);
    }

    ## Go though previous list of users
    my $users_removed = 0;
    my @deltab;
    foreach my $email (keys %old_subscribers) {
	unless( defined($new_subscribers->{$email}) ) {
	    ## User is also subscribed, update DB entry
	    if ($old_subscribers{$email}{'subscribed'}) {
		&do_log('debug', 'List:sync_include: updating %s to list %s', $email, $name);
		unless( $self->update_user($email,  {'update_date' => time,
						     'included' => 0,
						     'id' => ''}) ) {
		    &do_log('err', 'List:sync_include(%s): Failed to update %s',  $name, $email);
		    next;
		}
		
		$users_updated++;

		## Tag user for deletion
	    }else {
		push(@deltab, $email);
	    }
	}
    }
    if ($#deltab >= 0) {
	unless($users_removed = $self->delete_user(@deltab)) {
	    &do_log('err', 'List:sync_include(%s): Failed to delete %s',
		    $name, $users_removed);
	    return undef;
        }
        &do_log('notice', 'List:sync_include(%s): %d users removed',
		$name, $users_removed);
    }
    &do_log('notice', 'List:sync_include(%s): %d users updated', $name, $users_updated);

    ## Release lock
    unless (&tools::unlock($lock_file, $list_of_fh{$lock_file})) {
	return undef;
    }
    delete $list_of_fh{$lock_file};

    ## Get and save total of subscribers
    $self->{'total'} = $self->_load_total_db('nocache');
    $self->{'last_sync'} = time;
    $self->savestats();

    return 1;
}



sub sync_include_admin {
    my ($self) = shift;
    my $option = shift;
    
    my $name=$self->{'name'};
    &do_log('debug2', 'List:sync_include_admin(%s)', $name);

    unless($self->{'admin'}{'user_data_source'} eq 'include2'){
	&do_log('debug', 'sync_include_admin failed ; user_data_source for list %s is set to %s', $self->{'name'}, $self->{'admin'}{'user_data_source'}); 
	return 0;
    }

    ## don't care about listmaster role
    foreach my $role ('owner','editor'){
	my $old_admin_users = {};
        ## Load a hash with the old admin users
	for (my $admin_user=$self->get_first_admin_user($role); $admin_user; $admin_user=$self->get_next_admin_user()) {
	    $old_admin_users->{lc($admin_user->{'email'})} = $admin_user;
	}
	
	## Load a hash with the new admin user list from an include source(s)
	my $new_admin_users_include;
	## Load a hash with the new admin user users from the list config
	my $new_admin_users_config;
	unless ($option eq 'purge') {
	    
	    $new_admin_users_include = $self->_load_admin_users_include($role);
	    
	    ## If include sources were not available, do not update admin users
	    ## Use DB cache instead
	    unless (defined $new_admin_users_include) {
		&do_log('err', 'Could not get %ss from an include source for list %s', $role, $name);
		unless (&List::send_notify_to_listmaster('sync_include_admin_failed', $self->{'domain'}, [$name])) {
		    &do_log('notice',"Unable to send notify 'sync_include_admmin_failed' to listmaster");
		}
		return undef;
	    }

	    $new_admin_users_config = $self->_load_admin_users_config($role);
	    
	    unless (defined $new_admin_users_config) {
		&do_log('err', 'Could not get %ss from config for list %s', $role, $name);
		return undef;
	    }
	}
	
	my @add_tab;
	my $admin_users_added = 0;
	my $admin_users_updated = 0;
	
	## Get an Exclusive lock
	
	my $lock_file = $self->{'dir'}.'/include_admin_user.lock';
	unless (open FH, ">>$lock_file") {
	    &do_log('err', 'Cannot open %s: %s', $lock_file, $!);
	    return undef;
	}
	unless ($list_of_fh{$lock_file} = &tools::lock($lock_file,'write')) {
		return undef;
	    }
	
	## Go through new admin_users_include
	foreach my $email (keys %{$new_admin_users_include}) {
	    
	    # included and subscribed
	    if (defined $new_admin_users_config->{$email}) {
		my $param;
		foreach my $p ('reception','gecos','info','profile') {
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
			    &do_log('debug', 'List:sync_include_admin : updating %s %s to list %s',$role, $email, $name);
			    $param_update->{'update_date'} = time;
			    
			    unless ($self->update_admin_user($email, $role,$param_update)) {
				&do_log('err', 'List:sync_include_admin(%s): Failed to update %s %s', $name,$role,$email);
				next;
			    }
			    $admin_users_updated++;
			}
		    }
		    #for the next foreach (sort of new_admin_users_config that are not included)
		    delete ($new_admin_users_config->{$email});
		    
		# add a new included and subscribed admin user 
		}else {
		    &do_log('debug2 ', 'List:sync_include_admin: adding %s %s to list %s',$email,$role, $name);
		    
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
			    &do_log('debug', 'List:sync_include_admin : updating %s %s to list %s', $role, $email, $name);
			    $param_update->{'update_date'} = time;
			    
			    unless ($self->update_admin_user($email, $role,$param_update)) {
				&do_log('err', 'List:sync_include_admin(%s): Failed to update %s %s', $name, $role,$email);
				next;
			    }
			    $admin_users_updated++;
			}
		    }
		# add a new included admin user 
		}else {
		    &do_log('debug2 ', 'List:sync_include_admin: adding %s %s to list %s', $role, $email, $name);
		    
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
			&do_log('debug', 'List:sync_include_admin : updating %s %s to list %s', $role, $email, $name);
			$param_update->{'update_date'} = time;
			
			unless ($self->update_admin_user($email, $role,$param_update)) {
			    &do_log('err', 'List:sync_include_admin(%s): Failed to update %s %s', $name, $role, $email);
			    next;
			}
			$admin_users_updated++;
		    }
		}
	    # add a new subscribed admin user 
	    }else {
		&do_log('debug2 ', 'List:sync_include_admin: adding %s %s to list %s', $role, $email, $name);
		
		foreach my $key (keys %{$param}) {  
		    $new_admin_users_config->{$email}{$key} = $param->{$key};
		}
		$new_admin_users_config->{$email}{'subscribed'} = 1;
		push (@add_tab,$new_admin_users_config->{$email});
	    }
	}
	
	if ($#add_tab >= 0) {
	    unless( $admin_users_added = $self->add_admin_user($role,@add_tab ) ) {
		&do_log('err', 'List:sync_include_admin(%s): Failed to add new %ss',  $role, $name);
		return undef;
	    }
	}
	
	if ($admin_users_added) {
	    &do_log('debug', 'List:sync_include_admin(%s): %d %s(s) added',
		    $name, $admin_users_added, $role);
	}
	
	&do_log('debug', 'List:sync_include_admin(%s): %d %s(s) updated', $name, $admin_users_updated, $role);

	## Go though old list of admin users
	my $admin_users_removed = 0;
	my @deltab;
	
	foreach my $email (keys %$old_admin_users) {
	    unless (defined($new_admin_users_include->{$email}) || defined($new_admin_users_config->{$email})) {
		&do_log('debug2 ', 'List:sync_include_admin: removing %s %s to list %s', $role, $email, $name);
		push(@deltab, $email);
	    }
	}
	
	if ($#deltab >= 0) {
	    unless($admin_users_removed = $self->delete_admin_user($role,@deltab)) {
		&do_log('err', 'List:sync_include_admin(%s): Failed to delete %s %s',
			$name, $role, $admin_users_removed);
		return undef;
	    }
	    &do_log('debug', 'List:sync_include_admin(%s): %d %s(s) removed',
		    $name, $admin_users_removed, $role);
	}

	## Release lock
	unless (&tools::unlock($lock_file, $list_of_fh{$lock_file})) {
	    return undef;
	}
	delete $list_of_fh{$lock_file};
    }	
   
    $self->{'last_sync_admin_user'} = time;
    $self->savestats();
 
    return $self->get_nb_owners;
}

## Load param admin users from the config of the list
sub _load_admin_users_config {
    my $self = shift;
    my $role = shift; 
    my $name = $self->{'name'};
    my %admin_users;

    &do_log('debug2', 'List::_load_admin_users_config(%s) for list %s',$role, $name);  

    foreach my $entry (@{$self->{'admin'}{$role}}) {
	my $email = lc($entry->{'email'});
	my %u;
  
	$u{'email'} = $email;
	$u{'reception'} = $entry->{'reception'};
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

    &do_log('debug2', 'List::is_update_param ');  

    foreach my $p ('reception','gecos','info','profile','id','included','subscribed') {
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
    # do_log('debug2', 'xxxxxxxxxxx _inclusion_loop(%s,%s)',$name,$incl);
    # do_log('debug2', 'xxxxxxxxxxx DEPENDANCE :');
    # foreach my $dpe (keys  %{$depend_on}) {
    #   do_log('debug2', "xxxxxxxxxxx ----$dpe----");
    # }

    return 1 if ($depend_on->{$incl}) ; 
    
    # do_log('notice', 'xxxxxxxx pas de PB pour inclure %s dans %s %s',$incl, $name);
    return undef;
}

sub _load_total_db {
    my $self = shift;
    my $option = shift;
    do_log('debug2', 'List::_load_total_db(%s)', $self->{'name'});

    unless ($List::use_db) {
	&do_log('info', 'Sympa not setup to use DBI');
	return undef;
    }
    
    ## Use session cache
    if (($option ne 'nocache') && (defined $list_cache{'load_total_db'}{$self->{'domain'}}{$self->{'name'}})) {
#	&do_log('debug3', 'xxx Use cache(load_total_db, %s)', $self->{'name'});
	return $list_cache{'load_total_db'}{$self->{'domain'}}{$self->{'name'}};
    }

    my ($statement);

    ## Check database connection
    unless ($dbh and $dbh->ping) {
	return undef unless &db_connect();
    }	   

    ## Query the Database
    $statement = sprintf "SELECT count(*) FROM subscriber_table WHERE (list_subscriber = %s AND robot_subscriber = %s)", $dbh->quote($self->{'name'}), $dbh->quote($self->{'domain'});
       
    push @sth_stack, $sth;

    unless ($sth = $dbh->prepare($statement)) {
	do_log('debug','Unable to prepare SQL statement : %s', $dbh->errstr);
	return undef;
    }
    
    unless ($sth->execute) {
	do_log('debug','Unable to execute SQL statement "%s" : %s', $statement, $dbh->errstr);
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
	&do_log('err', 'List_save_stats_file() : incorrect parameter');
	return undef;
    }

    do_log('debug2', 'List::_save_stats_file(%s, %d, %d, %d)', $file, $total,$last_sync,$last_sync_admin_user );
    
    open(L, "> $file") || return undef;
    printf L "%d %.0f %.0f %.0f %d %d %d\n", @{$stats}, $total, $last_sync, $last_sync_admin_user;
    close(L);
}

## Writes the user list to disk
sub _save_users_file {
    my($self, $file) = @_;
    do_log('debug3', 'List::_save_users_file(%s)', $file);
    
    my($k, $s);
    
    do_log('debug2','Saving user file %s', $file);
    
    rename("$file", "$file.old");
    open SUB, "> $file" or return undef;
    
    for ($s = $self->get_first_user(); $s; $s = $self->get_next_user()) {
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
    do_log('debug3', 'List::store_digest');

    my($filename, $newfile);
    my $separator = $tools::separator;  

    unless ( -d "$Conf{'queuedigest'}") {
	return;
    }
    
    my @now  = localtime(time);

    ## Reverse compatibility concern
    if (-f "$Conf{'queuedigest'}/$self->{'name'}") {
  	$filename = "$Conf{'queuedigest'}/$self->{'name'}";
    }else {
 	$filename = $Conf{'queuedigest'}.'/'.$self->get_list_id();
    }

    $newfile = !(-e $filename);
    my $oldtime=(stat $filename)[9] unless($newfile);
  
    open(OUT, ">> $filename") || return;
    if ($newfile) {
	## create header
	printf OUT "\nThis digest for list has been created on %s\n\n",
      POSIX::strftime("%a %b %e %H:%M:%S %Y", @now);
	print OUT "------- THIS IS A RFC934 COMPLIANT DIGEST, YOU CAN BURST IT -------\n\n";
	printf OUT "\n%s\n\n", $tools::separator;

       # send the date of the next digest to the users
    }
    #$msg->head->delete('Received') if ($msg->head->get('received'));
    $msg->print(\*OUT);
    printf OUT "\n%s\n\n", $tools::separator;
    close(OUT);
    
    #replace the old time
    utime $oldtime,$oldtime,$filename   unless($newfile);
}

## List of lists hosted a robot
sub get_lists {
    my $robot_context = shift || '*';
    my $options = shift;

    my(@lists, $l,@robots);
    do_log('debug2', 'List::get_lists(%s)',$robot_context);

    if ($robot_context eq '*') {
	@robots = &get_robots ;
    }else{
	push @robots, $robot_context ;
    }

    
    foreach my $robot (@robots) {
    
	my $robot_dir =  $Conf{'home'}.'/'.$robot ;
	$robot_dir = $Conf{'home'}  unless ((-d $robot_dir) || ($robot ne $Conf{'host'}));
	
	unless (-d $robot_dir) {
	    do_log('err',"unknown robot $robot, Unable to open $robot_dir");
	    return undef ;
	}
	
	unless (opendir(DIR, $robot_dir)) {
	    do_log('err',"Unable to open $robot_dir");
	    return undef;
	}
	foreach my $l (sort readdir(DIR)) {
	    next if (($l =~ /^\./o) || (! -d "$robot_dir/$l") || (! -f "$robot_dir/$l/config"));

	    my $list = new List ($l, $robot, $options);

	    next unless (defined $list);

	    push @lists, $list;
	    
	}
	closedir DIR;
    }
    return \@lists;
}

## List of robots hosted by Sympa
sub get_robots {

    my(@robots, $r);
    do_log('debug2', 'List::get_robots()');

    unless (opendir(DIR, $Conf{'etc'})) {
	do_log('err',"Unable to open $Conf{'etc'}");
	return undef;
    }
    my $use_default_robot = 1 ;
    foreach $r (sort readdir(DIR)) {
	next unless (($r !~ /^\./o) && (-d "$Conf{'home'}/$r"));
	next unless (-r "$Conf{'etc'}/$r/robot.conf");
	push @robots, $r;
	undef $use_default_robot if ($r eq $Conf{'host'});
    }
    closedir DIR;

    push @robots, $Conf{'host'} if ($use_default_robot);
    return @robots ;
}

## List of lists in database mode which e-mail parameter is member of
## Results concern ALL robots
sub get_which_db {
    my $email = shift;
    my $function = shift;
    do_log('debug3', 'List::get_which_db(%s,%s)', $email, $function);

    unless ($List::use_db) {
	&do_log('info', 'Sympa not setup to use DBI');
	return undef;
    }
    
    my ($l, %which, $statement);

    ## Check database connection
    unless ($dbh and $dbh->ping) {
	return undef unless &db_connect();
    }	   

    if ($function eq 'member') {
 	## Get subscribers
	$statement = sprintf "SELECT list_subscriber, robot_subscriber FROM subscriber_table WHERE user_subscriber = %s",$dbh->quote($email);
	
	push @sth_stack, $sth;
	
	&do_log('debug2','SQL: %s', $statement);
	unless ($sth = $dbh->prepare($statement)) {
	    do_log('err','Unable to prepare SQL statement : %s', $dbh->errstr);
	    return undef;
	}
	
	unless ($sth->execute) {
	    do_log('err','Unable to execute SQL statement "%s" : %s', $statement, $dbh->errstr);
	    return undef;
	}

	while ($l = $sth->fetchrow_hashref) {
	    my ($name, $robot) = ($l->{'list_subscriber'}, $l->{'robot_subscriber'});
	    $name =~ s/\s*$//;  ## usefull for PostgreSQL
	    $which{$robot}{$name}{'member'} = 1;
	}
	
	$sth->finish();
	
	$sth = pop @sth_stack;

    }else {
	## Get admin
	$statement = sprintf "SELECT list_admin, robot_admin, role_admin FROM admin_table WHERE user_admin = %s",$dbh->quote($email);

	push @sth_stack, $sth;
	
	unless ($sth = $dbh->prepare($statement)) {
	    do_log('err','Unable to prepare SQL statement : %s', $dbh->errstr);
 	return undef;
	}
	
	&do_log('debug2','SQL: %s', $statement);

	unless ($sth->execute) {
	    do_log('err','Unable to execute SQL statement "%s" : %s', $statement, $dbh->errstr);
	    return undef;
	}
	
	while ($l = $sth->fetchrow_hashref) {
	    $which{$l->{'robot_admin'}}{$l->{'list_admin'}}{$l->{'role_admin'}} = 1;
	}
	
	$sth->finish();
	
	$sth = pop @sth_stack;
    }

    return \%which;
}

## List of lists where $1 (an email) is $3 (owner, editor or subscriber)
sub get_which {
    my $email = shift;
    my $robot =shift;
    my $function = shift;
    do_log('debug2', 'List::get_which(%s, %s)', $email, $function);

    my ($l, @which);

    ## WHICH in Database
    my $db_which = {};

    if (defined $Conf{'db_type'} && $List::use_db) {
	$db_which = &get_which_db($email,  $function);
    }

    my $all_lists = &get_lists($robot);
    foreach my $list (@$all_lists){
 
	my $l = $list->{'name'};
	# next unless (($list->{'admin'}{'host'} eq $robot) || ($robot eq '*')) ;

	## Skip closed lists unless the user is Listmaster
	if ($list->{'admin'}{'status'} =~ /closed/ &&
	    ! &is_listmaster($email, $robot)) {
	    next;
	}

        if ($function eq 'member') {
	    if (($list->{'admin'}{'user_data_source'} eq 'database') ||
		($list->{'admin'}{'user_data_source'} eq 'include2')){
		if ($db_which->{$robot}{$l}{'member'}) {
		    push @which, $list ;

		    ## Update cache
		    $list_cache{'is_user'}{$list->{'domain'}}{$l}{$email} = 1;
		}else {
		    ## Update cache
		    $list_cache{'is_user'}{$list->{'domain'}}{$l}{$email} = 0;		    
		}
	    }else {
		push @which, $list if ($list->is_user($email));
	    }
	}elsif ($function eq 'owner') {
	    if ($list->{'admin'}{'user_data_source'} eq 'include2'){
 		if ($db_which->{$robot}{$l}{'owner'} == 1) {
  		    push @which, $list ;
 		    
 		    ## Update cache
 		    $list_cache{'am_i'}{'owner'}{$list->{'domain'}}{$l}{$email} = 1;
 		}else {
 		    ## Update cache
 		    $list_cache{'am_i'}{'owner'}{$list->{'domain'}}{$l}{$email} = 0;		    
 		}
  	    }else {	    
  		push @which, $list if ($list->am_i('owner',$email,{'strict' => 1}));
  	    }
	}elsif ($function eq 'editor') {
  	    if ($list->{'admin'}{'user_data_source'} eq 'include2'){
 		if ($db_which->{$robot}{$l}{'editor'} == 1) {
  		    push @which, $list ;
 		    
 		    ## Update cache
 		    $list_cache{'am_i'}{'editor'}{$list->{'domain'}}{$l}{$email} = 1;
  		}else {
 		    ## Update cache
 		    $list_cache{'am_i'}{'editor'}{$list->{'domain'}}{$l}{$email} = 0;		    
 		}
  	    }else {	    
   		push @which, $list if ($list->am_i('editor',$email,{'strict' => 1}));
  	    }
	}else {
	    do_log('err',"Internal error, unknown or undefined parameter $function  in get_which");
            return undef ;
	}
    }
    
    return @which;
}



## return total of messages awaiting moderation
sub get_mod_spool_size {
    my $self = shift;
    do_log('debug3', 'List::get_mod_spool_size()');    
    my @msg;
    
    unless (opendir SPOOL, $Conf{'queuemod'}) {
	&do_log('err', 'Unable to read spool %s', $Conf{'queuemod'});
	return undef;
    }

    my $list_name = $self->{'name'};
    my $list_id = $self->get_list_id();
    @msg = sort grep(/^($list_id|$list_name)\_\w+$/, readdir SPOOL);

    closedir SPOOL;
    return ($#msg + 1);
}

### moderation for shared

# return 1 if the shared is open
sub is_shared_open {
    my $self = shift;
    do_log('debug3', 'List::is_shared_open()');  
    my $dir = $self->{'dir'}.'/shared';
    
    return (-e "$dir/shared");
}

# return the list of documents shared waiting for moderation 
sub get_shared_moderated {
    my $self = shift;
    do_log('debug3', 'List::get_shared_moderated()');  
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
    do_log('debug3', 'List::sort_dir_to_get_mod()');  
    
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

    return undef unless ($Conf{'db_type'} eq 'mysql');

    ## Is the Database defined
    unless ($Conf{'db_name'}) {
	&do_log('info', 'No db_name defined in configuration file');
	return undef;
    }

    unless ($dbh and $dbh->ping) {
	return undef unless &db_connect();
    }
	
    unless ($sth = $dbh->prepare("SHOW FIELDS FROM $table")) {
	do_log('err','Unable to prepare SQL query : %s', $dbh->errstr);
	return undef;
    }
    
    unless ($sth->execute) {
	do_log('err','Unable to execute SQL query : %s', $dbh->errstr);
	return undef;
    }
	    
    while (my $ref = $sth->fetchrow_hashref()) {
	next unless ($ref->{'Field'} eq $field);

	return $ref->{'Type'};
    }

    return undef;
}

## Just check if DB connection is ok
sub check_db_connect {
    
    ## Is the Database defined
    unless ($Conf{'db_name'}) {
	&do_log('err', 'No db_name defined in configuration file');
	return undef;
    }
    
    unless ($dbh and $dbh->ping) {
	unless (&db_connect('just_try')) {
	    &do_log('err', 'Failed to connect to database');	   
	    return undef;
	}
    }

    return 1;
}

sub probe_db {
    &do_log('debug3', 'List::probe_db()');    
    my (%checked, $table);

    ## Database structure
    my %db_struct = ('mysql' => {'user_table' => {'email_user' => 'varchar(100)',
						  'gecos_user' => 'varchar(150)',
						  'password_user' => 'varchar(40)',
						  'cookie_delay_user' => 'int(11)',
						  'lang_user' => 'varchar(10)',
						  'attributes_user' => 'text'},
				 'subscriber_table' => {'list_subscriber' => 'varchar(50)',
							'user_subscriber' => 'varchar(100)',
							'robot_subscriber' => 'varchar(80)',
							'date_subscriber' => 'datetime',
							'update_subscriber' => 'datetime',
							'visibility_subscriber' => 'varchar(20)',
							'reception_subscriber' => 'varchar(20)',
							'topics_subscriber' => 'varchar(200)',
							'bounce_subscriber' => 'varchar(35)',
							'comment_subscriber' => 'varchar(150)',
							'subscribed_subscriber' => "int(1)",
							'included_subscriber' => "int(1)",
							'include_sources_subscriber' => 'varchar(50)',
							'bounce_score_subscriber' => 'smallint(6)',
							'bounce_address_subscriber' => 'varchar(100)'},
				 'admin_table' => {'list_admin' => 'varchar(50)',
						   'user_admin' => 'varchar(100)',
						   'robot_admin' => 'varchar(80)',
						   'role_admin' => "enum('listmaster','owner','editor')",
						   'date_admin' => 'datetime',
						   'update_admin' => 'datetime',
						   'reception_admin' => 'varchar(20)',
						   'comment_admin' => 'varchar(150)',
						   'subscribed_admin' => "int(1)",
						   'included_admin' => "int(1)",
						   'include_sources_admin' => 'varchar(50)',
						   'info_admin' =>  'varchar(150)',
						   'profile_admin' => "enum('privileged','normal')"}
			     },
		     'SQLite' => {'user_table' => {'email_user' => 'varchar(100)',
						   'gecos_user' => 'varchar(150)',
						   'password_user' => 'varchar(40)',
						   'cookie_delay_user' => 'integer',
						   'lang_user' => 'varchar(10)',
						   'attributes_user' => 'varchar(255)'},
				  'subscriber_table' => {'list_subscriber' => 'varchar(50)',
							 'user_subscriber' => 'varchar(100)',
							 'robot_subscriber' => 'varchar(80)',
							 'date_subscriber' => 'timestamp',
							 'update_subscriber' => 'timestamp',
							 'visibility_subscriber' => 'varchar(20)',
							 'reception_subscriber' => 'varchar(20)',
							 'topics_subscriber' => 'varchar(200)',
							 'bounce_subscriber' => 'varchar(35)',
							 'comment_subscriber' => 'varchar(150)',
							 'subscribed_subscriber' => "boolean",
							 'included_subscriber' => "boolean",
							 'include_sources_subscriber' => 'varchar(50)',
							 'bounce_score_subscriber' => 'integer',
							 'bounce_address_subscriber' => 'varchar(100)'},
				  'admin_table' => {'list_admin' => 'varchar(50)',
						    'user_admin' => 'varchar(100)',
						    'robot_admin' => 'varchar(80)',
						    'role_admin' => "varchar(15)",
						    'date_admin' => 'timestamp',
						    'update_admin' => 'timestamp',
						    'reception_admin' => 'varchar(20)',
						    'comment_admin' => 'varchar(150)',
						    'subscribed_admin' => "boolean",
						    'included_admin' => "boolean",
						    'include_sources_admin' => 'varchar(50)',
						    'info_admin' =>  'varchar(150)',
						    'profile_admin' => "varchar(15)"}
			      },
		     );
    
    my %not_null = ('email_user' => 1,
		    'list_subscriber' => 1,
		    'robot_subscriber' => 1,
		    'user_subscriber' => 1,
		    'date_subscriber' => 1,
		    'list_admin' => 1,
		    'robot_admin' => 1,
		    'user_admin' => 1,
		    'role_admin' => 1,
		    'date_admin' => 1);
    
    ## Is the Database defined
    unless ($Conf{'db_name'}) {
	&do_log('info', 'No db_name defined in configuration file');
	return undef;
    }
    unless ($dbh and $dbh->ping) {
	unless (&db_connect('just_try')) {
	    unless (&create_db()) {
		return undef;
	    }
	    if ($ENV{'HTTP_HOST'}) { ## Web context
		return undef unless &db_connect('just_try');
	    }else {
		return undef unless &db_connect();
	    }
	}
    }
    
    my (@tables, $fields, %real_struct);
    if ($Conf{'db_type'} eq 'mysql') {
	
	## Get tables
	@tables = $dbh->tables();
	
	## Clean table names that could be surrounded by `` (recent DBD::mysql release)
	foreach my $t (@tables) {
	    $t =~ s/^\`(.+)\`$/\1/;
	}
	
	unless (defined $#tables) {
	    &do_log('info', 'Can\'t load tables list from database %s : %s', $Conf{'db_name'}, $dbh->errstr);
	    return undef;
	}
	
	## Check required tables
	foreach my $t1 (keys %{$db_struct{'mysql'}}) {
	    my $found;
	    foreach my $t2 (@tables) {
		$found = 1 if ($t1 eq $t2);
	    }
	    unless ($found) {
		unless ($dbh->do("CREATE TABLE $t1 (temporary INT)")) {
		    &do_log('err', 'Could not create table %s in database %s : %s', $t1, $Conf{'db_name'}, $dbh->errstr);
		    next;
		}
		
		&do_log('notice', 'Table %s created in database %s', $t1, $Conf{'db_name'});
		push @tables, $t1;
		$real_struct{$t1} = {};
	    }
	}

	## Get fields
	foreach my $t (@tables) {
	    
	    #	    unless ($sth = $dbh->table_info) {
	    #	    unless ($sth = $dbh->prepare("LISTFIELDS $t")) {
	    unless ($sth = $dbh->prepare("SHOW FIELDS FROM $t")) {
		do_log('err','Unable to prepare SQL query : %s', $dbh->errstr);
		return undef;
	    }
	    
	    unless ($sth->execute) {
		do_log('err','Unable to execute SQL query : %s', $dbh->errstr);
		return undef;
	    }
	    
	    while (my $ref = $sth->fetchrow_hashref()) {
		$real_struct{$t}{$ref->{'Field'}} = $ref->{'Type'};
	    }
	}
	
    }elsif ($Conf{'db_type'} eq 'Pg') {
		
	unless (@tables = $dbh->tables) {
	    &do_log('info', 'Can\'t load tables list from database %s', $Conf{'db_name'});
	    return undef;
	}
    }elsif ($Conf{'db_type'} eq 'SQLite') {
 	
 	unless (@tables = $dbh->tables) {
 	    &do_log('info', 'Can\'t load tables list from database %s', $Conf{'db_name'});
 	    return undef;
 	}
	
 	foreach my $t (@tables) {
 	    $t =~ s/^\"(.+)\"$/\1/;
 	}
	
	foreach my $t (@tables) {
	    next unless (defined $db_struct{$Conf{'db_type'}}{$t});

	    my $res = $dbh->selectall_arrayref("PRAGMA table_info($t)");
	    unless (defined $res) {
		&do_log('err','Failed to check DB tables structure : %s', $dbh->errstr);
		next;
	    }
	    foreach my $field (@$res) {
		$real_struct{$t}{$field->[1]} = $field->[2];
	    }
	}

	# Une simple requête sqlite : PRAGMA table_info('nomtable') , retourne la liste des champs de la table en question.
	# La liste retournée est composée d'un N°Ordre, Nom du champ, Type (longueur), Null ou not null (99 ou 0),Valeur par défaut,Clé primaire (1 ou 0)
	
    }elsif ($Conf{'db_type'} eq 'Oracle') {
 	
 	my $statement = "SELECT table_name FROM user_tables";	 
	
	push @sth_stack, $sth;
	
	unless ($sth = $dbh->prepare($statement)) {
	    do_log('err','Unable to prepare SQL query : %s', $dbh->errstr);
	    return undef;
     	}
	
       	unless ($sth->execute) {
	    &do_log('err','Can\'t load tables list from database and Unable to perform SQL query %s : %s ',$statement, $dbh->errstr);
	    return undef;
     	}
	
	## Process the SQL results
     	while (my $table= $sth->fetchrow()) {
	    push @tables, lc ($table);   	
	}
	
     	$sth->finish();
	
	$sth = pop @sth_stack;
	
    }elsif ($Conf{'db_type'} eq 'Sybase') {
	
	my $statement = sprintf "SELECT name FROM %s..sysobjects WHERE type='U'",$Conf{'db_name'};
#	my $statement = "SELECT name FROM sympa..sysobjects WHERE type='U'";     
	
	push @sth_stack, $sth;
	unless ($sth = $dbh->prepare($statement)) {
	    do_log('err','Unable to prepare SQL query : %s', $dbh->errstr);
	    return undef;
	}
	unless ($sth->execute) {
	    &do_log('err','Can\'t load tables list from database and Unable to perform SQL query %s : %s ',$statement, $dbh->errstr);
	    return undef;
	}
	
	## Process the SQL results
	while (my $table= $sth->fetchrow()) {
	    push @tables, lc ($table);   
	}
	
	$sth->finish();
	$sth = pop @sth_stack;
    }

    foreach $table ( @tables ) {
	$checked{$table} = 1;
    }
    
    my $found_tables = 0;
    foreach $table('user_table', 'subscriber_table', 'admin_table') {
	if ($checked{$table} || $checked{'public.' . $table}) {
	    $found_tables++;
	}else {
	    &do_log('err', 'Table %s not found in database %s', $table, $Conf{'db_name'});
	}
    }
    
    ## Check tables structure if we could get it
    ## Currently only performed with mysql
    if (%real_struct) {
	foreach my $t (keys %{$db_struct{$Conf{'db_type'}}}) {
	    unless ($real_struct{$t}) {
		&do_log('info', 'Table \'%s\' not found in database \'%s\' ; you should create it with create_db.%s script', $t, $Conf{'db_name'}, $Conf{'db_type'});
		return undef;
	    }
	    
	    foreach my $f (sort keys %{$db_struct{$Conf{'db_type'}}{$t}}) {
		unless ($real_struct{$t}{$f}) {
		    &do_log('info', 'Field \'%s\' (table \'%s\' ; database \'%s\') was NOT found. Attempting to add it...', $f, $t, $Conf{'db_name'});
		    
		    my $options;
		    ## To prevent "Cannot add a NOT NULL column with default value NULL" errors
		    if ($not_null{$f}) {
			$options .= 'NOT NULL';
		    }

		    unless ($dbh->do("ALTER TABLE $t ADD $f $db_struct{$Conf{'db_type'}}{$t}{$f} $options")) {
			&do_log('err', 'Could not add field \'%s\' to table\'%s\'.', $f, $t);
			&do_log('err', 'Sympa\'s database structure may have change since last update ; please check RELEASE_NOTES');
			return undef;
		    }
		    
		    if ($f eq 'email_user') {
			&do_log('info', 'Setting %s field as PRIMARY', $f);
			unless ($dbh->do("ALTER TABLE $t ADD PRIMARY KEY ($f)")) {
			    &do_log('err', 'Could not set field \'%s\' as PRIMARY KEY, table \'%s\'.', $f, $t);
			    return undef;
			}
		    }
		    
		    ## We should DROP existing indexes
		    if ($f eq 'user_subscriber') {
			&do_log('info', 'Setting list_subscriber,user_subscriber fields as PRIMARY');
			unless ($dbh->do("ALTER TABLE $t ADD PRIMARY KEY (list_subscriber,user_subscriber,robot_subscriber)")) {
			    &do_log('err', 'Could not set field \'list_subscriber,user_subscriber,robot_subscriber\' as PRIMARY KEY, table\'%s\'.', $t);
			    return undef;
			}
			unless ($dbh->do("ALTER TABLE $t ADD INDEX (user_subscriber,list_subscriber,robot_subscriber)")) {
			    &do_log('err', 'Could not set INDEX on field \'user_subscriber,list_subscriber,robot_subscriber\', table\'%s\'.', $t);
			    return undef;
			}
		    }
		    
		    if ($f eq 'user_admin') {
			&do_log('info', 'Setting list_admin,user_admin,robot_admin,role_admin fields as PRIMARY');
			unless ($dbh->do("ALTER TABLE $t ADD PRIMARY KEY (list_admin,user_admin,robot_admin,role_admin)")) {
			    &do_log('err', 'Could not set field \'list_admin,user_admin,robot_admin,role_admin\' as PRIMARY KEY, table\'%s\'.', $t);
			    return undef;
			}
			unless ($dbh->do("ALTER TABLE $t ADD INDEX (user_admin,list_admin,robot_admin,role_admin)")) {
			    &do_log('err', 'Could not set INDEX on field \'user_admin,list_admin,robot_admin,role_admin\', table\'%s\'.', $t);
			    return undef;
			}
		    }		    
		    
		    &do_log('info', 'Field %s added to table %s', $f, $t);
		    
		    ## Remove temporary DB field
		    if ($real_struct{$t}{'temporary'}) {
			unless ($dbh->do("ALTER TABLE $t DROP temporary")) {
			    &do_log('err', 'Could not drop temporary table field : %s', $dbh->errstr);
			}
			delete $real_struct{$t}{'temporary'};
		    }
		    
		    next;
		}
		
		
		## Change DB types if different and if update_db_types enabled
		if ($Conf{'update_db_field_types'} eq 'auto') {
		    unless ($real_struct{$t}{$f} eq $db_struct{$Conf{'db_type'}}{$t}{$f}) {
			&do_log('err', 'Field \'%s\'  (table \'%s\' ; database \'%s\') does NOT have awaited type (%s). Attempting to change it...', $f, $t, $Conf{'db_name'}, $db_struct{$Conf{'db_type'}}{$t}{$f});
			
			my $options;
			if ($not_null{$f}) {
			    $options .= 'NOT NULL';
			}

			&do_log('notice', "ALTER TABLE $t CHANGE $f $f $db_struct{$Conf{'db_type'}}{$t}{$f} $options");
			unless ($dbh->do("ALTER TABLE $t CHANGE $f $f $db_struct{$Conf{'db_type'}}{$t}{$f} $options")) {
			    &do_log('err', 'Could not change field \'%s\' in table\'%s\'.', $f, $t);
			    &do_log('err', 'Sympa\'s database structure may have change since last update ; please check RELEASE_NOTES');
			    return undef;
			}
			
			&do_log('info', 'Field %s in table %s, structur updated', $f, $t);
		    }
		}else {
		    unless ($real_struct{$t}{$f} eq $db_struct{$Conf{'db_type'}}{$t}{$f}) {
			&do_log('err', 'Field \'%s\'  (table \'%s\' ; database \'%s\') does NOT have awaited type (%s).', $f, $t, $Conf{'db_name'}, $db_struct{$Conf{'db_type'}}{$t}{$f});
			&do_log('err', 'Sympa\'s database structure may have change since last update ; please check RELEASE_NOTES');
			return undef;
		    }
		}
	    }
	}

	## Try to run the create_db.XX script
    }elsif ($found_tables == 0) {
	unless (open SCRIPT, "--SCRIPTDIR--/create_db.$Conf{'db_type'}") {
	    &do_log('err', "Failed to open '%s' file : %s", "--SCRIPTDIR--/create_db.$Conf{'db_type'}", $!);
	    return undef;
	}
	my $script;
	while (<SCRIPT>) {
	    $script .= $_;
	}
	close SCRIPT;
	my @scripts = split /;\n/,$script;

	&do_log('notice', "Trying to run the '%s' script...", "--SCRIPTDIR--/create_db.$Conf{'db_type'}");
	foreach my $sc (@scripts) {
	    next if ($sc =~ /^\#/);
	    unless ($dbh->do($sc)) {
		&do_log('err', "Failed to run script '%s' : %s", "--SCRIPTDIR--/create_db.$Conf{'db_type'}", $dbh->errstr);
		return undef;
	    }
	}

	## SQLite :  the only access permissions that can be applied are 
	##           the normal file access permissions of the underlying operating system
	if (($Conf{'db_type'} eq 'SQLite') &&  (-f $Conf{'db_name'})) {
	    `chown --USER--.--GROUP-- $Conf{'db_name'}`; ## Failed with chmod() perl subroutine
	}

    }elsif ($found_tables < 3) {
	&do_log('err', 'Missing required tables in the database ; you should create them with create_db.%s script', $Conf{'db_type'});
	return undef;
    }
    
    return 1;
}

## Try to create the database
sub create_db {
    &do_log('debug3', 'List::create_db()');    

    &do_log('notice','Trying to create %s database...', $Conf{'db_name'});

    unless ($Conf{'db_type'} eq 'mysql') {
	&do_log('err', 'Cannot create %s DB', $Conf{'db_type'});
	return undef;
    }

    my $drh;
    unless ($drh = DBI->connect("DBI:mysql:dbname=mysql;host=localhost", 'root', '')) {
	&do_log('err', 'Cannot connect as root to database');
	return undef;
    }

    ## Create DB
    my $rc = $drh->func("createdb", $Conf{'db_name'}, 'localhost', $Conf{'db_user'}, $Conf{'db_passwd'}, 'admin');
    unless (defined $rc) {
	&do_log('err', 'Cannot create database %s : %s', $Conf{'db_name'}, $drh->errstr);
	return undef;
    }

    ## Re-connect to DB (to prevent "MySQL server has gone away" error)
    unless ($drh = DBI->connect("DBI:mysql:dbname=mysql;host=localhost", 'root', '')) {
	&do_log('err', 'Cannot connect as root to database');
	return undef;
    }

    ## Grant privileges
    unless ($drh->do("GRANT ALL ON $Conf{'db_name'}.* TO $Conf{'db_user'}\@localhost IDENTIFIED BY '$Conf{'db_passwd'}'")) {
	&do_log('err', 'Cannot grant privileges to %s on database %s : %s', $Conf{'db_user'}, $Conf{'db_name'}, $drh->errstr);
	return undef;
    }

    &do_log('notice', 'Database %s created', $Conf{'db_name'});

    ## Reload MysqlD to take changes into account
    my $rc = $drh->func("reload", $Conf{'db_name'}, 'localhost', $Conf{'db_user'}, $Conf{'db_passwd'}, 'admin');
    unless (defined $rc) {
	&do_log('err', 'Cannot reload mysqld : %s', $drh->errstr);
	return undef;
    }

    $drh->disconnect();

    return 1;
}

## Update DB structure or content if required
sub maintenance {
    my $version_file = "$Conf{'etc'}/data_structure.version";
    my $previous_version;

    if (-f $version_file) {
	unless (open VFILE, $version_file) {
	    do_log('err', "Unable to open %s : %s", $version_file, $!);
	    return undef;
	}
	while (<VFILE>) {
	    next if /^\s*$/;
	    next if /^\s*\#/;
	    chomp;
	    $previous_version = $_;
	    last;
	}
	close VFILE;
    }else {
	&do_log('notice', "No previous data_structure.version file was found ; assuming you are upgrading to %s", $Version::Version);
	$previous_version = '0';
    }
    
    ## Skip if version is the same
    if ($previous_version eq $Version::Version) {
	return 1;
    }

    &do_log('notice', "Upgrading from Sympa version %s to %s", $previous_version, $Version::Version);    

    ## Set 'subscribed' data field to '1' is none of 'subscribed' and 'included' is set
    if (&tools::lower_version($previous_version, '4.2a')) {

	## Check database connection
	unless ($dbh and $dbh->ping) {
	    return undef unless &db_connect();
	}
	
	my $statement = "UPDATE subscriber_table SET subscribed_subscriber=1 WHERE ((included_subscriber IS NULL OR included_subscriber!=1) AND (subscribed_subscriber IS NULL OR subscribed_subscriber!=1))";
	
	&do_log('notice','Updating subscribed field of the subscriber table...');
	my $rows = $dbh->do($statement);
	unless (defined $rows) {
	    &fatal_err("Unable to execute SQL statement %s : %s", $statement, $dbh->errstr);	    
	}
	&do_log('notice','%d rows have been updated', $rows);
    }    

    ## Migration to tt2
    if (&tools::lower_version($previous_version, '4.2b')) {

	&do_log('notice','Migrating templates to TT2 format...');	
	
	unless (open EXEC, '--SCRIPTDIR--/tpl2tt2.pl|') {
	    &do_log('err','Unable to run --SCRIPTDIR--/tpl2tt2.pl');
	    return undef;
	}
	close EXEC;
	
	&do_log('notice','Rebuilding web archives...');
	my $all_lists = &List::get_lists('*');
	foreach my $list ( @$all_lists ) {

	    next unless (defined $list->{'admin'}{'web_archive'});
	    my $file = $Conf{'queueoutgoing'}.'/.rebuild.'.$list->get_list_id();
	    
	    unless (open REBUILD, ">$file") {
		&do_log('err','Cannot create %s', $file);
		next;
	    }
	    print REBUILD ' ';
	    close REBUILD;
	}	
    }
    
    ## Initializing the new admin_table
    if (&tools::lower_version($previous_version, '4.2b.4')) {
	&do_log('notice','Initializing the new admin_table...');
	my $all_lists = &List::get_lists('*');
	foreach my $list ( @$all_lists ) {
	    $list->sync_include_admin();
	}
    }

    ## Move old-style web templates out of the include_path
    if (&tools::lower_version($previous_version, '5.0.1')) {
	&do_log('notice','Old web templates HTML structure is not compliant with latest ones.');
	&do_log('notice','Moving old-style web templates out of the include_path...');

	my @directories;

	if (-d "$Conf::Conf{'etc'}/web_tt2") {
	    push @directories, "$Conf::Conf{'etc'}/web_tt2";
	}

	## Go through Virtual Robots
	foreach my $vr (keys %{$Conf::Conf{'robots'}}) {

	    if (-d "$Conf::Conf{'etc'}/$vr/web_tt2") {
		push @directories, "$Conf::Conf{'etc'}/$vr/web_tt2";
	    }
	}

	## Search in V. Robot Lists
	my $all_lists = &List::get_lists('*');
	foreach my $list ( @$all_lists ) {
	    if (-d "$list->{'dir'}/web_tt2") {
		push @directories, "$list->{'dir'}/web_tt2";
	    }	    
	}

	my @templates;

	foreach my $d (@directories) {
	    unless (opendir DIR, $d) {
		printf STDERR "Error: Cannot read %s directory : %s", $d, $!;
		next;
	    }
	    
	    foreach my $tt2 (sort grep(/\.tt2$/,readdir DIR)) {
		push @templates, "$d/$tt2";
	    }
	    
	    closedir DIR;
	}

	foreach my $tpl (@templates) {
	    unless (rename $tpl, "$tpl.oldtemplate") {
		printf STDERR "Error : failed to rename $tpl to $tpl.oldtemplate : $!\n";
		next;
	    }

	    &do_log('notice','File %s renamed %s', $tpl, "$tpl.oldtemplate");
	}
    }


    ## Clean buggy list config files
    if (&tools::lower_version($previous_version, '5.1b')) {
	&do_log('notice','Cleaning buggy list config files...');
	my $all_lists = &List::get_lists('*');
	foreach my $list ( @$all_lists ) {
	    $list->save_config('listmaster@'.$list->{'domain'});
	}
    }

    ## Fix a bug in Sympa 5.1
    if (&tools::lower_version($previous_version, '5.1.2')) {
	&do_log('notice','Rename archives/log. files...');
	my $all_lists = &List::get_lists('*');
	foreach my $list ( @$all_lists ) {
	    my $l = $list->{'name'}; 
	    if (-f $list->{'dir'}.'/archives/log.') {
		rename $list->{'dir'}.'/archives/log.', $list->{'dir'}.'/archives/log.00';
	    }
	}
    }

    if (&tools::lower_version($previous_version, '5.2a.1')) {

	## Fill the robot_subscriber and robot_admin fields in DB
	&do_log('notice','Updating the new robot_subscriber and robot_admin  Db fields...');

	unless ($List::use_db) {
	    &do_log('info', 'Sympa not setup to use DBI');
	    return undef;
	}

	## Check database connection
	unless ($dbh and $dbh->ping) {
	    return undef unless &db_connect();
	}	   

	foreach my $r (keys %{$Conf{'robots'}}) {
	    my $all_lists = &List::get_lists($r, {'skip_sync_admin' => 1});
	    foreach my $list ( @$all_lists ) {
		
		foreach my $table ('subscriber','admin') {
		    my $statement = sprintf "UPDATE %s_table SET robot_%s=%s WHERE (list_%s=%s)",
		    $table,
		    $table,
		    $dbh->quote($r),
		    $table,
		    $dbh->quote($list->{'name'});

		    unless ($dbh->do($statement)) {
			do_log('err','Unable to execute SQL statement "%s" : %s', 
			       $statement, $dbh->errstr);
			return undef;
		    }
		}
		
		## Force Sync_admin
		$list = new List ($list->{'name'}, $list->{'domain'}, {'force_sync_admin' => 1});
	    }
	}

	## Rename web archive directories using 'domain' instead of 'host'
	&do_log('notice','Renaming web archive directories with the list domain...');
	
	my $root_dir = &Conf::get_robot_conf($Conf{'host'},'arc_path');
	unless (opendir ARCDIR, $root_dir) {
	    do_log('err',"Unable to open $root_dir : $!");
	    return undef;
	}
	
	foreach my $dir (sort readdir(ARCDIR)) {
	    next if (($dir =~ /^\./o) || (! -d $root_dir.'/'.$dir)); ## Skip files and entries starting with '.'
		     
	    my ($listname, $listdomain) = split /\@/, $dir;

	    next unless ($listname && $listdomain);

	    my $list = new List $listname;
	    unless (defined $list) {
		do_log('notice',"Skipping unknown list $listname");
		next;
	    }
	    
	    if ($listdomain ne $list->{'domain'}) {
		my $old_path = $root_dir.'/'.$listname.'@'.$listdomain;		
		my $new_path = $root_dir.'/'.$listname.'@'.$list->{'domain'};

		if (-d $new_path) {
		    do_log('err',"Could not rename %s to %s ; directory already exists", $old_path, $new_path);
		    next;
		}else {
		    unless (rename $old_path, $new_path) {
			do_log('err',"Failed to rename %s to %s : %s", $old_path, $new_path, $!);
			next;
		    }
		    &do_log('notice', "Renamed %s to %s", $old_path, $new_path);
		}
	    }		     
	}
	close ARCDIR;
	
    }

    ## DB fields of enum type have been changed to int
    if (&tools::lower_version($previous_version, '5.2a.1')) {
	
	if ($List::use_db && $Conf{'db_type'} eq 'mysql') {
	    my %check = ('subscribed_subscriber' => 'subscriber_table',
			 'included_subscriber' => 'subscriber_table',
			 'subscribed_admin' => 'admin_table',
			 'included_admin' => 'admin_table');
	    
	    ## Check database connection
	    unless ($dbh and $dbh->ping) {
		return undef unless &db_connect();
	    }	   
	    
	    foreach my $field (keys %check) {

		my $statement;
				
		## Query the Database
		$statement = sprintf "SELECT max(%s) FROM %s", $field, $check{$field};
		
		my $sth;
		
		unless ($sth = $dbh->prepare($statement)) {
		    do_log('err','Unable to prepare SQL statement : %s', $dbh->errstr);
		    return undef;
		}
		
		unless ($sth->execute) {
		    do_log('err','Unable to execute SQL statement "%s" : %s', $statement, $dbh->errstr);
		    return undef;
		}
		
		my $max = $sth->fetchrow();
		$sth->finish();		

		## '0' has been mapped to 1 and '1' to 2
		## Restore correct field value
		if ($max > 1) {
		    ## 1 to 0
		    &do_log('notice', 'Fixing DB field %s ; turning 1 to 0...', $field);
		    
		    my $statement = sprintf "UPDATE %s SET %s=%d WHERE (%s=%d)", $check{$field}, $field, 0, $field, 1;
		    my $rows;
		    unless ($rows = $dbh->do($statement)) {
			do_log('err','Unable to execute SQL statement "%s" : %s', $statement, $dbh->errstr);
			return undef;
		    }
		    
		    &do_log('notice', 'Updated %d rows', $rows);

		    ## 2 to 1
		    &do_log('notice', 'Fixing DB field %s ; turning 2 to 1...', $field);
		    
		    my $statement = sprintf "UPDATE %s SET %s=%d WHERE (%s=%d)", $check{$field}, $field, 1, $field, 2;
		    my $rows;
		    unless ($rows = $dbh->do($statement)) {
			do_log('err','Unable to execute SQL statement "%s" : %s', $statement, $dbh->errstr);
			return undef;
		    }
		    
		    &do_log('notice', 'Updated %d rows', $rows);		    

		}
	    }
	}
    }

    ## Rename bounce sub-directories
    if (&tools::lower_version($previous_version, '5.2a.1')) {

	&do_log('notice','Renaming bounce sub-directories adding list domain...');
	
	my $root_dir = &Conf::get_robot_conf($Conf{'host'},'bounce_path');
	unless (opendir BOUNCEDIR, $root_dir) {
	    do_log('err',"Unable to open $root_dir : $!");
	    return undef;
	}
	
	foreach my $dir (sort readdir(BOUNCEDIR)) {
	    next if (($dir =~ /^\./o) || (! -d $root_dir.'/'.$dir)); ## Skip files and entries starting with '.'
		     
	    next if ($dir =~ /\@/); ## Directory already include the list domain

	    my $listname = $dir;
	    my $list = new List $listname;
	    unless (defined $list) {
		do_log('notice',"Skipping unknown list $listname");
		next;
	    }
	    
	    my $old_path = $root_dir.'/'.$listname;		
	    my $new_path = $root_dir.'/'.$listname.'@'.$list->{'domain'};
	    
	    if (-d $new_path) {
		do_log('err',"Could not rename %s to %s ; directory already exists", $old_path, $new_path);
		next;
	    }else {
		unless (rename $old_path, $new_path) {
		    do_log('err',"Failed to rename %s to %s : %s", $old_path, $new_path, $!);
		    next;
		}
		&do_log('notice', "Renamed %s to %s", $old_path, $new_path);
	    }
	}
	close BOUNCEDIR;
    }

    ## Update lists config using 'include_list'
    if (&tools::lower_version($previous_version, '5.2a.1')) {
	
	&do_log('notice','Update lists config using include_list parameter...');

	my $all_lists = &List::get_lists('*');
	foreach my $list ( @$all_lists ) {

	    if (defined $list->{'admin'}{'include_list'}) {
	    
		foreach my $index (0..$#{$list->{'admin'}{'include_list'}}) {
		    my $incl = $list->{'admin'}{'include_list'}[$index];
		    my $incl_list = new List ($incl);
		    
		    if (defined $incl_list &&
			$incl_list->{'domain'} ne $list->{'domain'}) {
			&do_log('notice','Update config file of list %s, including list %s', $list->get_list_id(), $incl_list->get_list_id());
			
			$list->{'admin'}{'include_list'}[$index] = $incl_list->get_list_id();

			$list->save_config('listmaster@'.$list->{'domain'});
		    }
		}
	    }
	}	
    }

    ## Saving current version if required
    unless (open VFILE, ">$version_file") {
	do_log('err', "Unable to write %s ; sympa.pl needs write access on %s directory : %s", $version_file, $Conf{'etc'}, $!);
	return undef;
    }
    printf VFILE "# This file is automatically created by sympa.pl after installation\n# Unless you know what you are doing, you should not modify it\n";
    printf VFILE "%s\n", $Version::Version;
    close VFILE;

    return 1;
}

## Lowercase field from database
sub lowercase_field {
    my ($table, $field) = @_;

    my $total = 0;

    ## Check database connection
    unless ($dbh and $dbh->ping) {
	return undef unless &db_connect();
    }

    unless ($sth = $dbh->prepare("SELECT $field from $table")) {
	do_log('err','Unable to prepare SQL statement : %s', $dbh->errstr);
	return undef;
    }

    unless ($sth->execute) {
	do_log('err','Unable to execute SQL statement : %s', $dbh->errstr);
	return undef;
    }

    while (my $user = $sth->fetchrow_hashref) {
	my $lower_cased = lc($user->{$field});
	next if ($lower_cased eq $user->{$field});

	$total++;

	## Updating Db
	my $statement = sprintf "UPDATE $table SET $field=%s WHERE ($field=%s)", $dbh->quote($lower_cased), $dbh->quote($user->{$field});
	
	unless ($dbh->do($statement)) {
	    do_log('err','Unable to execute SQL statement "%s" : %s', $statement, $dbh->errstr);
	    return undef;
	}
    }
    $sth->finish();

    return $total;
}

## Loads the list of topics if updated
sub load_topics {
    
    my $robot = shift ;
    do_log('debug2', 'List::load_topics(%s)',$robot);

    my $conf_file = &tools::get_filename('etc','topics.conf',$robot);

    unless ($conf_file) {
	&do_log('err','No topics.conf defined');
	return undef;
    }

    my $topics = {};

    ## Load if not loaded or changed on disk
    if (! $list_of_topics{$robot} || ((stat($conf_file))[9] > $mtime{'topics'}{$robot})) {

	## delete previous list of topics
	%list_of_topics = undef;

	unless (-r $conf_file) {
	    &do_log('err',"Unable to read $conf_file");
	    return undef;
	}
	
	unless (open (FILE, $conf_file)) {
	    &do_log('err',"Unable to open config file $conf_file");
	    return undef;
	}
	
	## Raugh parsing
	my $index = 0;
	my (@raugh_data, $topic);
	while (<FILE>) {
	    if (/^([\w\/]+)\s*$/) {
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
	    &do_log('notice', 'No topic defined in %s/topics.conf', $Conf{'etc'});
	    return undef;
	}

	## Analysis
	foreach my $topic (@raugh_data) {
	    my @tree = split '/', $topic->{'name'};
	    
	    if ($#tree == 0) {
		my $title = _get_topic_titles($topic);
		$list_of_topics{$robot}{$tree[0]}{'title'} = $title;
		$list_of_topics{$robot}{$tree[0]}{'visibility'} = &_load_scenario_file('topics_visibility', $robot,$topic->{'visibility'}||'default');
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
		$list_of_topics{$robot}{$t}{'visibility'} = &_load_scenario_file('topics_visibility', $robot,'default');
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
    do_log('debug3', 'List::_apply_defaults()');

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
	    $::pinfo{$p}{'format'} = $tools::regexp{'scenario'};
	    $::pinfo{$p}{'default'} = 'default';
	}

	## Task format
	if ($::pinfo{$p}{'task'}) {
	    $::pinfo{$p}{'format'} = $tools::regexp{'task'};
	}

	## Datasource format
	if ($::pinfo{$p}{'datasource'}) {
	    $::pinfo{$p}{'format'} = $tools::regexp{'datasource'};
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
		$::pinfo{$p}{'format'}{$k}{'format'} = $tools::regexp{'scenario'};
		$::pinfo{$p}{'format'}{$k}{'default'} = 'default' unless (($p eq 'web_archive') && ($k eq 'access'));
	    }

	    ## Task format
	    if (ref($::pinfo{$p}{'format'}{$k}) && $::pinfo{$p}{'format'}{$k}{'task'}) {
		$::pinfo{$p}{'format'}{$k}{'format'} = $tools::regexp{'task'};
	    }

	    ## Datasource format
	    if (ref($::pinfo{$p}{'format'}{$k}) && $::pinfo{$p}{'format'}{$k}{'datasource'}) {
		$::pinfo{$p}{'format'}{$k}{'format'} = $tools::regexp{'datasource'};
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
    if ($List::use_db) {
	$::pinfo{'user_data_source'}{'default'} = 'include2';
    }else {
	$::pinfo{'user_data_source'}{'default'} = 'file';
    }
    
    return \%::pinfo;
}

## Save a parameter
sub _save_list_param {
    my ($key, $p, $defaults, $fd) = @_;
    &do_log('debug4', '_save_list_param(%s)', $key);

    ## Ignore default value
    return 1 if ($defaults == 1);
#    next if ($defaults == 1);

    return 1 unless (defined ($p));
#    next  unless (defined ($p));

    if (defined ($::pinfo{$key}{'scenario'}) ||
        defined ($::pinfo{$key}{'task'}) ) {
	return 1 if ($p->{'name'} eq 'default');

	printf $fd "%s %s\n", $key, $p->{'name'};
	print $fd "\n";

    }elsif (ref($::pinfo{$key}{'file_format'})) {
	printf $fd "%s\n", $key;
	foreach my $k (keys %{$p}) {

	    if (defined ($::pinfo{$key}{'file_format'}{$k}{'scenario'}) ) {
		## Skip if empty value
		next if ($p->{$k}{'name'} =~ /^\s*$/);

		printf $fd "%s %s\n", $k, $p->{$k}{'name'};

	    }elsif (($::pinfo{$key}{'file_format'}{$k}{'occurrence'} =~ /n$/)
		    && $::pinfo{$key}{'file_format'}{$k}{'split_char'}) {
		
		printf $fd "%s %s\n", $k, join($::pinfo{$key}{'file_format'}{$k}{'split_char'}, @{$p->{$k}});
	    }else {
		## Skip if empty value
		next if ($p->{$k} =~ /^\s*$/);

		printf $fd "%s %s\n", $k, $p->{$k};
	    }
	}
	print $fd "\n";

    }else {
	if (($::pinfo{$key}{'occurrence'} =~ /n$/)
	    && $::pinfo{$key}{'split_char'}) {
	    ################" avant de debugger do_edit_list qui crée des nouvelles entrées vides
 	    my $string = join($::pinfo{$key}{'split_char'}, @{$p});
 	    $string =~ s/\,\s*$//;
	    
 	    printf $fd "%s %s\n\n", $key, $string;
	}elsif ($key eq 'digest') {
	    my $value = sprintf '%s %d:%d', join(',', @{$p->{'days'}})
		,$p->{'hour'}, $p->{'minute'};
	    printf $fd "%s %s\n\n", $key, $value;
##	}elsif (($key eq 'user_data_source') && $defaults && $List::use_db) {
##	    printf $fd "%s %s\n\n", $key,  'database';
	}else {
	    printf $fd "%s %s\n\n", $key, $p;
	}
    }
    
    return 1;
}

## Load a single line
sub _load_list_param {
    my ($robot,$key, $value, $p, $directory) = @_;
    &do_log('debug4','_load_list_param(%s,\'%s\',\'%s\')', $robot,$key, $value);
    
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
    
    ## Scenario
    if ($p->{'scenario'}) {
	$value =~ y/,/_/;
	$value = &List::_load_scenario_file ($p->{'scenario'},$robot, $value, $directory);
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

    do_log('debug2', 'List::load_cert(%s)',$self->{'name'});

    # we only send the encryption certificate: this is what the user
    # needs to send mail to the list; if he ever gets anything signed,
    # it will have the respective cert attached anyways.
    # (the problem is that netscape, opera and IE can't only
    # read the first cert in a file)
    my($certs,$keys) = tools::smime_find_keys($self->{dir},'encrypt');

    my @cert;
    if ($format eq 'pem') {
	unless(open(CERT, $certs)) {
	    do_log('err', "List::get_cert(): Unable to open $certs: $!");
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
	unless (open CERT, "$Conf{'openssl'} x509 -in $certs -outform DER|") {
	    do_log('err', "$Conf{'openssl'} x509 -in $certs -outform DER|");
	    do_log('err', "List::get_cert(): Unable to open get $certs in DER format: $!");
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

## Load a config file
sub _load_admin_file {
    my ($directory,$robot, $file) = @_;
    do_log('debug3', 'List::_load_admin_file(%s, %s, %s)', $directory, $robot, $file);

    my $config_file = $directory.'/'.$file;

    my %admin;
    my (@paragraphs);

    ## Just in case...
    $/ = "\n";

    ## Set defaults to 1
    foreach my $pname (keys %::pinfo) {       
	$admin{'defaults'}{$pname} = 1 unless ($::pinfo{$pname}{'internal'});
    }

    unless (open CONFIG, $config_file) {
	&do_log('info', 'Cannot open %s', $config_file);
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
	    &do_log('info', 'Bad paragraph "%s" in %s, ignore it', @paragraph, $config_file);
	    next;
	}
	    
	$pname = $1;

	## Parameter aliases (compatibility concerns)
	if (defined $alias{$pname}) {
	    $paragraph[0] =~ s/^\s*$pname/$alias{$pname}/;
	    $pname = $alias{$pname};
	}
	
	unless (defined $::pinfo{$pname}) {
	    &do_log('info', 'Unknown parameter "%s" in %s, ignore it', $pname, $config_file);
	    next;
	}

	## Uniqueness
	if (defined $admin{$pname}) {
	    unless (($::pinfo{$pname}{'occurrence'} eq '0-n') or
		    ($::pinfo{$pname}{'occurrence'} eq '1-n')) {
		&do_log('info', 'Multiple parameter "%s" in %s', $pname, $config_file);
	    }
	}
	
	## Line or Paragraph
	if (ref $::pinfo{$pname}{'file_format'} eq 'HASH') {
	    ## This should be a paragraph
	    unless ($#paragraph > 0) {
		&do_log('info', 'Expecting a paragraph for "%s" parameter in %s, ignore it', $pname, $config_file);
		next;
	    }
	    
	    ## Skipping first line
	    shift @paragraph;

	    my %hash;
	    for my $i (0..$#paragraph) {	    
		next if ($paragraph[$i] =~ /^\s*\#/);
		
		unless ($paragraph[$i] =~ /^\s*(\w+)\s*/) {
		    &do_log('info', 'Bad line "%s" in %s',$paragraph[$i], $config_file);
		}
		
		my $key = $1;
		
		unless (defined $::pinfo{$pname}{'file_format'}{$key}) {
		    &do_log('info', 'Unknown key "%s" in paragraph "%s" in %s', $key, $pname, $config_file);
		    next;
		}
		
		unless ($paragraph[$i] =~ /^\s*$key\s+($::pinfo{$pname}{'file_format'}{$key}{'file_format'})\s*$/i) {
		    &do_log('info', 'Bad entry "%s" in paragraph "%s" in %s', $paragraph[$i], $key, $pname, $config_file);
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
			&do_log('info', 'Missing key "%s" in param "%s" in %s', $k, $pname, $config_file);
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
		&do_log('info', 'Expecting a single line for "%s" parameter in %s', $pname, $config_file);
	    }

	    unless ($paragraph[0] =~ /^\s*$pname\s+($::pinfo{$pname}{'file_format'})\s*$/i) {
		&do_log('info', 'Bad entry "%s" in %s', $paragraph[0], $config_file);
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

    ## Apply defaults & check required parameters
    foreach my $p (keys %::pinfo) {

	## Defaults
	unless (defined $admin{$p}) {
	    if (defined $::pinfo{$p}{'default'}) {
		$admin{$p} = &_load_list_param($robot,$p, $::pinfo{$p}{'default'}, $::pinfo{$p}, $directory);

	    }elsif ((ref $::pinfo{$p}{'format'} eq 'HASH')
		    && ($::pinfo{$p}{'occurrence'} !~ /n$/)) {
		## If the paragraph is not defined, try to apply defaults
		my $hash = {};
		
		foreach my $key (keys %{$::pinfo{$p}{'format'}}) {

		    ## Only if all keys have defaults
		    unless (defined $::pinfo{$p}{'format'}{$key}{'default'}) {
			undef $hash;
			last;
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
		&do_log('info','Missing parameter "%s" in %s', $p, $config_file);
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
	if ($admin{'custom_subject'} =~ /^\s*\[\s*(.+)\s*\]\s*$/) {
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
	unless ($List::use_db) {
	    &do_log('info', 'Sympa not setup to use DBI or no database access');
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
      do_log('info','reception is not compatible between default_user_options and available_user_options in %s',$directory);
    }

    return \%admin;
}

## Save a config file
sub _save_admin_file {
    my ($config_file, $old_config_file, $admin) = @_;
    do_log('debug3', 'List::_save_admin_file(%s, %s, %s)', $config_file,$old_config_file, $admin);

    unless (rename $config_file, $old_config_file) {
	&do_log('notice', 'Cannot rename %s to %s', $config_file, $old_config_file);
	return undef;
    }

    unless (open CONFIG, ">$config_file") {
	&do_log('info', 'Cannot open %s', $config_file);
	return undef;
    }
    
    foreach my $c (@{$admin->{'comment'}}) {
	printf CONFIG "%s\n", $c;
    }
    print CONFIG "\n";

    foreach my $key (sort by_order keys %{$admin}) {

	next if ($key =~ /^comment|defaults$/);
	next unless (defined $admin->{$key});

	## Multiple parameter (owner, custom_header,...)
	if ((ref ($admin->{$key}) eq 'ARRAY') &&
	    ! $::pinfo{$key}{'split_char'}) {
	    foreach my $elt (@{$admin->{$key}}) {
		&_save_list_param($key, $elt, $admin->{'defaults'}{$key}, \*CONFIG);
	    }
	}else {
	    &_save_list_param($key, $admin->{$key}, $admin->{'defaults'}{$key}, \*CONFIG);
	}

    }
    close CONFIG;

    return 1;
}

# Is a reception mode in the parameter reception of the available_user_options
# section ?
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
    
    if ($self->{'admin'}{'msg_topic_tagging'} eq 'required') {
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
    &do_log('debug3','automatic_tag(%s,%s)',$self->{'name'},$msg_id);


    my $topic_list = $self->compute_topic($msg,$robot);

    if ($topic_list) {
	my $filename = $self->tag_topic($msg_id,$topic_list,'auto');

	unless ($filename) {
	    &do_log('err','Unable to tag message %s with topic "%s"',$msg_id,$topic_list);
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
    &do_log('debug3','compute_topic(%s,%s)',$self->{'name'},$msg_id);
    my @topic_array;
    my %topic_hash;
    my %keywords;


    ## TAGGING INHERITED BY THREAD
    # getting reply-to
    my $reply_to = $msg->head->get('In-Reply-To');
    $reply_to =  &tools::clean_msg_id($reply_to);
    my $info_msg_reply_to = $self->load_msg_topic_file($reply_to,$robot);

    # is msg reply to already tagged ?	
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
    my $mail_string;

    if ($self->{'admin'}{'msg_topic_keywords_apply_on'} eq 'subject'){
	$mail_string = $msg->head->get('subject');

    }elsif ($self->{'admin'}{'msg_topic_keywords_apply_on'} eq 'body'){
	$mail_string = $msg->bodyhandle->as_string();
    }else {
	$mail_string = $msg->head->get('subject');
	$mail_string .= $msg->bodyhandle->as_string();
    }

    $mail_string =~ s/\-/\\-/;
    $mail_string =~ s/\./\\./;

    # parsing

    foreach my $keyw (keys %keywords) {
	if ($mail_string =~ /$keyw/i){
	    my $k = $keywords{$keyw};
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
    &do_log('debug4','tag_topic(%s,%s,"%s",%s)',$self->{'name'},$msg_id,$topic_list,$method);

    my $robot = $self->{'domain'};
    my $queuetopic = &Conf::get_robot_conf($robot, 'queuetopic');
    my $list_id = $self->get_list_id();
    $msg_id = &tools::clean_msg_id($msg_id);
    $msg_id =~ s/>$//;
    my $file = $list_id.'.'.$msg_id;

    unless (open (FILE, ">$queuetopic/$file")) {
	&do_log('info','Unable to create msg topic file %s/%s : %s', $queuetopic,$file, $!);
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
#         - filename : name of the file containing these informations 
#     | undef 
####################################################
sub load_msg_topic_file {
    my ($self,$msg_id,$robot) = @_;
    $msg_id = &tools::clean_msg_id($msg_id);
    &do_log('debug4','List::load_msg_topic_file(%s,%s)',$self->{'name'},$msg_id);
    
    my $queuetopic = &Conf::get_robot_conf($robot, 'queuetopic');
    my $list_id = $self->get_list_id();
    my $file = "$list_id.$msg_id";
    
    unless (open (FILE, "$queuetopic/$file")) {
	&do_log('info','Unable to open info msg_topic file %s/%s : %s', $queuetopic,$file, $!);
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
		    &do_log('err','List::load_msg_topic_file(%s,%s): syntax error in file %s/%s : %s', $queuetopic,$file, $!);
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
# modifying_msg_topic_for_subscribers()
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
sub modifying_msg_topic_for_subscribers(){
    my ($self,$new_msg_topic) = @_;
    &do_log('debug4',"List::modifying_msg_topic_for_subscribers($self->{'name'}");
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
	
	for (my $subscriber=$self->get_first_user(); $subscriber; $subscriber=$self->get_next_user()) {
	    
	    if ($subscriber->{'reception'} eq 'mail') {
		my $topics = &tools::diff_on_arrays($msg_topic_changes->{'deleted'},&tools::get_array_from_splitted_string($subscriber->{'topics'}));
		
		if ($#{$topics->{'intersection'}} >= 0) {
		    my $wwsympa_url = &Conf::get_robot_conf($self->{'domain'}, 'wwsympa_url');
		    unless ($self->send_notify_to_user('deleted_msg_topics',$subscriber->{'email'},
						       {'del_topics' => $topics->{'intersection'},
							'url' => $wwsympa_url.'/suboptions/'.$self->{'name'}})) {
			&do_log('err',"List::modifying_msg_topic_for_subscribers($self->{'name'}) : impossible to send notify to user about 'deleted_msg_topics'");
		    }
		    unless ($self->update_user(lc($subscriber->{'email'}), 
					       {'update_date' => time,
						'topics' => join(',',@{$topics->{'added'}})})) {
			&do_log('err',"List::modifying_msg_topic_for_subscribers($self->{'name'} : impossible to update user '$subscriber->{'email'}'");
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
# select_subscribers_for_topic
####################################################
# Select users subscribed to a topic that is in
# the topic list incoming when reception mode is 'mail', and the other
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
sub select_subscribers_for_topic {
    my ($self,$string_topic,$subscribers) = @_;
    &do_log('debug3', 'List::select_subscribers_for_topic(%s, %s)', $self->{'name'},$string_topic); 
    
    my @selected_users;
    my $msg_topics;

    if ($string_topic) {
	$msg_topics = &tools::get_array_from_splitted_string($string_topic);
    }

    foreach my $user (@$subscribers) {

	# user topic
	my $info_user = $self->get_subscriber($user);

	if ($info_user->{'reception'} ne 'mail') {
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
	&do_log('notice', "Unable to open $expl/$dir/$filename") ;
	return undef ; 
    }
    
    if ($encoding =~ /^binary|7bit|8bit|base64|quoted-printable|x-uu|x-uuencode|x-gzip64$/ ) {
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
    if ($size < $Conf{'urlize_min_size'}) {
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

    my $tt2_include_path = &tools::make_tt2_include_path($robot,'mail_tt2',$lang,$list);

    &tt2::parse_tt2({'file_name' => $file_name,
		     'file_url'  => $file_url,
		     'file_size' => $size },
		    'urlized_part.tt2',
		    \$new_part,
		    $tt2_include_path);

    my $entity = $parser->parse_data(\$new_part);

    return $entity;
}

sub store_subscription_request {
    my ($self, $email, $gecos) = @_;
    do_log('debug2', 'List::store_subscription_request(%s, %s, %s)', $self->{'name'}, $email, $gecos);

    my $filename = $Conf{'queuesubscribe'}.'/'.$self->get_list_id().'.'.time.'.'.int(rand(1000));
    
    unless (open REQUEST, ">$filename") {
	do_log('notice', 'Could not open %s', $filename);
	return undef;
    }

    printf REQUEST "$email\t$gecos\n";
    close REQUEST;

    return 1;
} 

sub get_subscription_requests {
    my ($self) = shift;
    do_log('debug2', 'List::get_subscription_requests(%s)', $self->{'name'});

    my %subscriptions;

    unless (opendir SPOOL, $Conf{'queuesubscribe'}) {
	&do_log('info', 'Unable to read spool %s', $Conf{'queuesubscribe'});
	return undef;
    }

    foreach my $filename (sort grep(/^$self->{'name'}(\@$self->{'domain'})?\.\d+\.\d+$/, readdir SPOOL)) {
	unless (open REQUEST, "$Conf{'queuesubscribe'}/$filename") {
	    do_log('err', 'Could not open %s', $filename);
	    closedir SPOOL;
	    next;
	}
	my $line = <REQUEST>;
	$line =~ /^((\S+|\".*\")\@\S+)\s*(.*)$/;
	my $email = $1;
	$subscriptions{$email} = {'gecos' => $3};
	
	unless($subscriptions{$email}{'gecos'}) {
		my $user = get_user_db($email);
		if ($user->{'gecos'}) {
			$subscriptions{$email} = {'gecos' => $user->{'gecos'}};
#			&do_log('info', 'get_user_db %s : no gecos',$email);
		}
	}

	$filename =~ /^$self->{'name'}(\@$self->{'domain'})?\.(\d+)\.\d+$/;
	$subscriptions{$email}{'date'} = $2;
	close REQUEST;
    }
    closedir SPOOL;

    return \%subscriptions;
} 

sub get_subscription_request_count {
    my ($self) = shift;
    do_log('debug2', 'List::get_subscription_requests_count(%s)', $self->{'name'});

    my %subscriptions;
    my $i = 0 ;

    unless (opendir SPOOL, $Conf{'queuesubscribe'}) {
	&do_log('info', 'Unable to read spool %s', $Conf{'queuesubscribe'});
	return undef;
    }

    foreach my $filename (sort grep(/^$self->{'name'}(\@$self->{'domain'})?\.\d+\.\d+$/, readdir SPOOL)) {
	$i++;
    }
    closedir SPOOL;

    return $i;
} 

sub delete_subscription_request {
    my ($self, $email) = @_;
    do_log('debug2', 'List::delete_subscription_request(%s, %s)', $self->{'name'}, $email);

    unless (opendir SPOOL, $Conf{'queuesubscribe'}) {
	&do_log('info', 'Unable to read spool %s', $Conf{'queuesubscribe'});
	return undef;
    }

    my $removed_file = 0;
    foreach my $filename (sort grep(/^$self->{'name'}(\@$self->{'domain'})?\.\d+\.\d+$/, readdir SPOOL)) {
	unless (open REQUEST, "$Conf{'queuesubscribe'}/$filename") {
	    do_log('notice', 'Could not open %s', $filename);
	    closedir SPOOL;
	    return undef;
	}
	my $line = <REQUEST>;
	unless ($line =~ /^($tools::regexp{'email'})\s*/ &&
		($1 eq $email)) {
	    next;
	}
	    
	close REQUEST;

	unless (unlink "$Conf{'queuesubscribe'}/$filename") {
	    do_log('err', 'Could not delete file %s', $filename);
	    next;
	}
	$removed_file++;
    }
    closedir SPOOL;
    
    unless ($removed_file > 0) {
	do_log('err', 'No pending subscription was found for user %s', $email);
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


## Returns a unique ID for an include datasource
sub _get_datasource_id {
    my ($source) = shift;

    if (ref ($source)) {
	return substr(Digest::MD5::md5_hex(join('/', %{$source})), -8);
    }else {
	return substr(Digest::MD5::md5_hex($source), -8);
    }
	
}

## Searches the include datasource corresponding to the provided ID
sub search_datasource {
    my ($self, $id) = @_;
    &do_log('debug2','List::search_datasource(%s,%s)', $self->{'name'}, $id);

    ## Go through list parameters
    foreach my $p (keys %{$self->{'admin'}}) {
	next unless ($p =~ /^include/);
	
	## Go through sources
	foreach my $s (@{$self->{'admin'}{$p}}) {
	    if (&_get_datasource_id($s) eq $id) {
		if (ref($s)) {
 		    return $s->{'name'} || $s->{'host'};
		}else{
		    return $s;
		}
	    }
	}
    }

    return undef;
}

## Remove a task in the tasks spool
sub remove_task {
    my $self = shift;
    my $task = shift;

    unless (opendir(DIR, $Conf{'queuetask'})) {
	&do_log ('err', "error : can't open dir %s: %s", $Conf{'queuetask'}, $!);
	return undef;
    }
    my @tasks = grep !/^\.\.?$/, readdir DIR;
    closedir DIR;

    foreach my $task_file (@tasks) {
	if ($task_file =~ /^(\d+)\.\w*\.$task\.$self->{'name'}$/) {
	    unless (unlink("$Conf{'queuetask'}/$task_file")) {
		&do_log('err', 'Unable to remove task file %s : %s', $task_file, $!);
		return undef;
	    }
	    &do_log('notice', 'Removing task file %s', $task_file);
	}
    }

    return 1;
}


# add log in RDBMS 
sub db_log {

    my $process = shift;
    my $email_user = shift; $email_user = lc($email_user);
    my $auth = shift;
    my $ip = shift; $ip = lc($ip);
    my $ope = shift; $ope = lc($ope);
    my $list = shift; $list = lc($list);
    my $robot = shift; $robot = lc($robot);
    my $arg = shift; 
    my $status = shift;
    my $subscriber_count = shift;

    do_log ('info',"db_log (PROCESS = $process, EMAIL = $email_user, AUTH = $auth, IP = $ip, OPERATION = $ope, LIST = $list,ROBOT = $robot, ARG = $arg ,STATUS = $status , LIST= list_subscriber)");

    unless ($process =~ /^((task)|(archived)|(sympa)|(wwsympa)|(bounce))$/) {
	do_log ('err',"Internal_error : incorrect process value $process");
	return undef;
    }

    unless ($auth =~ /^((smtp)|(md5)|(smime)|(null))$/) {
	do_log ('err',"Internal_error : incorrect auth value $auth");
	return undef;
    }
    $auth = '' if ($auth eq 'null');

    my $date=time;
    
    ## Insert in log_table



    my $statement = 'INSERT INTO log_table (id, date, pid, process, email_user, auth, ip, operation, list, robot, arg, status, subscriber_count) ';

    my $statement_value = sprintf "VALUES ('',%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)", $date,$$,$dbh->quote($process),$dbh->quote($email_user),$dbh->quote($auth),$dbh->quote($ip),$dbh->quote($ope),$dbh->quote($list),$dbh->quote($robot),$dbh->quote($arg),$dbh->quote($status),$subscriber_count;		    
    $statement = $statement.$statement_value;
    
		    unless ($dbh->do($statement)) {
			do_log('err','Unable to execute SQL statement \n"%s" \n %s', $statement, $dbh->errstr);
			return undef;
		    }

}

# Scan log_table with appropriate select 
sub get_first_db_log {

    my $select = shift;

    do_log('info','get_first_db_log (%s)',$select);
    ## Check database connection
    unless ($dbh and $dbh->ping) {
	return undef unless &db_connect();
    }

    my $statement; 

    if ($Conf{'db_type'} eq 'Oracle') {
	## "AS" not supported by Oracle
	$statement = "SELECT date \"date\", pid \"pid\", process \"process\", email_user \"email\", auth \"auth\", ip \"ip\",operation \"operation\", list \"list\", robot \"robot\", arg \"arg\", status \"status\", subscriber_count \"count\" FROM log_table WHERE 1 ";
    }else{
	$statement = "SELECT date AS date, pid AS pid, process AS process, email_user AS email, auth AS auth, ip AS ip, operation AS operation, list AS list, robot AS robot, arg AS arg, status AS status, subscriber_count AS count FROM log_table WHERE 1 ";	
    }
    if ($select->{'list'}) {
	$select->{'list'} = lc ($select->{'list'});
	$statement .= sprintf "AND list = %s ",$select->{'list'}; 
    }
    if ($select->{'robot'}) {
	$select->{'robot'} = lc ($select->{'robot'});
	$statement .= sprintf "AND robot = %s ",$select->{'robot'}; 
    }
    if ($select->{'ip'}) {
	$select->{'ip'} = lc ($select->{'ip'});
	$statement .= sprintf "AND ip = %s ",$select->{'ip'}; 
    }
    if ($select->{'ope'}) {
	$select->{'ope'} = lc ($select->{'ope'});
	$statement .= sprintf "AND operation = %s ",$select->{'operation'}; 
    }

    push @sth_stack, $sth;
    unless ($sth = $dbh->prepare($statement)) {
	do_log('err','Unable to prepare SQL statement : %s', $dbh->errstr);
	return undef;
    }
        unless ($sth->execute) {
	do_log('err','Unable to execute SQL statement "%s" : %s', $statement, $dbh->errstr);
	return undef;
    }
    return ($sth->fetchrow_hashref);

}

sub get_next_db_log {

    my $log = $sth->fetchrow_hashref;
    
    unless (defined $log) {
	$sth->finish;
	$sth = pop @sth_stack;
    }
    return $log;
}

## Close the list (remove from DB, remove aliases, change status to 'closed' or 'family_closed')
sub close {
    my ($self, $email, $status) = @_;

    return undef 
	unless ($self && ($list_of_lists{$self->{'domain'}}{$self->{'name'}}));
    
    ## Dump subscribers
    $self->_save_users_file("$self->{'dir'}/subscribers.closed.dump");

    ## Delete users
    my @users;
    for ( my $user = $self->get_first_user(); $user; $user = $self->get_next_user() ){
	push @users, $user->{'email'};
    }
    $self->delete_user(@users);

    ## Remove entries from admin_table
    foreach my $role ('owner','editor') {
	my @admin_users;
	for ( my $user = $self->get_first_admin_user($role); $user; $user = $self->get_next_admin_user() ){
	    push @admin_users, $user->{'email'};
	}
	$self->delete_admin_user($role, @admin_users);
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
    
    return 1;
}

## Remove the list
sub purge {
    my ($self, $email) = @_;

    return undef 
	unless ($self && ($list_of_lists{$self->{'domain'}}{$self->{'name'}}));
    
    &tools::remove_dir($self->{'dir'});

    if ($self->{'name'}) {
	my $arc_dir = &Conf::get_robot_conf($self->{'domain'},'arc_path');
	&tools::remove_dir($arc_dir.'/'.$self->get_list_id());
	&tools::remove_dir($self->get_bounce_dir());
    }
    my @users;
    for ( my $user = $self->get_first_user(); $user; $user = $self->get_next_user() ){
	push @users, $user->{'email'};
    }
    $self->delete_user(@users);
    
    ## Remove entries from admin_table
    foreach my $role ('owner','editor') {
	my @admin_users;
	for ( my $user = $self->get_first_admin_user($role); $user; $user = $self->get_next_admin_user() ){
	    push @admin_users, $user->{'email'};
	}
	$self->delete_admin_user($role, @admin_users);
    }

   # purge should remove alias but in most case aliases of thoses lists are undefined
   # $self->remove_aliases();    
    
    return 1;
}

## Remove list aliases
sub remove_aliases {
    my $self = shift;

    return undef 
	unless ($self && ($list_of_lists{$self->{'domain'}}{$self->{'name'}}));
    
    my $alias_manager = '--SBINDIR--/alias_manager.pl';
    
    unless (-x $alias_manager) {
	&do_log('err','Cannot run alias_manager %s', $alias_manager);
	return undef;
    }
    
    system ("$alias_manager del $self->{'name'} $self->{'admin'}{'host'}");
    my $status = $? / 256;
    unless ($status == 0) {
	do_log('err','Failed to remove aliases ; status %d : %s', $status, $!);
	return undef;
    }
    
    &do_log('info','Aliases for list %s removed successfully', $self->{'name'});
    
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
    &do_log('debug','List::remove_bouncers(%s)',$self->{'name'});
    
    ## Log removal
    foreach my $bouncer (@{$reftab}) {
	&do_log('notice','Removing bouncing subsrciber of list %s : %s', $self->{'name'}, $bouncer);
    }

    unless (&delete_user($self,@$reftab)){
      &do_log('info','error while caling sub delete_users');
      return undef;
    }
    return 1;
}

#Sub for notifying users : "Be carefull,You're bouncing"
#
sub notify_bouncers{
    my $self = shift;
    my $reftab = shift;
    &do_log('debug','List::notify_bouncers(%s)', $self->{'name'});

    foreach my $user (@$reftab){
 	&do_log('notice','Notifying bouncing subsrciber of list %s : %s', $self->{'name'}, $user);
	unless ($self->send_notify_to_user('auto_notify_bouncers',$user,{})) {
	    &do_log('notice',"Unable to send notify 'auto_notify_bouncers' to $user");
	}
    }
    return 1;
}

## Create the document repository
sub create_shared {
    my $self = shift;

    my $dir = $self->{'dir'}.'/shared';

    if (-e $dir) {
	&do_log('err',"List::create_shared : %s already exists", $dir);
	return undef;
    }

    unless (mkdir ($dir, 0777)) {
	&do_log('err',"List::create_shared : unable to create %s : %s ", $dir, $!);
	return undef;
    }

    return 1;
}

## check if a list  has include-type data sources
sub has_include_data_sources {
    my $self = shift;

    foreach my $type ('include_file','include_list','include_remote_sympa_list','include_sql_query','include_remote_file',
		      'include_ldap_query','include_ldap_2level_query','include_admin','owner_include','editor_include') {
	return 1 if (defined $self->{'admin'}{$type});
    }
    
    return 0
}

# move a message to distribute spool
sub move_message {
    my ($self, $file) = @_;
    &do_log('debug2', "tools::move_mesage($file, $self->{'name'})");

    my $dir = $Conf{'queuedistribute'};    
    my $filename = $self->get_list_id().'.'.time.'.'.int(rand(999));

    unless (open OUT, ">$dir/T.$filename") {
	&do_log('err', 'Cannot create file %s', "$dir/T.$filename");
	return undef;
    }
    
    unless (open IN, $file) {
	&do_log('err', 'Cannot open file %s', $file);
	return undef;
    }
    
    print OUT <IN>; close IN; close OUT;
    unless (rename "$dir/T.$filename", "$dir/$filename") {
	&do_log('err', 'Cannot rename file %s into %s',"$dir/T.$filename","$dir/$filename" );
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

#################################################################

## Packages must return true.
1;
