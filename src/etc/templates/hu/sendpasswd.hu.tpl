From: [conf->sympa]
Reply-to: [conf->request]
To: [newuser->email]
[IF action=subrequest]
Subject: [conf->title] / feliratkozás a(z) [list] listára
[ELSIF action=sigrequest]
Subject: [conf->title] / leiratkozás a(z) [list] listáról
[ELSE]
Subject: [conf->title] / beállításaid
[ENDIF]
Mime-version: 1.0
Content-Type: text/plain; charset=iso-8859-2
Content-transfer-encoding: 8bit

[IF action=subrequest]
Ha tényleg fel szeretnél iratkozni a(z) [list] levelezõlistára,
akkor a kérelmedet a következõ jelszóval meg kell erõsítened:

	jelszó: [newuser->password]

[ELSIF action=sigrequest]
Ha tényleg törölni szeretnéd magadat a(z) [list] levelezõlistáról,
akkor azt a következõ jelszóval meg kell erõsítened:

	jelszó: [newuser->password]

[ELSE]
Beállításaid megtekintéséhez elõször is be kell lépned

     e-mail címed: [newuser->email]
     jelszavad   : [newuser->password]

A jelszavadat az alábbi címen tudod megváltoztatni 
[base_url][path_cgi]/choosepasswd/[newuser->escaped_email]/[newuser->password]
[ENDIF]


[conf->title]: [base_url][path_cgi] 

Súgó a Sympa használatához: [base_url][path_cgi]/help
