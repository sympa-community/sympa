<!-- RCS Identication ; $Revision$ ; $Date$ -->

  [IF status=auth]
      Sie w&uuml;nschen, die Liste [list] abzubestellen. <BR>
      Bitte dr&uuml;cken Sie zur Best&auuml;tigung den Knopf:<BR>
	<BR>

	<FORM ACTION="[path_cgi]" METHOD=POST>
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[user->email]">
	  <INPUT TYPE="submit" NAME="action_signoff" VALUE="Ich bestelle die Liste [list] ab">
	</FORM>

  [ELSIF not_subscriber]

      Sie haben die Liste [list] gar nicht f&uuml;r die Adresse [email] abonniert.
      <BR><BR>
      M&ouml;glicherweise haben Sie die Liste mit einer anderen EMail-Adresse
      abonniert. Wenn Sie Hilfe ben&ouml;tigen, sollten Sie am besten den
      Besitzer der Liste kontaktieren:
      <A HREF="mailto:[list]-request@[conf->host]">[list]-request@[conf->host]</A>
      
  [ELSIF init_passwd]
    	Sie w&uuml;nschen die Liste [list] abzubestellen. 
	<BR><BR>
	Um Sie zu identifizieren und zu verhindern, da&szlig; jemand anders
        die Liste gegen Ihren Willen f&uuml;r Sie abbestellt, wird Ihnen  nun
	eine EMail mit einer URL zugesendet. <BR><BR>

	Bitte warten Sie die Nachricht ab und geben Sie das Passwort aus dieser
  	Nachricht unten ein. Damit best&auml;tigen Sie die Abbestellung der
	Mailing-Liste [list].
	
        <FORM ACTION="[path_cgi]" METHOD=POST>
          <FONT COLOR="[dark_color]"><B>EMail-Adresse</B> </FONT>[email]<BR>
            <FONT COLOR="[dark_color]"><B>Passwort</B> </FONT> 
  	  <INPUT TYPE="password" NAME="passwd" SIZE="20">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
        &nbsp; &nbsp; &nbsp;<INPUT TYPE="submit" NAME="action_signoff" VALUE="Abbestellen">
        </FORM>

	Das Sympa-Passwort zu Ihrer EMail-Adresse, erlaubt Ihnen den
	Zugriff auf Ihre pers&ouml;nlichen  Einstellungen.

  [ELSIF ! email]
      Bitte geben Sie die EMail-Adresse an, f&uuml;r welche Sie Liste [list] abbestellen wollen.

      <FORM ACTION="[path_cgi]" METHOD=POST>
          <B>Ihre EMail-Adresse:</B> 
          <INPUT NAME="email"><BR>
          <INPUT TYPE="hidden" NAME="action" VALUE="sigrequest">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
         </FORM>


  [ELSE]

	Bitte geben Sie unten Ihr Passwort
	zur Best&auml;tigung Ihrer Abmeldung f&uer die Liste [list] ein.

         <FORM ACTION="[path_cgi]" METHOD=POST>
          <FONT COLOR="[dark_color]"><B>EMail-Adresse</B> </FONT>[email]<BR>
            <FONT COLOR="[dark_color]"><B>Passwort</B> </FONT> 
  	  <INPUT TYPE="password" NAME="passwd" SIZE="20">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
         &nbsp; &nbsp; &nbsp;<INPUT TYPE="submit" NAME="action_signoff" VALUE="Abmelden">

<BR><BR>
<I>Falls Sie kein Passwort auf dieser Maschine haben oder sich nicht erinnern k&ouml;nnen:</I>  <INPUT TYPE="submit" NAME="action_sendpasswd" VALUE="Schicke mir mein Passwort">

         </FORM>

  [ENDIF]      













