[FOREACH notice IN notices]

[IF notice->msg=sent_to_owner]
La tua richiesta &egrave; stata mandata all'editore

[ELSIF notice->msg=performed]
[notice->action] : azione eseguita

[ELSIF notice->msg=list_config_updated]
Il file di configurazione &egrave; stato aggiornato.

[ELSIF notice->msg=upload_success] 
File [notice->path] inserito con successo!

[ELSIF notice->msg=save_success] 
File [notice->path] salvato

[ELSE]
[notice->msg]

[ENDIF]

<BR>
[END]




