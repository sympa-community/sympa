
Zusammenfassung Ihrer Abonnemente unter der der EMail-Adresse
[user->email]. Wenn Sie sich von einer der Listen abmelden wollen
können Sie einfach die angebenen mailtos benutzen:

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
[FOREACH l IN lists]
[l]     mailto:[conf->sympa]?subject=sig%20[l]%20[user->email]
[END]
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

[IF user->password]

Wenn Sie die Web-Schnittstelle [conf->wwsympa_url] benutzen wollen,
sollten Sie sich mit Ihrer EMail-Adresse [user->email] und Ihrem
Passwort [user->password] anmelden.

[ENDIF]

