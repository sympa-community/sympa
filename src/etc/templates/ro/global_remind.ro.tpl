
Descrierea abonarii tale (folosind adresa de e-mail [user->email]).
Daca vrei sa te dezabonezi de pe lista, salveaza acest mail.

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
[FOREACH l IN lists]
[l]	mailto:[conf->sympa]?subject=sig%20[l]%20[user->email]
[END]
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

[IF user->password]

Pentru a te autentifica in sistem folosind wwsympa [conf->wwsympa_url]
foloseste adresa ta de e-mail [user->email] si parola [user->password]


