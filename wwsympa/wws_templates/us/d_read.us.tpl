<!-- RCS Identication ; $Revision$ ; $Date$ -->

[IF file]
  [INCLUDE file]
[ELSE]

  [IF path]  
    <h2> <B> Listing of folder [path] </B> </h2> 
    Owner : [doc_owner] <BR>
    Last update : [doc_date] <BR>
    Description : [doc_title] <BR><BR>
    <font size=+1> <A HREF="[path_cgi]/d_read/[list]/[father]"> <IMG ALIGN="bottom"  src="[father_icon]"> Up to higher level directory</A></font>
    <BR>  
  [ELSE]
    <h2> <B> Listing of folder SHARED </B> </h2> 
  [ENDIF]
   
  <TABLE width=100%>
  <TR BGCOLOR="--DARK_COLOR--">
   
  <th><TABLE width=100%><TR><TD ALIGN="left"><font color="--BG_COLOR--">Document</font></TD>
  [IF  order_by<>order_by_doc]  
    <TD ALIGN="right">
    <form method="post" ACTION="[path_cgi]">  
    <INPUT ALIGN="top"  type="image" src="[sort_icon]" WIDTH=15 HEIGHT=15 name="Sort by name">
    <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
    <INPUT TYPE="hidden" NAME="path" VALUE="[path]">
    <INPUT TYPE="hidden" NAME="action" VALUE="d_read">
    <INPUT TYPE="hidden" NAME="order" VALUE="order_by_doc">
    </form>
    </TD>
  [ENDIF]	
  </TR></TABLE>
  </th>
  
  <th><TABLE width=100%><TR><TD ALIGN="left"><font color="--BG_COLOR--">Author</font></TD>
  [IF  order_by<>order_by_author]  
    <TD ALIGN="right">
    <form method="post" ACTION="[path_cgi]">  
    <INPUT ALIGN="top"  type="image" src="[sort_icon]" WIDTH=15 HEIGHT=15 name="Sort by author">
    <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
    <INPUT TYPE="hidden" NAME="path" VALUE="[path]">
    <INPUT TYPE="hidden" NAME="action" VALUE="d_read">
    <INPUT TYPE="hidden" NAME="order" VALUE="order_by_author">
    </form>	
    </TD>
  [ENDIF]
  </TR></TABLE>
  </th> 

  <th><TABLE width=100%><TR><TD ALIGN="left"><font color="--BG_COLOR--">Size (Kb)</font></TD>
  [IF order_by<>order_by_size] 
    <TD ALIGN="right">
    <form method="post" ACTION="[path_cgi]">
    <INPUT ALIGN="top"  type="image" src="[sort_icon]" WIDTH=15 HEIGHT=15 name="Sort by size">
    <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
    <INPUT TYPE="hidden" NAME="path" VALUE="[path]">
    <INPUT TYPE="hidden" NAME="action" VALUE="d_read">
    <INPUT TYPE="hidden" NAME="order" VALUE="order_by_size">
    </form>
    </TD>
  [ENDIF]
  </TR></TABLE>   
  </th> 

  <th><TABLE width=100%><TR><TD ALIGN="left"><font color="--BG_COLOR--">Last update</font></TD>
  [IF order_by<>order_by_date]
    <TD ALIGN="right">
    <form method="post" ACTION="[path_cgi]">
    <INPUT ALIGN="top"  type="image" src="[sort_icon]" WIDTH=15 HEIGHT=15 name="Sort by date">
    <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
    <INPUT TYPE="hidden" NAME="path" VALUE="[path]">
    <INPUT TYPE="hidden" NAME="action" VALUE="d_read">
    <INPUT TYPE="hidden" NAME="order" VALUE="order_by_date">
    </form>
    </TD>
  [ENDIF]
  </TR></TABLE>  
  </th> 

  <TD ALIGN="left"><font color="--BG_COLOR--">Description</font></TD> 
  <TD ALIGN="center"><font color="--BG_COLOR--">Edit</font></TD> 
  <TD ALIGN="center"><font color="--BG_COLOR--">Delete</font></D>
  <TD ALIGN="center"><font color="--BG_COLOR--">Access</font></TD></TR>
      
  [IF empty]
    <TR BGCOLOR="--LIGHT_COLOR--" VALIGN="top">
    <TD COLSPAN=8 ALIGN="center"> Empty folder </TD>
    </TR>
  [ELSE]   
    [IF sort_subdirs]
      [FOREACH s IN sort_subdirs] 
        <TR BGCOLOR="--LIGHT_COLOR--">        
	<TD NOWRAP> <A HREF="[path_cgi]/d_read/[list]/[path][s->doc]/"> 
	<IMG ALIGN=bottom BORDER=0 SRC="[s->icon]"> [s->doc]</A></TD>
	<TD>
	[IF s->author_known] 
	  <A HREF="mailto:[s->author]">[s->author]</A>  
        [ELSE]
	   Unknown 
	[ENDIF]
	</TD>	    
	<TD>&nbsp;</TD>
	<TD NOWRAP> [s->date] </TD>
	<TD NOWRAP>&nbsp; [s->title]</TD>
		
	<TD>&nbsp; </TD>
	
	[IF s->edit]
	  <TD><center>
	  <FONT size=-1>
	  <A HREF="[path_cgi]/d_delete/[list]/[path][s->doc]" onClick="request_confirm_link('[path_cgi]/d_delete/[list]/[path][s->doc]', 'Do you really want to delete [path][s->doc] ?'); return false;">delete</A>
	  </FONT>
	  </center></TD>
	[ELSE]
	  <TD>&nbsp; </TD>
	[ENDIF]
	
	[IF s->control]
	  <TD>
	  <center>
	  <FONT size=-1>
	  <A HREF="[path_cgi]/d_control/[list]/[path][s->doc]">access</A>
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
        <TR BGCOLOR="--LIGHT_COLOR--"> 
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
          Unknown  
        [ENDIF]
	</TD>
	 
	<TD NOWRAP> [f->size] </TD>
	<TD NOWRAP> [f->date] </TD>
	<TD NOWRAP>&nbsp; [f->title]</TD>
	 
	[IF f->edit]
	<TD>
	<center>
	<font size=-1>
	<A HREF="[path_cgi]/d_editfile/[list]/[path][f->doc]">edit</A>
	</font>
	</center>

	</TD>
	<TD>
	<center>
	<FONT size=-1>
	<A HREF="[path_cgi]/d_delete/[list]/[path][f->doc]" onClick="request_confirm_link('[path_cgi]/d_delete/[list]/[path][f->doc]', 'Do you really want to delete [path][s->doc] ([f->size] Kb) ?'); return false;">delete</A>
	</FONT>
	</center>
	</TD>
	[ELSE]
	  <TD>&nbsp; </TD> <TD>&nbsp; </TD>
	[ENDIF]
		 
	[IF f->control]
	  <TD> <center>
	  <font size=-1>
	  <A HREF="[path_cgi]/d_control/[list]/[path][f->doc]">access</A>
	  </font>
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
      <B> Describe the folder [path] </B> <BR>
            
      <input MAXLENGTH=100 type="text" name="content" value="[description]" SIZE=50>
      </TD>
      
      <TD ALIGN="left" VALIGN="bottom">
      <input type="submit" value="Apply" name="action_d_describe">
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
      <B> Edit the access of the folder [path]</B> 

      </TD>
     
      <TD ALIGN="left" VALIGN="bottom">
      <input type="submit" value="   Access   " name="action_d_control">
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
      <B> Create a new folder inside the folder [path]</B> <BR>
    [ELSE]
      <B> Create a new folder inside the folder SHARED</B> <BR>
    [ENDIF]
    <input MAXLENGTH=30 type="text" name="name_doc">
    </TD>

    <TD ALIGN="left" VALIGN="bottom">
    <input type="submit" value="Create a new subdirectory" name="action_d_create_dir">
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
     <B> Upload a file inside the folder [path]</B><BR>
   [ELSE]
     <B> Upload a file inside the folder SHARED </B><BR>
   [ENDIF]
   <input type="file" name="uploaded_file">
   </TD>

   <TD ALIGN="left" VALIGN="bottom">
   <input type="submit" value="Publish" name="action_d_upload">
   <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
   <INPUT TYPE="hidden" NAME="path" VALUE="[path]">
   <TD>
   </form> 
   </TR>
   [ENDIF]
</TABLE>
[ENDIF]
   




