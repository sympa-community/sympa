Tietoja listasta [list->name]@[list->host] :

Otsikko            : [subject]
[FOREACH o IN owner]
Omistaja              : [o->gecos] <[o->email]>
[END]
[FOREACH e IN editor]
Hallitsija          : [e->gecos] <[e->email]>
[END]
Tilaus       : [subscribe]
Tilauksen poisto   : [unsubscribe]
Viestien lähetys   : [send]
Katso tilaajat     : [review]
Vastausosoite      : [reply_to]
Max. koko          : [max_size]
[IF digest]
Kooste             : [digest]
[ENDIF]
Vastaanotto tilat  : [available_reception_mode]
Kotisivu           : [url]

[PARSE 'info']
