<!-- RCS Identication ; $Revision$ ; $Date$ -->

<FORM METHOD=POST ACTION="[path_cgi]">

<INPUT NAME=list TYPE=hidden VALUE="[list]">
<INPUT NAME=archive_name TYPE=hidden VALUE="[archive_name]">

<center>
<TABLE width=100%>
<TR><td bgcolor="--LIGHT_COLOR--" align=center>
<font size=+1>Recherche sur : </font><A HREF=[path_cgi]/arc/[list]/[archive_name]><font size=+2 color="--DARK_COLOR--"><b>[archive_name]</b></font></A>
</TD><TD bgcolor="--LIGHT_COLOR--" align=center>
<INPUT NAME=key_word     TYPE=text   SIZE=30 VALUE="[key_word]">
<INPUT NAME="action"  TYPE="hidden" Value="arcsearch">
<INPUT NAME=action_arcsearch TYPE=submit VALUE="Rechercher">
</TD></TR></TABLE>
 </center>
<P>

<TABLE CELLSPACING=0	CELLPADDING=0>

<TR VALIGN="TOP" NOWRAP>
<TD><b>Rechercher</b></TD>
<TD><INPUT TYPE=RADIO NAME=how VALUE="phrase" CHECKED> cette <font color="--DARK_COLOR--"><B>phrase</b></font></TD>
<TD><INPUT TYPE=RADIO NAME=how VALUE="all"> <font color="--DARK_COLOR--"><b>chacun</b></font> de ces mots</TD>
<TD><INPUT TYPE=RADIO NAME=how VALUE="any"> <font color="--DARK_COLOR--"><B>un</b></font> de ces mots</TD>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD><b>D'abord les messages </b></TD>
<TD><INPUT TYPE=RADIO NAME=age VALUE="new" CHECKED> <font color="--DARK_COLOR--">les plus <b>récents</b></font></TD>
<TD><INPUT TYPE=RADIO NAME=age VALUE="old"> <font color="--DARK_COLOR--">les plus <b>anciens</b></font></TD>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD><b>Majuscules/minuscules </b></TD>
<TD><INPUT TYPE=RADIO NAME=case VALUE="off" CHECKED> <font color="--DARK_COLOR--"><B>indifférenciées</b></font></TD>
<TD><INPUT TYPE=RADIO NAME=case VALUE="on"> <font color="--DARK_COLOR--"><B>différenciées</B></font></TD>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD><b>Vérifier par</b></TD>
<TD><INPUT TYPE=RADIO NAME=match VALUE="partial" CHECKED> <font color="--DARK_COLOR--"><B>partie</b></font> de mot</TD>
<TD><INPUT TYPE=RADIO NAME=match VALUE="exact"> <font color="--DARK_COLOR--"><B>mots</b></font> entier</TD>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD><b>Résultats</b></TD>
<TD><INPUT TYPE=RADIO NAME=limit VALUE="10" CHECKED> <font color="--DARK_COLOR--"><B>10</b></font> résultats par page
</TD>
<TD><INPUT TYPE=RADIO NAME=limit VALUE="25"> <font color="--DARK_COLOR--"><B>25</b></font> résultats par page</TD>
<TD><INPUT TYPE=RADIO NAME=limit VALUE="50"> <font color="--DARK_COLOR--"><B>50</b></font> résultats par page</TD>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD><b>Zone de recherche</b></TD>
<TD><INPUT TYPE=checkbox NAME=from Value="True"> <font color="--DARK_COLOR--"><B>From</B></font>

<TD><INPUT TYPE=checkbox NAME=subj Value="True"> <font color="--DARK_COLOR--"> <B>Subject</B></font>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD>&#160;</TD>
<TD><INPUT TYPE=checkbox NAME=date Value="True"> <font color="--DARK_COLOR--"><B>Date</B></font>

<TD><INPUT TYPE=checkbox NAME=body Value="True" checked> <font color="--DARK_COLOR--"><B>Contenu de message</B></font>
</TR>

</TABLE>

<DL>
<DT><b>Etendue de la recherche</b>
<SELECT NAME="directories" MULTIPLE SIZE=4>    
<DD>

[FOREACH u IN yyyymm]

<OPTION VALUE="[u]">[u]

[END] 

</SELECT></DL>

</FORM>
