<FORM METHOD=POST ACTION="[path_cgi]">

<INPUT NAME=list TYPE=hidden VALUE="[list]">
<INPUT NAME=archive_name TYPE=hidden VALUE="[archive_name]">

<center>
<TABLE width=100%>
<TR><td bgcolor="#ccccff" align=center>
<font size=+1>查找域: </font><A HREF=[path_cgi]/arc/[list]/[archive_name]><font size=+2 color="#330099"><b>[archive_name]</b></font></A>
</TD><TD bgcolor="#ccccff" align=center>
<INPUT NAME=key_word     TYPE=text   SIZE=30 VALUE="[key_word]">
<INPUT NAME="action"  TYPE="hidden" Value="arcsearch">
<INPUT NAME=action_arcsearch TYPE=submit VALUE="查找">
</TD></TR></TABLE>
 </center>
<P>

<TABLE CELLSPACING=0	CELLPADDING=0>

<TR VALIGN="TOP" NOWRAP>
<TD><b>查找</b></TD>
<TD><INPUT TYPE=RADIO NAME=how VALUE="phrase" CHECKED> 这<font color="#330099"><B>一句</b></font></TD>
<TD><INPUT TYPE=RADIO NAME=how VALUE="all"> <font color="#330099"><b>全部</b></font>词</TD>
<TD><INPUT TYPE=RADIO NAME=how VALUE="any"> <font color="#330099"><B>任一</b></font>词</TD>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD><b>优先</b></TD>
<TD><INPUT TYPE=RADIO NAME=age VALUE="new" CHECKED> <font color="#330099"><b>最新的</b></font>邮件</TD>
<TD><INPUT TYPE=RADIO NAME=age VALUE="old"> <font color="#330099"><b>最旧的</b></font>邮件</TD>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD><b>大小写</b></TD>
<TD><INPUT TYPE=RADIO NAME=case VALUE="off" CHECKED> <font color="#330099"><B>不区分</b></font></TD>
<TD><INPUT TYPE=RADIO NAME=case VALUE="on"> <font color="#330099"><B>区分</B></font></TD>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD><b>检查</b></TD>
<TD><INPUT TYPE=RADIO NAME=match VALUE="partial" CHECKED> <font color="#330099">单词的<B>部分</b></font></TD>
<TD><INPUT TYPE=RADIO NAME=match VALUE="exact"> <font color="#330099"><B>整个</b></font>单词</TD>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD><b>布局</b></TD>
<TD><INPUT TYPE=RADIO NAME=limit VALUE="10" CHECKED> <font color="#330099">每页<B>10</b></font>个结果</TD>
<TD><INPUT TYPE=RADIO NAME=limit VALUE="25"> <font color="#330099">每页<B>25</b></font>个结果</TD>
<TD><INPUT TYPE=RADIO NAME=limit VALUE="50"> <font color="#330099">每页<B>50</b></font>个结果</TD>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD><b>查找域</b></TD>
<TD><INPUT TYPE=checkbox NAME=from Value="True"> <font color="#330099"><B>发件人</B></font>

<TD><INPUT TYPE=checkbox NAME=subj Value="True"> <font color="#330099"> <B>主题</B></font>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD>&#160;</TD>
<TD><INPUT TYPE=checkbox NAME=date Value="True"> <font color="#330099"><B>Date</B></font>

<TD><INPUT TYPE=checkbox NAME=body Value="True" checked> <font color="#330099"><B>Body</B></font>
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
