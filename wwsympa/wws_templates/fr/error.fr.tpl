<!-- RCS Identication ; $Revision$ ; $Date$ -->

[IF error_msg=unknown_action]
[error->action] : cette action est incorrecte

[ELSIF error_msg=unknown_list]
[error->list] : cette liste est inconnue

[ELSIF error_msg=already_login]
Vous êtes déjà connecté avec l'adresse [error->email]

[ELSIF error_msg=no_email]
Vous devez fournir votre adresse e-mail

[ELSIF error_msg=incorrect_email]
L'adresse "[error->listname]" est incorrecte

[ELSIF error_msg=incorrect_listname]
"[error->email]" : nom de liste incorrect

[ELSIF error_msg=no_passwd]
Vous devez fournir votre mot de passe

[ELSIF error_msg=user_not_found]
"[error->email]" : utilisateur non reconnu

[ELSIF error_msg=user_not_found]
"[error->email]" n'est pas un abonné

[ELSIF error_msg=passwd_not_found]
Aucun mot de passe pour l'utilisateur "[error->email]"

[ELSIF error_msg=incorrect_passwd]
Mot de passe saisi incorrect

[ELSIF error_msg=uncomplete_passwd]
Mot de passe saisi incomplet

[ELSIF error_msg=no_user]
Vous devez vous identifier

[ELSIF error_msg=may_not]
[error->action] : vous n'êtes pas autorisé à effectuer cette action
[IF ! user->email]
<BR>identifiez-vous (Login)
[ENDIF]

[ELSIF error_msg=no_subscriber]
La liste ne comporte aucun abonné

[ELSIF error_msg=no_page]
Pas de page [error->page]

[ELSIF error_msg=no_filter]
Aucun filtre spécifié

[ELSIF error_msg=file_not_editable]
[error->file] : fichier non éditable

[ELSIF error_msg=already_subscriber]
Vous êtes déjà abonné à la liste [error->list] 

[ELSIF error_msg=user_already_subscriber]
[error->email] êtes déjà abonné à la liste [error->list] 

[ELSIF error_msg=sent_to_owner]
La demande a été soumise au gestionnaire de la liste

[ELSIF error_msg=failed]
L'opération a échoué

[ELSIF error_msg=performed]
[error->action] : l'opération a été effectuée

[ELSIF error_msg=not_subscriber]
Vous n'êtes pas abonné à la liste [error->list]

[ELSIF error_msg=diff_passwd]
Les 2 mots de passe sont différents

[ELSIF error_msg=missing_arg]
[error->argument] : paramètre manquant

[ELSIF error_msg=no_bounce]
Aucun bounce pour l'utilisateur [error->email]

[ELSIF error_msg=update_privilege_bypassed]
Vous avez édité un paramètre interdit: [error->pname]

[ELSIF error_msg=list_config_updated]
La configuration de la liste a été mise à jour

[ELSIF error_msg=config_changed]
Le fichier de configuration a été modifié par [error->email]. Impossible d'appliquer vos modifications

[ELSIF error_msg=syntax_errors]
Erreurs de syntaxe des paramètres suivants :[error->params]

[ELSIF error_msg=no_such_document]
[error->path] : document inexistant 

[ELSIF error_msg=no_such_file]
[error->path] : fichier inexistant 

[ELSIF error_msg=empty_document] 
Impossible de lire [error->path] : document vide

[ELSIF error_msg=no_description] 
Aucune description spécifiée

[ELSIF error_msg=no_content]
Echec : votre zone d'édition est vide  

[ELSIF error_msg=no_name]
Aucun nom specifié  

[ELSIF error_msg=incorrect_name]
[error->name] : nom incorrect  

[ELSIF error_msg = index_html]
Vous n'êtes pas autorisé à déposer un fichier INDEX.HTML dans [error->dir] 

[ELSIF error_msg=synchro_failed]
Les données ont changé sur le disque. Impossible d'appliquer vos modifications 

[ELSIF error_msg=cannot_overwrite] 
Impossible d'écraser le fichier [error->path] : [error->reason]

[ELSIF error_msg=cannot_upload] 
Impossible de déposer le  fichier [error->path] : [error->reason]

[ELSIF error_msg=cannot_create_dir] 
Impossible de créer le répertoire [error->path] : [error->reason]

[ELSIF error_msg=upload_success] 
Le fichier [error->path] a été déposé

[ELSIF error_msg=save_success] 
Fichier [error->path] sauvegardé

[ELSIF error_msg=full_directory]
Echec : le répertoire [error->directory] n'est pas vide  














[ELSE]
[error_msg]
[ENDIF]

