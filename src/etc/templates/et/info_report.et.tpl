Info listi [list->name]@[list->host] kohta:

Teema              : [subject]
[FOREACH o IN owner]
Omanik             : [o->gecos] <[o->email]>
[END]
[FOREACH e IN editor]
Moderaator         : [e->gecos] <[e->email]>
[END]
Listiga liitumine  : [subscribe]
Listist lahkumine  : [unsubscribe]
Kirjade saatmine   : [send]
Listiliikmed       : [review]
Vastusaadress      : [reply_to]
Maks. kirja suurus : [max_size]
[IF digest]
Kokkuvõtted        : [digest]
[ENDIF]
Kasutusviisid      : [available_reception_mode]
Koduleht           : [url]

[PARSE 'info']
