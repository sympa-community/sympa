From: [conf->email]@[conf->host]
To: Listmaster <[to]>
[IF type=request_list_creation]
Subject: Listan "[list->name]" luonti pyyntˆ

[email] pyysi listan "[list->name]" luontia

[list->name]@[list->host]
[list->subject]
[conf->wwsympa_url]/info/[list->name]

Aktivoidaksesi/poistaaksesi listan :
[conf->wwsympa_url]/get_pending_lists
[ELSIF type=virus_scan_failed]
Subject: Antivirus skannaus ep‰onnistui

Antivirus ohjelmisto ep‰onnistui seuraavan tiedoston skannauksessa:
	[filename]

Saatu virheilmoitus :
	[error_msg]
[ELSIF type=edit_list_error]
Subject: edit_list.conf muoto v‰‰rin

edit_list.conf muoto on muuttunut :
'default' ei hyv‰ksyt‰ tilaksi.

Tarkista dokumentaatiosta parametri [param0].
Kunnes olet sen tehnyt, suosittelemme parametrin [param0] poistoa ;
oletusasetuksia tullaan k‰ytt‰m‰‰n.
[ENDIF]
