<!-- RCS Identication ; $Revision$ ; $Date$ -->

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

      Usted no está subscrito a la lista [list] con el E-mail [email].
      <BR><BR>
      Puede ser que esté subscrito con otra dirección.
      Por favor, contacte con el propietario de la lista para que le ayude con la anulación:
      <A HREF="mailto:[list]-request@[conf->host]">[list]-request@[conf->host]</A>
      
  [ELSIF init_passwd]
    	Usted ha solicitado la anulación de sus subscripción de la lista [list]. 
	<BR><BR>
	Para confirmar su identidad y evitar que alguien le anula la subscripción sin su permiso, un mensaje con una URL se le enviará. <br><br>

	Compruebe los mensajes nuevos en su correo y utilice la contraseña que Sympa le envia.
   Dicha contraseña confirmará su anulación a la lista [list].
	
        <FORM ACTION="[path_cgi]" METHOD=POST>
          <FONT COLOR="--DARK_COLOR--"><B>Dirección E-mail </B> </FONT>[email]<BR>
            <FONT COLOR="--DARK_COLOR--"><B>Contraseña</B> </FONT> 
  	  <INPUT TYPE="password" NAME="passwd" SIZE="20">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
        &nbsp; &nbsp; &nbsp;<INPUT TYPE="submit" NAME="action_signoff" VALUE="Anula subscripción">
        </FORM>

      	Esta contraseña, asociada con su E-mail, le permitirá acceder a su entorno WWSympa.

  [ELSIF ! email]
      Por favor, entre su E-mail para la anulación de su subscripción a la lista [list].

      <FORM ACTION="[path_cgi]" METHOD=POST>
          <B>Su E-mail:</B> 
          <INPUT NAME="email"><BR>
          <INPUT TYPE="hidden" NAME="action" VALUE="sigrequest">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
         </FORM>


  [ELSE]

	Para confirmar la anulación de su subscripción a la lista [list], entre la siguiente contraseña:

         <FORM ACTION="[path_cgi]" METHOD=POST>
          <FONT COLOR="--DARK_COLOR--"><B>E-mail </B> </FONT>[email]<BR>
            <FONT COLOR="--DARK_COLOR--"><B>Contraseña</B> </FONT> 
  	  <INPUT TYPE="password" NAME="passwd" SIZE="20">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
         &nbsp; &nbsp; &nbsp;<INPUT TYPE="submit" NAME="action_signoff" VALUE="Anula subscripción">

<BR><BR>
<I>Si olvidó su contraseña o no tiene ninguna de este servidor:</I>  <INPUT TYPE="submit" NAME="action_sendpasswd" VALUE="Enviarme mi contraseña">

         </FORM>

  [ENDIF]      

