
Samenvatting van uw abonnement (met het emailadres [user->email]).
Wanneer u zich wilt uitschrijven van een lijst, bewaart u dan deze mail.

Voor elke lijst is een mailadres om te gebruiken wanneer u zich wilt uitschrijven.

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
[FOREACH l IN lists]
[l]	mailto:[conf->sympa]?subject=sig%20[l]%20[user->email]
[END]
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

[IF user->password]

Om in te loggen op de website [conf->wwsympa_url]
gebruik dan uw emailadres [user->email] en uw wachtwoord [user->password]


