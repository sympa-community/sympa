<!-- RCS Identication ; $Revision$ ; $Date$ -->

<H2>Hakusi arkistossa tuotti seuraavat tulokset
<A HREF="[path_cgi]/arc/[list]/[archive_name]"><FONT COLOR="[dark_color]">[list]</font></a> : </H2>

<P>Hakukentt‰ : 
[FOREACH u IN directories]
<A HREF="[path_cgi]/arc/[list]/[u]"><FONT COLOR="[dark_color]">[u]</font></a> - 
[END]
</P>

Haun parametrit sanalle <b> &quot;[key_word]&quot;</b> 
<I>

[IF how=phrase]
	(T‰m‰ lause,
[ELSIF how=any]
	(Kaikki sanat, 
[ELSE]
	(Jokainen sanoista, 
[ENDIF]

<i>

[IF case]
	EI ota huomioon isot ja pienet kirjaimet
[ELSE]
	OTTAA huomioon isot ja pienet kirjaimet
[ENDIF]

[IF match]
	ja tarkistaa osan sanasta)</i>
[ELSE]
	ja tarkistaa koko sanan)</i>
[ENDIF]
<p>

<HR>

[IF age]
	<B>Uusi viesti ensiksi</b><P>
[ELSE]
	<B>Vanhin viestin ensiksi</b><P>
[ENDIF]

[FOREACH u IN res]
	<DT><A HREF=[u->file]>[u->subj]</A> -- <EM>[u->date]</EM><DD>[u->from]<PRE>[u->body_string]</PRE>
[END]

<DL>
<B>Tulokset</b>
<DT><B>[searched] viesti‰ valittuna [num] viestist‰...</b><BR>

[IF body]
	<DD><B>[body_count]</b> osumaa viestin <i>Sis‰ltˆ</i>kentt‰‰n<BR>
[ENDIF]

[IF subj]
	<DD><B>[subj_count]</b> osumaa viestin <i>Otsikko</i> kentt‰‰n<BR>
[ENDIF]

[IF from]
	<DD><B>[from_count]</b> osumaa viestin <i>L‰hett‰j‰</i> kentt‰‰n<BR>
[ENDIF]

[IF date]
	<DD><B>[date_count]</b> osumaa viestin <i>Pvm</i> kentt‰‰n<BR>
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
	<INPUT NAME=action_arcsearch TYPE=submit VALUE="Jatka hakua">
[ENDIF]

<INPUT NAME=action_arcsearch_form TYPE=submit VALUE="Uusi haku">
</FORM>
<HR>
Perustuu <Font size=+1 color="[dark_color]"><i><A HREF="http://www.mhonarc.org/contrib/marc-search/">Marc-Search</a></i></font>, hakukone <B>MHonArc</B> arkistoille.<p>


<A HREF="[path_cgi]/arc/[list]/[archive_name]"><B>Palaa arkistoon [archive_name] 
</B></A><br>
