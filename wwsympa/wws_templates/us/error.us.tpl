<!-- RCS Identication ; $Revision$ ; $Date$ -->

[FOREACH error IN errors]

[IF error->msg=unknown_action]
[error->action] : unknown action

[ELSIF error->msg=unknown_list]
[error->list] : unknown list

[ELSIF error->msg=already_login]
You are already logged in as [error->email]

[ELSIF error->msg=no_email]
Please provide your email address

[ELSIF error->msg=incorrect_email]
Address "[error->email]" in incorrect

[ELSIF error->msg=incorrect_listname]
"[error->listname]" : bad listname

[ELSIF error->msg=no_passwd]
Please provide your password

[ELSIF error->msg=user_not_found]
"[error->email]" : user unknown

[ELSIF error->msg=user_not_found]
"[error->email]" is not a subscriber

[ELSIF error->msg=passwd_not_found]
No password for user "[error->email]"

[ELSIF error->msg=incorrect_passwd]
Provided password is incorrect

[ELSIF error->msg=uncomplete_passwd]
Provided password is uncomplete

[ELSIF error->msg=no_user]
You need to login

[ELSIF error->msg=may_not]
[error->action] : you are not allowed to perform this action
[IF ! user->email]
<BR>you need to login
[ENDIF]

[ELSIF error->msg=no_subscriber]
List has no subscriber

[ELSIF error->msg=no_bounce]
List has no bouncing subscriber

[ELSIF error->msg=no_page]
No page [error->page]

[ELSIF error->msg=no_filter]
Missing filter

[ELSIF error->msg=file_not_editable]
[error->file] : file not editable

[ELSIF error->msg=already_subscriber]
You are already subscriber in list [error->list]

[ELSIF error->msg=user_already_subscriber]
[error->email] is already subscriber in list [error->list] 

[ELSIF error->msg=sent_to_owner]
Your request has been forwarded to the list owner

[ELSIF error->msg=failed_add]
Failed adding user [error->user]

[ELSIF error->msg=failed]
Action failed

[ELSIF error->msg=add_performed]
[error->total] subscribers added

[ELSIF error->msg=performed]
[error->action] : action succeeded

[ELSIF error->msg=not_subscriber]
You are not subscriber in list [error->list]

[ELSIF error->msg=diff_passwd]
The 2 passwords differ

[ELSIF error->msg=missing_arg]
Missing argument [error->argument]

[ELSIF error->msg=no_bounce]
No bounce for user  [error->email]

[ELSIF error->msg=update_privilege_bypassed]
You have changed a parameter without permissions: [error->pname]

[ELSIF error->msg=list_config_updated]
Configuration file has been updated

[ELSIF error->msg=config_changed]
Config file has been modified by [error->email]. Cannot apply your changes

[ELSIF error->msg=syntax_errors]
Syntax errors with the following parameters : [error->params]



[ELSIF error->msg=no_such_document]
[error->path] : No such file or directory 

[ELSIF error->msg=no_such_file]
[error->path] : No such file  

[ELSIF error->msg=empty_document] 
Unable to read [error->path] : empty document

[ELSIF error->msg=no_description] 
No description specified

[ELSIF error->msg=no_content]
Failed : your content is empty  

[ELSIF error->msg=no_name]
No name specified  

[ELSIF error->msg=incorrect_name]
[error->name] : incorrect name 

[ELSIF error->msg = index_html]
You're not authorized to upload an INDEX.HTML in [error->dir] 

[ELSIF error->msg=synchro_failed]
Data have changed on disk. Cannot apply your changes 

[ELSIF error->msg=cannot_overwrite] 
Cannot overwrite file [error->path] : [error->reason]

[ELSIF error->msg=cannot_upload] 
Cannot upload file [error->path] : [error->reason]

[ELSIF error->msg=cannot_create_dir] 
Cannot create directory [error->path] : [error->reason]

[ELSIF error->msg=upload_success] 
File [error->path] successfully uploaded!

[ELSIF error->msg=save_success] 
File [error->path] saved

[ELSIF error->msg=full_directory]
Failed : [error->directory] not empty 

[ELSIF error->msg=password_sent]
Your password has been emailed to you

 

[ELSE]
[error->msg]
[ENDIF]

<BR>
[END]