From: [conf->sympa]
Reply-to: [conf->request]
To: [newuser->email]
[IF action=subrequest]
Subject: [wwsconf->title] / Abonnement fuer [list]
[ELSIF action=sigrequest]
Subject: [wwsconf->title] / Abmeldung fuer [list]
[ELSE]
Subject: [wwsconf->title] / Ihre Einstellungen
[ENDIF]

[IF action=subrequest]
Sie haben ein Abonnement der Mailing-Liste [list] angefordert.

Um dies zu bestaetigen, geben Sie bitte folgendes Passwort an:

	Passwort: [newuser->password]

[ELSIF action=sigrequest]
Sie haben die Abmeldung von der Mailing-Liste [list] angefordet.

Um dies zu bestaetigen, geben Sie bitte folgendes Passwort an:

	Passwort: [newuser->password]

[ELSE]
Um Ihre persoenlichen Einstellungen zu benutzen, muessen Sie
sich zu erst anmelden:

     Ihre EMail-Adresse: [newuser->email]
     Ihr Passwort: [newuser->password]

Zum aendern Ihres Passwortes:
[base_url][path_cgi]/choosepasswd/[newuser->escaped_email]/[newuser->password]
[ENDIF]


[wwsconf->title]: [base_url][path_cgi] 

Hilfe ueber Sympa: [base_url][path_cgi]/help

