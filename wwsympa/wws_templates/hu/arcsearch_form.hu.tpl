<!-- RCS Identication ; $Revision$ ; $Date$ -->

<FORM METHOD=POST ACTION="[path_cgi]">

<INPUT NAME=list TYPE=hidden VALUE="[list]">
<INPUT NAME=archive_name TYPE=hidden VALUE="[archive_name]">

<center>
<TABLE width=100%>
<TR><td bgcolor="[light_color]" align=center>
<font size=+1>Keresési tartomány: </font><A HREF=[path_cgi]/arc/[list]/[archive_name]><font size=+2 color="[dark_color]"><b>[archive_name]</b></font></A>
</TD><TD bgcolor="[light_color]" align=center>
<INPUT NAME=key_word     TYPE=text   SIZE=30 VALUE="[key_word]">
<INPUT NAME="action"  TYPE="hidden" Value="arcsearch">
<INPUT NAME=action_arcsearch TYPE=submit VALUE="Keresés">
</TD></TR></TABLE>
 </center>
<P>

<TABLE CELLSPACING=0	CELLPADDING=0>

<TR VALIGN="TOP" NOWRAP>
<TD><b>Keresés</b></TD>
<TD><INPUT TYPE=RADIO NAME=how VALUE="phrase" CHECKED> egész <font color="[dark_color]"><B>mondatot</b></font></TD>
<TD><INPUT TYPE=RADIO NAME=how VALUE="all"> <font color="[dark_color]"><b>minden</b></font> szót</TD>
<TD><INPUT TYPE=RADIO NAME=how VALUE="any"> <font color="[dark_color]"><B>bármelyik</b></font> szót</TD>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD><b>Találatok megjelenítése</b></TD>
<TD><INPUT TYPE=RADIO NAME=age VALUE="new" CHECKED> <font color="[dark_color]"><b>újabbak</b></font> elõl</TD>
<TD><INPUT TYPE=RADIO NAME=age VALUE="old"> <font color="[dark_color]"><b>régebbiek</b></font> elõl</TD>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD><b>Kis- és nagybetûk </b></TD>
<TD><INPUT TYPE=RADIO NAME=case VALUE="off" CHECKED> <font color="[dark_color]"><B>nem számítanak</b></font></TD>
<TD><INPUT TYPE=RADIO NAME=case VALUE="on"> <font color="[dark_color]"><B>számítanak</B></font></TD>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD><b>Egyezés</b></TD>
<TD><INPUT TYPE=RADIO NAME=match VALUE="partial" CHECKED>a szó <font color="[dark_color]"><B>része</b></font></TD>
<TD><INPUT TYPE=RADIO NAME=match VALUE="exact"> <font color="[dark_color]"><B>teljesen egyezik</b></font> a szóval</TD>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD><b>Találatok felsorolása</b></TD>
<TD><INPUT TYPE=RADIO NAME=limit VALUE="10" CHECKED> <font color="[dark_color]"><B>10</b></font> találat oldalanként
</TD>
<TD><INPUT TYPE=RADIO NAME=limit VALUE="25"> <font color="[dark_color]"><B>25</b></font> találat oldalanként</TD>
<TD><INPUT TYPE=RADIO NAME=limit VALUE="50"> <font color="[dark_color]"><B>50</b></font> találat oldalanként</TD>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD><b>A levél melyik részében keressen?</b></TD>
<TD><INPUT TYPE=checkbox NAME=from Value="True"> <font color="[dark_color]"><B>Feladó</B></font>

<TD><INPUT TYPE=checkbox NAME=subj Value="True"> <font color="[dark_color]"> <B>Tárgy</B></font>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD>&#160;</TD>
<TD><INPUT TYPE=checkbox NAME=date Value="True"> <font color="[dark_color]"><B>Dátum</B></font>

<TD><INPUT TYPE=checkbox NAME=body Value="True" checked> <font color="[dark_color]"><B>Törzs</B></font>
</TR>

</TABLE>

<DL>
<DT><b>Bõvített keresési tartomány</b>
<SELECT NAME="directories" MULTIPLE SIZE=4>    
<DD>

[FOREACH u IN yyyymm]

<OPTION VALUE="[u]">[u]

[END] 

</SELECT></DL>

</FORM>
