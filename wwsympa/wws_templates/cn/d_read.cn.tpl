<!-- RCS Identication ; $Revision$ ; $Date$ -->
[IF file]
  [INCLUDE file]
[ELSE]

  [IF path]  
    <h2> <B> 文件夹 [path] 内容 </B> </h2> 
    所有者: [doc_owner] <BR>
    最后更新: [doc_date] <BR>
    描述: [doc_title] <BR><BR>
    <font size=+1> <A HREF="[path_cgi]/d_read/[list]/[father]"> <IMG ALIGN="bottom"  src="[father_icon]"> 转到上一级目录</A></font>
    <BR>  
  [ELSE]
    <h2> <B> 文件夹 SHARED 的内容 </B> </h2> 
  [ENDIF]
   
  <TABLE width=100%>
  <TR BGCOLOR="#330099">
   
  <th><TABLE width=100%><TR><TD ALIGN="left"><font color="#ffffff">文档</font></TD>
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
  
  <th><TABLE width=100%><TR><TD ALIGN="left"><font color="#ffffff">作者</font></TD>
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

  <th><TABLE width=100%><TR><TD ALIGN="left"><font color="#ffffff">大小(KB)</font></TD>
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

  <th><TABLE width=100%><TR><TD ALIGN="left"><font color="#ffffff">最后更新</font></TD>
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

  <th ALIGN="left"><font color="#ffffff">描述</font></th> 
  <th ALIGN="center"><font color="#ffffff">编辑</font></th> 
  <th ALIGN="center"><font color="#ffffff">删除</font></th>
  <th ALIGN="center"><font color="#ffffff">存取</font></th></TR>
      
  [IF empty]
    <TR BGCOLOR="#ccccff" VALIGN="top">
    <TD COLSPAN=8 ALIGN="center"> 空文件夹 </TD>
    </TR>
  [ELSE]   
    [IF sort_subdirs]
      [FOREACH s IN sort_subdirs] 
        <TR BGCOLOR="#ccccff">        
	<TD NOWRAP> <A HREF="[path_cgi]/d_read/[list]/[path][s->doc]/"> 
	<IMG ALIGN=bottom BORDER=0 SRC="[s->icon]"> [s->doc]</A></TD>
	<TD>
	[IF s->author_known] 
	  <A HREF="mailto:[s->author]">[s->author]</A>  
        [ELSE]
	   未知
	[ENDIF]
	</TD>	    
	<TD>&nbsp;</TD>
	<TD NOWRAP> [s->date] </TD>
	<TD NOWRAP>&nbsp; [s->title]</TD>
		
	<TD>&nbsp; </TD>
	
	[IF s->edit]
	  <TD><center>
	  <form method="post" ACTION="[path_cgi]">
	  <FONT size=-2>
	  <input type="button" value="    " name="action_d_delete" onClick="request_confirm(this.form,
'您确定要删除 [path][s->doc] 吗 ?')">
	  </FONT>
	  <INPUT TYPE="hidden" NAME="action" VALUE="d_delete">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="path" VALUE="[path][s->doc]">
	  </form>	 
	  </center></TD>
	[ELSE]
	  <TD>&nbsp; </TD>
	[ENDIF]
	
	[IF s->control]
	  <TD>
	  <center>
	  <form method="post" ACTION="[path_cgi]">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="path" VALUE="[path][s->doc]">
	  <FONT size=-2>     
	  <input type="submit" value="    " name="action_d_control">
	  </font>
	  </form>
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
        <TR BGCOLOR="#ccccff"> 
        <TD>&nbsp;
        [IF f->html]
	  <A HREF="[path_cgi]/d_read/[list]/[path][f->doc]" TARGET="html_window">
	  <IMG ALIGN=bottom BORDER=0 SRC="[f->icon]"> [f->doc] </A>
	[ELSE]
	  <A HREF="[path_cgi]/d_read/[list]/[path][f->doc]">
	  <IMG ALIGN=bottom BORDER=0 SRC="[f->icon]"> [f->doc] </A>
        [ENDIF] 
	</TD>  
	 
	<TD> 
	[IF f->author_known]
	  <A HREF="mailto:[f->author]">[f->author]</A>  
	[ELSE]
          未知 
        [ENDIF]
	</TD>
	 
	<TD NOWRAP> [f->size] </TD>
	<TD NOWRAP> [f->date] </TD>
	<TD NOWRAP>&nbsp; [f->title]</TD>
	 
	[IF f->edit]
	<TD>
	<center>
	<form method="post" ACTION="[path_cgi]">
	<font size=-2>
        <input type="submit" value="    " name="action_d_editfile">
	</font>
	<INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	<INPUT TYPE="hidden" NAME="path" VALUE="[path][f->doc]">
	</form>
	</center>

	</TD>
	<TD>
	<center>
	<form method="post" ACTION="[path_cgi]">
	<FONT size=-2>
	<input type="button" value="    " name="action_d_delete" 
	onClick="request_confirm(this.form,'您确定要删除 [path][s->doc] ([f->size] Kb) ?')">
	</FONT>
	<INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	<INPUT TYPE="hidden" NAME="path" VALUE="[path][f->doc]">
	</form>
	</center>
	</TD>
	[ELSE]
	  <TD>&nbsp; </TD> <TD>&nbsp; </TD>
	[ENDIF]
		 
	[IF f->control]
	  <TD> <center>
	  <form method="post" ACTION="[path_cgi]">
	  <font size=-2>
	  <input type="submit" value="    " name="action_d_control">
	  </font>
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="path" VALUE="[path][f->doc]">     
	  </form>
	  </center></TD>
	[ELSE]
	<TD>&nbsp; </TD>
	[ENDIF]
	</TD>
	</TR>
      [END] 
    [ENDIF]
  [ENDIF]
  </TABLE>	        
 
  <HR> 
<TABLE CELLSPACING=20>
   
   [IF path]
         
      [IF may_edit]
      <TR>
      <form method="post" ACTION="[path_cgi]">
      <TD ALIGN="right" VALIGN="bottom">
      <B> 对文件夹 [path] 进行描述 </B> <BR>
            
      <input MAXLENGTH=100 type="text" name="content" value="[description]" SIZE=50>
      </TD>
      
      <TD ALIGN="left" VALIGN="bottom">
      <input type="submit" value="应用" name="action_d_describe">
      <INPUT TYPE="hidden" NAME="serial" VALUE="[serial_desc]">
      <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
      <INPUT TYPE="hidden" NAME="path" VALUE="[path]">     
      <INPUT TYPE="hidden" NAME="action" VALUE="d_describe">
      </TD>

      </form>
      </TR>
      [ENDIF]
   
      [IF may_control]
      <TR>   
      <form method="post" ACTION="[path_cgi]">
           
      <TD ALIGN="right" VALIGN="center">
      <B> 编辑文件夹 [path] 的存取权限</B> 

      </TD>
     
      <TD ALIGN="left" VALIGN="bottom">
      <input type="submit" value="   权限   " name="action_d_control">
      <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
      <INPUT TYPE="hidden" NAME="path" VALUE="[path]">     
      </TD>

      </form>
      </TR><BR>
      [ENDIF]
  
   [ENDIF] 


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
    <INPUT TYPE="hidden" NAME="action" VALUE="d_create_dir">
    </TD>
    </form>
    </TR><BR>

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
   




