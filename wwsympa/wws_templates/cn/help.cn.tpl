<!-- RCS Identication ; $Revision$ ; $Date$ -->

[IF help_topic]
 [PARSE help_template]

[ELSE]
<BR>
您可以在这里访问邮件邮递表服务器 <B>[conf->email]@[conf->host]</B>。
<BR><BR>
和 Sympa 机器人命令(通过邮件进行)相同的功能可以从高级别的用户界面上使用。
WWSympa 提供可定制的环境，可使用以下功能: 

<UL>
<LI><A HREF="[path_cgi]/pref">首选项</A>: 用户首选项。仅提供给确认身份的用户。

<LI><A HREF="[path_cgi]/lists">公开邮递表</A>: 服务器上提供的公开邮递表。

<LI><A HREF="[path_cgi]/which">您订阅的邮递表</A>: 您作为订阅者或拥有者的环境。

<LI><A HREF="[path_cgi]/loginrequest">登录</A>或<A HREF="[path_cgi]/logout">注销</A>: 从 WWSympa 上登录或退出。
</UL>

<H2>登录</H2>

在验证身份(<A HREF="[path_cgi]/loginrequest">登录</A>)时，请提供您的 Email 地址和相应的口令。
<BR><BR>
一旦通过验证，一个包含您登录信息的 <I>cookie</I> 使您能够持续访问 WWSympa。
这个 <I>cookie</I> 的生存期可以在您的<A HREF="[path_cgi]/pref">首选项</A>中指定。

<BR><BR>
您可以在任何时候使用<A HREF="[path_cgi]/logout">注销</A>功能来注销(删除
<I>cookie</I>)。

<H5>登录问题</H5>

<I>我不是邮递表的订阅者</I><BR>
所以您没有在 Sympa 的用户数据库中登记且无法登录。
如果您订阅了一个邮递表，WWSympa 将给您一个初始口令。
<BR><BR>

<I>我是至少一个邮递表的订阅者，但是我没有口令</I><BR>
要收到口令:
<A HREF="[path_cgi]/remindpasswd">[path_cgi]/remindpasswd</A>
<BR><BR>

<I>我忘记了口令</I><BR>
WWSympa 可以通过电子邮件来告诉您口令:
<A HREF="[path_cgi]/remindpasswd">[path_cgi]/remindpasswd</A>

<P>

如果要联系服务器管理员: <A HREF="mailto:listmaster@[conf->host]">listmaster@[conf->host]</A>
[ENDIF]













