Informace o konferenciInformazioni sulla lista [list->name]@[list->host] :

Oggetto               : [subject]
[FOREACH o IN owner]
Gestore               : [o->gecos] <[o->email]>
[END]
[FOREACH e IN editor]
Moderatore            : [e->gecos] <[e->email]>
[END]
Iscrizione            : [subscribe]
Iscrizione cancellata : [unsubscribe]
Invio di messaggi     : [send]
Lista degli iscritti  : [review]
Rispondere a          : [reply_to]
Dimensione massima    : [max_size]
[IF digest]
Riassunto             : [digest]
[ENDIF]
Reception modes       : [available_reception_mode]

[PARSE 'info']
