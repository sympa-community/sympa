
Sumário de sua subscrição (com e-mail [user->email]).
Se você quiser anular a subscrição de alguma lista, conserve este mail.

Por cada lista existe um método para anular a subscrição:

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
[FOREACH l IN lists]
[l]   mailto:[conf->sympa]?subject=sig%20[l]%20[user->email]
[END]
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

[IF user->password]

Para se autentificar usando o interface web wwsympa [conf->wwsympa_url]
utilize seu e-mail [user->email] y sua clave [user->password]

[ENDIF]

