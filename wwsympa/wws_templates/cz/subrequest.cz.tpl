<!-- RCS Identication ; $Revision$ ; $Date$ -->

  [IF status=auth]
Po¾adujete pøihlá¹ení do konference [list]. 
<BR>Pro potvrzení Va¹eho po¾adavku, stisknìte tlaèítko dole :<BR>
	<BR>

	<FORM ACTION="[path_cgi]" METHOD=POST>
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[user->email]">
	  <INPUT TYPE="submit" NAME="action_subscribe" VALUE="Pøihla¹uji se do konference [list]">
	</FORM>

  [ELSIF status=notauth_passwordsent]
Po¾adujete pøihlá¹ení do konference [list]. 
	<BR><BR>
Pro potvrzení Va¹í identity, a abychom zabránili cizím osobám ve Va¹em pøihlá¹ení 
proti Va¹í vùli, Vám bude odeslána zprava obsahující Va¹e heslo.
<BR><BR>
Zkontrolujte si Va¹i schránku a vlo¾te heslo. Tímto potvrdíte Va¹e pøihlá¹ení 
do konference [list].
	
        <FORM ACTION="[path_cgi]" METHOD=POST>
          <FONT COLOR="#330099"><B>e-mail address</B> </FONT>[email]<BR>
	  <FONT COLOR="#330099"><B>heslo</B> </FONT> 
  	  <INPUT TYPE="password" NAME="passwd" SIZE="20">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
	  <INPUT TYPE="hidden" NAME="previous_list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="previous_action" VALUE="subrequest">
        &nbsp; &nbsp; &nbsp;<INPUT TYPE="submit" NAME="action_subscribe" VALUE="Pøihlásit se">
        </FORM>
Toto heslo, spojené s Va¹í emailovou adresou, Vám umo¾ní pøístup k Va¹em
vlastnímu prostøedí.

  [ELSIF status=notauth_noemail]

         <FORM ACTION="[path_cgi]" METHOD=POST>
          <FONT COLOR="#330099"><B>Your e-mail address</B> 
	  <INPUT  NAME="email" SIZE="30"><BR>
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="action" VALUE="subrequest">
	  <INPUT TYPE="submit" NAME="action_subrequest" VALUE="Odeslat">
         </FORM>

  [ELSIF status=notauth]
Pro potvrzení Va¹eho pøihlá¹ení do konference [list], vlo¾te Va¹e heslo:

         <FORM ACTION="[path_cgi]" METHOD=POST>
          <FONT COLOR="#330099"><B>emailová adresa</B> </FONT>[email]<BR>
            <FONT COLOR="#330099"><B>heslo</B> </FONT> 
  	  <INPUT TYPE="password" NAME="passwd" SIZE="20">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
	  <INPUT TYPE="hidden" NAME="previous_list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="previous_action" VALUE="subrequest">
         &nbsp; &nbsp; &nbsp;<INPUT TYPE="submit" NAME="action_subscribe" VALUE="Pøihlásit se">
	<INPUT TYPE="submit" NAME="action_sendpasswd" VALUE="Moje heslo ?">
         </FORM>

  [ELSIF status=notauth_subscriber]

	<FONT COLOR="#330099"><B>Jste ji¾ èlenem konference [list].
	</FONT>
	<BR><BR>


	[PARSE '/home/sympa/bin/etc/wws_templates/loginbanner.cz.tpl']

  [ENDIF]      
