<!-- RCS Identication ; $Revision$ ; $Date$ -->

<FORM METHOD=POST ACTION="[path_cgi]">

<INPUT NAME=list TYPE=hidden VALUE="[list]">
<INPUT NAME=archive_name TYPE=hidden VALUE="[archive_name]">

<center>
<TABLE width=100%>
<TR><td bgcolor="[light_color]" align=center>
<font size=+1>Suchfeld: </font><A HREF=[path_cgi]/arc/[list]/[archive_name]><font size=+2 color="[dark_color]"><b>[archive_name]</b></font></A>
</TD><TD bgcolor="[light_color]" align=center>
<INPUT NAME=key_word     TYPE=text   SIZE=30 VALUE="[key_word]">
<INPUT NAME="action"  TYPE="hidden" Value="arcsearch">
<INPUT NAME=action_arcsearch TYPE=submit VALUE="Suchen">
</TD></TR></TABLE>
 </center>
<P>

<TABLE CELLSPACING=0	CELLPADDING=0>

<TR VALIGN="TOP" NOWRAP>
<TD><b>Search</b></TD>
<TD><INPUT TYPE=RADIO NAME=how VALUE="phrase" CHECKED> diese <font color="[dark_color]"><B>Phrase</b></font></TD>
<TD><INPUT TYPE=RADIO NAME=how VALUE="all"> <font color="[dark_color]"><b>jedes</b></font> dieser W&ouml;rter</TD>
<TD><INPUT TYPE=RADIO NAME=how VALUE="any"> <font color="[dark_color]"><B>eines</b></font> dieser W&ouml;rter</TD>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD><b>Ordnen</b></TD>
<TD><INPUT TYPE=RADIO NAME=age VALUE="new" CHECKED> <font color="[dark_color]"><b>neuste</b></font> Nachrichten</TD>
<TD><INPUT TYPE=RADIO NAME=age VALUE="old"> <font color="[dark_color]"><b>&auml;lteste</b></font> Nachrichten</TD>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD><b>GROSS/klein </b></TD>
<TD><INPUT TYPE=RADIO NAME=case VALUE="off" CHECKED> <font color="[dark_color]"><B>egal</b></font></TD>
<TD><INPUT TYPE=RADIO NAME=case VALUE="on"> <font color="[dark_color]"><B>wichtig</B></font></TD>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD><b>Vergleiche</b></TD>
<TD><INPUT TYPE=RADIO NAME=match VALUE="partial" CHECKED> <font color="[dark_color]"><B>Teil</b></font>worte</TD>
<TD><INPUT TYPE=RADIO NAME=match VALUE="exact"> <font color="[dark_color]"><B>ganze</b></font> Worte</TD>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD><b>Ausgabe</b></TD>
<TD><INPUT TYPE=RADIO NAME=limit VALUE="10" CHECKED> <font color="[dark_color]"><B>10</b></font> Treffer pro Seite
</TD>
<TD><INPUT TYPE=RADIO NAME=limit VALUE="25"> <font color="[dark_color]"><B>25</b></font> Treffer pro Seite</TD>
<TD><INPUT TYPE=RADIO NAME=limit VALUE="50"> <font color="[dark_color]"><B>50</b></font> Treffer pro Seite</TD>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD><b>Suchfelder</b></TD>
<TD><INPUT TYPE=checkbox NAME=from Value="True"> <font color="[dark_color]"><B>Absender</B></font>

<TD><INPUT TYPE=checkbox NAME=subj Value="True"> <font color="[dark_color]"> <B>&Uuml;berschrift</B></font>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD>&#160;</TD>
<TD><INPUT TYPE=checkbox NAME=date Value="True"> <font color="[dark_color]"><B>Datum</B></font>

<TD><INPUT TYPE=checkbox NAME=body Value="True" checked> <font color="[dark_color]"><B>Ganze Nachricht</B></font>
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
