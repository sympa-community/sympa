<!-- RCS Identication ; $Revision$ ; $Date$ -->

[IF url]
<H1>Edition du signet [path]</H1>
[ELSIF directory]
<H1>Edition du répertoire [path]</H1>
[ELSE]
<H1>Edition du fichier [path]</H1>
[ENDIF]
    Propriétaire : [doc_owner] <BR>
    Dernière mise à jour : [doc_date] <BR>
    Description : [desc] <BR><BR>
<H3><A HREF="[path_cgi]/d_read/[list]/[escaped_father]"> <IMG ALIGN="bottom"  src="[father_icon]" BORDER="0"> Dossier parent </A></H3>

<TABLE CELLSPACING=15>

  [IF !directory]
  <TR>
  <form method="post" ACTION="[path_cgi]" ENCTYPE="multipart/form-data">
  <TD ALIGN="right" VALIGN="bottom">
  [IF url]
  <B> URL du signet [path] </B><BR> 
  <input name="url" VALUE="[url]">
  [ELSE]
  <B> Remplacer le fichier [path] par votre fichier</B><BR> 
  <input type="file" name="uploaded_file">
  [ENDIF]
  </TD>
  <TD ALIGN="left" VALIGN="bottom">
  [IF url]
  <input type="submit" value="Modifier" name="action_d_savefile">
  [ELSE]
  <input type="submit" value="Publier" name="action_d_overwrite">
  [ENDIF]
  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
  <INPUT TYPE="hidden" NAME="path" VALUE="[path]">
  <INPUT TYPE="hidden" NAME="serial" VALUE="[serial_file]">
  </TD>
  </form>
  </TR>
  [ENDIF]

  <TR>
  <FORM ACTION="[path_cgi]" METHOD="POST">
  <TD ALIGN="right" VALIGN="bottom">
  [IF directory]
  <B> Décrire le répertoire [path]</B><BR>
  [ELSE]
  <B> Décrire le fichier [path]</B><BR>
  [ENDIF]
  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
  <INPUT TYPE="hidden" NAME="path" VALUE="[path]">
  <INPUT TYPE="hidden" NAME="serial" VALUE="[serial_desc]">
  <INPUT TYPE="hidden" NAME="action" VALUE="d_describe">
  <INPUT SIZE=50 MAXLENGTH=100 NAME="content" VALUE="[desc]">
  </TD>
  <TD ALIGN="left" VALIGN="bottom">
  <INPUT SIZE=50 MAXLENGTH=100 TYPE="submit" NAME="action_d_describe" VALUE="Appliquer">
  </TD>
  </FORM>
  </TR>

  <TR>
  <FORM ACTION="[path_cgi]" METHOD="POST">
  <TD ALIGN="right" VALIGN="bottom">
  [IF directory]
  <B> Renommer le répertoire [path]</B><BR>
  [ELSE]
  <B> Renommer le fichier [path]</B><BR>
  [ENDIF]
  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
  <INPUT TYPE="hidden" NAME="path" VALUE="[path]">
  <INPUT TYPE="hidden" NAME="serial" VALUE="[serial_desc]">
  <INPUT TYPE="hidden" NAME="action" VALUE="d_rename">
  <INPUT SIZE=50 MAXLENGTH=100 NAME="new_name" VALUE="[desc]"></TD>
  <TD ALIGN="left" VALIGN="bottom">
  <INPUT SIZE=20 MAXLENGTH=50 TYPE="submit" NAME="action_d_rename" VALUE="Renommer">
  </TD>
  </FORM>
  </TR>

</TABLE>
<BR>
<BR>

[IF !url]
[IF textfile]
  <FORM ACTION="[path_cgi]" METHOD="POST">
  <B> Editer le fichier [path]</B><BR>
  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
  <INPUT TYPE="hidden" NAME="path" VALUE="[path]">
  <INPUT TYPE="hidden" NAME="serial" VALUE="[serial_file]">
  <TEXTAREA NAME="content" COLS=80 ROWS=25>
[INCLUDE filepath]
  </TEXTAREA><BR>
  <INPUT TYPE="submit" NAME="action_d_savefile" VALUE="Publier">
  </FORM>
[ENDIF]
[ENDIF]




