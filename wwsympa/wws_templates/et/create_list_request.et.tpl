<!-- RCS Identication ; $Revision$ ; $Date$ -->


<FORM ACTION="[path_cgi]" METHOD=POST>

<P>
<TABLE>
 <TR>
   <TD NOWRAP><B>Listi nimi:</B></TD>
   <TD><INPUT TYPE="text" NAME="listname" SIZE=30 VALUE="[saved->listname]"></TD>
   <TD><img src="[icons_url]/unknown.png" alt="listi nimi ; tähelepanu, see ei ole listi aadress !"></TD>
 </TR>
 
 <TR>
   <TD NOWRAP><B>Omanik:</B></TD>
   <TD><I>[user->email]</I></TD>
   <TD><img src="[icons_url]/unknown.png" alt="Teie olete listi omanik"></TD>
 </TR>

 <TR>
   <TD valign=top NOWRAP><B>Listi tüüp:</B></TD>
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
    <TD valign=top><img src="[icons_url]/unknown.png" alt="Listi tüüp on hulk valmis parameetreid listi seadetes. Kui list on valmis tehtud, saab neid kõiki parameetreid muuta"></TD>
 </TR>
 <TR>
   <TD NOWRAP><B>Teema:</B></TD>
   <TD><INPUT TYPE="text" NAME="subject" SIZE=60 VALUE="[saved->subject]"></TD>
   <TD><img src="[icons_url]/unknown.png" alt="Listi teema"></TD>
 </TR>
 <TR>
   <TD NOWRAP><B>Jaotused:</B></TD>
   <TD><SELECT NAME="topics">
	<OPTION VALUE="">--Vali jaotus--
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
	<OPTION VALUE="other">Muu
     </SELECT>
   </TD>
   <TD valign=top><img src="[icons_url]/unknown.png" alt="Listi asukoht jaotuses"></TD>
 </TR>

 <TR>
   <TD valign=top NOWRAP><B>Kirjeldus:</B></TD>
   <TD><TEXTAREA COLS=60 ROWS=10 NAME="info">[saved->info]</TEXTAREA></TD>
   <TD valign=top><img src="[icons_url]/unknown.png" alt="Lühike listi kirjeldus"></TD>
 </TR>

 <TR>
   <TD COLSPAN=2 ALIGN="center">
    <TABLE>
     <TR>
      <TD BGCOLOR="[light_color]">
<INPUT TYPE="submit" NAME="action_create_list" VALUE="Saada listisoov">
      </TD>
     </TR></TABLE>
</TD></TR>
</TABLE>



</FORM>




