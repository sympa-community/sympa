
Synthèse de vos abonnements (avec l'adresse [user->email]).

Ce message est strictement informatif. Si vous ne souhaitez pas modifier
vos abonnements vous n'avez rien à faire, mais si vous souhaitez
vous désabonner de certaines listes, appliquez les instructions qui
suivent et conservez ce message.

Voici pour chaque liste une méthode de désabonnement :

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
[FOREACH l IN lists]
[l]	mailto:[conf->sympa]?subject=sig%20[l]%20[user->email]
[END]
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

[IF user->password]

Pour vous identifier sous [conf->wwsympa_url] :

     votre adresse électronique : [user->email]
     votre mot de passe         : [user->password]

[ENDIF]
