<!-- RCS Identication ; $Revision$ ; $Date$ -->

  [IF status=auth]

	[list] listára szeretnél feliratkozni. <BR>Feliratkozási kérelmed
	megerõsítéséhez kattints a lenti gombra: <BR>
	<BR>

	<FORM ACTION="[path_cgi]" METHOD=POST>
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[user->email]">
	  <INPUT TYPE="submit" NAME="action_subscribe" VALUE="[list] listára feliratkozom">
	</FORM>

  [ELSIF status=notauth_passwordsent]

    	[list] listára szeretnél feliratkozni. 
	<BR><BR>
	Azonosításodhoz és hogy mások vissza ne tudjanak élni a tagságoddal
	emailben elküldésre kerül a jelszavad.<BR><BR>

	A levélben található jelszót kell megadnod lentebb a(z) [list]
	listára történõ feliratkozásod megerõsítéséhez.
	
        <FORM ACTION="[path_cgi]" METHOD=POST>
          <FONT COLOR="[dark_color]"><B>email cím</B> </FONT>[email]<BR>
	  <FONT COLOR="[dark_color]"><B>jelszó</B> </FONT> 
  	  <INPUT TYPE="password" NAME="passwd" SIZE="20">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
	  <INPUT TYPE="hidden" NAME="previous_list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="previous_action" VALUE="subrequest">
        &nbsp; &nbsp; &nbsp;<INPUT TYPE="submit" NAME="action_subscribe" VALUE="Feliratkozás">
        </FORM>

      	A jelszavaddal és email címeddel az egyéni beállításaidat
	tudod késöbb megváltoztatni.

  [ELSIF status=notauth_noemail]

         <FORM ACTION="[path_cgi]" METHOD=POST>
          <FONT COLOR="[dark_color]"><B>Email címed</B> 
	  <INPUT  NAME="email" SIZE="30"><BR>
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="action" VALUE="subrequest">
	  <INPUT TYPE="submit" NAME="action_subrequest" VALUE="Elküld">
         </FORM>


  [ELSIF status=notauth]

	Feliratkozásod megerõsítéséhez a(z) [list] listára kérlek
	add meg a jelszavadat:

         <FORM ACTION="[path_cgi]" METHOD=POST>
          <FONT COLOR="[dark_color]"><B>Email cím</B> </FONT>[email]<BR>
            <FONT COLOR="[dark_color]"><B>Jelszó</B> </FONT> 
  	  <INPUT TYPE="password" NAME="passwd" SIZE="20">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
	  <INPUT TYPE="hidden" NAME="previous_list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="previous_action" VALUE="subrequest">
         &nbsp; &nbsp; &nbsp;<INPUT TYPE="submit" NAME="action_subscribe" VALUE="Feliratkozás">
	<INPUT TYPE="submit" NAME="action_sendpasswd" VALUE="Jelszavam?">
         </FORM>

  [ELSIF status=notauth_subscriber]

	<FONT COLOR="[dark_color]"><B>Már tagja vagy a(z) [list] listának.
	</FONT>
	<BR><BR>


	[PARSE '--ETCBINDIR--/wws_templates/loginbanner.hu.tpl']

  [ENDIF]      



