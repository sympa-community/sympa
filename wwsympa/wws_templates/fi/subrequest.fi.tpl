<!-- RCS Identication ; $Revision$ ; $Date$ -->

  [IF status=auth]

	Pyysit tilausta listalle [list]. <BR>Varmistaaksesi
	pyyntösi, paina alla olevaa nappia : <BR>
	<BR>

	<FORM ACTION="[path_cgi]" METHOD=POST>
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[user->email]">
	  <INPUT TYPE="submit" NAME="action_subscribe" VALUE="Tilaan listan [list]">
	</FORM>

  [ELSIF status=notauth_passwordsent]

	Pyysit tilausta listalle [list]. 
	<BR><BR>
        Varmistaakseemme henkilöllisyytesi ja estääksemme muita tilaamasta
        sinun osoitteella, lähetämme viestin joka sisältää salasanan.<BR><BR>

	Tarkista postisi ja anna salasana alle. 
	Tämä varmistaa tilauksesi listalle [list].
	
        <FORM ACTION="[path_cgi]" METHOD=POST>
          <FONT COLOR="[dark_color]"><B>e-mail osoite</B> </FONT>[email]<BR>
	  <FONT COLOR="[dark_color]"><B>salasana</B> </FONT> 
  	  <INPUT TYPE="password" NAME="passwd" SIZE="20">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
	  <INPUT TYPE="hidden" NAME="previous_list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="previous_action" VALUE="subrequest">
        &nbsp; &nbsp; &nbsp;<INPUT TYPE="submit" NAME="action_subscribe" VALUE="Tilaa">
        </FORM>
	
	Tämä salasana liittyen email osoitteeseen, 
	sallii yhteyden WWW-liittymään. 

  [ELSIF status=notauth_noemail]

         <FORM ACTION="[path_cgi]" METHOD=POST>
          <FONT COLOR="[dark_color]"><B>Email osoite</B> </FONT>
	  <INPUT  NAME="email" SIZE="30"><BR>
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="action" VALUE="subrequest">
	  <INPUT TYPE="submit" NAME="action_subrequest" VALUE="lähetä">
         </FORM>


  [ELSIF status=notauth]

	Varmistaaksesi tilauksesi listalle [list], 
	anna salasana alle :

         <FORM ACTION="[path_cgi]" METHOD=POST>
          <FONT COLOR="[dark_color]"><B>email osoite</B> </FONT>[email]<BR>
            <FONT COLOR="[dark_color]"><B>salasana</B> </FONT> 
  	  <INPUT TYPE="password" NAME="passwd" SIZE="20">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
	  <INPUT TYPE="hidden" NAME="previous_list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="previous_action" VALUE="subrequest">
         &nbsp; &nbsp; &nbsp;<INPUT TYPE="submit" NAME="action_subscribe" VALUE="Tilaa">
	<INPUT TYPE="submit" NAME="action_sendpasswd" VALUE="Salasanani ?">
         </FORM>

  [ELSIF status=notauth_subscriber]

	<FONT COLOR="[dark_color]"><B>Olet jo tilaajana listalla [list].</B>
	</FONT>
	<BR><BR>


	[PARSE '--ETCBINDIR--/wws_templates/loginbanner.us.tpl']

  [ENDIF]      



