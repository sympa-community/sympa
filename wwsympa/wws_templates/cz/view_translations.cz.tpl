<!-- RCS Identication ; $Revision$ ; $Date$ -->

<TABLE BGCOLOR="#330099" CELLPADDING="0" CELLSPACING="0">
<TR><TD>

<TABLE CELLPADDING="1" CELLSPACING="1" >
<TR BGCOLOR="#3366cc">
<TH  ALIGN="left"><FONT COLOR="#ffffff">Akce</TH>
[FOREACH lang IN tpl_lang]
<TH ALIGN="left"><FONT COLOR="#ffffff">[lang->NAME]</TH>
[END]
</TR>
[FOREACH file IN tpl]
  <TR><TH ALIGN="left" BGCOLOR="#3366cc"><FONT COLOR="#ffffff">[file->NAME]</FONT></TH>
  [FOREACH translation IN file]
      [IF translation=none]
	<TD BGCOLOR="#ffffff"><A HREF="[path_cgi]/translate/[file->NAME]/[translation->NAME]">Proveï</A></TD>
      [ELSE]
	<TD><FONT COLOR="#ffffff">pøelo¾eno</FONT></TD>
      [ENDIF]
  [END]
  </TR>
[END]
</TABLE>

</TD></TR></TABLE>

