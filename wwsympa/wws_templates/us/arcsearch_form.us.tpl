<!-- RCS Identication ; $Revision$ ; $Date$ -->

<FORM METHOD=POST ACTION="[path_cgi]">

<INPUT NAME=list TYPE=hidden VALUE="[list]">
<INPUT NAME=archive_name TYPE=hidden VALUE="[archive_name]">

<center>
<TABLE width=100%>
<TR><td bgcolor="--LIGHT_COLOR--" align=center>
<font size=+1>Search field : </font><A HREF=[path_cgi]/arc/[list]/[archive_name]><font size=+2 color="--DARK_COLOR--"><b>[archive_name]</b></font></A>
</TD><TD bgcolor="--LIGHT_COLOR--" align=center>
<INPUT NAME=key_word     TYPE=text   SIZE=30 VALUE="[key_word]">
<INPUT NAME="action"  TYPE="hidden" Value="arcsearch">
<INPUT NAME=action_arcsearch TYPE=submit VALUE="Search">
</TD></TR></TABLE>
 </center>
<P>

<TABLE CELLSPACING=0	CELLPADDING=0>

<TR VALIGN="TOP" NOWRAP>
<TD><b>Search</b></TD>
<TD><INPUT TYPE=RADIO NAME=how VALUE="phrase" CHECKED> this <font color="--DARK_COLOR--"><B>sentence</b></font></TD>
<TD><INPUT TYPE=RADIO NAME=how VALUE="all"> <font color="--DARK_COLOR--"><b>all of</b></font> this words</TD>
<TD><INPUT TYPE=RADIO NAME=how VALUE="any"> <font color="--DARK_COLOR--"><B>one of</b></font> this words</TD>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD><b>Prefer</b></TD>
<TD><INPUT TYPE=RADIO NAME=age VALUE="new" CHECKED> <font color="--DARK_COLOR--"><b>newest</b></font> messages</TD>
<TD><INPUT TYPE=RADIO NAME=age VALUE="old"> <font color="--DARK_COLOR--"><b>oldest</b></font> messages</TD>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD><b>Case </b></TD>
<TD><INPUT TYPE=RADIO NAME=case VALUE="off" CHECKED> <font color="--DARK_COLOR--"><B>insensitive</b></font></TD>
<TD><INPUT TYPE=RADIO NAME=case VALUE="on"> <font color="--DARK_COLOR--"><B>sensitive</B></font></TD>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD><b>Check</b></TD>
<TD><INPUT TYPE=RADIO NAME=match VALUE="partial" CHECKED> <font color="--DARK_COLOR--"><B>part</b></font> of word</TD>
<TD><INPUT TYPE=RADIO NAME=match VALUE="exact"> <font color="--DARK_COLOR--"><B>entire</b></font> word</TD>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD><b>Layout</b></TD>
<TD><INPUT TYPE=RADIO NAME=limit VALUE="10" CHECKED> <font color="--DARK_COLOR--"><B>10</b></font> results by page
</TD>
<TD><INPUT TYPE=RADIO NAME=limit VALUE="25"> <font color="--DARK_COLOR--"><B>25</b></font> results by page</TD>
<TD><INPUT TYPE=RADIO NAME=limit VALUE="50"> <font color="--DARK_COLOR--"><B>50</b></font> results by page</TD>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD><b>Search area</b></TD>
<TD><INPUT TYPE=checkbox NAME=from Value="True"> <font color="--DARK_COLOR--"><B>Sender</B></font>

<TD><INPUT TYPE=checkbox NAME=subj Value="True"> <font color="--DARK_COLOR--"> <B>Subject</B></font>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD>&#160;</TD>
<TD><INPUT TYPE=checkbox NAME=date Value="True"> <font color="--DARK_COLOR--"><B>Date</B></font>

<TD><INPUT TYPE=checkbox NAME=body Value="True" checked> <font color="--DARK_COLOR--"><B>Body</B></font>
</TR>

</TABLE>

<DL>
<DT><b>Extend search field</b>
<SELECT NAME="directories" MULTIPLE SIZE=4>    
<DD>

[FOREACH u IN yyyymm]

<OPTION VALUE="[u]">[u]

[END] 

</SELECT></DL>

</FORM>
