  [IF status=auth]

	Hai richiesto la sottoscrizione a [list]. <BR>Per confermare
	la tua richiesta, premi il pulsante sottostante :<BR>
	<BR>

	<FORM ACTION="[path_cgi]" METHOD=POST>
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[user->email]">
	  <INPUT TYPE="submit" NAME="action_subscribe" VALUE="Mi iscrivo alla lista [list]">
	</FORM>


  [ELSIF status=notauth_passwordsent]

    	Hai richiesto la sottoscrizione a [list]. 
	<BR><BR>
	Per confermare la tua identit&agrave; ed evitare che qualcuno abusi della tua e-mail,
	ti verr&agrave; mandato un messaggio contenente la tua password.
	<BR><BR>

	Controlla la tua mailbox per l'arrivo di nuovi messaggi e inserisci
	la password. Questo confermer&agrave; la tua sottoscrizione alla lista [list].
	
        <FORM ACTION="[path_cgi]" METHOD=POST>
          <FONT COLOR="--DARK_COLOR--"><B>indirizzo e-mail</B> </FONT>[email]<BR>
	  <FONT COLOR="--DARK_COLOR--"><B>password</B> </FONT> 
  	  <INPUT TYPE="password" NAME="passwd" SIZE="20">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
	  <INPUT TYPE="hidden" NAME="previous_list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="previous_action" VALUE="subrequest">
        &nbsp; &nbsp; &nbsp;<INPUT TYPE="submit" NAME="action_subscribe" VALUE="Sottoscrivi">
        </FORM>

	Questa password, associata all'indirizzo di posta, ti consetir&agrave;
	di accedere alle tue pagine personalizzate.
      	
  [ELSIF status=notauth_noemail]

         <FORM ACTION="[path_cgi]" METHOD=POST>
          <FONT COLOR="--DARK_COLOR--"><B>Il tuo indirizzo e-mail</B> 
	  <INPUT  NAME="email" SIZE="30"><BR>
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="action" VALUE="subrequest">
          <INPUT TYPE="submit" NAME="action_subrequest" VALUE="Sottoscrivi">
         </FORM>


  [ELSIF status=notauth]

	Per confermare la tua sottoscrizione alla lista [list], inserisci
	la password :

         <FORM ACTION="[path_cgi]" METHOD=POST>
          <FONT COLOR="--DARK_COLOR--"><B>Indirizzo e-mail</B> </FONT>[email]<BR>
            <FONT COLOR="--DARK_COLOR--"><B>password</B> </FONT> 
  	  <INPUT TYPE="password" NAME="passwd" SIZE="20">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
	  <INPUT TYPE="hidden" NAME="previous_list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="previous_action" VALUE="subrequest">
         &nbsp; &nbsp; &nbsp;<INPUT TYPE="submit" NAME="action_subscribe" VALUE="Sottoscrivi">
	<INPUT TYPE="submit" NAME="action_sendpasswd" VALUE="La mia password ?">
         </FORM>

  [ELSIF status=notauth_subscriber]

	<FONT COLOR="--DARK_COLOR--"><B>Sei gi&agrave; iscritto alla lista [list].
	</FONT>
	<BR><BR>


	[PARSE '--ETCBINDIR--/wws_templates/loginbanner.it.tpl']

  [ENDIF]      


