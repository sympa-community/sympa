
Summary of your subscription (using the e-mail [user->email]).
If you want to unsubscribe from some list, please save this mail.

Foreach list here is a mailto to use if you want to unsubscribe.

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
[FOREACH l IN lists]
[l]	mailto:[conf->sympa]?subject=sig%20[l]%20[user->email]
[END]
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

[IF user->password]

In order to authenticate your self using wwsympa [conf->wwsympa_url]
use your e-mail [user->email] and your password [user->password]


