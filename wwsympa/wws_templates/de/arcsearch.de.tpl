<!-- RCS Identication ; $Revision$ ; $Date$ -->

<H2>Ergebnisse Ihrer Suche im Archiv
<A HREF="[path_cgi]/arc/[list]/[archive_name]"><FONT COLOR="--DARK_COLOR--">[list]</font></a> : </H2>

<P>Suchfeld: 
[FOREACH u IN directories]
<A HREF="[path_cgi]/arc/[list]/[u]"><FONT COLOR="--DARK_COLOR--">[u]</font></a> - 
[END]
</P>

Parameter dieser Suche nach <b> &quot;[key_word]&quot;</b> 
<I>

[IF how=phrase]
	(Diese Phrase, 
[ELSIF how=any]
	(Eines dieser W&ouml;rter, 
[ELSE]
	(Jedes dieser W&ouml;rter, 
[ENDIF]

<i>

[IF case]
	GROSS/klein egal,
[ELSE]
	GROSS/klein wichtig,
[ENDIF]

[IF match]
	und Teilw&ouml;rter werden gefunden)</i>
[ELSE]
	und nur ganze W&ouml;rter werden gefunden)</i>
[ENDIF]
<p>

<HR>

[IF age]
	<B>Neusete Nachricht zuerst</b><P>
[ELSE]
	<B>&Auml;lteste Nachricht zuerst</b><P>
[ENDIF]

[FOREACH u IN res]
	<DT><A HREF=[u->file]>[u->subj]</A> -- <EM>[u->date]</EM><DD>[u->from]<PRE>[u->body_string]</PRE>
[END]

<DL>
<B>Ergebnis</b>
<DT><B>[searched] Nachrichten von [num] passen...</b><BR>

[IF body]
	<DD><B>[body_count]</b> Treffer im <i>Text</i> der Nachricht<BR>
[ENDIF]

[IF subj]
	<DD><B>[subj_count]</b> Treffer in der <i>&Uuml;berschrift</i><BR>
[ENDIF]

[IF from]
	<DD><B>[from_count]</b> Treffer im <i>Absender</i>-Feld<BR>
[ENDIF]

[IF date]
	<DD><B>[date_count]</b> Terffer im <i>Datums</i>-Feld<BR>
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
	<INPUT NAME=action_arcsearch TYPE=submit VALUE="Weiter suchen">
[ENDIF]

<INPUT NAME=action_arcsearch_form TYPE=submit VALUE="Neue Suche">
</FORM>
<HR>
Basierend auf <Font size=+1 color="--DARK_COLOR--"><i><A HREF="http://www.mhonarc.org/contrib/marc-search/">Marc-Search</a></i></font>, Suchmachine vom <B>MHonArc</B> Archiv<p>


<A HREF="[path_cgi]/arc/[list]/[archive_name]"><B>Zur&uuml;ck zum Archiv [archive_name] 
</B></A><br>
