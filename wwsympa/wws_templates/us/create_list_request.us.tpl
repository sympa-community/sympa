<!-- RCS Identication ; $Revision$ ; $Date$ -->


<FORM ACTION="[path_cgi]" METHOD=POST>

<P>
<TABLE>
 <TR>
   <TD NOWRAP><B>List name:</B></TD>
   <TD><INPUT TYPE="text" NAME="listname" SIZE=30 VALUE="[saved->listname]"></TD>
   <TD><img src="/icons/unknown.gif" alt="the list name ; be carefull, not its address !"></TD>
 </TR>
 
 <TR>
   <TD NOWRAP><B>Owner:</B></TD>
   <TD><I>[user->email]</I></TD>
   <TD><img src="/icons/unknown.gif" alt="You are the privileged owner of this list"></TD>
 </TR>

 <TR>
   <TD valign=top NOWRAP><B>List type :</B></TD>
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
    <TD valign=top><img src="/icons/unknown.gif" alt="The list type is a set of parameters' profile. Parameters will be editable, once the list created"></TD>
 </TR>
 <TR>
   <TD NOWRAP><B>Subject:</B></TD>
   <TD><INPUT TYPE="text" NAME="subject" SIZE=60 VALUE="[saved->subject]"></TD>
   <TD><img src="/icons/unknown.gif" alt="The list's subject"></TD>
 </TR>
 <TR>
   <TD NOWRAP><B>Topics:</B></TD>
   <TD><SELECT NAME="topics">
	<OPTION VALUE="">--Sélect a topic--
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
   <TD valign=top><img src="/icons/unknown.gif" alt="List classification in the directory"></TD>
 </TR>

 <TR>
   <TD valign=top NOWRAP><B>Description:</B></TD>
   <TD><TEXTAREA COLS=60 ROWS=10 NAME="info">[saved->info]</TEXTAREA></TD>
   <TD valign=top><img src="/icons/unknown.gif" alt="A few lines describing the list"></TD>
 </TR>

 <TR>
   <TD COLSPAN=2 ALIGN="center">
    <TABLE>
     <TR>
      <TD BGCOLOR="--LIGHT_COLOR--">
<INPUT TYPE="submit" NAME="action_create_list" VALUE="Submit your creation request">
      </TD>
     </TR></TABLE>
</TD></TR>
</TABLE>



</FORM>




