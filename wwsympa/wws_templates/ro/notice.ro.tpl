[FOREACH notice IN notices] 
[IF notice->msg=sent_to_owner]
 Cererea ta a fost trimisa 
mai departe la proprietarul listei
[ELSIF notice->msg=add_performed]
 [notice->total] 
abonati adaugati 
[ELSIF notice->msg=performed]
 [notice->action] : operatie reusita 
[ELSIF notice->msg=list_config_updated]
 Fisierul de actualizare a fost actualizat 
[ELSIF notice->msg=upload_success]
 Fisierul [notice->path] a fost incarcat! 
[ELSIF notice->msg=save_success]
 Fisierul [notice->path] salvat 
[ELSIF notice->msg=password_sent] 
Parola ti-a fost trimisa 
[ELSIF notice->msg=you_should_choose_a_password]
 Pentru 
a alege o parola mergi pe 'preferences', din meniul de deasupra. 
[ELSIF notice->msg=no_msg] 
Nu exista mesaje pentru moderarea pe aceasta lista [notice->list] 
[ELSE]
 [notice->msg] 
[ENDIF] <BR>
[END]




