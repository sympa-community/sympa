<!-- RCS Identication ; $Revision$ ; $Date$ -->

<TABLE BGCOLOR="--DARK_COLOR--" CELLPADDING="0" CELLSPACING="0">
<TR><TD>

<TABLE CELLPADDING="1" CELLSPACING="1" >
<TR BGCOLOR="--SELECTED_COLOR--">
<TH  ALIGN="left"><FONT COLOR="--BG_COLOR--">Módosítások</TH>
[FOREACH lang IN tpl_lang]
<TH ALIGN="left"><FONT COLOR="--BG_COLOR--">[lang->NAME]</TH>
[END]
</TR>
[FOREACH file IN tpl]
  <TR><TH ALIGN="left" BGCOLOR="--SELECTED_COLOR--"><FONT COLOR="--BG_COLOR--">[file->NAME]</FONT></TH>
  [FOREACH translation IN file]
      [IF translation=none]
	<TD BGCOLOR="--BG_COLOR--"><A HREF="[path_cgi]/translate/[file->NAME]/[translation->NAME]">Szerkesztés</A></TD>
      [ELSE]
	<TD><FONT COLOR="--BG_COLOR--">lefordítva</FONT></TD>
      [ENDIF]
  [END]
  </TR>
[END]
</TABLE>

</TD></TR></TABLE>
