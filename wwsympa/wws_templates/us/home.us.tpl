    <BR><P> 
<TABLE BORDER=0 BGCOLOR="--LIGHT_COLOR--"><TR><TD>
<P align=justify>
This server provides you access to your environment on mailing list server [conf->email]@[conf->host]. Starting from this URL, you can perform subscribtion options, unsubscribtion,
archives, list management and so on.
</P>
</TD></TR></TABLE>
<BR><BR>

<CENTER>
<TABLE BORDER=0>
 <TR>
  <TH BGCOLOR="--SELECTED_COLOR--">
   <FONT COLOR="--BG_COLOR--">Mailing lists</FONT>
  </TH>
 </TR>
 <TR>
  <TD>
   <TABLE BORDER=0 CELLPADDING=3><TR VALIGN="top">
    <TD WIDTH=33% NOWRAP>
     [FOREACH topic IN topics]
      [IF topic->id=topicsless]
       <A HREF="[path_cgi]/lists/[topic->id]"><B>Others</B></A><BR>
      [ELSE]
       <A HREF="[path_cgi]/lists/[topic->id]"><B>[topic->title]</B></A><BR>
      [ENDIF]

      [FOREACH subtopic IN topic->sub]
       <FONT SIZE="-1">
	&nbsp;&nbsp;<A HREF="[path_cgi]/lists/[topic->id]/[subtopic->NAME]">[subtopic->title]</A><BR>
       </FONT>
      [END]
      [IF topic->next]
	</TD><TD></TD><TD WIDTH=33% NOWRAP>
      [ENDIF]
     [END]
    </TD>	
   </TR>
   <TR>
<TD>
<TABLE CELLPADDING="2" CELLSPACING="2" WIDTH="100%" BORDER="0">
  <TR ALIGN=center BGCOLOR="--DARK_COLOR--">
  <TD>
  <TABLE WIDTH="100%" BORDER="0" CELLSPACING="0" CELLPADDING="2">
     <TR> 
      <TD NOWRAP BGCOLOR="--LIGHT_COLOR--" ALIGN="center"> 
      <A HREF="[path_cgi]/lists" >
     <FONT SIZE=-1><B>view all lists</B></FONT></A>
     </TD>
    </TR>
  </TABLE>
  </TD>
  </TR>
</TABLE>
</TD>
<TD width=100%></TD>
<TD NOWRAP>
        <FORM ACTION="[path_cgi]" METHOD=POST> 
         <INPUT SIZE=25 NAME=filter VALUE=[filter]>
         <INPUT TYPE="hidden" NAME="action" VALUE="search_list">
         <INPUT TYPE="submit" NAME="action_search_list" VALUE="Search lists">
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
   <TR><TD BGCOLOR="--DARK_COLOR--">
          <TABLE BORDER="0" WIDTH="100%"  VALIGN="top"> 
              <TR><TD BGCOLOR="--BG_COLOR--">
[PARSE '--ETCBINDIR--/wws_templates/loginbanner.us.tpl']
</TD></TR></TABLE>
</TD></TR></TABLE>

[ENDIF]
<BR><BR>
