<!-- RCS Identication ; $Revision$ ; $Date$ -->

<FORM METHOD=POST ACTION="[path_cgi]">

<INPUT NAME=list TYPE=hidden VALUE="[list]">
<INPUT NAME=archive_name TYPE=hidden VALUE="[archive_name]">

<center>
<TABLE width=100%>
<TR><td bgcolor="[light_color]" align=center>
<font size=+1>Campo de Búsqueda : </font><A HREF=[path_cgi]/arc/[list]/[archive_name]><font size=+2 color="[dark_color]"><b>[archive_name]</b></font></A>
</TD><TD bgcolor="[light_color]" align=center>
<INPUT NAME=key_word     TYPE=text   SIZE=30 VALUE="[key_word]">
<INPUT NAME="action"  TYPE="hidden" Value="arcsearch">
<INPUT NAME=action_arcsearch TYPE=submit VALUE="Buscar">
</TD></TR></TABLE>
 </center>
<P>

<TABLE CELLSPACING=0	CELLPADDING=0>

<TR VALIGN="TOP" NOWRAP>
<TD><b>Buscar</b></TD>
<TD><INPUT TYPE=RADIO NAME=how VALUE="phrase" CHECKED> esta <font color="[dark_color]"><B>frase</b></font></TD>
<TD><INPUT TYPE=RADIO NAME=how VALUE="all"> <font color="[dark_color]"><b>all of</b></font> estas palabras</TD>
<TD><INPUT TYPE=RADIO NAME=how VALUE="any"> <font color="[dark_color]"><B>one of</b></font> estas palabras</TD>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD><b>Prefiero</b></TD>
<TD><INPUT TYPE=RADIO NAME=age VALUE="new" CHECKED> <font color="[dark_color]"><b>los más nuevos</b></font> mensajes</TD>
<TD><INPUT TYPE=RADIO NAME=age VALUE="old"> <font color="[dark_color]"><b>los más viejos</b></font> mensajes</TD>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD><b>Mayúsculas </b></TD>
<TD><INPUT TYPE=RADIO NAME=case VALUE="off" CHECKED> <font color="[dark_color]"><B>insensible</b></font></TD>
<TD><INPUT TYPE=RADIO NAME=case VALUE="on"> <font color="[dark_color]"><B>sensible</B></font></TD>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD><b>Comprobar</b></TD>
<TD><INPUT TYPE=RADIO NAME=match VALUE="partial" CHECKED> <font color="[dark_color]"><B>parte</b></font> de la palabra</TD>
<TD><INPUT TYPE=RADIO NAME=match VALUE="exact"> <font color="[dark_color]"><B>toda la</b></font> palabra</TD>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD><b>Esquema</b></TD>
<TD><INPUT TYPE=RADIO NAME=limit VALUE="10" CHECKED> <font color="[dark_color]"><B>10</b></font> resultados por página
</TD>
<TD><INPUT TYPE=RADIO NAME=limit VALUE="25"> <font color="[dark_color]"><B>25</b></font> resultados por página</TD>
<TD><INPUT TYPE=RADIO NAME=limit VALUE="50"> <font color="[dark_color]"><B>50</b></font> resultados por página</TD>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD><b>Area de búsqueda</b></TD>
<TD><INPUT TYPE=checkbox NAME=from Value="True"> <font color="[dark_color]"><B>Remitente</B></font>

<TD><INPUT TYPE=checkbox NAME=subj Value="True"> <font color="[dark_color]"> <B>Tema</B></font>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD>&#160;</TD>
<TD><INPUT TYPE=checkbox NAME=date Value="True"> <font color="[dark_color]"><B>Fecha</B></font>

<TD><INPUT TYPE=checkbox NAME=body Value="True" checked> <font color="[dark_color]"><B>Cuerpo</B></font>
</TR>

</TABLE>

<DL>
<DT><b>Campo de búsqueda extendida</b>
<SELECT NAME="directories" MULTIPLE SIZE=4>    
<DD>

[FOREACH u IN yyyymm]

<OPTION VALUE="[u]">[u]

[END] 

</SELECT></DL>

</FORM>
