<!-- RCS Identication ; $Revision$ ; $Date$ -->

  [IF status=auth]

	Usted solicitó una subscripción a la lista [list]. <BR>
	Pulse el siguiente botón para confirmarla: <br>
	<BR>

	<FORM ACTION="[path_cgi]" METHOD=POST>
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[user->email]">
	  <INPUT TYPE="submit" NAME="action_subscribe" VALUE="Yo me subscribo a la lista [list]">
	</FORM>


  [ELSIF status=notauth_passwordsent]

	Usted solicitó una subscripción a la lista [list]. 
	<BR><BR>
 Para confirmar su identidad y evitar que alguien le subscriba sin su permiso, un mensaje con una contraseña se le enviará en breve. <br><br>

Compruebe los mensajes nuevos en su correo y utilice la contraseña que Sympa le envia en el siguiente formulario. Dicha contraseña confirmará su subscripción a la lista [list].

        <FORM ACTION="[path_cgi]" METHOD=POST>
          <FONT COLOR="--DARK_COLOR--"><B>e-mail address</B> </FONT>[email]<BR>
	  <FONT COLOR="--DARK_COLOR--"><B>password</B> </FONT> 
  	  <INPUT TYPE="password" NAME="passwd" SIZE="20">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
	  <INPUT TYPE="hidden" NAME="previous_list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="previous_action" VALUE="subrequest">
        &nbsp; &nbsp; &nbsp;<INPUT TYPE="submit" NAME="action_subscribe" VALUE="Subscribir">
        </FORM>

  Esta contraseña, asociada con su E-mail, le permitirá acceder a su entorno WWSympa.


  [ELSIF status=notauth_noemail]

         <FORM ACTION="[path_cgi]" METHOD=POST>
          <FONT COLOR="--DARK_COLOR--"><B>Su E-mail</B> 
	  <INPUT  NAME="email" SIZE="30"><BR>
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="action" VALUE="subrequest">
	  <INPUT TYPE="submit" NAME="action_subrequest" VALUE="Aceptar">
         </FORM>


  [ELSIF status=notauth]

 	Para confirmar su subscripción a la lista [list], entre su contraseña en el sgte. formulario:

         <FORM ACTION="[path_cgi]" METHOD=POST>
          <FONT COLOR="--DARK_COLOR--"><B>E-mail</B> </FONT>[email]<BR>
            <FONT COLOR="--DARK_COLOR--"><B>Contraseña</B> </FONT> 
  	  <INPUT TYPE="password" NAME="passwd" SIZE="20">
	  <INPUT TYPE="hidden" NAME="list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="email" VALUE="[email]">
	  <INPUT TYPE="hidden" NAME="previous_list" VALUE="[list]">
	  <INPUT TYPE="hidden" NAME="previous_action" VALUE="subrequest">
         &nbsp; &nbsp; &nbsp;<INPUT TYPE="submit" NAME="action_subscribe" VALUE="Subscribe">
	<INPUT TYPE="submit" NAME="action_sendpasswd" VALUE="Mi contraseña?">
         </FORM>

  [ELSIF status=notauth_subscriber]

	<FONT COLOR="--DARK_COLOR--"><B>Usted ya es subscriptor de la lista [list].
	</FONT>
	<BR><BR>


	[PARSE '--ETCBINDIR--/wws_templates/loginbanner.es.tpl']

  [ENDIF]      



