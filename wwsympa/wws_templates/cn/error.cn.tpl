<!-- RCS Identication ; $Revision$ ; $Date$ -->

[IF error_msg=unknown_action]
[error->action] : 未知操作

[ELSIF error_msg=unknown_list]
[error->list] : 未知邮递表

[ELSIF error_msg=already_login]
您已经以 [error->email] 登录

[ELSIF error_msg=no_email]
请输入您的电子邮件地址

[ELSIF error_msg=incorrect_email]
地址“[error->email]”是错误的

[ELSIF error_msg=incorrect_listname]
“[error->listname]”: 错误的邮递表名

[ELSIF error_msg=no_passwd]
请输入您的口令

[ELSIF error_msg=user_not_found]
“[error->email]”: 未知用户

[ELSIF error_msg=user_not_found]
“[error->email]”不是订阅者

[ELSIF error_msg=passwd_not_found]
用户“[error->email]”没有口令

[ELSIF error_msg=incorrect_passwd]
输入的口令不正确

[ELSIF error_msg=no_user]
您需要先登录

[ELSIF error_msg=may_not]
[error->action]: 您不被允许进行这个操作
[IF ! user->email]
<BR>您需要先登录
[ENDIF]

[ELSIF error_msg=no_subscriber]
邮递表没有订阅者

[ELSIF error_msg=no_bounce]
邮递表没有被退信的订阅者

[ELSIF error_msg=no_page]
没有页 [error->page]

[ELSIF error_msg=no_filter]
缺少过滤

[ELSIF error_msg=file_not_editable]
[error->file]: 文件不可编辑

[ELSIF error_msg=already_subscriber]
您已经订阅了邮递表 [error->list]

[ELSIF error_msg=user_already_subscriber]
[error->email] 已经订阅了邮递表 [error->list] 

[ELSIF error_msg=failed]
操作失败

[ELSIF error_msg=not_subscriber]
您不是邮递表 [error->list] 的订阅者

[ELSIF error_msg=diff_passwd]
两个口令不一致

[ELSIF error_msg=missing_arg]
缺少参数 [error->argument]

[ELSIF error_msg=no_bounce]
用户 [error->email] 没有退信

[ELSIF error_msg=update_privilege_bypassed]
您在没有权限的情况下修改了一个参数: [error->pname]

[ELSIF error_msg=config_changed]
配置文件已经被 [error->email] 修改。无法应用您的修改

[ELSIF error_msg=syntax_errors]
下列参数语法错误: [error->params]

[ELSIF error_msg=no_such_document]
[error->path]: 没有此文件或目录

[ELSIF error_msg=no_such_file]
[error->path] : 没有此文件

[ELSIF error_msg=empty_document] 
无法读取 [error->path] : 空的文档

[ELSIF error_msg=no_description] 
没有指定描述

[ELSIF error_msg=no_content]
错误: 您提供的内容是空的

[ELSIF error_msg=no_name]
没有指定名字

[ELSIF error_msg=incorrect_name]
[error->name]: 不正确的名字

[ELSIF error_msg = index_html]
您没有被授权上传一个 INDEX.HTML 到 [error->dir] 

[ELSIF error_msg=synchro_failed]
磁盘数据已经改变。无法应用您的修改

[ELSIF error_msg=cannot_overwrite] 
无法覆盖文件 [error->path] : [error->reason]

[ELSIF error_msg=cannot_upload] 
无法上传文件 [error->path] : [error->reason]

[ELSIF error_msg=cannot_create_dir] 
无法建立目录 [error->path] : [error->reason]

[ELSIF error_msg=full_directory]
失败: [error->directory] 不为空

[ELSIF error_msg=password_sent]
已经用电子邮件将您的口令发送给您

 

[ELSE]
[error_msg]
[ENDIF]
