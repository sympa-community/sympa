<!-- RCS Identication ; $Revision$ ; $Date$ -->

<FORM METHOD=POST ACTION="[path_cgi]">

<INPUT NAME=list TYPE=hidden VALUE="[list]">
<INPUT NAME=archive_name TYPE=hidden VALUE="[archive_name]">

<center>
<TABLE width=100%>
<TR><td bgcolor="[light_color]" align=center>
<font size=+1>Hakukenttä : </font><A HREF=[path_cgi]/arc/[list]/[archive_name]><font size=+2 color="[dark_color]"><b>[archive_name]</b></font></A>
</TD><TD bgcolor="[light_color]" align=center>
<INPUT NAME=key_word     TYPE=text   SIZE=30 VALUE="[key_word]">
<INPUT NAME="action"  TYPE="hidden" Value="arcsearch">
<INPUT NAME=action_arcsearch TYPE=submit VALUE="Etsi">
</TD></TR></TABLE>
 </center>
<P>

<TABLE CELLSPACING=0	CELLPADDING=0>

<TR VALIGN="TOP" NOWRAP>
<TD><b>Search</b></TD>
<TD><INPUT TYPE=RADIO NAME=how VALUE="phrase" CHECKED> tämä <font color="[dark_color]"><B>lause</b></font></TD>
<TD><INPUT TYPE=RADIO NAME=how VALUE="all"> <font color="[dark_color]"><b>kaikki</b></font> sanoista</TD>
<TD><INPUT TYPE=RADIO NAME=how VALUE="any"> <font color="[dark_color]"><B>yksi</b></font> sanoista</TD>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD><b>Hakujärjestys</b></TD>
<TD><INPUT TYPE=RADIO NAME=age VALUE="new" CHECKED> <font color="[dark_color]"><b>uusimmat</b></font> viestit</TD>
<TD><INPUT TYPE=RADIO NAME=age VALUE="old"> <font color="[dark_color]"><b>vanhimmat</b></font> viestit</TD>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD><b>Isot/pienet kirjaimet </b></TD>
<TD><INPUT TYPE=RADIO NAME=case VALUE="off" CHECKED> <font color="[dark_color]"><B>EI ota huomioon</b></font></TD>
<TD><INPUT TYPE=RADIO NAME=case VALUE="on"> <font color="[dark_color]"><B>OTTAA huomioon</B></font></TD>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD><b>Tarkistus</b></TD>
<TD><INPUT TYPE=RADIO NAME=match VALUE="partial" CHECKED> <font color="[dark_color]"><B>osa</b></font> sanasta</TD>
<TD><INPUT TYPE=RADIO NAME=match VALUE="exact"> <font color="[dark_color]"><B>koko</b></font> sana</TD>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD><b>Ulkoasu</b></TD>
<TD><INPUT TYPE=RADIO NAME=limit VALUE="10" CHECKED> <font color="[dark_color]"><B>10</b></font> tulosta sivulla
</TD>
<TD><INPUT TYPE=RADIO NAME=limit VALUE="25"> <font color="[dark_color]"><B>25</b></font> tulosta sivulla</TD>
<TD><INPUT TYPE=RADIO NAME=limit VALUE="50"> <font color="[dark_color]"><B>50</b></font> tulosta sivulla</TD>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD><b>Hakualue</b></TD>
<TD><INPUT TYPE=checkbox NAME=from Value="True"> <font color="[dark_color]"><B>Lähettäjä</B></font>

<TD><INPUT TYPE=checkbox NAME=subj Value="True"> <font color="[dark_color]"> <B>Otsikko</B></font>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD>&#160;</TD>
<TD><INPUT TYPE=checkbox NAME=date Value="True"> <font color="[dark_color]"><B>Pvm</B></font>

<TD><INPUT TYPE=checkbox NAME=body Value="True" checked> <font color="[dark_color]"><B>Sisältö</B></font>
</TR>

</TABLE>

<DL>
<DT><b>Jatkettu hakukenttä</b>
<SELECT NAME="directories" MULTIPLE SIZE=4>    

[FOREACH u IN yyyymm]

<OPTION VALUE="[u]">[u]

[END] 

</SELECT></DL>

</FORM>
