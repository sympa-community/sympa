<!-- RCS Identication ; $Revision$ ; $Date$ -->


<FORM ACTION="[path_cgi]" METHOD=POST>

<P>
<TABLE>
 <TR>
   <TD NOWRAP><B>Lista neve:</B></TD>
   <TD><INPUT TYPE="text" NAME="listname" SIZE=30 VALUE="[saved->listname]"></TD>
   <TD><img src="/icons/unknown.gif" alt="A lista neve; nem a címe!"></TD>
 </TR>
 
 <TR>
   <TD NOWRAP><B>Tulajdonos:</B></TD>
   <TD><I>[user->email]</I></TD>
   <TD><img src="/icons/unknown.gif" alt="A lista kiemelt gazdája leszel!"></TD>
 </TR>

 <TR>
   <TD valign=top NOWRAP><B>A lista típusa:</B></TD>
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
    <TD valign=top><img src="/icons/unknown.gif" alt="A lista típusát annak beállítása adja meg. A beállításokat a lista létrehozása után lehet elvégezni."></TD>
 </TR>
 <TR>
   <TD NOWRAP><B>Tárgy:</B></TD>
   <TD><INPUT TYPE="text" NAME="subject" SIZE=60 VALUE="[saved->subject]"></TD>
   <TD><img src="/icons/unknown.gif" alt="Amirõl a lista szól"></TD>
 </TR>
 <TR>
   <TD NOWRAP><B>Témakörök:</B></TD>
   <TD><SELECT NAME="topics">
	<OPTION VALUE="">--Válassz egyet--
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
   <TD valign=top><img src="/icons/unknown.gif" alt="A lista besorolása"></TD>
 </TR>

 <TR>
   <TD valign=top NOWRAP><B>Leírás:</B></TD>
   <TD><TEXTAREA COLS=60 ROWS=10 NAME="info">[saved->info]</TEXTAREA></TD>
   <TD valign=top><img src="/icons/unknown.gif" alt="A listáról pár szó"></TD>
 </TR>

 <TR>
   <TD COLSPAN=2 ALIGN="center">
    <TABLE>
     <TR>
      <TD BGCOLOR="[light_color]">
<INPUT TYPE="submit" NAME="action_create_list" VALUE="Kérelem elküldése">
      </TD>
     </TR></TABLE>
</TD></TR>
</TABLE>



</FORM>




