<!-- RCS Identication ; $Revision$ ; $Date$ -->

[IF action=search_list]
  [occurrence] egyezést találtam<BR><BR>
[ELSIF action=search_user]
  <B>[email]</B> a következõ listák tagja
[ENDIF]

<TABLE BORDER="0" WIDTH="100%">
   [FOREACH l IN which]
     <TR>
     [IF l->admin]
       <TD BGCOLOR="[dark_color]">
          <TABLE BORDER="0" WIDTH="100%" CELLSPACING="0" CELLPADDING="1">
           <TR><TD BGCOLOR="[light_color]" ALIGN="center" VALIGN="top">
             <FONT COLOR="[selected_color]" SIZE="-1">
              <A HREF="[base_url][path_cgi]/admin/[l->NAME]" ><b>admin</b></A>
         </FONT>
       </TD>
     </TR>
 </TABLE>
</TD>
     [ELSE]
       <TD>&nbsp;</TD>
     [ENDIF] 
     <TD WIDTH="100%" ROWSPAN="2">
     <A HREF="[path_cgi]/info/[l->NAME]" ><B>[l->NAME]@[l->host]</B></A>
     <BR>
     [l->subject]
     </TD></TR>
     <TR><TD>&nbsp;</TD></TR>
   [END]
</TABLE>
