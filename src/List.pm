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
require X509;
require Exporter;
require 'tools.pl';

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

=item get_user ( USER )

Returns a hash with the informations regarding the indicated
user.

=item get_first_user ()

Returns a hash to the first user on the list.

=item get_next_user ()

Returns a hash to the next users, until we reach the end of
the list.

=item update_user ( USER, HASHPTR )

Sets the new values given in the hash for the user.

=item add_user ( USER, HASHPTR )

Adds a new user to the list. May overwrite existing
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

use Mail::Header;
use Mail::Internet;
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
use PlainDigest;

## Database and SQL statement handlers
my ($dbh, $sth, $db_connected, @sth_stack, $use_db, $include_lock_count);

my %list_cache;
my %persistent_cache;

my %date_format = (
		   'read' => {
		       'Pg' => 'date_part(\'epoch\',%s)',
		       'mysql' => 'UNIX_TIMESTAMP(%s)',
		       'Oracle' => '((to_number(to_char(%s,\'J\')) - to_number(to_char(to_date(\'01/01/1970\',\'dd/mm/yyyy\'), \'J\'))) * 86400) +to_number(to_char(%s,\'SSSSS\'))',
		       'Sybase' => 'datediff(second, "01/01/1970",%s)'
		       },
		   'write' => {
		       'Pg' => '\'epoch\'::timestamp with time zone + \'%d sec\'',
		       'mysql' => 'FROM_UNIXTIME(%d)',
		       'Oracle' => 'to_date(to_char(round(%s/86400) + to_number(to_char(to_date(\'01/01/1970\',\'dd/mm/yyyy\'), \'J\'))) || \':\' ||to_char(mod(%s,86400)), \'J:SSSSS\')',
		       'Sybase' => 'dateadd(second,%s,"01/01/1970")'
		       }
	       );

## List parameters defaults
my %default = ('occurrence' => '0-1',
	       'length' => 25
	       );

my @param_order = qw (subject visibility info subscribe add unsubscribe del owner send editor 
		      account topics 
		      host lang web_archive archive digest available_user_options 
		      default_user_options reply_to_header reply_to forced_reply_to * 
		      welcome_return_path remind_return_path user_data_source include_file 
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
## title_id :    Title reference in NLS catalogues
## group :       Group of parameters
## obsolete :    Obsolete parameter ; should not be displayed 
##               nor saved
## order :       Order of parameters within paragraph
###############################################################
%::pinfo = ('account' => {'format' => '\S+',
			  'length' => 10,
			  'title_id' => 1,
			  'group' => 'other'
			  },
	    'add' => {'scenario' => 'add',
		      'title_id' => 2,
		      'group' => 'command'
		      },
	    'anonymous_sender' => {'format' => '.+',
				   'title_id' => 3,
				   'group' => 'sending'
				   },
	    'archive' => {'format' => {'period' => {'format' => ['day','week','month','quarter','year'],
						    'synonym' => {'weekly' => 'week'},
						    'title_id' => 5,
						    'order' => 1
						},
				       'access' => {'format' => ['open','private','public','owner','closed'],
						    'synonym' => {'open' => 'public'},
						    'title_id' => 6,
						    'order' => 2
						}
				   },
			  'title_id' => 4,
			  'group' => 'archives'
		      },
	    'archive_crypted_msg' => {'format' => ['original','decrypted'],
				    'default' => 'cleartext',
				    'title_id' => 212,
				    'group' => 'archives'
				    },
        'available_user_options' => {'format' => {'reception' => {'format' => ['mail','notice','digest','digestplain','summary','nomail','txt','html','urlize','not_me'],
								      'occurrence' => '1-n',
								      'split_char' => ',',
                                      'default' => 'mail,notice,digest,digestplain,summary,nomail,txt,html,urlize,not_me',
								      'title_id' => 89
								      }
						  },
					 'title_id' => 88,
					 'group' => 'sending'
				     },

	    'bounce' => {'format' => {'warn_rate' => {'format' => '\d+',
						      'length' => 3,
						      'unit' => '%',
						      'default' => {'conf' => 'bounce_warn_rate'},
						      'title_id' => 8,
						      'order' => 1
						  },
				      'halt_rate' => {'format' => '\d+',
						      'length' => 3,
						      'unit' => '%',
						      'default' => {'conf' => 'bounce_halt_rate'},
						      'title_id' => 9,
						      'order' => 2
						  }
				  },
			 'title_id' => 7,
			 'group' => 'bounces'
		     },
	    'bouncers_level1' => {'format' => {'rate' => {'format' => '\d+',
								 'length' => 2,
								 'unit' => 'Points',
								 'default' => {'conf' => 'default_bounce_level1_rate'},
								 'title_id' => 214,
								 'order' => 1
								 },
				               'action' => {'format' => ['remove_bouncers','notify_bouncers','none'],
								   'default' => 'notify_bouncers',
								   'title_id' => 215,
								   'order' => 2
								   },
					       'notification' => {'format' => ['none','owner','listmaster'],
									 'default' => 'owner',
									 'title_id' => 219,
									 'order' => 3
									 }
					   },
				      'title_id' => 213,
				      'group' => 'bounces'
				  },
	     'bouncers_level2' => {'format' => {'rate' => {'format' => '\d+',
								 'length' => 2,
								 'unit' => 'Points',
								 'default' => {'conf' => 'default_bounce_level2_rate'},
								 'title_id' => 217,
								 'order' => 1
								 },
				               'action' => {'format' =>  ['remove_bouncers','notify_bouncers','none'],
								   'default' => 'remove_bouncers',
								   'title_id' => 218,
								   'order' => 2
								   },
					       'notification' => {'format' => ['none','owner','listmaster'],
									 'default' => 'owner',
									 'title_id' => 219,
									 'order' => 3
									 }
								     },
				      'title_id' => 216,
				      'group' => 'bounces'
				  },
	    'clean_delay_queuemod' => {'format' => '\d+',
				       'length' => 3,
				       'unit' => 'days',
				       'default' => {'conf' => 'clean_delay_queuemod'},
				       'title_id' => 10,
				       'group' => 'other'
				       },
	    'cookie' => {'format' => '\S+',
			 'length' => 15,
			 'default' => {'conf' => 'cookie'},
			 'title_id' => 11,
			 'group' => 'other'
		     },
	    'creation' => {'format' => {'date_epoch' => {'format' => '\d+',
							 'occurrence' => '1',
							 'title_id' => 13,
							 'order' => 3
						     },
					'date' => {'format' => '.+',
						   'title_id' => 14,
						   'order' => 2
						   },
					'email' => {'format' => $tools::regexp{'email'},
						    'occurrence' => '1',
						    'title_id' => 15,
						    'order' => 1
						    }
				    },
			   'title_id' => 12,
			   'group' => 'other'

		       },
	    'custom_header' => {'format' => '\S+:\s+.*',
				'length' => 30,
				'occurrence' => '0-n',
				'title_id' => 16,
				'group' => 'sending'
				},
	    'custom_subject' => {'format' => '.+',
				 'length' => 15,
				 'title_id' => 17,
				 'group' => 'sending'
				 },
        'default_user_options' => {'format' => {'reception' => {'format' => ['digest','digestplain','mail','nomail','summary','notice','txt','html','urlize','not_me'],
								    'default' => 'mail',
								    'title_id' => 19,
								    'order' => 1
								    },
						    'visibility' => {'format' => ['conceal','noconceal'],
								     'default' => 'noconceal',
								     'title_id' => 20,
								     'order' => 2
								     }
						},
				       'title_id' => 18,
				       'group' => 'sending'
				   },
	    'del' => {'scenario' => 'del',
		      'title_id' => 21,
		      'group' => 'command'
		      },
	    'digest' => {'file_format' => '\d+(\s*,\s*\d+)*\s+\d+:\d+',
			 'format' => {'days' => {'format' => [0..6],
						 'file_format' => '1|2|3|4|5|6|7',
						 'occurrence' => '1-n',
						 'title_id' => 23,
						 'order' => 1
						 },
				      'hour' => {'format' => '\d+',
						 'length' => 2,
						 'occurrence' => '1',
						 'title_id' => 24,
						 'order' => 2
						 },
				      'minute' => {'format' => '\d+',
						   'length' => 2,
						   'occurrence' => '1',
						   'title_id' => 25,
						   'order' => 3
						   }
				  },
			 'title_id' => 22,
			 'group' => 'sending'
		     },

	    'editor' => {'format' => {'email' => {'format' => $tools::regexp{'email'},
						  'length' => 30,
						  'occurrence' => '1',
						  'title_id' => 27,
						  'order' => 1
						  },
				      'reception' => {'format' => ['mail','nomail'],
						      'default' => 'mail',
						      'title_id' => 28,
						      'order' => 4
						      },
				      'gecos' => {'format' => '.+',
						  'length' => 30,
						  'title_id' => 29,
						  'order' => 2
						  },
				      'info' => {'format' => '.+',
						 'length' => 30,
						 'title_id' => 30,
						 'order' => 3
						 }
				  },
			 'occurrence' => '0-n',
			 'title_id' => 26,
			 'group' => 'description'
			 },
	    'expire_task' => {'task' => 'expire',
			      'title_id' => 95,
			      'group' => 'other'
			 },
	    'footer_type' => {'format' => ['mime','append'],
			      'default' => 'mime',
			      'title_id' => 31,
			      'group' => 'sending'
			      },
	    'forced_reply_to' => {'format' => '\S+',
				  'title_id' => 32,
				  'obsolete' => 1
			 },
	    'host' => {'format' => $tools::regexp{'host'},
		       'length' => 20,
		       'title_id' => 33,
		       'group' => 'description'
		   },
	    'include_file' => {'format' => '\S+',
			       'length' => 20,
			       'occurrence' => '0-n',
			       'title_id' => 34,
			       'group' => 'data_source'
			       },

	    'include_admin' => {'format' => {'list' => {'format' => '\S+',
						        'occurrence' => '1',
							'title_id' => 210,
							'order' => 1
							},
					     'role' => {'format' => ['owners','editors','privileged_owners','listmaster'],
					                'occurrence' => '0-n',
					                'split_char' => ',',
					                'title_id' => 211,
					               }
					 },
				 'occurrence' => '0-n',

				 'name' => {'format' => '.+',
					    'title_id' => 209,
					    'length' => 15,
					    'order' => 1
					   },

				 'group' => 'data_source'
				 },


	    'include_ldap_query' => {'format' => {'host' => {'format' => $tools::regexp{'multiple_host_with_port'},
							     'occurrence' => '1',
							     'title_id' => 36,
							     'order' => 2
							     },
						  'port' => {'format' => '\d+',
							     'default' => 389,
							     'length' => 4,
							     'title_id' => 37,
							     'obsolete' => 1,
							     'order' => 2
							     },
						  'user' => {'format' => '.+',
							     'title_id' => 38,
							     'order' => 3
							     },
						  'passwd' => {'format' => '.+',
							       'length' => 10,
							       'title_id' => 39,
							       'order' => 3
							       },
						  'suffix' => {'format' => '.+',
							       'title_id' => 40,
							       'order' => 4
							       },
						  'filter' => {'format' => '.+',
							       'length' => 50,
							       'occurrence' => '1',
							       'title_id' => 41,
							       'order' => 7
							       },
						  'attrs' => {'format' => '\w+',
							      'length' => 15,
							      'default' => 'mail',
							      'title_id' => 42,
							      'order' => 8
							      },
						  'select' => {'format' => ['all','first'],
							       'default' => 'first',
							       'title_id' => 43,
							       'order' => 9
							       },
					          'scope' => {'format' => ['base','one','sub'],
							      'default' => 'sub',
							      'title_id' => 97,
							      'order' => 5
							      },
						  'timeout' => {'format' => '\w+',
								'default' => 30,
								'unit' => 'seconds',
								'title_id' => 98,
								'order' => 6
								},
						   'name' => {'format' => '.+',
							      'title_id' => 209,
							      'length' => 15,
							      'order' => 1
							      }
					      },
				     'occurrence' => '0-n',
				     'title_id' => 35,
				     'group' => 'data_source'
				     },
	    'include_ldap_2level_query' => {'format' => {'host' => {'format' => $tools::regexp{'multiple_host_with_port'},
							     'occurrence' => '1',
							     'title_id' => 136,
							     'order' => 1
							     },
						  'port' => {'format' => '\d+',
							     'default' => 389,
							     'length' => 4,
							     'title_id' => 137,
							     'obsolete' => 1,
							     'order' => 2
							     },
						  'user' => {'format' => '.+',
							     'title_id' => 138,
							     'order' => 3
							     },
						  'passwd' => {'format' => '.+',
							       'length' => 10,
							       'title_id' => 139,
							       'order' => 3
							       },
						  'suffix1' => {'format' => '.+',
							       'title_id' => 140,
							       'order' => 4
							       },
						  'filter1' => {'format' => '.+',
							       'length' => 50,
							       'occurrence' => '1',
							       'title_id' => 141,
							       'order' => 7
							       },
						  'attrs1' => {'format' => '\w+',
							      'length' => 15,
							      'title_id' => 142,
							      'order' => 8
							      },
						  'select1' => {'format' => ['all','first','regex'],
							       'default' => 'first',
							       'title_id' => 143,
							       'order' => 9
							       },
					          'scope1' => {'format' => ['base','one','sub'],
							      'default' => 'sub',
							      'title_id' => 197,
							      'order' => 5
							      },
						  'timeout1' => {'format' => '\w+',
								'default' => 30,
								'unit' => 'seconds',
								'title_id' => 198,
								'order' => 6
								},
						  'regex1' => {'format' => '.+',
								'length' => 50,
								'default' => '',
								'title_id' => 201,
								'order' => 10
								},
						  'suffix2' => {'format' => '.+',
							       'title_id' => 144,
							       'order' => 11
							       },
						  'filter2' => {'format' => '.+',
							       'length' => 50,
							       'occurrence' => '1',
							       'title_id' => 145,
							       'order' => 14
							       },
						  'attrs2' => {'format' => '\w+',
							      'length' => 15,
							      'default' => 'mail',
							      'title_id' => 146,
							      'order' => 15
							      },
						  'select2' => {'format' => ['all','first','regex'],
							       'default' => 'first',
							       'title_id' => 147,
							       'order' => 16
							       },
					          'scope2' => {'format' => ['base','one','sub'],
							      'default' => 'sub',
							      'title_id' => 199,
							      'order' => 12
							      },
						  'timeout2' => {'format' => '\w+',
								'default' => 30,
								'unit' => 'seconds',
								'title_id' => 200,
								'order' => 13
								},
						  'regex2' => {'format' => '.+',
								'length' => 50,
								'default' => '',
								'title_id' => 202,
								'order' => 17
								},
						   'name' => {'format' => '.+',
							      'title_id' => 209,
							      'length' => 15,
							      'order' => 1
							      }

					      },
				     'occurrence' => '0-n',
				     'title_id' => 135,
				     'group' => 'data_source'
				     },
	    'include_list' => {'format' => $tools::regexp{'listname'},
			       'occurrence' => '0-n',
			       'title_id' => 44,
			       'group' => 'data_source'
			       },
	    'include_remote_sympa_list' => {'format' => {'host' => {'format' => $tools::regexp{'host'},
							    'occurrence' => '1',
							    'title_id' => 136,
							    'order' => 1
							    },
							 'port' => {'format' => '\d+',
							     'default' => 443,
							     'length' => 4,
							     'title_id' => 137,
							     'order' => 2
							     },
							 'path' => {'format' => '\S+',
			                                     'length' => 20,
			                                     'occurrence' => '1',
			                                     'title_id' => 207,
							     'order' => 3 

			                                     },
                                                         'cert' => {'format' => ['robot','list'],
							           'title_id' => 208,
								   'default' => 'list',
								    'order' => 4
								    },
							   'name' => {'format' => '.+',
								      'title_id' => 209,
								      'length' => 15,
								      'order' => 1
								      }
					},

			       'occurrence' => '0-n',
			       'title_id' => 206,
			       'group' => 'data_source'
			       },
	    'include_sql_query' => {'format' => {'db_type' => {'format' => '\S+',
							       'occurrence' => '1',
							       'title_id' => 46,
							       'order' => 1
							       },
						 'host' => {'format' => $tools::regexp{'host'},
							    'occurrence' => '1',
							    'title_id' => 47,
							    'order' => 2
							    },
						 'db_name' => {'format' => '\S+',
							       'occurrence' => '1',
							       'title_id' => 48,
							       'order' => 3 
							       },
						 'connect_options' => {'format' => '.+',
								       'title_id' => 94,
								       'order' => 4
								       },
						 'db_env' => {'format' => '\w+\=\S+(;\w+\=\S+)*',
							      'order' => 5,
							      'title_id' => 148
							      },
						 'user' => {'format' => '\S+',
							    'occurrence' => '1',
							    'title_id' => 49,
							    'order' => 6
							    },
						 'passwd' => {'format' => '.+',
							      'title_id' => 50,
							      'order' => 7
							      },
						 'sql_query' => {'format' => $tools::regexp{'sql_query'},
								 'length' => 50,
								 'occurrence' => '1',
								 'title_id' => 51,
								 'order' => 8
								 },
						  'f_dir' => {'format' => '.+',
							     'title_id' => 52,
							     'order' => 9
							     },
						  'name' => {'format' => '.+',
							     'title_id' => 209,
							     'length' => 15,
							     'order' => 1
							     }
						 
					     },
				    'occurrence' => '0-n',
				    'title_id' => 45,
				    'group' => 'data_source'
				    },
	    'info' => {'scenario' => 'info',
		       'title_id' => 53,
		       'group' => 'command'
		       },
	    'invite' => {'scenario' => 'invite',
			 'title_id' => 54,
			 'group' => 'command'
			 },
	    'lang' => {'format' => ['fr','us','de','it','fi','es','tw','cn','pl','cz','hu','ro','et','nl'],
		       'default' => {'conf' => 'lang'},
		       'title_id' => 55,
		       'group' => 'description'
		   },
	    'max_size' => {'format' => '\d+',
			   'length' => 8,
			   'unit' => 'bytes',
			   'default' => {'conf' => 'max_size'},
			   'title_id' => 56,
			   'group' => 'sending'
		       },
	    'owner' => {'format' => {'email' => {'format' => $tools::regexp{'email'},
						 'length' =>30,
						 'occurrence' => '1',
						 'title_id' => 58,
						 'order' => 1
						 },
				     'reception' => {'format' => ['mail','nomail'],
						     'default' => 'mail',
						     'title_id' => 59,
						     'order' =>5
						     },
				     'gecos' => {'format' => '.+',
						 'length' => 30,
						 'title_id' => 60,
						 'order' => 2
						 },
				     'info' => {'format' => '.+',
						'length' => 30,
						'title_id' => 61,
						'order' => 3
						},
				     'profile' => {'format' => ['privileged','normal'],
						   'default' => 'normal',
						   'title_id' => 62,
						   'order' => 4
						   }
				 },
			'occurrence' => '1-n',
			'title_id' => 57,
			'group' => 'description'
			},
	    'priority' => {'format' => [0..9,'z'],
			   'length' => 1,
			   'default' => {'conf' => 'default_list_priority'},
			   'title_id' => 63,
			   'group' => 'description'
		       },
	    'remind' => {'scenario' => 'remind',
			 'title_id' => 64,
			 'group' => 'command'
			  },
	    'remind_return_path' => {'format' => ['unique','owner'],
				     'default' => {'conf' => 'remind_return_path'},
				     'title_id' => 65,
				     'group' => 'bounces'
				 },
	    'remind_task' => {'task' => 'remind',
			      'tilte-id' => 96,
			      'group' => 'other'
			      },
	    'reply_to' => {'format' => '\S+',
			   'default' => 'sender',
			   'title_id' => 66,
			   'group' => 'sending',
			   'obsolete' => 1
			   },
	    'reply_to_header' => {'format' => {'value' => {'format' => ['sender','list','all','other_email'],
							   'default' => 'sender',
							   'title_id' => 91,
							   'occurrence' => '1',
							   'order' => 1
							   },
					       'other_email' => {'format' => $tools::regexp{'email'},
								 'title_id' => 92,
								 'order' => 2
								 },
					       'apply' => {'format' => ['forced','respect'],
							   'default' => 'respect',
							   'title_id' => 93,
							   'order' => 3
							   }
					   },
				  'title_id' => 90,
				  'group' => 'sending'
				  },		
	    'review' => {'scenario' => 'review',
			 'synonym' => {'open' => 'public'},
			 'title_id' => 67,
			 'group' => 'command'
			 },
	    'rfc2369_header_fields' => {'format' => ['help','subscribe','unsubscribe','post','owner','archive'],
					'default' => {'conf' => 'rfc2369_header_fields'},
					'occurrence' => '0-n',
					'split_char' => ',',
					'title_id' => 213,
					'group' => 'sending'
					},
	    'send' => {'scenario' => 'send',
		       'title_id' => 68,
		       'group' => 'sending'
		       },
	    'serial' => {'format' => '\d+',
			 'default' => 0,
			 'length' => 3,
			 'default' => 0,
			 'title_id' => 69,
			 'group' => 'other'
			 },
	    'shared_doc' => {'format' => {'d_read' => {'scenario' => 'd_read',
						       'title_id' => 86,
						       'order' => 1
						       },
					  'd_edit' => {'scenario' => 'd_edit',
						       'title_id' => 87,
						       'order' => 2
						       },
					  'quota' => {'format' => '\d+',
						      'default' => {'conf' => 'default_shared_quota'},
						      'length' => 8,
						      'unit' => 'Kbytes',
						      'title_id' => 203,
						      'order' => 3
						      }
				      },
			     'title_id' => 70,
			     'group' => 'command'
			 },
	    'spam_protection' => {'format' => ['at','javascript','none'],
			 'default' => 'javascript',
			 'title_id' => 205,
			 'group' => 'other'
			  },
	    'web_archive_spam_protection' => {'format' => ['cookie','javascript','at','none'],
			 'default' => {'conf' => 'web_archive_spam_protection'},
			 'title_id' => 205,
			 'group' => 'other'
			  },

	    'status' => {'format' => ['open','closed','pending'],
			 'default' => 'open',
			 'title_id' => 71,
			 'group' => 'other'
			  },
	    'subject' => {'format' => '.+',
			  'length' => 50,
			  'occurrence' => '1',
			  'title_id' => 72,
			  'group' => 'description'
			   },
	    'subscribe' => {'scenario' => 'subscribe',
			    'title_id' => 73,
			    'group' => 'command'
			    },
	    'topics' => {'format' => '\w+(\/\w+)?',
			 'split_char' => ',',
			 'occurrence' => '0-n',
			 'title_id' => 74,
			 'group' => 'description'
			 },
	    'ttl' => {'format' => '\d+',
		      'length' => 6,
		      'unit' => 'seconds',
		      'default' => 3600,
		      'title_id' => 75,
		      'group' => 'data_source'
		      },
	    'unsubscribe' => {'scenario' => 'unsubscribe',
			      'title_id' => 76,
			      'group' => 'command'
			      },
	    'update' => {'format' => {'date_epoch' => {'format' => '\d+',
						       'length' => 8,
						       'occurrence' => '1',
						       'title_id' => 78,
						       'order' => 3
						       },
				      'date' => {'format' => '.+',
						 'length' => 30,
						 'title_id' => 79,
						 'order' => 2
						 },
				      'email' => {'format' => $tools::regexp{'email'},
						  'length' => 30,
						  'occurrence' => '1',
						  'title_id' => 80,
						  'order' => 1
						  }
				  },
			 'title_id' => 77,
			 'group' => 'other'
		     },
	    'user_data_source' => {'format' => ['database','file','include','include2'],
				   'default' => 'include2',
				   'title_id' => 81,
				   'group' => 'data_source'
				   },
	    'visibility' => {'scenario' => 'visibility',
			     'synonym' => {'public' => 'noconceal',
					   'private' => 'conceal'},
			     'title_id' => 82,
			     'group' => 'description'
			     },
	    'web_archive'  => {'format' => {'access' => {'scenario' => 'access_web_archive',
							 'title_id' => 84,
							 'order' => 1
							 },
					    'quota' => {'format' => '\d+',
							'default' => {'conf' => 'default_archive_quota'},
							'length' => 8,
							'unit' => 'Kbytes',
							'title_id' => 204,
							'order' => 2
							}
					},
			       
			       'title_id' => 83,
			       'group' => 'archives'

			   },
	    'welcome_return_path' => {'format' => ['unique','owner'],
				      'default' => {'conf' => 'welcome_return_path'},
				      'title_id' => 85,
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
    foreach my $db_param ('db_type','db_name','db_host','db_user') {
	unless ($Conf{$db_param}) {
	    do_log('info','Missing parameter %s for DBI connection', $db_param);
	    return undef;
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

	&send_notify_to_listmaster('no_db', $Conf{'domain'});

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
	&send_notify_to_listmaster('db_restored', $Conf{'domain'});

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
    my($pkg, $name, $robot) = @_;
    my $liste={};
    do_log('debug2', 'List::new(%s,%s)', $name, $robot);
    
    ## Allow robot in the name
    if ($name =~ /\@/) {
	my @parts = split /\@/, $name;
	$robot ||= $parts[1];
	$name = $parts[0];
    }

    ## Only process the list if the name is valid.
    unless ($name and ($name =~ /^$tools::regexp{'listname'}$/io) ) {
	&do_log('err', 'Incorrect listname "%s"',  $name);
	return undef;
    }
    ## Lowercase the list name.
    $name =~ tr/A-Z/a-z/;
    
    ## Reject listnames with reserved list suffixes
    my $regx = &Conf::get_robot_conf($robot,'list_check_regexp');
    if ( $regx ) {
	if ($name =~ /^(\S+)-($regx)$/) {
	    &do_log('err', 'Incorrect name: listname "%s" matches one of service aliases',  $name);
	    return undef;
	}
    }

    if ($list_of_lists{$name}){
	# use the current list in memory and update it
	$liste=$list_of_lists{$name};
    }else{
	# create a new object list
	bless $liste, $pkg;
    }
    return undef unless ($liste->load($name, $robot));

    return $liste;
}

## Saves the statistics data to disk.
sub savestats {
    my $self = shift;
    do_log('debug2', 'List::savestats');
   
    ## Be sure the list has been loaded.
    my $name = $self->{'name'};
    my $dir = $self->{'dir'};
    return undef unless ($list_of_lists{$name});
    
   _save_stats_file("$dir/stats", $self->{'stats'}, $self->{'total'}, $self->{'last_sync'});
    
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

## Dumps a copy of lists to disk, in text format
sub dump {
    my @listnames = @_;
    do_log('debug2', 'List::dump(%s)', @listnames);

    my $done;

    foreach my $l (@listnames) {
	
	my $list = new List($l);
	
	unless (defined $list) {
	    &do_log('err','Unknown list %s', $l);
	    next;
	}

	my $user_file_name = "$list->{'dir'}/subscribers.db.dump";
	do_log('debug3', 'Dumping list %s',$l);	
	unless ($list->_save_users_file($user_file_name)) {
	    &do_log('err', 'Failed to save file %s', $user_file_name);
	    next;
	}
	$list->{'mtime'} = [ (stat("$list->{'dir'}/config"))[9], (stat("$list->{'dir'}/subscribers"))[9], (stat("$list->{'dir'}/stats"))[9] ];

	$done++
    }
    return $done;
}

## Saves a copy of the list to disk. Does not remove the
## data.
sub save {
    my $self = shift;
    do_log('debug3', 'List::save');

    my $name = $self->{'name'};    
 
    return undef 
	unless ($list_of_lists{$name});
 
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
    do_log('debug3', 'List::save_config()');

    my $name = $self->{'name'};    
    my $old_serial = $self->{'admin'}{'serial'};
    my $config_file_name = "$self->{'dir'}/config";
    my $old_config_file_name = "$self->{'dir'}/config.$old_serial";

    return undef 
	unless ($list_of_lists{$name});
 
    ## Update management info
    $self->{'admin'}{'serial'}++;
    $self->{'admin'}{'defaults'}{'serial'} = 0;
    $self->{'admin'}{'update'} = {'email' => $email,
				  'date_epoch' => time,
				  'date' => &POSIX::strftime("%d %b %Y at %H:%M:%S", localtime(time))
				  };
    $self->{'admin'}{'defaults'}{'update'} = 0;
    
    unless (&_save_admin_file($config_file_name, $old_config_file_name, $self->{'admin'})) {
	&do_log('info', 'unable to save config file %s', $config_file_name);
	return undef;
    }
#    $self->{'mtime'}[0] = (stat("$list->{'dir'}/config"))[9];
    
    return 1;
}

## Loads the administrative data for a list
sub load {
    my ($self, $name, $robot) = @_;
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
	&do_log('err', 'No such list %s', $name);
	return undef ;
    }
    
    $self->{'domain'} = $robot ;
    unless ((-d $self->{'dir'}) && (-f "$self->{'dir'}/config")) {
	&do_log('info', 'Missing directory (%s) or config file for %s', $self->{'dir'}, $name);
	return undef ;
    }

    $self->{'name'}  = $name ;

    my ($m1, $m2, $m3) = (0, 0, 0);
    ($m1, $m2, $m3) = @{$self->{'mtime'}} if (defined $self->{'mtime'});

    my $time_config = (stat("$self->{'dir'}/config"))[9];
    my $time_subscribers; 
    my $time_stats = (stat("$self->{'dir'}/stats"))[9];
    
    my $admin;
    
    if ($self->{'name'} ne $name || $time_config > $self->{'mtime'}->[0]) {
	$admin = _load_admin_file($self->{'dir'}, $self->{'domain'}, 'config');
	$m1 = $time_config;
    }
    
    $self->{'admin'} = $admin if ($admin);

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
	unless ( defined $self->{'admin'}{'include_file'}
		 || defined $self->{'admin'}{'include_list'}
		 || defined $self->{'admin'}{'include_remote_sympa_list'}
		 || defined $self->{'admin'}{'include_sql_query'}
		 || defined $self->{'admin'}{'include_ldap_query'}
		 || defined $self->{'admin'}{'include_ldap_2level_query'}
		 || defined $self->{'admin'}{'include_admin'}
		 ) {
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
	    
	    $users = _load_users_include($name, $self->{'admin'}, $self->{'dir'}, "$self->{'dir'}/subscribers.db", 0);
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
	    $users = _load_users_include($name, $self->{'admin'}, $self->{'dir'}, "$self->{'dir'}/subscribers.db", 1);

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
	($stats, $total, $self->{'last_sync'}) = _load_stats_file("$self->{'dir'}/stats");
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

    $self->{'mtime'} = [ $m1, $m2, $m3 ];

    $list_of_lists{$name} = $self;
    return $self;
}

## Returns an array of owners' email addresses (unless reception nomail)
sub get_owners_email {
    my($self) = @_;
    do_log('debug3', 'List::get_owners_email(%s)', $self->{'name'});
    
    my ($i, @rcpt);
    my $admin = $self->{'admin'}; 
    my $name = $self->{'name'};

    foreach $i (@{$admin->{'owner'}}) {
	next if ($i->{'reception'} eq 'nomail');
	if (ref($i->{'email'})) {
	    push(@rcpt, @{$i->{'email'}});
	}elsif ($i->{'email'}) {
	    push(@rcpt, $i->{'email'});
	}
    }

    return @rcpt;
}

## Returns an array of editors' email addresses (unless reception nomail)
#  or owners if there isn't any editors'email adress
sub get_editors_email {
    my($self) = @_;
    do_log('debug3', 'List::get_editors_email(%s)', $self->{'name'});
    
    my ($i, @rcpt);
    my $admin = $self->{'admin'}; 
    my $name = $self->{'name'};

    foreach $i (@{$admin->{'editor'}}) {
	next if ($i->{'reception'} eq 'nomail');
	if (ref($i->{'email'})) {
	    push(@rcpt, @{$i->{'email'}});
	}elsif ($i->{'email'}) {
	    push(@rcpt, $i->{'email'});
	}
    }

    if ($#rcpt < 0) {
	return &get_owners_email($self);
    }

    return @rcpt;

}



## Send a sub/sig notice to listmasters.
sub send_notify_to_listmaster {

    my ($operation, $robot, @param) = @_;
    do_log('debug2', 'List::send_notify_to_listmaster(%s,%s )', $operation, $robot );

    my $sympa = &Conf::get_robot_conf($robot, 'sympa');

    ## No DataBase
    if ($operation eq 'no_db') {
        my $body = "Cannot connect to database $Conf{'db_name'}, still trying..." ; 
	my $to = sprintf "Listmaster <%s>", $Conf{'listmaster'};
	mail::mailback (\$body, {'Subject' => 'No DataBase'}, 'sympa', $to, $robot, $Conf{'listmaster'});

    ## DataBase restored
    }elsif ($operation eq 'db_restored') {
        my $body = "Connection to database $Conf{'db_name'} restored." ; 
	my $to = sprintf "Listmaster <%s>", $Conf{'listmaster'};
	mail::mailback (\$body, {'Subject' => 'DataBase connection restored'}, 'sympa', $to, $robot, $Conf{'listmaster'});

    ## creation list requested
    }elsif ($operation eq 'request_list_creation') {
	my $list = new List $param[0];
	unless (defined $list) {
	    &do_log('err','Parameter %s is not a valid list', $param[0]);
	    return undef;
	}
	my $host = &Conf::get_robot_conf($robot, 'host');

	$list->send_file('listmaster_notification', &Conf::get_robot_conf($robot, 'listmaster'), $robot,
			 {'to' => "listmaster\@$host",
			  'type' => 'request_list_creation',
			  'email' => $param[1]});

    ## Loop detected in Sympa
    }elsif ($operation eq 'loop_command') {
	my $file = $param[0];

	my $notice = build MIME::Entity (From => $sympa,
					 To => $Conf{'listmaster'},
					 Subject => 'Loop detected',
					 Data => 'A loop has been detected with the following message');

	$notice->attach(Path => $file,
			Type => 'message/rfc822');

	## Send message
	my $rcpt = $Conf{'listmaster'};
	*FH = &smtp::smtpto($Conf{'request'}, \$rcpt);
	$notice->print(\*FH);
	close FH;
    #Virus scan failed
    }elsif ($operation eq 'virus_scan_failed') {
	&send_global_file('listmaster_notification', $Conf{'listmaster'}, $robot,
			 {'to' => "listmaster\@$Conf{'host'}",
			  'type' => 'virus_scan_failed',
			  'filename' => $param[0],
			  'error_msg' => $param[1]});	
     
    # Automatic action done on bouncing adresses
    }elsif ($operation eq 'automatic_bounce_management') {
	my $list = new List $param[0];
	my $host = &Conf::get_robot_conf($robot, 'host');


	$list->send_file('listmaster_notification',&Conf::get_robot_conf($robot, 'listmaster'), $robot,
			  {'to' => "listmaster\@$host",
			   'type' => 'automatic_bounce_management',
			   'action' => $param[1],
			   'user_list' => $param[2],
			   'total' => $#{$param[2]} + 1});		

    }else {
	my $data = {'to' => "listmaster\@$Conf{'host'}",
		 'type' => $operation
		 };
	
	for my $i(0..$#param) {
	    $data->{"param$i"} = $param[$i];
	}

	&send_global_file('listmaster_notification', $Conf{'listmaster'}, $robot, $data);
    }
    
    return 1;
}
 
## Send a sub/sig notice to the owners.
sub send_notify_to_owner {
    my ($self, $param) = @_;
    do_log('debug3', 'List::send_notify_to_owner(%s, %s, %s, %s)', $self->{'name'}, $param->{'type'});
    
    my ($i, @rcpt);
    my $admin = $self->{'admin'}; 
    my $name = $self->{'name'};
    my $host = $admin->{'host'};

    return undef unless ($name && $admin);
    
    @rcpt = $self->get_owners_email();

    unless (@rcpt) {
	do_log('notice', 'Warning : no owner defined or  all of them use nomail option in list %s', $name );
	return undef;
    }

    ## Use list lang
    &Language::SetLang($self->{'admin'}{'lang'});

    my $to = sprintf (Msg(8, 1, "Owners of list %s :"), $name)." <$name-request\@$host>";

    if ($param->{'type'} eq 'warn-signoff') {
	my ($body, $subject);
	$subject = sprintf (Msg(8, 21, "WARNING: %s list %s from %s %s"), $param->{'type'}, $name, $param->{'who'}, $param->{'gecos'});
	$body = sprintf (Msg(8, 23, "WARNING : %s %s failed to signoff from %s\nbecause his address was not found in the list\n (You may help this person)\n"),$param->{'who'}, $param->{'gecos'}, $name);
	&mail::mailback (\$body, {'Subject' => $subject}, 'sympa', $to, $self->{'domain'}, @rcpt);
    }elsif ($param->{'type'} eq 'subrequest') {
	## Replace \s by %20 in email
	my $escaped_gecos = $param->{'gecos'};
	$escaped_gecos =~ s/\s/\%20/g;
	my $escaped_who = $param->{'who'};
	$escaped_who =~ s/\s/\%20/g;

	my $subject = sprintf(Msg(8, 2, "%s subscription request"), $name);
	my $to = sprintf (Msg(8, 1, "Owners of list %s :"), $name)." <$name-request\@$host>";
	my $body = sprintf Msg(8, 3, $msg::sub_owner), $name, $param->{'replyto'}, $param->{'keyauth'}, $name, $escaped_who, $escaped_gecos, $param->{'replyto'}, $param->{'keyauth'}, $name, $param->{'who'}, $param->{'gecos'};
	&mail::mailback (\$body, {'Subject' => $subject}, 'sympa', $to, $self->{'domain'}, @rcpt);

    }elsif ($param->{'type'} eq 'sigrequest') {
	my $sympa = &Conf::get_robot_conf($self->{'domain'}, 'sympa');
	
	## Replace \s by %20 in email
	my $escaped_who = $param->{'who'};
	$escaped_who =~ s/\s/\%20/g;

	my $subject = sprintf(Msg(8, 24, "%s UNsubscription request"), $name);
	my $to = sprintf (Msg(8, 1, "Owners of list %s :"), $name)." <$name-request\@$host>";
	my $body = sprintf Msg(8, 25, $msg::sig_owner), $name, $sympa, $param->{'keyauth'}, $name, $escaped_who, $sympa, $param->{'keyauth'}, $name, $param->{'who'};
	&mail::mailback (\$body, {'Subject' => $subject}, 'sympa', $to, $self->{'domain'}, @rcpt);

    }elsif ($param->{'type'} eq 'bounce_rate') {
	my $rate = int ($param->{'rate'} * 10) / 10;

        my $subject = sprintf(Msg(8, 28, "WARNING: bounce rate too high in list %s"), $name);
        my $body = sprintf Msg(8, 27, "Bounce rate in list %s is %d%%.\nYou should delete bouncing subscribers : %s/reviewbouncing/%s"), $name, $rate, &Conf::get_robot_conf($self->{'domain'}, 'wwsympa_url'), $name ;
        &mail::mailback (\$body, {'Subject' => $subject}, 'sympa', $to, $self->{'domain'}, @rcpt);

    }elsif ($param->{'type'} eq 'automatic_bounce_management') {

	my $subject = 'Automatic bounce management';
	my $body = $param->{'body'};
	&mail::mailback (\$body, {'Subject' => $subject}, 'sympa', $to, $self->{'domain'}, @rcpt);

    }elsif ($param->{'who'}) {
	my ($body, $subject);
	$subject = sprintf(Msg(8, 21, "FYI: %s list %s from %s %s"), $param->{'type'}, $name, $param->{'who'}, $param->{'gecos'});
	if ($param->{'by'}) {
	    $body = sprintf Msg(8, 26, "FYI command %s list %s from %s %s validated by %s\n (no action needed)\n"),$param->{'type'}, $name, $param->{'who'}, $param->{'gecos'}, $param->{'by'};
	}else {
	    $body = sprintf Msg(8, 22, "FYI command %s list %s from %s %s \n (no action needed)\n"),$param->{'type'}, $name, $param->{'who'}, $param->{'gecos'} ;
	}
	&mail::mailback (\$body, {'Subject' => $subject}, 'sympa', $to,$self->{'domain'}, @rcpt);

    }else {
	$self->send_file('listowner_notification', join(',', @rcpt), $param->{'robot'}, $param);
	
    }
    
}

sub new_send_notify_to_owner {
    
    my ($self,$operation,@param) = @_;

    &do_log('debug2', 'List::(new_)send_notify_to_owner(%s, %s)', $self->{'name'}, $operation);

    my $host = $self->{'admin'}->{'host'};
    my @to = $self->get_owners_email;
    my $robot = $self->{'domain'};

    unless (@to) {
	do_log('notice', 'Warning : no owner defined or all of them use nomail option in list %s', $self->{'name'} );
	return undef;
    }

    if ($operation eq 'automatic_bounce_management') {
	
	$self->send_file('listowner_notification',\@to, $robot,
			 {'type' => 'automatic_bounce_management',
			  'action' => $param[1],
			  'user_list' => $param[2],
			  'total' => $#{$param[2]} + 1
			 });		
    }
    return 1;
}

## Send a sub/sig notice to the editors (or owners if there isn't any editors).
sub send_notify_to_editor {

    my ($self,$operation,@param) = @_;

    &do_log('debug2', 'List::send_notify_to_editor(%s, %s)', $self->{'name'}, $operation);

    my @to = $self->get_editors_email();

    unless (@to) {
	do_log('notice', 'Warning : no editor or owner defined or all of them use nomail option in list %s', $self->{'name'} );
	return undef;
    }
    if ($operation eq 'shared_moderated') {
	$self->send_file('listeditor_notification',\@to, $self->{'domain'},
			 {'type' => 'shared_moderated',
			  'filename' => $param[0],
			  'who' => $param[1],
			  'address_interface' => $param[2]});
    }
    return 1;
}


sub send_notify_to_subscriber{

    my ($self,$operation,$who,@param) = @_;

    &do_log('debug2', 'List::send_notify_to_subscriber(%s, %s)', $self->{'name'}, $operation);

    my $host = $self->{'admin'}->{'host'};
    my $robot = $self->{'domain'};

     if ($operation eq 'auto_notify_bouncers') {	
	 $self->send_file('subscriber_notification',$who, $robot,
			  {'to' => "$who",
			   'type' => 'auto_notify_bouncers',
		       });			       		
	 
     }
    return 1;
}

## Send a notification to authors of messages sent to editors
sub notify_sender{
   my($self, $sender) = @_;
   do_log('debug3', 'List::notify_sender(%s)', $sender);

   my $admin = $self->{'admin'}; 
   my $name = $self->{'name'};
   return unless ($name && $admin && $sender);

   my $subject = sprintf Msg(4, 40, 'Moderating your message');
   my $body = sprintf Msg(4, 38, "Your message for list %s has been forwarded to editor(s)\n"), $name;
   &mail::mailback (\$body, {'Subject' => $subject}, 'sympa', $sender, $self->{'domain'}, $sender);
}

## Send a message to the editor
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
       unless (open(OUT, ">$modqueue\/$name\_$modkey")) {
	   do_log('notice', 'Could Not open %s', "$modqueue\/$name\_$modkey");
	   return undef;
       }

       unless (open (MSG, $file)) {
	   do_log('notice', 'Could not open %s', $file);
	   return undef;   
       }

       print OUT <MSG>;
       close MSG ;
       close(OUT);

       my $tmp_dir = "$modqueue\/.$name\_$modkey";
       unless (-d $tmp_dir) {
	   unless (mkdir ($tmp_dir, 0777)) {
	       &error_message('may_not_create_dir');
	       &do_log('info','do_viewmod: unable to create %s', $tmp_dir);
	       return undef;
	   }
	   my $mhonarc_ressources = &tools::get_filename('etc', 'mhonarc-ressources', $robot, $self);
	   unless ($mhonarc_ressources) {
	       do_log('notice',"Cannot find any MhOnArc ressource file");
	       return undef;
	   }

	   ## generate HTML
	   chdir $tmp_dir;
	   my $mhonarc = &Conf::get_robot_conf($robot, 'mhonarc');
	   open ARCMOD, "$mhonarc  -single -rcfile $mhonarc_ressources -definevars listname=$name -definevars hostname=$host $modqueue/$name\_$modkey|";
	   open MSG, ">msg00000.html";
	   &do_log('debug4', "$mhonarc  -single -rcfile $mhonarc_ressources -definevars listname=$name -definevars hostname=$host $modqueue/$name\_$modkey");
	   print MSG <ARCMOD>;
	   close MSG;
	   close ARCMOD;
	   chdir $Conf{'home'};
       }
   }
   foreach $i (@{$admin->{'editor'}}) {
      next if ($i->{'reception'} eq 'nomail');
      push(@rcpt, $i->{'email'}) if ($i->{'email'});
   }
   unless (@rcpt) {
       @rcpt = $self->get_owners_email();

       do_log('notice','Warning : no editor defined for list %s, contacting owners', $name );
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

	   my $crypted_file = "$Conf{'tmpdir'}/$name.moderate.$$";
	   unless (open CRYPTED, ">$crypted_file") {
	       &do_log('notice', 'Could not create file %s', $crypted_file);
	       return undef;
	   }
	   print CRYPTED $cryptedmsg;
	   close CRYPTED;
	   
	   $self->send_file('moderate', $recipient, $self->{'domain'}, {'modkey' => $modkey,
									'boundary' => $boundary,
									'msg' => $crypted_file,
									'method' => $method,
									## From the list because it is signed
									'from' => $self->{'name'}.'@'.$self->{'domain'}
									});
       }
   }else{
       $self->send_file('moderate', \@rcpt, $self->{'domain'}, {'modkey' => $modkey,
								'boundary' => $boundary,
								'msg' => $file,
								'method' => $method,
								'from' => &Conf::get_robot_conf($robot, 'sympa')
								});
   }
   return $modkey;
}

## Send an authentication message
sub send_auth {
   my($self, $message) = @_;
   my ($sender, $msg, $file) = ($message->{'sender'}, $message->{'msg'}, $message->{'filename'});
   do_log('debug3', 'List::send_auth(%s, %s)', $sender, $file);

   ## Ensure 1 second elapsed since last message
   sleep (1);

   my($i, @rcpt);
   my $admin = $self->{'admin'};
   my $name = $self->{'name'};
   my $host = $admin->{'host'};
   my $robot = $self->{'domain'};
   my $authqueue = $Conf{'queueauth'};
   return undef unless ($name && $admin);
  
   my $sympa = &Conf::get_robot_conf($robot, 'sympa');

   my @now = localtime(time);
   my $messageid = $now[6].$now[5].$now[4].$now[3].$now[2].$now[1]."."
                   .int(rand(6)).int(rand(6)).int(rand(6)).int(rand(6))
		   .int(rand(6)).int(rand(6))."\@".$host;
   my $modkey = Digest::MD5::md5_hex(join('/', $self->get_cookie(),$messageid));
   my $boundary = "----------------- Message-Id: \<$messageid\>" ;
   my $contenttype = "Content-Type: message\/rfc822";
     
   unless (open OUT, ">$authqueue\/$name\_$modkey") {
       &do_log('notice', 'Cannot create file %s', "$authqueue/$name/$modkey");
       return undef;
   }

   unless (open IN, $file) {
       &do_log('notice', 'Cannot open file %s', $file);
       return undef;
   }
   
   print OUT <IN>;

   close IN; close OUT;
 
   my $hdr = new Mail::Header;
   $hdr->add('From', sprintf Msg(12, 4, 'SYMPA <%s>'), $sympa);
   $hdr->add('To', $sender );
#   $hdr->add('Subject', Msg(8, 16, "Authentication needed"));
   $hdr->add('Subject', "confirm $modkey");
   $hdr->add('MIME-Version', "1.0");
   $hdr->add('Content-Type',"multipart/mixed; boundary=\"$boundary\"") ;
   $hdr->add('Content-Transfert-Encoding', "8bit");
   
   *DESC = smtp::smtpto(&Conf::get_robot_conf($robot, 'request'), \$sender);
   $hdr->print(\*DESC);
   print DESC "\n";
   print DESC "--$boundary\n";
   print DESC "Content-Type: text/plain\n\n";
   printf DESC Msg(8, 12,"In order to broadcast the following message into list %s, either click on this link:\nmailto:%s?subject=CONFIRM%%20%s\nOr reply to %s with this subject :\nCONFIRM %s"), $name, $sympa, $modkey, $sympa, $modkey;
   print DESC "--$boundary\n";
   print DESC "Content-Type: message/rfc822\n\n";
   
   unless (open IN, $file) {
       &do_log('notice', 'Cannot open file %s', $file);
       return undef;
   }
   while (<IN>) {
       print DESC <IN>;
   }
   close IN;

   print DESC "--$boundary--\n";

   close(DESC);

   return $modkey;
}

## Distribute a message to the list
sub distribute_msg {
    my($self, $message) = @_;
    do_log('debug2', 'List::distribute_msg(%s, %s, %s, %s, %s)', $self->{'name'}, $message->{'msg'}, $message->{'size'}, $message->{'filename'}, $message->{'smime_crypted'});

    my $hdr = $message->{'msg'}->head;
    my ($name, $host) = ($self->{'name'}, $self->{'admin'}{'host'});
    my $robot = $self->{'domain'};

    ## Update the stats, and returns the new X-Sequence, if any.
    my $sequence = $self->update_stats($message->{'size'});
    
    ## Hide the sender if the list is anonymoused
    if ( $self->{'admin'}{'anonymous_sender'} ) {
	foreach my $field (@{$Conf{'anonymous_header_fields'}}) {
	    $hdr->delete($field);
	}
	
	$hdr->add('From',"$self->{'admin'}{'anonymous_sender'}");
	$hdr->add('Message-id',"<$self->{'name'}.$sequence\@anonymous>");

	## xxxxxx Virer eventuelle signature S/MIME
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
    $hdr->add('Errors-to', "$name-owner\@$host");
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
		$hdr->add('List-Archive', sprintf ('<%s/arc/%s>', Conf::get_robot_conf($robot, 'wwsympa_url'), $self->{'name'}));
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

## Send a message to the list
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
	    $self->send_notify_to_owner({'type' => 'bounce_rate',
					 'rate' => $rate});
	}
    }

    ## Add Custom Subject
    if ($admin->{'custom_subject'}) {
	my $subject_field = &MIME::Words::decode_mimewords($message->{'msg'}->head->get('Subject'));
	$subject_field =~ s/^\s*(.*)\s*$/$1/; ## Remove leading and trailing blanks

	## Search previous subject tagging in Subject
	my $tag_regexp = $admin->{'custom_subject'};
	$tag_regexp =~ s/([\[\]\*\-\(\)\+\{\}\?])/\\$1/g;  ## cleanup, just in case dangerous chars were left
	$tag_regexp =~ s/\[\S+\]/\.\+/g;

	## Add subject tag
	$message->{'msg'}->head->delete('Subject');
	my @parsed_tag;
	&parser::parse_tpl({'list' => {'name' => $self->{'name'},
			       'sequence' => $self->{'stats'}->[0]
			       }},
		   [$admin->{'custom_subject'}], \@parsed_tag);

	## If subject is tagged, replace it with new tag
	if ($subject_field =~ /\[$tag_regexp\]/) {
	    $subject_field =~ s/\[$tag_regexp\]/\[$parsed_tag[0]\]/;
	}else {
	    $subject_field = '['.$parsed_tag[0].'] '.$subject_field
	}
	$message->{'msg'}->head->add('Subject', $subject_field);
    }
 
    ## Who is the enveloppe sender ?
    my $host = $self->{'admin'}{'host'};
    my $from = "$name-owner\@$host";
    
    my (@tabrcpt, @tabrcpt_notice, @tabrcpt_txt, @tabrcpt_html, @tabrcpt_url);
    my $mixed = ($message->{'msg'}->head->get('Content-Type') =~ /multipart\/mixed/i);
    my $alternative = ($message->{'msg'}->head->get('Content-Type') =~ /multipart\/alternative/i);
 
    for ( my $user = $self->get_first_user(); $user; $user = $self->get_next_user() ){
	unless ($user->{'email'}) {
	    &do_log('err','Skipping user with no email address in list %s', $name);
	    next;
	}

    if ($user->{'reception'} =~ /^digest|digestplain|summary|nomail$/i) {
	    next;
	}elsif ($user->{'reception'} eq 'not_me'){
	    push @tabrcpt, $user->{'email'} unless ($sender_hash{$user->{'email'}});

       } elsif ($user->{'reception'} eq 'notice') {
           push @tabrcpt_notice, $user->{'email'}; 
       } elsif ($alternative and ($user->{'reception'} eq 'txt')) {
           push @tabrcpt_txt, $user->{'email'};
       } elsif ($alternative and ($user->{'reception'} eq 'html')) {
           push @tabrcpt_html, $user->{'email'};
       } elsif ($mixed and ($user->{'reception'} eq 'urlize')) {
           push @tabrcpt_url, $user->{'email'};
       } elsif (($message->{'smime_crypted'}) && (! -r "$Conf{'ssl_cert_dir'}/".&tools::escape_chars($user->{'email'}))) {
	   ## Missing User certificate
	   $self->send_file('x509-user-cert-missing', $user->{'email'}, $robot, {'mail' => {'subject' => $message->{'msg'}->head->get('Subject'),
											    'sender' => $message->{'msg'}->head->get('From')}});
       } else {
	   push @tabrcpt, $user->{'email'};
       }
   }    

    ## sa  return 0  = Pb  ?
    unless (@tabrcpt || @tabrcpt_notice || @tabrcpt_txt || @tabrcpt_html || @tabrcpt_url) {
	&do_log('info', 'No subscriber for sending msg in list %s', $name);
	return 0;
    }
    #save the message before modifying it
    my $saved_msg = $message->{'msg'}->dup;
    my $nbr_smtp;

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
	 $nbr_smtp = &smtp::mailto($message, $from, @tabrcpt);
    }

    ##Prepare and send message for notice reception mode
    if (@tabrcpt_notice) {
	my $notice_msg = $saved_msg->dup;
        $notice_msg->bodyhandle(undef);    
	$notice_msg->parts([]);
	my $new_message = new Message($notice_msg);
	$nbr_smtp += &smtp::mailto($new_message, $from, @tabrcpt_notice);
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
 	$nbr_smtp += &smtp::mailto($new_message, $from, @tabrcpt_txt);
    }

   ##Prepare and send message for html reception mode
    if (@tabrcpt_html) {
	my $html_msg = $saved_msg->dup;
	if (&tools::as_singlepart($html_msg, 'text/html|multipart/related')) {
	    do_log('notice', 'Multipart message changed to singlepart');
	}
        ## Add a footer
	my $new_msg = $self->add_parts($html_msg);
	if (defined $new_msg) {
	    $html_msg = $new_msg;
        }
	my $new_message = new Message($html_msg);
	$nbr_smtp += &smtp::mailto($new_message, $from, @tabrcpt_html);
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
	$nbr_smtp += &smtp::mailto($new_message, $from, @tabrcpt_url);
    }

    return $nbr_smtp;
    
   }

## Add footer/header to a message
sub add_parts {
    my ($self, $msg, $listname, $type) = @_;
    do_log('debug2', 'List:add_parts(%s, %s, %s)', $msg, $listname, $type);

    my ($listname,$type) = ($self->{'name'}, $self->{'admin'}{'footer_type'});
    my $listdir = $self->{'dir'};

    my ($header, $headermime);
    foreach my $file ("$listdir/message.header", 
		      "$listdir/message.header.mime",
		      "$Conf{'etc'}/templates/message.header", 
		      "$Conf{'etc'}/templates/message.header.mime") {
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
		      "$Conf{'etc'}/templates/message.footer", 
		      "$Conf{'etc'}/templates/message.footer.mime") {
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

## Send a digest message to the subscribers with reception digest, digestplain or summary
sub send_msg_digest {
    my ($self) = @_;

    my $listname = $self->{'name'};
    my $robot = $self->{'domain'};
    do_log('debug2', 'List:send_msg_digest(%s)', $listname);
    
    my $filename = "$Conf{'queuedigest'}/$listname";
    my $param = {'host' => $self->{'admin'}{'host'},
		 'name' => "$self->{'name'}",
		 'from' => "$self->{'name'}-request\@$self->{'admin'}{'host'}",
		 'return_path' => "$self->{'name'}-owner\@$self->{'admin'}{'host'}",
		 'reply' => "$self->{'name'}-request\@$self->{'admin'}{'host'}",
		 'to' => "$self->{'name'}\@$self->{'admin'}{'host'}",
		 'table_of_content' => sprintf(Msg(8, 13, "Table of content")),
		 'boundary1' => '----------=_'.&tools::get_message_id($robot),
		 'boundary2' => '----------=_'.&tools::get_message_id($robot),
		 };
    if ($self->get_reply_to() =~ /^list$/io) {
	$param->{'reply'} = "$param->{'to'}";
    }
    
    my @tabrcpt ;
    my @tabrcptsummary;
    my @tabrcptplain;
    my $i;
    
    my ($mail, @list_of_mail);

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
    $/ = "\n\n" . $msg::separator . "\n\n";

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
	$mail = $parser->parse_data(\@text);

	push @list_of_mail, $mail;
	
    }
    close DIGEST;
    $/ = $old;

    ## Deletes the introduction part
    splice @list_of_mail, 0, 1;

    ## Digest index
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
	$mail->remove_sig;
	$msg->{'full_msg'} = $mail->as_string;
	$msg->{'body'} = $mail->body_as_string;
	$msg->{'plain_body'} = $mail->PlainDigest::plain_body_as_string();
	#$msg->{'body'} = $mail->bodyhandle->as_string();
	chomp $msg->{'from'};
	$msg->{'month'} = &POSIX::strftime("%Y-%m", localtime(time)); ## Should be extracted from Date:
	$msg->{'message_id'} = $mail->head->get('Message-Id');
	
	## Clean up Message-ID
	$msg->{'message_id'} =~ s/^\<(.+)\>$/$1/;
	$msg->{'message_id'} = &tools::escape_chars($msg->{'message_id'});

        push @{$param->{'msg_list'}}, $msg ;
	
    }
    
    my @now  = localtime(time);
    $param->{'datetime'} = sprintf "%s", POSIX::strftime("%a, %d %b %Y %H:%M:%S", @now);
    $param->{'date'} = sprintf "%s", POSIX::strftime("%a, %d %b %Y", @now);

    ## Prepare Digest
    if (@tabrcpt) {
	## Send digest
	$self->send_file('digest', \@tabrcpt, $robot, $param);
    }    

    ## Prepare Plain Text Digest
    if (@tabrcptplain) {
        ## Send digest-plain
        $self->send_file('digest_plain', \@tabrcptplain, $robot, $param);
    }    
    

    ## send summary
    if (@tabrcptsummary) {
	$param->{'subject'} = sprintf Msg(8, 31, 'Summary of list %s'), $self->{'name'};
	$self->send_file('summary', \@tabrcptsummary, $robot, $param);
    }
    
    return 1;
}

## Send a global (not relative to a list) file to a user
sub send_global_file {
    my($action, $who, $robot, $context) = @_;
    do_log('debug2', 'List::send_global_file(%s, %s, %s)', $action, $who, $robot);

    my $filename;
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
    my $lang = $data->{'user'}{'lang'} || &Conf::get_robot_conf($robot, 'lang');

    ## What file   
    foreach my $f ("$Conf{'etc'}/$robot/templates/$action.$lang.tpl","$Conf{'etc'}/$robot/templates/$action.tpl",
		   "$Conf{'etc'}/templates/$action.$lang.tpl","$Conf{'etc'}/templates/$action.tpl",
		   "--ETCBINDIR--/templates/$action.$lang.tpl","--ETCBINDIR--/templates/$action.tpl") {
	if (-r $f) {
	    $filename = $f;
	    last;
	}
    }

    unless ($filename) {
	do_log('err',"Unable to open file $Conf{'etc'}/$robot/templates/$action.tpl NOR  $Conf{'etc'}/templates/$action.tpl NOR --ETCBINDIR--/templates/$action.tpl");
    }

    foreach my $p ('email','host','sympa','request','listmaster','wwsympa_url','title') {
	$data->{'conf'}{$p} = &Conf::get_robot_conf($robot, $p);
    }

    $data->{'conf'}{'version'} = $main::Version;
		   $data->{'from'} = $data->{'conf'}{'request'};
    $data->{'robot_domain'} = $robot;
    $data->{'return_path'} = &Conf::get_robot_conf($robot, 'request');

    mail::mailfile($filename, $who, $data, $robot);

    return 1;
}

## Send a file to a user
sub send_file {
    my($self, $action, $who, $robot, $context) = @_;
    do_log('debug2', 'List::send_file(%s, %s, %s, %s)', $action, $who, $robot);

    my $name = $self->{'name'};
    my $filename;
    my $sign_mode;

    my $data = $context;

    ## Any recepients
    if ((ref ($who) && ($#{$who} < 0)) ||
	(!ref ($who) && ($who eq ''))) {
	&do_log('err', 'No recipient for sending %s', $action);
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
	
	## Unique return-path
	if ((($self->{'admin'}{'welcome_return_path'} eq 'unique') && ($action eq 'welcome')) ||
	    (($self->{'admin'}{'remind_return_path'} eq 'unique') && ($action eq 'remind')))  {
	    my $escapercpt = $who ;
	    $escapercpt =~ s/\@/\=\=a\=\=/;
	    $data->{'return_path'} = "bounce+$escapercpt\=\=$name\@$self->{'admin'}{'host'}";
	}
    }

    $data->{'return_path'} ||= "$name-owner\@$self->{'admin'}{'host'}";

    ## Lang
    my $lang = $data->{'user'}{'lang'} || $self->{'admin'}{'lang'} || &Conf::get_robot_conf($robot, 'lang');

    ## What file   
    foreach my $f ("$self->{'dir'}/$action.$lang.tpl",
		   "$self->{'dir'}/$action.tpl",
		   "$self->{'dir'}/$action.mime","$self->{'dir'}/$action",
		   "$Conf{'etc'}/$robot/templates/$action.$lang.tpl",
		   "$Conf{'etc'}/$robot/templates/$action.tpl",
		   "$Conf{'etc'}/templates/$action.$lang.tpl",
		   "$Conf{'etc'}/templates/$action.tpl",
		   "$Conf{'home'}/$action.mime",
		   "$Conf{'home'}/$action",
		   "--ETCBINDIR--/templates/$action.$lang.tpl",
		   "--ETCBINDIR--/templates/$action.tpl") {
	if (-r $f) {
	    $filename = $f;
	    last;
	}
    }

    unless ($filename) {
	do_log('err',"Unable to find '$action' template in list directory NOR $Conf{'etc'}/templates/ NOR --ETCBINDIR--/templates/");
    }
    
    foreach my $p ('email','host','sympa','request','listmaster','wwsympa_url','title') {
	$data->{'conf'}{$p} = &Conf::get_robot_conf($robot, $p);
    }

    $data->{'list'}{'lang'} = $self->{'admin'}{'lang'};
    $data->{'list'}{'name'} = $name;
    $data->{'list'}{'domain'} = $data->{'robot_domain'} = $robot;
    $data->{'list'}{'host'} = $self->{'admin'}{'host'};
    $data->{'list'}{'subject'} = $self->{'admin'}{'subject'};
    $data->{'list'}{'owner'} = $self->{'admin'}{'owner'};
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
	$data->{'from'} = "$name\@$data->{'list'}{'host'}";
	$data->{'replyto'} = "$name-request\@$data->{'list'}{'host'}";
    }else{
	$data->{'from'} = "$name-request\@$data->{'list'}{'host'}";
    }

    foreach my $key (keys %{$context}) {
	$data->{'context'}{$key} = $context->{$key};
    }

    chdir $self->{'dir'};
    if ($filename) {
        mail::mailfile($filename, $who, $data, $self->{'domain'}, $sign_mode);
    }
    chdir $Conf{'home'};

    return 1;
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
	    return undef;
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
	    
	    $list_cache{'is_user'}{$name}{$who} = undef;    
	    
	    ## Delete record in SUBSCRIBER
	    $statement = sprintf "DELETE FROM subscriber_table WHERE (user_subscriber=%s AND list_subscriber=%s)",$dbh->quote($who), $dbh->quote($name);
	    
	    unless ($dbh->do($statement)) {
		do_log('err','Unable to execute SQL statement %s : %s', $statement, $dbh->errstr);
		return undef;
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
	    $self->{'total'} = _load_total_db($self->{'name'}, $option);
	}
    }
#    if ($self->{'admin'}{'user_data_source'} eq 'database') {
	## If stats file was updated
#	my $time = (stat("$name/stats"))[9];
#	if ($time > $self->{'mtime'}[0]) {
#	    $self->{'total'} = _load_total_db($self->{'name'});
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

    ## decrypt password
    if ((defined $user) && $user->{'password'}) {
	$user->{'password'} = &tools::decrypt_password($user->{'password'});
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
	if (defined $list_cache{'get_subscriber'}{$name}{$email}) {
	    &do_log('debug3', 'xxx Use cache(get_subscriber, %s,%s)', $name, $email);
	    return $list_cache{'get_subscriber'}{$name}{$email};
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
	    $statement = sprintf "SELECT user_subscriber \"email\", comment_subscriber \"gecos\", bounce_subscriber \"bounce\", bounce_score_subscriber \"bounce_score\", reception_subscriber \"reception\", visibility_subscriber \"visibility\", %s \"date\", %s \"update_date\", subscribed_subscriber \"subscribed\", included_subscriber \"included\", include_sources_subscriber \"id\"  %s FROM subscriber_table WHERE (user_subscriber = %s AND list_subscriber = %s)", $date_field, $update_field, $additional, $dbh->quote($email), $dbh->quote($name);
	}else {
	    $statement = sprintf "SELECT user_subscriber AS email, comment_subscriber AS gecos, bounce_subscriber AS bounce, bounce_score_subscriber AS bounce_score, reception_subscriber AS reception, visibility_subscriber AS visibility, %s AS date, %s AS update_date, subscribed_subscriber AS subscribed, included_subscriber AS included, include_sources_subscriber AS id %s FROM subscriber_table WHERE (user_subscriber = %s AND list_subscriber = %s)", $date_field, $update_field, $additional, $dbh->quote($email), $dbh->quote($name);
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
	$list_cache{'get_subscriber'}{$name}{$email} = $user;

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

		## Read access to prevent "Bad file number" error on Solaris
		unless (open FH, "$lock_file") {
		    &do_log('err', 'Cannot open %s: %s', $lock_file, $!);
		    return undef;
		}
		
		unless (flock (FH, LOCK_SH | LOCK_NB)) {
		    &do_log('notice','Waiting for reading lock on %s', $lock_file);
		    unless (flock (FH, LOCK_SH)) {
			&do_log('err', 'Failed locking %s: %s', $lock_file, $!);
			return undef;
		    }
		}
		&do_log('debug2', 'Got lock for reading on %s', $lock_file);
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

	    $statement = sprintf "SELECT user_subscriber \"email\", comment_subscriber \"gecos\", reception_subscriber \"reception\", visibility_subscriber \"visibility\", bounce_subscriber \"bounce\", bounce_score_subscriber \"bounce_score\", %s \"date\", %s \"update_date\", subscribed_subscriber \"subscribed\", included_subscriber \"included\", include_sources_subscriber \"id\" %s FROM subscriber_table WHERE (list_subscriber = %s %s)", $date_field, $update_field, $additional, $dbh->quote($name), $selection;

	    ## SORT BY
	    if ($sortby eq 'domain') {
		$statement = sprintf "SELECT user_subscriber \"email\", comment_subscriber \"gecos\", reception_subscriber \"reception\", visibility_subscriber \"visibility\", bounce_subscriber \"bounce\", bounce_score_subscriber \"bounce_score\", %s \"date\", %s \"update_date\", subscribed_subscriber \"subscribed\", included_subscriber \"included\", include_sources_subscriber \"id\", substr(user_subscriber,instr(user_subscriber,'\@')+1) \"dom\" %s FROM subscriber_table WHERE (list_subscriber = %s ) ORDER BY \"dom\"", $date_field, $update_field, $additional, $dbh->quote($name);

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

	    $statement = sprintf "SELECT user_subscriber \"email\", comment_subscriber \"gecos\", reception_subscriber \"reception\", visibility_subscriber \"visibility\", bounce_subscriber \"bounce\", bounce_score_subscriber \"bounce_score\", %s \"date\", %s \"update_date\", subscribed_subscriber \"subscribed\", included_subscriber \"included\", include_sources_subscriber \"id\" %s FROM subscriber_table WHERE (list_subscriber = %s %s)", $date_field, $update_field, $additional, $dbh->quote($name), $selection;
	    
	    ## SORT BY
	    if ($sortby eq 'domain') {
		$statement = sprintf "SELECT user_subscriber \"email\", comment_subscriber \"gecos\", reception_subscriber \"reception\", visibility_subscriber \"visibility\", bounce_subscriber \"bounce\", bounce_score_subscriber \"bounce_score\", %s \"date\", %s \"update_date\", subscribed_subscriber \"subscribed\", included_subscriber \"included\", include_sources_subscriber \"id\", substring(user_subscriber,charindex('\@',user_subscriber)+1,100) \"dom\" %s FROM subscriber_table WHERE (list_subscriber = %s) ORDER BY \"dom\"", $date_field, $update_field, $additional, $dbh->quote($name);
		
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
	    
    $statement = sprintf "SELECT user_subscriber AS email, comment_subscriber AS gecos, reception_subscriber AS reception, visibility_subscriber AS visibility, bounce_subscriber AS bounce, bounce_score_subscriber AS bounce_score, %s AS date, %s AS update_date, subscribed_subscriber AS subscribed, included_subscriber AS included, include_sources_subscriber AS id %s FROM subscriber_table WHERE (list_subscriber = %s %s)", $date_field, $update_field, $additional, $dbh->quote($name), $selection;
	    
	    ## SORT BY
	    if ($sortby eq 'domain') {
		## Redefine query to set "dom"

		$statement = sprintf "SELECT user_subscriber AS email, comment_subscriber AS gecos, reception_subscriber AS reception, visibility_subscriber AS visibility, bounce_subscriber AS bounce, bounce_score_subscriber AS bounce_score, %s AS date, %s AS update_date, subscribed_subscriber AS subscribed, included_subscriber AS included, include_sources_subscriber AS id, REVERSE(SUBSTRING(user_subscriber FROM position('\@' IN user_subscriber) FOR 50)) AS dom %s FROM subscriber_table WHERE (list_subscriber = %s) ORDER BY dom", $date_field, $update_field, $additional, $dbh->quote($name);

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
	    
	    $statement = sprintf "SELECT user_subscriber AS email, comment_subscriber AS gecos, reception_subscriber AS reception, visibility_subscriber AS visibility, bounce_subscriber AS bounce, bounce_score_subscriber AS bounce_score, %s AS date, %s AS update_date, subscribed_subscriber AS subscribed, included_subscriber AS included, include_sources_subscriber AS id %s FROM subscriber_table WHERE (list_subscriber = %s %s)", $date_field, $update_field, $additional, $dbh->quote($name), $selection;
	    
	    ## SORT BY
	    if ($sortby eq 'domain') {
		## Redefine query to set "dom"

		$statement = sprintf "SELECT user_subscriber AS email, comment_subscriber AS gecos, reception_subscriber AS reception, visibility_subscriber AS visibility, bounce_subscriber AS bounce, bounce_score_subscriber AS bounce_score, %s AS date, %s AS update_date, subscribed_subscriber AS subscribed, included_subscriber AS included, include_sources_subscriber AS id, SUBSTRING(user_subscriber FROM position('\@' IN user_subscriber) FOR 50) AS dom %s FROM subscriber_table WHERE (list_subscriber = %s) ORDER BY dom", $date_field, $update_field, $additional, $dbh->quote($name);

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

	## If no offset (for LIMIT) was used, update total of subscribers
	unless ($offset) {
	    my $total = &_load_total_db($self->{'name'},'nocache');
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
		    flock(FH,LOCK_UN);
		    close FH;
		    &do_log('debug2', 'Release lock on %s', $lock_file);
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
	    
	    ## Read access to prevent "Bad file number" error on Solaris
	    unless (open FH, "$lock_file") {
		&do_log('err', 'Cannot open %s: %s', $lock_file, $!);
		return undef;
	    }

	    unless (flock (FH, LOCK_SH | LOCK_NB)) {
		&do_log('notice','Waiting for reading lock on %s', $lock_file);
		unless (flock (FH, LOCK_SH)) {
		    &do_log('err', 'Failed locking %s: %s', $lock_file, $!);
		    return undef;
		}
	    }
	    &do_log('debug2', 'Got lock for reading on %s', $lock_file);
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
	$statement = sprintf "SELECT user_subscriber \"email\", reception_subscriber \"reception\", visibility_subscriber \"visibility\", bounce_subscriber \"bounce\",bounce_score_subscriber \"bounce_score\", %s \"date\", %s \"update_date\" %s FROM subscriber_table WHERE (list_subscriber = %s AND bounce_subscriber is not NULL)", $date_field, $update_field, $additional, $dbh->quote($name);
    }else {
	$statement = sprintf "SELECT user_subscriber AS email, reception_subscriber AS reception, visibility_subscriber AS visibility, bounce_subscriber AS bounce,bounce_score_subscriber AS bounce_score, %s AS date, %s AS update_date %s FROM subscriber_table WHERE (list_subscriber = %s AND bounce_subscriber is not NULL)", $date_field, $update_field, $additional, $dbh->quote($name);
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
	    
    &do_log('err','Warning: entry with empty email address in list %s', $self->{'name'}) 
	if (! $user->{'email'});

    ## In case it was not set in the database
    $user->{'subscribed'} = 1
	if (defined($user) && ($self->{'admin'}{'user_data_source'} eq 'database'));    
    
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
		flock(FH,LOCK_UN);
		close FH;
		&do_log('debug2', 'Release lock on %s', $lock_file);
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
    $statement = sprintf "SELECT count(*) FROM subscriber_table WHERE (list_subscriber = %s  AND bounce_subscriber is not NULL)", $dbh->quote($name);
    
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
	if (defined $list_cache{'is_user'}{$name}{$who}) {
	    # &do_log('debug3', 'Use cache(%s,%s): %s', $name, $who, $list_cache{'is_user'}{$name}{$who});
	    return $list_cache{'is_user'}{$name}{$who};
	}
	
	## Check database connection
	unless ($dbh and $dbh->ping) {
	    return undef unless &db_connect();
	}	   
	
	## Query the Database
	$statement = sprintf "SELECT count(*) FROM subscriber_table WHERE (list_subscriber = %s AND user_subscriber = %s)",$dbh->quote($name), $dbh->quote($who);
	
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
	$list_cache{'is_user'}{$name}{$who} = $is_user;

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
			  id => 'include_sources_subscriber'
			  );
	
	## mapping between var and tables
	my %map_table = ( reception => 'subscriber_table',
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
			  id => 'subscriber_table'
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
			$value = $dbh->quote($value);
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
		    $statement = sprintf "UPDATE %s SET %s WHERE (list_subscriber=%s)", $table, join(',', @set_list), $dbh->quote($name);
		}else {
		    $statement = sprintf "UPDATE %s SET %s WHERE (user_subscriber=%s AND list_subscriber=%s)", $table, join(',', @set_list), $dbh->quote($who), $dbh->quote($name);
		}
	    }
	    
	    unless ($dbh->do($statement)) {
		do_log('err','Unable to execute SQL statement "%s" : %s', $statement, $dbh->errstr);
		return undef;
	    }
	}

	## Reset session cache
	$list_cache{'get_subscriber'}{$name}{$who} = undef;

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
	
	if ($map_field{$field} eq 'cookie_delay_user')  {
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
	
	my $insert = sprintf "%s", $dbh->quote($value);
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
	    
	    $list_cache{'is_user'}{$name}{$who} = undef;
	    
	    my $statement;

	    ## If datasource is 'include2' either is_included or is_subscribed must be set
	    ## default is is_subscriber for backward compatibility reason
	    if ($self->{'admin'}{'user_data_source'} eq 'include2') {
		unless ($new_user->{'included'}) {
		    $new_user->{'subscribed'} = 1;
		}
	    }
	    
	    unless ($new_user->{'included'}) {
		## Is the email in user table ?
		if (! is_user_db($who)) {
		    ## Insert in User Table
		    $statement = sprintf "INSERT INTO user_table (email_user, gecos_user, lang_user, password_user) VALUES (%s,%s,%s,%s)",$dbh->quote($who), $dbh->quote($new_user->{'gecos'}), $dbh->quote($new_user->{'lang'}), $dbh->quote($new_user->{'password'});
		    
		    unless ($dbh->do($statement)) {
			do_log('err','Unable to execute SQL statement "%s" : %s', $statement, $dbh->errstr);
			return undef;
		    }
		}
	    }	    

	    ## Update Subscriber Table
	    $statement = sprintf "INSERT INTO subscriber_table (user_subscriber, comment_subscriber, list_subscriber, date_subscriber, update_subscriber, reception_subscriber, visibility_subscriber,subscribed_subscriber,included_subscriber,include_sources_subscriber) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)", $dbh->quote($who), $dbh->quote($new_user->{'gecos'}), $dbh->quote($name), $date_field, $update_field, $dbh->quote($new_user->{'reception'}), $dbh->quote($new_user->{'visibility'}), $dbh->quote($new_user->{'subscribed'}), $dbh->quote($new_user->{'included'}), $dbh->quote($new_user->{'id'});
	    
	    unless ($dbh->do($statement)) {
		do_log('err','Unable to execute SQL statement "%s" : %s', $statement, $dbh->errstr);
		return undef;
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


## Update subscribers (used while renaming a list)
sub rename_list_db {
    my($listname, $new_listname) = @_;
    do_log('debug', 'List::rename_list_db(%s,%s)', $listname,$new_listname);

    unless ($List::use_db) {
	&do_log('info', 'Sympa not setup to use DBI');
	return undef;
    }

    my $statement;
    
    ## Check database connection
    unless ($dbh and $dbh->ping) {
	return undef unless &db_connect();
    }	   
    
    $statement =  sprintf "UPDATE subscriber_table SET list_subscriber=%s WHERE list_subscriber=%s", $dbh->quote($new_listname), $dbh->quote($listname) ; 

    do_log('debug', 'List::rename_list_db statement : %s',  $statement );

    unless ($dbh->do($statement)) {
	do_log('err','Unable to execute SQL statement "%s" : %s', $statement, $dbh->errstr);
	return undef;
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
    my($self, $function, $who) = @_;
    do_log('debug3', 'List::am_i(%s, %s)', $function, $who);

    my $u;
    
    return undef unless ($self && $who);
    $function =~ y/A-Z/a-z/;
    $who =~ y/A-Z/a-z/;
    chomp($who);
    
    ## Listmaster has all privileges except editor
    # sa contestable.
    return 1 if (($function eq 'owner') and &is_listmaster($who,$self->{'domain'}));

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

## Return the action to perform for 1 sender using 1 auth method to perform 1 operation
sub request_action {
    my $operation = shift;
    my $auth_method = shift;
    my $robot=shift;
    my $context = shift;
    my $debug = shift;
    do_log('debug3', 'List::request_action %s,%s,%s',$operation,$auth_method,$robot);

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
        unless ( $list = new List ($context->{'listname'}) ){
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
		return 'undef';
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
		    return ("error-performing-condition : $rule->{'condition'}",$rule->{'auth_method'},'reject') ;
		}
		&List::send_notify_to_listmaster('error-performing-condition', $robot, $context->{'listname'}."  ".$rule->{'condition'} );
		return undef;
	    }
	    if ($result == -1) {
		do_log('debug3',"rule $rule->{'condition'},$rule->{'auth_method'},$rule->{'action'} rejected");
		next;
	    }
	    if ($result == 1) {
		do_log('debug3',"rule $rule->{'condition'},$rule->{'auth_method'},$rule->{'action'} accepted");
		if ($debug) {
		    return ($rule->{'condition'},$rule->{'auth_method'},$rule->{'action'});
		}

		## Check syntax of returned action
		unless ($rule->{'action'} =~ /^(do_it|reject|request_auth|owner|editor|editorkey|listmaster)/) {
		    &do_log('err', "Matched unknown action '%s' in scenario", $rule->{'action'});
		    return undef;
		}

		return $rule->{'action'};
	    }
	}
    }
    do_log('debug3',"no rule match, reject");
    return ('default','default','reject');
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
	$list = new List ($context->{'listname'});
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
	    if (my $conf_value = &Conf::get_robot_conf($context->{'robot_domain'}, $1)) {
		
		$value =~ s/\[conf\-\>([\w\-]+)\]/$conf_value/;
	    }else{
		do_log('err',"unknown variable context $value in rule $condition");
		return undef;
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

	    ## Sender's user/subscriber attributes (if subscriber)
	}elsif ($value =~ /\[user\-\>([\w\-]+)\]/i) {

	    $context->{'user'} ||= &get_user_db($context->{'sender'});	    
	    $value =~ s/\[user\-\>([\w\-]+)\]/$context->{'user'}{$1}/;

	}elsif ($value =~ /\[user_attributes\-\>([\w\-]+)\]/i) {
	    
	    $context->{'user'} ||= &get_user_db($context->{'sender'});	    
	    foreach my $attr (split /;/, $context->{'user'}{'attributes'}) {
		my ($key, $value) = split /=/, $attr;
		$context->{'user_attributes'}{$key} = $value;
	    }

	    $value =~ s/\[user_attributes\-\>([\w\-]+)\]/$context->{'user_attributes'}{$1}/;

	}elsif (($value =~ /\[subscriber\-\>([\w\-]+)\]/i) && defined ($context->{'sender'} ne 'nobody')) {
	    
	    $context->{'subscriber'} ||= $list->get_subscriber($context->{'sender'});
	    $value =~ s/\[subscriber\-\>([\w\-]+)\]/$context->{'subscriber'}{$1}/;

	    ## SMTP Header field
	}elsif ($value =~ /\[(msg_header|header)\-\>([\w\-]+)\]/i) {
	    my $field_name = $2;
	    if (defined ($context->{'msg'})) {
		my $header = $context->{'msg'}->head;
		my $field = $header->get($field_name);
		$value =~ s/\[(msg_header|header)\-\>$field_name/$field/;
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

	if ( &is_listmaster($args[0],$context->{'robot_domain'})) {
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

	$list2 = new List ($args[0]);
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
	    my $reghost = &Conf::get_robot_conf($context->{'robot_domain'}, 'host');
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
	my $val_search = &search($args[0],$args[1],$context->{'robot_domain'});
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
    my $ldap_file = shift;
    my $sender = shift;
    my $robot = shift;

    &do_log('debug2', 'List::search(%s,%s,%s)', $ldap_file, $sender, $robot);

    my $file;

    unless ($file = &tools::get_filename('etc',"search_filters/$ldap_file", $robot)) {
	&do_log('err', 'Could not find LDAP filter %s', $ldap_file);
	return undef;
    }   

    my $timeout = 3600;

    my $var;
    my $time = time;
    my $value;

    my %ldap_conf;
    
    return undef unless (%ldap_conf = &Ldap::load($file));

 
    my $filter = $ldap_conf{'filter'};	
    $filter =~ s/\[sender\]/$sender/g;
    
    if (defined ($persistent_cache{'named_filter'}{$ldap_file}{$filter}) &&
	(time <= $persistent_cache{'named_filter'}{$ldap_file}{$filter}{'update'} + $timeout)){ ## Cache has 1hour lifetime
        &do_log('notice', 'Using previous LDAP named filter cache');
        return $persistent_cache{'named_filter'}{$ldap_file}{$filter}{'value'};
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
	
	unless ($ldap->bind()) {
	    do_log('notice','Unable to bind to the LDAP server %s:%d',$host, $port);
	    next;
	}
	
	my $mesg = $ldap->search(base => "$ldap_conf{'suffix'}" ,
				 filter => "$filter",
				 scope => "$ldap_conf{'scope'}");
    	
	
	if ($mesg->count() == 0){
	    $persistent_cache{'named_filter'}{$ldap_file}{$filter}{'value'} = 0;
	    
	}else {
	    $persistent_cache{'named_filter'}{$ldap_file}{$filter}{'value'} = 1;
	}
      	
	$ldap->unbind or do_log('notice','List::search_ldap.Unbind impossible');
	$persistent_cache{'named_filter'}{$ldap_file}{$filter}{'update'} = time;
	
	return $persistent_cache{'named_filter'}{$ldap_file}{$filter}{'value'};
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
    
    if (! $edit_list_conf{$self->{'domain'}} || ((stat(&tools::get_filename('etc','edit_list.conf',$self->{'domain'})))[9] > $mtime{'edit_list_conf'}{$self->{'domain'}})) {

        $edit_conf = $edit_list_conf{$self->{'domain'}} = &tools::load_edit_list_conf($self->{'domain'});
	$mtime{'edit_list_conf'}{$self->{'domain'}} = time;
    }else {
        $edit_conf = $edit_list_conf{$self->{'domain'}};
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
	return 'hidden';
    }

    ## What privilege does he/she has ?
    my ($what, @order);

    if (($parameter =~ /^(\w+)\.(\w+)$/) &&
	($parameter !~ /\.tpl$/)) {
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
	    return $what;
	}
    }
    
    return 'hidden';
}


## May the indicated user edit a paramter while creating a new list
# sa cette procÅÈdure est appelÅÈe nul part, je lui ajoute malgrÅËs tout le paramÅÍtre robot
# edit_conf devrait ÅÍtre aussi dÅÈpendant du robot
sub may_create_parameter {

    my($parameter, $who,$robot) = @_;
    do_log('debug3', 'List::may_create_parameter(%s, %s, %s)', $parameter, $who,$robot);

    if ( &is_listmaster($who,$robot)) {
	return 1;
    }
    my $edit_conf = &tools::load_edit_list_conf($robot);
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

   if ($action =~ /^(add|del|remind|reconfirm|purge|expire)$/io) {
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
   do_log('debug3', 'List::archive_exist(%s)', $file);

   return undef unless ($self->is_archived());
   Archive::exist("$self->{'dir'}/archives", $file);
}

## Send an archive file to someone
sub archive_send {
   my($self, $who, $file) = @_;
   do_log('debug2', 'List::archive_send(%s, %s)', $who, $file);

   return unless ($self->is_archived());
   my $i;
   if ($i = Archive::exist("$self->{'dir'}/archives", $file)) {
      mail::mailarc($i, Msg(8, 7, "File") . " $self->{'name'} $file",$who );
   }
}

## List the archived files
sub archive_ls {
   my $self = shift;
   do_log('debug2', 'List::archive_ls');

   Archive::list("$self->{'dir'}/archives") if ($self->is_archived());
}

## Archive 
sub archive_msg {
    my($self, $msg ) = @_;
    do_log('debug2', 'List::archive_msg for %s',$self->{'name'});

    my $is_archived = $self->is_archived();
    Archive::store("$self->{'dir'}/archives",$is_archived, $msg)  if ($is_archived);

    Archive::outgoing("$Conf{'queueoutgoing'}","$self->{'name'}\@$self->{'admin'}{'host'}",$msg) 
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
    do_log('debug3', 'List::is_archived');
    return (shift->{'admin'}{'archive'}{'period'});
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

    unless (-f "$Conf{'queuedigest'}/$listname") {
	return undef;
    }

    unless ($digest) {
	return undef;
    }
    
    my @days = @{$digest->{'days'}};
    my ($hh, $mm) = ($digest->{'hour'}, $digest->{'minute'});
     
    my @now  = localtime(time);
    my $today = $now[6]; # current day
    my @timedigest = localtime( (stat "$Conf{'queuedigest'}/$listname")[9]);

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

   
    # sa tester le chargement de scenario spÅÈcifique Å‡ un rÅÈpertoire du shared
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
	if (/^\s*title\.(\w+)\s+(.*)\s*$/i) {
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
	    
	    $list_of_task{$name}{'title'} = &List::_load_task_title ($file);
	    $list_of_task{$name}{'name'} = $name;
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

## Loads the statistics informations
sub _load_stats_file {
    my $file = shift;
    do_log('debug3', 'List::_load_stats_file(%s)', $file);

   ## Create the initial stats array.
   my ($stats, $total, $last_sync);
 
   if (open(L, $file)){     
       if (<L> =~ /^(\d+)\s+(\d+)\s+(\d+)\s+(\d+)(\s+(\d+))?(\s+(\d+))?/) {
	   $stats = [ $1, $2, $3, $4];
	   $total = $6;
	   $last_sync = $8;
       } else {
	   $stats = [ 0, 0, 0, 0];
	   $total = 0;
	   $last_sync = 0;
       }
       close(L);
   } else {
       $stats = [ 0, 0, 0, 0];
       $total = 0;
       $last_sync = 0;
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
    my ($users, $param, $dir, $robot, $default_user_options , $tied) = @_;

    my $host = $param->{'host'};
    my $port = $param->{'port'} || '443';
    my $path = $param->{'path'};
    my $cert = $param->{'cert'} || 'list';

    my $id = _get_datasource_id($param);

    do_log('debug', 'List::_include_users_remote_sympa_list https://%s:%s/%s using cert %s,', $host, $port, $path, $cert);
    
    my $total = 0; 
    my $get_total = 0;

    my $cert_file ; my $key_file ;

    if ($cert == 'list') {
	$cert_file = $dir.'/cert.pem';
	$key_file = $dir.'/private_key';
    }elsif($cert == 'robot') {
	$cert_file = &tools::get_filename('etc','cert.pem',$robot);
	$key_file =  &tools::get_filename('etc','private_key',$robot);
    }
    unless ((-r $cert_file) && ( -r $key_file)) {
	do_log('err', 'Include remote list https://%s:%s/%s using cert %s, unable to open %s or %s', $host, $port, $path, $cert,$cert_file,$key_file);
	return undef;
    }
    
    my $getting_headers = 1;

    my %user ;
    my $email ;


    foreach my $line ( &X509::get_https($host,$port,$path,$cert_file,$key_file,{'key_passwd' => $Conf{'key_passwd'},
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
	    do_log('debug4',"ignore $email because allready member");
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
	
	if ($tied) {
	    $users->{$email} = join("\n", %u);
	}else{
	    $users->{$email} = \%u;
	}
	delete $user{$email};undef $email;
    }
    do_log('info','Include %d subscribers from list (%d subscribers) https://%s:%s%s',$total,$get_total,$host,$port,$path);
    return $total ;    
}



## include a list as subscribers.
sub _include_users_list {
    my ($users, $includelistname, $default_user_options, $tied) = @_;
    do_log('debug2', 'List::_include_users_list');

    my $total = 0;
    
    my $includelist = new List ($includelistname);
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

	if ($tied) {
	    $users->{$email} = join("\n", %u);
	}else {
	    $users->{$email} = \%u;
	}
    }
    do_log('info',"Include %d subscribers from list %s",$total,$includelistname);
    return $total ;
}

## include a lists owners lists privileged_owners or lists_editors.
sub _include_users_admin {
    my ($users, $selection, $role, $default_user_options,$tied) = @_;
#   il fautr prÅÈparer une liste de hash avec le nom de liste, le nom de robot, le rÅÈpertoire de la liset pour appeler
#    load_admin_file dÅÈcommanter le include_admin
    my @lists;
    
    unless ($role eq 'listmaster') {
	
	if ($selection =~ /^\*\@(\S+)$/) {
	    @lists = get_lists($1);
	    my $robot = $1;
	}else{
	    $selection =~ /^(\S+)@(\S+)$/ ;
	    $lists[0] = $1;
	}
	
	foreach my $list (@lists) {
	    #my $admin = _load_admin_file($dir, $domain, 'config');
	}
    }
}
    
sub _include_users_file {
    my ($users, $filename, $default_user_options,$tied) = @_;
    do_log('debug2', 'List::_include_users_file');

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

	if ($tied) {
	    $users->{$email} = join("\n", %u);
	}else {
	    $users->{$email} = \%u;
	}
    }
    close INCLUDE ;
    
    do_log('info',"include %d new subscribers from file %s",$total,$filename);
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
    
    if ( defined $user ) {
	unless ($ldaph->bind ($user, password => "$passwd")) {
	    do_log('notice',"Can\'t bind with server %s as user '$user' : $@", join(',',@{$host}));
	    return undef;
	}
    }else {
	unless ($ldaph->bind ) {
	    do_log('notice',"Can\'t do anonymous bind with server %s : $@", join(',',@{$host}));
	    return undef;
	}
    }

    do_log('debug2', "Binded to LDAP server %s ; user : '$user'", join(',',@{$host})) ;
    
    do_log('debug2', 'Searching on server %s ; suffix %s ; filter %s ; attrs: %s', join(',',@{$host}), $ldap_suffix, $ldap_filter, $ldap_attrs);
    unless ($fetch = $ldaph->search ( base => "$ldap_suffix",
                                      filter => "$ldap_filter",
				      attrs => "$ldap_attrs",
				      scope => "$param->{'scope'}")) {
        do_log('debug2',"Unable to perform LDAP search in $ldap_suffix for $ldap_filter : $@");
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

	my %u = %{$default_user_options};
	$u{'email'} = $email;
	$u{'date'} = time;
	$u{'update_date'} = time;
	$u{'id'} = join (',', split(',', $u{'id'}), $id);

	if ($tied) {
	    $users->{$email} = join("\n", %u);
	}else {
	    $users->{$email} = \%u;
	}
    }

    do_log('debug2',"unbinded from LDAP server %s ", join(',',@{$host}));
    do_log('debug2','%d new subscribers included from LDAP query',$total);

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
    
    if ( defined $user ) {
	unless ($ldaph->bind ($user, password => "$passwd")) {
	    do_log('err',"Can\'t bind with server %s as user '$user' : $@", join(',',@{$host}));
	    return undef;
	}
    }else {
	unless ($ldaph->bind ) {
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

	if ($tied) {
	    $users->{$email} = join("\n", %u);
	}else {
	    $users->{$email} = \%u;
	}
    }

    do_log('debug2',"unbinded from LDAP server %s ",join(',',@{$host})) ;
    do_log('debug2','%d new subscribers included from LDAP query',$total);

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
    }elsif ($db_type eq 'Pg') {
	$connect_string = "DBI:Pg:dbname=$db_name;host=$host";
    }elsif ($db_type eq 'Sybase') {
	$connect_string = "DBI:Sybase:database=$db_name;server=$host";
    }else {
	$connect_string = "DBI:$db_type:$db_name:$host";
    }

    if ($param->{'connect_options'}) {
	$connect_string .= ';' . $param->{'connect_options'};
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
    while (defined ($email = $sth->fetchrow)) {
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

	if ($tied) {
	    $users->{$email} = join("\n", %u);
	}else {
	    $users->{$email} = \%u;
	}
    }
    $sth->finish ;
    $dbh->disconnect();

    do_log('debug2','%d included subscribers from SQL query', $total);
    return $total;
}

## Loads the list of subscribers from an external include source
sub _load_users_include {
    my $name = shift; 
    my $admin = shift ;
    my $dir = shift;
    my $db_file = shift;
    my $use_cache = shift;
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

	foreach my $type ('include_list','include_remote_sympa_list','include_file','include_ldap_query','include_ldap_2level_query','include_sql_query') {
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
			$included = _include_users_list (\%users, $incl, $admin->{'default_user_options'}, 'tied');

		    }
		}elsif ($type eq 'include_remote_sympa_list') {
		    $included = _include_users_remote_sympa_list(\%users, $incl, $dir,$admin->{'domain'},$admin->{'default_user_options'}, 'tied');
		}elsif ($type eq 'include_file') {
		    $included = _include_users_file (\%users, $incl, $admin->{'default_user_options'}, 'tied');
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
    my $name = shift; 
    my $admin = shift ;
    my $dir = shift;
    do_log('debug2', 'List::_load_users_include for list %s',$name);

    my (%users, $depend_on, $ref);
    my $total = 0;

    foreach my $type ('include_list','include_remote_sympa_list','include_file','include_ldap_query','include_ldap_2level_query','include_sql_query') {
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
		$included = _include_users_remote_sympa_list(\%users, $incl, $dir,$admin->{'domain'},$admin->{'default_user_options'});
	    }elsif ($type eq 'include_list') {
		$depend_on->{$name} = 1 ;
		if (&_inclusion_loop ($name,$incl,$depend_on)) {
		    do_log('err','loop detection in list inclusion : could not include again %s in %s',$incl,$name);
		}else{
		    $depend_on->{$incl};
		    $included = _include_users_list (\%users, $incl, $admin->{'default_user_options'});
		}
	    }elsif ($type eq 'include_file') {
		$included = _include_users_file (\%users, $incl, $admin->{'default_user_options'});
#	    }elsif ($type eq 'include_admin') {
#		$included = _include_users_admin (\\%users, $incl, $admin->{'default_user_options'});
	    }
	    unless (defined $included) {
		&do_log('err', 'Inclusion %s failed in list %s', $type, $name);
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
    return \%users;
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
	$new_subscribers = _load_users_include2($name, $self->{'admin'}, $self-{'dir'});

	## If include sources were not available, do not update subscribers
	## Use DB cache instead
	unless (defined $new_subscribers) {
	    &do_log('err', 'Could not include subscribers for list %s', $name);
	    &List::send_notify_to_listmaster('sync_include_failed', $self->{'domain'}, $name);
	    return undef;
	}
    }

    my $users_added = 0;
    my $users_updated = 0;

    ## Get an Exclusive lock
    my $lock_file = $self->{'dir'}.'/include.lock';
    unless (open FH, ">>$lock_file") {
	&do_log('err', 'Cannot open %s: %s', $lock_file, $!);
	return undef;
    }
    unless (flock (FH, LOCK_EX | LOCK_NB)) {
	&do_log('notice','Waiting for writing lock on %s', $lock_file);
	unless (flock (FH, LOCK_EX)) {
	    &do_log('err', 'Failed locking %s: %s', $lock_file, $!);
	    return undef;
	}
    }
    &do_log('debug2', 'Got lock for writing on %s', $lock_file);


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
    flock(FH,LOCK_UN);
    close FH;
    &do_log('debug2', 'Release lock on %s', $lock_file);

    ## Get and save total of subscribers
    $self->{'total'} = _load_total_db($self->{'name'}, 'nocache');
    $self->{'last_sync'} = time;
    $self->savestats();

    return 1;
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
    my $name = shift;
    my $option = shift;
    do_log('debug2', 'List::_load_total_db(%s)', $name);

    unless ($List::use_db) {
	&do_log('info', 'Sympa not setup to use DBI');
	return undef;
    }
    
    ## Use session cache
    if (($option ne 'nocache') && (defined $list_cache{'load_total_db'}{$name})) {
	&do_log('debug3', 'xxx Use cache(load_total_db, %s)', $name);
	return $list_cache{'load_total_db'}{$name};
    }

    my ($statement);

    ## Check database connection
    unless ($dbh and $dbh->ping) {
	return undef unless &db_connect();
    }	   

    ## Query the Database
    $statement = sprintf "SELECT count(*) FROM subscriber_table WHERE list_subscriber = %s", $dbh->quote($name);
       
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
    $list_cache{'load_total_db'}{$name} = $total;

    return $total;
}

## Writes to disk the stats data for a list.
sub _save_stats_file {
    my $file = shift;
    my $stats = shift;
    my $total = shift;
    my $last_sync = shift;
    do_log('debug2', 'List::_save_stats_file(%s, %d, %d)', $file, $total,$last_sync );
    
    open(L, "> $file") || return undef;
    printf L "%d %.0f %.0f %.0f %d %d\n", @{$stats}, $total, $last_sync;
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
    my $separator = $msg::separator;  

    unless ( -d "$Conf{'queuedigest'}") {
	return;
    }
    
    my @now  = localtime(time);
    $filename = "$Conf{'queuedigest'}/$self->{'name'}";
    $newfile = !(-e $filename);
    my $oldtime=(stat $filename)[9] unless($newfile);
  
    open(OUT, ">> $filename") || return;
    if ($newfile) {
	## create header
	printf OUT "\nThis digest for list has been created on %s\n\n",
      POSIX::strftime("%a %b %e %H:%M:%S %Y", @now);
	print OUT "------- THIS IS A RFC934 COMPLIANT DIGEST, YOU CAN BURST IT -------\n\n";
	print OUT "\n$separator\n\n";

       # send the date of the next digest to the users
    }
    #$msg->head->delete('Received') if ($msg->head->get('received'));
    $msg->print(\*OUT);
    print OUT "\n$separator\n\n";
    close(OUT);
    
    #replace the old time
    utime $oldtime,$oldtime,$filename   unless($newfile);
}

## List of lists hosted a robot
sub get_lists {
    my $robot_context = shift || '*';

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
	foreach $l (sort readdir(DIR)) {
	    next unless (($l !~ /^\./o) and (-d "$robot_dir/$l") and (-f "$robot_dir/$l/config"));
	    push @lists, $l;
	    
	}
	closedir DIR;
    }
    return @lists;
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
sub get_which_db {
    my $email = shift;
    do_log('debug3', 'List::get_which_db(%s)', $email);

    unless ($List::use_db) {
	&do_log('info', 'Sympa not setup to use DBI');
	return undef;
    }
    
    my ($l, %which, $statement);

    ## Check database connection
    unless ($dbh and $dbh->ping) {
	return undef unless &db_connect();
    }	   

    $statement = sprintf "SELECT list_subscriber FROM subscriber_table WHERE user_subscriber = %s",$dbh->quote($email);

    push @sth_stack, $sth;

    unless ($sth = $dbh->prepare($statement)) {
	do_log('err','Unable to prepare SQL statement : %s', $dbh->errstr);
	return undef;
    }

    unless ($sth->execute) {
	do_log('err','Unable to execute SQL statement "%s" : %s', $statement, $dbh->errstr);
	return undef;
    }

    while ($l = $sth->fetchrow) {
	$l =~ s/\s*$//;  ## usefull for PostgreSQL
	$which{$l} = 1;
    }

    $sth->finish();

    $sth = pop @sth_stack;

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

    if (($function eq 'member') and (defined $Conf{'db_type'})) {
	if ($List::use_db) {
	    $db_which = &get_which_db($email);
	}
    }

    foreach $l (get_lists($robot)){
 
	my $list = new List ($l);
	next unless ($list);
	# next unless (($list->{'admin'}{'host'} eq $robot) || ($robot eq '*')) ;

        if ($function eq 'member') {
	    if (($list->{'admin'}{'user_data_source'} eq 'database') ||
		($list->{'admin'}{'user_data_source'} eq 'include2')){
		if ($db_which->{$l}) {
		    push @which, $l ;
		}
	    }else {
		push @which, $list->{'name'} if ($list->is_user($email));
	    }
	}elsif ($function eq 'owner') {
	    push @which, $list->{'name'} if ($list->am_i('owner',$email));
	}elsif ($function eq 'editor') {
	    push @which, $list->{'name'} if ($list->am_i('editor',$email));
	}else {
	    do_log('err',"Internal error, unknown or undefined parameter $function  in get_which");
            return undef ;
	}
    }
    
    return @which;
}


## send auth request to $request 
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
    do_log('debug3', 'List::request_auth() List : %s,$email: %s cmd : %s',$self->{'name'},$email,$cmd);

    
    my $keyauth;
    my ($body, $command);
    my $robot_email = &Conf::get_robot_conf($robot, 'sympa');
    if (ref($self) eq 'List') {
	my $listname = $self->{'name'};

	if ($cmd =~ /signoff$/){
	    $keyauth = $self->compute_auth ($email, 'signoff');
	    $command = "auth $keyauth $cmd $listname $email";
	    my $url = "mailto:$robot_email?subject=$command";
	    $url =~ s/\s/%20/g;
	    $body = sprintf Msg(6, 261, $msg::signoff_need_auth ), $listname, $robot_email ,$command, $url;
	    
	}elsif ($cmd =~ /subscribe$/){
	    $keyauth = $self->compute_auth ($email, 'subscribe');
	    $command = "auth $keyauth $cmd $listname $param[0]";
	    my $url = "mailto:$robot_email?subject=$command";
	    $url =~ s/\s/%20/g;
	    $body = sprintf Msg(6, 260, $msg::subscription_need_auth)
		,$listname,  $robot_email, $command, $url ;
	}elsif ($cmd =~ /add$/){
	    $keyauth = $self->compute_auth ($param[0],'add');
	    $command = "auth $keyauth $cmd $listname $param[0] $param[1]";
	    $body = sprintf Msg(6, 39, $msg::adddel_need_auth),$listname
		, $robot_email, $command;
	}elsif ($cmd =~ /del$/){
	    my $keyauth = $self->compute_auth($param[0], 'del');
	    $command = "auth $keyauth $cmd $listname $param[0]";
	    $body = sprintf Msg(6, 39, $msg::adddel_need_auth),$listname
		, $robot_email, $command;
	}elsif ($cmd eq 'remind'){
	    my $keyauth = $self->compute_auth('','remind');
	    $command = "auth $keyauth $cmd $listname";
	    $body = sprintf Msg(6, 79, $msg::remind_need_auth),$listname
		, $robot_email, $command;
	}
    }else {
	if ($cmd eq 'remind'){
	    my $keyauth = &List::compute_auth('',$cmd);
	    $command = "auth $keyauth $cmd *";
	    $body = sprintf Msg(6, 79, $msg::remind_need_auth),'*'
		, $robot_email, $command;
	}
    }

    &mail::mailback (\$body, {'Subject' => $command}, 'sympa', $email, $robot, $email);

    return 1;
}

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

## return total of messages awaiting moderation
sub get_mod_spool_size {
    my $self = shift;
    do_log('debug3', 'List::get_mod_spool_size()');    
    my @msg;
    
    unless (opendir SPOOL, $Conf{'queuemod'}) {
	&do_log('err', 'Unable to read spool %s', $Conf{'queuemod'});
	return undef;
    }

    @msg = sort grep(/^$self->{'name'}\_\w+$/, readdir SPOOL);

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

sub probe_db {
    do_log('debug3', 'List::probe_db()');    
    my (%checked, $table);

    ## Database structure
    my %db_struct = ('user_table' => 
		     {'email_user' => 'varchar(100)',
		      'gecos_user' => 'varchar(150)',
		      'password_user' => 'varchar(40)',
		      'cookie_delay_user' => 'int(11)',
		      'lang_user' => 'varchar(10)',
		      'attributes_user' => 'text'},
		     'subscriber_table' => 
		     {'list_subscriber' => 'varchar(50)',
		      'user_subscriber' => 'varchar(100)',
		      'date_subscriber' => 'datetime',
		      'update_subscriber' => 'datetime',
		      'visibility_subscriber' => 'varchar(20)',
		      'reception_subscriber' => 'varchar(20)',
		      'bounce_subscriber' => 'varchar(35)',
		      'comment_subscriber' => 'varchar(150)',
		      'subscribed_subscriber' => "enum('0','1')",
		      'included_subscriber' => "enum('0','1')",
		      'include_sources_subscriber' => 'varchar(50)',
		      'bounce_score_subscriber' => 'smallint(6)'}
		     );

    my %not_null = ('email_user' => 1,
		    'list_subscriber' => 1,
		    'user_subscriber' => 1,
		    'date_subscriber' => 1);

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
	    return undef unless &db_connect();
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
	foreach my $t1 (keys %db_struct) {
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
    
    foreach $table('user_table', 'subscriber_table') {
	unless ($checked{$table} || $checked{'public.' . $table}) {
	    &do_log('err', 'Table %s not found in database %s', $table, $Conf{'db_name'});
	    return undef;
	}
    }

    ## Check tables structure if we could get it
    if (%real_struct) {
	foreach my $t (keys %db_struct) {
	    unless ($real_struct{$t}) {
		&do_log('info', 'Table \'%s\' not found in database \'%s\' ; you should create it with create_db.%s script', $t, $Conf{'db_name'}, $Conf{'db_type'});
		return undef;
	    }
	    
	    foreach my $f (sort keys %{$db_struct{$t}}) {
		unless ($real_struct{$t}{$f}) {
		    &do_log('info', 'Field \'%s\' (table \'%s\' ; database \'%s\') was NOT found. Attempting to add it...', $f, $t, $Conf{'db_name'});

		    my $options;
		    if ($not_null{$f}) {
			$options .= 'NOT NULL';
		    }
		    
		    unless ($dbh->do("ALTER TABLE $t ADD $f $db_struct{$t}{$f} $options")) {
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

		    if ($f eq 'user_subscriber') {
			&do_log('info', 'Setting list_subscriber,user_subscriber fields as PRIMARY');
			unless ($dbh->do("ALTER TABLE $t ADD PRIMARY KEY (list_subscriber,user_subscriber)")) {
			    &do_log('err', 'Could not set field field \'list_subscriber,user_subscriber\' as PRIMARY KEY, table\'%s\'.', $t);
			    return undef;
			}
			unless ($dbh->do("ALTER TABLE $t ADD INDEX (user_subscriber,list_subscriber)")) {
			    &do_log('err', 'Could not set INDEX on field \'user_subscriber,list_subscriber\', table\'%s\'.', $t);
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
		
		
		unless ($real_struct{$t}{$f} eq $db_struct{$t}{$f}) {
		     &do_log('err', 'Field \'%s\'  (table \'%s\' ; database \'%s\') does NOT have awaited type (%s). Attempting to change it...', $f, $t, $Conf{'db_name'}, $db_struct{$t}{$f});
		     
		     unless ($dbh->do("ALTER TABLE $t CHANGE $f $f $db_struct{$t}{$f}")) {
			 &do_log('err', 'Could not change field \'%s\' in table\'%s\'.', $f, $t);
			 &do_log('err', 'Sympa\'s database structure may have change since last update ; please check RELEASE_NOTES');
			 return undef;
		     }
		     
		     &do_log('info', 'Field %s in table %s, structur updated', $f, $t);
		}
	    }
	}
    }
    
    return 1;
}

## Try to create the database
sub create_db {
    &do_log('debug3', 'List::create_db()');    

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

    $drh->disconnect();

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
	    }elsif (/^([\w]+)\s+(.+)\s*$/) {
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
		$list_of_topics{$robot}{$tree[0]}{'title'} = $topic->{'title'};
		$list_of_topics{$robot}{$tree[0]}{'visibility'} = &_load_scenario_file('topics_visibility', $robot,$topic->{'visibility'}||'default');
		$list_of_topics{$robot}{$tree[0]}{'order'} = $topic->{'order'};
	    }else {
		my $subtopic = join ('/', @tree[1..$#tree]);
		$list_of_topics{$robot}{$tree[0]}{'sub'}{$subtopic} = &_add_topic($subtopic,$topic->{'title'},);
	    }
	}

	## Set undefined Topic (defined via subtopic)
	foreach my $t (keys %{$list_of_topics{$robot}}) {
	    unless (defined $list_of_topics{$robot}{$t}{'visibility'}) {
		$list_of_topics{$robot}{$t}{'visibility'} = &_load_scenario_file('topics_visibility', $robot,'default');
	    }
	    
	    unless (defined $list_of_topics{$robot}{$t}{'title'}) {
		$list_of_topics{$robot}{$t}{'title'} = $t;
	    }	
	}
    }

    return %{$list_of_topics{$robot}};
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
    next if ($defaults == 1);

    next unless (defined ($p));

    if (defined ($::pinfo{$key}{'scenario'}) ||
        defined ($::pinfo{$key}{'task'})) {
	next if ($p->{'name'} eq 'default');

	printf $fd "%s %s\n", $key, $p->{'name'};
	print $fd "\n";

    }elsif (ref($::pinfo{$key}{'file_format'})) {
	printf $fd "%s\n", $key;
	foreach my $k (keys %{$p}) {

	    if (defined ($::pinfo{$key}{'file_format'}{$k}{'scenario'})) {
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
	    printf $fd "%s %s\n\n", $key, join($::pinfo{$key}{'split_char'}, @{$p});
	}elsif ($key eq 'digest') {
	    my $value = sprintf '%s %d:%d', join(',', @{$p->{'days'}})
		,$p->{'hour'}, $p->{'minute'};
	    printf $fd "%s %s\n\n", $key, $value;
	}elsif (($key eq 'user_data_source') && $defaults && $List::use_db) {
	    printf $fd "%s %s\n\n", $key,  'database';
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

    ## Do we need to split param
    if (($p->{'occurrence'} =~ /n$/)
	&& $p->{'split_char'}) {
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

    do_log('debug2', 'List::load_cert(%s)',$self->{'name'});

    # we only send the encryption certificate: this is what the user
    # needs to send mail to the list; if he ever gets anything signed,
    # it will have the respective cert attached anyways.
    # (the problem is that netscape, opera and IE can't only
    # read the first cert in a file)
    my($certs,$keys) = tools::smime_find_keys($self->{dir},'encrypt');
    unless(open(CERT, $certs)) {
	do_log('err', "List::get_cert(): Unable to open $certs: $!");
	return undef;
    }

    my(@cert, $state);
    while(<CERT>) {
	chomp;
	if($state == 1) {
	    # convert to CRLF for windows clients
	    push(@cert, "$_\r\n");
	    if(/^-+END/) {
		last;
	    }
	}elsif (/^-+BEGIN/) {
	    $state = 1;
	}
    }
    close CERT ;
    
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
	$admin{'defaults'}{$pname} = 1;
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
	    &do_log('info', 'Bad paragraph "%s" in %s', @paragraph, $config_file);
	    next;
	}
	    
	$pname = $1;

	## Parameter aliases (compatibility concerns)
	if (defined $alias{$pname}) {
	    $paragraph[0] =~ s/^\s*$pname/$alias{$pname}/;
	    $pname = $alias{$pname};
	}
	
	unless (defined $::pinfo{$pname}) {
	    &do_log('info', 'Unknown parameter "%s" in %s', $pname, $config_file);
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
		&do_log('info', 'Expecting a paragraph for "%s" parameter in %s', $pname, $config_file);
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
	    return undef;
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
    my $file_url = "$wwsympa_url/attach/$listname$dir/$filename";

    my $parser = new MIME::Parser;
    $parser->output_to_core(1);
    my @new_part;
    &parser::parse_tpl({'file_name' => $file_name,
			'file_url'  => $file_url,
			'file_size' => $size },
		       &tools::get_filename('etc', 'templates/urlized_part.'.$list->{'admin'}{'lang'}.'.tpl', $robot, $list),
		       \@new_part);

    my $entity = $parser->parse_data(\@new_part);

    return $entity;
}

sub store_subscription_request {
    my ($self, $email, $gecos) = @_;
    do_log('debug2', 'List::store_subscription_request(%s, %s, %s)', $self->{'name'}, $email, $gecos);

    my $filename = $Conf{'queuesubscribe'}.'/'.$self->{'name'}.'.'.time.'.'.int(rand(1000));
    
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
	&do_log('info', 'Unable to read spool %s', $Conf{'queuemod'});
	return undef;
    }

    foreach my $filename (sort grep(/^$self->{'name'}\.\d+\.\d+$/, readdir SPOOL)) {
	unless (open REQUEST, "$Conf{'queuesubscribe'}/$filename") {
	    do_log('notice', 'Could not open %s', $filename);
	    closedir SPOOL;
	    return undef;
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

	$filename =~ /^$self->{'name'}\.(\d+)\.\d+$/;
	$subscriptions{$email}{'date'} = $1;
	close REQUEST;
    }
    closedir SPOOL;

    return \%subscriptions;
} 

sub delete_subscription_request {
    my ($self, $email) = @_;
    do_log('debug2', 'List::delete_subscription_request(%s, %s)', $self->{'name'}, $email);

    unless (opendir SPOOL, $Conf{'queuesubscribe'}) {
	&do_log('info', 'Unable to read spool %s', $Conf{'queuemod'});
	return undef;
    }

    my $removed_file = 0;
    foreach my $filename (sort grep(/^$self->{'name'}\.\d+\.\d+$/, readdir SPOOL)) {
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

    # do_log('notice',"$dir/$self->{'name'}\@$self->{'domain'}");
    return tools::get_dir_size("$dir/$self->{'name'}\@$self->{'domain'}");
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

    my $statement_value = sprintf "VALUES ('',%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)", $date,$dbh->quote($$),$dbh->quote($process),$dbh->quote($email_user),$dbh->quote($auth),$dbh->quote($ip),$dbh->quote($ope),$dbh->quote($list),$dbh->quote($robot),$dbh->quote($arg),$dbh->quote($status),$dbh->quote($subscriber_count);		    
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

    do_log('info',"xxxxxxxxxxxxxx statement $statement ");

    unless ($sth = $dbh->prepare($statement)) {
	do_log('err','Unable to prepare SQL statement : %s', $dbh->errstr);
	return undef;
    }
    
    unless ($sth->execute) {
	do_log('err','Unable to execute SQL statement "%s" : %s', $statement, $dbh->errstr);
	return undef;
    }

    do_log('info',"xxxxxxxxxxxxxx found 1");
  
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

## Close the list (remove from DB, remove aliases, change status to 'closed')
sub close {
    my ($self, $email) = @_;

    return undef 
	unless ($self && ($list_of_lists{$self->{'name'}}));
    
    ## Dump subscribers
    $self->_save_users_file("$self->{'dir'}/subscribers.closed.dump");

    ## Delete users
    my @users;
    for ( my $user = $self->get_first_user(); $user; $user = $self->get_next_user() ){
	push @users, $user->{'email'};
    }
    $self->delete_user(@users);

    ## Change status & save config
    $self->{'admin'}{'status'} = 'closed';
    $self->{'admin'}{'defaults'}{'status'} = 0;

    $self->save_config($email);
    $self->savestats();
    
    $self->remove_aliases();    
    
    return 1;
}

## Remove list aliases
sub remove_aliases {
    my $self = shift;

    return undef 
	unless ($self && ($list_of_lists{$self->{'name'}}));
    
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
      &do_log('info','error while calling sub delete_users');
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
	$self->send_notify_to_subscriber('auto_notify_bouncers',$user);
    }
    return 1;
}


#################################################################

## Packages must return true.
1;




