<!-- RCS Identication ; $Revision$ ; $Date$ -->

[IF url]
<H1>Edition of the bookmark [path]</H1>
[ELSIF directory]
<H1>Edition of the directory [path]</H1>
[ELSE]
<H1>Edition of the file [path]</H1>
[ENDIF]
    Owner : [doc_owner] <BR>
    Last update : [doc_date] <BR>
    Description : [desc] <BR><BR>
<H3><A HREF="[path_cgi]/d_read/[list]/[escaped_father]"> <IMG ALIGN="bottom"  src="[father_icon]" BORDER="0"> Up to higher level directory </A></H3>

<TABLE CELLSPACING=15>

  [IF !directory]
  <TR>
  <form method="post" ACTION="[path_cgi]" ENCTYPE="multipart/form-data">
  <TD ALIGN="right" VALIGN="bottom">
  [IF url]
  <B> Bookmark URL </B><BR> 
  <input name="url" VALUE="[url]">
  [ELSE]
  <B> Replace the file [path] by your file </B><BR> 
  <input type="file" name="uploaded_file">
  [ENDIF]
  </TD>
  <TD ALIGN="left" VALIGN="bottom"> 
  [IF url]
  <input type="submit" value="Modifier" name="action_d_savefile">
  [ELSE]
  <input type="submit" value="Publish" name="action_d_overwrite">
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
  <B> Describe the directory [path]</B><BR>
  [ELSE]
  <B> Describe the file [path]</B><BR>
  [ENDIF]
  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
  <INPUT TYPE="hidden" NAME="path" VALUE="[path]">
  <INPUT TYPE="hidden" NAME="serial" VALUE="[serial_desc]">
  <INPUT TYPE="hidden" NAME="action" VALUE="d_describe">
  <INPUT SIZE=50 MAXLENGTH=100 NAME="content" VALUE="[desc]">
  </TD>
  <TD ALIGN="left" VALIGN="bottom">
  <INPUT SIZE=50 MAXLENGTH=100 TYPE="submit" NAME="action_d_describe" VALUE="Apply">
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
  <INPUT TYPE="submit" NAME="action_d_savefile" VALUE="Publish">
  </FORM>
[ENDIF]
[ENDIF]




