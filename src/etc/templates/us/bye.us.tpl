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
Subject: Cancellazione iscrizione [list->name]
Mime-version: 1.0
Content-Type: text/plain; charset=iso-8859-1
Content-transfer-encoding: 8bit

 Il suo indirizzo [user->email] e' stato cancellato dalla lista [list->name]@[list->host]
 Grazie per avere usato questa lista.
 Arrivederci !

[ELSIF list->lang=pl]
Subject: Wypisanie z listy [list->name]
Mime-version: 1.0
Content-Type: text/plain; charset=iso-8859-2
Content-transfer-encoding: 8bit

 Twój adres email [user->email] zosta³ wypisany z listy [list->name]@[list->host]
 Do widzenia!

[ELSIF list->lang=cz]
Subject: Odhlaseni z konference [list->name]
Mime-version: 1.0
Content-Type: text/plain; charset=iso-8859-2
Content-transfer-encoding: 8bit

 Va¹e emailová adresa [user->email] byla odstranìna ze seznamu 
 konference [list->name]@[list->host].
 Na shledanou!

[ELSIF list->lang=de]
Subject: Abmeldung von der Mailing-Liste [list->name]
Mime-version: 1.0
Content-Type: text/plain; charset=iso-8859-1
Content-transfer-encoding: 8bit

 Ihr Abonnement für die Mailing-Liste [list->name]@[list->host] unter der
 Adresse [user->email] wurde beendet.
 Auf Wiedersehen!

[ELSIF list->lang=hu]
Subject: [list->name] listáról leiratkozás
Mime-version: 1.0
Content-Type: text/plain; charset=iso-8859-2
Content-transfer-encoding: 8bit

 Email címed ([user->email]) törölve lett a(z) [list->name]@[list->host]
 levelezõlistáról!
 Viszlát!
 
[ELSE]
Subject: Unsubscription from [list->name]

 Your email address ([user->email]) has been removed from list [list->name]@[list->host]
 bye !

[ENDIF]

