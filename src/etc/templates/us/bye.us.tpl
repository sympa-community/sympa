From: [conf->email]@[conf->host]
[IF  list->lang=fr]
Subject: Desabonnement [list->name]
Mime-version: 1.0
Content-Type: text/plain; charset=iso-8859-1
Content-transfer-encoding: 8bit

 Vous ([user->email]) êtes désabonné de la liste  [list->name]@[list->host] 
 Au revoir !

[ELSIF list->lang=es]
Subject: Anulación subscripción a [list->name]
Mime-version: 1.0
Content-Type: text/plain; charset=iso-8859-1
Content-transfer-encoding: 8bit

 Su dirección ([user->email]) ha sido suprimida de la lista [list->name]@[list->host] 
 Gracias por su colaboración y hasta pronto !

[ELSIF list->lang=it]
From: [conf->email]@[conf->host]
Subject: Cancellazione iscrizione [list->name]
Mime-version: 1.0
Content-Type: text/plain; charset=iso-8859-1
Content-transfer-encoding: 8bit

 Il suo indirizzo [user->email] e' stato cancellato dalla lista [list->name]@[list->host]
 Grazie per avere usato questa lista.
 Arrivederci !

[ELSIF list->lang=pl]
From: [conf->email]@[conf->host]
Subject: Wypisanie z listy [list->name]
Mime-version: 1.0
Content-Type: text/plain; charset=iso-8859-2
Content-transfer-encoding: 8bit

 Twój adres email [user->email] zosta³ wypisany z listy [list->name]@[list->host]
 Do widzenia!

[ELSE]
Subject: Unsubscription from [list->name]

 Your email address ([user->email]) has been removed from list [list->name]@[list->host]
 bye !

[ENDIF]

