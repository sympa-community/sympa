[FOREACH notice IN notices]

[IF notice->msg=sent_to_owner]
Ihre Anfrage wurde an den Listenbesitzer weitergeleitet.

[ELSIF notice->msg=add_performed]
[notice->total] Abonnenten hinzugef&uuml;gt

[ELSIF notice->msg=performed]
[notice->action] : Aktion erfolgreich

[ELSIF notice->msg=list_config_updated]
Konfiguration wurde gespeichert

[ELSIF notice->msg=upload_success] 
Datei [notice->path] erfolgreich auf den Server geladen!

[ELSIF notice->msg=save_success] 
Datei [notice->path] gesichert

[ELSIF notice->msg=password_sent]
Ihr Passwort wird Ihnen per EMail geschickt

[ELSIF notice->msg=you_should_choose_a_password]
Zum &Auml;ndern Ihres Passwortes k&ouml;nnen Sie 'Einstellungen' im Men&uuml; anklicken.

[ELSE]
[notice->msg]

[ENDIF]

<BR>
[END]




