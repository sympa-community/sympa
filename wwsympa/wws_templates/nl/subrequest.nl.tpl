<!-- RCS Identication ; $Revision$ ; $Date$ -->

  [IF status=auth]

        U vroeg om ingeschreven te worden bij de lijst [list]. <BR>Om te
	bevestigen, klik alstublieft op onderstaande knop :<BR>
	<BR>

	<FORM ACTION="[path_cgi]" METHOD=POST>
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[user->email]">
	  <INPUT TYPE="submit" NAME="action_subscribe" VALUE="Ik abonneer me op lijst [list]">
	</FORM>

  [ELSIF status=notauth_passwordsent]

    	U vroeg om ingeschreven te worden bij de lijst [list]. 
	<BR><BR>
	Om uw identiteit te bevestigen en om te voorkomen dat iemand anders
	u inschrijft tegen uw wil zal u een emailbericht worden toegezonden met
	daarin een wachtwoord.<BR><BR>

	Controleer of u nieuwe mail heeft en geef hieronder het wachtwoord.
	Dit zal uw abonnement bevestigen op de lijst [list].
	
        <FORM ACTION="[path_cgi]" METHOD=POST>
          <FONT COLOR="[dark_color]"><B>e-mail address</B> </FONT>[email]<BR>
	  <FONT COLOR="[dark_color]"><B>password</B> </FONT> 
  	  <INPUT TYPE="password" NAME="passwd" SIZE="20">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
	  <INPUT TYPE="hidden" NAME="previous_list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="previous_action" VALUE="subrequest">
        &nbsp; &nbsp; &nbsp;<INPUT TYPE="submit" NAME="action_subscribe" VALUE="Inschrijven">
        </FORM>

	Dit wachtwoord dat bij uw emaildres hoor, geeft u 
	toegang tot uw eigen omgeving.

  [ELSIF status=notauth_noemail]

         <FORM ACTION="[path_cgi]" METHOD=POST>
          <FONT COLOR="[dark_color]"><B>Your e-mail address</B> </FONT>
	  <INPUT  NAME="email" SIZE="30"><BR>
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="action" VALUE="subrequest">
	  <INPUT TYPE="submit" NAME="action_subrequest" VALUE="submit">
         </FORM>


  [ELSIF status=notauth]

  	 Om uw inschrijving te bevestigen op lijst [list], geeft
	 u alstublieft hieronder uw wachtwoord:

         <FORM ACTION="[path_cgi]" METHOD=POST>
          <FONT COLOR="[dark_color]"><B>e-mail address</B> </FONT>[email]<BR>
            <FONT COLOR="[dark_color]"><B>password</B> </FONT> 
  	  <INPUT TYPE="password" NAME="passwd" SIZE="20">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
	  <INPUT TYPE="hidden" NAME="previous_list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="previous_action" VALUE="subrequest">
         &nbsp; &nbsp; &nbsp;<INPUT TYPE="submit" NAME="action_subscribe" VALUE="Inschrijven">
	<INPUT TYPE="submit" NAME="action_sendpasswd" VALUE="Mijn wachtwoord ?">
         </FORM>

  [ELSIF status=notauth_subscriber]

	<FONT COLOR="[dark_color]"><B>U bent al abonnee van lijst [list].</B>
	</FONT>
	<BR><BR>


	[PARSE '--ETCBINDIR--/wws_templates/loginbanner.us.tpl']

  [ENDIF]      



