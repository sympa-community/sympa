Información acerca de la lista [list->name]@[list->host] :

Tema normal           : [subject]
[FOREACH o IN owner]
Propietario           : [o->gecos] <[o->email]>
[END]
[FOREACH e IN editor]
Moderador             : [e->gecos] <[e->email]>
[END]
Suscripción           : [subscribe]
Supresión             : [unsubscribe]
Enviando mensajes     : [send]
Lista de suscriptores : [review]
Respuesta a           : [reply_to]
Tamaño Máximo         : [max_size]
[IF digest]
Resumen               : [digest]
[ENDIF]
Modo de recepción     : [available_reception_mode]

[PARSE 'info']
