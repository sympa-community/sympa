<!-- RCS Identication ; $Revision$ ; $Date$ -->

<H2>Resultados de su búsqueda en el archivo
<A HREF="[path_cgi]/arc/[list]/[archive_name]"><FONT COLOR="--DARK_COLOR--">[list]</font></a> : </H2>

<P>Campo de búsqueda: 
[FOREACH u IN directories]
<A HREF="[path_cgi]/arc/[list]/[u]"><FONT COLOR="--DARK_COLOR--">[u]</font></a> - 
[END]
</P>

Parámetros de esta búsqueda hechos en <b> &quot;[key_word]&quot;</b> 
<I>

[IF how=phrase]
	(Esta frase, 
[ELSIF how=any]
	(Todas estas palabras, 
[ELSE]
	(Cada una de estas palabras, 
[ENDIF]

<i>

[IF case]
	no sensible a mayúsculas
[ELSE]
	sensible a mayúsculas
[ENDIF]

[IF match]
	y comprobar parte de la palabra)</i>
[ELSE]
	y comprobar la palabra entera)</i>
[ENDIF]
<p>

<HR>

[IF age]
	<B>Mensajes más nuevoe primero</b><P>
[ELSE]
	<B>Mensajes más viejo primero</b><P>
[ENDIF]

[FOREACH u IN res]
	<DT><A HREF=[u->file]>[u->subj]</A> -- <EM>[u->date]</EM><DD>[u->from]<PRE>[u->body_string]</PRE>
[END]

<DL>
<B>Result</b>
<DT><B>[searched] mensajes seleccionados entre [num]...</b><BR>

[IF body]
	<DD><B>[body_count]</b> coincidencias en el <i>Cuerpo</i> del mensaje<BR>
[ENDIF]

[IF subj]
	<DD><B>[subj_count]</b> coincidencias en el <i>Tema</i> del mensaje<BR>
[ENDIF]

[IF from]
	<DD><B>[from_count]</b> coincidencias en el <i>De:</i> del mensaje<BR>
[ENDIF]

[IF date]
	<DD><B>[date_count]</b> coincidencias en la <i>Fecha:</i> del mensaje<BR>
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
	<INPUT NAME=action_arcsearch TYPE=submit VALUE="Continuar la búsqueda">
[ENDIF]

<INPUT NAME=action_arcsearch_form TYPE=submit VALUE="Nueva búsqueda">
</FORM>
<HR>
Basado en <Font size=+1 color="--DARK_COLOR--"><i><A HREF="http://www.mhonarc.org/contrib/marc-search/">Marc-Search</a></i></font>, motor de búsqueda de <B>MHonArc</B> archivos<p>


<A HREF="[path_cgi]/arc/[list]/[archive_name]"><B>Volver al archivo [archive_name] 
</B></A><br>
