<!-- RCS Identication ; $Revision$ ; $Date$ -->

[FOREACH error IN errors]

[IF error->msg=unknown_action]
[error->action] : Unbekannte Aktion

[ELSIF error->msg=unknown_list]
[error->list] : Unbekannte Liste

[ELSIF error->msg=already_login]
Sie sind bereits angemeldet als [error->email]

[ELSIF error->msg=no_email]
Bitte geben Sie Ihre EMail-Addresse an

[ELSIF error->msg=incorrect_email]
Adresse "[error->email]" ist falsch

[ELSIF error->msg=incorrect_listname]
"[error->listname]" : Schlechter Listenname

[ELSIF error->msg=no_passwd]
Bitte geben Sie Ihr Passwort an

[ELSIF error->msg=user_not_found]
"[error->email]" : Benutzer unbekannt

[ELSIF error->msg=user_not_found]
"[error->email]" ist kein Abonnent

[ELSIF error->msg=passwd_not_found]
Kein Passwort f&uuml;r Benutzer "[error->email]"

[ELSIF error->msg=incorrect_passwd]
Angegebenes Passwort ist falsch

[ELSIF error->msg=uncomplete_passwd]
Angegebenes Posswort ist unvollst&auml;ndig

[ELSIF error->msg=no_user]
Sie m&uuml;ssen sich anmelden

[ELSIF error->msg=may_not]
[error->action] : Ihnen ist diese Operation nicht erlaubt.
[IF ! user->email]
<BR>Sie m&uuml;ssen sich anmelden.
[ENDIF]

[ELSIF error->msg=no_subscriber]
Mailing-Liste hat keine Abonnenten

[ELSIF error->msg=no_bounce]
Mailing-Liste hat keinen unzustellbaren  Abonnenten

[ELSIF error->msg=no_page]
Keine Seite [error->page]

[ELSIF error->msg=no_filter]
Kein Filter

[ELSIF error->msg=file_not_editable]
[error->file] : Datei ist nicht editierbar

[ELSIF error->msg=already_subscriber]
Sie sind bereits Abonnent der Liste [error->list]

[ELSIF error->msg=user_already_subscriber]
[error->email] ist bereits Abonnent der Liste [error->list] 

[ELSIF error->msg=failed_add]
Benutzer [error->user] konnte nicht hinzugef&uuml;gt werden

[ELSIF error->msg=failed]
[error->action]: Aktion gescheitert

[ELSIF error->msg=not_subscriber]
Sie sind keine Abonnent von Liste [error->list]

[ELSIF error->msg=diff_passwd]
Die beiden Passworte stimmen nicht &uuml;berein

[ELSIF error->msg=missing_arg]
Fehlendes Argument [error->argument]

[ELSIF error->msg=no_bounce]
Keine unzustellbaren Nachrichten f&uuml;r Benutzer [error->email]

[ELSIF error->msg=update_privilege_bypassed]
Sie haben versucht ein Parameter ohne die erforderlichen Rechte zu &auml;ndern: [error->pname]

[ELSIF error->msg=config_changed]
Konfigurationsdatei wurde ge&auml;nder durch [error->email]. Ihre
&Auml;nderungen k&onnen nicht durchgef&uhrt werden.

[ELSIF error->msg=syntax_errors]
Syntax-Fehler in folgenden Parametern : [error->params]

[ELSIF error->msg=no_such_document]
[error->path] : Keine solche Datei oder Verzeichnis

[ELSIF error->msg=no_such_file]
[error->path] : Keine solche Datei

[ELSIF error->msg=empty_document] 
Kann [error->path] nicht lesen : Leeres Dokument

[ELSIF error->msg=no_description] 
Keine Beschreibung angegeben

[ELSIF error->msg=no_content]
Failed : Leerer Inhalt

[ELSIF error->msg=no_name]
Kein Name angegeben

[ELSIF error->msg=incorrect_name]
[error->name] : Falscher Name

[ELSIF error->msg = index_html]
Sie sind nicht autorisiert die Datei INDEX.HTML in [error->dir] zuersetzen

[ELSIF error->msg=synchro_failed]
Daten auf Festplatte haben sich ge&auml;ndert. Ihre &Auml;nderungen k&ouml;nnen
nicht gespeichert werden

[ELSIF error->msg=cannot_overwrite] 
Kann Datei nicht &uuml;berschreiben [error->path] : [error->reason]

[ELSIF error->msg=cannot_upload] 
Kann Datei [error->path] nicht auf die Maschine laden : [error->reason]

[ELSIF error->msg=cannot_create_dir] 
Kann Verzeichnis [error->path] nicht anlegen : [error->reason]

[ELSIF error->msg=full_directory]
Fehlschlag : [error->directory] ist nicht leer

[ELSIF error->msg=init_passwd]
Sie haben kein Passwort gew&auml;hlt. Fordern Sie ein neues an.

[ELSE]
[error->msg]
[ENDIF]

<BR>
[END]
