<!-- RCS Identication ; $Revision$ ; $Date$ -->


    <TABLE WIDTH="100%" CELLPADDING="1" CELLSPACING="0">
      <TR VALIGN="top">
        <TH BGCOLOR="[dark_color]" COLSPAN="2">
          <TABLE WIDTH="100%" CELLPADDING="0" CELLSPACING="0">
            <TR>
             <TH BGCOLOR="[selected_color]" WIDTH="50%">
	      <FONT COLOR="[bg_color]">
	        Beállításaid
	      </FONT>
	     </TH>
            </TR>
           </TABLE>
         </TH>
      </TR>
      <TR VALIGN="top">
	<TD>
	  <FORM ACTION="[path_cgi]" METHOD=POST>
	    <INPUT TYPE="hidden" NAME="previous_action" VALUE="[previous_action]">
	    <INPUT TYPE="hidden" NAME="previous_list" VALUE="[previous_list]">
  	    <FONT COLOR="[dark_color]">Email: </FONT> [user->email]<BR><BR>
	    <FONT COLOR="[dark_color]">Név: </FONT> 
	    <INPUT TYPE="text" NAME="gecos" SIZE=20 VALUE="[user->gecos]"><BR><BR> 
	    <FONT COLOR="[dark_color]">Nyelv: </FONT>
	    <SELECT NAME="lang">
	      [FOREACH l IN languages]
	        <OPTION VALUE="[l->NAME]" [l->selected]>[l->complete]
	      [END]
	    </SELECT>
	    <BR><BR>
	    <FONT COLOR="[dark_color]">Kapcsolat lejár </FONT>
	    <SELECT NAME="cookie_delay">
	      [FOREACH period IN cookie_periods]
	        <OPTION VALUE="[period->value]" [period->selected]>[period->desc]
	      [END]  
	    </SELECT>
	    <BR><BR>
	    <INPUT TYPE="submit" NAME="action_setpref" VALUE="Mentés"></FONT>
	  </FORM>
	</TD>
      </TR>
      <TR VALIGN="top">
        <TH BGCOLOR="[dark_color]" COLSPAN="2">
          <TABLE WIDTH="100%" CELLPADDING="0" CELLSPACING="0">
            <TR>
	     <TH WIDTH="50%" BGCOLOR="[selected_color]">
	      <FONT COLOR="[bg_color]">
	        Email cím megváltoztatása
	      </FONT>
	     </TH><TH WIDTH="50%" BGCOLOR="[selected_color]">
	      <FONT COLOR="[bg_color]">
	        Jelszó megváltoztatása
	      </FONT>
	     </TH>
            </TR>
           </TABLE>
         </TH>
      </TR>
      <TR VALIGN="top">
        <TD>
   	    <FORM ACTION="[path_cgi]" METHOD=POST>
	    <INPUT TYPE="hidden" NAME="previous_action" VALUE="[previous_action]">
	    <INPUT TYPE="hidden" NAME="previous_list" VALUE="[previous_list]">
	    <BR><BR><BR><FONT COLOR="[dark_color]">Új cím: </FONT>
	    <BR>&nbsp;&nbsp;&nbsp;<INPUT NAME="email" SIZE=15>
	    <BR><BR><BR><INPUT TYPE="submit" NAME="action_change_email" VALUE="Mentés">
	    </FORM>
	</TD>
	<TD>
	  <FORM ACTION="[path_cgi]" METHOD=POST>
	    <INPUT TYPE="hidden" NAME="previous_action" VALUE="[previous_action]">
	    <INPUT TYPE="hidden" NAME="previous_list" VALUE="[previous_list]">
	    <BR><BR><BR><FONT COLOR="[dark_color]">Új jelszó: </FONT>
	    <BR>&nbsp;&nbsp;&nbsp;<INPUT TYPE="password" NAME="newpasswd1" SIZE=15>
	    <BR><FONT COLOR="[dark_color]">Új jelszó még egyszer: </FONT>
	    <BR>&nbsp;&nbsp;&nbsp;<INPUT TYPE="password" NAME="newpasswd2" SIZE=15>
	    <BR><BR><BR><INPUT TYPE="submit" NAME="action_setpasswd" VALUE="Mentés">
	    </FORM>
	</TD>
      </TR>


    </TABLE>
