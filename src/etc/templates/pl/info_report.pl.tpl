Informacje na temat listy[list->name]@[list->host] :

Temat                 : [subject]
[FOREACH o IN owner]
Administrator         : [o->gecos] <[o->email]>
[END]
[FOREACH e IN editor]
Moderator             : [e->gecos] <[e->email]>
[END]
Zapisanie             : [subscribe]
Wypisanie             : [unsubscribe]
Wysy³anie listów      : [send]
Lista zapisanych      : [review]
Odpowiedzi na         : [reply_to]
Limit rozmiaru        : [max_size]
[IF digest]
Digest                : [digest]
[ENDIF]
Reception modes       : [available_reception_mode]
Homepage	      : [url]

[PARSE 'info']
