<!-- RCS Identication ; $Revision$ ; $Date$ -->

<H2> Otsingu tulemused: 
<A HREF="[path_cgi]/arc/[list]/[archive_name]"><FONT COLOR="[dark_color]">[list]</font></a> : </H2>

<P>Otsiti listi arhiivist aegadel: 
[FOREACH u IN directories]
<A HREF="[path_cgi]/arc/[list]/[u]"><FONT COLOR="[dark_color]">[u]</font></a> - 
[END]
</P>

Parameters of these search make on <b> &quot;[key_word]&quot;</b> 
<I>

[IF how=phrase]
	(See lause, 
[ELSIF how=any]
	(Üks sõnadest, 
[ELSE]
	(Kõik sõnad, 
[ENDIF]

<i>

[IF case]
	 tõstutundetu,
[ELSE]
	 tõstutundlik, 
[ENDIF]

[IF match]
	 otsitakse sõnade osi)</i>
[ELSE]
	 otsitakse terveid sõnu)</i>
[ENDIF]
<p>

<HR>

[IF age]
	<B>Uuemad kirjad eespool</b><P>
[ELSE]
	<B>Vanemad kirjad eespool</b><P>
[ENDIF]

[FOREACH u IN res]
	<DT><A HREF=[u->file]>[u->subj]</A> -- <EM>[u->date]</EM><DD>[u->from]<PRE>[u->body_string]</PRE>
[END]

<DL>
<B>Tulemused</b>
<DT><B>leiti [searched] kirja kokku  [num] kirjast...</b><BR>

[IF body]
	<DD><B>[body_count]</b> vastet kirja <i>sisus</i><BR>
[ENDIF]

[IF subj]
	<DD><B>[subj_count]</b> vastet kirja <i>teemareal</i><BR>
[ENDIF]

[IF from]
	<DD><B>[from_count]</b> vastet kirja <i>saatja aadressil</i><BR>
[ENDIF]

[IF date]
	<DD><B>[date_count]</b> vastet kirja <i>kuupäevareal</i> field<BR>
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
	<INPUT NAME=action_arcsearch TYPE=submit VALUE="Jätka otsinguga">
[ENDIF]

<INPUT NAME=action_arcsearch_form TYPE=submit VALUE="Uus otsing">
</FORM>
<HR>
Töötab kasutades <Font size=+1 color="[dark_color]"><i><A HREF="http://www.mhonarc.org/contrib/marc-search/">Marc-Search</a></i></font>, <B>MHonArc</B> arhiivide otsingumootorit<p>


<A HREF="[path_cgi]/arc/[list]/[archive_name]"><B>Tagasi arhiivi [archive_name] 
</B></A><br>
