<!-- RCS Identication ; $Revision$ ; $Date$ -->

    <TABLE WIDTH="100%" CELLPADDING="1" CELLSPACING="0">
      <TR VALIGN="top">
        <TH BGCOLOR="[dark_color]" COLSPAN="2">
          <TABLE WIDTH="100%" CELLPADDING="0" CELLSPACING="0">
            <TR>
             
          <TH BGCOLOR="[selected_color]" WIDTH="50%"> <FONT COLOR="[bg_color]"> 
            Mediul tau</FONT></TH>
            </TR>
           </TABLE>
         </TH>
      </TR>
      <TR VALIGN="top">
        <TD>
          <FORM ACTION="[path_cgi]" METHOD=POST>
         
            <FONT COLOR="[dark_color]">Email  </FONT> [user->email]<BR><BR>
        <FONT COLOR="[dark_color]">Nume</FONT> 
        <INPUT TYPE="text" NAME="gecos" SIZE=20 VALUE="[user->gecos]"><BR><BR>
        <FONT COLOR="[dark_color]">Limba</FONT> 
        <SELECT NAME="lang">
              [FOREACH l IN languages]
                <OPTION VALUE='[l->NAME]' [l->selected]>[l->complete]
              [END]
            </SELECT>
            <BR><BR>
        <FONT COLOR="[dark_color]">Perioada de expirare a conexiunii</FONT>
<SELECT NAME="cookie_delay">
              [FOREACH period IN cookie_periods]
                <OPTION VALUE="[period->value]" [period->selected]>[period->desc]
              [END]
            </SELECT>
            <BR><BR>
            
        <INPUT TYPE="submit" NAME="action_setpref" VALUE="Trimite">
      </FORM>
        </TD>
      </TR>

      [IF auth=classic]
      <TR VALIGN="top">
        <TH BGCOLOR="[dark_color]" COLSPAN="2">
          <TABLE WIDTH="100%" CELLPADDING="0" CELLSPACING="0">
            <TR>
             
          <TH WIDTH="50%" BGCOLOR="[selected_color]"> <FONT COLOR="[bg_color]"> 
            Schimbarea adresei email</FONT> </TH>
          <TH WIDTH="50%" BGCOLOR="[selected_color]"> <FONT COLOR="[bg_color]"> 
            Schimbarea parolei</FONT></TH>
            </TR>
           </TABLE>
         </TH>

      </TR>
       
      <TR VALIGN="top">
           <TD>
           <FORM ACTION="[path_cgi]" METHOD=POST>
        
            <BR><BR>
        <FONT COLOR="[dark_color]">Noua adresa email: </FONT> <BR>
        &nbsp;&nbsp;&nbsp;<INPUT NAME="email" SIZE=15>
            <BR><BR>
        <INPUT TYPE="submit" NAME="action_change_email" VALUE="Trimite">
            </FORM>
        </TD>
        <TD>
          <FORM ACTION="[path_cgi]" METHOD=POST>
            <BR><BR>
        <FONT COLOR="[dark_color]">Noua parola : </FONT> <BR>
        &nbsp;&nbsp;&nbsp;<INPUT TYPE="password" NAME="newpasswd1" SIZE=15>
            <BR>
        <FONT COLOR="[dark_color]">Confirma parola noua: </FONT> <BR>
        &nbsp;&nbsp;&nbsp;<INPUT TYPE="password" NAME="newpasswd2" SIZE=15>
            <BR><BR><INPUT TYPE="submit" NAME="action_setpasswd" VALUE="Submit">
            </FORM>
	    [ENDIF]

        </TD>
	<TR VALIGN="top">
        <TH BGCOLOR="[dark_color]" COLSPAN="2">
          <TABLE WIDTH="100%" CELLPADDING="0" CELLSPACING="0">
            <TR>
             
          <TH WIDTH="50%" BGCOLOR="[selected_color]"> <FONT COLOR="[bg_color]"> 
            Celalalte adrese email</FONT></TH>
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
        <font color="[dark_color]">Alte adrese email : </font> &nbsp;&nbsp;&nbsp; 
        <INPUT NAME="new_alternative_email" SIZE=15>
        &nbsp;&nbsp;&nbsp;<FONT COLOR="[dark_color]">Parola : </FONT> &nbsp;&nbsp;&nbsp; 
        <INPUT TYPE = "password" NAME="new_password" SIZE=8>
            &nbsp;&nbsp;&nbsp &nbsp; <INPUT TYPE="submit" NAME="action_record_email" VALUE="Submit">
      </FORM>
      </TD>
      
    <TD VALIGN="middle"> Aceasta adresa trebuie sa fie cunoscuta de ctre Sympa. 
    </TD>
      </TR>
      </TABLE>
