<!-- RCS Identication ; $Revision$ ; $Date$ -->

  [IF status=auth]
      Ha solicitado la baja de la lista [list]. <BR>Para confirmar su
      petición pulse por favor el botón siguiente:<BR>
	<BR>

	<FORM ACTION="[path_cgi]" METHOD=POST>
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[user->email]">
	  <INPUT TYPE="submit" NAME="action_signoff" VALUE="Me doy de baja de la lista [list]">
	</FORM>

  [ELSIF not_subscriber]

      Usted no está suscrito a la lista [list] con el E-mail [email].
      <BR><BR>
      Puede ser que esté suscrito con otra dirección.
      Por favor, contacte con el propietario de la lista para que le ayude con la anulación:
      <A HREF="mailto:[list]-request@[conf->host]">[list]-request@[conf->host]</A>
      
  [ELSIF init_passwd]
    	Usted ha solicitado la anulación de sus suscripción de la lista [list]. 
	<BR><BR>
	Para confirmar su identidad y evitar que alguien le anula la suscripción sin su permiso, un mensaje con una URL se le enviará. <br><br>

	Compruebe los mensajes nuevos en su correo y utilice la contraseña que Sympa le envia.
   Dicha contraseña confirmará su anulación a la lista [list].
	
        <FORM ACTION="[path_cgi]" METHOD=POST>
          <FONT COLOR="[dark_color]"><B>Dirección E-mail </B> </FONT>[email]<BR>
            <FONT COLOR="[dark_color]"><B>Contraseña</B> </FONT> 
  	  <INPUT TYPE="password" NAME="passwd" SIZE="20">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
        &nbsp; &nbsp; &nbsp;<INPUT TYPE="submit" NAME="action_signoff" VALUE="Anula suscripción">
        </FORM>

      	Esta contraseña, asociada con su E-mail, le permitirá acceder a su entorno WWSympa.

  [ELSIF ! email]
      Por favor, introduzca su E-mail para darse de baja de la lista [list].

      <FORM ACTION="[path_cgi]" METHOD=POST>
          <B>Su E-mail:</B> 
          <INPUT NAME="email"><BR>
          <INPUT TYPE="hidden" NAME="action" VALUE="sigrequest">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="submit" NAME="action_sigrequest" VALUE="Anula suscripción">
         </FORM>

  [ELSE]

	Para confirmar la anulación de su suscripción a la lista [list], digite la siguiente contraseña:

         <FORM ACTION="[path_cgi]" METHOD=POST>
          <FONT COLOR="[dark_color]"><B>E-mail </B> </FONT>[email]<BR>
            <FONT COLOR="[dark_color]"><B>Contraseña</B> </FONT> 
  	  <INPUT TYPE="password" NAME="passwd" SIZE="20">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
         &nbsp; &nbsp; &nbsp;<INPUT TYPE="submit" NAME="action_signoff" VALUE="Anula suscripción">

<BR><BR>
<I>Si olvidó su contraseña o no tiene ninguna para este servidor:</I>  <INPUT TYPE="submit" NAME="action_sendpasswd" VALUE="Enviarme mi contraseña">

         </FORM>

  [ENDIF]      

