[FOREACH notice IN notices]

[IF notice->msg=sent_to_owner]
Teie soov saadeti listiomanikele

[ELSIF notice->msg=add_performed]
Lisatud [notice->total] liiget

[ELSIF notice->msg=performed]
[notice->action]: tehtud

[ELSIF notice->msg=list_config_updated]
Uuendati seadetefaili

[ELSIF notice->msg=upload_success] 
Fail [notice->path] laeti üles!

[ELSIF notice->msg=save_success] 
Fail [notice->path] salvestati 

[ELSIF notice->msg=password_sent]
Teie parool saadeti teile e-postiga

[ELSIF notice->msg=you_should_choose_a_password]
Parooli muutmiseks valige 'eelistused' ülevalt menüüst

[ELSIF notice->msg=no_msg] 
Listis [notice->list] ei ole modereeritavaid kirju

[ELSE]
[notice->msg]

[ENDIF]

<BR>
[END]




