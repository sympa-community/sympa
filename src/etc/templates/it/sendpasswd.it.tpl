From: [conf->sympa]
Reply-to: [conf->request]
To: [newuser->email]
Subject: Le tue preferenze di [wwsconf->title]

[IF action=subrequest]
Hai richiesto la sottoscrizione alla lista [list].

Per confermare la tua iscrizione, usa questo link
[base_url][path_cgi]/subscribe/[list]/[newuser->escaped_email]/[newuser->password]

[ELSIF action=sigrequest]
Hai richiesto la cancellazione della tua sottoscrizione alla lista [list].

Per confermare la tua iscrizione, usa questo link
[base_url][path_cgi]/signoff/[list]/[newuser->escaped_email]/[newuser->password]

[ENDIF]

[wwsconf->title]
[base_url][path_cgi]

Per accedere alle tue sottoscrizioni
      Email           : [newuser->email]
      La tua password : [newuser->password]

Per scegliere la tua password, segui questo link
[base_url][path_cgi]/login/[newuser->escaped_email]/[newuser->password]

Aiuto per WWSympa
[base_url][path_cgi]/help
