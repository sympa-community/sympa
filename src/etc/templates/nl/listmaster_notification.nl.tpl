From: [conf->email]@[conf->host]
To: Listmaster <[to]>
[IF type=request_list_creation]
Subject: List "[list->name]" creation request

[email] Aanvraag voor aanmaken van lijst "[list->name]"

[list->name]@[list->host]
[list->subject]
[conf->wwsympa_url]/info/[list->name]

Om deze lijst te activeren/verwijderen :
[conf->wwsympa_url]/get_pending_lists
[ELSIF type=virus_scan_failed]
Subject: Antivirus scan mislukt

De antivirus controle ging niet goed bij het verwerken van het volgende bestand:
	[filename]

De foutmelding die terugkwam :
	[error_msg]
[ELSIF type=edit_list_error]
Subject: fout formaat van edit_list.conf

edit_list.conf formaat is veranderd :
'default' is niet meer een mode die geaccepteerd wordt voor de populatie.

Zie de documentatie voor  [param0].
Tot die tijd bevelen we aan om [param0] te verwijderen; 
De standaard configuratie zal gebruikt worden.
[ENDIF]
