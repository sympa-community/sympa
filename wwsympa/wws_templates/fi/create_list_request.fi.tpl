<!-- RCS Identication ; $Revision$ ; $Date$ -->


<FORM ACTION="[path_cgi]" METHOD=POST>

<P>
<TABLE>
 <TR>
   <TD NOWRAP><B>Listan nimi:</B></TD>
   <TD><INPUT TYPE="text" NAME="listname" SIZE=30 VALUE="[saved->listname]"></TD>
   <TD><img src="[icons_url]/unknown.png" alt="listan nimi; ole tarkkana, ei osoite !"></TD>
 </TR>
 
 <TR>
   <TD NOWRAP><B>Omistajan email:</B></TD>
   <TD><I>[user->email]</I></TD>
   <TD><img src="[icons_url]/unknown.png" alt="Listan ylläpitäjä"></TD>
 </TR>

 <TR>
   <TD valign=top NOWRAP><B>Listan tyyppi :</B></TD>
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
    <TD valign=top><img src="[icons_url]/unknown.png" alt="Listan tyyppi on joukko parametrejä, joita voi muuttaa kun lista on luotu"></TD>
 </TR>
 <TR>
   <TD NOWRAP><B>Otsikko:</B></TD>
   <TD><INPUT TYPE="text" NAME="subject" SIZE=60 VALUE="[saved->subject]"></TD>
   <TD><img src="[icons_url]/unknown.png" alt="Listan otsikko"></TD>
 </TR>
 <TR>
   <TD NOWRAP><B>Aiheet:</B></TD>
   <TD><SELECT NAME="topics">
	<OPTION VALUE="">--Valitse aihe--
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
   <TD valign=top><img src="[icons_url]/unknown.png" alt="Listan määrittely hakemistossa"></TD>
 </TR>

 <TR>
   <TD valign=top NOWRAP><B>Kuvaus:</B></TD>
   <TD><TEXTAREA COLS=60 ROWS=10 NAME="info">[saved->info]</TEXTAREA></TD>
   <TD valign=top><img src="[icons_url]/unknown.png" alt="Listan kuvaus muutamalla rivillä"></TD>
 </TR>

 <TR>
   <TD COLSPAN=2 ALIGN="center">
    <TABLE>
     <TR>
      <TD BGCOLOR="[light_color]">
<INPUT TYPE="submit" NAME="action_create_list" VALUE="Lähetä luontipyyntö">
      </TD>
     </TR></TABLE>
</TD></TR>
</TABLE>



</FORM>




