[FOREACH notice IN notices]

[IF notice->msg=sent_to_owner]
Kérésed a lista adminisztrátorához lett továbbítva.

[ELSIF notice->msg=add_performed]
[notice->total] tag felírva

[ELSIF notice->msg=performed]
[notice->action] : változtatások sikeresen elmentve

[ELSIF notice->msg=list_config_updated]
A beállításokat tartalmazó állomány frissítve.

[ELSIF notice->msg=upload_success] 
[notice->path] állomány sikeresen betöltve!

[ELSIF notice->msg=save_success] 
[notice->path] állomány elmentve.

[ELSIF notice->msg=password_sent]
Jelszavad emailben el lett küldve.

[ELSIF notice->msg=you_should_choose_a_password]
Jelszavad módosításához válaszd a felsõ menü 'Beállításaim' részét.

[ELSE]
[notice->msg]

[ENDIF]

<BR>
[END]




