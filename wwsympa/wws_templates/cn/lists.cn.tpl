<!-- RCS Identication ; $Revision$ ; $Date$ -->

[IF action=search_list]
  找到 [occurrence] 个相关邮递表<BR><BR>
[ELSIF action=search_user]
  <B>[email]</B> 已订阅下列邮递表
[ENDIF]

<TABLE BORDER="0" WIDTH="100%">
   [FOREACH l IN which]
     <TR>
      [IF l->admin]
       <TD BGCOLOR="[dark_color]">
          <TABLE BORDER="0" WIDTH="100%" CELLSPACING="0" CELLPADDING="1">
           <TR><TD BGCOLOR="[light_color]" ALIGN="center" VALIGN="top">
             <FONT COLOR="[selected_color]" SIZE="-1">
              <A HREF="[base_url][path_cgi]/admin/[l->NAME]" ><b>管理</b></A>
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

<BR>

[IF action=which]
[IF ! which]
&nbsp;&nbsp;<FONT COLOR="[dark_color]">没有来自 <B>[user->email]</B> 的订阅!</FONT>
<BR>
[ENDIF]

[IF unique <> 1]
<TABLE>
&nbsp;&nbsp;<FONT COLOR="[dark_color]">以底下的电邮位址查看您的订阅状况</FONT><BR>
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
&nbsp;&nbsp;<FONT COLOR="[dark_color]">以电邮位址 <B>[user->email]</B> 统一订阅</FONT><BR> 
&nbsp;&nbsp;<FONT COLOR="[dark_color]">也就是说, 以单一的电邮位址统一管理您的 Sympa 订阅及设定</FONT>

<TR>
<TD>
    <FORM ACTION="[path_cgi]" METHOD=POST>
  
&nbsp;&nbsp;<INPUT TYPE="submit" NAME="action_unify_email" VALUE="确定"></FONT>
    </FORM>
</TD>
</TR>
<BR>

</TABLE>
[ENDIF]
[ENDIF]
