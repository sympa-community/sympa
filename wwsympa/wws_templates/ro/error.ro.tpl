<!-- RCS Identication ; $Revision$ ; $Date$ -->
[FOREACH error IN errors] 
[IF error->msg=unknown_action] 
[error->action] : actiune 
necunoscuta
[ELSIF error->msg=unknown_list] 
[error->list] : lista necunoscuta 
[ELSIF error->msg=already_login] 
Esti deja actualizat ca [error->email] 
[ELSIF error->msg=no_email] 
Trimite adresa ta email
[ELSIF error->msg=incorrect_email] 
Adresa"[error->email]" 
in lista gresita 
[ELSIF error->msg=incorrect_listname] 
"[error->listname]" : nume 
gresit de lista 
[ELSIF error->msg=no_passwd] 
Scrie parola 
[ELSIF error->msg=user_not_found] 
"[error->email]" : utilizator necunoscut 
[ELSIF error->msg=user_not_found] 
"[error->email]" 
nu este abonat 
[ELSIF error->msg=passwd_not_found]
 Parola inexistenta pentru utilizator"[error->email]" 
[ELSIF error->msg=incorrect_passwd]
 Parola furnizata nu este corecta 
[ELSIF error->msg=incomplete_passwd] 
Parola furnizata este incompleta 
[ELSIF error->msg=no_user]
 Trebuie sa te autentifici 
[ELSIF error->msg=may_not] [error->action] : aceasta actiune este interzisa 
[IF ! user->email] 
<BR>
trebuie sa te autentifici 
[ENDIF] 
[ELSIF error->msg=no_subscriber] 
List has no 
subscriber 
[ELSIF error->msg=no_bounce]
 Lista nu are abonati in asteptare
[ELSIF error->msg=no_page]
 Pagina nu exista [error->page] 
[ELSIF error->msg=no_filter] 
Filtrul nu exista 
[ELSIF error->msg=file_not_editable]
 [error->file] : fisier 
needitabil 
[ELSIF error->msg=already_subscriber]
 Esti de ja abonat in lista[error->list] 
[ELSIF error->msg=user_already_subscriber] 
[error->email] este abonat la lista 
[error->list] 
[ELSIF error->msg=failed_add] 
Eroare la adaugarea utilizatorului 
[error->user] 
[ELSIF error->msg=failed]
 [error->action]: actiune esuata
[ELSIF error->msg=not_subscriber]
 [IF error->email] 
Nu esti abonat: [error->email] 
[ELSE] 
Nu esti abonat la lista[error->list] 
[ENDIF] 
[ELSIF error->msg=diff_passwd] 
Cele 2 parole difera 
[ELSIF error->msg=missing_arg] 
Argument lipsa[error->argument] 
[ELSIF error->msg=no_bounce] 
Nu exista asteptare pentru utilizator [error->email] 
[ELSIF error->msg=update_privilege_bypassed] 
Ati schimbat un parametru fara a 
avea permisiunea: [error->pname] 
[ELSIF error->msg=config_changed] 
Fisierul Config a fost modificat de catre [error->email]. Modificarile nu pot fi operate 
[ELSIF error->msg=syntax_errors] 
Erori de sintaxa cu urmatorii parametri: [error->params] 
[ELSIF error->msg=no_such_document] 
[error->path] : Acest fisier sau director nu exista 
[ELSIF error->msg=no_such_file] 
[error->path] : Fisier inexistent 
[ELSIF error->msg=empty_document] 
Nu poate fi citit [error->path] : document gol 
[ELSIF error->msg=no_description] 
Descriere nespecificata 
[ELSIF error->msg=no_content] 
Eroare: nu exista continut 
[ELSIF error->msg=no_name] 
Nume nespecificat 
[ELSIF error->msg=incorrect_name]
 [error->name] : nume incorect 
[ELSIF error->msg = index_html] 
Nu esti autorizat sa incarci fisier INDEX.HTML in [error->dir] 
[ELSIF error->msg=synchro_failed] 
Informatiile de pe hard au fost modificate. Modificarile nu pot fi operate 
[ELSIF error->msg=cannot_overwrite] 
Fisierul nu poate fi scris peste cel original [error->path] 
: [error->reason] 
[ELSIF error->msg=cannot_upload]
 Fisierul nu poate fi incarcat 
[error->path] : [error->reason] 
[ELSIF error->msg=cannot_create_dir] 
Directorul nu poate fi incarcat [error->path] : [error->reason] 
[ELSIF error->msg=full_directory] 
Eroare: [error->directory] nu e deschis 
[ELSIF error->msg=init_passwd]
 Nu ti-ai ales o parola, cere parola initiala 
[ELSIF error->msg=change_email_failed] 
Modificarea emailului pentru lista nu a putut fi operata [error->list] 
[ELSIF error->msg=change_email_failed_because_subscribe_not_allowed] 
Modificarea adresei de subscriere la lista '[error->list]' nu a putut fi operata 
deoarece subscrierea cu adresa noua nu este permisa. 
[ELSIF error->msg=change_email_failed_because_unsubscribe_not_allowed] 
Modificarea adresei de subscriere la lista '[error->list]' nu a putut fi operata 
deoarece dezabonarea de la lista nu este permisa. 
[ELSE] 
[error->msg] 
[ENDIF] 
<BR>
[END]
