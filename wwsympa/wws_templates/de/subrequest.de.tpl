<!-- RCS Identication ; $Revision$ ; $Date$ -->

  [IF status=auth]

	Sie w&uuml;nschen die Liste [list] abonnieren. <BR>
	Bitte dr&uuml;cken Sie zur Best&auml;tigung den Knopf:<BR>
	<BR>

	<FORM ACTION="[path_cgi]" METHOD=POST>
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[user->email]">
	  <INPUT TYPE="submit" NAME="action_subscribe" VALUE="Ich abonniere die Liste [list]">
	</FORM>

  [ELSIF status=notauth_passwordsent]

    	Sie w&uuml;nschen die Liste [list] abonnieren. 
	<BR><BR>
	Um zu verhindern, da&szlig; jemand die Liste gegen Ihren Willen
	f&uuml;r Sie abonniert, wird eine EMail mit einem Passwort an Sie
	gesckickt.
	<BR><BR>
	Bitte warten Sie die EMail ab und best&auml;tigen Sie das Abonnement
	mit dem Passwort.
	
        <FORM ACTION="[path_cgi]" METHOD=POST>
          <FONT COLOR="[dark_color]"><B>EMail-Addresse</B> </FONT>[email]<BR>
	  <FONT COLOR="[dark_color]"><B>Passwort</B> </FONT> 
  	  <INPUT TYPE="password" NAME="passwd" SIZE="20">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
	  <INPUT TYPE="hidden" NAME="previous_list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="previous_action" VALUE="subrequest">
        &nbsp; &nbsp; &nbsp;<INPUT TYPE="submit" NAME="action_subscribe" VALUE="Abonnieren">

        </FORM>

	Dieses Passwort wird Ihnen zusammen mit der EMail-Adresse
	erm&ouml;glichen, Ihre pers&ouml;nlichen Einstellungen vorzunehmen.

  [ELSIF status=notauth_noemail]

         <FORM ACTION="[path_cgi]" METHOD=POST>
          <FONT COLOR="[dark_color]"><B>Ihre EMail-Adresse</B> 
	  <INPUT  NAME="email" SIZE="30"><BR>
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="action" VALUE="subrequest">
	  <INPUT TYPE="submit" NAME="action_subrequest" VALUE="Abonnieren">
         </FORM>


  [ELSIF status=notauth]

	Bitte gebeben Sie Ihr Passwort zur Best&auml;tigung Ihres Abonnements
	der Mailing-Liste [list] ein:

         <FORM ACTION="[path_cgi]" METHOD=POST>
          <FONT COLOR="[dark_color]"><B>EMail-Adresse</B> </FONT>[email]<BR>
            <FONT COLOR="[dark_color]"><B>Passwort</B> </FONT> 
  	  <INPUT TYPE="password" NAME="passwd" SIZE="20">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
	  <INPUT TYPE="hidden" NAME="previous_list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="previous_action" VALUE="subrequest">
         &nbsp; &nbsp; &nbsp;<INPUT TYPE="submit" NAME="action_subscribe" VALUE="Subscribe">
	<INPUT TYPE="submit" NAME="action_sendpasswd" VALUE="Abonnieren">
         </FORM>

  [ELSIF status=notauth_subscriber]

	<FONT COLOR="[dark_color]"><B>Sie haben bereits die Liste [list] abonniert.
	</FONT>
	<BR><BR>


	[PARSE '--ETCBINDIR--/wws_templates/loginbanner.us.tpl']

  [ENDIF]      



