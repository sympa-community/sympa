  [IF status=auth]
      You requested unsubscription from list [list]. <BR>To confirm
      your request, please click the button bellow :<BR>
	<BR>

	<FORM ACTION="[path_cgi]" METHOD=POST>
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[user->email]">
	  <INPUT TYPE="submit" NAME="action_signoff" VALUE="I unsubscribe from list [list]">
	</FORM>

  [ELSIF not_subscriber]

	Non sei iscritto alla lista [list] con l'indirizzo [email].
      <BR><BR>
      Potresti essere iscritto con un indirizzo differente.
      Contatta il creatore della lista per conferme o sottoscrizioni:
      <A HREF="mailto:[list]-request@[conf->host]">[list]-request@[conf->host]</A>
      
  [ELSIF init_passwd]
    	Hai richiesto la cancellazione della tua iscrizione alla lista [list]. 
	<BR><BR>
	Per confermare la tua identit&agrave; ed evitare abusi, ti viene ora spedito
	un messaggio contente un indirizzo.<BR><BR>


	Controlla la tua mailbox per l'arrivo di nuovi messaggi e inserisci
	la password. Questo confermer&agrave; la cancellazione della tua sottoscrizione alla lista [list].
	
        <FORM ACTION="[path_cgi]" METHOD=POST>
          <FONT COLOR="--DARK_COLOR--"><B>indirizzo e-mail</B> </FONT>[email]<BR>
            <FONT COLOR="--DARK_COLOR--"><B>password</B> </FONT> 
  	  <INPUT TYPE="password" NAME="passwd" SIZE="20">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
        &nbsp; &nbsp; &nbsp;<INPUT TYPE="submit" NAME="action_signoff" VALUE="Cancella sottoscrizione">
        </FORM>

  [ELSIF ! email]
      <FORM ACTION="[path_cgi]" METHOD=POST>
          <B>Your e-mail address :</B> 
          <INPUT NAME="email"><BR>
          <INPUT TYPE="hidden" NAME="action" VALUE="sigrequest">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
         </FORM>


  [ELSE]

	Per confermare la cancellazione della tua sottoscrizione alla lista [list], inserisci
	la password :

         <FORM ACTION="[path_cgi]" METHOD=POST>
          <FONT COLOR="--DARK_COLOR--"><B>indirizzo e-mail</B> </FONT>[email]<BR>
            <FONT COLOR="--DARK_COLOR--"><B>password</B> </FONT> 
  	  <INPUT TYPE="password" NAME="passwd" SIZE="20">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
         &nbsp; &nbsp; &nbsp;<INPUT TYPE="submit" NAME="action_signoff" VALUE="Cancella sottoscrizione">
<BR>
     	      <FONT SIZE=-1>
     	      <A HREF="[path_cgi]/remindpasswd"><b>Ho dimenticato la mia password</b></A>
     	      </FONT>
         </FORM>

  [ENDIF]      



