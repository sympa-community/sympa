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
[ENDIF]
