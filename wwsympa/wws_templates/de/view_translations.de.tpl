<!-- RCS Identication ; $Revision$ ; $Date$ -->

<TABLE BGCOLOR="[dark_color]" CELLPADDING="0" CELLSPACING="0">
<TR><TD>

<TABLE CELLPADDING="1" CELLSPACING="1" >
<TR BGCOLOR="[selected_color]">
<TH  ALIGN="left"><FONT COLOR="[bg_color]">Actions</TH>
[FOREACH lang IN tpl_lang]
<TH ALIGN="left"><FONT COLOR="[bg_color]">[lang->NAME]</TH>
[END]
</TR>
[FOREACH file IN tpl]
  <TR><TH ALIGN="left" BGCOLOR="[selected_color]"><FONT COLOR="[bg_color]">[file->NAME]</FONT></TH>
  [FOREACH translation IN file]
      [IF translation=none]
	<TD BGCOLOR="[bg_color]"><A HREF="[path_cgi]/translate/[file->NAME]/[translation->NAME]">Tut es</A></TD>
      [ELSE]
	<TD><FONT COLOR="[bg_color]">&uuml;bersetzt</FONT></TD>
      [ENDIF]
  [END]
  </TR>
[END]
</TABLE>

</TD></TR></TABLE>
