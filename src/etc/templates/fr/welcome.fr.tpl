From: [conf->email]@[conf->host]
Subject: Bienvenue sur la liste [list->name]
Mime-version: 1.0
Content-Type: multipart/alternative; boundary="===Sympa==="

--===Sympa===
Content-Type: text/plain; charset=iso-8859-1
Content-transfer-encoding: 8bit

Bienvenue dans la liste [list->name]

[INCLUDE 'info']

Votre adresse d'abonnement est : [user->email]

Pour envoyer un message diffusé à tous les abonnés, écrivez à la liste elle-même :
    [list->name]@[list->host]

Pour toutes les commandes concernant votre abonnement, n'écrivez pas à la liste, mais à :
    [conf->sympa]

Pour avoir la liste des commandes disponibles, postez un mél à l'adresse ci-dessus en écrivant HELP dans le sujet ou le corps du message.

Vous pouvez aussi utiliser une interface web en vous rendant à :
    [conf->wwsympa_url]/info/[list->name]

[IF user->password]
Votre mot de passe pour les commandes par web est : [user->password]
[ENDIF]

   ---

Si vous voulez vous désabonner de cette liste, envoyez simplement un mel vide à :
    [list->name]-unsubscribe@[list->host] 

ou bien utilisez l'interface web (bouton désabonnement).

--===Sympa===
Content-Type: text/html; charset=iso-8859-1
Content-transfer-encoding: 8bit

<HTML>
<HEAD>
<TITLE>Bienvenue dans la liste [list->name]@[list->host]</title>
<BODY  BGCOLOR=#ffffff>

Bienvenue sur la liste [list->name]
<br><br>
<PRE>
[INCLUDE 'info']
</PRE>
<br><br> 
Votre adresse d'abonnement est : [user->email] 
<br><br>
Pour envoyer un message diffusé à tous les abonnés, écrivez à la liste elle-même :<br>
    mailto:[list->name]@[list->host]
<br><br>
Pour toutes les commandes concernant votre abonnement, n'écrivez pas à la liste, mais à :<br>
    mailto:[conf->sympa]
<br><br>
Pour avoir la liste des commandes disponibles, postez un mél à l'adresse ci-dessus en écrivant HELP dans le sujet ou le corps du message.
<br><br>
Vous pouvez aussi utiliser une interface web en vous rendant à :
    [conf->wwsympa_url]/info/[list->name]        
<br><br>       
[IF user->password]<br> 
Votre mot de passe pour les commandes par web est : [user->password]
[ENDIF]   
<br>
   ---
<br>
Si vous voulez vous désabonner de cette liste, envoyez simplement un mel vide à :<br>
    mailto:[list->name]-unsubscribe@[list->host]                         
<br><br>
ou bien utilisez l'interface web (bouton désabonnement).

</BODY></HTML>
--===Sympa===--
