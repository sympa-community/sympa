<!-- RCS Identication ; $Revision$ ; $Date$ -->

<TABLE width=100% border="0" VALIGN="top">
<TR><TD>
    <FORM ACTION="[path_cgi]" METHOD=POST> 
      <INPUT TYPE="hidden" NAME="previous_action" VALUE="reviewbouncing">
      <INPUT TYPE=hidden NAME=list VALUE=[list]>
      <INPUT TYPE="hidden" NAME="action" VALUE="search">

      <INPUT SIZE=25 NAME=filter VALUE=[filter]>
      <INPUT TYPE="submit" NAME="action_search" VALUE="Hledat">
    </FORM>
</TD>
<TD>
  <FORM METHOD="post" ACTION="[path_cgi]">
    <INPUT TYPE="button" VALUE="Upomenout v¹echny èleny" NAME="action_remind" onClick="request_confirm(this.form,'Chcete opravdu poslat upomínací zprávu k  [total] èlenùm?')">
    <INPUT TYPE="hidden" NAME="action" VALUE="remind">
    <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
  </FORM>	
</TD>

</TR></TABLE>
    <FORM NAME="myform" ACTION="[path_cgi]" METHOD=POST>
    <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
    <INPUT TYPE="hidden" NAME="previous_action" VALUE="reviewbouncing">

    <TABLE WIDTH=100% BORDER=0>
    <TR><TD ALIGN="left" NOWRAP>
        <BR>
        <INPUT TYPE="submit" NAME="action_del" VALUE="Smazat vybrané u¾ivatele">
        <INPUT TYPE="checkbox" NAME="quiet"> skrytì

	<INPUT TYPE="hidden" NAME="sortby" VALUE="[sortby]">
	<INPUT TYPE="submit" NAME="action_reviewbouncing" VALUE="Velikost strany">
	        <SELECT NAME="size">
                  <OPTION VALUE="[size]" SELECTED>[size]
		  <OPTION VALUE="25">25
		  <OPTION VALUE="50">50
		  <OPTION VALUE="100">100
		   <OPTION VALUE="500">500
		</SELECT>
   </TD>

 <TD ALIGN="right">
        [IF prev_page]
	  <A HREF="[path_cgi]/reviewbouncing/[list]/[prev_page]/[size]"><IMG SRC="[icons_url]/left.png" BORDER=0 ALT="Pøedchozí strana"></A>
        [ENDIF]
        [IF page]
  	  strana [page] z [total_page]
        [ENDIF]
        [IF next_page]
	  <A HREF="[path_cgi]/reviewbouncing/[list]/[next_page]/[size]"><IMG SRC="[icons_url]/right.png" BORDER=0 ALT="dal¹í strana"></A>
        [ENDIF]
    </TD></TR>
    <TR><TD><INPUT TYPE="submit" NAME="action_resetbounce" VALUE="Vynulovat chyby pro vybrané u¾ivatele">
    </TD></TR>
    </TABLE>

    <TABLE WIDTH="100%" BORDER=1>
      <TR BGCOLOR="[error_color]" NOWRAP>
	<TH><FONT COLOR="[bg_color]">X</FONT></TH>
        <TH><FONT COLOR="[bg_color]">email</FONT></TH>
	<TH><FONT COLOR="[bg_color]">poèet vrácených zpráv</FONT></TH>
	<TH><FONT COLOR="[bg_color]">období</FONT></TH>
	<TH NOWRAP><FONT COLOR="[bg_color]">typ</FONT></TH>
      </TR>
      
      [FOREACH u IN members]

	[IF dark=1]
	  <TR BGCOLOR="[shaded_color]">
	[ELSE]
          <TR>
	[ENDIF]

	  <TD>
	    <INPUT TYPE=checkbox name="email" value="[u->escaped_email]">
	  </TD>
	  <TD NOWRAP><FONT SIZE=-1>
	      <A HREF="[path_cgi]/editsubscriber/[list]/[u->escaped_email]/reviewbouncing">[u->email]</A>

	  </FONT></TD>
          <TD ALIGN="center"><FONT SIZE=-1>
  	      [u->bounce_count]
	    </FONT></TD>
	  <TD NOWRAP ALIGN="center"><FONT SIZE=-1>
	    od [u->first_bounce] do [u->last_bounce]
	  </FONT></TD>
	  <TD NOWRAP ALIGN="center"><FONT SIZE=-1>
	    [IF u->bounce_class=2]
	    	úspìch
	    [ELSIF u->bounce_class=4]
		doèasný
	    [ELSIF u->bounce_class=5]
		trvalý
	    [ENDIF]
	  </FONT></TD>
        </TR>

        [IF dark=1]
	  [SET dark=0]
	[ELSE]
	  [SET dark=1]
	[ENDIF]

        [END]


      </TABLE>
    <TABLE WIDTH=100% BORDER=0>
    <TR><TD ALIGN="left" NOWRAP>
      [IF is_owner]
        <BR>
        <INPUT TYPE="submit" NAME="action_del" VALUE="Smazat vybrané u¾ivatele">
        <INPUT TYPE="checkbox" NAME="quiet"> skrytì
	<INPUT TYPE="submit" NAME="action_resetbounce" VALUE="Vynulovat chyby pro vybrané u¾ivatele">
      [ENDIF]
    </TD><TD ALIGN="right" NOWRAP>
        [IF prev_page]
	  <A HREF="[path_cgi]/reviewbouncing/[list]/[prev_page]/[size]"><IMG SRC="[icons_url]/left.png" BORDER=0 ALT="Pøedchozí strana"></A>
        [ENDIF]
        [IF page]
  	  strana [page] z [total_page]
        [ENDIF]
        [IF next_page]
	  <A HREF="[path_cgi]/reviewbouncing/[list]/[next_page]/[size]"><IMG SRC="[icons_url]/right.png" BORDER=0 ALT="Dal¹í strana"></A>
        [ENDIF]
    </TD></TR>
    <TR><TD><input type=button value="Obrátit výbìr" onClick="toggle_selection(document.myform.email)">
    </TD></TR>
    </TABLE>


      </FORM>
