<!-- RCS Identication ; $Revision$ ; $Date$ -->

[FOREACH error IN errors]

[IF error->msg=unknown_action]
[error->action] : tundmatu tegevus

[ELSIF error->msg=unknown_list]
[error->list] : tundmatu list

[ELSIF error->msg=already_login]
Te olete juba sisse loginud aadressiga [error->email]

[ELSIF error->msg=no_email]
Palun sisestage oma eposti aadress

[ELSIF error->msg=incorrect_email]
Aadress [error->email] on sobimatu

[ELSIF error->msg=incorrect_listname]
"[error->listname]" : sobimatu listinimi

[ELSIF error->msg=no_passwd]
Palun sisestage oma parool

[ELSIF error->msg=user_not_found]
"[error->email]" : tundmatu kasutaja

[ELSIF error->msg=user_not_found]
"[error->email]" is not a subscriber

[ELSIF error->msg=passwd_not_found]
Kasutajal [error->email] ei ole parooli

[ELSIF error->msg=incorrect_passwd]
Sisestatud parool ei ole õige.

[ELSIF error->msg=incomplete_passwd]
Sisestatud parool ei ole täielik

[ELSIF error->msg=no_user]
Te peate esmalt sisse logima

[ELSIF error->msg=may_not]
[error->action] : teil ei ole lubatud seda tegevust teha
[IF ! user->email]
<BR>te peate esmalt sisse logima
[ENDIF]

[ELSIF error->msg=no_subscriber]
Listis ei ole liikmeid

[ELSIF error->msg=no_bounce]
Listis ei ole vigadega liikmeid

[ELSIF error->msg=no_page]
Lehte [error->page] ei ole

[ELSIF error->msg=no_filter]
Filtrit ei ole

[ELSIF error->msg=file_not_editable]
[error->file] : faili ei saa muuta

[ELSIF error->msg=already_subscriber]
Te olete juba listi [error->list] liige

[ELSIF error->msg=user_already_subscriber]
[error->email] on juba listi [error->list] liige

[ELSIF error->msg=failed_add]
Ei saanud lisada kasutajat [error->user]

[ELSIF error->msg=failed]
[error->action]: tegevus ei õnnestunud

[ELSIF error->msg=not_subscriber]
[IF error->email]
  Ei ole liige: [error->email]
[ELSE]
Te ei ole listi [error->list] liige
[ENDIF]

[ELSIF error->msg=diff_passwd]
Sisestatud paroolid erinevad

[ELSIF error->msg=missing_arg]
Puuduv argument [error->argument]

[ELSIF error->msg=no_bounce]
Aadressil [error->email] ei ole vigu

[ELSIF error->msg=update_privilege_bypassed]
Te olete muutnud parameetreid ilma vastava ligipääsuta: [error->pname]

[ELSIF error->msg=config_changed]
Seadetefaili muutis [error->email]. Ei saa rakendada teie muudatusi.

[ELSIF error->msg=syntax_errors]
Parameetri [error->params] süntaksis on viga.

[ELSIF error->msg=no_such_document]
[error->path] : Seda faili või kataloogi ei ole

[ELSIF error->msg=no_such_file]
[error->path] : Seda faili ei ole 

[ELSIF error->msg=empty_document] 
Unable to read [error->path] : tühi dokument

[ELSIF error->msg=no_description] 
Kirjeldust ei ole

[ELSIF error->msg=no_content]
Sisu ei ole

[ELSIF error->msg=no_name]
Nime ei ole

[ELSIF error->msg=incorrect_name]
[error->name] : sobimatu nimi

[ELSIF error->msg = index_html]
Teil ei ole lubatud laadida faili INDEX.HTML kataloogi [error->dir] 

[ELSIF error->msg=synchro_failed]
Salvestatud andmed muutusid. Ei saa rakendada teie muudatusi.

[ELSIF error->msg=cannot_overwrite] 
Ei saa faili [error->path] üle kirjutada: [error->reason]

[ELSIF error->msg=cannot_upload] 
Ei saa faili [error->path] üles laadida: [error->reason]

[ELSIF error->msg=cannot_create_dir] 
Ei saa luua kataloogi [error->path]: [error->reason]

[ELSIF error->msg=full_directory]
Ei saa: kataloog [error->directory] ei ole tühi

[ELSIF error->msg=init_passwd]
Te ei muutnud parooli, palun saatke endale algne parool uuesti.

[ELSIF error->msg=change_email_failed]
Ei saanud muuta epostiaadressi listis [error->list]

[ELSIF error->msg=change_email_failed_because_subscribe_not_allowed]
Aadressi listis '[error->list]' ei saa muuta, kuna 
uute listiga liitumine on keelatud.

[ELSIF error->msg=change_email_failed_because_unsubscribe_not_allowed]
Aadressi listis '[error->list]' ei saa muuta, kuna listist lahkumine
on keelatud.

[ELSE]
[error->msg]
[ENDIF]

<BR>
[END]
