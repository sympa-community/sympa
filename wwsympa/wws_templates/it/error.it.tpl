<!-- RCS Identication ; $Revision$ ; $Date$ -->

[IF error_msg=unknown_action]
[error->action] : azione sconosciuta

[ELSIF error_msg=unknown_list]
[error->list] : lista sconosciuta

[ELSIF error_msg=already_login]
Gi&agrave collegato con identificativo [error->email]

[ELSIF error_msg=no_email]
Indica il tuo indirizzo email

[ELSIF error_msg=incorrect_email]
L'indirizzo "[error->email]" &egrave; sbagliato

[ELSIF error_msg=incorrect_listname]
"[error->listname]" : lista non esistente

[ELSIF error_msg=no_passwd]
Prego indica la tua password

[ELSIF error_msg=user_not_found]
"[error->email]" : utente sconosciuto

[ELSIF error_msg=user_not_found]
"[error->email]" non &egrave; un utente registrato

[ELSIF error_msg=passwd_not_found]
Nessuna password per l'utente "[error->email]"

[ELSIF error_msg=incorrect_passwd]
La password inserita &egrave; sbagliata

[ELSIF error_msg=no_user]
Devi fare login

[ELSIF error_msg=may_not]
[error->action] : non ti &egrave; permessa questa funzione

[ELSIF error_msg=no_subscriber]
La lista non contiene utenti

[ELSIF error_msg=no_bounce]
La lista non ha utenti con indirizzi errati

[ELSIF error_msg=no_page]
Nessuna pagina [error->page]

[ELSIF error_msg=no_filter]
Manca il filtro

[ELSIF error_msg=file_not_editable]
[error->file] : file non modificabile

[ELSIF error_msg=already_subscriber]
Sei gi&agrave; iscritto alla lista [error->list]

[ELSIF error_msg=user_already_subscriber]
[error->email] &egrave; gi&agrave; iscritto alla lista [error->list] 

[ELSIF error_msg=sent_to_owner]
La tua richiesta &egrave; stata mandata all'editore

[ELSIF error_msg=failed]
Azione fallita

[ELSIF error_msg=performed]
[error->action] : azione eseguita

[ELSIF error_msg=not_subscriber]
Non sei sottoscritto alla lista [error->list]

[ELSIF error_msg=diff_passwd]
Le due password sono differenti

[ELSIF error_msg=missing_arg]
Manca un argomento [error->argument]

[ELSIF error_msg=no_bounce]
Nessuna mail errata per l'utente  [error->email]

[ELSIF error_msg=update_privilege_bypassed]
Hai cambiato il valore del parametro senza averne i permessi: [error->pname]

[ELSIF error_msg=list_config_updated]
Il file di configurazione &egrave; stato aggiornato.

[ELSIF error_msg=config_changed]
Il file di configurazione &egrave; stato modificato da [error->email]. Non posso applicare i tuoi cambiamenti

[ELSIF error_msg=syntax_errors]
Errore nella sintassi del parametro : [error->params]


[ELSIF error_msg=no_such_document]
[error->path] : Non esiste tale file o directory

[ELSIF error_msg=no_such_file]
[error->path] : Non esiste tale file

[ELSIF error_msg=empty_document] 
Unable to read [error->path] : documento vuoto

[ELSIF error_msg=no_description] 
Nessuna descrizione specificata

[ELSIF error_msg=no_content]
Errore : contenuto vuoto

[ELSIF error_msg=no_name]
Nessun nome specificato

[ELSIF error_msg=incorrect_name]
[error->name] : nome incorretto

[ELSIF error_msg = index_html]
Non sei autorizzato a inserire un file INDEX.HTML in [error->dir] 

[ELSIF error_msg=synchro_failed]
I dati su disco sono cambiati. 
Data have changed on disk. Non posso applicare i tuoi cambiamenti

[ELSIF error_msg=cannot_overwrite] 
Non posso sovrascrivere il file [error->path] : [error->reason]

[ELSIF error_msg=cannot_upload] 
Non posso inserire il file [error->path] : [error->reason]

[ELSIF error_msg=cannot_create_dir] 
Non posso creare la directory [error->path] : [error->reason]

[ELSIF error_msg=upload_success] 
File [error->path] inserito con successo!

[ELSIF error_msg=save_success] 
File [error->path] salvato

[ELSIF error_msg=full_directory]
Errore : [error->directory] non vuoto

[ELSIF error_msg=password_sent]
La tua password ti &egrave; stata spedita

 

[ELSE]
[error_msg]
[ENDIF]