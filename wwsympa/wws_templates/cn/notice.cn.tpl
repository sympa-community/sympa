[FOREACH notice IN notices]

[IF notice_msg=sent_to_owner]
您的请求已经被转发给邮递表所有者

[ELSIF notice_msg=performed]
[notice->action]: 操作成功

[ELSIF notice_msg=list_config_updated]
配置文件已经被更新

[ELSIF notice_msg=upload_success] 
成功上传文件 [notice->path] !

[ELSIF notice_msg=save_success] 
文件 [notice->path] 已保存

[ELSE]
[notice->msg]

[ENDIF]

<BR>
[END]




