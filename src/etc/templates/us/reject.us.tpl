From: [conf->email]@[conf->host]
[IF  list->lang=fr]
Subject: Rejet de votre message
Mime-version: 1.0
Content-Type: text/plain; charset=iso-8859-1
Content-transfer-encoding: 8bit

Votre message pour la liste [list->name]@[list->host]
a été rejeté par [rejected_by], moderateur de la liste.

L'objet de votre message : [subject]


Vérifiez les conditions d'utilisation de cette liste :
[conf->wwsympa_url]/info/[list->name]

[ELSIF list->lang=es]
Subject: Rechazo de su mensaje
Mime-version: 1.0
Content-Type: text/plain; charset=iso-8859-1
Content-transfer-encoding: 8bit

Su mensaje a la lista [list->name]@[list->host]
ha sido rechazado por [rejected_by], moderador de la lista.

El tema de su mensaje era : [subject]

Verifique las normas de uso de la lista:
[conf->wwsympa_url]/info/[list->name]

[ELSIF list->lang=pl]
Subject: Twoja wiadomo¶æ nie zosta³a rozes³ana
Mime-version: 1.0
Content-Type: text/plain; charset=iso-8859-2
Content-transfer-encoding: 8bit

Twoja wiadomo¶æ wy³ana na listê [list->name]@[list->host]
nie zosta³a rozes³ana. Odrzuci³ j± moderator listy: [rejected_by]

Temat Twojego listu : [subject]

Verifique las normas de uso de la lista:
[conf->wwsympa_url]/info/[list->name]
[ELSIF list->lang=cz]
Subject: Vase zprava byla odmitnuta
Mime-version: 1.0
Content-Type: text/plain; charset=iso-8859-2
Content-transfer-encoding: 8bit

Va¹e zpráva do konference [list->name]@[list->host]
nebyla rozeslána. Byla odmítnuta moderátorem konference:
[rejected_by]

Subjekt Va¹í zprávy: [subject]

Zkontrolujte podmínky pro u¾ívání konference:
[conf->wwsympa_url]/info/[list->name]

[ELSIF list->lang=de]
Subject: Ihr Beitrag wurde abgelehnt.
Mime-version: 1.0
Content-Type: text/plain; charset=iso-8859-1
Content-transfer-encoding: 8bit

Ihr Beitrag zur Mailing-Liste [list->name]@[list->host]
wurde von [rejected_by] (Moderator) abgelehnt.

(Titel Ihrer EMail: [subject])


Sie können genaueres über die Liste erfahren unter:
[conf->wwsympa_url]/info/[list->name]

[ELSIF list->lang=hu]
Subject: A leveled nem jelenhet meg
Mime-version: 1.0
Content-Type: text/plain; charset=iso-8859-2
Content-transfer-encoding: 8bit

A(z) [list->name]@[list->host] listára küldött
leveled megjelenését [rejected_by] moderátor elutasította.

(Eredeti level tárgya: [subject])

[list->name] lista használatáról bõvebben itt olvashatsz:
[conf->wwsympa_url]/info/[list->name]

[ELSIF list->lang=pt]
Subject: Rechaço da sua mensagem
Mime-version: 1.0
Content-Type: text/plain; charset=iso-8859-1
Content-transfer-encoding: 8bit

Sua mensagem para a lista [list->name]@[list->host]
foi rechaçado por [rejected_by], moderador da lista.

O tema da sua mensagem era : [subject]

Verifique as normas de uso da lista:
[conf->wwsympa_url]/info/[list->name]

[ELSE]
Subject: Your message has been rejected.

Your message for list [list->name]@[list->host]
as been rejected by [rejected_by] list editor.

(Subject of your mail : [subject]) 


Check [list->name] list usage :
[conf->wwsympa_url]/info/[list->name]

[ENDIF]

