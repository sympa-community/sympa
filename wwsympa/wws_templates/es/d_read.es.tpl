<!-- RCS Identication ; $Revision$ ; $Date$ -->

[IF file]
  [INCLUDE file]
[ELSE]
  <SCRIPT LANGUAGE="JavaScript">
  <!-- for other browsers
  function delete_confirm(my_form,my_doc,my_size){
    var message;
    if (my_size==-1) {
       message = "¿Confirma el borrado de "+ my_doc +" ?";
    } else {
       message = "¿Confirma el borrado "+ my_doc +" ("+my_size +" Kb) ?";
    }
    if (window.confirm(message)) {
      my_form.submit();
    }
  }
  // end borwsers -->
  </SCRIPT>

  [IF path]  
    <h2> <B> Contenido de la carpeta [path] </B> </h2> 
    Propietario : [doc_owner] <BR>
    Ultima actualización : [doc_date] <BR>
    Descripción : [doc_title] <BR><BR>
    <font size=+1> <A HREF="[path_cgi]/d_read/[list]/[father]"> <IMG ALIGN="bottom"  src="[father_icon]"> .. subir un nivel</A></font>
     <BR>  
  [ELSE]
    <h2> <B> Contenido de la carpeta Web compartida </B> </h2> 
  [ENDIF]
   
  <TABLE width=100%>
  <TR BGCOLOR="[dark_color]">
   
  <th><TABLE width=100%><TR><TD ALIGN="left"><font color="[bg_color]">Documento</font></TD>
  [IF  order_by<>order_by_doc]  
    <TD ALIGN="right">
    <form method="post" ACTION="[path_cgi]">  
    <INPUT ALIGN="top"  type="image" src="[sort_icon]" WIDTH=15 HEIGHT=15 name="Ordenar por nombre">
    <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
    <INPUT TYPE="hidden" NAME="path" VALUE="[path]">
    <INPUT TYPE="hidden" NAME="action" VALUE="d_read">
    <INPUT TYPE="hidden" NAME="order" VALUE="order_by_doc">
    </form>
    </TD>
  [ENDIF]	
  </TR></TABLE>
  </th>
  
  <th><TABLE width=100%><TR><TD ALIGN="left"><font color="[bg_color]">Autor</font></TD>
  [IF  order_by<>order_by_author]  
    <TD ALIGN="right">
    <form method="post" ACTION="[path_cgi]">  
    <INPUT ALIGN="top"  type="image" src="[sort_icon]" WIDTH=15 HEIGHT=15 name="Ordenar por autor">
    <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
    <INPUT TYPE="hidden" NAME="path" VALUE="[path]">
    <INPUT TYPE="hidden" NAME="action" VALUE="d_read">
    <INPUT TYPE="hidden" NAME="order" VALUE="order_by_author">
    </form>	
    </TD>
  [ENDIF]
  </TR></TABLE>
  </th> 

  <th><TABLE width=100%><TR><TD ALIGN="left"><font color="[bg_color]">Tamaño (Kb)</font></TD>
  [IF order_by<>order_by_size] 
    <TD ALIGN="right">
    <form method="post" ACTION="[path_cgi]">
    <INPUT ALIGN="top"  type="image" src="[sort_icon]" WIDTH=15 HEIGHT=15 name="Ordenar por tamaño">
    <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
    <INPUT TYPE="hidden" NAME="path" VALUE="[path]">
    <INPUT TYPE="hidden" NAME="action" VALUE="d_read">
    <INPUT TYPE="hidden" NAME="order" VALUE="order_by_size">
    </form>
    </TD>
  [ENDIF]
  </TR></TABLE>   
  </th> 

  <th><TABLE width=100%><TR><TD ALIGN="left"><font color="[bg_color]">Ult. actualización</font></TD>
  [IF order_by<>order_by_date]
    <TD ALIGN="right">
    <form method="post" ACTION="[path_cgi]">
    <INPUT ALIGN="top"  type="image" src="[sort_icon]" WIDTH=15 HEIGHT=15 name="Ordenar por fecha">
    <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
    <INPUT TYPE="hidden" NAME="path" VALUE="[path]">
    <INPUT TYPE="hidden" NAME="action" VALUE="d_read">
    <INPUT TYPE="hidden" NAME="order" VALUE="order_by_date">
    </form>
    </TD>
  [ENDIF]
  </TR></TABLE>  
  </th> 

  <th ALIGN="left"><font color="[bg_color]">Descripción</font></th> 
  <th ALIGN="center"><font color="[bg_color]">Editar</font></th> 
  <th ALIGN="center"><font color="[bg_color]">Borrar</font></th>
  <th ALIGN="center"><font color="[bg_color]">Acceso</font></th></TR>
      
  [IF empty]
    <TR BGCOLOR="[light_color]" VALIGN="top">
    <TD COLSPAN=8 ALIGN="center"> Carpeta vacía</TD>
    </TR>
  [ELSE]   
    [IF sort_subdirs]
      [FOREACH s IN sort_subdirs] 
        <TR BGCOLOR="[light_color]">        
	<TD NOWRAP> <A HREF="[path_cgi]/d_read/[list]/[path][s->doc]/"> 
	<IMG ALIGN=bottom BORDER=0 SRC="[s->icon]"> [s->doc]</A></TD>
	<TD>
	[IF s->author_known] 
	  [s->author_mailto]
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
	  <form method="post" ACTION="[path_cgi]">
	  <FONT size=-2>
	  <input type="button" value="    " name="action_d_delete" onClick="delete_confirm(this.form,'[path][s->doc]',-1)">
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
        <TR BGCOLOR="[light_color]"> 
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
	onClick="delete_confirm(this.form,'[path][f->doc]',[f->size])">
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
      <B> Describa la carpeta [path] </B> <BR>
            
      <input MAXLENGTH=100 type="text" name="content" value="[description]" SIZE=50>
      </TD>
      
      <TD ALIGN="left" VALIGN="bottom">
      <input type="submit" value="Cambiar" name="action_d_describe">
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
      <B> Editar los permisos de la carpeta [path]</B> 
      </TD>
     
      <TD ALIGN="left" VALIGN="bottom">
      <input type="submit" value="Editar" name="action_d_control">
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
    <INPUT TYPE="hidden" NAME="previous_action" VALUE="d_read">
    <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
    <INPUT TYPE="hidden" NAME="path" VALUE="[path]">
    <INPUT TYPE="hidden" NAME="action" VALUE="d_create_dir">
    <TD ALIGN="right" VALIGN="bottom"><b>
    [IF path]
      Crear una nueva carpeta dentro de la carpeta [path]
    [ELSE]
      Crear una nueva carpeta dentro del raiz de la Web compartida
    [ENDIF]
    <br>Nombre </b><input MAXLENGTH=30 type="text" name="name_doc">
    </TD>
        
    <TD ALIGN="left" VALIGN="bottom">
    <input type="submit" value="Crear" name="action_d_create_dir">
    </TD>
    </form>
    </TR>

   <TR>
   <form method="post" ACTION="[path_cgi]" ENCTYPE="multipart/form-data">
   <TD ALIGN="right" VALIGN="bottom"><b>
   [IF path]
     Descargar un fichero dentro de la carpeta [path]
   [ELSE]
     Descargar un fichero dentro de la carpeta Web compartida
   [ENDIF]
   </b><br><input type="file" name="uploaded_file">
   </TD>

   <TD ALIGN="left" VALIGN="bottom">
   <input type="submit" value="Publicar" name="action_d_upload">
   <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
   <INPUT TYPE="hidden" NAME="path" VALUE="[path]">
   </TD>
   </form> 
   </TR>
   [ENDIF]
</TABLE>
[ENDIF]
   




