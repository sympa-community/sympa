<!-- RCS Identication ; $Revision$ ; $Date$ -->
[IF action=search_list] 
[occurrence] potrivire gasita<BR>
<BR>
[ELSIF action=search_user]
 <B>[email]</B> este inscris la urmatoarele liste 
[ENDIF] 
<TABLE BORDER="0" WIDTH="100%">
   [FOREACH l IN which]
     <TR>
      [IF l->admin]
       <TD>
       [PARSE '/home/sympa/bin/etc/wws_templates/button_header.tpl']
       <TD BGCOLOR="[light_color]" ALIGN="center" VALIGN="top">
             <FONT COLOR="[selected_color]" SIZE="-1">
              <A HREF="[path_cgi]/admin/[l->NAME]" ><b>admin</b></A>
         </FONT>
       </TD>
     [PARSE '/home/sympa/bin/etc/wws_templates/button_footer.tpl']

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

<BR>
[IF action=which] 
[IF ! which]
 &nbsp;&nbsp;<FONT COLOR="[dark_color]">Nu exista 
inscrieri cu adresa<B> [user->email]</B>!</FONT> <BR>
[ENDIF]

[IF unique <> 1]
<TABLE>
&nbsp;&nbsp;<FONT COLOR="[dark_color]">See your subscriptions with the following email addresses</FONT><BR>
<BR><BR>

 <TR> 
    <FORM METHOD=POST ACTION="[path_cgi]">
     
[FOREACH email IN alt_emails]
   <INPUT NAME="email"  TYPE=hidden VALUE="[email->NAME]">
   &nbsp;&nbsp;<A HREF="[path_cgi]/change_identity/[email->NAME]/which">[email->NAME]</A> 
    <BR>
    [END]  
    </FORM>
  </TR>
</TABLE>

<BR> 

<TABLE>
<TR>
&nbsp;&nbsp;<FONT COLOR="[dark_color]">Unifica abonarile tale cu adresa de mail <B>[user->email]</B></FONT><BR> 
&nbsp;&nbsp;<FONT COLOR="[dark_color]">Adica utilizarea unei adrese email unice in Sympa pentru abonari si optiuni</FONT>

<TR>
<TD>
    <FORM ACTION="[path_cgi]" METHOD=POST>
  
&nbsp;&nbsp;
        <INPUT TYPE="submit" NAME="action_unify_email" VALUE="Validare">
      </FORM>
</TD>
</TR>
<BR>

</TABLE>
[ENDIF]
[ENDIF]
