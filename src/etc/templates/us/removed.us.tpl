From: [conf->email]@[conf->host]
[IF  list->lang=fr]
Subject: Supprime de [list->name]
Mime-version: 1.0
Content-Type: text/plain; charset=iso-8859-1
Content-transfer-encoding: 8bit

 Votre adresse ([user->email]) a été supprimée de  la liste [list->name]@[list->host],
probablement parce que nous recevons des rapports d'anomalie concernant
cette adresse.

Vous pouvez cependant vous réabonner :
mailto:[conf->email]@[conf->host]?subject=sub%20[list->name]

[ELSIF list->lang=es]
Subject: Subscripción anulada de [list->name]
Mime-version: 1.0
Content-Type: text/plain; charset=iso-8859-1
Content-transfer-encoding: 8bit

Su dirección ([user->email]) ha sido anulada de la lista [list->name]@[list->host],
probablemente porque hemos recibido informes de errores de su e-mail.

Usted puede subscribirse otra vez mediante :
mailto:[conf->email]@[conf->host]?subject=sub%20[list->name]

[ELSIF list->lang=it]
Subject: Cancellazione dalla lista [list->name]
Mime-version: 1.0
Content-Type: text/plain; charset=iso-8859-1
Content-transfer-encoding: 8bit

 Il suo indirizzo ([user->email]) e' stato cancellato dalla lista
[list->name]@[list->host], probabilmente perche' riceviamo degli
errori riguardanti questo indirizzo.

Per iscriversi nuovamente :
mailto:[conf->email]@[conf->host]?subject=sub%20[list->name]

[ELSIF list->lang=pl]
Subject: Wypisanie z listy [list->name]
Mime-version: 1.0
Content-Type: text/plain; charset=iso-8859-2
Content-transfer-encoding: 8bit

 Twój adres ([user->email]) zosta³ wypisany z listy 
[list->name]@[list->host], prawdopodobnie dla tego, ¿e otrzymali¶my
zwroty listów wys³anych na niego.

Mo¿esz zapisaæ siê ponownie klikaj±c na link:
mailto:[conf->email]@[conf->host]?subject=sub%20[list->name]

[ELSE]
Subject: Removed from [list->name]


Your address ([user->email]) has been removed from list 
[list->name]@[list->host], probably because we received
non-delivery reports for your address.

You can subscribe again :
mailto:[conf->email]@[conf->host]?subject=sub%20[list->name]

[ENDIF]

