<!-- RCS Identication ; $Revision$ ; $Date$ -->

[IF url]
<H1>[path] könyvjelzõ (bookmark) szerkesztése</H1>
[ELSIF directory]
<H1>[path] könyvtár szerkesztése</H1>
[ELSE]
<H1>[path] állomány szerkesztése</H1>
[ENDIF]
    Tulajdonos: [doc_owner] <BR>
    Utolsó módosítás: [doc_date] <BR>
    Leírás: [desc] <BR><BR>
<H3><A HREF="[path_cgi]/d_read/[list]/[escaped_father]"> <IMG ALIGN="bottom"  src="[father_icon]">Egy könyvtárral feljebb</A></H3>

<TABLE CELLSPACING=15>

[IF !directory]
  <TR>
  <form method="post" ACTION="[path_cgi]" ENCTYPE="multipart/form-data">
  <TD ALIGN="right" VALIGN="bottom">
[IF url]
  <B>Webcím felvétele a könyvjelzõbe</B><BR>
  <input name="url" VALUE="[url]">
[ELSE]
  <B> A(z) [path] állomány felülírása </B><BR> 
  <input type="file" name="uploaded_file">
[ENDIF]
  </TD>
  <TD ALIGN="left" VALIGN="bottom"> 
[IF url]
  <input type="submit" value="Változtat" name="action_d_savefile">
[ELSE]
  <input type="submit" value="Feltölt" name="action_d_overwrite">
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
  <B>[path] könyvtár tulajdonságai</B></BR>
[ELSE]
  <B>[path] állomány tulajdonságai</B></BR>
  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
  <INPUT TYPE="hidden" NAME="path" VALUE="[path]">
  <INPUT TYPE="hidden" NAME="serial" VALUE="[serial_desc]">
  <INPUT TYPE="hidden" NAME="action" VALUE="d_describe">
  <INPUT SIZE=50 MAXLENGTH=100 NAME="content" VALUE="[desc]">
  </TD>
  <TD ALIGN="left" VALIGN="bottom">
  <INPUT SIZE=50 MAXLENGTH=100 TYPE="submit" NAME="action_d_describe" VALUE="Alkalmaz">
  </TD>
  </FORM>
  </TR>

</TABLE>
<BR>
<BR>

[IF !url]
[IF textfile]
  <FORM ACTION="[path_cgi]" METHOD="POST">
  <B> [path] állomány szerkesztése</B><BR>
  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
  <INPUT TYPE="hidden" NAME="path" VALUE="[path]">
  <INPUT TYPE="hidden" NAME="serial" VALUE="[serial_file]">
  <TEXTAREA NAME="content" COLS=80 ROWS=25>
[INCLUDE filepath]
  </TEXTAREA><BR>
  <INPUT TYPE="submit" NAME="action_d_savefile" VALUE="Elment">
  </FORM>
[ENDIF]
[ENDIF]




