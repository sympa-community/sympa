From: [conf->email]@[conf->host]
To: Listmaster <[to]>
[IF type=request_list_creation]
Subject: List "[list->name]" creation request

[email] requested creation of list "[list->name]"

[list->name]@[list->host]
[list->subject]
[conf->wwsympa_url]/info/[list->name]

To activate/delete this mailing list :
[conf->wwsympa_url]/get_pending_lists
[ELSIF type=virus_scan_failed]
Subject: Antivirus scan failed

The antivirus scan has failed while processing the following file:
	[filename]

The returned error message :
	[error_msg]
[ELSIF type=edit_list_error]
Subject: incorrect format of edit_list.conf

edit_list.conf format has changed :
'default' is no mode accepted for a population.

Refer to documentation to adapt [param0].
Until then we recommend your remove [param0] ; 
default configuration will be used.

[ELSIF type=sync_include_failed]
Subject: subscribers update failed for list [param0]

Sympa could not include subscribers from external data sources ; the
database or LDAP directory might be unreachable. 
Check Sympa log files for more precise information

[ELSIF type=automatic_bounce_management]
Subject:List [list->name] automatic bounce management

[IF action=notify_bouncers]
Because we received MANY non-delivery reports, the [total] subsribers listed bellow have been
notified that they might be removed from list [list->name] :
[ELSIF action=remove_bouncers]
Because we received MANY non-delivery reports, the [total] subsribers listed bellow have been
removed from list [list->name] :
[ELSIF action=none]
Because we received MANY non-delivery reports, the [total] subsribers listed bellow have been
selected by Sympa as severe bouncing addresses :
[ENDIF]


[FOREACH user IN  user_list]
[user]
[END]

[ELSE]
Subject: [type]

[param0]
[ENDIF]

