<!-- RCS Identication ; $Revision$ ; $Date$ -->


    <TABLE WIDTH="100%" CELLPADDING="1" CELLSPACING="0">
      <TR VALIGN="top">
        <TH BGCOLOR="#330099" COLSPAN="2">
          <TABLE WIDTH="100%" CELLPADDING="0" CELLSPACING="0">
            <TR>
             <TH BGCOLOR="#3366cc" WIDTH="50%">
	      <FONT COLOR="#ffffff">
	        Va¹e prostøedí
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
  	    <FONT COLOR="#330099">Email </FONT> [user->email]<BR><BR>
	    <FONT COLOR="#330099">Jméno</FONT> 
	    <INPUT TYPE="text" NAME="gecos" SIZE=20 VALUE="[user->gecos]"><BR><BR> 
	    <FONT COLOR="#330099">Jazyk</FONT>
	    <SELECT NAME="lang">
	      [FOREACH l IN languages]
	        <OPTION VALUE="[l->NAME]" [l->selected]>[l->complete]
	      [END]
	    </SELECT>
	    <BR><BR>
	    <FONT COLOR="#330099">Doba kdy vypr¹í ovìøení toto¾nosti </FONT>
	    <SELECT NAME="cookie_delay">
	      [FOREACH period IN cookie_periods]
	        <OPTION VALUE="[period->value]" [period->selected]>[period->desc]
	      [END]
	    </SELECT>
	    <BR><BR>
	    <INPUT TYPE="submit" NAME="action_setpref" VALUE="Odeslat"></FONT>
	  </FORM>
	</TD>
      </TR>
      <TR VALIGN="top">
        <TH BGCOLOR="#330099" COLSPAN="2">
          <TABLE WIDTH="100%" CELLPADDING="0" CELLSPACING="0">
            <TR>
	     <TH WIDTH="50%" BGCOLOR="#3366cc">
	      <FONT COLOR="#ffffff">
	        Zmìna Va¹í emailové adresy
	      </FONT>
	     </TH><TH WIDTH="50%" BGCOLOR="#3366cc">
	      <FONT COLOR="#ffffff">
	        Zmìna Va¹eho hesla
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
	    <BR><BR><BR><FONT COLOR="#330099">Nová adresa : </FONT>
	    <BR>&nbsp;&nbsp;&nbsp;<INPUT NAME="email" SIZE=15>
	    <BR><BR><BR><INPUT TYPE="submit" NAME="action_change_email" VALUE="Odeslat">
	    </FORM>
	</TD>
	<TD>
	  <FORM ACTION="[path_cgi]" METHOD=POST>
	    <INPUT TYPE="hidden" NAME="previous_action" VALUE="[previous_action]">
	    <INPUT TYPE="hidden" NAME="previous_list" VALUE="[previous_list]">
	    <BR><BR><BR><FONT COLOR="#330099">Nové heslo : </FONT>
	    <BR>&nbsp;&nbsp;&nbsp;<INPUT TYPE="password" NAME="newpasswd1" SIZE=15>
	    <BR><FONT COLOR="#330099">Zopakujte nové heslo : </FONT>
	    <BR>&nbsp;&nbsp;&nbsp;<INPUT TYPE="password" NAME="newpasswd2" SIZE=15>
	    <BR><BR><BR><INPUT TYPE="submit" NAME="action_setpasswd" VALUE="Odeslat">
	    </FORM>
	</TD>
      </TR>


    </TABLE>

 