<FORM ACTION="[path_cgi]" METHOD="POST"> 
<INPUT TYPE="hidden" NAME="list" VALUE="[list]">

    <TABLE WIDTH="100%" BORDER="1">
      <TR BGCOLOR="--DARK_COLOR--">
        <TH><FONT SIZE="-1" COLOR="--BG_COLOR--"><B>X</B></FONT></TH>
        <TH NOWRAP COLSPAN=2 >
	<FONT COLOR="--BG_COLOR--" SIZE="-1"><b>Email</b></FONT></TH>
        <TH><FONT COLOR="--BG_COLOR--" SIZE="-1"><B>Nom</B></FONT></TH>
        <TH NOWRAP>
	<FONT COLOR="--BG_COLOR--" SIZE="-1"><b>Date</b></FONT></TH>
      </TR>
      
      [IF subscriptions]

      [FOREACH sub IN subscriptions]

	[IF dark=1]
	  <TR BGCOLOR="--SHADED_COLOR--">
	[ELSE]
          <TR>
	[ENDIF]
	    <TD>
           <INPUT TYPE=checkbox name="email" value="[sub->NAME],[sub->gecos]">
	    </TD>
	  <TD COLSPAN=2 NOWRAP><FONT SIZE=-1>
	        [sub->NAME]
	  </FONT></TD>
	  <TD>
             <FONT SIZE=-1>
	        [sub->gecos]&nbsp;
	     </FONT>
          </TD>
	    <TD ALIGN="center"NOWRAP><FONT SIZE=-1>
	      [sub->date]
	    </FONT></TD>
        </TR>

        [IF dark=1]
	  [SET dark=0]
	[ELSE]
	  [SET dark=1]
	[ENDIF]

        [END]

        [ELSE]
         <TR COLSPAN="4"><TH>Aucune demande d'abonnement</TH></TR>
        [ENDIF]
      </TABLE>

<INPUT TYPE="submit" NAME="action_add" VALUE="Abonner les adresses sélectionnées">
<INPUT TYPE="submit" NAME="action_ignoresub" VALUE="Rejeter les adresses sélectionnées">
</FORM>