From: [conf->email]@[conf->host]
To: Listmaster <[to]>
[IF lang=fr]
Subject: Demande de creation de la liste "[list->name]"

Une demande de création pour la liste "[list->name]" a été faite par [email]

[list->name]@[list->host]
[list->subject]
[conf->wwsympa_url]/info/[list->name]

Pour activer/supprimer cette liste :
[conf->wwsympa_url]/get_pending_lists

[ELSE]
Subject: List "[list->name]" creation request

[email] requested creation of list "[list->name]"

[list->name]@[list->host]
[list->subject]
[conf->wwsympa_url]/info/[list->name]

To activate/delete this mailing list :
[conf->wwsympa_url]/get_pending_lists

[ENDIF]