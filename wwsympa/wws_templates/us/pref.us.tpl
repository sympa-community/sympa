<!-- RCS Identication ; $Revision$ ; $Date$ -->


    <TABLE WIDTH="100%" CELLPADDING="1" CELLSPACING="0">
      <TR VALIGN="top">
        <TH BGCOLOR="--DARK_COLOR--" COLSPAN="2">
          <TABLE WIDTH="100%" CELLPADDING="0" CELLSPACING="0">
            <TR>
             <TH BGCOLOR="--SELECTED_COLOR--" WIDTH="50%">
	      <FONT COLOR="--BG_COLOR--">
	        Your environment
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
  	    <FONT COLOR="--DARK_COLOR--">Email </FONT> [user->email]<BR><BR>
	    <FONT COLOR="--DARK_COLOR--">Name</FONT> 
	    <INPUT TYPE="text" NAME="gecos" SIZE=20 VALUE="[user->gecos]"><BR><BR> 
	    <FONT COLOR="--DARK_COLOR--">Language </FONT>
	    <SELECT NAME="lang">
	      [FOREACH l IN languages]
	        <OPTION VALUE="[l->NAME]" [l->selected]>[l->complete]
	      [END]
	    </SELECT>
	    <BR><BR>
	    <FONT COLOR="--DARK_COLOR--">Expiration of the connexion </FONT>
	    <SELECT NAME="cookie_delay">
	      [FOREACH period IN cookie_periods]
	        <OPTION VALUE="[period->value]" [period->selected]>[period->desc]
	      [END]
	    </SELECT>
	    <BR><BR>
	    <INPUT TYPE="submit" NAME="action_setpref" VALUE="Submit"></FONT>
	  </FORM>
	</TD>
      </TR>
      <TR VALIGN="top">
        <TH BGCOLOR="--DARK_COLOR--" COLSPAN="2">
          <TABLE WIDTH="100%" CELLPADDING="0" CELLSPACING="0">
            <TR>
	     <TH WIDTH="50%" BGCOLOR="--SELECTED_COLOR--">
	      <FONT COLOR="--BG_COLOR--">
	        Changing your email address
	      </FONT>
	     </TH><TH WIDTH="50%" BGCOLOR="--SELECTED_COLOR--">
	      <FONT COLOR="--BG_COLOR--">
	        Changing your password
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
	    <BR><BR><BR><FONT COLOR="--DARK_COLOR--">New email address : </FONT>
	    <BR>&nbsp;&nbsp;&nbsp;<INPUT NAME="email" SIZE=15>
	    <BR><BR><BR><INPUT TYPE="submit" NAME="action_change_email" VALUE="Submit">
	    </FORM>
	</TD>
	<TD>
	  <FORM ACTION="[path_cgi]" METHOD=POST>
	    <INPUT TYPE="hidden" NAME="previous_action" VALUE="[previous_action]">
	    <INPUT TYPE="hidden" NAME="previous_list" VALUE="[previous_list]">
	    <BR><BR><BR><FONT COLOR="--DARK_COLOR--">New password : </FONT>
	    <BR>&nbsp;&nbsp;&nbsp;<INPUT TYPE="password" NAME="newpasswd1" SIZE=15>
	    <BR><FONT COLOR="--DARK_COLOR--">Re-enter your new password : </FONT>
	    <BR>&nbsp;&nbsp;&nbsp;<INPUT TYPE="password" NAME="newpasswd2" SIZE=15>
	    <BR><BR><BR><INPUT TYPE="submit" NAME="action_setpasswd" VALUE="Submit">
	    </FORM>
	</TD>
      </TR>


    </TABLE>
