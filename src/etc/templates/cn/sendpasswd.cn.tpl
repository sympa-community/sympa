<!-- RCS Identication ; $Revision$ ; $Date$ -->
From: [conf->sympa]
Reply-to: [conf->request]
To: [newuser->email]
Subject: 您的 [conf->title] 环境设置

[IF action=subrequest]
您请求订阅邮递表 [list]。

要确认您的订阅，您需要使用以下的口令

	口令: [newuser->password]

[ELSIF action=sigrequest]
您请求退订邮递表 [list]。

要退订，您需要使用以下的口令

	口令: [newuser->password]

[ELSE]
要访问您个人的环境，您首先要登录

     您的邮件地址: [newuser->email]
     您 的 口 令 : [newuser->password]

修改您的口令
[base_url][path_cgi]/choosepasswd/[newuser->escaped_email]/[newuser->password]
[ENDIF]


[wwsconf->title]: [base_url][path_cgi] 

Sympa 的帮助: [base_url][path_cgi]/help

