<!-- RCS Identication ; $Revision$ ; $Date$ -->

[FOREACH error IN errors]

[IF error->msg=unknown_action]
[error->action]: ismeretlen parancs

[ELSIF error->msg=unknown_list]
[error->list]: ismeretlen lista

[ELSIF error->msg=already_login]
[error->email] címmel már beléptél.

[ELSIF error->msg=no_email]
Kérlek add meg az e-mail címedet.

[ELSIF error->msg=incorrect_email]
Nem megfelelõ eimail cím: "[error->email]" 

[ELSIF error->msg=incorrect_listname]
"[error->listname]": hibásan megadott listanév

[ELSIF error->msg=no_passwd]
Kérlek add meg a jelszavadat.

[ELSIF error->msg=user_not_found]
"[error->email]": ismeretlen felhasználó

[ELSIF error->msg=user_not_found]
"[error->email]" nem tagja a listának.

[ELSIF error->msg=passwd_not_found]
"[error->email]" felhasználónak nincsen jelszava.

[ELSIF error->msg=incorrect_passwd]
A megadott jelszó nem megfelelõ.

[ELSIF error->msg=uncomplete_passwd]
A megadott jelszó nem teljes.

[ELSIF error->msg=no_user]
Be kell jelentkezned.

[ELSIF error->msg=may_not]
[error->action]: nincs jogod a mûvelethez.
[IF ! user->email]
<BR>Be kell jelentkezned.
[ENDIF]

[ELSIF error->msg=no_subscriber]
A listára senkisem iratkozott fel.

[ELSIF error->msg=no_bounce]
A listán nincsen visszapattant levél.

[ELSIF error->msg=no_page]
Nincs ilyen nevû oldal: [error->page]

[ELSIF error->msg=no_filter]
Hiányzó szûrõ

[ELSIF error->msg=file_not_editable]
[error->file]: az állomány nem szerkeszthetõ.

[ELSIF error->msg=already_subscriber]
Már tagja vagy a(z) [error->list] listának.

[ELSIF error->msg=user_already_subscriber]
[error->email] már tagja a(z) [error->list] listának.

[ELSIF error->msg=failed_add]
Hiba a(z) [error->user] felhasználó hozzáadásakor.

[ELSIF error->msg=failed]
[error->action]: hiba a mûvelet elvégzésekor.

[ELSIF error->msg=not_subscriber]
Nem vagy a(z) [error->list] lista tagja.

[ELSIF error->msg=diff_passwd]
A megadott jelszavak nem egyeznek.

[ELSIF error->msg=missing_arg]
Hiányzó paraméter: [error->argument]

[ELSIF error->msg=no_bounce]
[error->email] felhasználónak nincsen visszapattant levele.

[ELSIF error->msg=update_privilege_bypassed]
Megfelelõ jogosultságok hiányában próbáltál meg módosítani: [error->pname]

[ELSIF error->msg=config_changed]
A konfigurációs állomány megváltozott [error->email]. Módosításaidat nem lehet elmenteni.

[ELSIF error->msg=syntax_errors]
Hibásan megadott parancs: [error->params]

[ELSIF error->msg=no_such_document]
[error->path]: Könyvtár nem található.

[ELSIF error->msg=no_such_file]
[error->path]: Állomány nem található.

[ELSIF error->msg=empty_document] 
Hiba a(z) [error->path] olvasásakor: a dokumentum üres

[ELSIF error->msg=no_description] 
Nincs megadva leírás.

[ELSIF error->msg=no_content]
Hiba: üres a beállításod

[ELSIF error->msg=no_name]
Nem lett megadva név.

[ELSIF error->msg=incorrect_name]
[error->name]: érvénytelen név.

[ELSIF error->msg = index_html]
Nincs jogosultságod új INDEX.HTML állomány feltöltésére a(z) [error->dir] könyvtárba.

[ELSIF error->msg=synchro_failed]
Az adatok megváltoztak. Nem lehet módosításaidat elmenteni.

[ELSIF error->msg=cannot_overwrite] 
[error->path] állományt nem lehet felülírni : [error->reason]

[ELSIF error->msg=cannot_upload] 
Nem lehet a(z) [error->path] állományt felölteni: [error->reason]

[ELSIF error->msg=cannot_create_dir] 
Nem lehet létrehozni a(z) [error->path] könyvtárat: [error->reason]

[ELSIF error->msg=full_directory]
Hiba: [error->directory] könyvtár nem üres. 

[ELSIF error->msg=init_passwd]
Nem adtál meg jelszót, az emlékeztetõ lekérdezésével kikérheted a jelenlegi jelszavadat.

[ELSIF error->msg=change_email_failed]
A(z) [error->list] listán nem sikerült megváltoztatni az e-mail címedet.

[ELSIF error->msg=change_email_failed_because_subscribe_not_allowed]
A(z) '[error->list]' listán az e-mail címedet nem sikerült megváltoztatni, mert az új címeddel a listán nem lehetnél tag.

[ELSIF error->msg=change_email_failed_because_unsubscribe_not_allowed] 
A(z) '[error->list]' listán az e-mail címedet nem sikerült megváltoztatni, mert a listáról nem lehet leiratkozni.

[ELSE]
[error->msg]
[ENDIF]

<BR>
[END]
