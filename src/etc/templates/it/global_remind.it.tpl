
Riassunto delle sue iscrizioni (con l'indirizzo [user->email]).

Questo messaggio e' solamente informativo: se non vuole modificare
le sue iscrizioni, non deve fare nulla.

Ecco per ciascuna lista un link per cancellare l'iscrizione :


-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
[FOREACH l IN list]
[l]     mailto:[conf->sympa]?subject=sig%20[l]%20[user->email]
[END]
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

[IF user->password]

Per identificarsi su  [conf->wwsympa_url] , il suo
indirizzo di login e' [user->email], la sua password [user->password]

[ENDIF]

