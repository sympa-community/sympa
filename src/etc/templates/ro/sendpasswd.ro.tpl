From: [conf->sympa]
Reply-to: [conf->request]
To: [newuser->email]
[IF action=subrequest]
Subject: [conf->title] / abonare pe lista [list]
[ELSIF action=sigrequest]
Subject: [conf->title] / dezabonare from [list]
[ELSE]
Subject: [conf->title] / zona ta
[ENDIF]

[IF action=subrequest]
Ai cerut abonarea pe lista [list].

Pentru a confirma abonarea ta, trebuie sa trimiti urmatoarea parola:

	password: [newuser->password]

[ELSIF action=sigrequest]
Ai cerut dezabonarea pe lista [list].

Pentru a confirma dezabonarea ta, trebuie sa trimiti urmatoarea parola:

	password: [newuser->password]

[ELSE]
Pentru a avea acces la zona ta, trebuie sa fi autentificat

     adresa ta de mail: [newuser->email]
     parola ta: [newuser->password]

Pentru a schimba parola apasa pe: 
[base_url][path_cgi]/choosepasswd/[newuser->escaped_email]/[newuser->password]
[ENDIF]


[wwsconf->title]: [base_url][path_cgi] 

Ajutor Sympa: [base_url][path_cgi]/help

