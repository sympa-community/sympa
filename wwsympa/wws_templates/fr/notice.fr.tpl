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

[ELSIF notice->msg=subscribers_update_soon]
La liste des membres de la liste sera générée/mise à jour dans un moment (quelques minutes).

[ELSIF notice->msg=add_performed]
[notice->total] adresses ont été abonnées

[ELSE]
[notice->msg]

[ENDIF]

<BR>
[END]




