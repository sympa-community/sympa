From: [conf->sympa]
Reply-to: [conf->request]
To: [newuser->email]
[IF action=subrequest]
Subject: [conf->title] / tilaus listalle [list]
[ELSIF action=sigrequest]
Subject: [conf->title] / tilauksen poisto listalle [list]
[ELSE]
Subject: [conf->title] / asetuksesi
[ENDIF]

[IF action=subrequest]
Pyysit tilausta postituslistalle [list].

Varmistaaksesi tilauksen, sinun tulee antaa salasana

	salasana: [newuser->password]

[ELSIF action=sigrequest]
Pyysit tilauksen poistoa listalta [list].

Varmistaaksesi tilauksen poisto, sinun tulee antaa salasana

	salasana: [newuser->password]

[ELSE]
Päästäksesi käsiksi asetuksiisi, sinun tulee kirjautua ensin

     email osoitteesi   : [newuser->email]
     salasanasi : [newuser->password]

Salasanan vaihto
[base_url][path_cgi]/choosepasswd/[newuser->escaped_email]/[newuser->password]
[ENDIF]


[conf->title]: [base_url][path_cgi] 

Apua Sympan käyttöön: [base_url][path_cgi]/help

