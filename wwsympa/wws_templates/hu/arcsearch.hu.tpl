<!-- RCS Identication ; $Revision$ ; $Date$ -->

<H2>Találatok a(z) 
<A HREF="[path_cgi]/arc/[list]/[archive_name]"><FONT COLOR="[dark_color]">[list]</font></a> archívumban: </H2>

<P>Keresési tartomány: 
[FOREACH u IN directories]
<A HREF="[path_cgi]/arc/[list]/[u]"><FONT COLOR="[dark_color]">[u]</font></a> - 
[END]
</P>

Megadott paraméterek a keresésben a(z) <b> &quot;[key_word]&quot;</b> kulcsszavakhoz:
<I>

[IF how=phrase]
	(Teljes mondat, 
[ELSIF how=any]
	(Minden szó, 
[ELSE]
	(Bármyel szó, 
[ENDIF]

<i>

[IF case]
	kis- és nagybetû megkülönböztetése nélkül 
[ELSE]
	kis- és nagybetû megkülönböztetésével 
[ENDIF]

[IF match]
	és szórészeket is vizsgálva.)</i>
[ELSE]
	csak egész szavakat vizsgálva.)</i>
[ENDIF]
<p>

<HR>

[IF age]
	<B>Újabb üzenetek elõl</b><P>
[ELSE]
	<B>Régebbi üzenetek elõl</b><P>
[ENDIF]

[FOREACH u IN res]
	<DT><A HREF=[u->file]>[u->subj]</A> -- <EM>[u->date]</EM><DD>[u->from]<PRE>[u->body_string]</PRE>
[END]

<DL>
<B>Találatok</b>
<DT><B>[searched] találatból [num] mutatva...</b><BR>

[IF body]
	<DD><B>[body_count]</b> találat a levél <i>Törzsében</i><BR>
[ENDIF]

[IF subj]
	<DD><B>[subj_count]</b> találat a levél <i>Tárgy</i> mezõjében<BR>
[ENDIF]

[IF from]
	<DD><B>[from_count]</b> találat a levél <i>Feladója</i> mezõjében<BR>
[ENDIF]

[IF date]
	<DD><B>[date_count]</b> találat a levél <i>Dátum</i> mezõjében<BR>
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
	<INPUT NAME=action_arcsearch TYPE=submit VALUE="Keresés folytatása">
[ENDIF]

<INPUT NAME=action_arcsearch_form TYPE=submit VALUE="Új keresés">
</FORM>
<HR>
Keresést az archívumban a <b>MHonArc</b> keresõ programja, a <Font size=+1 color="[dark_color]"><i><A HREF="http://www.mhonarc.org/contrib/marc-search/">Marc-Search</a></i></font> végezte.<p>


<A HREF="[path_cgi]/arc/[list]/[archive_name]"><B>Vissza a(z) [archive_name] archívumhoz
</B></A><br>
