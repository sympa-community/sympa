<!-- RCS Identication ; $Revision$ ; $Date$ -->

[IF file]
  [INCLUDE file]
[ELSE]

  [IF path]  
    <h2><B><IMG SRC="/icons/folder.open.png"> [path] </B> </h2> 
    <A HREF="[path_cgi]/d_editfile/[list]/[escaped_path]">修改</A> | 
    <A HREF="[path_cgi]/d_delete/[list]/[escaped_path]" onClick="request_confirm_link('[path_cgi]/d_delete/[list]/[escaped_path]', '确定要删除 [path] ?'); return false;">删除</A> |
    <A HREF="[path_cgi]/d_control/[list]/[escaped_path]">存取</A><BR>

    所有者: [doc_owner] <BR>
    最后更新: [doc_date] <BR>
    [IF doc_title]
    描述: [doc_title] <BR><BR>
    [ENDIF]
    <font size=+1> <A HREF="[path_cgi]/d_read/[list]/[father]"> <IMG ALIGN="bottom"  src="[father_icon]"> 转到上一级目录</A></font>
    <BR>  
  [ELSE]
    <h2> <B> 文件夹 SHARED 的内容 </B> </h2> 
  [ENDIF]
   
  <TABLE width=100%>
  <TR BGCOLOR="[dark_color]">
   
  <th><TABLE width=100%><TR><TD ALIGN="left"><font color="[bg_color]">文档</font></TD>
  [IF  order_by<>order_by_doc]  
    <TD ALIGN="right">
    <form method="post" ACTION="[path_cgi]">  
    <INPUT ALIGN="top"  type="image" src="[sort_icon]" WIDTH=15 HEIGHT=15 name="按名字排序">
    <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
    <INPUT TYPE="hidden" NAME="path" VALUE="[path]">
    <INPUT TYPE="hidden" NAME="action" VALUE="d_read">
    <INPUT TYPE="hidden" NAME="order" VALUE="order_by_doc">
    </form>
    </TD>
  [ENDIF]	
  </TR></TABLE>
  </th>
  
  <th><TABLE width=100%><TR><TD ALIGN="left"><font color="[bg_color]">作者</font></TD>
  [IF  order_by<>order_by_author]  
    <TD ALIGN="right">
    <form method="post" ACTION="[path_cgi]">  
    <INPUT ALIGN="top"  type="image" src="[sort_icon]" WIDTH=15 HEIGHT=15 name="按作者排序">
    <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
    <INPUT TYPE="hidden" NAME="path" VALUE="[path]">
    <INPUT TYPE="hidden" NAME="action" VALUE="d_read">
    <INPUT TYPE="hidden" NAME="order" VALUE="order_by_author">
    </form>	
    </TD>
  [ENDIF]
  </TR></TABLE>
  </th> 

  <th><TABLE width=100%><TR><TD ALIGN="left"><font color="[bg_color]">大小(KB)</font></TD>
  [IF order_by<>order_by_size] 
    <TD ALIGN="right">
    <form method="post" ACTION="[path_cgi]">
    <INPUT ALIGN="top"  type="image" src="[sort_icon]" WIDTH=15 HEIGHT=15 name="按大小排序">
    <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
    <INPUT TYPE="hidden" NAME="path" VALUE="[path]">
    <INPUT TYPE="hidden" NAME="action" VALUE="d_read">
    <INPUT TYPE="hidden" NAME="order" VALUE="order_by_size">
    </form>
    </TD>
  [ENDIF]
  </TR></TABLE>   
  </th> 

  <th><TABLE width=100%><TR><TD ALIGN="left"><font color="[bg_color]">最后更新</font></TD>
  [IF order_by<>order_by_date]
    <TD ALIGN="right">
    <form method="post" ACTION="[path_cgi]">
    <INPUT ALIGN="top"  type="image" src="[sort_icon]" WIDTH=15 HEIGHT=15 name="按日期排序">
    <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
    <INPUT TYPE="hidden" NAME="path" VALUE="[path]">
    <INPUT TYPE="hidden" NAME="action" VALUE="d_read">
    <INPUT TYPE="hidden" NAME="order" VALUE="order_by_date">
    </form>
    </TD>
  [ENDIF]
  </TR></TABLE>  
  </th> 

  <th ALIGN="left"><font color="[bg_color]">描述</font></th> 
  <th ALIGN="center"><font color="[bg_color]">编辑</font></th> 
  <th ALIGN="center"><font color="[bg_color]">删除</font></th>
  <th ALIGN="center"><font color="[bg_color]">存取</font></th></TR>
      
  [IF empty]
    <TR BGCOLOR="[light_color]" VALIGN="top">
    <TD COLSPAN=8 ALIGN="center"> 空文件夹 </TD>
    </TR>
  [ELSE]   
    [IF sort_subdirs]
      [FOREACH s IN sort_subdirs] 
        <TR BGCOLOR="[light_color]">        
	<TD NOWRAP> <A HREF="[path_cgi]/d_read/[list]/[escaped_path][s->escaped_doc]/"> 
	<IMG ALIGN=bottom BORDER=0 SRC="[s->icon]" ALT="[s->title]"> [s->doc]</A></TD>
	<TD>
	[IF s->author_known] 
	  <A HREF="mailto:[s->author]">[s->author]</A>  
        [ELSE]
	   未知
	[ENDIF]
	</TD>	    
	<TD>&nbsp;</TD>
	<TD NOWRAP> [s->date] </TD>
		
	[IF s->edit]

	<TD><center>
	<font size=-1>
	<A HREF="[path_cgi]/d_editfile/[list]/[escaped_path][s->escaped_doc]">修改</A>
	</font>
	</center></TD>

	  <TD><center>
          <FONT size=-1>
          <A HREF="[path_cgi]/d_delete/[list]/[escaped_path][s->escaped_doc]" onClick="request_confirm_link('[path_cgi]/d_delete/[list]/[escaped_path][s->escaped_doc]', '您确定要删除 [path][s->doc] 吗 ?'); return false;">删除</A>
	  </FONT>
	  </center></TD>
	[ELSE]
	  <TD>&nbsp; </TD>
	  <TD>&nbsp; </TD>
	[ENDIF]
	
	[IF s->control]
	  <TD>
	  <center>
	  <FONT size=-1>
	  <A HREF="[path_cgi]/d_control/[list]/[escaped_path][s->escaped_doc]">存取</A>
	  </font>
	  </center>
	  </TD>	 
	[ELSE]
	  <TD>&nbsp; </TD>
	[ENDIF]
      </TR>
      [END] 
    [ENDIF]

    [IF sort_files]
      [FOREACH f IN sort_files]
        <TR BGCOLOR="[light_color]"> 
        <TD>&nbsp;
        [IF f->html]
	  <A HREF="[path_cgi]/d_read/[list]/[escaped_path][f->escaped_doc]" TARGET="html_window">
	  <IMG ALIGN=bottom BORDER=0 SRC="[f->icon]" ALT="[f->title]"> [f->doc] </A>
	[ELSIF f->url]
	  <A HREF="[f->url]" TARGET="html_window">
	  <IMG ALIGN=bottom BORDER=0 SRC="[f->icon]" ALT="[f->title]"> [f->anchor] </A>
	[ELSE]
	  <A HREF="[path_cgi]/d_read/[list]/[escaped_path][f->escaped_doc]">
	  <IMG ALIGN=bottom BORDER=0 SRC="[f->icon]" ALT="[f->title]"> [f->doc] </A>
        [ENDIF] 
	</TD>  
	 
	<TD> 
	[IF f->author_known]
	  <A HREF="mailto:[f->author]">[f->author]</A>  
	[ELSE]
          未知 
        [ENDIF]
	</TD>
	 
	<TD NOWRAP>&nbsp;
	[IF !f->url]
	[f->size] 
	[ENDIF]
	</TD>
	<TD NOWRAP> [f->date] </TD>
	 
	[IF f->edit]
	<TD>
	<center>
	<font size=-1>
	<A HREF="[path_cgi]/d_editfile/[list]/[escaped_path][f->escaped_doc]">edit</A>
	</font>
	</center>

	</TD>
	<TD>
	<center>
	<FONT size=-1>
	<A HREF="[path_cgi]/d_delete/[list]/[escaped_path][f->escaped_doc]" onClick="request_confirm_link('[path_cgi]/d_delete/[list]/[escaped_path][f->escaped_doc]', '您确定要删除 [path][s->doc] ([f->size] Kb) 吗?'); return false;">删除</A>
	</FONT>
	</center>
	</TD>
	[ELSE]
	  <TD>&nbsp; </TD> <TD>&nbsp; </TD>
	[ENDIF]
		 
	[IF f->control]
	  <TD> <center>
	  <form method="post" ACTION="[path_cgi]">
	  <font size=-1>
	  <A HREF="[path_cgi]/d_control/[list]/[escaped_path][f->escaped_doc]">存取</A>
	  </font>
	  </center></TD>
	[ELSE]
	<TD>&nbsp; </TD>
	[ENDIF]
	</TR>
      [END] 
    [ENDIF]
  [ENDIF]
  </TABLE>	        
 
  <HR> 
<TABLE CELLSPACING=20>
   
  [IF may_edit]
    <TR>
    <form method="post" ACTION="[path_cgi]">
    <TD ALIGN="right" VALIGN="bottom">
    [IF path]
      <B> 在文件夹 [path] 里建立新文件夹</B> <BR>
    [ELSE]
      <B> 在文件夹 SHARED 里建立新文件夹</B> <BR>
    [ENDIF]
    <input MAXLENGTH=30 type="text" name="name_doc">
    </TD>

    <TD ALIGN="left" VALIGN="bottom">
    <input type="submit" value="建立新的子目录" name="action_d_create_dir">
    <INPUT TYPE="hidden" NAME="previous_action" VALUE="d_read">
    <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
    <INPUT TYPE="hidden" NAME="path" VALUE="[path]">
    <INPUT TYPE="hidden" NAME="type" VALUE="directory">
    <INPUT TYPE="hidden" NAME="action" VALUE="d_create_dir">
    </TD>
    </form>
    </TR>

    <TR>
    <form method="post" ACTION="[path_cgi]">
    <TD ALIGN="right" VALIGN="bottom">
      <B> 建立新的文件</B> <BR>
    <input MAXLENGTH=30 type="text" name="name_doc">
    </TD>

    <TD ALIGN="left" VALIGN="bottom">
    <input type="submit" value="建立新的文件" name="action_d_create_dir">
    <INPUT TYPE="hidden" NAME="previous_action" VALUE="d_read">
    <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
    <INPUT TYPE="hidden" NAME="path" VALUE="[path]">
    <INPUT TYPE="hidden" NAME="type" VALUE="file">
    <INPUT TYPE="hidden" NAME="action" VALUE="d_create_dir">
    </TD>
    </form>
    </TR>

    <TR>
    <FORM METHOD="POST" ACTION="[path_cgi]">
    <TD ALIGN="right" VALIGN="center">
    <B>建立新的书签</B><BR>
    URL <input MAXLENGTH=100 SIZE="25" type="text" name="url"><BR>
    title <input MAXLENGTH=100 SIZE="20" type="text" name="name_doc">
    </TD>

    <TD ALIGN="left" VALIGN="bottom">
    <input type="submit" value="新增" name="action_d_savefile">
    <INPUT TYPE="hidden" NAME="previous_action" VALUE="d_read">
    <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
    <INPUT TYPE="hidden" NAME="path" VALUE="[path]">
    <INPUT TYPE="hidden" NAME="action" VALUE="d_savefile">
    </TD>
    </FORM>
    </TR>


   <TR>
   <form method="post" ACTION="[path_cgi]" ENCTYPE="multipart/form-data">
   <TD ALIGN="right" VALIGN="bottom">
   [IF path]
     <B> 上传一个文件到文件夹 [path] 中 </B><BR>
   [ELSE]
     <B> 上传一个文件到文件夹 SHARED 中 </B><BR>
   [ENDIF]
   <input type="file" name="uploaded_file">
   </TD>

   <TD ALIGN="left" VALIGN="bottom">
   <input type="submit" value="发布" name="action_d_upload">
   <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
   <INPUT TYPE="hidden" NAME="path" VALUE="[path]">
   <TD>
   </form> 
   </TR>
   [ENDIF]
</TABLE>
[ENDIF]
   




