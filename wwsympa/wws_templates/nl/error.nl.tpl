<!-- RCS Identication ; $Revision$ ; $Date$ -->

[FOREACH error IN errors]

[IF error->msg=unknown_action]
[error->action] : onbekende actie

[ELSIF error->msg=unknown_list]
[error->list] : onbekende lijst

[ELSIF error->msg=already_login]
U bent al ingelogd als [error->email]

[ELSIF error->msg=no_email]
Geeft u a.u.b. uw emailadres

[ELSIF error->msg=incorrect_email]
Adres "[error->email]" is incorrect

[ELSIF error->msg=incorrect_listname]
"[error->listname]" : foute lijstnaam

[ELSIF error->msg=no_passwd]
Geeft u uw wachtwoord

[ELSIF error->msg=user_not_found]
"[error->email]" : onbekende gebruiker

[ELSIF error->msg=passwd_not_found]
Geen wachtwoord voor gebruiker "[error->email]"

[ELSIF error->msg=incorrect_passwd]
Het ingegeven wachtwoord is incorrect

[ELSIF error->msg=incomplete_passwd]
Het ingegeven wachtwoord is incompleet

[ELSIF error->msg=no_user]
U moet nog inloggen

[ELSIF error->msg=may_not]
[error->action] : Het is niet toegestaan dat u dat doet
[IF ! user->email]
<BR>U dient in te loggen
[ENDIF]

[ELSIF error->msg=no_subscriber]
De lijst heeft geen abonnees

[ELSIF error->msg=no_bounce]
De lijst geeft geen abonnees met bounces

[ELSIF error->msg=no_page]
Geen pagina [error->page]

[ELSIF error->msg=no_filter]
Missend filter

[ELSIF error->msg=file_not_editable]
[error->file] : bestand is niet te wijzigen

[ELSIF error->msg=already_subscriber]
U bent al geabonneerd op de lijst [error->list]

[ELSIF error->msg=user_already_subscriber]
[error->email] is al geabonneerd op de lijst [error->list] 

[ELSIF error->msg=failed_add]
Mislukt om de gebruiker toe te voegen [error->user]

[ELSIF error->msg=failed]
[error->action]: actie mislukt

[ELSIF error->msg=not_subscriber]
[IF error->email]
  Niet geabonneerd: [error->email]
[ELSE]
U bent niet geabonneerd op de lijst [error->list]
[ENDIF]

[ELSIF error->msg=diff_passwd]
De wachtwoorden die u ingaf zijn ongelijk

[ELSIF error->msg=missing_arg]
Missend argument [error->argument]

[ELSIF error->msg=no_bounce]
Geen bounces voor gebruiker  [error->email]

[ELSIF error->msg=update_privilege_bypassed]
U heeft een parameter veranderd zonder toestemming: [error->pname]

[ELSIF error->msg=config_changed]
Het configuratiebestand is veranderd door [error->email]. Kan uw wijzigingen niet doorvoeren

[ELSIF error->msg=syntax_errors]
Syntax fout met de volgende parameters : [error->params]

[ELSIF error->msg=no_such_document]
[error->path] : Bestand of map niet gevonden 

[ELSIF error->msg=no_such_file]
[error->path] : Bestand niet gevonden

[ELSIF error->msg=empty_document] 
Unable to read [error->path] : leeg document

[ELSIF error->msg=no_description] 
Geen omschrijving gegeven

[ELSIF error->msg=no_content]
Fout: Uw inhoud is leeg  

[ELSIF error->msg=no_name]
Geen naam gegeven 

[ELSIF error->msg=incorrect_name]
[error->name] : incorrecte naam 

[ELSIF error->msg = index_html]
U bent niet geautoriseerd om een INDEX.HTML te uploaden in [error->dir] 

[ELSIF error->msg=synchro_failed]
Data is veranderd op de disk, kan uw wijzigingen niet doorvoeren

[ELSIF error->msg=cannot_overwrite] 
kan bestand niet overschrijven [error->path] : [error->reason]

[ELSIF error->msg=cannot_upload] 
kan bestand niet uploaden [error->path] : [error->reason]

[ELSIF error->msg=cannot_create_dir] 
kan map niet maken [error->path] : [error->reason]

[ELSIF error->msg=full_directory]
Fout : [error->directory] niet leeg 

[ELSIF error->msg=init_passwd]
U heeft geen wachtwoord gekozen, kies een herinering voor uw eerste wachtwoord

[ELSIF error->msg=change_email_failed]
Kon email voor lijst [error->list] niet veranderen

[ELSIF error->msg=change_email_failed_because_subscribe_not_allowed]
Kon uw abonnee adres voor lijst '[error->list]' niet veranderen
omdat uw nieuwe adres niet kan inschrijven.

[ELSIF error->msg=change_email_failed_because_unsubscribe_not_allowed]
kon uw abonnee adres voor lijst '[error->list]' niet veranderen
omdat uw nieuwe adres niet kan uitschrijven.

[ELSIF error->msg=shared_full]
De document map is groter dan de schijfquota.

[ELSE]
[error->msg]
[ENDIF]

<BR>
[END]
