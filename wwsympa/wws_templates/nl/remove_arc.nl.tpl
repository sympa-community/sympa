<!-- RCS Identication ; $Revision$ ; $Date$ -->

[IF status = done]
<b>Operatie gelukt</b>. Het bericht zal zo snel mogelijk
worden verwijderd. Dit kan een een paar minuten duren.
[ELSIF status = no_msgid]
<b>Ik kan het bericht niet vinden om te verwijderen</b>, waarschijnlijk
omdat dit bericht ontvangen is zonder "Message-Id:" Vraag aan de listmaster
de complete URL van het bericht.
[ELSIF status = not_found]
<b>Ik kan het bericht niet vinden om te verwijderen</b>
[ELSE]
<b>Ik kan het bericht niet vinden om te verwijderen</b>, vraag aan de
listmaster de complete URL van het bericht.
[ENDIF]
