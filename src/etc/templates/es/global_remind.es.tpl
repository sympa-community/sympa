
Sumario de su subscripción (con e-mail [user->email]).
Si usted quiere anular la subscripción de alguna lista, conserve este mail.

Por cada lista existe un método para anular la subscripción:

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
[FOREACH l IN lists]
[l]   mailto:[conf->sympa]?subject=sig%20[l]%20[user->email]
[END]
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

[IF user->password]

Para autentificarse usando el interface web wwsympa [conf->wwsympa_url]
utilice su e-mail [user->email] y su contraseña [user->password]

[ENDIF]

