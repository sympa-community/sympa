<!-- RCS Identication ; $Revision$ ; $Date$ -->

<FORM METHOD=POST ACTION="[path_cgi]">

<INPUT NAME=list TYPE=hidden VALUE="[list]">
<INPUT NAME=archive_name TYPE=hidden VALUE="[archive_name]">

<center>
<TABLE width=100%>
<TR><td bgcolor="--LIGHT_COLOR--" align=center>
<font size=+1>Suchfeld: </font><A HREF=[path_cgi]/arc/[list]/[archive_name]><font size=+2 color="--DARK_COLOR--"><b>[archive_name]</b></font></A>
</TD><TD bgcolor="--LIGHT_COLOR--" align=center>
<INPUT NAME=key_word     TYPE=text   SIZE=30 VALUE="[key_word]">
<INPUT NAME="action"  TYPE="hidden" Value="arcsearch">
<INPUT NAME=action_arcsearch TYPE=submit VALUE="Suchen">
</TD></TR></TABLE>
 </center>
<P>

<TABLE CELLSPACING=0	CELLPADDING=0>

<TR VALIGN="TOP" NOWRAP>
<TD><b>Search</b></TD>
<TD><INPUT TYPE=RADIO NAME=how VALUE="phrase" CHECKED> diese <font color="--DARK_COLOR--"><B>Phrase</b></font></TD>
<TD><INPUT TYPE=RADIO NAME=how VALUE="all"> <font color="--DARK_COLOR--"><b>jedes</b></font> dieser W&ouml;rter</TD>
<TD><INPUT TYPE=RADIO NAME=how VALUE="any"> <font color="--DARK_COLOR--"><B>eines</b></font> dieser W&ouml;rter</TD>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD><b>Ordnen</b></TD>
<TD><INPUT TYPE=RADIO NAME=age VALUE="new" CHECKED> <font color="--DARK_COLOR--"><b>neuste</b></font> Nachrichten</TD>
<TD><INPUT TYPE=RADIO NAME=age VALUE="old"> <font color="--DARK_COLOR--"><b>&auml;lteste</b></font> Nachrichten</TD>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD><b>GROSS/klein </b></TD>
<TD><INPUT TYPE=RADIO NAME=case VALUE="off" CHECKED> <font color="--DARK_COLOR--"><B>egal</b></font></TD>
<TD><INPUT TYPE=RADIO NAME=case VALUE="on"> <font color="--DARK_COLOR--"><B>wichtig</B></font></TD>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD><b>Vergleiche</b></TD>
<TD><INPUT TYPE=RADIO NAME=match VALUE="partial" CHECKED> <font color="--DARK_COLOR--"><B>Teil</b></font>worte</TD>
<TD><INPUT TYPE=RADIO NAME=match VALUE="exact"> <font color="--DARK_COLOR--"><B>ganze</b></font> Worte</TD>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD><b>Ausgabe</b></TD>
<TD><INPUT TYPE=RADIO NAME=limit VALUE="10" CHECKED> <font color="--DARK_COLOR--"><B>10</b></font> Treffer pro Seite
</TD>
<TD><INPUT TYPE=RADIO NAME=limit VALUE="25"> <font color="--DARK_COLOR--"><B>25</b></font> Treffer pro Seite</TD>
<TD><INPUT TYPE=RADIO NAME=limit VALUE="50"> <font color="--DARK_COLOR--"><B>50</b></font> Treffer pro Seite</TD>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD><b>Suchfelder</b></TD>
<TD><INPUT TYPE=checkbox NAME=from Value="True"> <font color="--DARK_COLOR--"><B>Absender</B></font>

<TD><INPUT TYPE=checkbox NAME=subj Value="True"> <font color="--DARK_COLOR--"> <B>&Uuml;berschrift</B></font>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD>&#160;</TD>
<TD><INPUT TYPE=checkbox NAME=date Value="True"> <font color="--DARK_COLOR--"><B>Datum</B></font>

<TD><INPUT TYPE=checkbox NAME=body Value="True" checked> <font color="--DARK_COLOR--"><B>Ganze Nachricht</B></font>
</TR>

</TABLE>

<DL>
<DT><b>Suchzeitraum</b>
<SELECT NAME="directories" MULTIPLE SIZE=4>    
<DD>

[FOREACH u IN yyyymm]

<OPTION VALUE="[u]">[u]

[END] 

</SELECT></DL>

</FORM>
