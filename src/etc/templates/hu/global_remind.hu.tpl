
Értesítés a feliratkozásaidról ([user->email] címmel).
Ha valamelyik listáról le akarsz iratkozni, akkor mentsd el ezt a levelet.

Itt az összes listához megtalálod a leiratkozási címet.

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
[FOREACH l IN lists]
[l]     mailto:[conf->sympa]?subject=sig%20[l]%20[user->email]
[END]
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

[IF user->password]

A wwsympa [conf->wwsympa_url] belépésnél a(z) [user->email]
e-mail címet és [user->passwd] jelszót használd.

[ENDIF]
