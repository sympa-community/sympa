Voici la liste des listes de [conf->email]@[robot_domain] :

[FOREACH l IN lists]
[l->NAME]@[l->host] : [l->subject]

[END]

-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_
mailto:[conf->listmaster]
