<!-- RCS Identication ; $Revision$ ; $Date$ -->

<H2>在存档中搜索的结果
<A HREF="[path_cgi]/arc/[list]/[archive_name]"><FONT COLOR="[dark_color]">[list]</font></a>: </H2>

<P>查找域:
[FOREACH u IN directories]
<A HREF="[path_cgi]/arc/[list]/[u]"><FONT COLOR="[dark_color]">[u]</font></a> - 
[END]
</P>

查找参数的应用范围 <b> &quot;[key_word]&quot;</b>
<I>

[IF how=phrase]
	(本句话，
[ELSIF how=any]
	(所有的词，
[ELSE]
	(每个词，
[ENDIF]

<i>

[IF case]
	不区分大小写
[ELSE]
	区分大小写
[ENDIF]

[IF match]
	和检查词的部分)</i>
[ELSE]
	和检查整个词)</i>
[ENDIF]
<p>

<HR>

[IF age]
	<B>最新邮件优先</b><P>
[ELSE]
	<B>最旧邮件优先</b><P>
[ENDIF]

[FOREACH u IN res]
	<DT><A HREF=[u->file]>[u->subj]</A> -- <EM>[u->date]</EM><DD>[u->from]<PRE>[u->body_string]</PRE>
[END]

<DL>
<B>结果</b>
<DT><B>在 [num] 中选中了 [searched] 个邮件 ...</b><BR>

[IF body]
	<DD>根据邮件<i>内容</i>有 <B>[body_count]</b> 个命中<BR>
[ENDIF]

[IF subj]
	<DD>根据邮件<i>主题</i>有 <B>[subj_count]</b> 个命中<BR>
[ENDIF]

[IF from]
	<DD>根据邮件<i>发件人</i>有 <B>[from_count]</b> 个命中<BR>
[ENDIF]

[IF date]
	<DD>根据邮件<i>日期</i>有 <B>[date_count]</b> 个命中<BR>
[ENDIF]

</dl>

<FORM METHOD=POST ACTION="[path_cgi]">
<INPUT TYPE=hidden NAME=list		 VALUE="[list]">
<INPUT TYPE=hidden NAME=archive_name VALUE="[archive_name]">
<INPUT TYPE=hidden NAME=key_word     VALUE="[key_word]">
<INPUT TYPE=hidden NAME=how          VALUE="[how]">
<INPUT TYPE=hidden NAME=age          VALUE="[age]">
<INPUT TYPE=hidden NAME=case         VALUE="[case]">
<INPUT TYPE=hidden NAME=match        VALUE="[match]">
<INPUT TYPE=hidden NAME=limit        VALUE="[limit]">
<INPUT TYPE=hidden NAME=body_count   VALUE="[body_count]">
<INPUT TYPE=hidden NAME=date_count   VALUE="[date_count]">
<INPUT TYPE=hidden NAME=from_count   VALUE="[from_count]">
<INPUT TYPE=hidden NAME=subj_count   VALUE="[subj_count]">
<INPUT TYPE=hidden NAME=previous     VALUE="[searched]">

[IF body]
	<INPUT TYPE=hidden NAME=body Value="[body]">
[ENDIF]

[IF subj]
	<INPUT TYPE=hidden NAME=subj Value="[subj]">
[ENDIF]

[IF from]
	<INPUT TYPE=hidden NAME=from Value="[from]">
[ENDIF]

[IF date]
	<INPUT TYPE=hidden NAME=date Value="[date]">
[ENDIF]

[FOREACH u IN directories]
	<INPUT TYPE=hidden NAME=directories Value="[u]">
[END]

[IF continue]
	<INPUT NAME=action_arcsearch TYPE=submit VALUE="继续查找">
[ENDIF]

<INPUT NAME=action_arcsearch_form TYPE=submit VALUE="新的查找">
</FORM>
<HR>
基于<Font size=+1 color="[dark_color]"><i><A HREF="http://www.mhonarc.org/contrib/marc-search/">Marc-Search</a></i></font>，<B>MHonArc</B>归档的搜索引擎<p>


<A HREF="[path_cgi]/arc/[list]/[archive_name]"><B>回到归档 [archive_name] 
</B></A><br>
