From: [conf->email]@[conf->host]
To: Listmaster <[to]>
[IF type=request_list_creation]
Subject: Demande de création de la liste "[list->name]"

Une demande de création pour la liste "[list->name]" a été faite par [email].

[list->name]@[list->host]
[list->subject]
[conf->wwsympa_url]/info/[list->name]

Pour activer/supprimer cette liste :
[conf->wwsympa_url]/get_pending_lists
[ELSIF type=virus_scan_failed]
Subject: Echec de la détection antivirale

L'appel à l'antivirus a échoué lors du traitement du fichier suivant :
	[filename]

Le message d'erreur est :
	[error_msg]
[error_msg]
[ELSIF type=edit_list_error]
Subject: Format incorrect de edit_list.conf

Le format du fichier de configuration edit_list.conf a changé :
'default' n'est plus reconnu pour une population.

Reportez-vous à la documentation pour adapter [param0].
D'ici là, nous vous suggérons de supprimer [param0].
La configuration par défaut sera utilisée.
[ELSIF type=sync_include_failed]
Subject: problème de mise à jour des membres de la liste [param0]

Sympa n'a pas pu mettre à jour la liste des membres à partir des sources de 
données externes ; la base de données ou l'annuaire LDAP ne sont probablement
pas intérogeables.
Consultez les logs de Sympa pour plus de précisions.
[ELSE]
Subject: [type]

[param0]

[ENDIF]
