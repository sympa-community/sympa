
<FORM ACTION="[path_cgi]" METHOD=POST>

<P>
<TABLE>
 <TR>
   <TD NOWRAP><B>Nom de liste :</B></TD>
   <TD><INPUT TYPE="text" NAME="listname" SIZE=30 VALUE="[saved->listname]"></TD>
   <TD><img src="/icons/unknown.gif" alt="Attention, le nom pas l'adresse !"></TD>
 </TR>
 
 <TR>
   <TD NOWRAP><B>Propriétaire:</B></TD>
   <TD><I>[user->email]</I></TD>
   <TD><img src="/icons/unknown.gif" alt="Vous êtes le propriétaire de cette liste"></TD>
 </TR>

 <TR>
   <TD valign=top NOWRAP><B>Type de liste :</B></TD>
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
    <TD valign=top><img src="/icons/unknown.gif" alt="Le type de liste est un ensemble de paramètres regroupé dans un profile. s paramètres sont ré-éditable un à un une fois la liste créée"></TD>
 </TR>
 <TR>
   <TD NOWRAP><B>Object:</B></TD>
   <TD><INPUT TYPE="text" NAME="subject" SIZE=60 VALUE="[saved->subject]"></TD>
   <TD><img src="/icons/unknown.gif" alt="L'object de la liste"></TD>
 </TR>
 <TR>
   <TD NOWRAP><B>Catégories:</B></TD>
   <TD><SELECT NAME="topics">
	<OPTION VALUE="">--Choisir une catégorie--
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
   <TD valign=top><img src="/icons/unknown.gif" alt="Classement de liste dans l'annuaire"></TD>
 </TR>
 <TR>
   <TD valign=top NOWRAP><B>Description:</B></TD>
   <TD><TEXTAREA COLS=60 ROWS=10 NAME="info">[saved->info]</TEXTAREA></TD>
   <TD valign=top><img src="/icons/unknown.gif" alt="La liste en quelques lignes"></TD>
 </TR>

 <TR>
   <TD COLSPAN=2 ALIGN="center">
    <TABLE>
     <TR>
      <TD BGCOLOR="--LIGHT_COLOR--">
<INPUT TYPE="submit" NAME="action_create_list" VALUE="Envoyer votre demande de création">
      </TD>
     </TR></TABLE>
</TD></TR>
</TABLE>



</FORM>




