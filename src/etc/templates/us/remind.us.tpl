From: [conf->email]@[conf->host]
[IF  list->lang=fr]
Subject: Rappel de votre abonnement [list->name]
Mime-version: 1.0
Content-Type: text/plain; charset=iso-8859-1
Content-transfer-encoding: 8bit

 Vous êtes abonné dans la liste  [list->name]@[list->host] avec l'adresse
[user->email] ;
votre mot de passe: [user->password]. 

Pour tout savoir sur cette liste : [conf->wwsympa_url]/info/[list->name]
Pour un désabonnement :
mailto:[conf->email]@[conf->host]?subject=sig%20[list->name]%20[user->email]

[ELSIF list->lang=es]
Subject: Recordatorio de su subscripción a [list->name]
Mime-version: 1.0
Content-Type: text/plain; charset=iso-8859-1
Content-transfer-encoding: 8bit

Usted es subscriptor de la lista [list->name]@[list->host] con el e-mail [user->email]
y su contraseña es : [user->password].

Información acerca de esta lista : [conf->wwsympa_url]/info/[list->name]
Para anular su subscripción :
mailto:[conf->email]@[conf->host]?subject=sig%20[list->name]%20[user->email]

[ELSIF list->lang=it]
Subject: Promemoria della sua iscrizione alla lista [list->name]
Mime-version: 1.0
Content-Type: text/plain; charset=iso-8859-1
Content-transfer-encoding: 8bit

 Lei e' iscritto alla lista [list->name]@[list->host] con l'indirizzo
[user->email] ;
la sua password e' [user->password].

Per cancellare l'iscrizione :
mailto:[conf->email]@[conf->host]?subject=sig%20[list->name]%20[user->email]

[ELSIF list->lang=pl]
Subject: Przypomnienie o zapisaniu na listê [list->name]
Mime-version: 1.0
Content-Type: text/plain; charset=iso-8859-2
Content-transfer-encoding: 8bit

 Przypominamy o sybskrypcji listy [list->name]@[list->host] z adresu
[user->email]
 Twoje has³o to : [user->password].

 Informacje o li¶cie : [conf->wwsympa_url]/info/[list->name]
 Wypisanie : mailto:[conf->email]@[conf->host]?subject=sig%20[list->name]%20[user->email]

[ELSIF list->lang=cz]
Subject: Pripomenuti Vaseho clenstvi v konferenci [list->name]
Mime-version: 1.0
Content-Type: text/plain; charset=iso-8859-2
Content-transfer-encoding: 8bit

 Jste èlenem konference [list->name]@[list->host]
 s adresou [user->email]
 Va¹e heslo je : [user->password].

 Informace o konferenci : [conf->wwsympa_url]/info/[list->name]
 Odhlá¹ení :
mailto:[conf->email]@[conf->host]?subject=sig%20[list->name]%20[user->email]

[ELSIF list->lang=de]
Subject: Erinnerung zu Ihrem Abonnent fuer [list->name]
Mime-version: 1.0
Content-Type: text/plain; charset=iso-8859-1
Content-transfer-encoding: 8bit

Sie sind Abonnent für die Mailing-Liste [list->name]@[list->host] unter
Ihrer Adresse [user->email] und dem Passwort [user->password].

Informationen über die Liste: [conf->wwsympa_url]/info/[list->name]
Abbestellen der Liste:
mailto:[conf->email]@[conf->host]?subject=sig%20[list->name]%20[user->email]

[ELSE]
Subject: Reminder of your subscribtion to [list->name]

Your are subscriber of list [list->name]@[list->host] with  email [user->email] 
your password : [user->password]. 

Everything about this list : [conf->wwsympa_url]/info/[list->name]
Unsubscribtion :
mailto:[conf->email]@[conf->host]?subject=sig%20[list->name]%20[user->email]
[ENDIF]

