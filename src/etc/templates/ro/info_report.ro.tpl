Informatii despre lista [list->name]@[list->host] :

Subiect            : [subject]
[FOREACH o IN owner]
Proprietar              : [o->gecos] <[o->email]>
[END]
[FOREACH e IN editor]
Moderator          : [e->gecos] <[e->email]>
[END]
Inscriere       : [subscribe]
Dezabonare     : [unsubscribe]
Trimitere mesaje   : [send]
Vizualizare abonati : [review]
Raspuns la           : [reply_to]
Marime maxima       : [max_size]
[IF digest]
Digest             : [digest]
[ENDIF]
Mod de primire    : [available_reception_mode]
Pagina lista           : [url]

[PARSE 'info']
