<!-- RCS Identication ; $Revision$ ; $Date$ -->

    <TABLE WIDTH="100%" CELLPADDING="1" CELLSPACING="0">
      <TR VALIGN="top">
        <TH BGCOLOR="[dark_color]" COLSPAN="2">
          <TABLE WIDTH="100%" CELLPADDING="0" CELLSPACING="0">
            <TR>
             <TH BGCOLOR="[selected_color]" WIDTH="50%">
              <FONT COLOR="[bg_color]">
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
         
            <FONT COLOR="[dark_color]">Email  </FONT> [user->email]<BR><BR>
            <FONT COLOR="[dark_color]">Name</FONT>
            <INPUT TYPE="text" NAME="gecos" SIZE=20 VALUE="[user->gecos]"><BR><BR>
            <FONT COLOR="[dark_color]">Language </FONT>
            <SELECT NAME="lang">
              [FOREACH l IN languages]
                <OPTION VALUE='[l->NAME]' [l->selected]>[l->complete]
              [END]
            </SELECT>
            <BR><BR>
            <FONT COLOR="[dark_color]">Connexion expiration period </FONT>
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

      [IF auth=classic]
      <TR VALIGN="top">
        <TH BGCOLOR="[dark_color]" COLSPAN="2">
          <TABLE WIDTH="100%" CELLPADDING="0" CELLSPACING="0">
            <TR>
             <TH WIDTH="50%" BGCOLOR="[selected_color]">
              <FONT COLOR="[bg_color]">
                Changing your email address
              </FONT>
             </TH><TH WIDTH="50%" BGCOLOR="[selected_color]">
              <FONT COLOR="[bg_color]">
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
        
            <BR><BR><FONT COLOR="[dark_color]">New email address : </FONT>
            <BR>&nbsp;&nbsp;&nbsp;<INPUT NAME="email" SIZE=15>
            <BR><BR><INPUT TYPE="submit" NAME="action_change_email" VALUE="Submit">
            </FORM>
        </TD>
        <TD>
          <FORM ACTION="[path_cgi]" METHOD=POST>
            <BR><BR><FONT COLOR="[dark_color]">New password : </FONT>
            <BR>&nbsp;&nbsp;&nbsp;<INPUT TYPE="password" NAME="newpasswd1" SIZE=15>
            <BR><FONT COLOR="[dark_color]">Re-enter your new password : </FONT>
            <BR>&nbsp;&nbsp;&nbsp;<INPUT TYPE="password" NAME="newpasswd2" SIZE=15>
            <BR><BR><INPUT TYPE="submit" NAME="action_setpasswd" VALUE="Submit">
            </FORM>
	    [ENDIF]

        </TD>
	<TR VALIGN="top">
        <TH BGCOLOR="[dark_color]" COLSPAN="2">
          <TABLE WIDTH="100%" CELLPADDING="0" CELLSPACING="0">
            <TR>
             <TH WIDTH="50%" BGCOLOR="[selected_color]">
              <FONT COLOR="[bg_color]">
                Your other email addresses
              </FONT>
             </TH>
            </TR>
           </TABLE>
         </TH>
      </TR>
      [IF !unique]
      <TR VALIGN="top">
      <TD>  
            <FORM ACTION="[path_cgi]" METHOD=POST> 
   	    [FOREACH email IN alt_emails]
	    <A HREF="[path_cgi]/change_identity/[email->NAME]/pref">[email->NAME]</A>
	    <INPUT NAME="email" TYPE=hidden VALUE="[email->NAME]">
	    <BR>
	    [END]
	    </FORM>
      </TD>
      </TR> 
      [ENDIF]
      <TR VALIGN="top">
      <TD>
	    <FORM ACTION="[path_cgi]" METHOD=POST> 
	    <BR>
	    <FONT COLOR="[dark_color]">Other email address : </FONT>
	    &nbsp;&nbsp;&nbsp;<INPUT NAME="new_alternative_email" SIZE=15>
	    &nbsp;&nbsp;&nbsp;<FONT COLOR="[dark_color]">Password : </FONT>
	    &nbsp;&nbsp;&nbsp;<INPUT TYPE = "password" NAME="new_password" SIZE=8>
            &nbsp;&nbsp;&nbsp &nbsp; <INPUT TYPE="submit" NAME="action_record_email" VALUE="Submit">
            </FORM>
      </TD>
      <TD VALIGN="middle">
      This other email address, that should be known by Sympa, will be recognized by Sympa as 
	an alternate email address. You will also be able to unify your subscriptions with
	your main email address.  
      </TD>
      </TR>
      </TABLE>
