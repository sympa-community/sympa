<!-- RCS Identication ; $Revision$ ; $Date$ -->

<H2>Resultaat van uw zoekopdracht in het archief 
<A HREF="[path_cgi]/arc/[list]/[archive_name]"><FONT COLOR="[dark_color]">[list]</font></a> : </H2>

<P>Zoek veld : 
[FOREACH u IN directories]
<A HREF="[path_cgi]/arc/[list]/[u]"><FONT COLOR="[dark_color]">[u]</font></a> - 
[END]
</P>

Deze zoekopdracht bevatte: <b> &quot;[key_word]&quot;</b> 
<I>

[IF how=phrase]
	(deze zin, 
[ELSIF how=any]
	(All woorden, 
[ELSE]
	(Elk van deze woorden, 
[ENDIF]

<i>

[IF case]
	geen onderschied tussen hoofd- en kleine letters 
[ELSE]
        onderscheid tussen hoofd- en kleine letters
[ENDIF]

[IF match]
	en controleren op gedeelte van een woord)</i>
[ELSE]
	en controleren op hele woorden)</i>
[ENDIF]
<p>

<HR>

[IF age]
	<B>Nieuwste berichten eerst</b><P>
[ELSE]
	<B>Oudste berichten eerst</b><P>
[ENDIF]

[FOREACH u IN res]
	<DT><A HREF=[u->file]>[u->subj]</A> -- <EM>[u->date]</EM><DD>[u->from]<PRE>[u->body_string]</PRE>
[END]

<DL>
<B>Resultaat</b>
<DT><B>[searched] berichten geselecteerd van [num]...</b><BR>

[IF body]
	<DD><B>[body_count]</b> keer raak op bericht <i>Inhoud</i><BR>
[ENDIF]

[IF subj]
	<DD><B>[subj_count]</b> keer raak op bericht <i>onderwerp</i> veld<BR>
[ENDIF]

[IF from]
	<DD><B>[from_count]</b> keer raak op bericht <i>Van</i> veld<BR>
[ENDIF]

[IF date]
	<DD><B>[date_count]</b> keer raak op bericht <i>Datum</i> veld<BR>
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
	<INPUT NAME=action_arcsearch TYPE=submit VALUE="Doorgaan met zoeken">
[ENDIF]

<INPUT NAME=action_arcsearch_form TYPE=submit VALUE="Nieuwe zoekopdracht">
</FORM>
<HR>
Based on <Font size=+1 color="[dark_color]"><i><A
HREF="http://www.mhonarc.org/contrib/marc-search/">Marc-Search</a></i></font>,zoekengine van <B>MHonArc</B> archieven<p>


<A HREF="[path_cgi]/arc/[list]/[archive_name]"><B>Terug naar archief [archive_name] 
</B></A><br>
