[IF  user->lang=fr]
Voici la liste des listes de [conf->email]@[conf->host]

[ELSIF user->lang=es]
Directorio de las listas de [conf->email]@[conf->host]

[ELSIF user->lang=it]
Ecco l'elenco delle liste di [conf->email]@[conf->host]

[ELSIF user->lang=pl]
Oto lista list od [conf->email]@[conf->host]

[ELSIF user->lang=cz]
Zde je seznam konferencí [conf->email]@[conf->host]

[ELSIF user->lang=de]
Hier ist eine Übersicht der Mailing-Listen von [conf->email]@[conf->host]

[ELSIF user->lang=hu]
[conf->email]@[conf->host] gépen található levelezõlisták sora

[ELSE]
Here is the list of list from [conf->email]@[conf->host]

[ENDIF]

[FOREACH l IN lists]
[l->NAME]@[l->host] : [l->subject]

[END]

-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_
mailto:[conf->listmaster]
