From: [conf->sympa]
Reply-to: [conf->request]
To: [newuser->email]
[IF action=subrequest]
Subject: [conf->title] / inschrijven voor [list]
[ELSIF action=sigrequest]
Subject: [conf->title] / uitschrijven van [list]
[ELSE]
Subject: [conf->title] / uw omgeving
[ENDIF]

[IF action=subrequest]
U vroeg om een inschrijving voor de [list] mailinglijst.

Om uw inschrijving te bevestigen, heeft u het volgende wachtwoord nodig

	password: [newuser->password]

[ELSIF action=sigrequest]
U vroeg om u uit te schrijven van de [list] mailinglijst.

Om uit te schrijven van de lijst, heeft u het volgende wachtwoord nodig

	password: [newuser->password]

[ELSE]
Voor toegang tot uw persoonlijke omgeving dient uw eerst in te loggen

     uw emailadres    : [newuser->email]
     uw wachtwoord    : [newuser->password]

Uw wachtwoord veradneren
[base_url][path_cgi]/choosepasswd/[newuser->escaped_email]/[newuser->password]
[ENDIF]


[conf->title]: [base_url][path_cgi] 

Hulp voor Sympa: [base_url][path_cgi]/help

