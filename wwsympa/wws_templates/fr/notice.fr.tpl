[FOREACH notice IN notices]

[IF notice->msg=sent_to_owner]
La demande a été soumise au gestionnaire de la liste

[ELSIF notice->msg=performed]
[notice->action] : l'opération a été effectuée

[ELSIF notice->msg=list_config_updated]
La configuration de la liste a été mise à jour

[ELSIF notice->msg=upload_success] 
Le fichier [notice->path] a été déposé

[ELSIF notice->msg=save_success] 
Fichier [notice->path] sauvegardé

[ELSIF notice->msg=you_should_choose_a_password]
Pour choisir votre mot de passe, allez dans vos 'Préférences', depuis le menu supérieur

[ELSIF notice->msg=no_msg] 
Aucun message à modérer pour la liste [notice->list]

[ELSE]
[notice->msg]

[ENDIF]

<BR>
[END]




