Információk a(z) [list->name]@[list->host] listáról:

Tárgy                 : [subject]
[FOREACH o IN owner]
Tulajdonos            : [o->gecos] <[o->email]>
[END]
[FOREACH e IN editor]
Moderátor             : [e->gecos] <[e->email]>
[END]
Feliratkozás          : [subscribe]
Leiratkozás           : [unsubscribe]
Levelek küldése       : [send]
Tagok listája         : [review]
Válasz cím            : [reply_to]
Maximális méret       : [max_size]
[IF digest]
Digest                : [digest]
[ENDIF]
Fogadási mód          : [available_reception_mode]
Lista web címe	      : [url]

[PARSE 'info']
