Informace o konferenci [list->name]@[list->host] :

Subjekt               : [subject]
[FOREACH o IN owner]
Vlastník              : [o->gecos] <[o->email]>
[END]
[FOREACH e IN editor]
Moderátor             : [e->gecos] <[e->email]>
[END]
Pøihlá¹ení            : [subscribe]
Odhlá¹ení             : [unsubscribe]
Zasílání zpráv        : [send]
Seznam èlenù          : [review]
Odpovìï na            : [reply_to]
Maximální velikost    : [max_size]
[IF digest]
Shrnutí               : [digest]
[ENDIF]
Re¾im pøijímání zpráv : [available_reception_mode]
Domovská stránka      : [url]

[PARSE 'info']
