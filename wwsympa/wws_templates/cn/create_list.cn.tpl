<!-- RCS Identication ; $Revision$ ; $Date$ -->

[IF status=open]
您的邮递表已经创建。您可以试用它或者用管理按钮修改它的配置。
<BR>
[IF auto_aliases]
别名已成功设置。
[ELSE]
 <TABLE BORDER=1>
 <TR BGCOLOR="[light_color]"><TD align=center>所需别名</TD></TR>
 <TR>
 <TD>
 <pre><code>
 [aliases]
 </code></pre>
 </TD>
 </TR>
 </TABLE>
[ENDIF]


(建立有效的别名依赖于邮递表管理者，所以有可能您的邮递表地址还不能被识别。)
[ELSE]
您的邮递表创建请求已经被登记。您现在可以用管理按钮修改它的配置，但是
邮递表将在邮递表管理者使它生效后才可用。
[ENDIF]
