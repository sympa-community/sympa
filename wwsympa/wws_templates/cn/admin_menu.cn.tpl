<!-- begin admin_menu.us.tpl -->
    <TD BGCOLOR="#3366cc" ALIGN="CENTER" COLSPAN="7">
	<FONT COLOR="#ffffff"><b>邮递表管理面板</b></font>
    </TD>
    </TR>
    <TR>
    <TD BGCOLOR="#ccccff" ALIGN="CENTER">
       [IF list_conf->status=closed]
	[IF is_listmaster]
        <A HREF="[base_url][path_cgi]/restore_list/[list]" >
          <FONT size="-1"><b>恢复邮递表</b></font></A>
        [ELSE]
          <FONT size="-1" COLOR="#ffffff"><b>恢复邮递表</b></font>
        [ENDIF]
       [ELSE]
        <A HREF="[base_url][path_cgi]/close_list_request/[list]" ><FONT size=-1><b>Remove list</b></font></A>
       [ENDIF]
    </TD>
    <TD BGCOLOR="#ccccff" ALIGN="CENTER">
	[IF shared=none]
          <A HREF="[base_url][path_cgi]/d_admin/[list]/create" >
             <FONT size=-1><b>建立共享</b></font></A>
	[ELSIF shared=deleted]
          <A HREF="[base_url][path_cgi]/d_admin/[list]/restore" >
             <FONT size=-1><b>恢复共享</b></font></A>
	[ELSIF shared=exist]
          <A HREF="[base_url][path_cgi]/d_admin/[list]/delete" >
             <FONT size=-1><b>删除共享</b></font></A>
        [ELSE]
          <FONT size=1 color=red>
          [shared]
	[ENDIF]        
    </TD>

    [IF action=edit_list_request]
    <TD BGCOLOR="#3366cc" ALIGN="CENTER">
      <FONT size="-1" COLOR="#ffffff"><b>编辑邮递表配置</b></FONT>
    </TD>
    [ELSE]
    <TD BGCOLOR="#ccccff" ALIGN="CENTER">
	<A HREF="[path_cgi]/edit_list_request/[list]" >
          <FONT size="-1"><b>编辑邮递表配置</b></FONT></A>
    </TD>
    [ENDIF]

    [IF action=review]
    <TD BGCOLOR="#3366cc" ALIGN="CENTER">
       <FONT size="-1" COLOR="#ffffff"><b>订阅者</b></FONT>
    </TD>
    [ELSE]
    <TD BGCOLOR=#ccccff ALIGN=CENTER>
       [IF is_owner]
       <A HREF="[base_url][path_cgi]/review/[list]" >
       <FONT size="-1"><b>订阅者</b></FONT></A>
       [ENDIF]
    </TD>
    [ENDIF]

    [IF action=reviewbouncing]
    <TD BGCOLOR="#3366cc" ALIGN="CENTER">
       <FONT size="-1" COLOR="#ffffff"><b>退信</b></FONT>
    </TD>
    [ELSE]
    <TD BGCOLOR="#ccccff" ALIGN="CENTER">
       [IF is_owner]
       <A HREF="[base_url][path_cgi]/reviewbouncing/[list]" >
       <FONT size="-1"><b>退信</b></FONT></A>
       [ENDIF]
    </TD>
    [ENDIF]

    [IF action=modindex]
    <TD BGCOLOR="#3366cc" ALIGN="CENTER">
       <FONT size="-1" COLOR="#ffffff"><b>调解</b></FONT>
    </TD>
    [ELSE]
       [IF is_editor]
       <TD BGCOLOR="#ccccff" ALIGN=CENTER>
         <A HREF="[base_url][path_cgi]/modindex/[list]" >
         <FONT size="-1"><b>调解</b></FONT></A>
       </TD>
       [ELSE]
         <TD BGCOLOR="#ccccff" ALIGN="CENTER">
	   <FONT size="-1" COLOR="#ffffff"><b>调解</b></FONT>
	 </TD>
       [ENDIF]
    [ENDIF]

    [IF action=editfile]
    <TD BGCOLOR="#3366cc" ALIGN="CENTER">
       <FONT size="-1" COLOR="#ffffff"><b>定制</b></FONT>
    </TD>
    [ELSE]
    <TD BGCOLOR="#ccccff" ALIGN="CENTER">
       [IF is_owner]
       <A HREF="[base_url][path_cgi]/editfile/[list]" >
       <FONT size="-1"><b>定制</b></FONT></A>
       [ENDIF]
    </TD>
    [ENDIF]
<!-- end menu_admin.tpl -->

