<!-- RCS Identication ; $Revision$ ; $Date$ -->

    <TABLE WIDTH="100%" CELLPADDING="1" CELLSPACING="0">
      <TR VALIGN="top">
        <TH BGCOLOR="[dark_color]" COLSPAN="2">
          <TABLE WIDTH="100%" CELLPADDING="0" CELLSPACING="0">
            <TR>
             <TH BGCOLOR="[selected_color]" WIDTH="50%">
              <FONT COLOR="[bg_color]">
                Asetuksesi
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
            <FONT COLOR="[dark_color]">Nimi</FONT>
            <INPUT TYPE="text" NAME="gecos" SIZE=20 VALUE="[user->gecos]"><BR><BR>
            <FONT COLOR="[dark_color]">Kieli </FONT>
            <SELECT NAME="lang">
              [FOREACH l IN languages]
                <OPTION VALUE='[l->NAME]' [l->selected]>[l->complete]
              [END]
            </SELECT>
            <BR><BR>
            <FONT COLOR="[dark_color]">Yhteyden voimassaoloaika</FONT>
            <SELECT NAME="cookie_delay">
              [FOREACH period IN cookie_periods]
                <OPTION VALUE="[period->value]" [period->selected]>[period->desc]
              [END]
            </SELECT>
            <BR><BR>
            <INPUT TYPE="submit" NAME="action_setpref" VALUE="L‰het‰">
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
                Email osoitteen muuttaminen
              </FONT>
             </TH><TH WIDTH="50%" BGCOLOR="[selected_color]">
              <FONT COLOR="[bg_color]">
		Salasanan muuttaminen
              </FONT>
             </TH>
            </TR>
           </TABLE>
         </TH>

      </TR>
       
      <TR VALIGN="top">
           <TD>
           <FORM ACTION="[path_cgi]" METHOD=POST>
        
            <BR><BR><FONT COLOR="[dark_color]">Uusi email osoite : </FONT>
            <BR>&nbsp;&nbsp;&nbsp;<INPUT NAME="email" SIZE=15>
            <BR><BR><INPUT TYPE="submit" NAME="action_change_email" VALUE="L‰het‰">
            </FORM>
        </TD>
        <TD>
          <FORM ACTION="[path_cgi]" METHOD=POST>
            <BR><BR><FONT COLOR="[dark_color]">Uusi salasana : </FONT>
            <BR>&nbsp;&nbsp;&nbsp;<INPUT TYPE="password" NAME="newpasswd1" SIZE=15>
            <BR><FONT COLOR="[dark_color]">Salasana uudelleen : </FONT>
            <BR>&nbsp;&nbsp;&nbsp;<INPUT TYPE="password" NAME="newpasswd2" SIZE=15>
            <BR><BR><INPUT TYPE="submit" NAME="action_setpasswd" VALUE="L‰het‰">
            </FORM>
	    [ENDIF]

        </TD>
	<TR VALIGN="top">
        <TH BGCOLOR="[dark_color]" COLSPAN="2">
          <TABLE WIDTH="100%" CELLPADDING="0" CELLSPACING="0">
            <TR>
             <TH WIDTH="50%" BGCOLOR="[selected_color]">
              <FONT COLOR="[bg_color]">
		Vaihtoehtoinen email osoite
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
	    <FONT COLOR="[dark_color]">Vaihtoehtoinen email osoite : </FONT>
	    &nbsp;&nbsp;&nbsp;<INPUT NAME="new_alternative_email" SIZE=15><BR>
	    &nbsp;&nbsp;&nbsp;<FONT COLOR="[dark_color]">Salasana : </FONT>
	    &nbsp;&nbsp;&nbsp;<INPUT TYPE = "password" NAME="new_password" SIZE=8>
            &nbsp;&nbsp;&nbsp &nbsp; <INPUT TYPE="submit" NAME="action_record_email" VALUE="L‰het‰">
            </FORM>
      </TD>
      <TD VALIGN="middle">
      Vaihtoehtoinen osoite, joka tulee olla Sympan tiedossa, k‰ytet‰‰n vaihtoehtoisena 
      l‰hetysosoitteena. Voit myˆs yhdist‰‰ tilauksesi p‰‰osoitteellasi.
      </TD>
      </TR>
      </TABLE>
