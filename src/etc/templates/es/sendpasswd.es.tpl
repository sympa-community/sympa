From: [conf->sympa]
Reply-to: [conf->request]
To: [newuser->email]
Subject: Your WWSympa environment

[IF init_passwd]
  [IF action=subrequest]
Usted solicitó subscribirse a la lista de correo [list].

Para confirmar esta operación, siga este enlace:
[base_url][path_cgi]/subscribe/[list]/[newuser->escaped_email]/[newuser->password]

o utilice esta contraseña :

	Contraseña : [newuser->password]

  [ELSIF action=sigrequest]
Usted solicitó anular su subscripción a la lista [list].

Para confirmar esta operación, siga este enlace:
[base_url][path_cgi]/signoff/[list]/[newuser->escaped_email]/[newuser->password]

o utilice esta contraseña :

	Contraseña : [newuser->password]

  [ELSE]
Usted solicitó una cuenta en WWSympa.

Para escoger su contraseña, rellene el siguiente formulario:
[base_url][path_cgi]/login/[newuser->escaped_email]/[newuser->password]

o utilice esta contraseña :

	Contraseña : [newuser->password]

  [ENDIF]
Escoja su contraseña : [base_url][path_cgi]/choosepasswd/[newuser->escaped_email]/[newuser->password]
[ELSE]
Recordatorio de su contraseña de WWSympa 

	Contraseña : [newuser->password]

Cambiar su contraseña : [base_url][path_cgi]/choosepasswd
[ENDIF]
Ayuda de WWSympa : [base_url][path_cgi]/help
