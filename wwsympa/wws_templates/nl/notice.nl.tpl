[FOREACH notice IN notices]

[IF notice->msg=sent_to_owner]
Uw aanvraag is doorgestuurd naar de eigenaar van de lijst

[ELSIF notice->msg=add_performed]
[notice->total] abonnees toegevoegd

[ELSIF notice->msg=performed]
[notice->action] : actie gelukt

[ELSIF notice->msg=list_config_updated]
Configuratie bestand is gewijzigd.

[ELSIF notice->msg=upload_success] 
File [notice->path] succesvol geupload!

[ELSIF notice->msg=save_success] 
Bestand [notice->path] opgeslagen

[ELSIF notice->msg=password_sent]
Uw wachtwoord is naar u gemailed.

[ELSIF notice->msg=you_should_choose_a_password]
Om uw wachtwoord te kiezen dient u op "Voorkeuren" te klikken in het bovenste menu.

[ELSIF notice->msg=no_msg] 
Geen bericht om te modereren voor lijst [notice->list]

[ELSIF notice->msg=subscribers_update_soon]
De lijst van alle abonnees van de lijst wordt samengesteld (een paar minuten geduld a.u.b.)

[ELSE]
[notice->msg]

[ENDIF]

<BR>
[END]




