From: [conf->sympa]
Reply-to: [conf->request]
To: [newuser->email]
[IF action=subrequest]
Subject: [conf->title] / liitumine listiga [list]
[ELSIF action=sigrequest]
Subject: [conf->title] / lakumine listist [list]
[ELSE]
Subject: [conf->title] / info teie konto kohta
[ENDIF]

[IF action=subrequest]
Te soovisite liituda listiga [list].

Oma soovi kinnitamiseks peate kasutama järgnevat parooli:

	parool: [newuser->password]

[ELSIF action=sigrequest]
Te soovisite lahkuda listist [list].

Oma soovi kinnitamiseks peate kasutama järgnevat parooli:

	parool: [newuser->password]

[ELSE]
Sympa veebilehe kõikide võimaluste kasutamiseks peate esmalt lehele sisenema:

     teie e-posti aadress    : [newuser->email]
     teie parool             : [newuser->password]

Oma parooli saate vahetada siit:
[base_url][path_cgi]/choosepasswd/[newuser->escaped_email]/[newuser->password]
[ENDIF]


[conf->title]: [base_url][path_cgi] 

Abi Sympa kohta: [base_url][path_cgi]/help

