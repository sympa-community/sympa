<!-- RCS Identication ; $Revision$ ; $Date$ -->

<H2>Result of your search in the archive 
<A HREF="[path_cgi]/arc/[list]/[archive_name]"><FONT COLOR="--DARK_COLOR--">[list]</font></a> : </H2>

<P>Search field : 
[FOREACH u IN directories]
<A HREF="[path_cgi]/arc/[list]/[u]"><FONT COLOR="--DARK_COLOR--">[u]</font></a> - 
[END]
</P>

Parameters of these search make on <b> &quot;[key_word]&quot;</b> 
<I>

[IF how=phrase]
	(This sentence, 
[ELSIF how=any]
	(All of this words, 
[ELSE]
	(Each of this words, 
[ENDIF]

<i>

[IF case]
	case insensitive 
[ELSE]
	case sensitive 
[ENDIF]

[IF match]
	and checking on part of word)</i>
[ELSE]
	and checking on entire word)</i>
[ENDIF]
<p>

<HR>

[IF age]
	<B>Newest messages first</b><P>
[ELSE]
	<B>Oldest messages first</b><P>
[ENDIF]

[FOREACH u IN res]
	<DT><A HREF=[u->file]>[u->subj]</A> -- <EM>[u->date]</EM><DD>[u->from]<PRE>[u->body_string]</PRE>
[END]

<DL>
<B>Result</b>
<DT><B>[searched] messages selected amongst [num]...</b><BR>

[IF body]
	<DD><B>[body_count]</b> hits on message's <i>Body</i><BR>
[ENDIF]

[IF subj]
	<DD><B>[subj_count]</b> hits on message's <i>Subject</i> field<BR>
[ENDIF]

[IF from]
	<DD><B>[from_count]</b> hits on message's <i>From</i> field<BR>
[ENDIF]

[IF date]
	<DD><B>[date_count]</b> hits on message's <i>Date</i> field<BR>
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
	<INPUT NAME=action_arcsearch TYPE=submit VALUE="Continue search">
[ENDIF]

<INPUT NAME=action_arcsearch_form TYPE=submit VALUE="New search">
</FORM>
<HR>
Based on <Font size=+1 color="--DARK_COLOR--"><i><A HREF="http://www.mhonarc.org/contrib/marc-search/">Marc-Search</a></i></font>, search engine of <B>MHonArc</B> archives<p>


<A HREF="[path_cgi]/arc/[list]/[archive_name]"><B>Return to archive [archive_name] 
</B></A><br>
