<!-- RCS Identication ; $Revision$ ; $Date$ -->


<FORM ACTION="[path_cgi]" METHOD=POST>

<P>
<TABLE>
 <TR>
   <TD NOWRAP><B>Jméno konference:</B></TD>
   <TD><INPUT TYPE="text" NAME="listname" SIZE=30 VALUE="[saved->listname]"></TD>
   <TD><img src="/icons/unknown.png" alt="jméno konference ; ne její adresu!"></TD>
 </TR>
 
 <TR>
   <TD NOWRAP><B>Vlastník:</B></TD>
   <TD><I>[user->email]</I></TD>
   <TD><img src="/icons/unknown.png" alt="Jste vlastníkem konference"></TD>
 </TR>

 <TR>
   <TD valign=top NOWRAP><B>Typ konference :</B></TD>
   <TD>
     <MENU>
  [FOREACH template IN list_list_tpl]
     <INPUT TYPE="radio" NAME="template" Value="[template->NAME]"
     [IF template->selected]
       CHECKED
     [ENDIF]
     > [template->NAME]<BR>
     <BLOCKQUOTE>
     [PARSE template->comment]
     </BLOCKQUOTE>
     <BR>
  [END]
     </MENU>
    </TD>
    <TD valign=top><img src="/icons/unknown.png" alt="Typ konference je pøednastavený profil. Parametry se budou moci mìnit, a¾ se konference vytvoøí"></TD>
 </TR>
 <TR>
   <TD NOWRAP><B>Pøedmìt:</B></TD>
   <TD><INPUT TYPE="text" NAME="subject" SIZE=60 VALUE="[saved->subject]"></TD>
   <TD><img src="/icons/unknown.png" alt="Téma konference"></TD>
 </TR>
 <TR>
   <TD NOWRAP><B>Témata:</B></TD>
   <TD><SELECT NAME="topics">
	<OPTION VALUE="">--Vyberte témata--
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
   <TD valign=top><img src="/icons/unknown.png" alt="Klasifikace konference v adresáøi"></TD>
 </TR>

 <TR>
   <TD valign=top NOWRAP><B>Popis:</B></TD>
   <TD><TEXTAREA COLS=60 ROWS=10 NAME="info">[saved->info]</TEXTAREA></TD>
   <TD valign=top><img src="/icons/unknown.png" alt="Nìkolik øádkù popisujících konferenci"></TD>
 </TR>

 <TR>
   <TD COLSPAN=2 ALIGN="center">
    <TABLE>
     <TR>
      <TD BGCOLOR="[light_color]">
<INPUT TYPE="submit" NAME="action_create_list" VALUE="Odeslat po¾adavek na vytvoøení">
      </TD>
     </TR></TABLE>
</TD></TR>
</TABLE>



</FORM>
