
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
u¿yj swojego adresu email [user->email] i swojego has³a [user->password]

[ENDIF]

