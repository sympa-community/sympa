<!-- RCS Identication ; $Revision$ ; $Date$ -->

  [IF status=auth]
      U vroeg om uitgeschreven te worden van de lijst [list]. <BR>Om dit te 
      bevestigen, klik op de onderstaande knop.<BR>
	<BR>

	<FORM ACTION="[path_cgi]" METHOD=POST>
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[user->email]">
	  <INPUT TYPE="submit" NAME="action_signoff" VALUE="Ik schrijf me uit bij lijst [list]">
	</FORM>

  [ELSIF not_subscriber]

      U bent niet ingeschreven bij lijst [list] met emailadres
      [email].
      <BR><BR>
      Misschien bent u ingeschreven met een ander adres.
      Neem contact op met de lijsteigenaar die u kan helpen om u uit te schrijven:
      <A HREF="mailto:[list]-request@[conf->host]">[list]-request@[conf->host]</A>
      
  [ELSIF init_passwd]
    	U vroeg om uitgeschreven te worden van de lijst [list]. 
	<BR><BR>
	Om u identiteit te bevestigen en om te voorkomen dat iedereen u kan uitschrijven,
	krijgt u een emailbericht toegezonden.
	<BR><BR>

	Controleer of u nieuwe mail heeft en geef hieronder het
	wachtwoord dat Sympa u heeft gegeven in het bericht. Dit zal uw
	uitschrijving van lijst [list] bevestigen.
	
        <FORM ACTION="[path_cgi]" METHOD=POST>
          <FONT COLOR="[dark_color]"><B>emailadres</B> </FONT>[email]<BR>
            <FONT COLOR="[dark_color]"><B>wachtwoord</B> </FONT> 
  	  <INPUT TYPE="password" NAME="passwd" SIZE="20">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
        &nbsp; &nbsp; &nbsp;<INPUT TYPE="submit" NAME="action_signoff" VALUE="Uitschrijven">
        </FORM>

	Dit wachtwoord dat bij uw emailadres hoort, zorgt er voor 
	dat u bij uw eigen omgeving kunt inloggen.

  [ELSIF ! email]
      Geeft u alstublieft uw emailadres voor het uitschrijven bij de lijst [list].

      <FORM ACTION="[path_cgi]" METHOD=POST>
          <B>Your e-mail address :</B> 
          <INPUT NAME="email"><BR>
          <INPUT TYPE="hidden" NAME="action" VALUE="sigrequest">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="submit" NAME="action_sigrequest" VALUE="Uitschrijven">
         </FORM>


  [ELSE]

  	Om uw uitschrijven van lijst [list] te bevestigen, geef
	alstublieft uw wachtwoord hieronder:

         <FORM ACTION="[path_cgi]" METHOD=POST>
          <FONT COLOR="[dark_color]"><B>e-mail address</B> </FONT>[email]<BR>
            <FONT COLOR="[dark_color]"><B>password</B> </FONT> 
  	  <INPUT TYPE="password" NAME="passwd" SIZE="20">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
         &nbsp; &nbsp; &nbsp;<INPUT TYPE="submit" NAME="action_signoff" VALUE="Uitschrijven">

<BR><BR>
<I>Wanneer u nog nooit een wachtwoord van deze server heeft ontvangen of wanneer u zich deze niet herinnerd :</I>  <INPUT TYPE="submit" NAME="action_sendpasswd" VALUE="Stuur me mijn wachtwoord">

         </FORM>

  [ENDIF]      













