
Souhrn Va¹eho èlenství v konferencích (pøi pou¾ití adresy 
[user->email]).
Pokud se chcete odhlásit z nìjaké konference, ulo¾te si tuto zprávu.

Pro ka¾dou konferenci je zde odkaz, kterým se mù¾ete odhlásit.

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
[FOREACH l IN lists]
[l]     mailto:[conf->sympa]?subject=sig%20[l]%20[user->email]
[END]
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

[IF user->password]

Pro ovìøení toto¾nosti na WWW rozhraní 
na adrese [conf->wwsympa_url]
pou¾ijte svoji emailovou adresu [user->email] 
a svoje heslo [user->password]

[ENDIF]

