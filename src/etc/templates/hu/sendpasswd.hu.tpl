From: [conf->sympa]
Reply-to: [conf->request]
To: [newuser->email]
[IF action=subrequest]
Subject: [wwsconf->title] / feliratkozás a(z) [list] listára
[ELSIF action=sigrequest]
Subject: [wwsconf->title] / leiratkozás a(z) [list] listáról
[ELSE]
Subject: [wwsconf->title] / beállításaid
[ENDIF]

[IF action=subrequest]
Feliratkozásodat kérted a(z) [list] levelezõlistára.

Feliratkozásodat a következõ jelszóval erõsítheted meg.

	jelszó: [newuser->password]

[ELSIF action=sigrequest]
Leiratkozásodat kérted a(z) [list] levelezõlistáról.

Leiratkozásodat a következõ jelszóval erõsítheted meg.

	jelszó: [newuser->password]

[ELSE]
Egyéni beállításaid megtekintéséhez be kell jelentkezned

     email címed  : [newuser->email]
     jelszavad    : [newuser->password]

Jelszavadat itt változtathatod meg
[base_url][path_cgi]/choosepasswd/[newuser->escaped_email]/[newuser->password]
[ENDIF]


[wwsconf->title]: [base_url][path_cgi] 

Súgó a Sympa használatához: [base_url][path_cgi]/help

