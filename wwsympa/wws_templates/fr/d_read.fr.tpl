<!-- RCS Identication ; $Revision$ ; $Date$ -->

[IF file]
  [INCLUDE file]
[ELSE]

  [IF path]  
    <h2> <B> Contenu du dossier [path] </B> </h2> 
    Owner : [doc_owner] <BR>
    Mise à jour : [doc_date] <BR>
    Description : [doc_title] <BR><BR>
    <font size=+1> <A HREF="[path_cgi]/d_read/[list]/[father]"> <IMG ALIGN="bottom"  src="[father_icon]"> Dossier parent</A></font>
    <BR>  
  [ELSE]
    <h2> <B> Liste des documents</B> </h2> 
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
  
  <th><TABLE width=100%><TR><TD ALIGN="left"><font color="--BG_COLOR--">Auteur</font></TD>
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

  <th><TABLE width=100%><TR><TD ALIGN="left"><font color="--BG_COLOR--">Taille (Kb)</font></TD>
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

  <th><TABLE width=100%><TR><TD ALIGN="left"><font color="--BG_COLOR--">Mise à jour</font></TD>
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

  <th ALIGN="left"><font color="--BG_COLOR--">Description</font></th> 
  <th ALIGN="center"><font color="--BG_COLOR--">Editer</font></th> 
  <th ALIGN="center"><font color="--BG_COLOR--">Supprimer</font></th>
  <th ALIGN="center"><font color="--BG_COLOR--">Accès</font></th></TR>
      
  [IF empty]
    <TR BGCOLOR="--LIGHT_COLOR--">
    <TD COLSPAN=8 ALIGN="center"> Dossier vide </TD>
    </TR>
  [ELSE]   
    [IF sort_subdirs]
      [FOREACH s IN sort_subdirs] 
        <TR BGCOLOR="--LIGHT_COLOR--">        
	<TD> <A HREF="[path_cgi]/d_read/[list]/[path][s->doc]/"> 
	<IMG ALIGN=bottom BORDER=0 SRC="[s->icon]"> [s->doc]</A></TD>
	<TD>
	[IF s->author_known] 
	  <A HREF="mailto:[s->author]">[s->author]</A>  
        [ELSE]
	   inconnu
	[ENDIF]
	</TD>	    
	<TD>&nbsp;</TD>
	<TD> [s->date] </TD>
	<TD>&nbsp; [s->title]</TD>
		
	<TD>&nbsp; </TD>
	
	[IF s->edit]
	  <TD><center>
	  <form method="post" ACTION="[path_cgi]">
	  <FONT size=-2>
	  <input type="button" value="    " name="action_d_delete" onClick="request_confirm(this.form,'Voulez-vous vraiment supprimer [path][s->doc] ?')">
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
	 
	<TD> [f->size] </TD>
	<TD> [f->date] </TD>
	<TD>&nbsp; [f->title]</TD>
	 
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
	onClick="request_confirm(this.form,'Voulez-vous vraiment supprimer [path][f->doc] ([f->size] Kb) ?')">
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
      <B> Décrire le dossier [path] </B> <BR>
            
      <input MAXLENGTH=100 type="text" name="content" value="[description]" SIZE=50>
      </TD>
      
      <TD ALIGN="left" VALIGN="bottom">
      <input type="submit" value="Valider" name="action_d_describe">
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
      <B> Editer les droits d'accès du dossier [path]</B> 

      </TD>
     
      <TD ALIGN="left" VALIGN="bottom">
      <input type="submit" value="   Accès   " name="action_d_control">
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
      <B> Créer un sous dossier dans [path]</B> <BR>
    [ELSE]
      <B> Créer un dossier</B> <BR>
    [ENDIF]
    <input MAXLENGTH=30 type="text" name="name_doc">
    </TD>

    <TD ALIGN="left" VALIGN="bottom">
    <input type="submit" value=Créer un nouveau sous dossier"" name="action_d_create_dir">
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
     <B> Télécharger un fichier dans le dossier [path]</B><BR>
   [ELSE]
     <B> Télécharger un fichier </B><BR>
   [ENDIF]
   <input type="file" name="uploaded_file">
   </TD>

   <TD ALIGN="left" VALIGN="bottom">
   <input type="submit" value="Publier" name="action_d_upload">
   <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
   <INPUT TYPE="hidden" NAME="path" VALUE="[path]">
   <TD>
   </form> 
   </TR>
   [ENDIF]
</TABLE>
[ENDIF]
   




