<!-- RCS Identication ; $Revision$ ; $Date$ -->

<H2>Výsledek Va¹eho hledání v archívu
<A HREF="[path_cgi]/arc/[list]/[archive_name]"><FONT COLOR="#330099">[list]</font></a> : </H2>

<P>Pole hledání : 
[FOREACH u IN directories]
<A HREF="[path_cgi]/arc/[list]/[u]"><FONT COLOR="#330099">[u]</font></a> - 
[END]
</P>

Parametry toho hledání <b> &quot;[key_word]&quot;</b> 
<I>

[IF how=phrase]
	(Tato vìta, 
[ELSIF how=any]
	(V¹echny slova, 
[ELSE]
	(Jakékoli slovo, 
[ENDIF]

<i>

[IF case]
	nazávisle na velikosti písmen 
[ELSE]
	rozli¹ovat velikost písmen 
[ENDIF]

[IF match]
	staèí zaèátek slova)</i>
[ELSE]
	musí být celé slovo)</i>
[ENDIF]
<p>

<HR>

[IF age]
	<B>Zaèít od nejnovìj¹ích zpráv</b><P>
[ELSE]
	<B>Zaèit od nejstar¹ích zpráv</b><P>
[ENDIF]

[FOREACH u IN res]
	<DT><A HREF=[u->file]>[u->subj]</A> -- <EM>[u->date]</EM><DD>[u->from]<PRE>[u->body_string]</PRE>
[END]

<DL>
<B>Výsledek</b>
<DT><B>[searched] zpráv vybráno z [num]...</b><BR>

[IF body]
	<DD><B>[body_count]</b> shod v <i>tìle</i> zprávy<BR>
[ENDIF]

[IF subj]
	<DD><B>[subj_count]</b> shod v <i>subjektu</i> zprávy<BR>
[ENDIF]

[IF from]
	<DD><B>[from_count]</b> shod v poli <i>From</i><BR>
[ENDIF]

[IF date]
	<DD><B>[date_count]</b> shod v poli <i>Date</i><BR>
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
	<INPUT TYPE=hidden NAME=body Value="[tìlo]">
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
	<INPUT NAME=action_arcsearch TYPE=submit VALUE="Pokraèovat ve hledání">
[ENDIF]

<INPUT NAME=action_arcsearch_form TYPE=submit VALUE="Nové hledání">
</FORM>
<HR>
Zalo¾eno na <Font size=+1 color="#330099"><i><A HREF="http://www.mhonarc.org/contrib/marc-search/">Marc-Search</a></i></font>, vyhledávacím stroji<B>MHonArc</B> archívù<p>


<A HREF="[path_cgi]/arc/[list]/[archive_name]"><B>Návrat k archívu [archive_name] 
</B></A><br>
