<!-- RCS Identication ; $Revision$ ; $Date$ -->


<FORM ACTION="[path_cgi]" METHOD=POST>

<P>
<TABLE>
 <TR>
   <TD NOWRAP><B>Lijst naam:</B></TD>
   <TD><INPUT TYPE="text" NAME="listname" SIZE=30 VALUE="[saved->listname]"></TD>
   <TD><img src="[icons_url]/unknown.png" alt="de naam van de lijst; voorzichtig, niet het adres! !"></TD>
 </TR>
 
 <TR>
   <TD NOWRAP><B>Eigenaar:</B></TD>
   <TD><I>[user->email]</I></TD>
   <TD><img src="[icons_url]/unknown.png" alt="U bent de eigenaar van deze lijst"></TD>
 </TR>

 <TR>
   <TD valign=top NOWRAP><B>Lijst type :</B></TD>
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
    <TD valign=top><img src="[icons_url]/unknown.png" alt="Het lijsttype is een set van configuratie-items. Deze configuratie-items kunt u later weer wijzigen nadat u de lijst heeft gemaakt"></TD>
 </TR>
 <TR>
   <TD NOWRAP><B>Onderwerp:</B></TD>
   <TD><INPUT TYPE="text" NAME="subject" SIZE=60 VALUE="[saved->subject]"></TD>
   <TD><img src="[icons_url]/unknown.png" alt="Het onderwerp van de lijst"></TD>
 </TR>
 <TR>
   <TD NOWRAP><B>Onderwerpen:</B></TD>
   <TD><SELECT NAME="topics">
	<OPTION VALUE="">--Kies een onderwerp--
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
	<OPTION VALUE="other">Overig
     </SELECT>
   </TD>
   <TD valign=top><img src="[icons_url]/unknown.png" alt="Lijst klassificatie in de inhoudsopgave"></TD>
 </TR>

 <TR>
   <TD valign=top NOWRAP><B>Omschrijving:</B></TD>
   <TD><TEXTAREA COLS=60 ROWS=10 NAME="info">[saved->info]</TEXTAREA></TD>
   <TD valign=top><img src="[icons_url]/unknown.png" alt="Een paar regels die de lijst beschrijven"></TD>
 </TR>

 <TR>
   <TD COLSPAN=2 ALIGN="center">
    <TABLE>
     <TR>
      <TD BGCOLOR="[light_color]">
<INPUT TYPE="submit" NAME="action_create_list" VALUE="Verstuur uw lijst aanmaak aanvraag">
      </TD>
     </TR></TABLE>
</TD></TR>
</TABLE>



</FORM>




