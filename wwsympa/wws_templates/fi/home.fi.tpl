<!-- RCS Identication ; $Revision$ ; $Date$ -->

    <BR><P> 
<TABLE BORDER=0 BGCOLOR="[light_color]"><TR><TD>
<P align=justify>
Tämä palvelin tarjoaa pääsyn postituslistaympäristöön [conf->email]@[conf->host]. 
Tässä osoitteessa voit muuttaa tilaus asetuksia, poistaa tilauksen, selata arkistoja,
hallita listoja yms.
</P>
</TD></TR></TABLE>
<BR><BR>

<CENTER>
<TABLE BORDER=0>
 <TR>
  <TH BGCOLOR="[selected_color]">
   <FONT COLOR="[bg_color]">Postituslistat</FONT>
  </TH>
 </TR>
 <TR>
  <TD>
   <TABLE BORDER=0 CELLPADDING=3><TR VALIGN="top">
    <TD WIDTH=33% NOWRAP>
     [FOREACH topic IN topics]
      o
      [IF topic->id=topicsless]
       <A HREF="[path_cgi]/lists/[topic->id]"><B>Muut</B></A><BR>
      [ELSE]
       <A HREF="[path_cgi]/lists/[topic->id]"><B>[topic->title]</B></A><BR>
      [ENDIF]

      [IF topic->sub]
      [FOREACH subtopic IN topic->sub]
       <FONT SIZE="-1">
	&nbsp;&nbsp;<A HREF="[path_cgi]/lists/[topic->id]/[subtopic->NAME]">[subtopic->title]</A><BR>
       </FONT>
      [END]
      [ENDIF]
      [IF topic->next]
	</TD><TD></TD><TD WIDTH=33% NOWRAP>
      [ENDIF]
     [END]
    </TD>	
   </TR>
   <TR>
<TD>
     [PARSE '--ETCBINDIR--/wws_templates/button_header.tpl']
      <TD NOWRAP BGCOLOR="[light_color]" ALIGN="center"> 
      <A HREF="[path_cgi]/lists" >
     <FONT SIZE=-1><B>katso kaikkia listoja</B></FONT></A>
     </TD>
     [PARSE '--ETCBINDIR--/wws_templates/button_footer.tpl']
</TD>
<TD width=100%></TD>
<TD NOWRAP>
        <FORM ACTION="[path_cgi]" METHOD=POST> 
         <INPUT SIZE=25 NAME=filter VALUE=[filter]>
         <INPUT TYPE="hidden" NAME="action" VALUE="search_list">
         <INPUT TYPE="submit" NAME="action_search_list" VALUE="Hae listoista">
	  <BR>
	 <INPUT TYPE="radio" NAME="extended" VALUE="0" checked>Paikallinen
         <INPUT TYPE="radio" NAME="extended" VALUE="1">Erikois haku
	 
        </FORM>
   </TD>
        
   </TD></TR>
  </TABLE>
 </TD>
</TR>
</TABLE>
</CENTER>

[IF ! user->email]
<TABLE BORDER="0" WIDTH="100%"  CELLPADDING="1" CELLSPACING="0" VALIGN="top">
   <TR><TD BGCOLOR="[dark_color]">
          <TABLE BORDER="0" WIDTH="100%"  VALIGN="top"> 
              <TR><TD BGCOLOR="[bg_color]">
[PARSE '--ETCBINDIR--/wws_templates/loginbanner.us.tpl']
</TD></TR></TABLE>
</TD></TR></TABLE>

[ENDIF]
<BR><BR>
