<!-- RCS Identication ; $Revision$ ; $Date$ -->

[IF file]
  [INCLUDE file]
[ELSE]

  [IF path]  
    <h2><B><IMG SRC="/icons/folder.open.gif"> [path] </B> </h2> 
    <A HREF="[path_cgi]/d_editfile/[list]/[escaped_path]">éditer</A> |
    <A HREF="[path_cgi]/d_delete/[list]/[escaped_path]" onClick="request_confirm_link('[path_cgi]/d_delete/[list]/[escaped_path]', 'Voulez-vous vraiment supprimer [path] ?'); return false;">supprimer</A> |
<A HREF="[path_cgi]/d_control/[list]/[escaped_path]">accès</A><BR>
    Propriétaire : [doc_owner] <BR>
    Mise à jour : [doc_date] <BR>
    [IF doc_title]
    Description : [doc_title] <BR><BR>
    [ENDIF]
    <font size=+1> <A HREF="[path_cgi]/d_read/[list]/[escaped_father]"> <IMG ALIGN="bottom"  src="[father_icon]" BORDER="0"> Dossier parent</A></font>
    <BR>  
  [ELSE]
    <h2> <B> Liste des documents</B> </h2> 
  [ENDIF]
   
  <TABLE width=100% CELLPADDING="0">
  <TR BGCOLOR="--DARK_COLOR--">
   
  <th><TABLE width=100% CELLPADDING="0"><TR><TD ALIGN="left"><font color="--BG_COLOR--">Document</font></TD>
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
  
  <th><TABLE width=100% CELLPADDING="0"><TR><TD ALIGN="left"><font color="--BG_COLOR--">Auteur</font></TD>
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

  <th><TABLE width=100% CELLPADDING="0"><TR><TD ALIGN="left"><font color="--BG_COLOR--">Taille (Ko)</font></TD>
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

  <th><TABLE width=100% CELLPADDING="0"><TR><TD ALIGN="left"><font color="--BG_COLOR--">Mise à jour</font></TD>
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

  <TD ALIGN="center"><font color="--BG_COLOR--">Editer</font></TD> 
  <TD ALIGN="center"><font color="--BG_COLOR--">Supprimer</font></TD>
  <TD ALIGN="center"><font color="--BG_COLOR--">Accès</font></TD></TR>
      
  [IF empty]
    <TR BGCOLOR="--LIGHT_COLOR--">
    <TD COLSPAN=8 ALIGN="center"> Dossier vide </TD>
    </TR>
  [ELSE]   
    [IF sort_subdirs]
      [FOREACH s IN sort_subdirs] 
        <TR BGCOLOR="--LIGHT_COLOR--">        
	<TD NOWRAP> <A HREF="[path_cgi]/d_read/[list]/[escaped_path][s->escaped_doc]/"> 
	<IMG ALIGN=bottom BORDER=0 SRC="[s->icon]" ALT="[s->title]"> [s->doc]</A></TD>
	<TD>
	[IF s->author_known] 
	  <A HREF="mailto:[s->author]">[s->author]</A>  
        [ELSE]
	   inconnu
	[ENDIF]
	</TD>	    
	<TD>&nbsp;</TD>
	<TD> [s->date] </TD>
		
	[IF s->edit]
	<TD><center>
	<font size=-1>
	<A HREF="[path_cgi]/d_editfile/[list]/[escaped_path][s->escaped_doc]">éditer</A>
	</font>
	</center></TD>
	
	  <TD><center>
	  <FONT size=-1>
	  <A HREF="[path_cgi]/d_delete/[list]/[escaped_path][s->escaped_doc]" onClick="request_confirm_link('[path_cgi]/d_delete/[list]/[escaped_path][s->escaped_doc]', 'Voulez-vous vraiment supprimer [path][s->doc] ?'); return false;">supprimer</A>
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
	  <A HREF="[path_cgi]/d_control/[list]/[escaped_path][s->escaped_doc]">accès</A>
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
        <TD NOWRAP>
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
          inconnu  
        [ENDIF]
	</TD>
	 
	<TD NOWRAP>&nbsp;
	[IF !f->url]
	[f->size] 
	[ENDIF]
	</TD>
	<TD> [f->date] </TD>
	 
	[IF f->edit]
	<TD>
	<center>
	<font size=-1>
	<A HREF="[path_cgi]/d_editfile/[list]/[escaped_path][f->escaped_doc]">éditer</A>
	</font>
	</center>

	</TD>
	<TD>
	<center>
	<FONT size=-1>
	<A HREF="[path_cgi]/d_delete/[list]/[escaped_path][f->escaped_doc]" onClick="request_confirm_link('[path_cgi]/d_delete/[list]/[escaped_path][f->escaped_doc]', 'Voulez-vous vraiment supprimer [path][f->doc] ([f->size] Ko) ?'); return false;">supprimer</A>
	</FONT>
	</center>
	</TD>
	[ELSE]
	  <TD>&nbsp; </TD> <TD>&nbsp; </TD>
	[ENDIF]
		 
	[IF f->control]
	  <TD> <center>
	  <font size=-1>
	  <A HREF="[path_cgi]/d_control/[list]/[escaped_path][f->escaped_doc]">accès</A>
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
   
  [IF may_edit]
    <TR>
    <FORM METHOD="POST" ACTION="[path_cgi]">
    <TD ALIGN="right" VALIGN="bottom">
    [IF path]
      <B> Créer un sous dossier dans [path]</B> <BR>
    [ELSE]
      <B> Créer un dossier</B> <BR>
    [ENDIF]
    <input MAXLENGTH=30 type="text" name="name_doc">
    </TD>

    <TD ALIGN="left" VALIGN="bottom">
    <input type="submit" value="Créer" name="action_d_create_dir">
    <INPUT TYPE="hidden" NAME="previous_action" VALUE="d_read">
    <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
    <INPUT TYPE="hidden" NAME="path" VALUE="[path]">
    <INPUT TYPE="hidden" NAME="type" VALUE="directory">
    <INPUT TYPE="hidden" NAME="action" VALUE="d_create_dir">
    </TD>
    </FORM>
    </TR>

    <TR>
    <FORM METHOD="POST" ACTION="[path_cgi]">
    <TD ALIGN="right" VALIGN="bottom">
      <B> Créer un fichier</B> <BR>
    <input MAXLENGTH=30 type="text" name="name_doc">
    </TD>

    <TD ALIGN="left" VALIGN="bottom">
    <input type="submit" value="Créer" name="action_d_create_dir">
    <INPUT TYPE="hidden" NAME="previous_action" VALUE="d_read">
    <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
    <INPUT TYPE="hidden" NAME="path" VALUE="[path]">
    <INPUT TYPE="hidden" NAME="type" VALUE="file">
    <INPUT TYPE="hidden" NAME="action" VALUE="d_create_dir">
    </TD>
    </FORM>
    </TR>

    <TR>
    <FORM METHOD="POST" ACTION="[path_cgi]">
    <TD ALIGN="right" VALIGN="center">
    <B>Ajouter un signet</B><BR>
    URL <input MAXLENGTH=100 SIZE="25" type="text" name="url"><BR>
    intitulé <input MAXLENGTH=100 SIZE="20" type="text" name="name_doc">
    </TD>

    <TD ALIGN="left" VALIGN="bottom">
    <input type="submit" value="Ajouter" name="action_d_savefile">
    <INPUT TYPE="hidden" NAME="previous_action" VALUE="d_read">
    <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
    <INPUT TYPE="hidden" NAME="path" VALUE="[path]">
    <INPUT TYPE="hidden" NAME="action" VALUE="d_savefile">
    </TD>
    </FORM>
    </TR>

   <TR>
   <FORM METHOD="POST" ACTION="[path_cgi]" ENCTYPE="multipart/form-data">
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
   </FORM>
   </TR>
   [ENDIF]
</TABLE>
</FORM>
[ENDIF]
   




