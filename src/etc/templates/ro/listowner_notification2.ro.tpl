From: [conf->email]@[conf->host]
To: Listowners <[to]>
[IF type=arc_quota_exceeded]
Subject: Quota pentru lista "[list->name]" e in exces

[list->name]@[list->host] Arhiva a depasit limita admisa. Marimea maxima
folosit pentru arhiva la lista [list->name]@[list->host] este [size] Bytes. 
Mesajele viitoare nu vor mai fi arhivate. Contacteaza listmaster@[conf->host]. 

[ELSIF type=arc_quota_95]
Subject: ATENTIE Arhiva la lista "[list->name]": [rate]% e plin

[rate2]
[list->name]@[list->host] Arhiva foloseste [rate]% din spatiu acordat.
Marimea totala pentru arhiva la lista [list->name]@[list->host] este [size] Bytes.

Mesajele sunt inca arhivate, dar ar trebui contactat listmaster@[conf->host]. 
[ENDIF]
