<!-- RCS Identication ; $Revision$ ; $Date$ -->

[IF url]
<H1>Editarea bookmark-urilor [path]</H1>
[ELSIF directory]
<H1>Editarea directorului[path]</H1>
[ELSE]
<H1>Editarea fisierului [path]</H1>
[ENDIF] 
Proprietar: [doc_owner] <BR>
Ultima actualizare: [doc_date] <BR>
Descriere : [desc] <BR>
<BR>
<H3><A HREF="[path_cgi]/d_read/[list]/[escaped_father]"> <IMG ALIGN="bottom"  src="[father_icon]" BORDER="0"> 
  Nivelul precedent</A></H3>

<TABLE CELLSPACING=15>

  [IF !directory]
  <TR>
  <form method="post" ACTION="[path_cgi]" ENCTYPE="multipart/form-data">
  <TD ALIGN="right" VALIGN="bottom">
  [IF url]
  <B> Bookmark URL </B><BR> 
  <input name="url" VALUE="[url]">
        [ELSE] 
<B> Inlocuieste fisierul [path] cu fisierul tau</B><BR> 
  <input type="file" name="uploaded_file">
  [ENDIF]
  </TD>
  <TD ALIGN="left" VALIGN="bottom"> 
  [IF url]
        <input type="submit" value="Modificare" name="action_d_savefile">
  [ELSE]
        <input type="submit" value="Publica" name="action_d_overwrite">
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
 <B> Descrie directorul 
        [path]</B> <BR>
[ELSE] 
<B> Descrie fisierul [path]</B> <BR>
[ENDIF] 
        <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
  <INPUT TYPE="hidden" NAME="path" VALUE="[path]">
  <INPUT TYPE="hidden" NAME="serial" VALUE="[serial_desc]">
  <INPUT TYPE="hidden" NAME="action" VALUE="d_describe">
  <INPUT SIZE=50 MAXLENGTH=100 NAME="content" VALUE="[desc]">
  </TD>
  <TD ALIGN="left" VALIGN="bottom">
        <INPUT SIZE=50 MAXLENGTH=100 TYPE="submit" NAME="action_d_describe" VALUE="Modifica">
  </TD>
  </FORM>
  </TR>

</TABLE>
<BR>
<BR>

[IF !url]
[IF textfile]
  <FORM ACTION="[path_cgi]" METHOD="POST">
  <B> Editeaza fisierul [path]</B><BR>
  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
  <INPUT TYPE="hidden" NAME="path" VALUE="[path]">
  <INPUT TYPE="hidden" NAME="serial" VALUE="[serial_file]">
  <TEXTAREA NAME="content" COLS=80 ROWS=25>
[INCLUDE filepath]
  </TEXTAREA><BR>
  <INPUT TYPE="submit" NAME="action_d_savefile" VALUE="Publica">
  </FORM>
[ENDIF]
[ENDIF]




