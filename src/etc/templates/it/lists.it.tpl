Ecco l'elenco delle liste di [conf->email]@[conf->host]

[FOREACH l IN lists]
[l->NAME]@[l->host] : [l->subject]

[END]

-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_
mailto:[conf->listmaster]
