<!-- RCS Identication ; $Revision$ ; $Date$ -->

    <BR><P> 
<TABLE BORDER=0 BGCOLOR="#ccccff"><TR><TD>
<P align=justify>

Tento server poskytuje pøístup k Va¹emu prostøedí na konferenèním serveru
[conf->email]@[conf->host]. Z tohoto místa mù¾ete pøovádìt zmìny v pøihlá¹ení a
odhlá¹ení, prohlí¾et archívy, správu konferenci atd.

</P>
</TD></TR></TABLE>
<BR><BR>

<CENTER>
<TABLE BORDER=0>
 <TR>
  <TH BGCOLOR="#3366cc">
   <FONT COLOR="#ffffff">Konference</FONT>
  </TH>
 </TR>
 <TR>
  <TD>
   <TABLE BORDER=0 CELLPADDING=3><TR VALIGN="top">
    <TD WIDTH=33% NOWRAP>
     [FOREACH topic IN topics]
      o
      [IF topic->id=topicsless]
       <A HREF="[path_cgi]/lists/[topic->id]"><B>Ostatní</B></A><BR>
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
<TABLE CELLPADDING="2" CELLSPACING="2" WIDTH="100%" BORDER="0">
  <TR ALIGN=center BGCOLOR="#330099">
  <TD>
  <TABLE WIDTH="100%" BORDER="0" CELLSPACING="0" CELLPADDING="2">
     <TR> 
      <TD NOWRAP BGCOLOR="#ccccff" ALIGN="center"> 
      <A HREF="[path_cgi]/lists" >
     <FONT SIZE=-1><B>zobrazit v¹echny konference</B></FONT></A>
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
         <INPUT TYPE="submit" NAME="action_search_list" VALUE="Hledat konference">
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
   <TR><TD BGCOLOR="#330099">
          <TABLE BORDER="0" WIDTH="100%"  VALIGN="top"> 
              <TR><TD BGCOLOR="#ffffff">
[PARSE '/home/sympa/bin/etc/wws_templates/loginbanner.cz.tpl']
</TD></TR></TABLE>
</TD></TR></TABLE>

[ENDIF]
<BR><BR>
