<!-- RCS Identication ; $Revision$ ; $Date$ -->

<H2>Résultat de votre recherche dans l'archive
<A HREF="[path_cgi]/arc/[list]/[archive_name]"><FONT COLOR="[dark_color]">[list]</font></a> : </H2>

<P>Etendue de la recherche : 
[FOREACH u IN directories]
<A HREF="[path_cgi]/arc/[list]/[u]"><FONT COLOR="[dark_color]">[u]</font></a> - 
[END]
</P>

Recherche effectuée sur <b> &quot;[key_word]&quot;</b> 
<I>

[IF how=phrase]
	(Cette phrase, 
[ELSIF how=any]
	(Tout ces mots, 
[ELSE]
	(Chacun de ces mots, 
[ENDIF]

<i>

[IF case]
	pas de distinction majuscules/minuscules
[ELSE]
	distinction majuscules/minuscules activée
[ENDIF]

[IF match]
	et recherche sur des parties de mots)</i>
[ELSE]
	et recherche sur des mots entiers)</i>
[ENDIF]
<p>

<HR>

[IF age]
	<B>Messages les plus récents en tête</b><P>
[ELSE]
	<B>Messages les plus anciens en tête</b><P>
[ENDIF]

[FOREACH u IN res]
	<DT><A HREF=[u->file]>[u->subj]</A> -- <EM>[u->date]</EM><DD>[u->from]<PRE>[u->body_string]</PRE>
[END]

<DL>
<B>Résultats</b>
<DT><B>[searched] messages trouvés parmi [num]...</b><BR>

[IF body]
	<DD><B>[body_count]</b> occurence(s) dans le <i>corps</i><BR>
[ENDIF]

[IF subj]
	<DD><B>[subj_count]</b> occurence(s) dans le champs <i>Subject</i><BR>
[ENDIF]

[IF from]
	<DD><B>[from_count]</b> occurence(s) dans le champs <i>From</i><BR>
[ENDIF]

[IF date]
	<DD><B>[date_count]</b> occurence(s) dans le champs <i>Date</i><BR>
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

<INPUT NAME=action_arcsearch_form TYPE=submit VALUE="Nouvelle recherche">
</FORM>
<HR>
Recherche basée sur le moteur <Font size=+1 color="[dark_color]"><i><A HREF="http://www.mhonarc.org/contrib/marc-search/">Marc-Search</a></i></font><p>


<A HREF="[path_cgi]/arc/[list]/[archive_name]"><B>Retour dans l'archive [archive_name] 
</B></A><br>

