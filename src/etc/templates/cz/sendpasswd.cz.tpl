From: [conf->sympa]
Reply-to: [conf->request]
To: [newuser->email]
[IF action=subrequest]
Subject: [conf->title] / prihlaseni se do konference [list]
[ELSIF action=sigrequest]
Subject: [conf->title] / odhlaseni se z konference [list]
[ELSE]
Subject: [conf->title] / vase prostredi
[ENDIF]
Mime-version: 1.0
Content-Type: text/plain; charset=iso-8859-2
Content-transfer-encoding: 8bit

[IF action=subrequest]
Po¾adoval jste pøihlá¹ení se do konference [list].

Pro potvrzení Va¹eho pøihlá¹ení, musíte poskytnout následující heslo

	heslo: [newuser->password]

[ELSIF action=sigrequest]
Po¾adoval jste odhlá¹ení se do konference [list].

Pro potvrzení Va¹eho odhlá¹ení, musíte poskytnout následující heslo

	heslo: [newuser->password]

[ELSE]
Pro pøístup k Va¹emu osobnímu prostredí se musíte nejprve pøihlásit

     Va¹e adresa  : [newuser->email]
     Va¹e heslo   : [newuser->password]

Pro zmìnu Va¹eho hesla:
[base_url][path_cgi]/choosepasswd/[newuser->escaped_email]/[newuser->password]
[ENDIF]

[conf->title]: [base_url][path_cgi] 

Nápovìda pro systém Sympa: [base_url][path_cgi]/help
