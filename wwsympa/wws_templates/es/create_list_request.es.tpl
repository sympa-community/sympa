<!-- RCS Identication ; $Revision$ ; $Date$ -->


<FORM ACTION="[path_cgi]" METHOD=POST>

<P>
<TABLE>
 <TR>
   <TD NOWRAP><B>Nombre de la Lista:</B></TD>
   <TD><INPUT TYPE="text" NAME="listname" SIZE=30 VALUE="[saved->listname]"></TD>
   <TD><img src="/icons/unknown.png" alt="nombre de la lista ; no su dirección!"></TD>
 </TR>
 
 <TR>
   <TD NOWRAP><B>Propietario:</B></TD>
   <TD><I>[user->email]</I></TD>
   <TD><img src="/icons/unknown.png" alt="Vd. es el propietaro de esta lista"></TD>
 </TR>

 <TR>
   <TD valign=top NOWRAP><B>Tipo de Lista :</B></TD>
   <TD>
     <MENU>
[FOREACH template IN list_list_tpl]
     <INPUT TYPE="radio" NAME="template" Value="[template->NAME]"
     [IF template->selected]
       CHECKED
     [ENDIF]
     > [template->NAME]<BR>
     [PARSE template->comment]
     <BR>
[END]
     </MENU>
    </TD>
    <TD valign=top><img src="/icons/unknown.png" alt="El tipo de lista es un conjunto de parámetros. Estos, son editables, una vez que la lista haya sido creada"></TD>
 </TR>
 <TR>
   <TD NOWRAP><B>Tema:</B></TD>
   <TD><INPUT TYPE="text" NAME="subject" SIZE=60 VALUE="[saved->subject]"></TD>
   <TD><img src="/icons/unknown.png" alt="El tema de la lista"></TD>
 </TR>
 <TR>
   <TD NOWRAP><B>Tópicos:</B></TD>
   <TD><SELECT NAME="topics">
	<OPTION VALUE="" >--Seleccione un tópico--
	[FOREACH topic IN list_of_topics]
	  <OPTION VALUE="[topic->NAME]"
	  [IF topic->selected]
	    SELECTED
	  [ENDIF]
	  >[topic->title]
	  [IF topic->sub]
	  [FOREACH subtopic IN topic->sub]
	     <OPTION VALUE="[topic->NAME]/[subtopic->NAME]">[topic->title] / [subtopic->title]
	  [END]
	  [ENDIF]
	[END]
     </SELECT>
   </TD>
   <TD valign=top><img src="/icons/unknown.png" alt="Clasificación de la lista en el directorio"></TD>
 </TR>
 <TR>
   <TD valign=top NOWRAP><B>Descripción:</B></TD>
   <TD><TEXTAREA COLS=60 ROWS=10 NAME="info">[saved->info]</TEXTAREA></TD>
   <TD valign=top><img src="/icons/unknown.png" alt="Un par de líneas describiendo la lista"></TD>
 </TR>

 <TR>
   <TD COLSPAN=2 ALIGN="center">
    <TABLE>
     <TR>
      <TD BGCOLOR="[light_color]">
<INPUT TYPE="submit" NAME="action_create_list" VALUE="Enviar su petición de creación de lista">
      </TD>
     </TR></TABLE>
</TD></TR>
</TABLE>



</FORM>




