<!-- RCS Identication ; $Revision$ ; $Date$ -->

[FOREACH error IN errors]

[IF error->msg=unknown_action]
[error->action] : acción desconocida

[ELSIF error->msg=unknown_list]
[error->list] : lista desconocida

[ELSIF error->msg=already_login]
Vd. ya está autentificado en el sistema como [error->email]

[ELSIF error->msg=no_email]
Por favor indique su E-mail

[ELSIF error->msg=incorrect_email]
La dirección "[error->email]" es inválida

[ELSIF error->msg=incorrect_listname]
"[error->listname]" : nombre de lista incorrecto

[ELSIF error->msg=no_passwd]
Por favor, introduzca su contraseña

[ELSIF error->msg=user_not_found]
"[error->email]" : usuario desconocido

[ELSIF error->msg=user_not_found]
"[error->email]" no es un suscriptor

[ELSIF error->msg=passwd_not_found]
No hay contraseña para usuario "[error->email]"

[ELSIF error->msg=incorrect_passwd]
La contraseña introducida no es correcta

[ELSIF error->msg=no_user]
Usted tiene que hacer un login

[ELSIF error->msg=may_not]
[error->action] : no está autorizado para realizar esta operación

[ELSIF error->msg=no_subscriber]
La lista no tiene suscriptores

[ELSIF error->msg=no_bounce]
La lista no tiene suscriptores con errores

[ELSIF error->msg=no_page]
No hay página [error->page]

[ELSIF error->msg=no_filter]
Filtro no encontrado

[ELSIF error->msg=file_not_editable]
[error->file] : fichero no editable

[ELSIF error->msg=already_subscriber]
Usted ya es un suscriptor de la lista [error->list]

[ELSIF error->msg=user_already_subscriber]
[error->email] ya es suscriptor de la lista [error->list] 

[ELSIF error->msg=failed]
La operación ha fallado

[ELSIF error->msg=not_subscriber]
Usted no es un suscriptor de la lista [error->list]

[ELSIF error->msg=diff_passwd]
Las 2 contraseñas son diferentes

[ELSIF error->msg=missing_arg]
Falta un argumento [error->argument]

[ELSIF error->msg=no_bounce]
No hay errores del usuario [error->email]

[ELSIF error->msg=update_privilege_bypassed]
Ha cambiado un parámetro sin permisos : [error->pname]

[ELSIF error->msg=config_changed]
El fichero de configuración ha sido modificado por [error->email]. No se pueden hacer sus cambios

[ELSIF error->msg=syntax_errors]
Errores de sintaxis en los siguientes parámetros : [error->params]

[ELSIF error->msg=no_such_document]
[error->path] : No existe el fichero o el directorio

[ELSIF error->msg=no_such_file]
[error->path] : No existe el fichero

[ELSIF error->msg=empty_document] 
Unable to read [error->path] : documento vacío

[ELSIF error->msg=no_description] 
No se especificó la descripción

[ELSIF error->msg=no_content]
Fallo : el contenido está vacío

[ELSIF error->msg=no_name]
No se especificó un nombre

[ELSIF error->msg=incorrect_name]
[error->name] : nombre incorrecto

[ELSIF error->msg = index_html]
Usted no está autorizado a cargar INDEX.HTML en [error->dir] 

[ELSIF error->msg=synchro_failed]
Los datos han sido cambiados en el disco. No puedo hacer sus cambios

[ELSIF error->msg=cannot_overwrite] 
No puedo sobreescribir el fichero [error->path] : [error->reason]

[ELSIF error->msg=cannot_upload] 
No puedo cargar el fichero [error->path] : [error->reason]

[ELSIF error->msg=cannot_create_dir] 
No puedo cargar el directorio [error->path] : [error->reason]

[ELSIF error->msg=full_directory]
Fallo : [error->directory] no está vacío

[ELSIF error->msg=password_sent]
Su contraseña le ha sido enviada por correo

 

[ELSE]
[error->msg]
[ENDIF]

<BR>

[END]