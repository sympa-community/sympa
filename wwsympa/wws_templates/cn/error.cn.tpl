<!-- RCS Identication ; $Revision$ ; $Date$ -->

[FOREACH error IN errors]

[IF error->msg=unknown_action]
[error->action] : 未知操作

[ELSIF error->msg=unknown_list]
[error->list] : 未知邮递表

[ELSIF error->msg=already_login]
您已经以 [error->email] 登录

[ELSIF error->msg=no_email]
请输入您的电子邮件地址

[ELSIF error->msg=incorrect_email]
地址“[error->email]”是错误的

[ELSIF error->msg=incorrect_listname]
“[error->listname]”: 错误的邮递表名

[ELSIF error->msg=no_passwd]
请输入您的口令

[ELSIF error->msg=user_not_found]
“[error->email]”: 未知用户

[ELSIF error->msg=user_not_found]
“[error->email]”不是订阅者

[ELSIF error->msg=passwd_not_found]
用户“[error->email]”没有口令

[ELSIF error->msg=incorrect_passwd]
输入的口令不正确

[ELSIF error->msg=uncomplete_passwd]
输入的口令不完整

[ELSIF error->msg=no_user]
您需要先登录

[ELSIF error->msg=may_not]
[error->action]: 您不被允许进行这个操作
[IF ! user->email]
<BR>您需要先登录
[ENDIF]

[ELSIF error->msg=no_subscriber]
邮递表没有订阅者

[ELSIF error->msg=no_bounce]
邮递表没有被退信的订阅者

[ELSIF error->msg=no_page]
没有页 [error->page]

[ELSIF error->msg=no_filter]
缺少过滤

[ELSIF error->msg=file_not_editable]
[error->file]: 文件不可编辑

[ELSIF error->msg=already_subscriber]
您已经订阅了邮递表 [error->list]

[ELSIF error->msg=user_already_subscriber]
[error->email] 已经订阅了邮递表 [error->list] 

[ELSIF error->msg=failed_add]
新增使用者 [error->user] 失败

[ELSIF error->msg=failed]
[error->action]: 操作失败

[ELSIF error->msg=not_subscriber]
[IF error->email]
  并非订阅者: [error->email]
[ELSE]
您不是邮递表 [error->list] 的订阅者
[ENDIF]

[ELSIF error->msg=diff_passwd]
两个口令不一致

[ELSIF error->msg=missing_arg]
缺少参数 [error->argument]

[ELSIF error->msg=no_bounce]
用户 [error->email] 没有退信

[ELSIF error->msg=update_privilege_bypassed]
您在没有权限的情况下修改了一个参数: [error->pname]

[ELSIF error->msg=config_changed]
配置文件已经被 [error->email] 修改。无法应用您的修改

[ELSIF error->msg=syntax_errors]
下列参数语法错误: [error->params]

[ELSIF error->msg=no_such_document]
[error->path]: 没有此文件或目录

[ELSIF error->msg=no_such_file]
[error->path] : 没有此文件

[ELSIF error->msg=empty_document] 
无法读取 [error->path] : 空的文档

[ELSIF error->msg=no_description] 
没有指定描述

[ELSIF error->msg=no_content]
错误: 您提供的内容是空的

[ELSIF error->msg=no_name]
没有指定名字

[ELSIF error->msg=incorrect_name]
[error->name]: 不正确的名字

[ELSIF error->msg = index_html]
您没有被授权上传一个 INDEX.HTML 到 [error->dir] 

[ELSIF error->msg=synchro_failed]
磁盘数据已经改变。无法应用您的修改

[ELSIF error->msg=cannot_overwrite] 
无法覆盖文件 [error->path] : [error->reason]

[ELSIF error->msg=cannot_upload] 
无法上传文件 [error->path] : [error->reason]

[ELSIF error->msg=cannot_create_dir] 
无法建立目录 [error->path] : [error->reason]

[ELSIF error->msg=full_directory]
失败: [error->directory] 不为空

[ELSIF error->msg=init_passwd]
您并未选取口令, 请要求一份原先口令的提醒
 
[ELSIF error->msg=change_email_failed]
无法更改 [error->list] 的电邮位址

[ELSIF error->msg=change_email_failed_because_subscribe_not_allowed]
无法更新论坛 '[error->list]' 的订阅位址,
因为已禁止以新的位址订阅.

[ELSIF error->msg=change_email_failed_because_unsubscribe_not_allowed]
无法更新论坛 '[error->list]' 的订阅位址,
因为已禁止取消订阅.

[ELSE]
[error->msg]
[ENDIF]

<BR>
[END]
