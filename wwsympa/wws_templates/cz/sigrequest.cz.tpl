<!-- RCS Identication ; $Revision$ ; $Date$ -->

  [IF status=auth]
Po¾adujete odhlá¹ení z konference [list]. <BR>Pro potvrzení Va¹eho po¾adavku
Stisknìte tlaèítko dole :<BR>
	<BR>

	<FORM ACTION="[path_cgi]" METHOD=POST>
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[user->email]">
	  <INPUT TYPE="submit" NAME="action_signoff" VALUE="Odhla¹uji se z konference [list]">
	</FORM>

  [ELSIF not_subscriber]

      Nejste èlenem konference [list] s adresou [email].
      <BR><BR>
Mo¾ná jste pøihlá¹en z jiné adresy. Kontaktujte prosím správce konference, aby
Vám pomohl s odhlá¹ením:
 <A HREF="mailto:[list]-request@[conf->host]">[list]-request@[conf->host]</A>
      
  [ELSIF init_passwd]
Po¾adujete odhlá¹ení z konference [list]. 
	<BR><BR>
Pro potvrzení Va¹í identity a abychom zabránili cizím osobám ve Va¹em odhlá¹ení
proti Va¹í vùli, bude Vám odeslána zpráva s odkazem. <BR><BR>

Zkontrolujte si Va¹i schránku a vlo¾te dole heslo, které je v dané zprávì.
Tímto potvrdíte Va¹e odhlá¹ení z konference [list].
	
        <FORM ACTION="[path_cgi]" METHOD=POST>
          <FONT COLOR="[dark_color]"><B>emailová adresa</B> </FONT>[email]<BR>
            <FONT COLOR="[dark_color]"><B>heslo</B> </FONT> 
  	  <INPUT TYPE="password" NAME="passwd" SIZE="20">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
        &nbsp; &nbsp; &nbsp;<INPUT TYPE="submit" NAME="action_signoff" VALUE="Odhlásit">
        </FORM>
Toto heslo, pøipojené k Va¹í adrese, Vám zpøístupní Va¹e vlastní prostøedí.

  [ELSIF ! email]
Prosím, napi¹te Va¹i adresu pro odhlá¹ení se z konference [list].

      <FORM ACTION="[path_cgi]" METHOD=POST>
          <B>Va¹e emailová adresa:</B> 
          <INPUT NAME="email"><BR>
          <INPUT TYPE="hidden" NAME="action" VALUE="sigrequest">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="submit" NAME="action_sigrequest" VALUE="Odhlásit">
         </FORM>


  [ELSE]

Pro potvrzení va¹eho po¾adavku na odhlá¹ení z konference [list], vlo¾te Va¹e
heslo :

         <FORM ACTION="[path_cgi]" METHOD=POST>
          <FONT COLOR="[dark_color]"><B>emailová adresa</B> </FONT>[email]<BR>
            <FONT COLOR="[dark_color]"><B>heslo</B> </FONT> 
  	  <INPUT TYPE="password" NAME="passwd" SIZE="20">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
         &nbsp; &nbsp; &nbsp;<INPUT TYPE="submit" NAME="action_signoff" VALUE="Odhlásit">

<BR><BR> 
<I>Pokud zde nemáte heslo, nebo si ho nepamatujete :</I>  
<INPUT TYPE="submit" NAME="action_sendpasswd" VALUE="Za¹lete mi heslo">
         </FORM>

  [ENDIF]      
