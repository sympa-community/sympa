<!-- RCS Identication ; $Revision$ ; $Date$ -->

[IF url]
<H1>Kirjamerkin muuttaminen [path]</H1>
[ELSIF directory]
<H1>Hakemiston muuttaminen [path]</H1>
[ELSE]
<H1>Tiedoston muuttaminen[path]</H1>
[ENDIF]
    Omistaja : [doc_owner] <BR>
    Viim. p‰ivitetty : [doc_date] <BR>
    Kuvaus : [desc] <BR><BR>
<H3><A HREF="[path_cgi]/d_read/[list]/[escaped_father]"> <IMG ALIGN="bottom"  src="[father_icon]" BORDER="0"> Ylemp‰‰n hakemistoon </A></H3>

<TABLE CELLSPACING=15>

  [IF !directory]
  <TR>
  <form method="post" ACTION="[path_cgi]" ENCTYPE="multipart/form-data">
  <TD ALIGN="right" VALIGN="bottom">
  [IF url]
  <B> Kirjanmerkin URL </B><BR> 
  <input name="url" VALUE="[url]">
  [ELSE]
  <B> Korvaa tiedosto [path] omalla tiedostolla </B><BR> 
  <input type="file" name="uploaded_file">
  [ENDIF]
  </TD>
  <TD ALIGN="left" VALIGN="bottom"> 
  [IF url]
  <input type="submit" value="Muuttaja" name="action_d_savefile">
  [ELSE]
  <input type="submit" value="Julkista" name="action_d_overwrite">
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
  <B> Kuvaa hakemisto [path]</B><BR>
  [ELSE]
  <B> Kuvaa tiedosto [path]</B><BR>
  [ENDIF]
  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
  <INPUT TYPE="hidden" NAME="path" VALUE="[path]">
  <INPUT TYPE="hidden" NAME="serial" VALUE="[serial_desc]">
  <INPUT TYPE="hidden" NAME="action" VALUE="d_describe">
  <INPUT SIZE=50 MAXLENGTH=100 NAME="content" VALUE="[desc]">
  </TD>
  <TD ALIGN="left" VALIGN="bottom">
  <INPUT SIZE=50 MAXLENGTH=100 TYPE="submit" NAME="action_d_describe" VALUE="Toteuta">
  </TD>
  </FORM>
  </TR>

</TABLE>
<BR>
<BR>

[IF !url]
[IF textfile]
  <FORM ACTION="[path_cgi]" METHOD="POST">
  <B> Edit the file [path]</B><BR>
  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
  <INPUT TYPE="hidden" NAME="path" VALUE="[path]">
  <INPUT TYPE="hidden" NAME="serial" VALUE="[serial_file]">
  <TEXTAREA NAME="content" COLS=80 ROWS=25>
[INCLUDE filepath]
  </TEXTAREA><BR>
  <INPUT TYPE="submit" NAME="action_d_savefile" VALUE="Julkista">
  </FORM>
[ENDIF]
[ENDIF]




