<!-- RCS Identication ; $Revision$ ; $Date$ -->

<FORM METHOD=POST ACTION="[path_cgi]">

<INPUT NAME=list TYPE=hidden VALUE="[list]">
<INPUT NAME=archive_name TYPE=hidden VALUE="[archive_name]">

<center>
<TABLE width=100%>
<TR><td bgcolor="[light_color]" align=center>
<font size=+1>Campo di ricerca : </font><A HREF=[path_cgi]/arc/[list]/[archive_name]><font size=+2 color="[dark_color]"><b>[archive_name]</b></font></A>
</TD><TD bgcolor="[light_color]" align=center>
<INPUT NAME=key_word     TYPE=text   SIZE=30 VALUE="[key_word]">
<INPUT NAME="action"  TYPE="hidden" Value="arcsearch">
<INPUT NAME=action_arcsearch TYPE=submit VALUE="Ricerca">
</TD></TR></TABLE>
 </center>
<P>

<TABLE CELLSPACING=0	CELLPADDING=0>

<TR VALIGN="TOP" NOWRAP>
<TD><b>Ricerca</b></TD>
<TD><INPUT TYPE=RADIO NAME=how VALUE="phrase" CHECKED> this <font color="[dark_color]"><B>frase</b></font></TD>
<TD><INPUT TYPE=RADIO NAME=how VALUE="all"> <font color="[dark_color]"><b>tutte</b></font> queste parole</TD>
<TD><INPUT TYPE=RADIO NAME=how VALUE="any"> <font color="[dark_color]"><B>una di</b></font> queste parole</TD>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD><b>Preferenze</b></TD>
<TD><INPUT TYPE=RADIO NAME=age VALUE="new" CHECKED> <font color="[dark_color]"><b>ultimi</b></font> messaggi</TD>
<TD><INPUT TYPE=RADIO NAME=age VALUE="old"> <font color="[dark_color]"><b>primi</b></font> messaggi</TD>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD><b>Maiuscole e minuscole</b></TD>
<TD><INPUT TYPE=RADIO NAME=case VALUE="off" CHECKED> <font color="[dark_color]"><B>non sensitivo</b></font></TD>
<TD><INPUT TYPE=RADIO NAME=case VALUE="on"> <font color="[dark_color]"><B>sensitivo</B></font></TD>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD><b>Controlla</b></TD>
<TD><INPUT TYPE=RADIO NAME=match VALUE="partial" CHECKED> <font color="[dark_color]"><B>parte</b></font> della parola</TD>
<TD><INPUT TYPE=RADIO NAME=match VALUE="exact"> <font color="[dark_color]"><B>tutta</b></font> la parola</TD>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD><b>Risultati</b></TD>
<TD><INPUT TYPE=RADIO NAME=limit VALUE="10" CHECKED> <font color="[dark_color]"><B>10</b></font> risultati per pagina
</TD>
<TD><INPUT TYPE=RADIO NAME=limit VALUE="25"> <font color="[dark_color]"><B>25</b></font> risultati per pagina</TD>
<TD><INPUT TYPE=RADIO NAME=limit VALUE="50"> <font color="[dark_color]"><B>50</b></font> risultati per pagina</TD>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD><b>Dove cerco</b></TD>
<TD><INPUT TYPE=checkbox NAME=from Value="True"> <font color="[dark_color]"><B>Mittente</B></font>

<TD><INPUT TYPE=checkbox NAME=subj Value="True"> <font color="[dark_color]"> <B>Soggetto</B></font>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD>&#160;</TD>
<TD><INPUT TYPE=checkbox NAME=date Value="True"> <font color="[dark_color]"><B>Data</B></font>

<TD><INPUT TYPE=checkbox NAME=body Value="True" checked> <font color="[dark_color]"><B>Contenuto</B></font>
</TR>

</TABLE>

<DL>
<DT><b>Campo di ricerca esteso</b>
<SELECT NAME="directories" MULTIPLE SIZE=4>    
<DD>

[FOREACH u IN yyyymm]

<OPTION VALUE="[u]">[u]

[END] 

</SELECT></DL>

</FORM>
