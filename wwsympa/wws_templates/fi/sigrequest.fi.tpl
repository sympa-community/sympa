<!-- RCS Identication ; $Revision$ ; $Date$ -->

  [IF status=auth]
      Pyysit poistoa listalta [list]. <BR>Varmistaaksesi
      pyyntösi, paina alla olevaa nappia : <BR>
	<BR>

	<FORM ACTION="[path_cgi]" METHOD=POST>
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[user->email]">
	  <INPUT TYPE="submit" NAME="action_signoff" VALUE="Poistun listalta [list]">
	</FORM>

  [ELSIF not_subscriber]

      Et ole tilaajana listaan [list] osoitteella
      [email].
      <BR><BR>
      Saatat olla tilaajana eri osoitteella.
      Ota yhteyttä listan omistajaan niin 
      saat apua listalta poistumiseen :
      <A HREF="mailto:[list]-request@[conf->host]">[list]-request@[conf->host]</A>
      
  [ELSIF init_passwd]
        Pyysit poistoa listalta [list]. 
	<BR><BR>
	Varmistaaksesi henkilöllisyytesi ja estääksemme muita poistamasta sinua,
	viesti joka sisältää URL osoitteen lähetetään sinulle.
        <BR><BR>
	Tarkista postisi ja anna salasanasi jonka Sympa lähetti.
        Tällä varmistetaan poistumisesi listalta [list].
	
        <FORM ACTION="[path_cgi]" METHOD=POST>
          <FONT COLOR="[dark_color]"><B>e-mail osoite</B> </FONT>[email]<BR>
            <FONT COLOR="[dark_color]"><B>salasana</B> </FONT> 
  	  <INPUT TYPE="password" NAME="passwd" SIZE="20">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
        &nbsp; &nbsp; &nbsp;<INPUT TYPE="submit" NAME="action_signoff" VALUE="Poistu listalta">
        </FORM>

	Tämä salasana email osoitteeseen liitettynä, sallii pääsyn WWW-liittymään.

  [ELSIF ! email]
      	
	Anna email osoitteesi listalta [list] poistumispyyntöä varten.

      <FORM ACTION="[path_cgi]" METHOD=POST>
          <B>Email osoite :</B> 
          <INPUT NAME="email"><BR>
          <INPUT TYPE="hidden" NAME="action" VALUE="sigrequest">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="submit" NAME="action_sigrequest" VALUE="Poistu listalta">
         </FORM>


  [ELSE]
	
	Varmistaaksesi listalta [list] poistuminen, anna salasana :

         <FORM ACTION="[path_cgi]" METHOD=POST>
          <FONT COLOR="[dark_color]"><B>e-mail osoite</B> </FONT>[email]<BR>
            <FONT COLOR="[dark_color]"><B>salasana</B> </FONT> 
  	  <INPUT TYPE="password" NAME="passwd" SIZE="20">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
         &nbsp; &nbsp; &nbsp;<INPUT TYPE="submit" NAME="action_signoff" VALUE="Poistu listalta">

<BR><BR>
<I>Jos et ole koskaan saanut salasanaa tai et muista sitä :</I>  <INPUT TYPE="submit" NAME="action_sendpasswd" VALUE="Lähetä salasanani">

         </FORM>

  [ENDIF]      













