
[IF user->lang=fr]

Synthèse de vos abonnements (avec l'adresse [user->email]).

Ce message est strictement informatif, si vous ne souhaitez pas modifier
vos abonnements vous n'avez rien à entreprendre ; mais si vous souhaitez
vous désabonner de certaines listes, conservez bien ce message.

Voici pour chaque liste  une méthode de désabonnement :


-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
[FOREACH l IN lists]
[l]	mailto:[conf->sympa]?subject=sig%20[l]%20[user->email]
[END]
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

[IF user->password]

Pour vous identifier sous  [conf->wwsympa_url] , votre adresse
de login est [user->email], votre mot de passe [user->passwd]

[ENDIF]

[ELSIF user->lang=es]
Sumario de su subscripción (con e-mail [user->email]).
Si usted quiere anular la subscripción de alguna lista, conserve este mail.

Por cada lista existe un método para anular la subscripción:

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
[FOREACH l IN lists]
[l]   mailto:[conf->sympa]?subject=sig%20[l]%20[user->email]
[END]
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

[IF user->password]

Para autentificarse usando el interface web wwsympa [conf->wwsympa_url]
utilice su e-mail [user->email] y su contraseña [user->passwd]

[ENDIF]

[ELSIF user->lang=it]
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
indirizzo di login e' [user->email], la sua password [user->passwd]

[ENDIF]

[ELSIF user->lang=pl]
Podsumowanie twojego uczestnictwa na li¶cie (u¿ywaj±c adresu [user->email]).
Je¿eli chcesz siê wypisaæ z listy zachowaj ten list.

Dla ka¿dej listy mo¿esz klikn±æ na link ¿eby wypisaæ swój adres.

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
[FOREACH l IN lists]
[l]     mailto:[conf->sympa]?subject=sig%20[l]%20[user->email]
[END]
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

[IF user->password]

Aby zalogowaæ siê do interfejsu WWW pod adresem [conf->wwsympa_url]
u¿yj swojego adresu email [user->email] i swojego has³a [user->passwd]

[ENDIF]

[ELSIF user->lang=cz]
Mime-version: 1.0
Content-Type: text/plain; charset=iso-8859-2
Content-transfer-encoding: 8bit

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
a svoje heslo [user->passwd]

[ENDIF]

[ELSE]
Summary of your subscription (using the e-mail [user->email]).
If you want to unsubscribe from some list, please save this mail.

Foreach list here is a mailto to use if you want to unsubscribe.

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
[FOREACH l IN lists]
[l]	mailto:[conf->sympa]?subject=sig%20[l]%20[user->email]
[END]
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

[IF user->password]

In order to authenticate your self using wwsympa [conf->wwsympa_url]
use your e-mail [user->email] and your password [user->passwd]

[ENDIF]


