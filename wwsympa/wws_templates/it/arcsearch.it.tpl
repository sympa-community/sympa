<!-- RCS Identication ; $Revision$ ; $Date$ -->

<H2>Risultati della ricerca negli archivi
<A HREF="[path_cgi]/arc/[list]/[archive_name]"><FONT COLOR="--DARK_COLOR--">[list]</font></a> : </H2>

<P>Campo di ricerca : 
[FOREACH u IN directories]
<A HREF="[path_cgi]/arc/[list]/[u]"><FONT COLOR="--DARK_COLOR--">[u]</font></a> - 
[END]
</P>

Parametri di questa ricerca fatti su <b> &quot;[key_word]&quot;</b> 
<I>

[IF how=phrase]
	(Questa frase,
[ELSIF how=any]
	(Tutte le parole,
[ELSE]
	(Ognuna di queste parole, 
[ENDIF]

<i>

[IF case]
	maiuscole e minuscole indifferenti
[ELSE]
	maiuscole e minuscole sono differenti
[ENDIF]

[IF match]
	e controllo su parte della parola)</i>
[ELSE]
	e controllo su tutta la parola)</i>
[ENDIF]
<p>

<HR>

[IF age]
	<B>Ultimi messaggi prima</b><P>
[ELSE]
	<B>Vecchi messaggi prima</b><P>
[ENDIF]

[FOREACH u IN res]
	<DT><A HREF=[u->file]>[u->subj]</A> -- <EM>[u->date]</EM><DD>[u->from]<PRE>[u->body_string]</PRE>
[END]

<DL>
<B>Risultati</b>
<DT><B>[searched] messaggi selezionati tra [num] ...</b><BR>

[IF body]
	<DD><B>[body_count]</b> risultati sul <i>corpo</i> del messaggio<BR>
[ENDIF]

[IF subj]
	<DD><B>[subj_count]</b> risultati sul<i>Soggetto</i> del messaggio<BR>
[ENDIF]

[IF from]
	<DD><B>[from_count]</b> risultati sul <i>Mittente</i> del messaggio<BR>
[ENDIF]

[IF date]
	<DD><B>[date_count]</b> risultati sulla <i>Data</i> del messaggio<BR>
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
	<INPUT NAME=action_arcsearch TYPE=submit VALUE="Continua la ricerca">
[ENDIF]

<INPUT NAME=action_arcsearch_form TYPE=submit VALUE="Nuova ricerca">
</FORM>
<HR>
Basata su <Font size=+1 color="--DARK_COLOR--"><i><A HREF="http://www.mhonarc.org/contrib/marc-search/">Marc-Search</a></i></font>, motore di ricerca degli archivi di <B>MHonArc</B><p>

<A HREF="[path_cgi]/arc/[list]/[archive_name]"><B>Torna all'archivio [archive_name] 
</B></A><br>
