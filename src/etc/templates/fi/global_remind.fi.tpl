
Yhteenveto tilauksestasi (käyttäen osoitetta [user->email]).
Jos haluat poistaa tilauksen joltain listalta, tallenna tämä viesti.


Foreach lista tässä on osoite jota käyttää jos haluat poistaa tilauksen.

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
[FOREACH l IN lists]
[l]	mailto:[conf->sympa]?subject=sig%20[l]%20[user->email]
[END]
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

[IF user->password]

Kirjautuaksesi WWSympaan [conf->wwsympa_url]
käytä email osoitetta [user->email] ja salasanaa [user->password]


