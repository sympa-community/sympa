<!-- RCS Identication ; $Revision$ ; $Date$ -->

    <P><BR>
    <TABLE BORDER=0 WIDTH=100%>

    <TR><TD ALIGN="left">
	<FORM METHOD=POST ACTION="[path_cgi]">

	<INPUT NAME=list TYPE=hidden VALUE="[list]">
	<INPUT NAME=archive_name TYPE=hidden VALUE="[archive_name]">
	<INPUT NAME=how   TYPE=hidden VALUE="phrase">
	<INPUT NAME=age   TYPE=hidden VALUE="new">
	<INPUT NAME=case  TYPE=hidden VALUE="off"> 
	<INPUT NAME=match TYPE=hidden VALUE="partial">
	<INPUT NAME=limit TYPE=hidden VALUE="10"> 
	<INPUT NAME=body  TYPE=hidden Value="True">
	<INPUT NAME=key_word     TYPE=text   SIZE=17>
	<INPUT NAME="action"  TYPE="hidden" Value="arcsearch">
	<INPUT TYPE="submit" NAME="action_arcsearch" VALUE="Search"><BR>
	<A HREF="[path_cgi]/arcsearch_form/[list]/[archive_name]">Advanced search</A>

	</FORM>

    </TD>


    <TD ALIGN=right>
    <TABLE BORDER=0>
   
    [FOREACH year IN calendar]

      <TR BGCOLOR="[light_color]">
        <TD BGCOLOR="[bg_color]"><FONT SIZE="-1"><B>[year->NAME]</B></FONT> </TD>

        <TD>
        [IF year->01]
	   <A HREF="[path_cgi]/arc/[list]/[year->NAME]-01/"><FONT SIZE="-1"><b>01</b></FONT></A>
        [ELSE]
	  <FONT SIZE="-1" COLOR="[bg_color]">01</FONT>
        [ENDIF]
	</TD>

        <TD>
        [IF year->02]
	  <A HREF="[path_cgi]/arc/[list]/[year->NAME]-02/"><FONT SIZE="-1"><b>02</b></FONT></A>
        [ELSE]
 	  <FONT SIZE="-1" COLOR="[bg_color]">02</FONT>
        [ENDIF]
	</TD>

        <TD>
        [IF year->03]
	  <A HREF="[path_cgi]/arc/[list]/[year->NAME]-03/"><FONT SIZE="-1"><b>03</b></FONT></A>
        [ELSE]
 	  <FONT SIZE="-1" COLOR="[bg_color]">03</FONT>
        [ENDIF]
	</TD>

        <TD>
        [IF year->04]
	  <A HREF="[path_cgi]/arc/[list]/[year->NAME]-04/"><FONT SIZE="-1"><b>04</b></FONT></A>
        [ELSE]
 	  <FONT SIZE="-1" COLOR="[bg_color]">04</FONT>
         [ENDIF]
	</TD>
        <TD>

        [IF year->05]
	  <A HREF="[path_cgi]/arc/[list]/[year->NAME]-05/"><FONT SIZE="-1"><b>05</b></FONT></A>
        [ELSE]
 	  <FONT SIZE="-1" COLOR="[bg_color]">05</FONT>
        [ENDIF]
	</TD>

        <TD>
        [IF year->06]
	  <A HREF="[path_cgi]/arc/[list]/[year->NAME]-06/"><FONT SIZE="-1"><b>06</b></FONT></A>
        [ELSE]
 	  <FONT SIZE="-1" COLOR="[bg_color]">06</FONT>
        [ENDIF]
	</TD>

        <TD>
        [IF year->07]
	  <A HREF="[path_cgi]/arc/[list]/[year->NAME]-07/"><FONT SIZE="-1"><b>07</b></FONT></A>
        [ELSE]
 	  <FONT SIZE="-1" COLOR="[bg_color]">07</FONT>
        [ENDIF]
	</TD>

        <TD>
        [IF year->08]
	  <A HREF="[path_cgi]/arc/[list]/[year->NAME]-08/"><FONT SIZE="-1"><b>08</b></FONT></A>
        [ELSE]
 	  <FONT SIZE="-1" COLOR="[bg_color]">08</FONT>
        [ENDIF]
	</TD>
        <TD>

        [IF year->09]
	  <A HREF="[path_cgi]/arc/[list]/[year->NAME]-09/"><FONT SIZE="-1"><b>09</b></FONT></A>
        [ELSE]
 	  <FONT SIZE="-1" COLOR="[bg_color]">09</FONT>
        [ENDIF]
	</TD>

        <TD>
        [IF year->10]
	  <A HREF="[path_cgi]/arc/[list]/[year->NAME]-10/"><FONT SIZE="-1"><b>10</b></FONT></A>
        [ELSE]
 	  <FONT SIZE="-1" COLOR="[bg_color]">10</FONT>
        [ENDIF]
	</TD>

        <TD>
        [IF year->11]
	  <A HREF="[path_cgi]/arc/[list]/[year->NAME]-11/"><FONT SIZE="-1"><b>11</b></FONT></A>
        [ELSE]
 	  <FONT SIZE="-1" COLOR="[bg_color]">11</FONT>
        [ENDIF]
	</TD>

        <TD>
        [IF year->12]
	  <A HREF="[path_cgi]/arc/[list]/[year->NAME]-12/"><FONT SIZE="-1"><b>12</b></FONT></A>
        [ELSE]
 	  <FONT SIZE="-1" COLOR="[bg_color]">12</FONT>
        [ENDIF]
	</TD>


      </TR>

    [END]    
    </TABLE>
    </TD></TR>
    </TABLE>


    [PARSE file]
