<!-- RCS Identication ; $Revision$ ; $Date$ -->

[FOREACH error IN errors]

[IF error->msg=unknown_action]
[error->action] : neznámá akce

[ELSIF error->msg=unknown_list]
[error->list] : neznámá konference

[ELSIF error->msg=already_login]
Jste ji¾ pøihlá¹en jako [error->email]

[ELSIF error->msg=no_email]
Prosím poskytnìte Va¹i emailovou adresu

[ELSIF error->msg=incorrect_email]
Adresa "[error->email]" je nesprávná

[ELSIF error->msg=incorrect_listname]
"[error->listname]" : ¹patné jméno konference

[ELSIF error->msg=no_passwd]
Prosím poskytnìte Va¹e heslo

[ELSIF error->msg=user_not_found]
"[error->email]" : neznámý u¾ivatel

[ELSIF error->msg=passwd_not_found]
U¾ivatel "[error->email]" nemá heslo

[ELSIF error->msg=incorrect_passwd]
Poskytnuté heslo je nesprávné

[ELSIF error->msg=incomplete_passwd]
Poskytnuté heslo je nekompletní

[ELSIF error->msg=no_user]
Musíte se pøihlásit

[ELSIF error->msg=may_not]
[error->action] : na tuto akci nemáte oprávnìní
[IF ! user->email]
<BR>musíte se pøihlásit
[ENDIF]

[ELSIF error->msg=no_subscriber]
Konference nemá ¾ádné èleny

[ELSIF error->msg=no_bounce]
Konference neobsahuje chybné adresy

[ELSIF error->msg=no_page]
Strana [error->page] neexistuje

[ELSIF error->msg=no_filter]
Chybìjící filtr

[ELSIF error->msg=file_not_editable]
[error->file] : soubor se nedá upravovat

[ELSIF error->msg=already_subscriber]
V konferenci [error->list] jste ji¾ èlenem

[ELSIF error->msg=user_already_subscriber]
[error->email] je ji¾ èlenem konference [error->list] 

[ELSIF error->msg=failed_add]
Chyba pøi pøidávání u¾ivatele [error->user]

[ELSIF error->msg=failed]
[error->action]: akce selhala

[ELSIF error->msg=not_subscriber]
[IF error->email]
  Nejste pøihlá¹en: [error->email]
[ELSE]
Nejste èlenem konference [error->list]
[ENDIF]

[ELSIF error->msg=diff_passwd]
Hesla nejsou stejná

[ELSIF error->msg=missing_arg]
Chybìjící parametr [error->argument]

[ELSIF error->msg=no_bounce]
Pro u¾ivatele [error->email] nejsou vrácené zprávy

[ELSIF error->msg=update_privilege_bypassed]
Zmìnil jste parametr bez oprávnìní: [error->pname]

[ELSIF error->msg=config_changed]
[error->email] zmìnil konfiguraèní soubor. Va¹e zmìny nelze pou¾ít

[ELSIF error->msg=syntax_errors]
Syntaktická chyba s následujcími parametry : [error->params]

[ELSIF error->msg=no_such_document]
[error->path] : Cesta nenalezena

[ELSIF error->msg=no_such_file]
[error->path] : soubor neexistuje

[ELSIF error->msg=empty_document] 
Nelze èíst soubor [error->path] : prázdný dokument

[ELSIF error->msg=no_description] 
Popis nespecifikován

[ELSIF error->msg=no_content]
Chyba : obsah je prázdný

[ELSIF error->msg=no_name]
Zádné jméno nespecifikováno 

[ELSIF error->msg=incorrect_name]
[error->name] : nesprávné jméno 

[ELSIF error->msg = index_html]
Nemáte oprávnìní nahrát INDEX.HTML do adresáøe [error->dir] 

[ELSIF error->msg=synchro_failed]
Data zmìnìna na disku. Va¹e zmìny nelze pou¾ít 

[ELSIF error->msg=cannot_overwrite] 
Nelze pøepsat soubor [error->path] : [error->reason]

[ELSIF error->msg=cannot_upload] 
Nelze nahrát soubor [error->path] : [error->reason]

[ELSIF error->msg=cannot_create_dir] 
Nelze vytvoøit adresáø [error->path] : [error->reason]

[ELSIF error->msg=full_directory]
Chyba : Adresáø [error->directory] není prázdný

[ELSIF error->msg=init_passwd]
Nezvolil jste si heslo, nechte si jej poslat 

[ELSIF error->msg=change_email_failed]
Nelze zmìnit emailovou adresu pro konferenci [error->list]

[ELSIF error->msg=change_email_failed_because_subscribe_not_allowed]
Nelze zmìnit Va¹i adresu v konferenci '[error->list]', proto¾e není dovoleno
pøihlásit Va¹i novou adresu.

[ELSIF error->msg=change_email_failed_because_unsubscribe_not_allowed]
Nelze zmìnit Va¹i adresu v konferenci '[error->list]', proto¾e Vám není dovoleno
odhlásit se.

[ELSIF error->msg=shared_full]
The document repository exceed disk quota.

[ELSIF error->msg=ldap_user]
Your password is stored in an LDAP directory, therefore Sympa cannot post you a reminder

[ELSIF error->msg=select_month]
Please select archive months

[ELSE]
[error->msg]
[ENDIF]

<BR>
[END]
