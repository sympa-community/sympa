[FOREACH notice IN notices]

[IF notice->msg=sent_to_owner]
Pyyntösi on lähetetty listan omistajalle

[ELSIF notice->msg=add_performed]
[notice->total] tilaajaa lisätty

[ELSIF notice->msg=performed]
[notice->action] : toiminto onnistui

[ELSIF notice->msg=list_config_updated]
Asetustiedosto on päivitetty

[ELSIF notice->msg=upload_success] 
File [notice->path] ladattu onnistuneesti!

[ELSIF notice->msg=save_success] 
File [notice->path] tallennettu

[ELSIF notice->msg=password_sent]
Salasanasi on lähetetty emailina

[ELSIF notice->msg=you_should_choose_a_password]
Valitaksesi salasana mene 'asetukset' sivulle, ylävalikon kautta.

[ELSIF notice->msg=no_msg] 
Ei viestejä hallittavana listalla [notice->list]

[ELSE]
[notice->msg]

[ENDIF]

<BR>
[END]




