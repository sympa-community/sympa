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
[ENDIF]
