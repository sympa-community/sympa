<!-- RCS Identication ; $Revision$ ; $Date$ -->

  [IF status=auth]
	Soovisite liituda listiga [list]. <BR>Et kinnitada oma soovi listiga 
	liituda, palun klikake allolevale nupule:<BR><BR>

	<FORM ACTION="[path_cgi]" METHOD=POST>
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[user->email]">
	  <INPUT TYPE="submit" NAME="action_subscribe" VALUE="Soovin liituda listiga [list]">
	</FORM>

  [ELSIF status=notauth_passwordsent]

	Soovisite liituda listiga [list].
	<BR><BR>
	Et keegi teine ei saaks teid listidesse registreerida, saadetakse
	teile kiri teie parooliga. <BR><BR>

	Sisestage siia saadud parool, see kinnitab teie soovi liituda listiga
	[list].
	
        <FORM ACTION="[path_cgi]" METHOD=POST>
          <FONT COLOR="[dark_color]"><B>e-posti aadress</B> </FONT>[email]<BR>
	  <FONT COLOR="[dark_color]"><B>parool</B> </FONT> 
  	  <INPUT TYPE="password" NAME="passwd" SIZE="20">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
	  <INPUT TYPE="hidden" NAME="previous_list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="previous_action" VALUE="subrequest">
        &nbsp; &nbsp; &nbsp;<INPUT TYPE="submit" NAME="action_subscribe" VALUE="Liitu">
        </FORM>

	Seesama parool koos e-postiaadressiga võimaldab teil kasutada Sympa
	veebikeskkonda.

  [ELSIF status=notauth_noemail]

         <FORM ACTION="[path_cgi]" METHOD=POST>
          <FONT COLOR="[dark_color]"><B>Teie e-postiaadress</B> 
	  <INPUT  NAME="email" SIZE="30"><BR>
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="action" VALUE="subrequest">
	  <INPUT TYPE="submit" NAME="action_subrequest" VALUE="saada">
         </FORM>


  [ELSIF status=notauth]

	Liitumiseks listiga [list], sisesgate palun oma parool:

         <FORM ACTION="[path_cgi]" METHOD=POST>
          <FONT COLOR="[dark_color]"><B>e-posti aadress</B> </FONT>[email]<BR>
            <FONT COLOR="[dark_color]"><B>parool</B> </FONT> 
  	  <INPUT TYPE="password" NAME="passwd" SIZE="20">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
	  <INPUT TYPE="hidden" NAME="previous_list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="previous_action" VALUE="subrequest">
         &nbsp; &nbsp; &nbsp;<INPUT TYPE="submit" NAME="action_subscribe" VALUE="Liitu">
	<INPUT TYPE="submit" NAME="action_sendpasswd" VALUE="Minu paool ?">
         </FORM>

  [ELSIF status=notauth_subscriber]

	<FONT COLOR="[dark_color]"><B>Olete juba listi [list] liige.
	</FONT>
	<BR><BR>


	[PARSE '--ETCBINDIR--/wws_templates/loginbanner.et.tpl']

  [ENDIF]      



