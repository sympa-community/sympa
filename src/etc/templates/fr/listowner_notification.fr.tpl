From: [conf->email]@[conf->host]
To: Propriétaires de liste <[to]>
[IF type=arc_quota_exceeded]
Subject: Quota des archives de la liste "[list->name]" dépassé

Le quota des archives de la liste [list->name]@[list->host] est
dépassé. La taille des archives est de [size] octets. Les messages
de la liste ne sont plus archivés. 
Veuillez contacter listmaster@[conf->host]. 

[ELSIF type=arc_quota_95]
Subject: Alerte liste "[list->name]" : archives pleines à [rate]%

[rate2]
Les archives de la liste [list->name]@[list->host] ont atteint [rate]% 
de l'espace autorisé. Les archives de la liste utilisent [size] octets.

L'archivage des messages est toujours assuré, mais vous devriez contacter
listmaster@[conf->host]. 

[ELSIF type=automatic_bounce_management]
Subject: Gestion automatique des abonnés en erreur de la liste [list->name]

[IF action=notify_bouncers]
Notre serveur ayant reçu de NOMBREUX rapports de non-remise, les [total] abonnés listés ci-dessous ont été
informés qu'ils risquaient d'être désabonné de la liste [list->name] :
[ELSIF action=remove_bouncers]
Notre serveur ayant reçu de NOMBREUX rapports de non-remise, les [total] abonnés listés ci-dessous ont été
désabonnés de la liste [list->name] :
[ELSIF action=none]
Notre serveur ayant reçu de NOMBREUX rapports de non-remise, les [total] abonnés listés ci-dessous ont été
marqués par Sympa comme des adresses gravement en erreur :
[ENDIF]

[FOREACH user IN  user_list]
[user]
[END]

[ENDIF]
