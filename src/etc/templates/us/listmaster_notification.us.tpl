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
[ENDIF]
