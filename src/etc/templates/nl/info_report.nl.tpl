Informatie over de lijst [list->name]@[list->host] :

Onderwerp            : [subject]
[FOREACH o IN owner]
Eigenaar              : [o->gecos] <[o->email]>
[END]
[FOREACH e IN editor]
Moderator          : [e->gecos] <[e->email]>
[END]
Inschrijven        : [subscribe]
Uitschrijven       : [unsubscribe]
Berichten sturen   : [send]
Abonnees tonen     : [review]
Antwoord aan       : [reply_to]
Maximum groote     : [max_size]
[IF digest]
Samenvatting       : [digest]
[ENDIF]
Ontvangst manieren : [available_reception_mode]
Thuispagina        : [url]

[PARSE 'info']
