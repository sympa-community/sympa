Informations sur la liste [list->name]@[list->host] :

Sujet              : [subject]
[FOREACH o IN owner]
Propriétaire       : [o->gecos] <[o->email]>
[END]
[FOREACH e IN editor]
Modérateur         : [e->gecos] <[e->email]>
[END]
Abonnement         : [subscribe]
Désabonnement      : [unsubscribe]
Envoi de messages  : [send]
Liste des abonnés  : [review]
Réponse à          : [reply_to]
Taille maximale    : [max_size]
[IF digest]
Digest             : [digest]
[ENDIF]
Modes de réception : [available_reception_mode]
Page web           : [url]

[PARSE 'info']
