<!-- RCS Identication ; $Revision$ ; $Date$ -->

[IF status = done]
<b>Operation erfolgreich</b>. Die Nachricht wird so bald wie m&ouml;glich
gel&ouml;scht werden. Dies wird wohl einige Minuten dauern. Bitte vergessen
Sie nicht, die betroffene Seite dann neu zu laden.
[ELSIF status = no_msgid]
<b>Es war nicht m&ouml;glich die Nachricht zu l&ouml;schen. Wahrscheinlich
wurde die Nachricht ohne "Message-Id:"-Feld empfangen. Bitte wenden Sie
sich an den Sympa-Administrator (listmaster) und geben Sie die volle
URL der betroffenen Nachricht an.</b>
[ELSIF status = not_found]
<b>Die zu l&ouml;schende Nachricht kann nicht gefunden werden.</b>
[ELSE]
<b>Fehler beim L&ouml;schen der Nachricht. Bitte wenden Sie
sich an den Sympa-Administrator (listmaster) und geben Sie die volle
URL der betroffenen Nachricht an.</b>
[ENDIF]
