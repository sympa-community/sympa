[FOREACH notice IN notices]

[IF notice->msg=sent_to_owner]
Your request has been forwarded to the list owner

[ELSIF notice->msg=add_performed]
[notice->total] subscribers added

[ELSIF notice->msg=performed]
[notice->action] : action succeeded

[ELSIF notice->msg=list_config_updated]
Configuration file has been updated

[ELSIF notice->msg=upload_success] 
File [notice->path] successfully uploaded!

[ELSIF notice->msg=save_success] 
File [notice->path] saved

[ELSIF notice->msg=password_sent]
Your password has been emailed to you

[ELSE]
[notice->msg]

[ENDIF]

<BR>
[END]




