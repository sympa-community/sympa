<!-- RCS Identication ; $Revision$ ; $Date$ -->

<FORM METHOD=POST ACTION="[path_cgi]">

<INPUT NAME=list TYPE=hidden VALUE="[list]">
<INPUT NAME=archive_name TYPE=hidden VALUE="[archive_name]">

<center>
<TABLE width=100%>
<TR><td bgcolor="[light_color]" align=center>
<font size=+1>Search field : </font><A HREF=[path_cgi]/arc/[list]/[archive_name]><font size=+2 color="[dark_color]"><b>[archive_name]</b></font></A>
</TD><TD bgcolor="[light_color]" align=center>
<INPUT NAME=key_word     TYPE=text   SIZE=30 VALUE="[key_word]">
<INPUT NAME="action"  TYPE="hidden" Value="arcsearch">
<INPUT NAME=action_arcsearch TYPE=submit VALUE="Zoek">
</TD></TR></TABLE>
 </center>
<P>

<TABLE CELLSPACING=0	CELLPADDING=0>

<TR VALIGN="TOP" NOWRAP>
<TD><b>Zoeken</b></TD>
<TD><INPUT TYPE=RADIO NAME=how VALUE="tekenreeks" CHECKED> deze <font color="[dark_color]"><B>zin</b></font></TD>
<TD><INPUT TYPE=RADIO NAME=how VALUE="alles"> <font color="[dark_color]"><b>all of</b></font> deze woorden</TD>
<TD><INPUT TYPE=RADIO NAME=how VALUE="iedere"> <font color="[dark_color]"><B>een van deze </b></font> woorden</TD>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD><b>Voorkeur</b></TD>
<TD><INPUT TYPE=RADIO NAME=age VALUE="nieuw" CHECKED> <font color="[dark_color]"><b>nieuwste</b></font> berichten</TD>
<TD><INPUT TYPE=RADIO NAME=age VALUE="oud"> <font color="[dark_color]"><b>oudste</b></font> berichten</TD>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD><b>Hoofd- en kleine letters </b></TD>
<TD><INPUT TYPE=RADIO NAME=case VALUE="uit" CHECKED> <font color="[dark_color]"><B>ongevoelig</b></font></TD>
<TD><INPUT TYPE=RADIO NAME=case VALUE="aan"> <font color="[dark_color]"><B>gevoelig</B></font></TD>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD><b>Controleer</b></TD>
<TD><INPUT TYPE=RADIO NAME=match VALUE="deel" CHECKED> <font color="[dark_color]"><B>part</b></font> van woord</TD>
<TD><INPUT TYPE=RADIO NAME=match VALUE="exact"> <font color="[dark_color]"><B>entire</b></font> woord</TD>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD><b>Layout</b></TD>
<TD><INPUT TYPE=RADIO NAME=limit VALUE="10" CHECKED> <font color="[dark_color]"><B>10</b></font> resultaten per pagina
</TD>
<TD><INPUT TYPE=RADIO NAME=limit VALUE="25"> <font color="[dark_color]"><B>25</b></font> resultaten per pagina</TD>
<TD><INPUT TYPE=RADIO NAME=limit VALUE="50"> <font color="[dark_color]"><B>50</b></font> resultaten per pagina</TD>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD><b>Zoek gebied</b></TD>
<TD><INPUT TYPE=checkbox NAME=from Value="True"> <font color="[dark_color]"><B>Afzender</B></font>

<TD><INPUT TYPE=checkbox NAME=subj Value="True"> <font color="[dark_color]"> <B>Onderwerp</B></font>
</TR>

<P><TR VALIGN="TOP" NOWRAP>
<TD>&#160;</TD>
<TD><INPUT TYPE=checkbox NAME=date Value="True"> <font color="[dark_color]"><B>Datum</B></font>

<TD><INPUT TYPE=checkbox NAME=body Value="True" checked> <font color="[dark_color]"><B>Inhoud</B></font>
</TR>

</TABLE>

<DL>
<DT><b>Uitgebreid zoek veld</b>
<SELECT NAME="directories" MULTIPLE SIZE=4>    

[FOREACH u IN yyyymm]

<OPTION VALUE="[u]">[u]

[END] 

</SELECT></DL>

</FORM>
