<!-- RCS Identication ; $Revision$ ; $Date$ -->

[FOREACH error IN errors]

[IF error->msg=unknown_action]
[error->action] : azione sconosciuta

[ELSIF error->msg=unknown_list]
[error->list] : lista sconosciuta

[ELSIF error->msg=already_login]
Gi&agrave collegato con identificativo [error->email]

[ELSIF error->msg=no_email]
Indica il tuo indirizzo email

[ELSIF error->msg=incorrect_email]
L'indirizzo "[error->email]" &egrave; sbagliato

[ELSIF error->msg=incorrect_listname]
"[error->listname]" : lista non esistente

[ELSIF error->msg=no_passwd]
Prego indica la tua password

[ELSIF error->msg=user_not_found]
"[error->email]" : utente sconosciuto

[ELSIF error->msg=user_not_found]
"[error->email]" non &egrave; un utente registrato

[ELSIF error->msg=passwd_not_found]
Nessuna password per l'utente "[error->email]"

[ELSIF error->msg=incorrect_passwd]
La password inserita &egrave; sbagliata

[ELSIF error->msg=no_user]
Devi fare login

[ELSIF error->msg=may_not]
[error->action] : non ti &egrave; permessa questa funzione

[ELSIF error->msg=no_subscriber]
La lista non contiene utenti

[ELSIF error->msg=no_bounce]
La lista non ha utenti con indirizzi errati

[ELSIF error->msg=no_page]
Nessuna pagina [error->page]

[ELSIF error->msg=no_filter]
Manca il filtro

[ELSIF error->msg=file_not_editable]
[error->file] : file non modificabile

[ELSIF error->msg=already_subscriber]
Sei gi&agrave; iscritto alla lista [error->list]

[ELSIF error->msg=user_already_subscriber]
[error->email] &egrave; gi&agrave; iscritto alla lista [error->list] 

[ELSIF error->msg=failed]
Azione fallita

[ELSIF error->msg=not_subscriber]
Non sei sottoscritto alla lista [error->list]

[ELSIF error->msg=diff_passwd]
Le due password sono differenti

[ELSIF error->msg=missing_arg]
Manca un argomento [error->argument]

[ELSIF error->msg=no_bounce]
Nessuna mail errata per l'utente  [error->email]

[ELSIF error->msg=update_privilege_bypassed]
Hai cambiato il valore del parametro senza averne i permessi: [error->pname]

[ELSIF error->msg=config_changed]
Il file di configurazione &egrave; stato modificato da [error->email]. Non posso applicare i tuoi cambiamenti

[ELSIF error->msg=syntax_errors]
Errore nella sintassi del parametro : [error->params]

[ELSIF error->msg=no_such_document]
[error->path] : Non esiste tale file o directory

[ELSIF error->msg=no_such_file]
[error->path] : Non esiste tale file

[ELSIF error->msg=empty_document] 
Unable to read [error->path] : documento vuoto

[ELSIF error->msg=no_description] 
Nessuna descrizione specificata

[ELSIF error->msg=no_content]
Errore : contenuto vuoto

[ELSIF error->msg=no_name]
Nessun nome specificato

[ELSIF error->msg=incorrect_name]
[error->name] : nome incorretto

[ELSIF error->msg = index_html]
Non sei autorizzato a inserire un file INDEX.HTML in [error->dir] 

[ELSIF error->msg=synchro_failed]
I dati su disco sono cambiati. 
Data have changed on disk. Non posso applicare i tuoi cambiamenti

[ELSIF error->msg=cannot_overwrite] 
Non posso sovrascrivere il file [error->path] : [error->reason]

[ELSIF error->msg=cannot_upload] 
Non posso inserire il file [error->path] : [error->reason]

[ELSIF error->msg=cannot_create_dir] 
Non posso creare la directory [error->path] : [error->reason]

[ELSIF error->msg=full_directory]
Errore : [error->directory] non vuoto

[ELSIF error->msg=password_sent]
La tua password ti &egrave; stata spedita

 

[ELSE]
[error->msg]
[ENDIF]

<BR>

[END]