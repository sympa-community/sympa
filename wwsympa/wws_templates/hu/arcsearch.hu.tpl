<!-- RCS Identication ; $Revision$ ; $Date$ -->

<H2>Találatok az archívumban 
<A HREF="[path_cgi]/arc/[list]/[archive_name]"><FONT COLOR="--DARK_COLOR--">[list]</font></a> : </H2>

<P>Keresendõ kifejezés: 
[FOREACH u IN directories]
<A HREF="[path_cgi]/arc/[list]/[u]"><FONT COLOR="--DARK_COLOR--">[u]</font></a> - 
[END]
</P>

A keresésben megadott feltételek <b> &quot;[key_word]&quot;</b> 
<I>

[IF how=phrase]
	(Ez a kifejezés, 
[ELSIF how=any]
	(Az összes megadott szó, 
[ELSE]
	(A szavak bármelyike, 
[ENDIF]

<i>

[IF case]
	kis- és nagybetû nem különbözik 
[ELSE]
	kis- és nagybetû megkülönböztetése 
[ENDIF]

[IF match]
	és ha bármelyik szóban megtalálható.)</i>
[ELSE]
	és csak ha ez a teljes szó.)</i>
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
	<DD><B>[body_count]</b> találat a levél <i>Törzsben</i><BR>
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
Keresést az archívumban a <Font size=+1 color="--DARK_COLOR--"><i><A HREF="http://www.mhonarc.org/contrib/marc-search/">Marc-Search</a></i></font> a <B>MHonArc</B>
keresõ program végezte.<p>


<A HREF="[path_cgi]/arc/[list]/[archive_name]"><B>Visszatérés a(z) [archive_name] archívumhoz
</B></A><br>
